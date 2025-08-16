local Module = {}
--local RE = game.ReplicatedStorage:WaitForChild("Character"):WaitForChild("Events"):WaitForChild("Ragdoll")
local PS = game:GetService("PhysicsService")
local CS = game:GetService("CollectionService")

local AnchorTime = 300

Module.Bot = function(Ragdoll: Model)
	task.spawn(function()
		local Humanoid = Ragdoll.Humanoid
		Ragdoll.HumanoidRootPart:SetNetworkOwner(nil)
		CS:AddTag(Ragdoll.LowerTorso,"RootPart")
		for _,Animation in pairs(Humanoid:GetPlayingAnimationTracks()) do 
			Animation:Stop(0) 
		end
		
		for _,CharacterJoint in pairs(Ragdoll:GetDescendants()) do
			if CharacterJoint:IsA("Motor6D") and Module.Check(CharacterJoint.Name) then
				CharacterJoint.Enabled = false
			elseif CharacterJoint:IsA("BallSocketConstraint") or CharacterJoint:IsA("HingeConstraint") then
				CharacterJoint.Enabled = true
			elseif CharacterJoint:IsA("BasePart") then
				CharacterJoint.LocalTransparencyModifier = 0
				CharacterJoint:SetNetworkOwner(nil)
			end
		end
		
		Humanoid:SetStateEnabled(Enum.HumanoidStateType.GettingUp,false)
		Humanoid:ChangeState(Enum.HumanoidStateType.Physics)
		
		task.wait(game:GetService("Players").RespawnTime + 6.1 + AnchorTime)
		for _,part in pairs(Ragdoll:GetDescendants()) do
			if part:IsA("BasePart") then
				part.Anchored = true
			end
		end
	end)
end

Module.Check = function(t)
	for _,v in pairs({"LeftWrist","RightWrist","LeftAnkle","RightAnkle"}) do
		if v == t then 
			return false 
		end
	end
	return true
end

local bodyJoinInfo = {
	--["BallSocket Ex"] = 	{UpperAngle, TwistLowerAngle, TwistUpperAngle, AttachmentName}
	["HumanoidRootPart"] = 	{15, -10, 25, "RootPartRagdoll"},
	["LowerTorso"] = 		{ 0,   0,  0, "RootPartRagdoll"},
	["UpperTorso"] = 		{15, -10, 25, "WaistRagdoll"},
	["Head"] = 				{15, -45, 15, "NeckRagdoll"},
	["LeftUpperArm"] = 		{70, -45, 45, "LeftShoulderRagdoll"},
	["RightUpperArm"] = 	{70, -45, 45, "RightShoulderRagdoll"},
	["LeftUpperLeg"] = 		{45, -20, 45, "LeftHipRagdoll"},
	["RightUpperLeg"] = 	{45, -20, 45, "RightHipRagdoll"},
	
	
	--["Hinge Ex"] = 		{"Hinge", LowerAngle, UpperAngle, AttachmentName}
	["LeftLowerArm"] = 		{"Hinge",  20, 	  100, "LeftElbowRagdoll"},
	["LeftHand"] = 			{"Hinge",  5,     10, "LeftWristRagdoll"},
	["RightLowerArm"] = 	{"Hinge",  20,    100, "RightElbowRagdoll"},
	["RightHand"] = 		{"Hinge",  5,     10, "RightWristRagdoll"},
	["LeftLowerLeg"] = 		{"Hinge", -100,  -20, "LeftKneeRagdoll"},
	["LeftFoot"] = 			{"Hinge",  5,     10, "LeftAnkleRagdoll"},
	["RightLowerLeg"] = 	{"Hinge", -100,  -20, "RightKneeRagdoll"},
	["RightFoot"] = 		{"Hinge",  5,  	  10, "RightAnkleRagdoll"},
}

Module.Joints = function(c)
	c.Humanoid.BreakJointsOnDeath = false
	c.Humanoid.RequiresNeck = false
	for _,v in pairs(c:GetDescendants()) do
		if v:IsA("Motor6D") and Module.Check(v.Name) then --/ This is a joint
			local Constraint = nil
			if bodyJoinInfo[v.Part1.Name] and bodyJoinInfo[v.Part1.Name][1] == "Hinge" then --/ This is a hinge joint
				Constraint = Instance.new("HingeConstraint")
				Constraint.LowerAngle = bodyJoinInfo[v.Part1.Name][2]
				Constraint.UpperAngle = bodyJoinInfo[v.Part1.Name][3]
			elseif bodyJoinInfo[v.Part1.Name] then --/ This is a ball socket joint
				Constraint = Instance.new("BallSocketConstraint")
				Constraint.TwistLimitsEnabled = true
				Constraint.UpperAngle = bodyJoinInfo[v.Part1.Name][1]
				Constraint.TwistLowerAngle = bodyJoinInfo[v.Part1.Name][2]
				Constraint.TwistUpperAngle = bodyJoinInfo[v.Part1.Name][3]
			end
			
			if Constraint then
				Constraint.LimitsEnabled = true
				local Attachment0, Attachment1 = v.Part0[bodyJoinInfo[v.Part1.Name][4]]:Clone(), v.Part1[bodyJoinInfo[v.Part1.Name][4]]:Clone()
				Attachment0.Parent, Attachment1.Parent = v.Part0, v.Part1
				Constraint.Attachment0, Constraint.Attachment1 = Attachment0, Attachment1
				
				Constraint.Enabled = false
				Constraint.Parent = v.Part0
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

