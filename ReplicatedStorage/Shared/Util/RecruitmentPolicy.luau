--!strict
-- Preview only. MilitaryService.Recruit revalidates cost, funds and match state.
local Config = require(script.Parent.Parent.Config.MilitaryConfig)
local Policy = {}
Policy.Stops = table.freeze({ 25, 35, 50, 75, 100 })

function Policy.Preview(gold: number, percent: number): (number, number)
	assert(table.find(Policy.Stops, percent), "Only fixed recruitment stops are selectable")
	local spendable = if gold == gold and math.abs(gold) < math.huge then math.max(0, math.floor(gold)) else 0
	local cost = math.floor(spendable * percent / 100)
	return cost, cost * Config.TroopsPerGold
end

return Policy
