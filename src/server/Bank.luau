-- Banking: converts a player's carried animals into permanent session value
-- at their own zoo plot. Server-authoritative end to end — the prompt is only
-- a request; ownership, distance, liveness and the carried list are all
-- validated and read server-side. CarryState.TakeAll is the atomic claim that
-- makes banking the same carried animals twice impossible.

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared").Config)

local CarryState = require(script.Parent.CarryState)
local Economy = require(script.Parent.Economy)
local ZooPlots = require(script.Parent.ZooPlots)

local Bank = {}

local prompts = {} -- plotId -> ProximityPrompt

local function createPrompt(player: Player, plot)
	if prompts[plot.Id] then
		prompts[plot.Id]:Destroy()
	end
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = Config.Banking.PromptActionText
	prompt.ObjectText = Config.Banking.PromptObjectText
	prompt.HoldDuration = 0
	prompt.RequiresLineOfSight = false
	prompt.MaxActivationDistance = Config.Banking.PromptDistance
	-- Lets clients hide prompts that aren't theirs. Visual convenience only:
	-- TryBank validates ownership regardless of what any client displays.
	prompt:SetAttribute("BankOwnerUserId", player.UserId)
	CollectionService:AddTag(prompt, "BankPrompt")
	prompt.Triggered:Connect(function(triggeringPlayer)
		Bank.TryBank(triggeringPlayer, plot.Id)
	end)
	prompt.Parent = plot.EntrancePart
	prompts[plot.Id] = prompt
end

local function destroyPrompt(plotId: number)
	if prompts[plotId] then
		prompts[plotId]:Destroy()
		prompts[plotId] = nil
	end
end

-- Full validation + bank. Synchronous on purpose: there is no yield between
-- validation, the TakeAll claim and the Economy write.
function Bank.TryBank(player, plotId): boolean
	if typeof(player) ~= "Instance" or not player:IsA("Player") or player.Parent ~= Players then
		return false
	end

	-- A player may only bank at THEIR OWN plot.
	if ZooPlots.GetPlotId(player) ~= plotId then
		print(("[Bank] %s rejected: plot %s is not theirs"):format(player.Name, tostring(plotId)))
		return false
	end
	local plot = ZooPlots.GetPlotById(plotId)
	if not plot then
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

	-- Never trust the prompt for distance.
	local distance = (rootPart.Position - plot.EntrancePart.Position).Magnitude
	if distance > Config.Banking.MaxBankDistance then
		return false
	end

	-- Empty carry banks nothing, safely.
	if CarryState.GetCount(player) == 0 then
		return false
	end

	-- Economy must be able to receive the animals BEFORE they are claimed,
	-- or a bank could destroy the carried stack without paying for it.
	if not Economy.HasState(player) then
		warn(("[Bank] %s has no economy state; bank refused"):format(player.Name))
		return false
	end

	-- The claim: exactly one caller receives the records. Everything carried
	-- clears only because the records are now owned by this bank.
	local records = CarryState.TakeAll(player)
	if #records == 0 then
		return false
	end

	local added = Economy.AddBankedAnimals(player, records)
	local newRate = player:GetAttribute("BankedIncomePerSecond")

	print(("[Bank] BANK SUCCESS — %s\n  Animals: %d\n  Added income: +$%s/s\n  New income: $%s/s"):format(
		player.Name, #records, tostring(added), tostring(newRate)))
	return true
end

function Bank.Start()
	-- Subscribe before ZooPlots assigns anything (Main starts Bank first),
	-- plus a defensive sweep for any plot already assigned.
	ZooPlots.OnAssigned(createPrompt)
	ZooPlots.OnReleased(function(_player, plot)
		destroyPrompt(plot.Id)
	end)
	for plotId = 1, Config.ZooPlots.PlotCount do
		local owner = ZooPlots.GetOwner(plotId)
		if owner then
			createPrompt(owner, ZooPlots.GetPlotById(plotId))
		end
	end
end

return Bank
