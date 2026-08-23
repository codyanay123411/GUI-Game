--!strict

--[[
	Shared prototype GUI tokens. Visual language only.
	Does not change gameplay, remotes, or primary panel Size/Position.
]]

local PrototypeGuiTheme = {}

PrototypeGuiTheme.Colors = {
	panel = Color3.fromRGB(18, 20, 26),
	well = Color3.fromRGB(24, 27, 36),
	row = Color3.fromRGB(30, 34, 44),
	stroke = Color3.fromRGB(40, 44, 56),
	mapStage = Color3.fromRGB(16, 19, 24),
	overlay = Color3.fromRGB(26, 22, 14),
	toast = Color3.fromRGB(30, 24, 12),
	textPrimary = Color3.fromRGB(232, 234, 240),
	textSecondary = Color3.fromRGB(176, 182, 194),
	textMuted = Color3.fromRGB(140, 146, 158),
	section = Color3.fromRGB(198, 178, 128),
	accentGold = Color3.fromRGB(232, 186, 72),
	action = Color3.fromRGB(46, 120, 72),
	actionText = Color3.fromRGB(235, 240, 235),
	danger = Color3.fromRGB(140, 48, 48),
	dangerText = Color3.fromRGB(245, 232, 232),
	disabled = Color3.fromRGB(42, 46, 54),
	disabledText = Color3.fromRGB(140, 144, 150),
	scrollBar = Color3.fromRGB(72, 78, 92),
}

local C = PrototypeGuiTheme.Colors

local PRIMARY_PANELS = {
	Main = true,
	TitlePanel = true,
	TerritoryInfo = true,
	MapStage = true,
	ResultToast = true,
	VassalageOfferOverlay = true,
}

local function ensureCorner(inst: GuiObject, radius: number)
	local corner = inst:FindFirstChildOfClass("UICorner")
	if not corner then
		corner = Instance.new("UICorner")
		corner.Parent = inst
	end
	corner.CornerRadius = UDim.new(0, radius)
end

local function ensureStroke(inst: GuiObject, thickness: number, color: Color3)
	local stroke = inst:FindFirstChildOfClass("UIStroke")
	if not stroke then
		stroke = Instance.new("UIStroke")
		stroke.Parent = inst
	end
	stroke.Thickness = thickness
	stroke.Color = color
	stroke.Transparency = 0
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.LineJoinMode = Enum.LineJoinMode.Round
end

local function ensurePad(inst: GuiObject, inset: number)
	local pad = inst:FindFirstChildOfClass("UIPadding")
	if not pad then
		pad = Instance.new("UIPadding")
		pad.Parent = inst
	end
	pad.PaddingTop = UDim.new(0, inset)
	pad.PaddingBottom = UDim.new(0, inset)
	pad.PaddingLeft = UDim.new(0, inset)
	pad.PaddingRight = UDim.new(0, inset)
end

local function styleLabel(label: TextLabel, size: number, color: Color3, bold: boolean)
	label.BackgroundTransparency = 1
	label.BorderSizePixel = 0
	label.Font = if bold then Enum.Font.GothamBold else Enum.Font.Gotham
	label.TextSize = size
	label.TextColor3 = color
	label.TextScaled = false
	label.RichText = false
end

function PrototypeGuiTheme.applyPrimaryButton(button: TextButton, enabled: boolean)
	button.BorderSizePixel = 0
	button.AutoButtonColor = enabled
	button.Font = Enum.Font.GothamBold
	button.TextSize = 14
	button.TextScaled = false
	button.TextWrapped = false
	ensureCorner(button, 6)
	if enabled then
		button.BackgroundColor3 = C.action
		button.TextColor3 = C.actionText
	else
		button.BackgroundColor3 = C.disabled
		button.TextColor3 = C.disabledText
	end
end

function PrototypeGuiTheme.applyDangerButton(button: TextButton)
	button.BorderSizePixel = 0
	button.AutoButtonColor = true
	button.Font = Enum.Font.GothamBold
	button.TextSize = 14
	button.TextScaled = false
	button.TextWrapped = false
	button.BackgroundColor3 = C.danger
	button.TextColor3 = C.dangerText
	ensureCorner(button, 6)
end

local function styleScroll(scroll: ScrollingFrame)
	scroll.BackgroundColor3 = C.well
	scroll.BackgroundTransparency = 0
	scroll.BorderSizePixel = 0
	scroll.ScrollBarThickness = 6
	scroll.ScrollBarImageColor3 = C.scrollBar
	scroll.ScrollBarImageTransparency = 0.15
	ensureCorner(scroll, 6)
