--!strict

export type AgreementType = "Alliance" | "NAP"

export type DiplomacyRequestId = string

export type DiplomacyAgreementSnapshot = {
	leftRulerId: string,
	rightRulerId: string,
	alliance: boolean,
	nap: boolean,
}

export type DiplomacyRequestSnapshot = {
	requestId: DiplomacyRequestId,
	agreementType: string,
	fromRulerId: string,
	toRulerId: string,
	expiresAt: number,
}

export type DiplomacySnapshot = {
	agreements: { DiplomacyAgreementSnapshot },
	requests: { DiplomacyRequestSnapshot },
}

return {}
