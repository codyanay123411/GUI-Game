--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local TextService = game:GetService("TextService")
local Theme = require(ReplicatedStorage.Shared.Util.PrototypeGuiTheme)
local State = require(script.Parent.MapContextState)
local Domination = require(ReplicatedStorage.Shared.Util.Domination)
local Catalog = require(ReplicatedStorage.Shared.Config.MapCatalog)
local View = require(ReplicatedStorage.Shared.Util.PlayerRelevantView)
local Controller = {}
local started = false

function Controller.Start()
	if started then return end
	started = true
	local player = Players.LocalPlayer
	local gui = player:WaitForChild("PlayerGui"):WaitForChild("HierarchyPrototypeGui") :: ScreenGui
	local overlay = gui:WaitForChild("VictoryOverlay") :: Frame
	local panel = overlay:WaitForChild("Panel") :: Frame
	local state: any = nil
	local shown = false
	local requestPending = false
	local replayRevision = -1
	local requestFloorRevision = -1
	local remotes = ReplicatedStorage:WaitForChild("Remotes")
	local intent = remotes:WaitForChild("VictoryClientEvent") :: RemoteEvent
	local inspectButton = panel.Continue :: TextButton
	inspectButton.Text = "Inspect final map"
	local replay = Instance.new("TextButton")
	replay.Name = "PlayAgainButton"
	replay.Text = "Play Again"
	replay.ZIndex = inspectButton.ZIndex
	Theme.applyPrimaryButton(replay, false)
	replay.Parent = panel
	local content = Instance.new("ScrollingFrame")
	content.Name = "ResultContent"
	content.BackgroundTransparency = 1
	content.BorderSizePixel = 0
	content.Active = true
	content.ZIndex = panel.Body.ZIndex
	content.AutomaticCanvasSize = Enum.AutomaticSize.None
	content.CanvasSize = UDim2.fromOffset(0,0)
	content:SetAttribute("BlocksMapInput", true)
	Theme.applyScroll(content)
	content.Parent = panel
	local body = panel.Body :: TextLabel
	body.Parent = content
	local feedback = Instance.new("TextLabel")
	feedback.Name = "ReplayFeedback"
	feedback.BackgroundTransparency = 1
	feedback.TextWrapped = true
	feedback.TextXAlignment = Enum.TextXAlignment.Left
	feedback.TextYAlignment = Enum.TextYAlignment.Top
	feedback.ZIndex = body.ZIndex
	feedback.Text = "Request a fresh reserved match, starting with you alone. Other players stay here."
	Theme.applyText(feedback, "Caption")
	feedback.Parent = content
	local function replayEnabled(): boolean return state ~= nil and state.ended == true and not requestPending end
	local function styleReplay()
		replay.Active = replayEnabled()
		Theme.applyPrimaryButton(replay, replay.Active)
		replay.Text = if requestPending then "Preparing…" else "Play Again"
	end
	local function progress()
		local root = View.LocalRootRulerId(State.hierarchy.rulers, player.UserId)
		local count = nil
		if root and state then
			-- Public replicated ownership/hierarchy; same conquerable denominator as authority.
			local totals = Domination.Evaluate(Catalog.GetDefault(), State.hierarchy.rulers, State.territory.territories)
			count = totals.counts[root] or 0
		end
		gui.StrategyTopbar:SetAttribute("DominationControlled", count)
	end
	State.Changed.Event:Connect(function(system, kind)
		if kind == "State" and (system == "hierarchy" or system == "territory") then progress() end
	end)
	local function layout()
		local w, h = math.min(600, gui.AbsoluteSize.X - 32), math.min(430, gui.AbsoluteSize.Y - 32)
		panel.Size = UDim2.fromOffset(w,h)
		local padding = panel:FindFirstChildOfClass("UIPadding")
		local left = if padding then padding.PaddingLeft.Offset else 0
		local right = if padding then padding.PaddingRight.Offset else 0
		local top = if padding then padding.PaddingTop.Offset else 0
		local bottom = if padding then padding.PaddingBottom.Offset else 0
		local innerW, innerH = w-left-right, h-top-bottom
		local width = math.max(1, innerW-48)
		local function height(label: TextLabel, minimum: number, lineWidth: number): number
			return math.max(minimum, TextService:GetTextSize(label.Text,label.TextSize,label.Font,Vector2.new(lineWidth,100000)).Y+12)
		end
		local headingH = height(panel.Heading,38,width)
		local winnerH = height(panel.Winner,40,width)
		panel.Heading.Position = UDim2.fromOffset(24,16); panel.Heading.Size = UDim2.fromOffset(width,headingH)
		panel.Winner.Position = UDim2.fromOffset(24,20+headingH); panel.Winner.Size = UDim2.fromOffset(width,winnerH)
		local y = 28+headingH+winnerH
		local buttonH = math.max(44,math.ceil(replay.TextSize*2.6))
		local buttonY = innerH-16-buttonH
		content.Position = UDim2.fromOffset(24,y); content.Size = UDim2.fromOffset(width,math.max(32,buttonY-y-12))
		local textWidth = math.max(1,width-content.ScrollBarThickness-8)
		body.Position = UDim2.fromOffset(0,0); body.Size = UDim2.fromOffset(textWidth,height(body,80,textWidth))
		feedback.Position = UDim2.fromOffset(0,body.Size.Y.Offset+12)
		feedback.Size = UDim2.fromOffset(textWidth,height(feedback,40,textWidth))
		content.CanvasSize = UDim2.fromOffset(0,feedback.Position.Y.Offset+feedback.Size.Y.Offset+8)
		local buttonW = math.max(1,(width-12)/2)
		inspectButton.Position = UDim2.fromOffset(24,buttonY); inspectButton.Size = UDim2.fromOffset(buttonW,buttonH)
		replay.Position = UDim2.fromOffset(36+buttonW,buttonY); replay.Size = UDim2.fromOffset(buttonW,buttonH)
	end
	local function isCompetitive(button: TextButton): boolean
		if button.Name == "BackButton" then return false end
		if button.Name == "DeclareWar" then return true end
		for _, name in { "Main", "TitlePanel", "MilitaryWorkflowPanel", "VassalageOfferOverlay", "DiplomacyOfferOverlay" } do
			local container = gui:FindFirstChild(name)
			if container and button:IsDescendantOf(container) then return true end
		end
		return false
	end
	local function watch(item: Instance)
		if not item:IsA("TextButton") or not isCompetitive(item) then return end
		local function disable()
			if gui:GetAttribute("MatchEnded") == true and item.Active then
				item.Active = false
				Theme.applyPrimaryButton(item, false)
			end
		end
		item:GetPropertyChangedSignal("Active"):Connect(disable)
		gui:GetAttributeChangedSignal("MatchEnded"):Connect(disable)
		disable()
	end
	for _, item in gui:GetDescendants() do watch(item) end
	gui.DescendantAdded:Connect(watch)
	gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(layout)
	overlay:GetPropertyChangedSignal("Visible"):Connect(function() gui:SetAttribute("VictoryOverlayOpen", overlay.Visible) end)
	inspectButton.Activated:Connect(function() overlay.Visible = false end)
	replay.Activated:Connect(function()
		if not replayEnabled() then return end
		requestPending = true
		requestFloorRevision = replayRevision
		feedback.Text = "Requesting a new match. You can keep inspecting while the server responds."
		styleReplay(); layout()
		intent:FireServer("PlayAgain")
		-- Resynchronize only; never unlock or start a second transfer on a guessed timeout.
		task.delay(12,function() if requestPending then intent:FireServer("Ready") end end)
	end)
	gui.StrategyNavigation.MatchResult.Activated:Connect(function() if state and state.ended then overlay.Visible = true end end)
	local push = remotes:WaitForChild("VictoryServerEvent") :: RemoteEvent
	push.OnClientEvent:Connect(function(kind, payload)
		if kind == "ReplayStatus" then
			local ok, status = pcall(function() return HttpService:JSONDecode(payload) end)
			if not ok or typeof(status) ~= "table" or typeof(status.revision) ~= "number" or status.revision < replayRevision then return end
			if requestPending and status.pending ~= true and status.revision <= requestFloorRevision then return end
			replayRevision = status.revision
			requestPending = status.pending == true
			feedback.Text = (status.description or "") .. "\n\n" .. (status.message or "")
			styleReplay(); layout()
			return
		end
		if kind ~= "State" then return end
		local ok, decoded = pcall(function() return HttpService:JSONDecode(payload) end)
		if not ok or typeof(decoded) ~= "table" then return end
		state = decoded
		local ended = state.ended == true
		gui:SetAttribute("MatchEnded", ended)
		gui.MapHint.Text = if ended then "MATCH ENDED  ·  Inspect the map  ·  Players  ·  Match result" else string.format("DOMINATION: %d / %d territories required  ·  Expand your greater realm", state.required, state.total)
		gui.StrategyNavigation.MatchResult.Visible = ended
		gui.StrategyTopbar:SetAttribute("DominationRequired", state.required)
		progress()
		styleReplay()
		if not ended then return end
		local member = false
		for _, ruler in state.members or {} do if ruler.userId == player.UserId then member = true end end
		panel.Heading.Text = if state.winnerUserId == player.UserId then "VICTORY" elseif member then "REALM VICTORY" else "DEFEAT"
		panel.Winner.Text = state.winnerTitle .. " " .. state.winnerName
		body.Text = state.realmName .. "\n\n" .. string.format("%d / %d territories  ·  %.1f%% controlled", state.controlled, state.total, state.controlPercent * 100)
			.. "\nDomination achieved  ·  " .. string.format("%.0f%% required", state.threshold * 100)
			.. "\n\nThe match has ended. Competitive actions are frozen.\nInspect the map, view Players or continue communicating."
		if not shown then overlay.Visible = true; shown = true end
		layout()
	end)
	Theme.PresentationChanged.Event:Connect(function() styleReplay(); layout() end)
	for _, label in { panel.Heading, panel.Winner, body, feedback } do
		for _, property in { "Text", "TextSize", "FontFace" } do label:GetPropertyChangedSignal(property):Connect(layout) end
	end
	for _, button in { inspectButton, replay } do button:GetPropertyChangedSignal("TextSize"):Connect(layout) end
	intent:FireServer("Ready")
	layout()
end

return Controller
