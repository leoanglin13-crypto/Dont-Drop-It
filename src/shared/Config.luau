local Config = {}

Config.ServerSize = 8

Config.FieldRadius = 300
Config.ZooLineOffset = 30

-- Gameplay code locates the field via a Studio marker with this name, never
-- a hard-coded position, so the world can be repositioned without code changes.
Config.FieldCenterMarkerName = "FieldCenter"

Config.Spawning = {
	RespawnSeconds = 8,
	FieldCenterWaitTimeout = 10,
	SpawnRaycastHeight = 100,
}

Config.Pickup = {
	PromptDistance = 9,
	-- Server-side revalidation limit: prompt distance plus latency slack.
	MaxPickupDistance = 12,
}

Config.RingZones = {
	DetectionInterval = 0.2,
}

Config.StackRender = {
	-- placeholder visual size = BaseVisualSize * weight ^ WeightScaleExponent
	BaseVisualSize = 1.6,
	WeightScaleExponent = 0.35,
	-- Slightly negative so adjacent animals visibly rest on each other.
	BaseSpacing = -0.08,
	-- Carry anchor: the bottom animal rests on the ANIMATED HANDS — the
	-- midpoint of LeftHand/RightHand each frame — so every avatar carries at
	-- wherever its posed hands actually are. CarryOverlap sinks the animal's
	-- contact surface into the hand tops so there is never an air gap.
	-- FallbackHeightAboveHead is used only when hand parts don't exist.
	CarryOverlap = 0.15,
	FallbackHeightAboveHead = 0.45,
	-- Published carry-pose animation asset id. Empty string = Studio-only
	-- prototype pose (registered KeyframeSequence) until the real asset exists.
	CarryAnimationId = "",
	-- smoothing: higher = snappier; each stack index adds LagPerAnimal of lag.
	-- NOTE: lag compounds up the chain (each animal smooths toward the one
	-- below), so these must stay fairly stiff or tall towers turn to rope.
	FollowResponsiveness = 26,
	LagPerAnimal = 0.06,
	SwayAmount = 0.06,
	SwaySpeed = 2.2,
	-- lean opposite movement: radians per stud/s of speed, capped
	LeanAmount = 0.006,
	LeanMax = 0.18,
	-- local-player camera: extra CameraMinZoomDistance at full load
	CameraPullbackMax = 8,
	RingColors = {
		[1] = Color3.fromRGB(126, 200, 120),
		[2] = Color3.fromRGB(94, 148, 231),
		[3] = Color3.fromRGB(196, 110, 226),
		[4] = Color3.fromRGB(235, 160, 40),
	},
	DefaultColor = Color3.fromRGB(180, 180, 180),
}

Config.BaseWalkSpeed = 20
Config.StartingCarryWeight = 30

Config.SpeedExponent = 1.4
Config.SpeedPenalty = 0.72

Config.BumpWindup = 0.4
Config.BumpCooldown = 4
Config.BumpImmunityWeight = 3
Config.SpillRadius = 15

Config.HeatThresholds = {
	Noticed = 6,
	Wanted = 15,
	HighValue = 25,
}

Config.HeatDecayPerSecond = 2

Config.RangerSpeedMin = 13
Config.RangerSpeedMax = 17
Config.RangerSwingTelegraph = 0.5

Config.RangerKnockLooseMin = 1
Config.RangerKnockLooseMax = 2

return Config