--!strict
-- Presentation and navigation only; gameplay controllers retain their contracts.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TextService = game:GetService("TextService")
local Bindings = require(ReplicatedStorage.Shared.Config.PresentationBindings)
local Overview = require(script.Parent.RealmOverviewController)
local Theme = require(ReplicatedStorage.Shared.Util.PrototypeGuiTheme)
local Transitions = require(ReplicatedStorage.Shared.Util.ContextTransitions)
local Map = require(script.Parent.TerritoryMapController)
local Controller = {}
local started = false
local panels = { Realm = "Main", Titles = "TitlePanel", Military = "MilitaryWorkflowPanel", Economy = "EconomyPanel", Communications = "CommunicationsPanel" }
function Controller.Start()
	if started then return end
	started = true
	Overview.Start()
	local gui = Players.LocalPlayer:WaitForChild("PlayerGui"):WaitForChild("HierarchyPrototypeGui") :: ScreenGui
	local nav = gui:WaitForChild("StrategyNavigation") :: ScrollingFrame
	local top = gui:WaitForChild("StrategyTopbar") :: Frame
	local hint = gui:WaitForChild("MapHint") :: TextLabel
	local map = gui:WaitForChild("MapStage") :: Frame
	local selected = "Map"
	local C = Theme.Colors
	local commsPanel = gui.CommunicationsPanel
	Theme.applyPanel(commsPanel)
	for _, item in commsPanel:GetDescendants() do
		if item:IsA("TextLabel") then
			Theme.applyText(item, if item.Name == "Header" then "Heading" elseif item.Name == "Status" then "Caption" else "Body")
		end
		if item:IsA("TextButton") and item.Parent == commsPanel then
			if item.Name == "SendButton" then Theme.applyPrimaryButton(item, item.Active)
			else Theme.applySecondaryButton(item, item.Active) end
		end
	end
	local buttons = {}
	local layout: () -> ()
	local function position(item: GuiObject, x: number, y: number, w: number, h: number)
		item.AnchorPoint = Vector2.zero
		item.Position = UDim2.fromOffset(x,y)
		item.Size = UDim2.fromOffset(w,h)
	end
	local function gotoPanel(name: string)
		if name ~= "Map" and not panels[name] then return end
		selected = name
		gui:SetAttribute("SelectedSystem",name)
		for key, panelName in panels do
			local view = gui:FindFirstChild(panelName) :: GuiObject
			if view:IsA("CanvasGroup") then
				if key ~= name then Transitions.Hide(view, true) end
			else view.Visible = key == name end
		end
		for key, button in buttons do
			button.BackgroundColor3 = if key == name then C.action else C.well
			button.TextColor3 = if key == name then C.actionText else C.textSecondary
		end
		layout()
		if name == "Military" then Transitions.Show(gui.MilitaryWorkflowPanel, true) end
	end
	Controller.OpenSystem = gotoPanel
	local function layer(item: Instance, z: number)
		if item:IsA("GuiObject") then item.ZIndex = z end
		for _, child in item:GetDescendants() do
			if child:IsA("GuiObject") then child.ZIndex = z + 1 end
		end
	end
	layout = function()
		local size = gui.AbsoluteSize
		local w,h = size.X,size.Y
		if w < 1 or h < 1 then return end
		local density = Theme.Presentation.UIScale
		local rail = (if w < 760 then 80 else 100) * density
		local drawerMax = math.max(180, math.min(400, w - rail - 200))
		local drawer = math.clamp(w * 0.34 * density, math.min(260, drawerMax), drawerMax)
		local open = selected ~= "Map" or gui.ContextWorkflowPanel:GetAttribute("ContextOpen") == true
		local left = rail + 20
		local mapWidth = math.max(180,w-left-12-(if open then drawer+12 else 0))
		position(top,8,4,w-16,64)
		position(nav,8,76,rail,math.max(120,h-108))
		local navY = 4
		for _, name in { "Map", "Realm", "Titles", "Economy", "Communications", "Players", "MatchResult" } do
			local button = buttons[name]
			if button then
				button.Size = UDim2.new(1, -8, 0, 42 * density)
				button.Position = UDim2.fromOffset(4, navY)
				if button.Visible then navY += 42 * density + 8 end
			end
		end
		nav.RequestNotice.Position = UDim2.fromOffset(4, navY)
		nav.CanvasSize = UDim2.fromOffset(0, navY + (if nav.RequestNotice.Visible then 52 else 0))
		position(top.Gold,math.floor(w*0.42),8,math.floor(w*0.28)-20,52)
		position(top.Troops,math.floor(w*0.72),8,math.floor(w*0.28)-24,48)
		top.Gold.TextSize = if w < 760 then 12 else 14
		top.Troops.TextSize = if w < 760 then 12 else 14
		top.Ruler.Size = UDim2.fromOffset(math.max(120,math.floor(w*0.42)-32),22)
		top.Brand.Size = top.Ruler.Size
		top.Brand.TextSize = if w < 760 then 12 else 16
		position(map,left,76,mapWidth,math.max(160,h-108))
		position(hint,left,h-26,mapWidth,20)
		hint.Text = if gui:GetAttribute("MatchEnded") then "MATCH ENDED · Inspect map / Match result" else "Drag to pan · Wheel to zoom"
		hint.TextSize = 11
		for _, name in panels do
			local panel = gui:FindFirstChild(name) :: GuiObject
			position(panel,w-drawer-12,76,drawer,math.max(180,h-108))
			layer(panel,20)
		end
		local realm = gui.Main
		local realmPadding = realm:FindFirstChildOfClass("UIPadding")
		local realmInset = if realmPadding then realmPadding.PaddingLeft.Offset + realmPadding.PaddingRight.Offset else 0
		local realmWidth = math.max(1, drawer - 24 - realmInset - (if realm:IsA("ScrollingFrame") then realm.ScrollBarThickness else 0))
		local function realmTextHeight(label: TextLabel, minimum: number): number
			return math.max(minimum, TextService:GetTextSize(label.Text, label.TextSize, label.Font, Vector2.new(realmWidth,100000)).Y + 12)
		end
		local selfHeight = realmTextHeight(realm.SelfInfo,90)
		realm.SelfInfo.Size = UDim2.fromOffset(realmWidth,selfHeight)
		local council = realm:FindFirstChild("CouncilBody")
		local councilHeight = 0
		if council then
			councilHeight = realmTextHeight(council,40)
			council.Size = UDim2.fromOffset(realmWidth,councilHeight)
			realm.CouncilHeader.Size = UDim2.fromOffset(realmWidth,24)
		end
		realm.TreeScroll.Size = UDim2.fromOffset(realmWidth,math.max(110,h-280-(selfHeight-90)-councilHeight-32))
		local comms = gui.CommunicationsPanel
		local cw,ch = drawer,math.max(400,h-108)
		comms.CanvasSize = UDim2.fromOffset(0,ch)
		position(comms.Header,12,10,cw-114,24)
		position(comms.MuteObserver,cw-88,10,76,24)
		position(comms.Status,12,40,cw-24,32)
		position(comms.ConvList,12,80,cw-24,72)
		position(comms.Transcript,12,164,cw-24,ch-260)
		position(comms.ContactList,12,164,cw-24,ch-260)
		position(comms.Input,12,ch-86,cw-140,32)
		position(comms.SendButton,cw-120,ch-86,50,32)
		position(comms.HelpButton,cw-64,ch-86,52,32)
		position(comms.DirectButton,12,ch-46,cw-134,32)
		position(comms.ObserverButton,cw-114,ch-46,102,32)
		local title = gui.TitlePanel
		local titlePadding = title:FindFirstChildOfClass("UIPadding")
		local titleInset = if titlePadding then titlePadding.PaddingLeft.Offset + titlePadding.PaddingRight.Offset else 0
		local titleWidth = math.max(1, drawer - 24 - titleInset - title.ScrollBarThickness)
		position(title.Header,12,10,titleWidth,28)
		local titleHeight = math.max(90, TextService:GetTextSize(title.Body.Text, title.Body.TextSize, title.Body.Font,
			Vector2.new(titleWidth,100000)).Y + 12)
		position(title.Body,12,44,titleWidth,titleHeight)
		position(title.EstablishButton,12,56+titleHeight,titleWidth,36)
		if title:IsA("ScrollingFrame") then title.CanvasSize = UDim2.fromOffset(0,104+titleHeight) end
		local military = gui.MilitaryWorkflowPanel.Content
		local function textHeight(label: TextLabel, minimum: number): number
			return math.max(minimum, TextService:GetTextSize(label.Text, label.TextSize, label.Font, Vector2.new(math.max(1, drawer - 44), 100000)).Y + 12)
		end
		position(military.Header,12,10,drawer-24,28)
		position(military.Stats,12,44,drawer-24,textHeight(military.Stats,64))
		local y = 44 + military.Stats.Size.Y.Offset + 12
		local recruitment = military:FindFirstChild("RecruitmentBar")
		if recruitment then position(recruitment,12,y,drawer-44,96) end
		if gui:GetAttribute("MilitaryContextMode") == "Recruit" then
			y += 104
			position(military.CostLabel,12,y,drawer-44,textHeight(military.CostLabel,36))
			y += military.CostLabel.Size.Y.Offset + 12
			position(military.RecruitButton,12,y,drawer-44,36)
			y += 48
		end
		position(military.CommitBody,12,y,drawer-44,textHeight(military.CommitBody,36))
		y += military.CommitBody.Size.Y.Offset + 12
		local bar = military:FindFirstChild("CommitmentBar")
		if bar then
			position(bar,12,y,drawer-44,96)
			if bar.Visible then y += 104 end
		end
		position(military.LockButton,12,y,drawer-44,36)
		if military.LockButton.Visible then y += 44 end
		position(military.BackButton,12,y+4,drawer-44,36)
		military.CanvasSize = UDim2.fromOffset(0,y+52)
		for i,name in {"VassalageOfferOverlay","DiplomacyOfferOverlay"} do
			local overlay = gui:FindFirstChild(name) :: GuiObject
			overlay.AnchorPoint = Vector2.new(0.5,0.5)
			overlay.Position = UDim2.new(0.5,0,0,h/2+(if i == 1 then -93 else 93))
			overlay.Size = UDim2.fromOffset(math.min(460,w-48),172)
			layer(overlay,100+i*4)
		end
		local toast = gui.ResultToast
		toast.AnchorPoint = Vector2.new(0.5,0)
		toast.Position = UDim2.new(0.5,0,0,76)
		toast.Size = UDim2.fromOffset(math.min(520,w-40),64)
		layer(toast,140)
		local inspect = gui:FindFirstChild("AdminInspectPanel")
		if inspect and inspect:IsA("GuiObject") then
			inspect.AnchorPoint = Vector2.new(0.5,0.5)
			inspect.Position = UDim2.fromScale(0.5,0.5)
			inspect.Size = UDim2.fromOffset(math.min(640,w-48),math.min(400,h-48))
			layer(inspect,160)
		end
	end
	for _, button in nav:GetChildren() do
		if button:IsA("TextButton") then
			local name = button.Name
			buttons[name] = button
			button.Activated:Connect(function()
				if name == "MatchResult" then return end
				if name == "Players" then Overview.SetOpen(true); return end
				if gui:GetAttribute("RealmOverviewOpen") then return end
				gotoPanel(if selected == name then "Map" else name)
			end)
			button.MouseEnter:Connect(function()
				if selected ~= name then button.BackgroundColor3=C.row end
			end)
			button.MouseLeave:Connect(function()
				button.BackgroundColor3 = if selected == name then C.action else C.well
			end)
		end
	end
	local function summaries()
		local economy = gui.EconomyPanel.Body.Text
		local gold = string.match(economy,"Gold: ([^\n]+)") or "—"
		local income = if gui:GetAttribute("MatchEnded") then "Income frozen · Match ended" else (string.match(economy,"Income: ([^\n]+)") or "Loading treasury")
		local prestige = gui:GetAttribute("PersonalPrestige")
		local prestigeRate = gui:GetAttribute("PrestigePerMinute") or 0
		local prestigeText = if prestige == nil then "P —" else "P " .. tostring(prestige)
			.. (if gui:GetAttribute("MatchEnded") then " · frozen" else " · +" .. tostring(prestigeRate) .. "/m")
		top.Gold.Text = "GOLD  "..gold.."\n"..income.."\n"..prestigeText
		top.Troops.Text = "TROOPS  " .. tostring(gui:GetAttribute("MilitaryAvailable") or "—") .. " available\n" .. tostring(gui:GetAttribute("MilitaryCommitted") or "0") .. (if gui:GetAttribute("MilitaryPresenting") then " held" else " reserved")
		local self = gui.Main.SelfInfo.Text
		top.Ruler.Text = if gui:GetAttribute("Eliminated") then "Eliminated  ·  Spectating" elseif gui:GetAttribute("MatchEnded") and not string.match(self,"Name: ([^\n]+)") then "Spectator  ·  Match ended" else (string.match(self,"Rank: ([^\n]+)") or "Ruler").."  ·  "..(string.match(self,"Name: ([^\n]+)") or "Connecting")
		top.Brand.Text = (if gui:GetAttribute("MatchEnded") then "FINAL REALM" else "REALM") .. "  "
			.. tostring(top:GetAttribute("DominationControlled") or "—") .. "/" .. tostring(top:GetAttribute("DominationRequired") or "—")
			.. " · Domination"

	end
	gui:GetAttributeChangedSignal("MatchEnded"):Connect(summaries)
	gui:GetAttributeChangedSignal("Eliminated"):Connect(summaries)
	for _, attribute in { "DominationControlled", "DominationRequired" } do top:GetAttributeChangedSignal(attribute):Connect(summaries) end
	for _, label in {gui.EconomyPanel.Body,gui.Main.SelfInfo} do
		label:GetPropertyChangedSignal("Text"):Connect(summaries)
	end
	local function style(inst: Instance)
		Theme.StyleControl(inst)
		if (inst.Name == "CouncilBody" or inst.Name == "SelfInfo") and inst:IsA("TextLabel") then
			for _, property in { "Text", "TextSize", "FontFace" } do inst:GetPropertyChangedSignal(property):Connect(layout) end
			task.defer(layout)
		end
		if inst.Name == "CommitmentBar" and inst:IsA("GuiObject") then
			inst:GetPropertyChangedSignal("Visible"):Connect(layout)
			task.defer(layout)
		end
	end
	for _, item in gui:GetDescendants() do style(item) end
	gui.DescendantAdded:Connect(style)
	gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(layout)
	Theme.PresentationChanged.Event:Connect(layout)
	gui:GetAttributeChangedSignal("MilitaryContextMode"):Connect(layout)
	gui.ContextWorkflowPanel:GetAttributeChangedSignal("ContextOpen"):Connect(layout)
	for _, property in { "Text", "TextSize", "FontFace" } do gui.TitlePanel.Body:GetPropertyChangedSignal(property):Connect(layout) end
	for _, label in { gui.MilitaryWorkflowPanel.Content.Stats, gui.MilitaryWorkflowPanel.Content.CommitBody, gui.MilitaryWorkflowPanel.Content.CostLabel } do
		for _, property in { "Text", "TextSize", "FontFace" } do label:GetPropertyChangedSignal(property):Connect(layout) end
	end
	for _, control in { gui.MilitaryWorkflowPanel.Content.LockButton } do control:GetPropertyChangedSignal("Visible"):Connect(layout) end

	gui.ChildAdded:Connect(function() task.defer(layout) end)
	gui:GetAttributeChangedSignal("MilitaryAvailable"):Connect(summaries)
	gui:GetAttributeChangedSignal("MilitaryCommitted"):Connect(summaries)
	gui:GetAttributeChangedSignal("MilitaryPresenting"):Connect(summaries)
	gui:GetAttributeChangedSignal("PersonalPrestige"):Connect(summaries)
	gui:GetAttributeChangedSignal("PrestigePerMinute"):Connect(summaries)
	gui.MilitaryWorkflowPanel.Content.BackButton.Activated:Connect(function()
		gotoPanel("Map")
		Map.Select(gui.PresentationState.SelectedTerritoryId.Value)
	end)
	UserInputService.InputBegan:Connect(function(input, processed)
		if input.KeyCode == Enum.KeyCode.Escape and not processed and selected == "Military" then gotoPanel("Map") end
	end)
	for _, name in {"VassalageOfferOverlay","DiplomacyOfferOverlay"} do
		local overlay=gui[name]
		overlay:GetPropertyChangedSignal("Visible"):Connect(function()
			nav.RequestNotice.Visible=gui.VassalageOfferOverlay.Visible or gui.DiplomacyOfferOverlay.Visible
			layout()
		end)
	end
	nav.MatchResult:GetPropertyChangedSignal("Visible"):Connect(layout)
	local tabHeld = false
	UserInputService.InputBegan:Connect(function(input, processed)
		if input.KeyCode ~= Bindings.HoldRealmOverview or processed or UserInputService:GetFocusedTextBox() then return end
		tabHeld = true
		Overview.SetOpen(true)
	end)
	UserInputService.InputEnded:Connect(function(input)
		if input.KeyCode == Bindings.HoldRealmOverview and tabHeld then
			tabHeld = false
			Overview.SetOpen(false)
		end
	end)
	UserInputService.WindowFocusReleased:Connect(function() tabHeld = false; Overview.SetOpen(false) end)
	UserInputService.TextBoxFocused:Connect(function() if tabHeld then tabHeld = false; Overview.SetOpen(false) end end)
	summaries()
	gotoPanel("Map")
end
return Controller
