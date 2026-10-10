--!strict

--[[
	Title Progression V0.1.

	Reads hierarchy + territory ownership. Does not own those systems.
	Prestige is temporary server-side test Prestige (not spent, not an economy).
]]

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local RankRules = require(ReplicatedStorage.Shared.Util.PoliticalRankRules)
local TitleRequirements = require(ReplicatedStorage.Shared.Util.TitleRequirements)
local Hierarchy = require(ServerScriptService.Services.PoliticalHierarchyService)
local Territory = require(ServerScriptService.Services.TerritoryMapService)

local MatchState = require(script.Parent.MatchState)
local TitleProgressionService = {}

local DEFAULT_PRESTIGE = 0

local started = false
local prestigeByRuler: { [string]: number } = {}
local clientIntent: RemoteEvent
local serverPush: RemoteEvent
local debugSnapshot: StringValue?

local function findRuler(rulerId: string): any?
	for _, ruler in Hierarchy.GetSnapshot().rulers do
		if ruler.rulerId == rulerId then
			return ruler
		end
	end
	return nil
end

local function realmControl(rulerId: string): number
	local ruler = findRuler(rulerId)
	if not ruler then
		return 0
	end
	local ids = { ruler.rulerId }
	if typeof(ruler.descendantIds) == "table" then
		for _, id in ruler.descendantIds do
			table.insert(ids, id)
		end
	end
	return Territory.CountOwnedByRulers(ids)
end

local function getPrestige(rulerId: string): number
	local value = prestigeByRuler[rulerId]
	if typeof(value) == "number" then
		return value
	end
	return DEFAULT_PRESTIGE
end

local function buildRow(ruler: any): any
	local currentRank = ruler.titleRank
	local nextRank = RankRules.NextRank(currentRank)
	local mapDef = Territory.GetMapDefinition()
	local control = realmControl(ruler.rulerId)
	local prestige = getPrestige(ruler.rulerId)
	if nextRank == nil then
		return {
			rulerId = ruler.rulerId,
			userId = ruler.userId or 0,
			currentRank = currentRank,
			currentTitleName = RankRules.Name(currentRank),
			hasNext = false,
			nextRank = 0,
			nextTitleName = "",
			establishLabel = "",
			realmControl = control,
			realmRequired = 0,
			prestige = prestige,
			prestigeRequired = 0,
			eligible = false,
			statusText = "Maximum title",
		}
	end
	local req = TitleRequirements.ForRank(mapDef, nextRank)
	if not req then
		return {
			rulerId = ruler.rulerId,
			userId = ruler.userId or 0,
			currentRank = currentRank,
			currentTitleName = RankRules.Name(currentRank),
			hasNext = true,
			nextRank = nextRank,
			nextTitleName = RankRules.Name(nextRank),
			establishLabel = "",
			realmControl = control,
			realmRequired = 0,
			prestige = prestige,
			prestigeRequired = 0,
			eligible = false,
			statusText = "No requirement configured",
		}
	end
	local eligible = control >= req.territoryCount and prestige >= req.prestige
	return {
		rulerId = ruler.rulerId,
		userId = ruler.userId or 0,
		currentRank = currentRank,
		currentTitleName = RankRules.Name(currentRank),
		hasNext = true,
		nextRank = nextRank,
		nextTitleName = req.titleName,
		establishLabel = req.establishLabel,
		realmControl = control,
		realmRequired = req.territoryCount,
		prestige = prestige,
		prestigeRequired = req.prestige,
		eligible = eligible,
		statusText = if eligible then "Eligible" else "Not eligible",
	}
end

local function buildSnapshot()
	local byRulerId = {}
	for _, ruler in Hierarchy.GetSnapshot().rulers do
		table.insert(byRulerId, buildRow(ruler))
	end
	table.sort(byRulerId, function(a, b)
		return a.rulerId < b.rulerId
	end)
	return {
		mapId = Territory.GetMapId(),
		rows = byRulerId,
	}
end

local function pushState(toPlayer: Player?)
	local encoded = HttpService:JSONEncode(buildSnapshot())
	if debugSnapshot then
		debugSnapshot.Value = encoded
	end
	if toPlayer then
		print("[Title] push State to", toPlayer.Name)
		serverPush:FireClient(toPlayer, "State", encoded)
	else
		print("[Title] push State all clients")
		serverPush:FireAllClients("State", encoded)
	end
end

local function notice(player: Player, message: string)
	print("[Title] notice ->", player.Name, message)
	serverPush:FireClient(player, "Notice", message)
end

local function refresh()
	if not started then
		return
	end
	pushState()
end

function TitleProgressionService.GetSnapshot()
	return buildSnapshot()
end

-- Prototype/debug only. Not a client remote.
function TitleProgressionService.DebugSetPrestige(rulerId: string, value: number)
	if MatchState.IsEnded() then return end
	assert(typeof(value) == "number", "Prestige must be a number")
	assert(findRuler(rulerId), "Missing ruler")
	prestigeByRuler[rulerId] = value
	print("[Title] debug prestige", rulerId, value)
	refresh()
