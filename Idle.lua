-- Example State

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local State = require(ReplicatedStorage.State)

local Idle = setmetatable({}, State)
Idle.__index = Idle

function Idle.new()
	return setmetatable(State.new("Idle"), Idle)
end

-- Load Animation
function Idle:Setup(context)
	local animator = context.Animator

	local animation = context.Animations.Idle
	self._track = animator:LoadAnimation(animation)

	self._track.Looped = true
end

function Idle:Enter(context)
	if self._track then
		self._track:Play()
	end
end

-- Change state to walking fast enough
function Idle:Update(dt, context)
	local humanoid = context.Humanoid
	if humanoid.MoveDirection.Magnitude > 0.1 then
		context.FSM:Change("Walking")
	end
end



function Idle:Exit(context)
	if self._track then
		self._track:Stop()
	
	end
end
return Idle
