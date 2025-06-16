local module = {}
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Events = ReplicatedStorage.Events
local ToolEvents = Events.Tool
local Modules = ReplicatedStorage.Modules
local CTF = require(Modules.Tool.CommonToolFunctions)
local FlashGunEvent = ToolEvents.FlashGun
local MakeTracerEvent = ToolEvents.MakeTracer
local AnimationModifier = ToolEvents.AnimationModifier
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
	AnimationModifier.OnServerEvent:Connect(function(PlayerToIgnore,Action:string,Information:anything,Tool:Tool,Target:BasePart)
		if Players:GetPlayerFromCharacter(Tool.Parent) and Players:GetPlayerFromCharacter(Tool.Parent) == PlayerToIgnore then
			for _,otherPlayer in pairs(game.Players:GetPlayers()) do
				if otherPlayer ~= PlayerToIgnore then
					AnimationModifier:FireClient(otherPlayer,Action,Information,Tool,Target)
				end
			end
		end
	end)
end
return module
