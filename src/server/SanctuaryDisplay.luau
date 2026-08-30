-- Visible representation of secured animals inside the owner's Sanctuary.
-- Pure view over Economy.BankedAnimals — it holds no gameplay state of its
-- own, so it can never drift from the authoritative records. Each visual maps
-- to exactly one banked record, placed in bank order.
--
-- Server-rendered on purpose: anchored, collisionless placeholder parts
-- replicate to every client (late joiners included) with zero physics cost,
-- which is what makes another player's Sanctuary visible as a flex. Only
-- buildVisual knows what a displayed animal looks like — swapping in real
-- models later touches nothing else.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)

local Economy = require(script.Parent.Economy)
local ZooPlots = require(script.Parent.ZooPlots)

local SanctuaryDisplay = {}

local displaysFolder: Folder? = nil
local displays = {} -- Player -> { folder, renderedCount, overflowWarned }
local fieldCenter: BasePart? = nil

function SanctuaryDisplay.MaxSlots(): number
	return Config.SanctuaryDisplay.Columns * Config.SanctuaryDisplay.MaxRows
end

-- Deterministic slot placement in plot-LOCAL space, so the same layout works
-- for every rotation of the eight plots. Column 0 is the plot's local -X
-- edge; row 0 hugs the back edge (local +Z, away from the field/entrance)
-- and later rows advance toward the front without reaching the spawn area.
function SanctuaryDisplay.GetSlotCFrame(plotPart: BasePart, slotIndex: number, visualSize: number): CFrame
	local cfg = Config.SanctuaryDisplay
	local col = (slotIndex - 1) % cfg.Columns
	local row = math.floor((slotIndex - 1) / cfg.Columns)

	local localPos = Vector3.new(
		(col - (cfg.Columns - 1) / 2) * cfg.SpacingX,
		plotPart.Size.Y / 2 + visualSize / 2,
		plotPart.Size.Z / 2 - cfg.EdgePadding - row * cfg.SpacingZ)
	local worldPos = plotPart.CFrame:PointToWorldSpace(localPos)

	-- Face the central field, same convention as character spawning.
	local lookTarget
	if fieldCenter then
		lookTarget = Vector3.new(fieldCenter.Position.X, worldPos.Y, fieldCenter.Position.Z)
	else
		lookTarget = worldPos - plotPart.CFrame.LookVector -- plot local -Z = field side
	end
	return CFrame.lookAt(worldPos, lookTarget)
end

-- The single place that decides what a displayed animal looks like.
-- Placeholder: a ring-colored block with a debug label, mirroring the field
-- graybox style. Replace this with real models later; nothing else changes.
local function buildVisual(record, cframe: CFrame, size: number): BasePart
	local part = Instance.new("Part")
	part.Name = record.AnimalType
	part.Size = Vector3.new(size, size, size)
	part.Color = Config.StackRender.RingColors[record.Ring] or Config.StackRender.DefaultColor
	part.Material = Enum.Material.SmoothPlastic
	part.Anchored = true
	part.CanCollide = false
	part.CanTouch = false
	part.CanQuery = false
	part.CFrame = cframe

	-- The visual's link back to its banked record.
	part:SetAttribute("AnimalId", record.AnimalId)
	part:SetAttribute("AnimalType", record.AnimalType)
	part:SetAttribute("Ring", record.Ring)
	part:SetAttribute("Weight", record.Weight)
	part:SetAttribute("IncomePerSecond", record.IncomePerSecond)

	local billboard = Instance.new("BillboardGui")
	billboard.Size = UDim2.fromScale(6, 1.2)
	billboard.StudsOffsetWorldSpace = Vector3.new(0, size / 2 + 1.2, 0)
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.TextScaled = true
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextStrokeTransparency = 0
	label.Text = ("%s · $%d/s"):format(record.AnimalType, record.IncomePerSecond)
	label.Parent = billboard
	billboard.Parent = part

	return part
end

local function ensureDisplay(player: Player, plot)
	local display = displays[player]
	if display then
		return display
	end
	local folder = Instance.new("Folder")
	folder.Name = "Plot_" .. plot.Id
	folder:SetAttribute("OwnerUserId", player.UserId)
	folder.Parent = displaysFolder
	display = { folder = folder, renderedCount = 0, overflowWarned = false }
	displays[player] = display
	return display
end

-- Appends visuals for any banked records not yet rendered. BankedAnimals is
-- append-only during a session, so renderedCount fully describes what is on
-- the plot — repeated calls can never duplicate a visual.
local function render(player: Player)
	local plot = ZooPlots.GetPlot(player)
	if not plot then
		return -- no plot (should not happen for a banking player); records are untouched
	end
	local records = Economy.GetBankedAnimals(player)
	local display = ensureDisplay(player, plot)
	local cfg = Config.SanctuaryDisplay
	local maxSlots = SanctuaryDisplay.MaxSlots()

	for index = display.renderedCount + 1, #records do
		if index > maxSlots then
			if not display.overflowWarned then
				display.overflowWarned = true
				print(("[SanctuaryDisplay] %s has %d secured animals; only %d display slots — overflow stays secured, just not shown"):format(
					player.Name, #records, maxSlots))
			end
			break
		end
		local record = records[index]
		local size = cfg.BaseVisualSize * record.Weight ^ cfg.WeightScaleExponent
		local visual = buildVisual(record, SanctuaryDisplay.GetSlotCFrame(plot.PlotPart, index, size), size)
		visual.Parent = display.folder
		display.renderedCount = index
	end
end

local function cleanup(player: Player)
	local display = displays[player]
	if display then
		display.folder:Destroy()
		displays[player] = nil
	end
end

function SanctuaryDisplay.Start()
	displaysFolder = Instance.new("Folder")
	displaysFolder.Name = "SanctuaryDisplays"
	displaysFolder.Parent = Workspace

	-- Same marker convention as ZooPlots; missing marker only degrades facing.
	local marker = Workspace:FindFirstChild(Config.FieldCenterMarkerName)
	if marker and marker:IsA("BasePart") then
		fieldCenter = marker
	end

	Economy.OnBankedChanged(render)
	ZooPlots.OnReleased(function(player)
		cleanup(player)
	end)
end

return SanctuaryDisplay
