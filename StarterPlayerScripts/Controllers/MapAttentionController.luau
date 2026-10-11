--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Theme = require(ReplicatedStorage.Shared.Util.PrototypeGuiTheme)
local Sounds = require(ReplicatedStorage.Shared.Util.GuiSounds)
local Policy = require(ReplicatedStorage.Shared.Util.MapAttentionPolicy)
local View = require(ReplicatedStorage.Shared.Util.PlayerRelevantView)
local Catalog = require(ReplicatedStorage.Shared.Config.MapCatalog)
local State = require(script.Parent.MapContextState)
local Map = require(script.Parent.TerritoryMapController)
local Strategy = require(script.Parent.StrategyPresentationController)
local Communications = require(script.Parent.CommunicationsController)
local Controller = {}
local started = false

function Controller.Start()
	if started then return end
	started = true
	local player = Players.LocalPlayer
	local gui = player.PlayerGui:WaitForChild("HierarchyPrototypeGui") :: ScreenGui
	local stage = gui.MapStage :: Frame
	local layer = gui:WaitForChild("MapAttentionLayer") :: Frame
	local definitions = Catalog.GetDefault().territories
	local events: { [string]: any } = {}
	local markers: { [string]: TextButton } = {}
	local tweens: { [string]: Tween } = {}
	local acknowledged: { [string]: boolean } = {}
	local rendered: { [string]: any } = {}
	local redraw: () -> ()
	local function me(): any
		for _, r in State.hierarchy.rulers or {} do if tonumber(r.userId) == player.UserId then return r end end
		return nil
	end
	local function ruler(userId: number): any
		for _, r in State.hierarchy.rulers or {} do if tonumber(r.userId) == userId then return r end end
		return nil
	end
	local function anchor(event: any): string?
		if event.targetTerritoryId then return event.targetTerritoryId end
		local localRuler = me()
		if not localRuler then return nil end
		return Policy.NearestTerritory(definitions, State.territory.territories, State.hierarchy.rulers,
			event.rulerId, localRuler.rootRulerId or localRuler.rulerId)
	end
	local function add(event: any, quiet: boolean?)
		if acknowledged[event.id] then return end
		if events[event.id] then return end
		events[event.id] = event
		if not quiet then
			-- Offer/result sounds already come from the existing settings notification hooks.
			if event.category == "communication" then Sounds.Play("Notification")
			elseif event.category == "war" then Sounds.Play("Error") end
		end
	end
	local function sync()
		local localRuler = me()
		local localId = localRuler and localRuler.rulerId
		local rootId = localRuler and (localRuler.rootRulerId or localId)
		local keep = {}
		if gui:GetAttribute("MatchEnded") ~= true then
			for _, system in { "diplomacy", "hierarchy" } do
				for _, request in State[system].requests or {} do
					-- These services publish server os.clock deadlines, not synchronized time.
					-- Their authoritative expiry pushes remove requests from this snapshot.
					if request.toRulerId ~= localId then continue end
					local id = system .. ":" .. request.requestId
					keep[id] = true
					add({ id = id, rulerId = request.fromRulerId, priority = 2, category = "diplomacy", system = system, requestId = request.requestId })
				end
			end
			for _, war in View.FilterWarsForLocalRoot(State.warfare.wars, rootId) do
				local id = "war:" .. war.warId
				keep[id] = true
				add({ id = id, targetTerritoryId = war.targetTerritoryId, priority = 3, category = "war", warId = war.warId })
			end
		end
		for id in acknowledged do if not keep[id] then acknowledged[id] = nil end end
		local rulers = {}
		for _, r in State.hierarchy.rulers or {} do rulers[r.rulerId] = true end
		for id, event in events do
			if (event.category == "war" or event.category == "diplomacy") and not keep[id] then events[id] = nil; acknowledged[id] = nil
			elseif event.rulerId and not rulers[event.rulerId] then events[id] = nil
			elseif event.expiresAt and event.expiresAt <= os.clock() then events[id] = nil
			else event.territoryId = anchor(event) end
		end
		redraw()
	end
	local function reposition()
		local hide = gui:GetAttribute("RealmOverviewOpen") or gui:GetAttribute("VictoryOverlayOpen")
		local density = Theme.Presentation.UIScale
		for id, button in markers do
			local position = Map.Project(id)
			local inside = position and position.X > stage.AbsolutePosition.X + 20 and position.Y > stage.AbsolutePosition.Y + 35
				and position.X < stage.AbsolutePosition.X + stage.AbsoluteSize.X - 20
				and position.Y < stage.AbsolutePosition.Y + stage.AbsoluteSize.Y - 10
			button.Visible = inside == true and not hide
			if position then button.Position = UDim2.fromOffset(position.X - 17 * density, position.Y - 42 * density) end
			button.Size = UDim2.fromOffset(34 * density, 30 * density)
		end
	end
	local function activate(event: any)
		local id = event.territoryId
		if not id then return end
		Map.Select(id, if event.category == "result" then "Info" else "silent")
		if event.category == "communication" then
			Strategy.OpenSystem("Communications")
			Communications.OpenContext(event.contextId)
		elseif event.category == "diplomacy" then
			Strategy.OpenSystem("Map")
			local overlay = gui[if event.system == "hierarchy" then "VassalageOfferOverlay" else "DiplomacyOfferOverlay"]
			-- Incoming cards already contain the authorized Accept/Decline handlers.
			overlay.Visible = true
			for _, card in overlay.ExtraList:GetChildren() do
				if card:IsA("Frame") then
					local focused = card:GetAttribute("RequestId") == event.requestId
					card.BackgroundColor3 = if focused then Theme.Colors.action else Theme.Colors.row
					if focused then card.LayoutOrder = -1 end
				end
			end
		elseif event.category == "war" then
			acknowledged[event.id] = true; events[event.id] = nil
			local canCommit = false
			for _, war in State.military.wars or {} do if war.warId == event.warId then canCommit = true end end
			if canCommit then
				gui:SetAttribute("MilitaryContextMode", "Battle")
				Strategy.OpenSystem("Military")
			else Map.Select(id, "Info") end
		else
			events[event.id] = nil
		end
		redraw()
	end
	redraw = function()
		rendered = Policy.Aggregate(events)
		for id, button in markers do
			if not rendered[id] then
				if tweens[id] then tweens[id]:Cancel(); tweens[id] = nil end
				button:Destroy(); markers[id] = nil
			end
		end
		for id, group in rendered do
			local button = markers[id]
			if not button then
				button = Instance.new("TextButton")
				button.Name = "Attention_" .. id; button:SetAttribute("BlocksMapInput", true)
				button.Font = Enum.Font.GothamBold; button.TextSize = 16; button.BorderSizePixel = 0
				button.ZIndex = 71; button.TextColor3 = Theme.Colors.actionText
				local corner = Instance.new("UICorner"); corner.CornerRadius = UDim.new(0, 10); corner.Parent = button
				button.Parent = layer
				markers[id] = button
				button.Activated:Connect(function() local current = rendered[id]; if current then activate(current.event) end end)
				if Theme.Presentation.AnimationsEnabled then
					local scale = Instance.new("UIScale"); scale.Scale = 0.85; scale.Parent = button
					local tween = TweenService:Create(scale, TweenInfo.new(0.22 / Theme.Presentation.AnimationSpeed, Enum.EasingStyle.Back), { Scale = 1 })
					tweens[id] = tween; tween:Play()
				end
			end
			local event = group.event
			button.BackgroundColor3 = if event.priority >= 3 then Theme.Colors.danger else Theme.Colors.action
			button.Text = (if event.category == "communication" then "…" elseif event.category == "result" then "✓" else "!")
				.. (if group.count > 1 then " " .. group.count else "")
		end
		reposition()
	end
	Communications.Received.Event:Connect(function(message)
		local sender = ruler(message.userId)
		if not sender then return end
		local id = "message:" .. message.contextId .. ":" .. sender.rulerId
		local current = events[id]
		if current then current.count = (current.count or 1) + 1; Sounds.Play("Notification")
		else add({ id = id, rulerId = sender.rulerId, priority = 1, category = "communication", contextId = message.contextId, count = 1 }) end
		sync()
	end)
	Communications.Acknowledged.Event:Connect(function(contextId)
		for id, event in events do if event.contextId == contextId then events[id] = nil end end
		redraw()
	end)
	State.Changed.Event:Connect(function(system, kind, data)
		if system == "military" and kind == "BattleResult" and typeof(data) == "table" and data.targetTerritoryId then
			add({ id = "result:" .. tostring(data.warId), targetTerritoryId = data.targetTerritoryId, category = "result", priority = 2, expiresAt = os.clock() + 20 })
		end
		if kind == "State" or kind == "BattleResult" then sync() end
	end)
	Map.CameraChanged.Event:Connect(reposition)
	Theme.PresentationChanged.Event:Connect(function()
		if not Theme.Presentation.AnimationsEnabled then
			for id, tween in tweens do tween:Cancel(); tweens[id] = nil end
			for _, button in markers do local scale = button:FindFirstChildWhichIsA("UIScale"); if scale then scale.Scale = 1 end end
		end
		reposition()
	end)
	local elapsed = 0
	RunService.Heartbeat:Connect(function(dt)
		elapsed += dt
		if elapsed >= 1 then elapsed = 0; sync() end
	end)
	sync()
end
return Controller
