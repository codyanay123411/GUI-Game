--!strict
local Config = require(script.Parent.Parent.Config.BuildingConfig)
local Policy = {}
function Policy.Income(level: number): number
	return Config.FarmIncome[level] or 0
end
function Policy.Check(level: number, expected: any, revision: number, expectedRevision: any, owned: boolean, ended: boolean, gold: number, costs: any?): (boolean, string, number)
	if ended then return false, "Match ended · Inspection only", 0 end
	if not owned then return false, "Personally owned province required", 0 end
	if expected ~= level or expectedRevision ~= revision then return false, "Province or building changed. Review current state.", 0 end
	local cost = (costs or Config.FarmCosts)[level + 1]
	if not cost then return false, "Maximum level 5", 0 end
	if gold < cost then return false, string.format("Need %d Gold · You have %g", cost, gold), cost end
	return true, "Explicit purchase required", cost
end
return Policy
