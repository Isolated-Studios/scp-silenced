local module = {}
local Player = game.Players.LocalPlayer

--//Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local GamePlayers = game:GetService("Players")
local Debris = game:GetService("Debris")
local Lighting = game:GetService("Lighting")
local CollectionService = game:GetService("CollectionService")
local SequenceProvider = game:GetService("KeyframeSequenceProvider")

--//Service Objects
local Objects = ReplicatedStorage:WaitForChild("Objects")
local Modules = ReplicatedStorage:WaitForChild("Modules")
local Events = ReplicatedStorage:WaitForChild("Events")
local Tooling = ReplicatedStorage:WaitForChild("Tooling")
local TemporaryParts = workspace:WaitForChild("TemporaryParts")
local Tools = Tooling:WaitForChild("Tools")

--// Object Folders
local Tracers = Objects:WaitForChild("Tracers")
local GlassShatterObjects = Objects:WaitForChild("GlassShatterObjects")
local BulletHoleObjects = Objects:WaitForChild("BulletHoleObjects")
local primeBulletHole = BulletHoleObjects:WaitForChild("BulletHit")

local ToolModules = Modules:WaitForChild("Tool")

--// Event Folders
local ToolEvents = Events:WaitForChild("Tool")
local ViewmodelEvents = Events:WaitForChild("Viewmodel")
local InteractionEvents = Events:WaitForChild("Interaction")

--//Events
local ShatterEvent = InteractionEvents:WaitForChild("ShatterEvent")

local ResetIcons = ViewmodelEvents:WaitForChild("ResetIcons")

local SoundEvent = ToolEvents:WaitForChild("SoundEvent")
local Itemize = ToolEvents:WaitForChild("Itemize")
local FlashGunEvent = ToolEvents:WaitForChild("FlashGun")
local MakeTracerEvent = ToolEvents:WaitForChild("MakeTracer")
local DamageEvent = ToolEvents:WaitForChild("Damage")
local LandThrow = ToolEvents:WaitForChild("LandThrow")
local SetItemHolder = ToolEvents:WaitForChild("SetItemHolder")

--//Modules
local PartFracture = require(ToolModules:WaitForChild("GlassFractureModule"))
local FastCast = require(ToolModules:WaitForChild("FastCastRedux"))

--//Tables
local TransparencyIgnoreIndex = {
	"Handle","FlashlightF","LaserF","SightF","ScopeF","Hitbox","Flash","AimPart","EjectPart"
}
local MatToHole = {
	[Enum.Material.Concrete] = 		"NormalHit",
	[Enum.Material.Marble] = 		"NormalHit", 
	[Enum.Material.Granite] =		"NormalHit", 
	[Enum.Material.Brick] = 		"NormalHit", 
	[Enum.Material.Cobblestone] = 	"NormalHit", 
	[Enum.Material.Slate] = 		"NormalHit", 
	[Enum.Material.Metal] = 					"MetalHit", 
	[Enum.Material.DiamondPlate] = 				"MetalHit", 
	[Enum.Material.CorrodedMetal] = 			"MetalHit", 
	[Enum.Material.Grass] = 		"NormalHit", 
	[Enum.Material.LeafyGrass] = 	"NormalHit", 
	[Enum.Material.Snow] = 			"NormalHit", 
	[Enum.Material.Ice] = 			"NormalHit", 
	[Enum.Material.Pebble] = 		"NormalHit", 
	[Enum.Material.Water] = 		"NormalHit", 
	[Enum.Material.Ground] =		"NormalHit", 
	[Enum.Material.Asphalt] = 		"NormalHit", 
	[Enum.Material.Basalt] = 		"NormalHit", 
	[Enum.Material.WoodPlanks] = 							"WoodHit", 
	[Enum.Material.Wood] = 									"WoodHit", 
	[Enum.Material.Fabric] = 		"NormalHit", 
	[Enum.Material.Air] = 			"NormalHit",
	[Enum.Material.SmoothPlastic] = "NormalHit", 
	[Enum.Material.Plastic] = 		"NormalHit", 
	[Enum.Material.Sand] = 			"NormalHit", 
	[Enum.Material.Sandstone] = 	"NormalHit", 
	[Enum.Material.Glass] = 					"MetalHit", 
	[Enum.Material.ForceField] = 				"MetalHit", 
	[Enum.Material.Mud] = 			"NormalHit",
	[Enum.Material.Foil] = 			"NormalHit", 
	[Enum.Material.CrackedLava] = 	"NormalHit", 
	[Enum.Material.Neon] = 			"NormalHit",
}

