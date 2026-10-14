--!strict
-- Membership and server-only authority observation. Seats grant no powers; chat is unchanged.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local Hierarchy = require(script.Parent.PoliticalHierarchyService)
local Territory = require(script.Parent.TerritoryMapService)
local Military = require(script.Parent.MilitaryService)
local MatchState = require(script.Parent.MatchState)
local Config = require(script.Parent.PoliticalAuthorityConfig)
local Policy = require(script.Parent.PoliticalCouncilPolicy)
local Service = {}
local authorityChanged = Instance.new("BindableEvent")
Service.AuthorityChanged = authorityChanged.Event
local started, frozen = false, false
local rulers, councils, dueByCouncil, conquerable = {}, {}, {}, {}
local leaving: { [number]: boolean } = {}
local push: RemoteEvent
local lastPayload: { [Player]: string } = {}

local function now(): number return workspace:GetServerTimeNow() end
local function candidateRows(liegeId: string): { any }
	local rows = {}
	for id, ruler in rulers do
		if Policy.Eligible(ruler, liegeId) then
			table.insert(rows, { id = id, authority = Policy.Authority(ruler.land, Military.GetTotalTroops(id), Config) })
		end
	end
	return rows
end
local function evaluate(id: string, at: number)
	if not rulers[id] then councils[id], dueByCouncil[id] = nil, nil; return end
	local council = councils[id] or Policy.New()
	councils[id] = council
	local _, due = Policy.Evaluate(council, candidateRows(id), at, Config)
	dueByCouncil[id] = due
end
local function publicCouncil(id: string): any
	local ruler = rulers[id]
	local members = {}
	local council = councils[id]
	if council then
		for _, memberId in council.members do
			local member = rulers[memberId]
			if member then table.insert(members, { rulerId = memberId, displayName = member.displayName, titleName = member.titleName }) end
		end
	end
	-- Alphabetical presentation reveals neither score nor seat/replacement order.
	table.sort(members, function(a, b)
		return if a.displayName == b.displayName then a.rulerId < b.rulerId else a.displayName < b.displayName
	end)
	return { rulerId = id, displayName = ruler.displayName, titleName = ruler.titleName, members = members }
end
function Service.GetForPlayer(player: Player): any
	local viewerId = Hierarchy.GetRulerIdForUserId(player.UserId)
	local rows = {}
	local audience = rulers
	if not frozen then
		audience = {}
		for _, ruler in Hierarchy.GetSnapshot().rulers do audience[ruler.rulerId] = ruler end
	end
	for _, id in Policy.VisibleCouncilIds(viewerId, audience) do
		if rulers[id] then table.insert(rows, publicCouncil(id)) end
	end
	return { councils = rows, frozen = frozen, seatLimit = Config.SeatLimit }
end
local function pushPlayer(player: Player, force: boolean?)
	local payload = HttpService:JSONEncode(Service.GetForPlayer(player))
	if force or lastPayload[player] ~= payload then
		lastPayload[player] = payload
		push:FireClient(player, "State", payload)
	end
end
local function pushAll()
	for _, player in Players:GetPlayers() do pushPlayer(player) end
end
-- Synchronous service observers prevent lost intermediate transitions under deferred
-- Roblox signals. Compare compact projections, evaluating affected direct-liege councils.
local function refresh(at: number)
	local nextRulers, affected = {}, {}
	for _, ruler in Hierarchy.GetSnapshot().rulers do
		local land = 0
		for _, id in Territory.GetOwnedTerritoryIds(ruler.rulerId) do if conquerable[id] then land += 1 end end
		local connected = ruler.hasUser and not leaving[ruler.userId] and Players:GetPlayerByUserId(ruler.userId) ~= nil
		local row = { liegeId = ruler.liegeId, land = land, connected = connected, active = connected,
			displayName = ruler.displayName, titleName = ruler.titleName }
		nextRulers[ruler.rulerId] = row
		local previous = rulers[ruler.rulerId]
		if not previous or previous.liegeId ~= row.liegeId or previous.land ~= land or previous.connected ~= connected then
			affected[ruler.rulerId] = true
			if row.liegeId ~= "" then affected[row.liegeId] = true end
			if previous and previous.liegeId ~= "" then affected[previous.liegeId] = true end
		end
	end
	for id, previous in rulers do
		if not nextRulers[id] then
			affected[id] = true
			if previous.liegeId ~= "" then affected[previous.liegeId] = true end
		end
	end
	rulers = nextRulers
	for id in affected do evaluate(id, at) end
	authorityChanged:Fire()
	pushAll()
end
function Service.GetAuthority(rulerId: string): number?
	local ruler = rulers[rulerId]
	if not ruler then return nil end
	return Policy.Authority(ruler.land, Military.GetTotalTroops(rulerId), Config)
end
function Service.GetCouncilMembers(rulerId: string): { string }
	local council = councils[rulerId]
	return if council then table.clone(council.members) else {}
end
local function freeze(at: number)
	if frozen then return end
	refresh(at) -- Capture pending authoritative changes before freezing final membership.
	for id in rulers do evaluate(id, at) end
	frozen = true
	dueByCouncil = {}
	pushAll()
end
function Service.Start()
	if started then return end
	started = true
	Policy.Validate(Config)
	for _, province in Territory.GetMapDefinition().territories do conquerable[province.id] = province.conquerable ~= false end
	local remotes = ReplicatedStorage:WaitForChild("Remotes")
	local function remote(name: string): RemoteEvent
		local item = remotes:FindFirstChild(name)
		if not item then item = Instance.new("RemoteEvent"); item.Name = name; item.Parent = remotes end
		assert(item:IsA("RemoteEvent"), "Invalid council remote " .. name)
		return item
	end
	push = remote("CouncilServerEvent")
	remote("CouncilClientEvent").OnServerEvent:Connect(function(player, action)
		if action == "Ready" then pushPlayer(player, true) end -- No target or mutation intent.
	end)
	MatchState.SetCouncilFreeze(freeze)
	local function changed()
		if frozen or MatchState.IsEnded() then return end
		refresh(now())
	end
	Hierarchy.SetCouncilRefresh(changed)
	Territory.SetCouncilRefresh(changed)
	Military.SetCouncilTotalChanged(function(id: string)
		if frozen or MatchState.IsEnded() then return end
		local ruler = rulers[id]
		if ruler and ruler.liegeId ~= "" then evaluate(ruler.liegeId, now()); pushAll() end
		authorityChanged:Fire()
	end)
	Players.PlayerRemoving:Connect(function(player)
		lastPayload[player] = nil
		if frozen or MatchState.IsEnded() then return end
		leaving[player.UserId] = true
		changed()
	end)
	Players.PlayerAdded:Connect(function(player)
		leaving[player.UserId] = nil
		if not frozen and not MatchState.IsEnded() then changed() end
		task.defer(function() if player.Parent then pushPlayer(player, true) end end)
	end)
	refresh(now())
	if MatchState.IsEnded() then freeze(MatchState.GetFinal().endedAt) end
	task.spawn(function()
		while not frozen do
			task.wait(Config.EvaluationIntervalSeconds)
			if frozen or MatchState.IsEnded() then break end
			local at, evaluated = now(), false
			for id, due in dueByCouncil do
				if due <= at then evaluate(id, at); evaluated = true end
			end
			if evaluated then pushAll() end
		end
	end)
end
return Service
