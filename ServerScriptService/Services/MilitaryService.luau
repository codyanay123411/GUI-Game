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
local VassalCombat = require(ReplicatedStorage.Shared.Util.VassalCombat)
local Hierarchy = require(ServerScriptService.Services.PoliticalHierarchyService)
local Territory = require(ServerScriptService.Services.TerritoryMapService)
local Economy = require(ServerScriptService.Services.EconomyService)
local Warfare = require(ServerScriptService.Services.WarfareService)

local MatchState = require(script.Parent.MatchState)
local Neutral = require(script.Parent.NeutralDefenseService)
local Buildings = require(script.Parent.BuildingService)
local BuildingPolicy = require(ReplicatedStorage.Shared.Util.BuildingPolicy)
local BuildingConfig = require(ReplicatedStorage.Shared.Config.BuildingConfig)
local RecruitmentPolicy = require(ReplicatedStorage.Shared.Util.RecruitmentPolicy)
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
	attackerStrengthMultiplier: number?,
	defenderStrengthMultiplier: number?,
	concluded: boolean,
	travel: any?,
	entry: any?,
	resolvedAt: number?,
	castleSupport: number?,
	castleStrength: number?,
	castleAllocated: boolean?,
	nextTransportCheck: number?,
	targetKind: string,
	targetRevision: number,
}

local started = false
local totalByRuler: { [string]: number } = {}
local councilTotalChanged: ((string) -> ())? = nil
function MilitaryService.SetCouncilTotalChanged(callback: (string) -> ())
	assert(councilTotalChanged == nil, "Council troop observer already installed")
	councilTotalChanged = callback
end
local function notifyTotal(rulerId: string)
	if councilTotalChanged then councilTotalChanged(rulerId) end
end

function MilitaryService.GetTotalTroops(rulerId: string): number
	return totalByRuler[rulerId] or 0
end
local reserved: { [string]: { [string]: number } } = {} -- warId -> rulerId -> amount
local engagements: { [string]: Engagement } = {}
local supports: { [string]: { rulerId: string, amount: number } } = {}
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
		notifyTotal(rulerId)
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
	for _, support in supports do if support.rulerId == rulerId then sum += support.amount end end
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

local function supportTotal(rulerId: string): number
	local amount = 0
	for _, support in supports do if support.rulerId == rulerId then amount += support.amount end end
	return amount
end
local function allocateCastleSupport(eng: Engagement)
	if eng.castleAllocated then return end
	eng.castleAllocated = true
	local _, requirement = BuildingPolicy.Castle(Buildings.GetEffectiveLevel(eng.targetTerritoryId, "Castle"), 0)
	local amount = if eng.targetKind == "Player" then math.min(requirement, math.max(0, availableOf(eng.defenderRootId))) else 0
	eng.castleSupport = amount
	if amount > 0 then supports[eng.warId] = { rulerId = eng.defenderRootId, amount = amount } end
end
local function recruitmentRows(rulerId: string): any
	local rows = {}
	for _, id in Territory.GetOwnedTerritoryIds(rulerId) do
		table.insert(rows, { territoryId = id, townLevel = Buildings.GetEffectiveLevel(id, "Town"), priceTenths = Buildings.GetRecruitPriceTenths(id), ownershipRevision = Territory.GetOwnershipRevision(id) })
	end
	table.sort(rows, function(a,b) return a.territoryId < b.territoryId end)
	return rows
end

