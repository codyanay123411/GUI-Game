--!strict
local MatchIntent = require(game:GetService("ReplicatedStorage").Shared.Util.MatchIntent)

--[[
	Player-relevant Military / Armies V0.1 HUD.
	Recruit / SetCommit / LockCommit intents only.
	Five-stop local commitment preview; integer intents and acknowledged edits only.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")

local PrototypeGuiTheme = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Util"):WaitForChild("PrototypeGuiTheme"))
local MilitaryConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"):WaitForChild("MilitaryConfig"))

local player = Players.LocalPlayer
local CommitmentPolicy = require(ReplicatedStorage.Shared.Util.CommitmentPolicy)
local CommitmentBar = require(script.Parent.CommitmentBar)
local RecruitmentPolicy = require(ReplicatedStorage.Shared.Util.RecruitmentPolicy)
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

	local selectedValue = gui:WaitForChild("PresentationState"):WaitForChild("SelectedTerritoryId") :: StringValue
	local shell = gui:WaitForChild("MilitaryWorkflowPanel") :: CanvasGroup
	local panel = shell:WaitForChild("Content") :: ScrollingFrame
	local territoryNames = {}
	for _, definition in require(ReplicatedStorage.Shared.Config.MapCatalog).GetDefault().territories do territoryNames[definition.id] = definition.displayName end
	local stats = panel:WaitForChild("Stats") :: TextLabel
	PrototypeGuiTheme.applyPrimaryButton(panel:WaitForChild("BackButton") :: TextButton, true)
	local recruitBox = panel:WaitForChild("RecruitBox") :: TextBox
	local costLabel = panel:WaitForChild("CostLabel") :: TextLabel
	local recruitButton = panel:WaitForChild("RecruitButton") :: TextButton
	local maxRecruitButton = panel:WaitForChild("MaxRecruitButton") :: TextButton
	recruitBox.Visible = false; recruitBox.Active = false; recruitBox.TextEditable = false
	maxRecruitButton.Visible = false; maxRecruitButton.Active = false
	local recruitBar: any
	local recruitPercent = 25
	local spendableGold: number? = nil
	local recruitSequence = 0
	local recruitFlight: any = nil
	local recruitStatus = ""
	local commitBody = panel:WaitForChild("CommitBody") :: TextLabel
	local retiredCommitBox = panel:WaitForChild("CommitBox") :: TextBox
	retiredCommitBox.Visible = false; retiredCommitBox.Active = false; retiredCommitBox.TextEditable = false
	local bar: any
	local lockButton = panel:WaitForChild("LockButton") :: TextButton
	local mapStage = gui:WaitForChild("MapStage") :: Frame
	local battleBanner = mapStage:WaitForChild("BattleBanner") :: TextLabel
	local resultToast = gui:WaitForChild("ResultToast") :: Frame
	local resultToastLabel = resultToast:WaitForChild("Label") :: TextLabel

	local remotes = ReplicatedStorage:WaitForChild("Remotes")
	local intent = remotes:WaitForChild("MilitaryClientEvent") :: RemoteEvent
	local push = remotes:WaitForChild("MilitaryServerEvent") :: RemoteEvent

	local combatBonuses: any = nil
	local VassalCombat = require(ReplicatedStorage.Shared.Util.VassalCombat)
	local cap = 500
	local castleSupport = 0
	local recruitmentProvinces = {}
	local function recruitmentProvince(): any
		for _, row in recruitmentProvinces do if row.territoryId == selectedValue.Value then return row end end
		return nil
	end
	local total = 0
	local available = 0
	local committed = 0
	local wars = {}
	local hasState = false
	local noticeToken = 0
	local edits: { [string]: any } = {}
	local render: () -> ()
	local fieldStatus = ""
	local boundSessionWarId: string? = nil
	local lastBattleByTerritory: { [string]: any } = {}
	local lastBattleTokenByTerritory: { [string]: number } = {}

	lockButton.Text = "Ready · Lock accepted troops"

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

	local function updateCost()
		local province = recruitmentProvince()
		local cost, amount = RecruitmentPolicy.Preview(spendableGold or 0, recruitPercent, total, cap, if province then province.townLevel else 0)
		local ended = gui:GetAttribute("MatchEnded") == true
		local canEdit = hasState and spendableGold ~= nil and not ended and recruitFlight == nil and province ~= nil
		recruitBar.Set(recruitPercent, string.format("%d%% affordable recruitment", recruitPercent), canEdit)
		local lines = { string.format("Preview: %d Troops / %g Gold", amount, cost) }
		if ended then table.insert(lines, "Recruitment frozen - Match ended.")
		elseif recruitFlight then table.insert(lines, string.format("Submitting %d Troops for %g Gold...", recruitFlight.amount, recruitFlight.cost))
		elseif not hasState or spendableGold == nil then table.insert(lines, "Waiting for your Gold and troop state.")
		elseif not province then table.insert(lines, "Select a personally owned recruitment province.")
		elseif total >= cap then table.insert(lines, if total > cap then "Over cap: existing troops retained. Recruitment blocked." else "Army full: build or upgrade a Town for room.")
		elseif cost == 0 then table.insert(lines, "Zero whole batches at this stop: choose higher or obtain Gold/army room.")
		end
		if province then table.insert(lines, string.format("Town L%d · %g Gold/10 Troops · %d room", province.townLevel, province.priceTenths / 10, math.max(0, cap - total))) end
		if recruitStatus ~= "" then table.insert(lines, recruitStatus) end
		costLabel.Text = table.concat(lines, "\n")
		recruitButton.Text = if recruitFlight then "Recruiting..." else "Recruit"
		recruitButton.Active = canEdit and cost >= 1
		PrototypeGuiTheme.applyPrimaryButton(recruitButton, recruitButton.Active)
	end
	recruitBar = CommitmentBar.Create(panel, "RecruitmentBar", recruitButton.ZIndex, function(percent: number, _final: boolean)
		recruitPercent = percent
		recruitStatus = ""
		updateCost()
	end, RecruitmentPolicy.Stops)

	local function isLiveWar(war: any): boolean
		return war ~= nil and (war.phase == "travel" or war.phase == "commit" or war.phase == "present")
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
		fieldStatus = ""
		boundSessionWarId = nil
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
			if result.ownCastleStrength then string.format("Your Castle: %g defensive strength · %d backing returned unharmed", result.ownCastleStrength, result.ownCastleSupport or 0) else "",
		}, "\n")
	end

	local function beginLastBattle(result: any)
		local territoryId = lastBattleTerritoryId(result)
		if territoryId == nil then
			return
		end
		lastBattleTokenByTerritory[territoryId] = (lastBattleTokenByTerritory[territoryId] or 0) + 1
		local token = lastBattleTokenByTerritory[territoryId]
		local generation = MatchIntent.GetGeneration()
		lastBattleByTerritory[territoryId] = result
		local displayed = displayedWar()
		if displayed == nil or displayed.targetTerritoryId == territoryId then
			resetCommitInput()
		end
		task.delay(lastBattleDuration(), function()
			if generation == MatchIntent.GetGeneration() and lastBattleTokenByTerritory[territoryId] == token then
				lastBattleByTerritory[territoryId] = nil
			end
		end)
	end

	local function editFor(warId: string): any
		if not edits[warId] then edits[warId] = CommitmentPolicy.New() end
		return edits[warId]
	end
	local function syncCommitInputToSession()
		local session = displayedWar()
		local id = if session then session.warId else nil
		if boundSessionWarId ~= id then fieldStatus = ""; boundSessionWarId = id end
	end
	local function maxCommitFor(war: any): number
		return CommitmentPolicy.Pool(available, tonumber(war.intended))
	end
	local function byWarId(id: string): any?
		for _, war in wars do if war.warId == id then return war end end
		return nil
	end
	local function trySendCommit(warId: string): boolean
		local war = byWarId(warId)
		if not war or war.phase ~= "commit" or war.locked or gui:GetAttribute("MatchEnded") then return false end
		local edit = editFor(warId)
		local flight = CommitmentPolicy.Begin(edit)
		if not flight then return false end
		MatchIntent.Send(intent, "SetCommit", warId, flight.amount)
		task.delay(8, function()
			if edit.flight == flight then
				edit.flight = nil; edit.rejected = true
				if boundSessionWarId == warId then fieldStatus = "Acceptance unavailable. Choose a stop to retry." end
				render()
			end
		end)
		return true
	end
	local function scheduleCommitSend(warId: string, final: boolean)
		local edit = editFor(warId)
		edit.token = (edit.token or 0) + 1
		local token = edit.token
		if final then trySendCommit(warId); return end
		task.delay(COMMIT_DEBOUNCE_SEC, function()
			if token == edit.token then trySendCommit(warId) end
		end)
	end
	bar = CommitmentBar.Create(panel, "CommitmentBar", 87, function(percent, final)
		local war = activeCommitWar()
		if not war or war.phase ~= "commit" or war.locked or gui:GetAttribute("MatchEnded") then return end
		local edit = editFor(war.warId)
		local amount = CommitmentPolicy.Amount(maxCommitFor(war), percent)
		if edit.percent ~= percent or edit.amount ~= amount or edit.rejected then
			CommitmentPolicy.Choose(edit, percent, amount)
			fieldStatus = ""
		end
		scheduleCommitSend(war.warId, final)
		render()
	end)
	-- Confirm's deliberately chosen integer amount uses the same submission/receipt path.
	function MilitaryController.PrepareCommit(warId: string, amount: number, percent: number): boolean
		local war = activeCommitWar()
		if not war or war.warId ~= warId or war.phase ~= "commit" or war.locked then return false end
		if not CommitmentPolicy.IsStop(percent) or amount ~= amount or amount < 0 or amount % 1 ~= 0 then return false end
		CommitmentPolicy.Choose(editFor(warId), percent, amount)
		return trySendCommit(warId)
	end

	render = function()
		gui:SetAttribute("MilitaryAvailable", if hasState then available else nil)
		gui:SetAttribute("MilitaryCommitted", if hasState then committed else nil)
		local recruiting = gui:GetAttribute("MilitaryContextMode") == "Recruit"
		(panel.Header :: TextLabel).Text = (if recruiting then "Recruit" else "Military") .. " - " .. (territoryNames[selectedValue.Value] or selectedValue.Value)
		for _, item in { recruitBar.Root, recruitButton, costLabel } do item.Visible = recruiting end
		updateCost()
		gui:SetAttribute("MilitaryPresenting", false)
		if not hasState then
			stats.Text = "Total: —\nAvailable: —\nCommitted: —"
			commitBody.Text = "No active war commitment."
			bar.Root.Visible = false
			lockButton.Visible = false
			battleBanner.Visible = false
			PrototypeGuiTheme.applyPrimaryButton(lockButton, false)
			lockButton.Active = false
			return
		end
		local presenting = false
		for _, active in wars do if active.phase == "present" then presenting = true end end
		gui:SetAttribute("MilitaryPresenting", presenting)
		stats.Text = string.format("Total / cap: %d / %d\nAvailable: %d\n%s: %d", total, cap, available,
			if presenting then "Held (incl. survivors)" else "Reserved across wars", committed)
		stats.Text ..= string.format("\nCastle support held: %d · Recruitment room: %d", castleSupport, math.max(0, cap - total))
		if total > cap then stats.Text ..= "\nOver cap · Existing troops retained" end
		if combatBonuses then stats.Text ..= "\n" .. VassalCombat.Describe(combatBonuses) end
		for _, active in wars do
			if active.phase == "present" and active.ownResolvedStrengthMultiplier then
				stats.Text ..= string.format("\nYour resolved modifier (%s): x%g", active.targetDisplayName, active.ownResolvedStrengthMultiplier)
			end
		end
		updateCost()

		local function showLastBattleUi(result: any)
			syncCommitInputToSession()
			bar.Root.Visible = false
			lockButton.Visible = false
			lockButton.Active = false
			PrototypeGuiTheme.applyPrimaryButton(lockButton, false)
			battleBanner.Visible = false
			commitBody.Text = formatLastBattle(result)
		end

		local function showIdleCommitment(message: string)
			syncCommitInputToSession()
			bar.Root.Visible = false
			lockButton.Visible = false
			lockButton.Active = false
			PrototypeGuiTheme.applyPrimaryButton(lockButton, false)
			battleBanner.Visible = false
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
			bar.Root.Visible = true
			lockButton.Visible = true
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
		}
		if war.targetKind == "Unclaimed" then table.insert(lines, "Unclaimed militia: " .. tostring(war.neutralDefenders) .. " defenders") end
		if war.role == "Defender" and war.ownCastleSupport then
			table.insert(lines, string.format("Castle backing held: %d real troops · no backing casualties", war.ownCastleSupport))
			if war.ownCastleStrength then table.insert(lines, string.format("Your Castle contribution: %g defensive strength (not troops)", war.ownCastleStrength)) end
		end
		if war.phase == "travel" then
			table.insert(lines,"Transport travelling - troop amount locked at launch.")
			table.insert(lines,"Arrival in " .. formatCountdown(war.travel.arrivesAt) .. ". Defender decision window starts on arrival.")
			if war.role == "Attacker" then table.insert(lines,"Server-accepted locked force: " .. tostring(war.intended or 0)) end
		end
		if war.phase == "commit" then
			table.insert(lines, (if war.locked then "Locked force: " else "Server-accepted reservation: ") .. tostring(war.intended or "none"))
			if not war.locked then
				local edit = editFor(war.warId)
				if edit.percent then
					local preview = CommitmentPolicy.Amount(maxCommitFor(war), edit.percent)
					table.insert(lines, string.format("Preview: %d%% · %d troops from pool %d", edit.percent, preview, maxCommitFor(war)))
					if preview == 0 then table.insert(lines, "Small pool: selection rounds down to zero. Zero attackers cancel; zero defenders field no troops.") end
					if edit.flight or edit.revision ~= edit.settledRevision then
						table.insert(lines, "Latest edit pending acceptance; Ready unavailable.")
					elseif edit.rejected then table.insert(lines, "Latest edit rejected. Choose a stop to retry; Ready unavailable.")
					elseif preview ~= war.intended then table.insert(lines, "Forces changed: preview only. Choose again to update; Ready locks the accepted amount.") end
				else table.insert(lines, "Accepted amount shown exactly. Choose a stop to replace it; no automatic change.") end
				table.insert(lines, "Ready locks your accepted force; no changes afterward.")
			end
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
			table.insert(lines, "Combat calculated · Result presentation")
			table.insert(lines, "Troop totals already reflect casualties. Survivors remain held until completion; province transfer is pending.")
			if typeof(war.attackerCommitted) == "number" and typeof(war.defenderCommitted) == "number" then
				table.insert(lines, string.format("Fielded: attacker %d / defender %d", war.attackerCommitted, war.defenderCommitted))
			end
			if typeof(war.presentationEndsAt) == "number" then
				table.insert(lines, "Result completes in " .. formatCountdown(war.presentationEndsAt))
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

		local canEdit = war.phase == "commit" and war.locked ~= true and gui:GetAttribute("MatchEnded") ~= true
		local edit = editFor(war.warId)
		local canLock = canEdit and CommitmentPolicy.CanReady(edit, war.intended)
		bar.Root.Visible = war.phase == "commit"
		bar.Set(if canEdit then edit.percent else nil, if war.locked then "Locked: " .. tostring(war.intended or 0) .. " troops" elseif not canEdit then "Editing frozen" elseif edit.percent then string.format("%d%% · %d troops · Preview", edit.percent, CommitmentPolicy.Amount(maxCommitFor(war), edit.percent)) else "Choose a stop to edit accepted troops", canEdit)
		lockButton.Visible = war.phase == "commit"
		lockButton.Active = canLock
		PrototypeGuiTheme.applyPrimaryButton(lockButton, canLock)

		local showBattle = war.phase == "present"
		battleBanner.Visible = showBattle and not shell.Visible
		if showBattle then
			battleBanner.Text = (if war.visualResult and war.visualResult.winner == "Defender" then "Attack repelled - ownership unchanged - " else "Combat decided - cosmetic front; ownership pending - ") .. (war.targetDisplayName or "contested territory")
		end
	end

	gui:GetAttributeChangedSignal("MatchEnded"):Connect(render)
	local function recruitmentOpened()
		if shell.Visible and gui:GetAttribute("MilitaryContextMode") == "Recruit" and not recruitFlight then
			recruitPercent = 25
			recruitStatus = ""
		end
		render()
	end
	gui:GetAttributeChangedSignal("MilitaryContextMode"):Connect(recruitmentOpened)
	shell:GetPropertyChangedSignal("Visible"):Connect(recruitmentOpened)

	recruitButton.MouseButton1Click:Connect(function()
		if recruitFlight or not recruitButton.Active or gui:GetAttribute("MatchEnded") or spendableGold == nil then return end
		local province = recruitmentProvince(); if not province then return end
		local cost, amount = RecruitmentPolicy.Preview(spendableGold, recruitPercent, total, cap, province.townLevel)
		if cost < 1 then return end
		recruitSequence += 1
		recruitFlight = { id = recruitSequence, amount = amount, cost = cost }
		recruitStatus = ""
		updateCost()
		MatchIntent.Send(intent, "Recruit", amount, recruitSequence, selectedValue.Value, province.ownershipRevision, province.townLevel)
	end)
	local economyIntent = remotes:WaitForChild("EconomyClientEvent") :: RemoteEvent
	local economyPush = remotes:WaitForChild("EconomyServerEvent") :: RemoteEvent
	MatchIntent.ConnectPush(economyPush, function(kind: any, payload: any)
		if kind ~= "State" then return end
		local state = decodeState(payload)
		if not state or typeof(state.gold) ~= "number" then return end
		spendableGold = state.gold
		updateCost()
	end)
	MatchIntent.Send(economyIntent, "Ready")

	lockButton.MouseButton1Click:Connect(function()
		local war = activeCommitWar()
		if not war or war.phase ~= "commit" or war.locked or gui:GetAttribute("MatchEnded") then return end
		if not CommitmentPolicy.CanReady(editFor(war.warId), war.intended) then return end
		MatchIntent.Send(intent, "LockCommit", war.warId)
	end)

	selectedValue:GetPropertyChangedSignal("Value"):Connect(function()
		syncCommitInputToSession()
		render()
	end)

	MatchIntent.ConnectPush(push, function(kind: any, payload: any)
		if kind == "RecruitResult" then
			local receipt = decodeState(payload)
			if not receipt or not recruitFlight or receipt.requestId ~= recruitFlight.id then return end
			recruitFlight = nil
			recruitStatus = receipt.message or "Recruitment response received."
			if receipt.accepted ~= true then MatchIntent.Send(economyIntent, "Ready") end
			updateCost()
			return
		end
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
		if kind == "CommitResult" then
			local receipt = decodeState(payload)
			if receipt and typeof(receipt.warId) == "string" and typeof(receipt.amount) == "number" then
				local edit = edits[receipt.warId]
				if edit and CommitmentPolicy.Acknowledge(edit, receipt.amount, receipt.accepted == true) then
					if boundSessionWarId == receipt.warId and edit.revision == edit.settledRevision then
						fieldStatus = if receipt.accepted == true then "" else receipt.message or "Edit rejected."
					end
					trySendCommit(receipt.warId)
					render()
				end
			end
			return
		end
		if kind == "Notice" and typeof(payload) == "string" then
			showNotice(payload)
			local current = activeCommitWar()
			if current and editFor(current.warId).rejected and (string.find(payload, "Not enough", 1, true) or string.find(payload, "Commitment", 1, true)) then
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
		cap = tonumber(state.cap) or 500; castleSupport = tonumber(state.castleSupport) or 0; recruitmentProvinces = state.recruitmentProvinces or {}
		combatBonuses = state.combatBonuses
		total = tonumber(state.total) or 0
		available = tonumber(state.available) or 0
		committed = tonumber(state.committed) or 0
		wars = state.wars or {}
		hasState = true
		syncCommitInputToSession()

		render()
	end)

	RunService.Heartbeat:Connect(function()
		if hasState then
			render()
		end
	end)

	MatchIntent.OnChanged(function()
		noticeToken += 1;resultToast.Visible = false;battleBanner.Visible = false
		for _, edit in edits do edit.token = (edit.token or 0)+1;edit.flight = nil end
		edits, lastBattleByTerritory, lastBattleTokenByTerritory, wars = {}, {}, {}, {}
		recruitFlight = nil;recruitStatus = "";recruitSequence = 0;recruitPercent = 25
		spendableGold = nil;hasState = false;boundSessionWarId = nil;fieldStatus = ""
		cap = 500;castleSupport = 0;recruitmentProvinces = {}
		total, available, committed = 0, 0, 0;render()
	end)
	PrototypeGuiTheme.ApplyScreen(gui)
	MatchIntent.Send(intent, "Ready")
	render()
end

return MilitaryController
