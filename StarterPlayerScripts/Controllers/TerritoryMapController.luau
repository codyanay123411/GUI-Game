--!strict

--[[
	Prototype map renderer and input. Displays server ownership; never mutates it.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local GuiService = game:GetService("GuiService")

local MapCatalog = require(ReplicatedStorage.Shared.Config.MapCatalog)
local RealmColors = require(ReplicatedStorage.Shared.Config.RealmColors)
local MapGeometry = require(ReplicatedStorage.Shared.Util.MapGeometry)
local MapTriangles = require(ReplicatedStorage.Shared.Util.MapTriangles)

local player = Players.LocalPlayer
local TerritoryMapController = {}

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
	local info = gui:WaitForChild("TerritoryInfo") :: Frame
	local infoBody = info:WaitForChild("Body") :: TextLabel

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

	local function updateInfo()
		if not selectedId then
			infoBody.Text = "No territory selected.\nClick the map to inspect a province."
			return
		end
		local def = byId[selectedId]
		if not def then
			infoBody.Text = "Unknown territory."
			return
		end
		local ownerId = ownership[selectedId]
		if not ownerId or ownerId == "" then
			infoBody.Text = string.format(
				"%s\nID: %s\nOwner: Unclaimed\nRank: —\nStatus: —\nGreater realm: —",
				def.displayName,
				def.id
			)
			return
		end
		local owner = rulerOf(ownerId)
		local root = if owner then rulerOf(owner.rootRulerId) else nil
		infoBody.Text = string.format(
			"%s\nID: %s\nOwner: %s\nRank: %s\nStatus: %s\nGreater realm: %s",
			def.displayName,
			def.id,
			if owner then owner.displayName else ownerId,
			if owner then owner.titleName else "—",
			if owner then (if owner.independent then "Independent" else "Subject") else "—",
			if root then root.displayName else (if owner then owner.displayName else "—")
		)
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
		updateInfo()
		applyCamera()
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
			if current:IsA("GuiObject") and current.Parent == gui then
				local name = current.Name
				if name == "VassalageOfferOverlay" or name == "DiplomacyOfferOverlay" or name == "TitlePanel" or name == "Main" or name == "TerritoryInfo" or name == "DiplomacyPanel" then
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
	local function beginMapPress(input: InputObject)
		if input.UserInputType ~= Enum.UserInputType.MouseButton1 then
			return
		end
		if pointerOnHigherGui(pointerScreen()) then
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
			if not mouseOverMap(pos) or pointerOnHigherGui(pos) then
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
	end)

	mapStage:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
		applyCamera()
	end)

	applyCamera()
	territoryIntent:FireServer("Ready")
	print("[Territory] controller started; Ready sent")
	colorize()
end

return TerritoryMapController
