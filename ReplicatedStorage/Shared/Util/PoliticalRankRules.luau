--!strict

--[[
	Shared rank names and the approved voluntary-vassalage rank rule.
	The server must still revalidate; clients may use this only for display / UX.
]]

local PoliticalRankRules = {}

PoliticalRankRules.Lord = 1
PoliticalRankRules.Duke = 2
PoliticalRankRules.King = 3
PoliticalRankRules.Emperor = 4

local NAMES: { [number]: string } = {
	[1] = "Lord",
	[2] = "Duke",
	[3] = "King",
	[4] = "Emperor",
}

function PoliticalRankRules.IsValidRank(rank: number): boolean
	return rank == 1 or rank == 2 or rank == 3 or rank == 4
end

function PoliticalRankRules.Name(rank: number): string
	return NAMES[rank] or "Unknown"
end

-- vassal becomes the vassal of liege: liege rank must be >= vassal rank
function PoliticalRankRules.CanBecomeVassalOf(vassalRank: number, liegeRank: number): boolean
	if not PoliticalRankRules.IsValidRank(vassalRank) or not PoliticalRankRules.IsValidRank(liegeRank) then
		return false
	end
	return liegeRank >= vassalRank
end

return PoliticalRankRules
