local DetectorModule = {}

-- Services
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Replicated Storage Objects
local DetectorSounds = ReplicatedStorage.Sounds.Miscellaneous.Detector

-- Modules
local Zone = require(ReplicatedStorage.Modules.Interaction.Zone)

-- Tables
local ForbiddenToolTypes = {1, 2, 6} 

local function CreateDetector (Detector)
	local DetectorZonePart = Detector.Zone
	local DetectorZone = Zone.new(DetectorZonePart)

	local LightParts = Detector:FindFirstChild("LightParts") or nil
	local SoundPart = Detector["SoundPart"]

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

	-- Clone sounds from Detector folder so we can play them later.
	local function CreateDetectorSounds ()
		if SoundPart and DetectorSounds then
			for _, Sound in pairs(DetectorSounds:GetChildren()) do
				local NewSound = Sound:Clone()
				NewSound.Parent = SoundPart
			end
		end
	end

	-- Play detector sounds based on Detecting boolean.
	local function PlayDetectorSounds (Detecting: boolean)
		if Detecting then
			SoundPart["Detection"].Looped = true
			SoundPart["Detection"]:Play()
		else
			SoundPart["Detection"].Looped = false
		end
	end


	-- Create detector sounds.
	CreateDetectorSounds()
	-- Detector function loop
	while Detector.Parent do
		local Players = DetectorZone:getPlayers()
		local DetectingContraband = false
		for _, Player in pairs(Players) do

			-- Detect held tools
			if Player.Character 
				and Player.Character:FindFirstChildOfClass("Tool") 
				and table.find(ForbiddenToolTypes, Player.Characfter:FindFirstChildOfClass("Tool"):GetAttribute("ToolType"))
			then
				DetectingContraband = true
				break
			end

			-- Detect tools in backpack
			if Player.Backpack then
				for _, Tool in pairs(Player.Backpack:GetChildren()) do
					if table.find(ForbiddenToolTypes, Tool:GetAttribute("ToolType")) then
						DetectingContraband = true
						break
					end
				end
			end
		end

		-- Turn detector on
		if not Detector:GetAttribute("DetectingContraband") and DetectingContraband then
			Detector:SetAttribute("DetectingContraband", true)
			PlayDetectorSounds(true)
			ChangeLightParts(LightParts, Color3.fromRGB(255, 101, 101))
			task.wait(3)
			-- Turn detector off after wait.
			Detector:SetAttribute("DetectingContraband", false)
			PlayDetectorSounds(false)
			ChangeLightParts(LightParts, Color3.fromRGB(125, 255, 105))
		end

		task.wait()
	end
	Zone:Destroy()
end

function DetectorModule.Init()
	CollectionService:GetInstanceAddedSignal("Detector"):Connect(function(Detector)
		CreateDetector(Detector)
	end)

	for _, Detector in pairs(CollectionService:GetTagged("Detector")) do
		CreateDetector(Detector)
	end
end

return DetectorModule
