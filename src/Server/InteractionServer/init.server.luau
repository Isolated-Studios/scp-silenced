local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService('ServerStorage')
local TweenService = game:GetService('TweenService')

local Tooling = ReplicatedStorage.Tooling
local ToolingTools = Tooling.Tools
local Physical = Tooling.Physical

local Events = ReplicatedStorage.Events
local DoorConfigs = ReplicatedStorage.Configs.Doors

function getDistance(point1 : Vector3, point2 : Vector3)
	local distance
	if point1 and point2 then
		distance = (point1 - point2).Magnitude
	else
		return nil
	end
	return distance
end

local finishInteraction = Events.Interaction.FinishInteraction
local MedicalAmountCap = 2

local insecureIds = {4,5}

local InteractFunctions = {
    -- change this below, each new event needs a new id, make sure you add the , too
    -- template:
    -- change the '1' to a number that isnt already taken
    --[1] = function(interactObject, player) -- you should add a lable here so people can know what it does
    --    // code goes here
    --end, -- dontforget the comma
    
    [1] = function(interactObject, player) -- cargo box

	end,
	
	[2] = function(interactObject, player) -- basic button door
		if not interactObject:GetAttribute("interactable") then return end -- Might fix door spam bug?
		local function changeLightParts (LightModel,colorPicked)
			for _,light in pairs(LightModel:GetDescendants()) do
				if light:IsA("BasePart") or light:IsA("SurfaceLight") or light:IsA("PointLight") or light:IsA("SpotLight") then
					light.Color = colorPicked
				elseif light:IsA("ImageLabel") then
					light.ImageColor3 = colorPicked
				end
			end
		end
		
		local Allowed = true
		local Opened = interactObject.DoorConfigs.Opened
		local DoorSettings = require(DoorConfigs:FindFirstChild(interactObject:GetAttribute("DoorType")))
		local TweenObjectEvent = game:GetService("ReplicatedStorage").Events.Interaction.TweenObjectEvent
		
		local LeftDoor = interactObject["Door.L"]
		local RightDoor = interactObject["Door.R"]
		local LightParts = interactObject["LightParts"]
		local SoundPart = interactObject["SoundPart"]
		
		if player.Character and player.Character:FindFirstChild("Humanoid") then
			if DoorSettings.RequireKeycard then
				Allowed = false
				for _,keycard in pairs(player.Backpack:GetChildren()) do
					if keycard:GetAttribute("ToolType") == 5 then
						if DoorSettings.Cards and keycard:GetAttribute("SpecificID") and table.find(DoorSettings.Cards,keycard:GetAttribute("SpecificID")) or 
							not DoorSettings.Cards and DoorSettings.Clearance and keycard:GetAttribute("Clearance") >= DoorSettings.Clearance then
							Allowed = true
						end
					end
				end
				
				if player.Character:FindFirstChildOfClass("Tool") and player.Character:FindFirstChildOfClass("Tool"):GetAttribute("ToolType") == 5 then
					local keycard = player.Character:FindFirstChildOfClass("Tool")
					if DoorSettings.Cards and keycard:GetAttribute("SpecificID") and table.find(DoorSettings.Cards,keycard:GetAttribute("SpecificID")) or 
						not DoorSettings.Cards and DoorSettings.Clearance and keycard:GetAttribute("Clearance") >= DoorSettings.Clearance then
						Allowed = true
					end
				end
			end
			
			if SoundPart.button then SoundPart.button:Play() end
			
			if Allowed then
				--Playing = true
				interactObject:SetAttribute("interactable",false)
				if Opened.Value then
					Opened.Value = false
					interactObject:SetAttribute("interactText","open")
					TweenObjectEvent:FireAllClients(LeftDoor,LeftDoor.PrimaryPart.CFrame*CFrame.Angles(math.rad(-DoorSettings.LeftDoorOpen[3].X),math.rad(-DoorSettings.LeftDoorOpen[3].Y),math.rad(-DoorSettings.LeftDoorOpen[3].Z))+LeftDoor.PrimaryPart.CFrame[DoorSettings.LeftDoorOpen[1]]*-DoorSettings.LeftDoorOpen[2],DoorSettings.CloseSpeed,100,DoorSettings.CloseEasingStyle or Enum.EasingStyle.Linear,DoorSettings.CloseEasingDirection or Enum.EasingDirection.Out,"close")
					TweenObjectEvent:FireAllClients(RightDoor,RightDoor.PrimaryPart.CFrame*CFrame.Angles(math.rad(-DoorSettings.RightDoorOpen[3].X),math.rad(-DoorSettings.RightDoorOpen[3].Y),math.rad(-DoorSettings.RightDoorOpen[3].Z))+RightDoor.PrimaryPart.CFrame[DoorSettings.RightDoorOpen[1]]*-DoorSettings.RightDoorOpen[2],DoorSettings.CloseSpeed,100,DoorSettings.CloseEasingStyle or Enum.EasingStyle.Linear,DoorSettings.CloseEasingDirection or Enum.EasingDirection.Out,"close")
					changeLightParts(LightParts,DoorSettings.LightColors[2])
					SoundPart.door_close:Play()
					task.wait(DoorSettings.CloseSpeed)
					LeftDoor:PivotTo(LeftDoor.PrimaryPart.CFrame*CFrame.Angles(math.rad(-DoorSettings.LeftDoorOpen[3].X),math.rad(-DoorSettings.LeftDoorOpen[3].Y),math.rad(-DoorSettings.LeftDoorOpen[3].Z))+LeftDoor.PrimaryPart.CFrame[DoorSettings.LeftDoorOpen[1]]*-DoorSettings.LeftDoorOpen[2])
					RightDoor:PivotTo(RightDoor.PrimaryPart.CFrame*CFrame.Angles(math.rad(-DoorSettings.RightDoorOpen[3].X),math.rad(-DoorSettings.RightDoorOpen[3].Y),math.rad(-DoorSettings.RightDoorOpen[3].Z))+RightDoor.PrimaryPart.CFrame[DoorSettings.RightDoorOpen[1]]*-DoorSettings.RightDoorOpen[2])
				else
					Opened.Value = true
					interactObject:SetAttribute("interactText","close")
					TweenObjectEvent:FireAllClients(LeftDoor,LeftDoor.PrimaryPart.CFrame* CFrame.Angles(math.rad(DoorSettings.LeftDoorOpen[3].X),math.rad(DoorSettings.LeftDoorOpen[3].Y),math.rad(DoorSettings.LeftDoorOpen[3].Z))+LeftDoor.PrimaryPart.CFrame[DoorSettings.LeftDoorOpen[1]]*DoorSettings.LeftDoorOpen[2],DoorSettings.OpenSpeed,100,DoorSettings.OpenEasingStyle or Enum.EasingStyle.Linear,DoorSettings.OpenEasingDirection or Enum.EasingDirection.Out,"open")
					TweenObjectEvent:FireAllClients(RightDoor,RightDoor.PrimaryPart.CFrame* CFrame.Angles(math.rad(DoorSettings.RightDoorOpen[3].X),math.rad(DoorSettings.RightDoorOpen[3].Y),math.rad(DoorSettings.RightDoorOpen[3].Z))+RightDoor.PrimaryPart.CFrame[DoorSettings.RightDoorOpen[1]]*DoorSettings.RightDoorOpen[2],DoorSettings.OpenSpeed,100,DoorSettings.OpenEasingStyle or Enum.EasingStyle.Linear,DoorSettings.OpenEasingDirection or Enum.EasingDirection.Out,"open")
					changeLightParts(LightParts,DoorSettings.LightColors[1])
					SoundPart.door_open:Play()
					task.wait(DoorSettings.OpenSpeed)
					LeftDoor:PivotTo(LeftDoor.PrimaryPart.CFrame * CFrame.Angles(math.rad(DoorSettings.LeftDoorOpen[3].X),math.rad(DoorSettings.LeftDoorOpen[3].Y),math.rad(DoorSettings.LeftDoorOpen[3].Z)) + LeftDoor.PrimaryPart.CFrame[DoorSettings.LeftDoorOpen[1]] * DoorSettings.LeftDoorOpen[2])
					RightDoor:PivotTo(RightDoor.PrimaryPart.CFrame  * CFrame.Angles(math.rad(DoorSettings.RightDoorOpen[3].X),math.rad(DoorSettings.RightDoorOpen[3].Y),math.rad(DoorSettings.RightDoorOpen[3].Z)) + RightDoor.PrimaryPart.CFrame[DoorSettings.RightDoorOpen[1]] * DoorSettings.RightDoorOpen[2])
				end
				if DoorSettings.Cooldown and DoorSettings.Cooldown > 0 then
					task.wait(DoorSettings.Cooldown)
				end
				interactObject:SetAttribute("interactable",true)
				--Playing = false
			else
				--Playing = true
				interactObject:SetAttribute("interactable",false)
				SoundPart.error:Play()
				local ogColor = LightParts.Light.Color
				changeLightParts(LightParts,DoorSettings.LightColors[3])
				task.wait(DoorSettings.Cooldown)
				changeLightParts(LightParts,ogColor)
				interactObject:SetAttribute("interactable",true)
				--Playing = false
			end
		end
	end,
	
	[3] = function(interactObject, player) -- pick up
		if Physical:FindFirstChild(interactObject.Name) then
			interactObject:SetAttribute("interactable",false)
			local Tool = Physical[interactObject.Name]:Clone()
			if Tool:FindFirstChild("Holder") and interactObject:FindFirstChild("Holder") then
				Tool["Holder"]:Destroy()
				interactObject["Holder"].Parent = Tool
			end
			Tool:SetAttribute("NewTool",true)
			Tool.Parent = player.Backpack
			interactObject:Destroy()
		end
	end,
	
	[4] = function(interactObject, player) -- revive
		interactObject:SetAttribute("freezePlayer",nil)
		interactObject:SetAttribute("interactable",nil)
		interactObject:SetAttribute("interactAnimId",nil)
		interactObject:SetAttribute("interactFinishEventId",nil)
		interactObject:SetAttribute("interactText",nil)
		interactObject:SetAttribute("interactTime",nil)
		interactObject:SetAttribute("maxRange",nil)
		interactObject:SetAttribute("NoHighlight",nil)
		local reviveTime = 5
		local character = player.Character
		
		if player.Character:FindFirstChildOfClass("Tool") and player.Character:FindFirstChildOfClass("Tool"):GetAttribute("ToolName") then
			local Settings = require(ToolingTools[player.Character:FindFirstChildOfClass("Tool"):GetAttribute("ToolName")].Settings)
			reviveTime = Settings.ReviveTime or reviveTime
		end
		
		local revivePlayer = game.Players:GetPlayerFromCharacter(interactObject)
		local humanoid = character.Humanoid
		local reviveHumanoid = interactObject.Humanoid
		humanoid:SetAttribute("FreezeWalkSpeed",true)
		reviveHumanoid:SetAttribute("FreezeWalkSpeed",true)
		reviveHumanoid:SetAttribute("Reviving",reviveTime)
	end,
	
	[5] = function(interactObject, player)  -- execute
		local character = player.Character
		local humanoid = character.Humanoid
		local reviveHumanoid = interactObject.Humanoid
		humanoid:SetAttribute("FreezeWalkSpeed",true)
		reviveHumanoid:SetAttribute("FreezeWalkSpeed",true)
	end,
}


function onfinishInteraction(player, current,insecureId)
    if (current and (typeof(current) == "Instance")) then
        if ((player.Character) and (player.Character.PrimaryPart) and (getDistance(player.Character.PrimaryPart.Position, current.PrimaryPart.Position) <= current:GetAttribute("maxRange") * 1.5 )) then
			if current and InteractFunctions[current:GetAttribute("interactFinishEventId")] then
				if insecureId and table.find(insecureIds,insecureId) then
					InteractFunctions[insecureId](current, player)
				else
					InteractFunctions[current:GetAttribute("interactFinishEventId")](current, player)
				end
            end
        elseif current and (getDistance(player.Character.PrimaryPart.Position, current.PrimaryPart.Position) > current:GetAttribute("maxRange") * 3) then
            player:Kick("Impossible interaction at range.")
        end       
    end
end

finishInteraction.OnServerEvent:Connect(onfinishInteraction)