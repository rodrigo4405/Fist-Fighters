local Players = game:GetService("Players")

local Main = script.Parent.Parent.Parent
local Permissions = require(Main:WaitForChild("Permissions"))
local Helpers = require(Main:WaitForChild("Helpers"))

local TextChatService = game:GetService("TextChatService")
local channel = TextChatService:WaitForChild("TextChannels"):WaitForChild("RBXGeneral")
local systemChannel = TextChatService:WaitForChild("TextChannels"):WaitForChild("RBXSystem")

local Whisper = {}

Whisper.Name = "Whisper"
Whisper.Aliases = {"w"}
Whisper.Description = "Whispers to a player if u can chat with that user"
Whisper.PermissionLevel = Permissions.Ranks.Everyone
Whisper.Help = "Whisper <player> <message>"


function Whisper.Run(player: Player, ...): (boolean, string)
	local args = { ... }

	if not args[1] then
		return false, "Usage: " .. Whisper.Help
	end

	local matches = Helpers.resolvePartialName(args[1])
	if #matches == 0 then
		return false, "Couldn't find that player."
	elseif #matches > 1 then
		return false, "Multiple matches, be more specific."	end

	local target = matches[1]
	
	if target == player then return false, "You can't whisper to yourself." end
	
	local success, canChat = pcall(function() return TextChatService:CanUsersChatAsync(player.UserId, target.UserId) end)
	if not (success and canChat) then return false, "You can't whisper to this player." end
	
	local message = table.concat(args, " ", 2)
	
	return true, "whisper:" .. player.UserId .. ":" .. target.UserId .. ":" .. message
end

return Whisper