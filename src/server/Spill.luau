-- The catch consequence: a Ranger reaching a loaded player spills the ENTIRE
-- carried stack and boots the player away. "Lose the trip, never secured
-- property" — Banked animals, Cash and the Sanctuary are never touched.
--
-- Spilled animals are not deleted: each carried record goes back into the
-- world through AnimalSpawner.PlaceAnimal as a completely ordinary field
-- animal (same id, same prompt, same claim semantics), scattered around the
-- catch position. The player watches their haul go everywhere and can try to
-- re-grab it — and because spilled animals are normal field animals, they
-- are already contestable by anyone, which is exactly the future PvP hook.
--
-- Emptying the carry ends the trip: Heat resets and the Rangers walk home
-- through the existing signals, so a freshly-spilled player cannot be
-- stunlocked by repeat catches.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared").Config)

local AnimalSpawner = require(script.Parent.AnimalSpawner)
local CarryState = require(script.Parent.CarryState)
local Ragdoll = require(script.Parent.Ragdoll)
local RangerService = require(script.Parent.RangerService)

local Spill = {}

local rng = Random.new()

-- Spills everything the player carries around a world position. Returns the
-- number of animals spilled. Safe no-op on an empty carry.
function Spill.SpillCarried(player: Player, aroundPosition: Vector3): number
	local records = CarryState.TakeAll(player)
	if #records == 0 then
		return 0
	end
	local cfg = Config.Spill
	for _, record in ipairs(records) do
		local angle = rng:NextNumber(0, 2 * math.pi)
		local radius = rng:NextNumber(cfg.ScatterRadiusMin, cfg.ScatterRadiusMax)
		local position = aroundPosition + Vector3.new(math.cos(angle) * radius, 0, math.sin(angle) * radius)
		if not AnimalSpawner.PlaceAnimal(record, position) then
			-- Should not happen (ids leave the registry on claim); loud so a
			-- vanished animal never goes unnoticed.
			warn(("[Spill] failed to place spilled %s (%s)"):format(record.AnimalType, record.AnimalId))
		end
	end
	return #records
end

-- Predictable, config-driven boot away from the Ranger. Never a kill, never
-- a cross-map launch. A brief LinearVelocity constraint is used because a
-- raw velocity write is damped immediately by Humanoid ground control on the
-- owning client; the constraint replicates and wins for its short lifetime.
local function knockback(character: Model, awayFrom: Vector3, ring: number)
	local root = character:FindFirstChild("HumanoidRootPart")
	if not root or not root:IsA("BasePart") then
		return
	end
	-- Deeper rings hit harder; fall back to the shared values.
	local byRing = Config.Rangers.ByRing[ring]
	local cfg = (byRing and byRing.Knockback) or Config.Rangers.Knockback
	local dir = Vector3.new(root.Position.X - awayFrom.X, 0, root.Position.Z - awayFrom.Z)
	if dir.Magnitude < 0.05 then
		local angle = rng:NextNumber(0, 2 * math.pi)
		dir = Vector3.new(math.cos(angle), 0, math.sin(angle))
	else
		dir = dir.Unit
	end

	-- The ragdoll (applied just before this) already frees the body from
	-- Humanoid ground control, so no jump-state pop is needed.
	local attachment = Instance.new("Attachment")
	attachment.Parent = root
	local velocity = Instance.new("LinearVelocity")
	velocity.Attachment0 = attachment
	velocity.MaxForce = math.huge
	velocity.VectorVelocity = dir * cfg.HorizontalSpeed + Vector3.new(0, cfg.VerticalSpeed, 0)
	velocity.Parent = root
	task.delay(Config.Rangers.Knockback.DurationSeconds, function()
		velocity:Destroy()
		attachment:Destroy()
	end)
end

function Spill.Start()
	RangerService.OnCaught(function(player, ranger)
		if not player.Parent then
			return
		end
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		if not root then
			return
		end
		local spilled = Spill.SpillCarried(player, root.Position)
		if spilled > 0 then
			-- Impact sequence: stack scatters, body crumples, boot away.
			Ragdoll.Apply(character, Config.Rangers.RagdollDuration)
			knockback(character, ranger.Part.Position, ranger.Ring)
			print(("[Spill] %s caught by Ring %d Ranger — %d animals scattered"):format(
				player.Name, ranger.Ring, spilled))
		end
	end)
end

return Spill
