--!strict
-- Quoted, server-only no-yield transaction. Only accepted requests detach/transfer.
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Hierarchy = require(script.Parent.PoliticalHierarchyService)
local Military = require(script.Parent.MilitaryService)
local Warfare = require(script.Parent.WarfareService)
local Permissions = require(script.Parent.PoliticalPermissionsService)
local Authority = require(script.Parent.PoliticalCouncilService)
local Match = require(script.Parent.MatchState)
local Territory = require(script.Parent.TerritoryMapService)
local Config = require(script.Parent.PoliticalAuthorityConfig)
local Domain = require(ReplicatedStorage.Shared.Util.PoliticalDomain)
local Service = {}
local quotes: { [string]: any } = {}
local accepted: { [string]: any } = {}
local function preflight(actor: string, target: string): (boolean, any)
	if Match.IsEnded() then return false, "Match ended." end
	local rows = Hierarchy.GetSnapshot().rulers
	local ruler = Domain.Index(rows)[actor]
	if not ruler or ruler.liegeId == "" then return false, "Betrayal requires a current direct liege." end
	local liegeId = ruler.liegeId
	local own, liege = Authority.GetAuthority(actor), Authority.GetAuthority(liegeId)
	if not own or not liege or own <= liege then return false, "Betrayal requires authority strictly greater than your direct liege." end
	if Warfare.HasBetrayalConflict(actor, liegeId) then return false, "Betrayal unavailable while participants or the departing domain have an active war/result." end
	local valid, reason = Warfare.CheckDeclaration(actor, target, liegeId)
	if not valid then return false, reason end
	local total = Military.GetTotalTroops(actor)
	local penalty = math.floor(total * Config.BetrayalTransferFraction)
	local state = Military.GetInspect(actor)
	if not state or state.committed ~= 0 or state.available < penalty then return false, "Betrayal cannot transfer reserved or held troops." end
	return true, { actor = actor, target = target, liegeId = liegeId, penalty = penalty, total = total, available = state.available,
		liegeTotal = Military.GetTotalTroops(liegeId), ownAuthority = own, liegeAuthority = liege,
		actorDomain = Domain.Signature(rows, actor), liegeDomain = Domain.Signature(rows, liegeId),
		edgeRevision = Permissions.GetEdgeRevision(actor), targetRevision = Territory.GetOwnershipRevision(target) }
end
function Service.Prepare(actor: string, target: string): (boolean, any)
	local valid, result = preflight(actor, target)
	if not valid then quotes[actor] = nil; return false, result end
	result.token = HttpService:GenerateGUID(false)
	result.expiresAt = workspace:GetServerTimeNow() + Config.BetrayalReviewSeconds
	quotes[actor] = result
	-- Own army only. No liege scores, troop counts or global comparison exposed.
	return true, { token = result.token, target = target, liegeId = result.liegeId, penalty = result.penalty,
		availableAfter = result.available - result.penalty, expiresAt = result.expiresAt,
		message = "Betrayal breaks your vassalage, retains your descendants, and transfers floor(30% of your personal Total) to your former direct liege before war begins." }
end
function Service.Commit(actor: string, target: string, token: string): (boolean, any)
	local previous = accepted[actor]
	if previous and previous.token == token and previous.target == target then return true, previous end
	local quote = quotes[actor]
	if not quote or quote.token ~= token or quote.target ~= target then return false, "Betrayal review is no longer valid." end
	if workspace:GetServerTimeNow() >= quote.expiresAt then quotes[actor] = nil; return false, "Betrayal review expired. Review again." end
	local valid, current = preflight(actor, target)
	if not valid then quotes[actor] = nil; return false, current end
	for _, key in { "liegeId", "penalty", "total", "available", "liegeTotal", "ownAuthority", "liegeAuthority", "actorDomain", "liegeDomain", "edgeRevision", "targetRevision" } do
		if quote[key] ~= current[key] then quotes[actor] = nil; return false, "Betrayal conditions changed. Review the current troop transfer again." end
	end
	quotes[actor] = nil -- Consume before staged mutation; no yields through acceptance.
	local detached, why = Hierarchy.StageBetrayalDetach(actor, current.liegeId)
	if not detached then return false, why end
	local transferred, transferReason = Military.StageTroopTransfer(actor, current.liegeId, current.penalty)
	if not transferred then Hierarchy.RestoreBetrayalDetach(actor, current.liegeId); return false, transferReason end
	local declared, warId = Warfare.DeclareWar(actor, target, current.liegeId)
	if not declared then
		assert(Military.StageTroopTransfer(current.liegeId, actor, current.penalty))
		Hierarchy.RestoreBetrayalDetach(actor, current.liegeId)
		return false, warId
	end
	local receipt = { token = token, target = target, warId = warId, penalty = current.penalty, accepted = true }
	accepted[actor] = receipt
	Hierarchy.PublishBetrayal()
	Military.PublishTroopTransfer(actor, current.liegeId)
	return true, receipt
end
function Service.Remove(actor: string)
	quotes[actor], accepted[actor] = nil, nil
end
return Service
