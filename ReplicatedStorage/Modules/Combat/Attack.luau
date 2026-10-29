local HITBOX_CHECKS = 6
local DEBUG_BOXES = false

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local AnimationManager = require(ReplicatedStorage.Modules.AnimationManager)
local StaminaManager = require(ReplicatedStorage.Modules.StaminaManager)
local SoundManager = require(ReplicatedStorage.Modules.SoundManager)
local Configuration = require(script.Parent.Configuration)
local Utils = require(script.Parent.Utils)

local RE = ReplicatedStorage:WaitForChild("RemoteEvents"):WaitForChild("CombatEvent")

local Attack = {}

local cooldowns = {}
local onComplete = nil

function Attack.Init(completeCallback)
	onComplete = completeCallback
end

local function finish(ctx, attackName)	
	ctx.humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, true)
	if onComplete then onComplete(ctx) end
end

function Attack.CanEnter(attackName)
	local config = Configuration[attackName]
	if not config then return false end
	
	local onCooldownUntil = cooldowns[attackName]
	if onCooldownUntil and os.clock() < onCooldownUntil then return false end
	
	if StaminaManager.currentStamina < config.StaminaCost then return false end
	
	return true
end

function Attack.Enter(ctx, attackName)
	local config = Configuration[attackName]

	cooldowns[attackName] = os.clock() + config.Cooldown
	ctx.humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, false)

	if not StaminaManager.Deduct(config.StaminaCost) then
		finish(ctx, attackName, config.Cooldown)
		return false
	end

	local side = Utils.GetAttackSide()
	local armPart = ctx.character:FindFirstChild(side)
	assert(armPart)
	
	local anim = (side == "Right Arm") and config.RightAnim or config.LeftAnim

	SoundManager.PlaySFX(SoundManager.SFX.Attacks.Swing, armPart)
	local track = AnimationManager.PlayAnimation(anim, Enum.AnimationPriority.Action2, 1, 1, false)

	if not track then 
		finish(ctx, attackName)
		return true
	end
	
	local timer = 0
	local checks = 0
	local interval = track.Length / HITBOX_CHECKS
	
	local hitTargets = {}
	
	local connection
	connection = RunService.Heartbeat:Connect(function(deltaTime)
		timer += deltaTime
		
		if timer < interval then return end
		timer -= interval
		checks += 1
		
		local boxOffset = CFrame.new(0, -armPart.Size.Y / 2, 0) 
		local boxCFrame = armPart.CFrame * boxOffset
		local boxSize = armPart.Size + Vector3.new(.65, .8, .75)
		
		local overlapParams = OverlapParams.new()
		overlapParams.FilterType = Enum.RaycastFilterType.Exclude
		overlapParams.FilterDescendantsInstances = {ctx.character}
		
		local parts = workspace:GetPartBoundsInBox(boxCFrame, boxSize, overlapParams)
		
		local requestedTargets = {}
		
		for _, part in parts do
			local targetModel = part:FindFirstAncestorWhichIsA("Model")
			if targetModel and not hitTargets[targetModel] then 
				hitTargets[targetModel] = true
				table.insert(requestedTargets, targetModel)
			end
		end
		
		if #requestedTargets > 0 then
			RE:FireServer(requestedTargets, config.Damage, side)
			SoundManager.PlaySFX(SoundManager.SFX.Attacks.Hit, ctx.rootPart)
		end
		
		if DEBUG_BOXES then
			task.spawn(function()
				local debugPart = ReplicatedStorage:WaitForChild("HitboxDebugPart"):Clone()
				debugPart.Size = boxSize
				debugPart.CFrame = boxCFrame
				debugPart.Parent = workspace

				task.delay(0.2, function()
					debugPart:Destroy()
				end)
			end)
		end

		if checks == HITBOX_CHECKS then
			connection:Disconnect()
			connection = nil
			return
		end
	end)
	
	task.delay(track.Length, function()
		finish(ctx, attackName)
	end)

	return true
end

return Attack