--!strict

--[[
	Project-owned admin command feedback. Display only.
	Does not invoke AdminBridge. Does not trust the client for mutations.
]]

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PrototypeGuiTheme = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Util"):WaitForChild("PrototypeGuiTheme"))

local player = Players.LocalPlayer
local AdminFeedbackController = {}

local started = false

local INSPECT = {
	Help = true,
	InspectWars = true,
	InspectTerritory = true,
	InspectRuler = true,
	InspectGold = true,
}

local TITLES = {
	Help = "GameTester commands",
	InspectWars = "Active wars",
	InspectTerritory = "Territory",
	InspectRuler = "Ruler",
	InspectGold = "Gold",
	SetOwner = "Territory owner",
	SetPrestige = "Prestige",
	SetGold = "Gold",
	AddGold = "Gold",
	SpendGold = "Gold",
	ResolveWar = "War",
}

local function prettyMessage(raw: string): string
	local trimmed = string.gsub(raw, "^%s+", "")
	trimmed = string.gsub(trimmed, "%s+$", "")
	if string.sub(trimmed, 1, 1) == "{" or string.sub(trimmed, 1, 1) == "[" then
		local ok, decoded = pcall(function()
			return HttpService:JSONDecode(trimmed)
		end)
		if ok and typeof(decoded) == "table" then
			local lines = {}
			for key, value in decoded do
				table.insert(lines, string.format("%s: %s", tostring(key), tostring(value)))
			end
			table.sort(lines)
			return table.concat(lines, "\n")
		end
	end
	return raw
end

function AdminFeedbackController.Start()
	if started or _G.__AdminFeedbackStarted == true then
		return
	end
	started = true
	_G.__AdminFeedbackStarted = true

	local gui = player:WaitForChild("PlayerGui"):WaitForChild("HierarchyPrototypeGui", 12)
	if not (gui and gui:IsA("ScreenGui")) then
		warn("[Admin] HierarchyPrototypeGui missing; feedback idle.")
		started = false
		_G.__AdminFeedbackStarted = nil
		return
	end

	local function ensureInspectPanel(): (Frame, TextLabel, TextLabel, TextButton)
		local existing = gui:FindFirstChild("AdminInspectPanel")
		if existing and existing:IsA("Frame") then
			local header = existing:FindFirstChild("Header")
			local body = existing:FindFirstChild("Body", true)
			local closeBtn = existing:FindFirstChild("CloseButton")
			if header and header:IsA("TextLabel") and body and body:IsA("TextLabel") and closeBtn and closeBtn:IsA("TextButton") then
				return existing, header, body, closeBtn
			end
			existing:Destroy()
		end
		local panel = Instance.new("Frame")
		panel.Name = "AdminInspectPanel"
		panel.AnchorPoint = Vector2.new(0, 0)
		panel.Position = UDim2.fromOffset(12, 84)
		panel.Size = UDim2.fromOffset(420, 248)
		panel.Visible = false
		panel.Active = true
		panel.ZIndex = 28
		panel.Parent = gui
		local header = Instance.new("TextLabel")
		header.Name = "Header"
		header.BackgroundTransparency = 1
		header.Size = UDim2.new(1, -80, 0, 22)
		header.Text = "Inspect"
		header.Parent = panel
		local closeBtn = Instance.new("TextButton")
		closeBtn.Name = "CloseButton"
		closeBtn.AnchorPoint = Vector2.new(1, 0)
		closeBtn.Position = UDim2.new(1, 0, 0, 0)
		closeBtn.Size = UDim2.fromOffset(72, 22)
		closeBtn.Text = "Close"
		closeBtn.Parent = panel
		local scroll = Instance.new("ScrollingFrame")
		scroll.Name = "BodyScroll"
		scroll.Position = UDim2.fromOffset(0, 28)
		scroll.Size = UDim2.new(1, 0, 1, -28)
		scroll.BorderSizePixel = 0
		scroll.ScrollBarThickness = 6
		scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
		scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
		scroll.Parent = panel
		local body = Instance.new("TextLabel")
		body.Name = "Body"
		body.BackgroundTransparency = 1
		body.Size = UDim2.new(1, -8, 0, 0)
		body.AutomaticSize = Enum.AutomaticSize.Y
		body.TextWrapped = true
		body.TextXAlignment = Enum.TextXAlignment.Left
		body.TextYAlignment = Enum.TextYAlignment.Top
		body.Text = ""
		body.Parent = scroll
		return panel, header, body, closeBtn
	end

	local inspect, inspectHeader, inspectBody, closeBtn = ensureInspectPanel()
	local resultToast = gui:WaitForChild("ResultToast") :: Frame
	local resultToastLabel = resultToast:WaitForChild("Label") :: TextLabel
	PrototypeGuiTheme.ApplyScreen(gui)

	local remotes = ReplicatedStorage:WaitForChild("Remotes")
	local feedbackWait = remotes:WaitForChild("AdminFeedbackEvent", 20)
	if not (feedbackWait and feedbackWait:IsA("RemoteEvent")) then
		warn("[Admin] AdminFeedbackEvent missing; feedback idle.")
		started = false
		_G.__AdminFeedbackStarted = nil
		return
	end
	local feedback = feedbackWait :: RemoteEvent

	local toastToken = 0

	local function showToast(message: string, kind: string)
		toastToken += 1
		local token = toastToken
		PrototypeGuiTheme.applyToast(resultToast, kind)
		resultToastLabel.Text = message
		resultToast.Visible = true
		task.delay(6, function()
			if token == toastToken then
				resultToast.Visible = false
			end
		end)
	end

	closeBtn.MouseButton1Click:Connect(function()
		inspect.Visible = false
	end)

	feedback.OnClientEvent:Connect(function(payload: any)
		if typeof(payload) ~= "table" then
			return
		end
		local ok = payload.ok == true
		local operation = tostring(payload.operation or "")
		local message = prettyMessage(tostring(payload.message or ""))
		if not ok then
			inspect.Visible = false
			showToast(message, "error")
			return
		end
		if INSPECT[operation] then
			inspectHeader.Text = TITLES[operation] or "Inspect"
			inspectBody.Text = message
			inspect.Visible = true
		else
			inspect.Visible = false
			showToast(message, "ok")
		end
	end)

	print("[Admin] feedback controller started.")
end

return AdminFeedbackController
