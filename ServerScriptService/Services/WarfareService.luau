--!strict

--[[
	Warfare / Conquest V0.1.

	Server-authoritative wars by independent or permitted/autonomous actors.
	One enemy-controlled territory per war. Military / Armies V0.1 owns
	Troops and battle; this service owns lifecycle, contest/cooldown, and
	Attacker/Defender outcome application. Privileged DebugResolveWar remains.
]]

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Hierarchy = require(ServerScriptService.Services.PoliticalHierarchyService)
local Territory = require(ServerScriptService.Services.TerritoryMapService)
local Diplomacy = require(ServerScriptService.Services.DiplomacyService)
local WarfareAdjacency = require(ReplicatedStorage.Shared.Util.WarfareAdjacency)

local MatchState = require(script.Parent.MatchState)
local Neutral = require(script.Parent.NeutralDefenseService)
local Domain = require(ReplicatedStorage.Shared.Util.PoliticalDomain)
local Routes = require(ReplicatedStorage.Shared.Util.NavalRoutes)
local Geometry = require(ReplicatedStorage.Shared.Util.MapGeometry)
local MilitaryConfig = require(ReplicatedStorage.Shared.Config.MilitaryConfig)
local Permissions = require(script.Parent.PoliticalPermissionsService)
local WarfareService = {}

type War = {
	warId: string,
	attackerRootId: string,
	defenderRootId: string,
	targetTerritoryId: string,
	status: string,
	targetKind: string,
	targetRevision: number,
	neutralDefenders: number?,
	actorDomain: string,
	defenderDomain: string,
	travel: any?,
	entry: any?,
	originTerritoryId: string?,
}

local started = false
local warsById: { [string]: War } = {}
local cooldownUntil: { [string]: number } = {}
local clientIntent: RemoteEvent
local serverPush: RemoteEvent
local debugSnapshot: StringValue?
local TERRITORY_COOLDOWN_SECONDS = 10

local function militaryModule()
	return require(ServerScriptService.Services.MilitaryService)
end

local function serverNow(): number
	return workspace:GetServerTimeNow()
end

local function pruneCooldown(territoryId: string)
	local untilAt = cooldownUntil[territoryId]
	if untilAt ~= nil and serverNow() >= untilAt then
		cooldownUntil[territoryId] = nil
	end
end

local function isTerritoryOnCooldown(territoryId: string): boolean
	pruneCooldown(territoryId)
	return cooldownUntil[territoryId] ~= nil
end

local function beginTerritoryCooldown(territoryId: string)
	cooldownUntil[territoryId] = serverNow() + TERRITORY_COOLDOWN_SECONDS
end

local function activeWarOnTerritory(territoryId: string): War?
	for _, war in warsById do
		if war.status == "Active" and war.targetTerritoryId == territoryId then
			return war
		end
	end
	return nil
end

local function findRuler(rulerId: string): any?
	for _, ruler in Hierarchy.GetSnapshot().rulers do
		if ruler.rulerId == rulerId then
			return ruler
		end
	end
	return nil
end

local function isIndependentRoot(ruler: any?): boolean
	return ruler ~= nil and ruler.independent == true
end

local function greaterRealmRulerIds(rootId: string): { string }
	local root = findRuler(rootId)
	if not root then
		return {}
	end
	local byId: { [string]: any } = {}
	for _, ruler in Hierarchy.GetSnapshot().rulers do
		if typeof(ruler.rulerId) == "string" then
			byId[ruler.rulerId] = ruler
		end
	end
	local ids = { rootId }
	local seen: { [string]: boolean } = { [rootId] = true }
	local queue = { rootId }
	local i = 1
	while i <= #queue do
		local current = byId[queue[i]]
		i += 1
		if current and typeof(current.vassalIds) == "table" then
			for _, vassalId in current.vassalIds do
				if typeof(vassalId) == "string" and seen[vassalId] ~= true then
					seen[vassalId] = true
					table.insert(ids, vassalId)
					table.insert(queue, vassalId)
				end
			end
		end
	end
	if typeof(root.descendantIds) == "table" then
		for _, id in root.descendantIds do
			if typeof(id) == "string" and seen[id] ~= true then
				seen[id] = true
				table.insert(ids, id)
			end
		end
	end
	return ids
end

