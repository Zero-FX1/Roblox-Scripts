-- SERVICES
local CS=game:GetService("CollectionService") -- Tag system
local Debris=game:GetService("Debris") -- Automatic cleanup
local Players=game:GetService("Players")
local UIS=game:GetService("UserInputService") -- Input handler
local RunService=game:GetService("RunService") -- Per-frame updates

-- CONSTANTS
local WALL_DETECTION_DISTANCE=2
local WALL_JUMP_LIMIT=3
local WALLRUN_DOWN_FORCE=-4
local WALLRUN_FORCE_SCALE=0.1
local WALL_JUMP_BOOST=12
local WALL_JUMP_FORWARD_BOOST=0.5
local WALL_ANIM_SPEED=1

-- STATE
local cons={}
local airTime=0
local character=Players.LocalPlayer.Character
local currentAnimationTrack
local currentBodyForce
local currentBodyVelocity
local head=character:WaitForChild("Head",nil)
local humanoid=character:WaitForChild("Humanoid",nil)
local humanoidRootPart=character:WaitForChild("HumanoidRootPart",nil)
local leftArm=character:WaitForChild("Left Arm",nil)
local leftLeg=character:WaitForChild("Left Leg",nil)
local rightArm=character:WaitForChild("Right Arm",nil)
local rightLeg=character:WaitForChild("Right Leg",nil)
local localPlayer=Players:GetPlayerFromCharacter(character)
local wallrunLeftAnimation=script:WaitForChild("WallrunLeft",nil)
local wallrunRightAnimation=script:WaitForChild("WallrunRight",nil)
local wallRunning=false
local canWallRun=true
local wallJumps=0
local wallDir=nil

-- Load animations
local leftTrack=humanoid.Animator:LoadAnimation(wallrunLeftAnimation)
local rightTrack=humanoid.Animator:LoadAnimation(wallrunRightAnimation)
leftTrack:AdjustSpeed(WALL_ANIM_SPEED)
rightTrack:AdjustSpeed(WALL_ANIM_SPEED)

print("Wallrun system initialized")

-- HELPER: Raycast utility
local ray=function(origin,stop,start,include)
	include=include or{}
	local hit,position=workspace:FindPartOnRayWithWhitelist(Ray.new(origin,(stop-start)),include,false,false)
	return hit,position
end

-- HELPER: Create BodyVelocity
local function createBodyVelocity(parent,velocity)
	local bv=Instance.new("BodyVelocity")
	bv.Velocity=velocity
	bv.Parent=parent
	return bv
end

-- HELPER: Create BodyForce
local function createBodyForce(parent,force)
	local bf=Instance.new("BodyForce")
	bf.Force=force
	bf.Parent=parent
	return bf
end

-- WALL DETECTION
local function castLeftSideRay()
	local pos=humanoidRootPart.CFrame:ToWorldSpace(CFrame.new(-WALL_DETECTION_DISTANCE,0,0)).Position
	local hit=ray(humanoidRootPart.Position,pos,humanoidRootPart.CFrame.Position,CS:GetTagged("Wallrun"))
	print("Left wall check:",hit)
	return hit
end

local function castRightSideRay()
	local pos=humanoidRootPart.CFrame:ToWorldSpace(CFrame.new(WALL_DETECTION_DISTANCE,0,0)).Position
	local hit=ray(humanoidRootPart.Position,pos,humanoidRootPart.CFrame.Position,CS:GetTagged("Wallrun"))
	print("Right wall check:",hit)
	return hit
end

