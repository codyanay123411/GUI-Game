--!strict
-- Cosmetic WorldModel layers: camera transforms align geography, ships and fronts.
-- Only actor-scoped Military results drive fronts; public travel contains no force count.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Geometry = require(ReplicatedStorage.Shared.Util.MapGeometry)
local Triangles = require(ReplicatedStorage.Shared.Util.MapTriangles)
local Theme = require(ReplicatedStorage.Shared.Util.PrototypeGuiTheme)
local State = require(script.Parent.MapContextState)
local Effects = {}

function Effects.Start(world: WorldModel, map: any, gui: ScreenGui, colors: (string) -> (Color3, Color3))
	local layer = Instance.new("Folder");layer.Name = "MapBattleEffects";layer.Parent = world
	local byId, ships, fronts = {}, {}, {}
	for _, province in map.territories do
		local cx, cy = Geometry.Centroid(province.polygon)
		local inner = {};for _, p in province.polygon do table.insert(inner,{x=p.x+(cx-p.x)*.08,y=p.y+(cy-p.y)*.08})end
		byId[province.id] = { definition = province, outer = Geometry.Triangulate(province.polygon), inner = Geometry.Triangulate(inner) }
	end
	local function ship(war: any, at: number)
		local marker = ships[war.warId]
		if not marker then
			marker = Instance.new("Part");marker.Name = "Transport_" .. war.warId
			marker.Anchored = true;marker.CanCollide = false;marker.CanTouch = false;marker.CanQuery = false
			marker.CastShadow = false;marker.Size = Vector3.new(7, 3, 13)
			marker.Color = Theme.Colors.accentGold;marker.Material = Enum.Material.Neon;marker.Parent = layer
			ships[war.warId] = marker
		end
		local travel = war.travel
		local progress = if Theme.Presentation.AnimationsEnabled then math.clamp((at - travel.launchedAt) / (travel.arrivesAt - travel.launchedAt), 0, 1) else 0
		local a, b = travel.from, travel.to
		local point = Vector3.new(a.x + (b.x-a.x)*progress, 5, a.y + (b.y-a.y)*progress)
		marker.CFrame = CFrame.lookAt(point, point + Vector3.new(b.x-a.x,0,b.y-a.y))
	end
	local function front(war: any, at: number)
		local result, cached = war.visualResult, byId[war.targetTerritoryId]
		local province = cached and cached.definition
		if not province or not result.entry then return end
		local state = fronts[war.warId]
		if not state then
			local folder = Instance.new("Folder");folder.Name = "Front_" .. war.warId;folder.Parent = layer
			state = { folder = folder, parts = {} };fronts[war.warId] = state
			if result.winner == "Defender" then Triangles.DrawRing(folder,province.polygon,Theme.Colors.danger,"Repelled",2,4,5,true) end
		end
		if result.winner == "Defender" then return end
		local direct, realm = colors(result.attackerId)
		local progress = if Theme.Presentation.AnimationsEnabled then math.clamp((at-result.startedAt)/(result.endsAt-result.startedAt),0,1) else 1
		local boundary = Geometry.FrontBoundary(result.entry,province.polygon,progress)
		for _, pair in state.parts do for _, part in pair do part.Transparency = 1 end end
		local used = 0
		for _, pass in { {triangles=cached.outer,color=direct,y=1.25}, {triangles=cached.inner,color=realm,y=3.35} } do
			for _, triangle in pass.triangles do
				local clipped = Geometry.ClipConvex(triangle,boundary)
				-- Clipped triangles are convex: fan them without repeated ear clipping.
				for i = 2, #clipped-1 do
					if math.abs(Geometry.Area2({clipped[1],clipped[i],clipped[i+1]})) < .001 then continue end
					used += 1
					local pair = Triangles.Draw(state.folder,clipped[1],clipped[i],clipped[i+1],pass.color,"CosmeticFront",6,state.parts[used])
					if #pair > 0 then state.parts[used] = pair end
					for _, part in pair do part.CFrame += Vector3.new(0,pass.y,0);part.Transparency = 0 end
				end
			end
		end
		for i = used+1, #state.parts do for _, part in state.parts[i] do part.Transparency = 1 end end
	end
	local function render()
		local at = workspace:GetServerTimeNow()
		local aliveShips, aliveFronts = {}, {}
		if gui:GetAttribute("MatchEnded") ~= true then
			for _, war in State.warfare.wars or {} do if war.travel then aliveShips[war.warId] = true;ship(war,at) end end
			for _, war in State.military.wars or {} do
				if war.phase == "present" and war.visualResult and at < war.visualResult.endsAt then aliveFronts[war.warId] = true;front(war,at) end
			end
		end
		for id, marker in ships do if not aliveShips[id] then marker:Destroy();ships[id] = nil end end
		for id, state in fronts do if not aliveFronts[id] then state.folder:Destroy();fronts[id] = nil end end
	end
	local elapsed = 0
	RunService.Heartbeat:Connect(function(dt)
		elapsed += dt;if elapsed < .1 then return end;elapsed = 0;render()
	end)
	gui:GetAttributeChangedSignal("MatchEnded"):Connect(render)
	require(ReplicatedStorage.Shared.Util.MatchIntent).OnChanged(function()
		for _, marker in ships do marker:Destroy() end;for _, state in fronts do state.folder:Destroy() end
		ships, fronts = {}, {}
	end)
	State.Changed.Event:Connect(function(_,kind)if kind == "State"then render()end end)
	Theme.PresentationChanged.Event:Connect(render)
end

return Effects
