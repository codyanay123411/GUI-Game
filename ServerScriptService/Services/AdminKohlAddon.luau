--!strict

--[[
	Kohl's Admin addon (shared; gameplay only in server `run`).

	Must live under Kohl's Admin > Config > Addons (tagged "Kohl's Admin Addon").
	Do not put "Client" or "Server" in this ModuleScript's name.
	Does not contain gameplay logic — only AdminBridge.Execute.
	`run` is server-only (Kohl uses runClient on the client).
]]

return function(_K)
	local RunService = game:GetService("RunService")
	local ServerScriptService = game:GetService("ServerScriptService")

	local function runOp(context, operation: string, a: any, b: any)
		if not RunService:IsServer() then
			return
		end
		local userId = context.from
		if typeof(userId) ~= "number" then
			local player = context.fromPlayer
			if typeof(player) == "Instance" and player:IsA("Player") then
				userId = player.UserId
			end
		end
		if typeof(userId) ~= "number" then
			return
		end
		local AdminBridge = require(ServerScriptService.Services.AdminBridge)
		AdminBridge.Execute(userId, operation, a, b, nil)
		-- Kohl Command:run does pcall(run) then treats the first return as an error
		-- string (Process.escapeRichText). Do not return true/false/Execute results.
	end

	local function register(def)
		_K.Registry.registerCommand(_K, def)
	end

	register({
		name = "adminhelp",
		aliases = { "gameadminhelp" },
		description = "List GameTester project commands (not Kohl rank help).",
		group = "Creator",
		run = function(context)
			runOp(context, "Help")
		end,
	})

	register({
		name = "inspectwars",
		aliases = { "warsnapshot" },
		description = "List active territory-specific wars.",
		group = "Creator",
		run = function(context)
			runOp(context, "InspectWars")
		end,
	})

	register({
		name = "inspectterritory",
		description = "Inspect territory ownership.",
		group = "Creator",
		args = {
			{ type = "rawString", name = "territoryId", description = "Territory id (e.g. greyfen)" },
		},
		run = function(context, territoryId)
			runOp(context, "InspectTerritory", territoryId)
		end,
	})

	register({
		name = "inspectruler",
		description = "Inspect a hierarchy ruler.",
		group = "Creator",
		args = {
			{ type = "player # rawString", name = "who", description = "Player, rulerId, or userId" },
		},
		run = function(context, who)
			runOp(context, "InspectRuler", who)
		end,
	})

	register({
		name = "setowner",
		description = "Set territory owner via TerritoryMapService.",
		group = "Creator",
		args = {
			{ type = "rawString", name = "territoryId", description = "Territory id" },
			{ type = "player # rawString", name = "owner", description = "Player, rulerId, or unclaimed" },
		},
		run = function(context, territoryId, owner)
			runOp(context, "SetOwner", territoryId, owner)
		end,
	})

	register({
		name = "setprestige",
		description = "Set Title V0.1 test Prestige (not spent).",
		group = "Creator",
		args = {
			{ type = "player # rawString", name = "who", description = "Player or rulerId" },
			{ type = "number", name = "value", description = "Prestige" },
		},
		run = function(context, who, value)
			runOp(context, "SetPrestige", who, value)
		end,
	})

	register({
		name = "resolvewar",
		aliases = { "warresolve" },
		description = "Resolve a war via WarfareService.DebugResolveWar.",
		group = "Creator",
		args = {
			{ type = "rawString", name = "warId", description = "warId from inspectwars" },
			{ type = "rawString", name = "outcome", description = "attacker or defender" },
		},
		run = function(context, warId, outcome)
			runOp(context, "ResolveWar", warId, outcome)
		end,
	})
end
