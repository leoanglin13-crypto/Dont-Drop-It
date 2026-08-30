-- Carry-pose animation. Production path: a real published Animation asset id
-- in Config.StackRender.CarryAnimationId (see the publish steps in the Day 4
-- report). Until that exists, a Studio-only prototype pose is built here as a
-- KeyframeSequence and registered for a temporary id — visible in playtests,
-- impossible to ship by accident (RegisterKeyframeSequence is Studio-only).
-- No Motor6D manipulation anywhere; locomotion stays untouched.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local KeyframeSequenceProvider = game:GetService("KeyframeSequenceProvider")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

local CarryPose = {}

local localPlayer = Players.LocalPlayer
local track: AnimationTrack? = nil
-- Keep the built sequence referenced so the registered asset stays alive.
local prototypeSequence: KeyframeSequence? = nil

-- R15 upper-body-only pose: arms raised and bent to support a held load.
-- Only arm-chain Poses carry weight, so legs/torso keep normal locomotion.
local function buildCarryPoseSequence(): KeyframeSequence
	local sequence = Instance.new("KeyframeSequence")
	sequence.Name = "CarryPoseDraft"
	sequence.Loop = true
	sequence.Priority = Enum.AnimationPriority.Action

	local function addKeyframe(time: number, armPitch: number, elbowPitch: number)
		local keyframe = Instance.new("Keyframe")
		keyframe.Time = time

		local function pose(name: string, cf: CFrame?, weight: number?)
			local p = Instance.new("Pose")
			p.Name = name
			p.CFrame = cf or CFrame.new()
			p.Weight = weight or 1
			p.EasingStyle = Enum.PoseEasingStyle.Cubic
			p.EasingDirection = Enum.PoseEasingDirection.InOut
			return p
		end

		-- Weight-0 chain down to the arms so torso/legs stay locomotion-owned.
		local root = pose("HumanoidRootPart", nil, 0)
		local lowerTorso = pose("LowerTorso", nil, 0)
		local upperTorso = pose("UpperTorso", nil, 0)
		root:AddSubPose(lowerTorso)
		lowerTorso:AddSubPose(upperTorso)

		for _, side in ipairs({ "Left", "Right" }) do
			local mirror = if side == "Left" then 1 else -1
			-- Arms raised overhead, angled slightly outward so they frame the
			-- face instead of covering it; elbows softly bent.
			local upperArm = pose(side .. "UpperArm",
				CFrame.Angles(math.rad(armPitch), math.rad(-6 * mirror), math.rad(14 * mirror)))
			local lowerArm = pose(side .. "LowerArm", CFrame.Angles(math.rad(elbowPitch), 0, 0))
			local hand = pose(side .. "Hand", CFrame.Angles(math.rad(15), 0, 0))
			upperTorso:AddSubPose(upperArm)
			upperArm:AddSubPose(lowerArm)
			lowerArm:AddSubPose(hand)
		end

		keyframe:AddPose(root)
		keyframe.Parent = sequence
	end

	-- Arms raised with bent elbows, hands around crown level — not a rigid
	-- full vertical extension. The stack anchors to the hands, so these
	-- angles shape the silhouette rather than dictating the animal height.
	addKeyframe(0, 150, 32)
	addKeyframe(0.9, 146, 29) -- subtle breathing so the held loop feels alive
	addKeyframe(1.8, 150, 32)
	return sequence
end

local function resolveAnimationId(): string?
	local id = Config.StackRender.CarryAnimationId
	if id ~= nil and id ~= "" then
		return id
	end
	if not RunService:IsStudio() then
		return nil -- no published asset yet; production plays no pose
	end
	-- Register fresh on every character load: a cached registration can go
	-- stale once nothing engine-side references it, silently playing nothing.
	if not prototypeSequence then
		prototypeSequence = buildCarryPoseSequence()
	end
	local ok, result = pcall(function()
		return KeyframeSequenceProvider:RegisterKeyframeSequence(prototypeSequence)
	end)
	if ok then
		return result
	end
	warn("[CarryPose] prototype pose registration failed: " .. tostring(result))
	return nil
end

local function refresh()
	if not track then
		return
	end
	local carrying = (localPlayer:GetAttribute("CarriedCount") or 0) > 0
	if carrying and not track.IsPlaying then
		track:Play(0.2)
	elseif not carrying and track.IsPlaying then
		track:Stop(0.2)
	end
end

local function onCharacter(character: Model)
	track = nil
	local id = resolveAnimationId()
	if not id then
		return
	end

	local humanoid = character:WaitForChild("Humanoid", 10)
	if not humanoid then
		return
	end
	-- On a fresh character the Animator is created slightly after
	-- CharacterAdded fires, so wait briefly instead of giving up.
	local animator = humanoid:FindFirstChildOfClass("Animator")
		or humanoid:WaitForChild("Animator", 5)
	if not animator or not animator:IsA("Animator") then
		return
	end

	local animation = Instance.new("Animation")
	animation.AnimationId = id
	track = animator:LoadAnimation(animation)
	track.Priority = Enum.AnimationPriority.Action
	track.Looped = true

	-- The engine stops foreign tracks while a fresh character initializes,
	-- which silently killed the pose after respawn. If the track stops while
	-- the player is still carrying, resume it (the deliberate stop in
	-- refresh() only happens when CarriedCount is 0, so they never fight).
	local thisTrack = track
	thisTrack.Stopped:Connect(function()
		task.defer(function()
			if track == thisTrack and (localPlayer:GetAttribute("CarriedCount") or 0) > 0 then
				thisTrack:Play(0.2)
			end
		end)
	end)

	refresh()
end

function CarryPose.Start()
	localPlayer:GetAttributeChangedSignal("CarriedCount"):Connect(refresh)
	localPlayer.CharacterAdded:Connect(onCharacter)
	if localPlayer.Character then
		task.spawn(onCharacter, localPlayer.Character)
	end
end

return CarryPose
