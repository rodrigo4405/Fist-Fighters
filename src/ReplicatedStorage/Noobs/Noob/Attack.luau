local HITBOX_CHECKS = 6
local DEBUG_BOXES = false

local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SoundManager = require(ReplicatedStorage.Modules.SoundManager)
local CONFIG = require(script.Parent.Configuration)
local Utils = require(script.Parent.Utils)

local ServerScriptService = game:GetService("ServerScriptService")
local KillHandler = require(ServerScriptService.KillHandler)

local Attack = {}

local function finish(noob)
	if noob and noob.Humanoid then
		noob.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, true)
	end
end

function Attack.CanEnter(noob, attackName)
	local config = CONFIG.Combat[attackName]
	if not config then return false end

	noob.Cooldowns = noob.Cooldowns or {}
	local cooldown = noob.Cooldowns[attackName]
	if cooldown and os.clock() < cooldown then return false end

	return true
end


function Attack.Enter(noob, attackName)
	local config = CONFIG.Combat[attackName]

	noob.Cooldowns = noob.Cooldowns or {}
	noob.Cooldowns[attackName] = os.clock() + (config.Cooldown or 0)
	noob.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, false)


	local side = Utils.GetAttackSide()
	local armPart = noob.Model:FindFirstChild(side)
	if not armPart then
		finish(noob, attackName)
		return false
	end
	
	local anim = (side == "Right Arm") and config.RightAnim or config.LeftAnim

	SoundManager.PlaySFX(SoundManager.SFX.Attacks.Swing, armPart, true)
	local track = noob:PlayAnimation(anim, Enum.AnimationPriority.Action2, 1, 1, false)

	if not track then 
		finish(noob)
		return false
	end
	
	local timer = 0
	local checks = 0
	local interval = track.Length / HITBOX_CHECKS
	
	local hitTargets = {}
	
	local overlapParams = OverlapParams.new()
	overlapParams.FilterType = Enum.RaycastFilterType.Exclude
	overlapParams.FilterDescendantsInstances = {noob.Model}
	
	local connection
	connection = RunService.Heartbeat:Connect(function(deltaTime)
		if noob.State == "Dead" or not armPart.Parent then
			connection:Disconnect()
			connection = nil
			return
		end

		timer += deltaTime
		
		if timer < interval then return end
		timer -= interval
		checks += 1
		
		local boxOffset = CFrame.new(0, -armPart.Size.Y / 2, 0) 
		local boxCFrame = armPart.CFrame * boxOffset
		local boxSize = armPart.Size + Vector3.new(.65, .8, .75)
		
		local parts = workspace:GetPartBoundsInBox(boxCFrame, boxSize, overlapParams)
		
		local requestedTargets = {}
		
		for _, part in parts do
			local targetModel = part:FindFirstAncestorWhichIsA("Model")
			if targetModel and not hitTargets[targetModel] then
				local targetHumanoid = targetModel:FindFirstChildWhichIsA("Humanoid")
				local targetPlayer = Players:GetPlayerFromCharacter(targetModel)

				if targetHumanoid and targetHumanoid.Health > 0 and targetPlayer then
					hitTargets[targetModel] = true

					local damage = config.Damage or 8

					local targetState = targetModel:GetAttribute("CombatState")
					if targetState == "Block" then
						damage = math.round(damage * 0.3)
					elseif targetState == "Parry" then
						damage = 0
					end

					if damage > 0 then
						SoundManager.PlaySFX(SoundManager.SFX.Attacks.Hit, noob.Model:FindFirstChild("HumanoidRootPart"), true)
						KillHandler.ProcessNoobDamage(noob, targetHumanoid, damage)
					end
				end
			end
		end

		
		if DEBUG_BOXES then
			task.spawn(function()
				local debugPart = Instance.new("Part")
				debugPart.Size = boxSize
				debugPart.CFrame = boxCFrame
				debugPart.Anchored = true
				debugPart.CanCollide = false
				debugPart.Transparency = 0.5
				debugPart.Color = Color3.new(1, 0, 0)
				debugPart.Parent = workspace

				task.delay(0.2, function()
					debugPart:Destroy()
				end)
			end)
		end

		if checks >= HITBOX_CHECKS then
			connection:Disconnect()
			connection = nil
			return
		end
	end)
	
	task.delay(track.Length, function()
		finish(noob)
	end)

	return true
end

function Attack.Loop(self)
	Utils.cancelThread(self, "AttackThread")

	self.AttackThread = task.spawn(function()
		while self:IsInState("Attacking") do
			local targetRoot = self.Target:FindFirstChild("HumanoidRootPart")
			local noobRoot = self.Model:FindFirstChild("HumanoidRootPart")
			if not targetRoot or not noobRoot then break end
			
			noobRoot.CFrame = CFrame.lookAt(noobRoot.Position, Vector3.new(targetRoot.Position.X, noobRoot.Position.Y, targetRoot.Position.Z))
			self.Humanoid:MoveTo(noobRoot.Position)

			if Attack.CanEnter(self, "Jab") then
				Attack.Enter(self, "Jab")
			end
			task.wait(CONFIG.AttackCooldown)
		end
		
		self.AttackThread = nil
	end)
end

return Attack
