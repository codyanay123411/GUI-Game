--!strict
local MatchIntent = require(game:GetService("ReplicatedStorage").Shared.Util.MatchIntent)
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextChatService = game:GetService("TextChatService")
local TextService = game:GetService("TextService")
local Config = require(ReplicatedStorage.Shared.Config.CommunicationsConfig)
local Theme = require(ReplicatedStorage.Shared.Util.PrototypeGuiTheme)
local Controller = {}
Controller.Received = Instance.new("BindableEvent")
Controller.Acknowledged = Instance.new("BindableEvent")
local started = false

function Controller.Start()
	if started then return end
	started = true
	local player = Players.LocalPlayer
	local panel = player:WaitForChild("PlayerGui"):WaitForChild("HierarchyPrototypeGui"):WaitForChild("CommunicationsPanel") :: ScrollingFrame
	local transcript = panel:WaitForChild("Transcript") :: ScrollingFrame
	local body = transcript:WaitForChild("Body") :: TextLabel
	local list = panel:WaitForChild("ConvList") :: ScrollingFrame
	local contacts = panel:WaitForChild("ContactList") :: ScrollingFrame
	local input = panel:WaitForChild("Input") :: TextBox
	local send = panel:WaitForChild("SendButton") :: TextButton
	local help = panel:WaitForChild("HelpButton") :: TextButton
	local direct = panel:WaitForChild("DirectButton") :: TextButton
	local observe = panel:WaitForChild("ObserverButton") :: TextButton
	local muteButton = panel:WaitForChild("MuteObserver") :: TextButton
	local status = panel:WaitForChild("Status") :: TextLabel
	local remotes = ReplicatedStorage:WaitForChild("Remotes")
	local intent = remotes:WaitForChild("CommunicationsClientEvent") :: RemoteEvent
	local push = remotes:WaitForChild("CommunicationsServerEvent") :: RemoteEvent
	local channels = TextChatService:WaitForChild("TextChannels")
	local rows: { [string]: any } = {}
	local logs: { [string]: { string } } = {}
	local shown: { [string]: boolean } = {}
	local unread: { [string]: number } = {}
	local identity: { [string]: any } = {}
	local pending: { [string]: TextChatMessage } = {}
	local seen: { [string]: boolean } = {}
	local submitted: { [string]: string } = {}
	local observerLog: { string } = {}
	local selected = "diplomatic"
	local observing, muted, sending = false, false, false
	local availableContacts = {}
	local renderList: () -> ()

	local function fitTranscript()
		local height = TextService:GetTextSize(body.Text, body.TextSize, body.Font,
			Vector2.new(math.max(1, transcript.AbsoluteSize.X - 10), 100000)).Y + 8
		body.AutomaticSize = Enum.AutomaticSize.None
		body.Size = UDim2.new(1, -10, 0, height)
		transcript.AutomaticCanvasSize = Enum.AutomaticSize.None
		transcript.CanvasSize = UDim2.fromOffset(0, height)
		transcript.CanvasPosition = Vector2.new(0, math.max(0, height - transcript.AbsoluteWindowSize.Y))
	end
	transcript:GetPropertyChangedSignal("AbsoluteSize"):Connect(fitTranscript)
	body:GetPropertyChangedSignal("Text"):Connect(fitTranscript)
	body:GetPropertyChangedSignal("TextSize"):Connect(fitTranscript)
	body:GetPropertyChangedSignal("FontFace"):Connect(fitTranscript)
	TextChatService.ChatWindowConfiguration.Enabled = false
	TextChatService.ChatInputBarConfiguration.Enabled = false
	TextChatService.BubbleChatConfiguration.Enabled = false
	TextChatService.ChannelTabsConfiguration.Enabled = false

	local function refresh()
		local row = rows[selected]
		local canSend = row ~= nil and row.canSend == true and not observing
		input.TextEditable = canSend
		send.Active = canSend and not sending
		Theme.applyPrimaryButton(send, send.Active)
		send.Text = if sending then "…" else "Send"
		status.Text = if observing then "Observer (native receipts only)" elseif row then
			row.label .. (if canSend then "" else " — unavailable") else "History — unavailable"
		body.Text = table.concat(if observing then observerLog else logs[selected] or {}, "\n\n")
		fitTranscript()
		muteButton.Visible = observing
		muteButton.Text = if muted then "Unmute" else "Mute"
		task.defer(function()
			transcript.CanvasPosition = Vector2.new(0, math.max(0, transcript.AbsoluteCanvasSize.Y - transcript.AbsoluteWindowSize.Y))
		end)
	end
	local function append(id: string, line: string)
		local log = logs[id]
		if not log then log = {}; logs[id] = log end
		table.insert(log, line)
		while #log > Config.HistoryLimit do table.remove(log, 1) end
	end
	local function explain()
		local row = rows[selected]
		if row and not observing then
			append(selected, "[SYSTEM] " .. (Config.Help[row.kind] or "This context is unavailable."))
			shown[selected] = true
		end
		refresh()
	end
	local function selectContext(id: string)
		selected, observing = id, false
		contacts.Visible = false
		transcript.Visible = true
		unread[id] = 0
		if panel.Visible then Controller.Acknowledged:Fire(id) end
		if not shown[id] then explain() else refresh() end
		renderList()
	end
	Controller.OpenContext = selectContext
	function Controller.OpenDirect(userId: number)
		MatchIntent.Send(intent, "OpenDirect", userId)
	end
	panel:GetPropertyChangedSignal("Visible"):Connect(function()
		if panel.Visible and not observing then unread[selected] = 0; Controller.Acknowledged:Fire(selected); renderList() end
	end)
	local function button(parent: Instance, text: string, y: number, callback: () -> ())
		local item = Instance.new("TextButton")
		item.Size = UDim2.new(1, -8, 0, 24)
		item.Position = UDim2.fromOffset(0, y)
		item.Text = text
		Theme.applySecondaryButton(item, true)
		item.TextWrapped = true
		item.Parent = parent
		item.Activated:Connect(callback)
	end
	renderList = function()
		for _, child in list:GetChildren() do if child:IsA("TextButton") then child:Destroy() end end
		local ids = {}
		for id, row in rows do if not row.observerOnly or logs[id] then table.insert(ids, id) end end
		for id in logs do if not rows[id] then table.insert(ids, id) end end
		table.sort(ids)
		for i, id in ids do
			local row = rows[id]
			local label = if row then row.label else id .. " (history)"
			local count = unread[id] or 0
			button(list, (if id == selected then "› " else "") .. label .. (if count > 0 then " (" .. count .. ")" else ""), (i - 1) * 26,
				function() selectContext(id) end)
		end
		list.CanvasSize = UDim2.fromOffset(0, #ids * 26)
	end
	local function received(id: string)
		local message, meta = pending[id], identity[id]
		if not message or not meta or seen[id] then return end
		seen[id] = true
		if message.TextSource and message.TextSource.UserId == player.UserId and submitted[id] then
			if input.Text == submitted[id] then input.Text = "" end
			submitted[id] = nil
			sending = false
		end
		pending[id], identity[id] = nil, nil
		if meta.ordinary then
			append(meta.contextId, meta.prefix .. message.Text)
			if selected ~= meta.contextId or observing or not panel.Visible then
				unread[meta.contextId] = (unread[meta.contextId] or 0) + 1
				if message.TextSource and message.TextSource.UserId ~= player.UserId then
					Controller.Received:Fire({ id = id, contextId = meta.contextId, userId = message.TextSource.UserId, kind = meta.kind })
				end
			end
		end
		if meta.observing and not muted then
			table.insert(observerLog, meta.observerPrefix .. message.Text)
			while #observerLog > Config.HistoryLimit do table.remove(observerLog, 1) end
		end
		renderList()
		refresh()
		task.delay(30, function() seen[id] = nil end)
	end
	TextChatService.MessageReceived:Connect(function(message)
		local channel = message.TextChannel
		if message.Status ~= Enum.TextChatMessageStatus.Success or not message.TextSource
			or not channel or not channel:GetAttribute("CommunicationsContextId") or channel:GetAttribute("MatchGeneration") ~= MatchIntent.GetGeneration() then return end
		local id = message.MessageId
		pending[id] = message
		received(id)
		task.delay(30, function() pending[id], identity[id] = nil, nil end)
	end)
	MatchIntent.ConnectPush(push, function(action, data)
		if action == "Identity" and typeof(data) == "table" and typeof(data.messageId) == "string" then
			identity[data.messageId] = data
			received(data.messageId)
			task.delay(30, function() identity[data.messageId] = nil end)
		elseif action == "State" and typeof(data) == "table" then
			rows = {}
			for _, row in data.contexts do rows[row.id] = row end
			availableContacts = data.contacts
			observe.Visible = data.isAdmin
			if not data.isAdmin then observing = false end
			if not shown[selected] and rows[selected] and not rows[selected].observerOnly then explain() end
			renderList()
			refresh()
		elseif action == "Opened" and typeof(data) == "string" then selectContext(data)
		elseif action == "Notice" and typeof(data) == "string" then status.Text = data end
	end)
	local function submit()
		local row = rows[selected]
		local text = string.match(input.Text, "^%s*(.-)%s*$") or ""
		if observing or sending or not row or not row.canSend or text == "" then return end
		if string.lower(text) == "help" then input.Text = ""; explain(); return end
		local channel = channels:FindFirstChild(row.channelName)
		if not channel or not channel:IsA("TextChannel") then status.Text = "Native channel unavailable."; return end
		sending = true
		local generation = MatchIntent.GetGeneration()
		refresh()
		task.spawn(function()
			local ok, result = pcall(function() return channel:SendAsync(text) end)
			if generation ~= MatchIntent.GetGeneration() then return end
			sending = false
			refresh()
			if not ok or not result then
				status.Text = "Message not delivered by Roblox."
			elseif result.Status == Enum.TextChatMessageStatus.Sending or result.Status == Enum.TextChatMessageStatus.Success then
				submitted[result.MessageId] = text
				if seen[result.MessageId] then
					if input.Text == text then input.Text = "" end
					submitted[result.MessageId] = nil
				end
				task.delay(15, function()
					if submitted[result.MessageId] then
						submitted[result.MessageId] = nil
						status.Text = "Delivery not confirmed by Roblox."
					end
				end)
			else
				status.Text = "Message blocked by Roblox."
			end
			-- Only native MessageReceived + authoritative label can append player text.
		end)
	end
	send.Activated:Connect(submit)
	input.FocusLost:Connect(function(enter) if enter then submit() end end)
	help.Activated:Connect(explain)
	direct.Activated:Connect(function()
		contacts.Visible = not contacts.Visible
		transcript.Visible = not contacts.Visible
		for _, child in contacts:GetChildren() do if child:IsA("TextButton") then child:Destroy() end end
		for i, contact in availableContacts do button(contacts, contact.name, (i - 1) * 26, function() MatchIntent.Send(intent, "OpenDirect", contact.userId) end) end
		contacts.CanvasSize = UDim2.fromOffset(0, #availableContacts * 26)
		if #availableContacts == 0 then status.Text = "No currently neighboring contact." end
	end)
	observe.Activated:Connect(function()
		observing = not observing
		contacts.Visible = false
		transcript.Visible = true
		refresh()
	end)
	muteButton.Activated:Connect(function() muted = not muted; refresh() end)
	MatchIntent.OnChanged(function()
		rows, logs, shown, unread, identity, pending, seen, submitted, observerLog = {}, {}, {}, {}, {}, {}, {}, {}, {}
		availableContacts = {};selected = "diplomatic";observing = false;sending = false
		input.Text = "";renderList();refresh()
	end)
	MatchIntent.Send(intent, "Ready")
	refresh()
end
return Controller
