--!strict
-- No seat margin/timer: submission compares current personal authority strictly.
local Policy = {}
function Policy.Effective(ruler: any?, own: number?, liege: number?, grants: any, ended: boolean): any
	local independent = ruler ~= nil and ruler.independent == true
	local stronger = not independent and ruler ~= nil and own ~= nil and liege ~= nil and own > liege
	local function capability(key: string): (boolean, string)
		if ended then return false, "Match ended" end
		if not ruler then return false, "No ruler record" end
		if independent then return true, "Independent ruler" end
		if grants[key] == true then return true, "Granted by your direct liege" end
		if stronger then return true, "Autonomy: stronger than your direct liege" end
		return false, "Denied by your direct liege; stronger-subject autonomy unavailable"
	end
	local war, warReason = capability("War")
	local diplomacy, diplomacyReason = capability("Diplomacy")
	return { war = war, warReason = warReason, diplomacy = diplomacy, diplomacyReason = diplomacyReason,
		autonomy = stronger, betrayal = stronger and not ended, independent = independent }
end
return Policy
