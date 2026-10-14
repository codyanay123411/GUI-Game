--!strict

--[[
	Pure 2D geometry for authored polygons; naval policy remains in NavalRoutes.
]]

local MapGeometry = {}

export type Point = { x: number, y: number }

function MapGeometry.PointInPolygon(px: number, py: number, polygon: { Point }): boolean
	local inside = false
	local j = #polygon
	for i = 1, #polygon do
		local yi = polygon[i].y
		local yj = polygon[j].y
		local xi = polygon[i].x
		local xj = polygon[j].x
		local intersect = ((yi > py) ~= (yj > py)) and (px < (xj - xi) * (py - yi) / (yj - yi) + xi)
		if intersect then
			inside = not inside
		end
		j = i
	end
	return inside
end

function MapGeometry.PolygonBounds(polygon: { Point }): (number, number, number, number)
	local minX, minY = math.huge, math.huge
	local maxX, maxY = -math.huge, -math.huge
	for _, p in polygon do
		minX = math.min(minX, p.x)
		minY = math.min(minY, p.y)
		maxX = math.max(maxX, p.x)
		maxY = math.max(maxY, p.y)
	end
	return minX, minY, maxX, maxY
end

function MapGeometry.MapBounds(polygons: { { Point } }): (number, number, number, number)
	local minX, minY = math.huge, math.huge
	local maxX, maxY = -math.huge, -math.huge
	for _, polygon in polygons do
		local a, b, c, d = MapGeometry.PolygonBounds(polygon)
		minX = math.min(minX, a)
		minY = math.min(minY, b)
		maxX = math.max(maxX, c)
		maxY = math.max(maxY, d)
	end
	return minX, minY, maxX, maxY
end

function MapGeometry.Centroid(polygon: { Point }): (number, number)
	local sx, sy = 0, 0
	for _, p in polygon do
		sx += p.x
		sy += p.y
	end
	local n = math.max(#polygon, 1)
	return sx / n, sy / n
end

function MapGeometry.Cross(a: Point, b: Point, c: Point): number
	return (b.x - a.x) * (c.y - a.y) - (b.y - a.y) * (c.x - a.x)
end

function MapGeometry.OnSegment(p: Point, a: Point, b: Point): boolean
	return math.abs(MapGeometry.Cross(a, b, p)) < 1e-6
		and p.x >= math.min(a.x, b.x) - 1e-6 and p.x <= math.max(a.x, b.x) + 1e-6
		and p.y >= math.min(a.y, b.y) - 1e-6 and p.y <= math.max(a.y, b.y) + 1e-6
end

function MapGeometry.Area2(polygon: { Point }): number
	local area = 0
	for i, a in polygon do
		local b = polygon[i % #polygon + 1]
		area += a.x * b.y - b.x * a.y
	end
	return area
end

-- Ear clipping handles simple concave authored province polygons.
function MapGeometry.Triangulate(polygon: { Point }): { { Point } }
	local indices, result = {}, {}
	for i = 1, #polygon do table.insert(indices, i) end
	local sign = if MapGeometry.Area2(polygon) > 0 then 1 else -1
	while #indices > 3 do
		local found = false
		for k, i in indices do
			local a, b, c = polygon[indices[(k - 2) % #indices + 1]], polygon[i], polygon[indices[k % #indices + 1]]
			if sign * MapGeometry.Cross(a, b, c) <= 1e-7 then continue end
			local occupied = false
			for _, j in indices do
				local p = polygon[j]
				if p == a or p == b or p == c then continue end
				if sign * MapGeometry.Cross(a, b, p) >= -1e-7 and sign * MapGeometry.Cross(b, c, p) >= -1e-7
					and sign * MapGeometry.Cross(c, a, p) >= -1e-7 then occupied = true; break end
			end
			if not occupied then
				table.insert(result, { a, b, c }); table.remove(indices, k); found = true; break
			end
		end
		assert(found, "Invalid/self-intersecting map polygon")
	end
	if #indices == 3 then table.insert(result, { polygon[indices[1]], polygon[indices[2]], polygon[indices[3]] }) end
	return result
end

function MapGeometry.Entry(edge: any, polygon: { Point }): any
	local dx, dy = edge.b.x - edge.a.x, edge.b.y - edge.a.y
	local length = math.sqrt(dx * dx + dy * dy)
	local sign = if MapGeometry.Area2(polygon) > 0 then 1 else -1
	return { edge = edge, point = { x = (edge.a.x + edge.b.x) / 2, y = (edge.a.y + edge.b.y) / 2 },
		direction = { x = -dy * sign / length, y = dx * sign / length } }
end

function MapGeometry.SharedEntry(source: any, target: any): any?
	for i, a in target.polygon do
		local b = target.polygon[i % #target.polygon + 1]
		for j, c in source.polygon do
			local d = source.polygon[j % #source.polygon + 1]
			if MapGeometry.OnSegment(a, c, d) and MapGeometry.OnSegment(b, c, d) then
				return MapGeometry.Entry({ a = a, b = b }, target.polygon)
			end
		end
	end
	return nil
end

function MapGeometry.ClipConvex(polygon: { Point }, boundary: { Point }): { Point }
	local result = polygon
	for i, a in boundary do
		local b = boundary[i % #boundary + 1]
		local out = {}
		for j, p in result do
			local q = result[j % #result + 1]
			local dp, dq = MapGeometry.Cross(a,b,p), MapGeometry.Cross(a,b,q)
			if dp >= 0 then table.insert(out,p) end
			if (dp < 0 and dq > 0) or (dp > 0 and dq < 0) then
				local t = dp / (dp-dq);table.insert(out,{x=p.x+(q.x-p.x)*t,y=p.y+(q.y-p.y)*t})
			end
		end
		result = out;if #result == 0 then break end
	end
	return result
end

-- A convex capsule advances out of the actual entry segment. Unlike a global
-- sweep plane, it starts at a concave landing inlet rather than a distant edge.
function MapGeometry.FrontBoundary(entry: any, polygon: { Point }, progress: number): { Point }
	local a,b = entry.edge.a,entry.edge.b
	local dx,dy = b.x-a.x,b.y-a.y;local length2 = dx*dx+dy*dy
	local radius = 0
	for _, p in polygon do
		local t = math.clamp(((p.x-a.x)*dx+(p.y-a.y)*dy)/length2,0,1)
		radius = math.max(radius,math.sqrt((p.x-a.x-dx*t)^2+(p.y-a.y-dy*t)^2))
	end
	radius = math.max(.001,radius*progress*1.03)
	local points = {}
	for _, center in {a,b}do
		for i = 0,23 do local angle=i*math.pi/12;table.insert(points,{x=center.x+math.cos(angle)*radius,y=center.y+math.sin(angle)*radius})end
	end
	table.sort(points,function(p,q)return if p.x==q.x then p.y<q.y else p.x<q.x end)
	local lower,upper = {},{}
	for _, p in points do
		while #lower>=2 and MapGeometry.Cross(lower[#lower-1],lower[#lower],p)<=0 do table.remove(lower)end
		table.insert(lower,p)
	end
	for i=#points,1,-1 do local p=points[i]
		while #upper>=2 and MapGeometry.Cross(upper[#upper-1],upper[#upper],p)<=0 do table.remove(upper)end
		table.insert(upper,p)
	end
	table.remove(lower);table.remove(upper);for _,p in upper do table.insert(lower,p)end
	return lower
end

return MapGeometry
