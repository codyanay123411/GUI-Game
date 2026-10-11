--!strict
-- Temporary normal LocalScript. Message cases inject the semantic receipt event;
-- they verify presentation only, not native TextChatService transport/filter/privacy.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer
local gui = player.PlayerGui:WaitForChild("HierarchyPrototypeGui")
local Controllers = player.PlayerScripts:WaitForChild("Controllers")
local State = require(Controllers.MapContextState)
local Map = require(Controllers.TerritoryMapController)
local Context = require(Controllers.MapContextController)
local Communications = require(Controllers.CommunicationsController)
local Transitions = require(ReplicatedStorage.Shared.Util.ContextTransitions)
local Strategy = require(Controllers.StrategyPresentationController)
local Resolver = require(ReplicatedStorage.Shared.Util.ContextActionResolver)
local definitions = require(ReplicatedStorage.Shared.Config.MapCatalog).GetDefault().territories
local control = ReplicatedStorage:WaitForChild("ContextVerification")
repeat task.wait(0.1) until gui:GetAttribute("MapContextEnabled") and player:GetAttribute("ContextTestIndex")
local index = player:GetAttribute("ContextTestIndex")
local passed = 0
local function check(value: any, description: string)
	assert(value, description)
	passed += 1
end
local function resolve(id: string, ended: boolean?): any
	return Resolver.Resolve(State, definitions, id, player.UserId, ended == true, workspace:GetServerTimeNow())
end
local function has(context: any, id: string): boolean
	for _, action in context.actions do if action.id == id then return true end end
	return false
end
local function channel(context: any, text: string): boolean
	for _, item in context.communication do if item.label == text then return true end end
	return false
