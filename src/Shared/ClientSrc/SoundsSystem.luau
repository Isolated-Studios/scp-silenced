local module = {}
-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local Player = game:GetService("Players").LocalPlayer

-- Replicated Storage Folders
local PlayersFolder = ReplicatedStorage.Players

function module.Init()
	local TakeableData = PlayersFolder:WaitForChild(Player.UserId)
	local SoundData = TakeableData.Settings.Sound
	local MasterVolume = SoundData["Master Volume"]
	
	local function SoundEquation (SoundGroup, DataValue)
		SoundGroup.Volume = (SoundGroup:GetAttribute("MaxVolume")*(DataValue.Value/100)) * (MasterVolume.Value/100)
	end
	
	-- For all sound data values. If they change, their corresponding sound group's volume is changed based on their value 0-100 and MaxVolume attribute.
	for _,DataValue in pairs(SoundData:GetChildren()) do
		if DataValue ~= MasterVolume then
			local SoundGroup = SoundService[DataValue.Name]
			-- Set initial volume based on the data value and master volume.
			SoundEquation(SoundGroup, DataValue)
			-- Set when data is changed.
			DataValue.Changed:Connect(function()
				SoundEquation(SoundGroup, DataValue)
			end)
		else
			-- If master volume changes, update all sounds.
			DataValue.Changed:Connect(function()
				for _,DataValue in pairs(SoundData:GetChildren()) do
					if DataValue ~= MasterVolume then
						SoundEquation(SoundService[DataValue.Name], DataValue)
					end
				end
			end)
		end
	end
end

return module
