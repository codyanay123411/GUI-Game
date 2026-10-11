--!strict

--[[
	Prototype diplomacy panel. Sends intents only.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")

local PrototypeGuiTheme = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Util"):WaitForChild("PrototypeGuiTheme"))

local player = Players.LocalPlayer
local DiplomacyController = {}

local started = false

local function decodeState(payload: any): any?
	if typeof(payload) == "string" then
		local ok, decoded = pcall(function()
			return HttpService:JSONDecode(payload)
		end)
		if ok and typeof(decoded) == "table" then
			return decoded
		end
		return nil
	elseif typeof(payload) == "table" then
		return payload
	end
	return nil
end

function DiplomacyController.Start()
	if started or _G.__DiplomacyV01Started == true then
		return
	end
	started = true
	_G.__DiplomacyV01Started = true

	local gui = player:WaitForChild("PlayerGui"):WaitForChild("HierarchyPrototypeGui", 12)
	if not (gui and gui:IsA("ScreenGui")) then
		warn("[Diplomacy] HierarchyPrototypeGui missing; panel idle.")
		started = false
		_G.__DiplomacyV01Started = nil
		return
	end

	local panel = gui:WaitForChild("DiplomacyPanel") :: Frame
	local status = panel:WaitForChild("Status") :: TextLabel
	local list = panel:WaitForChild("List") :: ScrollingFrame
	local overlay = gui:WaitForChild("DiplomacyOfferOverlay") :: Frame
	overlay.Visible = false
	local overlayExtra = overlay:WaitForChild("ExtraList") :: Frame
	local overlayBody = overlay:FindFirstChild("Body")
	local overlayButtons = overlay:FindFirstChild("Buttons")
	if overlayBody and overlayBody:IsA("GuiObject") then
		overlayBody.Visible = false
	end
	if overlayButtons and overlayButtons:IsA("GuiObject") then
		overlayButtons.Visible = false
	end
	local rowTemplate = gui:WaitForChild("Templates"):WaitForChild("DiplomacyRow")
	local cardTemplate = gui:WaitForChild("Templates"):WaitForChild("DiplomacyOfferCard")
	local resultToast = gui:WaitForChild("ResultToast") :: Frame
	local resultToastLabel = resultToast:WaitForChild("Label") :: TextLabel

	local remotes = ReplicatedStorage:WaitForChild("Remotes")
	local intent = remotes:WaitForChild("DiplomacyClientEvent") :: RemoteEvent
	local push = remotes:WaitForChild("DiplomacyServerEvent") :: RemoteEvent
	local hierarchyPush = remotes:WaitForChild("HierarchyServerEvent") :: RemoteEvent

	local dip = { agreements = {}, requests = {} }
	local hierarchy = { rulers = {} }
	local noticeToken = 0

	local function showNotice(message: string)
		noticeToken += 1
		local token = noticeToken
		resultToastLabel.Text = message
		resultToast.Visible = true
		task.delay(6, function()
			if token == noticeToken then
				resultToast.Visible = false
			end
		end)
	end

	local function rulerById(id: string): any?
		for _, ruler in hierarchy.rulers do
			if ruler.rulerId == id then
				return ruler
			end
		end
		return nil
	end

	local function myRuler(): any?
		for _, ruler in hierarchy.rulers do
			if tonumber(ruler.userId) == player.UserId then
				return ruler
			end
		end
		return nil
	end

	local function agreementBetween(a: string, b: string): any?
		local keyA = if a < b then a else b
		local keyB = if a < b then b else a
		for _, row in dip.agreements do
			if row.leftRulerId == keyA and row.rightRulerId == keyB then
				return row
			end
		end
		return nil
	end

	local function pendingBetween(a: string, b: string, kind: string): any?
		for _, request in dip.requests do
			if request.agreementType == kind then
				local same = (request.fromRulerId == a and request.toRulerId == b)
					or (request.fromRulerId == b and request.toRulerId == a)
				if same then
					return request
				end
			end
		end
		return nil
	end

	local function clearFrames(container: Instance)
		for _, child in container:GetChildren() do
			if child:IsA("Frame") then
				child:Destroy()
			end
		end
	end

	local function stylePairButtons(offerBtn: TextButton, breakBtn: TextButton, hasAgreement: boolean, canAct: boolean, pending: boolean)
		if hasAgreement then
			offerBtn.Visible = false
			breakBtn.Visible = true
			breakBtn.Active = canAct
			if canAct then
				PrototypeGuiTheme.applyDangerButton(breakBtn)
			else
				PrototypeGuiTheme.applyPrimaryButton(breakBtn, false)
			end
		else
			breakBtn.Visible = false
			offerBtn.Visible = true
			local enable = canAct and not pending
			offerBtn.Active = enable
			PrototypeGuiTheme.applyPrimaryButton(offerBtn, enable)
			if pending then
				offerBtn.Text = "Pending..."
			end
		end
		offerBtn.TextSize = 12
		breakBtn.TextSize = 12
	end

	local function refresh()
		local me = myRuler()
		local actorId = if me and me.independent == true then me.rulerId else (if me then me.rootRulerId else nil)
		local canAct = me ~= nil and me.independent == true
		if not me then
			status.Text = "Waiting for server state..."
		elseif canAct then
			status.Text = "Independent realm. Offer or break Alliance / NAP with other independent realms."
		else
			local root = rulerById(me.rootRulerId)
			local rootName = if root then (root.titleName .. " " .. root.displayName) else "your liege"
			status.Text = "Subject of " .. rootName .. ". External diplomacy follows their realm (read-only)."
		end

		clearFrames(list)
		local order = 0
		if actorId then
			for _, ruler in hierarchy.rulers do
				if ruler.independent == true and ruler.rulerId ~= actorId then
					order += 1
					local row = rowTemplate:Clone()
					row.Name = "DipRow_" .. tostring(order)
					row.Visible = true
					row.LayoutOrder = order
					row.Parent = list
					local nameLabel = row:WaitForChild("NameLabel") :: TextLabel
					nameLabel.Text = string.format("%s %s", ruler.titleName, ruler.displayName)
					local rel = agreementBetween(actorId, ruler.rulerId)
					local bits = {}
					if rel and rel.alliance == true then
						table.insert(bits, "Alliance")
					end
					if rel and rel.nap == true then
						table.insert(bits, "NAP")
					end
					local relLabel = row:WaitForChild("RelationLabel") :: TextLabel
					relLabel.Text = if #bits > 0 then table.concat(bits, " · ") else "No agreements"
					local buttonRow = row:WaitForChild("ButtonRow")
					local offerA = buttonRow:WaitForChild("OfferAlliance") :: TextButton
					local breakA = buttonRow:WaitForChild("BreakAlliance") :: TextButton
					local offerN = buttonRow:WaitForChild("OfferNAP") :: TextButton
					local breakN = buttonRow:WaitForChild("BreakNAP") :: TextButton
					offerA.Text = "Offer Alliance"
					breakA.Text = "Break Alliance"
					offerN.Text = "Offer NAP"
					breakN.Text = "Break NAP"
					local pendingA = pendingBetween(actorId, ruler.rulerId, "Alliance") ~= nil
					local pendingN = pendingBetween(actorId, ruler.rulerId, "NAP") ~= nil
					stylePairButtons(offerA, breakA, rel ~= nil and rel.alliance == true, canAct, pendingA)
					stylePairButtons(offerN, breakN, rel ~= nil and rel.nap == true, canAct, pendingN)
					local targetId = ruler.rulerId
					offerA.MouseButton1Click:Connect(function()
						if canAct and offerA.Active then
							intent:FireServer("OfferAlliance", targetId)
						end
					end)
					offerN.MouseButton1Click:Connect(function()
						if canAct and offerN.Active then
							intent:FireServer("OfferNAP", targetId)
						end
					end)
					breakA.MouseButton1Click:Connect(function()
						if canAct and breakA.Active then
							intent:FireServer("BreakAlliance", targetId)
						end
					end)
					breakN.MouseButton1Click:Connect(function()
						if canAct and breakN.Active then
							intent:FireServer("BreakNAP", targetId)
						end
					end)
				end
			end
		end
		if order == 0 then
			status.Text = status.Text .. "\nNo other independent realms."
		end

		clearFrames(overlayExtra)
		local incoming = 0
		if me and me.independent == true then
			for _, request in dip.requests do
				if request.toRulerId == me.rulerId then
					incoming += 1
					local card = cardTemplate:Clone()
					card.Name = "DipOffer_" .. tostring(incoming)
					card:SetAttribute("RequestId", request.requestId)
					card.Visible = true
					card.LayoutOrder = incoming
					card.Parent = overlayExtra
					local from = rulerById(request.fromRulerId)
					local fromName = if from then (from.titleName .. " " .. from.displayName) else request.fromRulerId
					local kind = if request.agreementType == "NAP" then "a Non-Aggression Pact" else "an Alliance"
					local label = card:WaitForChild("Label") :: TextLabel
					label.Text = string.format("%s offers %s.", fromName, kind)
					local accept = card:FindFirstChild("AcceptButton", true) :: TextButton
					local decline = card:FindFirstChild("DeclineButton", true) :: TextButton
					accept.Visible = true
					decline.Visible = true
					PrototypeGuiTheme.applyPrimaryButton(accept, true)
					PrototypeGuiTheme.applyDangerButton(decline)
					local requestId = request.requestId
					accept.MouseButton1Click:Connect(function()
						intent:FireServer("Accept", requestId)
					end)
					decline.MouseButton1Click:Connect(function()
						intent:FireServer("Decline", requestId)
					end)
				end
			end
		end
		overlay.Visible = incoming > 0
	end

	push.OnClientEvent:Connect(function(kind: any, payload: any)
		if kind == "Notice" and typeof(payload) == "string" then
			showNotice(payload)
			return
		end
		if kind ~= "State" then
			return
		end
		local data = decodeState(payload)
		if not data then
			warn("[Diplomacy] State decode failed")
			return
		end
		dip.agreements = data.agreements or {}
		dip.requests = data.requests or {}
		refresh()
	end)

	hierarchyPush.OnClientEvent:Connect(function(kind: any, payload: any)
		if kind ~= "State" then
			return
		end
		local data = decodeState(payload)
		if data and typeof(data.rulers) == "table" then
			hierarchy.rulers = data.rulers
			refresh()
		end
	end)

	refresh()
	intent:FireServer("Ready")
	print("[Diplomacy] controller started; Ready sent")
end

return DiplomacyController
