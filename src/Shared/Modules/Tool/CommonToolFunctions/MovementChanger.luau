local MovementChanger = {}
local StopRunningEvent = game:GetService("ReplicatedStorage").Events.Character.StopRunning

function MovementChanger.stopRunning (DoesNotAffectInput: boolean)
	StopRunningEvent:Fire(DoesNotAffectInput)
end

return MovementChanger
