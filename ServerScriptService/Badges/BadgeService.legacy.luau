local BadgeService = game:GetService("BadgeService")
local Players = game:GetService("Players")

local CONFIG = require(script.Parent:WaitForChild("Configuration"))
local BadgeManager = require(script.Parent:WaitForChild("BadgeManager"))

local devsInGame = {}

Players.PlayerAdded:Connect(function(plr)
	BadgeManager.AwardBadge(plr, "first_time")
	
	if table.find(CONFIG.DevIds, plr.UserId) then
		table.insert(devsInGame, plr.UserId)
		if #devsInGame == 1 then 
			BadgeManager.BulkAward(Players:GetPlayers(), "met_devs")
		end		
	elseif #devsInGame ~= 0 then
		BadgeManager.AwardBadge(plr, "met_devs")
	end
end)

Players.PlayerRemoving:Connect(function(plr)
	if table.find(CONFIG.DevIds, plr.UserId) then
		local i = table.find(devsInGame, plr.UserId)
		if not i then return end
		table.remove(devsInGame, i)
	end
end)