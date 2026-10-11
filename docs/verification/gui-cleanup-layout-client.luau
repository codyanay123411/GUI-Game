--!strict
-- Temporary LocalScript: exercise real layouts in the current Studio device profile.
local p = game.Players.LocalPlayer
local gui = p.PlayerGui:WaitForChild("HierarchyPrototypeGui")
local c = p.PlayerScripts:WaitForChild("Controllers")
local Map = require(c.TerritoryMapController)
local Context = require(c.MapContextController)
local Radial = require(c.ContextRadialController)
repeat task.wait(.3) until gui:GetAttribute("MapContextEnabled")
local function within(item: GuiObject, container: GuiObject)
	local a, b = item.AbsolutePosition, container.AbsolutePosition
	local s, t = item.AbsoluteSize, container.AbsoluteSize
	assert(a.X >= b.X - 1 and a.Y >= b.Y - 1 and a.X + s.X <= b.X + t.X + 1 and a.Y + s.Y <= b.Y + t.Y + 1, item.Name .. " outside container")
end
local function overlaps(a: GuiObject, b: GuiObject): boolean
	local x, y = a.AbsolutePosition, b.AbsolutePosition
	local s, t = a.AbsoluteSize, b.AbsoluteSize
	return x.X < y.X + t.X and y.X < x.X + s.X and x.Y < y.Y + t.Y and y.Y < x.Y + s.Y
end
local function verify()
	task.wait(.3)
	Map.Select("northvale"); task.wait(.3)
	Context.OpenWorkflow("War"); task.wait(.3)
	local shell = gui.ContextWorkflowPanel
	local drawer = shell.Content
	assert(shell.Visible, "Review drawer visible")
	within(shell, gui)
	assert(drawer.Body.TextBounds.Y <= drawer.Body.AbsoluteSize.Y + 1, "Review text reflows")
	assert(drawer.CancelButton.Position.Y.Offset < drawer.CanvasSize.Y.Offset, "Cancel reachable by scrolling")
	Map.Select("northvale"); task.wait(.3); Context.OpenWorkflow("Military"); task.wait(.3)
	local military = gui.MilitaryWorkflowPanel
	within(military, gui)
	assert(military.Content.CommitBody.TextBounds.Y <= military.Content.CommitBody.AbsoluteSize.Y + 1, "Military text reflows")
	assert(military.Content.BackButton.Position.Y.Offset + 36 < military.Content.CanvasSize.Y.Offset, "Military back reachable")
	Map.Select("westmere"); task.wait(.3)
	local actions = {}
	for _, id in { "Info", "War", "Diplomacy", "Message", "Realm", "Military" } do table.insert(actions, { id = id, label = id }) end
	for _, relation in { "Non-Aggression Pact", "Your personal holding", "Your direct subject", "Your liege", "Your greater realm", "Unrelated ruler", "Current enemy", "Unclaimed" } do
		Radial.Show({ definition = { displayName = "Sunbarrow" }, relation = relation, actions = actions }, Vector2.new(gui.AbsoluteSize.X - 8, gui.AbsoluteSize.Y - 8))
		task.wait(.3)
		local panel = gui.ContextRadialPanel
		within(panel, gui)
		for _, child in panel:GetChildren() do
			if child:IsA("TextButton") then within(child, panel); assert(not overlaps(child, panel.Heading), "Action overlaps heading: " .. child.Name) end
		end
		assert(panel.Heading.TextBounds.Y <= panel.Heading.AbsoluteSize.Y + 1, "Heading reflows: " .. relation)
	end
	print("GUI_CLEANUP_LAYOUT_PASS", gui.AbsoluteSize, require(game.ReplicatedStorage.Shared.Util.PrototypeGuiTheme).Presentation.UIScale)
end
gui:GetAttributeChangedSignal("GuiCleanupLayoutVerify"):Connect(verify)
verify()
