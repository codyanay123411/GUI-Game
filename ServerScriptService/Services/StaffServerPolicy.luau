--!strict
local Policy = {}
Policy.HeartbeatSeconds = 30
Policy.ExpirySeconds = 100
function Policy.Kind(privateId: string, ownerId: number): string
	return if privateId == "" then "Public" elseif ownerId > 0 then "Private" else "Reserved"
end
function Policy.Fresh(row: any, at: number): boolean
	return typeof(row) == "table" and typeof(row.id) == "string" and row.id ~= ""
		and (row.kind == "Public" or row.kind == "Private" or row.kind == "Reserved")
		and typeof(row.players) == "number" and row.players >= 0 and row.players % 1 == 0 and row.players < math.huge
		and typeof(row.capacity) == "number" and row.capacity > 0 and row.capacity % 1 == 0 and row.capacity < math.huge
		and typeof(row.updatedAt) == "number" and row.updatedAt <= at+5 and at-row.updatedAt < Policy.ExpirySeconds
end
function Policy.Public(row: any): any
	return { id = row.id, placeId = row.placeId, kind = row.kind, players = row.players, capacity = row.capacity,
		ended = row.ended, joinable = row.joinable, note = row.note }
end
function Policy.Route(row: any, code: string?): (string?, string)
	if row.players >= row.capacity then return nil, "Destination is full." end
	if row.kind == "Public" then return "Instance", "" end
	if row.kind == "Reserved" and code and code ~= "" then return "Reserved", "" end
	return nil, if row.kind == "Reserved" then "Reserved access credentials are unavailable. Staff rank cannot recover them."
		else "Roblox does not provide this project a private-server invitation bypass. Use the owner's Roblox access invitation."
end
return Policy
