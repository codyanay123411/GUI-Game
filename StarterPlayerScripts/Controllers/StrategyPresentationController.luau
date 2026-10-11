--!strict
-- Presentation and navigation only; gameplay controllers retain their contracts.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local Bindings = require(ReplicatedStorage.Shared.Config.PresentationBindings)
local Overview = require(script.Parent.RealmOverviewController)
local Theme = require(ReplicatedStorage.Shared.Util.PrototypeGuiTheme)
local Controller = {}
local started = false
local panels = { Realm = "Main", Titles = "TitlePanel", Territory = "TerritoryInfo", Diplomacy = "DiplomacyPanel", Military = "MilitaryPanel", Economy = "EconomyPanel", Communications = "CommunicationsPanel" }
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
	local emptyRulers = Instance.new("TextLabel")
	emptyRulers.Name = "EmptyRulers"
	emptyRulers.BackgroundTransparency = 1
	emptyRulers.Size = UDim2.new(1, -12, 0, 48)
	emptyRulers.Text = "No other rulers in this match yet."
	emptyRulers.TextWrapped = true
	emptyRulers.Font = Enum.Font.Gotham
	emptyRulers.TextSize = 14
	emptyRulers.TextColor3 = C.textSecondary
	emptyRulers.Parent = gui.Main.PlayerList
	local function updateRulersEmpty()
		emptyRulers.Visible = gui.Main.PlayerList:FindFirstChildWhichIsA("Frame") == nil
	end
	gui.Main.PlayerList.ChildAdded:Connect(updateRulersEmpty)
	gui.Main.PlayerList.ChildRemoved:Connect(updateRulersEmpty)
	updateRulersEmpty()
	local buttons = {}
	local layout: () -> ()
	local function position(item: GuiObject, x: number, y: number, w: number, h: number)
		item.AnchorPoint = Vector2.zero
		item.Position = UDim2.fromOffset(x,y)
		item.Size = UDim2.fromOffset(w,h)
	end
	local function gotoPanel(name: string)
		selected = name
		gui:SetAttribute("SelectedSystem",name)
		for key, panelName in panels do
			(gui:FindFirstChild(panelName) :: GuiObject).Visible = key == name
		end
		for key, button in buttons do
			button.BackgroundColor3 = if key == name then C.action else C.well
			button.TextColor3 = if key == name then C.actionText else C.textSecondary
		end
		layout()
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
		for _, button in buttons do button.Size = UDim2.new(1, -8, 0, 42 * density) end
		nav.CanvasSize = UDim2.fromOffset(0,540)
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
		realm.TreeScroll.Size = UDim2.new(1,0,0,110)
		realm.PlayerList.Size = UDim2.new(1,0,0,140)
		realm.SelfInfo.Size = UDim2.new(1,0,0,90)
		local dip = gui.DiplomacyPanel
		dip.Status.Size = UDim2.new(1,0,0,64)
		dip.List.Size = UDim2.new(1,0,0,math.max(130,h-238))
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
		local territory = gui.TerritoryInfo
		territory.Body.Size = UDim2.new(1,0,0,140)
		territory.WarStatus.Size = UDim2.new(1,0,0,110)
		territory.WarStatus.TextTruncate = Enum.TextTruncate.None
		local title = gui.TitlePanel
		title.Body.Size = UDim2.new(1,0,1,-116)
		local military = gui.MilitaryPanel
		military.CanvasSize = UDim2.fromOffset(0,470)
		military.Stats.Position = UDim2.fromOffset(12,44)
		military.Stats.Size = UDim2.new(1,-24,0,72)
		military.Stats.TextSize = 18
		military.RecruitBox.Position = UDim2.fromOffset(12,126)
		military.RecruitBox.Size = UDim2.new(0.5,-18,0,32)
		military.RecruitButton.Position = UDim2.new(0.5,0,0,126)
		military.RecruitButton.Size = UDim2.new(0.5,-66,0,32)
		military.MaxRecruitButton.AnchorPoint = Vector2.zero
		military.MaxRecruitButton.Position = UDim2.new(1,-60,0,126)
		military.MaxRecruitButton.Size = UDim2.fromOffset(48,32)
		military.MaxRecruitButton.Text = "Max"
		military.CostLabel.Position = UDim2.fromOffset(12,166)
		military.CostLabel.Size = UDim2.new(1,-24,0,24)
		military.CommitBody.Position = UDim2.fromOffset(12,200)
		military.CommitBox.Position = UDim2.fromOffset(12,360)
		military.CommitBox.Size = UDim2.new(1,-24,0,32)
		military.LockButton.Position = UDim2.fromOffset(12,402)
		military.LockButton.Size = UDim2.new(1,-24,0,34)
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
		local stats = gui.MilitaryPanel.Stats.Text
		top.Troops.Text = "TROOPS  "..(string.match(stats,"Available: ([^\n]+)") or "—").." available\n"..(string.match(stats,"Committed: ([^\n]+)") or "0").." committed"
		local self = gui.Main.SelfInfo.Text
		top.Ruler.Text = if gui:GetAttribute("MatchEnded") and not string.match(self,"Name: ([^\n]+)") then "Spectator  ·  Match ended" else (string.match(self,"Rank: ([^\n]+)") or "Ruler").."  ·  "..(string.match(self,"Name: ([^\n]+)") or "Connecting")
		local war = gui.TerritoryInfo.WarStatus.Text
		buttons.Military.Text = if string.find(war,"No active wars",1,true) then "Military" else "Military  •"
	end
	gui:GetAttributeChangedSignal("MatchEnded"):Connect(summaries)
	for _, label in {gui.EconomyPanel.Body,gui.MilitaryPanel.Stats,gui.Main.SelfInfo,gui.TerritoryInfo.WarStatus} do
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
	gui.ChildAdded:Connect(function() task.defer(layout) end)
	local territoryValue = gui.TerritoryInfo.SelectedTerritoryId
	local previousCommitment: string? = nil
	gui.MilitaryPanel.CommitBody:GetPropertyChangedSignal("Text"):Connect(function()
		local text = gui.MilitaryPanel.CommitBody.Text
		local active = string.find(text, "Decision:", 1, true) or string.find(text, "Hard timeout:", 1, true)
		local key = if active then string.match(text, "^[^\n]+") else nil
		if key and key ~= previousCommitment then
			gui.MilitaryPanel.CanvasPosition = Vector2.zero
			if not gui:GetAttribute("MapContextEnabled") then gotoPanel("Military") end
		end
		previousCommitment = key
	end)
	territoryValue:GetPropertyChangedSignal("Value"):Connect(function()
		if not gui:GetAttribute("MapContextEnabled") and territoryValue.Value ~= "" and selected ~= "Military" then gotoPanel("Territory") end
	end)
	for _, name in {"VassalageOfferOverlay","DiplomacyOfferOverlay"} do
		local overlay=gui[name]
		overlay:GetPropertyChangedSignal("Visible"):Connect(function()
			nav.RequestNotice.Visible=gui.VassalageOfferOverlay.Visible or gui.DiplomacyOfferOverlay.Visible
		end)
	end
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
