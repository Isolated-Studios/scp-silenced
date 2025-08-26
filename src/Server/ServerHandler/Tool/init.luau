local module = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Events = ReplicatedStorage.Events
local SoundEvent = Events.Tool.SoundEvent

function onSoundEvent(PlayerToIgnore: Player, SoundToPlay: Sound, ParentToSound: Instance, ApplyRandomPitch: boolean, SendingPlayerRecieves: boolean)
	for _,Player in pairs(game.Players:GetPlayers()) do
		if SendingPlayerRecieves or Player ~= PlayerToIgnore then
			SoundEvent:FireClient(Player, SoundToPlay, ParentToSound, ApplyRandomPitch)
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
