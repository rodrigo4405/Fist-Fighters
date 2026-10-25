local Players = game:GetService("Players")
local player = Players.LocalPlayer

local function isFriend(plr)
	local success, result = pcall(function()
		return player:IsFriendsWithAsync(plr.UserId)
	end)
	if not success then return result end
	
	plr:SetAttribute("IsFriend", result)
end

Players.PlayerAdded:Connect(isFriend)

for _, plr in ipairs(Players:GetPlayers()) do
	isFriend(plr)
end