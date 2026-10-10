--!strict
-- Shared server-only gate. VictoryService alone ends the match.
local MatchState = {}
local final: any = nil

function MatchState.IsEnded(): boolean
	return final ~= nil
end

function MatchState.GetFinal(): any
	return final
end

function MatchState.End(snapshot: any): boolean
	if final then return false end
	final = snapshot
	return true
end

return MatchState
