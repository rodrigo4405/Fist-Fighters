local Players = game:GetService("Players")

local Main = script.Parent.Parent.Parent
local Permissions = require(Main:WaitForChild("Permissions"))
local Helpers = require(Main:WaitForChild("Helpers"))

local ServerScriptService = game:GetService("ServerScriptService")
local DataManager = require(ServerScriptService:WaitForChild("Datastore"):WaitForChild("DataManager"))
local playerStore = DataManager.playerDataStore

local Tag = {}

Tag.Name = "Tag"
Tag.Aliases = {"tags", "title"}
Tag.Description = "Lists your tags or picks which one shows above your head."
Tag.PermissionLevel = Permissions.Ranks.Everyone
Tag.Help = "Tag list | Tag set <tag> | Tag clear"

local function getPlayerTags(player: Player)
	local data = playerStore:Get(player)
	if not data then return false, nil end
	
	local tags = {}
	
	local permissionLevel = data.PermissionLevel
	for rank, level in pairs(Permissions.Ranks) do
		if level == permissionLevel and rank ~= "Everyone" then
			table.insert(tags, rank)
		end
	end
	
	for tag, enabled in pairs(data.Tags or {}) do
		if not enabled then continue end
		table.insert(tags, tag)
	end
	
	return true, tags
end

local function find(tbl: {string}, item: string)
	for _, k in ipairs(tbl) do
		if string.sub(k:lower(), 1, #item) == item:lower() then
			return k
		end
	end
	
	return nil
end

function Tag.Run(player: Player, ...): (boolean, string)
	local args = { ... }

	if not args[1] then
		return false, "Usage: " .. Tag.Help
	end

	if args[1]:lower() == "list" then
		local sucess, tags = getPlayerTags(player)
		return sucess, "Your tags: " .. table.concat(tags, ", ")
	end
	
	if args[1]:lower() == "clear" or args[1]:lower() == "c" then
		playerStore:Set(player, {SelectedTag = ""})
		return true, "Successfully cleared tag"
	end
	
	if args[1]:lower() ~= "set" then return false, "Invalid option" end
	if not args[2] then return false, "Invalid tag" end
	
	local success, tags = getPlayerTags(player)
	if not success or not tags then
		return false, "Couldn't load your data yet, try again in a moment."
	end
	local tag = find(tags, args[2]) 
	
	if not tag then return false, "You don't have this tag" end
	
	playerStore:Set(player, {SelectedTag = tag})
	
	return true, "Successfully set tag to: " .. tag 
end

return Tag