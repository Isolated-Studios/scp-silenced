local module = {}
local function FramePosChanger(ProgressFrame,Direction,StarterPoint)
	local F1 = ProgressFrame.Frame1
	local F2 = ProgressFrame.Frame2
	if Direction == "Vertical" then
		F1.Position = StarterPoint == "Up" and UDim2.fromScale(0,0) or UDim2.fromScale(1,0)
		F2.Position = StarterPoint == "Up" and UDim2.fromScale(1,0) or UDim2.fromScale(0,0)
		F1.AnchorPoint = StarterPoint == "Up" and Vector2.new(0,0) or Vector2.new(1,0)
		F2.AnchorPoint = StarterPoint == "Up" and Vector2.new(1,0) or Vector2.new(0,0)
		F1.Size = UDim2.fromScale(0.5,1)
		F2.Size = UDim2.fromScale(0.5,1)
		F1.ImageLabel.Position = StarterPoint == "Up" and UDim2.fromScale(0,0) or UDim2.fromScale(1,0)
		F2.ImageLabel.Position = StarterPoint == "Up" and UDim2.fromScale(1,0) or UDim2.fromScale(0,0)
		F1.ImageLabel.AnchorPoint = StarterPoint == "Up" and Vector2.new(0,0) or Vector2.new(1,0)
		F2.ImageLabel.AnchorPoint = StarterPoint == "Up" and Vector2.new(1,0) or Vector2.new(0,0)
		F1.ImageLabel.Size = UDim2.fromScale(2,1)
		F2.ImageLabel.Size = UDim2.fromScale(2,1)
	elseif Direction == "Horizontal" then
		F1.Position = StarterPoint == "Right" and UDim2.fromScale(0,0) or UDim2.fromScale(0,1)
		F2.Position = StarterPoint == "Right" and UDim2.fromScale(0,1) or UDim2.fromScale(0,0)
		F1.AnchorPoint = StarterPoint == "Right" and Vector2.new(0,0) or Vector2.new(0,1)
		F2.AnchorPoint = StarterPoint == "Right" and Vector2.new(0,1) or Vector2.new(0,0)
		F1.Size = UDim2.fromScale(1,0.5)
		F2.Size = UDim2.fromScale(1,0.5)
		F1.ImageLabel.Position = StarterPoint == "Right" and UDim2.fromScale(0,0) or UDim2.fromScale(0,1)
		F2.ImageLabel.Position = StarterPoint == "Right" and UDim2.fromScale(0,1) or UDim2.fromScale(0,0)
		F1.ImageLabel.AnchorPoint = StarterPoint == "Right" and Vector2.new(0,0) or Vector2.new(0,1)
		F2.ImageLabel.AnchorPoint = StarterPoint == "Right" and Vector2.new(0,1) or Vector2.new(0,0)
		F1.ImageLabel.Size = UDim2.fromScale(1,2)
		F2.ImageLabel.Size = UDim2.fromScale(1,2)
	end
end

