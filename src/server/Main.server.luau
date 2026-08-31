-- Single server entry point. Systems start in a deliberate order:
-- player state first, then the world, then movement, then interactions.

local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")

local CarryState = require(script.Parent.CarryState)
local CarryReplication = require(script.Parent.CarryReplication)
local Economy = require(script.Parent.Economy)
local Bank = require(script.Parent.Bank)
local SanctuaryDisplay = require(script.Parent.SanctuaryDisplay)
local ZooPlots = require(script.Parent.ZooPlots)
local AnimalSpawner = require(script.Parent.AnimalSpawner)
local RingZones = require(script.Parent.RingZones)
local WeightMovement = require(script.Parent.WeightMovement)
local Pickup = require(script.Parent.Pickup)
local HeatService = require(script.Parent.HeatService)
local RangerService = require(script.Parent.RangerService)
local Spill = require(script.Parent.Spill)
local Ragdoll = require(script.Parent.Ragdoll)

CarryState.Start()
CarryReplication.Start()
Economy.Start()
-- Bank and SanctuaryDisplay subscribe to plot assignment/release, so they
-- must start before ZooPlots assigns plots to already-present players.
Bank.Start()
SanctuaryDisplay.Start()
ZooPlots.Start()
AnimalSpawner.Start()
RingZones.Start()
WeightMovement.Start()
Pickup.Start()
-- RangerService subscribes to HeatService, and Spill subscribes to
-- RangerService, so they start in that order.
HeatService.Start()
RangerService.Start()
Spill.Start()

if RunService:IsStudio() then
	-- Studio-only test bridge for driving the live module instances from
	-- external test tooling. Everything below exists ONLY in Studio; a
	-- published production server never creates any debug bridge.
	local modules = {
		AnimalSpawner = AnimalSpawner,
		CarryState = CarryState,
		CarryReplication = CarryReplication,
		Economy = Economy,
		Bank = Bank,
		SanctuaryDisplay = SanctuaryDisplay,
		ZooPlots = ZooPlots,
		RingZones = RingZones,
		WeightMovement = WeightMovement,
		Pickup = Pickup,
		HeatService = HeatService,
		RangerService = RangerService,
		Spill = Spill,
		Ragdoll = Ragdoll,
	}
	local bridge = Instance.new("BindableFunction")
	bridge.Name = "TestBridge"
	bridge.OnInvoke = function(moduleName, fnName, ...)
		return modules[moduleName][fnName](...)
	end
	bridge.Parent = ServerStorage
end
