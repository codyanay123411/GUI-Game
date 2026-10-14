--!strict
-- Pure connected-player vote ledger; a match generation owns one instance.
local Votes = {}
function Votes.New(): any return { connected = {}, votes = {}, restarting = false } end
function Votes.Update(state: any, ids: { number })
	local connected = {};for _, id in ids do connected[id] = true end
	state.connected = connected
	for id in state.votes do if not connected[id] then state.votes[id] = nil end end
end
function Votes.Snapshot(state: any, viewer: number?): any
	local count, votes = 0, 0
	for _ in state.connected do count += 1 end
	for _ in state.votes do votes += 1 end
	local required = math.max(1, math.ceil(count * .5))
	return { votes = votes, required = required, connected = count, needed = math.max(0, required-votes),
		voted = viewer ~= nil and state.votes[viewer] == true, pending = state.restarting }
end
function Votes.Cast(state: any, id: number): boolean
	if state.restarting or not state.connected[id] or state.votes[id] then return false end
	state.votes[id] = true
	return true
end
function Votes.ShouldRestart(state: any): boolean
	local row = Votes.Snapshot(state)
	return not state.restarting and row.connected > 0 and row.votes >= row.required
end
return Votes
