local TweenModule = {}
-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Events
local TweenObjectEvent = ReplicatedStorage.Events.Interaction.TweenObjectEvent

function TweenModule.Tween (
	Object:Model,
	newCFrame:CFrame,
	Time:number,
	moveOnServer:bool,
	Distance:number,
	EasingStyle:EasingStyle,
	EasingDirection:EasingDirection,
	animationName:string,
	newSize:Vector3
	
)
	TweenObjectEvent:FireAllClients(Object, newCFrame, Time, Distance, EasingStyle, EasingDirection, animationName, newSize)
	if moveOnServer then
		task.wait(Time)
		Object:PivotTo(newCFrame)
	end
end

return TweenModule
