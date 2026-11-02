local Players = game:GetService("Players")

local Main = script.Parent.Parent.Parent
local Permissions = require(Main:WaitForChild("Permissions"))
local Helpers = require(Main:WaitForChild("Helpers"))

local Kick = {}

Kick.Name = "Kick"
Kick.Aliases = {}
Kick.Description = "Kicks a player." 
Kick.PermissionLevel = Permissions.Ranks.Moderator
Kick.Help = [[ kick <player> <reason:optional> ]]

function Kick.Run(player: Player, ...): (boolean, string)
	local args = { ... }

	if not args[1] then
		return false, "Usage: " .. Kick.Help
	end
	
	local target
	if tonumber(target) ~= nil then
		Players:GetPlayerByUserId(tonumber(args[1]))
	end
	
	if not target then
		local matches = Helpers.resolvePartialName(args[1])
		if #matches == 0 then
			return false, "Couldn't find that player."
		elseif #matches > 1 then
			return false, "Multiple matches, be more specific."
		end
		
		target = matches[1]
	end
	
	local targetLevel = Permissions.GetPermissionLevel(target) or 99
	local playerLevel = Permissions.GetPermissionLevel(player) or -1
	
	if targetLevel < Permissions.Ranks.Developer and playerLevel >= Permissions.Ranks.Moderator then
		return false, "You can't kick this player"
	end

	local reason = table.concat(args, " ", 2)
	if reason == "" then
		target:Kick(`{player.Name} has kicked you.`)
	else
		target:Kick(`{player.Name} has kicked you. Reason: {reason}`)
	end

	if target == player then
		return true, "" 
	end
	return true, `Kicked {target.Name} ({target.UserId}).`
end

return Kick