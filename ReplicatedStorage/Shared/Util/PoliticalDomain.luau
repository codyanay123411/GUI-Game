--!strict
-- Public hierarchy geometry only, never authority or client mutation permission.
local Domain = {}
function Domain.Index(rows: { any }): { [string]: any }
	local out = {}
	for _, row in rows do out[row.rulerId] = row end
	return out
end
function Domain.Ancestors(rows: { any }, id: string): { string }
	local byId, seen, result = Domain.Index(rows), {}, {}
	while byId[id] and not seen[id] do
		seen[id] = true
		table.insert(result, id)
		id = byId[id].liegeId
	end
	return result
end
function Domain.Contains(rows: { any }, actor: string, member: string): boolean
	return table.find(Domain.Ancestors(rows, member), actor) ~= nil
end
function Domain.Members(rows: { any }, actor: string): { string }
	local ids = {}
	for _, row in rows do if Domain.Contains(rows, actor, row.rulerId) then table.insert(ids, row.rulerId) end end
	table.sort(ids)
	return ids
end
function Domain.Signature(rows: { any }, actor: string): string
	return table.concat(Domain.Ancestors(rows, actor), "/") .. ":" .. table.concat(Domain.Members(rows, actor), ",")
end
function Domain.TreatyApplies(rows: { any }, agreements: { any }, actor: string, targetOwner: string): boolean
	local a, b = Domain.Ancestors(rows, actor), Domain.Ancestors(rows, targetOwner)
	for _, pact in agreements do
		if pact.nap and ((table.find(a, pact.leftRulerId) and table.find(b, pact.rightRulerId))
			or (table.find(a, pact.rightRulerId) and table.find(b, pact.leftRulerId))) then return true end
	end
	return false
end
return Domain
