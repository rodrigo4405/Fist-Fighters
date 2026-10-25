local BadgeService = game:GetService("BadgeService")
local CONFIG = require(script.Parent:WaitForChild("Configuration"))

local BadgeManager = {}

function BadgeManager.AwardBadge(player: Player, badgeName: string): boolean
	local badgeId = CONFIG.Badges[badgeName]
	if not badgeId then
		return false
	end

	local success, result = pcall(function()
		return BadgeService:AwardBadgeAsync(player.UserId, badgeId)
	end)

	return success and result
end

function BadgeManager.BulkAward(players: {Player}, badgeName: string): boolean
	if not players then
		return false
	end

	for _, player in pairs(players) do
		if not BadgeManager.AwardBadge(player, badgeName) then
			return false
		end
	end

	return true
end

return BadgeManager