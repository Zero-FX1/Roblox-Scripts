-- Example State

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local State = require(ReplicatedStorage.State)

local Idle = setmetatable({}, State)
Idle.__index = Idle

function Idle.new()
	return setmetatable(State.new("Idle"), Idle)
end

function Idle:Enter(context)
	print("Entering Idle")
end

function Idle:Update(dt, context)
	-- play idle animation or whatever
end

function Idle:Exit(context)
	print("Exiting Idle")
end

return Idle
