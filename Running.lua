local ReplicatedStorage = game:GetService("ReplicatedStorage")

local State = require(ReplicatedStorage.State)

local Running = {}
Running.__index = Running
setmetatable(Running, State)

function Running.new()
	local self = setmetatable(State.new("Running"), Running)

	self._track = nil

	return self
end

-- Load Animation
function Running:Setup(context)
	local animator = context.Animator

	local animation = context.Animations.Run
	self._track = animator:LoadAnimation(animation)

	self._track.Looped = true
end

function Running:Enter(context)
	context.Character.Humanoid.WalkSpeed = 28

	if self._track then
		self._track:Play()
	end
end

-- Enter runn
function Running:Update(dt, context)
	local humanoid = context.Humanoid
	local userInput = context.UserInput
	local moveMag = humanoid.MoveDirection.Magnitude

	
	if moveMag <= 0.1 then -- Not moving go idle
		context.FSM:Change("Idle")
		return
	elseif not userInput.ShiftHeld then -- Not holding shift walk
		context.FSM:Change("Walking")
		return
	end

	local speed = humanoid.WalkSpeed
	self._track:AdjustSpeed(speed / 24)
end


function Running:Exit(context)
	if self._track then
		self._track:Stop()
		
	end
end

return Running
