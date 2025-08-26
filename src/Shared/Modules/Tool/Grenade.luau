local module = {}
-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local CollectionService = game:GetService("CollectionService")
local Debris = game:GetService("Debris")
local Players = game:GetService("Players")

-- Replicated Storage Objects
local TemporaryParts = workspace:WaitForChild("TemporaryParts")
local Objects = ReplicatedStorage.Objects
local Events = ReplicatedStorage.Events
local Modules = ReplicatedStorage.Modules
local GrenadeObjects = Objects.GrenadeObjects
local ExplosionEffects = GrenadeObjects.ExplosionEffects
local SpreadTemples = GrenadeObjects.SpreadTemplates

local ToolModules = Modules.Tool
local CharacterModules = Modules.Character
local InteractionModules = Modules.Interaction

local ToolEvents = Events.Tool
local CharacterEvents = Events.Character

-- Events
local SoundEvent = ToolEvents.SoundEvent
local ParticleEvent = ToolEvents.ParticleEvent
local FlashGunEvent = ToolEvents.FlashGun
local FlashedEffectFunction = CharacterEvents.FlashedEffectFunction

-- Configs
local Configs = ReplicatedStorage.Configs
local GrenadeConfigs = Configs.Grenade

-- Modules
local CTF = require(ToolModules.CommonToolFunctions)
local StatusEffects = require(CharacterModules.StatusEffects)
local DamageHandler = require(CharacterModules.DamageHandler)
local ZoneModule = require(InteractionModules.Zone)
local TeamHandler = require(InteractionModules.TeamHandler)

-- Grenade Raycast
local grenadeParams = RaycastParams.new()
grenadeParams.FilterType = Enum.RaycastFilterType.Exclude

local beginningEffectFunctions = {
	["Stun"] = function (Settings,model,Player)
		local isOnScreen = FlashedEffectFunction:InvokeClient(Player,model:GetPivot().Position)
		if isOnScreen then
			StatusEffects.AddEffect("Flashed",1,3,nil,Player)
		end
	end,
}

local damageCalculate = {
	["Fragmentation"] = function (Distance,ZoneType,Settings)
		local Damage = 0
		if ZoneType == 1 then
			Damage = 200
		elseif ZoneType == 2 then
			Damage = 100 * (1 - (Distance/Settings.MidZone)^1.1)
		end
		return Damage
	end,
	["HE"] = function (Distance,ZoneType,Settings)
		local Damage = 0
		if ZoneType == 1 then
			Damage = 200
		elseif ZoneType == 2 then
			Damage = 100 * (1.5 - (Distance/Settings.MidZone))
		end
		return Damage
	end,
	["Stun"] = function (Distance,ZoneType,Settings)
		local Damage = 10
		return Damage
	end,
}

local function getCharactersFromRadius (radius,rootPosition)
	grenadeParams.FilterDescendantsInstances = {CollectionService:GetTagged("Ignore"),CollectionService:GetTagged("BeamIgnore")}
	local characterTable = {}
	for _,rootPart in pairs(CollectionService:GetTagged("RootPart")) do
		if math.round((rootPart.Position-rootPosition).Magnitude) <= radius then
			local distance =  math.round((rootPart.Position-rootPosition).Magnitude)
			local direction = (rootPart.Position-rootPosition).Unit
			local raycastResult = workspace:Raycast(rootPosition,direction*(distance+10),grenadeParams)
			if raycastResult and raycastResult.Instance and raycastResult.Instance.Parent and 
				(raycastResult.Instance.Parent == rootPart.Parent or 
					raycastResult.Instance.Parent.Parent and raycastResult.Instance.Parent.Parent == rootPart.Parent) then
				table.insert(characterTable,{rootPart.Parent, distance,raycastResult.Position})
			end
		end
	end
	return characterTable
end

local function getZone (Distance,LowZone,MidZone,FarZone)
	if Distance <= LowZone then
		return 1
	elseif Distance >= LowZone and Distance <= MidZone then
		return 2
	elseif Distance >= MidZone and Distance <= FarZone then
		return 3
	end
end