-- START WALLRUNNING
local function startWallRunning(wallSide)
	if humanoidRootPart.AssemblyLinearVelocity.Y>0 then return end
	if not wallRunning and currentAnimationTrack then
		currentAnimationTrack:Stop()
		currentAnimationTrack=nil
	end
	wallRunning=true
	wallDir=wallSide

	currentBodyVelocity=createBodyVelocity(humanoidRootPart,Vector3.new(0,WALLRUN_DOWN_FORCE,0))
	local totalMass=head:GetMass()+humanoidRootPart:GetMass()+leftArm:GetMass()+leftLeg:GetMass()+rightArm:GetMass()+rightLeg:GetMass()
	currentBodyForce=createBodyForce(humanoidRootPart,Vector3.new(0,totalMass*workspace.Gravity*WALLRUN_FORCE_SCALE,0))

	if wallSide==Enum.NormalId.Left then
		currentAnimationTrack=leftTrack
	elseif wallSide==Enum.NormalId.Right then
		currentAnimationTrack=rightTrack
	end

	if not currentAnimationTrack.IsPlaying then
		currentAnimationTrack.Looped=true
		currentAnimationTrack:Play()
	end

	print("Started wallrunning on side:",wallSide)
end

-- STOP WALLRUNNING
local function stopWallRunning()
	if currentAnimationTrack then
		currentAnimationTrack:Stop()
		currentAnimationTrack=nil
	end
	if currentBodyForce then Debris:AddItem(currentBodyForce,0) end
	if currentBodyVelocity then Debris:AddItem(currentBodyVelocity,0) end
	wallRunning=false
	print("Stopped wallrunning")
end

-- CAN WALLRUN CHECK
local function canStartWallRun()
	local ragdoll=character:WaitForChild("IsRagdoll").Value
	return not wallRunning and humanoid.FloorMaterial==Enum.Material.Air and humanoidRootPart.Velocity.Magnitude>humanoid.WalkSpeed/2 and airTime>0.25 and not ragdoll
end

-- CLEANUP FUNCTION
local function cleanup()
	for _,con in ipairs(cons) do
		if con.Disconnect then con:Disconnect() end
	end
	print("Wallrun system cleaned up.")
end

-- FLOOR CONTACT RESET
table.insert(cons,humanoid:GetPropertyChangedSignal("FloorMaterial"):Connect(function()
	if humanoid.FloorMaterial~=Enum.Material.Air then
		stopWallRunning()
		canWallRun=true
		wallJumps=0
	end
end))

-- WALL JUMP INPUT
table.insert(cons,UIS.JumpRequest:Connect(function()
	if wallRunning then
		humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
		local bodyPos=Instance.new("BodyPosition",humanoidRootPart)
		bodyPos.MaxForce=Vector3.new(1,1,1)*math.huge
		bodyPos.P=10000

		local val=wallDir.Value
		local boostDir
		if val==0 then
			boostDir=-humanoidRootPart.CFrame.RightVector
			val=5
		elseif val==3 then
			boostDir=humanoidRootPart.CFrame.RightVector
			val=-5
		end

		bodyPos.D=1000
		bodyPos.Position=humanoidRootPart.Position+boostDir*WALL_JUMP_BOOST+Vector3.new(0,humanoid.JumpHeight,0)+humanoidRootPart.CFrame.LookVector*(humanoid.WalkSpeed/5+WALL_JUMP_FORWARD_BOOST)
		Debris:AddItem(bodyPos,0.15)

		wallJumps+=1
		if wallJumps>=WALL_JUMP_LIMIT then
			canWallRun=false
		end
		stopWallRunning()
	end
end))

-- FRAME LOOP FOR WALLRUN CHECKS
table.insert(cons,RunService.Heartbeat:Connect(function(step)
	if humanoid.FloorMaterial==Enum.Material.Air then
		airTime+=step
	else
		airTime=0
	end

	if humanoid.FloorMaterial~=Enum.Material.Air then
		stopWallRunning()
		return
	end

	local leftWall=castLeftSideRay()
	if leftWall and canStartWallRun() then
		if not canWallRun then return end
		startWallRunning(Enum.NormalId.Left)
		return
	end

	local rightWall=castRightSideRay()
	if rightWall and canStartWallRun() then
		if not canWallRun then return end
		startWallRunning(Enum.NormalId.Right)
		return
	end

	if not leftWall and not rightWall then
		stopWallRunning()
	end
end))
