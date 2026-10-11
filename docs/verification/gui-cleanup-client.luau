--!strict
-- Temporary normal LocalScript; never included by production Bootstrap.
local player = game.Players.LocalPlayer
local gui = player.PlayerGui:WaitForChild("HierarchyPrototypeGui")
local controllers = player.PlayerScripts:WaitForChild("Controllers")
repeat task.wait(0.1) until gui:GetAttribute("MapContextEnabled")
local Map = require(controllers.TerritoryMapController)
local Context = require(controllers.MapContextController)
local Strategy = require(controllers.StrategyPresentationController)
local Overview = require(controllers.RealmOverviewController)
local Theme = require(game.ReplicatedStorage.Shared.Util.PrototypeGuiTheme)
local Transitions = require(game.ReplicatedStorage.Shared.Util.ContextTransitions)
local function verify()
	for _, name in { "TerritoryInfo", "DiplomacyPanel", "MilitaryPanel" } do
		assert(not gui:FindFirstChild(name), "Retired surface replicated: " .. name)
	end
	for _, name in { "Territory", "Diplomacy", "Military" } do assert(not gui.StrategyNavigation:FindFirstChild(name)) end
	assert(not gui.Main:FindFirstChild("PlayerList"))
	assert(not gui.Templates:FindFirstChild("DiplomacyRow") and not gui.Templates:FindFirstChild("PlayerRow"))
	Map.Select("northvale"); task.wait(0.3)
	assert(Transitions.IsOpen(gui.ContextRadialPanel), "Own province actions")
	assert(gui.ContextRadialPanel.BackgroundTransparency >= 0.419, "Map visible through radial")
	Context.OpenWorkflow("Info"); task.wait(0.3)
	assert(Transitions.IsOpen(gui.ContextWorkflowPanel) and not Transitions.IsOpen(gui.ContextRadialPanel))
	assert(not gui.ContextWorkflowPanel.Content.Actions:FindFirstChildWhichIsA("TextButton"), "No legacy Info route")
	Map.Select("northvale"); task.wait(0.1); Context.OpenWorkflow("Military"); task.wait(0.3)
	assert(Transitions.IsOpen(gui.MilitaryWorkflowPanel), "Contextual military")
	assert(gui.MilitaryWorkflowPanel.Content.RecruitButton.Visible, "Retained recruitment controls")
	Map.Select(nil); task.wait(0.3)
	assert(gui:GetAttribute("SelectedSystem") == "Map" and not gui.MilitaryWorkflowPanel.Visible, "Empty map closes military")
	for _, name in { "Realm", "Titles", "Economy", "Communications" } do
		Strategy.OpenSystem(name); Map.Select(nil); task.wait(.05)
		assert(gui:GetAttribute("SelectedSystem") == name, "Intentional global view survives empty map selection")
	end
	Overview.SetOpen(true); task.wait(0.1); assert(gui:GetAttribute("RealmOverviewOpen")); Overview.SetOpen(false)
	Strategy.OpenSystem("Map")
	local original = table.clone(Theme.Presentation)
	for _, speed in { 0.5, 1, 2 } do
	for _, animations in { false, true } do
		local values = table.clone(original); values.AnimationSpeed = speed; values.AnimationsEnabled = animations; Theme.SetPresentation(values)
		Map.Select("northvale"); task.wait(); Context.OpenWorkflow("Info"); Map.Select("northvale"); Map.Select(nil)
		task.wait(0.3)
		assert(not gui.ContextRadialPanel.Visible and not gui.ContextWorkflowPanel.Visible, "Rapid transition cleanup")
		assert(not gui.ContextRadialPanel.Interactable and not gui.ContextWorkflowPanel.Interactable, "Closed context releases input")
	end
	end
	Theme.SetPresentation(original)
	Map.Select("northvale")
	print("GUI_CLEANUP_SOLO_PASS", gui.AbsoluteSize)
end
gui:GetAttributeChangedSignal("GuiCleanupVerify"):Connect(verify)
verify()
