local Signal = {}
Signal.__index = Signal

function Signal.new()
	return setmetatable({ _listeners = {} }, Signal)
end

function Signal:Connect(fn)
	local connection = {
		Connected = true,
		Disconnect = function(self)
			if not self.Connected then return end
			self.Connected = false
			self._listeners[fn] = nil
		end,
		_listeners = self._listeners,
	}

	self._listeners[fn] = connection
	return connection
end

function Signal:Fire(...)
	for fn, connection in self._listeners do
		if connection.Connected then
			task.spawn(fn, ...)
		end
	end
end

function Signal:Destroy()
	table.clear(self._listeners)
end

return Signal