end

local function styleSectionHeader(label: TextLabel)
	styleLabel(label, 12, C.section, true)
	label.BackgroundTransparency = 1
	label.BackgroundColor3 = C.panel
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextYAlignment = Enum.TextYAlignment.Center
	local trimmed = string.gsub(label.Text, "^%s+", "")
	label.Text = trimmed
end

local function stylePanelTitle(label: TextLabel)
	styleLabel(label, 15, C.textPrimary, true)
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextYAlignment = Enum.TextYAlignment.Center
end

local function styleBody(label: TextLabel)
	styleLabel(label, 14, C.textSecondary, false)
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextYAlignment = Enum.TextYAlignment.Top
	label.TextWrapped = true
end

local function stylePlayerRow(row: Frame)
	row.BackgroundColor3 = C.row
	row.BackgroundTransparency = 0
	row.BorderSizePixel = 0
	ensureCorner(row, 6)
	local nameLabel = row:FindFirstChild("NameLabel")
	if nameLabel and nameLabel:IsA("TextLabel") then
		styleLabel(nameLabel, 13, C.textPrimary, false)
		nameLabel.TextXAlignment = Enum.TextXAlignment.Left
		nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
	end
	local offer = row:FindFirstChild("OfferButton")
	if offer and offer:IsA("TextButton") then
		PrototypeGuiTheme.applyPrimaryButton(offer, true)
		offer.TextSize = 13
	end
end

local function styleOfferCard(card: Frame)
	card.BackgroundColor3 = C.well
	card.BackgroundTransparency = 0
	card.BorderSizePixel = 0
	ensureCorner(card, 6)
	ensureStroke(card, 1, C.stroke)
	ensurePad(card, 10)
	local label = card:FindFirstChild("Label")
	if label and label:IsA("TextLabel") then
		styleBody(label)
		label.TextColor3 = C.textPrimary
		label.TextSize = 14
	end
	local accept = card:FindFirstChild("AcceptButton", true)
	local decline = card:FindFirstChild("DeclineButton", true)
	if accept and accept:IsA("TextButton") then
		PrototypeGuiTheme.applyPrimaryButton(accept, true)
		accept.TextSize = 14
	end
	if decline and decline:IsA("TextButton") then
		PrototypeGuiTheme.applyDangerButton(decline)
		decline.TextSize = 14
	end
end

