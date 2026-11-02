local Players = game:GetService("Players")

local Main = script.Parent.Parent.Parent
local Permissions = require(Main:WaitForChild("Permissions"))
local Helpers = require(Main:WaitForChild("Helpers"))

local Superman = {}

Superman.Name = "Superman"
Superman.Aliases = {"super"}
Superman.Description = "Supermans a player." 
Superman.PermissionLevel = Permissions.Ranks.Developer
Superman.Help = [[  ]]

function Superman.Run(player: Player, ...)
	local args = { ... }

	local character = player.Character
	if not character then return false, "Couldn't find character" end
	
	local ff = character:FindFirstChildWhichIsA("ForceField")
	if ff then 
		ff:Destroy()
		return true, "Superman disabled"
	end
	
	local forcefield = Instance.new("ForceField")
	forcefield.Parent = character
	forcefield.Visible = false
	
	return true, "Superman active"
end

return Superman