local function playExplosionEffect (Settings,model)
	task.defer(function()
		local explosionParticles = {}
		local explosionPart = ExplosionEffects[Settings.GrenadeEffect or "Fragmentation"]:Clone()
		explosionPart.Parent = TemporaryParts
		explosionPart.CFrame = model:GetPivot()
		task.wait(0.02)
		for _,explosionChild in pairs(explosionPart:GetChildren()) do
			if explosionChild:IsA("ParticleEmitter") then
				table.insert(explosionParticles,explosionChild)
			elseif explosionChild:IsA("Sound") then
				SoundEvent:FireAllClients(explosionChild, explosionPart, true)
			elseif explosionChild:IsA("Light") then
				FlashGunEvent:FireAllClients(nil, explosionChild, nil)
			end
		end
		ParticleEvent:FireAllClients(explosionParticles)
	end)
end

local function instantBlast (Settings,model)
	local GibChance = 0.5 or Settings.GibChance
	local PlayerId = model:GetAttribute("PlayerId")
	local Player = Players:GetPlayerByUserId(PlayerId)
	playExplosionEffect(Settings,model)
	local grenadePosition = model:GetPivot().Position
	local characterTable = getCharactersFromRadius(Settings.FarZone,model.PrimaryPart.Position)
	if Settings.DestroyWhenDetonated then
		model:Destroy()
	end
	
	for _,charInfo in pairs(characterTable) do
		local Damage = 0
		local canDown = 60
		local Character = charInfo[1]
		local Distance = charInfo[2]
		local raycastPosition = charInfo[3]
		if Players:GetPlayerFromCharacter(Character) and Player ~= Players:GetPlayerFromCharacter(Character) and TeamHandler.Check(Player,Players:GetPlayerFromCharacter(Character)) == 0 then
			return
		end
		
		local ZoneType = getZone(Distance,Settings.LowZone,Settings.MidZone,Settings.FarZone)
		Damage += damageCalculate[Settings.GrenadeType](Distance,ZoneType,Settings)
		if ZoneType == 1 then
			for name,data in pairs(Settings.LowZoneEffects) do
				StatusEffects.AddEffect(name,data.Power,data.Duration,Character)
			end
		elseif ZoneType == 2 then
			for name,data in pairs(Settings.MidZoneEffects) do
				StatusEffects.AddEffect(name,data.Power,data.Duration,Character)
			end
		elseif ZoneType == 3 then
			for name,data in pairs(Settings.FarZoneEffects) do
				StatusEffects.AddEffect(name,data.Power,data.Duration,Character)
			end
		end
		if Damage > 100 then
			canDown = nil
			GibChance = 2
		end
		
		local Humanoid = Character:FindFirstChildOfClass("Humanoid")
		local HitPart = Character:FindFirstChild("UpperTorso")
		local Twitch = true
		local Blood = true
		local Direction = CFrame.new(grenadePosition, raycastPosition).LookVector
		local Sever = false
		local AnnihilationRange = {1,5} or Settings.AnnihilationRange
		local GrenadeTypeToDeathnote = {
			["Fragmentation"] =  2,
			["HE"] =  3,
			["Stun"] =  7,
		}
		
		
		DamageHandler.Damage(
			Damage, -- Damage, number
			Humanoid, --HitHumanoid, Humanoid
			HitPart, -- HitPart, Part
			Player, -- Killer, Player
			nil, -- DowningTime, number
			GrenadeTypeToDeathnote[Settings.GrenadeType], -- Deathnote, number
			Twitch, -- Twitch, boolean
			nil, -- HeadshotFactor, number
			nil, -- AP, number
			Blood, -- Blood, boolean
			Direction, -- Direction, Vector3
			GibChance, -- Gibchance, number
			Sever, -- Sever, boolean
			nil, -- noLimbDamageAdjust, boolean
			nil, -- LegMultiplier, number
			AnnihilationRange -- AnnihilationRange, table
		)
		
		if Humanoid.Health <= 0 then --/ Flings the player if they die to the blast
			CTF.applyForce(HitPart,Direction*Damage*8,0.15)
		end
		
		if beginningEffectFunctions[Settings.GrenadeType] and Players:GetPlayerFromCharacter(Character) then
			beginningEffectFunctions[Settings.GrenadeType](Settings,model,Players:GetPlayerFromCharacter(Character))
		end
	end
end