function PrototypeGuiTheme.ApplyScreen(gui: ScreenGui)
	local main = gui:FindFirstChild("Main")
	if main and main:IsA("GuiObject") then
		main.BackgroundColor3 = C.panel
		main.BorderSizePixel = 0
		ensureCorner(main, 8)
		ensureStroke(main, 1, C.stroke)
		ensurePad(main, 10)
		local title = main:FindFirstChild("Title")
		if title and title:IsA("TextLabel") then
			stylePanelTitle(title)
			title.Size = UDim2.new(1, 0, 0, 20)
		end
		for _, name in { "SelfHeader", "TreeHeader", "PlayersHeader", "IncomingHeader" } do
			local header = main:FindFirstChild(name)
			if header and header:IsA("TextLabel") then
				styleSectionHeader(header)
				header.Size = UDim2.new(1, 0, 0, 20)
			end
		end
		local selfInfo = main:FindFirstChild("SelfInfo")
		if selfInfo and selfInfo:IsA("TextLabel") then
			styleBody(selfInfo)
			selfInfo.BackgroundTransparency = 0
			selfInfo.BackgroundColor3 = C.well
			selfInfo.BorderSizePixel = 0
			ensureCorner(selfInfo, 6)
		end
		local treeScroll = main:FindFirstChild("TreeScroll")
		if treeScroll and treeScroll:IsA("ScrollingFrame") then
			styleScroll(treeScroll)
			local treeView = treeScroll:FindFirstChild("TreeView")
			if treeView and treeView:IsA("TextLabel") then
				styleBody(treeView)
				treeView.TextWrapped = false
				treeView.Font = Enum.Font.Gotham
				treeView.TextColor3 = C.textSecondary
			end
		end
		local playerList = main:FindFirstChild("PlayerList")
		if playerList and playerList:IsA("ScrollingFrame") then
			styleScroll(playerList)
		end
		local incomingList = main:FindFirstChild("IncomingList")
		if incomingList and incomingList:IsA("ScrollingFrame") then
			styleScroll(incomingList)
		end
	end

	local titlePanel = gui:FindFirstChild("TitlePanel")
	if titlePanel and titlePanel:IsA("GuiObject") then
		titlePanel.BackgroundColor3 = C.panel
		titlePanel.BorderSizePixel = 0
		ensureCorner(titlePanel, 8)
		ensureStroke(titlePanel, 1, C.stroke)
		ensurePad(titlePanel, 10)
		local header = titlePanel:FindFirstChild("Header")
		if header and header:IsA("TextLabel") then
			stylePanelTitle(header)
			header.Size = UDim2.new(1, 0, 0, 20)
		end
		local body = titlePanel:FindFirstChild("Body")
		if body and body:IsA("TextLabel") then
			styleBody(body)
		end
		local establish = titlePanel:FindFirstChild("EstablishButton")
		if establish and establish:IsA("TextButton") then
			PrototypeGuiTheme.applyPrimaryButton(establish, establish.Active)
		end
	end

	local territory = gui:FindFirstChild("TerritoryInfo")
	if territory and territory:IsA("GuiObject") then
		territory.BackgroundColor3 = C.panel
		territory.BorderSizePixel = 0
		ensureCorner(territory, 8)
		ensureStroke(territory, 1, C.stroke)
		ensurePad(territory, 10)
		local header = territory:FindFirstChild("Header")
		if header and header:IsA("TextLabel") then
			stylePanelTitle(header)
			header.Size = UDim2.new(1, 0, 0, 20)
		end
		local body = territory:FindFirstChild("Body")
		if body and body:IsA("TextLabel") then
			styleBody(body)
		end
	end

	local mapStage = gui:FindFirstChild("MapStage")
	if mapStage and mapStage:IsA("GuiObject") then
		mapStage.BackgroundColor3 = C.mapStage
		mapStage.BorderSizePixel = 0
		ensureCorner(mapStage, 8)
		ensureStroke(mapStage, 1, C.stroke)
	end

	local overlay = gui:FindFirstChild("VassalageOfferOverlay")
	if overlay and overlay:IsA("GuiObject") then
		overlay.BackgroundColor3 = C.overlay
		overlay.BorderSizePixel = 0
		ensureCorner(overlay, 8)
		ensureStroke(overlay, 2, C.accentGold)
		ensurePad(overlay, 12)
		local header = overlay:FindFirstChild("Header")
		if header and header:IsA("TextLabel") then
			stylePanelTitle(header)
			header.TextColor3 = C.accentGold
			header.Text = "Vassalage offer"
		end
		local body = overlay:FindFirstChild("Body")
		if body and body:IsA("TextLabel") then
			styleBody(body)
			body.TextColor3 = C.textPrimary
		end
		local accept = overlay:FindFirstChild("AcceptButton", true)
		local decline = overlay:FindFirstChild("DeclineButton", true)
		if accept and accept:IsA("TextButton") then
			PrototypeGuiTheme.applyPrimaryButton(accept, true)
			accept.TextSize = 15
		end
		if decline and decline:IsA("TextButton") then
			PrototypeGuiTheme.applyDangerButton(decline)
			decline.TextSize = 15
		end
	end

	local toast = gui:FindFirstChild("ResultToast")
	if toast and toast:IsA("GuiObject") then
		toast.BackgroundColor3 = C.toast
		toast.BorderSizePixel = 0
		ensureCorner(toast, 8)
		ensureStroke(toast, 1, C.accentGold)
		local label = toast:FindFirstChild("Label")
		if label and label:IsA("TextLabel") then
			styleLabel(label, 15, C.accentGold, true)
			label.TextWrapped = true
			label.TextXAlignment = Enum.TextXAlignment.Left
			label.TextYAlignment = Enum.TextYAlignment.Center
		end
	end

	local templates = gui:FindFirstChild("Templates")
	if templates then
		local playerRow = templates:FindFirstChild("PlayerRow")
		if playerRow and playerRow:IsA("Frame") then
			stylePlayerRow(playerRow)
		end
		local offerCard = templates:FindFirstChild("OfferCard")
		if offerCard and offerCard:IsA("Frame") then
			styleOfferCard(offerCard)
		end
		local requestRow = templates:FindFirstChild("RequestRow")
		if requestRow and requestRow:IsA("Frame") then
			styleOfferCard(requestRow)
		end
	end

	for _, inst in gui:GetDescendants() do
		if inst:IsA("GuiObject") and not PRIMARY_PANELS[inst.Name] then
			if inst.BorderSizePixel ~= 0 then
				inst.BorderSizePixel = 0
			end
		end
	end
end

return PrototypeGuiTheme
