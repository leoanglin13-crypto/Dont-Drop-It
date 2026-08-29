-- Active = spawnable in the current four-ring prototype. Inactive animals stay
-- here for the full five-ring design but must never spawn until reactivated.
local AnimalConfig = {
	Frog = {
		Ring = 1,
		Weight = 1,
		IncomePerSecond = 2,
		Active = true,
	},

	Cat = {
		Ring = 1,
		Weight = 2,
		IncomePerSecond = 9,
		Active = true,
	},

	Pig = {
		Ring = 2,
		Weight = 3,
		IncomePerSecond = 45,
		Active = true,
	},

	-- Provisional MVP animal; weight and income are tuning values expected
	-- to change after playtesting.
	Dog = {
		Ring = 2,
		Weight = 4,
		IncomePerSecond = 100,
		Active = true,
	},

	Cow = {
		Ring = 3,
		Weight = 7,
		IncomePerSecond = 380,
		Active = true,
	},

	Gorilla = {
		Ring = 3,
		Weight = 8,
		IncomePerSecond = 610,
		Active = true,
	},

	Giraffe = {
		Ring = 4,
		Weight = 14,
		IncomePerSecond = 3100,
		Active = true,
	},

	Elephant = {
		Ring = 4,
		Weight = 15,
		IncomePerSecond = 4400,
		Active = true,
	},
}

return AnimalConfig