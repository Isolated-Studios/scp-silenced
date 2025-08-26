local module = {}
local Player = game.Players.LocalPlayer
--//Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")

--//Service Objects
local Events = ReplicatedStorage.Events
local Tooling = ReplicatedStorage.Tooling
local Tools = Tooling.Tools

--// Event Folders
local ViewmodelEvents = Events.Viewmodel
local ToolEvents = Events.Tool

--//Events
local SoundEvent = ToolEvents.SoundEvent
local FlashGunEvent = ToolEvents.FlashGun

--//Tables
local TransparencyIgnoreIndex = {
	"Handle","FlashlightF","LaserF","SightF","ScopeF","Hitbox","Flash","AimPart","EjectPart"
}

function module.playSound (Sounds: Sound | Instance, SoundName: string?, parent: Instance, replicate: boolean, ApplyRandomPitch: boolean | table, Properties: table?)
	assert(Sounds ~= nil, "Sound is nil.")
	local Sound = Sounds
	if SoundName then --/ If SoundName is not nil, it'll treat Sounds as a folder, and look for SoundName in the folder.
		Sound = Sounds[SoundName]
	end
	assert(Sound:IsA("Sound") == true, `{Sound:GetFullName()} is not a Sound.`)

	local NewSound = Sound:Clone()
	NewSound.Parent = parent
	NewSound:Play()

	if Properties then
		if typeof(Properties) == "table" then
			for Property, Value in pairs(Properties) do
				if NewSound[Property] then
					NewSound[Property] = Value
				end
			end
		else
			warn("Property parameter of sound '"..Sound.Name.."' is not a table")
		end

	end

	if ApplyRandomPitch then
		if typeof(ApplyRandomPitch) == "table" then
			NewSound.PlaybackSpeed = Random.new():NextNumber(ApplyRandomPitch[1],ApplyRandomPitch[2])
		else
			NewSound.PlaybackSpeed = Random.new():NextNumber(NewSound.PlaybackSpeed - 0.1, NewSound.PlaybackSpeed + 0.1)
		end
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