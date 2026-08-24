--!strict

--[[
	Validates static MapConfiguration adjacency: no self-links, no duplicates,
	symmetric pairs, all IDs exist. Gameplay consumes the authored lists.
]]

local MapAdjacency = {}

export type TerritoryDefinition = {
	id: string,
	displayName: string,
	polygon: { { x: number, y: number } },
	adjacentIds: { string },
}

function MapAdjacency.Validate(territories: { TerritoryDefinition }): (boolean, string)
	local byId = {}
	for _, t in territories do
		if byId[t.id] then
			return false, "Duplicate territory id: " .. t.id
		end
		byId[t.id] = t
	end
	for _, t in territories do
		local seen = {}
		for _, adj in t.adjacentIds do
			if adj == t.id then
				return false, t.id .. " is adjacent to itself"
			end
			if seen[adj] then
				return false, t.id .. " lists " .. adj .. " twice"
			end
			seen[adj] = true
			local other = byId[adj]
			if not other then
				return false, t.id .. " adjacent to missing id " .. adj
			end
			local reverse = false
			for _, back in other.adjacentIds do
				if back == t.id then
					reverse = true
					break
				end
			end
			if not reverse then
				return false, "Adjacency not symmetric: " .. t.id .. " -> " .. adj
			end
		end
	end
	return true, ""
end

return MapAdjacency
