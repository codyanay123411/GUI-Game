--!strict

--[[
	Military / Armies V0.1 — Troops, commitments, battle, casualties.

	Does not SetOwner. Does not declare wars.
	Feeds WarfareService.ApplyMilitaryOutcome after presentation.
]]

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")

local MilitaryConfig = require(ReplicatedStorage.Shared.Config.MilitaryConfig)
local MilitaryCombat = require(ReplicatedStorage.Shared.Util.MilitaryCombat)
local Hierarchy = require(ServerScriptService.Services.PoliticalHierarchyService)
local Territory = require(ServerScriptService.Services.TerritoryMapService)
local Economy = require(ServerScriptService.Services.EconomyService)
local Warfare = require(ServerScriptService.Services.WarfareService)

local MilitaryService = {}

type SideState = {
	intended: number?,
	interacted: boolean,
	locked: boolean,
	lockedAmount: number?,
}

type Engagement = {
	warId: string,
	attackerRootId: string,
	defenderRootId: string,
	targetTerritoryId: string,
	startedAt: number,
	attacker: SideState,
	defender: SideState,
	mechanicallyResolved: boolean,
	presentationUntil: number?,
	battle: MilitaryCombat.BattleResult?,
	concluded: boolean,
}

local started = false
local totalByRuler: { [string]: number } = {}
local reserved: { [string]: { [string]: number } } = {} -- warId -> rulerId -> amount
local engagements: { [string]: Engagement } = {}
local clientIntent: RemoteEvent
local serverPush: RemoteEvent
local debugSnapshot: StringValue?
local rngSeed: number? = nil
local diagEnabled = false

local function now(): number
	return workspace:GetServerTimeNow()
end

local function diag(...)
	if diagEnabled then
		print("[Military:diag]", ...)
	end
end

local function findRuler(rulerId: string): any?
	for _, ruler in Hierarchy.GetSnapshot().rulers do
		if ruler.rulerId == rulerId then
			return ruler
		end
	end
	return nil
end

local function territoryName(territoryId: string): string
	for _, t in Territory.GetMapDefinition().territories do
		if t.id == territoryId then
			if typeof(t.displayName) == "string" and t.displayName ~= "" then
				return t.displayName
			end
			return territoryId
		end
	end
	return territoryId
end

local function ensurePool(rulerId: string)
	if totalByRuler[rulerId] == nil then
		totalByRuler[rulerId] = MilitaryConfig.StartingTroops
	end
end

local function committedTotal(rulerId: string): number
	local sum = 0
	for _, byRuler in reserved do
		local n = byRuler[rulerId]
		if typeof(n) == "number" then
			sum += n
		end
	end
	return sum
end

local function availableOf(rulerId: string): number
	local total = totalByRuler[rulerId]
	if typeof(total) ~= "number" then
		return 0
	end
	return total - committedTotal(rulerId)
end

local function setReserved(warId: string, rulerId: string, amount: number)
	local row = reserved[warId]
	if row == nil then
		row = {}
		reserved[warId] = row
	end
	if amount <= 0 then
		row[rulerId] = nil
		if next(row) == nil then
			reserved[warId] = nil
		end
		return
	end
	row[rulerId] = amount
end

local function getReserved(warId: string, rulerId: string): number
	local row = reserved[warId]
	if not row then
		return 0
	end
	return row[rulerId] or 0
end

local function noticePlayer(player: Player, message: string)
	print("[Military] notice ->", player.Name, message)
	serverPush:FireClient(player, "Notice", message)
end

local function noticeRulerId(rulerId: string, message: string)
	local ruler = findRuler(rulerId)
	local userId = ruler and tonumber(ruler.userId)
	if typeof(userId) == "number" and userId ~= 0 then
		local player = Players:GetPlayerByUserId(userId)
		if player then
			noticePlayer(player, message)
		end
	end
end

local function sideFor(eng: Engagement, rulerId: string): SideState?
	if rulerId == eng.attackerRootId then
		return eng.attacker
	elseif rulerId == eng.defenderRootId then
		return eng.defender
	end
	return nil
end

