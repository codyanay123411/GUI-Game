--!strict
-- Server-only per-player routing coordinator. No match reset or destination state.
local Requests = {}
function Requests.Create(deps: any)
	local states = {}
	local sequence = 0
	local function stateFor(player: any): any
		if not states[player] then
			states[player] = { revision = 0, phase = "Idle", message = "Play Again leaves this server when the transfer succeeds.", flight = nil, nextTryAt = -math.huge }
		end
		return states[player]
	end
	local function snapshot(state: any): any
		return { revision = state.revision, phase = state.phase, message = state.message,
			pending = state.flight ~= nil, description = deps.description }
	end
	local function publish(player: any, state: any)
		if deps.connected(player) then deps.publish(player, snapshot(state)) end
	end
	local function change(player: any, state: any, phase: string, message: string)
		state.revision += 1; state.phase = phase; state.message = message
		publish(player, state)
	end
	local api = {}
	function api.Status(player: any): any return snapshot(stateFor(player)) end
	function api.Remove(player: any) states[player] = nil end
	function api.Fail(player: any, id: number, message: string): boolean
		local state = states[player]
		if not state or state.flight ~= id then return false end
		state.flight = nil
		state.nextTryAt = deps.clock() + 2
		change(player, state, "Failed", message)
		return true
	end
	function api.Request(player: any): boolean
		if not deps.connected(player) then return false end
		local state = stateFor(player)
		if state.flight then publish(player, state); return false end
		if not deps.ended() then
			change(player, state, "Unavailable", "Play Again is available after the match ends."); return false
		end
		if deps.clock() < state.nextTryAt then
			change(player, state, "Failed", "Please wait a moment, then try Play Again again."); return false
		end
		local available, reason = deps.available()
		if not available then
			state.nextTryAt = deps.clock() + 2
			change(player, state, "Unavailable", reason); return false
		end
		sequence += 1
		local id = sequence
		state.flight = id
		change(player, state, "Preparing", "Preparing a new reserved match for you. You can keep inspecting while waiting.")
		deps.spawn(function()
			-- A queued worker must not send a disconnected/replaced player's request.
			if states[player] ~= state or state.flight ~= id or not deps.connected(player) then return end
			local ok, err = pcall(function() deps.teleport(player, id) end)
			if not ok then
				if api.Fail(player, id, "Couldn't start your new match. You're still here. Try Play Again again.") then deps.log(err) end
			elseif states[player] == state and state.flight == id then
				change(player, state, "Transferring", "Roblox is transferring you. Other players stay here; final-map inspection remains available while you wait.")
			end
		end)
		return true
	end
	return api
end
return Requests
