--!strict

--[[
	Prototype title-progression panel. Sends Establish intent only.
	Never sends territory counts or Prestige as authority.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")

local PrototypeGuiTheme = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Util"):WaitForChild("PrototypeGuiTheme"))

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

	local panel = gui:WaitForChild("TitlePanel") :: ScrollingFrame
	panel.Header.Text = "Titles"
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
		gui:SetAttribute("PersonalPrestige", if row then math.floor(row.prestige) else nil)
		gui:SetAttribute("PrestigePerMinute", if row then row.prestigePerMinute else nil)
		-- Keep the Establish slot reserved so TitlePanel geometry does not reflow.
		establish.Visible = true
		if not row then
			body.Text = "Current title: —\nNext title: —\nRealm control: —\nPrestige: —\nStatus: Waiting for server state..."
			establish.Text = "Establish"
			establish.Active = false
			PrototypeGuiTheme.applyPrimaryButton(establish, false)
			return
		end
		local nextLabel = if row.hasNext == true and row.nextTitleName ~= "" then row.nextTitleName else "—"
		local realm = if row.hasNext == true
			then string.format("%d / %d", row.realmControl, row.realmRequired)
			else string.format("%d", row.realmControl)
		local prestige = if row.hasNext == true
			then string.format("%s / %g", if row.prestigeRequired % 1 == 0 then tostring(math.floor(row.prestige)) else string.format("%g", row.prestige), row.prestigeRequired)
			else string.format("%d", math.floor(row.prestige))
		body.Text = string.format(
			"Current title: %s\nNext title: %s\nRealm control: %s\nPrestige: %s\nStatus: %s",
			row.currentTitleName,
			nextLabel,
			realm,
			prestige,
			row.statusText
		)
		body.Text ..= string.format("\nIncome: %g Prestige/min · %d personal provinces\n\nPersonal conquerable holdings earn Prestige over time. Subject land earns for its direct owner. Realm control includes your descendants.\n\nPrestige is retained when establishing a title or losing land.%s", row.prestigePerMinute or 0, row.personalHoldings or 0,
			if row.matchEnded then " Match ended: earning frozen." else "")
		local goldIncome = gui:GetAttribute("PersonalGoldIncome")
		local goldBonus = gui:GetAttribute("GoldRankBonusPercent")
		body.Text ..= "\nPersonal Gold: " .. (if row.matchEnded then "frozen" elseif goldIncome then string.format("+%g/min", goldIncome) else "—")
			.. (if goldBonus then string.format(" · Rank +%g%%", goldBonus) else "")
		if row.hasNext == true then
			establish.Text = row.establishLabel
			local can = row.eligible == true and row.matchEnded ~= true
			establish.Active = can
			PrototypeGuiTheme.applyPrimaryButton(establish, can)
		else
			establish.Text = "No further title"
			establish.Active = false
			PrototypeGuiTheme.applyPrimaryButton(establish, false)
		end
	end

	for _, attribute in { "PersonalGoldIncome", "GoldRankBonusPercent" } do
		gui:GetAttributeChangedSignal(attribute):Connect(function() applyRow(myRow) end)
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
