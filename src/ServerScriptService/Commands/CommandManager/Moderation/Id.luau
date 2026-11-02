local Players = game:GetService("Players")

local Main = script.Parent.Parent.Parent
local Permissions = require(Main:WaitForChild("Permissions"))
local Helpers = require(Main:WaitForChild("Helpers"))

local Id = {}

Id.Name = "Id"
Id.Aliases = {}
Id.Description = "Gets a player userId" 
Id.PermissionLevel = Permissions.Ranks.Moderator
Id.Help = [[ id <player> ]]

function Id.Run(player: Player, ...): (boolean, string)
	local args = { ... }

	if not args[1] then
		return false, "Usage: " .. Id.Help
	end
	
	local matches = Helpers.resolvePartialName(args[1])
	if #matches == 0 then
		return false, "Couldn't find that player."
	elseif #matches > 1 then
		return false, "Multiple matches, be more specific."
	end

	local target = matches[1]
	
	local userId = target.UserId
	
	return userId and true, `{target.Name}'s userId is {userId}` or false, "Couldn't get userId"
end

return Id