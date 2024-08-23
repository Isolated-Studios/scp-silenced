local module = {}
local Player = game.Players.LocalPlayer
local Camera = workspace.CurrentCamera
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local Debris = game:GetService("Debris")
local PlayerEffectsFolder = Player.PlayerScripts:WaitForChild("Effects")
local PrimeEffectLoop = PlayerEffectsFolder:WaitForChild("EffectLoop")
local EffectVignette = Player.PlayerGui:WaitForChild("HUD"):WaitForChild("Vignettes"):WaitForChild("EffectVignette")
local Modules = ReplicatedStorage:WaitForChild("Modules")
local Objects = ReplicatedStorage:WaitForChild("Objects")
local Events = ReplicatedStorage:WaitForChild("Events")
local CharacterEvents = Events:WaitForChild("Character")
local FlashedEffectFunction = CharacterEvents:WaitForChild("FlashedEffectFunction")
local RemoveEffectEvent = CharacterEvents:WaitForChild("RemoveEffectEvent")
local StatusEffectObjects = Objects:WaitForChild("StatusEffects")
local StatusEffectsModule = require(Modules:WaitForChild("Character"):WaitForChild("StatusEffects"))

local function checkMovement (Humanoid)
	if Humanoid and (Humanoid.MoveDirection).Magnitude > 0 then
		return true
	end
end

local lightingToProperties = {
	["ColorCorrectionEffect"] = {Brightness = 0, Contrast = 0, Saturation = 0, TintColor = Color3.fromRGB(255,255,255)},
	["BloomEffect"] = {Intensity = 0, Size = 0, Threshold = 0},
	["DepthOfFieldEffect"] = {FarIntensity = 0, FocusDistance = 0, InFocusRadius = 30, NearIntensity = 0},
	["BlurEffect"] = {Size = 0},
	["SunRaysEffect"] = {Intensity = 0, Spread = 0},
}

local saveOriginalLightingProperties = {
	["ColorCorrectionEffect"] = function(lo)
		return {Brightness = lo.Brightness, Contrast = lo.Contrast, Saturation = lo.Saturation, TintColor = lo.TintColor}
	end,
	["BloomEffect"] = function(lo)
		return {Intensity = lo.Intensity, Contrast = lo.Contrast, Size = lo.Size, Threshold = lo.Threshold}
	end,
	["DepthOfFieldEffect"] = function(lo)
		return {FarIntensity = lo.FarIntensity, FocusDistance = lo.FocusDistance, InFocusRadius = lo.InFocusRadius, NearIntensity = lo.NearIntensity}
	end,
	["BlurEffect"] = function(lo)
		return {Size = lo.Size}
	end,
	["SunRaysEffect"] = function(lo)
		return {Intensity = lo.Intensity, Spread = lo.Spread}
	end,
}

local tweenSound = function (effect,destroying)
	if StatusEffectsModule.Effects[effect.Name].LoopSound then
		local sound = StatusEffectsModule.Effects[effect.Name].LoopSound 
		if not destroying then
			local EffectLoop = PrimeEffectLoop:Clone()
			EffectLoop.Name = effect.Name
			EffectLoop:SetAttribute("ActiveEffect",true)
			EffectLoop.TimePosition = 0
			EffectLoop.SoundId = sound.SoundId
			EffectLoop.Volume = 0
			EffectLoop.PlaybackSpeed = sound.PlaybackSpeed
			if StatusEffectsModule.Effects[effect.Name].LoopSound.PitchWithPower then
				local pwp = StatusEffectsModule.Effects[effect.Name].LoopSound.PitchWithPower
				EffectLoop.PlaybackSpeed = sound.PlaybackSpeed+((pwp*effect.Value)-pwp)
			end
			EffectLoop.Parent = PlayerEffectsFolder
			TweenService:Create(EffectLoop,TweenInfo.new(sound.TweenIn or 0.05,Enum.EasingStyle.Linear,Enum.EasingDirection.Out),{Volume = sound.Volume or 0.5}):Play()
			EffectLoop:Play()
		else
			if PlayerEffectsFolder:FindFirstChild(effect.Name) then
				local EffectLoop = PlayerEffectsFolder[effect.Name]
				Debris:AddItem(EffectLoop,sound.TweenOut or 0.05)
				TweenService:Create(EffectLoop,TweenInfo.new(sound.TweenOut or 0.05,Enum.EasingStyle.Linear,Enum.EasingDirection.Out),{Volume = 0}):Play()
			end
		end
	end
