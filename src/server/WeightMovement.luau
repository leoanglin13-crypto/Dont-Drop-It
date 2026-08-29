-- Applies weight-based movement slowdown. Event-driven: speed is recalculated
-- only when carried weight changes or a character (re)spawns — never per frame.
-- Touches Humanoid.WalkSpeed only; jump and gravity are untouched.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared").Config)
local CarryState = require(script.Parent.CarryState)

local WeightMovement = {}

local connections = {} -- Player -> { RBXScriptConnection }

-- Pure formula, independently testable.
function WeightMovement.CalculateSpeed(weight: number, capacity: number): number
	if type(capacity) ~= "number" or capacity <= 0 then
		return Config.BaseWalkSpeed
	end
	local w = math.clamp(weight, 0, capacity)
	local speed = Config.BaseWalkSpeed * (1 - (w / capacity) ^ Config.SpeedExponent * Config.SpeedPenalty)
	return math.max(speed, 0)
end

local function applySpeed(player: Player)
	local character = player.Character
	if not character then
		return
	end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
		or character:WaitForChild("Humanoid", 5)
	if not humanoid or not humanoid:IsA("Humanoid") then
		return -- character without a valid Humanoid; skip safely
	end

	-- Authoritative weight and capacity come from CarryState, never attributes.
	local state = CarryState.GetState(player)
	local capacity = state and state.capacity or Config.StartingCarryWeight
	local speed = WeightMovement.CalculateSpeed(CarryState.GetTotalWeight(player), capacity)

	humanoid.WalkSpeed = speed
	player:SetAttribute("EffectiveWalkSpeed", speed)
end

local function watchPlayer(player: Player)
	if connections[player] then
		return
	end
	local conns = {}
	-- CarriedWeight is the server-set change signal; the calculation itself
	-- reads authoritative CarryState.
	table.insert(conns, player:GetAttributeChangedSignal("CarriedWeight"):Connect(function()
		applySpeed(player)
	end))
	table.insert(conns, player.CharacterAdded:Connect(function()
		applySpeed(player)
	end))
	connections[player] = conns
	applySpeed(player)
end

function WeightMovement.Start()
	Players.PlayerAdded:Connect(watchPlayer)
	Players.PlayerRemoving:Connect(function(player)
		local conns = connections[player]
		if conns then
			for _, c in ipairs(conns) do
				c:Disconnect()
			end
			connections[player] = nil
		end
	end)
	for _, player in ipairs(Players:GetPlayers()) do
		watchPlayer(player)
	end
end

return WeightMovement
