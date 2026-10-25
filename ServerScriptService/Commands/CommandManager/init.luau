local CommandManager = {}

local Players = game:GetService("Players")

local Permissions = require(script.Parent:WaitForChild("Permissions"))

local commandModules = script:GetDescendants()
local commands = {}
local aliases = {}

local initialised = false

local function loadCommands()
	for _, commandModule in ipairs(commandModules) do
		if not commandModule:IsA("ModuleScript") then continue end

		local success, module = pcall(require, commandModule)
		if not success then
			warn("Failed to load command:", commandModule.Name, module)
			continue
		end

		local name = (module.Name or commandModule.Name):lower()
		commands[name] = module

		for _, alias in ipairs(module.Aliases or {}) do
			if alias then
				aliases[alias:lower()] = name
			end
		end
	end

	initialised = true
end

local function getCommandHelp(commandName: string?)
	if not commandName then
		return true, "Use /help <command> to get command information."
	end

	commandName = aliases[commandName:lower()] or commandName:lower()

	local cmd = commands[commandName]
	if not cmd then
		return false, "Invalid command"
	end

	local help = `/{cmd.Name:lower()}`

	if cmd.Aliases and #cmd.Aliases > 0 then
		local formattedAliases = {}

		for _, alias in ipairs(cmd.Aliases) do
			table.insert(formattedAliases, "/" .. alias:lower())
		end

		help ..= " " .. table.concat(formattedAliases, " ")
	end

	help ..= ` | {cmd.Description or "No description"}`

	return true, help
end

local function getCommands(player: Player)
	local ignore = {"superman"}
	local level = Permissions.GetPermissionLevel(player) or -1
	local categories = {}

	for _, command in pairs(commands) do
		if table.find(ignore, command.Name:lower()) then continue end
		if level < (command.PermissionLevel or 0) then continue end

		local rank = command.PermissionLevel or 0
		categories[rank] = categories[rank] or {}

		local success, help = getCommandHelp(command.Name)
		if success then
			table.insert(categories[rank], help)
		end
	end

	local result = {"Commands"}

	local ranks = {}
	for rank in pairs(categories) do
		table.insert(ranks, rank)
	end
	table.sort(ranks)

	for _, rank in ipairs(ranks) do
		table.sort(categories[rank])

		local rankName = "Level " .. rank
		for name, value in pairs(Permissions.Ranks) do
			if value == rank then
				rankName = name
				break
			end
		end

		table.insert(result, "\n" .. rankName)
		for _, command in ipairs(categories[rank]) do
			table.insert(result, command)
		end
	end

	return true, table.concat(result, "\n")
end

function CommandManager.Run(player: Player, commandName: string, ...): (boolean, string)
	if not initialised then
		loadCommands()
	end

	commandName = commandName:lower()
	commandName = aliases[commandName] or commandName

	if commandName == "help" or commandName == "?" or commandName == "h" then
		return getCommandHelp(...)
	end

	if commandName == "cmds" or commandName == "commands" then
		return getCommands(player, ...)
	end

	local command = commands[commandName]

	if not command then
		return false, "Invalid command"
	end

	local level = Permissions.GetPermissionLevel(player) or -1

	if level < (command.PermissionLevel or 99) then
		return false, "You don't have permission to run this command"
	end

	local ok, success, result = pcall(command.Run, player, ...)

	if not ok then
		warn("Command error:", commandName, success)
		return false, "Something went wrong running that command."
	end

	return success, result
end

return CommandManager