local function playerPayload(rulerId: string)
	local total = totalByRuler[rulerId] or 0
	local committed = committedTotal(rulerId)
	local wars = {}
	for _, eng in engagements do
		if eng.attackerRootId == rulerId or eng.defenderRootId == rulerId then
			local mine = sideFor(eng, rulerId) :: SideState
			local role = if rulerId == eng.attackerRootId then "Attacker" else "Defender"
			local bothLocked = eng.attacker.locked and eng.defender.locked
			local opponentState = "Opponent preparing forces"
			if mine.locked and not bothLocked then
				opponentState = "Waiting for opponent"
			end
			local row: any = {
				warId = eng.warId,
				targetTerritoryId = eng.targetTerritoryId,
				targetDisplayName = territoryName(eng.targetTerritoryId),
				role = role,
				intended = if mine.interacted then mine.intended else nil,
				locked = mine.locked,
				windowEndsAt = eng.startedAt + MilitaryConfig.CommitWindowSeconds,
				hardEndsAt = eng.startedAt + MilitaryConfig.HardTimeoutSeconds,
				opponentState = if bothLocked then nil else opponentState,
				phase = if eng.concluded
					then "done"
					elseif eng.mechanicallyResolved then "present"
					else "commit",
				presentationEndsAt = eng.presentationUntil,
			}
			if bothLocked and eng.battle then
				row.attackerCommitted = eng.battle.attackerCommitted
				row.defenderCommitted = eng.battle.defenderCommitted
			end
			table.insert(wars, row)
		end
	end
	table.sort(wars, function(a, b)
		return a.warId < b.warId
	end)
	return {
		total = total,
		available = availableOf(rulerId),
		committed = committed,
		troopsPerGold = MilitaryConfig.TroopsPerGold,
		wars = wars,
	}
end

local function inspectPayload(rulerId: string)
	local wars = {}
	for _, eng in engagements do
		if eng.attackerRootId == rulerId or eng.defenderRootId == rulerId then
			table.insert(wars, {
				warId = eng.warId,
				reserved = getReserved(eng.warId, rulerId),
				role = if rulerId == eng.attackerRootId then "Attacker" else "Defender",
				intended = if rulerId == eng.attackerRootId then eng.attacker.intended else eng.defender.intended,
				locked = if rulerId == eng.attackerRootId then eng.attacker.locked else eng.defender.locked,
				mechanicallyResolved = eng.mechanicallyResolved,
			})
		end
	end
	return {
		rulerId = rulerId,
		total = totalByRuler[rulerId] or 0,
		available = availableOf(rulerId),
		committed = committedTotal(rulerId),
		ledgerOk = (totalByRuler[rulerId] or 0) == availableOf(rulerId) + committedTotal(rulerId),
		wars = wars,
	}
end

local function pushPlayer(player: Player)
	if not started then
		return
	end
	local rulerId = Hierarchy.GetRulerIdForUserId(player.UserId)
	local payload
	if rulerId and totalByRuler[rulerId] ~= nil then
		payload = playerPayload(rulerId)
	else
		payload = {
			total = 0,
			available = 0,
			committed = 0,
			troopsPerGold = MilitaryConfig.TroopsPerGold,
			wars = {},
		}
	end
	serverPush:FireClient(player, "State", HttpService:JSONEncode(payload))
end

local function pushAllPlayers()
	if debugSnapshot then
		local rows = {}
		for rulerId, total in totalByRuler do
			table.insert(rows, {
				rulerId = rulerId,
				total = total,
				available = availableOf(rulerId),
				committed = committedTotal(rulerId),
			})
		end
		debugSnapshot.Value = HttpService:JSONEncode({
			rulers = rows,
			engagements = (function()
				local list = {}
				for id, eng in engagements do
					table.insert(list, {
						warId = id,
						mechanical = eng.mechanicallyResolved,
						atkLocked = eng.attacker.locked,
						defLocked = eng.defender.locked,
					})
				end
				return list
			end)(),
		})
	end
	for _, player in Players:GetPlayers() do
		pushPlayer(player)
	end
end

local function makeRng(): Random
	if rngSeed ~= nil then
		return Random.new(rngSeed)
	end
	return Random.new()
end

