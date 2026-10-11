--!strict
-- Owner-only, server-wide presentation. No gameplay or Kohl preference persistence.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.Shared.Config.GameSettingsConfig)
local AdminConfig = require(script.Parent.AdminConfig)
local Service = {}
local values = table.clone(Config.Defaults)
local revision = 0
local started = false
local stateEvent: RemoteEvent
local lastRequest: { [Player]: number } = {}

function Service.GetSnapshot(): any
	return { values = table.clone(values), revision = revision, persistence = "Runtime only" }
end

local function send(player: Player, errorMessage: string?)
	local snapshot = Service.GetSnapshot()
	snapshot.canConfigure = AdminConfig.CanConfigureGame(player.UserId)
	snapshot.canView = snapshot.canConfigure or AdminConfig.IsGameTester(player.UserId)
	snapshot.error = errorMessage
	stateEvent:FireClient(player, snapshot)
end

function Service.Apply(userId: number, action: any, key: any, value: any): (boolean, string)
	if not AdminConfig.CanConfigureGame(userId) then return false, "Only the game creator can configure presentation." end
	if action == "Set" then
		if not Config.Validate(key, value) then return false, "Invalid presentation setting or value." end
		if values[key] == value then return true, "Unchanged." end
		values[key] = value
	elseif action == "Reset" and (key == "Game UI" or key == "Game Audio") then
		for _, definition in Config.Definitions do
			if definition.category == key then values[definition.key] = definition.default end
		end
	else
		return false, "Invalid presentation action."
	end
	revision += 1
	if stateEvent then for _, player in Players:GetPlayers() do send(player) end end
	return true, "Updated runtime presentation."
end

function Service.Start()
	if started then return end
	started = true
	local remotes = ReplicatedStorage:WaitForChild("Remotes")
	local function remote(name: string): RemoteEvent
		local existing = remotes:FindFirstChild(name)
		if existing then assert(existing:IsA("RemoteEvent")); return existing end
		local event = Instance.new("RemoteEvent")
		event.Name = name
		event.Parent = remotes
		return event
	end
	stateEvent = remote("GameSettingsStateEvent")
	remote("GameSettingsRequestEvent").OnServerEvent:Connect(function(player, request)
		local now = os.clock()
		if now - (lastRequest[player] or -math.huge) < 0.1 then return end
		lastRequest[player] = now
		if typeof(request) ~= "table" then send(player, "Invalid presentation request."); return end
		if request.action == "Ready" then send(player); return end
		local ok, message = Service.Apply(player.UserId, request.action, request.key, request.value)
		if not ok then send(player, message) end
	end)
	Players.PlayerRemoving:Connect(function(player) lastRequest[player] = nil end)
	-- Permission refresh is UI admission only; Apply always checks actual server authority.
	task.spawn(function()
		for _ = 1, 20 do
			local K = shared._K_INTERFACE
			if K and K.Hook then
				local function refresh() for _, player in Players:GetPlayers() do send(player) end end
				K.Hook.roleAdded:Connect(refresh)
				K.Hook.roleRemoved:Connect(refresh)
				refresh()
				return
			end
			task.wait(0.5)
		end
	end)
end

return Service
