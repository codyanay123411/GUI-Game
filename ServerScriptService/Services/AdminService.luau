--!strict

--[[
	Admin / testing foundation. Starts after gameplay services.

	Exposes ServerScriptService.AdminDebug.Invoke for Studio/MCP.
	If official Kohl's Admin is present, clones AdminKohlAddon into Addons.
	Does not install Kohl's Admin itself.
]]

local ServerScriptService = game:GetService("ServerScriptService")

local AdminBridge = require(script.Parent.AdminBridge)

local AdminService = {}

local started = false
local KOHL_NAMES = {
	"Kohl's Admin",
	"Kohls Admin",
	"Kohl's Admin Infinite",
	"KA",
}

local function findAddonsFolder(root: Instance): Folder?
	local addons = root:FindFirstChild("Addons")
	if addons and addons:IsA("Folder") then
		return addons
	end
	local config = root:FindFirstChild("Config")
	if config then
		local nested = config:FindFirstChild("Addons")
		if nested and nested:IsA("Folder") then
			return nested
		end
	end
	return nil
end

local function findKohlRoot(): Instance?
	for _, parent in { ServerScriptService, workspace } do
		for _, name in KOHL_NAMES do
			local inst = parent:FindFirstChild(name)
			if inst then
				return inst
			end
		end
		for _, child in parent:GetChildren() do
			if string.find(string.lower(child.Name), "kohl", 1, true) then
				return child
			end
		end
	end
	return nil
end

local function tryInstallKohlAddon()
	local kohl = findKohlRoot()
	if not kohl then
		print("[Admin] Kohl's Admin not found. Studio AdminDebug.Invoke is available. Director must insert the official Kohl loader (@Scripth) to use chat commands.")
		return
	end
	local addons = findAddonsFolder(kohl)
	if not addons then
		warn("[Admin] Kohl instance found but no Addons folder:", kohl:GetFullName())
		return
	end
	if addons:FindFirstChild("AdminKohlAddon") then
		print("[Admin] Kohl addon already present under", addons:GetFullName())
		return
	end
	local source = ServerScriptService.Services:FindFirstChild("AdminKohlAddon")
	if not (source and source:IsA("ModuleScript")) then
		warn("[Admin] AdminKohlAddon module missing.")
		return
	end
	local clone = source:Clone()
	clone.Name = "AdminKohlAddon"
	clone.Parent = addons
	print("[Admin] Cloned AdminKohlAddon into", addons:GetFullName(), "- restart Play if Kohl already finished loading addons.")
end

function AdminService.Start()
	if started then
		return
	end
	started = true

	local debugFolder = ServerScriptService:FindFirstChild("AdminDebug")
	if debugFolder then
		debugFolder:Destroy()
	end
	debugFolder = Instance.new("Folder")
	debugFolder.Name = "AdminDebug"
	debugFolder.Parent = ServerScriptService

	local help = Instance.new("StringValue")
	help.Name = "Help"
	help.Value = AdminBridge.HelpText()
	help.Parent = debugFolder

	local invoke = Instance.new("BindableFunction")
	invoke.Name = "Invoke"
	invoke.Parent = debugFolder
	invoke.OnInvoke = function(operation: any, a: any, b: any, c: any)
		local ok, result = AdminBridge.Execute(nil, operation, a, b, c)
		print("[Admin] debug Invoke", operation, ok, result)
		return ok, result
	end

	tryInstallKohlAddon()
	ServerScriptService.ChildAdded:Connect(function()
		task.defer(tryInstallKohlAddon)
	end)

	print("[Admin] AdminBridge started. GameTester UserIds only for live commands.")
end

return AdminService
