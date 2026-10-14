--!strict
local Geometry = require(script.Parent.MapGeometry)
local Layout = {}
function Layout.Anchor(polygon: any): (number, number, number)
	local bestX, bestY, bestRadius = 0, 0, -1
	local bestScore = -1
	local _,labelY = Geometry.Centroid(polygon)
	local x1,y1,x2,y2 = Geometry.PolygonBounds(polygon)
	local function consider(x: number, y: number)
		if not Geometry.PointInPolygon(x,y,polygon) then return end
		local radius = math.huge
		for i,a in polygon do
			local b = polygon[i % #polygon + 1]
			local dx,dy = b.x-a.x,b.y-a.y
			local t = if dx*dx+dy*dy > 0 then math.clamp(((x-a.x)*dx+(y-a.y)*dy)/(dx*dx+dy*dy),0,1) else 0
			radius = math.min(radius,math.sqrt((x-a.x-t*dx)^2+(y-a.y-t*dy)^2))
		end
		local score = radius * (if y > labelY then 1.03 else 1)
		if score > bestScore then bestX,bestY,bestRadius,bestScore = x,y,radius,score end
	end
	-- Triangle interiors provide candidates even for narrow concave shapes.
	for _, triangle in Geometry.Triangulate(polygon) do
		consider((triangle[1].x+triangle[2].x+triangle[3].x)/3,(triangle[1].y+triangle[2].y+triangle[3].y)/3)
	end
	for i=1,9 do for j=1,9 do consider(x1+(x2-x1)*i/10,y1+(y2-y1)*j/10) end end
	assert(bestRadius > 0,"Province has no building-marker interior")
	return bestX,bestY,math.min(20,bestRadius*.43)
end
function Layout.Slot(x: number,y: number,unit: number,index: number): (number,number)
	return x+(if index%2==1 then -.65 else .65)*unit,y+(if index<=2 then -.65 else .65)*unit
end
return Layout
