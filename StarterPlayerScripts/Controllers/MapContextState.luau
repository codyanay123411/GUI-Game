--!strict
local MatchIntent = require(game:GetService("ReplicatedStorage").Shared.Util.MatchIntent)
-- Read-only presentation mirrors. Services remain the owners of every rule/state.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local State = { buildings = { provinces = {} }, economy = {}, hierarchy = { rulers = {}, requests = {} }, territory = { territories = {} },
	diplomacy = { agreements = {}, requests = {} }, warfare = { wars = {}, cooldowns = {} },
	permissions = { self = {}, subjects = {} }, military = { wars = {} }, communications = { contexts = {}, contacts = {} } } :: any
State.Changed = Instance.new("BindableEvent")
local started = false
local function showElimination(value: boolean)
 local gui = game:GetService("Players").LocalPlayer.PlayerGui:FindFirstChild("HierarchyPrototypeGui")
 if gui then gui:SetAttribute("Eliminated", value) end
end
function State.Start()
	if started then return end
	started = true
	MatchIntent.OnChanged(function()
		State.buildings = { provinces = {} };State.economy = {};showElimination(false)
		State.hierarchy = { rulers = {}, requests = {} };State.territory = { territories = {} }
		State.diplomacy = { agreements = {}, requests = {} };State.warfare = { wars = {}, cooldowns = {} }
		State.military = { wars = {} };State.permissions = { self = {}, subjects = {} }
		State.communications = { contexts = {}, contacts = {} }
		State.Changed:Fire("match", "Reset")
	end)
	local remotes = ReplicatedStorage:WaitForChild("Remotes")
	for key, prefix in { buildings = "Buildings", economy = "Economy", hierarchy = "Hierarchy", territory = "Territory", diplomacy = "Diplomacy",
		warfare = "Warfare", military = "Military", communications = "Communications", permissions = "Permissions" } do
		local push = remotes:WaitForChild(prefix .. "ServerEvent") :: RemoteEvent
		MatchIntent.ConnectPush(push, function(kind, payload)
			local data = payload
			if typeof(payload) == "string" and (kind == "State" or kind == "BattleResult") then
				local ok, decoded = pcall(HttpService.JSONDecode, HttpService, payload)
				data = if ok then decoded else nil
			end
			if kind == "State" and typeof(data) == "table" then State[key] = data;if key == "buildings" then showElimination(data.eliminated == true) end end
			State.Changed:Fire(key, kind, data)
		end)
		local intent = remotes:WaitForChild(prefix .. "ClientEvent") :: RemoteEvent
		MatchIntent.Send(intent, "Ready")
	end
end
return State