local function noticePlayer(player: Player, message: string)
	print("[Military] notice ->", player.Name, message)
	MatchState.Send(serverPush, player, "Notice", message)
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
			local opponentState = if eng.targetKind == "Unclaimed" then "Militia ready — lock your commitment" else "Opponent preparing forces"
			if mine.locked and not bothLocked then
				opponentState = "Waiting for opponent"
			end
			local row: any = {
				warId = eng.warId,
				targetTerritoryId = eng.targetTerritoryId,
				targetDisplayName = territoryName(eng.targetTerritoryId),
				role = role,
				ownCastleSupport = if role == "Defender" then eng.castleSupport else nil,
				ownCastleStrength = if role == "Defender" then eng.castleStrength else nil,
				ownResolvedStrengthMultiplier = if role == "Attacker" then eng.attackerStrengthMultiplier else eng.defenderStrengthMultiplier,
				targetKind = eng.targetKind,
				neutralDefenders = if eng.targetKind == "Unclaimed" then eng.defender.lockedAmount else nil,
				intended = if mine.interacted then mine.intended else nil,
				locked = mine.locked,
				windowEndsAt = eng.startedAt + MilitaryConfig.CommitWindowSeconds,
				hardEndsAt = eng.startedAt + MilitaryConfig.HardTimeoutSeconds,
				opponentState = if bothLocked then nil else opponentState,
				travel = eng.travel,
				visualResult = if eng.battle then { winner = eng.battle.winner, entry = eng.entry,
					attackerId = eng.attackerRootId, startedAt = eng.resolvedAt, endsAt = eng.presentationUntil } else nil,
				phase = if eng.travel then "travel" elseif eng.concluded
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
		combatBonuses = VassalCombat.Bonuses(rulerId, Hierarchy.GetSnapshot().rulers),
		cap = Buildings.GetArmyCap(rulerId),
		castleSupport = supportTotal(rulerId),
		recruitmentProvinces = recruitmentRows(rulerId),
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
		cap = Buildings.GetArmyCap(rulerId), castleSupport = supportTotal(rulerId),
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
			cap = BuildingConfig.BaseArmyCap, castleSupport = 0, recruitmentProvinces = {},
			wars = {},
		}
	end
	MatchState.Send(serverPush, player, "State", HttpService:JSONEncode(payload))
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
		notifyTotal(rulerId)
		setReserved(eng.warId, rulerId, survivors)
	end
	apply(eng.attackerRootId, battle.attackerCommitted, battle.attackerCasualties)
	apply(eng.defenderRootId, battle.defenderCommitted, battle.defenderCasualties)
end

local function returnSurvivors(eng: Engagement)
	setReserved(eng.warId, eng.attackerRootId, 0)
	setReserved(eng.warId, eng.defenderRootId, 0)
	reserved[eng.warId] = nil
	supports[eng.warId] = nil
end