function module.Progress(ProgressFrame,Percentage,Value)
	local F1 = ProgressFrame:FindFirstChild("Frame1")
	local F2 = ProgressFrame:FindFirstChild("Frame2")
	
	if not F1 and F2 then return end
	
	local PercentNumber = math.clamp(Value * 3.6,0,360)
	local I1 = F1.ImageLabel
	local I2 = F2.ImageLabel
	local G1 = I1.UIGradient
	local G2 = I2.UIGradient
	I1.ImageColor3 = Percentage.ImageColor.Value
	I2.ImageColor3 = Percentage.ImageColor.Value
	I1.ImageTransparency = Percentage.ImageTrans.Value
	I2.ImageTransparency = Percentage.ImageTrans.Value
	I1.Image = "rbxassetid://" .. Percentage.ImageId.Value
	I2.Image = "rbxassetid://" .. Percentage.ImageId.Value
	if Percentage.StarterPoint.Value == "Up" or Percentage.StarterPoint.Value == "Down"  then
		FramePosChanger(ProgressFrame,"Vertical",Percentage.StarterPoint.Value)
		if Percentage.StarterPoint.Value == "Up" then
			if Percentage.Direction.Value == "Left" then
				G1.Rotation = math.clamp(PercentNumber,180,360)
				G2.Rotation = math.clamp(PercentNumber,0,180)
			elseif Percentage.Direction.Value == "Right" then
				G1.Rotation = 180 - math.clamp(PercentNumber,0,180)
				G2.Rotation = - math.clamp(PercentNumber,180,360) + 180
			elseif Percentage.Direction.Value == "Middle" then
				G1.Rotation = 180 - math.clamp(PercentNumber,0,360)/2
				G2.Rotation = math.clamp(PercentNumber,0,360)/2
			end
		elseif Percentage.StarterPoint.Value == "Down" then
			if Percentage.Direction.Value == "Left" then
				G1.Rotation = math.clamp(PercentNumber,180,360) + 180
				G2.Rotation = math.clamp(PercentNumber,0,180) + 180
			elseif Percentage.Direction.Value == "Right" then
				G1.Rotation = - math.clamp(PercentNumber,0,180)
				G2.Rotation = - math.clamp(PercentNumber,180,360)
			elseif Percentage.Direction.Value == "Middle" then
				G1.Rotation = - math.clamp(PercentNumber,0,360)/2
				G2.Rotation = math.clamp(PercentNumber,0,360)/2 + 180
			end
		end
	elseif Percentage.StarterPoint.Value == "Left" or Percentage.StarterPoint.Value == "Right"  then
		FramePosChanger("Horizontal",Percentage.StarterPoint.Value)
		if Percentage.StarterPoint.Value == "Left" then
			if Percentage.Direction.Value == "Left" then
				G1.Rotation = math.clamp(PercentNumber,180,360) - 90
				G2.Rotation = math.clamp(PercentNumber,0,180) - 90
			elseif Percentage.Direction.Value == "Right" then
				G1.Rotation = 90 - math.clamp(PercentNumber,0,180)
				G2.Rotation = - math.clamp(PercentNumber,180,360) + 90
			elseif Percentage.Direction.Value == "Middle" then
				G1.Rotation = 90 - math.clamp(PercentNumber,0,360)/2
				G2.Rotation = math.clamp(PercentNumber,0,360)/2  - 90
			end
		elseif Percentage.StarterPoint.Value == "Right" then
			if Percentage.Direction.Value == "Left" then
				G1.Rotation = math.clamp(PercentNumber,180,360) + 90
				G2.Rotation = math.clamp(PercentNumber,0,180) + 90
			elseif Percentage.Direction.Value == "Right" then
				G1.Rotation = 270 - math.clamp(PercentNumber,0,180)
				G2.Rotation = - math.clamp(PercentNumber,180,360) + 270
			elseif Percentage.Direction.Value == "Middle" then
				G1.Rotation = 270 - math.clamp(PercentNumber,0,360)/2
				G2.Rotation = math.clamp(PercentNumber,0,360)/2  + 90
			end
		end
	else
		Percentage.StarterPoint.Value = "Up"
		warn("Unknown Type. Only 4 available: “Up”, “Down”, “Left” and “Right”, changing to “Up”.")
	end
	if Percentage.MissingPartType.Value == "Color" then
		I1.UIGradient.Color = ColorSequence.new({ColorSequenceKeypoint.new(0,Percentage.ColorOfPercentPart.Value),ColorSequenceKeypoint.new(0.5,Percentage.ColorOfPercentPart.Value),ColorSequenceKeypoint.new(0.502,Percentage.ColorOfMissingPart.Value),ColorSequenceKeypoint.new(1,Percentage.ColorOfMissingPart.Value)})
		I2.UIGradient.Color = ColorSequence.new({ColorSequenceKeypoint.new(0,Percentage.ColorOfPercentPart.Value),ColorSequenceKeypoint.new(0.5,Percentage.ColorOfPercentPart.Value),ColorSequenceKeypoint.new(0.502,Percentage.ColorOfMissingPart.Value),ColorSequenceKeypoint.new(1,Percentage.ColorOfMissingPart.Value)})
		I1.UIGradient.Transparency = NumberSequence.new(0)
		I2.UIGradient.Transparency = NumberSequence.new(0)
	elseif Percentage.MissingPartType.Value == "Trans" then
		I1.UIGradient.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0,Percentage.TransOfPercentPart.Value),NumberSequenceKeypoint.new(0.5,Percentage.TransOfPercentPart.Value),NumberSequenceKeypoint.new(0.502,Percentage.TransOfMissingPart.Value),NumberSequenceKeypoint.new(1,Percentage.TransOfMissingPart.Value)})
		I2.UIGradient.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0,Percentage.TransOfPercentPart.Value),NumberSequenceKeypoint.new(0.5,Percentage.TransOfPercentPart.Value),NumberSequenceKeypoint.new(0.502,Percentage.TransOfMissingPart.Value),NumberSequenceKeypoint.new(1,Percentage.TransOfMissingPart.Value)})
		I1.UIGradient.Color = ColorSequence.new(Color3.new(1,1,1))
		I2.UIGradient.Color = ColorSequence.new(Color3.new(1,1,1))
	elseif Percentage.MissingPartType.Value == "TransAndColor" then
		I1.UIGradient.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0,Percentage.TransOfPercentPart.Value),NumberSequenceKeypoint.new(0.5,Percentage.TransOfPercentPart.Value),NumberSequenceKeypoint.new(0.502,Percentage.TransOfMissingPart.Value),NumberSequenceKeypoint.new(1,Percentage.TransOfMissingPart.Value)})
		I2.UIGradient.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0,Percentage.TransOfPercentPart.Value),NumberSequenceKeypoint.new(0.5,Percentage.TransOfPercentPart.Value),NumberSequenceKeypoint.new(0.502,Percentage.TransOfMissingPart.Value),NumberSequenceKeypoint.new(1,Percentage.TransOfMissingPart.Value)})
		I1.UIGradient.Color = ColorSequence.new({ColorSequenceKeypoint.new(0,Percentage.ColorOfPercentPart.Value),ColorSequenceKeypoint.new(0.5,Percentage.ColorOfPercentPart.Value),ColorSequenceKeypoint.new(0.502,Percentage.ColorOfMissingPart.Value),ColorSequenceKeypoint.new(1,Percentage.ColorOfMissingPart.Value)})
		I2.UIGradient.Color = ColorSequence.new({ColorSequenceKeypoint.new(0,Percentage.ColorOfPercentPart.Value),ColorSequenceKeypoint.new(0.5,Percentage.ColorOfPercentPart.Value),ColorSequenceKeypoint.new(0.502,Percentage.ColorOfMissingPart.Value),ColorSequenceKeypoint.new(1,Percentage.ColorOfMissingPart.Value)})
	else
		Percentage.MissingPartType.Value = "Trans"
		warn("Unknown Type. Only 3 available: “Trans”, “Color” and “TransAndColor”, changing to “Trans”.")
	end
end
return module