local function Reflect(surfaceNormal, bulletNormal)
	return bulletNormal - (2 * bulletNormal:Dot(surfaceNormal) * surfaceNormal)
end

local BulletDespawn = 20
local lastRandomValue = nil
function module.createBulletHole (raycastResult,hitPerson,isPellet,randomValue)
	local HitPosition = raycastResult.Position
	local Normal = raycastResult.Normal
	local HitPart = raycastResult.Instance
	local HitMat = HitPart.Material
	local holeFolder = BulletHoleObjects[MatToHole[HitMat]]
	if hitPerson then
		holeFolder = BulletHoleObjects["BloodHit"]
	end
	local BulletHole = primeBulletHole:Clone()
	BulletHole.Parent = TemporaryParts
	BulletHole.Size = holeFolder:GetAttribute("Size")
	if isPellet then
		BulletHole.Size = Vector3.new(BulletHole.Size.X/3,BulletHole.Size.Y/3,BulletHole.Size.Z)
	else
		isPellet = 1
	end
	BulletHole.Position = HitPosition
	BulletHole.CFrame = CFrame.new(BulletHole.Position, BulletHole.Position+Normal)*(CFrame.Angles(0,0,Random.new():NextNumber(-180,180)))
	if CollectionService:HasTag(HitPart,"WeldSplatter") or HitPart.Parent and CollectionService:HasTag(HitPart.Parent,"WeldSplatter") then
		BulletHole.Anchored = false
		BulletHole.Weld.Part1 = HitPart
		BulletHole.Weld.Enabled = true
	else
		BulletHole.Anchored = true
	end
	BulletHole.BulletHoleDecal.Texture = holeFolder:GetAttribute("Image")
	for _,child in pairs(holeFolder:GetChildren()) do
		if child:IsA("Sound") and randomValue ~= lastRandomValue then
			local sound = child:Clone()
			sound.Parent = BulletHole
			sound:Play()
		elseif child:IsA("ParticleEmitter") then
			local particle = child:Clone()
			particle.Parent = BulletHole
			if particle:GetAttribute("PartColor") then
				particle.Color = ColorSequence.new(HitPart.Color)
			end
			if hitPerson and hitPerson:GetAttribute("BloodColor") then
				particle.Color = ColorSequence.new(hitPerson:GetAttribute("BloodColor"))
			end
			particle:Emit(math.floor(particle:GetAttribute("EmitCount")/isPellet))
		end
	end
	task.delay(BulletDespawn-1, function()
		for _,BBchildren in pairs(BulletHole:GetChildren()) do
			if BBchildren:IsA("Sound") or BBchildren:IsA("ParticleEmitter") then
				BBchildren:Destroy()
			end
		end
		BulletHole.Anchored = true
		--BulletHoleWeld:Destroy() 
		if BulletHole:FindFirstChild("BulletHoleDecal") then
			TweenService:Create(BulletHole.BulletHoleDecal,TweenInfo.new(1,Enum.EasingStyle.Linear),{Transparency = 1}):Play()
		end
		task.wait(1)
		BulletHole:Destroy()
		--BulletHoles:ReturnPart(BulletHole)
	end)
	lastRandomValue = randomValue
end

local DropParams = RaycastParams.new()
DropParams.FilterType = Enum.RaycastFilterType.Exclude

local bulletParams = RaycastParams.new()
bulletParams.FilterDescendantsInstances = {}
bulletParams.FilterType = Enum.RaycastFilterType.Exclude

CasterBehavior = FastCast:newBehavior()
CasterBehavior.RaycastParams = {}
CasterBehavior.MaxDistance = 9000
CasterBehavior.Acceleration = Vector3.new(0, -workspace.Gravity, 0)
CasterBehavior.CosmeticBulletTemplate = Tracers:WaitForChild("BasicTracer")
CasterBehavior.CosmeticBulletContainer = workspace.TracerCollection