local function pushBattleResult(rulerId: string, payload: any)
	local ruler = findRuler(rulerId)
	local userId = ruler and tonumber(ruler.userId)
	if typeof(userId) ~= "number" or userId == 0 then
		return
	end
	local player = Players:GetPlayerByUserId(userId)
	if player then
		MatchState.Send(serverPush, player, "BattleResult", HttpService:JSONEncode(payload))
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
			local attacker = findRuler(eng.attackerRootId)
			local staleNeutral = eng.targetKind == "Unclaimed" and (not Warfare.IsTargetCurrent(eng.warId) or not attacker or not Warfare.IsActorCurrent(eng.warId))
			if staleNeutral and role == "Attacker" then
				title = "BATTLE ENDED — TARGET NO LONGER AVAILABLE"
			elseif battle.unopposed then
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
				ownCastleStrength = if role == "Defender" then eng.castleStrength else nil,
				ownCastleSupport = if role == "Defender" then eng.castleSupport else nil,
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
	if not Warfare.IsTargetCurrent(eng.warId) or not Warfare.IsActorCurrent(eng.warId) then
		cancelEngagement(eng, "stale target")
		return
	end
	local rulers = Hierarchy.GetSnapshot().rulers
	local attackerBonus = VassalCombat.Bonuses(eng.attackerRootId, rulers)
	local defenderBonus = VassalCombat.Bonuses(eng.defenderRootId, rulers)
	eng.attackerStrengthMultiplier = VassalCombat.Multiplier(attackerBonus, false, false)
	local _, attackCapital = BuildingPolicy.Capital(Buildings.GetCapitalLevel(eng.attackerRootId))
	if Warfare.HasPersonalAttackOrigin(eng.warId) then eng.attackerStrengthMultiplier *= 1 + attackCapital end
	local ownDefense = Territory.GetOwnerRulerId(eng.targetTerritoryId) == eng.defenderRootId
	local defenseCapital, combatCapital = BuildingPolicy.Capital(Buildings.GetCapitalLevel(eng.defenderRootId))
	eng.defenderStrengthMultiplier = VassalCombat.Multiplier(defenderBonus, true,
		Territory.GetOwnerRulerId(eng.targetTerritoryId) == eng.defenderRootId)
	if ownDefense then eng.defenderStrengthMultiplier *= (1 + defenseCapital) * (1 + combatCapital) end
	allocateCastleSupport(eng)
	local castle = BuildingPolicy.Castle(Buildings.GetEffectiveLevel(eng.targetTerritoryId, "Castle"), eng.castleSupport or 0)
	eng.castleStrength = castle
	local combatCastle = castle
	if not ownDefense then
		local owner = Territory.GetOwnerRulerId(eng.targetTerritoryId)
		if owner then
			local localDefense, localCombat = BuildingPolicy.Capital(Buildings.GetCapitalLevel(owner))
			combatCastle *= (1 + localDefense) * (1 + localCombat)
		end
	end
	local battle = MilitaryCombat.Resolve(atk, def, makeRng(), eng.attackerStrengthMultiplier, eng.defenderStrengthMultiplier, combatCastle)
	eng.battle = battle
	eng.mechanicallyResolved = true
	eng.resolvedAt = now()
	eng.presentationUntil = eng.resolvedAt + MilitaryConfig.PresentationSeconds
	applyCasualties(eng, battle)
	if eng.targetKind == "Unclaimed" then Neutral.ApplySurvivors(eng.targetTerritoryId, eng.targetRevision, battle.defenderSurvivors) end
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

function MilitaryService.FreezeMatch()
	for _, eng in engagements do returnSurvivors(eng) end
	table.clear(engagements)
	table.clear(reserved)
	table.clear(supports)
	pushAllPlayers()
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
		travel = war.travel, entry = war.entry,
		attacker = { intended = nil, interacted = false, locked = false, lockedAmount = nil },
		defender = if war.targetKind == "Unclaimed"
			then { intended = war.neutralDefenders, interacted = true, locked = true, lockedAmount = war.neutralDefenders }
			else { intended = nil, interacted = false, locked = false, lockedAmount = nil },
		targetKind = war.targetKind or "Player",
		targetRevision = war.targetRevision or 0,
		mechanicallyResolved = false,
		presentationUntil = nil,
		battle = nil,
		concluded = false,
	}
	if not war.travel then allocateCastleSupport(engagements[war.warId]) end
	pushAllPlayers()
end

function MilitaryService.LaunchTransport(rulerId: string, warId: string, amount: number): (boolean, string)
	local eng = engagements[warId]
	if not eng or not eng.travel or eng.attackerRootId ~= rulerId then return false, "No transport engagement." end
	-- Same ledger/validation as ordinary commits; only this server launch path may
	-- reserve before arrival, and it never calls tryLock (militia could resolve early).
	if MatchState.IsEnded() or typeof(amount) ~= "number" or amount ~= amount or amount % 1 ~= 0 or amount <= 0 or amount > availableOf(rulerId) then return false, "Invalid transport commitment." end
	setReserved(warId, rulerId, amount)
	eng.attacker.intended = amount;eng.attacker.interacted = true
	eng.attacker.locked = true;eng.attacker.lockedAmount = amount
	pushAllPlayers()
	return true, "Transport force locked."
end

