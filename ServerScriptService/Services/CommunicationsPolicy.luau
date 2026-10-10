--!strict

-- Derived views only. Callers supply fresh authority snapshots for each action.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Graph = require(ReplicatedStorage.Shared.Util.RealmGraph)
local Config = require(ReplicatedStorage.Shared.Config.CommunicationsConfig)
local Policy = {}

function Policy.World(rulers: { any }, agreements: { any }, owned: (string) -> { string }, adjacent: (string, string) -> boolean): any
	local world: any = { rulers = {}, users = {}, agreements = agreements, owned = owned, adjacent = adjacent }
	for _, ruler in rulers do
		world.rulers[ruler.rulerId] = ruler
		if ruler.hasUser and ruler.userId ~= 0 then
			world.users[ruler.userId] = ruler
		end
	end
	world.lands = Graph.LandsByRoot(rulers, owned)
	world.neighbors = Graph.BuildNeighborSet(world.lands, adjacent)
	return world
end

function Policy.Distance(world: any, a: any, b: any): number?
	return Graph.Distance(a.rootRulerId, b.rootRulerId, world.neighbors)
end

function Policy.Direct(world: any, a: any, b: any): boolean
	if not a or not b or a.rulerId == b.rulerId then
		return false
	end
	-- Direct uses personal holdings, independently of greater-realm membership.
	for _, left in world.owned(a.rulerId) do
		for _, right in world.owned(b.rulerId) do
			if world.adjacent(left, right) then
				return true
			end
		end
	end
	return false
end

function Policy.Member(world: any, context: any, ruler: any): boolean
	if not ruler then
		return false
	end
	if context.kind == "diplomatic" then
		return true
	elseif context.kind == "council" then
		return world.rulers[context.owner] ~= nil and (ruler.rulerId == context.owner or ruler.liegeId == context.owner)
	elseif context.kind == "alliance" then
		for _, agreement in world.agreements do
			if agreement.alliance and agreement.allianceInstanceId == context.instanceId then
				local left, right = world.rulers[agreement.leftRulerId], world.rulers[agreement.rightRulerId]
				return left ~= nil and right ~= nil and left.independent and right.independent
					and (ruler.rulerId == left.rulerId or ruler.rulerId == right.rulerId)
			end
		end
	elseif context.kind == "direct" then
		local a, b = world.users[context.left], world.users[context.right]
		return Policy.Direct(world, a, b) and (ruler.userId == context.left or ruler.userId == context.right)
	end
	return false
end

function Policy.Deliver(world: any, context: any, senderId: number, recipientId: number, observer: boolean): boolean
	local sender, recipient = world.users[senderId], world.users[recipientId]
	if not Policy.Member(world, context, sender) then
		return false
	end
	if observer then
		return true -- Roblox's native filtering/privacy still controls this read-only source.
	end
	if not Policy.Member(world, context, recipient) then
		return false
	end
	if context.kind == "diplomatic" then
		local distance = Policy.Distance(world, sender, recipient)
		return distance ~= nil and distance <= Config.DiplomaticMaxDistance
	end
	return true
end

function Policy.Prefix(world: any, context: any, senderId: number, viewerId: number, observer: boolean): string
	local sender, viewer = world.users[senderId], world.users[viewerId]
	if not sender then
		return ""
	end
	local tag = ""
	if not observer and viewer and (context.kind == "diplomatic" or context.kind == "direct") then
		if viewer.liegeId == sender.rulerId then
			tag = " [Liege]"
		elseif sender.liegeId == viewer.rulerId then
			tag = " [Subject]"
		else
			for _, agreement in world.agreements do
				if agreement.alliance and ((agreement.leftRulerId == sender.rulerId and agreement.rightRulerId == viewer.rulerId)
					or (agreement.rightRulerId == sender.rulerId and agreement.leftRulerId == viewer.rulerId)) then
					tag = " [Ally]"
					break
				end
			end
		end
	end
	return "[" .. sender.titleName .. "]" .. tag .. " " .. sender.displayName .. ": "
end

return Policy
