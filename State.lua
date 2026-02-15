--[[
	Abstract State Class
	
	Every state inherits from this
	defines the lifecycle methods for the statemachine to call
	
	Enter() - Called when the state is entered
	Exit() - Called when the state is exited
	Update() - Called every frame whilst active
	Cleanup() - Handles memory cleanup

]]

local State = {}
State.__index = State

-- Create a new state instance
function State.new(name)
	local self = setmetatable({}, State)
	self.Name = name
	self._connections = {}
	return self
end

-- Overrided
function State:Enter(context) end
-- Overrided
function State:Exit(context) end
-- Overrided
function State:Update(dt, context) end
-- Overrided
function State:CanTransition(nextState, context)
	return true
end

-- Clears up connections to stop memory leaks
function State:Cleanup()
	for _, connection in self._connections do
		connection:Disconnect()
	end
	
	table.clear(self._connections)
end

return State		
