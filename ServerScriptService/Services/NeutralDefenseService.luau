--!strict
-- Territory-owned militia, never a ruler or player Troop pool.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.Shared.Config.NeutralDefenseConfig)
local MatchState = require(script.Parent.MatchState)
local Service = {}
local defenses: { [string]: { current: number, maximum: number, revision: number } } = {}

function Service.Get(territoryId: string): any
	local Territory = require(script.Parent.TerritoryMapService)
	if Territory.GetOwnerRulerId(territoryId) then return nil end
	local revision = Territory.GetOwnershipRevision(territoryId)
	local row = defenses[territoryId]
	if row and row.revision == revision then return table.clone(row) end
	local map = Territory.GetMapDefinition()
	for _, definition in map.territories do
		if definition.id == territoryId then
			local maximum = definition.unclaimedDefenders or map.unclaimedDefenders or Config.BaseDefenders
			assert(typeof(maximum) == "number" and maximum == math.floor(maximum) and maximum >= 0 and maximum < math.huge, "Invalid Unclaimed defense config")
			row = { current = maximum, maximum = maximum, revision = revision }
			defenses[territoryId] = row
			return table.clone(row)
		end
	end
	return nil
end

function Service.ApplySurvivors(territoryId: string, revision: number, survivors: number): boolean
	if MatchState.IsEnded() then return false end
	local row = Service.Get(territoryId)
	if not row or row.revision ~= revision then return false end
	if typeof(survivors) ~= "number" or survivors ~= math.floor(survivors) or survivors < 0 or survivors > row.current then return false end
	defenses[territoryId].current = survivors
	require(script.Parent.TerritoryMapService).RefreshPublicState()
	return true
end

function Service.DebugSet(territoryId: string, amount: any): (boolean, string)
	if MatchState.IsEnded() then return false, "Match ended." end
	local row = Service.Get(territoryId)
	if not row then return false, "Target must be Unclaimed." end
	local Warfare = require(script.Parent.WarfareService)
	for _, war in Warfare.GetSnapshot().wars do
		if war.targetTerritoryId == territoryId then return false, "Territory is contested." end
	end
	if typeof(amount) ~= "number" or amount ~= math.floor(amount) or amount < 0 or amount > row.maximum then return false, "Defense must be a whole number within its configured maximum." end
	defenses[territoryId].current = amount
	require(script.Parent.TerritoryMapService).RefreshPublicState()
	return true, "Unclaimed defense updated."
end

return Service
