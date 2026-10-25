local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Signal = require(ReplicatedStorage.Modules.Signal)

local ApplyAttributeRE = ReplicatedStorage:WaitForChild("RemoteEvents"):WaitForChild("ApplyAttribute")

local Movement = {}
Movement.StateChanged = Signal.new()

local activeStateName = nil
local stateCache = {}

local function getState(name)
	if not stateCache[name] then
		local instance = script:FindFirstChild(name)
		if not instance then
			error("Movement: no state named '" .. tostring(name) .. "'")
		end
		stateCache[name] = require(instance)
	end
	return stateCache[name]
end

function Movement.SetState(ctx, name, force)
	if not force and name == activeStateName then return end

	local incoming = getState(name)

	if activeStateName then
		getState(activeStateName).Exit(ctx)
	end

	incoming.Enter(ctx)
	
	if name == "Walking" or name == "Sprinting" then
		getState("CharacterTilt").Enter(ctx)
	end
	
	activeStateName = name

	ApplyAttributeRE:FireServer("Movement", name)
	Movement.StateChanged:Fire(name)
end

function Movement.ResetState(ctx)
	activeStateName = nil

	if ctx then
		ApplyAttributeRE:FireServer("Movement", nil)
	end
end

function Movement.GetState()
	return activeStateName
end

function Movement.IsBusy()
	return activeStateName == "Stunned"
	or activeStateName == "Dash"
	or activeStateName == "Jump"
end

return Movement