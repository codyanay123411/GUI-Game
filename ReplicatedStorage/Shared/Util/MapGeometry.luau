--!strict

--[[
	Shared 2D geometry helpers for map polygons. Not gameplay.
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

return MapGeometry
