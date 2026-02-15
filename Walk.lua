local ReplicatedStorage = game:GetService("ReplicatedStorage")

local State = require(ReplicatedStorage.State)

local Walking = {}
Walking.__index = Walking
setmetatable(Walking, State)

function Walking.new()
	local self = setmetatable(State.new("Walking"), Walking)

	self._track = nil

	return self
end

-- Load Animation
function Walking:Setup(context)
	local animator = context.Animator

	local animation = context.Animations.Walk
	self._track = animator:LoadAnimation(animation)

	self._track.Looped = true
end

function Walking:Enter(context)
	
	if self._track then
		self._track:Play()
	end
end

-- Update anim speed to walkspeed
function Walking:Update(dt, context)
	local humanoid = context.Humanoid

	if humanoid.MoveDirection.Magnitude <= 0.1 then
		context.FSM:Change("Idle")
		return
	end

	local speed = humanoid.WalkSpeed
	self._track:AdjustSpeed(speed / 16)
end

function Walking:Exit(context)
	if self._track then
		self._track:Stop()
		
	end
end

return Walking
