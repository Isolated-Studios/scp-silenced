local module = {}

--//Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")

--//Service Objects
local Events = ReplicatedStorage:WaitForChild("Events")
local Tooling = ReplicatedStorage:WaitForChild("Tooling")
local Tools = Tooling:WaitForChild("Tools")

--// Event Folders
local ViewmodelEvents = Events:WaitForChild("Viewmodel")
local ToolEvents = Events:WaitForChild("Tool")
local InteractionEvents = Events:WaitForChild("Interaction")

--//Events
local SoundEvent = ToolEvents:WaitForChild("SoundEvent")
local FlashGunEvent = ToolEvents:WaitForChild("FlashGun")

--//Tables
local TransparencyIgnoreIndex = {
	"Handle","FlashlightF","LaserF","SightF","ScopeF","Hitbox","Flash","AimPart","EjectPart"
}



function module.playSound (Sounds: Sound | Instance, SoundName: string?, parent: Instance, replicate: boolean, ApplyRandomPitch: boolean, pitch: number?)
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

return module
