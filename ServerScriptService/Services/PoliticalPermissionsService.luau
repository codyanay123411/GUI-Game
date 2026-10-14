--!strict
-- Ordinary direct-liege permissions; never admin privileges or council-seat powers.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local Hierarchy = require(script.Parent.PoliticalHierarchyService)
local Match = require(script.Parent.MatchState)
local Policy = require(script.Parent.PoliticalPermissionPolicy)
local Domain = require(ReplicatedStorage.Shared.Util.PoliticalDomain)
local Service = {}
local started = false
local grants: { [string]: any } = {}
local lastPayload: { [Player]: string } = {}
local push: RemoteEvent
Service.Changed = Instance.new("BindableEvent")
local function edge(id: string, ruler: any): any
	local row = grants[id]
	if not row or row.liegeId ~= ruler.liegeId then
		row = { liegeId = ruler.liegeId, revision = if row then row.revision + 1 else 1, War = false, Diplomacy = false }
		grants[id] = row
	end
	return row
end
function Service.GetEffective(id: string): any
	local ruler = Domain.Index(Hierarchy.GetSnapshot().rulers)[id]
	local row = if ruler and not ruler.independent then edge(id, ruler) else {}
	if ruler and ruler.independent then return Policy.Effective(ruler, nil, nil, row, Match.IsEnded()) end
	-- Lazy authority dependency avoids the Military -> Warfare require cycle.
	local Authority = require(script.Parent.PoliticalCouncilService)
	local own = Authority.GetAuthority(id)
	local liege = if ruler and ruler.liegeId ~= "" then Authority.GetAuthority(ruler.liegeId) else nil
	return Policy.Effective(ruler, own, liege, row, Match.IsEnded())
end
function Service.Can(id: string, permission: string): (boolean, string)
	local effective = Service.GetEffective(id)
	if permission == "War" then return effective.war, effective.warReason end
	if permission == "Diplomacy" then return effective.diplomacy, effective.diplomacyReason end
	return false, "Unknown permission"
end
function Service.GetEdgeRevision(id: string): number?
	local ruler = Domain.Index(Hierarchy.GetSnapshot().rulers)[id]
	return if ruler then edge(id, ruler).revision else nil
end
function Service.GetForPlayer(player: Player): any
	local rows = Hierarchy.GetSnapshot().rulers
	local id = Hierarchy.GetRulerIdForUserId(player.UserId)
	local subjects = {}
	if id then
		for _, ruler in rows do
			if ruler.liegeId == id then
				local grant = edge(ruler.rulerId, ruler)
				table.insert(subjects, { rulerId = ruler.rulerId, displayName = ruler.displayName, titleName = ruler.titleName,
					warGranted = grant.War, diplomacyGranted = grant.Diplomacy, revision = grant.revision })
			end
		end
	end
	table.sort(subjects, function(a, b) return if a.displayName == b.displayName then a.rulerId < b.rulerId else a.displayName < b.displayName end)
	return { self = if id then Service.GetEffective(id) else {}, subjects = subjects, frozen = Match.IsEnded() }
end
function Service.Refresh()
	if not started then return end
	local rows = Domain.Index(Hierarchy.GetSnapshot().rulers)
	for id in grants do if not rows[id] then grants[id] = nil else edge(id, rows[id]) end end
	for _, player in Players:GetPlayers() do
		local payload = HttpService:JSONEncode(Service.GetForPlayer(player))
		if lastPayload[player] ~= payload then lastPayload[player] = payload; push:FireClient(player, "State", payload) end
	end
	Service.Changed:Fire()
end
function Service.Set(liegeId: string, subjectId: string, permission: string, enabled: boolean, revision: number): (boolean, string)
	if Match.IsEnded() then return false, "Match ended." end
	local subject = Domain.Index(Hierarchy.GetSnapshot().rulers)[subjectId]
	if not subject or subject.liegeId ~= liegeId then return false, "Only the current direct liege may change this subject's permissions." end
	if permission ~= "War" and permission ~= "Diplomacy" then return false, "Unknown permission." end
	if typeof(enabled) ~= "boolean" then return false, "Invalid permission value." end
	local row = edge(subjectId, subject)
	if revision ~= row.revision then return false, "Permissions changed. Review the current row and retry." end
	row[permission] = enabled
	row.revision += 1
	Service.Refresh()
	return true, permission .. (if enabled then " permission granted." else " permission revoked.")
end
function Service.Start()
	if started then return end
	started = true
	local remotes = ReplicatedStorage.Remotes
	local function remote(name: string): RemoteEvent
		local item = remotes:FindFirstChild(name) or Instance.new("RemoteEvent")
		assert(item:IsA("RemoteEvent")); item.Name = name; item.Parent = remotes
		return item
	end
	push = remote("PermissionsServerEvent")
	remote("PermissionsClientEvent").OnServerEvent:Connect(function(player, action, subject, permission, enabled, revision)
		if action == "Ready" then push:FireClient(player, "State", HttpService:JSONEncode(Service.GetForPlayer(player))); return end
		local id = Hierarchy.GetRulerIdForUserId(player.UserId)
		if action ~= "Set" or not id or typeof(subject) ~= "string" then return end
		local ok, message = Service.Set(id, subject, permission, enabled, revision)
		push:FireClient(player, "PermissionResult", HttpService:JSONEncode({ subject = subject, permission = permission, revision = revision, accepted = ok, message = message }))
		if not ok then push:FireClient(player, "State", HttpService:JSONEncode(Service.GetForPlayer(player))) end
	end)
	Hierarchy.SetPermissionsRefresh(Service.Refresh)
	require(script.Parent.PoliticalCouncilService).AuthorityChanged:Connect(Service.Refresh)
	Players.PlayerRemoving:Connect(function(player) lastPayload[player] = nil end)
	Service.Refresh()
end
return Service
