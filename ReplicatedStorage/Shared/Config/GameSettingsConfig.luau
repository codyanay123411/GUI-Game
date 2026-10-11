--!strict
-- Presentation only. Global runtime values are owned by GameSettingsService.
local Config = {}
Config.FontOptions = { "GothamSSm", "SourceSansPro", "Roboto", "Arial" }
Config.Definitions = {
	{ key = "Font", label = "Font", category = "Game UI", default = "GothamSSm", kind = "font" },
	{ key = "FontScale", label = "Font Size Scale", category = "Game UI", default = 1, min = 0.9, max = 1.1, step = 0.01 },
	{ key = "UIScale", label = "UI Scale", category = "Game UI", default = 1, min = 0.9, max = 1.1, step = 0.01 },
	{ key = "CornerRadius", label = "Corner Radius", category = "Game UI", default = 8, min = 0, max = 16, step = 1 },
	{ key = "Padding", label = "Padding / Spacing", category = "Game UI", default = 10, min = 6, max = 12, step = 1 },
	{ key = "BackgroundStrength", label = "Background Strength", category = "Game UI", default = 1, min = 0.85, max = 1, step = 0.01 },
	{ key = "PanelOpacity", label = "Panel Opacity", category = "Game UI", default = 1, min = 0.8, max = 1, step = 0.01 },
	{ key = "AnimationSpeed", label = "Animation Speed", category = "Game UI", default = 1, min = 0.5, max = 2, step = 0.05 },
	{ key = "ProvinceLabelsEnabled", label = "Province Labels", category = "Game UI", default = true, kind = "toggle" },
	{ key = "AnimationsEnabled", label = "UI Animations", category = "Game UI", default = true, kind = "toggle" },
	{ key = "MasterUIVolume", label = "Master UI Volume", category = "Game Audio", default = 0.5, min = 0, max = 1, step = 0.01, percent = true },
	{ key = "InterfaceSoundsEnabled", label = "Interface Sounds", category = "Game Audio", default = true, kind = "toggle" },
	{ key = "HoverSoundsEnabled", label = "Hover Sounds", category = "Game Audio", default = false, kind = "toggle" },
	{ key = "NotificationSoundsEnabled", label = "Notification Sounds", category = "Game Audio", default = true, kind = "toggle" },
	{ key = "InteractionVolume", label = "Interaction Volume", category = "Game Audio", default = 0.6, min = 0, max = 1, step = 0.01, percent = true },
	{ key = "NotificationVolume", label = "Notification Volume", category = "Game Audio", default = 0.6, min = 0, max = 1, step = 0.01, percent = true },
	{ key = "ErrorVolume", label = "Warning / Error Volume", category = "Game Audio", default = 0.6, min = 0, max = 1, step = 0.01, percent = true },
}
Config.ByKey = {}
Config.Defaults = {}
for _, definition in Config.Definitions do
	Config.ByKey[definition.key] = definition
	Config.Defaults[definition.key] = definition.default
end

function Config.Validate(key: any, value: any): boolean
	if typeof(key) ~= "string" then return false end
	local definition = Config.ByKey[key]
	if not definition then return false end
	if definition.kind == "font" then return typeof(value) == "string" and table.find(Config.FontOptions, value) ~= nil end
	if definition.kind == "toggle" then return typeof(value) == "boolean" end
	return typeof(value) == "number" and value == value and value >= definition.min and value <= definition.max
end

return Config
