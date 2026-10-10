-- Offline Luau checks of the actual pure Domination module.
-- Does not substitute for Studio / multiplayer verification.
local Domination = require("../../ReplicatedStorage/Shared/Util/Domination")
local passed = 0
local function check(condition: boolean, label: string)
	assert(condition, label)
	passed += 1
	print("PASS", label)
end
local function mapOf(count: number, percent: number): any
	local map: any = { victory = { type = "Domination", territoryControlPercent = percent }, territories = {} }
	for i = 1, count do table.insert(map.territories, { id = tostring(i) }) end
	return map
end
local function owned(count: number, owner: string): { any }
	local rows = {}
	for i = 1, count do table.insert(rows, { territoryId = tostring(i), ownerRulerId = owner }) end
	return rows
end
local rulers = {
	{ rulerId = "root", rootRulerId = "root", independent = true },
	{ rulerId = "subject", rootRulerId = "root", independent = false },
	{ rulerId = "leaf", rootRulerId = "root", independent = false },
	{ rulerId = "other", rootRulerId = "other", independent = true },
}
local map = mapOf(16, 0.70)
local eleven = owned(11, "root")
local result = Domination.Evaluate(map, rulers, eleven)
check(result.required == 12 and result.total == 16, "map percentage uses ceiling")
check(result.winner == nil, "11 of 16 does not win")
table.insert(eleven, { territoryId = "12", ownerRulerId = "leaf" })
result = Domination.Evaluate(map, rulers, eleven)
check(result.winner.rootId == "root" and result.winner.controlled == 12, "deeper descendant pushes root over threshold")
check(result.counts.leaf == nil, "subject is not a separate winner")
check(Domination.Evaluate(map, rulers, owned(8, "root")).winner == nil, "Unclaimed land remains in world denominator")
check(Domination.Evaluate(mapOf(10, 0.70), rulers, owned(7, "root")).required == 7, "10-territory map")
check(Domination.Evaluate(mapOf(17, 0.70), rulers, owned(11, "root")).required == 12, "17-territory map")
check(Domination.Evaluate(mapOf(1, 0.70), rulers, owned(1, "root")).winner.rootId == "root", "one-territory configuration")
local split = owned(11, "root")
table.insert(split, { territoryId = "12", ownerRulerId = "subject" })
table.insert(split, { territoryId = "13", ownerRulerId = "leaf" })
check(Domination.Evaluate(map, rulers, split).counts.root == 13, "root/direct/deeper holdings all counted")
rulers[2].rootRulerId = "subject"; rulers[2].independent = true
rulers[3].rootRulerId = "subject"
result = Domination.Evaluate(map, rulers, split)
check(result.counts.root == 11 and result.counts.subject == 2 and result.winner == nil, "independence drops former realm below threshold before end")
rulers[2].rootRulerId = "root"; rulers[2].independent = false; rulers[3].rootRulerId = "root"
check(Domination.Evaluate(map, rulers, split).winner.rootId == "root", "fealty can cross domination threshold")
check(Domination.Evaluate(map, {}, split).winner == nil, "removed roots cannot win")
check(Domination.Evaluate(map, rulers, owned(16, "missing")).winner == nil, "unknown owner ignored")
map.territories[16].conquerable = false
result = Domination.Evaluate(map, rulers, owned(16, "root"))
check(result.total == 15 and result.required == 11 and result.winner.controlled == 15, "nonconquerable land excluded from both counts")
local tie = owned(8, "root")
for i = 9, 16 do table.insert(tie, { territoryId = tostring(i), ownerRulerId = "other" }) end
check(Domination.Evaluate(mapOf(16, 0.50), rulers, tie).winner.rootId == "other", "deterministic equal candidate fallback")
for _, percent in { 0, -1, 1.1, math.huge, 0 / 0 } do
	check(not pcall(Domination.Evaluate, mapOf(16, percent), rulers, split), "invalid threshold rejected")
end
check(not pcall(Domination.Evaluate, mapOf(0, 0.70), rulers, {}), "empty map rejected")
local State = require("../../ServerScriptService/Services/MatchState")
check(not State.IsEnded(), "match begins active")
local final = { ended = true, winnerRootId = "root" }
check(State.End(final) and State.IsEnded(), "first result ends match")
check(not State.End({ winnerRootId = "other" }) and State.GetFinal() == final, "end is idempotent and first winner retained")
print("DOMINATION_PURE_CHECKS_PASS", passed)
