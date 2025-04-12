local module = {}

module.Effects = {
	["Example"]					 = {
		SpeedDebuff = 0;
		Damage = 0;
		DamageWait = 0;
		Absorption = 0;
		LightingTweenIn = 0;
		LightingTweenOut = 0;
		Icon = {
			Image = "rbxassetid://12613759260",
			Color = Color3.fromRGB(0, 0, 0),
		},	
		Vignette = {
			Color = Color3.fromRGB(0,0,0);
			Transparency = 0;
		},
		LoopSound = {
			SoundId = "rbxassetid://1842400831";
			Volume = 0.5;
			PlaybackSpeed = 1;
			TweenIn = 0.1;
			TweenOut = 0.1;
		}
	},
	
	["Bleed"]					 = {
		Damage = 1;
		DamageWait = 1;
		Icon = {
			Image = "rbxassetid://12613759260",
			Color = Color3.fromRGB(200, 0, 0),
		},	
	},
	["Blindness"]				 = {
		LightingTweenOut = 0.5;
		Icon = {
			Image = "rbxassetid://15289032856",
			Color = Color3.fromRGB(91, 98, 112),
		},	
		Vignette = {
			Color = Color3.fromRGB(42, 45, 52);
			Transparency = 0;
			TweenIn = 1;
			TweenOut = 1;
		},	
	},
	
	["Burning"]					 = {
		SpeedDebuff = 0;
		Damage = 2;
		DamageWait = 0.5;
		Icon = {
			Image = "rbxassetid://12859803012",
			Color = Color3.fromRGB(255, 85, 0),
		},	
		Vignette = {
			Color = Color3.fromRGB(255, 85, 0);
			Transparency = 0.5;
		},
	},
	
	["Daze"]					 = {
		Icon = {
			Image = "rbxassetid://12581519783",
			Color = Color3.fromRGB(24, 21, 12),
		},	
	},
	
	["Disorientation"]			 = {
		SpeedDebuff = 20;
		LightingTweenOut = 1;
		Icon = {
			Image = "rbxassetid://12581519783",
			Color = Color3.fromRGB(255, 235, 156),
		},	
		LoopSound = {
			SoundId = "rbxassetid://138078479";
			Volume = 0.5;
			PlaybackSpeed = 0.01;
			TweenIn = 0.1;
			TweenOut = 3;
		}
	},
	
	["Flashed"]					 = {
		LightingTweenOut = 1;
		Icon = {
			Image = "rbxassetid://15289033782",
			Color = Color3.fromRGB(255, 194, 195),
		},	
		LoopSound = {
			SoundId = "rbxassetid://4155293439";
			Volume = 0.5;
			PlaybackSpeed = 1;
			TweenIn = 0.1;
			TweenOut = 1;
		}
	},
	
	["Regeneration"]			 = {
		Damage = -2;
		DamageWait = 1;
		Icon = {
			Image = "rbxassetid://13263131467",
			Color = Color3.fromRGB(67, 200, 0),
		},	
	},
	
	["Stun"]					 = {
		Icon = {
			Image = "rbxassetid://15289033782",
			Color = Color3.fromRGB(245, 255, 156),
		},	
	},
	
	["Suffocation"]				 = {
		StaminaDamage = 1;
		StaminaDamageWait = 0.2;
		Icon = {
			Image = "rbxassetid://12830959502",
			Color = Color3.fromRGB(134, 145, 115),
		},	
		Vignette = {
			Color = Color3.fromRGB(255, 255, 255);
			Transparency = 0.8;
		},
	},
	
	["Vigor"]					 = {
		StaminaDamage = -25;
		SpeedDebuff = -5;
		LightingTweenIn = 3;
		LightingTweenOut = 1;
		Icon = {
			Image = "rbxassetid://13263126278",
			Color = Color3.fromRGB(0, 170, 255),
		},	
		Vignette = {
			Color = Color3.fromRGB(0, 0, 0);
			Transparency = 0;
			TweenIn = 1;
			TweenOut = 1;
		},
		LoopSound = {
			SoundId = "rbxassetid://9043365993";
			Volume = 0.5;
			PlaybackSpeed = 1;
			TweenIn = 3;
			TweenOut = 1;
			PitchWithPower = 0.25;
		}
	},
	["Absorption"]					 = {
		Absorption = 25;
		Decay = true;
		DecayStart = 0.5;
		DecayRate = 1;
		Icon = {
			Image = "rbxassetid://17269808100",
			Color = Color3.fromRGB(255, 210, 96),
		},	
	},
	
}

