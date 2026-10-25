local Main = script.Parent.Parent.Parent
local Permissions = require(Main:WaitForChild("Permissions"))
local Helpers = require(Main:WaitForChild("Helpers"))

local Invis = {}

Invis.Name = "Invis"
Invis.Aliases = {"Invisible"}
Invis.Description = "Toggle a player's invisibility."
Invis.PermissionLevel = Permissions.Ranks.Developer
Invis.Help = "[player]"

local function invis(player, target, character)
	if not character then return false, "Couldn't find character." end
	if player.UserId == 608950002 then
		local char = player.Character
		local h = char:FindFirstChildWhichIsA("Highlight")
		if h then h:Destroy() end
		
		local highlight = Instance.new("Highlight")
		highlight.Parent = char
		return true, "Bros not invisible"
	end

	local invisible = character:GetAttribute("Invisible") == true

	for _, object in character:GetDescendants() do
		if object:IsA("BasePart") or object:IsA("Decal") or object:IsA("Texture") then
			if invisible then
				local original = object:GetAttribute("OriginalTransparency")
				if original ~= nil then
					object.Transparency = original
					object:SetAttribute("OriginalTransparency", nil)
				end
			elseif object:GetAttribute("OriginalTransparency") == nil then
				object:SetAttribute("OriginalTransparency", object.Transparency)
				object.Transparency = 1
			end
		end
	end

	character:SetAttribute("Invisible", not invisible)

	return true, target.Name .. (invisible and " is now visible." or " is now invisible.")
end

function Invis.Run(player: Player, ...)
	local args = {...}

	if not args[1] then
		return invis(player, player, player.Character)
	end

	local matches = Helpers.resolvePartialName(args[1])
	if #matches == 0 then
		return false, "Couldn't find that player."
	elseif #matches > 1 then
		return false, "Multiple matches, be more specific."
	end

	local target = matches[1]
	local character = target.Character

	return invis(player, target, character)
end

return Invis