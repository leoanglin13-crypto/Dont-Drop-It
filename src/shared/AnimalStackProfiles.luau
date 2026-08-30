-- Per-animal visual stacking profiles for StackRender.
--
-- StackRender places each animal by asking the animal BELOW for its top
-- support point and the animal ABOVE for its bottom contact point:
--
--   BottomOffset      studs from the model origin DOWN to its resting/contact
--                     surface (nil = half the placeholder size)
--   TopSupportOffset  studs from the model origin UP to the surface the next
--                     animal rests on (nil = half the placeholder size)
--   Rotation          yaw offset in radians applied when carried in a stack
--
-- Real animal models get hand-tuned entries when they exist (e.g. a Dog on a
-- Frog rests on the Frog's back, not on a generic cube top). Placeholder
-- cubes fall back to Default — do not hand-tune values for models that do
-- not exist yet.
local AnimalStackProfiles = {
	Default = {},

	Frog = {},
	Cat = {},
	Dog = {},
	Pig = {},
	Cow = {},
	Gorilla = {},
	Giraffe = {},
	Elephant = {},
}

return AnimalStackProfiles
