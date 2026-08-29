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

Config.BaseWalkSpeed = 16
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