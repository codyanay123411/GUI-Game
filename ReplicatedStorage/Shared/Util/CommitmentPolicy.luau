--!strict
-- Local presentation policy only. The server still validates integer troop amounts.
local Policy = {}
Policy.Stops = table.freeze({ 10, 25, 35, 50, 75 })
function Policy.IsStop(percent: number): boolean
	return table.find(Policy.Stops, percent) ~= nil
end
function Policy.Snap(position: number): number
	local index = math.clamp(math.floor(math.clamp(position, 0, 1) * 4 + 0.5) + 1, 1, 5)
	return Policy.Stops[index]
end
function Policy.Pool(available: number, ownReservation: number?): number
	return math.max(0, math.floor(available)) + math.max(0, math.floor(ownReservation or 0))
end
function Policy.Amount(pool: number, percent: number): number
	assert(Policy.IsStop(percent), "Only fixed commitment stops are selectable")
	return math.floor(math.max(0, pool) * percent / 100)
end

-- Each war has independent edit state. Serialize submissions to correlate existing amounts.
function Policy.New()
	return { percent = nil :: number?, revision = 0, settledRevision = 0,
		amount = nil :: number?, flight = nil :: any, rejected = false }
end
function Policy.Choose(edit: any, percent: number, amount: number)
	assert(Policy.IsStop(percent) and amount >= 0 and amount % 1 == 0)
	edit.percent = percent
	edit.amount = amount
	edit.revision += 1
	edit.rejected = false
end
function Policy.Begin(edit: any): any?
	if edit.flight or edit.rejected or edit.revision == edit.settledRevision then return nil end
	edit.flight = { revision = edit.revision, amount = edit.amount }
	return edit.flight
end
function Policy.Acknowledge(edit: any, amount: number, accepted: boolean): boolean
	local flight = edit.flight
	if not flight or flight.amount ~= amount then return false end
	edit.flight = nil
	edit.settledRevision = flight.revision
	edit.rejected = not accepted and flight.revision == edit.revision
	return true
end
function Policy.CanReady(edit: any, accepted: number?): boolean
	return accepted ~= nil and not edit.flight and not edit.rejected
		and edit.revision == edit.settledRevision
		and (edit.amount == nil or edit.amount == accepted)
end
return Policy
