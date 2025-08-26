local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService('ServerStorage')
local TweenService = game:GetService('TweenService')

local Tooling = ReplicatedStorage.Tooling
local ToolingTools = Tooling.Tools
local Physical = Tooling.Physical

local Events = ReplicatedStorage.Events
local DoorConfigs = ReplicatedStorage.Configs.Doors

local TweenModule = require(ReplicatedStorage.Modules.Interaction.TweenModule)

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

	[0] = function(interactObject, player) -- message (nothing on server)

	end,

	[1] = function(interactObject, player) -- cargo box

	end,

	[2] = function(interactObject, player) -- basic button door
		if not interactObject:GetAttribute("interactable") then return end -- Might fix door spam bug?
		local function changeLightParts (LightModel,colorPicked)
			if LightModel then
				for _,light in pairs(LightModel:GetDescendants()) do
					if light:IsA("BasePart") or light:IsA("SurfaceLight") or light:IsA("PointLight") or light:IsA("SpotLight") then
						light.Color = colorPicked
					elseif light:IsA("ImageLabel") then
						light.ImageColor3 = colorPicked
					end
				end
			end
		end

		local Allowed = true
		local Opened = interactObject.DoorConfigs.Opened
		local DoorSettings = require(DoorConfigs:FindFirstChild(interactObject:GetAttribute("DoorType")))
		local TweenObjectEvent = game:GetService("ReplicatedStorage").Events.Interaction.TweenObjectEvent

		local LeftDoor = interactObject:FindFirstChild("Door.L") or interactObject:FindFirstChild("Door")
		local RightDoor = interactObject:FindFirstChild("Door.R") or nil
		local LightParts = interactObject:FindFirstChild("LightParts") or nil
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
				interactObject:SetAttribute("interactable",false)
				if Opened.Value then
					Opened.Value = false
					interactObject:SetAttribute("interactText","open")
					changeLightParts(LightParts,DoorSettings.LightColors[2])
					SoundPart.door_close:Play()
					local DoorTweenInfo = {
						["Time"] = DoorSettings.CloseSpeed, 
						["EasingStyle"] = DoorSettings.CloseEasingStyle,
						["EasingDirection"] = DoorSettings.CloseEasingDirection
					}
					local LeftDoorFinal = LeftDoor.PrimaryPart.CFrame * CFrame.Angles(math.rad(-DoorSettings.LeftDoorOpen[3].X),math.rad(-DoorSettings.LeftDoorOpen[3].Y),math.rad(-DoorSettings.LeftDoorOpen[3].Z))+LeftDoor.PrimaryPart.CFrame[DoorSettings.LeftDoorOpen[1]]*-DoorSettings.LeftDoorOpen[2]
					TweenModule.Tween(
						LeftDoor,
						LeftDoorFinal,
						DoorTweenInfo,
						false,
						100,
						"close"
					)
					local RightDoorFinal = nil
					if RightDoor then
					 	RightDoorFinal = RightDoor.PrimaryPart.CFrame*CFrame.Angles(math.rad(-DoorSettings.RightDoorOpen[3].X),math.rad(-DoorSettings.RightDoorOpen[3].Y),math.rad(-DoorSettings.RightDoorOpen[3].Z))+RightDoor.PrimaryPart.CFrame[DoorSettings.RightDoorOpen[1]]*-DoorSettings.RightDoorOpen[2]
						TweenModule.Tween(
							RightDoor,
							RightDoorFinal,
							DoorTweenInfo,
							false,
							100,
							"close"
						)
					end
					task.wait(DoorSettings.CloseSpeed)
					LeftDoor:PivotTo(LeftDoorFinal)
					if RightDoor then
						RightDoor:PivotTo(RightDoorFinal)
					end
				else
					Opened.Value = true
					interactObject:SetAttribute("interactText","close")
					changeLightParts(LightParts,DoorSettings.LightColors[1])
					SoundPart.door_open:Play()
					local DoorTweenInfo = {
						["Time"] = DoorSettings.OpenSpeed, 
						["EasingStyle"] = DoorSettings.OpenEasingStyle,
						["EasingDirection"] = DoorSettings.OpenEasingDirection
					}
					local LeftDoorFinal = LeftDoor.PrimaryPart.CFrame * CFrame.Angles(math.rad(DoorSettings.LeftDoorOpen[3].X),math.rad(DoorSettings.LeftDoorOpen[3].Y),math.rad(DoorSettings.LeftDoorOpen[3].Z))+LeftDoor.PrimaryPart.CFrame[DoorSettings.LeftDoorOpen[1]]*DoorSettings.LeftDoorOpen[2]
					TweenModule.Tween(
						LeftDoor,
						LeftDoorFinal,
						DoorTweenInfo,
						false,
						100,
						"open"
					)
					local RightDoorFinal = nil
					if RightDoor then
						RightDoorFinal = RightDoor.PrimaryPart.CFrame * CFrame.Angles(math.rad(DoorSettings.RightDoorOpen[3].X),math.rad(DoorSettings.RightDoorOpen[3].Y),math.rad(DoorSettings.RightDoorOpen[3].Z))+RightDoor.PrimaryPart.CFrame[DoorSettings.RightDoorOpen[1]]*DoorSettings.RightDoorOpen[2]
						TweenModule.Tween(
							RightDoor,
							RightDoorFinal,
							DoorTweenInfo,
							false,
							100,
							"open"
						)
					end
					task.wait(DoorSettings.CloseSpeed)
					LeftDoor:PivotTo(LeftDoorFinal)
					if RightDoor then
						RightDoor:PivotTo(RightDoorFinal)
					end
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
	
	[6] = function(interactObject, player) -- Chair
	end,
	
	[7] = function(interactObject, player) -- Vending Machine
		
	end,
	
	[8] = function(interactObject, player) -- the cat.
		interactObject:SetAttribute("interactable", false)
			
		local CatObject = interactObject.PrimaryPart
		local InitialCFrame = CatObject.CFrame
		local InitialSize = CatObject.Size
		local FinalSize = Vector3.new(InitialSize.X, InitialSize.Y/1.2, InitialSize.Z)
		local FinalCFrame = InitialCFrame + InitialCFrame.UpVector * -(InitialSize.Y-FinalSize.Y)/2
		local CatTweenInfo = {
			["Time"] = 0.2,
			["EasingStyle"] = Enum.EasingStyle.Cubic
		}
			
		TweenModule.Tween(CatObject, FinalCFrame, CatTweenInfo, true, 100, nil, FinalSize)
		task.wait(0.2)
		TweenModule.Tween(CatObject, InitialCFrame, CatTweenInfo, true, 100, nil, InitialSize)
		task.wait(0.2)
		interactObject:SetAttribute("interactable", true)
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