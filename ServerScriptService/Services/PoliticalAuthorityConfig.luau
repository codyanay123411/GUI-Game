--!strict
-- Initial Director-approved values; council membership conveys no capabilities.
return table.freeze({
	LandWeight = 100,
	TroopWeight = 1,
	TroopUnit = 10,
	SeatLimit = 5,
	ReplacementMarginPercent = 10,
	ReplacementDurationSeconds = 30,
	EvaluationIntervalSeconds = 1,
	BetrayalTransferFraction = 0.30,
	BetrayalReviewSeconds = 30,
})
