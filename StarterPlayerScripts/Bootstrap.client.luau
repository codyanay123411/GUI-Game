--!strict

--[[
	Client entry point.

	This script is the thin bootstrap for local player startup.
	When controllers exist under StarterPlayer.StarterPlayerScripts.Controllers,
	require and start them from here in a defined order.

	Controllers own client behavior and GUI control only.
	Never treat client input or GUI state as authoritative game truth.
]]

-- Future: require Controllers and call their start/init functions here.
