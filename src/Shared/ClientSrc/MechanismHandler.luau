local module = {}
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local Events = ReplicatedStorage:WaitForChild("Events")
local InteractionEvents = Events:WaitForChild("Interaction")
local DoorEvent = InteractionEvents:WaitForChild("DoorEvent")
local TweenObjectEvent = InteractionEvents:WaitForChild("TweenObjectEvent")

local Character

function module.LoadChar(char)
	Character = char
end

function module.Init()
	local DoorEventFunction = DoorEvent.OnClientEvent:Connect(function(Opened,LeftDoor,RightDoor,LeftCFrame,RightCFrame,Time,Sound,LightParts,LightColor,PromptPlayer)
		local CFrameObject01 = Instance.new("CFrameValue")
		CFrameObject01.Value = LeftDoor:GetPrimaryPartCFrame()
		local CFrameObject02 = Instance.new("CFrameValue")
		CFrameObject02.Value = RightDoor:GetPrimaryPartCFrame()
		CFrameObject01.Parent = script
		CFrameObject02.Parent = script
		local DoorOpen1 = {Value = LeftCFrame}
		local DoorOpen2 = {Value = RightCFrame}

		CFrameObject01.Changed:Connect(function()
			LeftDoor:SetPrimaryPartCFrame(CFrameObject01.Value)
		end)

		CFrameObject02.Changed:Connect(function()
			RightDoor:SetPrimaryPartCFrame(CFrameObject02.Value)
		end)

		if Character and Character.Parent and (Character.PrimaryPart.Position-LeftDoor.PrimaryPart.Position).Magnitude > 90 then

			for _,CurrentLightParts in pairs(LightParts:GetChildren()) do
				CurrentLightParts.Color = LightColor
				if CurrentLightParts:FindFirstChildOfClass("PointLight") or CurrentLightParts:FindFirstChildOfClass("SurfaceLight") or CurrentLightParts:FindFirstChildOfClass("SpotLight") then
					for _,Lights in pairs(CurrentLightParts:GetChildren()) do
						Lights.Color = CurrentLightParts.Color
					end
				end
			end

			task.defer(function()
				CFrameObject01.Value = LeftCFrame
				CFrameObject02.Value = RightCFrame
			end)
		else

			for _,CurrentLightParts in pairs(LightParts:GetChildren()) do
				--CurrentLightParts.Color = LightColor
				TweenService:Create(CurrentLightParts,TweenInfo.new(0.6),{Color = LightColor}):Play()
				if CurrentLightParts:FindFirstChildOfClass("PointLight") or CurrentLightParts:FindFirstChildOfClass("SurfaceLight") or CurrentLightParts:FindFirstChildOfClass("SpotLight") then
					for _,Lights in pairs(CurrentLightParts:GetChildren()) do
						--Lights.Color = CurrentLightParts.Color
						TweenService:Create(Lights,TweenInfo.new(0.6),{Color = LightColor}):Play()
					end
				elseif CurrentLightParts:FindFirstChildOfClass("SurfaceGui") and CurrentLightParts:FindFirstChildOfClass("SurfaceGui"):FindFirstChildOfClass("ImageLabel") then
					TweenService:Create(CurrentLightParts:FindFirstChildOfClass("SurfaceGui"):FindFirstChildOfClass("ImageLabel"),TweenInfo.new(0.6),{ImageColor3 = LightColor}):Play()
				end
			end

			TweenService:Create(CFrameObject01,TweenInfo.new(Time),DoorOpen1):Play()
			TweenService:Create(CFrameObject02,TweenInfo.new(Time),DoorOpen2):Play()
		end

		if Sound then 
			Sound:Play() 
		end

		Debris:AddItem(CFrameObject01,Time)
		Debris:AddItem(CFrameObject02,Time)
	end)

	-- Used for tweening models but can work with BasePart.
	local TweenObject = TweenObjectEvent.OnClientEvent:Connect(function(
		Object: Model,
		newCFrame: CFrame,
		GivenTweenInfo: table,
		Distance: number,
		animationName: string,
		newSize: Vector3
	)
		local CFrameValue = Instance.new("CFrameValue")
		CFrameValue.Parent = Object
		
		-- Assemble GivenTweenInfo into an actual TweenInfo.
		local CreatedTweenInfo = TweenInfo.new(
			GivenTweenInfo["Time"] or 1,
			GivenTweenInfo["EasingStyle"] or Enum.EasingStyle.Linear,
			GivenTweenInfo["EasingDirection"] or Enum.EasingDirection.Out,
			GivenTweenInfo["RepeatCount"] or 0,
			GivenTweenInfo["Reverses"] or false,
			GivenTweenInfo["DelayTime"] or 0
		)
		
		if Object:IsA("Model") and Object.PrimaryPart then
			CFrameValue.Value = Object:GetPivot()
			CFrameValue.Changed:Connect(function()
				Object:PivotTo(CFrameValue.Value)
			end)
			if animationName and Object:FindFirstChild(animationName) and Object:FindFirstChild(animationName):IsA("Animation") and Object:FindFirstChildOfClass("AnimationController") then
				local animation = Object:FindFirstChildOfClass("AnimationController"):LoadAnimation(Object:FindFirstChild(animationName))
				animation:Play()
			end
		elseif Object:IsA("BasePart") then
			CFrameValue.Value = Object.CFrame
			CFrameValue.Changed:Connect(function()
				Object.CFrame = CFrameValue.Value
			end)
			if newSize then
				TweenService:Create(Object, CreatedTweenInfo, {Size = newSize}):Play()
			end
		end

		Debris:AddItem(CFrameValue, CreatedTweenInfo.Time+0.1)
		local objPos = nil

		if Object:IsA("Model") then
			objPos = Object:GetPivot().Position
		else
			objPos = Object.Position
		end

		Debris:AddItem(CFrameValue, CreatedTweenInfo.Time+0.1)

		if Character and Character.Parent and Distance > 0 and math.round((Character.PrimaryPart.Position-objPos).Magnitude) <= Distance or Distance <= 0 or not Distance then
			TweenService:Create(CFrameValue,CreatedTweenInfo,{Value = newCFrame}):Play()
		else
			task.defer(function()
				task.wait(CreatedTweenInfo.Time)
				CFrameValue.Value = newCFrame
			end)
		end

	end)
end
return module