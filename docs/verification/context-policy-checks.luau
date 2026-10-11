--!strict
-- Run in Studio edit Command Bar after loading current sources. Pure fixtures only.
local Resolver = require(game.ReplicatedStorage.Shared.Util.ContextActionResolver)
local Attention = require(game.ReplicatedStorage.Shared.Util.MapAttentionPolicy)
local definitions = require(game.ReplicatedStorage.Shared.Config.MapCatalog).GetDefault().territories
local passed = 0
local function check(value: any, description: string)
	assert(value, description)
	passed += 1
end
local function has(context: any, id: string): boolean
	for _, action in context.actions do if action.id == id then return true end end
	return false
end
local function channel(context: any, label: string): boolean
	for _, item in context.communication do if item.label == label then return true end end
	return false
end
local function ruler(id: string, userId: number): any
	return { rulerId = id, userId = userId, hasUser = true, displayName = id, titleName = "Lord", titleRank = 1,
		independent = true, rootRulerId = id, liegeId = "", vassalIds = {} }
end
local a, b, c = ruler("a", 1), ruler("b", 2), ruler("c", 3)
local state: any = { hierarchy = { rulers = { a, b, c }, requests = {} }, territory = { territories = {} },
	diplomacy = { agreements = {}, requests = {} }, warfare = { wars = {}, cooldowns = {} },
	military = { available = 1000, wars = {} }, communications = { contacts = { { userId = 2 } }, contexts = {
		{ id = "diplomatic", kind = "diplomatic", label = "Diplomatic", canSend = true } } } }
for _, t in definitions do
	table.insert(state.territory.territories, { territoryId = t.id, ownerRulerId = "", neutralDefense = { current = 300, maximum = 300, revision = 0 } })
end
local function own(id: string, owner: string)
	for _, t in state.territory.territories do if t.territoryId == id then t.ownerRulerId = owner end end
end
local function resolve(id: string, ended: boolean?): any
	return Resolver.Resolve(state, definitions, id, 1, ended == true, 100)
end
own("westmere", "a"); own("northvale", "b"); own("brightfen", "c")
check(has(resolve("westmere"), "Military") and not has(resolve("westmere"), "War"), "Self has military, no external war")
check(has(resolve("northvale"), "War"), "Neighbor supports war review")
check(channel(resolve("northvale"), "Direct"), "Direct comes from authoritative contact")
check(channel(resolve("northvale"), "Diplomatic"), "Adjacent target within Diplomatic reach")
check(not has(resolve("brightfen"), "War"), "Distant target has no war")
check(not channel(resolve("brightfen"), "Direct"), "Distant target no false Direct")
check(not channel(resolve("brightfen"), "Diplomatic"), "Disconnected realm no false Diplomatic recipient")
check(has(resolve("ashwood"), "War"), "Unclaimed neighbor conquer")
check(resolve("ashwood").province.neutralDefense.current == 300, "Militia uses public current value")
check(not has(resolve("northvale", true), "War") and not has(resolve("northvale", true), "Diplomacy"), "End gate removes competitive actions")
local agreement = { leftRulerId = "a", rightRulerId = "b", alliance = true, nap = false, allianceInstanceId = "ab" }
state.diplomacy.agreements = { agreement }
table.insert(state.communications.contexts, { id = "alliance:ab", kind = "alliance", label = "Allies", canSend = true })
check(resolve("northvale").relation == "Ally", "Alliance relation")
check(has(resolve("northvale"), "War"), "Alliance preserves existing war rule")
check(channel(resolve("northvale"), "Allies"), "Distinct authoritative alliance channel")
agreement.nap = true
check(not has(resolve("northvale"), "War"), "NAP blocks war")
check(channel(resolve("northvale"), "Direct"), "NAP does not alter Direct")
state.diplomacy.agreements = {}
b.liegeId = "a"; b.rootRulerId = "a"; b.independent = false; a.vassalIds = { "b" }
table.insert(state.communications.contexts, { id = "council:a", kind = "council", label = "Council", canSend = true })
check(resolve("northvale").relation == "Your direct subject", "Direct subject relation")
check(channel(resolve("northvale"), "Council") and channel(resolve("northvale"), "Direct"), "Same-root adjacency Council plus Direct")
check(not has(resolve("northvale"), "War"), "No war against own subject")
state.communications.contacts = {}
own("northvale", ""); own("brightfen", "b")
check(channel(resolve("brightfen"), "Council") and not channel(resolve("brightfen"), "Direct"), "Same-root distant Council only")
own("northvale", "b")
check(has(resolve("greyfen"), "War"), "Root may use subject border")
a.independent = false; a.rootRulerId = "b"; a.liegeId = "b"; a.vassalIds = {}; b.independent = true; b.rootRulerId = "b"; b.liegeId = ""; b.vassalIds = { "a" }
check(not has(resolve("ashwood"), "War"), "Subject cannot declare external war")
check(resolve("northvale").relation == "Your liege", "Liege relation")
a.independent = true; a.rootRulerId = "a"; a.liegeId = ""; b.rootRulerId = "b"
state.warfare.wars = { { warId = "ab", targetTerritoryId = "northvale", attackerRootId = "a", defenderRootId = "b" } }
check(has(resolve("northvale"), "Battle") and not has(resolve("northvale"), "War"), "Relevant contest opens battle")
state.warfare.wars = { { warId = "bc", targetTerritoryId = "northvale", attackerRootId = "c", defenderRootId = "b" } }
check(not has(resolve("northvale"), "Battle") and not has(resolve("northvale"), "War"), "Unrelated contested target hidden")
state.warfare.wars = {}; state.warfare.cooldowns = { { territoryId = "northvale", endsAt = 110 } }
check(not has(resolve("northvale"), "War"), "Cooldown hides declaration")
state.warfare.cooldowns[1].endsAt = 90
check(has(resolve("northvale"), "War"), "Expired cooldown allows prediction")
own("northvale", "b"); own("highmarch", "b"); own("brightfen", "c")
check(Attention.NearestTerritory(definitions, state.territory.territories, state.hierarchy.rulers, "b", "a") == "northvale", "Sender border province preferred")
local distant = Attention.NearestTerritory(definitions, state.territory.territories, state.hierarchy.rulers, "c", "a")
check(distant == "brightfen", "Distant sender has stable personal province")
check(Attention.NearestTerritory(definitions, state.territory.territories, state.hierarchy.rulers, "missing", "a") == nil, "Removed ruler no anchor")
local grouped = Attention.Aggregate({ m = { id = "m", territoryId = "northvale", priority = 1, count = 2 },
	w = { id = "w", territoryId = "northvale", priority = 3 }, d = { id = "d", territoryId = "highmarch", priority = 2 } })
check(grouped.northvale.count == 3 and grouped.northvale.event.id == "w", "Highest-priority aggregation/count")
check(grouped.highmarch.count == 1, "Distinct province stays distinct")
print("CONTEXT_POLICY_PASS", passed)
