local RunService = game:GetService("RunService")

--------------
-- SIGNAL CLASS
--------------
local Signal = {}
Signal.__index = Signal

function Signal.new()
	return setmetatable({
		_bindings = {}
	}, Signal)
end

function Signal:Connect(fn)
	table.insert(self._bindings, fn)
	return {
		Disconnect = function()
			local index = table.find(self._bindings, fn)
			if index then
				table.remove(self._bindings, index)
			end
		end
	}
end

function Signal:Fire(...)
	for _, fn in ipairs(self._bindings) do
		fn(...)
	end
end

function Signal:Destroy()
	table.clear(self._bindings)
end


-------------
-- STATE CLASS
----------------

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
function State:Setup(context) end
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

function State:AddTag(tag)
	self.Tags[tag] = true
end

function State:HasTag(tag)
	return self.Tags[tag] == true
end

-- Clears up connections to stop memory leaks
function State:Cleanup()
	for _, connection in self._connections do
		connection:Disconnect()
	end

	table.clear(self._connections)
end



---------------
-- STATE MACHINE CLASS
---------------
local StateMachine = {}
StateMachine.__index = StateMachine

function StateMachine.new(context)
	local self = setmetatable({}, StateMachine)

	self.Context = context -- Shared data like character stats
	self.CurrentState = nil
	self.StateStack = {}
	self._states = {}
	self._debug = false


	self._lastTransition = 0
	self.TransitionCooldown = 0.05

	self._timer = 0
	self._timedActive = false

	self._conditionalTransitions = {}
	self._globalTransitions = {}

	self.StateChanged = Signal.new()
	
	self._transitionQueue = {}
	self._isTransitioning = false
	
	self._history = {}
	self.MaxHistory = 50
	
	self.Tags = {}

	return self
end

-- Register new states that can be accessed via StateMachine:Change(name)
function StateMachine:Register(state)
	self._states[state.Name] = state
	state:Setup(self.Context)
end

function StateMachine:_canTransition(nextState)
	if not nextState then return false end

	if tick() - self._lastTransition < self.TransitionCooldown then
		return false
	end

	if self.CurrentState then
		if not self.CurrentState:CanTransition(nextState, self.Context) then
			return false
		end
	end

	return true
end

-- Transition to a new state
function StateMachine:Change(stateName)
	local nextState = self._states[stateName]
	if not nextState then return end

	if self.CurrentState then
		if not self.CurrentState:CanTransition(nextState, self.Context) then
			return
		end

		self.CurrentState:Exit(self.Context)
		self.CurrentState:Cleanup()
		
		table.insert(self._history, {
			From = self.CurrentState and self.CurrentState.Name,
			To = stateName,
			Time = tick()
		})

		if #self._history > self.MaxHistory then
			table.remove(self._history, 1)
		end
	end
	
	

	self.CurrentState = nextState
	self.CurrentState:Enter(self.Context)

	if self._debug then
		print("[FSM] Changed to:", stateName)
	end
end

function StateMachine:IsCurrentTagged(tag)
	if not self.CurrentState then return false end
	return self.CurrentState:HasTag(tag)
end

function StateMachine:RequestChange(stateName)
	table.insert(self._transitionQueue, stateName)
end

function StateMachine:_processQueue()
	if self._isTransitioning then return end
	if #self._transitionQueue == 0 then return end

	local nextState = table.remove(self._transitionQueue, 1)
	self._isTransitioning = true
	self:Change(nextState)
	self._isTransitioning = false
end

-- Push a new state to the top of the stack
function StateMachine:Push(stateName)
	if self.CurrentState then
		table.insert(self.StateStack, self.CurrentState)
		self.CurrentState:Exit(self.Context)
	end

	self.CurrentState = self._states[stateName]
	self.CurrentState:Enter(self.Context)
end

-- Create a global state transition
function StateMachine:AddGlobalTransition(toState, conditionFn)
	table.insert(self._globalTransitions, {
		To = toState,
		Condition = conditionFn
	})
end

-- Return to past state
function StateMachine:Pop()
	if self.CurrentState then
		self.CurrentState:Exit(self.Context)
		self.CurrentState:Cleanup()
	end

	self.CurrentState = table.remove(self.StateStack)
	if self.CurrentState then
		self.CurrentState:Enter(self.Context)
	end
end

-- Change to state for x seconds
function StateMachine:ChangeTimed(stateName, duration)
	self:Push(stateName)
	self._timer = duration
	self._timedActive = true
end

function StateMachine:Start()
	if self._connection then return end

	self._connection = RunService.Heartbeat:Connect(function(dt)

		-- Timed states
		if self._timedActive then
			self._timer -= dt
			if self._timer <= 0 then
				self._timedActive = false
				self:Pop()
			end
		end

		-- State update
		if self.CurrentState then
			self.CurrentState:Update(dt, self.Context)
		end

		-- Conditional transitions
		self:_checkConditionalTransitions()
	end)

	self:_log("StateMachine started")
end

function StateMachine:AddConditionalTransition(fromState : string, toState : string, conditionFn)
	assert(self._states[fromState], "Invalid fromState")
	assert(self._states[toState], "Invalid toState")

	self._conditionalTransitions[fromState] =
		self._conditionalTransitions[fromState] or {}

	table.insert(self._conditionalTransitions[fromState], {
		To = toState,
		Condition = conditionFn
	})
end


function StateMachine:_checkConditionalTransitions()
	if not self.CurrentState then return end

	local transitions = self._conditionalTransitions[self.CurrentState.Name]
	if not transitions then return end

	for _, data in ipairs(transitions) do
		if data.Condition(self.Context) then
			self:Change(data.To)
			return
		end
	end
	
	for _, data in ipairs(self._globalTransitions) do
		if data.Condition(self.Context) then
			self:Change(data.To)
			return
		end
	end
end


-- Stops the state machine 
function StateMachine:Stop()
	if self._connection then
		self._connection:Disconnect()
		self._connection = nil
	end
end


StateMachine.BaseState = State

return StateMachine
