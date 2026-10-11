--!strict
-- Project-owned semantic sounds, verified against installed Kohl v0.17.0 stock assets.
local SoundService = game:GetService("SoundService")
local ContentProvider = game:GetService("ContentProvider")
local Theme = require(script.Parent.PrototypeGuiTheme)
local Sounds = {}
local definitions = {
	Click = { id = "10128760939", volume = "InteractionVolume" },
	Select = { id = "10066968815", volume = "InteractionVolume" },
	Open = { id = "10128766965", volume = "InteractionVolume" },
	Close = { id = "10066914500", volume = "InteractionVolume" },
	Confirm = { id = "17208209318", volume = "InteractionVolume" },
	Hover = { id = "17208339919", volume = "InteractionVolume" },
	Error = { id = "17208353912", volume = "ErrorVolume" },
	Notification = { id = "17208372272", volume = "NotificationVolume" },
}
local objects: { [string]: Sound } = {}
local group: SoundGroup?
local last: { [string]: number } = {}

function Sounds.Start()
	if group then return end
	group = Instance.new("SoundGroup")
	group.Name = "GameGuiSounds"
	group.Parent = SoundService
	for key, definition in definitions do
		local sound = Instance.new("Sound")
		sound.Name = key
		sound.SoundId = "rbxassetid://" .. definition.id
		sound.SoundGroup = group
		sound.Parent = group
		objects[key] = sound
	end
	local function update()
		local settings = Theme.Presentation
		local soundGroup = group :: SoundGroup
		soundGroup.Volume = if settings.InterfaceSoundsEnabled then settings.MasterUIVolume else 0
		for key, sound in objects do sound.Volume = Theme.Presentation[definitions[key].volume] end
	end
	Theme.PresentationChanged.Event:Connect(update)
	update()
	task.spawn(function()
		local assets = {}
		for _, sound in objects do table.insert(assets, sound) end
		pcall(function() ContentProvider:PreloadAsync(assets) end)
	end)
end

function Sounds.Play(key: string)
	if not group then Sounds.Start() end
	local settings = Theme.Presentation
	if not settings.InterfaceSoundsEnabled or settings.MasterUIVolume <= 0 then return end
	if key == "Hover" and not settings.HoverSoundsEnabled then return end
	if (key == "Notification" or key == "Error") and not settings.NotificationSoundsEnabled then return end
	local sound = objects[key]
	if not sound then return end
	local now = os.clock()
	if now - (last[key] or -math.huge) < (if key == "Hover" then 0.12 else 0.06) then return end
	last[key] = now
	sound:Play()
end

return Sounds
