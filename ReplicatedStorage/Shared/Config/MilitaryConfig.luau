--!strict

--[[
	Military / Armies V0.1 tuning.
]]

local MilitaryConfig = {
	SubjectCombatBase = 0.09,
	SubjectCombatPerLiegeSubject = 0.01,
	PersonalDefensePerSubject = 0.02,
	NavalMapUnitsPerSecond = 25,
	NavalMinTravelSeconds = 5,
	NavalMaxTravelSeconds = 35,
	StartingTroops = 500,
	-- Recruitment uses BuildingConfig ten-Troop local prices; no legacy per-Gold conversion.
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
