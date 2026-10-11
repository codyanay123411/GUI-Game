--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TextService = game:GetService("TextService")
local Theme = require(ReplicatedStorage.Shared.Util.PrototypeGuiTheme)
local Resolver = require(ReplicatedStorage.Shared.Util.ContextActionResolver)
local Catalog = require(ReplicatedStorage.Shared.Config.MapCatalog)
local State = require(script.Parent.MapContextState)
local Map = require(script.Parent.TerritoryMapController)
local Radial = require(script.Parent.ContextRadialController)
local Strategy = require(script.Parent.StrategyPresentationController)
local Communications = require(script.Parent.CommunicationsController)
local Military = require(script.Parent.MilitaryController)
local Controller = {}
local started = false

function Controller.Start()
	if started then return end
	started = true
	local player = Players.LocalPlayer
	local gui = player.PlayerGui:WaitForChild("HierarchyPrototypeGui") :: ScreenGui
	local panel = gui:WaitForChild("ContextWorkflowPanel") :: ScrollingFrame
	local header = panel:WaitForChild("Heading") :: TextLabel
	local body = panel:WaitForChild("Body") :: TextLabel
	local amount = panel:WaitForChild("CommitAmount") :: TextBox
	local close = panel:WaitForChild("CancelButton") :: TextButton
	local list = panel:WaitForChild("Actions") :: Frame
	local mapDef = Catalog.GetDefault()
	local remotes = ReplicatedStorage.Remotes
	local selected: string? = nil
	local point = Vector2.zero
	local mode: string? = nil
	local pending: any = nil
	local pendingToken = 0
	local context: any = nil
	local redraw: () -> ()
	local function priority(): boolean
		return gui.VassalageOfferOverlay.Visible or gui.DiplomacyOfferOverlay.Visible
			or gui:GetAttribute("RealmOverviewOpen") == true or gui:GetAttribute("VictoryOverlayOpen") == true
	end
	local function resolve(): any
		return if selected then Resolver.Resolve(State, mapDef.territories, selected, player.UserId,
			gui:GetAttribute("MatchEnded") == true, workspace:GetServerTimeNow()) else nil
	end
	local function hide()
		Radial.Hide(); panel.Visible = false; mode = nil
	end
	local function layout()
		local size = gui.AbsoluteSize
		local width = math.min(370 * Theme.Presentation.UIScale, size.X - 24)
		panel.Position = UDim2.fromOffset(math.max(12, size.X - width - 12), 76)
		panel.Size = UDim2.fromOffset(width, math.max(120, size.Y - 108))
		local textHeight = TextService:GetTextSize(body.Text, body.TextSize, body.Font, Vector2.new(math.max(1, width - 24), 100000)).Y
		body.Size = UDim2.new(1, -24, 0, textHeight + 12)
		local y = 56 + body.Size.Y.Offset
		amount.Position = UDim2.fromOffset(12, y)
		amount.Size = UDim2.new(1, -24, 0, 36)
		list.Position = UDim2.fromOffset(12, y + (if amount.Visible then 46 else 0))
		local count = 0
		for _, child in list:GetChildren() do if child:IsA("TextButton") then count += 1 end end
		list.Size = UDim2.new(1, -24, 0, count * 44)
		close.Position = UDim2.fromOffset(12, list.Position.Y.Offset + count * 44 + 8)
		close.Size = UDim2.new(1, -24, 0, 36)
		panel.CanvasSize = UDim2.fromOffset(0, close.Position.Y.Offset + 52)
	end
	local function action(label: string, callback: () -> (), enabled: boolean?)
		local count = 0
		for _, child in list:GetChildren() do if child:IsA("TextButton") then count += 1 end end
		local button = Instance.new("TextButton")
		button.Name = "Action" .. tostring(count)
		button.Text = label; button.Font = Enum.Font.Gotham; button.TextSize = 14
		button.TextWrapped = true; button.BorderSizePixel = 0; button.ZIndex = 87
		button.Position = UDim2.fromOffset(0, count * 44); button.Size = UDim2.new(1, 0, 0, 38)
		button.Active = enabled ~= false
		Theme.applyPrimaryButton(button, button.Active)
		button.Parent = list
		button.Activated:Connect(function() if button.Active then callback() end end)
	end
	local function fullSystem(name: string)
		hide(); Strategy.OpenSystem(name)
	end
	local function showRadial()
		mode = nil; panel.Visible = false
		context = resolve()
		if context and not priority() then
			Strategy.OpenSystem("Map")
			Radial.Show(context, point)
		else Radial.Hide() end
	end
	function Controller.OpenWorkflow(kind: string)
		context = resolve()
		if not context or priority() then return end
		if kind == "Battle" then
			local canCommit = false
			for _, war in State.military.wars or {} do if war.targetTerritoryId == selected then canCommit = true end end
			fullSystem(if canCommit then "Military" else "Territory"); return
		end
		if kind == "Military" then fullSystem("Military"); return end
		Strategy.OpenSystem("Map")
		mode = kind
		redraw()
	end
	redraw = function()
		context = resolve()
		if not context or priority() then hide(); return end
		if not mode then showRadial(); return end
		Radial.Hide()
		for _, child in list:GetChildren() do if child:IsA("TextButton") then child:Destroy() end end
		panel.Visible = true; amount.Visible = mode == "War"
		header.Text = context.definition.displayName .. " · " .. mode
		close.Text = "Cancel · Back to map actions"
		local holder = context.holder
		local root = context.root
		local ownerName = if holder then holder.titleName .. " " .. holder.displayName else "Unclaimed"
		local lines = { context.relation, "Owner: " .. ownerName,
			"Root realm: " .. (if root then root.displayName else "None") }
		local militia = context.province and context.province.neutralDefense
		local militiaText = if typeof(militia) == "table" then tostring(militia.current) else "Awaiting state"
		if mode == "War" then
			table.insert(lines, "Your available troops: " .. context.available)
			table.insert(lines, if holder then "Enemy reserves are private." else "Public militia: " .. militiaText)
			table.insert(lines, context.warReason or "Border and treaty checks allow a declaration.")
			table.insert(lines, "Confirm declares war and submits your initial amount. Review and LOCK in Military. Existing commitment deadlines still apply.")
			if pending then table.insert(lines, "Awaiting server response…") end
			action("Confirm declaration & prepare troops", function()
				local latest = resolve()
				local n = tonumber(amount.Text)
				if not latest or not latest.canDeclare or pending then redraw(); return end
				if not n or n ~= n or n % 1 ~= 0 or n < 0 or n > latest.available then
					body.Text = table.concat(lines, "\n\n") .. "\n\nEnter a whole amount from 0 to " .. latest.available
					layout(); return
				end
				pendingToken += 1
				local token = pendingToken
				pending = { territoryId = selected, amount = n }
				(remotes.WarfareClientEvent :: RemoteEvent):FireServer("DeclareWar", selected)
				redraw()
				task.delay(8, function()
					if pending and token == pendingToken then pending = nil; redraw() end
				end)
			end, context.canDeclare and pending == nil)
		elseif mode == "Diplomacy" then
			for _, item in context.diplomacy do
				action(item.label, function()
					local latest = resolve()
					if not latest then return end
					for _, valid in latest.diplomacy do
						if valid.action == item.action and valid.target == item.target and valid.system == item.system then
							(remotes[valid.system .. "ClientEvent"] :: RemoteEvent):FireServer(valid.action, valid.target)
							return
						end
					end
					redraw()
				end)
			end
			action("Full diplomacy view", function() fullSystem("Diplomacy") end)
		elseif mode == "Message" then
			for _, channel in context.communication do
				action(channel.label, function()
					fullSystem("Communications")
					if channel.userId then Communications.OpenDirect(channel.userId)
					else Communications.OpenContext(channel.contextId) end
				end)
			end
		else
			if holder then
				local personal, realm = 0, 0
				for _, t in State.territory.territories do
					if t.ownerRulerId == holder.rulerId then personal += 1 end
					local r = context.rulers[t.ownerRulerId]
					if r and (r.rootRulerId or r.rulerId) == (holder.rootRulerId or holder.rulerId) then realm += 1 end
				end
				local liege = context.rulers[holder.liegeId]
				table.insert(lines, "Direct liege: " .. (if liege then liege.displayName else "None"))
				table.insert(lines, "Personal holdings: " .. personal .. " · Greater realm: " .. realm)
			else table.insert(lines, "Public militia: " .. militiaText) end
			table.insert(lines, if context.war then "Active conflict here. Military has your realm's details." else context.warReason or "No active conflict here.")
			action(if mode == "Realm" then "Full realm view" else "Full territory view", function() fullSystem(if mode == "Realm" then "Realm" else "Territory") end)
		end
		body.Text = table.concat(lines, "\n\n")
		layout()
	end
	Radial.Start(gui, Controller.OpenWorkflow)
	Map.SelectionChanged.Event:Connect(function(id, position, workflow)
		selected = id; point = position or point
		amount.Text = "0"
		if workflow == "silent" then hide()
		elseif workflow then Controller.OpenWorkflow(workflow)
		else showRadial() end
	end)
	close.Activated:Connect(showRadial)
	gui:GetAttributeChangedSignal("SelectedSystem"):Connect(function()
		if gui:GetAttribute("SelectedSystem") ~= "Map" then hide() end
	end)
	for _, name in { "VassalageOfferOverlay", "DiplomacyOfferOverlay" } do
		gui[name]:GetPropertyChangedSignal("Visible"):Connect(function() if priority() then hide() end end)
	end
	for _, name in { "RealmOverviewOpen", "VictoryOverlayOpen", "MatchEnded" } do
		gui:GetAttributeChangedSignal(name):Connect(function() if priority() then hide() elseif panel.Visible or gui.ContextRadialPanel.Visible then redraw() end end)
	end
	UserInputService.InputBegan:Connect(function(input, processed)
		if input.KeyCode == Enum.KeyCode.Escape and not processed then hide() end
	end)
	gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(layout)
	body:GetPropertyChangedSignal("TextSize"):Connect(layout)
	body:GetPropertyChangedSignal("FontFace"):Connect(layout)
	Theme.PresentationChanged.Event:Connect(layout)
	State.Changed.Event:Connect(function(system, kind, data)
		if pending and system == "military" and kind == "State" then
			for _, war in data.wars or {} do
				if war.targetTerritoryId == pending.territoryId and war.role == "Attacker" and war.phase == "commit" and not war.locked then
					local initial = pending.amount
					local targetId = pending.territoryId
					pending = nil
					-- Restore the reviewed target if the player selected elsewhere while awaiting a reply.
					Map.Select(targetId, "silent")
					Military.PrepareCommit(war.warId, initial)
					fullSystem("Military")
					break
				end
			end
		elseif pending and system == "warfare" and kind == "Notice" then pending = nil end
		if panel.Visible or gui.ContextRadialPanel.Visible then redraw() end
	end)
	gui:SetAttribute("MapContextEnabled", true)
	State.Start()
end
return Controller
