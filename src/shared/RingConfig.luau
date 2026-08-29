-- Radii are temporary graybox bands in studs, measured from the FieldCenter
-- marker. Deeper rings sit closer to the center. Rings 4 and 5 belong to the
-- full five-ring game and have no geometry during the three-ring MVP.
local RingConfig = {
	[1] = {
		Name = "Common",
		Active = true,
		InnerRadius = 73.3,
		OuterRadius = 110,
		BumpingEnabled = false,
		RangersEnabled = false,
	},

	[2] = {
		Name = "Rare",
		Active = true,
		InnerRadius = 36.7,
		OuterRadius = 73.3,
		BumpingEnabled = true,
		RangersEnabled = true,
	},

	[3] = {
		Name = "Epic",
		Active = true,
		InnerRadius = 0,
		OuterRadius = 36.7,
		BumpingEnabled = true,
		RangersEnabled = true,
	},

	[4] = {
		Name = "Legendary",
		Active = false,
		BumpingEnabled = true,
		RangersEnabled = true,
	},

	[5] = {
		Name = "Mythic",
		Active = false,
		BumpingEnabled = true,
		RangersEnabled = true,
	},
}

return RingConfig