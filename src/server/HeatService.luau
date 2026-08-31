-- Server-authoritative trip risk. Heat exists only while the player carries
-- unbanked animals: it ratchets upward as they get heavier and go deeper
-- (max of current and target), never cools while the trip is live, and
-- resets to 0 the moment the carried trip ends — successful Sanctuary
-- placement or death both empty the carry, so both reset Heat through the
-- same signal. Escaping outward therefore keeps the danger earned going in.
--
-- Event-driven only: recomputed when CarriedWeight or CurrentRing change,
-- never per frame. Clients cannot influence Heat — both inputs are
-- server-set attributes backed by server state.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared").Config)

local CarryState = require(script.Parent.CarryState)

local HeatService = {}

local heats = {} -- Player -> current heat (0..MaxHeat)
local connections = {} -- Player -> { RBXScriptConnection }

-- Fired (player, heat) after a player's Heat value changes.
local heatChangedListeners = {}

function HeatService.OnHeatChanged(callback)
	table.insert(heatChangedListeners, callback)
end

local function tierFor(heat: number): string
	local cfg = Config.Heat
	if heat >= cfg.HotThreshold then
		return "Hot"
	elseif heat >= cfg.CautionThreshold then
		return "Caution"
	end
	return "Clear"
end

function HeatService.GetHeat(player: Player): number
	return heats[player] or 0
end

-- Pure target formula, independently testable. Ring bonus only applies while
-- a trip is active (carrying at least one animal): Heat is the risk of what
-- you are carrying, so empty hands are always Heat 0 — a Ranger never chases
-- an unloaded player.
function HeatService.CalculateTargetHeat(carriedCount: number, carriedWeight: number, capacity: number, ring: number): number
	if carriedCount <= 0 then
		return 0
	end
	local cfg = Config.Heat
	local weightHeat = 0
	if capacity > 0 then
		weightHeat = (carriedWeight / capacity) * cfg.WeightContribution
	end
	local ringBonus = cfg.RingBonus[ring] or 0
	-- TripBaseHeat: carrying anything at all is stealing from Ranger
	-- territory, and Rangers notice immediately.
	return math.clamp(cfg.TripBaseHeat + weightHeat + ringBonus, 0, cfg.MaxHeat)
end

local function setHeat(player: Player, heat: number)
	if heats[player] == heat then
		return
	end
	heats[player] = heat
	player:SetAttribute("Heat", heat)
	player:SetAttribute("HeatTier", tierFor(heat))
	for _, callback in ipairs(heatChangedListeners) do
		task.spawn(callback, player, heat)
	end
end

local function recompute(player: Player)
	if heats[player] == nil then
		return -- player already removed
	end
	local state = CarryState.GetState(player)
	local count = CarryState.GetCount(player)
	local target = HeatService.CalculateTargetHeat(
		count,
		CarryState.GetTotalWeight(player),
		state and state.capacity or Config.StartingCarryWeight,
		player:GetAttribute("CurrentRing") or 0)

	if count == 0 then
		-- Trip over (banked, or lost to death/reset): risk resolves fully.
		setHeat(player, 0)
	else
		-- Live trip: risk only ratchets upward.
		setHeat(player, math.max(heats[player], target))
	end
end

local function watchPlayer(player: Player)
	if connections[player] then
		return
	end
	heats[player] = 0
	player:SetAttribute("Heat", 0)
	player:SetAttribute("HeatTier", tierFor(0))
	connections[player] = {
		player:GetAttributeChangedSignal("CarriedWeight"):Connect(function()
			recompute(player)
		end),
		player:GetAttributeChangedSignal("CurrentRing"):Connect(function()
			recompute(player)
		end),
	}
	recompute(player)
end

local function removePlayer(player: Player)
	local conns = connections[player]
	if conns then
		for _, c in ipairs(conns) do
			c:Disconnect()
		end
		connections[player] = nil
	end
	heats[player] = nil
end

function HeatService.Start()
	Players.PlayerAdded:Connect(watchPlayer)
	Players.PlayerRemoving:Connect(removePlayer)
	for _, player in ipairs(Players:GetPlayers()) do
		watchPlayer(player)
	end
end

return HeatService
