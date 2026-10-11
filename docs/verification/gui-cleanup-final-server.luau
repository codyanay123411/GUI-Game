--!strict
-- Install gui-cleanup-victory-client.luau in remaining PlayerGui instances through Studio before running this Script.
local control=game.ReplicatedStorage.ContextVerification
control:SetAttribute("Step","V2:CancelWar")
task.wait(3)
control:SetAttribute("Step","V2:Disconnect")
task.wait(3)
local T=require(game.ServerScriptService.Services.TerritoryMapService)
for _,t in T.GetMapDefinition().territories do T.SetOwner(t.id,"Player_-1") end
print("GUI_CLEANUP_VICTORY_SETUP")
