local ReplicatedStorage = game:GetService("ReplicatedStorage")
local remotes = ReplicatedStorage:WaitForChild("RemoteFunctions")
local commandFunction = remotes:WaitForChild("RunCommand")

local CommandManager = require(script.Parent:WaitForChild("CommandManager"))

commandFunction.OnServerInvoke = function(player: Player, message: string): (boolean, string)
	if typeof(player) ~= "Instance" or type(message) ~= "string" then
		return false, ""
	end
	if not player or player.Parent ~= game.Players then return false, "" end

	message = message:sub(2)

	local args = string.split(message, " ")
	local command = table.remove(args, 1)

	return CommandManager.Run(player, command:lower(), unpack(args))
end