--!strict
-- Authoritative/shared route geometry. No proximity-based land adjacency.
local Geometry = require(script.Parent.MapGeometry)
local Routes = {}
local cache: { [any]: { [string]: any } } = setmetatable({}, { __mode = "k" }) :: any
local function midpoint(edge: any): any
	return { x = (edge.a.x + edge.b.x) / 2, y = (edge.a.y + edge.b.y) / 2 }
end
local function cross(ax: number, ay: number, bx: number, by: number): number return ax * by - ay * bx end
local function projected(point: any, edge: any): any
	local dx, dy = edge.b.x-edge.a.x, edge.b.y-edge.a.y
	local t = math.clamp(((point.x-edge.a.x)*dx+(point.y-edge.a.y)*dy)/(dx*dx+dy*dy), .0001, .9999)
	return { x = edge.a.x+dx*t, y = edge.a.y+dy*t }
end

function Routes.Validate(map: any, departure: any, target: any, from: any, to: any): (boolean, string)
	if not departure or not target or departure.id == target.id then return false, "Invalid coastal endpoints" end
	local function coastal(province: any, point: any): boolean
		for _, edge in province.coastEdges or {} do if Geometry.OnSegment(point, edge.a, edge.b) then return true end end
		return false
	end
	if not coastal(departure, from) or not coastal(target, to) then return false, "Route must leave and land on authored coastlines" end
	local dx, dy = to.x - from.x, to.y - from.y
	if dx * dx + dy * dy < 1 then return false, "No water crossing" end
	local cuts = { 0, 1 }
	for _, province in map.territories do
		for i, a in province.polygon do
			local b = province.polygon[i % #province.polygon + 1]
			local ex, ey = b.x - a.x, b.y - a.y
			local denom = cross(dx, dy, ex, ey)
			if math.abs(denom) > 1e-8 then
				local t = cross(a.x - from.x, a.y - from.y, ex, ey) / denom
				local u = cross(a.x - from.x, a.y - from.y, dx, dy) / denom
				if t > 1e-7 and t < 1 - 1e-7 and u >= -1e-7 and u <= 1 + 1e-7 then
					-- Even corner contacts with unrelated land are impassable.
					if province ~= departure and province ~= target then return false, "Route crosses unrelated land" end
					table.insert(cuts, t)
				end
			elseif math.abs(cross(a.x - from.x, a.y - from.y, dx, dy)) < 1e-7 then
				local length2 = dx * dx + dy * dy
				local t1 = ((a.x - from.x) * dx + (a.y - from.y) * dy) / length2
				local t2 = ((b.x - from.x) * dx + (b.y - from.y) * dy) / length2
				if math.min(t1, t2) < 1 - 1e-7 and math.max(t1, t2) > 1e-7 then return false, "Route runs along land" end
			end
		end
	end
	for _, region in map.waterRegions or {} do
		-- Authored water bounds may be concave: collect their segment intersections too.
		for i, a in region do
			local b = region[i % #region + 1]
			local ex, ey = b.x - a.x, b.y - a.y
			local denom = cross(dx, dy, ex, ey)
			if math.abs(denom) > 1e-8 then
				local t = cross(a.x - from.x, a.y - from.y, ex, ey) / denom
				local u = cross(a.x - from.x, a.y - from.y, dx, dy) / denom
				if t > 0 and t < 1 and u >= 0 and u <= 1 then table.insert(cuts, t) end
			end
		end
	end
	table.sort(cuts)
	for i = 1, #cuts - 1 do
		if cuts[i + 1] - cuts[i] < 1e-8 then continue end
		local t = (cuts[i] + cuts[i + 1]) / 2
		local x, y = from.x + dx * t, from.y + dy * t
		for _, province in map.territories do
			if Geometry.PointInPolygon(x, y, province.polygon) then return false, "Route crosses land" end
		end
		local water = false
		for _, region in map.waterRegions or {} do if Geometry.PointInPolygon(x, y, region) then water = true; break end end
		if not water then return false, "Route leaves authored water" end
	end
	return true, ""
end

function Routes.Find(map: any, departureId: string, targetId: string): any?
	local entries = cache[map]
	if not entries then entries = {}; cache[map] = entries end
	local key = departureId .. ":" .. targetId
	if entries[key] ~= nil then return if entries[key] == false then nil else entries[key] end
	local departure, target = nil, nil
	for _, province in map.territories do
		if province.id == departureId then departure = province end
		if province.id == targetId then target = province end
	end
	if not departure or not target or departure.conquerable == false or target.conquerable == false then return nil end
	local best = nil
	for _, coast in departure.coastEdges or {} do
		for _, landing in target.coastEdges or {} do
			-- Closest segment projections plus interior points around authored bays.
			-- Inset endpoints avoid grazing an unrelated province at a shared vertex.
			local pairs = { { midpoint(coast), midpoint(landing) } }
			for _, p in { coast.a, coast.b, midpoint(coast) } do
				local to = projected(p, landing);table.insert(pairs, { projected(to, coast), to })
			end
			for _, p in { landing.a, landing.b, midpoint(landing) } do
				local from = projected(p, coast);table.insert(pairs, { from, projected(from, landing) })
			end
			for _, pair in pairs do
			local from, to = pair[1], pair[2]
			if Routes.Validate(map, departure, target, from, to) then
				local distance = math.sqrt((to.x - from.x)^2 + (to.y - from.y)^2)
				if not best or distance < best.distance then best = { departureId = departureId, targetId = targetId, from = from, to = to,
					distance = distance, entry = Geometry.Entry(landing, target.polygon) } end
			end
			end
		end
	end
	entries[key] = best or false
	return best
end

function Routes.Closest(map: any, personalIds: { string }, targetId: string): any?
	local ids = table.clone(personalIds);table.sort(ids)
	local best = nil
	for _, id in ids do
		local route = Routes.Find(map, id, targetId)
		if route and (not best or route.distance < best.distance - 1e-7) then best = route end
	end
	-- Equal distances retain lexical departure ID, then authored edge/candidate order.
	return best
end

function Routes.TravelSeconds(route: any, config: any): number
	assert(config.NavalMapUnitsPerSecond > 0 and config.NavalMapUnitsPerSecond < math.huge
		and config.NavalMinTravelSeconds > 0 and config.NavalMaxTravelSeconds >= config.NavalMinTravelSeconds
		and config.NavalMaxTravelSeconds < math.huge, "Invalid naval travel configuration")
	return math.clamp(route.distance / config.NavalMapUnitsPerSecond, config.NavalMinTravelSeconds, config.NavalMaxTravelSeconds)
end

return Routes
