local module = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Modules = ReplicatedStorage.Modules
local Events = ReplicatedStorage.Events
local ToolEvents = Events.Tool
local CTF = require(Modules.Tool.CommonToolFunctions)
local FlashGunEvent = ToolEvents.FlashGun
local MakeTracerEvent = ToolEvents.MakeTracer
local SoundEvent = ToolEvents.SoundEvent
local ParticleEvent = ToolEvents.ParticleEvent
local AnimationModifier = ToolEvents.AnimationModifier

local Player = game:GetService("Players").LocalPlayer

function module.Init()
	FlashGunEvent.OnClientEvent:Connect(function(FlashPoint,flashLight)
		CTF.flashGun(FlashPoint,flashLight)
	end)
	
	MakeTracerEvent.OnClientEvent:Connect(function(Tool,Origin,Direction,TravelSpeed,params,MaxDistance,Acceleration,BulletTemplate,Character,isPellet,randomValue)
		CTF.castBullet(Tool,Origin,Direction,TravelSpeed,MaxDistance,Acceleration,BulletTemplate,Character,isPellet,randomValue)
	end)
	
	SoundEvent.OnClientEvent:Connect(function(SoundToPlay, ParentToSound, ApplyRandomPitch)
		if Player.Character and Player.Character.PrimaryPart and ParentToSound.Position and
			math.floor((Player.Character.PrimaryPart.Position-ParentToSound.Position).Magnitude) <= SoundToPlay.RollOffMaxDistance then
			CTF.playSound(SoundToPlay, nil, ParentToSound, false, ApplyRandomPitch)
		end
	end)
	ParticleEvent.OnClientEvent:Connect(function(particleTable)
		for _,particle in pairs(particleTable) do
			if particle:IsA("ParticleEmitter") then
				particle:Emit(particle:GetAttribute("EmitCount") or 0)
			end
		end
	end)
	local AnimationModifierActions = {
		["Transparency"] = function(TargetPart,Information)
			TargetPart.Transparency = Information
		end,
	}
	AnimationModifier.OnClientEvent:Connect(function(Action,Information,Tool,Target)
		if Tool:FindFirstChild(Target) and AnimationModifierActions[Action] then
			AnimationModifierActions[Action](Tool[Target],Information)
		end
	end)
end

return module
