--!strict

--[[
	Client-only Kohl addon (name contains "Client").
	Applies PrototypeGuiTheme-mapped Kohl theme after load.
	Does not touch AdminBridge or permissions.
]]

return function(_K)
	if not _K.IsClient then
		return
	end
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local theme = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Util"):WaitForChild("KohlPrototypeTheme"))
	if type(_K.Data) == "table" then
		if type(_K.Data.settings) == "table" then
			_K.Data.settings.getKohlsAdminPopup = false
		end
	end
	local slim: { [string]: any } = {}
	for key, value in theme :: any do
		if key ~= "Image" and key ~= "Sound" then
			if (key == "Font" or key == "FontMono") and typeof(value) == "EnumItem" then
				slim[key] = Font.fromEnum(value)
			else
				slim[key] = value
			end
		end
	end
	local UI = _K.UI
	if UI and type(UI.changeTheme) == "function" then
		pcall(UI.changeTheme, slim)
	end
end
