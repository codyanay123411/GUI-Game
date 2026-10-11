--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Theme = require(ReplicatedStorage.Shared.Util.PrototypeGuiTheme)
local Radial = {}
local panel: Frame
local heading: TextLabel
local buttons: { TextButton } = {}
local anchor = Vector2.zero
local gui: ScreenGui
local actions = {}
local shortRelations = {
	["Your personal holding"] = "Yours",
	["Your direct subject"] = "Subject",
	["Your liege"] = "Liege",
	["Your greater realm"] = "Your realm",
	["Unrelated ruler"] = "Unrelated",
	["Non-Aggression Pact"] = "NAP",
	["Current enemy"] = "Enemy",
}

function Radial.Layout()
	if not panel or not panel.Visible then return end
	local size = gui.AbsoluteSize
	local scale = Theme.Presentation.UIScale
	local compact = size.X < 760 or size.Y < 520
	local width = if compact then math.min(240 * scale, size.X - 24) else 320 * scale
	local height = if compact then (52 + #buttons * 39) * scale else 320 * scale
	height = math.min(height, size.Y - 92)
	local minX, minY = 12, 76
	panel.Size = UDim2.fromOffset(width, height)
	local corner = panel:FindFirstChildWhichIsA("UICorner")
	if corner then corner.CornerRadius = if compact then UDim.new(0, 12) else UDim.new(0.5, 0) end
	panel.Position = UDim2.fromOffset(math.clamp(anchor.X - width / 2, minX, math.max(minX, size.X - width - 12)),
		math.clamp(anchor.Y - height / 2, minY, math.max(minY, size.Y - height - 12)))
	heading.Position = if compact then UDim2.fromOffset(8, 4) else UDim2.fromOffset(width / 2 - 42 * scale, height / 2 - 30 * scale)
	heading.Size = if compact then UDim2.fromOffset(width - 16, 48 * scale) else UDim2.fromOffset(84 * scale, 60 * scale)
	for index, button in buttons do
		if compact then
			button.Size = UDim2.fromOffset(width - 16, math.max(25, (height - 52 * scale) / math.max(1, #buttons) - 4))
			button.Position = UDim2.fromOffset(8, 52 * scale + (index - 1) * (height - 52 * scale) / math.max(1, #buttons))
		else
			local angle = -math.pi / 2 + (index - 1) * math.pi * 2 / math.max(1, #buttons)
			button.Size = UDim2.fromOffset(104 * scale, 44 * scale)
			button.Position = UDim2.fromOffset(width / 2 + math.cos(angle) * 101 * scale - 52 * scale,
				height / 2 + math.sin(angle) * 108 * scale - 22 * scale)
		end
	end
end

function Radial.Start(screen: ScreenGui, activate: (string) -> ())
	gui = screen
	panel = gui:WaitForChild("ContextRadialPanel") :: Frame
	heading = panel:WaitForChild("Heading") :: TextLabel
	gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(Radial.Layout)
	Theme.PresentationChanged.Event:Connect(Radial.Layout)
	Radial.Activate = activate
end
function Radial.Hide()
	if panel then panel.Visible = false end
end
function Radial.Show(context: any, position: Vector2)
	anchor = position
	for _, button in buttons do button:Destroy() end
	buttons = {}
	actions = context.actions
	local relation = shortRelations[context.relation] or context.relation
	heading.Text = context.definition.displayName .. "\n" .. relation
	for _, action in actions do
		local button = Instance.new("TextButton")
		button.Name = action.id
		button.Text = action.label
		button.TextWrapped = true
		button.Font = Enum.Font.Gotham
		button.TextSize = 13
		button.BorderSizePixel = 0
		button.ZIndex = 82
		Theme.applyPrimaryButton(button, true)
		local corner = Instance.new("UICorner"); corner.CornerRadius = UDim.new(0, 12); corner.Parent = button
		button.Parent = panel
		button.Activated:Connect(function() Radial.Activate(action.id) end)
		table.insert(buttons, button)
	end
	panel.Visible = true
	Radial.Layout()
end
return Radial
