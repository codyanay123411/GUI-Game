--!strict

export type WarId = string

export type WarStatus = "Active" | "Resolved"

export type WarSnapshot = {
	warId: WarId,
	attackerRootId: string,
	defenderRootId: string,
	targetTerritoryId: string,
	status: string,
}

export type WarfareSnapshot = {
	wars: { WarSnapshot },
}

return {}
