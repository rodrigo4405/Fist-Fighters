local ServerScriptService = game:GetService("ServerScriptService")
local DataManager = require(ServerScriptService:WaitForChild("Datastore"):WaitForChild("DataManager"))
local playerStore = DataManager.playerDataStore

local Permissions = {}

Permissions.Ranks = {
	Everyone = 0,
	Moderator = 1,
	Admin = 2,
	Developer = 2.5,
	Creator = 3
}

function Permissions.GetPermissionLevel(player: Player): number
	local data = playerStore:Get(player)
	if not data then return -1 end

	return data["PermissionLevel"] or -1
end

function Permissions.GetRank(player: Player): string?
	local level = Permissions.GetPermissionLevel(player)

	for rank, rankLevel in pairs(Permissions.Ranks) do
		if rankLevel == level then
			return rank
		end
	end

	return nil
end

return Permissions