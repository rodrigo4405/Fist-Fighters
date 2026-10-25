local plr = game:GetService("Players").LocalPlayer
local plrGui = plr:WaitForChild("PlayerGui")
local playerTab = plrGui:WaitForChild("PlayerTab", 9e9):WaitForChild("UwuFrame")
local container = playerTab:WaitForChild("Container")
local playerTabFrame = container:WaitForChild("PlayerFrame")
local template = container:WaitForChild("Template")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local remotes = ReplicatedStorage:WaitForChild("RemoteEvents")
local updatePlayerTabEvent = remotes:WaitForChild("UpdatePlayerTab")


local function calculateKd(kills, deaths): string
	if deaths == 0 then
		return string.format("%.2f", kills)
	end

	return string.format("%.2f", kills / deaths)
end

local function updatePlayerTab(data)
	for _, child in ipairs(playerTabFrame:GetChildren()) do
		if child:IsA("Frame") and child.Name ~= "Template" then
			child:Destroy()
		end
	end
	
	for _, playerData in ipairs(data) do
		local newFrame = template:Clone()
		newFrame.Parent = playerTabFrame
		newFrame.Visible = true
		newFrame.Name = "Player"
		
		local playerLbl = newFrame:WaitForChild("Player")
		local totalKillsLbl = newFrame:WaitForChild("TotalKills")
		local sessionKillsLbl = newFrame:WaitForChild("SessionKills")
		local sessionDeathsLbl = newFrame:WaitForChild("SessionDeaths")
		local kdLbl = newFrame:WaitForChild("KD")
		local friend = newFrame:WaitForChild("Friend"):WaitForChild("Icon")
		
		playerLbl.Text = playerData.Player.Name
		totalKillsLbl.Text = tostring(playerData.Lifetime.Kills)
		sessionDeathsLbl.Text = tostring(playerData.Session.Deaths)
		sessionKillsLbl.Text = tostring(playerData.Session.Kills)
		kdLbl.Text = calculateKd(playerData.Session.Kills, playerData.Session.Deaths)
		friend.ImageTransparency = (playerData.Player):GetAttribute("IsFriend") and 0 or 1
	end
end

updatePlayerTabEvent.OnClientEvent:Connect(updatePlayerTab)