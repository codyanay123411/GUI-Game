--!strict

export type TerritoryId = string

export type MapId = string

export type Point = { x: number, y: number }

export type TerritoryDefinition = {
	id: TerritoryId,
	displayName: string,
	polygon: { Point },
	adjacentIds: { TerritoryId },
}

export type MapDefinition = {
	mapId: MapId,
	displayName: string,
	territories: { TerritoryDefinition },
}

export type TerritoryOwnershipSnapshot = {
	territoryId: TerritoryId,
	ownerRulerId: string,
	hasOwner: boolean,
}

export type RulerColorSnapshot = {
	rulerId: string,
	colorIndex: number,
}

export type TerritoryMapSnapshot = {
	mapId: MapId,
	territories: { TerritoryOwnershipSnapshot },
	rulerColors: { RulerColorSnapshot },
}

return {}
