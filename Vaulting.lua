local UIS = game:GetService("UserInputService")
local CS = game:GetService("CollectionService")





	local plr = game:GetService("Players").LocalPlayer
	local char = plr.Character or plr.CharacterAdded:Wait()
	local HRP = char:WaitForChild("HumanoidRootPart")

	local Hum = char:WaitForChild("Humanoid")
	local CA = Hum:LoadAnimation(script:WaitForChild("ClimbAnim"))


	
	local cons = {}
	
	local vaultavail = true
	
	table.insert(cons, game:GetService("RunService").RenderStepped:Connect(function() 
		local r = Ray.new(HRP.Position, HRP.CFrame.LookVector * 3 + HRP.CFrame.UpVector * -2)
		local part = workspace:FindPartOnRay(r,char)

		if part and vaultavail  then
			if part.Name ~= "Baseplate" then
				if part.Name ~= "SpawnLocation" then

					if part:HasTag("Vaultable") then
						if Hum.FloorMaterial ~= Enum.Material.Air then
							if char:WaitForChild("IsRagdoll").Value then
								return
							end
							Hum.AutoRotate = false

							vaultavail = false
							local Vel = Instance.new("BodyVelocity")
							Vel.Parent = HRP
							Vel.Velocity = Vector3.new(0,0,0)
							Vel.MaxForce = Vector3.new(1,1,1) * math.huge
							Vel.Velocity = HRP.CFrame.LookVector * 20 + Vector3.new(0,10,0)
							CA:Play()
							game.Debris:AddItem(Vel, .15)
							task.delay(0.3, function()
								Hum.AutoRotate = true
							end)
							wait(0.75)

							vaultavail = true
						end
					end

				end
			end
		end
	end))	
	
