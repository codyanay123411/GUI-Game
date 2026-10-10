--!strict

--[[
	Shared prototype GUI tokens. Visual language only.
	Does not change gameplay or remotes. Layout is owned by StrategyPresentationController.
]]

local PrototypeGuiTheme = {}

PrototypeGuiTheme.Colors = {
	panel = Color3.fromRGB(19, 28, 37),
	well = Color3.fromRGB(25, 36, 47),
	row = Color3.fromRGB(33, 47, 59),
	stroke = Color3.fromRGB(66, 77, 86),
	mapStage = Color3.fromRGB(15, 24, 32),
	overlay = Color3.fromRGB(26, 22, 14),
	toast = Color3.fromRGB(30, 24, 12),
	textPrimary = Color3.fromRGB(235, 231, 219),
	textSecondary = Color3.fromRGB(181, 194, 201),
	textMuted = Color3.fromRGB(140, 146, 158),
	section = Color3.fromRGB(199, 177, 125),
	accentGold = Color3.fromRGB(232, 186, 72),
	action = Color3.fromRGB(141, 110, 54),
	actionText = Color3.fromRGB(255, 246, 223),
	danger = Color3.fromRGB(140, 48, 48),
	dangerText = Color3.fromRGB(245, 232, 232),
	disabled = Color3.fromRGB(42, 46, 54),
	disabledText = Color3.fromRGB(140, 144, 150),
	scrollBar = Color3.fromRGB(72, 78, 92),
	toastError = Color3.fromRGB(36, 18, 18),
}

local C = PrototypeGuiTheme.Colors

