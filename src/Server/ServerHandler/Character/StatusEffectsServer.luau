local module = {}
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")
local Players = game:GetService("Players")

local Modules = ReplicatedStorage.Modules
local Events = ReplicatedStorage.Events
local Objects = ReplicatedStorage.Objects
local StatusEffectFolder = Objects.StatusEffects
local CharacterEvents = Events.Character
local ToolEvents = Events.Tool

local EffectParticleEvent = CharacterEvents.EffectParticleEvent
local BloodEvent = CharacterEvents.BloodEvent
local RemoveEffectEvent = CharacterEvents.RemoveEffectEvent
local SoundEvent = ToolEvents.SoundEvent

local CharacterModules = Modules.Character
local StatusEffectsModule = require(CharacterModules.StatusEffects)
local DamageHandler = require(CharacterModules.DamageHandler)

local function checkMovement (Humanoid)
	if Humanoid and (Humanoid.MoveDirection).Magnitude > 0 then
		return true
	end
end

local EffectFunctions = {
	["Bleed"] = function(effect,Humanoid,destroying)
		if destroying then return end
		local Effects = StatusEffectsModule.Effects["Bleed"]
		local UpperTorso = Humanoid.Parent.UpperTorso
		local Player = game.Players:GetPlayerFromCharacter(Humanoid.Parent)
		if Effects.DamageWait then
			while Humanoid.Health > 0 and not effect:GetAttribute("Disabled") do
				DamageHandler.Damage(
					Effects.Damage, -- Damage, number
					Humanoid, --HitHumanoid, Humanoid
					nil, -- HitPart, Part
					nil, -- Killer, Player
					60, -- DowningTime, number
					8 -- Deathnote, number
				)
				BloodEvent:FireAllClients(-UpperTorso.CFrame.UpVector,UpperTorso.Position,Humanoid.Parent,Humanoid.Parent,Effects.Damage)
				if Player then
					SoundEvent:FireClient(Player,StatusEffectFolder.Bleed.Sounds,"Splat",UpperTorso,false,true)
				end
				if checkMovement(Humanoid) then
					task.wait(Effects.DamageWait/2/effect.Value)
				else
					task.wait(Effects.DamageWait/effect.Value)
				end
			end
		end
	end,
	["Burning"] = function(effect,Humanoid,destroying)
		if destroying then return end
		local Effects = StatusEffectsModule.Effects["Burning"]
		local UpperTorso = Humanoid.Parent.UpperTorso
		local Player = game.Players:GetPlayerFromCharacter(Humanoid.Parent)
		if Effects.DamageWait then
			while Humanoid.Health > 0 and not effect:GetAttribute("Disabled") do
				if Player then
					SoundEvent:FireClient(Player, StatusEffectFolder.Burning.Sounds.Burn, UpperTorso, true)
				end
				DamageHandler.Damage(
					Effects.Damage*effect.Value, -- Damage, number
					Humanoid, --HitHumanoid, Humanoid
					nil, -- HitPart, Part
					nil, -- Killer, Player
					60, -- DowningTime, number
					4 -- Deathnote, number
				)
				task.wait(Effects.DamageWait)
			end
		end
	end,
	["Regeneration"] = function(effect,Humanoid,destroying)
		if destroying then return end
		local Effects = StatusEffectsModule.Effects["Regeneration"]
		if Effects.DamageWait then
			while Humanoid.Health > 0 and not effect:GetAttribute("Disabled") do
				Humanoid.Health =  Humanoid.Health + -Effects.Damage*effect.Value
				task.wait(Effects.DamageWait)
			end
		end
	end,
	["Absorption"] = function(effect,Humanoid,destroying)
		if destroying then
			local Effects = StatusEffectsModule.Effects["Absorption"]
			Humanoid:SetAttribute("Absorption",math.clamp(Humanoid:GetAttribute("Absorption")-(Effects.Absorption*effect.Value),0,Humanoid:GetAttribute("MaxAbsorption") or 100))
		else
			local Effects = StatusEffectsModule.Effects["Absorption"]
			local Duration = effect.Duration.Value
			Humanoid:SetAttribute("Absorption",math.clamp(Effects.Absorption*effect.Value,0,Humanoid:GetAttribute("MaxAbsorption") or 100))
			if Effects.Decay then
				local StartEffectAmount = Humanoid:GetAttribute("Absorption")
				task.delay(Effects.DecayStart or 1, function()
					while effect and effect.Parent and effect.Parent.Parent and Humanoid.Health > 0 and not effect:GetAttribute("Disabled") do
						local goal = math.clamp(Humanoid:GetAttribute("Absorption")-(StartEffectAmount/((Duration-Effects.DecayStart)/Effects.DecayRate)),0,Humanoid:GetAttribute("MaxAbsorption") or 100)
						local difference = math.abs(Humanoid:GetAttribute("Absorption")-goal)
						for i=1,difference,1 do
							Humanoid:SetAttribute("Absorption",math.clamp(Humanoid:GetAttribute("Absorption")-1,0,Humanoid:GetAttribute("MaxAbsorption") or 100))
							task.wait(Effects.DecayRate/difference)
						end
						Humanoid:SetAttribute("Absorption",goal)
						--task.wait(Effects.DecayRate)
					end
				end)
			end
		end
	end,
}

function module.Init(Character)
	local StatusEffects = Character:WaitForChild("StatusEffects")
	local Humanoid = Character:WaitForChild("Humanoid")
	local childAdded = StatusEffects.ChildAdded:Connect(function(effect)
		if effect:IsA("NumberValue") then
			task.delay(effect.Duration.Value,function()
				effect:SetAttribute("Disabled",true)
				effect:Destroy()
			end)
			if effect and Humanoid.Health > 0 and not effect:GetAttribute("Disabled") and EffectFunctions[effect.Name] then
				EffectFunctions[effect.Name](effect,Humanoid)
			end
		end
	end)
	local childRemoved = StatusEffects.ChildRemoved:Connect(function(effect)
		if effect:IsA("NumberValue") then
			effect:SetAttribute("Disabled",true)
			if EffectFunctions[effect.Name] then
				EffectFunctions[effect.Name](effect,Humanoid,true)
			end
		end
	end)
	
	Humanoid.Died:Once(function()
		for _,effect in pairs(StatusEffects:GetChildren()) do
			if effect:IsA("NumberValue") then
				effect:SetAttribute("Disabled",true)
				if EffectFunctions[effect.Name] then
					EffectFunctions[effect.Name](effect,Humanoid,true)
				end
				effect:Destroy()
			end
		end
		childAdded:Disconnect()
		childRemoved:Disconnect()
	end)
end

RemoveEffectEvent.OnServerEvent:Connect(function(Player,EffectName)
	StatusEffectsModule.RemoveEffect(EffectName,nil,Player)
end)

EffectParticleEvent.OnServerEvent:Connect(function(Player,Character,Effect)
	if Player.Character and Player.Character == Character then
		for _,otherplayer in pairs(Players:GetPlayers()) do
			if otherplayer ~= Player then
				EffectParticleEvent:FireClient(otherplayer,Character,Effect)
			end
		end
	end
end)

return module
