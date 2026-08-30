-- Assigns each player one of the eight Workspace zoo plots for the session.
-- Assignment is keyed on the Player object, so it survives respawns and is
-- released only when the player leaves. The plot and entrance parts are
-- Jadon-owned world geometry: this module locates them by name and never
-- modifies them.
--
-- Also owns gameplay spawning: every character spawn (initial and respawn)
-- is moved to the player's assigned plot, facing the field, so the generic
-- SpawnLocation never determines where a player actually plays from.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage:WaitForChild("Shared").Config)

local ZooPlots = {}

local plots = {} -- plotId -> { Id, PlotPart, EntrancePart, Owner: Player? }
local assignments = {} -- Player -> plotId
local spawnConnections = {} -- Player -> RBXScriptConnection (CharacterAdded)
local fieldCenter: BasePart? = nil

-- Assignment signals so dependent systems (Bank) can react without ZooPlots
-- knowing about them. Callbacks receive (player, plot).
local assignedListeners = {}
local releasedListeners = {}

function ZooPlots.OnAssigned(callback)
	table.insert(assignedListeners, callback)
end

function ZooPlots.OnReleased(callback)
	table.insert(releasedListeners, callback)
end

local function fire(listeners, player, plot)
	for _, callback in ipairs(listeners) do
		task.spawn(callback, player, plot)
	end
end

local function findPlots()
	local cfg = Config.ZooPlots
	for i = 1, cfg.PlotCount do
		local plotPart = Workspace:FindFirstChild(cfg.PlotNamePrefix .. i)
		local entrancePart = Workspace:FindFirstChild(cfg.EntranceNamePrefix .. i)
		if plotPart and plotPart:IsA("BasePart") and entrancePart and entrancePart:IsA("BasePart") then
			plots[i] = { Id = i, PlotPart = plotPart, EntrancePart = entrancePart, Owner = nil }
		else
			warn(("[ZooPlots] plot %d is missing %q or %q in Workspace — it will never be assigned"):format(
				i, cfg.PlotNamePrefix .. i, cfg.EntranceNamePrefix .. i))
		end
	end
end

-- Where a character stands on this plot: just inside the entrance, facing
-- the field center. Derived from the plot's own geometry, never hard-coded
-- per plot.
function ZooPlots.GetSpawnCFrame(plot): CFrame
	local spawnCfg = Config.ZooPlots.Spawn
	local entrancePos = plot.EntrancePart.Position
	local plotPos = plot.PlotPart.Position

	-- Horizontal direction from the entrance into the plot interior.
	local inward = Vector3.new(plotPos.X - entrancePos.X, 0, plotPos.Z - entrancePos.Z)
	inward = if inward.Magnitude > 0 then inward.Unit else Vector3.zAxis

	local position = entrancePos
		+ inward * spawnCfg.InsetFromEntrance
		+ Vector3.new(0, spawnCfg.SpawnHeight, 0)

	local lookTarget
	if fieldCenter then
		lookTarget = Vector3.new(fieldCenter.Position.X, position.Y, fieldCenter.Position.Z)
	else
		-- No field marker: the entrance sits between plot and field, so
		-- facing out through it is the best available approximation.
		lookTarget = position - inward
	end
	return CFrame.lookAt(position, lookTarget)
end

local function placeCharacter(player: Player, character: Model)
	local plot = ZooPlots.GetPlot(player)
	if not plot then
		return
	end
	if not character:WaitForChild("HumanoidRootPart", 10) then
		return
	end
	-- One frame so the engine's own SpawnLocation placement finishes first
	-- and can never overwrite ours.
	task.wait()
	if player.Character ~= character or not character.Parent then
		return
	end
	character:PivotTo(ZooPlots.GetSpawnCFrame(plot))
end

local function assignPlot(player: Player)
	if assignments[player] then
		return
	end
	for i = 1, Config.ZooPlots.PlotCount do
		local plot = plots[i]
		if plot and not plot.Owner then
			plot.Owner = player
			assignments[player] = i
			player:SetAttribute("ZooPlotId", i)
			print(("[ZooPlots] %s assigned plot %d"):format(player.Name, i))

			-- Every spawn from now on lands at this plot. A character that
			-- spawned before assignment finished is moved as well.
			spawnConnections[player] = player.CharacterAdded:Connect(function(character)
				task.spawn(placeCharacter, player, character)
			end)
			if player.Character then
				task.spawn(placeCharacter, player, player.Character)
			end

			fire(assignedListeners, player, plot)
			return
		end
	end
	-- Unreachable with 8 plots and 8-player servers, but never silent.
	warn(("[ZooPlots] no free plot for %s"):format(player.Name))
end

local function releasePlot(player: Player)
	local plotId = assignments[player]
	if not plotId then
		return
	end
	if spawnConnections[player] then
		spawnConnections[player]:Disconnect()
		spawnConnections[player] = nil
	end
	assignments[player] = nil
	local plot = plots[plotId]
	plot.Owner = nil
	print(("[ZooPlots] %s released plot %d"):format(player.Name, plotId))
	fire(releasedListeners, player, plot)
end

function ZooPlots.GetPlotId(player: Player): number?
	return assignments[player]
end

function ZooPlots.GetPlot(player: Player)
	local plotId = assignments[player]
	return plotId and plots[plotId] or nil
end

function ZooPlots.GetPlotById(plotId: number)
	return plots[plotId]
end

function ZooPlots.GetOwner(plotId: number): Player?
	local plot = plots[plotId]
	return plot and plot.Owner or nil
end

function ZooPlots.Start()
	findPlots()
	-- Same marker convention as AnimalSpawner/RingZones. Missing marker only
	-- degrades spawn facing, so a broken world never blocks plot assignment.
	local marker = Workspace:FindFirstChild(Config.FieldCenterMarkerName)
	if marker and marker:IsA("BasePart") then
		fieldCenter = marker
	else
		warn(("[ZooPlots] no BasePart named %q in Workspace — spawn facing will use the entrance direction."):format(
			Config.FieldCenterMarkerName))
	end
	Players.PlayerAdded:Connect(assignPlot)
	Players.PlayerRemoving:Connect(releasePlot)
	for _, player in ipairs(Players:GetPlayers()) do
		assignPlot(player)
	end
end

return ZooPlots
