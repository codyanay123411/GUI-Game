--!strict

--[[
	Greater-realm war adjacency from MapConfiguration adjacentIds.
	Does not use visual proximity, grid index, or realm membership alone.
]]

local WarfareAdjacency = {}

local function findTerritory(territories: { any }, territoryId: string): any?
	for _, t in territories do
		if t.id == territoryId then
			return t
		end
	end
	return nil
end

function WarfareAdjacency.IsTargetAdjacentToOwned(
	territories: { any },
	targetTerritoryId: string,
	ownedTerritoryIds: { string }
): boolean
	if targetTerritoryId == "" or #ownedTerritoryIds == 0 then
		return false
	end
	local target = findTerritory(territories, targetTerritoryId)
	if not target or typeof(target.adjacentIds) ~= "table" then
		return false
	end
	local owned: { [string]: boolean } = {}
	for _, id in ownedTerritoryIds do
		if typeof(id) == "string" and id ~= "" and id ~= targetTerritoryId then
			owned[id] = true
		end
	end
	for _, adjId in target.adjacentIds do
		if typeof(adjId) == "string" and owned[adjId] == true then
			return true
		end
	end
	return false
end

return WarfareAdjacency
