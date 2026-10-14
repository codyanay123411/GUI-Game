--!strict

--[[
	Kohl's Admin addon (shared; gameplay only in server `run`).

	Must live under Kohl's Admin > Config > Addons (tagged "Kohl's Admin Addon").
	Do not put "Client" or "Server" in this ModuleScript's name.
	Does not contain gameplay logic — only AdminBridge.Execute.
	`run` is server-only (Kohl uses runClient on the client).
]]

return function(_K)
	local Players = game:GetService("Players")
	local RunService = game:GetService("RunService")
	local ServerScriptService = game:GetService("ServerScriptService")
	local CommandPolicy = require(game:GetService("ReplicatedStorage").Shared.Config.AdminCommandPolicy)

	-- Suggestion-only types: Kohl must not validate/resolve targets.
	-- AdminBridge remains the resolver for player names, rulerIds, and special tokens.
	local function playerNameSuggestions(): { any }
		local names = {}
		local list = Players:GetPlayers()
		table.sort(list, function(a: Player, b: Player)
			return a.Name < b.Name
		end)
		for _, player in list do
			local aliases = { player.Name }
			if player.DisplayName ~= "" and player.DisplayName ~= player.Name then
				table.insert(aliases, player.DisplayName)
			end
			table.insert(names, { aliases, player.Name })
		end
		return names
	end

	local function acceptRawToken(v: any): (boolean, string?)
		if v == nil then
			return false, "Need a target"
		end
		return true, nil
	end

	local function parseRawToken(v: any): string
		return tostring(v)
	end

	local function registerRawTargetType(typeName: string, displayName: string, extraSuggestions: { any }?)
		if _K.Registry.types[typeName] then
			return
		end
		_K.Registry.registerType(typeName, {
			displayName = displayName,
			filterLog = true,
			validate = acceptRawToken,
			parse = parseRawToken,
			suggestions = function()
				local names = playerNameSuggestions()
				if extraSuggestions then
					for _, extra in extraSuggestions do
						table.insert(names, extra)
					end
				end
				return names
			end,
		})
	end

	registerRawTargetType("adminRulerToken", "player or rulerId", nil)
	registerRawTargetType("adminOwnerToken", "player, rulerId, or unclaimed", {
		{ { "unclaimed" }, "unclaimed" },
	})

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

	-- Adapt only this addon's command gate; leave unrelated Kohl commands intact.
	local gate = _K._gameTesterCommandGate
	if not gate then
		gate = { commands = {}, original = _K.Auth.hasCommand }
		_K._gameTesterCommandGate = gate
		_K.Auth.hasCommand = function(userId, command)
			local definition = if typeof(command) == "string" then _K.Registry.commands[string.lower(command)] else command
			if not gate.commands[definition] then
				return gate.original(userId, command)
			end
			local allowed = false
			if RunService:IsServer() then
				allowed = require(ServerScriptService.Services.AdminConfig).IsGameTester(userId)
			else
				-- Replicated server decision is UI admission only. Server rechecks every execution.
				local player = Players:GetPlayerByUserId(userId)
				allowed = player ~= nil and player:GetAttribute("_GameTesterAuthorized") == true
			end
			if not allowed then
				return false
			end
			local rank = _K.Auth.getRank(userId)
			return math.max(rank, 1)
		end
	end
	-- Supported definition overrides; no vendor Source edits or role changes.
	-- Role config alone cannot deny the installed Kohl creator fast path.
	if not _K._strategyCommandPolicy then
		local state = { archive = {}, originalRegister = _K.Registry.registerCommand, originalAuth = _K.Auth.hasCommand }
		_K._strategyCommandPolicy = state
		local function restricted(def)
			local reason = CommandPolicy.Disabled[string.lower(def.name)]
			if not reason then return def end
			state.archive[def.name] = table.clone(def)
			local replacement = table.clone(def)
			replacement.description = "Disabled for this strategy game: " .. reason
			local function deny() return replacement.description end
			replacement.run, replacement.runClient = deny, deny
			-- Preserve initialized environments for dependent retained commands;
			-- do not install duplicate client remote handlers on replacement.
			replacement.envClient = nil
			return replacement
		end
		_K.Registry.registerCommand = function(interface, def)
			return state.originalRegister(interface, restricted(def))
		end
		_K.Auth.hasCommand = function(userId, command)
			local def = if typeof(command) == "string" then _K.Registry.commands[string.lower(command)] else command
			if typeof(def) == "table" and CommandPolicy.Disabled[string.lower(def.name)] then return false end
			return state.originalAuth(userId, command)
		end
		for _, def in table.clone(_K.Registry.commandsList) do
			if CommandPolicy.Disabled[string.lower(def.name)] then
				_K.Registry.registerCommand(_K, def)
			end
		end
	end
	local function register(def)
		def.group = "SuperAdmin"
		gate.commands[def] = true
		_K.Registry.registerCommand(_K, def)
	end

	register({
		name = "adminhelp",
		aliases = { "gameadminhelp" },
		description = "List GameTester project commands (not Kohl rank help).",
		run = function(context)
			runOp(context, "Help")
		end,
	})

	register({
		name = "inspectwars",
		aliases = { "warsnapshot" },
		description = "List active territory-specific wars.",
		run = function(context)
			runOp(context, "InspectWars")
		end,
	})

	register({
		name = "inspectterritory",
		description = "Inspect territory ownership.",
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
		args = {
			{ type = "adminRulerToken", name = "who", description = "Player, rulerId, or userId" },
		},
		run = function(context, who)
			runOp(context, "InspectRuler", who)
		end,
	})

	register({
		name = "setowner",
		description = "Set territory owner via TerritoryMapService.",
		args = {
			{ type = "rawString", name = "territoryId", description = "Territory id" },
			{ type = "adminOwnerToken", name = "owner", description = "Player, rulerId, or unclaimed" },
		},
		run = function(context, territoryId, owner)
			runOp(context, "SetOwner", territoryId, owner)
		end,
	})

	register({
		name = "setprestige",
		description = "Set Title V0.1 test Prestige (not spent).",
		args = {
			{ type = "adminRulerToken", name = "who", description = "Player or rulerId" },
			{ type = "number", name = "value", description = "Prestige" },
		},
		run = function(context, who, value)
			runOp(context, "SetPrestige", who, value)
		end,
	})

	register({
		name = "inspectgold",
		description = "Inspect Economy V0.1 Gold for a ruler.",
		args = {
			{ type = "adminRulerToken", name = "who", description = "Player or rulerId" },
		},
		run = function(context, who)
			runOp(context, "InspectGold", who)
		end,
	})

	register({
		name = "setgold",
		description = "Set Economy V0.1 Gold (whole number >= 0).",
		args = {
			{ type = "adminRulerToken", name = "who", description = "Player or rulerId" },
			{ type = "number", name = "value", description = "Gold" },
		},
		run = function(context, who, value)
			runOp(context, "SetGold", who, value)
		end,
	})

	register({
		name = "addgold",
		description = "Add Economy V0.1 Gold.",
		args = {
			{ type = "adminRulerToken", name = "who", description = "Player or rulerId" },
			{ type = "number", name = "value", description = "Gold to add" },
		},
		run = function(context, who, value)
			runOp(context, "AddGold", who, value)
		end,
	})

	register({
		name = "spendgold",
		description = "Spend Economy V0.1 Gold (rejects if unaffordable).",
		args = {
			{ type = "adminRulerToken", name = "who", description = "Player or rulerId" },
			{ type = "number", name = "value", description = "Gold to spend" },
		},
		run = function(context, who, value)
			runOp(context, "SpendGold", who, value)
		end,
	})

	register({
		name = "inspecttroops",
		description = "Inspect Military V0.1 Troop state for a ruler.",
		args = {
			{ type = "adminRulerToken", name = "who", description = "Player or rulerId" },
		},
		run = function(context, who)
			runOp(context, "InspectTroops", who)
		end,
	})

	register({
		name = "settroops",
		description = "Set Military V0.1 Total Troops (whole number >= committed).",
		args = {
			{ type = "adminRulerToken", name = "who", description = "Player or rulerId" },
			{ type = "number", name = "value", description = "Troops" },
		},
		run = function(context, who, value)
			runOp(context, "SetTroops", who, value)
		end,
	})

	register({
		name = "addtroops",
		description = "Add Military V0.1 Troops.",
		args = {
			{ type = "adminRulerToken", name = "who", description = "Player or rulerId" },
			{ type = "number", name = "value", description = "Troops to add" },
		},
		run = function(context, who, value)
			runOp(context, "AddTroops", who, value)
		end,
	})

	register({
		name = "inspectmilitary",
		description = "Inspect hidden Military commitment/battle state for a warId.",
		args = {
			{ type = "rawString", name = "warId", description = "warId from inspectwars" },
		},
		run = function(context, warId)
			runOp(context, "InspectMilitary", warId)
		end,
	})

	register({
		name = "inspectcomms",
		description = "Inspect authoritative Communications membership (no message text).",
		args = {},
		run = function(context)
			runOp(context, "InspectComms")
		end,
	})

	register({
		name = "inspectcontest",
		description = "Inspect Warfare contest and post-war cooldown state.",
		args = {},
		run = function(context)
			runOp(context, "InspectContest")
		end,
	})

	register({
		name = "resolvewar",
		aliases = { "warresolve" },
		description = "DEBUG OVERRIDE: force unresolved war outcome; bypasses combat, unwinds commitments. Rejected after mechanical resolution or match end.",
		args = {
			{ type = "rawString", name = "warId", description = "warId from inspectwars" },
			{ type = "rawString", name = "outcome", description = "attacker or defender" },
		},
		run = function(context, warId, outcome)
			runOp(context, "ResolveWar", warId, outcome)
		end,
	})
	for _, item in { { "inspectvictory", "InspectVictory" }, { "checkvictory", "CheckVictory" } } do
		local operation = item[2]
		register({ name = item[1], description = "Inspect/check Domination state.", args = {}, run = function(context) runOp(context, operation) end })
	end
	register({ name = "inspectneutral", description = "Inspect Unclaimed defense.", args = { { type = "rawString", name = "territoryId" } }, run = function(context, id) runOp(context, "InspectNeutral", id) end })
	register({ name = "setneutraldefense", description = "Set uncontested neutral defense within maximum.", args = { { type = "rawString", name = "territoryId" }, { type = "number", name = "defenders" } }, run = function(context, id, amount) runOp(context, "SetNeutralDefense", id, amount) end })
	register({ name = "inspectrealm", description = "Read personal vs greater-realm holdings, members and Domination progress; no mutation.", args = { { type = "adminRulerToken", name = "who", description = "Player or rulerId; resolves their greater realm" } }, run = function(context, who) runOp(context, "InspectRealm", who) end })
	register({ name = "checkledgers", description = "Read-only troop reservation and territory-index invariants for all current rulers; reports concrete failures.", args = {}, run = function(context) runOp(context, "CheckLedgers") end })
	register({ name = "seedbattle", description = "DEBUG: deterministic Military battle seed (integer 0..2147483647 or clear). Future rolls only; match end blocks changes.", args = { { type = "rawString", name = "seed", description = "Integer 0..2147483647 or clear to restore normal randomness" } }, run = function(context, seed) runOp(context, "SeedBattle", seed) end })
end
