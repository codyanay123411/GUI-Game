--!strict

--[[
	Client entry point.

	This script is the thin bootstrap for local player startup.
	When controllers exist under StarterPlayer.StarterPlayerScripts.Controllers,
	require and start them from here in a defined order.

	Controllers own client behavior and GUI control only.
	Never treat client input or GUI state as authoritative game truth.

	Must be a LocalScript (Script Sync: Bootstrap.local.luau). A Script with
	RunContext=Client under StarterPlayerScripts runs twice and duplicates GUI.
]]

local PoliticalHierarchyController = require(script.Parent.Controllers.PoliticalHierarchyController)
local TerritoryMapController = require(script.Parent.Controllers.TerritoryMapController)
local TitleProgressionController = require(script.Parent.Controllers.TitleProgressionController)
local DiplomacyController = require(script.Parent.Controllers.DiplomacyController)
local WarfareController = require(script.Parent.Controllers.WarfareController)
local EconomyController = require(script.Parent.Controllers.EconomyController)
local MilitaryController = require(script.Parent.Controllers.MilitaryController)
local AdminFeedbackController = require(script.Parent.Controllers.AdminFeedbackController)
local CommunicationsController = require(script.Parent.Controllers.CommunicationsController)
PoliticalHierarchyController.Start()
require(script.Parent.Controllers.PoliticalCouncilController).Start()
require(script.Parent.Controllers.PoliticalPermissionsController).Start()
TerritoryMapController.Start()
TitleProgressionController.Start()
DiplomacyController.Start()
WarfareController.Start()
EconomyController.Start()
MilitaryController.Start()
CommunicationsController.Start()
AdminFeedbackController.Start()
require(script.Parent.Controllers.StrategyPresentationController).Start()

require(script.Parent.Controllers.VictoryController).Start()
require(script.Parent.Controllers.MapContextController).Start()
require(script.Parent.Controllers.MapAttentionController).Start()
require(script.Parent.Controllers.GameSettingsController).Start()
