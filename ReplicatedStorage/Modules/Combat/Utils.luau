local Utils = {}
local RESET_DELAY = 2

local lastSide = "Right Arm"
local lastAttackTime = 0

function Utils.GetAttackSide()
	local now = os.clock()
	if now - lastAttackTime >= RESET_DELAY then
		lastSide = "Right Arm"
	else
		lastSide = (lastSide == "Right Arm") and "Left Arm" or "Right Arm"
	end
	lastAttackTime = now
	return lastSide
end

return Utils