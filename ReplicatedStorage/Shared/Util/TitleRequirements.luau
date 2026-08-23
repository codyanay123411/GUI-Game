--!strict

--[[
	Reads TitleRequirements from a MapConfiguration.
	Gameplay must not hardcode Vale test numbers here.
]]

export type TitleRequirement = {
	rank: number,
	titleName: string,
	establishLabel: string,
	establishedNotice: string,
	territoryCount: number,
	prestige: number,
}

local TitleRequirements = {}

function TitleRequirements.FromMap(mapDef: any): { TitleRequirement }
	if typeof(mapDef) ~= "table" or typeof(mapDef.titleRequirements) ~= "table" then
		return {}
	end
	local list = {}
	for _, row in mapDef.titleRequirements do
		if typeof(row) == "table" and typeof(row.rank) == "number" then
			table.insert(list, row :: TitleRequirement)
		end
	end
	table.sort(list, function(a, b)
		return a.rank < b.rank
	end)
	return list
end

function TitleRequirements.ForRank(mapDef: any, rank: number): TitleRequirement?
	for _, row in TitleRequirements.FromMap(mapDef) do
		if row.rank == rank then
			return row
		end
	end
	return nil
end

return TitleRequirements
