-- Server-authoritative Ranger pressure, tower-based.
--
-- Rangers are guards, not spawners-around-the-player: each active ring has a
-- Lookout Tower in Workspace (RangerTowers/Ring<N>Tower/RangerSpawn) and a
-- Ranger always originates from — and returns to — its ring's tower. The
-- towers are replaceable art; only the RangerSpawn marker part matters here.
--
-- Territory: the FIELD is Ranger territory. A Ranger activated by ring N
-- chases its target outward through every ring, but never crosses the outer
-- Ring 1 boundary (Config.FieldRadius). When the target escapes the field,
-- spills the trip, banks, dies, or leaves, the Ranger walks home and
-- despawns at its tower — no popping out in front of the player.
--
-- States: "Pursuing" -> "Returning" -> despawned at home.
--
-- A Ranger is permanently assigned to one target player; per-player counts
-- are driven by that player's Heat (and whether they are inside the field),
-- so players' Ranger states can never interfere. Rangers own no economy
-- state: a catch only fires OnCaught, which Spill consumes.
--
-- Performance: ONE update loop steps every active Ranger; no per-Ranger
-- connections, no Workspace scans.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local RingConfig = require(Shared.RingConfig)

local HeatService = require(script.Parent.HeatService)

local RangerService = {}

local PURSUING_COLOR = Color3.fromRGB(220, 60, 50)
local RETURNING_COLOR = Color3.fromRGB(235, 150, 60)

local rangersFolder: Folder? = nil
local fieldCenter: BasePart? = nil
local towerSpawns = {} -- ring -> Vector3 (RangerSpawn marker position)
local missingTowerWarned = {} -- ring -> true

local pursuing = {} -- Player -> array of ranger { Part, Target, Ring, Home, Speed, LastCatch }
local returning = {} -- array of ranger walking home

-- Per-PLAYER catch immunity: while ragdolled/recovering from one impact, no
-- Ranger (including a second one arriving the same tick) can land another.
local catchGraceUntil = {} -- Player -> os.clock() deadline

-- Fired (player, ranger) when a Ranger reaches its target. Spill consumes
-- this; RangerService itself applies no penalty.
local caughtListeners = {}

function RangerService.OnCaught(callback)
	table.insert(caughtListeners, callback)
end

function RangerService.GetRangerCount(player: Player): number
	local list = pursuing[player]
	return list and #list or 0
end

function RangerService.GetReturningCount(): number
	return #returning
end

-- Desired pursuit pressure for a heat value; pure and testable.
function RangerService.DesiredCount(heat: number): number
	local cfg = Config.Rangers
	if heat >= cfg.SecondRangerHeat then
		return 2
	elseif heat >= cfg.FirstRangerHeat then
		return 1
	end
	return 0
end

local function speedForRing(ring: number): number
	local byRing = Config.Rangers.ByRing[ring]
	return byRing and byRing.MoveSpeed or Config.Rangers.DefaultMoveSpeed
end

local function flatOffsetFromCenter(position: Vector3): (number, number, number)
	local dx = position.X - fieldCenter.Position.X
	local dz = position.Z - fieldCenter.Position.Z
	return dx, dz, math.sqrt(dx * dx + dz * dz)
end

local function isOutsideField(position: Vector3): boolean
	if not fieldCenter then
		return false
	end
	local _, _, dist = flatOffsetFromCenter(position)
	return dist > Config.FieldRadius
end

-- Rangers never cross the outer Ring 1 boundary.
local function clampToField(position: Vector3): Vector3
	if not fieldCenter then
		return position
	end
	local maxRadius = Config.FieldRadius - Config.Rangers.BoundaryMargin
	local dx, dz, dist = flatOffsetFromCenter(position)
	if dist <= maxRadius then
		return position
	end
	local scale = maxRadius / dist
	return Vector3.new(
		fieldCenter.Position.X + dx * scale,
		position.Y,
		fieldCenter.Position.Z + dz * scale)
end

local function groundHeight(x: number, z: number, fallbackY: number): number
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	local exclude = { rangersFolder }
	for _, player in ipairs(Players:GetPlayers()) do
		if player.Character then
			table.insert(exclude, player.Character)
		end
	end
	params.FilterDescendantsInstances = exclude
	local hit = Workspace:Raycast(Vector3.new(x, 80, z), Vector3.new(0, -160, 0), params)
	return hit and hit.Position.Y or fallbackY
end

