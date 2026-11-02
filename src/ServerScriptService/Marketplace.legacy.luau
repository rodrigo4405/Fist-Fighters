local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")

local ServerScriptService = game:GetService("ServerScriptService")
local DataManager = require(ServerScriptService.Datastore.DataManager)
local playerStore = DataManager.playerDataStore

local gamepasses = require(
	game:GetService("StarterGui"):WaitForChild("Shop"):WaitForChild("Container"):WaitForChild("Pages")
		:WaitForChild("Gamepasses"):WaitForChild("GamepassesScript"):WaitForChild("Gamepasses")
)
local donationLeaderboard = DataManager.donationLeaderboard

MarketplaceService.ProcessReceipt = function(receiptInfo)
	local uid = receiptInfo.UserId
	
	local success, donationStats = donationLeaderboard:GetPlayerStats(uid)
	if not success then return Enum.ProductPurchaseDecision.NotProcessedYet end
	
	local amount = receiptInfo.CurrencySpent
	
	local updateSuccess = donationLeaderboard:UpdateLeaderboard(uid, donationStats + amount)
	if not updateSuccess then return Enum.ProductPurchaseDecision.NotProcessedYet end
	
	return Enum.ProductPurchaseDecision.PurchaseGranted
end

MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, gamepassId, wasPurchased)
	if not wasPurchased then 
		return
	end	

	if gamepassId == gamepasses.VIP.gamepassId then
		local success = playerStore:Set(player, {SelectedTag = "VIP", Tags = {VIP = true}})
	end
end)