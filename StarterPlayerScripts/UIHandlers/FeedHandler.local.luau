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
	local label = line.Message
	label.RichText = true
	label.Text = richText

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
			if nextLine then
				addLine(nextLine[1], nextLine[2])
			end
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
	return `<font color="#55AAFF"><b>{killer.Name}</b></font> 👊 <font color="#FF5555"><b>{victim.Name}</b></font> <font color="#FFD700"><b>[{damage} DMG]</b></font>`
end

local function formatKillstreak(killer, streak)
	return `<font color="#55AAFF"><b>{killer.Name}</b></font> is on a <font color="#FFD700"><b>{streak} killstreak</b></font>`
end

FeedEvent.OnClientEvent:Connect(function(killer: Player, victim: Player, damage: number, streak: number?)
	if not killer or not victim then return end

	damage = damage or 100
	addLine(formatKillFeed(killer, victim, damage), killer == player)

	if streak and streak ~= 0 and math.fmod(streak, 5) == 0 then
		addLine(formatKillstreak(killer, streak), killer == player)
	end
end)

Players.PlayerAdded:Connect(function(player)
	addLine(formatPlayerJoin(player))
end)

Players.PlayerRemoving:Connect(function(player)
	addLine(formatPlayerLeave(player))
end)

local playerTab = playerGui:WaitForChild("PlayerTab", 9e9)
local frame = playerTab:FindFirstChildOfClass("Frame")
local tab = frame:WaitForChild("Tab")
tab:GetPropertyChangedSignal("Visible"):Connect(function()
	container.Visible = tab.Visible
end)