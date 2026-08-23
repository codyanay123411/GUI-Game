--!strict

export type TitleRank = number

export type RulerId = string

export type FealtyRequestId = string

export type RulerSnapshot = {
	rulerId: RulerId,
	userId: number?,
	displayName: string,
	titleRank: TitleRank,
	titleName: string,
	liegeId: RulerId?,
	independent: boolean,
	vassalIds: { RulerId },
	descendantIds: { RulerId },
	rootRulerId: RulerId,
}

export type FealtyRequestSnapshot = {
	requestId: FealtyRequestId,
	fromRulerId: RulerId,
	toRulerId: RulerId,
	expiresAt: number,
}

export type HierarchySnapshot = {
	rulers: { RulerSnapshot },
	requests: { FealtyRequestSnapshot },
}

return {}
