--!strict

--[[
	Places two WedgeParts for a triangle on the XZ plane (Y up).
	Thickness is along world Y so the map reads as a flat political board.
]]

local MapTriangles = {}

local template = Instance.new("WedgePart")
template.Anchored = true
template.CanCollide = false
template.CanQuery = false
template.CanTouch = false
template.CastShadow = false
template.Material = Enum.Material.SmoothPlastic
template.TopSurface = Enum.SurfaceType.Smooth
template.BottomSurface = Enum.SurfaceType.Smooth

local function toV3(p: { x: number, y: number }): Vector3
	return Vector3.new(p.x, 0, p.y)
end

function MapTriangles.Draw(
	parent: Instance,
	a: { x: number, y: number },
	b: { x: number, y: number },
	c: { x: number, y: number },
	color: Color3,
	name: string,
	thickness: number
): { WedgePart }
	local pa, pb, pc = toV3(a), toV3(b), toV3(c)
	local ab, ac, bc = pb - pa, pc - pa, pc - pb
	local abd, acd, bcd = ab.Magnitude, ac.Magnitude, bc.Magnitude
	if abd < 1e-3 or acd < 1e-3 or bcd < 1e-3 then
		return {}
	end
	-- Put the longest edge as BC so two wedges meet along the altitude.
	if abd >= acd and abd >= bcd then
		pa, pb, pc = pc, pa, pb
	elseif acd >= abd and acd >= bcd then
		pa, pb, pc = pb, pc, pa
	end
	ab, ac, bc = pb - pa, pc - pa, pc - pb
	local edge = pc - pb
	local edgeLen = edge.Magnitude
	if edgeLen < 1e-3 then
		return {}
	end
	local back = edge.Unit
	local toA = pa - pb
	local proj = toA:Dot(back)
	local perp = toA - back * proj
	local height = perp.Magnitude
	if height < 1e-3 then
		return {}
	end
	local up = perp.Unit
	local right = up:Cross(back)
	if right.Y < 0 then
		right = -right
	end
	right = right.Unit

	local w1 = template:Clone()
	local w2 = template:Clone()
	w1.Name = name .. "_a"
	w2.Name = name .. "_b"
	w1.Color = color
	w2.Color = color
	local z1 = math.abs(proj)
	local z2 = math.abs(edgeLen - proj)
	w1.Size = Vector3.new(thickness, height, math.max(z1, 0.05))
	w2.Size = Vector3.new(thickness, height, math.max(z2, 0.05))
	local midA = pb + back * (z1 * 0.5) + up * (height * 0.5)
	local midB = pc - back * (z2 * 0.5) + up * (height * 0.5)
	w1.CFrame = CFrame.fromMatrix(midA, right, up, back)
	w2.CFrame = CFrame.fromMatrix(midB, -right, up, -back)
	w1.Parent = parent
	w2.Parent = parent
	return { w1, w2 }
end

-- Outward border strips only. Does not fill the interior.
function MapTriangles.DrawRing(
	parent: Instance,
	polygon: { { x: number, y: number } },
	color: Color3,
	name: string,
	thickness: number,
	width: number,
	yOffset: number?,
	inward: boolean?
): { WedgePart }
	if #polygon < 3 then
		return {}
	end
	local cx, cy = 0, 0
	for _, p in polygon do
		cx += p.x
		cy += p.y
	end
	cx /= #polygon
	cy /= #polygon
	local parts = {}
	for i = 1, #polygon do
		local a = polygon[i]
		local b = polygon[i % #polygon + 1]
		local dx = b.x - a.x
		local dy = b.y - a.y
		local nlen = math.sqrt(dx * dx + dy * dy)
		if nlen >= 1e-3 then
			local nx = dy / nlen
			local ny = -dx / nlen
			local mx = (a.x + b.x) * 0.5
			local my = (a.y + b.y) * 0.5
			local pointingOut = (mx - cx) * nx + (my - cy) * ny >= 0
			local wantIn = inward == true
			if pointingOut == wantIn then
				nx = -nx
				ny = -ny
			end
			local strip = {
				a,
				b,
				{ x = b.x + nx * width, y = b.y + ny * width },
				{ x = a.x + nx * width, y = a.y + ny * width },
			}
			local tri = MapTriangles.DrawQuad(parent, strip, color, name .. "_" .. tostring(i), thickness, yOffset)
			for _, p in tri do
				table.insert(parts, p)
			end
		end
	end
	return parts
end

function MapTriangles.DrawQuad(
	parent: Instance,
	polygon: { { x: number, y: number } },
	color: Color3,
	name: string,
	thickness: number,
	yOffset: number?
): { WedgePart }
	if #polygon < 3 then
		return {}
	end
	local parts = {}
	for i = 2, #polygon - 1 do
		local tri = MapTriangles.Draw(parent, polygon[1], polygon[i], polygon[i + 1], color, name .. "_" .. tostring(i), thickness)
		for _, p in tri do
			if yOffset then
				p.CFrame = p.CFrame + Vector3.new(0, yOffset, 0)
			end
			table.insert(parts, p)
		end
	end
	return parts
end

return MapTriangles
