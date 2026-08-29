-- Pickup interaction and server-side validation. The claim on a field animal
-- is AnimalSpawner.RemoveAnimal: whichever caller receives the record owns it,
-- so two players can never both take the same animal.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local AnimalConfig = require(Shared.AnimalConfig)

local AnimalSpawner = require(script.Parent.AnimalSpawner)
local CarryState = require(script.Parent.CarryState)

local Pickup = {}

local function attachPrompt(animalPart: Instance)
	if not animalPart:IsA("BasePart") then
		return
	end
	if animalPart:FindFirstChildOfClass("ProximityPrompt") then
		return
	end

	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Grab"
	prompt.ObjectText = tostring(animalPart:GetAttribute("AnimalType"))
	prompt.HoldDuration = 0
	prompt.RequiresLineOfSight = false
	prompt.MaxActivationDistance = Config.Pickup.PromptDistance
	prompt.Triggered:Connect(function(player)
		Pickup.TryPickup(player, animalPart)
	end)
	prompt.Parent = animalPart
end

-- Full validation + claim. Synchronous on purpose: there is no yield between
-- validation and the RemoveAnimal claim.
function Pickup.TryPickup(player, animalPart): boolean
	if typeof(player) ~= "Instance" or not player:IsA("Player") or player.Parent ~= Players then
		return false
	end
	local character = player.Character
	if not character then
		return false
	end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then
		return false
	end
	local rootPart = character:FindFirstChild("HumanoidRootPart")
	if not rootPart then
		return false
	end

	if typeof(animalPart) ~= "Instance" or not animalPart:IsA("BasePart") then
		return false
	end
	local id = animalPart:GetAttribute("AnimalId")
	if type(id) ~= "string" then
		return false
	end

	-- Authoritative existence check; nil also covers already-claimed animals.
	local animal = AnimalSpawner.GetAnimal(id)
	if not animal then
		return false
	end
	if not AnimalConfig[animal.Type] then
		return false
	end

	-- Never trust the prompt for distance.
	local distance = (rootPart.Position - animalPart.Position).Magnitude
	if distance > Config.Pickup.MaxPickupDistance then
		return false
	end

	if not CarryState.CanAdd(player, { Weight = animal.Weight }) then
		return false
	end

	-- The claim: exactly one caller receives the record.
	local claimed = AnimalSpawner.RemoveAnimal(id)
	if not claimed then
		return false
	end

	local record = {
		AnimalId = claimed.Id,
		AnimalType = claimed.Type,
		Ring = claimed.Ring,
		Weight = claimed.Weight,
		IncomePerSecond = claimed.IncomePerSecond,
	}
	if not CarryState.AddAnimal(player, record) then
		-- Unreachable unless something yields between CanAdd and here. Loud,
		-- because failing now would mean a claimed animal vanished.
		warn(("[Pickup] claimed %s for %s but AddAnimal failed"):format(record.AnimalType, player.Name))
		return false
	end

	print(("[Pickup] %s grabbed %s | weight %d/%d"):format(
		player.Name,
		record.AnimalType,
		CarryState.GetTotalWeight(player),
		player:GetAttribute("CarryCapacity")))
	return true
end

function Pickup.Start()
	local folder = Workspace:WaitForChild("Animals", 30)
	if not folder then
		warn("[Pickup] Workspace.Animals not found — is AnimalSpawner running? Pickup disabled.")
		return
	end
	for _, child in ipairs(folder:GetChildren()) do
		attachPrompt(child)
	end
	folder.ChildAdded:Connect(attachPrompt)
end

return Pickup
