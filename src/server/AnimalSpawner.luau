-- Server-authoritative animal spawning for the three-ring MVP graybox.
-- Owns the registry of live animals. Visuals are placeholder parts until
-- real animal models exist.

local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local AnimalConfig = require(Shared.AnimalConfig)
local RingConfig = require(Shared.RingConfig)

local AnimalSpawner = {}

-- Placeholder graybox colors per ring, replaced by real models later.
local RING_COLORS = {
	[1] = Color3.fromRGB(126, 200, 120),
	[2] = Color3.fromRGB(94, 148, 231),
	[3] = Color3.fromRGB(196, 110, 226),
	[4] = Color3.fromRGB(235, 160, 40),
}
local DEFAULT_COLOR = Color3.fromRGB(180, 180, 180)

local rng = Random.new()

local animals = {} -- id -> { Id, Type, Ring, Weight, IncomePerSecond, Part }
local ringCounts = {} -- ring number -> live animal count
local spawnTables = {} -- ring number -> array of active animal type names
local fieldCenter: BasePart? = nil
local animalsFolder: Folder? = nil
local started = false

local function buildSpawnTables()
	for animalType, animal in pairs(AnimalConfig) do
		if not animal.Active then
			continue
		end

		local ring = RingConfig[animal.Ring]
		if not ring or not ring.Active then
			warn(("[AnimalSpawner] %s is Active but ring %s is not; it will not spawn"):format(
				animalType, tostring(animal.Ring)))
			continue
		end
		if ring.InnerRadius == nil or ring.OuterRadius == nil then
			warn(("[AnimalSpawner] ring %d has no radii; %s will not spawn"):format(
				animal.Ring, animalType))
			continue
		end

		spawnTables[animal.Ring] = spawnTables[animal.Ring] or {}
		table.insert(spawnTables[animal.Ring], animalType)
	end

	for ringNumber, ring in pairs(RingConfig) do
		if ring.Active and (ring.MaxAnimals or 0) > 0 and not spawnTables[ringNumber] then
			warn(("[AnimalSpawner] ring %d has MaxAnimals but no active animals"):format(ringNumber))
		end
	end
end

local function randomPositionInRing(ringNumber: number): Vector3
	local ring = RingConfig[ringNumber]
	local center = fieldCenter.Position

	-- Uniform over the annulus AREA, not the radius, so spawns don't cluster
	-- toward the inner edge.
	local r = math.sqrt(rng:NextNumber(ring.InnerRadius ^ 2, ring.OuterRadius ^ 2))
	local angle = rng:NextNumber(0, 2 * math.pi)
	local x = center.X + math.cos(angle) * r
	local z = center.Z + math.sin(angle) * r

	local height = Config.Spawning.SpawnRaycastHeight
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { animalsFolder }
	local hit = Workspace:Raycast(
		Vector3.new(x, center.Y + height, z),
		Vector3.new(0, -height * 2, 0),
		params)

	local groundY = if hit then hit.Position.Y else center.Y
	return Vector3.new(x, groundY, z)
end

local function spawnAnimal(ringNumber: number): string?
	local pool = spawnTables[ringNumber]
	if not pool or #pool == 0 then
		return nil
	end

	local animalType = pool[rng:NextInteger(1, #pool)]
	local animal = AnimalConfig[animalType]
	local id = HttpService:GenerateGUID(false)

	-- Placeholder: a cube sized by weight so heavier animals read bigger.
	local size = 1.5 + animal.Weight * 0.35
	local part = Instance.new("Part")
	part.Name = animalType
	part.Size = Vector3.new(size, size, size)
	part.Color = RING_COLORS[ringNumber] or DEFAULT_COLOR
	part.Material = Enum.Material.SmoothPlastic
	part.Anchored = true
	part.CanCollide = false

	local position = randomPositionInRing(ringNumber)
	part.CFrame = CFrame.new(position + Vector3.new(0, size / 2, 0))

	part:SetAttribute("AnimalId", id)
	part:SetAttribute("AnimalType", animalType)
	part:SetAttribute("Ring", ringNumber)
	part:SetAttribute("Weight", animal.Weight)
	part:SetAttribute("IncomePerSecond", animal.IncomePerSecond)

	-- Debug label so graybox playtests can identify animals at a glance.
	local billboard = Instance.new("BillboardGui")
	billboard.Size = UDim2.fromScale(4, 1)
	billboard.StudsOffsetWorldSpace = Vector3.new(0, size / 2 + 1.5, 0)
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.TextScaled = true
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextStrokeTransparency = 0
	label.Text = animalType
	label.Parent = billboard
	billboard.Parent = part

	part.Parent = animalsFolder

	animals[id] = {
		Id = id,
		Type = animalType,
		Ring = ringNumber,
		Weight = animal.Weight,
		IncomePerSecond = animal.IncomePerSecond,
		Part = part,
	}
	ringCounts[ringNumber] = (ringCounts[ringNumber] or 0) + 1

	return id
end

local function populateRing(ringNumber: number)
	local max = RingConfig[ringNumber].MaxAnimals or 0
	for _ = 1, max do
		if (ringCounts[ringNumber] or 0) >= max then
			break
		end
		if not spawnAnimal(ringNumber) then
			break
		end
	end
end

-- Locates the field marker and populates every active ring. Returns false
-- (after warning) instead of erroring when the marker is missing, so a
-- broken world never crashes the server.
function AnimalSpawner.Start(): boolean
	if started then
		return true
	end

	local markerName = Config.FieldCenterMarkerName
	local marker = Workspace:WaitForChild(markerName, Config.Spawning.FieldCenterWaitTimeout)
	if not marker or not marker:IsA("BasePart") then
		warn(("[AnimalSpawner] no BasePart named %q in Workspace after %ds — spawning disabled. Add the marker and restart the server."):format(
			markerName, Config.Spawning.FieldCenterWaitTimeout))
		return false
	end

	fieldCenter = marker
	started = true

	animalsFolder = Instance.new("Folder")
	animalsFolder.Name = "Animals"
	animalsFolder.Parent = Workspace

	buildSpawnTables()
	for ringNumber in pairs(spawnTables) do
		populateRing(ringNumber)
	end

	return true
end

function AnimalSpawner.GetAnimal(id: string)
	return animals[id]
end

-- Removes a live animal (the future Pickup/Spill entry point) and schedules
-- a respawn into the same ring. Returns the removed record, or nil if the
-- id is unknown — callers must treat nil as an invalid request.
function AnimalSpawner.RemoveAnimal(id: string)
	local animal = animals[id]
	if not animal then
		return nil
	end

	animals[id] = nil
	ringCounts[animal.Ring] -= 1
	animal.Part:Destroy()

	local respawnSeconds = Config.Spawning.RespawnSecondsByRing[animal.Ring]
		or Config.Spawning.DefaultRespawnSeconds
	task.delay(respawnSeconds, function()
		if started then
			populateRing(animal.Ring)
		end
	end)

	return animal
end

return AnimalSpawner
