--!strict

-- Player text never passes through these remotes. TextChannel owns delivery.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextChatService = game:GetService("TextChatService")
local HttpService = game:GetService("HttpService")
local Hierarchy = require(script.Parent.PoliticalHierarchyService)
local Territory = require(script.Parent.TerritoryMapService)
local Diplomacy = require(script.Parent.DiplomacyService)
local AdminConfig = require(script.Parent.AdminConfig)
local Policy = require(script.Parent.CommunicationsPolicy)
local Service = {}

type Context = {
	id: string, kind: string, label: string, owner: string?, instanceId: string?,
	left: number?, right: number?, channel: TextChannel?, adding: { [number]: boolean },
}
local contexts: { [string]: Context } = {}
local started = false
local push: RemoteEvent
local intent: RemoteEvent
local channels: Instance
local queued = false
local excluded: { [number]: boolean } = {}
local lastIntent: { [number]: number } = {}
local snapshotValue: StringValue

local function world(): any
	return Policy.World(Hierarchy.GetSnapshot().rulers, Diplomacy.GetSnapshot().agreements,
		Territory.GetOwnedTerritoryIds, Territory.AreAdjacent)
end

local function observer(player: Player): boolean
	return not excluded[player.UserId] and AdminConfig.IsGameTester(player.UserId)
end

local function eligible(w: any, context: Context, player: Player): boolean
	return not excluded[player.UserId] and Policy.Member(w, context, w.users[player.UserId])
end

local function relationContext(w: any, context: Context): string
	if context.kind == "diplomatic" then
		return "Diplomatic / public political reach"
	end
	if context.kind ~= "direct" then
		return context.label
	end
	local a, b = w.users[context.left], w.users[context.right]
	if a and b then
		local relation = if a.liegeId == b.rulerId or b.liegeId == a.rulerId then "Liege ↔ Subject"
			else "Neighboring rulers"
		return context.label .. " / " .. relation
	end
	return context.label
end

local function canDeliver(context: Context, message: TextChatMessage, target: TextSource): boolean
	local source = message.TextSource
	if not source or not source.CanSend or not context.channel or source.Parent ~= context.channel then
		return false
	end
	local from, to = Players:GetPlayerByUserId(source.UserId), Players:GetPlayerByUserId(target.UserId)
	if not from or not to or excluded[from.UserId] or excluded[to.UserId] then
		return false
	end
	-- No yielding permission calls or cached membership in this callback.
	local w = world()
	local ordinary = Policy.Deliver(w, context, from.UserId, to.UserId, false)
	local observing = observer(to) and Policy.Deliver(w, context, from.UserId, to.UserId, true)
	if not ordinary and not observing then
		return false
	end
	-- Labels alone cannot display text: client joins this envelope to native Success receipt.
	push:FireClient(to, "Identity", {
		messageId = message.MessageId, contextId = context.id, kind = context.kind,
		label = context.label, ordinary = ordinary, observing = observing,
		prefix = Policy.Prefix(w, context, from.UserId, to.UserId, false),
		observerPrefix = "[" .. relationContext(w, context) .. "] " .. Policy.Prefix(w, context, from.UserId, to.UserId, true),
	})
	return true
end

local function create(id: string, kind: string, label: string, fields: any?): Context
	local existing = contexts[id]
	if existing then
		return existing
	end
	local context: Context = {
		id = id, kind = kind, label = label, adding = {},
		owner = fields and fields.owner, instanceId = fields and fields.instanceId,
		left = fields and fields.left, right = fields and fields.right,
	}
	local channel = Instance.new("TextChannel")
	channel.Name = "Comms_" .. id
	channel:SetAttribute("CommunicationsContextId", id)
	channel.Parent = channels
	context.channel = channel
	contexts[id] = context
	channel.ShouldDeliverCallback = function(message, target)
		return canDeliver(context, message, target)
	end
	return context
end