function MilitaryService.Recruit(rulerId: string, troopAmount: any, provinceId: any?, revision: any?, expectedTown: any?): (boolean, string)
	if MatchState.IsEnded() then return false, "Match ended." end
	if totalByRuler[rulerId] == nil then return false, "No troop state." end
	if typeof(troopAmount) ~= "number" or troopAmount ~= troopAmount or troopAmount <= 0 or troopAmount == math.huge or troopAmount % BuildingConfig.RecruitBatchTroops ~= 0 then return false, "Recruit in whole 10-Troop batches." end
	-- Legacy server/debug calls use a deterministic personal province; ordinary requests must supply selection.
	if provinceId == nil then local rows = recruitmentRows(rulerId); provinceId = if rows[1] then rows[1].territoryId else nil end
	if typeof(provinceId) ~= "string" or Territory.GetOwnerRulerId(provinceId) ~= rulerId then return false, "Select a personally owned recruitment province." end
	if revision ~= nil and revision ~= Territory.GetOwnershipRevision(provinceId) then return false, "Recruitment province changed. Review again." end
	local town = Buildings.GetEffectiveLevel(provinceId, "Town")
	if expectedTown ~= nil and expectedTown ~= town then return false, "Local Town price changed. Review again." end
	local cap = Buildings.GetArmyCap(rulerId)
	if troopAmount > math.max(0, cap - totalByRuler[rulerId]) then return false, "Insufficient army capacity; existing over-cap troops are retained." end
	local goldCost = troopAmount / BuildingConfig.RecruitBatchTroops * Buildings.GetRecruitPriceTenths(provinceId) / 10
	local ok, err = Economy.TrySpend(rulerId, goldCost)
	if not ok then return false, err end
	totalByRuler[rulerId] += troopAmount
	notifyTotal(rulerId); pushAllPlayers()
	return true, string.format("Recruited %d Troops for %g Gold through %s.", troopAmount, goldCost, territoryName(provinceId))
end

function MilitaryService.RecruitMax(rulerId: string, provinceId: any?): (boolean, string)
	if provinceId == nil then local rows = recruitmentRows(rulerId); provinceId = if rows[1] then rows[1].territoryId else nil end
	if typeof(provinceId) ~= "string" or Territory.GetOwnerRulerId(provinceId) ~= rulerId then return false, "Personal recruitment province required." end
	local _, amount = RecruitmentPolicy.Preview(Economy.GetBalance(rulerId),100,MilitaryService.GetTotalTroops(rulerId),Buildings.GetArmyCap(rulerId),Buildings.GetLevel(provinceId,"Town"))
	if amount == 0 then return false, "No affordable whole batch or army room." end
	return MilitaryService.Recruit(rulerId, amount, provinceId)
end

function MilitaryService.StageTroopTransfer(fromId: string, toId: string, amount: number): (boolean, string)
	if MatchState.IsEnded() then return false, "Match ended." end
	if fromId == toId or totalByRuler[fromId] == nil or totalByRuler[toId] == nil then return false, "Invalid troop owners." end
	if amount ~= amount or math.abs(amount) == math.huge or amount < 0 or amount % 1 ~= 0 then return false, "Invalid transfer amount." end
	if availableOf(fromId) < amount then return false, "Transfer would take reserved troops." end
	totalByRuler[fromId] -= amount
	totalByRuler[toId] += amount
	return true, ""
end
function MilitaryService.PublishTroopTransfer(fromId: string, toId: string)
	notifyTotal(fromId); notifyTotal(toId)
	pushAllPlayers()
end

function MilitaryService.SetCommit(rulerId: string, warId: string, amountAny: any): (boolean, string)
	if MatchState.IsEnded() then return false, "Match ended." end
	local eng = engagements[warId]
	if not eng or eng.concluded then
		return false, "No active engagement."
	end
	if eng.travel then return false, "Transport in transit. Defense window starts on arrival." end
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
	if MatchState.IsEnded() then return false, "Match ended." end
	local eng = engagements[warId]
	if not eng or eng.concluded then
		return false, "No active engagement."
	end
	if eng.travel then return false, "Transport in transit. Defense window starts on arrival." end
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
		travel = eng.travel,
		entry = eng.entry,
		castleSupport = eng.castleSupport, castleStrength = eng.castleStrength,
		mechanicallyResolved = eng.mechanicallyResolved,
		presentationUntil = eng.presentationUntil,
		battle = eng.battle,
	}
