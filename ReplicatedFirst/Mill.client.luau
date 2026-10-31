local RunService = game:GetService("RunService")

local model = workspace:WaitForChild("Map"):WaitForChild("WaterMill", 60)
local pivot = model:GetPivot()

local ROTATE_SPEED = 10 

RunService.Heartbeat:Connect(function()
	local t = workspace:GetServerTimeNow() % ROTATE_SPEED
	local angle = (t / ROTATE_SPEED) * 360
	model:PivotTo(pivot * CFrame.Angles(0, math.rad(angle), 0))
end)