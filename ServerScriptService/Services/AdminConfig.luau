--!strict

--[[
	Server-only allowlist for game-state testing commands.
	Kohl's Admin roles are not sufficient by themselves.
]]

local AdminConfig = {}

-- Immutable UserId list. Studio Local Server clients often use -1/-2/-3;
-- add those explicitly if Kohl commands must work in that mode.
AdminConfig.GameTesterUserIds = {
	106676397, -- Director account used in current Studio testing
}

function AdminConfig.IsGameTester(userId: number): boolean
	if typeof(userId) ~= "number" then
		return false
	end
	for _, id in AdminConfig.GameTesterUserIds do
		if id == userId then
			return true
		end
	end
	return false
end

return AdminConfig
