local ReplicatedStorage = game:GetService("ReplicatedStorage")

local AnimationManager = require(ReplicatedStorage.Modules.AnimationManager)
local StaminaManager = require(ReplicatedStorage.Modules.StaminaManager)
local Configuration = require(script.Parent.Configuration)
local Utils = require(script.Parent.Utils)

local BlockStrengthEvent = ReplicatedStorage.RemoteEvents.BlockStrengthEvent

local blockBar = game:GetService("Players").LocalPlayer.PlayerGui.Bars.Placeholder.Block.Bar

local Block = {}

local config = Configuration.Block

local blockStrength = config.MaxBlockStrength
local lastBlockStrengthDrain = 0

local cooldown = false
local onComplete = nil

function Block.Init(completeCallback)
	onComplete = completeCallback
end

local function finish(ctx)
	ctx.humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, true)
	if onComplete then onComplete(ctx) end

	task.delay(config.Cooldown, function()
		cooldown = false
	end)
end

function Block.CanEnter()
	if cooldown then return false end
	if blockStrength == 0 then return end

	return true
end

function Block.Enter(ctx)
	cooldown = true
	ctx.humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, false)

	StaminaManager.StartDrain("Block", config.StaminaCost)
	AnimationManager.PlayAnimation(config.Anim, Enum.AnimationPriority.Action2, 1, 1, true)
end

function Block.Exit(ctx)
	AnimationManager.StopAnimation(config.Anim)
	StaminaManager.StopDrain("Block")
	finish(ctx)
end

BlockStrengthEvent.OnClientEvent:Connect(function(ctx, damage)
	lastBlockStrengthDrain = os.clock()

	blockStrength = math.max(0, blockStrength - damage)
	blockBar.Size = UDim2.new(blockStrength / config.MaxBlockStrength, 0, 1, 0)
	
	if blockStrength == 0 then Block.Exit(ctx) end
end)

local regenTask = nil
if regenTask then
	task.cancel(regenTask)
	regenTask = nil
end

regenTask = task.spawn(function()
	while task.wait(1) do
		if os.clock() - lastBlockStrengthDrain < config.BlockStrengthRegenDelay then continue end

		if blockStrength < config.MaxBlockStrength then
			blockStrength = math.min(config.MaxBlockStrength, blockStrength + config.BlockStrengthRegenRate)
			blockBar.Size = UDim2.new(blockStrength / config.MaxBlockStrength, 0, 1, 0)
		end
	end
end)
	

return Block