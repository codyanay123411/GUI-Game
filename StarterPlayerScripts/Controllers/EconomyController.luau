--!strict
local MatchIntent = require(game:GetService("ReplicatedStorage").Shared.Util.MatchIntent)

--[[
	Player-relevant Economy V0.1 HUD.
	Ready only. Never sends Gold mutations.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")

local PrototypeGuiTheme = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Util"):WaitForChild("PrototypeGuiTheme"))

local player = Players.LocalPlayer
local EconomyController = {}

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

local function formatCountdown(remaining: number): string
	local secs = math.max(0, math.ceil(remaining))
	return string.format("0:%02d", secs)
end

function EconomyController.Start()
	if started or _G.__EconomyV01Started == true then
		return
	end
	started = true
	_G.__EconomyV01Started = true

	local gui = player:WaitForChild("PlayerGui"):WaitForChild("HierarchyPrototypeGui", 12)
	if not (gui and gui:IsA("ScreenGui")) then
		warn("[Economy] HierarchyPrototypeGui missing; HUD idle.")
		started = false
		_G.__EconomyV01Started = nil
		return
	end

	local panel = gui:WaitForChild("EconomyPanel") :: Frame
	local body = panel:WaitForChild("Body") :: TextLabel

	local remotes = ReplicatedStorage:WaitForChild("Remotes")
	local intent = remotes:WaitForChild("EconomyClientEvent") :: RemoteEvent
	local push = remotes:WaitForChild("EconomyServerEvent") :: RemoteEvent

	local gold = 0
	local income = 0
	local baseIncome = 0
	local rankBonus = 0
	local nextPayoutAt = 0
	local hasState = false

	local function render(remainingOverride: number?)
		gui:SetAttribute("PersonalGoldIncome", if hasState then income else nil)
		gui:SetAttribute("GoldRankBonusPercent", if hasState then rankBonus else nil)
		if not hasState then
			body.Text = "Gold: —\nIncome: —\nNext payout: —"
			return
		end
		if gui:GetAttribute("MatchEnded") == true then
			body.Text = string.format("Gold: %g\nIncome: frozen · Match ended\nNo further payouts.", gold)
			return
		end
		local remaining = remainingOverride
		if remaining == nil then
			remaining = nextPayoutAt - workspace:GetServerTimeNow()
		end
		body.Text = string.format(
			"Gold: %g\nIncome: +%g Gold/min\nPersonal base: %g/min · Rank +%g%%\nSubject income excluded.\nFractional bonuses carry forward.\nNext payout: %s",
			gold,
			income,
			baseIncome,
			rankBonus,
			formatCountdown(remaining)
		)
	end

	gui:GetAttributeChangedSignal("MatchEnded"):Connect(function() render() end)
	MatchIntent.ConnectPush(push, function(kind: any, payload: any)
		if kind == "State" then
			local state = decodeState(payload)
			if not state then
				return
			end
			gold = tonumber(state.gold) or 0
			income = tonumber(state.incomeGoldPerMinute) or 0
			baseIncome = tonumber(state.baseIncomeGoldPerMinute) or 0
			rankBonus = tonumber(state.rankBonusPercent) or 0
			nextPayoutAt = tonumber(state.nextPayoutAt) or 0
			hasState = true
			render()
		end
	end)

	RunService.Heartbeat:Connect(function()
		if hasState then
			render()
		end
	end)

	PrototypeGuiTheme.ApplyScreen(gui)
	MatchIntent.Send(intent, "Ready")
	render()
end

return EconomyController