end

function MilitaryService.DebugSetTroops(rulerId: string, value: number): (boolean, string)
	if MatchState.IsEnded() then return false, "Match ended." end
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
	notifyTotal(rulerId)
	pushAllPlayers()
	return true, string.format("Troops set to %d.", value)
end

function MilitaryService.DebugAddTroops(rulerId: string, value: number): (boolean, string)
	if MatchState.IsEnded() then return false, "Match ended." end
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
	notifyTotal(rulerId)
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

local retired: { [string]: number } = {}
function MilitaryService.GetRetiredTroops(id: string): number return retired[id] or 0 end
function MilitaryService.RetireEliminated(id: string)
	if retired[id] ~= nil then return end
	local snapshot = {};for _, eng in engagements do table.insert(snapshot, eng) end
	for _, eng in snapshot do
		if eng.attackerRootId == id or eng.defenderRootId == id then
			if eng.mechanicallyResolved then returnSurvivors(eng)
			else cancelEngagement(eng, "Capital owner eliminated") end
		end
	end
	retired[id] = totalByRuler[id] or 0
	-- Removal from the active pool follows hierarchy lifecycle; retirement preserves surviving units.
end

local function tickEngagements()
	if MatchState.IsEnded() then return end
	local t = now()
	local snapshot = {}
	for _, eng in engagements do
		table.insert(snapshot, eng)
	end
	table.sort(snapshot, function(a,b)
		local at = if a.travel then a.travel.arrivesAt else a.startedAt
		local bt = if b.travel then b.travel.arrivesAt else b.startedAt
		local af = if a.mechanicallyResolved then a.presentationUntil or at else at
		local bf = if b.mechanicallyResolved then b.presentationUntil or bt else bt
		return if af == bf then a.warId < b.warId else af < bf
	end)
	local Victory = require(script.Parent.VictoryService)
	Victory.BeginCaptureBatch()
	for _, eng in snapshot do
		if MatchState.IsEnded() then break end
		if not eng.concluded then
			if eng.travel then
				if eng.nextTransportCheck and t < eng.nextTransportCheck then continue end
				eng.nextTransportCheck = t + 0.25
				local valid, reason = Warfare.IsTransportCurrent(eng.warId)
				if not valid then cancelEngagement(eng, reason);continue end
				if t < eng.travel.arrivesAt then continue end
				eng.travel = nil;eng.startedAt = t
				allocateCastleSupport(eng)
				Buildings.NavalLanded(eng.targetTerritoryId)
				Warfare.TransportArrived(eng.warId)
				noticeRulerId(eng.defenderRootId, "Transport arrived. Your normal defense decision window starts now.")
				if eng.defender.locked then resolveBattle(eng) else pushAllPlayers() end
				continue
			end
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
	Victory.EndCaptureBatch()
end

function MilitaryService.DebugAdvance(seconds: number): (boolean, string)
	if typeof(seconds) ~= "number" or seconds ~= seconds then
		return false, "Need seconds."
	end
	for _, eng in engagements do
		eng.startedAt -= seconds
		if eng.travel then eng.travel.arrivesAt -= seconds;eng.travel.launchedAt -= seconds;eng.nextTransportCheck = nil end
		if eng.presentationUntil then
			eng.presentationUntil -= seconds
		end
	end
	tickEngagements()
	pushAllPlayers()
	return true, "Advanced military timers."
end

-- Optional correlated recruitment receipts. Legacy server/admin calls retain their API.
local lastRecruitReceipt: { [Player]: any } = {}
local function sendRecruitReceipt(player: Player, requestId: any, amount: any, ok: boolean, message: string)
	local receipt = { requestId = requestId, amount = amount, accepted = ok, message = message }
	MatchState.Send(serverPush, player, "RecruitResult", HttpService:JSONEncode(receipt))
	return receipt
