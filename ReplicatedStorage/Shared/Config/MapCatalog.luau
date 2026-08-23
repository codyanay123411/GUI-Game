--!strict

--[[
	Selected MapConfiguration for the current match.
	V0.1 always uses the Vale prototype; the API is map-id based so
	future presets can be swapped without rewriting political systems.
]]

local ValePrototypeMap = require(script.Parent.ValePrototypeMap)

local MapCatalog = {}

local mapsById = {
	[ValePrototypeMap.mapId] = ValePrototypeMap,
}

function MapCatalog.Get(mapId: string)
	return mapsById[mapId]
end

function MapCatalog.GetDefault()
	return ValePrototypeMap
end

return MapCatalog
