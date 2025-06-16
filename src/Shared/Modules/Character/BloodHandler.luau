
--//Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")
local TweenService = game:GetService("TweenService")
local GamePlayers = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")

local Player = game.Players.LocalPlayer
local PlayerData = ReplicatedStorage:WaitForChild('Players')
--local PlayerBloodSettings = PlayerData:WaitForChild(Player.UserId):WaitForChild("PlayerSettings"):WaitForChild("Blood")
--local RealisticBloodSetting = PlayerBloodSettings:WaitForChild("RealisticBlood")

local Modules = ReplicatedStorage:WaitForChild("Modules")
local Objects = ReplicatedStorage:WaitForChild("Objects")
local Gore = Objects:WaitForChild("Gore")
local BloodObjects = Gore:WaitForChild("Blood")
local TemporaryParts = workspace:WaitForChild("Blood")
local RagdollCollection = workspace:WaitForChild("Corpses")
--\\



--//Modules
local FastCast = require(Modules:WaitForChild("Tool"):WaitForChild("FastCastRedux"))
local BLOOD	= {}

--\\

--//Raycast Objects
local RaycastFilterList = {RagdollCollection,CollectionService:GetTagged("Ignore")}

local raycastParams = RaycastParams.new()
raycastParams.FilterDescendantsInstances = RaycastFilterList
raycastParams.FilterType = Enum.RaycastFilterType.Exclude
--\\

--//Module Objects
local fastCaster = FastCast.new()

CasterBehavior =  FastCast:newBehavior()
fastCaster.VisualizeCasts = true
CasterBehavior.RaycastParams = raycastParams
CasterBehavior.AutoIgnoreContainer = true
CasterBehavior.MaxDistance = 100
CasterBehavior.Acceleration = Vector3.new(0, -workspace.Gravity, 0)
CasterBehavior.CosmeticBulletTemplate = Objects:WaitForChild("Tracers"):WaitForChild("BloodTracer")
CasterBehavior.CosmeticBulletContainer = workspace.TracerCollection
--\\

local MaxSize = 5


GamePlayers.PlayerAdded:Connect(function(plr)
	plr.CharacterAdded:Connect(function(char)
		table.insert(RaycastFilterList,char)
	end)
	plr.CharacterRemoving:Connect(function(char)
		table.remove(RaycastFilterList,table.find(RaycastFilterList,char))
	end)
end)

function BLOOD.create(r, dt, ua, da)
	local blood	= {
			Range = r or 7;
			DecayTime = dt or 20;
			UpwardsAngle = ua or 3;
			DownwardsAngle = da or 3;
		}
		function blood.ProjectBlood(self,RegDirection,Origin,Caster,HitCharacter,Damage,Force,Size)
			local GraphicsSettings = PlayerData[Player.UserId].Settings.Display
			if Player.Character and Player.Character.PrimaryPart and math.round((Player.Character.PrimaryPart.Position-Origin).Magnitude) > GraphicsSettings["Blood Cull Distance"].Value 
			and #TemporaryParts:GetChildren() >= GraphicsSettings["Max Blood"].Value then return end
			local function bloodTrail (Damage,Negative)
				local Amount = math.ceil(Damage/8)
				if Amount < 1 then
					Amount = 1
				end
				local Total = math.random(1,Amount)
				if #TemporaryParts:GetChildren()+Total >= GraphicsSettings["Max Blood"].Value then return end
				RaycastFilterList = {Caster,RagdollCollection,CollectionService:GetTagged("CharPart"),CollectionService:GetTagged("Ignore"),HitCharacter}
				raycastParams.FilterDescendantsInstances = RaycastFilterList
				for _=1,Total,1 do 
					local Direction = Vector3.new(RegDirection.X,RegDirection.Y,RegDirection.Z)
					if Negative then
						Direction = CFrame.Angles(
							(0.5 - math.random()) * 2 *.3,
							(0.5 - math.random()) * 2 *.3,
							(0.5 - math.random()) * 2 *.3) * - Direction
					else
						Direction = CFrame.Angles(
							(0.5 - math.random()) * 2 *.3,
							(0.5 - math.random()) * 2 *.3,
							(0.5 - math.random()) * 2 *.3) * Direction
					end
					
					task.defer(function()
						if fastCaster then
							local force = Random.new():NextNumber(30,35)
							if Negative then
								force = Random.new():NextNumber(10,15)
							end
							if Force then
								force = Force
							end
							local cast = fastCaster:Fire(Origin, Direction*100, force, CasterBehavior)
							cast.UserData.DecayTime = blood.DecayTime
							if Size then
								cast.UserData.Size = Size
							end
							if HitCharacter:GetAttribute("BloodColor") then
								cast.UserData.Color = HitCharacter:GetAttribute("BloodColor")
							end
						end
					end)
				end
			end
			bloodTrail(Damage)
			bloodTrail(Damage,true)
		end
	
	return blood
