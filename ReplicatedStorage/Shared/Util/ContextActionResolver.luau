--!strict
-- Client UX prediction only. Every consequential intent is revalidated by its service.
local Adjacency = require(script.Parent.WarfareAdjacency)
local Rank = require(script.Parent.PoliticalRankRules)
local View = require(script.Parent.PlayerRelevantView)
local Graph = require(script.Parent.RealmGraph)
local CommsConfig = require(script.Parent.Parent.Config.CommunicationsConfig)
local Domain = require(script.Parent.PoliticalDomain)
local Routes = require(script.Parent.NavalRoutes)
local Resolver = {}

function Resolver.Resolve(state: any, definitions: { any }, territoryId: string, userId: number, ended: boolean, now: number, mapDef: any?): any
	local rulers, ownership = {}, {}
	local me, province, holder, target = nil, nil, nil, nil
	for _, r in state.hierarchy.rulers or {} do
		rulers[r.rulerId] = r
		if tonumber(r.userId) == userId then me = r end
	end
	for _, t in state.territory.territories or {} do
		ownership[t.territoryId] = t.ownerRulerId
		if t.territoryId == territoryId then province = t end
	end
	for _, t in definitions do if t.id == territoryId then target = t end end
	if not target then return nil end
	holder = province and rulers[province.ownerRulerId]
	local root = holder and rulers[holder.rootRulerId or holder.rulerId]
	local localRoot = me and (me.rootRulerId or me.rulerId)
	local targetRoot = holder and (holder.rootRulerId or holder.rulerId)
	local relation = if not holder then "Unclaimed" elseif not me then "Public realm"
		elseif holder.rulerId == me.rulerId then "Your personal holding"
		elseif holder.liegeId == me.rulerId then "Your direct subject"
		elseif me.liegeId == holder.rulerId then "Your liege"
		elseif targetRoot == localRoot then "Your greater realm" else "Unrelated ruler"
	local capabilities = (state.permissions and state.permissions.self) or {}
	local ownAgreement = nil
	local agreement = nil
	for _, a in state.diplomacy.agreements or {} do
		if me and holder and ((a.leftRulerId == me.rulerId and a.rightRulerId == holder.rulerId) or (a.rightRulerId == me.rulerId and a.leftRulerId == holder.rulerId)) then ownAgreement = a end
		if (a.leftRulerId == localRoot and a.rightRulerId == targetRoot)
			or (a.rightRulerId == localRoot and a.leftRulerId == targetRoot) then agreement = a end
	end
	if agreement then relation = if agreement.nap then "Non-Aggression Pact" elseif agreement.alliance then "Ally" else relation end
	local war, contested = nil, false
	for _, w in state.warfare.wars or {} do
		if w.targetTerritoryId == territoryId then contested = true end
		if w.targetTerritoryId == territoryId and localRoot and (View.WarInvolvesRoot(w, localRoot) or (me and View.WarInvolvesRoot(w, me.rulerId))) then
			contested = true
			war = w
		end
	end
	if war and holder and targetRoot ~= localRoot then relation = "Current enemy" end
	local lands, personal = {}, {}
	for id, ownerId in ownership do
		local owner = rulers[ownerId]
		if owner and me and Domain.Contains(state.hierarchy.rulers, me.rulerId, owner.rulerId) then table.insert(lands, id) end
		if me and ownerId == me.rulerId then table.insert(personal, id) end
	end
	local betrayal = capabilities.betrayal == true and me and holder and me.liegeId ~= ""
		and Domain.Contains(state.hierarchy.rulers, me.liegeId, holder.rulerId)
		and not Domain.Contains(state.hierarchy.rulers, me.rulerId, holder.rulerId)
	local landAdjacent = Adjacency.IsTargetAdjacentToOwned(definitions, territoryId, lands)
	local navalRoute = if mapDef and me and not landAdjacent then Routes.Closest(mapDef, personal, territoryId) else nil
	local navalDepartures = if navalRoute then { { id = navalRoute.departureId, route = navalRoute } } else {}
	local reason = nil
	if ended then reason = "Match ended"
	elseif not me or not province then reason = "Waiting for authoritative state"
	elseif not me.independent and not capabilities.war then reason = capabilities.warReason or "Waiting for your liege permissions"
	elseif holder and targetRoot == localRoot and not betrayal then reason = "Target belongs to your realm"
	elseif holder and me and Domain.TreatyApplies(state.hierarchy.rulers, state.diplomacy.agreements or {}, me.rulerId, holder.rulerId) then reason = "Non-Aggression Pact blocks war"
	elseif contested then reason = "Province is already contested"
	elseif not holder and (typeof(province.neutralDefense) ~= "table" or typeof(province.neutralDefense.current) ~= "number") then reason = "Waiting for militia state" end
	if not reason then
		for _, c in state.warfare.cooldowns or {} do
			if c.territoryId == territoryId and (tonumber(c.endsAt) or 0) > now then reason = "Post-war cooldown" end
		end
	end
	local navalReason = reason or (if landAdjacent then "Land access takes priority" elseif #navalDepartures == 0 then "No personally owned coast with a clear water route" elseif betrayal then "Use the existing land betrayal review" else nil)
	if not reason and not landAdjacent then reason = "No border with your own territorial domain" end
	local communication = {}
	if holder and me and holder.rulerId ~= me.rulerId then
		local realmLands = Graph.LandsByRoot(state.hierarchy.rulers, function(rulerId)
			local ids = {}
			for id, ownerId in ownership do if ownerId == rulerId then table.insert(ids, id) end end
			return ids
		end)
		local definitionsById = {}
		for _, definition in definitions do definitionsById[definition.id] = definition end
		local graph = Graph.BuildNeighborSet(realmLands, function(left, right)
			for _, id in definitionsById[left].adjacentIds do if id == right then return true end end
			return false
		end)
		local distance = Graph.Distance(localRoot, targetRoot, graph)
		for _, contact in state.communications.contacts or {} do
			if tonumber(contact.userId) == tonumber(holder.userId) then
				table.insert(communication, { label = "Direct", userId = tonumber(holder.userId) })
			end
		end
		for _, c in state.communications.contexts or {} do
			if not c.canSend or c.observerOnly then continue end
			local relevant = (c.kind == "council" and ((holder.liegeId == me.rulerId and c.id == "council:" .. me.rulerId)
				or (me.liegeId == holder.rulerId and c.id == "council:" .. holder.rulerId)
				or (me.liegeId and me.liegeId == holder.liegeId and c.id == "council:" .. me.liegeId)))
				or (c.kind == "alliance" and holder.independent and agreement and agreement.alliance and c.id == "alliance:" .. tostring(agreement.allianceInstanceId))
				or (c.kind == "diplomatic" and distance ~= nil and distance <= CommsConfig.DiplomaticMaxDistance)
			if relevant then table.insert(communication, { label = c.label, contextId = c.id }) end
		end
	end
	-- Preserve ordinary root offers; a subject acts as itself. Existing subject-domain
	-- agreements remain directly addressable even by an independent counterpart.
	local diplomacyTarget = if ownAgreement or (me and not me.independent) then (holder and holder.rulerId) else targetRoot
	local actionableAgreement = if diplomacyTarget == (holder and holder.rulerId) then ownAgreement else agreement
	local diplomacy = {}
	if not ended and me and holder and holder.rulerId ~= me.rulerId then
		if (me.independent or capabilities.diplomacy) and root and (targetRoot ~= localRoot or ownAgreement ~= nil) then
			for _, kind in { "Alliance", "NAP" } do
				local exists = actionableAgreement and (if kind == "Alliance" then actionableAgreement.alliance else actionableAgreement.nap)
				local pending = false
				for _, r in state.diplomacy.requests or {} do
					if r.agreementType == kind and ((r.fromRulerId == me.rulerId and r.toRulerId == diplomacyTarget)
						or (r.toRulerId == me.rulerId and r.fromRulerId == diplomacyTarget)) then pending = true end
				end
				if exists or (targetRoot ~= localRoot and not pending) then table.insert(diplomacy, { label = (if exists then "Break " else "Offer ") .. kind,
					action = (if exists then "Break" else "Offer") .. kind, target = diplomacyTarget, system = "Diplomacy" }) end
			end
		end
		local cursor, cycle = holder, false
		local seen = {}
		while cursor and not seen[cursor.rulerId] do
			seen[cursor.rulerId] = true
			if cursor.rulerId == me.rulerId then cycle = true; break end
			cursor = rulers[cursor.liegeId]
		end
		if me.liegeId ~= holder.rulerId and not cycle and tonumber(holder.userId)
			and Rank.CanBecomeVassalOf(me.titleRank, holder.titleRank) then
			table.insert(diplomacy, { label = "Offer Vassalage", action = "Offer", target = tonumber(holder.userId), system = "Hierarchy" })
		end
	end
	local actions = { { id = "Info", label = "Province info" } }
	if holder and me and holder.rulerId == me.rulerId then table.insert(actions, { id = "Build", label = "Build" }) end
	if war and not ended then table.insert(actions, { id = "Battle", label = "War / battle" })
	elseif not reason then table.insert(actions, { id = if betrayal then "Betrayal" else "War", label = if betrayal then "Betray liege" elseif holder then "War review" else "Conquer" }) end
	if not navalReason then table.insert(actions, { id = "Naval", label = "Naval attack" }) end
	if #diplomacy > 0 then table.insert(actions, { id = "Diplomacy", label = "Diplomacy" }) end
	if #communication > 0 then table.insert(actions, { id = "Message", label = "Message" }) end
	if holder then table.insert(actions, { id = "Realm", label = "Realm info" }) end
	if me and holder and holder.rulerId == me.rulerId and not ended then table.insert(actions, { id = "Military", label = "Military" }) end
	return { territoryId = territoryId, definition = target, province = province, holder = holder, root = root,
		me = me, relation = relation, actions = actions, communication = communication, diplomacy = diplomacy,
		war = war, warReason = reason, canDeclare = reason == nil and not betrayal, canBetray = reason == nil and betrayal == true, personalLands = personal, rulers = rulers,
		diplomacyReason = if ended then "Match ended" elseif me and (me.independent or capabilities.diplomacy) then "Own domain diplomacy allowed" else capabilities.diplomacyReason or "Waiting for permissions",
		navalDepartures = navalDepartures, navalReason = navalReason, canNaval = navalReason == nil,
		available = tonumber(state.military.available) or 0 }
end

-- Public identity and a predicted action reason, never additional war intelligence.
function Resolver.SelectionText(context: any): string
	local holder, root = context.holder, context.root
	local identity = if holder then "Owner: " .. holder.displayName .. " · Realm: " .. (if root then root.displayName else holder.displayName) else "Owner: Unclaimed · No realm"
	local authority = if holder and root and holder.rulerId ~= root.rulerId then "Ordinary external defense: root " .. root.displayName .. "; subject-initiated wars use personal forces" else nil
	local status = if context.warReason == "Match ended" then "Match ended · Inspection only"
		elseif context.war then "Your realm's conflict · Open War / battle"
		elseif context.canBetray then "Betrayal review available - independence and troop transfer require confirmation"
		elseif context.canNaval and not context.canDeclare then "Naval eligible - automatic coastal departure; server rechecks"
		elseif context.canDeclare then (if holder then "War eligible" else "Conquest eligible") .. " · Server rechecks"
		else context.warReason or "Waiting for state"
	return context.definition.displayName .. " · " .. context.relation .. "\n" .. identity .. "\n"
		.. (if authority then authority .. "\n" else "") .. status .. "\n" .. context.diplomacyReason
end
return Resolver
