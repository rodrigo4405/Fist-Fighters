local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local AnimationManager = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("AnimationManager"))
local StaminaManager = require(ReplicatedStorage.Modules.StaminaManager)

local Movement = require(ReplicatedStorage.Modules.Movement)
local Combat = require(ReplicatedStorage.Modules.Combat)
local Keybinds = require(ReplicatedStorage.Modules.Keybinds)

local Falling = require(ReplicatedStorage.Modules.Movement.Falling)
local Dash = require(ReplicatedStorage.Modules.Movement.Dash)

local CombatEvent = ReplicatedStorage.RemoteEvents.CombatEvent

local player = game:GetService("Players").LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local rootPart = character:WaitForChild("HumanoidRootPart")

humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
humanoid:SetStateEnabled(Enum.HumanoidStateType.GettingUp, false)
humanoid:SetStateEnabled(Enum.HumanoidStateType.Climbing, false)

local animateScript = character:FindFirstChild("Animate") or character:WaitForChild("Animate", 5)
if animateScript then
	animateScript:Destroy()
end

task.spawn(function()
	for _, animation in ipairs(ReplicatedStorage.Animations:GetDescendants()) do
		if animation:IsA("Animation") then
			task.spawn(AnimationManager.WarmUp, animation)
		end
	end
end)

local ctx = {
	humanoid = humanoid,
	rootPart = rootPart,
	character = character,
}

local isShiftPressed = false

local function evaluate()
	if Movement.IsBusy() then return end

	if not humanoid or humanoid.Health <= 0 then return end

	local isMoving = humanoid.MoveDirection.Magnitude > 0 and humanoid.WalkSpeed > 0
	local canSprint = isShiftPressed and isMoving and StaminaManager.currentStamina > 0
	
	local humanoidState = humanoid:GetState()
	
	if humanoidState == Enum.HumanoidStateType.Freefall then
		if Falling.ShouldEnter(ctx) then
			Movement.SetState(ctx, "Falling")
		end
		
	elseif humanoidState == Enum.HumanoidStateType.Jumping then
		Movement.SetState(ctx, "Jumping")
		
	elseif canSprint and not Combat.IsBusy() then
		Movement.SetState(ctx, "Sprinting")	
		
	elseif isMoving then
		Movement.SetState(ctx, "Walking")
		
	else
		Movement.SetState(ctx, "Idle")
	end
end

UserInputService.InputBegan:Connect(function(input, gpe)
	if gpe then return end
	
	if input.KeyCode == Keybinds.Get("Sprint") then
		isShiftPressed = true
		evaluate()

	elseif input.KeyCode == Keybinds.Get("Dash") then
		if not Combat.IsBusy() and Dash.CanEnter() then
			Movement.SetState(ctx, "Dash")
		end
	end
end)

UserInputService.InputEnded:Connect(function(input, gpe)
	if gpe then return end

	if input.KeyCode == Keybinds.Get("Sprint") then
		isShiftPressed = false
		evaluate()
	end
end)

local combatInputConnections = {}

character.ChildAdded:Connect(function(child)
	if child:IsA("Tool") and child.Name == "Combat" then
		Combat.SetActive(ctx)
		
		table.insert(combatInputConnections, UserInputService.InputBegan:Connect(function(input, gpe)
			if gpe then return end
			if Movement.IsBusy() then return end
			
			local humanoidState = humanoid:GetState()
			if humanoidState == Enum.HumanoidStateType.Jumping or humanoidState == Enum.HumanoidStateType.Freefall then return end

			if humanoid.Health <= 0 then return end

			if input.UserInputType == Enum.UserInputType.MouseButton1 then
				Combat.Attack(ctx, "Jab")
			elseif input.KeyCode == Keybinds.Get("Hook") then
				Combat.Attack(ctx, "Hook")
			elseif input.KeyCode == Keybinds.Get("Uppercut") then
				Combat.Attack(ctx, "Uppercut")
			elseif input.KeyCode == Keybinds.Get("BodyShot") then
				Combat.Attack(ctx, "Bodyshot")
			elseif input.KeyCode == Keybinds.Get("Overhand") then
				Combat.Attack(ctx, "Overhand")
			elseif input.KeyCode == Keybinds.Get("Block") then
				Combat.EnterBlock(ctx)
			end
		end))
		
		table.insert(combatInputConnections, UserInputService.InputEnded:Connect(function(input, gpe)
			if gpe then return end
			
			if input.KeyCode == Keybinds.Get("Block") then
				task.defer(function()
					Combat.ExitBlock(ctx)
				end)
			end
		end))
			
	end
end)

character.ChildRemoved:Connect(function(child)
	if child:IsA("Tool") and child.Name == "Combat" then
		Combat.ExitBlock(ctx)
		Combat.ResetState(ctx)
		
		for _, conn in combatInputConnections do
			conn:Disconnect()
		end
		
		table.clear(combatInputConnections)
	end
end)

humanoid:GetPropertyChangedSignal("MoveDirection"):Connect(evaluate)

humanoid.StateChanged:Connect(evaluate)

Movement.StateChanged:Connect(evaluate)

Combat.StateChanged:Connect(evaluate)


StaminaManager.StaminaChanged:Connect(function(current)
	if current == 0 then
		isShiftPressed = false
		evaluate()
		Combat.ExitBlock(ctx)
	end
end)

RunService.Heartbeat:Connect(function()
	if humanoid:GetState() == Enum.HumanoidStateType.Freefall then
		evaluate()
	end
end)

ctx.humanoid.Died:Connect(function()
	Combat.ExitBlock(ctx)
	
	Movement.ResetState(ctx)
	Combat.ResetState(ctx)
end)

CombatEvent.OnClientEvent:Connect(function(state, switch)
	if switch then
		Movement.SetState(ctx, state)
	else
		Movement.ResetState(ctx)
	end
end)