local function ownerRootId(territoryId: string): string?
	local ownerId = Territory.GetOwnerRulerId(territoryId)
	if not ownerId then
		return nil
	end
	local owner = findRuler(ownerId)
	if not owner then
		return nil
	end
	if typeof(owner.rootRulerId) == "string" and owner.rootRulerId ~= "" then
		return owner.rootRulerId
	end
	return ownerId
end

local function isOwnedByRealm(territoryId: string, rootId: string): boolean
	local ownerId = Territory.GetOwnerRulerId(territoryId)
	if not ownerId then
		return false
	end
	for _, memberId in greaterRealmRulerIds(rootId) do
		if memberId == ownerId then
			return true
		end
	end
	return false
end

local function ownedByGreaterRealm(rootId: string): { string }
	local owned = {}
	for _, memberId in greaterRealmRulerIds(rootId) do
		for _, territoryId in Territory.GetOwnedTerritoryIds(memberId) do
			table.insert(owned, territoryId)
		end
	end
	return owned
end

local function isGreaterRealmAdjacent(attackerRootId: string, targetTerritoryId: string): boolean
	local mapDef = Territory.GetMapDefinition()
	return WarfareAdjacency.IsTargetAdjacentToOwned(mapDef.territories, targetTerritoryId, ownedByGreaterRealm(attackerRootId))
end

local function noticePlayer(player: Player, message: string)
	print("[Warfare] notice ->", player.Name, message)
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

local function buildSnapshot()
	local wars = {}
	for _, war in warsById do
		if war.status == "Active" then
			table.insert(wars, {
				warId = war.warId,
				attackerRootId = war.attackerRootId,
				attackerDomainId = war.attackerRootId,
				defenderDomainId = war.defenderRootId,
				defenderRootId = war.defenderRootId,
				targetTerritoryId = war.targetTerritoryId,
				status = war.status,
				travel = war.travel,
				targetKind = war.targetKind,
				neutralDefenders = war.neutralDefenders,
			})
		end
	end
	table.sort(wars, function(a, b)
		return a.warId < b.warId
	end)
	local cooldowns = {}
	for territoryId, untilAt in cooldownUntil do
		pruneCooldown(territoryId)
		local remaining = cooldownUntil[territoryId]
		if remaining ~= nil then
			table.insert(cooldowns, {
				territoryId = territoryId,
				endsAt = remaining,
			})
		end
	end
	table.sort(cooldowns, function(a, b)
		return a.territoryId < b.territoryId
	end)
	return { wars = wars, cooldowns = cooldowns }
end