local numberToColor = {
	[2] = Color3.fromRGB(255, 255, 0),
	[3] = Color3.fromRGB(255, 136, 0),
	[4] = Color3.fromRGB(255, 0, 0),
	[5] = Color3.fromRGB(255, 0, 136),
	[6] = Color3.fromRGB(183, 0, 255),
	[7] = Color3.fromRGB(149, 0, 255),
	[8] = Color3.fromRGB(93, 0, 255),
	[9] = Color3.fromRGB(17, 0, 255),
	[10] = Color3.fromRGB(0, 255, 225),
}

local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")
local Modules = ReplicatedStorage.Modules
local EffectParticleEvent = ReplicatedStorage.Events.Character.EffectParticleEvent
local CircleFrames = require(Modules.UI.CircleFrames)

function module.AddEffect(StatusEffectName,Power,Duration,Character,Player)
	local NPC = false
	if Player and not Character then
		Character = Player.Character
	end
	if Character and not Player then
		Player = game.Players:GetPlayerFromCharacter(Character)
		if not Player then
			NPC = true
		end
	end
	if not Character then warn("Character nil when adding effect: "..StatusEffectName) return end
	
	local Humanoid = Character:WaitForChild("Humanoid")
	local StatusEffects = Character:FindFirstChild("StatusEffects")
	if not StatusEffects then return end
	local StatusEffectValueSample = game:GetService("ReplicatedStorage"):WaitForChild("Objects"):WaitForChild("StatusEffects"):WaitForChild("Sample")
	local StatusEffectValue = StatusEffectValueSample:Clone()
	
	for _,oldEffect in pairs(StatusEffects:GetChildren()) do
		if oldEffect:IsA("NumberValue") and oldEffect.Name == StatusEffectName then
			oldEffect:Destroy()
		end
	end
	
	StatusEffectValue.Name = StatusEffectName
	StatusEffectValue.Value = Power
	StatusEffectValue.Duration.Value = Duration
	
	StatusEffectValue.Parent = StatusEffects
	if not NPC and Player then
		local HUD = Player.PlayerGui:WaitForChild("HUD")
		local EffectCanvas = HUD:WaitForChild("EffectFrame")
		local EffectFrame = EffectCanvas:WaitForChild("MainFrame")
		local StatusEffectSample = EffectCanvas:WaitForChild("StatusEffectSample")
		local StatusEffectFrame = StatusEffectSample:Clone()
		local ProgressFrame = StatusEffectFrame:WaitForChild("Progress")
		local ProgressPercentage = ProgressFrame:WaitForChild("Percentage")
		StatusEffectFrame.Name = StatusEffectName
		
		for _,oldEffect in pairs(EffectFrame:GetChildren()) do
			if oldEffect:IsA("Frame") and oldEffect.Name == StatusEffectName then
				oldEffect:Destroy()
			end
		end
		
		if Power > 1 and Power < 11 then
			ProgressPercentage.ImageColor.Value = numberToColor[Power]
		end
		
		StatusEffectFrame.Parent = EffectFrame
		local icon = StatusEffectFrame.Progress.Icon
		icon.Image = module.Effects[StatusEffectName].Icon.Image
		icon.ImageColor3 = module.Effects[StatusEffectName].Icon.Color
		ProgressPercentage.Value = 100
		TweenService:Create(ProgressPercentage,TweenInfo.new(Duration,Enum.EasingStyle.Linear),{Value = 0}):Play()
		local PPChanged = ProgressPercentage.Changed:Connect(function(val)
			CircleFrames.Progress(ProgressFrame,ProgressPercentage,val)
		end)
		StatusEffectValue.Destroying:Once(function()
			PPChanged:Disconnect()
			StatusEffectFrame:Destroy()
		end)
	end
