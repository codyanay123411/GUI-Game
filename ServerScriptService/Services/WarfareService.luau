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
		serverPush:FireClient(toPlayer, "State", encoded)
	else
		print("[Warfare] push State all clients wars=", #payload.wars)
		serverPush:FireAllClients("State", encoded)
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

function WarfareService.CheckDeclaration(attackerRootId: string, targetTerritoryId: string, betrayalLiege: string?): (boolean, any)
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
	if not isGreaterRealmAdjacent(attackerRootId, targetTerritoryId) then
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
	return true, { defenderId = defenderRoot, neutral = neutral }
end

function WarfareService.DeclareWar(attackerRootId: string, targetTerritoryId: string, betrayalLiege: string?): (boolean, string)
	local valid, details = WarfareService.CheckDeclaration(attackerRootId, targetTerritoryId, betrayalLiege)
	if not valid then return false, details end
	local defenderRoot, neutral = details.defenderId, details.neutral

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
		actorDomain = Domain.Signature(Hierarchy.GetSnapshot().rulers, attackerRootId),
		defenderDomain = if defenderRoot ~= "" then Domain.Signature(Hierarchy.GetSnapshot().rulers, defenderRoot) else "",
	}
	warsById[warId] = created
	militaryModule().OnWarCreated(created)
	pushState()
	noticeRulerId(attackerRootId, if neutral then "Conquest begun. Commit Troops in Military." else "War declared.")
	noticeRulerId(defenderRoot, "War declared against your realm.")
	return true, warId
end

function WarfareService.CancelWar(warId: string, reason: string)
	local war = warsById[warId]
	if not war or war.status ~= "Active" then
		return
	end
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

local function onClientIntent(player: Player, action: any, a: any, b: any)
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
	if action == "PrepareBetrayal" or action == "Betray" then
		if typeof(a) ~= "string" or (action == "Betray" and typeof(b) ~= "string") then noticePlayer(player, "Invalid betrayal request."); return end
		local Betrayal = require(script.Parent.BetrayalService)
		local ok, result
		if action == "PrepareBetrayal" then ok, result = Betrayal.Prepare(fromId, a) else ok, result = Betrayal.Commit(fromId, a, b) end
		serverPush:FireClient(player, if action == "PrepareBetrayal" then "BetrayalReview" else "BetrayalResult", HttpService:JSONEncode({
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
	clientIntent.OnServerEvent:Connect(onClientIntent)

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

return WarfareService
