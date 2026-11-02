local Players = game:GetService("Players")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local remotes = ReplicatedStorage:WaitForChild("RemoteFunctions")
local changeView = remotes:WaitForChild("ChangeView")

local Main = script.Parent.Parent.Parent
local Permissions = require(Main:WaitForChild("Permissions"))
local Helpers = require(Main:WaitForChild("Helpers"))

local View = {}

View.Name = "View"
View.Aliases = {}
View.Description = "Views a player point of view." 
View.PermissionLevel = Permissions.Ranks.Moderator
View.Help = [[ view <player:optional> ]]

function View.Run(player: Player, ...): (boolean, string)
	local args = { ... }
	
	local success 
	if not args[1] then
		success = changeView:InvokeClient(player, player)
		if not success then return false, "Failed to view player." end
		return true, "Successfully stopped viewing."
	end

	local matches = Helpers.resolvePartialName(args[1])
	if #matches == 0 then
		return false, "Couldn't find that player."
	elseif #matches > 1 then
		return false, "Multiple matches, be more specific."
	end

	local target = matches[1]

	success = changeView:InvokeClient(player, target)
	
	if not success then return false, "Failed to view player." end
	return true, "Successfully viewed player."
end

return View