local function applyCasualties(eng: Engagement, battle: MilitaryCombat.BattleResult)
	local function apply(rulerId: string, committed: number, casualties: number)
		if totalByRuler[rulerId] == nil then
			return
		end
		local survivors = math.max(0, committed - casualties)
		totalByRuler[rulerId] = math.max(0, totalByRuler[rulerId] - casualties)
		setReserved(eng.warId, rulerId, survivors)
	end
	apply(eng.attackerRootId, battle.attackerCommitted, battle.attackerCasualties)
	apply(eng.defenderRootId, battle.defenderCommitted, battle.defenderCasualties)
end

local function returnSurvivors(eng: Engagement)
	setReserved(eng.warId, eng.attackerRootId, 0)
	setReserved(eng.warId, eng.defenderRootId, 0)
	reserved[eng.warId] = nil
end

local function pushBattleResult(rulerId: string, payload: any)
	local ruler = findRuler(rulerId)
	local userId = ruler and tonumber(ruler.userId)
	if typeof(userId) ~= "number" or userId == 0 then
		return
	end
	local player = Players:GetPlayerByUserId(userId)
	if player then
		serverPush:FireClient(player, "BattleResult", HttpService:JSONEncode(payload))
	end
end

local function concludeEngagement(eng: Engagement)
	if eng.concluded then
		return
	end
	eng.concluded = true
	local battle = eng.battle
	if battle then
		local function resultFor(role: string)
			local won = (role == "Attacker" and battle.winner == "Attacker") or (role == "Defender" and battle.winner == "Defender")
			local title
			if battle.unopposed then
				title = "UNOPPOSED — " .. string.upper(territoryName(eng.targetTerritoryId)) .. " TAKEN"
			elseif won and role == "Attacker" then
				title = "VICTORY — " .. string.upper(territoryName(eng.targetTerritoryId)) .. " CAPTURED"
			elseif won then
				title = "DEFENDED — " .. string.upper(territoryName(eng.targetTerritoryId)) .. " HELD"
			else
				title = "DEFEAT — " .. string.upper(territoryName(eng.targetTerritoryId))
			end
			local myCommit = if role == "Attacker" then battle.attackerCommitted else battle.defenderCommitted
			local myCas = if role == "Attacker" then battle.attackerCasualties else battle.defenderCasualties
			local mySurv = if role == "Attacker" then battle.attackerSurvivors else battle.defenderSurvivors
			local enemyCommit = if role == "Attacker" then battle.defenderCommitted else battle.attackerCommitted
			return {
				title = title,
				committed = myCommit,
				enemyCommitted = enemyCommit,
				casualties = myCas,
				survivors = mySurv,
				unopposed = battle.unopposed,
				won = won,
				warId = eng.warId,
				targetTerritoryId = eng.targetTerritoryId,
				targetDisplayName = territoryName(eng.targetTerritoryId),
			}
		end
		pushBattleResult(eng.attackerRootId, resultFor("Attacker"))
		pushBattleResult(eng.defenderRootId, resultFor("Defender"))
	end
	returnSurvivors(eng)
	if battle then
		local outcome = battle.winner
		local ok, err = Warfare.ApplyMilitaryOutcome(eng.warId, outcome)
		print("[Military] ApplyMilitaryOutcome", eng.warId, outcome, ok, err)
	end
	engagements[eng.warId] = nil
	pushAllPlayers()
end

local function cancelEngagement(eng: Engagement, reason: string)
	if eng.mechanicallyResolved then
		return
	end
	returnSurvivors(eng)
	engagements[eng.warId] = nil
	Warfare.CancelWar(eng.warId, reason)
	pushAllPlayers()
end

local function resolveBattle(eng: Engagement)
	if eng.mechanicallyResolved then
		return
	end
	local atk = eng.attacker.lockedAmount
	local def = eng.defender.lockedAmount
	if typeof(atk) ~= "number" or typeof(def) ~= "number" then
		return
	end
	if atk <= 0 then
		diag("attacker locked 0; cancel", eng.warId)
		cancelEngagement(eng, "attacker committed no force")
		noticeRulerId(eng.attackerRootId, "Attack cancelled: you committed 0 Troops.")
		return
	end
	local battle = MilitaryCombat.Resolve(atk, def, makeRng())
	eng.battle = battle
	eng.mechanicallyResolved = true
	eng.presentationUntil = now() + MilitaryConfig.PresentationSeconds
	applyCasualties(eng, battle)
	diag("battle resolved", eng.warId, battle.winner, battle.band or "unopposed")
	pushAllPlayers()
