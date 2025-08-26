local module = {}
-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local Debris = game:GetService("Debris")
local Player = game:GetService("Players").LocalPlayer

-- Replicated Storage Folders
local PlayersFolder = ReplicatedStorage.Players

-- Other
local SendClientSoundEvent = ReplicatedStorage.Events.Interaction.SendClientSound
local SetMusicVolume = ReplicatedStorage.Events.Interaction.SetMusicVolume

function module.Init()
	local TakeableData = PlayersFolder:WaitForChild(Player.UserId)
	local SoundData = TakeableData.Settings.Sound
	local MasterVolume = SoundData["Master Volume"]

	local function SoundEquation (SoundGroup, DataValue)
		SoundGroup.Volume = (SoundGroup:GetAttribute("MaxVolume")*(DataValue.Value/100)) * (MasterVolume.Value/100)
	end

	-- For all sound data values. If they change, their corresponding sound group's volume is changed based on their value 0-100 and MaxVolume attribute.
	for _,DataValue in pairs(SoundData:GetChildren()) do
		if DataValue ~= MasterVolume and SoundService:FindFirstChild(DataValue.Name) then
			local SoundGroup = SoundService[DataValue.Name]
			-- Set initial volume based on the data value and master volume.
			SoundEquation(SoundGroup, DataValue)
			-- Set when data is changed.
			DataValue.Changed:Connect(function()
				SoundEquation(SoundGroup, DataValue)
			end)
		elseif DataValue == MasterVolume then
			-- If master volume changes, update all sounds.
			DataValue.Changed:Connect(function()
				for _,DataValue in pairs(SoundData:GetChildren()) do
					if DataValue ~= MasterVolume and SoundService:FindFirstChild(DataValue.Name) then
						SoundEquation(SoundService[DataValue.Name], DataValue)
					end
				end
			end)
		end
	end

	-- Server sent a signal to play a sound on the client.
	SendClientSoundEvent.OnClientEvent:Connect(function(Sound: Sound, Parent: Instance)
		local SoundToPlay = Sound:Clone()
		if not Parent then
			SoundToPlay.Parent = workspace
			SoundToPlay.RollOffMaxDistance = 10000
			SoundToPlay.RollOffMinDistance = 10000
		else
			SoundToPlay.Parent = Parent
		end
		SoundToPlay:Play()
		Debris:AddItem(SoundToPlay, SoundToPlay.TimeLength+2)
	end)

	-- Set the volume of the music list.
	SetMusicVolume.OnClientEvent:Connect(function(MusicList: Folder, Volume: number)
		for _,Sound in pairs(MusicList:GetChildren()) do
			if Sound:IsA("Sound") then
				Sound.Volume = Volume
			end
		end
	end)
end

return module
