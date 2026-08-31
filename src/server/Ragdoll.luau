-- Temporary, fully-reversible ragdoll for both R15 rig generations:
--
--  * Constraint-based avatars (current Roblox default): every joint is an
--    AnimationConstraint with a native BallSocketConstraint already behind
--    it. Ragdoll = disable the AnimationConstraints; the native sockets
--    (with Roblox-tuned limits) take over. Nothing is created or destroyed.
--  * Classic Motor6D rigs: motors are disabled (never destroyed) and
--    bridged with temporary BallSocketConstraints built from each motor's
--    own C0/C1, removed again on restore.
--
-- PlatformStand keeps the humanoid state machine from fighting the collapse;
-- clearing it lets the character get up on its own. Standalone utility so
-- future impacts (player bumps) can reuse it. Never kills, never breaks
-- joints permanently, restores reliably even if the character dies or
-- leaves mid-ragdoll.

local Ragdoll = {}

local active = {} -- character -> restore record

function Ragdoll.IsRagdolled(character: Model): boolean
	return active[character] ~= nil
end

function Ragdoll.Restore(character: Model)
	local record = active[character]
	if not record then
		return
	end
	active[character] = nil

	for _, instance in ipairs(record.temporary) do
		instance:Destroy()
	end
	for _, joint in ipairs(record.joints) do
		if joint.Parent then
			joint.Enabled = true
		end
	end
	for part, wasCollidable in pairs(record.colliders) do
		if part.Parent then
			part.CanCollide = wasCollidable
		end
	end

	local humanoid = record.humanoid
	if humanoid.Parent and humanoid.Health > 0 then
		humanoid.RequiresNeck = record.requiresNeck
		humanoid.PlatformStand = false
		humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
	end
end

-- Ragdolls the character for durationSeconds, then restores automatically.
-- Safe no-op when already ragdolled or when there is no live humanoid.
function Ragdoll.Apply(character: Model, durationSeconds: number)
	if active[character] then
		return
	end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local root = character:FindFirstChild("HumanoidRootPart")
	if not humanoid or humanoid.Health <= 0 or not root then
		return
	end

	local record = {
		humanoid = humanoid,
		requiresNeck = humanoid.RequiresNeck,
		joints = {}, -- disabled AnimationConstraints / Motor6Ds to re-enable
		temporary = {}, -- instances we created, destroyed on restore
		colliders = {}, -- part -> original CanCollide
	}

	-- Disabling the neck joint must never count as decapitation.
	humanoid.RequiresNeck = false

	for _, descendant in ipairs(character:GetDescendants()) do
		if descendant:IsA("AnimationConstraint") then
			-- Constraint rig: the native BallSocketConstraint behind this
			-- joint takes over the moment the rigid animation joint is off.
			descendant.Enabled = false
			table.insert(record.joints, descendant)
		elseif descendant:IsA("Motor6D") and descendant.Part0 and descendant.Part1 then
			-- Classic rig: bridge the motor with a temporary ball socket.
			local attachment0 = Instance.new("Attachment")
			attachment0.CFrame = descendant.C0
			attachment0.Parent = descendant.Part0
			local attachment1 = Instance.new("Attachment")
			attachment1.CFrame = descendant.C1
			attachment1.Parent = descendant.Part1

			local socket = Instance.new("BallSocketConstraint")
			socket.Attachment0 = attachment0
			socket.Attachment1 = attachment1
			-- Limits stop the uncontrollable-spin failure mode.
			socket.LimitsEnabled = true
			socket.TwistLimitsEnabled = true
			socket.Parent = descendant.Part0

			descendant.Enabled = false
			table.insert(record.joints, descendant)
			table.insert(record.temporary, attachment0)
			table.insert(record.temporary, attachment1)
			table.insert(record.temporary, socket)
		elseif descendant:IsA("BasePart") and descendant ~= root then
			-- Limbs need collision while the humanoid isn't holding the body up.
			record.colliders[descendant] = descendant.CanCollide
			descendant.CanCollide = true
		end
	end

	humanoid.PlatformStand = true
	humanoid:ChangeState(Enum.HumanoidStateType.Physics)

	active[character] = record
	task.delay(durationSeconds, function()
		Ragdoll.Restore(character)
	end)
end

return Ragdoll