end

local function tryLock(eng: Engagement, side: SideState, amount: number)
	if side.locked then
		return
	end
	side.locked = true
	side.lockedAmount = amount
	side.intended = amount
	side.interacted = true
	if side == eng.attacker and amount <= 0 then
		diag("attacker locked 0; cancel", eng.warId)
		cancelEngagement(eng, "attacker committed no force")
		noticeRulerId(eng.attackerRootId, "Attack cancelled: you committed 0 Troops.")
		return
	end
	if eng.attacker.locked and eng.defender.locked then
		resolveBattle(eng)
	else
		pushAllPlayers()
	end
end

function MilitaryService.IsMechanicallyResolved(warId: string): boolean
	local eng = engagements[warId]
	return eng ~= nil and eng.mechanicallyResolved == true
end

function MilitaryService.UnwindPreResolution(warId: string): (boolean, string)
	local eng = engagements[warId]
	if not eng then
		return true, "No military engagement."
	end
	if eng.mechanicallyResolved then
		return false, "War is already resolving."
	end
	returnSurvivors(eng)
	engagements[warId] = nil
	pushAllPlayers()
	return true, "Military commitments unwound."
end

function MilitaryService.OnWarCreated(war: any)
	if typeof(war) ~= "table" or typeof(war.warId) ~= "string" then
		return
	end
	if engagements[war.warId] then
		return
	end
	engagements[war.warId] = {
		warId = war.warId,
		attackerRootId = war.attackerRootId,
		defenderRootId = war.defenderRootId,
		targetTerritoryId = war.targetTerritoryId,
		startedAt = now(),
		attacker = { intended = nil, interacted = false, locked = false, lockedAmount = nil },
		defender = { intended = nil, interacted = false, locked = false, lockedAmount = nil },
		mechanicallyResolved = false,
		presentationUntil = nil,
		battle = nil,
		concluded = false,
	}
	pushAllPlayers()
end

function MilitaryService.Recruit(rulerId: string, troopAmount: any): (boolean, string)
	if totalByRuler[rulerId] == nil then
		return false, "No troop state."
	end
	if typeof(troopAmount) ~= "number" or troopAmount ~= troopAmount then
		return false, "Recruit amount must be a whole number."
	end
	if troopAmount ~= math.floor(troopAmount) then
		return false, "Recruit amount must be a whole number."
	end
	if troopAmount <= 0 then
		return false, "Recruit amount must be greater than 0."
	end
	if troopAmount < MilitaryConfig.TroopsPerGold then
		return false, "Minimum recruit is 3 Troops."
	end
	if troopAmount % MilitaryConfig.TroopsPerGold ~= 0 then
		return false, "Recruit amount must be a multiple of 3 Troops."
	end
	local goldCost = troopAmount / MilitaryConfig.TroopsPerGold
	local ok, err = Economy.TrySpend(rulerId, goldCost)
	if not ok then
		return false, err
	end
	totalByRuler[rulerId] += troopAmount
	pushAllPlayers()
	return true, string.format("Recruited %d Troops for %d Gold.", troopAmount, goldCost)
end

function MilitaryService.RecruitMax(rulerId: string): (boolean, string)
	if totalByRuler[rulerId] == nil then
		return false, "No troop state."
	end
	local gold = Economy.GetBalance(rulerId)
	if typeof(gold) ~= "number" or gold ~= gold or gold < 1 then
		return false, "Insufficient Gold."
	end
	local wholeGold = math.floor(gold)
	if wholeGold < 1 then
		return false, "Insufficient Gold."
	end
	return MilitaryService.Recruit(rulerId, wholeGold * MilitaryConfig.TroopsPerGold)
end