BulletCaster = FastCast.new()
BulletCaster.RayHit:Connect(function(cast, raycastResult,segmentVelocity,cosmeticBulletObject)
	
	if cosmeticBulletObject:IsA("Model") then
		for _,part in pairs(cosmeticBulletObject:GetChildren()) do
			if part:IsA("BasePart") then part.Transparency = 1 end
		end
	end
	
	if cast.Throwable then
		if cast.Bounces and cast.Bounces > cast.MaxBounces or cast.MaxBounces == 0 then
			if not cast.Fake then
				local passableCFrame = cosmeticBulletObject.PrimaryPart:GetPivot() or nil
				LandThrow:FireServer(cast.Tool,raycastResult.Position,cast.Origin,cast.Character,raycastResult.Normal,passableCFrame)
			end
		else
			local newNormal = Reflect(raycastResult.Normal, segmentVelocity.Unit)
			local replicate = nil
			if not cast.Fake then
				replicate = "realButNoReplication"
			end
			
			local newCast = module.castBullet(
				cast.Tool, 
				raycastResult.Position+raycastResult.Normal*0.1,
				newNormal, 
				segmentVelocity.Magnitude*0.6, 
				cast.MaxDistance - cast.StateInfo.DistanceCovered, 
				cast:GetAcceleration(), 
				cast.RayInfo.CosmeticBulletObject.Name, 
				cast.Character, 
				cast.isPellet, 
				cast.randomValue,
				replicate)
			--newCast.RayInfo.CosmeticBulletObject = cast.RayInfo.CosmeticBulletObject
			--cast.RayInfo.CosmeticBulletObject = nil
			if not cast.Bounces then
				newCast.Bounces = 1
			else
				newCast.Bounces = cast.Bounces + 1
			end
			--table.insert(newCast.IgnoreList, raycastResult.Instance)
			if cosmeticBulletObject:FindFirstChild("Hitbox") and cosmeticBulletObject.Hitbox:FindFirstChild("ImpactSound") then
				cosmeticBulletObject.Hitbox.ImpactSound:Play()
			end
		end
	end
	
	
	local hitPerson = nil
	--if not cast.Fake then
		local HitPart = raycastResult.Instance
		if HitPart then
			local HitModel = HitPart.Parent
			if not HitModel:GetAttribute("isCharacter") and not HitModel:GetAttribute("Ragdoll") then
				HitModel = HitPart.Parent.Parent
			end
			local HitHumanoid = HitModel:FindFirstChildOfClass("Humanoid")
			if HitHumanoid then
				if not cast.Fake then
					local Distance = math.round((cast.Origin-raycastResult.Position).Magnitude)
					DamageEvent:FireServer(cast.Tool,nil,HitHumanoid,HitPart,cast.Direction,Distance)
				end
				hitPerson = HitModel
			end
		end
	--end
	if not cast.Throwable then
		module.createBulletHole(raycastResult,hitPerson,cast.isPellet,cast.randomValue)
	end
end)

BulletCaster.CastTerminating:Connect(function(cast)
	local cosmeticBulletToDestroy = cast.RayInfo.CosmeticBulletObject
	Debris:AddItem(cosmeticBulletToDestroy,5)
end)

BulletCaster.LengthChanged:Connect(function(Cast,lastPoint,rayDir,displacement,segmentVelocity,cosmeticBulletObject)
	if cosmeticBulletObject:IsA("Model") and cosmeticBulletObject.PrimaryPart then
		local bulLength = cosmeticBulletObject.PrimaryPart.Size.Z/2
		local offset = CFrame.new(0,0,-(displacement - bulLength))
		TweenService:Create(cosmeticBulletObject.PrimaryPart, TweenInfo.new(0.03, Enum.EasingStyle.Linear), {CFrame = CFrame.lookAt(lastPoint, lastPoint + rayDir):ToWorldSpace(offset)}):Play()
	else
		local bulLength = cosmeticBulletObject.Size.Z/2
		local offset = CFrame.new(0,0,-(displacement - bulLength))
		TweenService:Create(cosmeticBulletObject, TweenInfo.new(0.03, Enum.EasingStyle.Linear), {CFrame = CFrame.lookAt(lastPoint, lastPoint + rayDir):ToWorldSpace(offset)}):Play()
	end
end)

function module.printcat()
    print(":3")
end

