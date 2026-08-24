--!strict

--[[
	Project Admin Bridge V0.1.

	Kohl's Admin (and Studio debug) call this module. Gameplay services do not
	require Kohl. All mutations go through existing authoritative APIs.
]]

local HttpService = game:GetService("HttpService")

local AdminConfig = require(script.Parent.AdminConfig)
local Hierarchy = require(script.Parent.PoliticalHierarchyService)
local Territory = require(script.Parent.TerritoryMapService)
local Title = require(script.Parent.TitleProgressionService)
local Warfare = require(script.Parent.WarfareService)

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
		"AdminBridge V0.1 operations (GameTester UserId, server-enforced):",
		"InspectWars",
		"InspectTerritory <territoryId>",
		"InspectRuler <rulerId>",
		"SetOwner <territoryId> <rulerId|unclaimed>",
		"SetPrestige <rulerId> <number>",
		"ResolveWar <warId> Attacker|Defender",
		"Studio: ServerScriptService.AdminDebug.Invoke",
		"Existing per-system debug folders remain.",
	}, "\n")
end

local function inspectWars(): (boolean, string)
	local snap = Warfare.GetSnapshot()
	return true, HttpService:JSONEncode(snap)
end

local function inspectTerritory(territoryId: string): (boolean, string)
	if typeof(territoryId) ~= "string" or territoryId == "" then
		return fail("Need territoryId.")
	end
	local owner = Territory.GetOwnerRulerId(territoryId)
	return true, HttpService:JSONEncode({
		territoryId = territoryId,
		hasOwner = owner ~= nil,
		ownerRulerId = owner or "",
	})
end

local function inspectRuler(rulerId: string): (boolean, string)
	if typeof(rulerId) ~= "string" or rulerId == "" then
		return fail("Need rulerId.")
	end
	local asUser = tonumber(rulerId)
	if asUser then
		local mapped = Hierarchy.GetRulerIdForUserId(asUser)
		if mapped then
			rulerId = mapped
		end
	end
	for _, ruler in Hierarchy.GetSnapshot().rulers do
		if ruler.rulerId == rulerId then
			return true, HttpService:JSONEncode(ruler)
		end
	end
	return fail("Ruler not found.")
end

local function setOwner(territoryId: string, rulerId: string): (boolean, string)
	if typeof(territoryId) ~= "string" or territoryId == "" then
		return fail("Need territoryId.")
	end
	if typeof(rulerId) ~= "string" then
		return fail("Need rulerId or unclaimed.")
	end
	local target: string? = rulerId
	if rulerId == "" or string.lower(rulerId) == "unclaimed" then
		target = nil
	end
	return Territory.SetOwner(territoryId, target)
end

local function setPrestige(rulerId: string, valueAny: any): (boolean, string)
	if typeof(rulerId) ~= "string" or rulerId == "" then
		return fail("Need rulerId.")
	end
	local value = tonumber(valueAny)
	if value == nil then
		return fail("Need numeric Prestige.")
	end
	local ok, err = pcall(function()
		Title.DebugSetPrestige(rulerId, value)
	end)
	if not ok then
		return fail(tostring(err))
	end
	return true, "Prestige set."
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
function AdminBridge.Execute(actorUserId: number?, operation: string, a: any, b: any, c: any): (boolean, string)
	if actorUserId ~= nil then
		if not AdminConfig.IsGameTester(actorUserId) then
			print("[Admin] denied userId", actorUserId, operation)
			return fail("Not a GameTester.")
		end
	end
	if typeof(operation) ~= "string" then
		return fail("Need operation.")
	end
	local op = operation
	print("[Admin] Execute", actorUserId or "studio", op, a, b, c)
	if op == "Help" then
		return true, AdminBridge.HelpText()
	elseif op == "InspectWars" then
		return inspectWars()
	elseif op == "InspectTerritory" then
		return inspectTerritory(a)
	elseif op == "InspectRuler" then
		return inspectRuler(a)
	elseif op == "SetOwner" then
		return setOwner(a, b)
	elseif op == "SetPrestige" then
		return setPrestige(a, b)
	elseif op == "ResolveWar" then
		return resolveWar(a, b)
	end
	local _ = c
	return fail("Unknown operation.")
end

return AdminBridge
