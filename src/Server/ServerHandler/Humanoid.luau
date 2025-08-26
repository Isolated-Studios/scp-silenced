local module = {}
local Players = game:GetService("Players")
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
	DamageEvent.OnServerEvent:Connect(function(
		Player: Player,
		Tool: Tool, -- or table
		Character: Character,
		HitHumanoid: Humanoid,
		HitPart: Part,
		Deathnote: number,
		Direction: Vector3,
		Distance: number,
		noLimbDamageAdjust: boolean
	)
		local Damage = nil
		local CanDown = nil
		local HeadshotFactor = 0
		local AP = 0
		local GibChance = nil
		local Sever = nil
		local LegMultiplier = nil
		local AnnihilationRange = nil
		
		if not HitHumanoid then return end
		local HitCharacter = HitHumanoid.Parent
		if not HitCharacter then return end
		--if not isObstructed(Character.PrimaryPart,HitCharacter.PrimaryPart) then
		if typeof(Tool) == "table" then
			if Player ~= Players:GetPlayerFromCharacter(HitCharacter) then return end
			Damage = Tool["Damage"] or nil
			CanDown = Tool["CanDown"] or false
			HeadshotFactor = Tool["HeadshotFactor"] or 0
			AP = Tool["AP"] or 0
			GibChance = Tool["GibChance"] or 0
			Sever = Tool["Sever"] or nil
			LegMultiplier = Tool["LegMultiplier"] or nil
			AnnihilationRange = Tool["AnnihilationRange"] or nil
			
		else
			local ToolObjects = Tools[Tool:GetAttribute("ToolName")]
			local Settings = require(ToolObjects.Settings)
			Damage = Settings.Damage
			CanDown = Settings.CanDown or false
			HeadshotFactor = Settings.HeadshotFactor or 0
			AP = Settings.AP or 0
			GibChance = Settings.GibChance
			Sever = Settings.Sever
			LegMultiplier = Settings.LegMultiplier
			AnnihilationRange = Settings.AnnihilationRange
			
			if Distance and Settings.MidFallOffDist and Settings.LongFallOffDist and Settings.MidFallOffMult and Settings.LongFallOffMult then
				if Distance >= Settings.MidFallOffDist and Distance < Settings.LongFallOffDist then
					Damage = Damage*Settings.MidFallOffMult
				elseif Distance >= Settings.LongFallOffDist then
					Damage = Damage*Settings.LongFallOffMult
				end
			end
		end
			
		DamageHandler.Damage(
			Damage, -- Damage, number
			HitHumanoid, --HitHumanoid, Humanoid
			HitPart, -- HitPart, Part
			Player, -- Killer, Player
			CanDown, -- DowningTime, number
			Deathnote, -- Deathnote, number
			true, -- Twitch, boolean
			HeadshotFactor or 0, -- HeadshotFactor, number
			AP, -- AP, number
			true, -- Blood, boolean
			Direction, -- Direction, Vector3
			GibChance, -- Gibchance, number
			Sever, -- Sever, boolean
			noLimbDamageAdjust, -- noLimbDamageAdjust, boolean
			LegMultiplier, -- LegMultiplier, number
			AnnihilationRange -- AnnihilationRange, table
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
