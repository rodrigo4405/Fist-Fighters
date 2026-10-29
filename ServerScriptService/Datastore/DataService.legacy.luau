local DataManager = require(script.Parent:WaitForChild("DataManager"))

local playerStore = DataManager.playerDataStore
local killsLb = DataManager.killsLeaderboard
local donationsLb = DataManager.donationLeaderboard

local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Permissions = require(ServerScriptService:WaitForChild("Commands"):WaitForChild("Permissions"))

local saveKeybind = ReplicatedStorage:WaitForChild("RemoteEvents"):WaitForChild("SaveKeybind")
local saveSetting = ReplicatedStorage:WaitForChild("RemoteEvents"):WaitForChild("SaveSetting")

local function setPlayerTag(player: Player, data) 
	if not data then return end

	local tag = data.SelectedTag
	if tag == "" then return player:SetAttribute("Tag", nil) end
	player:SetAttribute("Tag", tag)
end

local function setKeybinds(player, data)
	if not data then return end
	
	local savedKeybinds = data.Settings and data.Settings.Keybinds
	if not savedKeybinds then return end
	
	local keybinds = {}
	
	for action, bind in pairs(savedKeybinds) do
		keybinds[action] = Enum.KeyCode[bind]
	end
	
	saveKeybind:FireClient(player, keybinds)
end

local function setSettings(player, data)
	if not data then return end
	
	local settings_ = data.Settings
	if not settings_ then return end
	
	saveSetting:FireClient(player, settings_)
end

saveKeybind.OnServerEvent:Connect(function(player: Player, changes: {[string]: Enum.KeyCode})
	if type(changes) ~= "table" then return end
	local newKeyBinds = {}
	
	for action, key in pairs(changes) do
		if type(action) ~= "string" then continue end
		if typeof(key) ~= "EnumItem" or key.EnumType ~= Enum.KeyCode then continue end
		newKeyBinds[action] = key.Name
	end
	
	playerStore:Set(player, {Settings = {Keybinds = newKeyBinds}})
end)

saveSetting.OnServerEvent:Connect(function(player: Player, setting: {[string]: any})
	local data = {Settings = table.clone(setting)}
	playerStore:Set(player, data)
end)

local function onPlayerAdded(player: Player)	
	local sig = playerStore:GetPlayerChangedSignal(player)
	sig:Connect(function()
		local data = playerStore:Get(player)
		setPlayerTag(player, data)
		setKeybinds(player, data)
		setSettings(player, data)
	end)
end

Players.PlayerAdded:Connect(onPlayerAdded)

for _, player in ipairs(Players:GetPlayers()) do
	task.spawn(function()
		onPlayerAdded(player)
	end)
end

playerStore:Initialize()
killsLb:Initialize()
donationsLb:Initialize()