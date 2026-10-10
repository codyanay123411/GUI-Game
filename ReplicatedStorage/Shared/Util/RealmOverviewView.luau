--!strict
-- Read-only, allowlisted presentation projection. Never exposes resources or requests.
local View = {}

function View.Build(connected: { any }, localUserId: number, states: any, sortMode: string): { any }
	local rulers, users, personal, realm, direct = {}, {}, {}, {}, {}
	for _, ruler in (states.Hierarchy or {}).rulers or {} do
		rulers[ruler.rulerId] = ruler
		if ruler.userId then users[tonumber(ruler.userId)] = ruler end
	end
	for _, territory in (states.Territory or {}).territories or {} do
		local owner = rulers[territory.ownerRulerId]
		if owner then
			personal[owner.rulerId] = (personal[owner.rulerId] or 0) + 1
			realm[owner.rootRulerId] = (realm[owner.rootRulerId] or 0) + 1
		end
	end
	for _, contact in (states.Communications or {}).contacts or {} do direct[contact.userId] = true end
	local me = users[localUserId]
	local localRoot = if me then me.rootRulerId else nil
	local function name(id: string?): string
		local ruler = if id then rulers[id] else nil
		return if ruler then ruler.displayName else "Awaiting ruler"
	end
	local rows = {}
	for _, player in connected do
		local ruler = users[player.UserId]
		local relation, allied, nap, war = "Unrelated", false, false, false
		local root = if ruler then ruler.rootRulerId else nil
		if me and ruler then
			for _, agreement in (states.Diplomacy or {}).agreements or {} do
				if (agreement.leftRulerId == localRoot and agreement.rightRulerId == root)
					or (agreement.rightRulerId == localRoot and agreement.leftRulerId == root) then
					allied, nap = agreement.alliance == true, agreement.nap == true
				end
			end
			for _, active in (states.Warfare or {}).wars or {} do
				if (active.attackerRootId == localRoot and active.defenderRootId == root)
					or (active.defenderRootId == localRoot and active.attackerRootId == root) then war = true end
			end
			if player.UserId == localUserId then relation = "You"
			elseif me.liegeId == ruler.rulerId then relation = "Your liege"
			elseif ruler.liegeId == me.rulerId then relation = "Your subject"
			elseif root == localRoot then relation = "Your realm"
			elseif war then relation = "At war"
			elseif allied then relation = if nap then "Ally / NAP" else "Ally"
			elseif nap then relation = "NAP" end
		end
		local independent = ruler ~= nil and ruler.independent == true
		table.insert(rows, {
			userId = player.UserId, displayName = player.DisplayName, username = player.Name,
			localPlayer = player.UserId == localUserId, title = if ruler then ruler.titleName else "Pending",
			rank = if ruler then ruler.titleRank else 0, independent = independent,
			status = if not ruler then "Awaiting ruler" elseif independent then "Independent" else "Subject",
			liege = if ruler and ruler.liegeId and ruler.liegeId ~= "" then name(ruler.liegeId) else "None",
			root = if ruler then name(root) else "Awaiting ruler",
			personal = if ruler and states.Territory then personal[ruler.rulerId] or 0 else nil,
			realm = if ruler and states.Territory then realm[root] or 0 else nil,
			subjectCount = if ruler then #(ruler.vassalIds or {}) else 0,
			relation = relation, allied = allied, nap = nap, war = war,
			direct = if player.UserId == localUserId then "Self" elseif not states.Communications then "Awaiting state"
				elseif direct[player.UserId] then "Available" else "Unavailable",
			diplomacy = if not me or not ruler then "Awaiting state" elseif independent and me.independent and root ~= localRoot then "Use Diplomacy"
				elseif root == localRoot then "Internal realm" else "Root ruler acts",
		})
	end
	table.sort(rows, function(a, b)
		if sortMode == "Name" then
			-- Names alone below.
		elseif sortMode == "Title" then
			if a.rank ~= b.rank then return a.rank > b.rank end
		elseif sortMode == "Territory" then
			if (a.personal or -1) ~= (b.personal or -1) then return (a.personal or -1) > (b.personal or -1) end
		else
			if a.independent ~= b.independent then return a.independent end
			if a.rank ~= b.rank then return a.rank > b.rank end
			if (a.realm or -1) ~= (b.realm or -1) then return (a.realm or -1) > (b.realm or -1) end
		end
		local an, bn = string.lower(a.displayName), string.lower(b.displayName)
		if an ~= bn then return an < bn end
		if a.username ~= b.username then return a.username < b.username end
		return a.userId < b.userId
	end)
	return rows
end

return View
