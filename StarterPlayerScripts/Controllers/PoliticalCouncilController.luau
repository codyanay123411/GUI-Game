--!strict
-- Only server-filtered membership; no strength calculation or political actions.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local Theme = require(ReplicatedStorage.Shared.Util.PrototypeGuiTheme)
local Controller = {}
local started = false
function Controller.Start()
	if started then return end
	started = true
	local gui = Players.LocalPlayer:WaitForChild("PlayerGui"):WaitForChild("HierarchyPrototypeGui")
	local main = gui:WaitForChild("Main")
	local heading = Instance.new("TextLabel")
	heading.Name = "CouncilHeader"
	heading.BackgroundTransparency = 1
	heading.TextXAlignment = Enum.TextXAlignment.Left
	heading.TextYAlignment = Enum.TextYAlignment.Center
	heading.Text = "Political councils"
	heading.LayoutOrder = 4
	heading.Size = UDim2.new(1, 0, 0, 20)
	Theme.applyText(heading, "Caption")
	heading.Parent = main
	main.TreeHeader.LayoutOrder = 6
	main.TreeScroll.LayoutOrder = 7
	local body = Instance.new("TextLabel")
	body.Name = "CouncilBody"
	body.BackgroundTransparency = 1
	body.TextXAlignment = Enum.TextXAlignment.Left
	body.TextYAlignment = Enum.TextYAlignment.Top
	body.TextWrapped = true
	body.Text = "Waiting for membership..."
	body.LayoutOrder = 5
	body.Size = UDim2.new(1, 0, 0, 100)
	Theme.applyText(body, "Body")
	body.Parent = main
	local remotes = ReplicatedStorage:WaitForChild("Remotes")
	local push = remotes:WaitForChild("CouncilServerEvent") :: RemoteEvent
	push.OnClientEvent:Connect(function(kind: any, payload: any)
		if kind ~= "State" or typeof(payload) ~= "string" then return end
		local ok, state = pcall(function() return HttpService:JSONDecode(payload) end)
		if not ok or typeof(state) ~= "table" or typeof(state.councils) ~= "table" then return end
		heading.Text = if state.frozen then "Political councils · Final" else "Political councils"
		local lines = {}
		for _, council in state.councils do
			table.insert(lines, council.titleName .. " " .. council.displayName .. "'s council (" .. #council.members .. "/" .. state.seatLimit .. ")")
			if #council.members == 0 then table.insert(lines, "No eligible members seated.") end
			for _, member in council.members do table.insert(lines, "• " .. member.titleName .. " " .. member.displayName) end
		end
		if #state.councils == 0 then table.insert(lines, "No council available to this player.") end
		table.insert(lines, "Seats grant no permissions or bonuses. Council chat includes all direct subjects.")
		body.Text = table.concat(lines, "\n")
	end)
	local intent = remotes:WaitForChild("CouncilClientEvent") :: RemoteEvent
	intent:FireServer("Ready")
end
return Controller
