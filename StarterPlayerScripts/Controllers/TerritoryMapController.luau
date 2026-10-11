--!strict

--[[
	Prototype map renderer and input. Displays server ownership; never mutates it.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local GuiService = game:GetService("GuiService")

local Theme = require(ReplicatedStorage.Shared.Util.PrototypeGuiTheme)
local MapCatalog = require(ReplicatedStorage.Shared.Config.MapCatalog)
local RealmColors = require(ReplicatedStorage.Shared.Config.RealmColors)
local MapGeometry = require(ReplicatedStorage.Shared.Util.MapGeometry)
local MapTriangles = require(ReplicatedStorage.Shared.Util.MapTriangles)

local player = Players.LocalPlayer
local TerritoryMapController = {}
TerritoryMapController.SelectionChanged = Instance.new("BindableEvent")
TerritoryMapController.CameraChanged = Instance.new("BindableEvent")

local MIN_ZOOM = 0.7
local MAX_ZOOM = 2.8
local FOV = 25
local THICK = 6
local SELECT_COLOR = Color3.fromRGB(255, 214, 64)

local started = false

local function decodeState(payload: any): any?
	if typeof(payload) == "string" then
		local ok, decoded = pcall(function()
			return HttpService:JSONDecode(payload)
		end)
		if ok and typeof(decoded) == "table" then
			return decoded
		end
		return nil
	elseif typeof(payload) == "table" then
		return payload
	end
	return nil
end

local function scaleFromCentroid(polygon: { { x: number, y: number } }, towardCenter: number)
	local cx, cy = MapGeometry.Centroid(polygon)
	local out = {}
	for _, p in polygon do
		table.insert(out, {
			x = p.x + (cx - p.x) * towardCenter,
			y = p.y + (cy - p.y) * towardCenter,
		})
	end
	return out
end

function TerritoryMapController.Start()
	if started or _G.__TerritoryMapV01Started == true then
		return
	end
	started = true
	_G.__TerritoryMapV01Started = true

	local gui = player:WaitForChild("PlayerGui"):WaitForChild("HierarchyPrototypeGui", 12)
	if not (gui and gui:IsA("ScreenGui")) then
		warn("[Territory] HierarchyPrototypeGui missing; map idle.")
		started = false
		_G.__TerritoryMapV01Started = nil
		return
	end

	local mapStage = gui:WaitForChild("MapStage") :: Frame
	local viewport = mapStage:FindFirstChild("MapView")
	if not (viewport and viewport:IsA("ViewportFrame")) then
		if viewport then
			viewport:Destroy()
		end
		viewport = Instance.new("ViewportFrame")
		viewport.Name = "MapView"
		viewport.BackgroundColor3 = Color3.fromRGB(28, 34, 42)
		viewport.BorderSizePixel = 0
		viewport.Size = UDim2.fromScale(1, 1)
		viewport.ZIndex = 1
		viewport.Active = false
		viewport.Ambient = Color3.fromRGB(210, 210, 210)
		viewport.LightColor = Color3.fromRGB(255, 255, 255)
		viewport.LightDirection = Vector3.new(0, -1, 0)
		viewport.Parent = mapStage
	end
	viewport.Active = false
	local selectedValue = gui:WaitForChild("PresentationState"):WaitForChild("SelectedTerritoryId") :: StringValue

	local remotes = ReplicatedStorage:WaitForChild("Remotes")
	local territoryIntent = remotes:WaitForChild("TerritoryClientEvent") :: RemoteEvent
	local territoryPush = remotes:WaitForChild("TerritoryServerEvent") :: RemoteEvent
	local hierarchyPush = remotes:WaitForChild("HierarchyServerEvent") :: RemoteEvent

	local mapDef = MapCatalog.GetDefault()
	local polygons = {}
	local byId = {}
	for _, t in mapDef.territories do
		byId[t.id] = t
		table.insert(polygons, t.polygon)
	end
	local minX, minY, maxX, maxY = MapGeometry.MapBounds(polygons)
	local spanX = math.max(maxX - minX, 1)
	local spanY = math.max(maxY - minY, 1)
	local midX = (minX + maxX) * 0.5
	local midY = (minY + maxY) * 0.5

	local ownership: { [string]: string } = {}
	local colorIndex: { [string]: number } = {}
	local hierarchyById: { [string]: any } = {}
	local selectedId: string? = nil

	local zoom = 1
	local lookX = midX
	local lookZ = midY
	local dragging = false
	local dragMoved = false
	local dragStart: Vector2? = nil
	local lookStart = Vector2.zero

	local world = Instance.new("WorldModel")
	world.Parent = viewport
	local folder = Instance.new("Folder")
	folder.Name = "Territories"
	folder.Parent = world
	local fillParts: { [string]: { WedgePart } } = {}
	local rimParts: { [string]: { WedgePart } } = {}
	local selectParts: { [string]: { WedgePart } } = {}

	for _, t in mapDef.territories do
		local selectFolder = Instance.new("Folder")
		selectFolder.Name = t.id .. "_select"
		selectFolder.Parent = folder
		local rim = Instance.new("Folder")
		rim.Name = t.id .. "_rim"
		rim.Parent = folder
		local fill = Instance.new("Folder")
		fill.Name = t.id .. "_fill"
		fill.Parent = folder
		-- Gold outline above fill/holder so selection does not replace political colors.
		selectParts[t.id] = MapTriangles.DrawRing(
			selectFolder,
			t.polygon,
			SELECT_COLOR,
			t.id .. "select",
			THICK,
			10,
			THICK * 0.75,
			true
		)
		for _, p in selectParts[t.id] do
			p.Transparency = 1
			p.Material = Enum.Material.Neon
			p.Color = SELECT_COLOR
		end
		rimParts[t.id] = MapTriangles.DrawQuad(rim, t.polygon, RealmColors.Unclaimed, t.id .. "rim", THICK, THICK * 0.2)
		fillParts[t.id] = MapTriangles.DrawQuad(
			fill,
			scaleFromCentroid(t.polygon, 0.18),
			RealmColors.Unclaimed,
			t.id .. "fill",
			THICK,
			THICK * 0.55
		)
	end

	local camera = Instance.new("Camera")
	camera.FieldOfView = FOV
	camera.Parent = viewport
	viewport.CurrentCamera = camera
	-- Noninteractive province names use the same projection as map picking.
	local provinceLabels = {}
	for _, t in mapDef.territories do
		local label = Instance.new("TextLabel")
		label.Name = "ProvinceName_" .. t.id
		label.BackgroundTransparency = 1
		label.AnchorPoint = Vector2.new(0.5, 0.5)
		label.Text = t.displayName
		label.Font = Enum.Font.GothamMedium
		label.TextSize = 12
		label.TextColor3 = Color3.fromRGB(25, 34, 42)
		label.TextStrokeColor3 = Color3.fromRGB(235, 231, 219)
		label.TextStrokeTransparency = 0.65
		label.Active = false
		label.ZIndex = 2
		label.Parent = mapStage
		provinceLabels[t.id] = label
	end

	local function rulerOf(rulerId: string?): any?
		if not rulerId or rulerId == "" then
			return nil
		end
		return hierarchyById[rulerId]
	end

	local function ownerColor(ownerId: string): Color3
		local idx = colorIndex[ownerId]
		if typeof(idx) == "number" then
			return RealmColors.ByIndex(idx)
		end
		return RealmColors.ByIndex(1)
	end

	local function cameraHeight(): number
		local size = mapStage.AbsoluteSize
		local aspect = if size.Y > 0 then size.X / size.Y else 1
		local half = math.max(spanX / aspect, spanY) * 0.55 / zoom
		return half / math.tan(math.rad(FOV * 0.5))
	end

	local function applyCamera()
		local h = cameraHeight()
		local size = mapStage.AbsoluteSize
		local aspect = if size.Y > 0 then size.X / size.Y else 1
		local halfZ = h * math.tan(math.rad(FOV * 0.5))
		local halfX = halfZ * aspect
		local pad = 20
		local loX = minX - pad + halfX
		local hiX = maxX + pad - halfX
		if loX <= hiX then
			lookX = math.clamp(lookX, loX, hiX)
		else
			lookX = midX
		end
		local loZ = minY - pad + halfZ
		local hiZ = maxY + pad - halfZ
		if loZ <= hiZ then
			lookZ = math.clamp(lookZ, loZ, hiZ)
		else
			lookZ = midY
		end
		camera.CFrame = CFrame.lookAt(Vector3.new(lookX, h, lookZ), Vector3.new(lookX, 0, lookZ), Vector3.new(0, 0, -1))
		for _, t in mapDef.territories do
			local cx, cy = MapGeometry.Centroid(t.polygon)
			local label = provinceLabels[t.id]
			local px = (0.5 + (cx - lookX) / (2 * halfX)) * size.X
			local py = (0.5 + (cy - lookZ) / (2 * halfZ)) * size.Y
			local x1, _, x2 = MapGeometry.PolygonBounds(t.polygon)
			local width = (x2 - x1) / (2 * halfX) * size.X * 0.85
			label.Position = UDim2.fromOffset(px, py)
			label.Size = UDim2.fromOffset(width, 24)
			label.TextSize = if width < 90 then 10 else 12
			label.Visible = Theme.Presentation.ProvinceLabelsEnabled and width >= 54 and px > 0 and py > 0 and px < size.X and py < size.Y
		end
		TerritoryMapController.CameraChanged:Fire()
	end
	function TerritoryMapController.Project(territoryId: string): Vector2?
		local label = provinceLabels[territoryId]
		if not label then return nil end
		return mapStage.AbsolutePosition + Vector2.new(label.Position.X.Offset, label.Position.Y.Offset)
	end

	local function screenToMap(screen: Vector2): (number?, number?)
		local abs = viewport.AbsolutePosition
		local size = viewport.AbsoluteSize
		if size.X < 1 or size.Y < 1 then
			return nil, nil
		end
		local u = (screen.X - abs.X) / size.X
		local v = (screen.Y - abs.Y) / size.Y
		if u < 0 or v < 0 or u > 1 or v > 1 then
			return nil, nil
		end
		local h = cameraHeight()
		local aspect = size.X / size.Y
		local halfZ = h * math.tan(math.rad(FOV * 0.5))
		local halfX = halfZ * aspect
		local mx = lookX + (u - 0.5) * 2 * halfX
		local my = lookZ + (v - 0.5) * 2 * halfZ
		return mx, my
	end

	local function hitTerritory(mx: number, my: number): string?
		for _, t in mapDef.territories do
			if MapGeometry.PointInPolygon(mx, my, t.polygon) then
				return t.id
			end
		end
		return nil
	end

	local function colorize()
		for _, t in mapDef.territories do
			local ownerId = ownership[t.id]
			local fill = RealmColors.Unclaimed
			local rim = Color3.fromRGB(40, 44, 50)
			if ownerId and ownerId ~= "" then
				local owner = rulerOf(ownerId)
				local rootId = if owner and typeof(owner.rootRulerId) == "string" and owner.rootRulerId ~= "" then owner.rootRulerId else ownerId
				fill = ownerColor(rootId)
				rim = ownerColor(ownerId)
			end
			for _, p in fillParts[t.id] do
				p.Color = fill
				p.Material = Enum.Material.SmoothPlastic
			end
			for _, p in rimParts[t.id] do
				p.Color = rim
			end
			local selected = selectedId == t.id
			for _, p in selectParts[t.id] do
				p.Color = SELECT_COLOR
				p.Material = Enum.Material.Neon
				p.Transparency = if selected then 0 else 1
			end
		end
		applyCamera()
		if selectedValue and selectedValue:IsA("StringValue") then
			selectedValue.Value = selectedId or ""
		end
	end

	local function applyTerritoryState(data: any)
		ownership = {}
		if typeof(data.territories) == "table" then
			for _, row in data.territories do
				if typeof(row.territoryId) == "string" then
					ownership[row.territoryId] = if row.hasOwner == true then (tostring(row.ownerRulerId)) else ""
				end
			end
		end
		colorIndex = {}
		if typeof(data.rulerColors) == "table" then
			for _, row in data.rulerColors do
				if typeof(row.rulerId) == "string" and typeof(row.colorIndex) == "number" then
					colorIndex[row.rulerId] = row.colorIndex
				end
			end
		end
		print("[Territory] State received map=", tostring(data.mapId))
		colorize()
	end

	local function applyHierarchyState(data: any)
		hierarchyById = {}
		if typeof(data.rulers) == "table" then
			for _, ruler in data.rulers do
				if typeof(ruler.rulerId) == "string" then
					hierarchyById[ruler.rulerId] = ruler
				end
			end
		end
		colorize()
	end

	territoryPush.OnClientEvent:Connect(function(kind: any, payload: any)
		if kind == "State" then
			local data = decodeState(payload)
			if data then
				applyTerritoryState(data)
			else
				warn("[Territory] State decode failed")
			end
		end
	end)

	hierarchyPush.OnClientEvent:Connect(function(kind: any, payload: any)
		if kind == "State" then
			local data = decodeState(payload)
			if data then
				applyHierarchyState(data)
			end
		end
	end)

	local function pointerScreen(): Vector2
		return UserInputService:GetMouseLocation() - GuiService:GetGuiInset()
	end

	local function mouseOverMap(screen: Vector2): boolean
		local abs = mapStage.AbsolutePosition
		local size = mapStage.AbsoluteSize
		return screen.X >= abs.X and screen.Y >= abs.Y and screen.X <= abs.X + size.X and screen.Y <= abs.Y + size.Y
	end

	-- Map is the lowest input layer. Higher project GUI at this point owns the pointer.
	-- ResultToast is informational and is not treated as a blocking layer.
	-- AdminInspectPanel, EconomyPanel, MilitaryPanel, and visible Kohl command/dashboard chrome block the map.
	local function isKohlBlockingGui(obj: GuiObject): boolean
		local screenGui = obj:FindFirstAncestorWhichIsA("ScreenGui")
		if not screenGui then
			return false
		end
		local guiName = screenGui.Name
		if
			guiName ~= "FluxUILayerTopbar"
			and guiName ~= "FluxUILayerTop"
			and guiName ~= "FluxUILayerDefault"
			and guiName ~= "FluxUILayerBottom"
		then
			return false
		end
		local current: Instance? = obj
		while current and current ~= screenGui do
			if current:IsA("GuiObject") and current.Visible then
				local n = current.Name
				if n == "CommandBar" or n == "Window" or n == "Dialog" or n == "Cmdbar2" or n == "KADashboardButton" or n == "KACommandsButton" then
					return true
				end
			end
			current = current.Parent
		end
		return false
	end
	local function isMapDescendant(obj: Instance): boolean
		local current: Instance? = obj
		while current and current ~= gui do
			if current == mapStage then
				return true
			end
			current = current.Parent
		end
		return false
	end

	local function blockingPanelOf(obj: Instance): GuiObject?
		local current: Instance? = obj
		while current and current ~= gui do
			if current:IsA("GuiObject") and current:GetAttribute("BlocksMapInput") then return current end
			if current:IsA("GuiObject") and current.Parent == gui then
				local name = current.Name
				if current:GetAttribute("BlocksMapInput") or name == "VictoryOverlay" or name == "RealmOverviewOverlay" or name == "VassalageOfferOverlay" or name == "DiplomacyOfferOverlay" or name == "TitlePanel" or name == "Main" or name == "AdminInspectPanel" or name == "EconomyPanel" or name == "MilitaryWorkflowPanel" or name == "CommunicationsPanel" or name == "StrategyNavigation" or name == "StrategyTopbar" then
					return current
				end
			end
			current = current.Parent
		end
		return nil
	end

	local function pointerOnHigherGui(screen: Vector2): boolean
		local objects = player.PlayerGui:GetGuiObjectsAtPosition(screen.X, screen.Y)
		for _, obj in objects do
			if obj:IsA("GuiObject") and obj.Visible and not isMapDescendant(obj) then
				if isKohlBlockingGui(obj) then
					return true
				end
				local panel = blockingPanelOf(obj)
				if panel and panel.Visible then
					return true
				end
			end
		end
		return false
	end

	local mapPress = false

	-- Press must start on the map surface (MapStage / MapView), not on higher panels.
	-- Drag uses inset-corrected cursor position so GuiObject vs UIS coordinates cannot cancel pan.
	gui:GetAttributeChangedSignal("RealmOverviewOpen"):Connect(function()
		if gui:GetAttribute("RealmOverviewOpen") then mapPress = false; dragging = false; dragStart = nil end
	end)
	gui:GetAttributeChangedSignal("VictoryOverlayOpen"):Connect(function()
		if gui:GetAttribute("VictoryOverlayOpen") then mapPress = false; dragging = false; dragStart = nil end
	end)
	local function beginMapPress(input: InputObject)
		if input.UserInputType ~= Enum.UserInputType.MouseButton1 then
			return
		end
		if gui:GetAttribute("RealmOverviewOpen") or pointerOnHigherGui(pointerScreen()) then
			return
		end
		mapPress = true
		dragging = true
		dragMoved = false
		dragStart = pointerScreen()
		lookStart = Vector2.new(lookX, lookZ)
	end

	mapStage.InputBegan:Connect(beginMapPress)
	viewport.InputBegan:Connect(beginMapPress)

	UserInputService.InputChanged:Connect(function(input, _gameProcessed)
		if dragging and mapPress and input.UserInputType == Enum.UserInputType.MouseMovement and dragStart then
			local now = pointerScreen()
			if (now - dragStart).Magnitude > 6 then
				dragMoved = true
			end
			if dragMoved then
				local size = viewport.AbsoluteSize
				if size.X < 1 or size.Y < 1 then
					return
				end
				local h = cameraHeight()
				local halfZ = h * math.tan(math.rad(FOV * 0.5))
				local halfX = halfZ * (size.X / size.Y)
				local dx = (now.X - dragStart.X) / size.X * 2 * halfX
				local dz = (now.Y - dragStart.Y) / size.Y * 2 * halfZ
				lookX = lookStart.X - dx
				lookZ = lookStart.Y - dz
				applyCamera()
			end
		elseif input.UserInputType == Enum.UserInputType.MouseWheel then
			-- Active MapStage marks wheel as gameProcessed. That is the map surface, not a higher panel.
			local pos = pointerScreen()
			if gui:GetAttribute("RealmOverviewOpen") or not mouseOverMap(pos) or pointerOnHigherGui(pos) then
				return
			end
			if input.Position.Z > 0 then
				zoom = math.clamp(zoom * 1.12, MIN_ZOOM, MAX_ZOOM)
			else
				zoom = math.clamp(zoom / 1.12, MIN_ZOOM, MAX_ZOOM)
			end
			applyCamera()
		end
	end)

	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType ~= Enum.UserInputType.MouseButton1 then
			return
		end
		local wasMapPress = mapPress
		local wasDrag = dragMoved
		mapPress = false
		dragging = false
		dragMoved = false
		if not wasMapPress or wasDrag then
			return
		end
		local pos = pointerScreen()
		if pointerOnHigherGui(pos) then
			return
		end
		local mx, my = screenToMap(pos)
		if not mx or not my then
			return
		end
		selectedId = hitTerritory(mx, my)
		colorize()
		TerritoryMapController.SelectionChanged:Fire(selectedId, pos)
	end)
	function TerritoryMapController.Select(territoryId: string?, contextWorkflow: string?)
		selectedId = territoryId
		colorize()
		TerritoryMapController.SelectionChanged:Fire(selectedId, if territoryId then TerritoryMapController.Project(territoryId) else nil, contextWorkflow)
	end

	mapStage:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
		applyCamera()
	end)

	Theme.PresentationChanged.Event:Connect(applyCamera)
	applyCamera()
	territoryIntent:FireServer("Ready")
	print("[Territory] controller started; Ready sent")
	colorize()
end

return TerritoryMapController
