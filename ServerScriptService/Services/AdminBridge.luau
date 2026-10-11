--!strict

--[[
	Project Admin Bridge V0.1.

	Kohl's Admin (and Studio debug) call this module. Gameplay services do not
	require Kohl. All mutations go through existing authoritative APIs.
]]

local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local AdminConfig = require(script.Parent.AdminConfig)
local Hierarchy = require(script.Parent.PoliticalHierarchyService)
local Territory = require(script.Parent.TerritoryMapService)
local Title = require(script.Parent.TitleProgressionService)
local Warfare = require(script.Parent.WarfareService)
local Economy = require(script.Parent.EconomyService)
local Military = require(script.Parent.MilitaryService)
local Communications = require(script.Parent.CommunicationsService)

local MatchState = require(script.Parent.MatchState)
local AdminBridge = {}

export type ExecuteResult = {
	ok: boolean,
	message: string,
}

local function fail(message: string): (boolean, string)
	return false, message
end

function AdminBridge.IsGameTester(userId: number): boolean
	return AdminConfig.IsGameTester(userId)
end

function AdminBridge.HelpText(): string
	return table.concat({
		"GameTester commands (authorized UserIds or Kohl SuperAdmin+).",
		"Studio Local Server only: synthetic UserIds < 0 are allowed for testing.",
		";adminhelp",
		";inspectvictory / ;checkvictory",
		";inspectneutral <territoryId>",
		";setneutraldefense <territoryId> <defenders>",
		";inspectwars",
		";inspectterritory <territoryId>",
		";inspectruler <player|rulerId>",
		";setowner <territoryId> <player|rulerId|unclaimed>",
		";setprestige <player|rulerId> <number>",
		";inspectgold <player|rulerId>",
		";setgold <player|rulerId> <number>",
		";addgold <player|rulerId> <number>",
		";spendgold <player|rulerId> <number>",
		";inspecttroops <player|rulerId>",
		";settroops <player|rulerId> <number>",
		";addtroops <player|rulerId> <number>",
		";inspectmilitary <warId>",
		";inspectcomms",
		";inspectcontest",
		";resolvewar <warId> attacker|defender",
		"Studio fallback: ServerScriptService.AdminDebug.Invoke",
	}, "\n")
end

local function rulerLabel(rulerId: string): string
	for _, ruler in Hierarchy.GetSnapshot().rulers do
		if ruler.rulerId == rulerId then
			return string.format("%s (%s)", ruler.displayName, rulerId)
		end
	end
	return rulerId
end

local function firstPlayer(value: any): Player?
	if typeof(value) == "Instance" and value:IsA("Player") then
		return value
	end
	if typeof(value) == "table" then
		local first = (value :: any)[1]
		if typeof(first) == "Instance" and first:IsA("Player") then
			return first
		end
	end
	return nil
end

function AdminBridge.ResolveRulerId(ref: any): (string?, string?)
	if ref == nil then
		return nil, "Need a player, rulerId, or unclaimed."
	end
	local player = firstPlayer(ref)
	if player then
		local mapped = Hierarchy.GetRulerIdForUserId(player.UserId)
		if mapped then
			return mapped, nil
		end
		return nil, "No ruler for player " .. player.Name
	end
	if typeof(ref) ~= "string" then
		ref = tostring(ref)
	end
	local s = ref :: string
	if s == "" then
		return nil, "Need a player, rulerId, or unclaimed."
	end
	local snap = Hierarchy.GetSnapshot()
	for _, ruler in snap.rulers do
		if ruler.rulerId == s then
			return s, nil
		end
	end
	local asUser = tonumber(s)
	if asUser then
		local mapped = Hierarchy.GetRulerIdForUserId(asUser)
		if mapped then
			return mapped, nil
		end
	end
	local lower = string.lower(s)
	for _, p in Players:GetPlayers() do
		if string.lower(p.Name) == lower or string.lower(p.DisplayName) == lower then
			local mapped = Hierarchy.GetRulerIdForUserId(p.UserId)
			if mapped then
				return mapped, nil
			end
			return nil, "No ruler for player " .. p.Name
		end
	end
	for _, ruler in snap.rulers do
		if typeof(ruler.displayName) == "string" and string.lower(ruler.displayName) == lower then
			return ruler.rulerId, nil
		end
	end
	return nil, "Could not resolve ruler: " .. s
end

