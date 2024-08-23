local module = {}
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Events = ReplicatedStorage.Events

local Tooling = ReplicatedStorage.Tooling
local Modules = ReplicatedStorage.Modules

local ToolingTools = Tooling.Tools
local ToolEvents = Events.Tool

local HealEvent = ToolEvents.Heal

local StatusEffects = require(Modules.Character.StatusEffects)

function module.Init()
	HealEvent.OnServerEvent:Connect(function(Player,Tool,CharacterToHeal,Durability,revived)
		local HumanoidToHeal = nil
		local healStatusEffect = nil
		local Settings = require(ToolingTools[Tool:GetAttribute("ToolName")].Settings)
		if Tool.Parent ~= Player.Character then return end
		if CharacterToHeal and CharacterToHeal:FindFirstChild("Humanoid") then
			HumanoidToHeal = CharacterToHeal.Humanoid
			if CharacterToHeal and CharacterToHeal:FindFirstChild("StatusEffects") then
				healStatusEffect = CharacterToHeal.StatusEffects
			end
			if Settings.HealAmount then
				local amountToActuallyHeal = HumanoidToHeal.MaxHealth - HumanoidToHeal.Health
				if amountToActuallyHeal > Settings.HealAmount or not Settings.HealthAsDurability then amountToActuallyHeal = Settings.HealAmount end
				if not revived then 				
					if Settings.HealTime then
						task.defer(function()
							for i=1,amountToActuallyHeal do
								if HumanoidToHeal.Health <= 0 then break end
								HumanoidToHeal.Health += 1
								task.wait(Settings.HealTime/Settings.HealAmount)
							end
						end)
					else
						HumanoidToHeal.Health += amountToActuallyHeal
					end
				end
				
				for _,name in pairs(Settings.DestroyStatusEffects) do
					StatusEffects.RemoveEffect(name,CharacterToHeal)
				end
				for name,data in pairs(Settings.StatusEffects) do
					StatusEffects.AddEffect(name,data.Power,data.Duration,CharacterToHeal)
				end
			end
		end
		if Durability == 0 then
			if Settings.HasEndMarker then
				Tool:SetAttribute("DisableEquip",true)
				task.wait(Settings.HasEndMarker or 0.1)
			end
			Tool:Destroy()
		end
	end)
end
return module
