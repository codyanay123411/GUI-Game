--!strict

--[[
	Diplomacy V0.1.

	Server-authoritative Alliance and NAP between independent root rulers.
	Consumes Political Hierarchy; does not duplicate the tree.
	No warfare, map, or title effects.
]]

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Config = require(ReplicatedStorage.Shared.Config.DiplomacyConfig)
local Hierarchy = require(ServerScriptService.Services.PoliticalHierarchyService)

local MatchState = require(script.Parent.MatchState)
local DiplomacyService = {}

local stateChangedBindable = Instance.new("BindableEvent")
DiplomacyService.StateChanged = stateChangedBindable.Event

type Agreement = {
	leftId: string,
	rightId: string,
	alliance: boolean,
	allianceInstanceId: string?,
	nap: boolean,
}

type DipRequest = {
	requestId: string,
	agreementType: string,
	fromRulerId: string,
	toRulerId: string,
	createdAt: number,
	expiresAt: number,
	expireThread: thread?,
}

local started = false
local agreementsByKey: { [string]: Agreement } = {}
local requestsById: { [string]: DipRequest } = {}
local clientIntent: RemoteEvent
local serverPush: RemoteEvent
local debugSnapshot: StringValue?

local function now(): number
	return os.clock()
end

local function pairKey(a: string, b: string): string
	if a < b then
		return a .. "|" .. b
	end
	return b .. "|" .. a
end

local function orderedPair(a: string, b: string): (string, string)
	if a < b then
		return a, b
	end
	return b, a
end

local function lifetime(): number
	local value = Config.RequestLifetimeSeconds
	if typeof(value) ~= "number" or value <= 0 then
		return 30
	end
	return value
end

local function findRuler(rulerId: string): any?
	for _, ruler in Hierarchy.GetSnapshot().rulers do
		if ruler.rulerId == rulerId then
			return ruler
		end
	end
	return nil
end

local function isIndependentRoot(ruler: any?): boolean
	return ruler ~= nil and ruler.independent == true
end

local function noticePlayer(player: Player, message: string)
	print("[Diplomacy] notice ->", player.Name, message)
	serverPush:FireClient(player, "Notice", message)
end

local function noticeRulerId(rulerId: string, message: string)
	local ruler = findRuler(rulerId)
	local userId = ruler and tonumber(ruler.userId)
	if typeof(userId) == "number" and userId ~= 0 then
		local player = Players:GetPlayerByUserId(userId)
		if player then
			noticePlayer(player, message)
		end
	end
end

local function cancelExpire(request: DipRequest)
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

local function getOrCreateAgreement(a: string, b: string): Agreement
	local key = pairKey(a, b)
	local existing = agreementsByKey[key]
	if existing then
		return existing
	end
	local left, right = orderedPair(a, b)
	local created: Agreement = {
		leftId = left,
		rightId = right,
		alliance = false,
		nap = false,
	}
	agreementsByKey[key] = created
	return created
end

local function pruneEmpty(agreement: Agreement)
	if not agreement.alliance and not agreement.nap then
		agreementsByKey[pairKey(agreement.leftId, agreement.rightId)] = nil
	end
end

local function findPendingSameType(a: string, b: string, agreementType: string): DipRequest?
	local t = now()
	for _, request in requestsById do
		if request.agreementType == agreementType and request.expiresAt > t then
			local same = pairKey(request.fromRulerId, request.toRulerId) == pairKey(a, b)
			if same then
				return request
			end
		end
	end
	return nil
end

local function buildSnapshot()
	local agreements = {}
	for _, agreement in agreementsByKey do
		if agreement.alliance or agreement.nap then
			table.insert(agreements, {
				leftRulerId = agreement.leftId,
				rightRulerId = agreement.rightId,
				alliance = agreement.alliance,
				allianceInstanceId = agreement.allianceInstanceId or "",
				nap = agreement.nap,
			})
		end
	end
	table.sort(agreements, function(x, y)
		if x.leftRulerId ~= y.leftRulerId then
			return x.leftRulerId < y.leftRulerId
		end
		return x.rightRulerId < y.rightRulerId
	end)
	local requests = {}
	local t = now()
	for _, request in requestsById do
		if request.expiresAt > t then
			table.insert(requests, {
				requestId = request.requestId,
				agreementType = request.agreementType,
				fromRulerId = request.fromRulerId,
				toRulerId = request.toRulerId,
				expiresAt = request.expiresAt,
			})
		end
	end
	return {
		agreements = agreements,
		requests = requests,
	}
end

