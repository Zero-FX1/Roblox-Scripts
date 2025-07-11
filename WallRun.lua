local CS = game:GetService("CollectionService")
local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")



local cons = {}
	
local airTime = 0
local character = game.Players.LocalPlayer.Character
local currentAnimationTrack: AnimationTrack
local currentBodyForce: BodyForce
local currentBodyVelocity
local head = character:WaitForChild("Head", nil)
local humanoid = character:WaitForChild("Humanoid", nil)
local humanoidRootPart = character:WaitForChild("HumanoidRootPart", nil)
local leftArm = character:WaitForChild("Left Arm", nil)
local leftLeg = character:WaitForChild("Left Leg", nil)
local localPlayer = Players:GetPlayerFromCharacter(character)
local rightArm = character:WaitForChild("Right Arm", nil)
local rightLeg = character:WaitForChild("Right Leg", nil)	
local wallrunLeftAnimation = script:WaitForChild("WallrunLeft", nil)
local wallrunRightAnimation = script:WaitForChild("WallrunRight", nil)
local wallRunning = false
local canWallRun = true
local wallJumps = 0
local wallDir = nil
	


local leftTrack = humanoid.Animator:LoadAnimation(wallrunLeftAnimation)
local rightTrack = humanoid.Animator:LoadAnimation(wallrunRightAnimation)





	local ray = function(origin, stop, start, include)
		include = include or {}
		local hit, position, _, _ = workspace:FindPartOnRayWithWhitelist(Ray.new(origin, (stop - start)), include, false, false)
		return hit, position
	end

	local function castLeftSideRay()
		local hit, position = ray(humanoidRootPart.Position, humanoidRootPart.CFrame:ToWorldSpace(CFrame.new(-2, 0, 0)).Position, humanoidRootPart.CFrame.Position, CS:GetTagged("Wallrun"))
		return hit
	end

	local function castRightSideRay()
		local hit, position = ray(humanoidRootPart.Position, humanoidRootPart.CFrame:ToWorldSpace(CFrame.new(2, 0, 0)).Position, humanoidRootPart.CFrame.Position, CS:GetTagged("Wallrun"))
		return hit
	end

--[[
	New Code
--]]

	local function startWallRunning(wallSide)
		
		if humanoidRootPart.AssemblyLinearVelocity.Y > 0 then
			return
		end

		if not wallRunning then
			if currentAnimationTrack then

				currentAnimationTrack:Stop()
				currentAnimationTrack = nil
			end
		end

		wallRunning = true


		wallDir = wallSide
		
		

		currentBodyVelocity = Instance.new("BodyVelocity", nil)
currentBodyVelocity.Parent = humanoidRootPart
	--[[	if wallSide == Enum.NormalId.Left then
			currentBodyVelocity.Velocity = (humanoidRootPart.CFrame * CFrame.fromEulerAnglesXYZ(0, math.rad(90), 0)).LookVector * humanoid.WalkSpeed + Vector3.new(0, -2, 0)
		elseif wallSide == Enum.NormalId.Right then
			currentBodyVelocity.Velocity = (humanoidRootPart.CFrame * CFrame.fromEulerAnglesXYZ(0, math.rad(-90), 0)).LookVector * humanoid.WalkSpeed + Vector3.new(0, -2, 0)
		end]]--
	currentBodyVelocity.Velocity = Vector3.new(0, -4, 0)


		currentBodyForce = Instance.new("BodyForce", nil)

		currentBodyForce.Force = Vector3.new(0, (head:GetMass() + humanoidRootPart:GetMass() + leftArm:GetMass() + leftLeg:GetMass() + rightArm:GetMass() + rightLeg:GetMass()) * (workspace.Gravity*0.1), 0)

	

		if wallSide == Enum.NormalId.Left then
			currentAnimationTrack = leftTrack
		elseif wallSide == Enum.NormalId.Right then
			currentAnimationTrack = rightTrack
		end

		if not currentAnimationTrack.IsPlaying then

			currentAnimationTrack.Looped = true
			currentAnimationTrack:Play()
		end
	end

	local function stopWallRunning()
		if currentAnimationTrack then

			currentAnimationTrack:Stop()
			currentAnimationTrack = nil
		end

		if currentBodyForce then
			Debris:AddItem(currentBodyForce, 0)
		end

		if currentBodyVelocity then
			Debris:AddItem(currentBodyVelocity, 0)
		end

		wallRunning = false
	end

	local function canStartWallRun()
		return not wallRunning and humanoid.FloorMaterial == Enum.Material.Air and humanoidRootPart.Velocity.Magnitude > humanoid.WalkSpeed / 2 and airTime > 0.25 and   character:WaitForChild("IsRagdoll").Value == false 
		
	end


	table.insert(cons, humanoid:GetPropertyChangedSignal("FloorMaterial"):Connect(function()
		if humanoid.FloorMaterial ~= Enum.Material.Air then
			stopWallRunning()
			canWallRun = true
			wallJumps = 0
		end
	end))

	table.insert(cons, UIS.JumpRequest:Connect(function()


		if wallRunning then


			humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
			-- apply velo in walldir
			local bodyPos = Instance.new("BodyPosition", humanoidRootPart)
			bodyPos.MaxForce = Vector3.new(1, 1, 1) * math.huge
			bodyPos.P = 10000

			local val = wallDir.Value
			local boostDir

			if val == 0 then
				boostDir = -humanoidRootPart.CFrame.RightVector
				val = 5
			elseif val == 3 then
				boostDir = humanoidRootPart.CFrame.RightVector
				val = -5
			end



			bodyPos.D = 1000
			bodyPos.Position = humanoidRootPart.Position + boostDir*12 + Vector3.new(0, humanoid.JumpHeight, 0) + humanoidRootPart.CFrame.LookVector*(humanoid.WalkSpeed/5 + 0.5)
			Debris:AddItem(bodyPos, 0.15)


			wallJumps += 1
			if wallJumps >= 3 then
				canWallRun = false

			end
			stopWallRunning()
		end
	end))

	table.insert(cons, RunService.Heartbeat:Connect(function(step)



		if humanoid.FloorMaterial == Enum.Material.Air then
			airTime = airTime + step
		else
			airTime = 0
		end



		if humanoid.FloorMaterial ~= Enum.Material.Air  then
			stopWallRunning()

			return
		end

		local leftWall = castLeftSideRay()

		if leftWall and canStartWallRun() then
			if not canWallRun then
				return
			end
			startWallRunning(Enum.NormalId.Left)

			return
		end

		local rightWall = castRightSideRay()

		if rightWall and canStartWallRun() then
			if not canWallRun then
				return
			end
			startWallRunning(Enum.NormalId.Right)

			return
		end

		if not leftWall and not rightWall then
			stopWallRunning()
		end
	end))
	
	return cons
end
