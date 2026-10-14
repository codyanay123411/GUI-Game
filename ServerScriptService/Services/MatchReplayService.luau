--!strict
-- A new reserved server per request. Never reuse an ended JobId or reset this match.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local MatchState = require(script.Parent.MatchState)
local Requests = require(script.Parent.ReplayRequests)
local Service = {}
local router: any = nil
local push: RemoteEvent
local tokens: { [Player]: { id: number, token: string } } = {}
local function connected(player: Player): boolean return player.Parent == Players end
function Service.Start(serverPush: RemoteEvent)
	if router then return end
	push = serverPush
	router = Requests.Create({
		description = "Request a fresh reserved match, starting with you alone. Other players stay in this finished match.",
		clock = os.clock, ended = MatchState.IsEnded, connected = connected, spawn = task.spawn,
		available = function()
			if RunService:IsStudio() then return false, "Play Again needs the published Roblox game; Studio cannot transfer players. You can keep inspecting this result." end
			if game.PlaceId <= 0 then return false, "This place needs a published destination before Play Again can transfer you." end
			return true, ""
		end,
		publish = function(player: Player, status: any) push:FireClient(player, "ReplayStatus", HttpService:JSONEncode(status)) end,
		log = function(err: any) warn("[Replay] transfer failed", tostring(err)) end,
		teleport = function(player: Player, id: number)
			local options = Instance.new("TeleportOptions")
			options.ShouldReserveServer = true
			local token = HttpService:GenerateGUID(false)
			tokens[player] = { id = id, token = token }
			-- Correlation only: no resources, ranks, permissions or destination reset flag.
			options:SetTeleportData({ replayRequest = token })
			TeleportService:TeleportAsync(game.PlaceId, { player }, options)
		end,
	})
	TeleportService.TeleportInitFailed:Connect(function(player, _, _, placeId, options)
		if placeId ~= game.PlaceId or not options then return end
		local ok, data = pcall(function() return options:GetTeleportData() end)
		local current = tokens[player]
		if ok and typeof(data) == "table" and current and data.replayRequest == current.token then
			if router.Fail(player, current.id, "Roblox couldn't complete the transfer. You're still here. Try Play Again again.") then tokens[player] = nil end
		end
	end)
	Players.PlayerRemoving:Connect(function(player) router.Remove(player); tokens[player] = nil end)
end
function Service.SendStatus(player: Player)
	if router and connected(player) then push:FireClient(player, "ReplayStatus", HttpService:JSONEncode(router.Status(player))) end
end
function Service.Request(player: Player)
	if router then router.Request(player) end
end
return Service