function MilitaryService.SetCommit(rulerId: string, warId: string, amountAny: any): (boolean, string)
	local eng = engagements[warId]
	if not eng or eng.concluded then
		return false, "No active engagement."
	end
	if eng.mechanicallyResolved then
		return false, "Battle is already resolving."
	end
	local side = sideFor(eng, rulerId)
	if not side then
		return false, "Only the war roots may commit Troops."
	end
	if side.locked then
		return false, "Commitment is locked."
	end
	if typeof(amountAny) ~= "number" or amountAny ~= amountAny then
		return false, "Commitment must be a whole number."
	end
	if amountAny ~= math.floor(amountAny) then
		return false, "Commitment must be a whole number."
	end
	if amountAny < 0 then
		return false, "Commitment cannot be negative."
	end
	local current = getReserved(warId, rulerId)
	local available = availableOf(rulerId) + current
	if amountAny > available then
		return false, "Not enough Available Troops."
	end
	if side.interacted == true and side.intended == amountAny and current == amountAny then
		return true, string.format("Commitment set to %d.", amountAny)
	end
	setReserved(warId, rulerId, amountAny)
	side.intended = amountAny
	side.interacted = true
	pushAllPlayers()
	return true, string.format("Commitment set to %d.", amountAny)
end

function MilitaryService.LockCommit(rulerId: string, warId: string): (boolean, string)
	local eng = engagements[warId]
	if not eng or eng.concluded then
		return false, "No active engagement."
	end
	if eng.mechanicallyResolved then
		return false, "Battle is already resolving."
	end
	local side = sideFor(eng, rulerId)
	if not side then
		return false, "Only the war roots may lock."
	end
	if side.locked then
		return false, "Already locked."
	end
	if not side.interacted or typeof(side.intended) ~= "number" then
		return false, "Submit a commitment first."
	end
	local amount = side.intended
	tryLock(eng, side, amount)
	if side == eng.attacker and amount <= 0 then
		return true, "Attack cancelled: you committed 0 Troops."
	end
	return true, "Forces locked."
end

function MilitaryService.GetInspect(rulerId: string)
	if totalByRuler[rulerId] == nil then
		return nil
	end
	return inspectPayload(rulerId)
end

function MilitaryService.GetEngagementInspect(warId: string)
	local eng = engagements[warId]
	if not eng then
		return nil
	end
	return {
		warId = eng.warId,
		targetTerritoryId = eng.targetTerritoryId,
		startedAt = eng.startedAt,
		now = now(),
		windowEndsAt = eng.startedAt + MilitaryConfig.CommitWindowSeconds,
		hardEndsAt = eng.startedAt + MilitaryConfig.HardTimeoutSeconds,
		attacker = {
			rulerId = eng.attackerRootId,
			intended = eng.attacker.intended,
			interacted = eng.attacker.interacted,
			locked = eng.attacker.locked,
			lockedAmount = eng.attacker.lockedAmount,
			reserved = getReserved(eng.warId, eng.attackerRootId),
		},
		defender = {
			rulerId = eng.defenderRootId,
			intended = eng.defender.intended,
			interacted = eng.defender.interacted,
			locked = eng.defender.locked,
			lockedAmount = eng.defender.lockedAmount,
			reserved = getReserved(eng.warId, eng.defenderRootId),
		},
		mechanicallyResolved = eng.mechanicallyResolved,
		presentationUntil = eng.presentationUntil,
		battle = eng.battle,
	}
end

function MilitaryService.DebugSetTroops(rulerId: string, value: number): (boolean, string)
	if totalByRuler[rulerId] == nil then
		return false, "No troop state."
	end
	if typeof(value) ~= "number" or value ~= value or value ~= math.floor(value) or value < 0 then
		return false, "Troops must be a whole number >= 0."
	end
	local committed = committedTotal(rulerId)
	if value < committed then
		return false, "Cannot set Total below currently committed Troops."
	end
	totalByRuler[rulerId] = value
	pushAllPlayers()
	return true, string.format("Troops set to %d.", value)
end

function MilitaryService.DebugAddTroops(rulerId: string, value: number): (boolean, string)
	if totalByRuler[rulerId] == nil then
		return false, "No troop state."
	end
	if typeof(value) ~= "number" or value ~= value or value ~= math.floor(value) then
		return false, "Need a whole number."
	end
	local nextTotal = totalByRuler[rulerId] + value
	if nextTotal < committedTotal(rulerId) then
		return false, "Cannot reduce Total below currently committed Troops."
	end
	if nextTotal < 0 then
		return false, "Troops cannot be negative."
	end
	totalByRuler[rulerId] = nextTotal
	pushAllPlayers()
	return true, string.format("Troops now %d.", nextTotal)
