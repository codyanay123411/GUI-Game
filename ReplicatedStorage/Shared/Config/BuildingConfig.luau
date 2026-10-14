--!strict
-- Current-level totals replace earlier levels. Initial playtest tuning.
return table.freeze({
	FarmCosts = table.freeze({ 10, 15, 20, 30, 40 }),
	FarmIncome = table.freeze({ 2, 5, 9, 14, 20 }),
	TownCosts = table.freeze({ 10, 15, 20, 30, 40 }),
	TownCapacity = table.freeze({ 100, 250, 450, 700, 1000 }),
	TownPriceTenths = table.freeze({ 98, 96, 94, 92, 90 }),
	BaseArmyCap = 500,
	RecruitBatchTroops = 10,
	BaseRecruitPriceTenths = 100,
	CastleCosts = table.freeze({ 10, 15, 20, 30, 40 }),
	CastleStrength = table.freeze({ 100, 200, 300, 400, 500 }),
	CapitalCosts = table.freeze({ 15, 25, 35, 45, 60 }),
	CapitalDefense = table.freeze({ .10, .10, .10, .15, .15 }),
	CapitalCombat = table.freeze({ 0, .05, .15, .15, .15 }),
	CapitalPrestige = table.freeze({ 0, 0, 0, 0, .10 }),
	NoCapitalDefense = -.05,
	CaptureDamageProbabilityMin = .40,
	CaptureDamageProbabilityMax = .60,
	RepairPriceFraction = .50,
})
