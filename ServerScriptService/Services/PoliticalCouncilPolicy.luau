--!strict
-- Server-only pure membership policy. Never replicate scores or timers.
local Policy = {}
function Policy.Validate(config: any)
	local function finite(n: any): boolean return typeof(n) == "number" and n == n and math.abs(n) < math.huge end
	assert(finite(config.LandWeight) and config.LandWeight >= 0, "Invalid council land weight")
	assert(finite(config.TroopWeight) and config.TroopWeight >= 0, "Invalid council troop weight")
	assert(config.LandWeight + config.TroopWeight > 0, "Council needs a strength weight")
	assert(finite(config.TroopUnit) and config.TroopUnit > 0, "Invalid council troop unit")
	assert(finite(config.SeatLimit) and config.SeatLimit >= 1 and config.SeatLimit % 1 == 0, "Invalid council seat limit")
	assert(finite(config.ReplacementMarginPercent) and config.ReplacementMarginPercent >= 0, "Invalid council margin")
	assert(finite(config.ReplacementDurationSeconds) and config.ReplacementDurationSeconds > 0, "Invalid council duration")
	assert(finite(config.EvaluationIntervalSeconds) and config.EvaluationIntervalSeconds > 0, "Invalid council evaluation interval")
end
function Policy.Authority(land: number, total: number, config: any): number
	return config.LandWeight * land + config.TroopWeight * total / config.TroopUnit
end
function Policy.Eligible(ruler: any, liegeId: string): boolean
	return ruler.liegeId == liegeId and ruler.connected == true and ruler.active == true and ruler.land > 0
end
function Policy.New(): any return { members = {}, since = {} } end
local function stronger(a: any, b: any): boolean
	return a.authority > b.authority or (a.authority == b.authority and a.id < b.id)
end
local function qualifies(a: any, b: any, config: any): boolean
	return a.authority > b.authority and a.authority * 100 >= b.authority * (100 + config.ReplacementMarginPercent)
end
function Policy.Evaluate(state: any, candidates: { any }, at: number, config: any): (boolean, number?)
	local before = table.concat(state.members, "|")
	local byId, ordered = {}, table.clone(candidates)
	for _, candidate in ordered do byId[candidate.id] = candidate end
	table.sort(ordered, stronger)
	local members, seated = {}, {}
	for _, id in state.members do
		if byId[id] and not seated[id] and #members < config.SeatLimit then
			table.insert(members, id); seated[id] = true
		end
	end
	for _, candidate in ordered do
		if #members >= config.SeatLimit then break end
		if not seated[candidate.id] then table.insert(members, candidate.id); seated[candidate.id] = true end
	end
	local timers = {}
	for _, challenger in ordered do
		if seated[challenger.id] then continue end
		local previous = state.since[challenger.id] or {}
		local current = {}
		for _, id in members do
			if qualifies(challenger, byId[id], config) then current[id] = previous[id] or at end
		end
		if next(current) then timers[challenger.id] = current end
	end
	-- Strongest mature challenger first; displace the weakest qualifying incumbent.
	for _, challenger in ordered do
		local since = timers[challenger.id]
		if not since or seated[challenger.id] then continue end
		local victim: any = nil
		for _, id in members do
			if since[id] and at - since[id] >= config.ReplacementDurationSeconds then
				local incumbent = byId[id]
				if not victim or stronger(victim, incumbent) then victim = incumbent end
			end
		end
		if victim then
			members[table.find(members, victim.id) :: number] = challenger.id
			seated[victim.id], seated[challenger.id] = nil, true
			timers[challenger.id] = nil
		end
	end
	-- Retain only live nonmember/incumbent pairs, including newly started pairs.
	local nextAt: number? = nil
	local nextTimers = {}
	for _, challenger in ordered do
		if seated[challenger.id] then continue end
		local current = {}
		for _, id in members do
			if qualifies(challenger, byId[id], config) then
				local previous = timers[challenger.id]
				local started = if previous and previous[id] then previous[id] else at
				current[id] = started
				local due = started + config.ReplacementDurationSeconds
				nextAt = if nextAt then math.min(nextAt, due) else due
			end
		end
		if next(current) then nextTimers[challenger.id] = current end
	end
	table.sort(members) -- Stable ID display storage; never strength-ranked output.
	state.members, state.since = members, nextTimers
	return before ~= table.concat(members, "|"), nextAt
end
-- Own and direct-liege councils only. No root/descendant/ally propagation.
function Policy.VisibleCouncilIds(viewerId: string?, rulers: any): { string }
	local viewer = if viewerId then rulers[viewerId] else nil
	if not viewer then return {} end
	local ids = { viewerId :: string }
	if viewer.liegeId ~= "" and rulers[viewer.liegeId] then table.insert(ids, viewer.liegeId) end
	return ids
end
return Policy
