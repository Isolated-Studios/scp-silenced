local module = {}
local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Events = ReplicatedStorage:WaitForChild("Events")
local CharacterEvents = Events:WaitForChild("Character")
local Objects = ReplicatedStorage:WaitForChild("Objects")
local GoreFolder = Objects:WaitForChild("Gore")
local Gibs = GoreFolder:WaitForChild("Gibs")
local Modules = ReplicatedStorage:WaitForChild("Modules")
local BloodObjects = GoreFolder:WaitForChild("BloodObjects")
local GoreEvent = CharacterEvents:WaitForChild("GoreEvent")
local BloodEvent = CharacterEvents:WaitForChild("BloodEvent")
local BloodMod = require(Modules:WaitForChild("Character"):WaitForChild("BloodHandler"))
local BloodHandler = BloodMod.create(8,20,3,3)
local function transparencyPartFunction (model)
	for _,charparts in pairs(model:GetChildren()) do
		if charparts:IsA("BasePart") then
			charparts.Size = Vector3.new(0.001,0.001,0.001)
			charparts.Transparency = 1
		end
	end
end
local gibTable =
		{
			["Head"] = 			{"UpperTorso",		"HeadBloodAttachment",	"Head",			"Neck",			"Head",			"Hair"},

			["LeftUpperArm"] = 	{"UpperTorso",		"LeftBloodAttachment",	"LeftUpperArm",	"LeftShoulder",	"LeftUpperArm",	"LeftLowerArm",	"LeftHand"},
			["RightUpperArm"] = {"UpperTorso",		"RightBloodAttachment",	"RightUpperArm","RightShoulder","RightUpperArm","RightLowerArm","RightHand"},
			["RightLowerArm"] = {"RightUpperArm",	"BloodAttachment",		"RightUpperArm","RightLowerArm","RightLowerArm","RightHand"},
			["LeftLowerArm"] = 	{"LeftUpperArm",	"BloodAttachment",		"LeftUpperArm",	"LeftLowerArm",	"LeftLowerArm",	"LeftHand"},
			["RightHand"] = 	{"RightUpperArm",	"BloodAttachment",		"RightUpperArm","RightLowerArm","RightLowerArm","RightHand"},
			["LeftHand"] = 		{"LeftUpperArm",	"BloodAttachment",		"LeftUpperArm",	"LeftLowerArm",	"LeftLowerArm",	"LeftHand"},

			["LeftUpperLeg"] = 	{"LowerTorso",		"LeftBloodAttachment",	"LowerTorso",	"LeftUpperLeg",	"LeftUpperLeg",	"LeftLowerLeg",	"LeftFoot"},
			["RightUpperLeg"] = {"LowerTorso",		"RightBloodAttachment",	"LowerTorso",	"RightUpperLeg","RightUpperLeg","RightLowerLeg","RightFoot"},
			["RightLowerLeg"] = {"RightUpperLeg",	"BloodAttachment",		"RightUpperLeg","RightLowerLeg","RightLowerLeg","RightFoot"},
			["LeftLowerLeg"] = 	{"LeftUpperLeg",	"BloodAttachment",		"LeftUpperLeg",	"LeftLowerLeg",	"LeftLowerLeg",	"LeftFoot"},
			["RightFoot"] = 	{"RightUpperLeg",	"BloodAttachment",		"RightUpperLeg","RightLowerLeg","RightLowerLeg","RightFoot"},
			["LeftFoot"] = 		{"LeftUpperLeg",	"BloodAttachment",		"LeftUpperLeg",	"LeftLowerLeg",	"LeftLowerLeg",	"LeftFoot"},
		}

