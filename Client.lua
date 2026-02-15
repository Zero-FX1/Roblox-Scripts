local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")


local States = ReplicatedStorage.States

local Idle = require(States.Idle)
local Walking = require(States.Walk)
local Running = require(States.Running)

local StateMachine = require(ReplicatedStorage.StateMachine)

local character = script.Parent
local humanoid = character:WaitForChild("Humanoid")
local animator = humanoid:WaitForChild("Animator")



local userInput = { ShiftHeld = false }

UserInputService.InputBegan:Connect(function(inp, pro)
	if pro then return end

	if inp.KeyCode == Enum.KeyCode.LeftShift then
		userInput.ShiftHeld = true
	end
end)

UserInputService.InputEnded:Connect(function(inp)

	if inp.KeyCode == Enum.KeyCode.LeftShift then
		userInput.ShiftHeld = false
	end
end)


local context = {
	Character = character,
	Humanoid = humanoid,
	Animator = animator,
	Animations = {
		Idle = script.Animations.Idle,
		Walk = script.Animations.Walk,
		Run = script.Animations.Run
	},
	UserInput = userInput,
}


local fsm = StateMachine.new(context)
context.FSM = fsm 


fsm:Register(Idle.new())
fsm:Register(Walking.new())
fsm:Register(Running.new())
fsm:Change("Idle")
fsm:Start()

