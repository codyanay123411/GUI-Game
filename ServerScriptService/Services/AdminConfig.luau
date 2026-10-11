--!strict

-- Server-only GameTester authority. Client rank/attributes are never authority.
-- Preserve the Studio-only synthetic UserId convenience.
local RunService = game:GetService("RunService")
local AdminConfig = {}
local PROJECT_OWNER_USER_ID = 106676397

AdminConfig.GameTesterUserIds = {
	PROJECT_OWNER_USER_ID, -- Existing Director/owner account
	2646795710, -- ffrjfss
	701857, -- coolguy2323
	470733, -- iceboy10
	555636491, -- nooblyklll
}

function AdminConfig.IsGameTester(userId: number): boolean
	if not RunService:IsServer() or typeof(userId) ~= "number"
		or userId ~= userId or math.abs(userId) == math.huge or userId ~= math.floor(userId) then
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
	local interface = shared._K_INTERFACE
	if typeof(interface) ~= "table" or interface.IsServer ~= true then
		return false
	end
	local auth, data = interface.Auth, interface.Data
	local roles = if typeof(data) == "table" then data.roles else nil
	local role = if typeof(roles) == "table" then roles.superadmin else nil
	if typeof(auth) ~= "table" or typeof(auth.getRank) ~= "function"
		or typeof(role) ~= "table" or typeof(role._rank) ~= "number"
		or role._rank ~= role._rank or role._rank == math.huge or role._rank <= 0 then
		return false
	end
	local ok, rank = pcall(auth.getRank, userId)
	return ok and typeof(rank) == "number" and rank >= role._rank
end

function AdminConfig.CanConfigureGame(userId: number): boolean
	if not RunService:IsServer() or typeof(userId) ~= "number" or userId <= 0 or userId ~= math.floor(userId) or userId == math.huge then return false end
	if userId == PROJECT_OWNER_USER_ID then return true end
	if game.CreatorType == Enum.CreatorType.User then return userId == game.CreatorId end
	-- Kohl resolves the group experience owner on the server; never infer ownership from rank.
	local interface = shared._K_INTERFACE
	return typeof(interface) == "table" and interface.IsServer == true and userId == interface.creatorId
end

return AdminConfig
