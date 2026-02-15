-- State Machine

local RunService = game:GetService("RunService")

local StateMachine = {}
StateMachine.__index = StateMachine

function StateMachine.new(context)
	local self = setmetatable({}, StateMachine)

	self.Context = context -- Shared data like character stats
	self.CurrentState = nil
	self.StateStack = {}
	self._states = {}
	self._debug = false

	return self
end

-- Register new states that can be accessed via StateMachine:Change(name)
function StateMachine:Register(state)
	self._states[state.Name] = state
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
	end

	self.CurrentState = nextState
	self.CurrentState:Enter(self.Context)

	if self._debug then
		print("[FSM] Changed to:", stateName)
	end
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
function StateMachine:ChangeFor(stateName: string, duration: number)
	self:Push(stateName)

	task.delay(duration, function()
		if self.CurrentState and self.CurrentState.Name == stateName then
			self:Pop()
		end
	end)
end

function StateMachine:Start()
	if self._connection then return end

	self._connection = RunService.Heartbeat:Connect(function(dt)
		if self.CurrentState then
			self.CurrentState:Update(dt, self.Context)
		end
	end)
end

-- Stops the state machine 
function StateMachine:Stop()
	if self._connection then
		self._connection:Disconnect()
		self._connection = nil
	end
end


return StateMachine
