--!strict
-- Pure resolver. TerritoryMapService resolves/freezes this once at map startup.
local Config = require(script.Parent.Parent.Config.TitleProgressionConfig)
export type TitleRequirement = {
	rank: number, titleName: string, establishLabel: string, establishedNotice: string,
	territoryCount: number, prestige: number,
}
local Requirements = {}
local function positive(value: any): boolean
	return typeof(value) == "number" and value == value and value > 0 and value < math.huge
end
function Requirements.Resolve(mapDef: any): { TitleRequirement }
	local prefix = "Invalid title configuration (" .. tostring(if typeof(mapDef) == "table" then mapDef.mapId else "unknown") .. "): "
	assert(typeof(mapDef) == "table" and typeof(mapDef.territories) == "table", prefix .. "province definitions required")
	local count, seen = 0, {}
	for _, province in mapDef.territories do
		assert(typeof(province) == "table" and typeof(province.id) == "string" and province.id ~= "" and not seen[province.id], prefix .. "unique province IDs required")
		assert(province.conquerable == nil or typeof(province.conquerable) == "boolean", prefix .. "conquerable must be boolean")
		seen[province.id] = true
		if province.conquerable ~= false then count += 1 end
	end
	assert(positive(count) and count % 1 == 0, prefix .. "positive conquerable province count required")
	local overrides = {}
	if mapDef.titleRequirements ~= nil then
		assert(typeof(mapDef.titleRequirements) == "table", prefix .. "titleRequirements overrides must be a table")
		for _, row in mapDef.titleRequirements do
			assert(typeof(row) == "table" and (row.rank == 2 or row.rank == 3 or row.rank == 4) and not overrides[row.rank], prefix .. "unique Duke/King/Emperor override ranks required")
			assert(positive(row.territoryCount) and row.territoryCount % 1 == 0 and positive(row.prestige), prefix .. "override land must be a positive integer; Prestige finite and positive")
			overrides[row.rank] = row
		end
	end
	local result: { TitleRequirement } = {}
	local previousLand, previousPrestige = 0, 0
	assert(positive(Config.PrestigePerRequiredProvince), prefix .. "invalid Prestige multiplier")
	for _, base in Config.Ranks do
		assert(positive(base.ratio) and base.ratio <= 1, prefix .. "rank ratio must be in (0,1]")
		local override = overrides[base.rank]
		local land = if override then override.territoryCount else math.ceil(count * base.ratio)
		local prestige = if override then override.prestige else land * Config.PrestigePerRequiredProvince
		assert(positive(land) and land % 1 == 0 and land <= count and positive(prestige), prefix .. "requirements exceed available conquerable land or are invalid")
		assert(land > previousLand and prestige > previousPrestige, prefix .. "ranks must strictly increase; tiny/rounded maps need valid explicit overrides or an approved rank policy")
		local row = { rank = base.rank, titleName = base.titleName, establishLabel = base.establishLabel,
			establishedNotice = base.establishedNotice, territoryCount = land, prestige = prestige }
		table.insert(result, table.freeze(row))
		previousLand, previousPrestige = land, prestige
	end
	return table.freeze(result)
end
function Requirements.ForRank(resolved: { TitleRequirement }, rank: number): TitleRequirement?
	for _, row in resolved do if row.rank == rank then return row end end
	return nil
end
return Requirements
