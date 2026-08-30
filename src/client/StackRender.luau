-- Client-side visual rendering of every player's carried stack, driven by the
-- server's sanitized CarryVisuals attribute snapshots. Purely cosmetic:
-- anchored client-local parts, CFrame-driven, no physics, never authoritative.

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local AnimalStackProfiles = require(Shared:WaitForChild("AnimalStackProfiles"))
local SR = Config.StackRender

local StackRender = {}

local localPlayer = Players.LocalPlayer

local stacks = {} -- Player -> { entries, folder, connection }
local visualsRoot -- client-local folder in Workspace (never replicates)

local defaultMinZoom

local function visualSize(weight: number): number
	return SR.BaseVisualSize * math.max(weight, 1) ^ SR.WeightScaleExponent
end

local function clearEntries(stack)
	for _, entry in ipairs(stack.entries) do
		entry.part:Destroy()
	end
	stack.entries = {}
end

local function rebuildStack(player: Player)
	local stack = stacks[player]
	if not stack then
		return
	end
	clearEntries(stack)

	local raw = player:GetAttribute("CarryVisuals")
	local ok, list = pcall(HttpService.JSONDecode, HttpService, raw or "[]")
	if not ok or type(list) ~= "table" then
		return
	end

	for index, record in ipairs(list) do
		local size = visualSize(tonumber(record.Weight) or 1)
		local part = Instance.new("Part")
		part.Name = tostring(record.AnimalType)
		part.Size = Vector3.one * size
		part.Color = SR.RingColors[record.Ring] or SR.DefaultColor
		part.Material = Enum.Material.SmoothPlastic
		part.Anchored = true
		part.CanCollide = false
		part.CanTouch = false
		part.CanQuery = false
		part.CastShadow = false

		-- Dev-only label; final art replaces all of this.
		local billboard = Instance.new("BillboardGui")
		billboard.Size = UDim2.fromScale(3, 0.8)
		billboard.StudsOffsetWorldSpace = Vector3.new(0, size / 2 + 0.6, 0)
		local label = Instance.new("TextLabel")
		label.Size = UDim2.fromScale(1, 1)
		label.BackgroundTransparency = 1
		label.TextScaled = true
		label.TextColor3 = Color3.new(1, 1, 1)
		label.TextStrokeTransparency = 0.2
		label.Text = tostring(record.AnimalType)
		label.Parent = billboard
		billboard.Parent = part

		part.Parent = stack.folder
		table.insert(stack.entries, {
			part = part,
			size = size,
			current = nil,
			index = index,
			profile = AnimalStackProfiles[record.AnimalType] or AnimalStackProfiles.Default,
		})
	end
end

