-- Permanent world-space "Your Sanctuary" label over the local player's own
-- Sanctuary entrance. Created entirely client-side, so it exists only on this
-- client and can never label anyone else's screen — other players' plots are
-- untouched. Cosmetic only; no gameplay reads it.
--
-- Placeholder presentation for MVP: plain BillboardGui text matching the
-- graybox debug style. Real UI styling comes later with the HUD pass.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage:WaitForChild("Shared").Config)

local localPlayer = Players.LocalPlayer

local SanctuaryLabel = {}

local currentLabel: BillboardGui? = nil

local function createLabel(entrancePart: BasePart): BillboardGui
	local cfg = Config.SanctuaryLabel
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "SanctuaryLabel"
	billboard.Size = UDim2.fromScale(cfg.WidthStuds, cfg.HeightStuds)
	billboard.StudsOffsetWorldSpace = Vector3.new(0, cfg.HeightAboveEntrance, 0)
	billboard.MaxDistance = cfg.MaxDistance
	billboard.AlwaysOnTop = false

	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.TextScaled = true
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextStrokeTransparency = 0
	label.Text = cfg.Text
	label.Parent = billboard

	billboard.Parent = entrancePart
	return billboard
end

-- Rebuilds the label for the current assignment. ZooPlotId is assigned once
-- per session, but this stays correct even if that ever changes.
local function refresh()
	if currentLabel then
		currentLabel:Destroy()
		currentLabel = nil
	end
	local plotId = localPlayer:GetAttribute("ZooPlotId")
	if plotId == nil then
		return
	end
	local entrance = Workspace:WaitForChild(Config.ZooPlots.EntranceNamePrefix .. plotId, 10)
	if not entrance or not entrance:IsA("BasePart") then
		warn(("[SanctuaryLabel] entrance for plot %s not found; label skipped"):format(tostring(plotId)))
		return
	end
	-- Assignment may have changed while waiting for the entrance to appear.
	if localPlayer:GetAttribute("ZooPlotId") ~= plotId then
		return
	end
	currentLabel = createLabel(entrance)
end

function SanctuaryLabel.Start()
	localPlayer:GetAttributeChangedSignal("ZooPlotId"):Connect(function()
		task.spawn(refresh)
	end)
	task.spawn(refresh)
end

return SanctuaryLabel
