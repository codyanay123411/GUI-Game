--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local Theme = require(ReplicatedStorage.Shared.Util.PrototypeGuiTheme)
local Controller = {}
local started = false

function Controller.Start()
	if started then return end
	started = true
	local player = Players.LocalPlayer
	local gui = player:WaitForChild("PlayerGui"):WaitForChild("HierarchyPrototypeGui") :: ScreenGui
	local overlay = gui:WaitForChild("VictoryOverlay") :: Frame
	local panel = overlay:WaitForChild("Panel") :: Frame
	local state: any = nil
	local shown = false
	local function layout()
		panel.Size = UDim2.fromOffset(math.min(600, gui.AbsoluteSize.X - 32), math.min(370, gui.AbsoluteSize.Y - 32))
	end
	local function isCompetitive(button: TextButton): boolean
		if button.Name == "DeclareWar" then return true end
		for _, name in { "Main", "TitlePanel", "DiplomacyPanel", "MilitaryPanel", "VassalageOfferOverlay", "DiplomacyOfferOverlay" } do
			local container = gui:FindFirstChild(name)
			if container and button:IsDescendantOf(container) then return true end
		end
		return false
	end
	local function watch(item: Instance)
		if not item:IsA("TextButton") or not isCompetitive(item) then return end
		local function disable()
			if gui:GetAttribute("MatchEnded") == true and item.Active then
				item.Active = false
				Theme.applyPrimaryButton(item, false)
			end
		end
		item:GetPropertyChangedSignal("Active"):Connect(disable)
		gui:GetAttributeChangedSignal("MatchEnded"):Connect(disable)
		disable()
	end
	for _, item in gui:GetDescendants() do watch(item) end
	gui.DescendantAdded:Connect(watch)
	gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(layout)
	overlay:GetPropertyChangedSignal("Visible"):Connect(function() gui:SetAttribute("VictoryOverlayOpen", overlay.Visible) end)
	panel.Continue.Activated:Connect(function() overlay.Visible = false end)
	gui.StrategyNavigation.MatchResult.Activated:Connect(function() if state and state.ended then overlay.Visible = true end end)
	local remotes = ReplicatedStorage:WaitForChild("Remotes")
	local push = remotes:WaitForChild("VictoryServerEvent") :: RemoteEvent
	push.OnClientEvent:Connect(function(kind, payload)
		if kind ~= "State" then return end
		local ok, decoded = pcall(function() return HttpService:JSONDecode(payload) end)
		if not ok or typeof(decoded) ~= "table" then return end
		state = decoded
		local ended = state.ended == true
		gui:SetAttribute("MatchEnded", ended)
		gui.MapHint.Text = if ended then "MATCH ENDED  ·  Inspect the map  ·  Players  ·  Match result" else string.format("DOMINATION: %d / %d territories required  ·  Expand your greater realm", state.required, state.total)
		gui.StrategyNavigation.MatchResult.Visible = ended
		gui.StrategyTopbar:SetAttribute("DominationRequired", state.required)
		if not ended then return end
		local member = false
		for _, ruler in state.members or {} do if ruler.userId == player.UserId then member = true end end
		panel.Heading.Text = if state.winnerUserId == player.UserId then "VICTORY" elseif member then "REALM VICTORY" else "DEFEAT"
		panel.Winner.Text = state.winnerTitle .. " " .. state.winnerName
		panel.Body.Text = state.realmName .. "\n\n" .. string.format("%d / %d territories  ·  %.1f%% controlled", state.controlled, state.total, state.controlPercent * 100)
			.. "\nDomination achieved  ·  " .. string.format("%.0f%% required", state.threshold * 100)
			.. "\n\nThe match has ended. Competitive actions are frozen.\nInspect the map, view Players or continue communicating."
		if not shown then overlay.Visible = true; shown = true end
		layout()
	end)
	local intent = remotes:WaitForChild("VictoryClientEvent") :: RemoteEvent
	intent:FireServer("Ready")
	layout()
end

return Controller
