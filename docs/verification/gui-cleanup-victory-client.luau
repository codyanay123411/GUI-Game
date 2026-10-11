--!strict
-- Temporary normal LocalScript observing authoritative victory replication.
local player = game.Players.LocalPlayer
local gui = player.PlayerGui:WaitForChild("HierarchyPrototypeGui")
repeat task.wait(.1) until gui:GetAttribute("MatchEnded") == true
task.wait(.6)
assert(gui.VictoryOverlay.Visible, "Authoritative result opens")
assert(gui:GetAttribute("SelectedSystem") == "Map", "Result dismisses contextual military")
for _, name in { "ContextRadialPanel", "ContextWorkflowPanel", "MilitaryWorkflowPanel" } do
	assert(not gui[name].Visible and not gui[name].Interactable, "Result clears context: " .. name)
end
assert(gui.MilitaryWorkflowPanel.Content.BackButton.Active, "Back remains an inspection control")
assert(gui.StrategyNavigation.MatchResult.Visible, "Result remains accessible")
assert(not gui:FindFirstChild("TerritoryInfo") and not gui:FindFirstChild("DiplomacyPanel"), "Victory does not restore retired surfaces")
print("GUI_CLEANUP_VICTORY_PASS", player.Name)
