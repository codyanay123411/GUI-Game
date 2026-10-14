--!strict
-- A generation tag is a stale-request guard, never authorization.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Intent = {}
local listeners: { (number) -> () } = {}
function Intent.OnChanged(callback: (number) -> ())
	table.insert(listeners, callback)
end
local generation = ReplicatedStorage:GetAttribute("MatchGeneration") or 1
local function observe(value: any)
	if typeof(value) == "number" and value > generation then
		generation = value
		-- BindableEvent callbacks may be deferred until after fresh snapshots arrive.
		-- Clear old presentation synchronously before the first new-generation payload.
		for _, callback in listeners do callback(value) end
	end
end
ReplicatedStorage:GetAttributeChangedSignal("MatchGeneration"):Connect(function() observe(ReplicatedStorage:GetAttribute("MatchGeneration")) end)
function Intent.GetGeneration(): number return generation end
function Intent.ConnectPush(remote: RemoteEvent, handler: any): RBXScriptConnection
	return remote.OnClientEvent:Connect(function(kind, payload, epoch)
		if typeof(epoch) ~= "number" or epoch < generation then return end
		observe(epoch)
		handler(kind, payload)
	end)
end
function Intent.Send(remote: RemoteEvent, ...)
	local args = table.pack(...)
	args.n += 1
	args[args.n] = { matchGeneration = generation }
	remote:FireServer(table.unpack(args, 1, args.n))
end
return Intent
