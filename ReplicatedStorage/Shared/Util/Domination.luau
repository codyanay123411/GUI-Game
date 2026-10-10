--!strict
-- Pure public-count calculation; no match authority or private statistics.
local Domination = {}

function Domination.Evaluate(map: any, rulers: { any }, ownership: { any }): any
	local config = map.victory
	assert(config and config.type == "Domination", "Map must configure Domination victory")
	local percent = config.territoryControlPercent
	assert(typeof(percent) == "number" and percent == percent and percent > 0 and percent <= 1, "Invalid domination threshold")
	local conquerable, total = {}, 0
	for _, territory in map.territories do
		if territory.conquerable ~= false then conquerable[territory.id] = true; total += 1 end
	end
	assert(total > 0, "Map needs conquerable territory")
	local byId, counts = {}, {}
	for _, ruler in rulers do byId[ruler.rulerId] = ruler end
	for _, land in ownership do
		local owner = byId[land.ownerRulerId]
		local root = owner and byId[owner.rootRulerId]
		if conquerable[land.territoryId] and root and root.independent then counts[root.rulerId] = (counts[root.rulerId] or 0) + 1 end
	end
	local required = math.ceil(total * percent)
	local candidates = {}
	for id, count in counts do
		if count >= required then table.insert(candidates, { rootId = id, controlled = count }) end
	end
	-- Deterministic fallback for batched admin transfers / thresholds <= 50%.
	table.sort(candidates, function(a, b) return if a.controlled ~= b.controlled then a.controlled > b.controlled else a.rootId < b.rootId end)
	return { total = total, required = required, threshold = percent, counts = counts, winner = candidates[1] }
end

return Domination
