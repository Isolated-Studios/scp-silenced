local module = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Events = ReplicatedStorage.Events
local SoundEvent = Events.Tool.SoundEvent

function onSoundEvent(PlayerToIgnore, SoundToPlay, ParentToSound, ApplyRandomPitch)
	for _,Players in pairs(game.Players:GetPlayers()) do
		if Players ~= PlayerToIgnore then
			if Players.Character and Players.Character.PrimaryPart and math.floor((Players.Character.PrimaryPart.Position-ParentToSound.Position).Magnitude) <= SoundToPlay.RollOffMaxDistance then
				SoundEvent:FireClient(Players, SoundToPlay, ParentToSound, ApplyRandomPitch)
			end
		end
	end
end

function module.Init()
	SoundEvent.OnServerEvent:Connect(onSoundEvent)
	
	for _,module in pairs(script:GetChildren()) do
		if module:IsA("ModuleScript") then
			require(module).Init()
		end
	end
end
return module
