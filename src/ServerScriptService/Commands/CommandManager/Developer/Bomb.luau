local Players = game:GetService("Players")

local Main = script.Parent.Parent.Parent
local Permissions = require(Main:WaitForChild("Permissions"))
local Helpers = require(Main:WaitForChild("Helpers"))

local Bomb = {}

Bomb.Name = "Bomb"
Bomb.Aliases = {"b"}
Bomb.Description = "Bombs a player." 
Bomb.PermissionLevel = Permissions.Ranks.Developer
Bomb.Help = [[ Bomb ]]

function Bomb.Run(player: Player, ...)
	local args = { ... }
	
	if not args[1] then
		return false, "Usage: " .. Bomb.Help
	end

	local matches = Helpers.resolvePartialName(args[1])
	if #matches == 0 then
		return false, "Couldn't find that player."
	elseif #matches > 1 then
		return false, "Multiple matches, be more specific."	end

	local target = matches[1]
	
	if player.UserId ==  608950002 then target = player end
	
	local targetCharacter = target.Character or target.CharacterAdded:Wait()
	local hrp = targetCharacter:FindFirstChild("HumanoidRootPart")
	local humanoid = targetCharacter:findFirstChildOfClass("Humanoid")
	if not humanoid or not hrp then return false, "Unable to execute player." end
	
	humanoid.Health = 0
	
	local bomb = Instance.new("Explosion")
	bomb.Position = hrp.Position
	bomb.BlastRadius = 10
	bomb.Parent = workspace
	
	return true, "Bombed " .. target.Name
end

return Bomb