local partGibTable =
		{
			["Head"] = 			{"UpperTorso",		"TopGibPoint", 	  "GibEndNeck", "Head", 			"GibPoint", 	"NeckRagdoll"},
			["LeftUpperArm"] = 	{"UpperTorso",		"LeftGibPoint",   "GibEnd", 	"LeftUpperArm", 	"TopGibPoint", 	"LeftShoulderRagdoll"},
			["RightUpperArm"] = {"UpperTorso",		"RightGibPoint",  "GibEnd", 	"RightUpperArm",	"TopGibPoint", 	"RightShoulderRagdoll"},
			["RightLowerArm"] = {"RightUpperArm",	"BottomGibPoint", "GibEnd", 	"RightLowerArm", 	"GibPoint", 	"RightElbowRagdoll"},
			["LeftLowerArm"] = 	{"LeftUpperArm",	"BottomGibPoint", "GibEnd", 	"LeftLowerArm", 	"GibPoint", 	"LeftElbowRagdoll"},
			["RightHand"] = 	{"RightUpperArm",	"BottomGibPoint", "GibEnd", 	"RightLowerArm", 	"GibPoint", 	"RightElbowRagdoll"},
			["LeftHand"] = 		{"LeftUpperArm",	"BottomGibPoint", "GibEnd", 	"LeftLowerArm", 	"GibPoint", 	"LeftElbowRagdoll"},

			["LeftUpperLeg"] = 	{"LowerTorso",		"LeftGibPoint",	  "GibEnd", 	"LeftUpperLeg", 	"TopGibPoint", 	"LeftHipRagdoll"},
			["RightUpperLeg"] = {"LowerTorso",		"RightGibPoint",  "GibEnd", 	"RightUpperLeg",	"TopGibPoint", 	"RightHipRagdoll"},
			["RightLowerLeg"] = {"RightUpperLeg",	"BottomGibPoint", "GibEnd", 	"RightLowerLeg", 	"GibPoint", 	"RightKneeRagdoll"},
			["LeftLowerLeg"] = 	{"LeftUpperLeg",	"BottomGibPoint", "GibEnd", 	"LeftLowerLeg", 	"GibPoint", 	"LeftKneeRagdoll"},
			["RightFoot"] = 	{"RightUpperLeg",	"BottomGibPoint", "GibEnd", 	"RightLowerLeg", 	"GibPoint", 	"RightKneeRagdoll"},
			["LeftFoot"] = 		{"LeftUpperLeg",	"BottomGibPoint", "GibEnd", 	"LeftLowerLeg", 	"GibPoint", 	"LeftKneeRagdoll"},
		}
