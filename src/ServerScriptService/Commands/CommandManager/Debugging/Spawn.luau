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
	local args = { ... }
	local n = 1
	
	if args[1] then
		n = tonumber(args[1]) or n
	end
	
	local character = player.Character
	local hrp = character:FindFirstChild("HumanoidRootPart")
	if not hrp then return false, "" end

	for i=1,n do
		noob.new(hrp.CFrame * CFrame.new(math.random(-5,5),0,math.random(-5,5)))
	end

	return true, "Spawned noob"
end

return Spawn