end

function MilitaryService.DebugSetSeed(seed: number): (boolean, string)
	if typeof(seed) ~= "number" then
		rngSeed = nil
		return true, "RNG seed cleared."
	end
	rngSeed = math.floor(seed)
	return true, "RNG seed set."
end

function MilitaryService.DebugSetDiag(enabled: boolean): (boolean, string)
	diagEnabled = enabled == true
	return true, if diagEnabled then "Diagnostics on." else "Diagnostics off."
end

local function stillOpen(eng: Engagement): boolean
	return engagements[eng.warId] == eng and not eng.concluded and not eng.mechanicallyResolved
end

local function tickEngagements()
	local t = now()
	local snapshot = {}
	for _, eng in engagements do
		table.insert(snapshot, eng)
	end
	for _, eng in snapshot do
		if not eng.concluded then
			if eng.mechanicallyResolved then
				if eng.presentationUntil and t >= eng.presentationUntil then
					concludeEngagement(eng)
				end
			else
				if t >= eng.startedAt + MilitaryConfig.CommitWindowSeconds then
					if not eng.attacker.locked and eng.attacker.interacted and typeof(eng.attacker.intended) == "number" then
						tryLock(eng, eng.attacker, eng.attacker.intended)
					end
					if stillOpen(eng) and not eng.defender.locked and eng.defender.interacted and typeof(eng.defender.intended) == "number" then
						tryLock(eng, eng.defender, eng.defender.intended)
					end
				end
				if stillOpen(eng) and t >= eng.startedAt + MilitaryConfig.HardTimeoutSeconds then
					if not eng.attacker.locked then
						cancelEngagement(eng, "attacker did not commit")
					elseif not eng.defender.locked then
						tryLock(eng, eng.defender, 0)
					end
				end
			end
		end
	end
end

function MilitaryService.DebugAdvance(seconds: number): (boolean, string)
	if typeof(seconds) ~= "number" or seconds ~= seconds then
		return false, "Need seconds."
	end
	for _, eng in engagements do
		eng.startedAt -= seconds
		if eng.presentationUntil then
			eng.presentationUntil -= seconds
		end
	end
	tickEngagements()
	pushAllPlayers()
	return true, "Advanced military timers."
end

local function onClientIntent(player: Player, action: any, a: any, b: any)
	if typeof(action) ~= "string" then
		noticePlayer(player, "Invalid request.")
		return
	end
	if action == "Ready" then
		pushPlayer(player)
		return
	end
	local fromId = Hierarchy.GetRulerIdForUserId(player.UserId)
	if not fromId then
		noticePlayer(player, "No ruler record.")
		return
	end
	if action == "Recruit" then
		local ok, result = MilitaryService.Recruit(fromId, a)
		noticePlayer(player, result)
		if not ok then
			return
		end
		return
	end
	if action == "RecruitMax" then
		local ok, result = MilitaryService.RecruitMax(fromId)
		noticePlayer(player, result)
		return
	end
	if action == "SetCommit" then
		if typeof(a) ~= "string" then
			noticePlayer(player, "Invalid war.")
			return
		end
		local ok, result = MilitaryService.SetCommit(fromId, a, b)
		if not ok then
			noticePlayer(player, result)
		end
		return
	end
	if action == "LockCommit" then
		if typeof(a) ~= "string" then
			noticePlayer(player, "Invalid war.")
			return
		end
		local ok, result = MilitaryService.LockCommit(fromId, a)
		noticePlayer(player, result)
		return
	end
	noticePlayer(player, "Unknown action.")
end

