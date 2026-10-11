--!strict

--[[
	Prototype GUI driver for Political Hierarchy V0.1.
	Displays replicated server state and sends untrusted intents only.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local StarterGui = game:GetService("StarterGui")

local PrototypeGuiTheme = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Util"):WaitForChild("PrototypeGuiTheme"))

local player = Players.LocalPlayer
local PoliticalHierarchyController = {}

local function bindGui(): ScreenGui?
	local playerGui = player:WaitForChild("PlayerGui")
	local chosen = playerGui:FindFirstChild("HierarchyPrototypeGui")
	if not (chosen and chosen:IsA("ScreenGui")) then
		local waited = playerGui:WaitForChild("HierarchyPrototypeGui", 8)
		if waited and waited:IsA("ScreenGui") then
			chosen = waited
		end
	end
	if not (chosen and chosen:IsA("ScreenGui")) then
		local template = StarterGui:FindFirstChild("HierarchyPrototypeGui")
		if template and template:IsA("ScreenGui") then
			chosen = template:Clone()
			chosen.Parent = playerGui
		end
	end
	if not (chosen and chosen:IsA("ScreenGui")) then
		return nil
	end
	for _, child in playerGui:GetChildren() do
		if child:IsA("ScreenGui") and child.Name == "HierarchyPrototypeGui" and child ~= chosen then
			child:Destroy()
		end
	end
	return chosen
end

local started = false

function PoliticalHierarchyController.Start()
	if started or _G.__PoliticalHierarchyV01Started == true then
		return
	end
	started = true
	_G.__PoliticalHierarchyV01Started = true

	local remotes = ReplicatedStorage:WaitForChild("Remotes")
	local clientIntent = remotes:WaitForChild("HierarchyClientEvent") :: RemoteEvent
	local serverPush = remotes:WaitForChild("HierarchyServerEvent") :: RemoteEvent

	local gui = bindGui()
	if not gui then
		warn("[Hierarchy] HierarchyPrototypeGui missing; controller idle.")
		started = false
		_G.__PoliticalHierarchyV01Started = nil
		return
	end
	gui.Enabled = true
	PrototypeGuiTheme.ApplyScreen(gui)
	print("[Hierarchy] controller started listening", player.Name)

	local playerGui = player:WaitForChild("PlayerGui")
	playerGui.ChildAdded:Connect(function(child)
		if child:IsA("ScreenGui") and child.Name == "HierarchyPrototypeGui" and child ~= gui then
			task.defer(function()
				if child.Parent then
					child:Destroy()
				end
			end)
		end
	end)

	local main = gui:WaitForChild("Main")
	local selfInfo = main:WaitForChild("SelfInfo") :: TextLabel
	local treeView = main:WaitForChild("TreeScroll"):WaitForChild("TreeView") :: TextLabel
	local noticeLabel = main:WaitForChild("Notice") :: TextLabel
	noticeLabel.Visible = false
	local resultToast = gui:WaitForChild("ResultToast") :: Frame
	local resultToastLabel = resultToast:WaitForChild("Label") :: TextLabel
	local playerList = main:WaitForChild("PlayerList") :: ScrollingFrame
	local incomingList = main:FindFirstChild("IncomingList")
	local incomingHeader = main:FindFirstChild("IncomingHeader")
	if incomingHeader and incomingHeader:IsA("GuiObject") then
		incomingHeader.Visible = false
	end
	if incomingList and incomingList:IsA("GuiObject") then
		incomingList.Visible = false
	end
	local playerTemplate = gui:WaitForChild("Templates"):WaitForChild("PlayerRow")
	local offerCardTemplate = gui:WaitForChild("Templates"):WaitForChild("OfferCard")
	local offerOverlay = gui:WaitForChild("VassalageOfferOverlay") :: Frame
	offerOverlay.Visible = false
	local overlayExtra = offerOverlay:WaitForChild("ExtraList") :: Frame
	local overlayBody = offerOverlay:FindFirstChild("Body")
	local overlayButtons = offerOverlay:FindFirstChild("Buttons")
	if overlayBody and overlayBody:IsA("GuiObject") then
		overlayBody.Visible = false
	end
	if overlayButtons and overlayButtons:IsA("GuiObject") then
		overlayButtons.Visible = false
	end

	local myRulerId: string? = nil
	local receivedState = false
	local snapshot: any = { rulers = {}, requests = {} }
	local noticeToken = 0

	local function showNotice(message: string)
		noticeToken += 1
		local token = noticeToken
		resultToastLabel.Text = message
		resultToast.Visible = true
		noticeLabel.Text = message
		task.delay(6, function()
			if token == noticeToken then
				resultToast.Visible = false
			end
		end)
	end

	local function rulerById(id: string): any?
		for _, ruler in snapshot.rulers do
			if ruler.rulerId == id then
				return ruler
			end
		end
		return nil
	end

	local function myRuler(): any?
		if myRulerId then
			local found = rulerById(myRulerId)
			if found then
				return found
			end
		end
		for _, ruler in snapshot.rulers do
			if tonumber(ruler.userId) == player.UserId then
				myRulerId = ruler.rulerId
				return ruler
			end
		end
		return nil
	end

	local function clearFrameChildren(container: Instance)
		for _, child in container:GetChildren() do
			if child:IsA("Frame") then
				child:Destroy()
			end
		end
	end

	local function formatTree(): string
		local lines = {}
		local byId = {}
		for _, ruler in snapshot.rulers do
			byId[ruler.rulerId] = ruler
		end
		local function walk(id: string, linePrefix: string, childPrefix: string)
			local ruler = byId[id]
			if not ruler then
				return
			end
			table.insert(lines, linePrefix .. ruler.titleName .. " " .. ruler.displayName)
			for index, vassalId in ruler.vassalIds do
				local isLast = index == #ruler.vassalIds
				local branch = if isLast then "└── " else "├── "
				local nextChild = childPrefix .. (if isLast then "    " else "│   ")
				walk(vassalId, childPrefix .. branch, nextChild)
			end
		end
		for _, ruler in snapshot.rulers do
			if ruler.independent then
				walk(ruler.rulerId, "", "")
			end
		end
		if not receivedState then
			return "Waiting for server state..."
		end
		if #lines == 0 then
			return "(no rulers)"
		end
		return table.concat(lines, "\n")
	end

	local function refresh()
		local me = myRuler()
		if me then
			local liegeName = "none"
			if me.liegeId and me.liegeId ~= "" then
				local liege = rulerById(me.liegeId)
				liegeName = if liege then liege.displayName else me.liegeId
			end
			local vassalNames = {}
			for _, id in me.vassalIds do
				local v = rulerById(id)
				table.insert(vassalNames, if v then v.displayName else id)
			end
			selfInfo.Text = string.format(
				"Name: %s\nRank: %s\nStatus: %s\nDirect liege: %s\nDirect vassals: %s",
				me.displayName,
				me.titleName,
				if me.independent then "Independent" else "Subject",
				liegeName,
				if #vassalNames > 0 then table.concat(vassalNames, ", ") else "none"
			)
		else
			selfInfo.Text = if receivedState then "No ruler record yet." else "Waiting for server state..."
		end
		treeView.Text = formatTree()

		clearFrameChildren(playerList)
		local layoutOrder = 0
		local otherRows = 0
		for _, ruler in snapshot.rulers do
			local uid = tonumber(ruler.userId)
			local hasUser = ruler.hasUser == true or (uid ~= nil and uid ~= 0)
			if hasUser and uid ~= player.UserId then
				layoutOrder += 1
				otherRows += 1
				local row = playerTemplate:Clone()
				row.Name = "PlayerRow_" .. tostring(layoutOrder)
				row.Visible = true
				row.LayoutOrder = layoutOrder
				row.Size = UDim2.new(1, -8, 0, 34)
				row.Parent = playerList
				local nameLabel = row:WaitForChild("NameLabel") :: TextLabel
				nameLabel.Text = string.format("%s %s", ruler.titleName, ruler.displayName)
				nameLabel.Visible = true
				nameLabel.LayoutOrder = 1
				local offer = row:WaitForChild("OfferButton") :: TextButton
				offer.Visible = true
				offer.Active = true
				offer.LayoutOrder = 2
				offer.Text = "Offer Vassalage"
				PrototypeGuiTheme.applyPrimaryButton(offer, true)
				offer.TextSize = 13
				offer.MouseButton1Click:Connect(function()
					clientIntent:FireServer("Offer", uid)
				end)
			end
		end

		clearFrameChildren(overlayExtra)
		layoutOrder = 0
		local incomingCount = 0
		local meId = if me then me.rulerId else nil
		for _, request in snapshot.requests do
			if meId and request.toRulerId == meId then
				layoutOrder += 1
				incomingCount += 1
				local from = rulerById(request.fromRulerId)
				local fromName = if from then (from.titleName .. " " .. from.displayName) else request.fromRulerId
				local card = offerCardTemplate:Clone()
				card.Name = "OfferCard_" .. tostring(layoutOrder)
				card:SetAttribute("RequestId", request.requestId)
				card.Visible = true
				card.LayoutOrder = layoutOrder
				card.Parent = overlayExtra
				local label = card:WaitForChild("Label") :: TextLabel
				label.Text = string.format("%s offers to become your vassal.", fromName)
				local accept = card:FindFirstChild("AcceptButton", true) :: TextButton
				local decline = card:FindFirstChild("DeclineButton", true) :: TextButton
				accept.Visible = true
				accept.Active = true
				decline.Visible = true
				decline.Active = true
				PrototypeGuiTheme.applyPrimaryButton(accept, true)
				accept.TextSize = 14
				PrototypeGuiTheme.applyDangerButton(decline)
				decline.TextSize = 14
				accept.MouseButton1Click:Connect(function()
					clientIntent:FireServer("Accept", request.requestId)
				end)
				decline.MouseButton1Click:Connect(function()
					clientIntent:FireServer("Decline", request.requestId)
				end)
			end
		end
		offerOverlay.Visible = incomingCount > 0
		print(
			"[Hierarchy] render",
			player.Name,
			"rulers=",
			#(snapshot.rulers or {}),
			"otherRows=",
			otherRows,
			"incoming=",
			incomingCount
		)
	end

	serverPush.OnClientEvent:Connect(function(kind: any, payload: any)
		if kind == "State" then
			local data = payload
			if typeof(payload) == "string" then
				local ok, decoded = pcall(function()
					return HttpService:JSONDecode(payload)
				end)
				if not ok or typeof(decoded) ~= "table" then
					warn("[Hierarchy] State JSON decode failed")
					return
				end
				data = decoded
			elseif typeof(payload) ~= "table" then
				warn("[Hierarchy] State payload not table/string", typeof(payload))
				return
			end
			receivedState = true
			snapshot = data
			if snapshot.rulers == nil then
				snapshot.rulers = {}
			end
			if snapshot.requests == nil then
				snapshot.requests = {}
			end
			print("[Hierarchy] State received", player.Name, "rulers=", #snapshot.rulers, "requests=", #snapshot.requests)
			refresh()
		elseif kind == "Notice" and typeof(payload) == "string" then
			showNotice(payload)
		end
	end)

	refresh()
	clientIntent:FireServer("Ready")
	print("[Hierarchy] remote Ready sent", player.Name)
end

return PoliticalHierarchyController
