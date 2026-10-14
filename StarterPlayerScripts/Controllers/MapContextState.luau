--!strict
-- Read-only presentation mirrors. Services remain the owners of every rule/state.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local State = { hierarchy = { rulers = {}, requests = {} }, territory = { territories = {} },
	diplomacy = { agreements = {}, requests = {} }, warfare = { wars = {}, cooldowns = {} },
	permissions = { self = {}, subjects = {} }, military = { wars = {} }, communications = { contexts = {}, contacts = {} } } :: any
State.Changed = Instance.new("BindableEvent")
local started = false
function State.Start()
	if started then return end
	started = true
	local remotes = ReplicatedStorage:WaitForChild("Remotes")
	for key, prefix in { hierarchy = "Hierarchy", territory = "Territory", diplomacy = "Diplomacy",
		warfare = "Warfare", military = "Military", communications = "Communications", permissions = "Permissions" } do
		local push = remotes:WaitForChild(prefix .. "ServerEvent") :: RemoteEvent
		push.OnClientEvent:Connect(function(kind, payload)
			local data = payload
			if typeof(payload) == "string" and (kind == "State" or kind == "BattleResult") then
				local ok, decoded = pcall(HttpService.JSONDecode, HttpService, payload)
				data = if ok then decoded else nil
			end
			if kind == "State" and typeof(data) == "table" then State[key] = data end
			State.Changed:Fire(key, kind, data)
		end)
		local intent = remotes:WaitForChild(prefix .. "ClientEvent") :: RemoteEvent
		intent:FireServer("Ready")
	end
end
return State
