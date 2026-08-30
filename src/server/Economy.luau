-- Server-authoritative session economy: Cash, BankedIncomePerSecond, and the
-- immutable record of every banked animal. Session-only — no persistence yet.
--
-- Banked animals are stored as full frozen records (not just a summed number)
-- so later zoo-ownership features (rendering, rarity, mutations, index) can
-- extend the records without replacing this architecture.
-- BankedIncomePerSecond is always derived from the records, never accumulated
-- separately, so the two can never drift apart.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared").Config)

local Economy = {}

local states = {} -- Player -> { cash, bankedIncomePerSecond, bankedAnimals }

local function updateAttributes(player, state)
	player:SetAttribute("Cash", state.cash)
	player:SetAttribute("BankedIncomePerSecond", state.bankedIncomePerSecond)
end

function Economy.InitPlayer(player: Player)
	if states[player] then
		return
	end
	local state = {
		cash = 0,
		bankedIncomePerSecond = 0,
		bankedAnimals = {},
	}
	states[player] = state
	updateAttributes(player, state)
end

function Economy.RemovePlayer(player: Player)
	states[player] = nil
end

function Economy.HasState(player: Player): boolean
	return states[player] ~= nil
end

-- Records animals as permanently banked for this session. Each record is
-- cloned and frozen so a banked animal can never be mutated after the fact.
-- Returns the income per second added, or nil if the player has no state
-- (callers must check before consuming carried animals).
function Economy.AddBankedAnimals(player: Player, records): number?
	local state = states[player]
	if not state then
		return nil
	end
	for _, record in ipairs(records) do
		table.insert(state.bankedAnimals, table.freeze(table.clone(record)))
	end
	local total = 0
	for _, banked in ipairs(state.bankedAnimals) do
		total += banked.IncomePerSecond or 0
	end
	local added = total - state.bankedIncomePerSecond
	state.bankedIncomePerSecond = total
	updateAttributes(player, state)
	return added
end

-- Snapshot of frozen banked records; safe to hand out.
function Economy.GetBankedAnimals(player: Player)
	local state = states[player]
	if not state then
		return {}
	end
	return table.clone(state.bankedAnimals)
end

function Economy.GetState(player: Player)
	local state = states[player]
	if not state then
		return nil
	end
	return {
		Cash = state.cash,
		BankedIncomePerSecond = state.bankedIncomePerSecond,
		BankedCount = #state.bankedAnimals,
	}
end

function Economy.Start()
	Players.PlayerAdded:Connect(Economy.InitPlayer)
	Players.PlayerRemoving:Connect(Economy.RemovePlayer)
	for _, player in ipairs(Players:GetPlayers()) do
		Economy.InitPlayer(player)
	end

	-- Single service-level income loop for all players — never one loop per
	-- player. Deterministic: Cash += rate * tickSeconds each tick.
	task.spawn(function()
		while true do
			task.wait(Config.Economy.IncomeTickSeconds)
			for player, state in pairs(states) do
				if state.bankedIncomePerSecond > 0 then
					state.cash += state.bankedIncomePerSecond * Config.Economy.IncomeTickSeconds
					updateAttributes(player, state)
				end
			end
		end
	end)
end

return Economy
