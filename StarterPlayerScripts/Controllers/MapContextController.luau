--!strict
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
local CommitmentPolicy = require(ReplicatedStorage.Shared.Util.CommitmentPolicy)
local CommitmentBar = require(script.Parent.CommitmentBar)
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
			gui:GetAttribute("MatchEnded") == true, workspace:GetServerTimeNow()) else nil
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
		local count = 0
		for _, child in list:GetChildren() do if child:IsA("TextButton") then count += 1 end end
		list.Size = UDim2.new(1, -24, 0, count * 44)
		close.Position = UDim2.fromOffset(12, list.Position.Y.Offset + count * 44 + 8)
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
		button.Position = UDim2.fromOffset(0, count * 44); button.Size = UDim2.new(1, 0, 0, 38)
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
		if kind == "War" or kind == "Betrayal" then selectedPercent = 10 end
		if kind == "Betrayal" then
			betrayalQuote = nil; betrayalFeedback = "Preparing a current server review..."; reviewPending = true
			(remotes.WarfareClientEvent :: RemoteEvent):FireServer("PrepareBetrayal", selected)
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
		bar.Root.Visible = mode == "War" or mode == "Betrayal"
		local pool = if mode == "Betrayal" and betrayalQuote then betrayalQuote.availableAfter else context.available
		local preview = CommitmentPolicy.Amount(pool, selectedPercent)
		bar.Set(selectedPercent, string.format("%d%% · %d troops · Preview only", selectedPercent, preview), (context.canDeclare or (mode == "Betrayal" and context.canBetray and betrayalQuote ~= nil)) and pending == nil)
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
		if mode == "War" then
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
				(remotes.WarfareClientEvent :: RemoteEvent):FireServer("DeclareWar", selected)
				redraw()
				task.delay(8, function()
					if pending and token == pendingToken then pending = nil; redraw() end
				end)
			end, context.canDeclare and pending == nil)
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
				(remotes.WarfareClientEvent :: RemoteEvent):FireServer("PrepareBetrayal", selected); redraw()
			end, pending == nil and not reviewPending)
			action("Confirm betrayal and 30% troop transfer", function()
				if pending or not betrayalQuote or workspace:GetServerTimeNow() >= betrayalQuote.expiresAt then betrayalFeedback = "Review expired. Review again."; redraw(); return end
				local latest = resolve()
				if not latest or not latest.canBetray then betrayalFeedback = "Betrayal no longer eligible."; redraw(); return end
				pending = { territoryId = selected, amount = CommitmentPolicy.Amount(betrayalQuote.availableAfter, selectedPercent), percent = selectedPercent, betrayal = true }
				(remotes.WarfareClientEvent :: RemoteEvent):FireServer("Betray", selected, betrayalQuote.token); redraw()
			end, currentReview and context.canBetray and pending == nil, true)
		elseif mode == "Diplomacy" then
			for _, item in context.diplomacy do
				action(item.label, function()
					local latest = resolve()
					if not latest then return end
					for _, valid in latest.diplomacy do
						if valid.action == item.action and valid.target == item.target and valid.system == item.system then
							(remotes[valid.system .. "ClientEvent"] :: RemoteEvent):FireServer(valid.action, valid.target)
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
	Radial.Start(gui, Controller.OpenWorkflow)
	Map.SelectionChanged.Event:Connect(function(id, position, workflow)
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
		if pending and system == "military" and kind == "State" then
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
		elseif pending and not pending.betrayal and system == "warfare" and kind == "Notice" then pending = nil end
		if Transitions.IsOpen(shell) or Transitions.IsOpen(gui.ContextRadialPanel) then redraw() end
	end)
	local warfarePush = remotes.WarfareServerEvent :: RemoteEvent
	warfarePush.OnClientEvent:Connect(function(kind, payload)
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
	gui:SetAttribute("MapContextEnabled", true)
	State.Start()
end
return Controller
