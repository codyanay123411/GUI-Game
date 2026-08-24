--!strict

--[[
	Warfare / Conquest V0.1.

	Server-authoritative external wars between independent roots.
	One enemy-controlled territory per war. No armies or battles.
	Resolution is server-only debug. Consumes Hierarchy, Territory, Diplomacy.
]]

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Hierarchy = require(ServerScriptService.Services.PoliticalHierarchyService)
local Territory = require(ServerScriptService.Services.TerritoryMapService)
local Diplomacy = require(ServerScriptService.Services.DiplomacyService)
local WarfareAdjacency = require(ReplicatedStorage.Shared.Util.WarfareAdjacency)

local WarfareService = {}

type War = {
	warId: string,
	attackerRootId: string,
	defenderRootId: string,
	targetTerritoryId: string,
	status: string,
}

local started = false
local warsById: { [string]: War } = {}
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

local function isIndependentRoot(ruler: any?): boolean
	return ruler ~= nil and ruler.independent == true
end

local function greaterRealmRulerIds(rootId: string): { string }
	local root = findRuler(rootId)
	if not isIndependentRoot(root) then
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
				defenderRootId = war.defenderRootId,
				targetTerritoryId = war.targetTerritoryId,
				status = war.status,
			})
		end
	end
	table.sort(wars, function(a, b)
		return a.warId < b.warId
	end)
	return { wars = wars }
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
	print("[Warfare] ended", war.warId, reason)
end

local function targetStillOriginalDefender(war: War): boolean
	local currentRoot = ownerRootId(war.targetTerritoryId)
	return currentRoot == war.defenderRootId
end

function WarfareService.GetSnapshot()
	return buildSnapshot()
end

function WarfareService.DeclareWar(attackerRootId: string, targetTerritoryId: string): (boolean, string)
	if typeof(targetTerritoryId) ~= "string" or targetTerritoryId == "" then
		return false, "Cannot declare war: invalid target."
	end
	local attacker = findRuler(attackerRootId)
	if not isIndependentRoot(attacker) then
		return false, "Subjects cannot independently declare external war."
	end
	local mapDef = Territory.GetMapDefinition()
	local exists = false
	for _, t in mapDef.territories do
		if t.id == targetTerritoryId then
			exists = true
			break
		end
	end
	if not exists then
		return false, "Cannot declare war: unknown territory."
	end
	local ownerId = Territory.GetOwnerRulerId(targetTerritoryId)
	if not ownerId then
		return false, "Cannot declare war: target is Unclaimed."
	end
	if isOwnedByRealm(targetTerritoryId, attackerRootId) then
		return false, "Cannot declare war: target belongs to your realm."
	end
	local defenderRoot = ownerRootId(targetTerritoryId)
	if not defenderRoot then
		return false, "Cannot declare war: target is Unclaimed."
	end
	local defender = findRuler(defenderRoot)
	if not isIndependentRoot(defender) then
		return false, "Cannot declare war: defender is not an independent realm."
	end
	if not isGreaterRealmAdjacent(attackerRootId, targetTerritoryId) then
		return false, "Cannot declare war: target not adjacent."
	end
	if Diplomacy.HasNonAggressionPact(attackerRootId, defenderRoot) then
		return false, "Cannot declare war: Non-Aggression Pact active."
	end
	for _, war in warsById do
		if war.status == "Active" and war.attackerRootId == attackerRootId and war.targetTerritoryId == targetTerritoryId then
			return false, "Cannot declare war: a matching war is already active."
		end
	end
	local warId = HttpService:GenerateGUID(false)
	local created: War = {
		warId = warId,
		attackerRootId = attackerRootId,
		defenderRootId = defenderRoot,
		targetTerritoryId = targetTerritoryId,
		status = "Active",
	}
	warsById[warId] = created
	pushState()
	noticeRulerId(attackerRootId, "War declared.")
	noticeRulerId(defenderRoot, "War declared against your realm.")
	return true, warId
end

function WarfareService.DebugResolveWar(warId: string, outcome: string): (boolean, string)
	local war = warsById[warId]
	if not war or war.status ~= "Active" then
		return false, "War is no longer active."
	end
	if outcome ~= "Attacker" and outcome ~= "Defender" then
		return false, "Unknown resolution."
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
	local attacker = findRuler(war.attackerRootId)
	if not isIndependentRoot(attacker) then
		endWar(war, "attacker no longer independent")
		pushState()
		return false, "War terminated: attacker is no longer independent."
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
	for _, war in toEnd do
		local other = if war.attackerRootId == rulerId then war.defenderRootId else war.attackerRootId
		endWar(war, reason)
		noticeRulerId(other, "War cancelled (" .. reason .. ").")
		removed = true
	end
	if removed then
		noticeRulerId(rulerId, "External wars ended (" .. reason .. ").")
		pushState()
	end
end

local function invalidateStaleWars()
	local removed = false
	for _, war in warsById do
		if war.status == "Active" and not targetStillOriginalDefender(war) then
			endWar(war, "stale after ownership change")
			noticeRulerId(war.attackerRootId, "War ended: target no longer belongs to the original defender.")
			noticeRulerId(war.defenderRootId, "War ended: target no longer belongs to the original defender.")
			removed = true
		end
	end
	if removed then
		pushState()
	end
end

local function syncIndependence()
	for _, ruler in Hierarchy.GetSnapshot().rulers do
		if ruler.independent ~= true then
			cancelInvolving(ruler.rulerId, "no longer independent")
		end
	end
end

local function onClientIntent(player: Player, action: any, a: any)
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
		end
		return false, "Unknown debug action."
	end

	_G.__WarfareV01 = WarfareService

	Hierarchy.StateChanged:Connect(syncIndependence)
	Hierarchy.RulerRemoving:Connect(function(rulerId: string)
		cancelInvolving(rulerId, "left the match")
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