end

function module.HasEffect(StatusEffectName,Character,Player)
	local NPC = false
	if Player and not Character then
		Character = Player.Character
	end
	if Character and not Player then
		Player = game.Players:GetPlayerFromCharacter(Character)
		if not Player then
			NPC = true
		end
	end
	if not Character then warn("Character nil when adding effect: "..StatusEffectName) return end
	local Humanoid = Character:WaitForChild("Humanoid")
	local StatusEffects = Character:FindFirstChild("StatusEffects")
	if not StatusEffects then return end
	if StatusEffects:FindFirstChild(StatusEffectName) then
		return true
	end
end

function module.RemoveEffect(StatusEffectName,Character,Player)
	local NPC = false
	if Player and not Character then
		Character = Player.Character
	end
	if Character and not Player then
		Player = game.Players:GetPlayerFromCharacter(Character)
		if not Player then
			NPC = true
		end
	end
	if not Character then warn("Character nil when removing effect: "..StatusEffectName) return end
	local StatusEffects = Character:FindFirstChild("StatusEffects")
	if StatusEffects:FindFirstChild(StatusEffectName) then
		StatusEffects[StatusEffectName]:Destroy()
	end
end

function module.AddEffectParticles (Character: object, StatusEffectFolder: object, Replicating: bool)
	if not Character and not Character:FindFirstChild("UpperTorso") then return end
	local UpperTorso = Character.UpperTorso
	
	for _,particle in pairs(UpperTorso:GetChildren()) do
		if particle:IsA("ParticleEmitter") and particle.Name == StatusEffectFolder.Name then
			particle.Enabled = false
			Debris:AddItem(particle,particle.Lifetime.Max)
		end
	end
	
	if StatusEffectFolder:FindFirstChild("Particles") then
		for _,particle in pairs(StatusEffectFolder.Particles:GetChildren()) do
			if particle:IsA("ParticleEmitter") then
				local cloneParticle = particle:Clone()
				cloneParticle.Name = StatusEffectFolder.Name
				cloneParticle.Enabled = true
				cloneParticle.Parent = UpperTorso
			end
		end
	end
	
	if Replicating then
		EffectParticleEvent:FireServer(Character,StatusEffectFolder)
	end
end

function module.RemoveEffectParticles(Character: object, StatusEffectName: string, Replicating: bool)
	if not Character then return end
	local UpperTorso = nil
	local Dead = false
	
	local function removeParticles ()
		for _,particle in pairs(UpperTorso:GetChildren()) do
			if particle:IsA("ParticleEmitter") and particle.Name == StatusEffectName then
				particle.Enabled = false
				Debris:AddItem(particle,particle.Lifetime.Max)
			end
		end
	end
	
	if Character:FindFirstChild("Ragdoll") then
		UpperTorso = Character.Ragdoll.Value.UpperTorso
		Dead = true
		for _,charPart in pairs(Character.Ragdoll.Value:GetDescendants()) do
			if charPart:IsA("BasePart") then
				local H,S,V = charPart.Color:ToHSV()
				TweenService:Create(charPart,TweenInfo.new(5,Enum.EasingStyle.Linear,Enum.EasingDirection.Out),{Color = Color3.fromHSV(H,S,V/5)}):Play()
			end
		end
		task.delay(10, function()
			removeParticles()
		end)
	else
		UpperTorso = Character.UpperTorso
		removeParticles()
	end

	
	
	if Replicating then
		EffectParticleEvent:FireServer(Character,StatusEffectName)
	end
end

return module