function MilitaryService.Start()
	if started then
		return
	end
	started = true

	local remotesFolder = ReplicatedStorage:WaitForChild("Remotes") :: Folder
	clientIntent = remotesFolder:WaitForChild("MilitaryClientEvent") :: RemoteEvent
	serverPush = remotesFolder:WaitForChild("MilitaryServerEvent") :: RemoteEvent
	clientIntent.OnServerEvent:Connect(onClientIntent)

	for _, ruler in Hierarchy.GetSnapshot().rulers do
		ensurePool(ruler.rulerId)
	end

	local debugFolder = ServerScriptService:FindFirstChild("MilitaryDebug")
	if debugFolder then
		debugFolder:Destroy()
	end
	debugFolder = Instance.new("Folder")
	debugFolder.Name = "MilitaryDebug"
	debugFolder.Parent = ServerScriptService
	local help = Instance.new("StringValue")
	help.Name = "Help"
	help.Value =
		"Invoke('Inspect'| 'SetTroops'| 'AddTroops'| 'InspectWar'| 'SelfTest'| 'SetSeed'| 'SetDiag', ...). Prefer AdminBridge/Kohl."
	help.Parent = debugFolder
	debugSnapshot = Instance.new("StringValue")
	debugSnapshot.Name = "LastSnapshot"
	debugSnapshot.Parent = debugFolder
	local invoke = Instance.new("BindableFunction")
	invoke.Name = "Invoke"
	invoke.Parent = debugFolder
	invoke.OnInvoke = function(action: any, a: any, b: any, c: any)
		if action == "Inspect" then
			local snap = MilitaryService.GetInspect(tostring(a))
			local encoded = if snap then HttpService:JSONEncode(snap) else "No troop state."
			print("[Military] debug Inspect", encoded)
			return snap ~= nil, encoded
		elseif action == "InspectWar" then
			local snap = MilitaryService.GetEngagementInspect(tostring(a))
			local encoded = if snap then HttpService:JSONEncode(snap) else "No engagement."
			print("[Military] debug InspectWar", encoded)
			return snap ~= nil, encoded
		elseif action == "SetTroops" then
			local ok, result = MilitaryService.DebugSetTroops(tostring(a), tonumber(b) or -1)
			print("[Military] debug SetTroops", ok, result)
			return ok, result
		elseif action == "AddTroops" then
			local ok, result = MilitaryService.DebugAddTroops(tostring(a), tonumber(b) or 0)
			print("[Military] debug AddTroops", ok, result)
			return ok, result
		elseif action == "SetSeed" then
			local ok, result = MilitaryService.DebugSetSeed(tonumber(a) or 0)
			print("[Military] debug SetSeed", ok, result)
			return ok, result
		elseif action == "SetDiag" then
			local ok, result = MilitaryService.DebugSetDiag(a == true or a == "true" or a == 1)
			print("[Military] debug SetDiag", ok, result)
			return ok, result
		elseif action == "SelfTest" then
			local ok, result = MilitaryCombat.SelfTest()
			print("[Military] SelfTest", ok, result)
			return ok, result
		elseif action == "Advance" then
			local ok, result = MilitaryService.DebugAdvance(tonumber(a) or 0)
			print("[Military] debug Advance", ok, result)
			return ok, result
		elseif action == "Recruit" then
			local amount = if typeof(b) == "number" then b else b
			local ok, result = MilitaryService.Recruit(tostring(a), amount)
			print("[Military] debug Recruit", ok, result)
			return ok, result
		elseif action == "RecruitMax" then
			local ok, result = MilitaryService.RecruitMax(tostring(a))
			print("[Military] debug RecruitMax", ok, result)
			return ok, result
		elseif action == "SetCommit" then
			local ok, result = MilitaryService.SetCommit(tostring(a), tostring(b), c)
			print("[Military] debug SetCommit", ok, result)
			return ok, result
		elseif action == "LockCommit" then
			local ok, result = MilitaryService.LockCommit(tostring(a), tostring(b))
			print("[Military] debug LockCommit", ok, result)
			return ok, result
		end
		return false, "Unknown action."
	end

	_G.__MilitaryV01 = MilitaryService

	Hierarchy.RulerCreated:Connect(function(rulerId: string)
		ensurePool(rulerId)
		pushAllPlayers()
	end)
	Hierarchy.RulerRemoving:Connect(function(rulerId: string)
		totalByRuler[rulerId] = nil
		for warId, byRuler in reserved do
			byRuler[rulerId] = nil
			if next(byRuler) == nil then
				reserved[warId] = nil
			end
		end
		pushAllPlayers()
	end)

	RunService.Heartbeat:Connect(tickEngagements)

	Players.PlayerAdded:Connect(function(player)
		task.defer(function()
			if player.Parent then
				pushPlayer(player)
			end
		end)
	end)

	pushAllPlayers()
	print("[Military] service started")
end

return MilitaryService