local function stateFor(player: Player, w: any): any
	local rows, contacts = {}, {}
	for _, context in contexts do
		local member = eligible(w, context, player)
		if member or observer(player) then
			table.insert(rows, { id = context.id, kind = context.kind, label = context.label,
				channelName = context.channel and context.channel.Name or "", canSend = member, observerOnly = not member })
		end
	end
	local me = w.users[player.UserId]
	for _, other in Players:GetPlayers() do
		if other ~= player and not excluded[other.UserId] and Policy.Direct(w, me, w.users[other.UserId]) then
			table.insert(contacts, { userId = other.UserId, name = other.Name })
		end
	end
	table.sort(rows, function(a, b) return a.id < b.id end)
	table.sort(contacts, function(a, b) return a.name < b.name end)
	return { contexts = rows, contacts = contacts, isAdmin = observer(player) }
end

local function sync()
	local w = world()
	create("diplomatic", "diplomatic", "Diplomatic")
	for _, ruler in w.rulers do
		if #ruler.vassalIds > 0 then
			create("council:" .. ruler.rulerId, "council", "Council — " .. ruler.displayName, { owner = ruler.rulerId })
		end
	end
	for _, agreement in w.agreements do
		if agreement.alliance and agreement.allianceInstanceId ~= "" then
			local a, b = w.rulers[agreement.leftRulerId], w.rulers[agreement.rightRulerId]
			if a and b then
				create("alliance:" .. agreement.allianceInstanceId, "alliance", "Allies — " .. a.displayName .. " ↔ " .. b.displayName,
					{ instanceId = agreement.allianceInstanceId })
			end
		end
	end
	for _, context in contexts do
		local channel = context.channel
		if not channel then continue end
		local wanted: { [number]: boolean } = {}
		for _, player in Players:GetPlayers() do
			if eligible(w, context, player) or observer(player) then wanted[player.UserId] = true end
		end
		local present: { [number]: boolean } = {}
		for _, source in channel:GetChildren() do
			if source:IsA("TextSource") then
				local player = Players:GetPlayerByUserId(source.UserId)
				if not wanted[source.UserId] or not player then
					source.CanSend = false
					source:Destroy() -- History is local; retained recipients are not history.
				else
					source.CanSend = eligible(w, context, player)
					present[source.UserId] = true
				end
			end
		end
		for userId in wanted do
			if present[userId] or context.adding[userId] then continue end
			context.adding[userId] = true
			task.spawn(function()
				local ok, source = pcall(function() return channel:AddUserAsync(userId) end)
				context.adding[userId] = nil
				if ok and source and source:IsA("TextSource") then
					local player = Players:GetPlayerByUserId(userId)
					local fresh = world()
					if not player or not (eligible(fresh, context, player) or observer(player)) then
						source:Destroy()
					else
						source.CanSend = eligible(fresh, context, player)
					end
				elseif not ok then
					warn("[Communications] native membership denied:", userId, tostring(source))
				end
			end)
		end
	end
	for _, player in Players:GetPlayers() do
		if not excluded[player.UserId] then push:FireClient(player, "State", stateFor(player, w)) end
	end
	if snapshotValue then snapshotValue.Value = HttpService:JSONEncode(Service.DebugInspect()) end
end

local function queueSync()
	if queued then return end
	queued = true
	task.defer(function() queued = false; sync() end)
end

function Service.OpenDirect(player: Player, targetId: any): (boolean, string)
	if typeof(targetId) ~= "number" or targetId % 1 ~= 0 or targetId == player.UserId then
		return false, "Invalid contact."
	end
	local target = Players:GetPlayerByUserId(targetId)
	local w = world()
	if not target or excluded[player.UserId] or excluded[targetId] or not Policy.Direct(w, w.users[player.UserId], w.users[targetId]) then
		return false, "Direct requires a current border."
	end
	local left, right = math.min(player.UserId, targetId), math.max(player.UserId, targetId)
	local id = "direct:" .. left .. ":" .. right
	local context = contexts[id]
	if not context then
		context = create(id, "direct", "Direct — " .. player.Name .. " ↔ " .. target.Name, { left = left, right = right })
		local ok, err = pcall(function() (context.channel :: TextChannel):SetDirectChatRequester(player) end)
		if not ok then
			(context.channel :: TextChannel):Destroy()
			contexts[id] = nil
			return false, "Native Direct unavailable: " .. tostring(err)
		end
	end
	sync()
	push:FireClient(player, "Opened", id)
	return true, id
