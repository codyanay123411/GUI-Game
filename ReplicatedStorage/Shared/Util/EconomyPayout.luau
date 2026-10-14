--!strict

--[[
	Translates configured Gold/minute into the V0.1 global payout interval.

	Territory config stores Gold per minute, not "+1 per 6 seconds".
	Farm-stage production may pay fractional Gold; fixed-point carry preserves it.
	Configured whole Gold/minute at the six-second cadence yields tenths before rank.
]]

local EconomyConfig = require(script.Parent.Parent.Config.EconomyConfig)

local EconomyPayout = {}

function EconomyPayout.IntervalSeconds(): number
	return EconomyConfig.PayoutIntervalSeconds
end

function EconomyPayout.GoldPerTick(goldPerMinute: number): number?
	if typeof(goldPerMinute) ~= "number" then
		return nil
	end
	if goldPerMinute < 0 or goldPerMinute ~= goldPerMinute or goldPerMinute == math.huge then
		return nil
	end
	if goldPerMinute ~= math.floor(goldPerMinute) then
		return nil
	end
	local interval = EconomyConfig.PayoutIntervalSeconds
	local numerator = goldPerMinute * interval
	return numerator / 60
end

function EconomyPayout.ValidateTerritoryIncome(territoryId: string, goldPerMinute: any): (boolean, string?)
	if typeof(goldPerMinute) ~= "number" then
		return false, string.format("Territory %s missing numeric baseGoldIncome (Gold/min).", territoryId)
	end
	if EconomyPayout.GoldPerTick(goldPerMinute) == nil then
		return false,
			string.format(
				"Territory %s baseGoldIncome %s Gold/min is not valid finite whole Gold/minute at %ss.",
				territoryId,
				tostring(goldPerMinute),
				tostring(EconomyConfig.PayoutIntervalSeconds)
			)
	end
	return true, nil
end

function EconomyPayout.ValidateMap(mapDef: any): (boolean, string?)
	if typeof(mapDef) ~= "table" or typeof(mapDef.territories) ~= "table" then
		return false, "Map definition has no territories."
	end
	for _, t in mapDef.territories do
		if typeof(t) ~= "table" or typeof(t.id) ~= "string" then
			return false, "Map territory is missing id."
		end
		local ok, err = EconomyPayout.ValidateTerritoryIncome(t.id, t.baseGoldIncome)
		if not ok then
			return false, err
		end
	end
	return true, nil
end

function EconomyPayout.RankBonusPercent(rank: number): number
	return (EconomyConfig.RankBonusBasisPoints[rank] or 0) / 100
end

function EconomyPayout.IncomeWithRank(baseIncome: number, rank: number): number
	return baseIncome * (10000 + (EconomyConfig.RankBonusBasisPoints[rank] or 0)) / 10000
end

-- Only personal province payouts call this. Grants/start/spending never enter it.
function EconomyPayout.CreditWithRank(basePayout: number, rank: number, remainder: number): (number, number)
	assert(basePayout >= 0 and basePayout < math.huge, "Invalid base payout")
	assert(remainder >= 0 and remainder < 10000 and remainder % 1 == 0, "Invalid Gold remainder")
	-- Whole Gold/minute, six-second ticks and configured basis points yield integer units; round binary noise only.
	local units = math.round(basePayout * (10000 + (EconomyConfig.RankBonusBasisPoints[rank] or 0))) + remainder
	return math.floor(units / 10000), units % 10000
end

return EconomyPayout
