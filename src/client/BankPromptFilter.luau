-- Controls local visibility of Sanctuary PLACE prompts: only the local
-- player's own prompt, and only while they are carrying at least one animal.
-- Event-driven off the replicated CarriedCount attribute — never polled.
--
-- Visual convenience only — the server validates ownership, distance and
-- carry contents on every place attempt regardless of what any client
-- displays. Enabled is a local-only property change; it never replicates,
-- and the server never touches Enabled after creating a prompt, so nothing
-- here can be overwritten by replication.

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")

local localPlayer = Players.LocalPlayer

local BankPromptFilter = {}

local ownPrompts = {} -- ProximityPrompt -> true (own-Sanctuary prompts only)

local function refreshOwnPrompts()
	local carrying = (localPlayer:GetAttribute("CarriedCount") or 0) > 0
	for prompt in pairs(ownPrompts) do
		prompt.Enabled = carrying
	end
end

local function apply(prompt: Instance)
	if not prompt:IsA("ProximityPrompt") then
		return
	end
	if prompt:GetAttribute("BankOwnerUserId") == localPlayer.UserId then
		ownPrompts[prompt] = true
		refreshOwnPrompts()
	else
		-- Never show someone else's Sanctuary prompt on this client.
		prompt.Enabled = false
	end
end

local function forget(prompt: Instance)
	ownPrompts[prompt] = nil
end

function BankPromptFilter.Start()
	CollectionService:GetInstanceAddedSignal("BankPrompt"):Connect(apply)
	CollectionService:GetInstanceRemovedSignal("BankPrompt"):Connect(forget)
	localPlayer:GetAttributeChangedSignal("CarriedCount"):Connect(refreshOwnPrompts)
	for _, prompt in ipairs(CollectionService:GetTagged("BankPrompt")) do
		apply(prompt)
	end
end

return BankPromptFilter
