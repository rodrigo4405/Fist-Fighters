local Players = game:GetService("Players")
local StarterPack = game:GetService("StarterPack")

local Main = script.Parent.Parent.Parent
local Permissions = require(Main:WaitForChild("Permissions"))
local Helpers = require(Main:WaitForChild("Helpers"))

local Freeze = {}

Freeze.Name = "Freeze"
Freeze.Aliases = {}
Freeze.Description = "Freezes a player."
Freeze.PermissionLevel = Permissions.Ranks.Moderator
Freeze.Help = "Freeze <player>"

local function freeze(player: Player, target: Player): (boolean, string)
	local targetLevel = Permissions.GetPermissionLevel(target) or 99
	local playerLevel = Permissions.GetPermissionLevel(player) or -1

	if targetLevel >= playerLevel then
		return false, "You cannot freeze someone with an equal or higher rank."
	end

	local character = target.Character or target.CharacterAdded:Wait()
	local hrp = character:FindFirstChild("HumanoidRootPart")
	local humanoid = character:FindFirstChildOfClass("Humanoid")

	if not humanoid or not hrp then
		return false, "Unable to freeze player."
	end

	if hrp.Anchored then
		local combatTool = StarterPack:WaitForChild("Combat"):Clone()
		combatTool.Parent = target.Backpack
		hrp.Anchored = false
		return true, "Unfroze " .. target.Name
	else
		local combatTool = character:FindFirstChildOfClass("Tool")
			or target.Backpack:FindFirstChildOfClass("Tool")

		if combatTool then combatTool:Destroy() end

		hrp.Anchored = true
		return true, "Froze " .. target.Name
	end
end

function Freeze.Run(player: Player, ...): (boolean, string)
	local args = { ... }

	if not args[1] then
		return false, "Usage: " .. Freeze.Help
	end

	if args[1]:lower() == "all" then
		local frozen = 0

		for _, target in Players:GetPlayers() do
			if target == player then continue end

			local success = freeze(player, target)
			if success then
				frozen += 1
			end
		end

		return true, `Froze/unfroze {frozen} players.`
	end

	local matches = Helpers.resolvePartialName(args[1])

	if #matches == 0 then
		return false, "Couldn't find that player."
	elseif #matches > 1 then
		return false, "Multiple matches, be more specific."
	end

	return freeze(player, matches[1])
end

return Freeze