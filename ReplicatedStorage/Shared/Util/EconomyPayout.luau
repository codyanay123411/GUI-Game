--!strict

--[[
	Translates configured Gold/minute into the V0.1 global payout interval.

	Territory config stores Gold per minute, not "+1 per 6 seconds".
	V0.1 requires that (goldPerMinute * intervalSeconds / 60) is a whole number.
	No fractional carry is implemented.
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
	if goldPerMinute < 0 or goldPerMinute ~= goldPerMinute then
		return nil
	end
	if goldPerMinute ~= math.floor(goldPerMinute) then
		return nil
	end
	local interval = EconomyConfig.PayoutIntervalSeconds
	local numerator = goldPerMinute * interval
	if numerator % 60 ~= 0 then
		return nil
	end
	return numerator / 60
end

function EconomyPayout.ValidateTerritoryIncome(territoryId: string, goldPerMinute: any): (boolean, string?)
	if typeof(goldPerMinute) ~= "number" then
		return false, string.format("Territory %s missing numeric baseGoldIncome (Gold/min).", territoryId)
	end
	if EconomyPayout.GoldPerTick(goldPerMinute) == nil then
		return false,
			string.format(
				"Territory %s baseGoldIncome %s Gold/min is not a whole payout at %ss (goldPerMinute * interval / 60 must be a whole number).",
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

return EconomyPayout
