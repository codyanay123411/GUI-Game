--!strict
-- Shared server-only gate. VictoryService alone ends the match.
local MatchState = {}
local final: any = nil
local councilFreeze: ((number) -> ())? = nil

function MatchState.SetCouncilFreeze(callback: (number) -> ())
	assert(councilFreeze == nil, "Council freeze already installed")
	councilFreeze = callback
end

local prestigeFreeze: ((number) -> ())? = nil

function MatchState.SetPrestigeFreeze(callback: (number) -> ())
	assert(prestigeFreeze == nil, "Prestige freeze already installed")
	prestigeFreeze = callback
end

function MatchState.IsEnded(): boolean
	return final ~= nil
end

function MatchState.GetFinal(): any
	return final
end

function MatchState.End(snapshot: any): boolean
	if final then return false end
	final = snapshot
	if prestigeFreeze then prestigeFreeze(snapshot.endedAt) end
	if councilFreeze then councilFreeze(snapshot.endedAt) end
	return true
end

return MatchState
