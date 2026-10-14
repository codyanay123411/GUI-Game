--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local Hierarchy = require(script.Parent.PoliticalHierarchyService)
local Territory = require(script.Parent.TerritoryMapService)
local MatchState = require(script.Parent.MatchState)
local Domination = require(ReplicatedStorage.Shared.Util.Domination)
local Replay = require(script.Parent.MatchReplayService)
local Service = {}
local started = false
local transactionDepth = 0
local captureDirty = false
function Service.BeginCaptureBatch() transactionDepth += 1 end
function Service.EndCaptureBatch() assert(transactionDepth > 0);transactionDepth -= 1;if transactionDepth == 0 and captureDirty then captureDirty = false;Service.Evaluate() end end
local startedAt = 0
local push: RemoteEvent

function Service.GetSnapshot(): any
	if MatchState.IsEnded() then return MatchState.GetFinal() end
	local result = Domination.Evaluate(Territory.GetMapDefinition(), Hierarchy.GetSnapshot().rulers, Territory.GetSnapshot().territories)
	return { ended = false, type = "Domination", total = result.total, required = result.required, threshold = result.threshold, counts = result.counts }
end

local function send(player: Player?)
	local snapshot = table.clone(Service.GetSnapshot())
	snapshot.generation = MatchState.GetGeneration()
	local payload = HttpService:JSONEncode(snapshot)
	if player then MatchState.Send(push, player, "State", payload) else MatchState.Send(push, nil, "State", payload) end
end

function Service.Restarted()
	startedAt = workspace:GetServerTimeNow()
	Service.Evaluate()
end

function Service.Evaluate(): any
	if transactionDepth > 0 then captureDirty = true;return MatchState.GetFinal() end
	if not started or MatchState.IsEnded() then return MatchState.GetFinal() end
	local rulers = Hierarchy.GetSnapshot().rulers
	local result = Domination.Evaluate(Territory.GetMapDefinition(), rulers, Territory.GetSnapshot().territories)
	if result.winner then
		local root, members = nil, {}
		for _, ruler in rulers do
			if ruler.rulerId == result.winner.rootId then root = ruler end
			if ruler.rootRulerId == result.winner.rootId then
				table.insert(members, { rulerId = ruler.rulerId, userId = ruler.userId, displayName = ruler.displayName, titleName = ruler.titleName })
			end
		end
		assert(root)
		local final = { ended = true, type = "Domination", winnerRootId = root.rulerId, winnerUserId = root.userId,
			winnerName = root.displayName, winnerTitle = root.titleName, realmName = root.displayName .. "'s realm",
			controlled = result.winner.controlled, total = result.total, required = result.required, threshold = result.threshold,
			controlPercent = result.winner.controlled / result.total, members = members, endedAt = workspace:GetServerTimeNow(),
			durationSeconds = workspace:GetServerTimeNow() - startedAt }
		if MatchState.End(final) then
			require(script.Parent.MilitaryService).FreezeMatch()
			require(script.Parent.WarfareService).FreezeMatch()
			print("[Victory] Domination", final.winnerRootId, final.controlled, final.total)
		end
	end
	send(nil)
	return MatchState.GetFinal()
end

function Service.Start()
	if started then return end
	startedAt = workspace:GetServerTimeNow()
	local remotes = ReplicatedStorage:WaitForChild("Remotes")
	push = remotes:WaitForChild("VictoryServerEvent") :: RemoteEvent
	local intent = remotes:WaitForChild("VictoryClientEvent") :: RemoteEvent
	Domination.Evaluate(Territory.GetMapDefinition(), Hierarchy.GetSnapshot().rulers, Territory.GetSnapshot().territories)
	started = true
	Replay.Start(push)
	MatchState.ConnectIntent(intent, function(player, action)
		if action == "Ready" then send(player); Replay.SendStatus(player)
		elseif action == "PlayAgain" then Replay.Request(player) end
	end)
	Hierarchy.StateChanged:Connect(Service.Evaluate)
	Territory.OwnershipChanged:Connect(Service.Evaluate)
	Players.PlayerAdded:Connect(function(player) task.defer(function() if player.Parent then send(player) end end) end)
	Service.Evaluate()
end

return Service
