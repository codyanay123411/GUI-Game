--!strict
-- One input surface with five labeled stops, shared by review and active commitment.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Input = game:GetService("UserInputService")
local Theme = require(ReplicatedStorage.Shared.Util.PrototypeGuiTheme)
local Policy = require(ReplicatedStorage.Shared.Util.CommitmentPolicy)
local Bar = {}

function Bar.Create(parent: Instance, name: string, zIndex: number, changed: (number, boolean) -> (), stops: { number }?)
	local choices = stops or Policy.Stops
	assert(#choices == 5, "Fixed-stop bar requires five choices")
	local root = Instance.new("Frame")
	root.Name = name
	root.BackgroundTransparency = 1
	root.BorderSizePixel = 0
	root.Active = true
	root.ZIndex = zIndex
	root.Size = UDim2.new(1, -24, 0, 96)
	root:SetAttribute("BlocksMapInput", true)
	local caption = Instance.new("TextLabel")
	caption.Name = "Preview"
	caption.BackgroundTransparency = 1
	caption.Size = UDim2.new(1, 0, 0, 28)
	caption.TextWrapped = true
	caption.ZIndex = zIndex + 1
	Theme.applyText(caption, "Caption")
	caption.Parent = root
	local track = Instance.new("Frame")
	track.Name = "Track"
	track.BorderSizePixel = 0
	track.BackgroundColor3 = Theme.Colors.stroke
	track.Position = UDim2.new(0, 22, 0, 49)
	track.Size = UDim2.new(1, -44, 0, 4)
	track.ZIndex = zIndex + 1
	track.Parent = root
	local labels, marks = {}, {}
	for index, percent in choices do
		local label = Instance.new("TextLabel")
		label.Name = "Stop" .. percent
		label.Text = percent .. "%"
		label.BackgroundTransparency = 1
		label.AnchorPoint = Vector2.new(0.5, 0)
		label.Position = UDim2.new((index - 1) / 4, 0, 0, 17)
		label.Size = UDim2.fromOffset(44, 26)
		label.ZIndex = zIndex + 2
		Theme.applyText(label, "Caption")
		label.TextXAlignment = Enum.TextXAlignment.Center
		label.Parent = track
		local mark = Instance.new("Frame")
		mark.Name = "Mark" .. percent
		mark.AnchorPoint = Vector2.new(0.5, 0.5)
		mark.Position = UDim2.new((index - 1) / 4, 0, 0.5, 0)
		mark.Size = UDim2.fromOffset(8, 12)
		mark.BorderSizePixel = 0
		mark.ZIndex = zIndex + 2
		mark.Parent = track
		labels[index], marks[index] = label, mark
	end
	local selector = Instance.new("Frame")
	selector.Name = "Selector"
	selector.AnchorPoint = Vector2.new(0.5, 0.5)
	selector.Size = UDim2.fromOffset(16, 22)
	selector.BorderSizePixel = 0
	selector.ZIndex = zIndex + 3
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 4)
	corner.Parent = selector
	selector.Parent = track
	root.Parent = parent
	local enabled, dragging = false, false
	local percent: number? = nil
	local api = { Root = root }
	local function visible(): boolean
		local current: Instance? = root
		while current do
			if current:IsA("GuiObject") and not current.Visible then return false end
			current = current.Parent
		end
		return true
	end
	local function paint()
		selector.Visible = percent ~= nil
		selector.BackgroundColor3 = if enabled then Theme.Colors.accentGold else Theme.Colors.disabled
		for index, stop in choices do
			marks[index].BackgroundColor3 = if percent == stop and enabled then Theme.Colors.accentGold else Theme.Colors.stroke
			labels[index].TextColor3 = if not enabled then Theme.Colors.disabledText elseif percent == stop then Theme.Colors.accentGold else Theme.Colors.textPrimary
			if percent == stop then selector.Position = UDim2.new((index - 1) / 4, 0, 0.5, 0) end
		end
		root:SetAttribute("SelectedPercent", percent)
		root:SetAttribute("EditingEnabled", enabled)
	end
	function api.Set(value: number?, text: string, canEdit: boolean)
		percent = value
		caption.Text = text
		enabled = canEdit
		if not enabled or not visible() then dragging = false end
		paint()
	end
	local function selectAt(x: number, final: boolean)
		if not enabled or not visible() then return end
		local position = math.clamp((x - track.AbsolutePosition.X) / math.max(1, track.AbsoluteSize.X), 0, 1)
		local stop = choices[math.clamp(math.floor(position * 4 + 0.5) + 1, 1, 5)]
		if stop ~= percent or final then
			percent = stop
			paint()
			changed(stop, final)
		end
	end
	root.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 and enabled and visible() then
			dragging = true
			selectAt(input.Position.X, false)
		end
	end)
	Input.InputChanged:Connect(function(input)
		if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then selectAt(input.Position.X, false) end
	end)
	Input.InputEnded:Connect(function(input)
		if dragging and input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = false
			selectAt(Input:GetMouseLocation().X, true)
		end
	end)
	Theme.PresentationChanged.Event:Connect(paint)
	paint()
	return api
end
return Bar
