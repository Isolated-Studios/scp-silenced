local module = {}

--//Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

--//Service Objects
local Objects = ReplicatedStorage.Objects
local Tooling = ReplicatedStorage.Tooling
local TemporaryParts = workspace:WaitForChild("TemporaryParts")
local Tools = Tooling.Tools
local Modules = ReplicatedStorage.Modules
local Events = ReplicatedStorage.Events

--// Object Folders
local Tracers = Objects.Tracers
local BulletHoleObjects = Objects.BulletHoleObjects
local primeBulletHole = BulletHoleObjects.BulletHit
local ToolModules = Modules.Tool
local GlassShatterObjects = Objects.GlassShatterObjects

--// Event Folders
local ToolEvents = Events.Tool
local InteractionEvents = Events.Interaction
local ViewmodelEvents = Events.Viewmodel
local InteractionEvents = Events.Interaction

--//Events
local LandThrow = ToolEvents.LandThrow
local DamageEvent = ToolEvents.Damage
local MakeTracerEvent = ToolEvents.MakeTracer
local ShatterEvent = InteractionEvents.ShatterEvent


--//Modules
local PartFracture = require(ToolModules.GlassFractureModule)
local FastCast = require(ToolModules.FastCastRedux)

local BulletDespawn = 20
local lastRandomValue = nil

local MatToHole = {
	[Enum.Material.Metal] = 			"MetalHit",
	[Enum.Material.DiamondPlate] = 		"MetalHit",
	[Enum.Material.CorrodedMetal] = 	"MetalHit",

	[Enum.Material.WoodPlanks] = 		"WoodHit",
	[Enum.Material.Wood] = 				"WoodHit",

	[Enum.Material.Glass] = 			"MetalHit",
	[Enum.Material.ForceField] = 		"MetalHit",
}


--/Start of functions

local function Reflect(surfaceNormal, bulletNormal) --/ Used to reflect trajectories (grenades)
	return bulletNormal - (2 * bulletNormal:Dot(surfaceNormal) * surfaceNormal)
end

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

BulletCaster.CastTerminating:Connect(function(cast) --/ Destroy tracer
	local cosmeticBulletToDestroy = cast.RayInfo.CosmeticBulletObject
	Debris:AddItem(cosmeticBulletToDestroy,5)
end)

BulletCaster.LengthChanged:Connect(function(Cast,lastPoint,rayDir,displacement,segmentVelocity,cosmeticBulletObject) --/ Tracer moving
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
			if not cast.Bounces then
				newCast.Bounces = 1
			else
				newCast.Bounces = cast.Bounces + 1
			end
			if cosmeticBulletObject:FindFirstChild("Hitbox") and cosmeticBulletObject.Hitbox:FindFirstChild("ImpactSound") then
				cosmeticBulletObject.Hitbox.ImpactSound:Play()
			end
		end
	end
	
	local hitPerson = nil
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
	if not cast.Throwable then
		module.createBulletHole(raycastResult,hitPerson,cast.isPellet,cast.randomValue)
	end
end)

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

function module.createBulletHole (raycastResult,hitPerson,isPellet,randomValue)
	local HitPosition = raycastResult.Position
	local Normal = raycastResult.Normal
	local HitPart = raycastResult.Instance
	local HitMat = HitPart.Material
	local holeFolder = BulletHoleObjects["NormalHit"]
	
	if MatToHole[HitMat] then
		holeFolder = BulletHoleObjects[MatToHole[HitMat]]
	end
	
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
		if BulletHole:FindFirstChild("BulletHoleDecal") then
			TweenService:Create(BulletHole.BulletHoleDecal,TweenInfo.new(1,Enum.EasingStyle.Linear),{Transparency = 1}):Play()
		end
		task.wait(1)
		BulletHole:Destroy()
	end)
	
	lastRandomValue = randomValue
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

return module
