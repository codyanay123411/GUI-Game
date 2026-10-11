--!strict
-- Temporary Studio Local Server fixture. Never part of production Bootstrap.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Services = game.ServerScriptService.Services
local Hierarchy = require(Services.PoliticalHierarchyService)
local Territory = require(Services.TerritoryMapService)
local Diplomacy = require(Services.DiplomacyService)
local Warfare = require(Services.WarfareService)
local Military = require(Services.MilitaryService)
local control = ReplicatedStorage:WaitForChild("ContextVerification")
repeat task.wait(0.1) until #Players:GetPlayers() == 3 and #Hierarchy.GetSnapshot().rulers == 3
local players = Players:GetPlayers()
table.sort(players, function(a, b) return a.Name < b.Name end)
local ids = {}
for index, player in players do
	ids[index] = Hierarchy.GetRulerIdForUserId(player.UserId)
	player:SetAttribute("ContextTestIndex", index)
end
for _, t in Territory.GetMapDefinition().territories do assert(Territory.SetOwner(t.id, nil)) end
assert(Territory.SetOwner("westmere", ids[1]))
assert(Territory.SetOwner("northvale", ids[2]))
assert(Territory.SetOwner("highmarch", ids[3]))
for _, id in ids do assert(Military.DebugSetTroops(id, 1000)) end
local allianceRequest: string? = nil
local hierarchyRequest: string? = nil
local warId: string? = nil
control:SetAttribute("Phase", "V2:Baseline")
print("CONTEXT_MP_SERVER_READY", table.concat(ids, ","))
control:GetAttributeChangedSignal("Step"):Connect(function()
	local step = string.gsub(control:GetAttribute("Step") or "", "^V2:", "")
	if step == "Offer" then
		local ok, id = Diplomacy.Offer(ids[2], ids[1], "Alliance"); assert(ok, id); allianceRequest = id
		local accepted, request = Hierarchy.OfferFealty(ids[3], ids[1]); assert(accepted, request); hierarchyRequest = request
		control:SetAttribute("Phase", "V2:Offers")
	elseif step == "Accept" then
		assert(Diplomacy.Accept(allianceRequest, ids[1]))
		assert(Hierarchy.AcceptFealty(hierarchyRequest, ids[1]))
		control:SetAttribute("Phase", "V2:Relationships")
	elseif step == "ManualAccepted" then
		assert(#Diplomacy.GetSnapshot().requests == 0 and #Hierarchy.GetSnapshot().requests == 0)
		control:SetAttribute("Phase", "V2:Relationships")
	elseif step == "NAP" then
		local ok, id = Diplomacy.Offer(ids[2], ids[1], "NAP"); assert(ok, id); assert(Diplomacy.Accept(id, ids[1]))
		control:SetAttribute("Phase", "V2:NAP")
	elseif step == "Messages" then
		control:SetAttribute("Phase", "V2:Messages")
	elseif step == "War" then
		assert(Diplomacy.Break(ids[1], ids[2], "NAP"))
		local ok, id = Warfare.DeclareWar(ids[2], "westmere"); assert(ok, id); warId = id
		control:SetAttribute("Phase", "V2:War")
	elseif step == "CancelWar" then
		Warfare.CancelWar(warId, "Context verification cleanup")
		control:SetAttribute("Phase", "V2:WarResolved")
	elseif step == "Disconnect" then
		players[3]:Kick("Context verification disconnect case")
		control:SetAttribute("Phase", "V2:Disconnected")
	end
	print("CONTEXT_MP_SERVER_STEP", step)
end)
