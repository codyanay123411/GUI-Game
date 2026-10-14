--!strict

--[[
	Military / Armies V0.1 tuning.
]]

local MilitaryConfig = {
	SubjectCombatBase = 0.09,
	SubjectCombatPerLiegeSubject = 0.01,
	PersonalDefensePerSubject = 0.02,
	StartingTroops = 1000,
	TroopsPerGold = 3,
	CommitWindowSeconds = 40,
	HardTimeoutSeconds = 55,
	PresentationSeconds = 5,
	LastBattleSummarySeconds = 20,
	TerritoryCooldownSeconds = 10,
	CombatRollMin = 0.90,
	CombatRollMax = 1.10,
	DefenseRollMin = 1.00,
	DefenseRollMax = 1.05,
	CloseRatioMax = 1.15,
	ClearRatioMax = 1.50,
}

return MilitaryConfig
