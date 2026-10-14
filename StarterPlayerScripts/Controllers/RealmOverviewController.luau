--!strict
local MatchIntent = require(game:GetService("ReplicatedStorage").Shared.Util.MatchIntent)
-- Public political overview only. Existing services remain authoritative.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local StarterGui = game:GetService("StarterGui")
local View = require(ReplicatedStorage.Shared.Util.RealmOverviewView)
local Theme = require(ReplicatedStorage.Shared.Util.PrototypeGuiTheme)
local Controller = {}
local started = false
local overlay: Frame? = nil

function Controller.SetOpen(open: boolean)
	if overlay then
		overlay.Visible = open
		overlay.Parent:SetAttribute("RealmOverviewOpen", open)
	end
end

function Controller.Start()
	if started then return end
	started = true
	local player = Players.LocalPlayer
	local gui = player:WaitForChild("PlayerGui"):WaitForChild("HierarchyPrototypeGui") :: ScreenGui
	overlay = gui:WaitForChild("RealmOverviewOverlay") :: Frame
	local root = overlay :: Frame
	local panel = root:WaitForChild("Panel") :: Frame
	local list = panel:WaitForChild("List") :: ScrollingFrame
	local detail = panel:WaitForChild("Detail") :: TextLabel
	local template = gui.Templates:WaitForChild("RealmOverviewRow") :: TextButton
	local C = Theme.Colors
	local states: any = {}
	local rows: { [number]: TextButton } = {}
	local excluded: { [number]: boolean } = {}
	local selected: number? = nil
	local sortMode = "Realm"
	local pending = false
	local compact = false
	local refresh: () -> ()
	local function disableDefault()
		local ok = pcall(function() StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, false) end)
		if not ok then
			-- CoreGui may not have initialized yet; bounded startup retry.
			task.spawn(function()
				for _ = 1, 5 do
					task.wait(0.5)
					if pcall(function() StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, false) end) then return end
				end
				warn("[RealmOverview] Could not disable default PlayerList")
			end)
		end
	end
	local function schedule()
		if pending then return end
		pending = true
		task.defer(function() pending = false; refresh() end)
	end
	local function layout()
		local size = gui.AbsoluteSize
		local w, h = math.min(1120, size.X - 32), math.max(200, size.Y - 32)
		compact = w < 720
		panel.Size = UDim2.fromOffset(w, h)
		local footer = if selected then (if compact then 110 else 90) else 30
		list.Position = UDim2.fromOffset(16, if compact then 114 else 134)
		list.Size = UDim2.new(1, -32, 1, -(if compact then 130 else 150) - footer)
		panel.Columns.Visible = not compact
		detail.Size = UDim2.new(1, -32, 0, footer)
		detail.Position = UDim2.new(0, 16, 1, -footer - 12)
		detail.TextSize = if compact then 12 else 13
		for _, row in rows do
			row.Size = UDim2.new(1, -8, 0, (if compact then 94 else 74) * Theme.Presentation.UIScale)
			row.Identity.Position = UDim2.fromOffset(14, 10)
			row.Identity.Size = if compact then UDim2.new(0.60, -18, 0, 24) else UDim2.new(0.25, -18, 0, 24)
			row.Username.Position = UDim2.fromOffset(14, 36)
			row.Username.Size = row.Identity.Size
			row.Politics.Position = if compact then UDim2.new(0.60, 0, 0, 10) else UDim2.new(0.25, 0, 0, 10)
			row.Politics.Size = if compact then UDim2.new(0.40, -14, 0, 46) else UDim2.new(0.18, -8, 0, 52)
			row.Realm.Position = if compact then UDim2.fromOffset(14, 62) else UDim2.new(0.43, 0, 0, 10)
			row.Realm.Size = if compact then UDim2.new(0.60, -20, 0, 24) else UDim2.new(0.27, -12, 0, 52)
			row.Holdings.Position = if compact then UDim2.new(0.60, 0, 0, 62) else UDim2.new(0.70, 0, 0, 10)
			row.Holdings.Size = if compact then UDim2.new(0.40, -14, 0, 24) else UDim2.new(0.12, -8, 0, 52)
			row.Relation.Visible = not compact
		end
	end
	refresh = function()
		layout()
		local connected = {}
		for _, current in Players:GetPlayers() do if not excluded[current.UserId] then table.insert(connected, current) end end
		local projected = View.Build(connected, player.UserId, states, sortMode)
		local alive, chosen = {}, nil
		for order, data in projected do
			local id = data.userId
			alive[id] = true
			local row = rows[id]
			if not row then
				row = template:Clone()
				row.Name = "Player_" .. id
				row.Visible = true
				row.Parent = list
				rows[id] = row
				row.Activated:Connect(function() selected = if selected == id then nil else id; schedule() end)
			end
			row.LayoutOrder = order
			row:SetAttribute("UserId", id)
			row:SetAttribute("PersonalHoldings", data.personal)
			row:SetAttribute("RealmHoldings", data.realm)
			row:SetAttribute("Relationship", data.relation)
			row.BackgroundColor3 = if selected == id then C.row elseif data.localPlayer then C.well else C.panel
			row.Accent.BackgroundColor3 = if data.localPlayer then C.accentGold elseif data.war then C.danger elseif data.allied then C.section else C.stroke
			row.Identity.Text = data.displayName .. (if data.localPlayer then "  ·  YOU" else "")
			row.Identity.TextColor3 = if data.localPlayer then C.accentGold else C.textPrimary
			row.Username.Text = "@" .. data.username .. (if compact then "  ·  " .. data.relation else "")
			row.Politics.Text = data.title .. "\n" .. data.status .. (if data.subjectCount > 0 then " · Liege" else "")
			row.Realm.Text = "Realm: " .. data.root .. (if data.status == "Subject" then "\nLiege: " .. data.liege else "")
			row.Holdings.Text = if compact then tostring(data.personal or "—") .. " / " .. tostring(data.realm or "—") .. " land" else tostring(data.personal or "—") .. " personal\n" .. tostring(data.realm or "—") .. " realm"
			row.Relation.Text = data.relation
			row.Relation.TextColor3 = if data.war then Color3.fromRGB(238, 135, 128) else C.section
			if selected == id then chosen = data end
		end
		for id, row in rows do if not alive[id] then row:Destroy(); rows[id] = nil end end
		if selected and not chosen then selected = nil end
		panel.Subtitle.Text = "Players — " .. #projected .. "   ·   Hold Tab to view"
		if chosen then
			detail.Text = chosen.title .. " " .. chosen.displayName .. "  ·  " .. chosen.status .. "  ·  " .. chosen.relation
				.. "\nRoot: " .. chosen.root .. "  ·  Liege: " .. chosen.liege .. "  ·  Holdings: " .. tostring(chosen.personal or "—") .. " personal / " .. tostring(chosen.realm or "—") .. " realm"
				.. "\nAlliance: " .. (if chosen.allied then "Yes" else "No") .. "  ·  NAP: " .. (if chosen.nap then "Yes" else "No") .. "  ·  War: " .. (if chosen.war then "Yes" else "No")
				.. "  ·  Direct: " .. chosen.direct .. "  ·  " .. chosen.diplomacy
		else detail.Text = "Select a ruler for details.  ·  Holdings: personal / greater realm." end
		layout()
	end
	for _, button in panel.Sorts:GetChildren() do
		if button:IsA("TextButton") then
			button.Activated:Connect(function()
				sortMode = button.Name
				for _, other in panel.Sorts:GetChildren() do if other:IsA("TextButton") then other.BackgroundColor3 = if other == button then C.action else C.well end end
				schedule()
			end)
		end
	end
	panel.Close.Activated:Connect(function() Controller.SetOpen(false) end)
	gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(schedule)
	Theme.PresentationChanged.Event:Connect(layout)
	Players.PlayerAdded:Connect(function(current) excluded[current.UserId] = nil; schedule() end)
	Players.PlayerRemoving:Connect(function(current) excluded[current.UserId] = true; schedule() end)
	player.CharacterAdded:Connect(function() disableDefault(); Controller.SetOpen(false) end)
	local remotes = ReplicatedStorage:WaitForChild("Remotes")
	for _, system in { "Hierarchy", "Territory", "Diplomacy", "Warfare", "Communications" } do
		local push = remotes:WaitForChild(system .. "ServerEvent") :: RemoteEvent
		MatchIntent.ConnectPush(push, function(kind: any, payload: any)
			if kind ~= "State" then return end
			local ok, decoded = pcall(function() return if typeof(payload) == "string" then HttpService:JSONDecode(payload) else payload end)
			if ok and typeof(decoded) == "table" then states[system] = decoded; schedule() end
		end)
		local intent = remotes:WaitForChild(system .. "ClientEvent") :: RemoteEvent
		MatchIntent.Send(intent, "Ready")
	end
	disableDefault()
	Controller.SetOpen(false)
	schedule()
end

return Controller
