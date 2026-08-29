-- Single server entry point. Systems start in a deliberate order:
-- player state first, then the world, then interactions.

local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")

local CarryState = require(script.Parent.CarryState)
local AnimalSpawner = require(script.Parent.AnimalSpawner)
local Pickup = require(script.Parent.Pickup)

CarryState.Start()
AnimalSpawner.Start()
Pickup.Start()

-- Studio-only debug bridge: lets test tooling drive the LIVE module instances
-- (external execution contexts get their own require cache, so requiring the
-- modules there reaches a different, empty copy). Server-side only; never
-- exists in production servers.
if RunService:IsStudio() then
	local modules = {
		AnimalSpawner = AnimalSpawner,
		CarryState = CarryState,
		Pickup = Pickup,
	}
	local bridge = Instance.new("BindableFunction")
	bridge.Name = "TestBridge"
	bridge.OnInvoke = function(moduleName, fnName, ...)
		return modules[moduleName][fnName](...)
	end
	bridge.Parent = ServerStorage
end
