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

local animals = {} -- id -> { Id, Type, Ring, Weight, IncomePerSecond, Part, Slot? }
local ringCounts = {} -- ring number -> live animal count
local spawnTables = {} -- ring number -> array of active animal type names
local fieldCenter: BasePart? = nil
local animalsFolder: Folder? = nil
local started = false

-- Even distribution: each ring's circumference is divided into MaxAnimals
-- angular sectors and every ring-spawned animal owns one sector, so no side
-- of the field is ever starved while another clumps. Positions are still
-- randomized inside the sector (angle jitter + area-aware radius), and each
-- ring gets a random base rotation per server, so nothing reads as a grid.
-- Spilled animals land wherever they were dropped and own no sector.
local ringSlots = {} -- ring number -> { [slotIndex] = animalId }
local ringSlotRotation = {} -- ring number -> base rotation (radians)

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

		if not ringSlots[animal.Ring] then
			ringSlots[animal.Ring] = {}
			ringSlotRotation[animal.Ring] = rng:NextNumber(0, 2 * math.pi)
		end
	end

	for ringNumber, ring in pairs(RingConfig) do
		if ring.Active and (ring.MaxAnimals or 0) > 0 and not spawnTables[ringNumber] then
			warn(("[AnimalSpawner] ring %d has MaxAnimals but no active animals"):format(ringNumber))
		end
	end
end

-- A random free sector for the next spawn. Free slots are chosen uniformly
-- (never "the same sector again") so simultaneous respawns spread out.
local function pickFreeSlot(ringNumber: number): number?
	local max = RingConfig[ringNumber].MaxAnimals or 0
	local slots = ringSlots[ringNumber]
	local free = {}
	for index = 1, max do
		if slots[index] == nil then
			table.insert(free, index)
		end
	end
	if #free == 0 then
		return nil
	end
	return free[rng:NextInteger(1, #free)]
end

local function slotPosition(ringNumber: number, slotIndex: number): Vector3
	local ring = RingConfig[ringNumber]
	local center = fieldCenter.Position
	local max = ring.MaxAnimals

	-- Randomized angle INSIDE the slot's sector; the 10% margins keep
	-- neighbors from visually merging at sector edges.
	local sectorWidth = 2 * math.pi / max
	local angle = ringSlotRotation[ringNumber]
		+ (slotIndex - 1) * sectorWidth
		+ sectorWidth * rng:NextNumber(0.1, 0.9)
	-- Uniform over the annulus AREA, not the radius, so spawns don't cluster
	-- toward the inner edge.
	local r = math.sqrt(rng:NextNumber(ring.InnerRadius ^ 2, ring.OuterRadius ^ 2))
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

-- Builds and registers a live field animal. Shared by fresh ring spawns and
-- by PlaceAnimal (spill recovery), so a spilled animal is a completely
-- ordinary field animal: same prompt, same claim semantics, grabbable by
-- anyone.
local function createAnimal(id: string, animalType: string, ringNumber: number, weight: number, incomePerSecond: number, position: Vector3): ()
	-- Placeholder: a cube sized by weight so heavier animals read bigger.
	local size = 1.5 + weight * 0.35
	local part = Instance.new("Part")
	part.Name = animalType
	part.Size = Vector3.new(size, size, size)
	part.Color = RING_COLORS[ringNumber] or DEFAULT_COLOR
	part.Material = Enum.Material.SmoothPlastic
	part.Anchored = true
	part.CanCollide = false

	part.CFrame = CFrame.new(position + Vector3.new(0, size / 2, 0))

	part:SetAttribute("AnimalId", id)
	part:SetAttribute("AnimalType", animalType)
	part:SetAttribute("Ring", ringNumber)
	part:SetAttribute("Weight", weight)
	part:SetAttribute("IncomePerSecond", incomePerSecond)

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
		Weight = weight,
		IncomePerSecond = incomePerSecond,
		Part = part,
	}
	ringCounts[ringNumber] = (ringCounts[ringNumber] or 0) + 1
end

local function spawnAnimal(ringNumber: number): string?
	local pool = spawnTables[ringNumber]
	if not pool or #pool == 0 then
		return nil
	end

	local slotIndex = pickFreeSlot(ringNumber)
	if not slotIndex then
		return nil -- every sector occupied (spilled animals may hold the count elsewhere)
	end

	local animalType = pool[rng:NextInteger(1, #pool)]
	local animal = AnimalConfig[animalType]
	local id = HttpService:GenerateGUID(false)
	createAnimal(id, animalType, ringNumber, animal.Weight, animal.IncomePerSecond, slotPosition(ringNumber, slotIndex))
	animals[id].Slot = slotIndex
	ringSlots[ringNumber][slotIndex] = id
	return id
end

-- Returns a previously-claimed animal record to the field as a live animal
-- (spill). Identity is preserved — the same AnimalId becomes claimable again
-- by any player through the normal Pickup path. Rejects an id that is
-- already live, so one record can never produce two field animals.
function AnimalSpawner.PlaceAnimal(record, position: Vector3): boolean
	if not started then
		return false
	end
	if type(record) ~= "table" or type(record.AnimalId) ~= "string" or animals[record.AnimalId] then
		return false
	end

	-- Ground-snap the requested position like normal spawns. Characters are
	-- excluded so a spill never lands an animal on someone's head.
	local height = Config.Spawning.SpawnRaycastHeight
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	local exclude = { animalsFolder }
	for _, player in ipairs(game:GetService("Players"):GetPlayers()) do
		if player.Character then
			table.insert(exclude, player.Character)
		end
	end
	params.FilterDescendantsInstances = exclude
	local hit = Workspace:Raycast(
		Vector3.new(position.X, position.Y + height, position.Z),
		Vector3.new(0, -height * 2, 0),
		params)
	local groundY = if hit then hit.Position.Y else position.Y

	createAnimal(
		record.AnimalId,
		record.AnimalType,
		record.Ring,
		record.Weight,
		record.IncomePerSecond,
		Vector3.new(position.X, groundY, position.Z))
	return true
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
	if animal.Slot then
		ringSlots[animal.Ring][animal.Slot] = nil
	end
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