-- The single place that decides what a Ranger looks like.
local function buildRangerVisual(targetPlayer: Player, ring: number): BasePart
	local part = Instance.new("Part")
	part.Name = "Ranger"
	part.Size = Vector3.new(2, 5, 2)
	part.Color = PURSUING_COLOR
	part.Material = Enum.Material.SmoothPlastic
	part.Anchored = true
	part.CanCollide = false
	part.CanTouch = false
	part.CanQuery = false
	part:SetAttribute("TargetUserId", targetPlayer.UserId)
	part:SetAttribute("Ring", ring)
	part:SetAttribute("State", "Pursuing")

	local billboard = Instance.new("BillboardGui")
	billboard.Size = UDim2.fromScale(5, 1.2)
	billboard.StudsOffsetWorldSpace = Vector3.new(0, 3.6, 0)
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.TextScaled = true
	label.TextColor3 = Color3.fromRGB(255, 80, 70)
	label.TextStrokeTransparency = 0
	label.Text = ("RING %d RANGER"):format(ring)
	label.Parent = billboard
	billboard.Parent = part
	return part
end

local function updateActiveRangersAttribute(player: Player)
	if player.Parent then
		player:SetAttribute("ActiveRangers", RangerService.GetRangerCount(player))
	end
end

local function sendHome(ranger)
	ranger.Part:SetAttribute("State", "Returning")
	ranger.Part.Color = RETURNING_COLOR
	table.insert(returning, ranger)
end

