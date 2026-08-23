--!strict

--[[
	Prototype title-progression panel. Sends Establish intent only.
	Never sends territory counts or Prestige as authority.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")

local player = Players.LocalPlayer
local TitleProgressionController = {}

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

function TitleProgressionController.Start()
	if started or _G.__TitleProgressionV01Started == true then
		return
	end
	started = true
	_G.__TitleProgressionV01Started = true

	local gui = player:WaitForChild("PlayerGui"):WaitForChild("HierarchyPrototypeGui", 12)
	if not (gui and gui:IsA("ScreenGui")) then
		warn("[Title] HierarchyPrototypeGui missing; title panel idle.")
		started = false
		_G.__TitleProgressionV01Started = nil
		return
	end

	local panel = gui:WaitForChild("TitlePanel") :: Frame
	local body = panel:WaitForChild("Body") :: TextLabel
	local establish = panel:WaitForChild("EstablishButton") :: TextButton
	local resultToast = gui:WaitForChild("ResultToast") :: Frame
	local resultToastLabel = resultToast:WaitForChild("Label") :: TextLabel

	local remotes = ReplicatedStorage:WaitForChild("Remotes")
	local titleIntent = remotes:WaitForChild("TitleClientEvent") :: RemoteEvent
	local titlePush = remotes:WaitForChild("TitleServerEvent") :: RemoteEvent

	local myRow: any? = nil
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

	local function applyRow(row: any?)
		myRow = row
		if not row then
			body.Text = "Waiting for server state..."
			establish.Visible = false
			establish.Active = false
			return
		end
		if row.hasNext ~= true then
			body.Text = string.format(
				"Current title: %s\nNext title: —\nRealm control: %d\nTest Prestige: %d\nStatus: %s",
				row.currentTitleName,
				row.realmControl,
				row.prestige,
				row.statusText
			)
			establish.Visible = false
			establish.Active = false
			return
		end
		body.Text = string.format(
			"Current title: %s\nNext title: %s\nRealm control: %d / %d\nTest Prestige: %d / %d\nStatus: %s",
			row.currentTitleName,
			row.nextTitleName,
			row.realmControl,
			row.realmRequired,
			row.prestige,
			row.prestigeRequired,
			row.statusText
		)
		establish.Text = row.establishLabel
		local can = row.eligible == true
		establish.Visible = true
		establish.Active = can
		establish.AutoButtonColor = can
		establish.BackgroundColor3 = if can then Color3.fromRGB(46, 120, 72) else Color3.fromRGB(48, 52, 58)
		establish.TextColor3 = if can then Color3.fromRGB(235, 240, 235) else Color3.fromRGB(140, 144, 150)
	end

	titlePush.OnClientEvent:Connect(function(kind: any, payload: any)
		if kind == "Notice" and typeof(payload) == "string" then
			showNotice(payload)
			return
		end
		if kind ~= "State" then
			return
		end
		local data = decodeState(payload)
		if not data or typeof(data.rows) ~= "table" then
			warn("[Title] State decode failed")
			return
		end
		local mine = nil
		for _, row in data.rows do
			if tonumber(row.userId) == player.UserId then
				mine = row
				break
			end
		end
		applyRow(mine)
	end)

	establish.MouseButton1Click:Connect(function()
		if not myRow or myRow.eligible ~= true then
			return
		end
		titleIntent:FireServer("Establish")
	end)

	applyRow(nil)
	titleIntent:FireServer("Ready")
	print("[Title] controller started; Ready sent")
end

return TitleProgressionController