local function playRandomSound (Pool,newParent)
	local newSound = Pool:GetChildren()[math.random(1,#Pool:GetChildren())]:Clone()
	newSound.Parent = newParent
	newSound:Play()
	newSound.PlaybackSpeed = Random.new():NextNumber(newSound.PlaybackSpeed - 0.1, newSound.PlaybackSpeed + 0.1) 
	Debris:AddItem(newSound,newSound.TimeLength)
end
local function playBloodDestruction (bloodattachmentparent)
	task.defer(function()
		for i=1,math.random(20,40),1 do
			if bloodattachmentparent.Parent.Transparency >= 1 then break end 
			BloodHandler:ProjectBlood(bloodattachmentparent.WorldCFrame.UpVector * 300,bloodattachmentparent.WorldPosition,bloodattachmentparent.Parent.Parent,bloodattachmentparent.Parent.Parent,10)
			playRandomSound(BloodObjects.BloodSplat,bloodattachmentparent)
			if bloodattachmentparent.Parent.Transparency >= 1 then break end 
			task.wait((1.1^i)/15)
		end
	end)
end
local function coughBlood (HitHumanoid,bloodattachmentparent)
	for i=1,math.random(3,6),1 do
		if bloodattachmentparent.Parent.Transparency >= 1 then break end 
		BloodHandler:ProjectBlood(bloodattachmentparent.WorldCFrame.LookVector * 300,bloodattachmentparent.WorldPosition,bloodattachmentparent.Parent.Parent,bloodattachmentparent.Parent.Parent,10)
		playRandomSound(BloodObjects.Coughing,bloodattachmentparent)
		task.wait(0.2)
		playRandomSound(BloodObjects.BloodSplat,bloodattachmentparent)
		if bloodattachmentparent.Parent.Transparency >= 1 then break end 
		task.wait(math.random(1,2))
	end
end
local function createGibs (HitPart)
	local Region = Region3.new(HitPart.Position - (0.5 * HitPart.Size), HitPart.Position + (0.5 * HitPart.Size))
	local rX, rZ = Region.Size.X, Region.Size.Z
	for i=1,math.random(30,40),1 do
		local Gib = BloodObjects.Gibs:GetChildren()[math.random(1,#BloodObjects.Gibs:GetChildren())]:Clone()
		Gib.CollisionGroup = "Gibs"
		Gib.Parent = workspace.BloodCollection
		Gib.Position = HitPart.Position
		--Gib.Position = Vector3.new(math.random(-rX/2, rX/2), Gib.Position.Y, math.random(-rZ/2, rZ/2))
		Debris:AddItem(Gib,20)
		task.delay(20-1,function()
			TweenService:Create(Gib,TweenInfo.new(1,Enum.EasingStyle.Linear),{Transparency = 1,Size = Vector3.new(0.001,0.001,0.001)}):Play()
		end)
	end
end
local function getRagdoll (HitCharacter)
	local Ragdoll = nil
	local RagdollObjectValue = HitCharacter:FindFirstChild("Ragdoll")
	if RagdollObjectValue then
		Ragdoll = RagdollObjectValue.Value
	end
	return Ragdoll 
end

function module.Init()
	local GoreEventFunction = GoreEvent.OnClientEvent:Connect(function(HitPart,HitCharacter,Sever,Direction)
		if HitPart:GetAttribute("Gibbed") then return end
		--Sever = true
		local Ragdoll = HitCharacter
		if not HitCharacter:GetAttribute("Ragdoll") then
			Ragdoll = getRagdoll(HitCharacter)
		end
		if HitPart and Ragdoll and gibTable[HitPart.Name] then
			HitPart:SetAttribute("Gibbed",true)
			local PrimaryGibPoint = Ragdoll[partGibTable[HitPart.Name][1]][partGibTable[HitPart.Name][2]]
			local primeGib = Gibs[partGibTable[HitPart.Name][3]]
			if Sever and primeGib.Name == "GibEndNeck" then
				primeGib = Gibs["GibEndNeck2"]
			end
			if Ragdoll[partGibTable[HitPart.Name][1]].Transparency ~= 1 then
				local Gib = primeGib:Clone()
				Gib.Name = HitPart.Name.."GibEnd"
				Gib:PivotTo(PrimaryGibPoint.WorldCFrame)
				Gib.Parent = Ragdoll
				Gib.PrimaryPart:WaitForChild("PrimaryWeld").Part1 = Ragdoll[partGibTable[HitPart.Name][1]]
				if HitPart.Name == "Head" and not Sever then
					Gib.PrimaryPart:WaitForChild("PrimaryWeld").Part1 = Ragdoll[partGibTable[HitPart.Name][4]]
				end
			end
			if Sever then
				local PrimaryGibPoint = Ragdoll[partGibTable[HitPart.Name][4]][partGibTable[HitPart.Name][5]]
				local primeGib = Gibs[partGibTable[HitPart.Name][3]]
				if primeGib.Name == "GibEndNeck" then
					primeGib = Gibs["GibEndNeck2"]
				end
				local Gib = primeGib:Clone()
				Gib.Name = HitPart.Name.."GibEnd"
				Gib:PivotTo(PrimaryGibPoint.WorldCFrame)
				Gib.Parent = Ragdoll
				Gib.PrimaryPart:WaitForChild("PrimaryWeld").Part1 = Ragdoll[partGibTable[HitPart.Name][4]]
				for _,Constraint in pairs(Ragdoll[partGibTable[HitPart.Name][1]]:GetChildren()) do
					if Constraint and string.find(Constraint.Name,"Constraint") then
						if Constraint and Constraint.Attachment0.Parent.Name == partGibTable[HitPart.Name][1] and Constraint.Attachment1.Parent.Name == HitPart.Name then
							GoreEvent:FireServer(Constraint)
						end
					end
				end
				--if Direction then
				--	Ragdoll[partGibTable[HitPart.Name][4]]:ApplyImpulse(Direction*20)
				--end
				playBloodDestruction(PrimaryGibPoint)
			end
		end
		if HitPart.Name == "UpperTorso" and not HitCharacter:GetAttribute("Ragdoll") and Ragdoll:FindFirstChild("Humanoid") then
			coughBlood(Ragdoll.Humanoid,Ragdoll.Head.MouthGibPoint)
		end
		if HitPart and Ragdoll and gibTable[HitPart.Name] and Ragdoll[HitPart.Name].Transparency == 0 then
			local bloodattachmentparent = Ragdoll[gibTable[HitPart.Name][1]][gibTable[HitPart.Name][2]]
			for _,obj in pairs(BloodObjects.BloodParticles:GetChildren()) do
				if obj:IsA("ParticleEmitter") then
					local bloodObject = obj:Clone()
					bloodObject.Parent = bloodattachmentparent
					bloodObject:Emit(5)
					Debris:AddItem(bloodObject,5)
				end
			end
			playRandomSound(BloodObjects.BloodImpact,bloodattachmentparent)
			--createGibs(Ragdoll[gibTable[HitPart.Name][5]])
			if not Sever then
				for _,charparts in pairs(Ragdoll:GetChildren()) do
					if charparts:IsA("BasePart") and not charparts:GetAttribute("GibPart") then
						if gibTable[HitPart.Name][5] and string.find(charparts.Name,gibTable[HitPart.Name][5])
							or gibTable[HitPart.Name][6] and string.find(charparts.Name,gibTable[HitPart.Name][6])
							or gibTable[HitPart.Name][7] and string.find(charparts.Name,gibTable[HitPart.Name][7]) then
								charparts.Transparency = 1
							if charparts.Name == "Head" then 
								charparts.Mesh.MeshId = charparts.Mesh:GetAttribute("MeshId")
								charparts.Mesh.Offset = charparts.Mesh:GetAttribute("Offset")
								charparts.Size = Vector3.new(0.001,0.001,0.001)
								charparts.Transparency = 0
							end
						end
					elseif charparts:IsA("Model") and (not charparts:GetAttribute("GibPart") or charparts:GetAttribute("GibPart") and string.find(charparts.Name,gibTable[HitPart.Name][6])) then
						if gibTable[HitPart.Name][5] and string.find(charparts.Name,gibTable[HitPart.Name][5])
							or gibTable[HitPart.Name][6] and string.find(charparts.Name,gibTable[HitPart.Name][6])
							or gibTable[HitPart.Name][7] and string.find(charparts.Name,gibTable[HitPart.Name][7]) then
							transparencyPartFunction(charparts)
						end
					end
				end
			end
			playBloodDestruction(bloodattachmentparent)
		end
	end)

	local BloodEventFunction = BloodEvent.OnClientEvent:Connect(function(Direction,HitPartPosition,Caster,HitPartParent,Damage,deathBlood)	
		if not deathBlood then
			if not HitPartParent:GetAttribute("isCharacter") then
				HitPartParent = HitPartParent.Parent
			end
			BloodHandler:ProjectBlood(Direction,HitPartPosition,Caster,HitPartParent,Damage)
		else
			local Ragdoll = getRagdoll(Caster)
			if Ragdoll and Ragdoll:FindFirstChild("UpperTorso") then
				local GibPoint = Ragdoll.UpperTorso.CenterGibPoint
				task.wait(math.random(1,5))
				BloodHandler:ProjectBlood(GibPoint.WorldCFrame.UpVector * 300,GibPoint.WorldPosition,GibPoint.Parent.Parent,GibPoint.Parent.Parent,50,0.5,6)
			end
		end
	end)
end

return module