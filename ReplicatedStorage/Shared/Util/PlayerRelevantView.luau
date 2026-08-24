--!strict

--[[
	Player-facing view helpers. Not authority. Does not change server snapshots.
	Admin/debug inspection must not use this filter.
]]

local PlayerRelevantView = {}

function PlayerRelevantView.LocalRootRulerId(rulers: { any }, userId: number): string?
	if typeof(userId) ~= "number" then
		return nil
	end
	for _, ruler in rulers do
		if tonumber(ruler.userId) == userId then
			if typeof(ruler.rootRulerId) == "string" and ruler.rootRulerId ~= "" then
				return ruler.rootRulerId
			end
			if typeof(ruler.rulerId) == "string" and ruler.rulerId ~= "" then
				return ruler.rulerId
			end
			return nil
		end
	end
	return nil
end

function PlayerRelevantView.WarInvolvesRoot(war: any, localRootId: string): boolean
	if typeof(localRootId) ~= "string" or localRootId == "" or typeof(war) ~= "table" then
		return false
	end
	return war.attackerRootId == localRootId or war.defenderRootId == localRootId
end

function PlayerRelevantView.FilterWarsForLocalRoot(wars: { any }, localRootId: string?): { any }
	local out = {}
	if typeof(localRootId) ~= "string" or localRootId == "" or typeof(wars) ~= "table" then
		return out
	end
	for _, war in wars do
		if PlayerRelevantView.WarInvolvesRoot(war, localRootId) then
			table.insert(out, war)
		end
	end
	return out
end

return PlayerRelevantView
