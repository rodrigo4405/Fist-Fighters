local Players = game:GetService("Players")

local Main = script.Parent.Parent.Parent
local Permissions = require(Main:WaitForChild("Permissions"))
local Helpers = require(Main:WaitForChild("Helpers"))

local DataManager = require(game:GetService("ServerScriptService"):WaitForChild("Datastore"):WaitForChild("DataManager"))
local playerStore = DataManager.playerDataStore

local Rank = {}

Rank.Name = "Rank"
Rank.Aliases = {}
Rank.Description = "Ranks a player to a specified permission level or role name."
Rank.PermissionLevel = Permissions.Ranks.Developer
Rank.Help = [[ rank <player> <level/role name> ]]

function Rank.Run(player: Player, ...): (boolean, string)
	local args = { ... }

	if not args[1] or not args[2] then
		return false, "Usage: " .. Rank.Help
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

	if target == player then
		return false, "You cannot rank yourself."
	end

	local targetLevel = Permissions.GetPermissionLevel(target) or 99
	local playerLevel = Permissions.GetPermissionLevel(player) or -1

	if targetLevel >= playerLevel then
		return false, "You cannot rank someone with an equal or higher rank."
	end

	local newLevel
	for rank, level in pairs(Permissions.Ranks) do
		if string.lower(rank) == string.lower(args[2]) or tonumber(args[2]) == level then
			newLevel = level
			break
		end
	end

	local success = playerStore:Set(target, {PermissionLevel = newLevel})
	if not success then
		return false, "Failed to update player data."
	end

	return true, `Set {target.Name}'s permission level to {newLevel} ({args[2]}).`
end

return Rank
