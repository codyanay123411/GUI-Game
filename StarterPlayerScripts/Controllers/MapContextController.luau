--!strict
local MatchIntent = require(game:GetService("ReplicatedStorage").Shared.Util.MatchIntent)
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TextService = game:GetService("TextService")
local HttpService = game:GetService("HttpService")
local Theme = require(ReplicatedStorage.Shared.Util.PrototypeGuiTheme)
local Transitions = require(ReplicatedStorage.Shared.Util.ContextTransitions)
local Resolver = require(ReplicatedStorage.Shared.Util.ContextActionResolver)
local Catalog = require(ReplicatedStorage.Shared.Config.MapCatalog)
local State = require(script.Parent.MapContextState)
local Map = require(script.Parent.TerritoryMapController)
local Radial = require(script.Parent.ContextRadialController)
local Strategy = require(script.Parent.StrategyPresentationController)
local Communications = require(script.Parent.CommunicationsController)
local Military = require(script.Parent.MilitaryController)
local Routes = require(ReplicatedStorage.Shared.Util.NavalRoutes)
local MilitaryConfig = require(ReplicatedStorage.Shared.Config.MilitaryConfig)
local CommitmentPolicy = require(ReplicatedStorage.Shared.Util.CommitmentPolicy)
local CommitmentBar = require(script.Parent.CommitmentBar)
local FarmPolicy = require(ReplicatedStorage.Shared.Util.FarmPolicy)
local BuildingConfig = require(ReplicatedStorage.Shared.Config.BuildingConfig)
local Controller = {}
local started = false

