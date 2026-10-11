--!strict
-- Presentation only. Logical dismissal and input release happen before the fade.
local TweenService = game:GetService("TweenService")
local Theme = require(script.Parent.PrototypeGuiTheme)
local Transitions = {}
local records: { [CanvasGroup]: any } = {}

local function stop(group: CanvasGroup): any
	local record = records[group]
	if not record then
		local scale = Instance.new("UIScale")
		scale.Name = "ContextTransitionScale"
		scale.Parent = group
		record = { scale = scale, tweens = {}, token = 0 }
		records[group] = record
	end
	record.token += 1
	for _, tween in record.tweens do tween:Cancel() end
	table.clear(record.tweens)
	return record
end

function Transitions.IsOpen(group: CanvasGroup): boolean
	return group:GetAttribute("ContextOpen") == true
end

function Transitions.Show(group: CanvasGroup, drawer: boolean?)
	if Transitions.IsOpen(group) then return end
	local record = stop(group)
	group:SetAttribute("ContextOpen", true)
	local blocksBackground = group:GetAttribute("MapInputThroughBackground") ~= true
	group:SetAttribute("BlocksMapInput", blocksBackground)
	group.Interactable = true
	group.Active = blocksBackground
	group.Visible = true
	group.GroupTransparency = 0
	record.scale.Scale = 1
	if not Theme.Presentation.AnimationsEnabled then return end
	local duration = 0.16 / Theme.Presentation.AnimationSpeed
	group.GroupTransparency = 1
	record.scale.Scale = if drawer then 0.98 else 0.94
	local fade = TweenService:Create(group, TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { GroupTransparency = 0 })
	local scale = TweenService:Create(record.scale, TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Scale = 1 })
	table.insert(record.tweens, fade); table.insert(record.tweens, scale)
	if drawer then
		local position = group.Position
		group.Position = position + UDim2.fromOffset(10, 0)
		local slide = TweenService:Create(group, TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Position = position })
		table.insert(record.tweens, slide)
	end
	for _, tween in record.tweens do tween:Play() end
end

function Transitions.Hide(group: CanvasGroup, immediate: boolean?)
	if not Transitions.IsOpen(group) and not immediate then return end
	local record = stop(group)
	group:SetAttribute("ContextOpen", false)
	group:SetAttribute("BlocksMapInput", false)
	group.Interactable = false
	group.Active = false
	if immediate or not Theme.Presentation.AnimationsEnabled then
		group.Visible = false; group.GroupTransparency = 0; record.scale.Scale = 1
		return
	end
	local token = record.token
	local duration = 0.12 / Theme.Presentation.AnimationSpeed
	local fade = TweenService:Create(group, TweenInfo.new(duration), { GroupTransparency = 1 })
	local scale = TweenService:Create(record.scale, TweenInfo.new(duration), { Scale = 0.94 })
	table.insert(record.tweens, fade); table.insert(record.tweens, scale)
	fade.Completed:Once(function()
		if record.token == token then group.Visible = false; group.GroupTransparency = 0; record.scale.Scale = 1 end
	end)
	fade:Play(); scale:Play()
end

Theme.PresentationChanged.Event:Connect(function()
	for group in records do
		local open = Transitions.IsOpen(group)
		local record = stop(group)
		group.Visible = open
		group.GroupTransparency = 0
		record.scale.Scale = 1
	end
end)
return Transitions
