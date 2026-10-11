--!strict

--[[
	Player-relevant Military / Armies V0.1 HUD.
	Recruit / RecruitMax / SetCommit / LockCommit intents only.
	Commitment field auto-submits parsed integers; Lock uses server-accepted intent.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")

local PrototypeGuiTheme = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Util"):WaitForChild("PrototypeGuiTheme"))
local MilitaryConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"):WaitForChild("MilitaryConfig"))

local player = Players.LocalPlayer
local MilitaryController = {}

local started = false
local COMMIT_DEBOUNCE_SEC = 0.08

local function decodeState(payload: any): any?
	if typeof(payload) == "string" then
		local ok, decoded = pcall(function()
			return HttpService:JSONDecode(payload)
		end)
		if ok and typeof(decoded) == "table" then
			return decoded
		end
		return nil
	elseif typeof(payload) == "table" then
		return payload
	end
	return nil
end

local function formatCountdown(endsAt: number): string
	local remaining = math.max(0, math.ceil(endsAt - workspace:GetServerTimeNow()))
	return string.format("%ds", remaining)
end

local function parseWholeNonNegative(text: string): number?
	if text == "" then
		return nil
	end
	local n = tonumber(text)
	if typeof(n) ~= "number" or n ~= n or n ~= math.floor(n) or n < 0 then
		return nil
	end
	return n
end

function MilitaryController.Start()
	if started or _G.__MilitaryV01Started == true then
		return
	end
	started = true
	_G.__MilitaryV01Started = true

	local gui = player:WaitForChild("PlayerGui"):WaitForChild("HierarchyPrototypeGui", 12)
	if not (gui and gui:IsA("ScreenGui")) then
		warn("[Military] HierarchyPrototypeGui missing; HUD idle.")
		started = false
		_G.__MilitaryV01Started = nil
		return
	end

	local info = gui:WaitForChild("TerritoryInfo") :: Frame
	local selectedValue = info:WaitForChild("SelectedTerritoryId") :: StringValue
	local panel = gui:WaitForChild("MilitaryPanel") :: Frame
	local stats = panel:WaitForChild("Stats") :: TextLabel
	local recruitBox = panel:WaitForChild("RecruitBox") :: TextBox
	local costLabel = panel:WaitForChild("CostLabel") :: TextLabel
	local recruitButton = panel:WaitForChild("RecruitButton") :: TextButton
	local maxRecruitButton = panel:WaitForChild("MaxRecruitButton") :: TextButton
	local commitBody = panel:WaitForChild("CommitBody") :: TextLabel
	local commitBox = panel:WaitForChild("CommitBox") :: TextBox
	local lockButton = panel:WaitForChild("LockButton") :: TextButton
	local mapStage = gui:WaitForChild("MapStage") :: Frame
	local battleBanner = mapStage:WaitForChild("BattleBanner") :: TextLabel
	local resultToast = gui:WaitForChild("ResultToast") :: Frame
	local resultToastLabel = resultToast:WaitForChild("Label") :: TextLabel

	local remotes = ReplicatedStorage:WaitForChild("Remotes")
	local intent = remotes:WaitForChild("MilitaryClientEvent") :: RemoteEvent
	local push = remotes:WaitForChild("MilitaryServerEvent") :: RemoteEvent

	local total = 0
	local available = 0
	local committed = 0
	local troopsPerGold = 3
	local wars = {}
	local hasState = false
	local noticeToken = 0
	local lastSentByWar: { [string]: number } = {}
	local fieldStatus = ""
	local debounceToken = 0
	local boundSessionWarId: string? = nil
	local lastBattleByTerritory: { [string]: any } = {}
	local lastBattleTokenByTerritory: { [string]: number } = {}
	local COMMIT_BODY_IDLE = UDim2.new(1, -16, 0, 148)
	local COMMIT_BODY_SUMMARY = UDim2.new(1, -16, 0, 148)

	commitBox.PlaceholderText = "Troops to commit"
	lockButton.Text = "Ready"

	local function showNotice(message: string)
		noticeToken += 1
		local token = noticeToken
		resultToastLabel.Text = message
		resultToast.Visible = true
		task.delay(6, function()
			if token == noticeToken then
				resultToast.Visible = false
			end
		end)
	end

	local function recruitAmount(): number?
		local n = tonumber(recruitBox.Text)
		if n == nil then
			return nil
		end
		return n
	end

	local function updateCost()
		local n = recruitAmount()
		if n == nil then
			costLabel.Text = "Gold cost: —"
			return
		end
		if n > 0 and n == math.floor(n) and n % troopsPerGold == 0 then
			costLabel.Text = string.format("Gold cost: %d", n / troopsPerGold)
		else
			costLabel.Text = "Gold cost: invalid"
		end
	end

	local function isLiveWar(war: any): boolean
		return war ~= nil and (war.phase == "commit" or war.phase == "present")
	end

	local function liveWars(): { any }
		local live = {}
		for _, war in wars do
			if isLiveWar(war) then
				table.insert(live, war)
			end
		end
		return live
	end

	local function warForTarget(territoryId: string): any?
		if territoryId == "" then
			return nil
		end
		for _, war in wars do
			if isLiveWar(war) and war.targetTerritoryId == territoryId then
				return war
			end
		end
		return nil
	end

	-- Display/input context only. Selection never mutates server Military state.
	local function displayedWar(): any?
		local selected = selectedValue.Value
		local matched = warForTarget(selected)
		if matched then
			return matched
		end
		-- Empty selection + exactly one war: keep single-war HUD without a map click.
		if selected == "" then
			local live = liveWars()
			if #live == 1 then
				return live[1]
			end
		end
		return nil
	end

	local function activeCommitWar(): any?
		return displayedWar()
	end

	local function resetCommitInput()
		debounceToken += 1
		fieldStatus = ""
		if commitBox.Text ~= "" then
			commitBox.Text = ""
		end
		commitBox.PlaceholderText = "Troops to commit"
	end

	local function lastBattleDuration(): number
		local override = panel:GetAttribute("DebugLastBattleSeconds")
		if typeof(override) == "number" and override == override and override > 0 then
			return override
		end
		local configured = tonumber(MilitaryConfig.LastBattleSummarySeconds)
		if configured and configured > 0 then
			return configured
		end
		return 20
	end

	local function lastBattleTerritoryId(result: any): string?
		if typeof(result.targetTerritoryId) == "string" and result.targetTerritoryId ~= "" then
			return result.targetTerritoryId
		end
		return nil
	end

	local function lastBattleForTerritory(territoryId: string): any?
		if territoryId == "" then
			return nil
		end
		return lastBattleByTerritory[territoryId]
	end

	local function soleCachedLastBattle(): any?
		local found: any? = nil
		local n = 0
		for _, result in lastBattleByTerritory do
			n += 1
			found = result
		end
		if n == 1 then
			return found
		end
		return nil
	end

	local function discardTerritoryLastBattle(territoryId: string)
		lastBattleTokenByTerritory[territoryId] = (lastBattleTokenByTerritory[territoryId] or 0) + 1
		lastBattleByTerritory[territoryId] = nil
	end

	local function formatLastBattle(result: any): string
		local place = result.targetDisplayName
		if typeof(place) ~= "string" or place == "" then
			place = result.targetTerritoryId
		end
		if typeof(place) ~= "string" or place == "" then
			place = "contested territory"
		end
		local outcome = if result.won == true then "VICTORY" else "DEFEAT"
		return table.concat({
			"Last Battle — " .. place,
			"",
			outcome,
			"",
			"Your committed: " .. tostring(tonumber(result.committed) or 0),
			"Enemy committed: " .. tostring(tonumber(result.enemyCommitted) or 0),
			"Your casualties: " .. tostring(tonumber(result.casualties) or 0),
			"Your survivors: " .. tostring(tonumber(result.survivors) or 0),
		}, "\n")
	end

	local function beginLastBattle(result: any)
		local territoryId = lastBattleTerritoryId(result)
		if territoryId == nil then
			return
		end
		lastBattleTokenByTerritory[territoryId] = (lastBattleTokenByTerritory[territoryId] or 0) + 1
		local token = lastBattleTokenByTerritory[territoryId]
		lastBattleByTerritory[territoryId] = result
		local displayed = displayedWar()
		if displayed == nil or displayed.targetTerritoryId == territoryId then
			resetCommitInput()
		end
		task.delay(lastBattleDuration(), function()
			if lastBattleTokenByTerritory[territoryId] == token then
				lastBattleByTerritory[territoryId] = nil
			end
		end)
	end

	local function syncCommitInputToSession()
		local session = displayedWar()
		local sessionId = if session and typeof(session.warId) == "string" then session.warId else nil
		if sessionId == nil then
			if boundSessionWarId ~= nil or commitBox.Text ~= "" then
				resetCommitInput()
			end
			boundSessionWarId = nil
			return
		end
		if boundSessionWarId == sessionId then
			return
		end
		debounceToken += 1
		fieldStatus = ""
		commitBox.PlaceholderText = "Troops to commit"
		boundSessionWarId = sessionId
		local intended = tonumber(session.intended)
		if typeof(intended) == "number" then
			lastSentByWar[sessionId] = intended
			local shown = tostring(intended)
			if commitBox.Text ~= shown then
				commitBox.Text = shown
			end
		elseif commitBox.Text ~= "" then
			commitBox.Text = ""
		end
	end

	local function maxCommitFor(war: any): number
		local intended = tonumber(war.intended) or 0
		return available + intended
	end

	local function trySendCommit(force: boolean): boolean
		local war = activeCommitWar()
		if not war or typeof(war.warId) ~= "string" then
			return false
		end
		if war.phase ~= "commit" or war.locked == true then
			return false
		end
		local parsed = parseWholeNonNegative(commitBox.Text)
		if parsed == nil then
			local text = commitBox.Text
			if text == "" then
				fieldStatus = ""
			else
				fieldStatus = "Invalid amount (not a whole number >= 0)"
			end
			return false
		end
		if parsed > maxCommitFor(war) then
			fieldStatus = "Invalid: over Available"
			if lastSentByWar[war.warId] == parsed and not force then
				return false
			end
			lastSentByWar[war.warId] = parsed
			intent:FireServer("SetCommit", war.warId, parsed)
			return false
		end
		if lastSentByWar[war.warId] == parsed and not force then
			fieldStatus = ""
			return true
		end
		fieldStatus = ""
		lastSentByWar[war.warId] = parsed
		intent:FireServer("SetCommit", war.warId, parsed)
		return true
	end

	local function scheduleCommitSend()
		debounceToken += 1
		local token = debounceToken
		task.delay(COMMIT_DEBOUNCE_SEC, function()
			if token == debounceToken then
				trySendCommit(false)
			end
		end)
	end
	-- Contextual declaration handoff uses the same field and submission path as this HUD.
	function MilitaryController.PrepareCommit(warId: string, amount: number): boolean
		local war = activeCommitWar()
		if not war or war.warId ~= warId or war.phase ~= "commit" or war.locked then return false end
		if amount ~= amount or amount < 0 or amount % 1 ~= 0 or amount > maxCommitFor(war) then return false end
		commitBox.Text = tostring(amount)
		debounceToken += 1
		return trySendCommit(true)
	end

	local function render()
		if not hasState then
			stats.Text = "Total: —\nAvailable: —\nCommitted: —"
			commitBody.Text = "No active war commitment."
			commitBody.Size = COMMIT_BODY_IDLE
			commitBox.Visible = true
			lockButton.Visible = true
			battleBanner.Visible = false
			PrototypeGuiTheme.applyPrimaryButton(recruitButton, true)
			PrototypeGuiTheme.applyPrimaryButton(maxRecruitButton, true)
			PrototypeGuiTheme.applyPrimaryButton(lockButton, false)
			lockButton.Active = false
			return
		end
		stats.Text = string.format("Total: %d\nAvailable: %d\nCommitted: %d", total, available, committed)
		updateCost()
		PrototypeGuiTheme.applyPrimaryButton(recruitButton, true)
		PrototypeGuiTheme.applyPrimaryButton(maxRecruitButton, true)
		recruitButton.Active = true
		maxRecruitButton.Active = true

		local function showLastBattleUi(result: any)
			syncCommitInputToSession()
			commitBox.Visible = false
			lockButton.Visible = false
			lockButton.Active = false
			PrototypeGuiTheme.applyPrimaryButton(lockButton, false)
			battleBanner.Visible = false
			commitBody.Size = COMMIT_BODY_SUMMARY
			commitBody.Text = formatLastBattle(result)
		end

		local function showIdleCommitment(message: string)
			syncCommitInputToSession()
			commitBox.Visible = true
			lockButton.Visible = true
			lockButton.Active = false
			PrototypeGuiTheme.applyPrimaryButton(lockButton, false)
			battleBanner.Visible = false
			commitBody.Size = COMMIT_BODY_IDLE
			commitBody.Text = message
		end

		local war = displayedWar()
		if war then
			local targetId = war.targetTerritoryId
			if typeof(targetId) == "string" then
				local cached = lastBattleForTerritory(targetId)
				if cached ~= nil and typeof(cached.warId) == "string" and cached.warId ~= war.warId then
					discardTerritoryLastBattle(targetId)
				end
			end
			commitBox.Visible = true
			lockButton.Visible = true
			commitBody.Size = COMMIT_BODY_IDLE
		else
			local selected = selectedValue.Value
			local selectedSummary = lastBattleForTerritory(selected)
			if selected ~= "" and selectedSummary ~= nil then
				showLastBattleUi(selectedSummary)
				return
			end
			if #liveWars() > 0 then
				showIdleCommitment("No commitment for this territory.\nSelect a contested territory.")
				return
			end
			if selected == "" then
				local only = soleCachedLastBattle()
				if only ~= nil then
					showLastBattleUi(only)
					return
				end
			end
			showIdleCommitment("No active war commitment.")
			return
		end

		local lines = {
			string.format("%s — %s", war.role or "?", war.targetDisplayName or war.targetTerritoryId),
			string.format("Available: %d", available),
		}
		if war.targetKind == "Unclaimed" then table.insert(lines, "Unclaimed militia: " .. tostring(war.neutralDefenders) .. " defenders") end
		if typeof(war.intended) == "number" then
			table.insert(lines, "Accepted commitment: " .. tostring(war.intended))
		else
			table.insert(lines, "Accepted commitment: none")
		end
		if fieldStatus ~= "" and war.phase == "commit" and war.locked ~= true then
			table.insert(lines, fieldStatus)
		end
		if war.phase == "commit" then
			if (tonumber(war.windowEndsAt) or 0) > workspace:GetServerTimeNow() then
				table.insert(lines, "Decision: " .. formatCountdown(war.windowEndsAt))
			else
				table.insert(lines, "Hard timeout: " .. formatCountdown(war.hardEndsAt))
			end
			if war.locked then
				table.insert(lines, war.opponentState or "Waiting for opponent")
			else
				table.insert(lines, war.opponentState or "Opponent preparing forces")
			end
		elseif war.phase == "present" then
			table.insert(lines, "Battle in progress")
			if typeof(war.attackerCommitted) == "number" and typeof(war.defenderCommitted) == "number" then
				table.insert(lines, string.format("Fielded: attacker %d / defender %d", war.attackerCommitted, war.defenderCommitted))
			end
			if typeof(war.presentationEndsAt) == "number" then
				table.insert(lines, "Resolving in " .. formatCountdown(war.presentationEndsAt))
			end
		end
		if war.result then
			table.insert(lines, war.result.title or "")
			table.insert(
				lines,
				string.format(
					"Committed %d / Casualties %d / Survivors %d",
					war.result.committed,
					war.result.casualties,
					war.result.survivors
				)
			)
		end
		commitBody.Text = table.concat(lines, "\n")

		local canLock = war.phase == "commit" and war.locked ~= true and typeof(war.intended) == "number"
		lockButton.Active = canLock
		PrototypeGuiTheme.applyPrimaryButton(lockButton, canLock)

		local showBattle = war.phase == "present"
		battleBanner.Visible = showBattle
		if showBattle then
			battleBanner.Text = "Battle in progress — " .. (war.targetDisplayName or "contested territory")
		end
	end

	recruitBox:GetPropertyChangedSignal("Text"):Connect(updateCost)

	recruitButton.MouseButton1Click:Connect(function()
		local n = recruitAmount()
		intent:FireServer("Recruit", n)
	end)

	maxRecruitButton.MouseButton1Click:Connect(function()
		intent:FireServer("RecruitMax")
	end)

	commitBox:GetPropertyChangedSignal("Text"):Connect(function()
		local war = activeCommitWar()
		if not war or war.phase ~= "commit" or war.locked == true then
			return
		end
		scheduleCommitSend()
	end)

	lockButton.MouseButton1Click:Connect(function()
		local war = activeCommitWar()
		if not war or typeof(war.warId) ~= "string" then
			return
		end
		if not lockButton.Active then
			return
		end
		debounceToken += 1
		local parsed = parseWholeNonNegative(commitBox.Text)
		if parsed ~= nil and parsed <= maxCommitFor(war) then
			trySendCommit(true)
		end
		intent:FireServer("LockCommit", war.warId)
	end)

	selectedValue:GetPropertyChangedSignal("Value"):Connect(function()
		syncCommitInputToSession()
		render()
	end)

	push.OnClientEvent:Connect(function(kind: any, payload: any)
		if kind == "BattleResult" then
			local result = decodeState(payload)
			if result and typeof(result.title) == "string" then
				showNotice(string.format(
					"%s  Committed %d / Casualties %d / Survivors %d",
					result.title,
					tonumber(result.committed) or 0,
					tonumber(result.casualties) or 0,
					tonumber(result.survivors) or 0
				))
				beginLastBattle(result)
			end
			return
		end
		if kind == "Notice" and typeof(payload) == "string" then
			showNotice(payload)
			if string.find(payload, "Not enough", 1, true) or string.find(payload, "Commitment", 1, true) then
				if string.find(payload, "Not enough", 1, true) then
					fieldStatus = "Invalid: over Available"
				elseif string.find(payload, "whole number", 1, true) or string.find(payload, "negative", 1, true) then
					fieldStatus = "Invalid amount"
				end
			end
			return
		end
		if kind ~= "State" then
			return
		end
		local state = decodeState(payload)
		if not state then
			return
		end
		total = tonumber(state.total) or 0
		available = tonumber(state.available) or 0
		committed = tonumber(state.committed) or 0
		troopsPerGold = tonumber(state.troopsPerGold) or 3
		wars = state.wars or {}
		hasState = true
		syncCommitInputToSession()
		for _, war in wars do
			if typeof(war.warId) == "string" and typeof(war.intended) == "number" then
				if lastSentByWar[war.warId] == nil then
					lastSentByWar[war.warId] = war.intended
				end
			end
		end
		render()
	end)

	RunService.Heartbeat:Connect(function()
		if hasState then
			render()
		end
	end)

	PrototypeGuiTheme.ApplyScreen(gui)
	intent:FireServer("Ready")
	render()
end

return MilitaryController
