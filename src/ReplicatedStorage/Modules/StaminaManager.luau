local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Signal = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Signal"))

local StaminaManager = {}

-- Configurations
StaminaManager.MAX_STAMINA = 100
StaminaManager.STAMINA_REGEN_RATE = 15
StaminaManager.STAMINA_REGEN_DELAY = 1
--

StaminaManager.StaminaChanged = Signal.new()

StaminaManager.activeDrains = {}
StaminaManager.currentStamina = StaminaManager.MAX_STAMINA
StaminaManager.lastDrainTime = 0

function StaminaManager.GetStamina()
	return StaminaManager.currentStamina
end

function StaminaManager.Deduct(amount: number): boolean
	if StaminaManager.currentStamina < amount then return false end
	
	StaminaManager.currentStamina -= math.min(StaminaManager.currentStamina, amount)
	StaminaManager.lastDrainTime = os.clock()
	
	StaminaManager.StaminaChanged:Fire(StaminaManager.currentStamina, StaminaManager.MAX_STAMINA)
	return true
end

function StaminaManager.StartDrain(actionName: string, drainRate: number)
	StaminaManager.activeDrains[actionName] = drainRate
	StaminaManager.lastDrainTime = os.clock()
end

function StaminaManager.StopDrain(actionName: string)
	StaminaManager.activeDrains[actionName] = nil
end

local function getTotalDrainRate()
	local totalRate = 0

	for _, rate in StaminaManager.activeDrains do
		totalRate = totalRate + rate
	end

	return totalRate
end

RunService.Heartbeat:Connect(function(deltaTime)
	local now = os.clock()
	local totalDrainRate = getTotalDrainRate()

	if totalDrainRate > 0 and StaminaManager.currentStamina > 0 then
		StaminaManager.currentStamina = math.max(0, StaminaManager.currentStamina - (totalDrainRate * deltaTime))
		StaminaManager.lastDrainTime = now
		
		StaminaManager.StaminaChanged:Fire(StaminaManager.currentStamina, StaminaManager.MAX_STAMINA)
	elseif StaminaManager.currentStamina < StaminaManager.MAX_STAMINA and now - StaminaManager.lastDrainTime >= StaminaManager.STAMINA_REGEN_DELAY then
		StaminaManager.currentStamina = math.max(0, StaminaManager.currentStamina + (StaminaManager.STAMINA_REGEN_RATE * deltaTime))
	
		StaminaManager.StaminaChanged:Fire(StaminaManager.currentStamina, StaminaManager.MAX_STAMINA)
	end
end)

return StaminaManager
