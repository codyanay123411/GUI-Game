--!strict
local Geometry = require(script.Parent.MapGeometry)
local Policy = {}
-- Prefer authored border adjacency, then geometric proximity, then stable ID.
function Policy.NearestTerritory(definitions: { any }, ownership: { any }, rulers: { any }, senderId: string, localRoot: string): string?
	local byId, owned, localLands = {}, {}, {}
	for _, r in rulers do byId[r.rulerId] = r end
	for _, t in ownership do
		owned[t.territoryId] = t.ownerRulerId
		local r = byId[t.ownerRulerId]
		if r and (r.rootRulerId or r.rulerId) == localRoot then localLands[t.territoryId] = true end
	end
	local targets = {}
	for _, t in definitions do if localLands[t.id] then table.insert(targets, t) end end
	local bestId, bestBorder, bestDistance = nil, false, math.huge
	for _, t in definitions do
		if owned[t.id] ~= senderId then continue end
		local border = false
		for _, id in t.adjacentIds or {} do if localLands[id] then border = true end end
		local x, y = Geometry.Centroid(t.polygon)
		local distance = math.huge
		for _, target in targets do
			local tx, ty = Geometry.Centroid(target.polygon)
			distance = math.min(distance, (x - tx)^2 + (y - ty)^2)
		end
		if not bestId or (border and not bestBorder) or (border == bestBorder and
			(distance < bestDistance or (distance == bestDistance and t.id < bestId))) then
			bestId, bestBorder, bestDistance = t.id, border, distance
		end
	end
	return bestId
end

function Policy.Aggregate(events: { [string]: any }): { [string]: any }
	local groups = {}
	for id, event in events do
		local territoryId = event.territoryId
		if not territoryId then continue end
		local group = groups[territoryId]
		if not group then group = { count = 0, event = event }; groups[territoryId] = group end
		group.count += event.count or 1
		local best = group.event
		if event.priority > best.priority or (event.priority == best.priority and id < best.id) then group.event = event end
	end
	return groups
end
return Policy
