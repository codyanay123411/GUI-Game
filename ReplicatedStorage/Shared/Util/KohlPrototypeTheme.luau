--!strict

--[[
	Kohl Config.Themes.Default mapping from PrototypeGuiTheme.
	Project-owned. Synced into Kohl Config at runtime; survives MainModule auto-update.
	Image/Sound ids are Kohl's stock assets (not gameplay).
]]

local PrototypeGuiTheme = require(script.Parent.PrototypeGuiTheme)
local C = PrototypeGuiTheme.Colors

return {
	Transparency = 0,
	TextStrokeTransparency = 0.9,

	BackgroundImage = "rbxassetid://104331312960285",
	BackgroundImageScaleType = Enum.ScaleType.Crop,
	BackgroundImageTransparency = 1,

	BackgroundGradientEnabled = false,
	BackgroundGradient = C.panel,
	BackgroundGradientStop = C.well,
	BackgroundGradientAngle = 90,

	Primary = C.panel,
	PrimaryText = C.textPrimary,

	Secondary = C.section,
	SecondaryText = C.panel,

	Border = C.stroke,
	BorderStop = C.stroke,
	BorderAngle = 90,

	Valid = C.action,
	Invalid = C.danger,

	FontSize = 14,
	Font = Font.fromEnum(Enum.Font.Gotham),
	FontMono = Font.fromEnum(Enum.Font.Gotham),

	CornerRadius = UDim.new(0, 8),
	Padding = UDim.new(0, 10),
	StrokeEnabled = true,

	TweenIn = TweenInfo.new(0.3, Enum.EasingStyle.Cubic, Enum.EasingDirection.In),
	TweenOut = TweenInfo.new(0.3, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out),
	TweenInOut = TweenInfo.new(0.3, Enum.EasingStyle.Cubic, Enum.EasingDirection.InOut),

	Image = {
		Add = "75463072948156",
		Check = "125053493387464",
		Close = "117385134461283",
		Check_Bold = "73008384795860",
		Close_Bold = "74789968601408",
		Cloud = "118275085320462",
		Cloud_Done = "123950085396972",
		Cloud_Save = "118034592501659",
		Circle = "89534232370062",
		Edit = "76957302873541",
		Filter = "93483633020282",
		Graph1 = "106022943008038",
		Host = "90101028950281",
		Hourglass_Bottom = "113528044873866",
		Memory = "129377673430313",
		Memory_Alt = "94473693145825",
		Pace = "109012026245646",
		Search = "82890781874034",
		Speed = "116538164057946",
		Terminal = "108121111850606",
		Copy = "124783262098670",
		Cut = "100350584715025",
		Delete = "100174268115752",
		Paste = "107985770649673",
		Down = "116491276097788",
		Play = "113952858544170",
		Stop = "94423843228984",
		SignalSheet = "79089908951427",
	},

	SoundEnabled = true,
	TypingSounds = true,
	TypingSoundsOnEveryTextBox = false,
	Volume = 1,

	Sound = {
		Back = "10066914500",
		Call_Accept = "17208209318",
		Call_Decline = "17208214688",
		Call_Hangup = "17208220181",
		Call_Leave = "17208295577",
		Hello = "17208335138",
		Hover01 = "17208339919",
		Hover02 = "17208343514",
		Hover03 = "17208348006",
		Negative = "17208353912",
		Notification_High = "17208361335",
		Notification_Low = "17208372272",
		PopSwipe = "10128766965",
		Select01 = "10128760939",
		Select02 = "10066968815",
		Select03 = "17208396156",
		Swipe = "17208405682",
	},
}
