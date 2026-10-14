--!strict
-- Private effective capabilities and direct-subject grants in the existing Realm drawer.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local TextService = game:GetService("TextService")
local Theme = require(ReplicatedStorage.Shared.Util.PrototypeGuiTheme)
local VassalCombat = require(ReplicatedStorage.Shared.Util.VassalCombat)
local Controller = {}
local started = false
function Controller.Start()
	if started then return end
	started = true
	local gui = Players.LocalPlayer:WaitForChild("PlayerGui"):WaitForChild("HierarchyPrototypeGui")
	local main = gui.Main
	main.TreeHeader.LayoutOrder = 7; main.TreeScroll.LayoutOrder = 8
	local section = Instance.new("Frame")
	section.Name = "PermissionsSection"; section.BackgroundTransparency = 1
	section.LayoutOrder = 6; section.Size = UDim2.new(1, 0, 0, 100); section.Parent = main
	local state: any = { self = {}, subjects = {} }
	local combatBonuses: any = nil
	local pending: any = nil
	local message = ""
	local remotes = ReplicatedStorage:WaitForChild("Remotes")
	local intent = remotes:WaitForChild("PermissionsClientEvent") :: RemoteEvent
	local render: () -> ()
	local measured: { any } = {}
	local reflowQueued = false
	local function queueReflow()
		if reflowQueued then return end
		reflowQueued = true
		task.defer(function()
			reflowQueued = false
			local y, width = 0, section.Size.X.Offset
			for _, row in measured do
				local item = row.item
				if not item.Parent then continue end
				local textHeight = TextService:GetTextSize(item.Text, item.TextSize, item.Font, Vector2.new(math.max(1, width - (if row.button then 24 else 0)), 100000)).Y
				local height = if row.button then math.max(36, textHeight + 24) else textHeight + 12
				item.Position = UDim2.fromOffset(0, y); item.Size = UDim2.fromOffset(width, height)
				y += height + (if row.button then 8 else 0)
			end
			section.Size = UDim2.fromOffset(width, y)
		end)
	end
	local function measure(item: any, button: boolean)
		table.insert(measured, { item = item, button = button })
		item:GetPropertyChangedSignal("TextSize"):Connect(queueReflow)
		item:GetPropertyChangedSignal("FontFace"):Connect(queueReflow)
	end
	local function label(name: string, text: string, y: number, width: number, role: string): number
		local item = Instance.new("TextLabel")
		item.Name = name; item.BackgroundTransparency = 1; item.TextWrapped = true
		item.TextXAlignment = Enum.TextXAlignment.Left; item.TextYAlignment = Enum.TextYAlignment.Top
		item.Text = text; item.ZIndex = main.SelfInfo.ZIndex
		Theme.applyText(item, role :: any)
		local height = TextService:GetTextSize(text, item.TextSize, item.Font, Vector2.new(width, 100000)).Y + 12
		item.Position = UDim2.fromOffset(0, y); item.Size = UDim2.fromOffset(width, height); item.Parent = section
		measure(item, false)
		return height
	end
	render = function()
		for _, child in section:GetChildren() do child:Destroy() end
		measured = {}
		local padding = main:FindFirstChildOfClass("UIPadding")
		local inset = if padding then padding.PaddingLeft.Offset + padding.PaddingRight.Offset else 0
		local width = math.max(1, main.AbsoluteSize.X - inset - main.ScrollBarThickness - 24)
		local y = label("Header", "Liege permissions", 0, width, "Caption")
		local effective = state.self
		local summary = "External war/conquest: " .. (effective.warReason or "Waiting for server")
			.. "\nExternal diplomacy: " .. (effective.diplomacyReason or "Waiting for server")
			.. "\n" .. (if effective.independent then "Independent rulers do not need liege grants." elseif effective.autonomy then "Stronger-subject autonomy available; vassalage remains intact." else "Stronger-subject autonomy unavailable.")
		y += label("Effective", summary, y, width, "Body")
		if combatBonuses then y += label("CombatBonuses", VassalCombat.Describe(combatBonuses), y, width, "Caption") end
		if message ~= "" then y += label("Feedback", message, y, width, "Caption") end
		for _, subject in state.subjects do
			y += label("Subject_" .. subject.rulerId, subject.titleName .. " " .. subject.displayName, y, width, "Body")
			for _, permission in { "War", "Diplomacy" } do
				local granted = if permission == "War" then subject.warGranted else subject.diplomacyGranted
				local button = Instance.new("TextButton")
				button.Name = permission .. "_" .. subject.rulerId
				button.Text = (if granted then "Revoke " else "Grant ") .. (if permission == "War" then "external war / conquest" else "external diplomacy")
				button.ZIndex = main.SelfInfo.ZIndex + 1
				local enabled = not state.frozen and pending == nil
				button.Active = enabled; Theme.applySecondaryButton(button, enabled)
				local height = math.max(36, button.TextSize * 2.6)
				button.Position = UDim2.fromOffset(0, y); button.Size = UDim2.fromOffset(width, height)
				button:SetAttribute("BlocksMapInput", true); button.Parent = section
				measure(button, true)
				button.Activated:Connect(function()
					if pending or state.frozen then return end
					pending = { subject = subject.rulerId, permission = permission, revision = subject.revision }
					message = "Saving permission..."; render()
					intent:FireServer("Set", subject.rulerId, permission, not granted, subject.revision)
				end)
				y += height + 8
			end
		end
		if #state.subjects == 0 then y += label("Empty", "No direct subjects to manage.", y, width, "Caption") end
		y += label("Limits", "Grants apply to direct subjects. Stronger subjects can bypass denials. Council seats grant no powers.", y, width, "Caption")
		section.Size = UDim2.fromOffset(width, y)
		queueReflow()
	end
	(remotes:WaitForChild("PermissionsServerEvent") :: RemoteEvent).OnClientEvent:Connect(function(kind, payload)
		local ok, data = pcall(HttpService.JSONDecode, HttpService, payload)
		if not ok or typeof(data) ~= "table" then return end
		if kind == "State" then state = data; render()
		elseif kind == "PermissionResult" and pending and data.subject == pending.subject and data.permission == pending.permission and data.revision == pending.revision then
			pending = nil; message = data.message; render()
		end
	end)
	local militaryPush = remotes:WaitForChild("MilitaryServerEvent") :: RemoteEvent
	militaryPush.OnClientEvent:Connect(function(kind, payload)
		if kind ~= "State" then return end
		local ok, data = pcall(HttpService.JSONDecode, HttpService, payload)
		if ok and typeof(data) == "table" then combatBonuses = data.combatBonuses; render() end
	end)
	main:GetPropertyChangedSignal("AbsoluteSize"):Connect(render)
	Theme.PresentationChanged.Event:Connect(render)
	intent:FireServer("Ready"); render()
end
return Controller
