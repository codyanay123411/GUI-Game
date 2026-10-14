--!strict

--[[
	Admin / testing foundation. Starts after gameplay services.

	Exposes ServerScriptService.AdminDebug.Invoke for Studio/MCP.
	If official Kohl's Admin is present, clones AdminKohlAddon into Addons.
	Does not install Kohl's Admin itself.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local AdminBridge = require(script.Parent.AdminBridge)
local AdminConfig = require(script.Parent.AdminConfig)

local function refreshGameTesterAccess()
	for _, player in Players:GetPlayers() do
		player:SetAttribute("_GameTesterAuthorized", AdminConfig.IsGameTester(player.UserId))
		player:SetAttribute("_StaffServerAuthorized", AdminConfig.IsStaff(player.UserId))
	end
end

local accessHooksInstalled = false

local AdminService = {}

local started = false
local KOHL_ADDON_TAG = "Kohl's Admin Addon"
local lateRegisterDone = false
local lateRegisterPasses = 0
local LATE_REGISTER_PASSES = 3
local loggedPresence = false
local loggedMissingKohl = false
local loggedMissingAddon = false
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

local function collectAddonsFolders(): { Folder }
	local folders: { Folder } = {}
	local seen = {}
	local function consider(inst: Instance?)
		if inst and inst:IsA("Folder") and not seen[inst] then
			seen[inst] = true
			table.insert(folders, inst)
		end
	end
	local kohl = findKohlRoot()
	if kohl then
		consider(findAddonsFolder(kohl))
	end
	local serverStorage = game:GetService("ServerStorage")
	local kohlServer = serverStorage:FindFirstChild("Server")
	if kohlServer then
		consider(kohlServer:FindFirstChild("Addons") :: Folder?)
	end
	local rsSource = game:GetService("ReplicatedStorage"):FindFirstChild("Kohl's Admin Source")
	if rsSource then
		consider(rsSource:FindFirstChild("Addons") :: Folder?)
	end
	return folders
end

local function moduleSourceContains(module: ModuleScript, needle: string): boolean
	local ok, source = pcall(function()
		return module.Source
	end)
	return ok and typeof(source) == "string" and string.find(source, needle, 1, true) ~= nil
end

local function shouldReplaceAddon(existing: ModuleScript, sourceName: string): boolean
	if sourceName == "CurrentServerKohlClient" then return true end
	if sourceName == "GamePresentationKohlClient" then return true end
	if sourceName == "AdminKohlAddon" then
		return moduleSourceContains(existing, "return runOp")
			or moduleSourceContains(existing, "local ok, message = AdminBridge")
			or not moduleSourceContains(existing, "inspectgold")
			or moduleSourceContains(existing, "player # rawString")
			or not moduleSourceContains(existing, "adminOwnerToken")
			or not moduleSourceContains(existing, "_gameTesterCommandGate")
			or not moduleSourceContains(existing, "_strategyCommandPolicy")
			or not moduleSourceContains(existing, "seedbattle")
	end
	if sourceName == "AdminKohlThemeClient" then
		return moduleSourceContains(existing, "changeTheme") and not moduleSourceContains(existing, "Font.fromEnum")
	end
	return false
end

local function replaceAddonWithCanonical(existing: ModuleScript, canonical: ModuleScript): ModuleScript
	local parent = existing.Parent
	local name = existing.Name
	existing:Destroy()
	local clone = canonical:Clone()
	clone.Name = name
	clone:AddTag(KOHL_ADDON_TAG)
	clone.Parent = parent
	return clone
end

local function placeNamedAddon(sourceName: string, tag: boolean): ModuleScript?
	local source = ServerScriptService.Services:FindFirstChild(sourceName)
	if not (source and source:IsA("ModuleScript")) then
		return nil
	end
	local folders = collectAddonsFolders()
	if #folders == 0 then
		return source
	end
	local placed: ModuleScript? = nil
	for _, addons in folders do
		local existing = addons:FindFirstChild(sourceName)
		-- New project addon must reach each supported copied client/server container.
		if not existing and sourceName == "CurrentServerKohlClient" then
			existing = source:Clone()
			existing.Parent = addons
		end
		if existing and existing:IsA("ModuleScript") then
			if existing ~= source and shouldReplaceAddon(existing, sourceName) then
				existing = replaceAddonWithCanonical(existing, source)
				print("[Admin] Replaced stale", sourceName, "at", existing:GetFullName())
			end
			if tag then
				existing:AddTag(KOHL_ADDON_TAG)
			end
			placed = existing
		end
	end
	if placed then
		return placed
	end
	local clone = source:Clone()
	clone.Name = sourceName
	if tag then
		clone:AddTag(KOHL_ADDON_TAG)
	end
	clone.Parent = folders[1]
	print("[Admin] Cloned", sourceName, "into", folders[1]:GetFullName())
	return clone
end

local patchedKohlSettings = false

local function syncKohlConfigTheme()
	if patchedKohlSettings then
		return
	end
	local kohl = findKohlRoot()
	local config = kohl and kohl:FindFirstChild("Config")
	local settings = config and config:FindFirstChild("Settings")
	if settings and settings:IsA("ModuleScript") then
		patchedKohlSettings = true
		pcall(function()
			settings.Source = string.gsub(settings.Source, "getKohlsAdminPopup = true", "getKohlsAdminPopup = false", 1)
		end)
	end
end

local function getCanonicalAddon(): ModuleScript?
	local services = ServerScriptService.Services:FindFirstChild("AdminKohlAddon")
	if services and services:IsA("ModuleScript") then
		return services
	end
	for _, folder in collectAddonsFolders() do
		local existing = folder:FindFirstChild("AdminKohlAddon")
		if existing and existing:IsA("ModuleScript") then
			return existing
		end
	end
	return nil
end

local function tryLateRegister()
	if lateRegisterDone then
		return
	end
	local interface = shared._K_INTERFACE
	if typeof(interface) ~= "table" then
		return
	end
	if not accessHooksInstalled then
		accessHooksInstalled = true
		interface.Hook.roleAdded:Connect(refreshGameTesterAccess)
		interface.Hook.roleRemoved:Connect(refreshGameTesterAccess)
	end
	refreshGameTesterAccess()
	local canonical = ServerScriptService.Services:FindFirstChild("AdminKohlAddon")
	if not (canonical and canonical:IsA("ModuleScript")) then
		return
	end
	-- Kohl loadAddons requires addons in task.spawn after parenting Package to RS.
	-- Wait until that copy exists, then keep re-registering so canonical `run` wins.
	if not ReplicatedStorage:FindFirstChild("Kohl's Admin Source") then
		return
	end
	local ok, err = pcall(function()
		local fresh = canonical:Clone()
		fresh.Name = "AdminKohlAddonRegister"
		fresh.Parent = game:GetService("ServerStorage")
		local impl = require(fresh) :: any
		impl(interface)
		fresh:Destroy()
	end)
	if ok then
		lateRegisterPasses += 1
		if lateRegisterPasses >= LATE_REGISTER_PASSES then
			lateRegisterDone = true
			print("[Admin] Registered AdminKohlAddon with Kohl _K_INTERFACE.")
		end
	else
		warn("[Admin] Register AdminKohlAddon failed:", err)
	end
end

local function ensureAddonModule(): ModuleScript?
	placeNamedAddon("GamePresentationKohlClient", true)
	placeNamedAddon("CurrentServerKohlClient", true)
	placeNamedAddon("AdminKohlThemeClient", false)
	syncKohlConfigTheme()
	local source = getCanonicalAddon()
	if not source then
		if not loggedMissingAddon then
			loggedMissingAddon = true
			warn("[Admin] AdminKohlAddon module missing from Services; waiting for Kohl Addons copy.")
		end
		return nil
	end

	local folders = collectAddonsFolders()
	if #folders == 0 then
		return source
	end

	local placed: ModuleScript? = nil
	for _, addons in folders do
		local existing = addons:FindFirstChild("AdminKohlAddon")
		if existing and existing:IsA("ModuleScript") then
			if existing ~= source and shouldReplaceAddon(existing, "AdminKohlAddon") then
				existing = replaceAddonWithCanonical(existing, source)
				print("[Admin] Replaced stale AdminKohlAddon at", existing:GetFullName())
			end
			existing:AddTag(KOHL_ADDON_TAG)
			placed = existing
		end
	end
	if placed then
		if not loggedPresence then
			loggedPresence = true
			print("[Admin] Kohl addon already present under", placed:GetFullName())
		end
		return placed
	end

	local clone = source:Clone()
	clone.Name = "AdminKohlAddon"
	clone:AddTag(KOHL_ADDON_TAG)
	clone.Parent = folders[1]
	print("[Admin] Cloned AdminKohlAddon into", folders[1]:GetFullName())
	return clone
end

local function tryInstallKohlAddon()
	local kohl = findKohlRoot()
	if not kohl then
		if not loggedMissingKohl then
			loggedMissingKohl = true
			print("[Admin] Kohl's Admin not found. Studio AdminDebug.Invoke is available. Director must insert the official Kohl loader (@Scripth) to use chat commands.")
		end
		return
	end
	local module = ensureAddonModule()
	if module then
		tryLateRegister()
	end
end

function AdminService.Start()
	if started then
		return
	end
	started = true
	Players.PlayerAdded:Connect(refreshGameTesterAccess)
	refreshGameTesterAccess()

	local remotesFolder = ReplicatedStorage:FindFirstChild("Remotes")
	if remotesFolder then
		local existing = remotesFolder:FindFirstChild("AdminFeedbackEvent")
		if existing and not existing:IsA("RemoteEvent") then
			existing:Destroy()
			existing = nil
		end
		if not existing then
			local event = Instance.new("RemoteEvent")
			event.Name = "AdminFeedbackEvent"
			event.Parent = remotesFolder
			print("[Admin] Created AdminFeedbackEvent (server to client only).")
		end
	end

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
	task.spawn(function()
		for _ = 1, 40 do
			tryInstallKohlAddon()
			if lateRegisterDone then
				break
			end
			task.wait(0.25)
		end
	end)

	print("[Admin] AdminBridge started. GameTester authorized UserIds or Kohl SuperAdmin+ for live commands.")
end

return AdminService
