--!strict

--[[
	Prototype warfare panel. Sends DeclareWar intent only.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")

local PrototypeGuiTheme = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Util"):WaitForChild("PrototypeGuiTheme"))
local MapCatalog = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"):WaitForChild("MapCatalog"))
local WarfareAdjacency = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Util"):WaitForChild("WarfareAdjacency"))
local PlayerRelevantView = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Util"):WaitForChild("PlayerRelevantView"))

local player = Players.LocalPlayer
local WarfareController = {}

local started = false

local function decodeState(payload: any): any?
	if typeof(payload) == "string" then
		local ok, decoded = pcall(function()
			return HttpService:JSONDecode(payload)
		end)
		if ok and typeof(decoded) == "table" then
			return decoded
		end
		return nil
	elseif typeof(payload) == "table" then
		return payload
	end
	return nil
end

function WarfareController.Start()
	if started or _G.__WarfareV01Started == true then
		return
	end
	started = true
	_G.__WarfareV01Started = true

	local gui = player:WaitForChild("PlayerGui"):WaitForChild("HierarchyPrototypeGui", 12)
	if not (gui and gui:IsA("ScreenGui")) then
		warn("[Warfare] HierarchyPrototypeGui missing; panel idle.")
		started = false
		_G.__WarfareV01Started = nil
		return
	end

	local info = gui:WaitForChild("TerritoryInfo") :: Frame
	local declareBtn = info:WaitForChild("DeclareWar") :: TextButton
	local warStatus = info:WaitForChild("WarStatus") :: TextLabel
	local selectedValue = info:WaitForChild("SelectedTerritoryId") :: StringValue
	local resultToast = gui:WaitForChild("ResultToast") :: Frame
	local resultToastLabel = resultToast:WaitForChild("Label") :: TextLabel

	local remotes = ReplicatedStorage:WaitForChild("Remotes")
	local intent = remotes:WaitForChild("WarfareClientEvent") :: RemoteEvent
	local push = remotes:WaitForChild("WarfareServerEvent") :: RemoteEvent
	local hierarchyPush = remotes:WaitForChild("HierarchyServerEvent") :: RemoteEvent
	local territoryPush = remotes:WaitForChild("TerritoryServerEvent") :: RemoteEvent
	local diplomacyPush = remotes:WaitForChild("DiplomacyServerEvent") :: RemoteEvent

	local wars = {}
	local hierarchy = { rulers = {} }
	local ownership: { [string]: string } = {}
	local diplomacy = { agreements = {} }
	local noticeToken = 0

	local function showNotice(message: string)
		noticeToken += 1
		local token = noticeToken
		resultToastLabel.Text = message
		resultToast.Visible = true
		task.delay(6, function()
			if token == noticeToken then
				resultToast.Visible = false
			end
		end)
	end

	local function rulerById(id: string): any?
		for _, ruler in hierarchy.rulers do
			if ruler.rulerId == id then
				return ruler
			end
		end
		return nil
	end

	local function myRuler(): any?
		for _, ruler in hierarchy.rulers do
			if tonumber(ruler.userId) == player.UserId then
				return ruler
			end
		end
		return nil
	end

	local function ownerRoot(territoryId: string): string?
		local ownerId = ownership[territoryId]
		if not ownerId or ownerId == "" then
			return nil
		end
		local owner = rulerById(ownerId)
		if owner and typeof(owner.rootRulerId) == "string" and owner.rootRulerId ~= "" then
			return owner.rootRulerId
		end
		return ownerId
	end

	local function hasNap(a: string, b: string): boolean
		local keyA = if a < b then a else b
		local keyB = if a < b then b else a
		for _, row in diplomacy.agreements do
			if row.leftRulerId == keyA and row.rightRulerId == keyB and row.nap == true then
				return true
			end
		end
		return false
	end

	local function greaterRealmMemberIds(root: any): { string }
		local byId: { [string]: any } = {}
		for _, ruler in hierarchy.rulers do
			if typeof(ruler.rulerId) == "string" then
				byId[ruler.rulerId] = ruler
			end
		end
		local ids = { root.rulerId }
		local seen: { [string]: boolean } = { [root.rulerId] = true }
		local queue = { root.rulerId }
		local i = 1
		while i <= #queue do
			local current = byId[queue[i]]
			i += 1
			if current and typeof(current.vassalIds) == "table" then
				for _, vassalId in current.vassalIds do
					if typeof(vassalId) == "string" and seen[vassalId] ~= true then
						seen[vassalId] = true
						table.insert(ids, vassalId)
						table.insert(queue, vassalId)
					end
				end
			end
		end
		if typeof(root.descendantIds) == "table" then
			for _, id in root.descendantIds do
				if typeof(id) == "string" and seen[id] ~= true then
					seen[id] = true
					table.insert(ids, id)
				end
			end
		end
		return ids
	end

	local function ownedByGreaterRealm(root: any): { string }
		local members: { [string]: boolean } = {}
		for _, id in greaterRealmMemberIds(root) do
			members[id] = true
		end
		local owned = {}
		for territoryId, ownerId in ownership do
			if typeof(ownerId) == "string" and ownerId ~= "" and members[ownerId] == true then
				table.insert(owned, territoryId)
			end
		end
		return owned
	end

	local function isAdjacentForRoot(root: any, targetId: string): boolean
		local mapDef = MapCatalog.GetDefault()
		return WarfareAdjacency.IsTargetAdjacentToOwned(mapDef.territories, targetId, ownedByGreaterRealm(root))
	end

	local function territoryName(id: string): string
		local mapDef = MapCatalog.GetDefault()
		for _, t in mapDef.territories do
			if t.id == id then
				if typeof(t.displayName) == "string" and t.displayName ~= "" then
					return t.displayName
				end
				return id
			end
		end
		return id
	end

	local function rulerName(id: string): string
		local ruler = rulerById(id)
		if ruler and typeof(ruler.displayName) == "string" and ruler.displayName ~= "" then
			return ruler.displayName
		end
		return id
	end

	local function formatWarPair(war: any): string
		return string.format(
			"%s vs %s — %s",
			rulerName(war.attackerRootId),
			rulerName(war.defenderRootId),
			territoryName(war.targetTerritoryId)
		)
	end

	local function localRootId(): string?
		return PlayerRelevantView.LocalRootRulerId(hierarchy.rulers, player.UserId)
	end

	local function relevantWars(): { any }
		return PlayerRelevantView.FilterWarsForLocalRoot(wars, localRootId())
	end

	local function warsBetween(rootA: string, rootB: string): { any }
		local matches = {}
		for _, war in wars do
			local atk = war.attackerRootId
			local def = war.defenderRootId
			if (atk == rootA and def == rootB) or (atk == rootB and def == rootA) then
				table.insert(matches, war)
			end
		end
		return matches
	end

	local function refresh()
		local me = myRuler()
		local selected = selectedValue.Value
		local bits = {}
		if not me then
			table.insert(bits, "Waiting for server state...")
		else
			if me.independent ~= true then
				table.insert(bits, "Subjects cannot independently declare external war.")
			end
			local visible = relevantWars()
			if #visible == 0 then
				table.insert(bits, "No active wars.")
			elseif #visible == 1 then
				table.insert(bits, "Active war: " .. formatWarPair(visible[1]))
			else
				local parts = {}
				for _, war in visible do
					table.insert(parts, formatWarPair(war))
				end
				table.insert(bits, "Active wars: " .. table.concat(parts, "; "))
			end
		end

		declareBtn.Text = "Declare War"
		local canDeclare = false
		local defRoot: string? = nil
		if selected == "" then
			declareBtn.Active = false
			PrototypeGuiTheme.applyPrimaryButton(declareBtn, false)
		elseif me and me.independent ~= true then
			declareBtn.Active = false
			PrototypeGuiTheme.applyPrimaryButton(declareBtn, false)
		elseif me then
			local ownerId = ownership[selected]
			if not ownerId or ownerId == "" then
				declareBtn.Active = false
				PrototypeGuiTheme.applyPrimaryButton(declareBtn, false)
			elseif ownerRoot(selected) == me.rulerId then
				declareBtn.Active = false
				PrototypeGuiTheme.applyPrimaryButton(declareBtn, false)
			else
				defRoot = ownerRoot(selected)
				if defRoot and hasNap(me.rulerId, defRoot) then
					declareBtn.Text = "NAP blocks war"
					declareBtn.Active = false
					PrototypeGuiTheme.applyPrimaryButton(declareBtn, false)
				elseif not isAdjacentForRoot(me, selected) then
					declareBtn.Text = "Not adjacent"
					declareBtn.Active = false
					PrototypeGuiTheme.applyPrimaryButton(declareBtn, false)
					table.insert(bits, "Cannot declare war: target not adjacent to the greater realm.")
				else
					canDeclare = true
					local pairWars = warsBetween(me.rulerId, defRoot :: string)
					if #pairWars > 0 then
						declareBtn.Text = "Declare Additional War for " .. territoryName(selected)
					else
						declareBtn.Text = "Declare War for " .. territoryName(selected)
					end
					declareBtn.Active = true
					PrototypeGuiTheme.applyPrimaryButton(declareBtn, true)
				end
			end
		else
			declareBtn.Active = false
			PrototypeGuiTheme.applyPrimaryButton(declareBtn, false)
		end

		if selected ~= "" then
			local selName = territoryName(selected)
			if me and defRoot and canDeclare then
				local pairWars = warsBetween(me.rulerId, defRoot)
				if #pairWars > 0 then
					local existingNames = {}
					for _, war in pairWars do
						table.insert(existingNames, territoryName(war.targetTerritoryId))
					end
					table.insert(bits, "Existing war target: " .. table.concat(existingNames, ", "))
					local selectedIsExisting = false
					for _, name in existingNames do
						if name == selName then
							selectedIsExisting = true
							break
						end
					end
					if selectedIsExisting then
						table.insert(bits, "Selected: " .. selName)
					else
						table.insert(bits, "Selected new target: " .. selName)
					end
				else
					table.insert(bits, "Selected: " .. selName)
				end
			else
				table.insert(bits, "Selected: " .. selName)
			end
		end

		warStatus.Text = table.concat(bits, "\n")
		declareBtn.TextSize = 12
	end

	declareBtn.MouseButton1Click:Connect(function()
		if not declareBtn.Active then
			return
		end
		local selected = selectedValue.Value
		if selected ~= "" then
			intent:FireServer("DeclareWar", selected)
		end
	end)

	selectedValue:GetPropertyChangedSignal("Value"):Connect(refresh)

	push.OnClientEvent:Connect(function(kind: any, payload: any)
		if kind == "Notice" and typeof(payload) == "string" then
			showNotice(payload)
			return
		end
		if kind ~= "State" then
			return
		end
		local data = decodeState(payload)
		if not data then
			warn("[Warfare] State decode failed")
			return
		end
		wars = data.wars or {}
		refresh()
	end)

	hierarchyPush.OnClientEvent:Connect(function(kind: any, payload: any)
		if kind ~= "State" then
			return
		end
		local data = decodeState(payload)
		if data and typeof(data.rulers) == "table" then
			hierarchy.rulers = data.rulers
			refresh()
		end
	end)

	territoryPush.OnClientEvent:Connect(function(kind: any, payload: any)
		if kind ~= "State" then
			return
		end
		local data = decodeState(payload)
		if not data or typeof(data.territories) ~= "table" then
			return
		end
		ownership = {}
		for _, row in data.territories do
			if typeof(row.territoryId) == "string" then
				ownership[row.territoryId] = if row.hasOwner == true then tostring(row.ownerRulerId) else ""
			end
		end
		refresh()
	end)

	diplomacyPush.OnClientEvent:Connect(function(kind: any, payload: any)
		if kind ~= "State" then
			return
		end
		local data = decodeState(payload)
		if data and typeof(data.agreements) == "table" then
			diplomacy.agreements = data.agreements
			refresh()
		end
	end)

	refresh()
	intent:FireServer("Ready")
	print("[Warfare] controller started; Ready sent")
end

return WarfareController
