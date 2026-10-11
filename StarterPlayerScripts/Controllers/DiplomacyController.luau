--!strict

--[[
	Incoming diplomacy offers and notices. Target actions live in map context.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")

local Transitions = require(ReplicatedStorage.Shared.Util.ContextTransitions)
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

	local overlay = gui:WaitForChild("DiplomacyOfferOverlay") :: Frame
	overlay.Visible = false
	local overlayExtra = overlay:WaitForChild("ExtraList") :: Frame
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

	local function clearFrames(container: Instance)
		for _, child in container:GetChildren() do
			if child:IsA("Frame") then
				child:Destroy()
			end
		end
	end

	local function refresh()
		local me = myRuler()
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
		if incoming > 0 then Transitions.Show(overlay :: any) else Transitions.Hide(overlay :: any, true) end
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