local function inspectWars(): (boolean, string)
	local snap = Warfare.GetSnapshot()
	local wars = snap.wars or {}
	local cooldowns = snap.cooldowns or {}
	local lines = { string.format("Active wars: %d", #wars) }
	for _, war in wars do
		table.insert(
			lines,
			string.format(
				"%s\n  attacker: %s\n  defender: %s\n  target: %s",
				tostring(war.warId),
				rulerLabel(war.attackerRootId),
				if war.targetKind == "Unclaimed" then "Unclaimed militia" else rulerLabel(war.defenderRootId),
				tostring(war.targetTerritoryId)
			)
		)
	end
	if #cooldowns > 0 then
		table.insert(lines, string.format("Post-war cooldowns: %d", #cooldowns))
		for _, row in cooldowns do
			table.insert(lines, string.format("  %s until %s", tostring(row.territoryId), tostring(row.endsAt)))
		end
	end
	if #wars == 0 and #cooldowns == 0 then
		return true, "No active wars."
	end
	return true, table.concat(lines, "\n")
end

local function inspectTerritory(territoryId: string): (boolean, string)
	if typeof(territoryId) ~= "string" or territoryId == "" then
		return fail("Need territoryId.")
	end
	territoryId = string.lower(territoryId)
	local owner = Territory.GetOwnerRulerId(territoryId)
	return true, HttpService:JSONEncode({
		territoryId = territoryId,
		hasOwner = owner ~= nil,
		ownerRulerId = owner or "",
	})
end

local function inspectRuler(ref: any): (boolean, string)
	local rulerId, err = AdminBridge.ResolveRulerId(ref)
	if not rulerId then
		return fail(err or "Ruler not found.")
	end
	for _, ruler in Hierarchy.GetSnapshot().rulers do
		if ruler.rulerId == rulerId then
			return true, HttpService:JSONEncode(ruler)
		end
	end
	return fail("Ruler not found.")
end

local function setOwner(territoryId: string, ownerRef: any): (boolean, string)
	if typeof(territoryId) ~= "string" or territoryId == "" then
		return fail("Need territoryId.")
	end
	territoryId = string.lower(territoryId)
	if ownerRef == nil then
		return fail("Need player, rulerId, or unclaimed.")
	end
	if typeof(ownerRef) == "string" then
		local lower = string.lower(ownerRef)
		if lower == "" or lower == "unclaimed" then
			return Territory.SetOwner(territoryId, nil)
		end
	end
	local rulerId, err = AdminBridge.ResolveRulerId(ownerRef)
	if not rulerId then
		return fail(err or "Could not resolve owner.")
	end
	return Territory.SetOwner(territoryId, rulerId)
end

local function setPrestige(rulerRef: any, valueAny: any): (boolean, string)
	local rulerId, err = AdminBridge.ResolveRulerId(rulerRef)
	if not rulerId then
		return fail(err or "Need player or rulerId.")
	end
	local value = tonumber(valueAny)
	if value == nil then
		return fail("Need numeric Prestige.")
	end
	local ok, callErr = pcall(function()
		Title.DebugSetPrestige(rulerId, value)
	end)
	if not ok then
		return fail(tostring(callErr))
	end
	return true, string.format("Prestige set to %s for %s.", tostring(value), rulerLabel(rulerId))
end

local function inspectGold(rulerRef: any): (boolean, string)
	local rulerId, err = AdminBridge.ResolveRulerId(rulerRef)
	if not rulerId then
		return fail(err or "Need player or rulerId.")
	end
	local snap = Economy.GetInspect(rulerId)
	if not snap then
		return fail("No economy state for " .. rulerLabel(rulerId))
	end
	return true, HttpService:JSONEncode(snap)
end

local function setGold(rulerRef: any, valueAny: any): (boolean, string)
	local rulerId, err = AdminBridge.ResolveRulerId(rulerRef)
	if not rulerId then
		return fail(err or "Need player or rulerId.")
	end
	local value = tonumber(valueAny)
	if value == nil then
		return fail("Need numeric Gold.")
	end
	return Economy.DebugSetGold(rulerId, value)
end

local function addGold(rulerRef: any, valueAny: any): (boolean, string)
	local rulerId, err = AdminBridge.ResolveRulerId(rulerRef)
	if not rulerId then
		return fail(err or "Need player or rulerId.")
	end
	local value = tonumber(valueAny)
	if value == nil then
		return fail("Need numeric Gold.")
	end
	return Economy.AddGold(rulerId, value)
end

local function spendGold(rulerRef: any, valueAny: any): (boolean, string)
	local rulerId, err = AdminBridge.ResolveRulerId(rulerRef)
	if not rulerId then
		return fail(err or "Need player or rulerId.")
	end
	local value = tonumber(valueAny)
	if value == nil then
		return fail("Need numeric Gold.")
	end
	return Economy.TrySpend(rulerId, value)
end

local function inspectTroops(rulerRef: any): (boolean, string)
	local rulerId, err = AdminBridge.ResolveRulerId(rulerRef)
	if not rulerId then
		return fail(err or "Need player or rulerId.")
	end
	local snap = Military.GetInspect(rulerId)
	if not snap then
		return fail("No troop state for " .. rulerLabel(rulerId))
	end
	return true, HttpService:JSONEncode(snap)
end

local function setTroops(rulerRef: any, valueAny: any): (boolean, string)
	local rulerId, err = AdminBridge.ResolveRulerId(rulerRef)
	if not rulerId then
		return fail(err or "Need player or rulerId.")
	end
	local value = tonumber(valueAny)
	if value == nil then
		return fail("Need numeric Troops.")
	end
	return Military.DebugSetTroops(rulerId, value)
end

local function addTroops(rulerRef: any, valueAny: any): (boolean, string)
	local rulerId, err = AdminBridge.ResolveRulerId(rulerRef)
	if not rulerId then
		return fail(err or "Need player or rulerId.")
	end
	local value = tonumber(valueAny)
	if value == nil then
		return fail("Need numeric Troops.")
	end
	return Military.DebugAddTroops(rulerId, value)
end

local function inspectMilitary(warId: any): (boolean, string)
	if typeof(warId) ~= "string" or warId == "" then
		return fail("Need warId.")
	end
	local snap = Military.GetEngagementInspect(warId)
	if not snap then
		return fail("No military engagement.")
	end
	return true, HttpService:JSONEncode(snap)
end

local function inspectContest(): (boolean, string)
	return true, HttpService:JSONEncode(Warfare.GetContestInspect())
end

local function resolveWar(warId: string, outcome: string): (boolean, string)
	if typeof(warId) ~= "string" or warId == "" then
		return fail("Need warId.")
	end
	if typeof(outcome) ~= "string" then
		return fail("Need Attacker or Defender.")
	end
	local normalized = outcome
	local lower = string.lower(outcome)
	if lower == "attacker" then
		normalized = "Attacker"
	elseif lower == "defender" then
		normalized = "Defender"
	end
	return Warfare.DebugResolveWar(warId, normalized)
end

--[[
	actorUserId: Player.UserId for Kohl/live commands.
	nil = Studio/server BindableFunction (already server-only).
]]
local function pushFeedback(actorUserId: number?, operation: string, ok: boolean, message: string)
	local remotes = ReplicatedStorage:FindFirstChild("Remotes")
	local event = remotes and remotes:FindFirstChild("AdminFeedbackEvent")
	if not (event and event:IsA("RemoteEvent")) then
		return
	end
	local payload = {
		ok = ok,
		operation = operation,
		message = message,
	}
	if actorUserId ~= nil then
		local player = Players:GetPlayerByUserId(actorUserId)
		if player then
			event:FireClient(player, payload)
		end
		return
	end
	for _, player in Players:GetPlayers() do
		if AdminConfig.IsGameTester(player.UserId) then
			event:FireClient(player, payload)
		end
	end
end

function AdminBridge.Execute(actorUserId: number?, operation: string, a: any, b: any, c: any): (boolean, string)
	local function done(ok: boolean, message: string): (boolean, string)
		pushFeedback(actorUserId, if typeof(operation) == "string" then operation else "Unknown", ok, message)
		return ok, message
	end
	if actorUserId ~= nil then
		if not AdminConfig.IsGameTester(actorUserId) then
			print("[Admin] denied userId", actorUserId, operation)
			return done(fail("Not a GameTester."))
		end
	end
	if typeof(operation) ~= "string" then
		return done(fail("Need operation."))
	end
	local op = operation
	if MatchState.IsEnded() and ({ SetOwner = true, SetPrestige = true, SetGold = true, AddGold = true, SpendGold = true, SetTroops = true, AddTroops = true, ResolveWar = true, SetNeutralDefense = true })[op] then return done(false, "Match ended.") end
	print("[Admin] Execute", actorUserId or "studio", op, a, b, c)
	if op == "Help" then
		return done(true, AdminBridge.HelpText())
	elseif op == "InspectVictory" then
		return done(true, HttpService:JSONEncode(require(script.Parent.VictoryService).GetSnapshot()))
	elseif op == "CheckVictory" then
		require(script.Parent.VictoryService).Evaluate()
		return done(true, HttpService:JSONEncode(require(script.Parent.VictoryService).GetSnapshot()))
	elseif op == "InspectNeutral" then
		local state = require(script.Parent.NeutralDefenseService).Get(tostring(a))
		return done(state ~= nil, HttpService:JSONEncode(state or { error = "Not Unclaimed" }))
	elseif op == "SetNeutralDefense" then
		return done(require(script.Parent.NeutralDefenseService).DebugSet(tostring(a), tonumber(b)))
	elseif op == "InspectWars" then
		return done(inspectWars())
	elseif op == "InspectTerritory" then
		return done(inspectTerritory(a))
	elseif op == "InspectRuler" then
		return done(inspectRuler(a))
	elseif op == "SetOwner" then
		return done(setOwner(a, b))
	elseif op == "SetPrestige" then
		return done(setPrestige(a, b))
	elseif op == "InspectGold" then
		return done(inspectGold(a))
	elseif op == "SetGold" then
		return done(setGold(a, b))
	elseif op == "AddGold" then
		return done(addGold(a, b))
	elseif op == "SpendGold" then
		return done(spendGold(a, b))
	elseif op == "InspectTroops" then
		return done(inspectTroops(a))
	elseif op == "SetTroops" then
		return done(setTroops(a, b))
	elseif op == "AddTroops" then
		return done(addTroops(a, b))
	elseif op == "InspectComms" then
		return done(true, HttpService:JSONEncode(Communications.DebugInspect()))
	elseif op == "InspectMilitary" then
		return done(inspectMilitary(a))
	elseif op == "InspectContest" then
		return done(inspectContest())
	elseif op == "ResolveWar" then
		return done(resolveWar(a, b))
	end
	local _ = c
	return done(fail("Unknown operation."))
end

return AdminBridge
