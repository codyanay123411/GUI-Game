--!strict
-- Same-server restart coordinator. Historical filename; no teleport route remains.
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local Match = require(script.Parent.MatchState)
local Votes = require(script.Parent.RestartVotes)
local Service = {}
local started = false
local ledger = Votes.New()
local push: RemoteEvent
local revision = 0
local failure: string? = nil
local function membership(excluded: Player?)
	local ids = {};for _, player in Match.GetConnectedPlayers() do if player ~= excluded then table.insert(ids, player.UserId) end end
	Votes.Update(ledger, ids)
end
local function publish()
	revision += 1
	for _, player in Players:GetPlayers() do Service.SendStatus(player) end
end
function Service.SendStatus(player: Player)
	local row = Votes.Snapshot(ledger, player.UserId)
	row.revision = revision;row.generation = Match.GetGeneration()
	row.description = "Vote to restart this shared match. Everyone stays in this server."
	row.message = failure or string.format("%d / %d votes · %d connected · %d more needed", row.votes, row.required, row.connected, row.needed)
	Match.Send(push, player, "ReplayStatus", HttpService:JSONEncode(row))
end
function Service.GetSnapshot(player: Player?): any
	return Votes.Snapshot(ledger, if player then player.UserId else nil)
end
local function evaluate()
	if not Match.IsEnded() or Match.IsResetting() or not Votes.ShouldRestart(ledger) then return end
	ledger.restarting = true;publish()
	if not Match.BeginReset() then return end
	-- No yields: observers/requests cannot enter a partially reset match.
	local ok, err = pcall(function()
		local function reset(name: string) require(script.Parent[name]).ResetMatch() end
		for _, name in { "CommunicationsService", "WarfareService", "DiplomacyService", "BetrayalService",
			"PoliticalPermissionsService", "PoliticalCouncilService", "NeutralDefenseService" } do reset(name) end
		reset("PoliticalHierarchyService")
		reset("TitleProgressionService")
		reset("BuildingService")
		reset("TerritoryMapService")
		reset("EconomyService")
		reset("MilitaryService")
	end)
	if not ok then
		failure = "Restart could not complete. The match remains frozen; staff must inspect the server error."
		warn("[MatchRestart] reset failed", tostring(err))
		-- Retain the already-public result card and display a failed-closed status.
		-- Do not resume a partially reset match or claim another vote can repair it.
		local final = table.clone(Match.GetFinal());final.generation = Match.GetGeneration()
		push:FireAllClients("State", HttpService:JSONEncode(final), Match.GetGeneration())
		publish();return
	end
	ledger = Votes.New();membership();failure = nil
	Match.FinishReset()
	Match.Send(push, nil, "MatchReset", Match.GetGeneration())
	for _, name in { "PoliticalHierarchyService", "TerritoryMapService", "TitleProgressionService", "EconomyService",
		"MilitaryService", "WarfareService", "DiplomacyService", "PoliticalCouncilService", "CommunicationsService", "BuildingService" } do
		local service = require(script.Parent[name])
		if service.PublishMatch then service.PublishMatch() else service.RefreshPublicState() end
	end
	require(script.Parent.PoliticalPermissionsService).Refresh()
	require(script.Parent.VictoryService).Restarted()
	publish()
end
function Service.Start(serverPush: RemoteEvent)
	if started then return end
	started = true;push = serverPush;membership()
	Players.PlayerAdded:Connect(function() membership();publish();evaluate() end)
	Players.PlayerRemoving:Connect(function(player) membership(player);publish();evaluate() end)
end
function Service.Request(player: Player)
	if not Match.IsEnded() or Match.IsResetting() then Service.SendStatus(player);return end
	membership()
	Votes.Cast(ledger, player.UserId)
	publish();evaluate()
end
return Service
