--!strict

export type WarId = string

export type WarStatus = "Active" | "Resolved"

export type WarSnapshot = {
	warId: WarId,
	attackerRootId: string,
	defenderRootId: string,
	targetTerritoryId: string,
	status: string,
	targetKind: string,
	neutralDefenders: number?,
}

export type WarfareSnapshot = {
	wars: { WarSnapshot },
}

return {}
