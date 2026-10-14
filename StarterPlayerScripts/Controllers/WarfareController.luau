--!strict
local MatchIntent = require(game:GetService("ReplicatedStorage").Shared.Util.MatchIntent)
-- Retained warfare notice adapter. Context state owns snapshots and target workflows.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local WarfareController = {}
local started = false
function WarfareController.Start()
	if started then return end
	started = true
	local gui = Players.LocalPlayer:WaitForChild("PlayerGui"):WaitForChild("HierarchyPrototypeGui")
	local toast = gui:WaitForChild("ResultToast") :: Frame
	local label = toast:WaitForChild("Label") :: TextLabel
	local token = 0
	local remotes = ReplicatedStorage:WaitForChild("Remotes")
	local push = remotes:WaitForChild("WarfareServerEvent") :: RemoteEvent
	MatchIntent.ConnectPush(push, function(kind, payload)
		if kind ~= "Notice" or typeof(payload) ~= "string" then return end
		token += 1
		local current = token
		label.Text = payload
		toast.Visible = true
		local generation = MatchIntent.GetGeneration()
		task.delay(6, function() if generation == MatchIntent.GetGeneration() and current == token then toast.Visible = false end end)
	end)
end
return WarfareController
