local RunService = game:GetService("RunService")
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Utils = require(script.Parent:WaitForChild("Utils"))
local Signal = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Signal"))
local CONFIG = require(script.Parent:WaitForChild("Configuration"))

local refreshLb = ReplicatedStorage:WaitForChild("RemoteEvents"):WaitForChild("RefreshLeaderboard")
local requestLb = ReplicatedStorage:WaitForChild("RemoteFunctions"):WaitForChild("RequestLeaderboard")
local leaderboards = {}

requestLb.OnServerInvoke = function(player: Player, shortName: string)
	local leaderboard = leaderboards[shortName]
	if not leaderboard then return nil end

	return leaderboard:GetLeaderboard(leaderboard.Length)
end

local Leaderboard = {}
Leaderboard.__index = Leaderboard

function Leaderboard.new(storeName, shortName: string, length: number?, refreshInterval: number?)
	local self = setmetatable({}, Leaderboard)

	self.StoreName = storeName
	self.ShortName = shortName
	self.LeaderboardStore = DataStoreService:GetOrderedDataStore(storeName)

	self.Length = length or 10
	self.RefreshInterval = refreshInterval or 60

	self.LeaderboardCache = nil
	self.LeaderboardCacheExpiry = 0

	self.RefreshThread = nil
	self.Initialized = false

	return self
end

local function refreshLeaderboard(self)
	self.LeaderboardCacheExpiry = 0
	local data = self:GetLeaderboard(self.Length)
	if not data then return end

	refreshLb:FireAllClients(self.ShortName, data)
end

function Leaderboard:Initialize()
	if self.Initialized then return end

	self.Initialized = true
	
	leaderboards[self.ShortName] = self

	if self.RefreshInterval <= 0 then return end

	self.RefreshThread = task.spawn(function()
		while task.wait(self.RefreshInterval) do
			refreshLeaderboard(self)
		end
	end)
end

function Leaderboard:UpdateLeaderboard(player, value: number): boolean
	if RunService:IsStudio() and not CONFIG.KEEP_SAVES_STUDIO then return true end
	if not tonumber(value) then return false end

	local userId = (tonumber(player) or tostring(player.UserId))
	value = math.floor(tonumber(value))
	local success, err = pcall(function()
		self.LeaderboardStore:SetAsync(userId, value)
	end)

	if not success then
		warn("Leaderboard update failed! " .. err)
		return false
	end

	self.LeaderboardCacheExpiry = 0

	if self.RefreshInterval <= 0 then
		refreshLeaderboard(self)
	end

	return true
end

function Leaderboard:GetPlayerStats(userId: number): (boolean, number)
	local success, result = pcall(function()
		return self.LeaderboardStore:GetAsync(tostring(userId))
	end)

	return success, result or 0
end

function Leaderboard:GetLeaderboard(length: number)	
	if self.LeaderboardCache ~= nil and os.clock() < self.LeaderboardCacheExpiry then
		return Utils.deepcopy(self.LeaderboardCache)
	end

	local success, pages = pcall(function()
		return self.LeaderboardStore:GetSortedAsync(false, length)
	end)

	if not success then return nil end

	local result = pages:GetCurrentPage()
	self.LeaderboardCache = Utils.deepcopy(result)
	self.LeaderboardCacheExpiry = os.clock() + CONFIG.LEADERBOARD_CACHE_DURATION

	return result
end

function Leaderboard:Reset()
	if RunService:IsStudio() and not CONFIG.KEEP_SAVES_STUDIO then return true end

	local success, pages = pcall(function()
		return self.LeaderboardStore:GetSortedAsync(false, 100)
	end)

	if not success then return false end

	while true do
		local page = pages:GetCurrentPage()
		for _, entry in ipairs(page) do
			local userId = entry.key
			local removeSuccess, err = pcall(function()
				return self.LeaderboardStore:RemoveAsync(userId)
			end)
		end
		if pages.IsFinished then
			break
		end
		pages:AdvanceToNextPageAsync()
	end
	self.LeaderboardCache = nil
	self.LeaderboardCacheExpiry = 0
	return true
end

return Leaderboard