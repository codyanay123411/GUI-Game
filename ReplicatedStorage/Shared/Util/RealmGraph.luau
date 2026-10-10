--!strict

--[[
	Greater-realm adjacency graph. Uses Territory adjacency + Hierarchy roots.
	Not visual proximity. Server must recompute from live ownership.
]]

local RealmGraph = {}

local function rootOf(ruler: any): string?
	if typeof(ruler) ~= "table" then
		return nil
	end
	if typeof(ruler.rootRulerId) == "string" and ruler.rootRulerId ~= "" then
		return ruler.rootRulerId
	end
	if typeof(ruler.rulerId) == "string" then
		return ruler.rulerId
	end
	return nil
end

function RealmGraph.LandsByRoot(rulers: { any }, ownedByRuler: (string) -> { string }): { [string]: { string } }
	local lands: { [string]: { string } } = {}
	local seen: { [string]: { [string]: boolean } } = {}
	for _, ruler in rulers do
		local rootId = rootOf(ruler)
		local rulerId = ruler.rulerId
		if typeof(rootId) == "string" and typeof(rulerId) == "string" then
			if seen[rootId] == nil then
				seen[rootId] = {}
				lands[rootId] = {}
			end
			for _, territoryId in ownedByRuler(rulerId) do
				if seen[rootId][territoryId] ~= true then
					seen[rootId][territoryId] = true
					table.insert(lands[rootId], territoryId)
				end
			end
		end
	end
	return lands
end

function RealmGraph.AreRealmsAdjacent(
	landsA: { string },
	landsB: { string },
	areAdjacent: (string, string) -> boolean
): boolean
	for _, a in landsA do
		for _, b in landsB do
			if areAdjacent(a, b) then
				return true
			end
		end
	end
	return false
end

function RealmGraph.Distance(
	fromRoot: string,
	toRoot: string,
	neighborSet: { [string]: { string } }
): number?
	if fromRoot == toRoot then
		return 0
	end
	local visited: { [string]: boolean } = { [fromRoot] = true }
	local queue = { { id = fromRoot, d = 0 } }
	local head = 1
	while head <= #queue do
		local cur = queue[head]
		head += 1
		local neighbors = neighborSet[cur.id]
		if neighbors then
			for _, nxt in neighbors do
				if visited[nxt] ~= true then
					if nxt == toRoot then
						return cur.d + 1
					end
					visited[nxt] = true
					table.insert(queue, { id = nxt, d = cur.d + 1 })
				end
			end
		end
	end
	return nil
end

function RealmGraph.BuildNeighborSet(
	landsByRoot: { [string]: { string } },
	areAdjacent: (string, string) -> boolean
): { [string]: { string } }
	local roots = {}
	for rootId in landsByRoot do
		table.insert(roots, rootId)
	end
	table.sort(roots)
	local neighborSet: { [string]: { string } } = {}
	for _, id in roots do
		neighborSet[id] = {}
	end
	for i = 1, #roots do
		for j = i + 1, #roots do
			local a = roots[i]
			local b = roots[j]
			if RealmGraph.AreRealmsAdjacent(landsByRoot[a], landsByRoot[b], areAdjacent) then
				table.insert(neighborSet[a], b)
				table.insert(neighborSet[b], a)
			end
		end
	end
	return neighborSet
end

return RealmGraph
