local RingConfig = {
	[1] = {
		Name = "Common",
		Active = true,
		InnerRadius = 187.5,
		OuterRadius = 300,
		-- The outer ring is by far the largest band; 20 keeps the onboarding
		-- area feeling stocked from every Sanctuary side.
		MaxAnimals = 20,
		BumpingEnabled = false,
		RangersEnabled = false,
	},

	[2] = {
		Name = "Rare",
		Active = true,
		InnerRadius = 112.5,
		OuterRadius = 187.5,
		MaxAnimals = 8,
		BumpingEnabled = true,
		RangersEnabled = true,
	},

	[3] = {
		Name = "Epic",
		Active = true,
		InnerRadius = 50,
		OuterRadius = 112.5,
		MaxAnimals = 6,
		BumpingEnabled = true,
		RangersEnabled = true,
	},

	[4] = {
		Name = "Legendary",
		Active = true,
		InnerRadius = 0,
		OuterRadius = 50,
		MaxAnimals = 4,
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