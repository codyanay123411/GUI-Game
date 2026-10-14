--!strict
-- Project addon for installed Kohl's native Servers/ScrollerFast contracts.
-- No vendor source changes, new browser, discovery requests or join privileges.
return function(K)
	if not K.IsClient then return end
	local Players = game:GetService("Players")
	local metadata = game:GetService("ReplicatedStorage")
	local deadline = os.clock() + 30
	repeat task.wait() until (K.client and K.client.dashboard and K.client.dashboard.Servers and metadata:GetAttribute("_CurrentServerStudio") ~= nil) or os.clock() > deadline
	local browser = K.client and K.client.dashboard and K.client.dashboard.Servers
	if not browser or not browser.RenderItem or typeof(browser.RenderItem._value) ~= "function"
		or not browser._instance or typeof(browser.updateList) ~= "function" or not K.Data.servers then
		warn("[CurrentServer] Unsupported Kohl Servers handles; recheck addon compatibility.")
		return
	end
	if browser._instance:GetAttribute("CurrentServerMounted") then return end
	browser._instance:SetAttribute("CurrentServerMounted", true)
	local id = metadata:GetAttribute("_CurrentServerJobId")
	local studio = metadata:GetAttribute("_CurrentServerStudio") == true
	local usableId = typeof(id) == "string" and id ~= "" and not studio
	-- Presentation key only, never a fabricated Roblox ID or teleport destination.
	local key = if usableId then id else "__CurrentStudioSession"
	local startedAt = metadata:GetAttribute("_CurrentServerStartedAt") or os.time()
	local original = browser.RenderItem._value
	browser.RenderItem(function(self, item, jobId)
		local current = jobId == key
		if current then
			item.lastRender = nil
			item.jobId, item.placeId = nil, nil -- native Activated cannot route this row
			item._instance.Id.Text = "Current server"
			item._instance.Place.Text = if studio then "Studio session" elseif not usableId then "No routable ID" else tostring(metadata:GetAttribute("_CurrentServerKind") or "Server") .. " · Place " .. game.PlaceId
			item._instance.Count.Text = tostring(#Players:GetPlayers())
			item._instance.Age.Text = K.Util.Time.clock(math.max(0, os.time() - startedAt))
			item._instance:SetAttribute("CurrentServer", true)
		else
			original(self, item, jobId)
			item._instance:SetAttribute("CurrentServer", false)
		end
		-- Native virtual rows can be recycled: restore other rows' normal Join state.
		for _, child in item._instance:GetDescendants() do
			if child:IsA("GuiButton") then
				child.Active = not current
				child.Selectable = not current
				child.Interactable = not current
			elseif child:IsA("TextLabel") and child.Name == "Label" then
				child.Text = if current then "Already here" else "Join"
				child.TextTransparency = if current then .35 else 0
			end
		end
	end)
	local function refresh()
		local row = { game.PlaceId, #Players:GetPlayers(), startedAt }
		K.Data.servers[key] = row
		K.client.servers._value[key] = row
		local empty = browser._instance:FindFirstChild("EmptyListLabel", true)
		if empty and empty:IsA("GuiObject") then empty.Visible = false end
		browser:updateList()
	end
	local stateConnection = K.client.servers:Connect(refresh)
	local added = Players.PlayerAdded:Connect(function() task.defer(refresh) end)
	local removed = Players.PlayerRemoving:Connect(function() task.defer(refresh) end)
	local alive = true
	browser._instance.Destroying:Connect(function()
		alive = false
		added:Disconnect();removed:Disconnect()
		if stateConnection and typeof(stateConnection.Disconnect) == "function" then stateConnection:Disconnect() end
	end)
	refresh()
	task.spawn(function()
		-- The native component may mount after this addon: initial nil Parent is not destruction.
		while alive do
			task.wait(15)
			if not alive then break end
			if browser._instance.Visible then refresh() end
		end
	end)
	print("[CurrentServer] Extended native Kohl Servers list.")
end
