--!strict
-- Owns province building levels only; Economy remains spending/payout authority.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local Territory = require(script.Parent.TerritoryMapService)
local Hierarchy = require(script.Parent.PoliticalHierarchyService)
local Economy = require(script.Parent.EconomyService)
local Match = require(script.Parent.MatchState)
local Config = require(ReplicatedStorage.Shared.Config.BuildingConfig)
local Buildings = require(ReplicatedStorage.Shared.Util.BuildingPolicy)
local Policy = require(ReplicatedStorage.Shared.Util.FarmPolicy)
local Service = {}
local changed = Instance.new("BindableEvent")
Service.Changed = changed.Event
local started = false
local levels: { [string]: { [string]: number } } = {}
local receipts: { [Player]: any } = {}
local damage: { [string]: { [string]: boolean } } = {}
local capitals: { [string]: string } = {}
local ruins: { [string]: boolean } = {}
local blockers: { [string]: string } = {}
local captures: { [string]: boolean } = {}
local rng = Random.new()
local capitalRevision: { [string]: number } = {}
function Service.SetVerificationRandom(random)
	assert(game:GetService("RunService"):IsStudio(), "Verification random is Studio-only")
	rng = random or Random.new()
end
function Service.IsDamaged(id: string, kind: string): boolean return damage[id] ~= nil and damage[id][kind] == true end
function Service.GetEffectiveLevel(id: string, kind: string): number
	return if Service.IsDamaged(id, kind) then 0 else Service.GetLevel(id, kind)
end
function Service.GetCapitalLevel(rulerId: string): number
	local id = capitals[rulerId]
	return if id and Territory.GetOwnerRulerId(id) == rulerId then Service.GetEffectiveLevel(id, "Capital") else 0
end
function Service.GetCapital(rulerId: string): string? return capitals[rulerId] end
function Service.OwnershipBoundary(id: string, previous: string?, nextOwner: string?, at: number)
	if previous and previous ~= nextOwner and capitals[previous] == id then
		capitals[previous] = nil;ruins[id] = true
		require(script.Parent.TitleProgressionService).RefreshCapital(previous, at)
	end
end
function Service.RefreshBlockers()
	local roots = {}
	for _, r in Hierarchy.GetSnapshot().rulers do roots[r.rulerId] = r.rootRulerId end
	for _, p in Territory.GetMapDefinition().territories do
		local owner = Territory.GetOwnerRulerId(p.id)
		if owner and roots[owner] then for _, other in p.adjacentIds do
			local neighbor = Territory.GetOwnerRulerId(other)
			if neighbor and roots[neighbor] and roots[neighbor] ~= roots[owner] then blockers[owner] = "Foreign realm bordered personal land this match." end
		end end
	end
end
function Service.NavalLanded(id: string)
	local owner = Territory.GetOwnerRulerId(id)
	if owner then blockers[owner] = "Enemy naval transport landed on personal land this match.";Service.PublishMatch() end
end
function Service.GetPlacementReason(rulerId: string): string
	Service.RefreshBlockers()
	return blockers[rulerId] or ""
end
local function settleCapital(rulerId: string): number
	return require(script.Parent.TitleProgressionService).SettleCapital(rulerId)
end
local function refreshEffects(rulerId: string?)
	if rulerId then require(script.Parent.TitleProgressionService).RefreshCapital(rulerId) end
	changed:Fire(); Economy.PublishMatch(); Service.PublishMatch()
end
function Service.AcceptBattleCapture(receipt: string, id: string, previous: string?, attacker: string)
	if captures[receipt] then return end
	captures[receipt] = true
	local capitalOwner = nil
	for owner, province in capitals do if province == id then capitalOwner = owner end end
	local probability = Buildings.CaptureProbability(rng:NextNumber())
	damage[id] = damage[id] or {}
	for _, kind in {"Farm", "Town", "Castle", "Capital"} do
		if not (kind == "Capital" and ruins[id]) and Service.GetLevel(id, kind) > 0 and not Service.IsDamaged(id, kind) and rng:NextNumber() < probability then damage[id][kind] = true end
	end
	if capitalOwner then
		local boundary = settleCapital(capitalOwner);capitals[capitalOwner] = nil;ruins[id] = true
		require(script.Parent.TitleProgressionService).RefreshCapital(capitalOwner, boundary)
		require(script.Parent.MilitaryService).RetireEliminated(capitalOwner)
		local holdings = table.clone(Territory.GetOwnedTerritoryIds(capitalOwner))
		for _, province in holdings do assert(Territory.SetOwner(province, attacker)) end
		Hierarchy.Eliminate(capitalOwner)
	end
	refreshEffects(previous)
