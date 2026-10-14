--!strict
-- Shared server-only gate. VictoryService alone ends the match.
local MatchState = {}
local final: any = nil
local generation = 1
local resetting = false
local Players = game:GetService("Players")
local leaving: { [Player]: boolean } = setmetatable({}, { __mode = "k" }) :: any
Players.PlayerRemoving:Connect(function(player) leaving[player] = true end)
Players.PlayerAdded:Connect(function(player) leaving[player] = nil end)
function MatchState.GetConnectedPlayers(): { Player }
	local result = {};for _, player in Players:GetPlayers() do if not leaving[player] then table.insert(result, player) end end
	return result
end
game:GetService("ReplicatedStorage"):SetAttribute("MatchGeneration", generation)

function MatchState.GetGeneration(): number return generation end
function MatchState.Send(remote: RemoteEvent, player: Player?, kind: string, payload: any)
	if resetting and kind ~= "ReplayStatus" then return end -- Never publish partially reset gameplay state.
	if player then remote:FireClient(player, kind, payload, generation)
	else remote:FireAllClients(kind, payload, generation) end
end
function MatchState.IsResetting(): boolean return resetting end
function MatchState.BeginReset(): boolean
	if not final or resetting then return false end
	resetting = true
	generation += 1
	game:GetService("ReplicatedStorage"):SetAttribute("MatchGeneration", generation)
	return true
end
function MatchState.FinishReset()
	assert(resetting, "No match reset in progress")
	final = nil
	resetting = false
end
-- Ready is read-only. Every mutation carries its originating match generation.
function MatchState.ConnectIntent(remote: RemoteEvent, handler: any): RBXScriptConnection
	return remote.OnServerEvent:Connect(function(player, ...)
		local args = table.pack(...)
		if args[1] ~= "Ready" then
			local envelope = args[args.n]
			if resetting or typeof(envelope) ~= "table" or envelope.matchGeneration ~= generation then return end
			args.n -= 1
		end
		handler(player, table.unpack(args, 1, args.n))
	end)
end
local councilFreeze: ((number) -> ())? = nil

function MatchState.SetCouncilFreeze(callback: (number) -> ())
	assert(councilFreeze == nil, "Council freeze already installed")
	councilFreeze = callback
end

local prestigeFreeze: ((number) -> ())? = nil

function MatchState.SetPrestigeFreeze(callback: (number) -> ())
	assert(prestigeFreeze == nil, "Prestige freeze already installed")
	prestigeFreeze = callback
end

function MatchState.IsEnded(): boolean
	return final ~= nil or resetting
end

function MatchState.GetFinal(): any
	return final
end

function MatchState.End(snapshot: any): boolean
	if final then return false end
	final = snapshot
	if prestigeFreeze then prestigeFreeze(snapshot.endedAt) end
	if councilFreeze then councilFreeze(snapshot.endedAt) end
	return true
end

return MatchState