local function spawnRanger(player: Player, ring: number)
	local home = towerSpawns[ring]
	if not home then
		if not missingTowerWarned[ring] then
			missingTowerWarned[ring] = true
			warn(("[RangerService] no tower spawn marker for ring %d — that ring cannot field Rangers"):format(ring))
		end
		return
	end
	local part = buildRangerVisual(player, ring)
	part.CFrame = CFrame.new(home)
	part.Parent = rangersFolder

	local list = pursuing[player]
	if not list then
		list = {}
		pursuing[player] = list
	end
	table.insert(list, { Part = part, Target = player, Ring = ring, Home = home, Speed = speedForRing(ring), LastCatch = 0 })
	updateActiveRangersAttribute(player)
	print(("[RangerService] Ring %d Ranger deployed on %s (heat %s) — %d active"):format(
		ring, player.Name, tostring(player:GetAttribute("Heat")), #list))
end

-- State-machine rule: a Ranger that is still walking home when its target
-- re-acquires a trip re-engages that SAME target (Returning -> Pursuing)
-- instead of a fresh Ranger spawning. Only a Ranger that reached home and
-- despawned counts as reset.
local function reengageReturning(player: Player): boolean
	for index, ranger in ipairs(returning) do
		if ranger.Target == player then
			table.remove(returning, index)
			ranger.Part:SetAttribute("State", "Pursuing")
			ranger.Part.Color = PURSUING_COLOR
			local list = pursuing[player]
			if not list then
				list = {}
				pursuing[player] = list
			end
			table.insert(list, ranger)
			updateActiveRangersAttribute(player)
			print(("[RangerService] Ring %d Ranger re-engages %s before reaching home"):format(
				ranger.Ring, player.Name))
			return true
		end
	end
	return false
end

-- Brings the player's pursuit to what their Heat demands — but only inside
-- the field: the moment the target is beyond the Ring 1 boundary, desired
-- pressure is zero and every assigned Ranger heads home. Idempotent, capped.
local function reconcile(player: Player)
	if not player.Parent then
		return
	end
	local heat = HeatService.GetHeat(player)
	local inField = player:GetAttribute("InField") == true
	local desired = if inField then RangerService.DesiredCount(heat) else 0
	local list = pursuing[player]
	local current = list and #list or 0

	if current > desired then
		for i = current, desired + 1, -1 do
			sendHome(table.remove(list, i))
		end
		if desired == 0 then
			pursuing[player] = nil
		end
		updateActiveRangersAttribute(player)
		print(("[RangerService] %s pressure over — Rangers returning to their towers"):format(player.Name))
	elseif current < desired then
		local ring = math.clamp(player:GetAttribute("CurrentRing") or 1, 1, 4)
		for _ = current + 1, desired do
			-- A Ranger still walking home comes back for you first.
			if not reengageReturning(player) then
				spawnRanger(player, ring)
			end
		end
	end
end

local function fireCaught(player: Player, ranger)
	player:SetAttribute("RangerCatches", (player:GetAttribute("RangerCatches") or 0) + 1)
	print(("[RangerService] CATCH — Ring %d Ranger reached %s (heat %s)"):format(
		ranger.Ring, player.Name, tostring(player:GetAttribute("Heat"))))
	for _, callback in ipairs(caughtListeners) do
		task.spawn(callback, player, ranger)
	end
end

local function moveToward(ranger, targetX: number, targetZ: number, dt: number)
	local pos = ranger.Part.Position
	local flat = Vector3.new(targetX, pos.Y, targetZ)
	local offset = flat - pos
	local distance = offset.Magnitude
	if distance < 0.05 then
		return distance
	end
	local stepLength = math.min(ranger.Speed * dt, distance)
	local newPos = clampToField(pos + offset.Unit * stepLength)
	local y = groundHeight(newPos.X, newPos.Z, pos.Y) + 2.5
	ranger.Part.CFrame = CFrame.lookAt(Vector3.new(newPos.X, y, newPos.Z), Vector3.new(targetX, y, targetZ))
	return distance - stepLength
end

-- Returns true when the ranger should switch to Returning.
local function stepPursuit(ranger, dt: number): boolean
	local player = ranger.Target
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not root or not humanoid or humanoid.Health <= 0 then
		return false -- momentary; death empties the carry and reconcile sends us home
	end

	-- Territory rule: target beyond the Ring 1 boundary ends the pursuit.
	if isOutsideField(root.Position) then
		return true
	end

	local cfg = Config.Rangers
	local pos = ranger.Part.Position
	local flatDistance = (Vector3.new(root.Position.X, pos.Y, root.Position.Z) - pos).Magnitude
	if flatDistance <= cfg.CatchDistance then
		local now = os.clock()
		if now >= (catchGraceUntil[player] or 0) and now - ranger.LastCatch >= cfg.CatchCooldown then
			ranger.LastCatch = now
			-- Set synchronously BEFORE firing so a second Ranger stepping in
			-- this same tick cannot land a second catch on a downed player.
			catchGraceUntil[player] = now + cfg.CatchGraceSeconds
			fireCaught(player, ranger)
		end
		return false
	end

	moveToward(ranger, root.Position.X, root.Position.Z, dt)
	return false
end

local function stepAll(dt: number)
	-- Pursuers (transitions collected, then applied, so lists stay stable).
	for player, list in pairs(pursuing) do
		local toReturn = nil
		for index, ranger in ipairs(list) do
			if stepPursuit(ranger, dt) then
				toReturn = toReturn or {}
				table.insert(toReturn, index)
			end
		end
		if toReturn then
			for i = #toReturn, 1, -1 do
				sendHome(table.remove(list, toReturn[i]))
			end
			if #list == 0 then
				pursuing[player] = nil
			end
			updateActiveRangersAttribute(player)
		end
	end

	-- Returners walk home and despawn at their tower.
	for i = #returning, 1, -1 do
		local ranger = returning[i]
		local remaining = moveToward(ranger, ranger.Home.X, ranger.Home.Z, dt)
		if remaining <= Config.Rangers.HomeArriveDistance then
			ranger.Part:Destroy()
			table.remove(returning, i)
		end
	end
end

-- Exactly one tower per ACTIVE ring (from RingConfig): future rings get
-- towers only when they are activated, and a missing tower for an active
-- ring is a loud warning, never a silent gap.
local function findTowers()
	local cfg = Config.Rangers
	local folder = Workspace:FindFirstChild(cfg.TowersFolderName)
	if not folder then
		warn(("[RangerService] Workspace.%s not found — no Rangers can spawn"):format(cfg.TowersFolderName))
		return
	end
	for ringNumber, ring in pairs(RingConfig) do
		if not ring.Active then
			continue
		end
		local tower = folder:FindFirstChild(("Ring%dTower"):format(ringNumber))
		local marker = tower and tower:FindFirstChild(cfg.SpawnMarkerName, true)
		if marker and marker:IsA("BasePart") then
			towerSpawns[ringNumber] = marker.Position
		elseif tower then
			-- Tower without a marker: fall back to the tower's own pivot.
			towerSpawns[ringNumber] = tower:GetPivot().Position
			warn(("[RangerService] Ring%dTower has no %s marker; using tower pivot"):format(ringNumber, cfg.SpawnMarkerName))
		else
			warn(("[RangerService] active ring %d has no Ring%dTower — it cannot field Rangers"):format(ringNumber, ringNumber))
		end
	end
end

function RangerService.Start()
	rangersFolder = Instance.new("Folder")
	rangersFolder.Name = "Rangers"
	rangersFolder.Parent = Workspace

	local marker = Workspace:FindFirstChild(Config.FieldCenterMarkerName)
	if marker and marker:IsA("BasePart") then
		fieldCenter = marker
	end
	findTowers()

	HeatService.OnHeatChanged(function(player, _heat)
		reconcile(player)
	end)

	local function watchPlayer(player: Player)
		player:SetAttribute("ActiveRangers", 0)
		-- Re-entering / leaving the field changes desired pressure even when
		-- Heat itself did not change.
		player:GetAttributeChangedSignal("InField"):Connect(function()
			reconcile(player)
		end)
	end
	Players.PlayerAdded:Connect(watchPlayer)
	for _, player in ipairs(Players:GetPlayers()) do
		watchPlayer(player)
	end
	Players.PlayerRemoving:Connect(function(player)
		catchGraceUntil[player] = nil
		local list = pursuing[player]
		if list then
			pursuing[player] = nil
			for _, ranger in ipairs(list) do
				sendHome(ranger)
			end
		end
	end)

	-- The one update loop for every active Ranger on the server.
	task.spawn(function()
		local last = os.clock()
		while true do
			task.wait(Config.Rangers.UpdateInterval)
			local now = os.clock()
			local dt = now - last
			last = now
			stepAll(dt)
		end
	end)
end

return RangerService
