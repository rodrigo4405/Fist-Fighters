local Players = game:GetService("Players")
local player = Players.LocalPlayer

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local FeedEvent = ReplicatedStorage:WaitForChild("RemoteEvents"):WaitForChild("FeedEvent")

local playerGui = player.PlayerGui
local feed = playerGui:WaitForChild("Feed", 9e9)
local container = feed:WaitForChild("Container")
local history = container:WaitForChild("History")
local template = history:WaitForChild("Template")

local MAX_LINES = 5
local DISPLAY_TIME = 10
local lineCount = 0
local layoutOrder = 0
local queue = {}

local function addLine(richText, highlight)
	if lineCount >= MAX_LINES then
		table.insert(queue, {richText, highlight})
		return
	end
	local line = template:Clone()
	line.Message.RichText = true
	line.Message.Text = richText
	line.LayoutOrder = layoutOrder
	line.Visible = true
	line.Parent = history
	lineCount += 1
	layoutOrder += 1
	task.delay(DISPLAY_TIME, function()
		if line.Parent then
			line:Destroy()
			lineCount -= 1
			local nextLine = table.remove(queue, 1)
			if nextLine then addLine(nextLine[1], nextLine[2]) end
		end
	end)
end

local function formatPlayerJoin(plr)
	if not plr then return end
	return `<font color="#55AAFF"><b>{plr.Name}</b></font> <font color="#FFFFFF">joined the game!</font>`
end

local function formatPlayerLeave(plr)
	if not plr then return end
	return `<font color="#FF5555"><b>{plr.Name}</b></font> <font color="#FFFFFF">left the game!</font>`
end

local function formatKillFeed(killer, victim, damage)
	local killerName = killer and killer.Name
	local victimName = victim and victim.Name
	if not killerName or not victimName then return end
	return `<font color="#55AAFF"><b>{killerName}</b></font> 👊 <font color="#FF5555"><b>{victimName}</b></font> <font color="#FFD700"><b>[{damage} DMG]</b></font>`
end

local function formatKillstreak(killer, streak)
	local killerName = killer and killer.Name or "Unknown"
	return `<font color="#55AAFF"><b>{killerName}</b></font> is on a <font color="#FFD700"><b>{streak} killstreak</b></font>`
end

FeedEvent.OnClientEvent:Connect(function(killer, victim, damage, streak)
	print(killer)
	if not killer or not victim then return end
	damage = damage or 100
	local highlight = killer == player
	addLine(formatKillFeed(killer, victim, damage), highlight)
	if streak and streak ~= 0 and math.fmod(streak, 5) == 0 then
		addLine(formatKillstreak(killer, streak), highlight)
	end
end)

Players.PlayerAdded:Connect(function(p) addLine(formatPlayerJoin(p)) end)
Players.PlayerRemoving:Connect(function(p) addLine(formatPlayerLeave(p)) end)

local playerTab = playerGui:WaitForChild("PlayerTab", 9e9)
local frame = playerTab:FindFirstChildOfClass("Frame")
local tab = frame:WaitForChild("Tab")
tab:GetPropertyChangedSignal("Visible"):Connect(function() container.Visible = tab.Visible end)
