local Module = {}
--local RE = game.ReplicatedStorage:WaitForChild("Character"):WaitForChild("Events"):WaitForChild("Ragdoll")
local PS = game:GetService("PhysicsService")
local CS = game:GetService("CollectionService")

Module.Bot = function(bot)
	task.spawn(function()
		local H = bot.Humanoid
		bot.HumanoidRootPart:SetNetworkOwner(nil)
		CS:AddTag(bot.LowerTorso,"RootPart")
		for _,v in pairs(H:GetPlayingAnimationTracks()) do 
			v:Stop(0) 
		end
		
		local numberOfForces = 0
		for _,v in pairs(bot:GetDescendants()) do
			if v:IsA'Motor6D'and Module.Check(v.Name) then
				v.Enabled = false
			elseif v:IsA'BallSocketConstraint' or v:IsA("HingeConstraint") then
				v.Enabled = true
			elseif v:IsA("BasePart") then
				v.LocalTransparencyModifier = 0
				v:SetNetworkOwner(nil)
			end
		end
		
		H:SetStateEnabled(Enum.HumanoidStateType.GettingUp,false)
		H:ChangeState(Enum.HumanoidStateType.Physics)
		
		task.wait(game:GetService("Players").RespawnTime+6.1)
		
		--task.wait(100)
		--for _,part in pairs(bot:GetDescendants()) do
		--	if part:IsA("BasePart") then
		--	--	part.Anchored = true
		--	end
		--end
	end)
end

Module.Check = function(t)
	for _,v in pairs({"LeftWrist","RightWrist","LeftAnkle","RightAnkle"}) do
		if v == t then return false end
	end
	return true
end

local bodyJoinInfo = {
	--["BallSocket Ex"] = 	{UpperAngle,TwistLowerAngle,TwistUpperAngle}
	["HumanoidRootPart"] = 	{15, -10, 25},
	["LowerTorso"] = 		{ 0,   0,  0},
	["UpperTorso"] = 		{15, -10, 25},
	["Head"] = 				{0, 0,0},
	["LeftUpperArm"] = 		{70, -45, 45},
	["RightUpperArm"] = 	{70, -45, 45},
	["LeftUpperLeg"] = 		{45, -20, 45},
	["RightUpperLeg"] = 	{45, -20, 45},
	
	
	--["Hinge Ex"] = 		{"Hinge",LowerAngle,UpperAngle}
	["LeftLowerArm"] = 		{"Hinge",  20, 	  100},
	["LeftHand"] = 			{"Hinge",  5,     10},
	["RightLowerArm"] = 	{"Hinge",  20,    100},
	["RightHand"] = 		{"Hinge",  5,     10},
	["LeftLowerLeg"] = 		{"Hinge", -100,  -20},
	["LeftFoot"] = 			{"Hinge",  5,     10},
	["RightLowerLeg"] = 	{"Hinge", -100,  -20},
	["RightFoot"] = 		{"Hinge",  5,  	  10},
}

Module.Joints = function(c)
	c.Humanoid.BreakJointsOnDeath = false
	c.Humanoid.RequiresNeck = false
	for _,v in pairs(c:GetDescendants()) do
		if v:IsA("Motor6D") and Module.Check(v.Name) then --/ This is a joint
			local b = nil
			if bodyJoinInfo[v.Part1.Name] and bodyJoinInfo[v.Part1.Name][1] == "Hinge" then --/ This is a hinge joint
				b = Instance.new("HingeConstraint")
				b.LowerAngle = bodyJoinInfo[v.Part1.Name][2]
				b.UpperAngle = bodyJoinInfo[v.Part1.Name][3]
			elseif bodyJoinInfo[v.Part1.Name] then --/ This is a ball socket joint
				b = Instance.new("BallSocketConstraint")
				b.TwistLimitsEnabled = true
				b.UpperAngle = bodyJoinInfo[v.Part1.Name][1]
				b.TwistLowerAngle = bodyJoinInfo[v.Part1.Name][2]
				b.TwistUpperAngle = bodyJoinInfo[v.Part1.Name][3]
			end
			
			if b then
				b.LimitsEnabled = true
				local a0,a1 = Instance.new("Attachment"), Instance.new("Attachment")
				a0.Parent,a1.Parent = v.Part0,v.Part1
				a0.Name,a1.Name = v.Part0.Name,v.Part1.Name
				b.Attachment0,b.Attachment1 = a0,a1
				a0.CFrame,a1.CFrame = v.c0,v.c1
				
				if b:IsA("BallSocketConstraint") and b.Attachment0.Name == "UpperTorso" and b.Attachment1.Name == "Head" then
					b.Attachment0.Orientation = Vector3.new(0, -90, 0)
					b.Attachment1.Orientation = Vector3.new(0, -90, 0)
				end
				
				b.Enabled = false
				b.Parent = v.Part0
			end
			
		elseif v:IsA("BasePart") then --/ This is a part
			v.CollisionGroup = "A"
			if v.Name == "HumanoidRootPart" then
				v.CollisionGroup = "B"
			elseif v.Name == "Head" and v.Parent.Name ~= "Hair" then -- Make head (and not hair) collidable
				v.CanCollide = true
			end
		end
	end
end

return Module