end

local addLighting = function (statusEffectParent,effect,destroying)
	if statusEffectParent:FindFirstChild("Lighting") then
		local lightingChildren = statusEffectParent["Lighting"]
		if not destroying then
			for _,lo in pairs(lightingChildren:GetChildren()) do
				local lightingObject = lo:Clone()
				lightingObject:SetAttribute("Effect",effect.Name)
				if StatusEffectsModule.Effects[effect.Name].LightingTweenIn then
					local ogProperties = saveOriginalLightingProperties[lo.ClassName](lo)
					TweenService:Create(lightingObject,TweenInfo.new(0,Enum.EasingStyle.Linear),lightingToProperties[lo.ClassName]):Play()
					task.delay(0.01,function()
						TweenService:Create(lightingObject,TweenInfo.new(StatusEffectsModule.Effects[effect.Name].LightingTweenIn,Enum.EasingStyle.Linear),ogProperties):Play()
					end)
				end
				lightingObject.Parent = Lighting
			end
		else
			for _,lo in pairs(Lighting:GetChildren()) do
				if lo:GetAttribute("Effect") and lo:GetAttribute("Effect") == effect.Name then
					if lightingToProperties[lo.ClassName] and StatusEffectsModule.Effects[effect.Name].LightingTweenOut then
						TweenService:Create(lo,TweenInfo.new(StatusEffectsModule.Effects[effect.Name].LightingTweenOut,Enum.EasingStyle.Linear),lightingToProperties[lo.ClassName]):Play()
						Debris:AddItem(lo,StatusEffectsModule.Effects[effect.Name].LightingTweenOut)
					else
						lo:Destroy()
					end
				end
			end
		end
	end
end

local addVignette = function (effect,destroying)
	if StatusEffectsModule.Effects[effect.Name].Vignette then
		local vignette = StatusEffectsModule.Effects[effect.Name].Vignette
		if not destroying then
			local newEffectVignette = EffectVignette:Clone()
			newEffectVignette.Name = effect.Name
			newEffectVignette.Parent = EffectVignette.Parent.Parent
			newEffectVignette.ImageTransparency = 1
			newEffectVignette.ImageColor3 = vignette.Color or Color3.fromRGB(255,255,255)
			newEffectVignette.Image = vignette.Image or "rbxassetid://258368510"
			TweenService:Create(newEffectVignette,TweenInfo.new(vignette.TweenIn or 0.05,Enum.EasingStyle.Linear,Enum.EasingDirection.Out),{ImageTransparency = vignette.Transparency or 0}):Play()
		else
			if EffectVignette.Parent.Parent:FindFirstChild(effect.Name) then
				local newEffectVignette = EffectVignette.Parent.Parent[effect.Name]
				Debris:AddItem(newEffectVignette,vignette.TweenOut or 0.05)
				TweenService:Create(newEffectVignette,TweenInfo.new(vignette.TweenOut or 0.05,Enum.EasingStyle.Linear,Enum.EasingDirection.Out),{ImageTransparency = 1}):Play()
			end
		end
		
	end
end

local speedDebuff = function (effect,Humanoid,destroying)
	if StatusEffectsModule.Effects[effect.Name].SpeedDebuff then
		local SpeedDebuff = StatusEffectsModule.Effects[effect.Name].SpeedDebuff*effect.Value
		if not destroying then
			Humanoid:SetAttribute("SpeedDebuff",Humanoid:GetAttribute("SpeedDebuff")+SpeedDebuff)
		else
			Humanoid:SetAttribute("SpeedDebuff",Humanoid:GetAttribute("SpeedDebuff")-SpeedDebuff)
		end
	end
end

EffectFunctions = {
	["Suffocation"] = function(effect,Humanoid,destroying)
		local Effects = StatusEffectsModule.Effects[effect.Name]
		if not destroying then
			if Effects.StaminaDamageWait and Effects.StaminaDamage then
				while Humanoid.Health > 0 and effect.Parent do
					--if game.Players:GetPlayerFromCharacter(Humanoid.Parent) then
					--	SoundEvent:FireClient(game.Players:GetPlayerFromCharacter(Humanoid.Parent),StatusEffectFolder.Burning.Sounds.Splat, UpperTorso, true)
					--end
					Humanoid:SetAttribute("Stamina",math.clamp(Humanoid:GetAttribute("Stamina")-Effects.StaminaDamage,0,Humanoid:GetAttribute("MaxStamina")))
					task.wait(Effects.StaminaDamageWait)
				end
			end
		end
	end,
}

