--!strict
local Config = require(script.Parent.Parent.Config.BuildingConfig)
local Policy = {}
function Policy.Capacity(townLevels: { number }): number
	local cap = Config.BaseArmyCap
	for _, level in townLevels do cap += Config.TownCapacity[level] or 0 end
	return cap
end
function Policy.PriceTenths(level: number): number
	return Config.TownPriceTenths[level] or Config.BaseRecruitPriceTenths
end
function Policy.Castle(level: number, allocated: number): (number, number, number)
	local maximum = Config.CastleStrength[level] or 0
	local baseline = maximum * .25
	local requirement = baseline * 3
	local strength = baseline + (maximum - baseline) * (if requirement > 0 then math.clamp(allocated / requirement, 0, 1) else 0)
	return strength, requirement, baseline
end
function Policy.RepairCost(kind: string, level: number): number?
	local costs = Config[kind .. "Costs"]
	if not costs or level % 1 ~= 0 or not costs[level] then return nil end
	return costs[level] * Config.RepairPriceFraction
end
function Policy.Capital(level: number): (number, number, number)
	return Config.CapitalDefense[level] or Config.NoCapitalDefense,
		Config.CapitalCombat[level] or 0, Config.CapitalPrestige[level] or 0
end
-- Server supplies one probability sample and independent healthy-building rolls.
-- Receipts/ownership validation belong to the authoritative capture transaction.
function Policy.CaptureProbability(sample: number): number
	assert(sample >= 0 and sample <= 1, "Damage sample outside unit interval")
	return Config.CaptureDamageProbabilityMin
		+ (Config.CaptureDamageProbabilityMax - Config.CaptureDamageProbabilityMin) * sample
end
return Policy
