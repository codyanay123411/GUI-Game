--!strict

--[[
	Economy / Resources V0.1 tuning.

	Territory Gold/minute lives on MapConfiguration.baseGoldIncome.
	This module holds match-wide Gold rules only.
]]

local EconomyConfig = {
	StartingGold = 100,
	PayoutIntervalSeconds = 6,
	-- Current rank only; basis points keep whole-Gold remainder accounting exact.
	RankBonusBasisPoints = table.freeze({ [1] = 0, [2] = 50, [3] = 100, [4] = 200 }),
}

return EconomyConfig
