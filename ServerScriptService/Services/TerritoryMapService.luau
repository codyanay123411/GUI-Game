--!strict

--[[
	Authoritative territory ownership for Territory / Map Foundation V0.1.

	Match state only. Map geometry lives in MapConfiguration.
	Does not own political hierarchy; listens to hierarchy ruler lifecycle.
]]

local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local MapCatalog = require(ReplicatedStorage.Shared.Config.MapCatalog)
local MapAdjacency = require(ReplicatedStorage.Shared.Util.MapAdjacency)
local Hierarchy = require(ServerScriptService.Services.PoliticalHierarchyService)

local TerritoryMapService = {}

local started = false
local mapDef
local ownerByTerritory: { [string]: string } = {}
local territoriesByRuler: { [string]: { string } } = {}
local colorIndexByRuler: { [string]: number } = {}
local nextColorIndex = 1

local remotesFolder: Folder
local clientIntent: RemoteEvent
local serverPush: RemoteEvent

local function definitionById()
	local byId = {}
	for _, t in mapDef.territories do
		byId[t.id] = t
	end
	return byId
end

local function unclaimedIds(): { string }
	local list = {}
	for _, t in mapDef.territories do
		if ownerByTerritory[t.id] == nil then
			table.insert(list, t.id)
		end
	end
	table.sort(list)
	return list
end

local function ensureColor(rulerId: string)
	if colorIndexByRuler[rulerId] == nil then
		colorIndexByRuler[rulerId] = nextColorIndex
		nextColorIndex += 1
	end
end

local function buildSnapshot()
	local territories = {}
	for _, t in mapDef.territories do
		local owner = ownerByTerritory[t.id]
		table.insert(territories, {
			territoryId = t.id,
			ownerRulerId = owner or "",
			hasOwner = owner ~= nil,
		})
	end
	table.sort(territories, function(a, b)
		return a.territoryId < b.territoryId
	end)
	local rulerColors = {}
	for rulerId, index in colorIndexByRuler do
		table.insert(rulerColors, {
			rulerId = rulerId,
			colorIndex = index,
		})
	end
	table.sort(rulerColors, function(a, b)
		return a.rulerId < b.rulerId
	end)
	return {
		mapId = mapDef.mapId,
		territories = territories,
		rulerColors = rulerColors,
	}
end

local function pushState(toPlayer: Player?)
	local payload = buildSnapshot()
	local encoded = HttpService:JSONEncode(payload)
	if toPlayer then
		print("[Territory] push State to", toPlayer.Name)
		serverPush:FireClient(toPlayer, "State", encoded)
	else
		print("[Territory] push State all clients")
		serverPush:FireAllClients("State", encoded)
	end
end

local function unclaimRuler(rulerId: string)
	local owned = territoriesByRuler[rulerId]
	if not owned then
		colorIndexByRuler[rulerId] = nil
		return
	end
	for _, territoryId in owned do
		if ownerByTerritory[territoryId] == rulerId then
			ownerByTerritory[territoryId] = nil
			print("[Territory] unclaimed", territoryId, "from", rulerId)
		end
	end
	territoriesByRuler[rulerId] = nil
	colorIndexByRuler[rulerId] = nil
	pushState()
end

local function assignStartingTerritory(rulerId: string)
	local existing = territoriesByRuler[rulerId]
	if existing and #existing > 0 then
		return
	end
	local free = unclaimedIds()
	if #free == 0 then
		warn("[Territory] no free starting territory for", rulerId)
		return
	end
	local pick = free[math.random(1, #free)]
	ensureColor(rulerId)
	ownerByTerritory[pick] = rulerId
	territoriesByRuler[rulerId] = { pick }
	print("[Territory] assigned", pick, "to", rulerId)
	pushState()
end

function TerritoryMapService.GetSnapshot()
	return buildSnapshot()
end

function TerritoryMapService.GetMapId(): string
	return mapDef.mapId
end

-- Prototype/debug only. Not a client remote.
function TerritoryMapService.DebugSetOwner(territoryId: string, rulerId: string?)
	local byId = definitionById()
	assert(byId[territoryId], "Unknown territory")
	local previous = ownerByTerritory[territoryId]
	if previous then
		local list = territoriesByRuler[previous]
		if list then
			local nextList = {}
			for _, id in list do
				if id ~= territoryId then
					table.insert(nextList, id)
				end
			end
			territoriesByRuler[previous] = nextList
		end
	end
	if rulerId == nil or rulerId == "" then
		ownerByTerritory[territoryId] = nil
	else
		ensureColor(rulerId)
		ownerByTerritory[territoryId] = rulerId
		local list = territoriesByRuler[rulerId] or {}
		table.insert(list, territoryId)
		territoriesByRuler[rulerId] = list
	end
	pushState()
end

local function onClientIntent(player: Player, action: any)
	if action == "Ready" then
		print("[Territory] Ready from", player.Name)
		pushState(player)
	end
end

function TerritoryMapService.Start()
	if started then
		return
	end
	started = true

	mapDef = MapCatalog.GetDefault()
	local ok, err = MapAdjacency.Validate(mapDef.territories)
	assert(ok, err)

	remotesFolder = ReplicatedStorage:WaitForChild("Remotes") :: Folder
	clientIntent = remotesFolder:WaitForChild("TerritoryClientEvent") :: RemoteEvent
	serverPush = remotesFolder:WaitForChild("TerritoryServerEvent") :: RemoteEvent

	clientIntent.OnServerEvent:Connect(onClientIntent)

	Hierarchy.RulerCreated:Connect(function(rulerId: string, userId: number?)
		if typeof(userId) == "number" then
			assignStartingTerritory(rulerId)
		end
	end)
	Hierarchy.RulerRemoving:Connect(function(rulerId: string)
		unclaimRuler(rulerId)
	end)

	local snap = Hierarchy.GetSnapshot()
	for _, ruler in snap.rulers do
		if ruler.hasUser == true then
			assignStartingTerritory(ruler.rulerId)
		end
	end
end

return TerritoryMapService
