-- Authoritative server-side record of what each player currently carries.
-- Carried records are plain immutable data tables — never Instance references.
-- All writes go through this module; getters return snapshots.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared").Config)

local CarryState = {}

local states = {} -- Player -> { animals = {ordered records}, totalWeight, capacity }

-- Minimal state-change signal so other systems (e.g. replication) can react
-- without CarryState knowing about networking.
local changedListeners = {}

function CarryState.OnChanged(callback)
	table.insert(changedListeners, callback)
end

local function fireChanged(player)
	for _, callback in ipairs(changedListeners) do
		task.spawn(callback, player)
	end
end

local function updateAttributes(player, state)
	player:SetAttribute("CarriedWeight", state.totalWeight)
	player:SetAttribute("CarriedCount", #state.animals)
	player:SetAttribute("CarryCapacity", state.capacity)
end

function CarryState.InitPlayer(player: Player)
	if states[player] then
		return
	end
	local state = {
		animals = {},
		totalWeight = 0,
		capacity = Config.StartingCarryWeight,
	}
	states[player] = state
	updateAttributes(player, state)
	fireChanged(player)
end

function CarryState.RemovePlayer(player: Player)
	states[player] = nil
	fireChanged(player)
end

-- Ordered shallow snapshot; mutating the result never touches real state.
function CarryState.GetAnimals(player: Player)
	local state = states[player]
	if not state then
		return {}
	end
	return table.clone(state.animals)
end

function CarryState.GetState(player: Player)
	local state = states[player]
	if not state then
		return nil
	end
	return {
		animals = table.clone(state.animals),
		totalWeight = state.totalWeight,
		capacity = state.capacity,
	}
end

function CarryState.GetTotalWeight(player: Player): number
	local state = states[player]
	return state and state.totalWeight or 0
end

function CarryState.GetCount(player: Player): number
	local state = states[player]
	return state and #state.animals or 0
end

function CarryState.CanAdd(player: Player, record): boolean
	local state = states[player]
	if not state then
		return false
	end
	if type(record) ~= "table" or type(record.Weight) ~= "number" or record.Weight <= 0 then
		return false
	end
	return state.totalWeight + record.Weight <= state.capacity
end

function CarryState.AddAnimal(player: Player, record): boolean
	if not CarryState.CanAdd(player, record) then
		return false
	end
	local state = states[player]
	table.insert(state.animals, record)
	state.totalWeight += record.Weight
	updateAttributes(player, state)
	fireChanged(player)
	return true
end

-- Atomically removes and returns every carried record, in carry order.
-- This is the single synchronous claim point for consuming a carried stack
-- (bank now, spill later): exactly one caller receives the records, so the
-- same carried animals can never be consumed twice.
function CarryState.TakeAll(player: Player)
	local state = states[player]
	if not state or #state.animals == 0 then
		return {}
	end
	local taken = state.animals
	state.animals = {}
	state.totalWeight = 0
	updateAttributes(player, state)
	fireChanged(player)
	return taken
end

-- "You lose the trip, never the property": dying or resetting forfeits every
-- currently carried animal. Without this, respawning at the Sanctuary would
-- let players skip the escape entirely (grab deep -> reset -> place safely).
-- Banked animals, Cash and the Sanctuary are never touched here.
local function watchCharacter(player: Player, character: Model)
	local humanoid = character:WaitForChild("Humanoid", 10)
	if not humanoid or not humanoid:IsA("Humanoid") then
		return
	end
	humanoid.Died:Connect(function()
		local lost = CarryState.TakeAll(player)
		if #lost > 0 then
			print(("[CarryState] %s died — trip lost (%d carried animals forfeited)"):format(
				player.Name, #lost))
		end
	end)
end

local function watchPlayer(player: Player)
	CarryState.InitPlayer(player)
	player.CharacterAdded:Connect(function(character)
		task.spawn(watchCharacter, player, character)
	end)
	if player.Character then
		task.spawn(watchCharacter, player, player.Character)
	end
end

function CarryState.Start()
	Players.PlayerAdded:Connect(watchPlayer)
	Players.PlayerRemoving:Connect(CarryState.RemovePlayer)
	for _, player in ipairs(Players:GetPlayers()) do
		watchPlayer(player)
	end
end

return CarryState