function module.getAllAnimationEventNames(animation): table
	local markers: table = {}
	if animation then
		local ks: KeyframeSequence = SequenceProvider:GetKeyframeSequenceAsync(animation.Animation.AnimationId)
		local function recurse(parent: Instance): void
			for _, child in pairs(parent:GetChildren()) do
				if (child:IsA("KeyframeMarker")) then
					table.insert(markers, tostring(child))
				end
				if (#child:GetChildren() > 0) then
					recurse(child)
				end
			end
		end
		recurse(ks)
	end
	return markers
end

function module.HideParts (Hive,Transparency)
	if Hive then
		for _,ToolParts in pairs(Hive:GetChildren()) do
			if ToolParts:IsA("BasePart") or ToolParts:IsA("MeshPart") then
				if not table.find(TransparencyIgnoreIndex,ToolParts.Name) then
					ToolParts.Transparency = Transparency
					ToolParts.CanCollide = false
					ToolParts.Massless = true
				end
			end
		end
	end
end

function module.playSound (Sounds:object,SoundName:string,parent:object,replicate:bool, ApplyRandomPitch:bool, pitch)
	assert(Sounds ~= nil, "Sound is nil.")
	local Sound = Sounds
	if SoundName then
		Sound = Sounds[SoundName]
	end
	assert(Sound:IsA("Sound") == true, `{Sound:GetFullName()} is not a Sound.`)
	
	local NewSound = Sound:Clone()
	NewSound.Parent = parent
	NewSound:Play()
	
	if pitch and replicate then
		NewSound.PlaybackSpeed = pitch
	end
	
	if ApplyRandomPitch then 
		NewSound.PlaybackSpeed = Random.new():NextNumber(NewSound.PlaybackSpeed - 0.1, NewSound.PlaybackSpeed + 0.1) 
	end
	Debris:AddItem(NewSound,NewSound.TimeLength)

	if replicate then
		SoundEvent:FireServer(Sound, NewSound.Parent, ApplyRandomPitch) 
	end
end

function module.breakGlass (HitPosition,HitPart,CasterCFrame,noevent)
	if HitPart:GetAttribute("Shatter") and not HitPart:GetAttribute("Shattered") then
		local RespawnTime = HitPart:GetAttribute("RespawnTime") or 60
		local Glass = HitPart:Clone()
		Glass.Parent = TemporaryParts
		Glass.CFrame = HitPart.CFrame
		Glass.CollisionGroup = "Items"
		local ogSize = HitPart.Size
		HitPart.Size = Vector3.new(0.001,0.001,0.001)
		HitPart.CanCollide = false
		PartFracture(Glass,HitPosition,CasterCFrame.LookVector*50)
		if not noevent then
			ShatterEvent:FireServer(HitPart,ogSize,HitPosition,CasterCFrame.LookVector*50)
			module.playSound(GlassShatterObjects,"BreakSound",HitPart,true,true)
		end
		task.delay(RespawnTime,function()
			HitPart.Size = ogSize
			HitPart.CollisionGroup = "Default"
			HitPart:SetAttribute("Shattered",nil)
			HitPart.CanCollide = true
		end)
	end
end

function module.dropItem (Character,Tool)
	DropParams.FilterDescendantsInstances = {Character}
	local HRP = Character:WaitForChild("HumanoidRootPart")
	local Humanoid = Character:WaitForChild("Humanoid")
	if Humanoid:GetAttribute("inAir") or Humanoid:GetAttribute("DisableEquip") then return end
	if Tool:GetAttribute("ToolName") and Tools:FindFirstChild(Tool:GetAttribute("ToolName")) then
		local ToolObjects = Tools[Tool:GetAttribute("ToolName")]
		module.playSound(ToolObjects.Sounds,"Drop",HRP,true,true)
	end
	if Character:FindFirstChildOfClass("Tool") and Character:FindFirstChildOfClass("Tool") == Tool then
		Humanoid:UnequipTools()
	end
	ResetIcons:Fire(Tool)
	
	if Tool:GetAttribute("ToolType") == 12 then
		SetItemHolder:FireServer(Tool,"Capacity",Tool.Holder.Capacity.Value)
	end
	
	local Origin = HRP.Position
	local HRPCFrame = HRP.CFrame
	local CastFailed = true
	local HorizontalRange = 3
	local VerticalRange = 5
	--Tool.Hitbox.Size.Z/2
	local raycast = workspace:Raycast(Origin,HRPCFrame.LookVector*HorizontalRange,DropParams)
	if raycast then
		local raycast2nd = workspace:Raycast(Vector3.new(raycast.Position.X+(Tool.Hitbox.Size.X/2)*raycast.Normal.X,raycast.Position.Y,raycast.Position.Z+(Tool.Hitbox.Size.Z/2)*raycast.Normal.Z),-HRPCFrame.UpVector*VerticalRange,DropParams)
		if raycast2nd then
			CastFailed = false
			Itemize:FireServer(Tool,Vector3.new(raycast2nd.Position.X,raycast2nd.Position.Y+(Tool.Hitbox.Size.Y/2),raycast2nd.Position.Z),HRP.Orientation.Y)
		end
	else
		local raycast2nd = workspace:Raycast((HRPCFrame+HRPCFrame.LookVector*HorizontalRange).Position,-HRPCFrame.UpVector*VerticalRange,DropParams)
		if raycast2nd then
			CastFailed = false
			Itemize:FireServer(Tool,Vector3.new(raycast2nd.Position.X,raycast2nd.Position.Y+(Tool.Hitbox.Size.Y/2),raycast2nd.Position.Z),HRP.Orientation.Y)
		end
	end
	if CastFailed then
		local raycast = workspace:Raycast(Origin,-HRPCFrame.UpVector*VerticalRange,DropParams)
		if raycast then
			Itemize:FireServer(Tool,Vector3.new(raycast.Position.X,raycast.Position.Y+(Tool.Hitbox.Size.Y/2),raycast.Position.Z),HRP.Orientation.Y)
		else
			Itemize:FireServer(Tool,Origin,HRP.Orientation.Y)
		end
	end
end

function module.flashGun (FlashPoint, flashLight, sendToServer)
	if FlashPoint then
		for _,particle in pairs(FlashPoint:GetChildren()) do
			if particle:IsA("ParticleEmitter") then
				particle:Emit(particle:GetAttribute("EmitCount"))
			end
		end
	end
	if flashLight then
		task.defer(function()
			flashLight.Enabled = true
			task.wait(0.1)
			flashLight.Enabled = false
		end)
	end
	
	if sendToServer then
		FlashGunEvent:FireServer(FlashPoint,flashLight)
	end
end

function module.castBullet (Tool,Origin,Direction,TravelSpeed,MaxDistance,Acceleration,BulletTemplate,Character,isPellet,randomValue,replicate)
	bulletParams.FilterDescendantsInstances = {CollectionService:GetTagged("Ignore"),Character,Tool}
	if not BulletTemplate then BulletTemplate = "BasicTracer" end
	if not MaxDistance then MaxDistance = 9000 end
	if not TravelSpeed then TravelSpeed = 3000 end
	if isPellet and isPellet == 1 then isPellet = nil end
	CasterBehavior.RaycastParams = bulletParams or {}
	CasterBehavior.MaxDistance = MaxDistance
	CasterBehavior.Acceleration = Acceleration or Vector3.new(0, -workspace.Gravity, 0)
	CasterBehavior.CosmeticBulletTemplate = Tracers[BulletTemplate]
	CasterBehavior.CosmeticBulletContainer = workspace.TracerCollection
	--BulletCaster.VisualizeCasts = true
	
	if not replicate and Tool:FindFirstChild("Handle") and Tool.Handle:FindFirstChild("Flash") then
		Origin = Tool.Handle.Flash.WorldPosition
	end
	
	local Cast = BulletCaster:Fire(Origin,Direction,TravelSpeed,CasterBehavior)
	Cast.Tool = Tool
	Cast.Direction = Direction
	Cast.isPellet = isPellet
	Cast.randomValue = randomValue
	Cast.Origin = Origin
	Cast.Character = Character
	Cast.TravelSpeed = TravelSpeed
	Cast.MaxDistance = MaxDistance
	Cast.Origin = Origin
	if Tool:GetAttribute("ToolSource") and Tool:GetAttribute("ToolSource") == "Throwable" then
		Cast.Throwable = true
	end
	if Tool:GetAttribute("ToolName") and Tools:FindFirstChild(Tool:GetAttribute("ToolName"))then
		local ToolObjects = Tools[Tool:GetAttribute("ToolName")]
		local Settings = require(ToolObjects.Settings)
		if Settings.FireThrowable or Cast.Throwable then
			Cast.Throwable = true
			Cast.MaxBounces = Settings.MaxBounces or 6
		end
	end
	if replicate and replicate ~= "realButNoReplication" then
		MakeTracerEvent:FireServer(Tool,Origin,Direction,TravelSpeed,bulletParams,MaxDistance,Acceleration,BulletTemplate,Character,isPellet,randomValue)
	elseif not replicate then
		Cast.Fake = true
	end
	return Cast
end

function module:getDistance(point1 : Vector3, point2 : Vector3)
	local distance
	if point1 and point2 then
		distance = (point1 - point2).Magnitude
	else
		warn("getDistance threw an error: No point1 or point2 provided.")
		return nil
	end
	return distance
end

return module