local function pushState(toPlayer: Player?)
	if not toPlayer then
		stateChangedBindable:Fire()
	end
	local payload = buildSnapshot()
	local encoded = HttpService:JSONEncode(payload)
	if debugSnapshot then
		debugSnapshot.Value = encoded
	end
	if toPlayer then
		print("[Diplomacy] push State to", toPlayer.Name)
		serverPush:FireClient(toPlayer, "State", encoded)
	else
		print("[Diplomacy] push State all clients agreements=", #payload.agreements, "requests=", #payload.requests)
		serverPush:FireAllClients("State", encoded)
	end
end

local function typeLabel(agreementType: string): string
	if agreementType == "NAP" then
		return "Non-Aggression Pact"
	end
	return "Alliance"
end

function DiplomacyService.GetSnapshot()
	return buildSnapshot()
end

function DiplomacyService.AreAllied(rulerA: string, rulerB: string): boolean
	local a = findRuler(rulerA)
	local b = findRuler(rulerB)
	if not a or not b then
		return false
	end
	local ra = a.rootRulerId
	local rb = b.rootRulerId
	if ra == rb then
		return false
	end
	local agreement = agreementsByKey[pairKey(ra, rb)]
	return agreement ~= nil and agreement.alliance == true
end

function DiplomacyService.HasNonAggressionPact(rulerA: string, rulerB: string): boolean
	local a = findRuler(rulerA)
	local b = findRuler(rulerB)
	if not a or not b then
		return false
	end
	local ra = a.rootRulerId
	local rb = b.rootRulerId
	if ra == rb then
		return false
	end
	local agreement = agreementsByKey[pairKey(ra, rb)]
	return agreement ~= nil and agreement.nap == true
end

local function dissolveInvolving(rulerId: string, reason: string)
	local removedAny = false
	for key, agreement in agreementsByKey do
		if agreement.leftId == rulerId or agreement.rightId == rulerId then
			local other = if agreement.leftId == rulerId then agreement.rightId else agreement.leftId
			if agreement.alliance then
				noticeRulerId(other, "Alliance dissolved (" .. reason .. ").")
			end
			if agreement.nap then
				noticeRulerId(other, "Non-Aggression Pact dissolved (" .. reason .. ").")
			end
			agreementsByKey[key] = nil
			removedAny = true
		end
	end
	local t = now()
	for requestId, request in requestsById do
		if request.fromRulerId == rulerId or request.toRulerId == rulerId then
			if request.expiresAt > t then
				local other = if request.fromRulerId == rulerId then request.toRulerId else request.fromRulerId
				noticeRulerId(other, typeLabel(request.agreementType) .. " offer is no longer valid.")
			end
			removeRequest(requestId)
			removedAny = true
		end
	end
	if removedAny then
		noticeRulerId(rulerId, "External diplomatic agreements ended (" .. reason .. ").")
		pushState()
	end
end

function DiplomacyService.Offer(fromRulerId: string, toRulerId: string, agreementType: string): (boolean, string)
	if MatchState.IsEnded() then return false, "Match ended." end
	if agreementType ~= "Alliance" and agreementType ~= "NAP" then
		return false, "Unknown agreement type."
	end
	if fromRulerId == toRulerId then
		return false, "Cannot conduct diplomacy with yourself."
	end
	local fromRuler = findRuler(fromRulerId)
	local toRuler = findRuler(toRulerId)
	if not isIndependentRoot(fromRuler) or not isIndependentRoot(toRuler) then
		return false, "Only independent rulers may conduct this diplomacy."
	end
	local agreement = agreementsByKey[pairKey(fromRulerId, toRulerId)]
	if agreementType == "Alliance" and agreement and agreement.alliance then
		return false, "Alliance already exists."
	end
	if agreementType == "NAP" and agreement and agreement.nap then
		return false, "Non-Aggression Pact already exists."
	end
	if findPendingSameType(fromRulerId, toRulerId, agreementType) then
		return false, "A matching offer is already pending."
	end
	local requestId = HttpService:GenerateGUID(false)
	local created = now()
	local ttl = lifetime()
	local request: DipRequest = {
		requestId = requestId,
		agreementType = agreementType,
		fromRulerId = fromRulerId,
		toRulerId = toRulerId,
		createdAt = created,
		expiresAt = created + ttl,
		expireThread = nil,
	}
	request.expireThread = task.delay(ttl, function()
		local expired = requestsById[requestId]
		if expired then
			expired.expireThread = nil
			removeRequest(requestId)
			pushState()
			noticeRulerId(expired.fromRulerId, typeLabel(expired.agreementType) .. " offer expired.")
			noticeRulerId(expired.toRulerId, typeLabel(expired.agreementType) .. " offer expired.")
		end
	end)
	requestsById[requestId] = request
	pushState()
	noticeRulerId(toRulerId, typeLabel(agreementType) .. " offered.")
	return true, requestId
end

function DiplomacyService.Decline(requestId: string, actorRulerId: string): (boolean, string)
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
	if actorRulerId ~= request.toRulerId then
		return false, "Only the recipient may decline this offer."
	end
	local fromId = request.fromRulerId
	local toId = request.toRulerId
	local label = typeLabel(request.agreementType)
	removeRequest(requestId)
	pushState()
	noticeRulerId(toId, label .. " declined.")
	noticeRulerId(fromId, label .. " declined.")
	return true, label .. " declined."
end

function DiplomacyService.Accept(requestId: string, actorRulerId: string): (boolean, string)
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
	if actorRulerId ~= request.toRulerId then
		return false, "Only the recipient may accept this offer."
	end
	local fromRuler = findRuler(request.fromRulerId)
	local toRuler = findRuler(request.toRulerId)
	if not isIndependentRoot(fromRuler) or not isIndependentRoot(toRuler) then
		removeRequest(requestId)
		pushState()
		return false, "Only independent rulers may conduct this diplomacy."
	end
	local agreement = getOrCreateAgreement(request.fromRulerId, request.toRulerId)
	if request.agreementType == "Alliance" then
		if agreement.alliance then
			removeRequest(requestId)
			pushState()
			return false, "Alliance already exists."
		end
		agreement.alliance = true
		agreement.allianceInstanceId = HttpService:GenerateGUID(false)
	else
		if agreement.nap then
			removeRequest(requestId)
			pushState()
			return false, "Non-Aggression Pact already exists."
		end
		agreement.nap = true
	end
	local label = typeLabel(request.agreementType)
	removeRequest(requestId)
	pushState()
	noticeRulerId(request.toRulerId, label .. " accepted.")
	noticeRulerId(request.fromRulerId, label .. " accepted.")
	return true, label .. " accepted."
end

function DiplomacyService.Break(fromRulerId: string, toRulerId: string, agreementType: string): (boolean, string)
	if MatchState.IsEnded() then return false, "Match ended." end
	if agreementType ~= "Alliance" and agreementType ~= "NAP" then
		return false, "Unknown agreement type."
	end
	local fromRuler = findRuler(fromRulerId)
	if not isIndependentRoot(fromRuler) then
		return false, "Only independent rulers may break this agreement."
	end
	local agreement = agreementsByKey[pairKey(fromRulerId, toRulerId)]
	if not agreement then
		return false, "No such agreement."
	end
	if agreementType == "Alliance" then
		if not agreement.alliance then
			return false, "No Alliance with that realm."
		end
		agreement.alliance = false
		agreement.allianceInstanceId = nil
	else
		if not agreement.nap then
			return false, "No Non-Aggression Pact with that realm."
		end
		agreement.nap = false
	end
	pruneEmpty(agreement)
	pushState()
	local label = typeLabel(agreementType)
	noticeRulerId(fromRulerId, label .. " broken.")
	noticeRulerId(toRulerId, label .. " broken.")
	return true, label .. " broken."
end

local function onClientIntent(player: Player, action: any, a: any, b: any)
	if typeof(action) ~= "string" then
		noticePlayer(player, "Invalid request.")
		return
	end
	if action == "Ready" then
		print("[Diplomacy] Ready from", player.Name)
		pushState(player)
		return
	end
	local fromId = Hierarchy.GetRulerIdForUserId(player.UserId)
	if not fromId then
		noticePlayer(player, "No ruler record.")
		return
	end
	if action == "OfferAlliance" or action == "OfferNAP" then
		if typeof(a) ~= "string" then
			noticePlayer(player, "Invalid target.")
			return
		end
		local kind = if action == "OfferAlliance" then "Alliance" else "NAP"
		local ok, result = DiplomacyService.Offer(fromId, a, kind)
		if not ok then
			noticePlayer(player, result)
		else
			noticePlayer(player, typeLabel(kind) .. " offered.")
		end
		return
	end
	if action == "Accept" or action == "Decline" then
		if typeof(a) ~= "string" then
			noticePlayer(player, "Invalid request.")
			return
		end
		local ok, result
		if action == "Accept" then
			ok, result = DiplomacyService.Accept(a, fromId)
		else
			ok, result = DiplomacyService.Decline(a, fromId)
		end
		if not ok then
			noticePlayer(player, result)
		end
		return
	end
	if action == "BreakAlliance" or action == "BreakNAP" then
		if typeof(a) ~= "string" then
			noticePlayer(player, "Invalid target.")
			return
		end
		local kind = if action == "BreakAlliance" then "Alliance" else "NAP"
		local ok, result = DiplomacyService.Break(fromId, a, kind)
		if not ok then
			noticePlayer(player, result)
		end
		return
	end
	noticePlayer(player, "Unknown action.")
end

local function syncIndependence()
	for _, ruler in Hierarchy.GetSnapshot().rulers do
		if ruler.independent ~= true then
			dissolveInvolving(ruler.rulerId, "no longer independent")
		end
	end
end

function DiplomacyService.Start()
	if started then
		return
	end
	started = true

	local remotesFolder = ReplicatedStorage:WaitForChild("Remotes") :: Folder
	clientIntent = remotesFolder:WaitForChild("DiplomacyClientEvent") :: RemoteEvent
	serverPush = remotesFolder:WaitForChild("DiplomacyServerEvent") :: RemoteEvent
	clientIntent.OnServerEvent:Connect(onClientIntent)

	local debugFolder = ServerScriptService:FindFirstChild("DiplomacyDebug")
	if debugFolder then
		debugFolder:Destroy()
	end
	debugFolder = Instance.new("Folder")
	debugFolder.Name = "DiplomacyDebug"
	debugFolder.Parent = ServerScriptService
	debugSnapshot = Instance.new("StringValue")
	debugSnapshot.Name = "LastSnapshot"
	debugSnapshot.Parent = debugFolder
	local help = Instance.new("StringValue")
	help.Name = "Help"
	help.Value =
		"Prototype only. Invoke Offer/Accept/Decline/Break; or DipOffer=fromId=toId=Alliance|NAP; Accept=requestId=actorId; Break=fromId=toId=Alliance|NAP"
	help.Parent = debugFolder
	local invoke = Instance.new("BindableFunction")
	invoke.Name = "Invoke"
	invoke.Parent = debugFolder
	invoke.OnInvoke = function(action: any, a: any, b: any, c: any)
		if action == "Offer" then
			local ok, result = DiplomacyService.Offer(a, b, c)
			print("[Diplomacy] debug Invoke Offer", ok, result)
			return ok, result
		elseif action == "Accept" then
			local ok, result = DiplomacyService.Accept(a, b)
			print("[Diplomacy] debug Invoke Accept", ok, result)
			return ok, result
		elseif action == "Decline" then
			local ok, result = DiplomacyService.Decline(a, b)
			print("[Diplomacy] debug Invoke Decline", ok, result)
			return ok, result
		elseif action == "Break" then
			local ok, result = DiplomacyService.Break(a, b, c)
			print("[Diplomacy] debug Invoke Break", ok, result)
			return ok, result
		end
		return false, "Unknown debug action."
	end

	debugFolder:GetAttributeChangedSignal("DipOffer"):Connect(function()
		local raw = debugFolder:GetAttribute("DipOffer")
		if typeof(raw) ~= "string" then
			return
		end
		local fromId, toId, kind = string.match(raw, "^(.-)=(.-)=(Alliance|NAP)$")
		if fromId and toId and kind then
			local ok, result = DiplomacyService.Offer(fromId, toId, kind)
			print("[Diplomacy] debug Offer", ok, result)
		end
	end)
	debugFolder:GetAttributeChangedSignal("Accept"):Connect(function()
		local raw = debugFolder:GetAttribute("Accept")
		if typeof(raw) ~= "string" then
			return
		end
		local requestId, actorId = string.match(raw, "^(.-)=(.+)$")
		if requestId and actorId then
			local ok, result = DiplomacyService.Accept(requestId, actorId)
			print("[Diplomacy] debug Accept", ok, result)
		end
	end)
	debugFolder:GetAttributeChangedSignal("Break"):Connect(function()
		local raw = debugFolder:GetAttribute("Break")
		if typeof(raw) ~= "string" then
			return
		end
		local fromId, toId, kind = string.match(raw, "^(.-)=(.-)=(Alliance|NAP)$")
		if fromId and toId and kind then
			local ok, result = DiplomacyService.Break(fromId, toId, kind)
			print("[Diplomacy] debug Break", ok, result)
		end
	end)

	_G.__DiplomacyV01 = DiplomacyService

	Hierarchy.StateChanged:Connect(syncIndependence)
	Hierarchy.RulerRemoving:Connect(function(rulerId: string)
		dissolveInvolving(rulerId, "left the match")
	end)

	Players.PlayerAdded:Connect(function(player)
		task.defer(function()
			if player.Parent then
				pushState(player)
			end
		end)
	end)

	pushState()
	print("[Diplomacy] service started")
end

return DiplomacyService
