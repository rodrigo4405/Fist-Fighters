local Players = game:GetService("Players")

local Permissions = require(script.Parent:WaitForChild("Permissions"))

local Helpers = {}

function Helpers.trim(s: string): string
	return (s:gsub("^%s*(.-)%s*$", "%1"))
end

function Helpers.resolvePartialName(partialName: string): {Player}
	if not partialName then return {} end
	partialName = Helpers.trim(partialName:lower())
	if partialName == "" then return {} end

	local plrs = Players:GetPlayers()
	local matches = {}

	for _, plr in ipairs(plrs) do
		if plr.Name:lower():sub(1,#partialName) == partialName then
			table.insert(matches, plr)
		end
	end

	return matches
end

function Helpers.parseDuration(duration: string): number?
	if duration == "perm" then
		return -1
	end

	local amount, unit = duration:match("^(%d+)(%a+)$")
	if not amount or not unit then return nil end

	local multipliers = {
		m = 60,
		h = 3600,
		d = 3600 * 24,
		w = 3600 * 24 * 7,
		mo = 3600 * 24 * 30,
		y = 3600 * 24 * 365,
	}

	return tonumber(amount) * multipliers[unit]
end

return Helpers