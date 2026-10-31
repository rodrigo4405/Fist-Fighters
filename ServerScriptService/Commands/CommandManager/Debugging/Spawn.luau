local Players = game:GetService("Players")

local Main = script.Parent.Parent.Parent
local Permissions = require(Main:WaitForChild("Permissions"))

local noob = require(game:GetService("ReplicatedStorage"):WaitForChild("Noobs"):WaitForChild("Noob"))

local Spawn = {}

Spawn.Name = "Spawn"
Spawn.Aliases = {"s"}
Spawn.Description = "Spawns a test noob." 
Spawn.PermissionLevel = Permissions.Ranks.Developer
Spawn.Help = [[ Spawn ]]

function Spawn.Run(player: Player, ...)
	local character = player.Character
	local hrp = character:FindFirstChild("HumanoidRootPart")
	if not hrp then return false, "" end

	noob.new(hrp.CFrame + CFrame.new(3,0,0))

	return true, "Spawned noob"
end

return Spawn