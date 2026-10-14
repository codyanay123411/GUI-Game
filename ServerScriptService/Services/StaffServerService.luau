--!strict
-- Staff routing only. No GameTester/admin mutations; access codes never reach clients/logs.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local MemoryStoreService = game:GetService("MemoryStoreService")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local Auth = require(script.Parent.AdminConfig)
local Policy = require(script.Parent.StaffServerPolicy)
local Match = require(script.Parent.MatchState)
local Service = {}
local started = false
local registry = MemoryStoreService:GetSortedMap("StrategyActiveServers_v1_" .. tostring(game.GameId))
local credentials = MemoryStoreService:GetHashMap("StrategyReservedCredentials_v1_" .. tostring(game.GameId))
local flights: { [Player]: any } = {}
local lastRequest: { [Player]: number } = {}
local function notify(player: Player, message: string)
	local k = shared._K_INTERFACE
	if k and k.Remote and k.Remote.Notify then k.Remote.Notify:Fire(player, { Text = message }) end
end
local function admit(player: Player): (boolean, string)
	if player.Parent ~= Players or not Auth.IsStaff(player.UserId) then return false, "Staff authorization required." end
	if RunService:IsStudio() then return false, "Server discovery and joins require the published Roblox client; Studio has no routable JobId." end
	if os.clock()-(lastRequest[player] or -math.huge)<3 then return false, "Please wait before requesting servers again." end
	lastRequest[player] = os.clock()
	return true, ""
end
local function reservedCode(privateId: string, placeId: number): string?
	local ok, row = pcall(function() return credentials:GetAsync(privateId) end)
	return if ok and typeof(row) == "table" and row.placeId == placeId and typeof(row.code) == "string" then row.code else nil
end
-- Trusted server integration for a creator that already owns a reserved access code.
-- Never accept credentials from a player, teleport data, attribute or client remote.
function Service.RegisterReservedCredential(privateId: string, code: string, destinationPlaceId: number?): boolean
	assert(typeof(privateId) == "string" and privateId ~= "" and typeof(code) == "string" and code ~= "")
	if RunService:IsStudio() then return false end
	local placeId = destinationPlaceId or game.PlaceId
	assert(placeId > 0 and placeId % 1 == 0 and placeId < math.huge)
	local ok = pcall(function() credentials:SetAsync(privateId, { code = code, placeId = placeId }, 86400) end)
	return ok
end
function Service.List(player: Player): (boolean, any)
	local ok, message = admit(player);if not ok then return false, message end
	local success, entries = pcall(function() return registry:GetRangeAsync(Enum.SortDirection.Descending, 100) end)
	if not success then return false, "Active-server registry is unavailable. Try again later." end
	if player.Parent ~= Players or not Auth.IsStaff(player.UserId) then return false, "Staff authorization changed." end
	local rows = {}
	for _, entry in entries do
		if Policy.Fresh(entry.value, os.time()) then table.insert(rows, Policy.Public(entry.value)) end
	end
	return true, rows
