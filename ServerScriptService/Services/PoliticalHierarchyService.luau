--!strict

--[[
	Authoritative political hierarchy for V0.1.

	Human players become Independent Lords on join.
	Voluntary vassalage requires both parties and server-side validation.
	Subordinate trees are preserved (only the joining ruler's liege changes).
	Disconnect cleanup is temporary prototype behavior: the leaving ruler's
	runtime record is removed; remaining trees stay valid. No AI replacement,
	reconnection, succession, or persistence.
]]

local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Config = require(ReplicatedStorage.Shared.Config.PoliticalHierarchyConfig)
local RankRules = require(ReplicatedStorage.Shared.Util.PoliticalRankRules)

type Ruler = {
	rulerId: string,
	userId: number?,
	player: Player?,
	displayName: string,
	titleRank: number,
	liegeId: string?,
	vassalIds: { [string]: boolean },
	isMock: boolean,
}

type FealtyRequest = {
	requestId: string,
	fromRulerId: string,
	toRulerId: string,
	createdAt: number,
	expiresAt: number,
	expireThread: thread?,
}

local MatchState = require(script.Parent.MatchState)
local PoliticalHierarchyService = {}

local started = false
local rulersById: { [string]: Ruler } = {}
local rulerIdByUserId: { [number]: string } = {}
local requestsById: { [string]: FealtyRequest } = {}

local remotesFolder: Folder
local clientIntent: RemoteEvent
local serverPush: RemoteEvent
local debugSnapshot: StringValue?

local prestigeCreated: ((string, number) -> ())? = nil
local prestigeRemoving: ((string, number) -> ())? = nil
-- Synchronous lifecycle accounting; public Bindable notifications may be deferred.
function PoliticalHierarchyService.SetPrestigeLifecycleAccounting(created: (string, number) -> (), removing: (string, number) -> ())
	assert(prestigeCreated == nil and prestigeRemoving == nil, "Prestige lifecycle accounting already installed")
	prestigeCreated, prestigeRemoving = created, removing
end

local rulerCreatedBindable = Instance.new("BindableEvent")
local rulerRemovingBindable = Instance.new("BindableEvent")
local stateChangedBindable = Instance.new("BindableEvent")
PoliticalHierarchyService.RulerCreated = rulerCreatedBindable.Event
PoliticalHierarchyService.RulerRemoving = rulerRemovingBindable.Event
PoliticalHierarchyService.StateChanged = stateChangedBindable.Event

local function now(): number
	return os.clock()
end

local function listKeys(set: { [string]: boolean }): { string }
	local list = {}
	for id in set do
		table.insert(list, id)
	end
	table.sort(list)
	return list
end

local function collectDescendants(root: Ruler): { string }
	local result = {}
	local queue = { root.rulerId }
	local seen: { [string]: boolean } = { [root.rulerId] = true }
	local i = 1
	while i <= #queue do
		local current = rulersById[queue[i]]
		i += 1
		if current then
			for vassalId in current.vassalIds do
				if not seen[vassalId] then
					seen[vassalId] = true
					table.insert(result, vassalId)
					table.insert(queue, vassalId)
				end
			end
		end
	end
	table.sort(result)
	return result
end

local function isInSubtree(rootId: string, maybeDescendantId: string): boolean
	if rootId == maybeDescendantId then
		return true
	end
	local root = rulersById[rootId]
	if not root then
		return false
	end
	for _, id in collectDescendants(root) do
		if id == maybeDescendantId then
			return true
		end
	end
	return false
end

local function getRootId(rulerId: string): string
	local current = rulersById[rulerId]
	local guard = 0
	while current and current.liegeId and guard < 64 do
		local liege = rulersById[current.liegeId]
		if not liege then
			break
		end
		current = liege
		guard += 1
	end
	return if current then current.rulerId else rulerId
end

local function snapshotRuler(ruler: Ruler)
	-- Avoid nil fields: RemoteEvents can drop table payloads in multi-client Studio.
	return {
		rulerId = ruler.rulerId,
		userId = ruler.userId or 0,
		hasUser = ruler.userId ~= nil,
		displayName = ruler.displayName,
		titleRank = ruler.titleRank,
		titleName = RankRules.Name(ruler.titleRank),
		liegeId = ruler.liegeId or "",
		independent = ruler.liegeId == nil,
		vassalIds = listKeys(ruler.vassalIds),
		descendantIds = collectDescendants(ruler),
		rootRulerId = getRootId(ruler.rulerId),
	}
end

local function buildSnapshot()
	local rulers = {}
	for _, ruler in rulersById do
		table.insert(rulers, snapshotRuler(ruler))
	end
	table.sort(rulers, function(a, b)
		return a.displayName < b.displayName
	end)
	local requests = {}
	local t = now()
	for _, request in requestsById do
		if request.expiresAt > t then
			table.insert(requests, {
				requestId = request.requestId,
				fromRulerId = request.fromRulerId,
				toRulerId = request.toRulerId,
				expiresAt = request.expiresAt,
			})
		end
	end
	return {
		rulers = rulers,
		requests = requests,
	}
end

local councilRefresh: (() -> ())? = nil
local permissionsRefresh: (() -> ())? = nil
local diplomacyRefresh: (() -> ())? = nil
local warfareRefresh: (() -> ())? = nil
function PoliticalHierarchyService.SetDiplomacyRefresh(callback: () -> ())
	assert(diplomacyRefresh == nil, "Diplomacy refresh already installed")
	diplomacyRefresh = callback
end
function PoliticalHierarchyService.SetWarfareRefresh(callback: () -> ())
	assert(warfareRefresh == nil, "Warfare refresh already installed")
	warfareRefresh = callback
end
function PoliticalHierarchyService.SetPermissionsRefresh(callback: () -> ())
	assert(permissionsRefresh == nil, "Permissions refresh already installed")
	permissionsRefresh = callback
end
function PoliticalHierarchyService.SetCouncilRefresh(callback: () -> ())
	assert(councilRefresh == nil, "Council refresh already installed")
	councilRefresh = callback
end

local function pushState(toPlayer: Player?)
	local payload = buildSnapshot()
	local encoded = HttpService:JSONEncode(payload)
	if debugSnapshot then
		debugSnapshot.Value = encoded
	end
	local n = #payload.rulers
	if toPlayer then
		print("[Hierarchy] push State to", toPlayer.Name, "rulers=", n, "requests=", #payload.requests)
		MatchState.Send(serverPush, toPlayer, "State", encoded)
	else
		print("[Hierarchy] push State all clients rulers=", n, "requests=", #payload.requests)
		MatchState.Send(serverPush, nil, "State", encoded)
	end
	if councilRefresh then councilRefresh() end
	if permissionsRefresh then permissionsRefresh() end
	if diplomacyRefresh then diplomacyRefresh() end
	if warfareRefresh then warfareRefresh() end
	stateChangedBindable:Fire()
	require(script.Parent.VictoryService).Evaluate()
end

local function notice(player: Player, message: string)
	print("[Hierarchy] notice ->", player.Name, message)
	MatchState.Send(serverPush, player, "Notice", message)
end

local function noticeRuler(ruler: Ruler?, message: string)
	local target = ruler and ruler.player
	if target and target.Parent then
		notice(target, message)
	end
end

local function cancelExpire(request: FealtyRequest)
	local thread = request.expireThread
	request.expireThread = nil
	if thread then
		pcall(function()
			task.cancel(thread)
		end)
	end
end

local function removeRequest(requestId: string)
	local request = requestsById[requestId]
	if not request then
		return
	end
	cancelExpire(request)
	requestsById[requestId] = nil
end

local function supersedePair(fromRulerId: string, toRulerId: string)
	for id, request in requestsById do
		if request.fromRulerId == fromRulerId and request.toRulerId == toRulerId then
			removeRequest(id)
		end
	end
end

local function detachFromLiege(ruler: Ruler)
	local liegeId = ruler.liegeId
	if not liegeId then
		return
	end
	local liege = rulersById[liegeId]
	if liege then
		liege.vassalIds[ruler.rulerId] = nil
	end
	ruler.liegeId = nil
end

local function attachVassal(liege: Ruler, vassal: Ruler)
	detachFromLiege(vassal)
	vassal.liegeId = liege.rulerId
	liege.vassalIds[vassal.rulerId] = true
end

local function removeRulerInternal(rulerId: string)
	if MatchState.IsEnded() then return end
	local ruler = rulersById[rulerId]
	if not ruler then
		return
	end
	if prestigeRemoving then prestigeRemoving(ruler.rulerId, workspace:GetServerTimeNow()) end
	rulerRemovingBindable:Fire(ruler.rulerId)
	detachFromLiege(ruler)
	for vassalId in ruler.vassalIds do
		local vassal = rulersById[vassalId]
		if vassal then
			vassal.liegeId = nil
		end
	end
	for requestId, request in requestsById do
		if request.fromRulerId == rulerId or request.toRulerId == rulerId then
			removeRequest(requestId)
		end
	end
	if ruler.userId then
		rulerIdByUserId[ruler.userId] = nil
	end
	rulersById[rulerId] = nil
end

local function createRuler(props: {
	rulerId: string,
	userId: number?,
	player: Player?,
	displayName: string,
	titleRank: number,
	isMock: boolean,
}, quiet: boolean?): Ruler
	local ruler: Ruler = {
		rulerId = props.rulerId,
		userId = props.userId,
		player = props.player,
		displayName = props.displayName,
		titleRank = props.titleRank,
		liegeId = nil,
		vassalIds = {},
		isMock = props.isMock,
	}
	rulersById[ruler.rulerId] = ruler
	if ruler.userId then
		rulerIdByUserId[ruler.userId] = ruler.rulerId
	end
	print("[Hierarchy] ruler created", ruler.displayName, "userId=", tostring(ruler.userId), "id=", ruler.rulerId)
	if prestigeCreated then prestigeCreated(ruler.rulerId, workspace:GetServerTimeNow()) end
	if not quiet then rulerCreatedBindable:Fire(ruler.rulerId, ruler.userId) end
	return ruler
end

local function validateFealty(fromRulerId: string, toRulerId: string): (boolean, string)
	if fromRulerId == toRulerId then
		return false, "Cannot offer vassalage to yourself."
	end
	local fromRuler = rulersById[fromRulerId]
	local toRuler = rulersById[toRulerId]
	if not fromRuler or not toRuler then
		return false, "Ruler no longer exists."
	end
	if fromRuler.liegeId == toRulerId then
		return false, "That direct relationship already exists."
	end
	if not RankRules.CanBecomeVassalOf(fromRuler.titleRank, toRuler.titleRank) then
		return false, "Cannot become the vassal of a lower-ranked ruler."
	end
	if isInSubtree(fromRulerId, toRulerId) then
		return false, "That change would create a political cycle."
	end
	return true, ""
end

function PoliticalHierarchyService.OfferFealty(fromRulerId: string, toRulerId: string): (boolean, string)
	if MatchState.IsEnded() then return false, "Match ended." end
	local ok, err = validateFealty(fromRulerId, toRulerId)
	if not ok then
		return false, err
	end
	supersedePair(fromRulerId, toRulerId)
	local requestId = HttpService:GenerateGUID(false)
	local created = now()
	local lifetime = Config.VassalageRequestLifetimeSeconds
	if typeof(lifetime) ~= "number" or lifetime <= 0 then
		lifetime = 30
	end
	local request: FealtyRequest = {
		requestId = requestId,
		fromRulerId = fromRulerId,
		toRulerId = toRulerId,
		createdAt = created,
		expiresAt = created + lifetime,
		expireThread = nil,
	}
	request.expireThread = task.delay(lifetime, function()
		local expired = requestsById[requestId]
		if expired then
			expired.expireThread = nil
			local fromRuler = rulersById[expired.fromRulerId]
			removeRequest(requestId)
			pushState()
			noticeRuler(fromRuler, "Request expired.")
		end
	end)
	requestsById[requestId] = request
	pushState()
	return true, requestId
end

function PoliticalHierarchyService.DeclineFealty(requestId: string, actorRulerId: string?): (boolean, string)
	if MatchState.IsEnded() then return false, "Match ended." end
	local request = requestsById[requestId]
	if not request then
		return false, "Request is no longer valid."
	end
	if now() >= request.expiresAt then
		removeRequest(requestId)
		pushState()
		return false, "Request has expired."
	end
	if actorRulerId and actorRulerId ~= request.toRulerId then
		return false, "Only the prospective liege may decline this request."
	end
	local fromRuler = rulersById[request.fromRulerId]
	local toRuler = rulersById[request.toRulerId]
	removeRequest(requestId)
	pushState()
	if toRuler then
		noticeRuler(toRuler, "Vassalage declined.")
	end
	if fromRuler and toRuler then
		noticeRuler(fromRuler, string.format("%s declined your vassalage offer.", toRuler.displayName))
	end
	return true, "Vassalage declined."
end

function PoliticalHierarchyService.AcceptFealty(requestId: string, actorRulerId: string?): (boolean, string)
	if MatchState.IsEnded() then return false, "Match ended." end
	local request = requestsById[requestId]
	if not request then
		return false, "Request is no longer valid."
	end
	if now() >= request.expiresAt then
		removeRequest(requestId)
		pushState()
		return false, "Request has expired."
	end
	if actorRulerId and actorRulerId ~= request.toRulerId then
		return false, "Only the prospective liege may accept this request."
	end
	local ok, err = validateFealty(request.fromRulerId, request.toRulerId)
	if not ok then
		removeRequest(requestId)
		pushState()
		return false, err
	end
	local fromRuler = rulersById[request.fromRulerId]
	local toRuler = rulersById[request.toRulerId]
	if not fromRuler or not toRuler then
		removeRequest(requestId)
		pushState()
		return false, "Ruler no longer exists."
	end
	attachVassal(toRuler, fromRuler)
	removeRequest(requestId)
	pushState()
	noticeRuler(toRuler, "Vassalage accepted.")
	noticeRuler(fromRuler, string.format("%s accepted your vassalage offer.", toRuler.displayName))
	return true, "Vassalage accepted."
end

function PoliticalHierarchyService.GetSnapshot()
	return buildSnapshot()
end

-- Staged server-only betrayal integration. The coordinator preflights/rolls back
-- before publishing; ordinary fealty, disconnect and title operations are unchanged.
function PoliticalHierarchyService.StageBetrayalDetach(id: string, expectedLiege: string): (boolean, string)
	if MatchState.IsEnded() then return false, "Match ended." end
	local ruler = rulersById[id]
	if not ruler or ruler.liegeId ~= expectedLiege then return false, "Direct liege changed." end
	detachFromLiege(ruler)
	return true, ""
end
function PoliticalHierarchyService.RestoreBetrayalDetach(id: string, expectedLiege: string)
	local ruler, liege = rulersById[id], rulersById[expectedLiege]
	assert(ruler and liege and ruler.liegeId == nil, "Invalid staged betrayal rollback")
	attachVassal(liege, ruler)
end
function PoliticalHierarchyService.PublishBetrayal()
	pushState()
end

function PoliticalHierarchyService.GetRulerIdForUserId(userId: number): string?
	return rulerIdByUserId[userId]
end

-- Production rank mutation used by Title Progression after server revalidation.
-- Does not change liege/vassal links or territory.
function PoliticalHierarchyService.SetTitleRank(rulerId: string, titleRank: number): (boolean, string)
	if MatchState.IsEnded() then return false, "Match ended." end
	if not RankRules.IsValidRank(titleRank) then
		return false, "Invalid rank."
	end
	local ruler = rulersById[rulerId]
	if not ruler then
		return false, "Ruler no longer exists."
	end
	if ruler.titleRank == titleRank then
		return true, "Rank unchanged."
	end
	ruler.titleRank = titleRank
	print("[Hierarchy] rank set", ruler.displayName, RankRules.Name(titleRank))
	pushState()
	return true, "Rank updated."
end

function PoliticalHierarchyService.DebugCreateMockRuler(displayName: string, titleRank: number): string
	assert(RankRules.IsValidRank(titleRank), "Invalid rank")
	local ruler = createRuler({
		rulerId = "Mock_" .. HttpService:GenerateGUID(false),
		displayName = displayName,
		titleRank = titleRank,
		isMock = true,
	})
	pushState()
	return ruler.rulerId
end

function PoliticalHierarchyService.DebugSetRank(rulerId: string, titleRank: number)
	local ok, err = PoliticalHierarchyService.SetTitleRank(rulerId, titleRank)
	assert(ok, err)
end

function PoliticalHierarchyService.DebugRemoveRuler(rulerId: string)
	removeRulerInternal(rulerId)
	pushState()
end

local function onClientIntent(player: Player, action: any, a: any, b: any)
	if typeof(action) ~= "string" then
		notice(player, "Invalid request.")
		return
	end
	if action == "Ready" then
		print("[Hierarchy] Ready from", player.Name)
		pushState(player)
		return
	end
	local fromId = rulerIdByUserId[player.UserId]
	if not fromId then
		notice(player, "No ruler record.")
		return
	end
	if action == "Offer" then
		local targetUserId = tonumber(a)
		if typeof(targetUserId) ~= "number" then
			notice(player, "Invalid target.")
			return
		end
		local toId = rulerIdByUserId[targetUserId]
		if not toId then
			notice(player, "Target ruler not found.")
			return
		end
		local ok, result = PoliticalHierarchyService.OfferFealty(fromId, toId)
		if not ok then
			notice(player, result)
		else
			notice(player, "Vassalage offered.")
		end
		return
	end
	if action == "Accept" or action == "Decline" then
		if typeof(a) ~= "string" then
			notice(player, "Invalid request.")
			return
		end
		local ok, result
		if action == "Accept" then
			ok, result = PoliticalHierarchyService.AcceptFealty(a, fromId)
		else
			ok, result = PoliticalHierarchyService.DeclineFealty(a, fromId)
		end
		if not ok then
			notice(player, result)
		end
		return
	end
	notice(player, "Unknown action.")
end

local eliminatedUsers: { [number]: boolean } = {}
function PoliticalHierarchyService.IsEliminated(userId: number): boolean return eliminatedUsers[userId] == true end
function PoliticalHierarchyService.Eliminate(id: string)
	local ruler = rulersById[id]
	if not ruler then return end
	if ruler.userId then eliminatedUsers[ruler.userId] = true end
	removeRulerInternal(id);pushState()
end

local function onPlayerAdded(player: Player)
	if MatchState.IsEnded() or eliminatedUsers[player.UserId] then pushState(player); return end
	local existing = rulerIdByUserId[player.UserId]
	if existing then
		removeRulerInternal(existing)
	end
	createRuler({
		rulerId = "Player_" .. tostring(player.UserId) .. "_M" .. tostring(MatchState.GetGeneration()),
		userId = player.UserId,
		player = player,
		displayName = player.DisplayName,
		titleRank = RankRules.Lord,
		isMock = false,
	})
	pushState()
	pushState(player)
end

local function onPlayerRemoving(player: Player)
	if MatchState.IsEnded() then return end
	local rulerId = rulerIdByUserId[player.UserId]
	if rulerId then
		-- Temporary V0.1 disconnect: drop the runtime ruler; do not replace with AI.
		removeRulerInternal(rulerId)
		pushState()
	end
end

function PoliticalHierarchyService.Start()
	if started then
		return
	end
	started = true

	remotesFolder = ReplicatedStorage:WaitForChild("Remotes") :: Folder
	clientIntent = remotesFolder:WaitForChild("HierarchyClientEvent") :: RemoteEvent
	serverPush = remotesFolder:WaitForChild("HierarchyServerEvent") :: RemoteEvent

	MatchState.ConnectIntent(clientIntent, onClientIntent)
	Players.PlayerAdded:Connect(onPlayerAdded)
	Players.PlayerRemoving:Connect(onPlayerRemoving)
	for _, player in Players:GetPlayers() do
		onPlayerAdded(player)
	end

	-- Prototype/debug: running instance for Command Bar / MCP. Not a client remote.
	_G.__PoliticalHierarchyV01 = PoliticalHierarchyService

	local debugFolder = ServerScriptService:FindFirstChild("PoliticalHierarchyDebug")
	if debugFolder then
		debugFolder:Destroy()
	end
	debugFolder = Instance.new("Folder")
	debugFolder.Name = "PoliticalHierarchyDebug"
	debugFolder.Parent = ServerScriptService
	debugSnapshot = Instance.new("StringValue")
	debugSnapshot.Name = "LastSnapshot"
	debugSnapshot.Parent = debugFolder
	debugFolder:GetAttributeChangedSignal("CreateMock"):Connect(function()
		local raw = debugFolder:GetAttribute("CreateMock")
		if typeof(raw) ~= "string" then
			return
		end
		local name, rankStr = string.match(raw, "^(.-)=(%d+)$")
		local rank = tonumber(rankStr)
		if name and rank then
			PoliticalHierarchyService.DebugCreateMockRuler(name, rank)
		end
	end)
	debugFolder:GetAttributeChangedSignal("Offer"):Connect(function()
		local raw = debugFolder:GetAttribute("Offer")
		if typeof(raw) ~= "string" then
			return
		end
		local fromId, toId = string.match(raw, "^(.-)=(.+)$")
		if fromId and toId then
			local ok, err = PoliticalHierarchyService.OfferFealty(fromId, toId)
			print("[Hierarchy] debug Offer", ok, err)
		end
	end)
	debugFolder:GetAttributeChangedSignal("Accept"):Connect(function()
		local raw = debugFolder:GetAttribute("Accept")
		if typeof(raw) ~= "string" then
			return
		end
		local ok, err = PoliticalHierarchyService.AcceptFealty(raw)
		print("[Hierarchy] debug Accept", ok, err)
	end)
	pushState()
end

function PoliticalHierarchyService.PublishMatch() pushState() end

function PoliticalHierarchyService.ResetMatch()
	assert(MatchState.IsResetting())
	for _, request in requestsById do cancelExpire(request) end
	rulersById, rulerIdByUserId, requestsById = {}, {}, {}; eliminatedUsers = {}
	for _, player in MatchState.GetConnectedPlayers() do
		createRuler({ rulerId = "Player_" .. tostring(player.UserId) .. "_M" .. tostring(MatchState.GetGeneration()),
			userId = player.UserId, player = player, displayName = player.DisplayName, titleRank = RankRules.Lord, isMock = false }, true)
	end
end

return PoliticalHierarchyService