function Controller.Start()
	if started then return end
	started = true
	local player = Players.LocalPlayer
	local gui = player.PlayerGui:WaitForChild("HierarchyPrototypeGui") :: ScreenGui
	local shell = gui:WaitForChild("ContextWorkflowPanel") :: CanvasGroup
	local panel = shell:WaitForChild("Content") :: ScrollingFrame
	local header = panel:WaitForChild("Heading") :: TextLabel
	local body = panel:WaitForChild("Body") :: TextLabel
	local retiredAmount = panel:WaitForChild("CommitAmount") :: TextBox
	retiredAmount.Visible = false; retiredAmount.Active = false; retiredAmount.TextEditable = false
	local redraw: () -> ()
	local betrayalQuote: any = nil
	local betrayalFeedback = ""
	local reviewPending = false
	local navalFeedback = ""
	local farmPending: any = nil
	local farmSequence = 0
	local farmFeedback = ""
	local selectedPercent = 10
	local bar: any
	bar = CommitmentBar.Create(panel, "CommitmentBar", 87, function(percent)
		selectedPercent = percent
		redraw()
	end)
	local close = panel:WaitForChild("CancelButton") :: TextButton
	local list = panel:WaitForChild("Actions") :: Frame
	local mapDef = Catalog.GetDefault()
	local remotes = ReplicatedStorage.Remotes
	local selected: string? = nil
	local point = Vector2.zero
	local mode: string? = nil
	local pending: any = nil
	local pendingToken = 0
	local context: any = nil
	local function priority(): boolean
		return gui.VassalageOfferOverlay.Visible or gui.DiplomacyOfferOverlay.Visible
			or gui:GetAttribute("RealmOverviewOpen") == true or gui:GetAttribute("VictoryOverlayOpen") == true
	end
	local function resolve(): any
		return if selected then Resolver.Resolve(State, mapDef.territories, selected, player.UserId,
			gui:GetAttribute("MatchEnded") == true, workspace:GetServerTimeNow(), mapDef) else nil
	end
	local function hide()
		Radial.Hide(); Transitions.Hide(shell); mode = nil
	end
	local function layout()
		local size = gui.AbsoluteSize
		local density = Theme.Presentation.UIScale
		local rail = (if size.X < 760 then 80 else 100) * density
		local maximum = math.max(180, math.min(400, size.X - rail - 200))
		local width = math.clamp(size.X * 0.34 * density, math.min(260, maximum), maximum)
		shell.Position = UDim2.fromOffset(math.max(12, size.X - width - 12), 76)
		shell.Size = UDim2.fromOffset(width, math.max(120, size.Y - 108))
		local textHeight = TextService:GetTextSize(body.Text, body.TextSize, body.Font, Vector2.new(math.max(1, width - 24), 100000)).Y
		body.Size = UDim2.new(1, -24, 0, textHeight + 12)
		local y = 56 + body.Size.Y.Offset
		bar.Root.Position = UDim2.fromOffset(12, y)
		bar.Root.Size = UDim2.new(1, -24, 0, 96)
		list.Position = UDim2.fromOffset(12, y + (if bar.Root.Visible then 106 else 0))
		local height = 0
		for _, child in list:GetChildren() do
			if child:IsA("TextButton") then
				local rowHeight = if mode == "Build" then math.max(88, TextService:GetTextSize(child.Text, child.TextSize, child.Font, Vector2.new(math.max(1, width - 40), 100000)).Y + 18) else 38
				child.Position = UDim2.fromOffset(0, height); child.Size = UDim2.new(1, 0, 0, rowHeight)
				height += rowHeight + 6
			end
		end
		list.Size = UDim2.new(1, -24, 0, height)
		close.Position = UDim2.fromOffset(12, list.Position.Y.Offset + height + 8)
		close.Size = UDim2.new(1, -24, 0, 36)
		panel.CanvasSize = UDim2.fromOffset(0, close.Position.Y.Offset + 52)
	end
	local function action(label: string, callback: () -> (), enabled: boolean?, dangerous: boolean?)
		local count = 0
		for _, child in list:GetChildren() do if child:IsA("TextButton") then count += 1 end end
		local button = Instance.new("TextButton")
		button.Name = "Action" .. tostring(count)
		button.Text = label; button.Font = Enum.Font.Gotham; button.TextSize = 14
		button.TextWrapped = true; button.BorderSizePixel = 0; button.ZIndex = 87
		button.Position = UDim2.fromOffset(0, count * (if mode == "Build" then 94 else 44)); button.Size = UDim2.new(1, 0, 0, if mode == "Build" then 88 else 38)
		button.Active = enabled ~= false
		if dangerous and button.Active then Theme.applyDangerButton(button) else Theme.applyPrimaryButton(button, button.Active) end
		button.Parent = list
		button.Activated:Connect(function() if button.Active then callback() end end)
	end
	local function fullSystem(name: string)
		hide(); Strategy.OpenSystem(name)
	end
	local function showRadial()
		mode = nil; Transitions.Hide(shell)
		context = resolve()
		if not priority() and (context or gui:GetAttribute("SelectedSystem") == "Military") then Strategy.OpenSystem("Map") end
		if context and not priority() then
			Radial.Show(context, point)
		else Radial.Hide() end
	end
	function Controller.OpenWorkflow(kind: string)
		context = resolve()
		if not context or priority() then return end
		if kind == "Battle" then
			local canCommit = false
			for _, war in State.military.wars or {} do if war.targetTerritoryId == selected then canCommit = true end end
			if canCommit then
				gui:SetAttribute("MilitaryContextMode", "Battle")
				fullSystem("Military"); return
			end
			kind = "Info"
		end
		if kind == "Military" then
			gui:SetAttribute("MilitaryContextMode", if context.holder and tonumber(context.holder.userId) == player.UserId then "Recruit" else "Battle")
			fullSystem("Military"); return
		end
		Strategy.OpenSystem("Map")
		mode = kind
		if kind == "War" or kind == "Betrayal" or kind == "Naval" then selectedPercent = 10 end
		if kind == "Naval" then navalFeedback = "Preview only. Confirm launches and locks troops." end
		if kind == "Betrayal" then
			betrayalQuote = nil; betrayalFeedback = "Preparing a current server review..."; reviewPending = true
			MatchIntent.Send((remotes.WarfareClientEvent :: RemoteEvent), "PrepareBetrayal", selected)
		end
		redraw()
	end
	redraw = function()
		context = resolve()
		if not context or priority() then hide(); return end
		if not mode then showRadial(); return end
		Radial.Hide()
		for _, child in list:GetChildren() do if child:IsA("TextButton") then child:Destroy() end end
		retiredAmount.Visible = false
		bar.Root.Visible = mode == "War" or mode == "Betrayal" or mode == "Naval"
		local pool = if mode == "Betrayal" and betrayalQuote then betrayalQuote.availableAfter else context.available
		local preview = CommitmentPolicy.Amount(pool, selectedPercent)
		bar.Set(selectedPercent, string.format("%d%% · %d troops · Preview only", selectedPercent, preview), (context.canDeclare or (mode == "Naval" and context.canNaval) or (mode == "Betrayal" and context.canBetray and betrayalQuote ~= nil)) and pending == nil)
		header.Text = context.definition.displayName .. " · " .. (if mode == "War" and not context.holder then "Conquest" else mode)
		close.Text = "Cancel · Back to map actions"
		local holder = context.holder
		local root = context.root
		local ownerName = if holder then holder.titleName .. " " .. holder.displayName else "Unclaimed"
		local lines = { context.relation, "Direct owner: " .. ownerName,
			"Root realm: " .. (if root then root.displayName else "None") }
		if holder and root and holder.rulerId ~= root.rulerId then table.insert(lines, "Ordinary external defense: root " .. root.displayName .. ". Permitted/autonomous subjects initiate with their own army.") end
		local militia = context.province and context.province.neutralDefense
		local militiaText = if typeof(militia) == "table" then tostring(militia.current) else "Awaiting state"
		if mode == "Build" then
			lines = { "Personal buildings · Gold: " .. tostring(State.economy.gold or "—") }
			if farmFeedback ~= "" then table.insert(lines, "Last request: " .. farmFeedback) end
			local row = nil
			for _, entry in State.buildings.provinces or {} do if entry.territoryId == selected then row = entry end end
			local gold = tonumber(State.economy.gold) or 0
			local own = context.me and holder and context.me.rulerId == holder.rulerId
			table.insert(lines, "Capital loss eliminates you and surrenders personal land. Placement/relocation is permanently blocked after foreign-realm land adjacency or an enemy naval landing this match.")
   for _, kind in { "Farm", "Town", "Castle", "Capital" } do
				local level = if row then row[string.lower(kind) .. "Level"] or 0 else 0
				local costs = BuildingConfig[kind .. "Costs"]
				local enabled, reason = FarmPolicy.Check(level, level, if row then row.ownershipRevision else 0, if row then row.ownershipRevision else 0, own == true, gui:GetAttribute("MatchEnded") == true, gold, costs)
				if not row then enabled = false; reason = "Waiting for building state" end
				local damaged = row and row.damage and row.damage[kind] == true
    local relocate = kind == "Capital" and State.buildings.capitalProvince and State.buildings.capitalProvince ~= selected
    local operation = if damaged then "RepairBuilding" elseif relocate then "RelocateCapital" else "PurchaseBuilding"
    local price = if damaged then costs[level] * .5 elseif relocate then 0 else costs[level + 1] or 0
    if damaged or relocate then enabled = own == true and gui:GetAttribute("MatchEnded") ~= true and gold >= price;reason = "Ownership, match or funds unavailable." end
    if kind == "Capital" and (level == 0 or relocate) and not damaged and State.buildings.placementReason ~= "" then enabled = false;reason = State.buildings.placementReason or "Waiting for Capital eligibility" end
    if farmPending then enabled = false; reason = "Awaiting building receipt…" end
				local function benefit(at: number): string
					if kind == "Farm" then return string.format("+%d Gold/min", FarmPolicy.Income(at)) end
					if kind == "Capital" then
      local d = BuildingConfig.CapitalDefense[at] or BuildingConfig.NoCapitalDefense
      return string.format("%g%% personal defense · %g%% personal combat · %g%% Prestige", d * 100, (BuildingConfig.CapitalCombat[at] or 0) * 100, (BuildingConfig.CapitalPrestige[at] or 0) * 100)
     end
     if kind == "Town" then return string.format("+%d cap · %g Gold/10 troops", BuildingConfig.TownCapacity[at] or 0, (BuildingConfig.TownPriceTenths[at] or BuildingConfig.BaseRecruitPriceTenths) / 10) end
					local strength = BuildingConfig.CastleStrength[at] or 0
					return string.format("%d baseline / %d max · %d support", strength * .25, strength, strength * .75)
				end
				local displayLevel = if relocate then State.buildings.capitalLevel or 0 else level
				local label = kind .. ": " .. (if damaged then "Repair" elseif relocate then "Relocate here" elseif level == 5 then "Max" elseif level == 0 then "Build" else "Upgrade") .. " · Level " .. displayLevel
				label ..= "\n" .. benefit(displayLevel)
				if damaged then label ..= string.format("\nEffects suspended · Repair %g Gold", price) elseif relocate then label ..= "\nPreserves Capital level · No relocation fee" elseif level < 5 then label ..= string.format("\nNext: %s · %d Gold", benefit(level + 1), costs[level + 1]) end
				if not enabled then label ..= "\n" .. reason end
				action(label, function()
					if farmPending or not row or not enabled then return end
					farmSequence += 1
					local token = farmSequence
					farmPending = token; farmFeedback = ""
					MatchIntent.Send(remotes.BuildingsClientEvent :: RemoteEvent, operation, selected, level, row.ownershipRevision, token, kind, State.buildings.capitalRevision)
					redraw()
					task.delay(8, function()
						if farmPending == token then farmPending = nil; farmFeedback = "Receipt delayed. Refreshing state before retry."; MatchIntent.Send(remotes.BuildingsClientEvent :: RemoteEvent, "Ready"); if mode == "Build" then redraw() end end
					end)
				end, enabled)
			end
		elseif mode == "War" then
			table.insert(lines, "Your available troops: " .. context.available)
			table.insert(lines, if holder then "Enemy reserves are private." else "Public militia: " .. militiaText)
			table.insert(lines, context.warReason or "Border and treaty checks allow a declaration.")
			table.insert(lines, "Selected amount is a preview, not reserved yet. Confirm declares war and requests this reservation. Military shows server acceptance; Ready locks it. Existing deadlines still apply.")
			if preview == 0 then table.insert(lines, "This small troop pool rounds the selected percentage down to zero. Confirming zero cannot field an attack.") end
			if pending then table.insert(lines, "Awaiting server response…") end
			action("Confirm declaration & prepare troops", function()
				local latest = resolve()
				local n = if latest then CommitmentPolicy.Amount(latest.available, selectedPercent) else 0
				if not latest or not latest.canDeclare or pending then redraw(); return end

				pendingToken += 1
				local token = pendingToken
				pending = { territoryId = selected, amount = n, percent = selectedPercent }
				MatchIntent.Send((remotes.WarfareClientEvent :: RemoteEvent), "DeclareWar", selected)
				redraw()
				task.delay(8, function()
					if pending and token == pendingToken then pending = nil; redraw() end
				end)
			end, context.canDeclare and pending == nil)
		elseif mode == "Naval" then
			local choice = context.navalDepartures[1]
			if choice then
				local name = choice.id
				for _, t in mapDef.territories do if t.id == choice.id then name = t.displayName end end
				table.insert(lines, "Automatic departure: " .. name .. " (shortest clear coastline route).")
			end
			if choice then table.insert(lines, string.format("Straight coastal route: %.0f map units / %.1fs. Confirm reserves and locks %d troops; defense window begins on arrival.",choice.route.distance,Routes.TravelSeconds(choice.route,MilitaryConfig),preview)) end
			if preview == 0 then table.insert(lines,"This small troop pool rounds to zero; choose a stop with at least one troop.") end
			table.insert(lines, context.navalReason or navalFeedback)
			action("Confirm naval launch and lock troops", function()
				local latest = resolve();if pending or not latest or not latest.canNaval then redraw();return end
				local amount = CommitmentPolicy.Amount(latest.available,selectedPercent)
				if amount <= 0 then navalFeedback = "At least one available troop required.";redraw();return end
				local token = HttpService:GenerateGUID(false)
				pending = { naval = true, requestId = token, territoryId = selected, amount = amount }
				MatchIntent.Send((remotes.WarfareClientEvent :: RemoteEvent), "LaunchNaval",selected,amount,token);redraw()
			end, context.canNaval and choice ~= nil and preview > 0 and pending == nil)
		elseif mode == "Betrayal" then
			table.insert(lines, "Independent betrayal uses your own forces and remaining subtree. Your former direct liege defends with their own forces.")
			table.insert(lines, "Vassalage breaks only after server acceptance. Your descendants remain yours. The 30% transfer creates no troops.")
			if betrayalQuote then
				table.insert(lines, string.format("Transfer %d of your personal surviving Total troops to your direct liege. Post-transfer available: %d. Preview commitment: %d.", betrayalQuote.penalty, betrayalQuote.availableAfter, preview))
			end
			table.insert(lines, betrayalFeedback)
			local currentReview = betrayalQuote ~= nil and workspace:GetServerTimeNow() < betrayalQuote.expiresAt
			action("Review current betrayal conditions", function()
				if pending or reviewPending then return end
				reviewPending = true; betrayalQuote = nil; betrayalFeedback = "Refreshing server review..."
				MatchIntent.Send((remotes.WarfareClientEvent :: RemoteEvent), "PrepareBetrayal", selected); redraw()
			end, pending == nil and not reviewPending)
			action("Confirm betrayal and 30% troop transfer", function()
				if pending or not betrayalQuote or workspace:GetServerTimeNow() >= betrayalQuote.expiresAt then betrayalFeedback = "Review expired. Review again."; redraw(); return end
				local latest = resolve()
				if not latest or not latest.canBetray then betrayalFeedback = "Betrayal no longer eligible."; redraw(); return end
				pending = { territoryId = selected, amount = CommitmentPolicy.Amount(betrayalQuote.availableAfter, selectedPercent), percent = selectedPercent, betrayal = true }
				MatchIntent.Send((remotes.WarfareClientEvent :: RemoteEvent), "Betray", selected, betrayalQuote.token); redraw()
			end, currentReview and context.canBetray and pending == nil, true)
		elseif mode == "Diplomacy" then
			for _, item in context.diplomacy do
				action(item.label, function()
					local latest = resolve()
					if not latest then return end
					for _, valid in latest.diplomacy do
						if valid.action == item.action and valid.target == item.target and valid.system == item.system then
							MatchIntent.Send((remotes[valid.system .. "ClientEvent"] :: RemoteEvent), valid.action, valid.target)
							return
						end
					end
					redraw()
				end)
			end
		elseif mode == "Message" then
			for _, channel in context.communication do
				action(channel.label, function()
					fullSystem("Communications")
					if channel.userId then Communications.OpenDirect(channel.userId)
					else Communications.OpenContext(channel.contextId) end
				end)
			end
		else
			if holder then
				local personal, realm = 0, 0
				for _, t in State.territory.territories do
					if t.ownerRulerId == holder.rulerId then personal += 1 end
					local r = context.rulers[t.ownerRulerId]
					if r and (r.rootRulerId or r.rulerId) == (holder.rootRulerId or holder.rulerId) then realm += 1 end
				end
				local liege = context.rulers[holder.liegeId]
				table.insert(lines, "Direct liege: " .. (if liege then liege.displayName else "None"))
				table.insert(lines, "Personal holdings: " .. personal .. " · Greater realm: " .. realm)
			else table.insert(lines, "Public militia: " .. militiaText) end
			table.insert(lines, if context.war then "Active conflict here." else context.warReason or "No active conflict here.")
			if mode == "Realm" then action("Your realm overview", function() fullSystem("Realm") end) end
			if context.war then
				table.insert(lines, "Conflict phase: " .. tostring(context.war.phase or "Active"))
			end
		end
		body.Text = table.concat(lines, "\n\n")
		layout()
		Transitions.Show(shell, true)
	end
	MatchIntent.ConnectPush((remotes.WarfareServerEvent :: RemoteEvent), function(kind,payload)
		if kind ~= "NavalResult" then return end
		local ok,data = pcall(HttpService.JSONDecode,HttpService,payload)
		if not ok or typeof(data) ~= "table" or not pending or not pending.naval or data.requestId ~= pending.requestId then return end
		local targetId = pending.territoryId
		pending = nil;navalFeedback = data.message
		if data.accepted and data.active then Map.Select(targetId,"silent"); gui:SetAttribute("MilitaryContextMode","Battle");fullSystem("Military") else redraw() end
	end)
	MatchIntent.ConnectPush(remotes:WaitForChild("BuildingsServerEvent") :: RemoteEvent, function(kind, payload)
		if kind ~= "FarmResult" and kind ~= "BuildingResult" then return end
		local ok, result = pcall(HttpService.JSONDecode, HttpService, payload)
		if ok and typeof(result) == "table" and farmPending == result.requestId then
			farmPending = nil; farmFeedback = if result.territoryId == selected then result.message else ""; if mode == "Build" then redraw() end
		end
	end)
	Radial.Start(gui, Controller.OpenWorkflow)
	Map.SelectionChanged.Event:Connect(function(id, position, workflow)
		if selected ~= id then farmFeedback = "" end
		selected = id; point = position or point
		selectedPercent = 10
		if workflow == "silent" then hide()
		elseif workflow then Controller.OpenWorkflow(workflow)
		else showRadial() end
	end)
	close.Activated:Connect(showRadial)
	gui:GetAttributeChangedSignal("SelectedSystem"):Connect(function()
		if gui:GetAttribute("SelectedSystem") ~= "Map" then hide() end
	end)
	for _, name in { "VassalageOfferOverlay", "DiplomacyOfferOverlay" } do
		gui[name]:GetPropertyChangedSignal("Visible"):Connect(function()
			if priority() then
				hide()
				if gui:GetAttribute("SelectedSystem") == "Military" then Strategy.OpenSystem("Map") end
			end
		end)
	end
	for _, name in { "RealmOverviewOpen", "VictoryOverlayOpen", "MatchEnded" } do
		gui:GetAttributeChangedSignal(name):Connect(function()
			if priority() then
				hide()
				if gui:GetAttribute("SelectedSystem") == "Military" then Strategy.OpenSystem("Map") end
			elseif Transitions.IsOpen(shell) or Transitions.IsOpen(gui.ContextRadialPanel) then redraw() end
		end)
	end
	UserInputService.InputBegan:Connect(function(input, processed)
		if input.KeyCode == Enum.KeyCode.Escape and not processed then hide() end
	end)
	gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(layout)
	body:GetPropertyChangedSignal("TextSize"):Connect(layout)
	body:GetPropertyChangedSignal("FontFace"):Connect(layout)
	Theme.PresentationChanged.Event:Connect(layout)
	State.Changed.Event:Connect(function(system, kind, data)
		if pending and not pending.naval and system == "military" and kind == "State" then
			for _, war in data.wars or {} do
				if war.targetTerritoryId == pending.territoryId and war.role == "Attacker" and war.phase == "commit" and not war.locked then
					local initial = pending.amount
					local percent = pending.percent
					local targetId = pending.territoryId
					pending = nil
					-- Restore the reviewed target if the player selected elsewhere while awaiting a reply.
					Map.Select(targetId, "silent")
					Military.PrepareCommit(war.warId, initial, percent)
					gui:SetAttribute("MilitaryContextMode", "Battle")
					fullSystem("Military")
					break
				end
			end
		elseif pending and not pending.betrayal and not pending.naval and system == "warfare" and kind == "Notice" then pending = nil end
		if Transitions.IsOpen(shell) or Transitions.IsOpen(gui.ContextRadialPanel) then redraw() end
	end)
	local warfarePush = remotes.WarfareServerEvent :: RemoteEvent
	MatchIntent.ConnectPush(warfarePush, function(kind, payload)
		if kind ~= "BetrayalReview" and kind ~= "BetrayalResult" then return end
		local ok, receipt = pcall(HttpService.JSONDecode, HttpService, payload)
		if not ok or typeof(receipt) ~= "table" then return end
		if kind == "BetrayalResult" and pending and pending.betrayal and receipt.target == pending.territoryId and not receipt.accepted then
			pending = nil
		end
		if receipt.target ~= selected then return end
		if kind == "BetrayalReview" then
			reviewPending = false
			betrayalQuote = if receipt.accepted then receipt.review else nil
			betrayalFeedback = if receipt.accepted then receipt.review.message else receipt.message
			if betrayalQuote then
				local quoteToken = betrayalQuote.token
				task.delay(math.max(0, betrayalQuote.expiresAt - workspace:GetServerTimeNow()), function()
					if betrayalQuote and betrayalQuote.token == quoteToken then
						betrayalQuote = nil; betrayalFeedback = "Betrayal review expired. Review current conditions again."
						if mode == "Betrayal" then redraw() end
					end
				end)
			end
		elseif not receipt.accepted then pending = nil; betrayalQuote = nil; betrayalFeedback = receipt.message end
		if mode == "Betrayal" then redraw() end
	end)
	MatchIntent.OnChanged(function()
		farmPending = nil; farmFeedback = ""
		pendingToken += 1;pending = nil;reviewPending = false;betrayalQuote = nil
		selectedPercent = 10;selected = nil;mode = nil;navalFeedback = "";betrayalFeedback = ""
		hide()
	end)
	gui:SetAttribute("MapContextEnabled", true)
	State.Start()
end
return Controller
