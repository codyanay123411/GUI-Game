--!strict
-- Addon for installed Kohl v0.17.0. No vendor Source edits or Kohl savedSettings writes.
-- Only this adapter knows dashboard.Settings handles; the game owns all settings/state.
return function(K)
	if not K.IsClient or K._gamePresentationSettingsMounted then return end
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local Config = require(ReplicatedStorage.Shared.Config.GameSettingsConfig)
	local player = game.Players.LocalPlayer
	local Controller = require(player:WaitForChild("PlayerScripts"):WaitForChild("Controllers"):WaitForChild("GameSettingsController"))
	local UI = K.UI
	local deadline = os.clock() + 30
	repeat task.wait() until (K.client and K.client.dashboard and K.client.dashboard.Settings) or os.clock() > deadline
	local settings = K.client and K.client.dashboard and K.client.dashboard.Settings
	if not settings or not settings._scroller or not settings._input then warn("[GamePresentation] Unsupported Kohl Settings handles; game defaults remain active."); return end
	-- Kohl may invoke an addon concurrently from multiple copied addon containers.
	-- The dashboard instance, rather than an interface copy, owns mount admission.
	if settings._scroller:GetAttribute("GamePresentationMounted") then return end
	settings._scroller:SetAttribute("GamePresentationMounted", true)
	K._gamePresentationSettingsMounted = true
	local writable, viewable = UI.state(false), UI.state(false)
	local status = UI.state("Connecting to game presentation settings…")
	local states, categories, rows = {}, {}, {}
	for _, definition in Config.Definitions do states[definition.key] = UI.state(definition.default) end
	local function set(key, value)
		if Controller.GetSnapshot().values[key] ~= value then Controller.Request(key, value) end
	end
	local function display(definition, value)
		if definition.kind == "toggle" then return if value then "On" else "Off" end
		if definition.percent then return string.format("%.0f%%", value * 100) end
		if typeof(value) == "number" then return string.format("%.2g", value) end
		return tostring(value)
	end
	for order, category in { "Game UI", "Game Audio" } do
		local list = UI.new "List" {
			Name = category,
			Parent = settings._scroller,
			Label = string.upper(category),
			Collapsible = true,
			Padding = UI.Theme.PaddingDouble,
			LayoutOrder = 2 + order,
			Visible = viewable,
		}
		categories[category] = list
		UI.new "ListItem" { Parent = list, Text = status, LayoutOrder = 0 }
		for index, definition in Config.Definitions do
			if definition.category ~= category then continue end
			local key = definition.key
			local value = states[key]
			local row = UI.new "ListItem" { Parent = list, Text = definition.label, LayoutOrder = index, Tooltip = "Server-wide game presentation. Only the game creator can edit. Runtime only." }
			table.insert(rows, { row = row, definition = definition })
			UI.new "TextLabel" {
				Parent = row,
				BackgroundTransparency = 1,
				AutomaticSize = Enum.AutomaticSize.XY,
				FontFace = UI.Theme.Font,
				TextSize = UI.Theme.FontSize,
				TextColor3 = UI.Theme.PrimaryText,
				Visible = function() return not writable() end,
				Text = function() return display(definition, value()) .. "  ·  Read only" end,
			}
			if definition.kind == "font" then
				UI.new "Select" { Parent = row, Choices = Config.FontOptions, Value = value, Visible = writable,
					[UI.Hook] = { Value = function(v) set(key, v) end } }
			elseif definition.kind == "toggle" then
				UI.new "Switch" { Parent = row, Value = value, Visible = writable,
					[UI.Hook] = { Value = function(v) set(key, v) end } }
			else
				local multiplier = if definition.percent then 100 else 1
				UI.new "Input" {
					Parent = row,
					Visible = writable,
					NumberOnly = true,
					NumberRange = NumberRange.new(definition.min * multiplier, definition.max * multiplier),
					Size = UDim2.fromOffset(58, 24),
					Value = function() return tostring(math.round(value() * multiplier * 100) / 100) end,
					[UI.Hook] = { Value = function(v) local number = tonumber(v); if number then set(key, number / multiplier) end end },
				}
				UI.new "Slider" {
					Parent = row,
					Visible = writable,
					Snap = math.round((definition.max - definition.min) / definition.step) + 1,
					Value = function() return 1 + (value() - definition.min) / definition.step end,
					UI.new "UIFlexItem" { FlexMode = Enum.UIFlexMode.Fill },
					[UI.Hook] = { Value = function(v) set(key, math.clamp(definition.min + (v - 1) * definition.step, definition.min, definition.max)) end },
				}
			end
		end
		local label = UI.state("Reset " .. category .. " Defaults")
		local armed = false
		UI.new "Button" {
			Parent = list, LayoutOrder = 100, Label = label, Visible = writable,
			Activated = function()
				if not Controller.GetSnapshot().canConfigure then return end
				if armed then
					armed = false
					label("Reset " .. category .. " Defaults")
					Controller.Reset(category)
				else
					armed = true
					label("Confirm reset " .. category .. " for everyone")
					task.delay(5, function() armed = false; label("Reset " .. category .. " Defaults") end)
				end
			end,
		}
	end
	local function filter()
		local text = string.lower(settings._input._input.Text)
		local visible = Controller.GetSnapshot().canView
		for category, list in categories do
			local categoryFound = text == "" or string.find(string.lower(category), text, 1, true) ~= nil
			local anyFound = categoryFound
			for _, item in rows do
				if item.definition.category ~= category then continue end
				local found = categoryFound or string.find(string.lower(item.definition.label), text, 1, true) ~= nil
				item.row._instance.Visible = found
				anyFound = anyFound or found
			end
			list._instance.Visible = visible and anyFound
			if text ~= "" and anyFound then list.Collapsed(false) end
		end
	end
	local function refresh(errorMessage)
		local snapshot = Controller.GetSnapshot()
		writable(snapshot.canConfigure)
		viewable(snapshot.canView)
		status(errorMessage or (if snapshot.canConfigure then "Creator changes apply live to everyone · Runtime only" else "Read only · Creator-controlled game settings · Runtime only"))
		for key, value in snapshot.values do states[key](value) end
		filter()
	end
	Controller.Changed.Event:Connect(refresh)
	settings._input._input:GetPropertyChangedSignal("Text"):Connect(filter)
	refresh()
	print("[GamePresentation] Mounted native GAME UI / GAME AUDIO settings.")
end
