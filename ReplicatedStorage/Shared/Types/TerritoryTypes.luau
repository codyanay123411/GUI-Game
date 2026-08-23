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

export type TitleRequirement = {
	rank: number,
	titleName: string,
	establishLabel: string,
	establishedNotice: string,
	territoryCount: number,
	prestige: number,
}

export type MapDefinition = {
	mapId: MapId,
	displayName: string,
	territories: { TerritoryDefinition },
	titleRequirements: { TitleRequirement }?,
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
