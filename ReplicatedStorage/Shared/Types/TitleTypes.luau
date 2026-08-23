--!strict

export type TitleRequirement = {
	rank: number,
	titleName: string,
	establishLabel: string,
	establishedNotice: string,
	territoryCount: number,
	prestige: number,
}

export type TitleEligibilitySnapshot = {
	rulerId: string,
	currentRank: number,
	currentTitleName: string,
	hasNext: boolean,
	nextRank: number,
	nextTitleName: string,
	establishLabel: string,
	realmControl: number,
	realmRequired: number,
	prestige: number,
	prestigeRequired: number,
	eligible: boolean,
	statusText: string,
}

export type TitleProgressionSnapshot = {
	mapId: string,
	rows: { TitleEligibilitySnapshot },
}

return {}
