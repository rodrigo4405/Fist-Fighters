local Utils = {}
local CONFIG = require(script.Parent:WaitForChild("Configuration"))

function Utils.deepcopy(t)
	if type(t) ~= "table" then return t end
	local copy = {}
	for key, value in pairs(t) do
		copy[key] = Utils.deepcopy(value)
	end
	return copy
end

function Utils.retry(func, funcName)
	funcName = funcName or "function"
	local err
	for attempt = 1, CONFIG.MAX_RETRIES do
		local success, result = pcall(func)
		if success then return success, result end
		err = result
		warn(("`%s` failed (attempt %d/%d): %s"):format(funcName, attempt, CONFIG.MAX_RETRIES, err))
		if attempt < CONFIG.MAX_RETRIES then
			task.wait(2 ^ (attempt - 1))
		end
	end
	return false, err
end

function Utils.getDefaultData()
	return Utils.deepcopy(CONFIG.DEFAULT_DATA)
end

function Utils.getDefaultSessionData()
	return Utils.deepcopy(CONFIG.DEFAULT_SESSION_DATA)
end

function Utils.reconcileData(data, template)
	local clean = Utils.deepcopy(template or Utils.getDefaultData())
	if type(data) ~= "table" then return clean end
	for k, v in pairs(data) do
		if clean[k] ~= nil and type(clean[k]) == type(v) then
			if type(v) ~= "table" then
				clean[k] = v
				continue
			end
			clean[k] = Utils.reconcileData(v, clean[k])
		end
	end
	return clean
end

return Utils
