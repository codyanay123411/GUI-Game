--!strict

--[[
	Server entry point.

	This script is the thin bootstrap for authoritative server startup.
	When services exist under ServerScriptService.Services, require and
	start them from here in a defined order.

	Do not put gameplay, GUI, or client-trusted logic in this file.
	Keep it an orchestrator so systems stay in their own modules.
]]

-- Future: require Services and call their start/init functions here.
