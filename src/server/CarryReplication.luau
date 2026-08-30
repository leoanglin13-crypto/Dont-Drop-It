-- Replicates a sanitized, ordered visual snapshot of each player's carried
-- animals as a JSON string in the player's "CarryVisuals" attribute.
-- Attributes replicate to every client automatically (late joiners included),
-- and clients cannot write server-visible attributes — so there is no
-- client -> server channel at all. The server list stays authoritative.

local HttpService = game:GetService("HttpService")

local CarryState = require(script.Parent.CarryState)

local CarryReplication = {}

local function publish(player: Player)
	if not player.Parent then
		return -- player left; nothing to publish
	end
	local snapshot = {}
	for _, record in ipairs(CarryState.GetAnimals(player)) do
		-- Only what StackRender needs; never income, never Instances.
		table.insert(snapshot, {
			AnimalId = record.AnimalId,
			AnimalType = record.AnimalType,
			Ring = record.Ring,
			Weight = record.Weight,
		})
	end
	player:SetAttribute("CarryVisuals", HttpService:JSONEncode(snapshot))
end

function CarryReplication.Start()
	CarryState.OnChanged(publish)
end

return CarryReplication
