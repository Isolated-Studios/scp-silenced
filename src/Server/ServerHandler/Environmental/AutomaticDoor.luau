local AutomaticDoorModule = {}

-- Services
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Replicated Storage Objects
local DoorConfigs = ReplicatedStorage.Configs.Doors
local DoorSounds = ReplicatedStorage.Sounds.DoorSounds

-- Modules
local Zone = require(ReplicatedStorage.Modules.Interaction.Zone)
local TweenModule = require(ReplicatedStorage.Modules.Interaction.TweenModule)

local function CreateDoor (Door)
	local DoorZonePart = Door.Zone
	local Config = Door.DoorConfigs
	local Positioning = Door.Positioning
	local DoorZone = Zone.new(DoorZonePart)
	local DoorSettings = require(DoorConfigs[Door:GetAttribute("DoorType")])
	
	local LeftDoor = Door:FindFirstChild("DoorL") or Door:FindFirstChild("Door")
	local RightDoor = Door:FindFirstChild("DoorR") or nil
	local LightParts = Door:FindFirstChild("LightParts") or nil
	local SoundPart = Door["SoundPart"]
	
	local CloseL = Positioning:FindFirstChild("CloseL") or Positioning:FindFirstChild("Close")
	local CloseR =  Positioning:FindFirstChild("CloseR") or nil
	local OpenL = Positioning:FindFirstChild("OpenL") or Positioning:FindFirstChild("Open")
	local OpenR =  Positioning:FindFirstChild("OpenR") or nil
	
	local OpenConfig = Config.Open
	local CloseConfig = Config.Close
	
	-- Change the parts/lights of LightModel to the colorPicked color.
	local function ChangeLightParts (LightModel: Model, colorPicked: Color3)
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
	
	-- Clone sounds from DoorSounds folder using DoorType so we can play them later.
	local function CreateDoorSounds ()
		if SoundPart and DoorSounds:FindFirstChild(Door:GetAttribute("DoorType")) then
			for _, Sound in pairs(DoorSounds[Door:GetAttribute("DoorType")]:GetChildren()) do
				local NewSound = Sound:Clone()
				NewSound.Parent = SoundPart
			end
		end
	end
	
	-- Play door sounds based on Opening boolean.
	local function PlayDoorSounds (Opening: boolean)
		if Opening then
			SoundPart["door_close"]:Stop()
			SoundPart["door_open"]:Play()
			
			SoundPart["door_closebeep"]:Stop()
			SoundPart["door_openbeep"]:Play()
		else
			SoundPart["door_close"]:Play()
			SoundPart["door_open"]:Stop()
			
			SoundPart["door_closebeep"]:Play()
			SoundPart["door_openbeep"]:Stop()
		end
	end
	
	-- Stop all tweens. Used for switching opening/closing statuses.
	local function StopTweens ()
		if CloseConfig.Value == true or OpenConfig.Value == true then
			TweenModule.StopTween(LeftDoor)
			if RightDoor then
				TweenModule.StopTween(RightDoor)
			end
		end
	end
	
	-- Tween the door open.
	local function OpenDoor ()
		CloseConfig.Value = false
		OpenConfig.Value = true
		local LeftDoorFinal = OpenL.WorldCFrame
		local DoorTweenInfo = {
			["Time"] = DoorSettings.OpenSpeed or 1,
			["EasingStyle"] = DoorSettings.OpenEasingStyle or Enum.EasingStyle.Linear,
			["EasingDirection"] = DoorSettings.OpenEasingDirection or Enum.EasingDirection.Out
		}
		ChangeLightParts(LightParts, DoorSettings.LightColors.Open)
		PlayDoorSounds(true)
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
			local RightDoorFinal = OpenR.WorldCFrame
			
			TweenModule.Tween(
				RightDoor,
				RightDoorFinal,
				DoorTweenInfo,
				false,
				100,
				"open"
			)
		end
	end
	
	-- Tween the door closed.
	local function CloseDoor ()
		OpenConfig.Value = false
		CloseConfig.Value = true
		local LeftDoorFinal = CloseL.WorldCFrame
		local DoorTweenInfo = {
			["Time"] = DoorSettings.CloseSpeed or 1,
			["EasingStyle"] = DoorSettings.CloseEasingStyle or Enum.EasingStyle.Linear,
			["EasingDirection"] = DoorSettings.CloseEasingDirection or Enum.EasingDirection.Out
		}
		ChangeLightParts(LightParts, DoorSettings.LightColors.Close)
		PlayDoorSounds(false)
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
			local RightDoorFinal = CloseR.WorldCFrame
			
			TweenModule.Tween(
				RightDoor,
				RightDoorFinal,
				DoorTweenInfo,
				false,
				100,
				"close"
			)
		end
	end
	
	-- Create door sounds.
	CreateDoorSounds()
	-- Door function loop
	while Door.Parent do
		local Players = DoorZone:getPlayers()
		if #Players > 0 and OpenConfig.Value == false  then
			StopTweens()
			OpenDoor()
		elseif #Players == 0 and CloseConfig.Value == false then
			StopTweens()
			CloseDoor()
		end
		task.wait()
	end
	Zone:Destroy()
end

function AutomaticDoorModule.Init()
	CollectionService:GetInstanceAddedSignal("AutomaticDoor"):Connect(function(Door)
		CreateDoor(Door)
	end)
	
	for _, Door in pairs(CollectionService:GetTagged("AutomaticDoor")) do
		CreateDoor(Door)
	end
end

return AutomaticDoorModule
