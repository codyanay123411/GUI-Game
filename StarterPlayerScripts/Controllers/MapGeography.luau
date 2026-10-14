--!strict
-- Static geographic art plus six reusable water glints. No movement/combat semantics.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Geometry = require(ReplicatedStorage.Shared.Util.MapGeometry)
local Triangles = require(ReplicatedStorage.Shared.Util.MapTriangles)
local Theme = require(ReplicatedStorage.Shared.Util.PrototypeGuiTheme)
local Art = {}
function Art.Start(world: WorldModel, map: any)
	local folder = Instance.new("Folder");folder.Name = "DecorativeGeography";folder.Parent = world
	local function part(name: string, color: Color3, size: Vector3, position: Vector3): Part
		local p = Instance.new("Part");p.Name = name;p.Anchored = true;p.CanCollide = false;p.CanTouch = false;p.CanQuery = false;p.CastShadow = false
		p.Material = Enum.Material.SmoothPlastic;p.Color = color;p.Size = size;p.Position = position;p.Parent = folder;return p
	end
	local polygons = {};for _, p in map.territories do table.insert(polygons,p.polygon) end
	local xmin, ymin, xmax, ymax = Geometry.MapBounds(polygons)
	-- Coastal shallows are art outside exposed authored edges; actual routes use the polygons.
	for _, province in map.territories do
		for _, edge in province.coastEdges do
			local dx, dy = edge.b.x-edge.a.x, edge.b.y-edge.a.y
			local length = math.sqrt(dx*dx+dy*dy)
			local x, y = (edge.a.x+edge.b.x)/2, (edge.a.y+edge.b.y)/2
			for _, band in { {width=20,color=Color3.fromRGB(30,83,97),height=-5}, {width=6,color=Color3.fromRGB(113,139,132),height=-3.5} } do
				local p = part("Shore",band.color,Vector3.new(band.width,1,length+1),Vector3.new(x,band.height,y))
				p.CFrame = CFrame.lookAt(p.Position,p.Position+Vector3.new(dx,0,dy))
			end
		end
		local cx, cy = Geometry.Centroid(province.polygon)
		-- Restrained translucent symbols supplement, rather than replace, political color.
		for i = -1, 1 do
			local x, y = cx+i*13, cy+18+math.abs(i)*4
			if not Geometry.PointInPolygon(x,y,province.polygon) then continue end
			if province.terrain == "Mountain" then
				local points = { {x=x-9,y=y+6},{x=x,y=y-11},{x=x+9,y=y+6} }
				for _, p in Triangles.DrawQuad(folder,points,Color3.fromRGB(187,189,177),"Ridge",1,8) do p.Transparency=.45 end
			elseif province.terrain == "Forest" then
				local points = { {x=x-5,y=y+5},{x=x,y=y-8},{x=x+5,y=y+5} }
				for _, p in Triangles.DrawQuad(folder,points,Color3.fromRGB(28,65,57),"Forest",1,8) do p.Transparency=.38 end
			else
				local p=part("Plain",Color3.fromRGB(218,209,164),Vector3.new(9,.3,1),Vector3.new(x,8,y));p.Transparency=.65
			end
		end
	end
	local glints = {}
	for i=1,6 do
		local p=part("WaterGlint",Color3.fromRGB(64,109,125),Vector3.new(40+i*4,.2,1),Vector3.new(xmin+(xmax-xmin)*i/7,-6,ymin+(ymax-ymin)*i/7))
		p.Transparency=.8;table.insert(glints,{part=p,origin=p.Position})
	end
	local elapsed = 0
	RunService.Heartbeat:Connect(function(dt)
		elapsed+=dt;if elapsed<.25 then return end;elapsed=0
		local at=os.clock()
		for i, g in glints do
			g.part.Position=g.origin+Vector3.new(if Theme.Presentation.AnimationsEnabled then math.sin(at*.3+i)*7 else 0,0,0)
		end
	end)
end
return Art