end
function Service.Join(player: Player, id: string): (boolean, string)
	local ok, message = admit(player);if not ok then return false, message end
	if flights[player] then return false, "A server join is already pending." end
	if typeof(id) ~= "string" or #id > 100 or id == "" then return false, "Use an instance ID from strategyservers." end
	if id == game.JobId then return false, "You are already in that server." end
	local success, row = pcall(function() return registry:GetAsync(id) end)
	if not success then return false, "Destination lookup failed. Refresh strategyservers." end
	if not Policy.Fresh(row, os.time()) then return false, "Server is closed or its heartbeat expired. Refresh strategyservers." end
	if typeof(row.placeId) ~= "number" or row.placeId <= 0 or row.placeId % 1 ~= 0 or row.placeId == math.huge then return false, "Destination has invalid routing metadata. Refresh strategyservers." end
	-- Recheck authorization after every yielding lookup.
	if player.Parent ~= Players or not Auth.IsStaff(player.UserId) then return false, "Staff authorization changed." end
	local code = if row.kind == "Reserved" then reservedCode(row.privateId, row.placeId) else nil
	local route, reason = Policy.Route(row, code);if not route then return false, reason end
	if player.Parent ~= Players or not Auth.IsStaff(player.UserId) then return false, "Staff authorization changed." end
	local token = HttpService:GenerateGUID(false)
	if flights[player] then return false, "A server join is already pending." end
	local options = Instance.new("TeleportOptions")
	if route == "Reserved" then options.ReservedServerAccessCode = code :: string else options.ServerInstanceId = id end
	options:SetTeleportData({ staffJoinToken = token }) -- Correlation only, never a credential or permission.
	flights[player] = { token = token, options = options, placeId = row.placeId }
	local sent = pcall(function() TeleportService:TeleportAsync(row.placeId, { player }, options) end)
	if not sent then flights[player] = nil;return false, "Roblox could not start this join. The destination may be closed, full or inaccessible. Retry after refreshing." end
	task.delay(60, function()
		local current = flights[player]
		if current and current.token == token and player.Parent == Players then
			flights[player] = nil
			notify(player, "No completed transfer was confirmed. You are still here; refresh strategyservers before retrying.")
		end
	end)
	return true, "Join requested. Closed public instances may cause Roblox to select a replacement. Reserved routing follows Roblox's platform partition; private credentials/access cannot be bypassed."
end
local function heartbeat()
	if RunService:IsStudio() or game.JobId == "" then return end
	local kind = Policy.Kind(game.PrivateServerId, game.PrivateServerOwnerId)
	local code = if kind == "Reserved" then reservedCode(game.PrivateServerId, game.PlaceId) else nil
	local row = { id = game.JobId, placeId = game.PlaceId, kind = kind, privateId = game.PrivateServerId, players = #Players:GetPlayers(), capacity = Players.MaxPlayers,
		updatedAt = os.time(), ended = Match.IsEnded(), joinable = kind == "Public" or (kind == "Reserved" and code ~= nil),
		note = if kind == "Private" then "Owner invitation required" elseif kind == "Reserved" and not code then "Credential unavailable" else "Roblox validates destination access" }
	local ok = pcall(function() registry:SetAsync(game.JobId, row, Policy.ExpirySeconds, row.updatedAt) end)
	if not ok then warn("[StaffServers] heartbeat unavailable; entry will expire") end
end
function Service.Start()
	if started then return end;started = true
	-- Safe browser metadata; discovery credentials and join authority stay server-only.
	game:GetService("ReplicatedStorage"):SetAttribute("_CurrentServerJobId", game.JobId)
	game:GetService("ReplicatedStorage"):SetAttribute("_CurrentServerStudio", RunService:IsStudio())
	game:GetService("ReplicatedStorage"):SetAttribute("_CurrentServerKind", Policy.Kind(game.PrivateServerId, game.PrivateServerOwnerId))
	game:GetService("ReplicatedStorage"):SetAttribute("_CurrentServerStartedAt", os.time() - math.floor(workspace.DistributedGameTime))
	TeleportService.TeleportInitFailed:Connect(function(player, _, _, placeId, options)
		local flight = flights[player]
		if not flight or placeId ~= flight.placeId or not options then return end
		local ok, data = pcall(function() return options:GetTeleportData() end)
		if ok and typeof(data) == "table" and data.staffJoinToken == flight.token then
			flights[player] = nil;notify(player, "Server join failed: destination closed, full or inaccessible. Refresh strategyservers and retry.")
		end
	end)
	Players.PlayerRemoving:Connect(function(player) flights[player] = nil;lastRequest[player] = nil end)
	task.spawn(function() while started do heartbeat();task.wait(Policy.HeartbeatSeconds) end end)
	game:BindToClose(function() started = false;if not RunService:IsStudio() and game.JobId ~= "" then pcall(function() registry:RemoveAsync(game.JobId) end) end end)
end
return Service
