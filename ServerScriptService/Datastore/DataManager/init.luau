local Datastore = require(script:WaitForChild("Datastore"))
local Leaderboard = require(script:WaitForChild("Leaderboard"))
local CONFIG = require(script:WaitForChild("Configuration"))

local playerDataStore = Datastore.new("PlayerDataStore", true)

local killsLeaderboard = Leaderboard.new("KillsLeaderboardStore", "Kills", 10)
local donationLeaderboard = Leaderboard.new("DonationLeaderboardStore", "Donations", 15)

return {
    Datastore = Datastore,
    Leaderboard = Leaderboard,
    playerDataStore = playerDataStore,
	killsLeaderboard = killsLeaderboard,
	donationLeaderboard = donationLeaderboard
}

