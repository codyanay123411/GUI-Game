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
	commsPanel.BackgroundColor3 = C.panel
	for _, item in commsPanel:GetDescendants() do
		if item:IsA("TextLabel") then
			item.BackgroundTransparency = 1
			item.Font = Enum.Font.Gotham
			item.TextSize = 14
		end
		if item:IsA("TextButton") and item.Parent == commsPanel then
			Theme.applyPrimaryButton(item, item.Active)
		end
	end
	commsPanel.Header.Font = Enum.Font.GothamBold
	commsPanel.Header.TextSize = 16
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
		local open = selected ~= "Map"
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
		position(top.Gold,math.floor(w*0.42),8,math.floor(w*0.28)-20,48)
		position(top.Troops,math.floor(w*0.72),8,math.floor(w*0.28)-24,48)
		top.Gold.TextSize = if w < 760 then 12 else 14
		top.Troops.TextSize = if w < 760 then 12 else 14
		top.Ruler.Size = UDim2.fromOffset(math.max(120,math.floor(w*0.42)-32),22)
		position(map,left,76,mapWidth,math.max(160,h-108))
		position(hint,left,h-26,mapWidth,20)
		hint.Text = if gui:GetAttribute("MatchEnded") then "MATCH ENDED  ·  Inspect the map  ·  Players  ·  Match result" else (if top:GetAttribute("DominationRequired") then "Domination: " .. tostring(top:GetAttribute("DominationRequired")) .. " territories  ·  Drag to pan  ·  Wheel to zoom" else "Drag to pan  ·  Wheel to zoom  ·  Select a territory")
		for _, name in panels do
			local panel = gui:FindFirstChild(name) :: GuiObject
			position(panel,w-drawer-12,76,drawer,math.max(180,h-108))
			layer(panel,20)
		end
		local realm = gui.Main
		realm.TreeScroll.Size = UDim2.new(1,0,0,math.max(110,h-280))
		realm.SelfInfo.Size = UDim2.new(1,0,0,90)
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
		title.Body.Size = UDim2.new(1,0,1,-116)
		local military = gui.MilitaryWorkflowPanel.Content
		local function textHeight(label: TextLabel, minimum: number): number
			return math.max(minimum, TextService:GetTextSize(label.Text, label.TextSize, label.Font, Vector2.new(math.max(1, drawer - 44), 100000)).Y + 12)
		end
		position(military.Header,12,10,drawer-24,28)
		position(military.Stats,12,44,drawer-24,textHeight(military.Stats,64))
		local y = 44 + military.Stats.Size.Y.Offset + 12
		position(military.RecruitBox,12,y,drawer*.5-18,36)
		position(military.RecruitButton,drawer*.5,y,drawer*.5-66,36)
		position(military.MaxRecruitButton,drawer-60,y,48,36)
		military.MaxRecruitButton.Text = "Max"
		position(military.CostLabel,12,y+40,drawer-24,textHeight(military.CostLabel,24))
		if gui:GetAttribute("MilitaryContextMode") == "Recruit" then y += 80 end
		position(military.CommitBody,12,y,drawer-24,textHeight(military.CommitBody,36))
		y += military.CommitBody.Size.Y.Offset + 12
		position(military.CommitBox,12,y,drawer-24,36)
		if military.CommitBox.Visible then y += 44 end
		position(military.LockButton,12,y,drawer-24,36)
		if military.LockButton.Visible then y += 44 end
		position(military.BackButton,12,y+4,drawer-24,36)
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
		top.Gold.Text = "GOLD  "..gold.."\n"..income
		top.Troops.Text = "TROOPS  " .. tostring(gui:GetAttribute("MilitaryAvailable") or "—") .. " available\n" .. tostring(gui:GetAttribute("MilitaryCommitted") or "0") .. " committed"
		local self = gui.Main.SelfInfo.Text
		top.Ruler.Text = if gui:GetAttribute("MatchEnded") and not string.match(self,"Name: ([^\n]+)") then "Spectator  ·  Match ended" else (string.match(self,"Rank: ([^\n]+)") or "Ruler").."  ·  "..(string.match(self,"Name: ([^\n]+)") or "Connecting")

	end
	gui:GetAttributeChangedSignal("MatchEnded"):Connect(summaries)
	for _, label in {gui.EconomyPanel.Body,gui.Main.SelfInfo} do
		label:GetPropertyChangedSignal("Text"):Connect(summaries)
	end
	local function style(inst: Instance)
		if inst:IsA("TextBox") then
			inst.BackgroundColor3=C.well; inst.TextColor3=C.textPrimary;inst.PlaceholderColor3=C.textMuted
			inst.Font=Enum.Font.Gotham;inst.TextSize=14;inst.BorderSizePixel=0
		elseif inst:IsA("ScrollingFrame") then
			inst.ScrollBarThickness=5;inst.ScrollBarImageColor3=C.section
		end
	end
	for _, item in gui:GetDescendants() do style(item) end
	gui.DescendantAdded:Connect(style)
	gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(layout)
	Theme.PresentationChanged.Event:Connect(layout)
	gui:GetAttributeChangedSignal("MilitaryContextMode"):Connect(layout)
	for _, label in { gui.MilitaryWorkflowPanel.Content.Stats, gui.MilitaryWorkflowPanel.Content.CommitBody, gui.MilitaryWorkflowPanel.Content.CostLabel } do
		for _, property in { "Text", "TextSize", "FontFace" } do label:GetPropertyChangedSignal(property):Connect(layout) end
	end
	for _, control in { gui.MilitaryWorkflowPanel.Content.CommitBox, gui.MilitaryWorkflowPanel.Content.LockButton } do control:GetPropertyChangedSignal("Visible"):Connect(layout) end

	gui.ChildAdded:Connect(function() task.defer(layout) end)
	gui:GetAttributeChangedSignal("MilitaryAvailable"):Connect(summaries)
	gui:GetAttributeChangedSignal("MilitaryCommitted"):Connect(summaries)
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