local function pushState(toPlayer: Player?)
	local payload = buildSnapshot()
	local encoded = HttpService:JSONEncode(payload)
	if debugSnapshot then
		debugSnapshot.Value = encoded
	end
	if toPlayer then
		print("[Warfare] push State to", toPlayer.Name)
		MatchState.Send(serverPush, toPlayer, "State", encoded)
	else
		print("[Warfare] push State all clients wars=", #payload.wars)
		MatchState.Send(serverPush, nil, "State", encoded)
	end
end

local function endWar(war: War, reason: string)
	if war.status ~= "Active" then
		return
	end
	war.status = "Resolved"
	warsById[war.warId] = nil
	beginTerritoryCooldown(war.targetTerritoryId)
	print("[Warfare] ended", war.warId, reason)
end

local function targetStillOriginalDefender(war: War): boolean
	if war.targetKind == "Unclaimed" then
		return Territory.GetOwnerRulerId(war.targetTerritoryId) == nil and Territory.GetOwnershipRevision(war.targetTerritoryId) == war.targetRevision
	end
	return Domain.Contains(Hierarchy.GetSnapshot().rulers, war.defenderRootId, Territory.GetOwnerRulerId(war.targetTerritoryId) or "")
		and war.defenderDomain == Domain.Signature(Hierarchy.GetSnapshot().rulers, war.defenderRootId)
end

function WarfareService.GetSnapshot()
	return buildSnapshot()
end

function WarfareService.CheckDeclaration(attackerRootId: string, targetTerritoryId: string, betrayalLiege: string?, navalDeparture: string?): (boolean, any)
	if MatchState.IsEnded() then return false, "Match ended." end
	if typeof(targetTerritoryId) ~= "string" or targetTerritoryId == "" then
		return false, "Cannot declare war: invalid target."
	end
	local attacker = findRuler(attackerRootId)
	local admitted, reason = Permissions.Can(attackerRootId, "War")
	if not admitted then return false, reason end
	local mapDef = Territory.GetMapDefinition()
	local exists = false
	for _, t in mapDef.territories do
		if t.id == targetTerritoryId and t.conquerable ~= false then
			exists = true
			break
		end
	end
	if not exists then
		return false, "Cannot declare war: unknown territory."
	end
	local ownerId = Territory.GetOwnerRulerId(targetTerritoryId)
	local neutral = if not ownerId then Neutral.Get(targetTerritoryId) else nil
	if isOwnedByRealm(targetTerritoryId, attackerRootId) or (not betrayalLiege and ownerId and ownerRootId(targetTerritoryId) == attacker.rootRulerId) then
		return false, "Cannot declare war: target belongs to your realm."
	end
	local defenderRoot = betrayalLiege or ownerRootId(targetTerritoryId) or ""
	if betrayalLiege and (not ownerId or not Domain.Contains(Hierarchy.GetSnapshot().rulers, betrayalLiege, ownerId)) then return false, "Target is outside the direct liege's domain." end
	local defender = findRuler(defenderRoot)
	if not neutral and not defender then
		return false, "Cannot declare war: defender is no longer available."
	end
	local route = nil
	if navalDeparture then
		if isGreaterRealmAdjacent(attackerRootId, targetTerritoryId) then return false, "Land access takes priority; use ordinary war/conquest." end
		if betrayalLiege then return false, "Naval betrayal is outside this transport action." end
		if Territory.GetOwnerRulerId(navalDeparture) ~= attackerRootId then return false, "Departure must be personally owned." end
		route = Routes.Find(mapDef, navalDeparture, targetTerritoryId)
		if not route then return false, "No valid straight water route between these coasts." end
	elseif not isGreaterRealmAdjacent(attackerRootId, targetTerritoryId) then
		return false, "Cannot declare war: target not adjacent."
	end
	if not neutral and Diplomacy.HasNonAggressionPact(attackerRootId, ownerId) then
		return false, "Cannot declare war: Non-Aggression Pact active."
	end
	if activeWarOnTerritory(targetTerritoryId) then
		return false, "Territory is already contested."
	end
	if isTerritoryOnCooldown(targetTerritoryId) then
		return false, "Territory is on post-war cooldown."
	end
	for _, war in warsById do
		if war.status == "Active" and war.attackerRootId == attackerRootId and war.targetTerritoryId == targetTerritoryId then
			return false, "Cannot declare war: a matching war is already active."
		end
	end
	return true, { defenderId = defenderRoot, neutral = neutral, route = route }
end

local function createWar(attackerRootId: string, targetTerritoryId: string, betrayalLiege: string?, navalDeparture: string?, navalAmount: number?): (boolean, string)
	local valid, details = WarfareService.CheckDeclaration(attackerRootId, targetTerritoryId, betrayalLiege, navalDeparture)
	if not valid then return false, details end
	local defenderRoot, neutral = details.defenderId, details.neutral
	local entry = nil
	local origin = navalDeparture
	if details.route then entry = details.route.entry else
		local map = Territory.GetMapDefinition(); local byId = {};for _, t in map.territories do byId[t.id] = t end
		for _, id in greaterRealmRulerIds(attackerRootId) do
			for _, land in Territory.GetOwnedTerritoryIds(id) do
				if table.find(byId[land].adjacentIds, targetTerritoryId) then origin = land;entry = Geometry.SharedEntry(byId[land], byId[targetTerritoryId]);break end
			end
			if origin then break end
		end
	end
	local travel = nil
	if details.route then
		local at = workspace:GetServerTimeNow()
		travel = { departureId = navalDeparture, departureRevision = Territory.GetOwnershipRevision(navalDeparture),
			from = details.route.from, to = details.route.to, launchedAt = at, arrivesAt = at + Routes.TravelSeconds(details.route, MilitaryConfig) }
	end

	local warId = HttpService:GenerateGUID(false)
	local created: War = {
		warId = warId,
		attackerRootId = attackerRootId,
		defenderRootId = defenderRoot,
		targetTerritoryId = targetTerritoryId,
		status = "Active",
		targetKind = if neutral then "Unclaimed" else "Player",
		targetRevision = Territory.GetOwnershipRevision(targetTerritoryId),
		neutralDefenders = if neutral then neutral.current else nil,
		travel = travel, entry = entry, originTerritoryId = origin,
		actorDomain = Domain.Signature(Hierarchy.GetSnapshot().rulers, attackerRootId),
		defenderDomain = if defenderRoot ~= "" then Domain.Signature(Hierarchy.GetSnapshot().rulers, defenderRoot) else "",
	}
	warsById[warId] = created
	militaryModule().OnWarCreated(created)
	if navalAmount then
		local launched, errorMessage = militaryModule().LaunchTransport(attackerRootId, warId, navalAmount)
		if not launched then militaryModule().UnwindPreResolution(warId);warsById[warId] = nil;return false, errorMessage end
	end
	pushState()
	noticeRulerId(attackerRootId, if travel then "Transport launched. Troops reserved and locked until arrival." elseif neutral then "Conquest begun. Commit Troops in Military." else "War declared.")
	noticeRulerId(defenderRoot, if travel then "Naval attack launched against your realm. Your defense window starts on arrival." else "War declared against your realm.")
	return true, warId
end

function WarfareService.DeclareWar(attackerRootId: string, targetTerritoryId: string, betrayalLiege: string?): (boolean, string)
	return createWar(attackerRootId, targetTerritoryId, betrayalLiege, nil, nil)
end

local navalReceipts: { [string]: any } = {}
function WarfareService.LaunchNaval(actor: string, target: string, amount: any, requestId: any): (boolean, string)
	if MatchState.IsEnded() then return false, "Match ended." end
	if typeof(requestId) ~= "string" or #requestId < 1 or #requestId > 80 then return false, "Invalid transport request." end
	local receipts = navalReceipts[actor] or {}
	navalReceipts[actor] = receipts
	local previous = receipts[requestId]
	if previous and previous.requestId == requestId then
		if previous.target ~= target or previous.amount ~= amount then return false, "Transport request changed." end
		return true, previous.warId
	end
	local pool = militaryModule().GetInspect(actor)
	if not pool or typeof(amount) ~= "number" or amount ~= amount or amount == math.huge or amount % 1 ~= 0 or amount <= 0 or amount > pool.available then return false, "Need positive whole available troops for launch." end
	local route = Routes.Closest(Territory.GetMapDefinition(), Territory.GetOwnedTerritoryIds(actor), target)
	if not route then return false, "No personally owned coast with a clear water route." end
	local departure = route.departureId
	local ok, result = createWar(actor, target, nil, departure, amount)
	if ok then receipts[requestId] = { requestId = requestId, departure = departure, target = target, amount = amount, warId = result } end
	return ok, result
end

function WarfareService.IsTransportCurrent(warId: string): (boolean, string)
	local war = warsById[warId]
	if not war or not war.travel then return false, "Transport no longer active" end
	if not WarfareService.IsActorCurrent(warId) or not targetStillOriginalDefender(war) then return false, "Political domain or target changed" end
	if Territory.GetOwnerRulerId(war.travel.departureId) ~= war.attackerRootId
		or Territory.GetOwnershipRevision(war.travel.departureId) ~= war.travel.departureRevision then return false, "Departure ownership changed" end
	if Territory.GetOwnershipRevision(war.targetTerritoryId) ~= war.targetRevision then return false, "Landing ownership changed" end
	local eligible, reason = Permissions.Can(war.attackerRootId, "War")
	if not eligible then return false, reason end
	local targetOwner = Territory.GetOwnerRulerId(war.targetTerritoryId)
	if targetOwner and Diplomacy.HasNonAggressionPact(war.attackerRootId, targetOwner) then return false, "Non-Aggression Pact blocks landing" end
	return true, ""
end

function WarfareService.TransportArrived(warId: string)
	local war = warsById[warId]
	if war then war.travel = nil;pushState() end
end

function WarfareService.CancelWar(warId: string, reason: string)
	local war = warsById[warId]
	if not war or war.status ~= "Active" then
		return
	end
	-- Cancellation must release all pre-resolution commitments/backing through their owner.
	local unwound = militaryModule().UnwindPreResolution(warId)
	if not unwound then return end -- Calculated results retain their existing lifecycle.
	local attacker = war.attackerRootId
	local defender = war.defenderRootId
	endWar(war, reason)
	pushState()
	noticeRulerId(attacker, "War cancelled (" .. reason .. ").")
	noticeRulerId(defender, "War cancelled (" .. reason .. ").")
end

function WarfareService.ApplyMilitaryOutcome(warId: string, outcome: string): (boolean, string)
	if MatchState.IsEnded() then return false, "Match ended." end
	local war = warsById[warId]
	if not war or war.status ~= "Active" then
		return false, "War is no longer active."
	end
	if outcome ~= "Attacker" and outcome ~= "Defender" then
		return false, "Unknown resolution."
	end
	if war.targetKind == "Unclaimed" and (not targetStillOriginalDefender(war) or not WarfareService.IsActorCurrent(war.warId)) then
		endWar(war, "stale neutral conquest")
		pushState()
		return false, "Conquest stale; no transfer."
	end
	if outcome == "Defender" then
		local attacker = war.attackerRootId
		local defender = war.defenderRootId
		endWar(war, "defender victory")
		pushState()
		noticeRulerId(attacker, "War ended: defender victory. Ownership unchanged.")
		noticeRulerId(defender, "War ended: defender victory. Ownership unchanged.")
		return true, "Defender victory."
	end
	if not WarfareService.IsActorCurrent(warId) then
		endWar(war, "attacker domain stale");pushState();return false, "Attacker domain changed; no capture."
	end
	local attackerId = war.attackerRootId
	local defenderId = war.defenderRootId
	local targetId = war.targetTerritoryId
	if not targetStillOriginalDefender(war) then
		endWar(war, "attacker victory stale target")
		pushState()
		noticeRulerId(attackerId, "War ended: attacker victory. Target no longer belongs to the original defender.")
		noticeRulerId(defenderId, "War ended: attacker victory. Target no longer belongs to the original defender.")
		return true, "Attacker victory recorded; territory was not transferred."
	end
	endWar(war, "attacker victory")
	local Buildings = require(script.Parent.BuildingService)
	Buildings.AcceptBattleCapture(warId, targetId, Territory.GetOwnerRulerId(targetId), attackerId)
	local ok, err = Territory.SetOwner(targetId, attackerId)
	if not ok then
		pushState()
		return false, err
	end
	pushState()
	noticeRulerId(attackerId, "War ended: attacker victory. You now hold " .. targetId .. ".")
	noticeRulerId(defenderId, "War ended: attacker victory. " .. targetId .. " was lost.")
	return true, "Attacker victory."
end

function WarfareService.HasPersonalAttackOrigin(warId: string): boolean
	local war = warsById[warId]
	return war ~= nil and war.originTerritoryId ~= nil and Territory.GetOwnerRulerId(war.originTerritoryId) == war.attackerRootId
end

function WarfareService.IsActorCurrent(warId: string): boolean
	local war = warsById[warId]
	return war ~= nil and findRuler(war.attackerRootId) ~= nil
		and war.actorDomain == Domain.Signature(Hierarchy.GetSnapshot().rulers, war.attackerRootId)
end

function WarfareService.HasBetrayalConflict(subjectId: string, liegeId: string): boolean
	local rows = Hierarchy.GetSnapshot().rulers
	for _, war in warsById do
		if war.status == "Active" then
			local owner = Territory.GetOwnerRulerId(war.targetTerritoryId)
			if war.attackerRootId == liegeId or war.defenderRootId == liegeId
				or Domain.Contains(rows, subjectId, war.attackerRootId) or Domain.Contains(rows, subjectId, war.defenderRootId)
				or Domain.Contains(rows, war.attackerRootId, subjectId) or Domain.Contains(rows, war.defenderRootId, subjectId)
				or (owner and Domain.Contains(rows, subjectId, owner)) then return true end
		end
	end
	return false
end

function WarfareService.IsTargetCurrent(warId: string): boolean
	local war = warsById[warId]
	return war ~= nil and targetStillOriginalDefender(war)
end

function WarfareService.FreezeMatch()
	local snapshot = {}
	for _, war in warsById do table.insert(snapshot, war) end
	for _, war in snapshot do endWar(war, "match ended") end
	pushState()
end

function WarfareService.GetContestInspect()
	return buildSnapshot()
end

function WarfareService.DebugResolveWar(warId: string, outcome: string): (boolean, string)
	if MatchState.IsEnded() then return false, "Match ended." end
	local war = warsById[warId]
	if not war or war.status ~= "Active" then
		return false, "War is no longer active."
	end
	if outcome ~= "Attacker" and outcome ~= "Defender" then
		return false, "Unknown resolution."
	end
	local Military = militaryModule()
	if Military.IsMechanicallyResolved(warId) then
		return false, "War is already resolving."
	end
	Military.UnwindPreResolution(warId)
	if outcome == "Defender" then
		local attacker = war.attackerRootId
		local defender = war.defenderRootId
		endWar(war, "defender victory")
		pushState()
		noticeRulerId(attacker, "War ended: defender victory. Ownership unchanged.")
		noticeRulerId(defender, "War ended: defender victory. Ownership unchanged.")
		return true, "Defender victory."
	end
	local attacker = findRuler(war.attackerRootId)
	if not WarfareService.IsActorCurrent(war.warId) then
		endWar(war, "attacker political domain changed")
		pushState()
		return false, "War terminated: attacker political domain changed."
	end
	if not targetStillOriginalDefender(war) then
		endWar(war, "stale target")
		pushState()
		noticeRulerId(war.attackerRootId, "War ended: target no longer belongs to the original defender.")
		noticeRulerId(war.defenderRootId, "War ended: target no longer belongs to the original defender.")
		return false, "War is stale. Territory was not transferred."
	end
	if not WarfareService.IsActorCurrent(warId) then
		endWar(war, "attacker domain stale");pushState();return false, "Attacker domain changed; no capture."
	end
	local attackerId = war.attackerRootId
	local defenderId = war.defenderRootId
	local targetId = war.targetTerritoryId
	endWar(war, "attacker victory")
	local ok, err = Territory.SetOwner(targetId, attackerId)
	if not ok then
		pushState()
		return false, err
	end
	pushState()
	noticeRulerId(attackerId, "War ended: attacker victory. You now hold " .. targetId .. ".")
	noticeRulerId(defenderId, "War ended: attacker victory. " .. targetId .. " was lost.")
	return true, "Attacker victory."
end

local function cancelInvolving(rulerId: string, reason: string)
	local removed = false
	local toEnd = {}
	for _, war in warsById do
		if war.status == "Active" and (war.attackerRootId == rulerId or war.defenderRootId == rulerId) then
			table.insert(toEnd, war)
		end
	end
	local Military = militaryModule()
	for _, war in toEnd do
		if Military.IsMechanicallyResolved(war.warId) then
			-- Mechanical result stays authoritative through presentation.
		else
			Military.UnwindPreResolution(war.warId)
			local other = if war.attackerRootId == rulerId then war.defenderRootId else war.attackerRootId
			endWar(war, reason)
			noticeRulerId(other, "War cancelled (" .. reason .. ").")
			removed = true
		end
	end
	if removed then
		noticeRulerId(rulerId, "External wars ended (" .. reason .. ").")
		pushState()
	end
end

local function invalidateStaleWars()
	local removed = false
	local Military = militaryModule()
	for _, war in warsById do
		if war.status == "Active" and not targetStillOriginalDefender(war) then
			if Military.IsMechanicallyResolved(war.warId) then
				-- Do not reopen a mechanically final battle.
			else
				Military.UnwindPreResolution(war.warId)
				endWar(war, "stale after ownership change")
				noticeRulerId(war.attackerRootId, "War ended: target no longer belongs to the original defender.")
				noticeRulerId(war.defenderRootId, "War ended: target no longer belongs to the original defender.")
				removed = true
			end
		end
	end
	if removed then
		pushState()
	end
end

local function syncIndependence()
	if MatchState.IsEnded() then return end
	for _, war in warsById do
		if war.status == "Active" and (not WarfareService.IsActorCurrent(war.warId) or not targetStillOriginalDefender(war)) then
			if not militaryModule().IsMechanicallyResolved(war.warId) then
				militaryModule().UnwindPreResolution(war.warId)
				endWar(war, "political domain changed")
			end
		end
	end
	pushState()
end

local function onClientIntent(player: Player, action: any, a: any, b: any, c: any, d: any)
	if typeof(action) ~= "string" then
		noticePlayer(player, "Invalid request.")
		return
	end
	if action == "Ready" then
		print("[Warfare] Ready from", player.Name)
		pushState(player)
		return
	end
	local fromId = Hierarchy.GetRulerIdForUserId(player.UserId)
	if not fromId then
		noticePlayer(player, "No ruler record.")
		return
	end
	if action == "LaunchNaval" then
		if typeof(a) ~= "string" or typeof(b) ~= "number" or typeof(c) ~= "string" or #c > 80 then noticePlayer(player, "Invalid naval launch request.");return end
		local ok, result = WarfareService.LaunchNaval(fromId, a, b, c)
		MatchState.Send(serverPush, player, "NavalResult", HttpService:JSONEncode({ requestId = c, accepted = ok, warId = if ok then result else nil, active = ok and warsById[result] ~= nil, message = if ok then (if warsById[result] then "Transport launched; force locked." else "Launch already processed; this transport is no longer active.") else result }))
		return
	end
	if action == "PrepareBetrayal" or action == "Betray" then
		if typeof(a) ~= "string" or (action == "Betray" and typeof(b) ~= "string") then noticePlayer(player, "Invalid betrayal request."); return end
		local Betrayal = require(script.Parent.BetrayalService)
		local ok, result
		if action == "PrepareBetrayal" then ok, result = Betrayal.Prepare(fromId, a) else ok, result = Betrayal.Commit(fromId, a, b) end
		MatchState.Send(serverPush, player, if action == "PrepareBetrayal" then "BetrayalReview" else "BetrayalResult", HttpService:JSONEncode({
			accepted = ok, target = a, review = if ok then result else nil, message = if ok then "" else result,
		}))
		return
	end
	if action == "DeclareWar" then
		if typeof(a) ~= "string" then
			noticePlayer(player, "Cannot declare war: invalid target.")
			return
		end
		local ok, result = WarfareService.DeclareWar(fromId, a)
		if not ok then
			noticePlayer(player, result)
		end
		return
	end
	noticePlayer(player, "Unknown action.")
end

function WarfareService.Start()
	if started then
		return
	end
	started = true

	local remotesFolder = ReplicatedStorage:WaitForChild("Remotes") :: Folder
	clientIntent = remotesFolder:WaitForChild("WarfareClientEvent") :: RemoteEvent
	serverPush = remotesFolder:WaitForChild("WarfareServerEvent") :: RemoteEvent
	MatchState.ConnectIntent(clientIntent, onClientIntent)

	local debugFolder = ServerScriptService:FindFirstChild("WarfareDebug")
	if debugFolder then
		debugFolder:Destroy()
	end
	debugFolder = Instance.new("Folder")
	debugFolder.Name = "WarfareDebug"
	debugFolder.Parent = ServerScriptService
	debugSnapshot = Instance.new("StringValue")
	debugSnapshot.Name = "LastSnapshot"
	debugSnapshot.Parent = debugFolder
	local help = Instance.new("StringValue")
	help.Name = "Help"
	help.Value =
		"Prototype only. Invoke('Resolve', warId, 'Attacker'|'Defender'). Directors: ServerScriptService.WarfareDebug.Invoke"
	help.Parent = debugFolder
	local invoke = Instance.new("BindableFunction")
	invoke.Name = "Invoke"
	invoke.Parent = debugFolder
	invoke.OnInvoke = function(action: any, a: any, b: any)
		if action == "Declare" then
			local ok, result = WarfareService.DeclareWar(a, b)
			print("[Warfare] debug Invoke Declare", ok, result)
			return ok, result
		elseif action == "Resolve" then
			local ok, result = WarfareService.DebugResolveWar(a, b)
			print("[Warfare] debug Invoke Resolve", ok, result)
			return ok, result
		elseif action == "Contest" then
			local snap = WarfareService.GetContestInspect()
			print("[Warfare] debug Contest", snap)
			return true, snap
		end
		return false, "Unknown debug action."
	end

	_G.__WarfareV01 = WarfareService

	Hierarchy.SetWarfareRefresh(syncIndependence)
	Hierarchy.RulerRemoving:Connect(function(rulerId: string)
		navalReceipts[rulerId] = nil
		cancelInvolving(rulerId, "left the match")
		require(script.Parent.BetrayalService).Remove(rulerId)
	end)
	Territory.OwnershipChanged:Connect(invalidateStaleWars)

	Players.PlayerAdded:Connect(function(player)
		task.defer(function()
			if player.Parent then
				pushState(player)
			end
		end)
	end)

	pushState()
	print("[Warfare] service started")
end

function WarfareService.PublishMatch() pushState() end

function WarfareService.ResetMatch()
	assert(MatchState.IsResetting())
	warsById, cooldownUntil, navalReceipts = {}, {}, {}
end

return WarfareService
