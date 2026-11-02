local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local Map = Workspace:WaitForChild("Map")

local userIds = {3200533020, 608950002, 2548330406}
local npcs = {
	["shop"] = Map.Shop.Shopkeeper,
	["cave"] = Map.CaveNPC,
	["???"] = Map.UnknownNPC
}

local positions = {}

local function setPositions()
	local available = {}

	for key, npc in pairs(npcs) do
		table.insert(available, key)
	end

	for _, userId in ipairs(userIds) do
		if #available == 0 then
			break
		end

		local rnd = math.random(1, #available)
		local key = table.remove(available, rnd)

		positions[userId] = key
	end
end

local function spawnNPC(positions)
	for userId, position in pairs(positions) do
		local npc = npcs[position]
		
		local humanoidDescription = Players:GetHumanoidDescriptionFromUserIdAsync(userId)
		local humanoid = npc:WaitForChild("Humanoid")
		humanoid:ApplyDescription(humanoidDescription)
		
		-- keep only hats
		for _, part in npc:GetChildren() do
			if part:IsA("Accessory") then
				if part.AccessoryType ~= Enum.AccessoryType.Hat then
					part:Destroy()
				end
			end
		end
		
	end
end

setPositions()
spawnNPC(positions)