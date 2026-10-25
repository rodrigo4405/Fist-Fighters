local Players = game:GetService("Players")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local refreshLbEvent = ReplicatedStorage:WaitForChild("RemoteEvents"):WaitForChild("RefreshLeaderboard")
local requestLbEvent = ReplicatedStorage:WaitForChild("RemoteFunctions"):WaitForChild("RequestLeaderboard")

local CONFIG = require(script:WaitForChild("Configuration"))

local map = workspace:WaitForChild("Map")
local killsLb = map:WaitForChild("Leaderboard")
local donationsLb = map:WaitForChild("DonationLeaderboard")

local nameCache = {}

local function getName(uid: number)
	if nameCache[uid] then
		return nameCache[uid]
	end
	
	local success, name = pcall(function()
		return Players:GetNameFromUserIdAsync(uid)
	end)
	
	if not success then return tostring(uid) end
	
	nameCache[uid] = name
	return name
end

local function populateLeaderboard(lbName, data)
	local topFrame
	local template 
	if lbName == "Kills" then
		topFrame = killsLb:WaitForChild("LeaderboardSurface", 9e9):WaitForChild("LeaderboardGui"):WaitForChild("Frame"):WaitForChild("TopFrame")
	elseif lbName == "Donations" then
		topFrame = donationsLb:WaitForChild("LeaderboardSurface", 9e9):WaitForChild("LeaderboardGui"):WaitForChild("Frame"):WaitForChild("TopFrame")
	else return end
	if not topFrame then return end
	
	local template = topFrame.Parent:WaitForChild("Template")
	
	for _, child in ipairs(topFrame:GetChildren()) do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end
	
	if not data or #data == 0 then
		return
	end
	
	for i, v in ipairs(data) do
		local entry = template:Clone()
		entry.Parent = topFrame
		entry.Visible = true

		local placeLbl = entry:WaitForChild("Place")
		local nameLbl = entry:WaitForChild("Player")
		local valueLbl = entry:WaitForChild("Value")

		placeLbl.Text = tostring(i)
		nameLbl.Text = getName(v.key)
		valueLbl.Text = tostring(v.value or 0)

		if i >= 1 and i <= 3 then
			placeLbl.TextColor3 = CONFIG.PLACE_COLORS[i]
			nameLbl.TextColor3 = CONFIG.PLACE_COLORS[i]
			valueLbl.TextColor3 = CONFIG.PLACE_COLORS[i]
		end
	end
end

refreshLbEvent.OnClientEvent:Connect(populateLeaderboard)

populateLeaderboard("Kills", requestLbEvent:InvokeServer("Kills"))
task.wait(0.5)
populateLeaderboard("Donations", requestLbEvent:InvokeServer("Donations"))