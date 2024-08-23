local module = {}

local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Player = game:GetService("Players").LocalPlayer
local UIS = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Modules = ReplicatedStorage:WaitForChild("Modules")
local CircleFrames = require(Modules:WaitForChild("UI"):WaitForChild("CircleFrames"))

local Player = game:GetService("Players").LocalPlayer
local Dot = nil

local function loadCharacter(Character)
	local Humanoid = Character:WaitForChild("Humanoid")
	local Mouse = game:GetService("Players").LocalPlayer:GetMouse()
	local renderStep = RunService.RenderStepped:Connect(function()
		UIS.MouseIconEnabled = false
		Dot.Position = UDim2.new(0,Mouse.X,0,Mouse.Y)
	end)
	Humanoid.Died:Once(function()
		renderStep:Disconnect()
	end)
end

function module.Init()
	local MouseUI = Player:WaitForChild("PlayerGui"):WaitForChild("MouseUI")
	Dot = MouseUI:WaitForChild("Dot")
	local Percentage = MouseUI:WaitForChild("Percentage")
	local CirclePercentage = MouseUI:WaitForChild("Crosshair")
	local ChargePercentage = MouseUI:WaitForChild("Charge")
	local ArrowPower = MouseUI:WaitForChild("Arrow")
	local MainCrosshairFrame = Dot:WaitForChild("Crosshair")
	local CrosshairFrame = MainCrosshairFrame:WaitForChild("Frame")
	local CircleFrame = Dot:WaitForChild("Progress")
	local ArrowFrame = Dot:WaitForChild("ArrowFrame")
	local ArrowFolder = ArrowFrame:WaitForChild("Arrows")
	local ArrowShadowFolder = ArrowFrame:WaitForChild("ArrowShadows")
	local ChargeFrame = Dot:WaitForChild("ChargeBar")
	local ChargeBar = ChargeFrame:WaitForChild("Bar")
	local arrowPowerIndex = {
		[1] = {false,false,true,Color3.fromRGB(255, 87, 87)},
		[2] = {false,true,true,Color3.fromRGB(208, 158, 42)},
		[3] = {true,true,true,Color3.fromRGB(55, 200, 45)},
	}
	local function changeArrowState ()
		if ArrowPower:GetAttribute("Enabled") then
			for i=1,3,1 do
				local arrow = ArrowFolder["Arrow"..tostring(i)]
				arrow.Visible = arrowPowerIndex[ArrowPower.Value][i]
				arrow.ImageColor3 = arrowPowerIndex[ArrowPower.Value][4]
			end
		end
	end
	
	local function enableArrows ()
		if ArrowPower:GetAttribute("Enabled") then
			changeArrowState()
			for _,arrow in pairs(ArrowShadowFolder:GetChildren()) do
				arrow.Visible = true
			end
		else
			for _,arrow in pairs(ArrowFolder:GetChildren()) do
				arrow.Visible = false
			end
			for _,arrow in pairs(ArrowShadowFolder:GetChildren()) do
				arrow.Visible = false
			end
		end
	end
	
	Percentage.Changed:Connect(function(val)
		CircleFrames.Progress(CircleFrame,Percentage,Percentage.Value)
	end)
	ChargePercentage.Changed:Connect(function(val)
		if val == 0 then
			ChargeFrame.Visible = false
		else
			ChargeFrame.Visible = true
		end
		ChargeBar.Size = UDim2.fromScale(1,val)
	end)
	CirclePercentage.Changed:Connect(function(val)
		if val == 0 then
			MainCrosshairFrame.Visible = false
		else
			MainCrosshairFrame.Visible = true
		end
		TweenService:Create(CrosshairFrame.L,TweenInfo.new(0.1,Enum.EasingStyle.Linear),{Position = UDim2.new(0.47,-val,0.5,0)}):Play()
		TweenService:Create(CrosshairFrame.R,TweenInfo.new(0.1,Enum.EasingStyle.Linear),{Position = UDim2.new(0.53,val,0.5,0)}):Play()
		TweenService:Create(CrosshairFrame.U,TweenInfo.new(0.1,Enum.EasingStyle.Linear),{Position = UDim2.new(0.5,0,0.47,-val)}):Play()
		TweenService:Create(CrosshairFrame.B,TweenInfo.new(0.1,Enum.EasingStyle.Linear),{Position = UDim2.new(0.5,0,0.53,val)}):Play()
	end)
	CircleFrames.Progress(CircleFrame,Percentage,0)
	enableArrows()
	changeArrowState()
	ArrowPower:GetAttributeChangedSignal("Enabled"):Connect(enableArrows)
	ArrowPower.Changed:Connect(changeArrowState)
	Player.CharacterAdded:Connect(loadCharacter)
	if Player.Character then
		loadCharacter(Player.Character)
	end
end

return module
