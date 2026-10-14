--!strict
-- All game UI consumes project tokens; only the Kohl bridge knows Kohl's dashboard.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Config = require(ReplicatedStorage.Shared.Config.GameSettingsConfig)
local Theme = require(ReplicatedStorage.Shared.Util.PrototypeGuiTheme)
local Sounds = require(ReplicatedStorage.Shared.Util.GuiSounds)
local Controller = {}
Controller.Changed = Instance.new("BindableEvent")
local started = false
local revision = -1
local canConfigure, canView = false, false
local requestEvent: RemoteEvent
local records = setmetatable({}, { __mode = "k" })
local tweens = setmetatable({}, { __mode = "k" })
local pending = {}
local resets = {}
local pumping = false

function Controller.GetSnapshot(): any
	return { values = table.clone(Theme.Presentation), revision = revision, canConfigure = canConfigure, canView = canView }
end

local function pump()
	if pumping then return end
	pumping = true
	task.spawn(function()
		while next(pending) or next(resets) do
			task.wait(0.12)
			if not canConfigure then table.clear(pending); table.clear(resets); break end
			local category = table.remove(resets, 1)
			if category then
				requestEvent:FireServer({ action = "Reset", key = category })
				continue
			end
			for _, definition in Config.Definitions do
				local queued = pending[definition.key]
				if queued and os.clock() >= queued.readyAt then
					pending[definition.key] = nil
					requestEvent:FireServer({ action = "Set", key = definition.key, value = queued.value })
					break
				end
			end
		end
		pumping = false
	end)
end

function Controller.Request(key: string, value: any)
	if not canConfigure or not Config.Validate(key, value) then return end
	pending[key] = { value = value, readyAt = os.clock() + 0.2 }
	pump()
end

function Controller.Reset(category: string)
	if not canConfigure or (category ~= "Game UI" and category ~= "Game Audio") then return end
	for _, definition in Config.Definitions do
		if definition.category == category then pending[definition.key] = nil end
	end
	table.insert(resets, category)
	pump()
end

local function properties(item: Instance): { string }
	if item:IsA("TextLabel") or item:IsA("TextButton") or item:IsA("TextBox") then return { "FontFace", "TextSize" } end
	if item:IsA("UICorner") then return { "CornerRadius" } end
	if item:IsA("UIPadding") then return { "PaddingLeft", "PaddingRight", "PaddingTop", "PaddingBottom" } end
	if item:IsA("UIListLayout") then return { "Padding" } end
	return {}
end

