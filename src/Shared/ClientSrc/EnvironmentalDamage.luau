local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CTF = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Tool"):WaitForChild("CommonToolFunctions"))
local Events = ReplicatedStorage:WaitForChild("Events")
local InteractionEvents = Events:WaitForChild("Interaction")
local ShatterEvent = InteractionEvents:WaitForChild("ShatterEvent")
local module = {}
function module.LoadChar(Character)
	local Humanoid = Character:WaitForChild("Humanoid")
	local ShatterFunction = ShatterEvent.OnClientEvent:Connect(function(HitPart,HitPosition,CasterCFrame)
		CTF.breakGlass(HitPosition,HitPart,CasterCFrame,true)
	end)
	Humanoid.Died:Once(function()
		ShatterFunction:Disconnect()
	end)
end
return module