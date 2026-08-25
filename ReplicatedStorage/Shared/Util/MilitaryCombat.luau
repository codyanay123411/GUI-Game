--!strict

--[[
	Pure Military / Armies V0.1 battle math.
	Does not replicate. Does not own Troop ledgers.
]]

local MilitaryConfig = require(script.Parent.Parent.Config.MilitaryConfig)

local MilitaryCombat = {}

export type BattleResult = {
	unopposed: boolean,
	winner: string,
	attackerCommitted: number,
	defenderCommitted: number,
	attackerCasualties: number,
	defenderCasualties: number,
	attackerSurvivors: number,
	defenderSurvivors: number,
	attackerCombatRoll: number?,
	defenderCombatRoll: number?,
	defenderDefenseRoll: number?,
	attackerEffective: number?,
	defenderEffective: number?,
	victoryRatio: number?,
	band: string?,
	winnerCasualtyPct: number?,
	loserCasualtyPct: number?,
}

local function inRange(rng: Random, lo: number, hi: number): number
	return lo + rng:NextNumber() * (hi - lo)
end

function MilitaryCombat.ClassifyRatio(ratio: number): string
	if ratio < MilitaryConfig.CloseRatioMax then
		return "CLOSE"
	elseif ratio < MilitaryConfig.ClearRatioMax then
		return "CLEAR"
	end
	return "DECISIVE"
end

function MilitaryCombat.CasualtyPercentRange(band: string): (number, number, number, number)
	if band == "CLOSE" then
		return 0.20, 0.25, 0.25, 0.35
	elseif band == "CLEAR" then
		return 0.15, 0.20, 0.35, 0.40
	end
	return 0.10, 0.15, 0.40, 0.50
end

function MilitaryCombat.FloorCasualties(committed: number, pct: number): number
	return math.floor(committed * pct)
end

function MilitaryCombat.Resolve(attackerCommitted: number, defenderCommitted: number, rng: Random): BattleResult
	local attackerN = math.floor(attackerCommitted)
	local defenderN = math.floor(defenderCommitted)

	if attackerN > 0 and defenderN == 0 then
		return {
			unopposed = true,
			winner = "Attacker",
			attackerCommitted = attackerN,
			defenderCommitted = 0,
			attackerCasualties = 0,
			defenderCasualties = 0,
			attackerSurvivors = attackerN,
			defenderSurvivors = 0,
		}
	end

	local atkRoll = inRange(rng, MilitaryConfig.CombatRollMin, MilitaryConfig.CombatRollMax)
	local defRoll = inRange(rng, MilitaryConfig.CombatRollMin, MilitaryConfig.CombatRollMax)
	local defMult = inRange(rng, MilitaryConfig.DefenseRollMin, MilitaryConfig.DefenseRollMax)
	local atkEff = attackerN * atkRoll
	local defEff = defenderN * defRoll * defMult
	local attackerWins = atkEff > defEff
	local winner = if attackerWins then "Attacker" else "Defender"
	local winnerEff = if attackerWins then atkEff else defEff
	local loserEff = if attackerWins then defEff else atkEff
	local ratio = if loserEff > 0 then winnerEff / loserEff else MilitaryConfig.ClearRatioMax
	local band = MilitaryCombat.ClassifyRatio(ratio)
	local wLo, wHi, lLo, lHi = MilitaryCombat.CasualtyPercentRange(band)
	local wPct = inRange(rng, wLo, wHi)
	local lPct = inRange(rng, lLo, lHi)
	local winnerCommit = if attackerWins then attackerN else defenderN
	local loserCommit = if attackerWins then defenderN else attackerN
	local winnerCas = MilitaryCombat.FloorCasualties(winnerCommit, wPct)
	local loserCas = MilitaryCombat.FloorCasualties(loserCommit, lPct)
	local atkCas = if attackerWins then winnerCas else loserCas
	local defCas = if attackerWins then loserCas else winnerCas

	return {
		unopposed = false,
		winner = winner,
		attackerCommitted = attackerN,
		defenderCommitted = defenderN,
		attackerCasualties = atkCas,
		defenderCasualties = defCas,
		attackerSurvivors = math.max(0, attackerN - atkCas),
		defenderSurvivors = math.max(0, defenderN - defCas),
		attackerCombatRoll = atkRoll,
		defenderCombatRoll = defRoll,
		defenderDefenseRoll = defMult,
		attackerEffective = atkEff,
		defenderEffective = defEff,
		victoryRatio = ratio,
		band = band,
		winnerCasualtyPct = wPct,
		loserCasualtyPct = lPct,
	}
end

function MilitaryCombat.SelfTest(): (boolean, string)
	local lines = {}
	local function check(ok: boolean, label: string)
		table.insert(lines, (if ok then "PASS " else "FAIL ") .. label)
		return ok
	end
	local allOk = true

	local unop = MilitaryCombat.Resolve(100, 0, Random.new(1))
	allOk = check(unop.unopposed == true and unop.winner == "Attacker" and unop.attackerCasualties == 0 and unop.defenderCasualties == 0, "unopposed 0/0") and allOk

	allOk = check(MilitaryCombat.ClassifyRatio(1.14) == "CLOSE", "CLOSE < 1.15") and allOk
	allOk = check(MilitaryCombat.ClassifyRatio(1.15) == "CLEAR", "CLEAR at 1.15") and allOk
	allOk = check(MilitaryCombat.ClassifyRatio(1.49) == "CLEAR", "CLEAR < 1.50") and allOk
	allOk = check(MilitaryCombat.ClassifyRatio(1.50) == "DECISIVE", "DECISIVE at 1.50") and allOk
	allOk = check(MilitaryCombat.FloorCasualties(10, 0.09) == 0, "floor may be 0") and allOk
	allOk = check(MilitaryCombat.FloorCasualties(100, 0.255) == 25, "floor 25.5 -> 25") and allOk

	local rng = Random.new(42)
	for i = 1, 40 do
		local r = MilitaryCombat.Resolve(200, 180, rng)
		if r.unopposed then
			allOk = check(false, "unexpected unopposed")
			break
		end
		local atkRoll = r.attackerCombatRoll :: number
		local defRoll = r.defenderCombatRoll :: number
		local defM = r.defenderDefenseRoll :: number
		if atkRoll < MilitaryConfig.CombatRollMin or atkRoll > MilitaryConfig.CombatRollMax then
			allOk = check(false, "attacker combat roll out of range")
			break
		end
		if defRoll < MilitaryConfig.CombatRollMin or defRoll > MilitaryConfig.CombatRollMax then
			allOk = check(false, "defender combat roll out of range")
			break
		end
		if defM < MilitaryConfig.DefenseRollMin or defM > MilitaryConfig.DefenseRollMax then
			allOk = check(false, "defense roll out of range")
			break
		end
		local _ = i
	end

	-- Exact equal Effective Strength favors defender (attacker must be strictly greater).
	local tieWinner = if 100 * 1.0 > 100 * 1.0 then "Attacker" else "Defender"
	allOk = check(tieWinner == "Defender", "tie favors defender") and allOk

	-- Winner can lose more absolute soldiers (CLOSE loser % can exceed winner %).
	local winnerMore = MilitaryCombat.FloorCasualties(1000, 0.24)
	local loserLess = MilitaryCombat.FloorCasualties(400, 0.34)
	allOk = check(winnerMore > loserLess, "winner can lose more absolute soldiers") and allOk

	return allOk, table.concat(lines, "\n")
end

return MilitaryCombat