end

local function onClientIntent(player: Player, action: any, a: any, b: any, c: any, d: any, e: any)
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
		if action == "Recruit" and typeof(b) == "number" and b == b and b >= 1 and b <= 2147483647 and b % 1 == 0 then sendRecruitReceipt(player, b, nil, false, "No ruler record.") end
		noticePlayer(player, "No ruler record.")
		return
	end
	if action == "Recruit" then
		if b ~= nil then
			if typeof(b) ~= "number" or b ~= b or b < 1 or b > 2147483647 or b % 1 ~= 0 then
				noticePlayer(player, "Invalid recruitment request.")
				return
			end
			local previous = lastRecruitReceipt[player]
			if previous and b <= previous.requestId then
				if b == previous.requestId and a == previous.amount and c == previous.provinceId and d == previous.revision and e == previous.townLevel then
					MatchState.Send(serverPush, player, "RecruitResult", HttpService:JSONEncode(previous))
				else
					sendRecruitReceipt(player, b, nil, false, "Outdated recruitment request. Try again.")
				end
				return
			end
		end
		local validSelection = typeof(c) == "string" and typeof(d) == "number" and typeof(e) == "number"
		local ok, result = false, "Select a current personal recruitment province."
		if validSelection then ok, result = MilitaryService.Recruit(fromId, a, c, d, e) end
		if b ~= nil then
			local receipt = sendRecruitReceipt(player, b, if typeof(a) == "number" and a == a and math.abs(a) < math.huge then a else nil, ok, result)
			receipt.provinceId = if typeof(c) == "string" then c else nil
			receipt.revision = if typeof(d) == "number" and d == d and math.abs(d) < math.huge then d else nil
			receipt.townLevel = if typeof(e) == "number" and e == e and math.abs(e) < math.huge then e else nil
			lastRecruitReceipt[player] = receipt
		end
		noticePlayer(player, result)
		if not ok then
			return
		end
		return
	end
	if action == "RecruitMax" then
		local ok, result = false, "Select a personally owned recruitment province."
		if typeof(a) == "string" then ok, result = MilitaryService.RecruitMax(fromId, a) end
		noticePlayer(player, result)
		return
	end
	if action == "SetCommit" then
		if typeof(a) ~= "string" then
			noticePlayer(player, "Invalid war.")
			return
		end
		local ok, result = MilitaryService.SetCommit(fromId, a, b)
		-- Receipt only: existing validated integer intent remains the sole mutation path.
		MatchState.Send(serverPush, player, "CommitResult", HttpService:JSONEncode({
			warId = a, amount = if typeof(b) == "number" and b == b and math.abs(b) < math.huge then b else nil, accepted = ok, message = result,
		}))
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
	MatchState.ConnectIntent(clientIntent, onClientIntent)
	Buildings.Changed:Connect(pushAllPlayers)
	Territory.OwnershipChanged:Connect(pushAllPlayers)
	Players.PlayerRemoving:Connect(function(player) lastRecruitReceipt[player] = nil end)

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
		notifyTotal(rulerId)
		for warId, byRuler in reserved do
			byRuler[rulerId] = nil
			if next(byRuler) == nil then
				reserved[warId] = nil
			end
		end
		for warId, support in supports do if support.rulerId == rulerId then supports[warId] = nil end end
		pushAllPlayers()
	end)

	Hierarchy.StateChanged:Connect(pushAllPlayers)
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

function MilitaryService.PublishMatch() pushAllPlayers() end

function MilitaryService.ResetMatch()
	assert(MatchState.IsResetting())
	totalByRuler, reserved, supports, engagements, lastRecruitReceipt = {}, {}, {}, {}, {};retired = {}
	rngSeed, diagEnabled = nil, false
	for _, ruler in Hierarchy.GetSnapshot().rulers do ensurePool(ruler.rulerId) end
end

return MilitaryService
