--!strict

export type EconomyPlayerSnapshot = {
	gold: number,
	incomeGoldPerMinute: number,
	payoutIntervalSeconds: number,
	nextPayoutAt: number,
}

export type EconomyInspectSnapshot = {
	rulerId: string,
	gold: number,
	incomeGoldPerMinute: number,
	ownedTerritoryCount: number,
}

return {}
