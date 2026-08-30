-- Client entry point. Visual/presentation systems start here.

local StackRender = require(script.Parent.StackRender)
local CarryPose = require(script.Parent.CarryPose)
local BankPromptFilter = require(script.Parent.BankPromptFilter)
local SanctuaryLabel = require(script.Parent.SanctuaryLabel)

StackRender.Start()
CarryPose.Start()
BankPromptFilter.Start()
SanctuaryLabel.Start()