function module.LoadChar(Character)
	local Humanoid = Character:WaitForChild("Humanoid")
	local StatusEffects = Character:WaitForChild("StatusEffects")
	EffectVignette = Player.PlayerGui:WaitForChild("HUD"):WaitForChild("Vignettes"):WaitForChild("EffectVignette")
	local childAdded = StatusEffects.ChildAdded:Connect(function(effect)
		if effect:IsA("NumberValue") then
			task.defer(function()
				if EffectFunctions[effect.Name] then
					EffectFunctions[effect.Name](effect,Humanoid)
				end
			end)
			speedDebuff(effect,Humanoid)
			tweenSound(effect)
			addVignette(effect)
			addLighting(StatusEffectObjects[effect.Name],effect)
			
			if StatusEffectsModule.Effects[effect.Name] and not StatusEffectsModule.Effects[effect.Name].StaminaDamageWait and StatusEffectsModule.Effects[effect.Name].StaminaDamage then
				Humanoid:SetAttribute("Stamina",math.clamp(Humanoid:GetAttribute("Stamina")-(StatusEffectsModule.Effects[effect.Name].StaminaDamage*effect.Value),0,Humanoid:GetAttribute("MaxStamina")))
			end
			
			effect.Destroying:Once(function()
				speedDebuff(effect,Humanoid,true)
				tweenSound(effect,true)
				addVignette(effect,true)
				addLighting(StatusEffectObjects[effect.Name],effect,true)
				if EffectFunctions[effect.Name] then
					EffectFunctions[effect.Name](effect,Humanoid,true)
				end
			end)
		end
	end)
	Humanoid.Died:Once(function()
		childAdded:Disconnect()
		for _,EffectLoop in pairs(PlayerEffectsFolder:GetChildren()) do
			if EffectLoop:GetAttribute("ActiveEffect") then
				EffectLoop:Destroy()
			end
		end
		for _,lo in pairs(Lighting:GetChildren()) do
			if lo:GetAttribute("Effect") then
				lo:Destroy()
			end
		end
	end)
end

FlashedEffectFunction.OnClientInvoke = function(flashPos)
	local Character = Player.Character
	local StatusEffects = Character:WaitForChild("StatusEffects")
	local v,onScreen = Camera:WorldToScreenPoint(flashPos)
	if not onScreen then 
		return false
	end
	local screenPoint = {v.X, v.Y}
	local HUD = Player.PlayerGui:WaitForChild("HUD")
	local BlotchesPrime = HUD:WaitForChild("Blotches")
	
	local blotchSizeExtender = Random.new():NextNumber(1, 1.6)
	local rotation = math.random(0,359)
	local BlotchAfter = BlotchesPrime:WaitForChild("BlotchAfter"):Clone()
	local BlotchImage = BlotchesPrime:WaitForChild("BlotchImage"):Clone()
	BlotchAfter.Parent = HUD
	BlotchImage.Parent = HUD
	BlotchImage.Rotation = rotation
	BlotchImage.Size = UDim2.fromScale(BlotchImage.Size.X.Scale*blotchSizeExtender,BlotchImage.Size.Y.Scale*blotchSizeExtender)
	BlotchImage.Position = UDim2.fromOffset(screenPoint[1],screenPoint[2])
	BlotchAfter.Rotation = rotation
	BlotchAfter.Size = UDim2.fromScale(BlotchAfter.Size.X.Scale*blotchSizeExtender,BlotchAfter.Size.Y.Scale*blotchSizeExtender)
	BlotchAfter.Position = UDim2.fromOffset(screenPoint[1],screenPoint[2])
	BlotchAfter.Visible = true
	BlotchImage.Visible = true
	task.defer(function()
		task.wait(0.1)
		local effect = StatusEffects:FindFirstChild("Flashed")
		effect.Destroying:Once(function()
			local duration = StatusEffectsModule.Effects[effect.Name].BlotchDuration or 30
			TweenService:Create(BlotchAfter,TweenInfo.new(duration*effect.Value,Enum.EasingStyle.Linear),{ImageTransparency = 1}):Play()
			TweenService:Create(BlotchImage,TweenInfo.new(1,Enum.EasingStyle.Linear),{ImageTransparency = 1}):Play()
			Debris:AddItem(BlotchAfter,duration*effect.Value)
			Debris:AddItem(BlotchImage,1)
		end)
	end)
	return true
end


return module