end
local push: RemoteEvent
local function remote(name: string): RemoteEvent
	local folder = ReplicatedStorage:WaitForChild("Remotes")
	local found = folder:FindFirstChild(name)
	if found then assert(found:IsA("RemoteEvent")); return found end
	local value = Instance.new("RemoteEvent"); value.Name = name; value.Parent = folder
	return value
end
function Service.GetLevel(id: string, kind: string): number return if levels[id] then levels[id][kind] or 0 else 0 end
function Service.GetFarmLevel(id: string): number return Service.GetLevel(id, "Farm") end
function Service.GetArmyCap(rulerId: string): number
	local townLevels = {}
	for _, id in Territory.GetOwnedTerritoryIds(rulerId) do table.insert(townLevels, Service.GetEffectiveLevel(id, "Town")) end
	return Buildings.Capacity(townLevels)
end
function Service.GetRecruitPriceTenths(id: string): number return Buildings.PriceTenths(Service.GetEffectiveLevel(id, "Town")) end
function Service.GetProvinceIncome(id: string): number return Policy.Income(Service.GetEffectiveLevel(id, "Farm")) end
function Service.GetSnapshot(): any
	local rows = {}
	for _, province in Territory.GetMapDefinition().territories do
		table.insert(rows, { territoryId = province.id, farmLevel = Service.GetFarmLevel(province.id), townLevel = Service.GetLevel(province.id, "Town"), castleLevel = Service.GetLevel(province.id, "Castle"), capitalLevel = if ruins[province.id] then 0 else Service.GetLevel(province.id, "Capital"), ruin = ruins[province.id] == true, damage = (function() local d = table.clone(damage[province.id] or {});if ruins[province.id] then d.Capital = nil end;return d end)(),
			ownershipRevision = Territory.GetOwnershipRevision(province.id) })
	end
	return { provinces = rows }
end
function Service.PublishMatch()
	if not started then return end
	for _, player in Players:GetPlayers() do
		local state = Service.GetSnapshot()
		local ruler = Hierarchy.GetRulerIdForUserId(player.UserId)
		state.capitalProvince = if ruler then capitals[ruler] else nil
		state.capitalRevision = if ruler then capitalRevision[ruler] or 0 else 0
		state.capitalLevel = if ruler and capitals[ruler] then Service.GetLevel(capitals[ruler], "Capital") else 0
		state.placementReason = if ruler then Service.GetPlacementReason(ruler) else "Eliminated or no active ruler."
		state.eliminated = Hierarchy.IsEliminated(player.UserId)
		Match.Send(push, player, "State", HttpService:JSONEncode(state))
	end
