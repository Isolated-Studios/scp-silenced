-- Services
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

-- Tooling
local Tooling = ReplicatedStorage.Tooling
local ToolingTools = Tooling.Tools
local Physical = Tooling.Physical

-- Replicated Storage Objects
local Events = ReplicatedStorage.Events
local DoorConfigs = ReplicatedStorage.Configs.Doors
local Sounds = ReplicatedStorage.Sounds

-- Modules
local TweenModule = require(ReplicatedStorage.Modules.Interaction.TweenModule)

-- Events
local finishInteraction = Events.Interaction.FinishInteraction

-- Other
local MedicalAmountCap = 2
local insecureIds = {4,5}

-- Get the distance between two Vector3 points and return the distance.
function getDistance(point1 : Vector3, point2 : Vector3)
	local distance
	if point1 and point2 then
		distance = (point1 - point2).Magnitude
	else
		return nil
	end
	return distance
end

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
		-- Might fix door spam bug?
		if not interactObject:GetAttribute("Interactable") then 
			return 
		end 
		
		local Allowed = true
		local Opened = interactObject.DoorConfigs.Opened
		local DoorSettings = require(DoorConfigs:FindFirstChild(interactObject:GetAttribute("DoorType")))

		local LeftDoor = interactObject:FindFirstChild("DoorL") or interactObject:FindFirstChild("Door")
		local RightDoor = interactObject:FindFirstChild("DoorR") or nil
		local LightParts = interactObject:FindFirstChild("LightParts") or nil
		local SoundPart = interactObject["SoundPart"]
		
		-- Change the parts/lights of LightModel to the colorPicked color.
		local function changeLightParts (LightModel: Model, colorPicked: Color3)
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
		
		local function playSound (SoundName: string)
			if SoundName 
				and Sounds.DoorSounds:FindFirstChild(interactObject:GetAttribute("DoorType")) 
				and Sounds.DoorSounds[interactObject:GetAttribute("DoorType")]:FindFirstChild(SoundName)
			then
				local NewSound = Sounds.DoorSounds[interactObject:GetAttribute("DoorType")][SoundName]:Clone()
				NewSound.Parent = SoundPart
				NewSound:Play()
				Debris:AddItem(NewSound, NewSound.TimeLength + 1)
			end
		end

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

			playSound("button")

			if Allowed then
				interactObject:SetAttribute("Interactable",false)
				if Opened.Value then
					Opened.Value = false
					if interactObject:GetAttribute("InteractText") 
						and string.lower(interactObject:GetAttribute("InteractText")) == "close" 
						and not interactObject:GetAttribute("Locked") 
					then
						interactObject:SetAttribute("InteractText", "OPEN")
					end
					changeLightParts(LightParts,DoorSettings.LightColors.Moving)
					playSound("door_close")
					-- Move left door
					local DoorTweenInfo = {
						["Time"] = DoorSettings.CloseSpeed, 
						["EasingStyle"] = DoorSettings.CloseEasingStyle,
						["EasingDirection"] = DoorSettings.CloseEasingDirection
					}
					local LeftDoorFinal = LeftDoor.PrimaryPart.CFrame * 
						CFrame.Angles(
							math.rad(-DoorSettings.LeftDoorOpen.Rotation.X),
							math.rad(-DoorSettings.LeftDoorOpen.Rotation.Y),
							math.rad(-DoorSettings.LeftDoorOpen.Rotation.Z)
						)
						+ LeftDoor.PrimaryPart.CFrame[DoorSettings.LeftDoorOpen.Vector] * -DoorSettings.LeftDoorOpen.Distance
					TweenModule.Tween(
						LeftDoor,
						LeftDoorFinal,
						DoorTweenInfo,
						false,
						100,
						"close"
					)
					-- Move right door
					local RightDoorFinal = nil
					if RightDoor then
						RightDoorFinal = RightDoor.PrimaryPart.CFrame * 
							CFrame.Angles(
								math.rad(-DoorSettings.RightDoorOpen.Rotation.X),
								math.rad(-DoorSettings.RightDoorOpen.Rotation.Y),
								math.rad(-DoorSettings.RightDoorOpen.Rotation.Z)
							) 
							+ RightDoor.PrimaryPart.CFrame[DoorSettings.RightDoorOpen.Vector] * -DoorSettings.RightDoorOpen.Distance
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
					if interactObject:GetAttribute("InteractText") 
						and string.lower(interactObject:GetAttribute("InteractText")) == "open" 
						and not interactObject:GetAttribute("Locked") 
					then
						interactObject:SetAttribute("InteractText", "CLOSE")
					end
					changeLightParts(LightParts,DoorSettings.LightColors.Open)
					playSound("door_open")
					local DoorTweenInfo = {
						["Time"] = DoorSettings.OpenSpeed, 
						["EasingStyle"] = DoorSettings.OpenEasingStyle,
						["EasingDirection"] = DoorSettings.OpenEasingDirection
					}
					-- Move left door
					local LeftDoorFinal = LeftDoor.PrimaryPart.CFrame * 
						CFrame.Angles(
							math.rad(DoorSettings.LeftDoorOpen.Rotation.X),
							math.rad(DoorSettings.LeftDoorOpen.Rotation.Y),
							math.rad(DoorSettings.LeftDoorOpen.Rotation.Z)
						)
						+ LeftDoor.PrimaryPart.CFrame[DoorSettings.LeftDoorOpen.Vector] * DoorSettings.LeftDoorOpen.Distance
					TweenModule.Tween(
						LeftDoor,
						LeftDoorFinal,
						DoorTweenInfo,
						false,
						100,
						"open"
					)
					-- Move right door
					local RightDoorFinal = nil
					if RightDoor then
						RightDoorFinal = RightDoor.PrimaryPart.CFrame * 
							CFrame.Angles(
								math.rad(DoorSettings.RightDoorOpen.Rotation.X),
								math.rad(DoorSettings.RightDoorOpen.Rotation.Y),
								math.rad(DoorSettings.RightDoorOpen.Rotation.Z)
							)
							+ RightDoor.PrimaryPart.CFrame[DoorSettings.RightDoorOpen.Vector] * DoorSettings.RightDoorOpen.Distance
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
				interactObject:SetAttribute("Interactable",true)
				--Playing = false
			else
				--Playing = true
				interactObject:SetAttribute("Interactable",false)
				playSound("error")
				local ogColor = LightParts.Light.Color
				changeLightParts(LightParts,DoorSettings.LightColors.Close)
				task.wait(DoorSettings.Cooldown)
				changeLightParts(LightParts,ogColor)
				interactObject:SetAttribute("Interactable",true)
				--Playing = false
			end
		end
	end,

	[3] = function(interactObject, player) -- Pick up an item.
		interactObject:SetAttribute("Interactable", false)
		if Physical:FindFirstChild(interactObject.Name) then
			local ToolFromItem = Physical[interactObject.Name]:Clone()
			
			-- Replace the configuration if it exists in the interact object. 
			if interactObject:FindFirstChildOfClass("Configuration") then
				-- Destroy the tool's configuration if it exists.
				if ToolFromItem:FindFirstChildOfClass("Configuration") then
					ToolFromItem:FindFirstChildOfClass("Configuration"):Destroy()
				end

				interactObject:FindFirstChildOfClass("Configuration").Parent = ToolFromItem
			end
			
			-- Destroy the item model and give the tool to the player.
			ToolFromItem:SetAttribute("NewTool", true)
			ToolFromItem.Parent = player.Backpack
			interactObject:Destroy()
		else
			warn("Invalid Pick up. Could not find item '"..interactObject.Name.. "' in physical tool folder")
			interactObject:SetAttribute("Interactable", true)
		end
	end,

	[4] = function(interactObject, player) -- revive
		interactObject:SetAttribute("FreezePlayer",nil)
		interactObject:SetAttribute("Interactable",nil)
		interactObject:SetAttribute("InteractAnimationId",nil)
		interactObject:SetAttribute("InteractId",nil)
		interactObject:SetAttribute("InteractText",nil)
		interactObject:SetAttribute("interactTime",nil)
		interactObject:SetAttribute("Range",nil)
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
		interactObject:SetAttribute("Interactable", false)
			
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
		interactObject:SetAttribute("Interactable", true)
	end,

}


function onfinishInteraction(player, current,insecureId)
	if (current and (typeof(current) == "Instance")) then
		if ((player.Character) and (player.Character.PrimaryPart) and (getDistance(player.Character.PrimaryPart.Position, current.PrimaryPart.Position) <= current:GetAttribute("Range") * 1.5 )) then
			if current and InteractFunctions[current:GetAttribute("InteractId")] then
				if insecureId and table.find(insecureIds,insecureId) then
					InteractFunctions[insecureId](current, player)
				else
					InteractFunctions[current:GetAttribute("InteractId")](current, player)
					
				end
			end
			-- Play if there is a second interaction Id
			if current and current:GetAttribute("InteractId2") and InteractFunctions[current:GetAttribute("InteractId2")] then
				InteractFunctions[current:GetAttribute("InteractId2")](current, player)
				if insecureId and table.find(insecureIds,insecureId) then
					InteractFunctions[insecureId](current, player)
				else
					InteractFunctions[current:GetAttribute("InteractId2")](current, player)
				end
			end
		end       
	end
end

finishInteraction.OnServerEvent:Connect(onfinishInteraction)