local module = {}
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Events = ReplicatedStorage.Events
local ToolEvents = Events.Tool
local Modules = ReplicatedStorage.Modules
local CTF = require(Modules.Tool.CommonToolFunctions)
local FlashGunEvent = ToolEvents.FlashGun
local MakeTracerEvent = ToolEvents.MakeTracer
function module.Init()
	FlashGunEvent.OnServerEvent:Connect(function(Player,FlashPoint,flashLight)
		for _,otherPlayer in pairs(game.Players:GetPlayers()) do
			if otherPlayer ~= Player then
				FlashGunEvent:FireClient(otherPlayer,FlashPoint,flashLight)
			end
		end
	end)
	MakeTracerEvent.OnServerEvent:Connect(function(Player,Tool,Origin,Direction,TravelSpeed,MaxDistance,Acceleration,BulletTemplate,Character,isPellet,randomValue)
		for _,otherPlayer in pairs(game.Players:GetPlayers()) do
			if otherPlayer ~= Player then
				MakeTracerEvent:FireClient(otherPlayer,Tool,Origin,Direction,TravelSpeed,MaxDistance,Acceleration,BulletTemplate,Character,isPellet,randomValue)
			end
		end
	end)
end
return module
