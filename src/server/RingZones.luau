-- Detects which gameplay ring each player occupies, from RingConfig radii and
-- the FieldCenter marker. Detection only: no ring behaviors are activated
-- here — future systems (Heat, Rangers, Bump, Bank) query these results.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local RingConfig = require(Shared.RingConfig)

local RingZones = {}

local fieldCenter: BasePart? = nil
local bands = {} -- active rings with radii, sorted by OuterRadius ascending

-- Vector3 stores float32, so a position meant to sit exactly on a ring
-- boundary quantizes up to ~2e-5 studs off the line. This tolerance keeps
-- "on the boundary" deterministically inside the inner ring per the design.
local BOUNDARY_EPSILON = 1e-3

local function buildBands()
	for ringNumber, ring in pairs(RingConfig) do
		if ring.Active and ring.InnerRadius ~= nil and ring.OuterRadius ~= nil then
			table.insert(bands, { ring = ringNumber, outer = ring.OuterRadius, name = ring.Name })
		end
	end
	table.sort(bands, function(a, b)
		return a.outer < b.outer
	end)
end

-- Returns ringNumber, ringName, inField. Deterministic boundaries: a distance
-- exactly on a shared edge belongs to the inner (deeper) ring.
function RingZones.GetRingAtPosition(position: Vector3): (number, string, boolean)
	if not fieldCenter then
		return 0, "Outside", false
	end
	local dx = position.X - fieldCenter.Position.X
	local dz = position.Z - fieldCenter.Position.Z
	local dist = math.sqrt(dx * dx + dz * dz)
	for _, band in ipairs(bands) do
		if dist <= band.outer + BOUNDARY_EPSILON then
			return band.ring, band.name, true
		end
	end
	return 0, "Outside", false
end

-- Returns nil when the player has no character to locate.
function RingZones.GetPlayerRing(player: Player)
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root then
		return nil
	end
	return RingZones.GetRingAtPosition(root.Position)
end

local function updatePlayer(player: Player)
	local ringNumber, ringName, inField = RingZones.GetPlayerRing(player)
	if ringNumber == nil then
		return
	end
	if player:GetAttribute("CurrentRing") ~= ringNumber then
		player:SetAttribute("CurrentRing", ringNumber)
		player:SetAttribute("CurrentRingName", ringName)
		player:SetAttribute("InField", inField)
	end
end

function RingZones.Start(): boolean
	local markerName = Config.FieldCenterMarkerName
	local marker = Workspace:WaitForChild(markerName, Config.Spawning.FieldCenterWaitTimeout)
	if not marker or not marker:IsA("BasePart") then
		warn(("[RingZones] no BasePart named %q in Workspace — ring detection disabled."):format(markerName))
		return false
	end
	fieldCenter = marker
	buildBands()

	task.spawn(function()
		while true do
			for _, player in ipairs(Players:GetPlayers()) do
				updatePlayer(player)
			end
			task.wait(Config.RingZones.DetectionInterval)
		end
	end)
	return true
end

return RingZones
