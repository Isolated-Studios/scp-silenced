local TweenModule = {}
-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Events
local TweenObjectEvent = ReplicatedStorage.Events.Interaction.TweenObjectEvent

function TweenModule.Tween (
	Object:Model,
	newCFrame:CFrame,
	GivenTweenInfo:table,
	moveOnServer:bool,
	Distance:number,
	animationName:string,
	newSize:Vector3
	
)
	TweenObjectEvent:FireAllClients(Object, newCFrame, GivenTweenInfo, Distance, animationName, newSize)
	if moveOnServer then
		task.wait(GivenTweenInfo["Time"])
		Object:PivotTo(newCFrame)
	end
end

return TweenModule