local function updateStack(stack, player: Player, dt: number, now: number)
	local character = player.Character
	local hrp = character and character:FindFirstChild("HumanoidRootPart")
	if not hrp or #stack.entries == 0 then
		if stack.folder.Parent then
			stack.folder.Parent = nil -- hide while dead/characterless or empty
		end
		return
	end
	if not stack.folder.Parent then
		stack.folder.Parent = visualsRoot
	end

	-- Yaw-only rotation so the stack doesn't pitch with ragdoll/fall tilts.
	local look = hrp.CFrame.LookVector
	local flatLook = Vector3.new(look.X, 0, look.Z)
	local yawRot = stack.lastYaw or CFrame.new()
	if flatLook.Magnitude > 0.01 then
		yawRot = CFrame.lookAlong(Vector3.zero, flatLook.Unit)
		stack.lastYaw = yawRot
	end

	-- Carry anchor: the animal rests where the ANIMATED HANDS actually are —
	-- the LeftHand/RightHand midpoint this frame — so any avatar's pose and
	-- proportions place the load correctly. The animal's contact surface
	-- sinks CarryOverlap into the hand tops so there is never an air gap.
	local forwardVec = yawRot.LookVector
	local rightVec = yawRot.RightVector
	local leftHand = character:FindFirstChild("LeftHand")
	local rightHand = character:FindFirstChild("RightHand")
	local anchorPos
	if leftHand and rightHand then
		local mid = (leftHand.Position + rightHand.Position) / 2
		anchorPos = Vector3.new(mid.X, mid.Y + leftHand.Size.Y / 2 - SR.CarryOverlap, mid.Z)
	else
		-- No hand parts (R6/unusual rig): fixed offset above the head.
		local refPart = character:FindFirstChild("Head")
			or character:FindFirstChild("UpperTorso")
			or hrp
		anchorPos = Vector3.new(hrp.Position.X,
			refPart.Position.Y + refPart.Size.Y / 2 + SR.FallbackHeightAboveHead - SR.CarryOverlap,
			hrp.Position.Z)
	end
	local anchorY = anchorPos.Y

	local velocity = hrp.AssemblyLinearVelocity
	local horizVel = Vector3.new(velocity.X, 0, velocity.Z)
	local speed = horizVel.Magnitude
	local leanFactor = math.min(speed * SR.LeanAmount, SR.LeanMax)
	local leanDir = speed > 0.5 and -horizVel.Unit or Vector3.zero

	-- Chain stacking: each animal targets the support point of the SMOOTHED
	-- animal below it, so lag and sway cascade upward from a rigid base.
	local supportPos, supportTopY
	for i, entry in ipairs(stack.entries) do
		local profile = entry.profile
		local bottomHalf = profile.BottomOffset or entry.size / 2
		local topHalf = profile.TopSupportOffset or entry.size / 2

		local current
		if i == 1 then
			-- Bottom animal is rigidly held: computed from the live torso
			-- every frame with no smoothing and no sway, so it can never
			-- detach from the hands. This is what "supported" looks like.
			current = anchorPos + Vector3.new(0, bottomHalf, 0)
		else
			local heightAboveAnchor = supportTopY - anchorY + bottomHalf
			local sway = math.sin(now * SR.SwaySpeed + i * 0.7) * SR.SwayAmount * (i - 1)
			local target = Vector3.new(supportPos.X, supportTopY + SR.BaseSpacing + bottomHalf, supportPos.Z)
				+ rightVec * sway
				+ leanDir * (leanFactor * heightAboveAnchor)

			-- Exponential smoothing; higher entries lag more (whip).
			local responsiveness = SR.FollowResponsiveness / (1 + (i - 1) * SR.LagPerAnimal)
			local alpha = 1 - math.exp(-responsiveness * dt)
			current = entry.current and entry.current:Lerp(target, alpha) or target
			-- Never let an animal drift far from its support point.
			if (current - target).Magnitude > 3 then
				current = target
			end
		end
		entry.current = current

		local rot = yawRot
		if profile.Rotation and profile.Rotation ~= 0 then
			rot = yawRot * CFrame.Angles(0, profile.Rotation, 0)
		end
		entry.part.CFrame = CFrame.new(current) * rot

		supportPos = current
		supportTopY = current.Y + topHalf
	end
end

local function updateCamera(dt: number)
	if not defaultMinZoom then
		return
	end
	local weight = localPlayer:GetAttribute("CarriedWeight") or 0
	local capacity = localPlayer:GetAttribute("CarryCapacity") or 30
	local target = defaultMinZoom + (math.clamp(weight / capacity, 0, 1)) * SR.CameraPullbackMax
	local current = localPlayer.CameraMinZoomDistance
	local alpha = 1 - math.exp(-4 * dt)
	localPlayer.CameraMinZoomDistance = current + (target - current) * alpha
end

local function watchPlayer(player: Player)
	if stacks[player] then
		return
	end
	local folder = Instance.new("Folder")
	folder.Name = player.Name
	folder.Parent = visualsRoot
	local stack = { entries = {}, folder = folder }
	stacks[player] = stack
	stack.connection = player:GetAttributeChangedSignal("CarryVisuals"):Connect(function()
		rebuildStack(player)
	end)
	rebuildStack(player)
end

local function dropPlayer(player: Player)
	local stack = stacks[player]
	if not stack then
		return
	end
	if stack.connection then
		stack.connection:Disconnect()
	end
	stack.folder:Destroy()
	stacks[player] = nil
end

function StackRender.Start()
	visualsRoot = Instance.new("Folder")
	visualsRoot.Name = "ClientStackVisuals"
	visualsRoot.Parent = Workspace

	defaultMinZoom = localPlayer.CameraMinZoomDistance

	Players.PlayerAdded:Connect(watchPlayer)
	Players.PlayerRemoving:Connect(dropPlayer)
	for _, player in ipairs(Players:GetPlayers()) do
		watchPlayer(player)
	end

	RunService.RenderStepped:Connect(function(dt)
		local now = os.clock()
		for player, stack in pairs(stacks) do
			updateStack(stack, player, dt, now)
		end
		updateCamera(dt)
	end)
end

return StackRender
