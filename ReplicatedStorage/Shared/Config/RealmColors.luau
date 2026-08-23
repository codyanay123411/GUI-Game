--!strict

--[[
	Curated distinguishable prototype palette. Not player-chosen.
]]

local RealmColors = {}

RealmColors.Unclaimed = Color3.fromRGB(118, 120, 124)

RealmColors.Palette = {
	Color3.fromRGB(196, 64, 64),
	Color3.fromRGB(64, 112, 196),
	Color3.fromRGB(56, 148, 88),
	Color3.fromRGB(196, 148, 48),
	Color3.fromRGB(148, 72, 168),
	Color3.fromRGB(48, 164, 164),
	Color3.fromRGB(196, 96, 48),
	Color3.fromRGB(80, 88, 176),
	Color3.fromRGB(120, 160, 56),
	Color3.fromRGB(176, 72, 104),
	Color3.fromRGB(64, 140, 140),
	Color3.fromRGB(168, 120, 64),
	Color3.fromRGB(88, 108, 148),
	Color3.fromRGB(140, 84, 64),
	Color3.fromRGB(72, 128, 96),
	Color3.fromRGB(152, 88, 152),
}

function RealmColors.ByIndex(index: number): Color3
	local n = #RealmColors.Palette
	if n == 0 then
		return RealmColors.Unclaimed
	end
	local i = ((index - 1) % n) + 1
	return RealmColors.Palette[i]
end

return RealmColors
