--!strict

--[[
	Server-only allowlist for game-state testing commands.
	Kohl's Admin roles are not sufficient by themselves.

	Studio Local Server clients use synthetic negative UserIds (-1, -2, …).
	Those may pass IsGameTester only while RunService:IsStudio() is true.
	That is a Studio testing convenience, not production authorization.
	Do not put -1/-2/-3 on GameTesterUserIds.
]]

local RunService = game:GetService("RunService")

local AdminConfig = {}

AdminConfig.GameTesterUserIds = {
	106676397, -- Director account used in current Studio testing
}

function AdminConfig.IsGameTester(userId: number): boolean
	if typeof(userId) ~= "number" then
		return false
	end
	if RunService:IsStudio() and userId < 0 then
		return true
	end
	for _, id in AdminConfig.GameTesterUserIds do
		if id == userId then
			return true
		end
	end
	return false
end

return AdminConfig
