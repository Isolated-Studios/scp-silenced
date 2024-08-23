local Module = {}
--local RE = game.ReplicatedStorage:WaitForChild("Character"):WaitForChild("Events"):WaitForChild("Ragdoll")
local PS = game:GetService("PhysicsService")

Module.Bot = function(bot)
	task.spawn(function()
		local H = bot.Humanoid
		bot.HumanoidRootPart:SetNetworkOwner(nil)
			H:SetStateEnabled(Enum.HumanoidStateType.GettingUp,false)
			H:ChangeState(Enum.HumanoidStateType.Ragdoll)
			for _,v in pairs(H:GetPlayingAnimationTracks())do v:Stop(0)end
			
			for _,v in pairs(bot:GetDescendants()) do
				if v:IsA'Motor6D'and Module.Check(v.Name) then
					v.Enabled = false
				elseif v:IsA'BallSocketConstraint' or v:IsA("HingeConstraint") then
					v.Enabled = true
				end
			end
			task.wait(100)
			for _,part in pairs(bot:GetDescendants()) do
				if part:IsA("BasePart") then
					part.Anchored = true
				end
			end
			--wait(10)
			--H:SetStateEnabled(Enum.HumanoidStateType.GettingUp,true)
			--H:ChangeState(Enum.HumanoidStateType.GettingUp)

			--for _,v in pairs(bot:GetDescendants()) do
			--	if v:IsA'Motor6D' then
			--		v.Enabled = true
			--	elseif v:IsA'BallSocketConstraint' then
			--		v.Enabled = false
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
	["HumanoidRootPart"] = 	{15,-10,25},
	["LowerTorso"] = 		{15,-10,25},
	["UpperTorso"] = 		{15,-10,25},
	["Head"] = 				{15,-45,15},
	["LeftUpperArm"] = 		{70,-45,45},
	["LeftLowerArm"] = 		{"Hinge",-90,30},
	["LeftHand"] = 			{"Hinge",5,10},
	["RightUpperArm"] = 	{70,-45,45},
	["RightLowerArm"] = 	{"Hinge",-90,30},
	["RightHand"] = 		{"Hinge",5,10},
	["LeftUpperLeg"] = 		{45,-20,45},
	["LeftLowerLeg"] = 		{"Hinge",-90,30},
	["LeftFoot"] = 			{"Hinge",5,10},
	["RightUpperLeg"] = 	{45,-20,45},
	["RightLowerLeg"] = 	{"Hinge",-90,30},
	["RightFoot"] = 		{"Hinge",5,10},
}

Module.Joints = function(c)
	c.Humanoid.BreakJointsOnDeath = false
	c.Humanoid.RequiresNeck = false
	for _,v in pairs(c:GetDescendants()) do
		if v:IsA("Motor6D")and Module.Check(v.Name)then
			local b = nil
			if bodyJoinInfo[v.Part1.Name] and bodyJoinInfo[v.Part1.Name][1] == "Hinge" then
				b = Instance.new("HingeConstraint")
				b.LowerAngle = bodyJoinInfo[v.Part1.Name][2]
				b.UpperAngle = bodyJoinInfo[v.Part1.Name][3]
			elseif bodyJoinInfo[v.Part1.Name] then
				b = Instance.new("BallSocketConstraint")
				b.TwistLimitsEnabled = true
				b.UpperAngle = bodyJoinInfo[v.Part1.Name][1]
				b.TwistLowerAngle = bodyJoinInfo[v.Part1.Name][2]
				b.TwistUpperAngle = bodyJoinInfo[v.Part1.Name][3]
			end
			if b then
				b.LimitsEnabled = true
				local a0,a1 = Instance.new("Attachment"),Instance.new("Attachment")
				a0.Parent,a1.Parent = v.Part0,v.Part1
				a0.Name,a1.Name = v.Part0.Name,v.Part1.Name
				b.Attachment0,b.Attachment1 = a0,a1
				a0.CFrame,a1.CFrame = v.c0,v.c1
				b.Enabled = false
				b.Parent = v.Part0
			end
		elseif v:IsA'BasePart' then
			v.CollisionGroup = "A"
			if v.Name == "HumanoidRootPart" then
				v.CollisionGroup = "B"
			elseif v.Name=="Head"then
				v.CanCollide = true
			end
		end
	end
end

return Module

