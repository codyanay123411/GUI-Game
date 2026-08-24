--!strict

--[[
	Kohl's Admin addon: registers GameTester commands that call AdminBridge.

	Do not put gameplay logic here. If Kohl is not installed, this module is
	unused until the Director inserts the official loader and this module is
	present under Kohl's Addons folder (AdminService will clone it if found).

	Filename must not contain "Client" or "Server" (Kohl context filter).
]]

return function(_K)
	local ServerScriptService = game:GetService("ServerScriptService")
	local AdminBridge = require(ServerScriptService.Services.AdminBridge)

	local function actorFrom(context): Player?
		if typeof(context) == "Instance" and context:IsA("Player") then
			return context
		end
		if typeof(context) == "table" then
			local from = (context :: any).from or (context :: any).From or (context :: any).player or (context :: any).Player
			if typeof(from) == "Instance" and from:IsA("Player") then
				return from
			end
		end
		return nil
	end

	local function runOp(context, operation: string, a: any, b: any)
		local player = actorFrom(context)
		if not player then
			return "Admin command missing player context."
		end
		local ok, message = AdminBridge.Execute(player.UserId, operation, a, b, nil)
		return if ok then message else ("Failed: " .. message)
	end

	local function register(def)
		_K.Registry.registerCommand(_K, def)
	end

	register({
		name = "inspectwars",
		aliases = { "warsnapshot" },
		description = "Inspect active territory-specific wars (JSON).",
		group = "creator",
		run = function(context)
			return runOp(context, "InspectWars")
		end,
	})

	register({
		name = "inspectterritory",
		description = "Inspect territory ownership.",
		group = "creator",
		args = {
			{ type = "string", name = "territoryId", description = "Territory id" },
		},
		run = function(context, territoryId)
			return runOp(context, "InspectTerritory", territoryId)
		end,
	})

	register({
		name = "inspectruler",
		description = "Inspect a hierarchy ruler snapshot.",
		group = "creator",
		args = {
			{ type = "string", name = "rulerId", description = "rulerId or userId" },
		},
		run = function(context, rulerId)
			return runOp(context, "InspectRuler", rulerId)
		end,
	})

	register({
		name = "setowner",
		description = "Set territory owner via TerritoryMapService (unclaimed to clear).",
		group = "creator",
		args = {
			{ type = "string", name = "territoryId", description = "Territory id" },
			{ type = "string", name = "rulerId", description = "rulerId or unclaimed" },
		},
		run = function(context, territoryId, rulerId)
			return runOp(context, "SetOwner", territoryId, rulerId)
		end,
	})

	register({
		name = "setprestige",
		description = "Set Title V0.1 test Prestige (not spent).",
		group = "creator",
		args = {
			{ type = "string", name = "rulerId", description = "rulerId" },
			{ type = "number", name = "value", description = "Prestige" },
		},
		run = function(context, rulerId, value)
			return runOp(context, "SetPrestige", rulerId, value)
		end,
	})

	register({
		name = "resolvewar",
		aliases = { "warresolve" },
		description = "Resolve a war via WarfareService.DebugResolveWar.",
		group = "creator",
		args = {
			{ type = "string", name = "warId", description = "warId" },
			{ type = "string", name = "outcome", description = "Attacker or Defender" },
		},
		run = function(context, warId, outcome)
			return runOp(context, "ResolveWar", warId, outcome)
		end,
	})
end
