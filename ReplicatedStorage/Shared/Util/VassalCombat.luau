--!strict
-- Pure hierarchy modifiers. Call with authoritative relationships at resolution.
local Config = require(script.Parent.Parent.Config.MilitaryConfig)
local VassalCombat = {}

function VassalCombat.Bonuses(rulerId: string, rulers: { any }): any
	local me, liege = nil, nil
	for _, ruler in rulers do
		if ruler.rulerId == rulerId then me = ruler; break end
	end
	if me and me.liegeId ~= "" then
		for _, ruler in rulers do
			if ruler.rulerId == me.liegeId then liege = ruler; break end
		end
	end
	local ownCount = if me then #me.vassalIds else 0
	return {
		subjectBonus = if liege then Config.SubjectCombatBase + Config.SubjectCombatPerLiegeSubject * #liege.vassalIds else 0,
		personalDefenseBonus = Config.PersonalDefensePerSubject * ownCount,
	}
end

function VassalCombat.Multiplier(bonuses: any, defending: boolean, personallyOwned: boolean): number
	return (1 + bonuses.subjectBonus) * (1 + (if defending and personallyOwned then bonuses.personalDefenseBonus else 0))
end

function VassalCombat.Describe(bonuses: any): string
	return string.format("Subject combat: +%g%%\nPersonal-land defense: +%g%%", bonuses.subjectBonus * 100, bonuses.personalDefenseBonus * 100)
		.. "\nDefense applies only when you defend your own province. Bonuses multiply; checked at resolution."
end

return VassalCombat
