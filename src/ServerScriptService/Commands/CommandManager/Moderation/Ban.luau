local Players = game:GetService("Players")

local Main = script.Parent.Parent.Parent
local Permissions = require(Main:WaitForChild("Permissions"))
local Helpers = require(Main:WaitForChild("Helpers"))

local Ban = {}

Ban.Name = "Ban"
Ban.Aliases = {}
Ban.Description = "Bans a player."
Ban.PermissionLevel = Permissions.Ranks.Admin
Ban.Help = [[ ban <player/userId> <duration:perm/30m/2h/7d:optional> <reason:optional> ]]

function Ban.Run(player: Player, ...): (boolean, string)
	local args = { ... }

	if not args[1] then
		return false, "Usage: " .. Ban.Help
	end

	local target = Helpers.resolvePartialName(args[1])
	if not target then
		return false, "Couldn't find that player."
	end

	if target == player then
		return false, "You can't ban yourself."
	end

	local targetLevel = Permissions.GetPermissionLevel(target) or 99
	local playerLevel = Permissions.GetPermissionLevel(player) or -1

	if targetLevel < Permissions.Ranks.Developer and playerLevel >= Permissions.Ranks.Moderator then
		return false, "You can't ban this player"
	end

	local duration = -1
	local reasonStart = 2

	if args[2] then
		local parsedDuration = Helpers.parseDuration(args[2])
		if parsedDuration then
			duration = parsedDuration
			reasonStart = 3
		elseif args[2]:match("^%d+[smhdwy]$") or args[2]:match("^%d+mo$") or args[2] == "perm" then
			return false, "Invalid duration."
		end
	end

	local reason = table.concat(args, " ", reasonStart)
	if reason == "" then
		reason = "No reason provided."
	end

	local success, err = pcall(function()
		Players:BanAsync({
			UserIds = { target.UserId },
			Duration = duration,
			DisplayReason = reason,
			PrivateReason = `Banned by {player.Name} ({player.UserId}). Reason: {reason}`,
			ExcludeAltAccounts = false,
			ApplyToUniverse = true,
		})
	end)

	if not success then
		warn("Ban failed:", err)
		return false, `Failed to ban {target.Name}.`
	end

	return true, `Banned {target.Name} ({target.UserId}).`
end

return Ban