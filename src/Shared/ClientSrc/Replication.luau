local module = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Modules = ReplicatedStorage:WaitForChild("Modules")
local Events = ReplicatedStorage:WaitForChild("Events")
local ToolEvents = Events:WaitForChild("Tool")
local CTF = require(Modules:WaitForChild("Tool"):WaitForChild("CommonToolFunctions"))
local FlashGunEvent = ToolEvents:WaitForChild("FlashGun")
local MakeTracerEvent = ToolEvents:WaitForChild("MakeTracer")
local SoundEvent =ToolEvents:WaitForChild("SoundEvent")
local ParticleEvent = ToolEvents:WaitForChild("ParticleEvent")

function module.Init()
	FlashGunEvent.OnClientEvent:Connect(function(FlashPoint,flashLight)
		CTF.flashGun(FlashPoint,flashLight)
	end)
	MakeTracerEvent.OnClientEvent:Connect(function(Tool,Origin,Direction,TravelSpeed,params,MaxDistance,Acceleration,BulletTemplate,Character,isPellet,randomValue)
		CTF.castBullet(Tool,Origin,Direction,TravelSpeed,MaxDistance,Acceleration,BulletTemplate,Character,isPellet,randomValue)
	end)
	SoundEvent.OnClientEvent:Connect(function(SoundToPlay, ParentToSound, ApplyRandomPitch)
		CTF.playSound(SoundToPlay, nil, ParentToSound, false, ApplyRandomPitch)
	end)
	ParticleEvent.OnClientEvent:Connect(function(particleTable)
		for _,particle in pairs(particleTable) do
			if particle:IsA("ParticleEmitter") then
				particle:Emit(particle:GetAttribute("EmitCount") or 0)
			end
		end
	end)
end

return module
