--!strict

--[[
	Economy / Resources V0.1 — server-authoritative Gold.

	Reads Hierarchy ruler lifecycle and Territory ownership/config.
	Does not own those systems. Does not grant titles, Prestige, wars, or tax.
]]

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local EconomyConfig = require(ReplicatedStorage.Shared.Config.EconomyConfig)
local EconomyPayout = require(ReplicatedStorage.Shared.Util.EconomyPayout)
local Hierarchy = require(ServerScriptService.Services.PoliticalHierarchyService)
local Territory = require(ServerScriptService.Services.TerritoryMapService)

local EconomyService = {}

local started = false
local goldByRuler: { [string]: number } = {}
local nextPayoutAt = 0
local payoutLoopRunning = false

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

local function definitionById()
	local byId = {}
	for _, t in Territory.GetMapDefinition().territories do
		byId[t.id] = t
	end
	return byId
end

local function isWholeNonNegative(value: number): boolean
	return typeof(value) == "number" and value >= 0 and value == math.floor(value) and value == value
end

local function ensureGold(rulerId: string)
	if goldByRuler[rulerId] == nil then
		goldByRuler[rulerId] = EconomyConfig.StartingGold
	end
end

function EconomyService.GetBalance(rulerId: string): number
	local value = goldByRuler[rulerId]
	if typeof(value) == "number" then
		return value
	end
	return 0
end

function EconomyService.GetIncomeGoldPerMinute(rulerId: string): number
	if goldByRuler[rulerId] == nil then
		return 0
	end
	local byId = definitionById()
	local total = 0
	for _, territoryId in Territory.GetOwnedTerritoryIds(rulerId) do
		local def = byId[territoryId]
		if def and typeof(def.baseGoldIncome) == "number" then
			total += def.baseGoldIncome
		end
	end
	return total
end

local function playerSnapshot(rulerId: string)
	return {
		gold = EconomyService.GetBalance(rulerId),
		incomeGoldPerMinute = EconomyService.GetIncomeGoldPerMinute(rulerId),
		payoutIntervalSeconds = EconomyConfig.PayoutIntervalSeconds,
		nextPayoutAt = nextPayoutAt,
	}
end

local function inspectSnapshot(rulerId: string)
	return {
		rulerId = rulerId,
		gold = EconomyService.GetBalance(rulerId),
		incomeGoldPerMinute = EconomyService.GetIncomeGoldPerMinute(rulerId),
		ownedTerritoryCount = #Territory.GetOwnedTerritoryIds(rulerId),
	}
end

local function pushPlayer(player: Player)
	if not started then
		return
	end
	local rulerId = Hierarchy.GetRulerIdForUserId(player.UserId)
	local payload
	if rulerId and goldByRuler[rulerId] ~= nil then
		payload = playerSnapshot(rulerId)
	else
		payload = {
			gold = 0,
			incomeGoldPerMinute = 0,
			payoutIntervalSeconds = EconomyConfig.PayoutIntervalSeconds,
			nextPayoutAt = nextPayoutAt,
		}
	end
	serverPush:FireClient(player, "State", HttpService:JSONEncode(payload))
end

local function pushAllPlayers()
	if debugSnapshot then
		local rows = {}
		for rulerId, gold in goldByRuler do
			table.insert(rows, {
				rulerId = rulerId,
				gold = gold,
				incomeGoldPerMinute = EconomyService.GetIncomeGoldPerMinute(rulerId),
			})
		end
		table.sort(rows, function(a, b)
			return a.rulerId < b.rulerId
		end)
		debugSnapshot.Value = HttpService:JSONEncode({
			nextPayoutAt = nextPayoutAt,
			rulers = rows,
		})
	end
	for _, player in Players:GetPlayers() do
		pushPlayer(player)
	end
end

local function notice(player: Player, message: string)
	serverPush:FireClient(player, "Notice", message)
end

function EconomyService.GetInspect(rulerId: string): any?
	if goldByRuler[rulerId] == nil then
		return nil
	end
	return inspectSnapshot(rulerId)
end

function EconomyService.AddGold(rulerId: string, amount: number): (boolean, string)
	if goldByRuler[rulerId] == nil then
		return false, "No economy state."
	end
	if not isWholeNonNegative(amount) then
		return false, "Gold amount must be a whole number >= 0."
	end
	if amount == 0 then
		return true, "No change."
	end
	goldByRuler[rulerId] += amount
	pushAllPlayers()
	return true, string.format("Added %d Gold.", amount)
end

function EconomyService.TrySpend(rulerId: string, amount: number): (boolean, string)
	if goldByRuler[rulerId] == nil then
		return false, "No economy state."
	end
	if typeof(amount) ~= "number" or amount ~= amount or amount ~= math.floor(amount) or amount <= 0 then
		return false, "Spend amount must be a whole number greater than 0."
	end
	local balance = goldByRuler[rulerId]
	if amount > balance then
		return false, "Insufficient Gold."
	end
	goldByRuler[rulerId] = balance - amount
	pushAllPlayers()
	return true, string.format("Spent %d Gold.", amount)
end

