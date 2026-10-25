local ReplicatedStorage = game:GetService("ReplicatedStorage")
local AnimationManager = require(ReplicatedStorage:WaitForChild('Modules'):WaitForChild("AnimationManager"))
local Signal = require(ReplicatedStorage.Modules.Signal)

local activeAnim = ReplicatedStorage:WaitForChild("Animations"):WaitForChild("Combat"):WaitForChild("Idle")
local ApplyAttributeRE = ReplicatedStorage:WaitForChild("RemoteEvents"):WaitForChild("ApplyAttribute")

local blockBarFrame = game:GetService("Players").LocalPlayer.PlayerGui.Bars.Placeholder.Block

local Combat = {}
Combat.StateChanged = Signal.new()

local current = nil

function Combat.SetActive(ctx)
	if current == "Active" then return end
	
	if not ctx.character:FindFirstChild("Combat") then
		Combat.ResetState(ctx)
		return
	end
	
	blockBarFrame.Visible = true
	
	AnimationManager.PlayAnimation(activeAnim, Enum.AnimationPriority.Action, 1, 1, true)
	current = "Active"
	
	ApplyAttributeRE:FireServer("Combat", current)
	Combat.StateChanged:Fire(current)
end

function Combat.ResetState(ctx)
	if current == nil then return end
	
	blockBarFrame.Visible = false
	
	AnimationManager.StopAnimation(activeAnim)
	current = nil
	ApplyAttributeRE:FireServer("Combat", nil)
	Combat.StateChanged:Fire(current)
end

function Combat.GetState()
	return current
end

function Combat.IsBusy()
	return current ~= nil and current ~= "Active"
end

local Attack = require(script.Attack)
Attack.Init(Combat.SetActive)

function Combat.Attack(ctx, attackName)
	if current ~= "Active" then return end
	if not Attack.CanEnter(attackName) then return end
	
	current = attackName
	ApplyAttributeRE:FireServer("Combat", current)

	Attack.Enter(ctx, attackName)
	Combat.StateChanged:Fire(current)
end

local Block = require(script.Block)
Block.Init(Combat.SetActive)

function Combat.EnterBlock(ctx)
	if current ~= "Active" then return end
	if not Block.CanEnter() then return end
	
	current = "Parry"
	ApplyAttributeRE:FireServer("Combat", current)

	Block.Enter(ctx)
	Combat.StateChanged:Fire(current)
	
	task.delay(1, function()
		if current == "Parry" then
			current = "Block"

			ApplyAttributeRE:FireServer("Combat", current)
			Combat.StateChanged:Fire(current)
		end
	end)
end

function Combat.ExitBlock(ctx)
	if current ~= "Block" and current ~= "Parry" then return end	
	Block.Exit(ctx)
end

return Combat