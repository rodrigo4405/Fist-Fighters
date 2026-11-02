local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Utils = require(script.Parent:WaitForChild("Utils"))
local Signal = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Signal"))
local CONFIG = require(script.Parent:WaitForChild("Configuration"))

local remotes = ReplicatedStorage:WaitForChild("RemoteEvents")
local updatePlayerTabEvent = remotes:WaitForChild("UpdatePlayerTab")

local Datastore = {}
Datastore.__index = Datastore

function Datastore.new(storeName, autosaveEnabled, defaultData, defaultSessionData, broadcastThrottle)
	if autosaveEnabled == nil then autosaveEnabled = true end
	if broadcastThrottle == nil then broadcastThrottle = 0.2 end

	local self = setmetatable({}, Datastore)

	self.StoreName = storeName

	if defaultData then
		self.DefaultData = Utils.deepcopy(defaultData)
	else
		self.DefaultData = Utils.getDefaultData()
	end
	if defaultSessionData then
		self.DefaultSessionData = Utils.deepcopy(defaultSessionData)
	else
		self.DefaultSessionData = Utils.getDefaultSessionData()
	end

	self.DataCache = {}
	self.SessionCache = {}
	self.DataStores = {}
	self.Connections = {}
	self.AutosaveThread = nil
	self.Initialized = false
	self.PendingSaves = 0
	self.Saving = {}

	--self.PlayerDataLoadedSignal = Signal.new()
	self.PlayerChangedSignals = {}
	self.PlayerDataChanged = {}

	self.BroadcastThrottle = broadcastThrottle
	self.lastBroadcastTime = -math.huge
	self.broadcastPending = false

	self.autosaveEnabled = autosaveEnabled

	return self
end

local function getDataStore(self, name)
	if not self.DataStores[name] then
		self.DataStores[name] = DataStoreService:GetDataStore(name)
		self.DataCache[name] = {}
		self.SessionCache[name] = {}
	end
	return self.DataStores[name]
end

local function saveData(self, userId, data, name)
	local start = os.clock()
	if RunService:IsStudio() and not CONFIG.KEEP_SAVES_STUDIO then return true end
	if userId <= 0 then return true end

	name = name or self.StoreName
	local store = getDataStore(self, name)

	self.PendingSaves += 1
	while self.Saving[userId] do task.wait() end
	
	if self.PlayerDataChanged[userId] == false then
		self.PendingSaves -= 1
		return true
	end 
	
	self.PlayerDataChanged[userId] = false
	self.Saving[userId] = true
	local backup = Utils.deepcopy(data)

	local success, result = Utils.retry(function()
		return store:UpdateAsync(tostring(userId), function() return backup end)
	end, "Data Saving")

	self.PendingSaves -= 1
	self.Saving[userId] = nil
	
	if not success then self.PlayerDataChanged[userId] = true end
	if success then print(("Saved data in %.2fs"):format(os.clock() - start)) end
	return success
end

local function loadData(self, name, userId)
	local store = getDataStore(self, name)

	while self.Saving[userId] do task.wait() end

	local success, data = Utils.retry(function()
		return store:GetAsync(tostring(userId))
	end, "Data Loading")

	if not success then return false, nil end
	if data == nil then
		return true, Utils.deepcopy(self.DefaultData)
	end
	return true, Utils.reconcileData(data, self.DefaultData)
end

local function onPlayerAdded(self, player, name)
	if not self.DataCache[name] then self.DataCache[name] = {} end
	if not self.SessionCache[name] then self.SessionCache[name] = {} end

	local success, data = loadData(self, name, player.UserId)

	if player.Parent ~= Players then return end
	if not success then
		player:Kick("Data failed to load. Please rejoin.")
		return
	end

	self.DataCache[name][player.UserId] = data
	if self.SessionCache[name][player.UserId] == nil then
		self.SessionCache[name][player.UserId] = Utils.deepcopy(self.DefaultSessionData)
	end

	local sig = self.PlayerChangedSignals[player.UserId]
	if sig then
		sig:Fire(player, data)
	end
end

local function onPlayerRemoving(self, player, name)
	local uid = player.UserId
	local cache = self.DataCache[name]
	local data = cache and cache[uid]
	if cache then cache[uid] = nil end

	local sig = self.PlayerChangedSignals[uid]
	if sig then
		self.PlayerChangedSignals[uid] = nil
		if sig.Destroy then sig:Destroy() end
	end

	if self.SessionCache[name] then self.SessionCache[name][uid] = nil end
	if data then saveData(self, uid, data, name) end
end

local function onGameShutdown(self)
	for name, cache in pairs(self.DataCache) do
		for uid, data in pairs(cache) do
			task.spawn(function() saveData(self, uid, data, name) end)
		end
	end
	local deadline = os.clock() + 22
	while self.PendingSaves > 0 and os.clock() < deadline do
		task.wait(0.1)
	end
end

local function autosave(self)
	while task.wait(CONFIG.AUTOSAVE_INTERVAL) do
		for name, cache in pairs(self.DataCache) do
			for uid, data in pairs(cache) do
				task.spawn(function() saveData(self, uid, data, name) end)
				task.wait(0.2)
			end
		end
	end
end