local PRIMARY_PANELS = {
	Main = true,
	TitlePanel = true,
	TerritoryInfo = true,
	MapStage = true,
	ResultToast = true,
	VassalageOfferOverlay = true,
	DiplomacyPanel = true,
	DiplomacyOfferOverlay = true,
	AdminInspectPanel = true,
	EconomyPanel = true,
	MilitaryPanel = true,
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

function PrototypeGuiTheme.applyToast(toast: GuiObject, kind: string)
	local stroke = toast:FindFirstChildOfClass("UIStroke")
	local label = toast:FindFirstChild("Label")
	if kind == "error" then
		toast.BackgroundColor3 = C.toastError
		if stroke then
			stroke.Color = C.danger
		end
		if label and label:IsA("TextLabel") then
			label.TextColor3 = C.dangerText
		end
	else
		toast.BackgroundColor3 = C.toast
		if stroke then
			stroke.Color = C.accentGold
		end
		if label and label:IsA("TextLabel") then
			label.TextColor3 = C.accentGold
		end
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
			body.Size = UDim2.new(1, 0, 0, 40)
		end
		local warStatus = territory:FindFirstChild("WarStatus")
		if warStatus and warStatus:IsA("TextLabel") then
			styleBody(warStatus)
			warStatus.TextSize = 12
			warStatus.Size = UDim2.new(1, 0, 0, 44)
			warStatus.ClipsDescendants = true
			warStatus.TextTruncate = Enum.TextTruncate.AtEnd
			warStatus.TextYAlignment = Enum.TextYAlignment.Top
		end
		local declareWar = territory:FindFirstChild("DeclareWar")
		if declareWar and declareWar:IsA("TextButton") then
			PrototypeGuiTheme.applyPrimaryButton(declareWar, true)
			declareWar.TextSize = 12
			declareWar.TextWrapped = true
		end
	end

	local economy = gui:FindFirstChild("EconomyPanel")
	if economy and economy:IsA("GuiObject") then
		economy.BackgroundColor3 = C.panel
		economy.BorderSizePixel = 0
		ensureCorner(economy, 8)
		ensureStroke(economy, 1, C.stroke)
		ensurePad(economy, 10)
		local header = economy:FindFirstChild("Header")
		if header and header:IsA("TextLabel") then
			stylePanelTitle(header)
			header.Size = UDim2.new(1, 0, 0, 20)
			header.Text = "Economy"
		end
		local body = economy:FindFirstChild("Body")
		if body and body:IsA("TextLabel") then
			styleBody(body)
			body.TextYAlignment = Enum.TextYAlignment.Top
		end
	end

	local military = gui:FindFirstChild("MilitaryPanel")
	if military and military:IsA("GuiObject") then
		military.BackgroundColor3 = C.panel
		military.BorderSizePixel = 0
		ensureCorner(military, 8)
		ensureStroke(military, 1, C.stroke)
		ensurePad(military, 10)
		local header = military:FindFirstChild("Header")
		if header and header:IsA("TextLabel") then
			stylePanelTitle(header)
			header.Size = UDim2.new(1, 0, 0, 20)
			header.Text = "Military"
		end
		for _, name in { "Stats", "CostLabel", "CommitBody" } do
			local label = military:FindFirstChild(name)
			if label and label:IsA("TextLabel") then
				styleBody(label)
				label.TextYAlignment = Enum.TextYAlignment.Top
			end
		end
		local recruitButton = military:FindFirstChild("RecruitButton")
		if recruitButton and recruitButton:IsA("TextButton") then
			PrototypeGuiTheme.applyPrimaryButton(recruitButton, true)
			recruitButton.TextSize = 12
		end
		local maxRecruit = military:FindFirstChild("MaxRecruitButton")
		if maxRecruit and maxRecruit:IsA("TextButton") then
			PrototypeGuiTheme.applyPrimaryButton(maxRecruit, true)
			maxRecruit.Text = "M"
			maxRecruit.TextSize = 12
		end
		local lockButton = military:FindFirstChild("LockButton")
		if lockButton and lockButton:IsA("TextButton") then
			PrototypeGuiTheme.applyPrimaryButton(lockButton, true)
			lockButton.TextSize = 12
		end
	end

	local mapStage = gui:FindFirstChild("MapStage")
	if mapStage and mapStage:IsA("GuiObject") then
		mapStage.BackgroundColor3 = C.mapStage
		mapStage.BorderSizePixel = 0
		ensureCorner(mapStage, 8)
		ensureStroke(mapStage, 1, C.stroke)
	end

	local diplomacy = gui:FindFirstChild("DiplomacyPanel")
	if diplomacy and diplomacy:IsA("GuiObject") then
		diplomacy.BackgroundColor3 = C.panel
		diplomacy.BorderSizePixel = 0
		ensureCorner(diplomacy, 8)
		ensureStroke(diplomacy, 1, C.stroke)
		ensurePad(diplomacy, 10)
		local header = diplomacy:FindFirstChild("Header")
		if header and header:IsA("TextLabel") then
			stylePanelTitle(header)
			header.Size = UDim2.new(1, 0, 0, 20)
		end
		local status = diplomacy:FindFirstChild("Status")
		if status and status:IsA("TextLabel") then
			styleBody(status)
			status.TextSize = 13
		end
		local dipList = diplomacy:FindFirstChild("List")
		if dipList and dipList:IsA("ScrollingFrame") then
			styleScroll(dipList)
		end
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

	local dipOverlay = gui:FindFirstChild("DiplomacyOfferOverlay")
	if dipOverlay and dipOverlay:IsA("GuiObject") then
		dipOverlay.BackgroundColor3 = C.overlay
		dipOverlay.BorderSizePixel = 0
		ensureCorner(dipOverlay, 8)
		ensureStroke(dipOverlay, 2, C.accentGold)
		ensurePad(dipOverlay, 12)
		local header = dipOverlay:FindFirstChild("Header")
		if header and header:IsA("TextLabel") then
			stylePanelTitle(header)
			header.TextColor3 = C.accentGold
			header.Text = "Diplomatic offer"
		end
		local accept = dipOverlay:FindFirstChild("AcceptButton", true)
		local decline = dipOverlay:FindFirstChild("DeclineButton", true)
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

	local inspect = gui:FindFirstChild("AdminInspectPanel")
	if inspect and inspect:IsA("GuiObject") then
		inspect.BackgroundColor3 = C.panel
		inspect.BorderSizePixel = 0
		ensureCorner(inspect, 8)
		ensureStroke(inspect, 1, C.stroke)
		ensurePad(inspect, 10)
		local header = inspect:FindFirstChild("Header")
		if header and header:IsA("TextLabel") then
			stylePanelTitle(header)
			header.TextColor3 = C.section
			header.Size = UDim2.new(1, -80, 0, 22)
		end
		local scroll = inspect:FindFirstChild("BodyScroll")
		if scroll and scroll:IsA("ScrollingFrame") then
			styleScroll(scroll)
		end
		local body = inspect:FindFirstChild("Body", true)
		if body and body:IsA("TextLabel") then
			styleBody(body)
			body.Font = Enum.Font.Gotham
			body.TextSize = 13
			body.TextColor3 = C.textSecondary
		end
		local closeBtn = inspect:FindFirstChild("CloseButton")
		if closeBtn and closeBtn:IsA("TextButton") then
			PrototypeGuiTheme.applyDangerButton(closeBtn)
			closeBtn.TextSize = 12
			closeBtn.Text = "Close"
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
		local dipRow = templates:FindFirstChild("DiplomacyRow")
		if dipRow and dipRow:IsA("Frame") then
			dipRow.BackgroundColor3 = C.row
			dipRow.BorderSizePixel = 0
			ensureCorner(dipRow, 6)
			local nameLabel = dipRow:FindFirstChild("NameLabel")
			if nameLabel and nameLabel:IsA("TextLabel") then
				styleLabel(nameLabel, 13, C.textPrimary, true)
			end
			local relLabel = dipRow:FindFirstChild("RelationLabel")
			if relLabel and relLabel:IsA("TextLabel") then
				styleLabel(relLabel, 12, C.textSecondary, false)
			end
			local buttonRow = dipRow:FindFirstChild("ButtonRow")
			if buttonRow then
				for _, child in buttonRow:GetChildren() do
					if child:IsA("TextButton") then
						PrototypeGuiTheme.applyPrimaryButton(child, true)
						child.TextSize = 11
					end
				end
			end
		end
		local dipCard = templates:FindFirstChild("DiplomacyOfferCard")
		if dipCard and dipCard:IsA("Frame") then
			styleOfferCard(dipCard)
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