function EconomyService.DebugSetGold(rulerId: string, value: number): (boolean, string)
	if goldByRuler[rulerId] == nil then
		return false, "No economy state."
	end
	if not isWholeNonNegative(value) then
		return false, "Gold must be a whole number >= 0."
	end
	goldByRuler[rulerId] = value
	pushAllPlayers()
	return true, string.format("Gold set to %d.", value)
end

local function payoutTick()
	local byId = definitionById()
	local credit: { [string]: number } = {}
	for _, t in Territory.GetMapDefinition().territories do
		local ownerId = Territory.GetOwnerRulerId(t.id)
		if ownerId and goldByRuler[ownerId] ~= nil then
			local def = byId[t.id]
			local perTick = if def then EconomyPayout.GoldPerTick(def.baseGoldIncome) else nil
			if perTick and perTick > 0 then
				credit[ownerId] = (credit[ownerId] or 0) + perTick
			end
		end
	end
	for rulerId, amount in credit do
		goldByRuler[rulerId] += amount
	end
end

local function runPayoutLoop()
	if payoutLoopRunning then
		return
	end
	payoutLoopRunning = true
	local interval = EconomyConfig.PayoutIntervalSeconds
	nextPayoutAt = workspace:GetServerTimeNow() + interval
	task.spawn(function()
		pushAllPlayers()
		while started do
			local waitFor = nextPayoutAt - workspace:GetServerTimeNow()
			if waitFor > 0 then
				task.wait(waitFor)
			end
			if not started then
				break
			end
			payoutTick()
			nextPayoutAt = workspace:GetServerTimeNow() + interval
			pushAllPlayers()
		end
		payoutLoopRunning = false
	end)
end

local function onClientIntent(player: Player, action: any)
	if typeof(action) ~= "string" then
		return
	end
	if action == "Ready" then
		pushPlayer(player)
		return
	end
	notice(player, "Unknown action.")
end

function EconomyService.Start()
	if started then
		return
	end

	local mapOk, mapErr = EconomyPayout.ValidateMap(Territory.GetMapDefinition())
	if not mapOk then
		error("[Economy] " .. (mapErr or "Invalid map Gold configuration."))
	end

	started = true

	local remotesFolder = ReplicatedStorage:WaitForChild("Remotes") :: Folder
	clientIntent = remotesFolder:WaitForChild("EconomyClientEvent") :: RemoteEvent
	serverPush = remotesFolder:WaitForChild("EconomyServerEvent") :: RemoteEvent
	clientIntent.OnServerEvent:Connect(onClientIntent)

	for _, ruler in Hierarchy.GetSnapshot().rulers do
		ensureGold(ruler.rulerId)
	end

	local debugFolder = ServerScriptService:FindFirstChild("EconomyDebug")
	if debugFolder then
		debugFolder:Destroy()
	end
	debugFolder = Instance.new("Folder")
	debugFolder.Name = "EconomyDebug"
	debugFolder.Parent = ServerScriptService
	local help = Instance.new("StringValue")
	help.Name = "Help"
	help.Value =
		"Prototype only. Invoke('Inspect'|'SetGold'|'AddGold'|'SpendGold', rulerId, amount). Prefer AdminBridge/Kohl."
	help.Parent = debugFolder
	debugSnapshot = Instance.new("StringValue")
	debugSnapshot.Name = "LastSnapshot"
	debugSnapshot.Parent = debugFolder
	local invoke = Instance.new("BindableFunction")
	invoke.Name = "Invoke"
	invoke.Parent = debugFolder
	invoke.OnInvoke = function(action: any, a: any, b: any)
		if action == "Inspect" then
			local snap = EconomyService.GetInspect(tostring(a))
			local encoded = if snap then HttpService:JSONEncode(snap) else "No economy state."
			print("[Economy] debug Inspect", encoded)
			return snap ~= nil, encoded
		elseif action == "SetGold" then
			local ok, result = EconomyService.DebugSetGold(tostring(a), tonumber(b) or -1)
			print("[Economy] debug SetGold", ok, result)
			return ok, result
		elseif action == "AddGold" then
			local ok, result = EconomyService.AddGold(tostring(a), tonumber(b) or -1)
			print("[Economy] debug AddGold", ok, result)
			return ok, result
		elseif action == "SpendGold" then
			local ok, result = EconomyService.TrySpend(tostring(a), tonumber(b) or -1)
			print("[Economy] debug SpendGold", ok, result)
			return ok, result
		end
		return false, "Unknown action."
	end

	Hierarchy.RulerCreated:Connect(function(rulerId: string)
		ensureGold(rulerId)
		pushAllPlayers()
	end)
	Hierarchy.RulerRemoving:Connect(function(rulerId: string)
		goldByRuler[rulerId] = nil
		pushAllPlayers()
	end)
	Hierarchy.StateChanged:Connect(function()
		pushAllPlayers()
	end)
	Territory.OwnershipChanged:Connect(function()
		pushAllPlayers()
	end)

	Players.PlayerAdded:Connect(function(player)
		task.defer(function()
			if player.Parent then
				pushPlayer(player)
			end
		end)
	end)

	runPayoutLoop()

	_G.__EconomyV01 = EconomyService
	print("[Economy] started. StartingGold", EconomyConfig.StartingGold, "interval", EconomyConfig.PayoutIntervalSeconds)
end

return EconomyService