local function spreadingBlast (Settings,model)
	playExplosionEffect(Settings,model)
	local Caster = Players:GetPlayerByUserId(model:GetAttribute("PlayerId"))
	local Template: BasePart = SpreadTemples[Settings.GrenadeEffect]
	local tweenInfo = TweenInfo.new(8, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out)
	local castParams = RaycastParams.new()
	local CenterPosition = model:GetPivot().Position
	castParams.FilterDescendantsInstances = CollectionService:GetTagged("IgnoreGrenadeDepthCast")
	CollectionService:GetInstanceAddedSignal("IgnoreGrenadeDepthCast"):Connect(function(obj)
		castParams:AddToFilter(obj)
	end)
	castParams.FilterType = Enum.RaycastFilterType.Exclude
	local radius = Template.Size.X/2
		--[[
			the radius of the circle is the width of the spreadpart,
			but the placement of the fire is on the Y axis which has a smaller height
		]]
	local heightCorrection = Template.Size.Y/2 - radius

	local spreadGrid = {}
	local smokeHit = {}
	local itsjoever = false
	local playerAffected = {}
	
	local templateModel = Instance.new("Model")
	templateModel.Name = Settings.GrenadeType.."Spread"
	templateModel.Parent = workspace:WaitForChild("TemporaryParts")
	local zone = ZoneModule.new(templateModel)
	zone.autoUpdate = true
	zone:setDetection("WholeBody")
	zone.playerEntered:Connect(function(plr)
		if itsjoever then return end
		if not table.find(smokeHit,plr) then
			table.insert(smokeHit,plr)
			--plr.Character.Humanoid:SetAttribute("InFire",true)
		end
	end)
	zone.playerExited:Connect(function(plr)
		if table.find(smokeHit,plr) then
			table.remove(smokeHit,table.find(smokeHit,plr))
			table.remove(playerAffected,table.find(playerAffected,plr))
			for name,data in pairs(Settings.ExitZoneEffects) do
				StatusEffects.AddEffect(name,data.Power,data.Duration,plr.Character)
			end
		end
	end)
	
	local function createFire(x, y, startY, maxDepth, originalPart)
		if not spreadGrid[x] then
			spreadGrid[x] = {}
		end

		local startPos = CenterPosition * Vector3.new(1, 0, 1) + Template.Size * Vector3.new(x, 0, y)
		if originalPart then
			local target = startPos + Vector3.new(0, originalPart.Position.Y, 0)
			local canPass = true
			local origin = originalPart.Position
			local rayResult = workspace:Raycast(origin, target - origin, castParams)
			if rayResult then
				origin = originalPart.CFrame:PointToWorldSpace(Vector3.new(originalPart.Size * 0.3, 0, 0))
				rayResult = workspace:Raycast(origin, target - origin, castParams)
				if rayResult then
					origin = originalPart.CFrame:PointToWorldSpace(-Vector3.new(originalPart.Size * 0.3, 0, 0))
					rayResult = workspace:Raycast(origin, target - origin, castParams)
					canPass = false
				end
			end
			-- 3 ugly nested ifs because im lazy

			if not canPass then
				spreadGrid[x][y] = true
				return
			end
		end

		local castResult = workspace:Spherecast(
			startPos + Vector3.new(0, radius + startY + 0.5, 0),
			radius,
			Vector3.new(0, -radius - maxDepth - 0.5, 0),
			castParams
		)
		local depth = 0
		if castResult then
			depth = castResult.Position.Y
			depth += heightCorrection
		else
			spreadGrid[x][y] = true
			return
		end

		local SpreadPart = Template:Clone()
		SpreadPart.Position = startPos + Vector3.yAxis * depth
		SpreadPart.Position = SpreadPart.Origin.WorldPosition
		SpreadPart.Parent = templateModel
		castParams:AddToFilter(SpreadPart)
		--zone = ZoneModule.new(templateModel)
		spreadGrid[x][y] = {SpreadPart, zone}
		return SpreadPart
	end

	task.defer(function()
		while not itsjoever do
			for _,hitplayer in pairs(smokeHit) do
				if not table.find(playerAffected,hitplayer) then
					table.insert(playerAffected,hitplayer)
					hitplayer.Character.Humanoid:SetAttribute("In"..Settings.GrenadeType,true)
					for name,data in pairs(Settings.EnterZoneEffects) do
						StatusEffects.AddEffect(name,data.Power,data.Duration,hitplayer.Character)
					end
					--if hitplayer.Character and hitplayer.Character:FindFirstChild("StatusEffects") then
						--if checkTeamDamage(Caster,hitplayer) then
						--	StatusEffects:SetAttribute("Burning",1)
						--	StatusEffects:WaitForChild("Duration"):SetAttribute("Burning",math.huge)

						--	if not hitplayer.Character.Humanoid.Parent:GetAttribute("TestRig") then
						--		Caster.Character.Humanoid:SetAttribute("InCombat",true)
						--		hitplayer.Character.Humanoid:SetAttribute("InCombat",true)
						--		hitplayer.Character.Humanoid:SetAttribute("Killer",Caster.Name)
						--	end

						--end
						--if hitplayer == Caster then
						--	hitplayer.Character:SetAttribute("BurningLingeringTag",nil)
						--else
						--	hitplayer.Character:SetAttribute("BurningLingeringTag",Caster.Team.Name)
						--end
					--end

				end
			end
			task.wait(0.1)
		end
	end)

	task.defer(function()
		local centralPart = createFire(0, 0, CenterPosition.Y + 2, 16)
		if centralPart:FindFirstChildOfClass("Sound") then
			centralPart:FindFirstChildOfClass("Sound"):Play()
		end
		if centralPart:FindFirstChild("LightPoint") then
			TweenService:Create(centralPart.LightPoint.PointLight, tweenInfo, {Brightness = 4}):Play()
		end
		-- // r = radius
		for r = 0.5, Settings.CellRadius or 3, 0.5 do
			for x, xfires in spreadGrid do
				for y, fire in xfires do
					if fire == true then continue end -- fire == true is a skipped slot, not an actual fire
					for _, dir in {{-1, 0}, {1, 0}, {0, -1}, {0, 1}} do
						local newX = x+dir[1]
						local newY = y+dir[2]
						if Vector2.new(newX, newY).Magnitude > r then continue end
						if not (spreadGrid[newX] and spreadGrid[newX][newY]) then
							local newFire = createFire(newX, newY, fire[1].Position.Y + 6, 12, fire[1])
							if newFire and newFire:FindFirstChild("LightPoint") then
								newFire.LightPoint:Destroy()
							end
						end
					end
				end
			end
			task.wait(Settings.SpreadRate or 0.5)
		end
		task.wait(Settings.Duration)
		if Settings.DestroyWhenDetonated then
			model:Destroy()
		end
		itsjoever = true
		for _, xfires in spreadGrid do
			for _, fire in xfires do
				if fire == true then continue end
				for _,gasParticles in pairs(fire[1]:GetChildren()) do
					if gasParticles:IsA("ParticleEmitter") then
						gasParticles.Rate = 0
					elseif gasParticles:IsA("Sound") then
						game:GetService("TweenService"):Create(gasParticles,TweenInfo.new(1),{Volume = 0}):Play()
					end
				end

				if fire[1]:FindFirstChild("LightPoint") then
					for _,gasLights in pairs(fire[1].LightPoint:GetChildren()) do
						if gasLights:IsA("PointLight") then
							game:GetService("TweenService"):Create(gasLights,TweenInfo.new(1),{Brightness = 0}):Play()
						end
					end
				end

			end
		end
		zone:destroy()
		for _,hitplayer in pairs(smokeHit) do
			if table.find(smokeHit,hitplayer) then
				table.remove(smokeHit,table.find(smokeHit,hitplayer))
				table.remove(playerAffected,table.find(playerAffected,hitplayer))
				for name,data in pairs(Settings.ExitZoneEffects) do
					StatusEffects.AddEffect(name,data.Power,data.Duration,hitplayer.Character)
				end
			end
		end
		Debris:AddItem(templateModel, Settings.DispelTime or 5)
	end)
end

local grenadeTable = {
	["Fragmentation"] = function(Settings,model)
		instantBlast(Settings,model)
	end,
	["HE"] = function(Settings,model)
		instantBlast(Settings,model)
	end,
	["Stun"] = function(Settings,model)
		instantBlast(Settings,model)
	end,
	["Incendiary"] = function(Settings,model)
		spreadingBlast(Settings,model)
	end,
	["Smoke"] = function(Settings,model)
		spreadingBlast(Settings,model)
	end,
	["Gas"] = function(Settings,model)
		spreadingBlast(Settings,model)
	end,
}

function module.Apply (grenadeType,model)
	if GrenadeConfigs:FindFirstChild(grenadeType) then
		task.defer(function()
			local Settings = require(GrenadeConfigs[grenadeType])
			model:SetAttribute("Grenade",true)
			task.wait(Settings.FuseTime)
			grenadeTable[Settings.GrenadeType](Settings,model)
		end)
	end
end

return module
