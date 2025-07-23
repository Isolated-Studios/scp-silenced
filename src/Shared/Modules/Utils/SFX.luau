local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SoundEvent = ReplicatedStorage.Events.Tool.SoundEvent

local SFXUtils = {}

function SFXUtils.playSound (Sounds: Sound | Instance, SoundName: string?, parent: Instance, replicate: boolean, ApplyRandomPitch: boolean | table, Properties: table?)
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
	Debris:AddItem(NewSound, NewSound.TimeLength)

	if replicate then
		SoundEvent:FireServer(Sound, NewSound.Parent, ApplyRandomPitch)
	end
end

return SFXUtils
