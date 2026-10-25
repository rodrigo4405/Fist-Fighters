local Main = script.Parent.Parent.Parent
local Permissions = require(Main:WaitForChild("Permissions"))
local Helpers = require(Main:WaitForChild("Helpers"))

local Teleport = {}

Teleport.Name = "Teleport"
Teleport.Aliases = {"tp", "to"}
Teleport.Description = "Teleports you to a player"
Teleport.PermissionLevel = Permissions.Ranks.Moderator
Teleport.Help = "Teleport <player>"

local OFFSET = CFrame.new(0, 0, -5)

function Teleport.Run(player: Player, ...): (boolean, string)
	local args = { ... }

	if not args[1] then
		return false, "Usage: " .. Teleport.Help
	end

	local matches = Helpers.resolvePartialName(args[1])
	if #matches == 0 then
		return false, "Couldn't find that player."
	elseif #matches > 1 then
		return false, "Multiple matches, be more specific."
	end

	local target = matches[1]

	if target == player then
		return false, "You can't teleport to yourself."
	end

	local character = player.Character
	local targetCharacter = target.Character
	if not character or not targetCharacter then return false, "Couldn't find character" end

	local hrp = character:FindFirstChild("HumanoidRootPart")
	local targetHrp = targetCharacter:FindFirstChild("HumanoidRootPart")
	if not hrp or not targetHrp then return false, "Couldn't find root part" end

	local destination = (targetHrp.CFrame * OFFSET).Position
	character:PivotTo(CFrame.lookAt(destination, targetHrp.Position))

	return true, `Teleported to {target.Name}`
end

return Teleport