end

function Service.DebugInspect(): any
	local w = world()
	local result: any = { implementation = "NativeDeliveryV01", contexts = {} }
	for _, context in contexts do
		local members, sources = {}, {}
		for _, player in Players:GetPlayers() do
			if eligible(w, context, player) then table.insert(members, player.UserId) end
		end
		if context.channel then
			for _, source in context.channel:GetChildren() do
				if source:IsA("TextSource") then table.insert(sources, { userId = source.UserId, canSend = source.CanSend }) end
			end
		end
		table.insert(result.contexts, { id = context.id, kind = context.kind, members = members, sources = sources })
	end
	return result
end

function Service.DebugCanDeliver(id: string, from: number, to: number, asObserver: boolean?): boolean
	local context = contexts[id]
	if not context or excluded[from] or excluded[to] then return false end
	return Policy.Deliver(world(), context, from, to, asObserver == true)
end

function Service.Start()
	if started then return end
	started = true
	local remotes = ReplicatedStorage:WaitForChild("Remotes")
	intent = remotes:WaitForChild("CommunicationsClientEvent") :: RemoteEvent
	push = remotes:WaitForChild("CommunicationsServerEvent") :: RemoteEvent
	channels = TextChatService:FindFirstChild("TextChannels") :: Instance
	if not channels then
		channels = Instance.new("Folder")
		channels.Name = "TextChannels"
		channels.Parent = TextChatService
	end
	-- No unrestricted parallel default room, team room, or whisper path.
	for _, child in channels:GetChildren() do
		if child:IsA("TextChannel") then child.ShouldDeliverCallback = function() return false end end
	end
	channels.ChildAdded:Connect(function(child)
		if child:IsA("TextChannel") and not child:GetAttribute("CommunicationsContextId") then
			child.ShouldDeliverCallback = function() return false end
		end
	end)
	Hierarchy.StateChanged:Connect(queueSync)
	Territory.OwnershipChanged:Connect(queueSync)
	Diplomacy.StateChanged:Connect(queueSync)
	Players.PlayerAdded:Connect(function(player) excluded[player.UserId] = nil; queueSync() end)
	Players.PlayerRemoving:Connect(function(player) excluded[player.UserId] = true; lastIntent[player.UserId] = nil; queueSync() end)
	intent.OnServerEvent:Connect(function(player, action, arg)
		local now = os.clock()
		if now - (lastIntent[player.UserId] or -math.huge) < 0.15 then return end
		lastIntent[player.UserId] = now
		if action == "Ready" then
			push:FireClient(player, "State", stateFor(player, world()))
		elseif action == "OpenDirect" then
			local ok, message = Service.OpenDirect(player, arg)
			if not ok then push:FireClient(player, "Notice", message) end
		else
			push:FireClient(player, "Notice", "Unsupported Communications intent.")
		end
	end)
	local debugFolder = Instance.new("Folder")
	debugFolder.Name = "CommunicationsDebug"
	debugFolder.Parent = script.Parent.Parent
	snapshotValue = Instance.new("StringValue")
	snapshotValue.Name = "LastSnapshot"
	snapshotValue.Parent = debugFolder
	local invoke = Instance.new("BindableFunction")
	invoke.Name = "Invoke"
	invoke.Parent = debugFolder
	invoke.OnInvoke = function(action, a, b, c)
		if action == "Inspect" then return Service.DebugInspect() end
		if action == "Sync" then sync(); return true end
		if action == "CanDeliver" then return Service.DebugCanDeliver(a, b, c) end
		if action == "OpenDirect" then
			local player = Players:GetPlayerByUserId(a)
			if player then return Service.OpenDirect(player, b) end
		end
		return false, "Unknown debug operation."
	end
	sync()
	print("[Communications] NativeDeliveryV01 started.")
end

return Service