end
function Service.PurchaseBuilding(player: Player, kind: any, id: any, expected: any, revision: any, sequence: any, operation: string?, expectedCapital: number?): any
	operation = operation or "Purchase"
	local result: any = { requestId = 0, territoryId = if typeof(id) == "string" then string.sub(id, 1, 128) else "", accepted = false, message = "Invalid building request." }
	if typeof(sequence) ~= "number" or sequence % 1 ~= 0 or sequence < 1 or sequence > 2147483647 then return result end
	result.requestId = sequence
	if kind ~= "Farm" and kind ~= "Town" and kind ~= "Castle" and kind ~= "Capital" then return result end
	result.building = kind; result.operation = operation;result.expectedCapital = expectedCapital
	if typeof(expected) ~= "number" or expected % 1 ~= 0 or expected < 0 or expected > 5 or typeof(revision) ~= "number" or revision % 1 ~= 0 or revision < 0 or revision > 9007199254740991 then return result end
	local prior = receipts[player]
	if prior and sequence <= prior.requestId then
		if sequence == prior.requestId and id == prior.territoryId and expected == prior.expected and revision == prior.revision and kind == prior.building and operation == prior.operation and expectedCapital == prior.expectedCapital then return prior end
		result.message = "Stale or altered request. Review the building."; return result
	end
	result.expected = expected; result.revision = revision
	if typeof(id) ~= "string" then receipts[player] = result; return result end
	local rulerId = Hierarchy.GetRulerIdForUserId(player.UserId)
	local owned = rulerId ~= nil and Territory.GetOwnerRulerId(id) == rulerId
	if kind == "Capital" and expectedCapital ~= nil and (not rulerId or expectedCapital ~= (capitalRevision[rulerId] or 0)) then result.message = "Capital changed. Review again.";receipts[player] = result;return result end
	local level = Service.GetLevel(id, kind)
	local capitalId = if rulerId then capitals[rulerId] else nil
	if kind == "Capital" and ruins[id] then level = 0 end
	local valid, reasonOverride = true, ""
	local costOverride = nil
	if operation == "Repair" then
		valid = Service.IsDamaged(id, kind) and level == expected
		reasonOverride = "Building changed or does not need Repair."
		costOverride = Buildings.RepairCost(kind, level)
	elseif operation == "Relocate" then
		valid = kind == "Capital" and capitalId ~= nil and capitalId ~= id and level == expected
		reasonOverride = "No active Capital to relocate, or destination changed."
		costOverride = 0
	elseif operation ~= "Purchase" then valid = false;reasonOverride = "Invalid operation."
	elseif Service.IsDamaged(id, kind) then valid = false;reasonOverride = "Repair before upgrading."
	end
	if kind == "Capital" and operation ~= "Repair" then
		if operation == "Relocate" or level == 0 then
			local blocked = if rulerId then Service.GetPlacementReason(rulerId) else "No ruler."
			if blocked ~= "" then valid = false;reasonOverride = blocked end
		end
		if operation == "Purchase" and level == 0 and capitalId then valid = false;reasonOverride = "Relocate your existing Capital here." end
	end
	if not valid then result.message = reasonOverride;receipts[player] = result;return result end
	local ok, reason, cost = Policy.Check(level, expected, Territory.GetOwnershipRevision(id), revision, owned, Match.IsEnded(), if rulerId then Economy.GetBalance(rulerId) else 0, Config[kind .. "Costs"])
	if operation ~= "Purchase" then
		ok = owned and not Match.IsEnded() and expected == level and revision == Territory.GetOwnershipRevision(id) and costOverride ~= nil and Economy.GetBalance(rulerId) >= costOverride
		cost = costOverride or 0; reason = "Ownership, funds or building changed."
	end
	result.message = reason
	if ok and rulerId then
		-- No yields between validation, spend and mutation. No client prices/levels used.
		local paid, message = true, ""
		if cost > 0 then paid, message = Economy.TrySpend(rulerId, cost) end
		if paid then
			levels[id] = levels[id] or {}
			local capitalBoundary = nil
			if kind == "Capital" then capitalBoundary = settleCapital(rulerId);capitalRevision[rulerId] = (capitalRevision[rulerId] or 0) + 1 end
			if operation == "Repair" then damage[id][kind] = nil
			elseif operation == "Relocate" then
				levels[id].Capital = levels[capitalId].Capital
				damage[id] = damage[id] or {};damage[id].Capital = Service.IsDamaged(capitalId, "Capital")
				levels[capitalId].Capital = nil
				if damage[capitalId] then damage[capitalId].Capital = nil end
				capitals[rulerId] = id;ruins[id] = nil
			else levels[id][kind] = level + 1
				if kind == "Capital" then capitals[rulerId] = id;ruins[id] = nil end
			end
			if kind == "Capital" then require(script.Parent.TitleProgressionService).RefreshCapital(rulerId, capitalBoundary) end
			result.accepted = true; result.message = string.format("%s: %s accepted (level %d).", kind, operation, levels[id][kind])
			changed:Fire()
			Economy.PublishMatch(); Service.PublishMatch()
		else result.message = message end
	end
	receipts[player] = result
	return result
end
function Service.Purchase(player: Player, id: any, expected: any, revision: any, sequence: any): any
	return Service.PurchaseBuilding(player, "Farm", id, expected, revision, sequence)
end
function Service.ResetMatch()
	assert(Match.IsResetting()); levels = {}; receipts = {}; damage = {}; capitals = {}; ruins = {}; blockers = {}; captures = {};capitalRevision = {};rng = Random.new()
end
function Service.Start()
	if started then return end
	started = true; push = remote("BuildingsServerEvent")
	Economy.SetBuildingIncomeProvider(Service.GetProvinceIncome)
	Match.ConnectIntent(remote("BuildingsClientEvent"), function(player, action, id, expected, revision, sequence, kind, expectedCapital)
		if action == "Ready" then Service.PublishMatch()
		elseif action == "PurchaseFarm" or action == "PurchaseBuilding" or action == "RepairBuilding" or action == "RelocateCapital" then
			if kind == "Capital" and typeof(expectedCapital) ~= "number" then return end
			local result = Service.PurchaseBuilding(player, if action == "PurchaseFarm" then "Farm" else kind, id, expected, revision, sequence, if action == "RepairBuilding" then "Repair" elseif action == "RelocateCapital" then "Relocate" else "Purchase", expectedCapital)
			Match.Send(push, player, if action == "PurchaseFarm" then "FarmResult" else "BuildingResult", HttpService:JSONEncode(result))
			Service.PublishMatch()
		end
	end)
	Territory.OwnershipChanged:Connect(function()
		for owner, id in capitals do if Territory.GetOwnerRulerId(id) ~= owner then
			settleCapital(owner);capitals[owner] = nil;ruins[id] = true;refreshEffects(owner)
		end end
		Service.RefreshBlockers();Service.PublishMatch()
	end)
	Hierarchy.StateChanged:Connect(function() Service.RefreshBlockers();Service.PublishMatch() end)
	Players.PlayerRemoving:Connect(function(player) receipts[player] = nil end)
end
return Service
