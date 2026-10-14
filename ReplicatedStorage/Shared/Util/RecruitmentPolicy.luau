--!strict
-- Preview only; authoritative Military/Economy revalidate identity, price and cap.
local Config = require(script.Parent.Parent.Config.BuildingConfig)
local Buildings = require(script.Parent.BuildingPolicy)
local Policy = {}
Policy.Stops = table.freeze({ 25, 35, 50, 75, 100 })
function Policy.Batches(gold: number, total: number, cap: number, townLevel: number): number
	if gold ~= gold or math.abs(gold) == math.huge or total ~= total or cap ~= cap then return 0 end
	local goldTenths = math.max(0, math.floor(gold * 10 + .000001))
	return math.min(math.floor(goldTenths / Buildings.PriceTenths(townLevel)), math.floor(math.max(0, cap - total) / Config.RecruitBatchTroops))
end
function Policy.Preview(gold: number, percent: number, total: number, cap: number, townLevel: number): (number, number)
	assert(table.find(Policy.Stops, percent), "Only fixed recruitment stops are selectable")
	local batches = math.floor(Policy.Batches(gold, total, cap, townLevel) * percent / 100)
	return batches * Buildings.PriceTenths(townLevel) / 10, batches * Config.RecruitBatchTroops
end
return Policy
