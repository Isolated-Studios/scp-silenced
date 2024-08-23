local module = {}
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Events = ReplicatedStorage.Events
local Modules = ReplicatedStorage.Modules
local Tooling = ReplicatedStorage.Tooling
local CharacterModules = Modules.Character
local CharacterEvents = Events.Character
local ToolEvents = Events.Tool
local Tools = Tooling.Tools
local DamageEvent = ToolEvents.Damage
local ReviveTool = ToolEvents.ReviveTool
local GoreEvent = CharacterEvents.GoreEvent
local DownedEvent = CharacterEvents.DownedEvent
local ReviveEvent = CharacterEvents.ReviveEvent
local HumanoidAttributeEvent = Events.Character.HumanoidAttribute
local DamageHandler = require(CharacterModules.DamageHandler)
local params = RaycastParams.new()
params.FilterType = Enum.RaycastFilterType.Exclude
params.FilterDescendantsInstances = {}

local validAttributes = {
	["Melee"] = {"Swinging"}
}

local function isObstructed(A, B)
	params.FilterDescendantsInstances = {A:FindFirstAncestorOfClass("Model"),B:FindFirstAncestorOfClass("Model")}
	local Direction = (B.Position - A.Position).Unit
	local Hit = workspace:FindPartOnRay(Ray.new(A.Position,Direction))--workspace:Raycast(A.Position,A.CFrame.LookVector*15,params)
	if Hit then
		return true
	else
		return false
	end
end

local function isValidAttribute(Source,Name)
	if validAttributes[Source] and table.find(validAttributes[Source],Name) then
		return true
	else
		return false
	end
end

function module.Init()
	DamageEvent.OnServerEvent:Connect(function(Player,Tool,Character,HitHumanoid,HitPart,Direction,Distance,noLimbDamageAdjust)
		if not HitHumanoid then return end
		local HitCharacter = HitHumanoid.Parent
		--if not isObstructed(Character.PrimaryPart,HitCharacter.PrimaryPart) then
			local ToolObjects = Tools[Tool:GetAttribute("ToolName")]
			local Settings = require(ToolObjects.Settings)
			local Damage = Settings.Damage
			if Distance and Settings.MidFallOffDist and Settings.LongFallOffDist and Settings.MidFallOffMult and Settings.LongFallOffMult then
				if Distance >= Settings.MidFallOffDist and Distance < Settings.LongFallOffDist then
					Damage = Damage*Settings.MidFallOffMult
				elseif Distance >= Settings.LongFallOffDist then
					Damage = Damage*Settings.LongFallOffMult
				end
			end
		DamageHandler.Damage(
			Settings.Damage,
			HitHumanoid,
			HitPart,
			Player,
			Settings.CanDown,
			true,
			Settings.HeadshotFactor or 0,
			Settings.AP or 0,
			true,
			Direction,
			Settings.GibChance,
			Settings.Sever,
			noLimbDamageAdjust,
			Settings.LegMultiplier
		)
		--end
	end)
	HumanoidAttributeEvent.OnServerEvent:Connect(function(Player,Humanoid,Name,Value)
		local Tool = Humanoid.Parent:FindFirstChildOfClass("Tool")
		if Tool and Tool:GetAttribute("ToolSource") and isValidAttribute(Tool:GetAttribute("ToolSource"),Name) then
			Humanoid:SetAttribute(Name,Value)
		end
	end)
	GoreEvent.OnServerEvent:Connect(function(Player,Constraint)
		if Constraint and Constraint:IsA("Constraint") and string.find(Constraint.Name,"Constraint") and Constraint.Parent.Parent:GetAttribute("Ragdoll") then
			Constraint.Enabled = false
		end
	end)
	DownedEvent.OnServerEvent:Connect(function(Player,Humanoid)
		if Humanoid:GetAttribute("Downed") then
			local Character = Humanoid.Parent
			Humanoid.Health = 0
		end
	end)
	ReviveEvent.OnServerEvent:Connect(function(Player,Character,RevivedCharacter,failRevive)
		local Humanoid = Character.Humanoid
		local RevivedHumanoid = RevivedCharacter.Humanoid
		Humanoid:SetAttribute("FreezeWalkSpeed",nil)
		RevivedHumanoid:SetAttribute("FreezeWalkSpeed",nil)
		RevivedHumanoid:SetAttribute("Reviving",0)
		if not failRevive then
			local ReviveHealth = 10
			RevivedCharacter:SetAttribute("freezePlayer",nil)
			RevivedCharacter:SetAttribute("interactable",nil)
			RevivedCharacter:SetAttribute("interactAnimId",nil)
			RevivedCharacter:SetAttribute("interactFinishEventId",nil)
			RevivedCharacter:SetAttribute("interactText",nil)
			RevivedCharacter:SetAttribute("interactTime",nil)
			RevivedCharacter:SetAttribute("maxRange",nil)
			RevivedCharacter:SetAttribute("NoHighlight",nil)
			RevivedHumanoid:SetAttribute("Downed",nil)
			RevivedHumanoid:SetAttribute("DownedOnceAlready",true)
			
			if Player.Character:FindFirstChildOfClass("Tool") and Player.Character:FindFirstChildOfClass("Tool"):GetAttribute("ToolName") then
				local Settings = require(Tools[Player.Character:FindFirstChildOfClass("Tool"):GetAttribute("ToolName")].Settings)
				if Settings.CanRevive then
					ReviveTool:FireClient(Player,RevivedCharacter)
					ReviveHealth = Settings.ReviveHealth or ReviveHealth
				end
			end
			RevivedHumanoid.Health = ReviveHealth
		else
			RevivedCharacter:SetAttribute("freezePlayer",false)
			RevivedCharacter:SetAttribute("interactable",true)
			RevivedCharacter:SetAttribute("interactAnimId",0)
			RevivedCharacter:SetAttribute("interactFinishEventId",4)
			RevivedCharacter:SetAttribute("interactText","REVIVE")
			RevivedCharacter:SetAttribute("interactTime",0)
			RevivedCharacter:SetAttribute("maxRange",10)
			RevivedCharacter:SetAttribute("NoHighlight",false)
			DownedEvent:FireAllClients(Character)
		end
	end)
end
return module
