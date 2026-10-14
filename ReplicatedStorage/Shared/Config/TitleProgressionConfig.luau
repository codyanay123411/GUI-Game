--!strict
-- Initial playtest tuning; title establishment never spends Prestige.
return table.freeze({
	PrestigePerPersonalProvincePerMinute = 20,
	PrestigePerRequiredProvince = 50,
	UpdateIntervalSeconds = 2,
	Ranks = table.freeze({
		table.freeze({ rank = 2, ratio = 0.125, titleName = "Duke", establishLabel = "Establish Duchy", establishedNotice = "Duchy established." }),
		table.freeze({ rank = 3, ratio = 0.3125, titleName = "King", establishLabel = "Establish Kingdom", establishedNotice = "Kingdom established." }),
		table.freeze({ rank = 4, ratio = 0.625, titleName = "Emperor", establishLabel = "Establish Empire", establishedNotice = "Empire established." }),
	}),
})
