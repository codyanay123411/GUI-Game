--!strict

--[[
	Title Progression V0.1.

	Reads hierarchy + territory ownership. Does not own those systems.
	Personal timed Prestige is cumulative eligibility, never spent.
]]

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Config = require(ReplicatedStorage.Shared.Config.TitleProgressionConfig)
local Accrual = require(ReplicatedStorage.Shared.Util.PrestigeAccrual)
local RankRules = require(ReplicatedStorage.Shared.Util.PoliticalRankRules)
local TitleRequirements = require(ReplicatedStorage.Shared.Util.TitleRequirements)
local Hierarchy = require(ServerScriptService.Services.PoliticalHierarchyService)
local Territory = require(ServerScriptService.Services.TerritoryMapService)

local MatchState = require(script.Parent.MatchState)
local TitleProgressionService = {}

assert(Config.UpdateIntervalSeconds >= 0.1 and Config.UpdateIntervalSeconds <= 60, "Prestige update interval must be bounded")
local ledger = Accrual.new(Config.PrestigePerPersonalProvincePerMinute)
local conquerable: { [string]: boolean } = {}
function TitleProgressionService.SettleCapital(id: string): number
	local at = workspace:GetServerTimeNow();ledger:Get(id, at);return at
end
function TitleProgressionService.RefreshCapital(id: string, boundary: number?)
	local level = require(script.Parent.BuildingService).GetCapitalLevel(id)
	local _, _, bonus = require(ReplicatedStorage.Shared.Util.BuildingPolicy).Capital(level)
	ledger:SetMultiplier(id, 1 + bonus, boundary or workspace:GetServerTimeNow())
end

local started = false
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
	return ledger:Get(rulerId, workspace:GetServerTimeNow())
end

local function personalHoldings(rulerId: string): number
	local count = 0
	for _, id in Territory.GetOwnedTerritoryIds(rulerId) do
		if conquerable[id] then count += 1 end
	end
	return count
end

local function buildRow(ruler: any): any
	local currentRank = ruler.titleRank
	local nextRank = RankRules.NextRank(currentRank)
	local control = realmControl(ruler.rulerId)
	local prestige = getPrestige(ruler.rulerId)
	local personal = personalHoldings(ruler.rulerId)
	local rate = if MatchState.IsEnded() then 0 else personal * Config.PrestigePerPersonalProvincePerMinute * (if ledger.accounts[ruler.rulerId] then ledger.accounts[ruler.rulerId].multiplier or 1 else 1)
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
			prestigePerMinute = rate,
			personalHoldings = personal,
			matchEnded = MatchState.IsEnded(),
			prestigeRequired = 0,
			eligible = false,
			statusText = "Maximum title",
		}
	end
	local req = TitleRequirements.ForRank(Territory.GetTitleRequirements(), nextRank)
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
			prestigePerMinute = rate,
			personalHoldings = personal,
			matchEnded = MatchState.IsEnded(),
			prestigeRequired = 0,
			eligible = false,
			statusText = "No requirement configured",
		}
	end
	local eligible = not MatchState.IsEnded() and control >= req.territoryCount and prestige >= req.prestige
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
		prestigePerMinute = rate,
		personalHoldings = personal,
		matchEnded = MatchState.IsEnded(),
		prestigeRequired = req.prestige,
		eligible = eligible,
		statusText = if MatchState.IsEnded() then "Match ended" elseif eligible then "Eligible" else "Not eligible",
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
		MatchState.Send(serverPush, toPlayer, "State", encoded)
	else
		print("[Title] push State all clients")
		MatchState.Send(serverPush, nil, "State", encoded)
	end
end

local function notice(player: Player, message: string)
	print("[Title] notice ->", player.Name, message)
	MatchState.Send(serverPush, player, "Notice", message)
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
	assert(typeof(value) == "number" and value == value and value >= 0 and value < math.huge, "Prestige must be finite and nonnegative")
	assert(findRuler(rulerId), "Missing ruler")
	ledger:SetValue(rulerId, value, workspace:GetServerTimeNow())
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
	local req = TitleRequirements.ForRank(Territory.GetTitleRequirements(), nextRank)
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
	MatchState.ConnectIntent(clientIntent, onClientIntent)

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

	for _, province in Territory.GetMapDefinition().territories do
		conquerable[province.id] = province.conquerable ~= false
	end
	local initializedAt = workspace:GetServerTimeNow()
	for _, ruler in Hierarchy.GetSnapshot().rulers do
		ledger:AddRuler(ruler.rulerId, initializedAt, personalHoldings(ruler.rulerId))
	end
	Hierarchy.SetPrestigeLifecycleAccounting(function(id, at)
		ledger:AddRuler(id, at, 0)
	end, function(id, at)
		ledger:Remove(id, at)
	end)
	Territory.SetOwnershipAccounting(function(id, previous, nextOwner, at)
		if not conquerable[id] then return end
		require(script.Parent.BuildingService).OwnershipBoundary(id, previous, nextOwner, at)
		if previous and ledger.accounts[previous] then
			ledger:SetHoldings(previous, ledger.accounts[previous].holdings - 1, at)
		end
		if nextOwner and ledger.accounts[nextOwner] then
			ledger:SetHoldings(nextOwner, ledger.accounts[nextOwner].holdings + 1, at)
		end
	end)
	MatchState.SetPrestigeFreeze(function(at)
		ledger:Freeze(at)
		refresh()
	end)
	Hierarchy.StateChanged:Connect(refresh)
	Territory.OwnershipChanged:Connect(refresh)
	-- Notifications update presentation only; synchronous hooks own accounting/lifetime.
	Hierarchy.RulerCreated:Connect(refresh)
	Hierarchy.RulerRemoving:Connect(refresh)
	task.spawn(function()
		while started do
			task.wait(Config.UpdateIntervalSeconds)
			if not MatchState.IsEnded() then refresh() end
		end
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

function TitleProgressionService.PublishMatch() refresh() end

function TitleProgressionService.ResetMatch()
	assert(MatchState.IsResetting())
	ledger = Accrual.new(Config.PrestigePerPersonalProvincePerMinute)
	local at = workspace:GetServerTimeNow()
	for _, ruler in Hierarchy.GetSnapshot().rulers do ledger:AddRuler(ruler.rulerId, at, 0) end
end

return TitleProgressionService