end

fastCaster.LengthChanged:Connect(function(cast, lastPoint, rayDir, displacement, _, cosmeticBulletObject)
	if cast.UserData.Color then
		cosmeticBulletObject.Trail.Color = ColorSequence.new(cast.UserData.Color)
	end
	local bulLength = cosmeticBulletObject.Size.Z/2
	local offset = CFrame.new(0,0,-(displacement - bulLength))
	TweenService:Create(cosmeticBulletObject, TweenInfo.new(0.03, Enum.EasingStyle.Linear), {CFrame = CFrame.lookAt(lastPoint, lastPoint + rayDir):ToWorldSpace(offset)}):Play()
end)

fastCaster.RayHit:Connect(function(cast, raycastResult)
	local HitPart = raycastResult.Instance
	local HitPosition = raycastResult.Position
	local Normal = raycastResult.Normal
	
	if HitPart.Parent:GetAttribute("isCharacter") or HitPart.Parent:IsA("Tool") or HitPart.Parent.Name == "MotorModel" then return end
	
	if HitPart.Parent ~= TemporaryParts and not HitPart.Parent:IsA("Tool") then
		local bloodFolder = BloodObjects
		local RandomSize = Random.new():NextNumber(0.1,1.5)
		--if math.random(1,12) == 12 then
		--	bloodFolder = BloodObjects2
		--	RandomSize = Random.new():NextNumber(1,3)
		--end
		local GraphicsSettings = PlayerData[Player.UserId].Settings.Display
		if #TemporaryParts:GetChildren() >= GraphicsSettings["Max Blood"].Value then return end
		local BloodPart = bloodFolder:GetChildren()[math.random(1, #bloodFolder:GetChildren())]:Clone()
		if cast.UserData.Color then
			BloodPart.Color = cast.UserData.Color
		end
		if cast.UserData.Size then
			RandomSize = cast.UserData.Size
		end
		if not cast.UserData.Size and RandomSize > 6.5 then 
			RandomSize = RandomSize*0.7 
		end
		
		--if #BloodCollection:GetChildren() >= 60 then
		--	BloodPart.Size = Vector3.new(RandomSize,RandomSize,0.06)--Random.new():NextNumber(0.02,0.1))
		--else
			BloodPart.Size = Vector3.new(RandomSize/8,RandomSize/8,Random.new():NextNumber(0.3,0.5))
			local FlatSize = BloodPart.Size.Z/8
			BloodPart:SetAttribute("FlatSize",FlatSize)
			TweenService:Create(BloodPart,TweenInfo.new(1),{Size = Vector3.new(RandomSize,RandomSize,FlatSize)}):Play()
			task.delay(1,function()
				BloodPart.Size = Vector3.new(RandomSize,RandomSize,FlatSize)
			end)
		--end

		BloodPart.Position = HitPosition
		BloodPart.CFrame = CFrame.new(BloodPart.Position, BloodPart.Position+Normal)*CFrame.Angles(0,0,Random.new():NextNumber(-180,180))

		if CollectionService:HasTag(HitPart,"WeldSplatter") or HitPart.Parent and CollectionService:HasTag(HitPart.Parent,"WeldSplatter") then
			BloodPart:FindFirstChild("BloodWeld").Part1 = HitPart
			BloodPart.Anchored = false
		end
		Debris:AddItem(BloodPart,cast.UserData.DecayTime)
		task.delay(cast.UserData.DecayTime-5, function()
			TweenService:Create(BloodPart,TweenInfo.new(5,Enum.EasingStyle.Linear),{Transparency = 1,Size = Vector3.new()}):Play()
		end)

		BloodPart.Parent = TemporaryParts
	elseif not HitPart:GetAttribute("Stunted") and HitPart.Size.X < MaxSize then
		local RandomSize = Random.new():NextNumber(0.05,0.08)
		if HitPart.Size.X < MaxSize then
			TweenService:Create(HitPart,TweenInfo.new(1),{Size = Vector3.new(HitPart.Size.X+RandomSize,HitPart.Size.Y+RandomSize,HitPart:GetAttribute("FlatSize") or HitPart.Size.Z)}):Play()
		end
	end
	
end)

fastCaster.CastTerminating:Connect(function(cast)
	local cosmeticBulletToDestroy = cast.RayInfo.CosmeticBulletObject
	Debris:AddItem(cosmeticBulletToDestroy,1)
end)

--\\

-- Return

return BLOOD