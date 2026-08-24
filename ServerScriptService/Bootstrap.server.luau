--!strict

--[[
	Server entry point.

	This script is the thin bootstrap for authoritative server startup.
	When services exist under ServerScriptService.Services, require and
	start them from here in a defined order.

	Order: Hierarchy → Territory → Title → Diplomacy → Warfare → Economy → Admin.
	Economy starts after Territory (ownership/config) and Hierarchy (ruler lifecycle).

	Do not put gameplay, GUI, or client-trusted logic in this file.
	Keep it an orchestrator so systems stay in their own modules.
]]

local PoliticalHierarchyService = require(script.Parent.Services.PoliticalHierarchyService)
local TerritoryMapService = require(script.Parent.Services.TerritoryMapService)
local TitleProgressionService = require(script.Parent.Services.TitleProgressionService)
local DiplomacyService = require(script.Parent.Services.DiplomacyService)
local WarfareService = require(script.Parent.Services.WarfareService)
local EconomyService = require(script.Parent.Services.EconomyService)
local AdminService = require(script.Parent.Services.AdminService)
PoliticalHierarchyService.Start()
TerritoryMapService.Start()
TitleProgressionService.Start()
DiplomacyService.Start()
WarfareService.Start()
EconomyService.Start()
AdminService.Start()
