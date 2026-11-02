local Main = script.Parent.Parent.Parent
local Permissions = require(Main:WaitForChild("Permissions"))
local Helpers = require(Main:WaitForChild("Helpers"))

local Bring = {}

Bring.Name = "Bring"
Bring.Aliases = {}
Bring.Description = "Brings a player to you"
Bring.PermissionLevel = Permissions.Ranks.Moderator
Bring.Help = "Bring <player>"

local OFFSET = CFrame.new(0, 0, -5)

local function bring(player: Player, target: Player): (boolean, string)
	if target == player then
		return false, "You can't bring yourself."
	end

	local character = player.Character
	local targetCharacter = target.Character
	if not character or not targetCharacter then
		return false, "Couldn't find character"
	end

	local hrp = character:FindFirstChild("HumanoidRootPart")
	local targetHrp = targetCharacter:FindFirstChild("HumanoidRootPart")
	if not hrp or not targetHrp then
		return false, "Couldn't find root part"
	end

	local destination = (hrp.CFrame * OFFSET).Position
	targetCharacter:PivotTo(CFrame.lookAt(destination, hrp.Position))

	return true, `{target.Name} was brought to {player.Name}`
end

function Bring.Run(player: Player, ...): (boolean, string)
	local args = { ... }

	if not args[1] then
		return false, "Usage: " .. Bring.Help
	end
	
	if args[1]:lower() == "all" then
		local brought = 0

		for _, target in game.Players:GetPlayers() do
			if target == player then continue end

			local success = bring(player, target)
			if success then
				brought += 1
			end
		end

		return true, `Brought {brought} players.`
	end
	
	local matches = Helpers.resolvePartialName(args[1])
	if #matches == 0 then
		return false, "Couldn't find that player."
	elseif #matches > 1 then
		return false, "Multiple matches, be more specific."
	end

	return bring(player, matches[1])
end

return Bring