local function collectPlayerData(self)
	local result = {}
	local storeName = self.StoreName
	for _, player in ipairs(Players:GetPlayers()) do
		local data = self.DataCache[storeName] and self.DataCache[storeName][player.UserId] or self.DefaultData
		local sessionData = self.SessionCache[storeName] and self.SessionCache[storeName][player.UserId] or self.DefaultSessionData
		table.insert(result, {
			Player = player,
			Lifetime = { Kills = data.Kills or 0 },
			Session = { Kills = sessionData.Kills or 0, Deaths = sessionData.Deaths or 0 },
		})
	end
	return result
end

local function broadcastPlayerData(self)
	local elapsed = os.clock() - self.lastBroadcastTime

	if elapsed < self.BroadcastThrottle then
		if self.broadcastPending then return end
		self.broadcastPending = true

		task.delay(self.BroadcastThrottle - elapsed, function()
			self.broadcastPending = false
			self.lastBroadcastTime = os.clock()
			updatePlayerTabEvent:FireAllClients(collectPlayerData(self))
		end)
		return
	end

	self.lastBroadcastTime = os.clock()
	updatePlayerTabEvent:FireAllClients(collectPlayerData(self))
end

function Datastore:Initialize()
	if self.Initialized then return end
	self.Initialized = true

	getDataStore(self, self.StoreName)

	self.Connections.PlayerAdded = Players.PlayerAdded:Connect(function(player)
		onPlayerAdded(self, player, self.StoreName)
		broadcastPlayerData(self)
	end)

	self.Connections.PlayerRemoving = Players.PlayerRemoving:Connect(function(player)
		onPlayerRemoving(self, player, self.StoreName)
		task.defer(function() broadcastPlayerData(self) end)
	end)

	local initialPlayers = Players:GetPlayers()
	for _, player in ipairs(initialPlayers) do
		onPlayerAdded(self, player, self.StoreName)
	end
	if #initialPlayers > 0 then
		broadcastPlayerData(self)
	end

	if not self.AutosaveThread and self.autosaveEnabled then
		self.AutosaveThread = task.spawn(function() autosave(self) end)
		game:BindToClose(function() onGameShutdown(self) end)
	end
end

function Datastore:GetDefaultData()
	return Utils.deepcopy(self.DefaultData)
end

function Datastore:Get(player: Player, deep: boolean?)
	local data = self.DataCache[self.StoreName] and self.DataCache[self.StoreName][player.UserId]
	return data and Utils.deepcopy(data) or nil
end

function Datastore:Set(player, data)
	if not player or player.Parent ~= Players then return end
	if not self.Initialized then return false end
	if not self.DataCache[self.StoreName] then return false end

	local cachedData = self.DataCache[self.StoreName][player.UserId]
	if not cachedData then return false end

	self.DataCache[self.StoreName][player.UserId] = Utils.reconcileData(data, cachedData)

	local uid = player.UserId
	local sig = self.PlayerChangedSignals[uid]
	if sig then
		sig:Fire(player, data)
	end
	
	self.PlayerDataChanged[player.UserId] = true
	return true
end

function Datastore:Increment(player, field, amount)
	if not player or player.Parent ~= Players then return end
	if not self.Initialized then return false end
	if not self.DataCache[self.StoreName] then return false end

	local data = self.DataCache[self.StoreName][player.UserId]
	if not data then return false end

	if type(amount) ~= "number" or amount ~= amount or math.abs(amount) == math.huge then return false end
	if type(data[field]) ~= "number" then return false end

	data[field] += amount

	local uid = player.UserId
	local sig = self.PlayerChangedSignals[uid]
	if sig then
		sig:Fire(player, self.DataCache[self.StoreName][uid])
	end
	self.PlayerDataChanged[player.UserId] = true
	return true
end

function Datastore:GetSessionData(player)
	local sessionData = self.SessionCache[self.StoreName] and self.SessionCache[self.StoreName][player.UserId]
	return Utils.deepcopy(sessionData or self.DefaultSessionData)
end

function Datastore:IncrementSession(player, field, amount)
	if not self.Initialized then return false end

	local sessionData = self.SessionCache[self.StoreName] and self.SessionCache[self.StoreName][player.UserId]
	if not sessionData then return false end

	if type(sessionData[field]) ~= "number" then return false end
	if amount < 0 then return false end

	if self.DefaultData[field] ~= nil then
		if not self:Increment(player, field, amount) then return false end
	end
	sessionData[field] += amount

	broadcastPlayerData(self)
	return true
end

function Datastore:GetPlayerChangedSignal(player)
	local uid = player.UserId
	local sig = self.PlayerChangedSignals[uid]
	if not sig then
		sig = Signal.new()
		self.PlayerChangedSignals[uid] = sig
	end
	return sig
end

function Datastore:GetMultiple(players: {Players})
	local result = {}
	for _, player in ipairs(players) do
		result[player] = self:Get(player)
	end
	return result
end

function Datastore:SetMultiple(players: {Players}, data)
	local successCount = 0
	for _, player in ipairs(players) do
		if self:Set(player, data) then
			successCount += 1
		end
	end
	return successCount
end

function Datastore:UpdateOffline(uid: number, data)
	if Players:GetPlayerByUserId(uid) then return false end
	if not self.Initialized then return false end
	if not self.DataCache[self.StoreName] then return false end
	
	local success, savedData = loadData(self, self.StoreName, uid)
	if not savedData or not success then return false end

	local reconciled = Utils.reconcileData(data, savedData)
	return saveData(self, uid, reconciled, self.StoreName)
end

return Datastore