function Controller.Start()
	if started then return end
	started = true
	Sounds.Start()
	local player = Players.LocalPlayer
	local gui = player:WaitForChild("PlayerGui"):WaitForChild("HierarchyPrototypeGui") :: ScreenGui
	local background = gui:FindFirstChild("StrategyBackground")
	if not background then
		local frame = Instance.new("Frame")
		frame.Name = "StrategyBackground"
		frame.BackgroundColor3 = Theme.Colors.mapStage
		frame.BorderSizePixel = 0
		frame.Size = UDim2.fromScale(1, 1)
		frame.ZIndex = 0
		frame.Active = false
		frame.Parent = gui
		background = frame
	end
	local function apply(item: Instance)
		local record = records[item]
		if not record or not item.Parent then return end
		record.applying = true
		Theme.ApplyPresentation(item, record.base)
		for _, key in record.keys do record.applied[key] = item[key] end
		record.applying = false
	end
	local function watch(item: Instance)
		if records[item] then return end
		local templates = gui:FindFirstChild("Templates")
		if templates and item:IsDescendantOf(templates) then return end
		Theme.StyleControl(item)
		local keys = properties(item)
		local base = {}
		for _, key in keys do base[key] = item[key] end
		if item:IsA("GuiObject") then base.BackgroundTransparency = item.BackgroundTransparency end
		if not next(base) then return end
		local record = { base = base, applied = {}, keys = keys }
		records[item] = record
		if item:IsA("TextBox") then
			item:GetPropertyChangedSignal("TextEditable"):Connect(function() Theme.applyInputState(item) end)
		end
		for _, key in keys do
			item:GetPropertyChangedSignal(key):Connect(function()
				if record.applying or item[key] == record.applied[key] then return end
				record.base[key] = item[key]
				apply(item)
			end)
		end
		if item:IsA("GuiButton") then
			local function transition(hover: boolean)
				if tweens[item] then tweens[item]:Cancel(); tweens[item] = nil end
				local target = Theme.PanelTransparency(base.BackgroundTransparency + (if hover and item.Active then 0.1 else 0))
				if not Theme.Presentation.AnimationsEnabled then item.BackgroundTransparency = target; return end
				local tween = TweenService:Create(item, TweenInfo.new(0.12 / Theme.Presentation.AnimationSpeed), { BackgroundTransparency = target })
				tweens[item] = tween
				tween.Completed:Once(function() if tweens[item] == tween then tweens[item] = nil end end)
				tween:Play()
			end
			item.MouseEnter:Connect(function() if item.Active then Sounds.Play("Hover"); transition(true) end end)
			item.MouseLeave:Connect(function() transition(false) end)
			item.Activated:Connect(function()
				if item.Active then Sounds.Play(if item.Name == "AcceptButton" then "Confirm" elseif item.Name:find("Close") or item.Name == "Continue" then "Close" else "Click") end
			end)
		end
		if item:IsA("GuiObject") and item.Parent == gui and item.Name:find("Panel") then
			item:GetPropertyChangedSignal("Visible"):Connect(function() Sounds.Play(if item.Visible then "Open" else "Close") end)
		end
		apply(item)
	end
	for _, item in gui:GetDescendants() do watch(item) end
	gui.DescendantAdded:Connect(function(item) task.defer(watch, item) end)
	local remotes = ReplicatedStorage:WaitForChild("Remotes")
	requestEvent = remotes:WaitForChild("GameSettingsRequestEvent") :: RemoteEvent
	local push = remotes:WaitForChild("GameSettingsStateEvent") :: RemoteEvent
	push.OnClientEvent:Connect(function(snapshot)
		if typeof(snapshot) ~= "table" or typeof(snapshot.values) ~= "table" or typeof(snapshot.revision) ~= "number" or snapshot.revision < revision then return end
		for _, definition in Config.Definitions do if not Config.Validate(definition.key, snapshot.values[definition.key]) then return end end
		canConfigure, canView = snapshot.canConfigure == true, snapshot.canView == true
		revision = snapshot.revision
		Theme.SetPresentation(snapshot.values)
		for item, tween in tweens do tween:Cancel(); tweens[item] = nil end
		for item in records do apply(item) end
		if background and background:IsA("GuiObject") then background.BackgroundTransparency = 1 - Theme.Presentation.BackgroundStrength end
		gui:SetAttribute("GamePresentationRevision", revision)
		Controller.Changed:Fire(snapshot.error)
	end)
	local feedback = remotes:WaitForChild("AdminFeedbackEvent") :: RemoteEvent
	feedback.OnClientEvent:Connect(function(payload)
		if typeof(payload) == "table" then Sounds.Play(if payload.ok == false then "Error" elseif payload.operation == "Help" or string.sub(tostring(payload.operation), 1, 7) == "Inspect" then "Notification" else "Confirm") end
	end)
	gui.ResultToast:GetPropertyChangedSignal("Visible"):Connect(function()
		if gui.ResultToast.Visible then Sounds.Play("Notification") end
	end)
	gui.PresentationState.SelectedTerritoryId:GetPropertyChangedSignal("Value"):Connect(function() Sounds.Play("Select") end)
	for _, name in { "VassalageOfferOverlay", "DiplomacyOfferOverlay", "VictoryOverlay" } do
		local overlay = gui:FindFirstChild(name)
		if overlay and overlay:IsA("GuiObject") then overlay:GetPropertyChangedSignal("Visible"):Connect(function() if overlay.Visible then Sounds.Play("Notification") end end) end
	end
	requestEvent:FireServer({ action = "Ready" })
end

return Controller