end

function TitleProgressionService.EstablishForPlayer(player: Player): (boolean, string)
	if MatchState.IsEnded() then return false, "Match ended." end
	local rulerId = Hierarchy.GetRulerIdForUserId(player.UserId)
	if not rulerId then
		return false, "No ruler record."
	end
	local ruler = findRuler(rulerId)
	if not ruler then
		return false, "Ruler no longer exists."
	end
	local nextRank = RankRules.NextRank(ruler.titleRank)
	if nextRank == nil then
		return false, "No higher landed title."
	end
	local req = TitleRequirements.ForRank(Territory.GetMapDefinition(), nextRank)
	if not req then
		return false, "No requirement configured."
	end
	local control = realmControl(rulerId)
	local prestige = getPrestige(rulerId)
	if control < req.territoryCount then
		return false, "Insufficient realm control."
	end
	if prestige < req.prestige then
		return false, "Insufficient Prestige."
	end
	local ok, err = Hierarchy.SetTitleRank(rulerId, nextRank)
	if not ok then
		return false, err
	end
	-- Prestige is not spent.
	print("[Title] established", req.titleName, "for", ruler.displayName, "prestige remains", prestige)
	return true, req.establishedNotice
end

local function onClientIntent(player: Player, action: any)
	if typeof(action) ~= "string" then
		notice(player, "Invalid request.")
		return
	end
	if action == "Ready" then
		print("[Title] Ready from", player.Name)
		pushState(player)
		return
	end
	if action == "Establish" then
		local ok, result = TitleProgressionService.EstablishForPlayer(player)
		notice(player, result)
		if ok then
			refresh()
		end
		return
	end
	notice(player, "Unknown action.")
end

function TitleProgressionService.Start()
	if started then
		return
	end
	started = true

	local remotesFolder = ReplicatedStorage:WaitForChild("Remotes") :: Folder
	clientIntent = remotesFolder:WaitForChild("TitleClientEvent") :: RemoteEvent
	serverPush = remotesFolder:WaitForChild("TitleServerEvent") :: RemoteEvent
	clientIntent.OnServerEvent:Connect(onClientIntent)

	local debugFolder = ServerScriptService:FindFirstChild("TitleProgressionDebug")
	if debugFolder then
		debugFolder:Destroy()
	end
	debugFolder = Instance.new("Folder")
	debugFolder.Name = "TitleProgressionDebug"
	debugFolder.Parent = ServerScriptService
	local help = Instance.new("StringValue")
	help.Name = "Help"
	help.Value =
		"Prototype only. Play Server Command Bar: _G.__TitleProgressionV01.DebugSetPrestige(rulerId, n). MCP: SetAttribute SetPrestige to rulerId=number."
	help.Parent = debugFolder
	debugSnapshot = Instance.new("StringValue")
	debugSnapshot.Name = "LastSnapshot"
	debugSnapshot.Parent = debugFolder
	debugFolder:GetAttributeChangedSignal("SetPrestige"):Connect(function()
		local raw = debugFolder:GetAttribute("SetPrestige")
		if typeof(raw) ~= "string" then
			return
		end
		local rulerId, valueStr = string.match(raw, "^(.-)=([%-%d%.]+)$")
		local value = tonumber(valueStr)
		if rulerId and value then
			TitleProgressionService.DebugSetPrestige(rulerId, value)
		else
			warn("[Title] debug SetPrestige expected rulerId=number")
		end
	end)
	debugFolder:GetAttributeChangedSignal("EstablishForUserId"):Connect(function()
		local userId = tonumber(debugFolder:GetAttribute("EstablishForUserId"))
		if not userId then
			return
		end
		local player = Players:GetPlayerByUserId(userId)
		if not player then
			warn("[Title] debug EstablishForUserId: no player")
			return
		end
		local ok, result = TitleProgressionService.EstablishForPlayer(player)
		print("[Title] debug establish", ok, result)
		notice(player, result)
		if ok then
			refresh()
		end
	end)

	Hierarchy.StateChanged:Connect(refresh)
	Territory.OwnershipChanged:Connect(refresh)
	Hierarchy.RulerCreated:Connect(function(rulerId: string)
		if prestigeByRuler[rulerId] == nil then
			prestigeByRuler[rulerId] = DEFAULT_PRESTIGE
		end
		refresh()
	end)
	Hierarchy.RulerRemoving:Connect(function(rulerId: string)
		prestigeByRuler[rulerId] = nil
		refresh()
	end)

	Players.PlayerAdded:Connect(function(player)
		task.defer(function()
			if player.Parent then
				pushState(player)
			end
		end)
	end)

	refresh()

	-- Prototype/debug: bind the running instance for Command Bar / MCP.
	-- Not a client remote. Do not use from ordinary gameplay.
	_G.__TitleProgressionV01 = TitleProgressionService
end

return TitleProgressionService