end
local phaseToken = 0
local function phase()
	phaseToken += 1
	local token = phaseToken
	local name = string.gsub(control:GetAttribute("Phase") or "", "^V2:", "")
	task.wait(0.8)
	if token ~= phaseToken then return end
	if name == "Baseline" then
		check(#State.hierarchy.rulers == 3, "Three authoritative rulers")
		local own = ({ "westmere", "northvale", "highmarch" })[index]
		Map.Select(own); task.wait(0.05)
		check(gui.ContextRadialPanel.Visible, "Own province radial opens")
		check(gui.ContextRadialPanel:FindFirstChild("Military"), "Own military action")
		Context.OpenWorkflow("Info"); task.wait(0.3)
		check(gui.ContextWorkflowPanel.Visible, "Focused info opens")
		check(string.find(gui.ContextWorkflowPanel.Content.Body.Text, "Personal holdings: 1", 1, true), "Public holdings displayed")
		Map.Select(nil); task.wait(0.3)
		check(not gui.ContextWorkflowPanel.Visible and not gui.ContextRadialPanel.Visible, "Empty selection closes both")
		check(not gui:FindFirstChild("TerritoryInfo") and not gui:FindFirstChild("DiplomacyPanel") and not gui:FindFirstChild("MilitaryPanel"), "Retired panels absent on every client")
		for _, name in { "Territory", "Diplomacy", "Military" } do check(not gui.StrategyNavigation:FindFirstChild(name), "Retired navigation absent") end
		Map.Select(own); task.wait(0.1); Context.OpenWorkflow("Military"); task.wait(0.3)
		check(Transitions.IsOpen(gui.MilitaryWorkflowPanel), "Own contextual recruitment")
		Map.Select(nil); task.wait(0.3)
		check(not gui.MilitaryWorkflowPanel.Visible, "Military click-away lifecycle")
		if index == 1 then
			check(has(resolve("northvale"), "War"), "Neighbor war review")
			check(not has(resolve("highmarch"), "War"), "Distant no declaration")
		end
		if index == 1 then Map.Select(own); task.wait(.1); Context.OpenWorkflow("Military"); task.wait(.3) end
	elseif name == "Offers" and index == 1 then
		check(gui.DiplomacyOfferOverlay.Visible and gui.VassalageOfferOverlay.Visible, "Both original offer notifications retained")
		check(gui.MapAttentionLayer:FindFirstChild("Attention_northvale"), "Alliance offer at sender border")
		check(gui.MapAttentionLayer:FindFirstChild("Attention_highmarch"), "Vassalage offer at sender holding")
		check(not gui.ContextRadialPanel.Visible and not gui.ContextWorkflowPanel.Visible and not gui.MilitaryWorkflowPanel.Visible and gui:GetAttribute("SelectedSystem") == "Map", "Priority offers hide all territory context")
	elseif name == "Relationships" then
		check(#State.diplomacy.requests == 0 and #State.hierarchy.requests == 0, "Offers consumed")
		if index == 1 then
			check(not gui.MapAttentionLayer:FindFirstChild("Attention_northvale"), "Resolved alliance marker removed")
			check(not gui.MapAttentionLayer:FindFirstChild("Attention_highmarch"), "Resolved hierarchy marker removed")
			check(has(resolve("northvale"), "War"), "Alliance does not change accepted war rule")
			check(channel(resolve("highmarch"), "Council — Player1"), "Distant direct subject Council channel")
			check(not has(resolve("highmarch"), "War"), "Own realm no external war")
		elseif index == 3 then check(not has(resolve("greyfen"), "War"), "Subject no independent external declaration") end
	elseif name == "Messages" and index == 1 then
		Strategy.OpenSystem("Map")
		local others = {}
		for _, r in State.hierarchy.rulers do others[r.displayName] = r end
		local sender = others.Player2
		local distant = others.Player3
		local allyId = ""
		for _, c in State.communications.contexts do if c.kind == "alliance" and c.canSend then allyId = c.id end end
		check(allyId ~= "", "Authoritative distinct Allies context")
		Communications.Received:Fire({ id = "fixture1", userId = sender.userId, contextId = allyId, kind = "alliance" })
		Communications.Received:Fire({ id = "fixture2", userId = sender.userId, contextId = allyId, kind = "alliance" })
		Communications.Received:Fire({ id = "fixture3", userId = distant.userId, contextId = "council:" .. resolve("westmere").me.rulerId, kind = "council" })
		task.wait(0.2)
		check(gui.MapAttentionLayer.Attention_northvale.Text == "… 2", "Bordering ally messages aggregate")
		check(gui.MapAttentionLayer.Attention_highmarch.Text == "…", "Distant sender stable personal anchor")
	elseif name == "NAP" and index == 1 then
		check(not has(resolve("northvale"), "War"), "NAP removes war review")
		check(resolve("northvale").relation == "Non-Aggression Pact", "Treaty relation updates")
	elseif name == "War" and (index == 1 or index == 2) then
		check(gui.MapAttentionLayer:FindFirstChild("Attention_westmere"), "War at actual target, not attacker holding")
		check(has(resolve("westmere"), "Battle"), "Relevant current battle action")
		Map.Select("westmere"); task.wait(0.1); Context.OpenWorkflow("Battle"); task.wait(0.3)
		check(Transitions.IsOpen(gui.MilitaryWorkflowPanel), "Target commitment via existing military controller")
		check(not gui.MilitaryWorkflowPanel.Content.RecruitButton.Visible, "Battle has no duplicate recruiting controls")
	elseif name == "WarResolved" and (index == 1 or index == 2) then
		check(not gui.MapAttentionLayer:FindFirstChild("Attention_westmere"), "Cancelled war marker removed")
	elseif name == "Disconnected" and index == 1 then
		local deadline = os.clock() + 5
		repeat task.wait(0.1) until #State.hierarchy.rulers == 2 or os.clock() >= deadline
		task.wait(0.1)
		check(#State.hierarchy.rulers == 2, "Authoritative disconnect snapshot arrived")
		check(not gui.MapAttentionLayer:FindFirstChild("Attention_highmarch"), "Disconnected sender marker cleared")
	end
	print("GUI_CLEANUP_MP_CLIENT_PASS", player.Name, name, passed)
end
control:GetAttributeChangedSignal("Phase"):Connect(phase)
phase()
