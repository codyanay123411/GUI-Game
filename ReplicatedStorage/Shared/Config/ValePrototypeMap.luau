--!strict

--[[
	V0.1 test map preset: 16 irregular quads on a jittered 4x4 lattice.
	This is one MapConfiguration, not a universal territory count.
	Ownership is never stored here.
]]

local NAMES = {
	{ "westmere", "Westmere" },
	{ "northvale", "Northvale" },
	{ "greyfen", "Greyfen" },
	{ "highmarch", "Highmarch" },
	{ "ashwood", "Ashwood" },
	{ "riverholt", "Riverholt" },
	{ "frostfield", "Frostfield" },
	{ "sunbarrow", "Sunbarrow" },
	{ "mossbank", "Mossbank" },
	{ "ironlea", "Ironlea" },
	{ "duskfen", "Duskfen" },
	{ "goldmere", "Goldmere" },
	{ "stoneford", "Stoneford" },
	{ "ravenreach", "Ravenreach" },
	{ "lowmarsh", "Lowmarsh" },
	{ "brightfen", "Brightfen" },
}

-- 5x5 lattice (map units). Interior jitter keeps quads irregular without gaps.
local GRID: { { { number } } } = {
	{ { 0, 0 }, { 198, 12 }, { 402, -6 }, { 604, 10 }, { 800, 2 } },
	{ { 10, 158 }, { 190, 172 }, { 408, 150 }, { 592, 166 }, { 790, 154 } },
	{ { -4, 318 }, { 204, 302 }, { 396, 324 }, { 610, 308 }, { 804, 316 } },
	{ { 8, 472 }, { 186, 488 }, { 414, 458 }, { 598, 478 }, { 792, 464 } },
	{ { 2, 640 }, { 208, 628 }, { 390, 642 }, { 606, 630 }, { 800, 640 } },
}

local function pt(col: number, row: number): { x: number, y: number }
	local p = GRID[row][col]
	return { x = p[1], y = p[2] }
end

local function cellVerts(col: number, row: number)
	return {
		pt(col, row),
		pt(col + 1, row),
		pt(col + 1, row + 1),
		pt(col, row + 1),
	}
end

local territories = {}
for row = 1, 4 do
	for col = 1, 4 do
		local index = (row - 1) * 4 + col
		local adj = {}
		if col > 1 then
			table.insert(adj, NAMES[index - 1][1])
		end
		if col < 4 then
			table.insert(adj, NAMES[index + 1][1])
		end
		if row > 1 then
			table.insert(adj, NAMES[index - 4][1])
		end
		if row < 4 then
			table.insert(adj, NAMES[index + 4][1])
		end
		table.insert(territories, {
			id = NAMES[index][1],
			displayName = NAMES[index][2],
			polygon = cellVerts(col, row),
			adjacentIds = adj,
		})
	end
end

local ValePrototypeMap = {
	mapId = "vale_prototype_16",
	displayName = "The Vale (Prototype)",
	territories = territories,
}

return ValePrototypeMap
