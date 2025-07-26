local module = {}
-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Player = game:GetService("Players").LocalPlayer

-- Replicated Storage Folders
local Modules = ReplicatedStorage.Modules

-- Modules
local KeybindHandler = require(Modules.UI.KeybindHandler)
local CommonFuncs = require(Modules.CommonFuncs)

-- Events
local SaveSettingChange = ReplicatedStorage.Events.Interaction.SaveSettingChange

-- Other
local SelectedCategory = "General"
local ForbiddenKeybinds = {
	Enum.KeyCode.Slash,
	Enum.KeyCode.Backquote,
	Enum.KeyCode.Return,
	Enum.KeyCode.Backspace,
	Enum.KeyCode.W,
	Enum.KeyCode.A,
	Enum.KeyCode.S,
	Enum.KeyCode.D,
	Enum.KeyCode.Escape,
	Enum.KeyCode.One,
	Enum.KeyCode.Two,
	Enum.KeyCode.Three,
	Enum.KeyCode.Four,
	Enum.KeyCode.Five,
	Enum.KeyCode.Six,
	Enum.KeyCode.Seven,
	Enum.KeyCode.Eight,
	Enum.KeyCode.Nine,
	Enum.KeyCode.Zero,
	Enum.KeyCode.F1,
	Enum.KeyCode.F2,
	Enum.KeyCode.F3,
	Enum.KeyCode.F4,
	Enum.KeyCode.F5,
	Enum.KeyCode.F6,
	Enum.KeyCode.F7,
	Enum.KeyCode.F8,
	Enum.KeyCode.F9,
	Enum.KeyCode.F10,
	Enum.KeyCode.F11,
	Enum.KeyCode.F12,
}
local NumberKeys = {
	Enum.KeyCode.One,
	Enum.KeyCode.Two,
	Enum.KeyCode.Three,
	Enum.KeyCode.Four,
	Enum.KeyCode.Five,
	Enum.KeyCode.Six,
	Enum.KeyCode.Seven,
	Enum.KeyCode.Eight,
	Enum.KeyCode.Nine,
	Enum.KeyCode.Zero,
}
local WordToNumber = {
	["One"] = "1",
	["Two"] = "2",
	["Three"] = "3",
	["Four"] = "4",
	["Five"] = "5",
	["Six"] = "6",
	["Seven"] = "7",
	["Eight"] = "8",
	["Nine"] = "9",
	["Zero"] = "0",
}
local ErrorTextTween = nil

function module.LoadChar(Character)
	
end


function module.Init()
	local SettingsUI = Player.PlayerGui:WaitForChild("Settings")
	local Settings = ReplicatedStorage.Players:WaitForChild(tostring(Player.UserId)).Settings
	
	local Main = SettingsUI.Main
	local Modal = SettingsUI.ModalFrame
	local CategoryFrame = Main.CategoryContainer.CategoryFrame
	local ContainerFrame = Main.Container.ContainerFrame
	local ButtonPrimes = SettingsUI.ButtonPrimes
	
	local KeyToSet = nil
	
	-- Sets Setting to the NewValue and sends over to server. If Mock is true, will not send to server (Useful for testing and not saving data)
	local function SetSetting (Setting, NewValue, Mock)
		Setting.Value = NewValue
		if not Mock then
			SaveSettingChange:FireServer(Setting, NewValue)
		end
	end
	
	-- Shift the TextLabel color3 and UIStroke to the Color instantly, and then revert back to white.
	local function ColorShiftAssign (TextLabel,Color)
		TextLabel.TextColor3 = Color
		TextLabel.UIStroke.Color = Color
		TweenService:Create(TextLabel, TweenInfo.new(0.7), {TextColor3 = Color3.fromRGB(255,255,255)}):Play()
		TweenService:Create(TextLabel.UIStroke, TweenInfo.new(0.7), {Color = Color3.fromRGB(255,255,255)}):Play()
	end
	
	-- Shift the TextLabel color3 and slider bar to the Color instantly, and then revert back to white.
	local function ColorShiftSlider (TextButton, Sliderbar, Color)
		TextButton.TextColor3 = Color
		Sliderbar.BackgroundColor3 = Color
		TweenService:Create(TextButton, TweenInfo.new(0.7), {TextColor3 = Color3.fromRGB(255,255,255)}):Play()
		TweenService:Create(Sliderbar, TweenInfo.new(0.7), {BackgroundColor3 = Color3.fromRGB(255,255,255)}):Play()
	end
	
	-- Set the slider position based on the number. Will account for values exceeding or less than Max and Min respectively.
	local function SetSlider (Setting, UIDragDetector, Min, Max)
		if KeyToSet then
			local RealValue = 0
			if tonumber(KeyToSet.Text) and tonumber(KeyToSet.Text) > Max then 
				RealValue = Max
			elseif tonumber(KeyToSet.Text) and tonumber(KeyToSet.Text) < Min then
				RealValue = Min
			elseif KeyToSet.Text == "" then
				RealValue = Setting.Value
			else
				RealValue = tonumber(KeyToSet.Text)
			end 
			UIDragDetector.DragUDim2 = UDim2.fromScale(RealValue/Max - 0.5, 0)
		end
	end
	
	-- Enters in slider number as the setting number and sets the slider bar to it.
	local function EnterNewSliderNumber (Setting, UIDragDetector, Min, Max)
		-- Colorshift to green to indicate setting
		ColorShiftSlider(KeyToSet, UIDragDetector.Parent, Color3.fromRGB(20, 255, 20))	
		-- Set number to the minimum if below minimum or blank.
		if tonumber(KeyToSet.Text) and tonumber(KeyToSet.Text) < Min then
			KeyToSet.Text = tostring(Min)
			-- Set number to the maximum if above maximum.
		elseif tonumber(KeyToSet.Text) and tonumber(KeyToSet.Text) > Max then
			KeyToSet.Text = tostring(Max)
		elseif KeyToSet.Text == "" then
			KeyToSet.Text = Setting.Value
		end
		SetSlider(Setting, UIDragDetector, Min, Max)
		-- Set new number in setting and disconnect KeyToSet.
		SetSetting(Setting, tonumber(KeyToSet.Text))
		KeyToSet = nil
	end
	
	local typeCreation = { -- Creation functions of each button type
		-- Keybind buttons
		["Assign"] = function(Setting, SettingCategory, SettingButton)
			local StageFrame = SettingButton.StageFrame
			local Key = StageFrame.Key
			local Reset = StageFrame.Reset
			
			Key.Text = string.upper(Setting.Value)
			
			Key.MouseButton1Click:Connect(function()
				for _,otherKeyBindButtons in pairs(ContainerFrame.Keybinds:GetChildren()) do
					if otherKeyBindButtons:GetAttribute("Type") == "Assign" then
						otherKeyBindButtons.StageFrame.Key.Text = string.upper(otherKeyBindButtons.Setting.Value.Value)
						otherKeyBindButtons.StageFrame.Key.TextColor3 = Color3.fromRGB(255,255,255)
					end
				end
				
				Key.Text = "PRESS ANY KEY TO ASSIGN"
				KeyToSet = Key
			end)
			
			-- Reset keybind to default and fire an orange colorshift for key text.
			Reset.MouseButton1Click:Connect(function()
				SetSetting(Setting, Setting:GetAttribute("Default"))
				ColorShiftAssign(Key,Color3.fromRGB(255, 118, 20))
				Key.Text = string.upper(Setting.Value)
				KeyToSet = nil
			end)
		end,
		["Multistage"] = function(Setting, SettingCategory, SettingButton)
		end,
		-- Slider bar with number for number values with ranges.
		["Slider"] = function(Setting, SettingCategory, SettingButton)
			local StageFrame = SettingButton.StageFrame
			local Number = StageFrame.Number
			local SliderBar = StageFrame.BarFrame.SliderBar
			local UIDragDetector = SliderBar.UIDragDetector
			local Min = Setting:GetAttribute("Min")
			local Max = Setting:GetAttribute("Max")
			
			Number.Text = tostring(Setting.Value)
			UIDragDetector.DragUDim2 = UDim2.fromScale(Setting.Value/Max-0.5, 0)
			
			Number.MouseButton1Click:Connect(function()
				if KeyToSet then
					local PreviousSetting = KeyToSet.Parent.Parent.Setting.Value
					EnterNewSliderNumber(PreviousSetting, KeyToSet.Parent.BarFrame.SliderBar.UIDragDetector, PreviousSetting:GetAttribute("Min"), PreviousSetting:GetAttribute("Max"))
				end
				
				for _,otherNumberButtons in pairs(ContainerFrame[SelectedCategory]:GetChildren()) do
					if otherNumberButtons:GetAttribute("Type") == "Slider" then
						otherNumberButtons.StageFrame.Number.Text = otherNumberButtons.Setting.Value.Value
					end
				end
				
				Number.Text = ""
				KeyToSet = Number
			end)
			
			UIDragDetector.DragContinue:Connect(function()
				local X = math.clamp(SliderBar.Position.X.Scale, 0, 1)
				local NewValue = math.clamp(math.round(X * Max), Min, Max)
				Number.Text = tostring(NewValue)
			end)
			
			UIDragDetector.DragEnd:Connect(function()
				ColorShiftSlider(Number, SliderBar, Color3.fromRGB(20, 255, 20))	
				local X = math.clamp(SliderBar.Position.X.Scale, 0, 1)
				local NewValue = math.clamp(math.round(X * Max), Min, Max)
				UIDragDetector.DragUDim2 = UDim2.fromScale(NewValue/Max-0.5, 0)
				Number.Text = tostring(NewValue)
				SetSetting(Setting, NewValue)
			end)
		end,
		["Switch"] = function(Setting, SettingCategory, SettingButton)
		end,
		-- Simple On/Off toggle for boolean values.
		["Toggle"] = function(Setting, SettingCategory, SettingButton)
			local StageFrame = SettingButton.StageFrame
			local On = StageFrame.On
			local Off = StageFrame.Off
			local TweenTime = TweenInfo.new(0.2)
			
			if Setting.Value then
				On.TextColor3 = Color3.fromRGB(0, 0, 0)
				On.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
				Off.TextColor3 = Color3.fromRGB(255, 255, 255)
				Off.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
			else
				On.TextColor3 = Color3.fromRGB(255, 255, 255)
				On.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
				Off.TextColor3 = Color3.fromRGB(0, 0, 0)
				Off.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
			end
			
			-- Turn on. Set Setting to true.
			On.MouseButton1Click:Connect(function()
				if Setting.Value == false then
					SetSetting(Setting, true)
					TweenService:Create(On, TweenTime,
						{BackgroundColor3 = Color3.fromRGB(255, 255, 255), TextColor3 = Color3.fromRGB(0, 0, 0)}
					):Play()
					TweenService:Create(Off, TweenTime,
						{BackgroundColor3 = Color3.fromRGB(0, 0, 0), TextColor3 = Color3.fromRGB(255, 255, 255)}
					):Play()
				end
			end)
			
			-- Turn off. Set Setting to false
			Off.MouseButton1Click:Connect(function()
				if Setting.Value then
					SetSetting(Setting, false)
					TweenService:Create(On, TweenTime,
						{BackgroundColor3 = Color3.fromRGB(0, 0, 0), TextColor3 = Color3.fromRGB(255, 255, 255)}
					):Play()
					TweenService:Create(Off, TweenTime,
						{BackgroundColor3 = Color3.fromRGB(255, 255, 255), TextColor3 = Color3.fromRGB(0, 0, 0)}
					):Play()
				end
			end)
		end,
	}
	
	-- Create all buttons of all categories. Only fire once at the beginning of player loading.
	local function createSettingsButtons ()
		for _,SettingCategory in pairs(Settings:GetChildren()) do
			for _,Setting in pairs(SettingCategory:GetChildren()) do
				if Setting:GetAttribute("Show") and Setting:GetAttribute("Type") and typeCreation[Setting:GetAttribute("Type")] then
					local SettingButton = ButtonPrimes[Setting:GetAttribute("Type")]:Clone()
					SettingButton.Visible = false
					SettingButton.Interactable = false
					SettingButton.Title.Text = Setting.Name
					SettingButton.Name = Setting.Name
					SettingButton.Setting.Value = Setting
					if Setting:GetAttribute("LayoutOrder") then
						SettingButton.LayoutOrder = Setting:GetAttribute("LayoutOrder")
					end
					SettingButton.Parent = ContainerFrame[SettingCategory.Name]
					
					typeCreation[Setting:GetAttribute("Type")](Setting,SettingCategory,SettingButton)
				end
			end
		end
	end
	
	-- Show all buttons in the SelectedCategory. Hide all other buttons.
	local function showCurrentCategory ()
		-- Disable any keybind setting
		if KeyToSet then
			KeyToSet.Text = string.upper(KeyToSet.Parent.Parent.Setting.Value.Value)
			KeyToSet = nil
		end
		
		for _,SettingCategory in pairs(ContainerFrame:GetChildren()) do
			for _,SettingButton in pairs(SettingCategory:GetChildren()) do
				if SettingButton:IsA("Frame") then
					if SettingCategory.Name == SelectedCategory then
						SettingButton.Visible = true
						SettingButton.Interactable = true
					else
						SettingButton.Visible = false
						SettingButton.Interactable = false
					end
				end
			end
		end
	end
	
	-- Create category buttons and set up their functions for changing them.
	local function createCategoryButtons ()
		for _,CategoryButton in pairs(CategoryFrame:GetChildren()) do
			if CategoryButton:IsA("ImageButton") then
				CategoryButton.MouseButton1Click:Connect(function()
					for _, otherCategoryButton in pairs(CategoryFrame:GetChildren()) do
						if otherCategoryButton:IsA("ImageButton") then
							TweenService:Create(otherCategoryButton.Frame.Line,TweenInfo.new(0.3),{BackgroundTransparency = 1}):Play()
							TweenService:Create(otherCategoryButton.Frame.SettingsLabel,TweenInfo.new(0.3),{TextTransparency = 0.6}):Play()
						end
					end
					SelectedCategory = CategoryButton.Name
					TweenService:Create(CategoryButton.Frame.Line,TweenInfo.new(0.3),{BackgroundTransparency = 0.35}):Play()
					TweenService:Create(CategoryButton.Frame.SettingsLabel,TweenInfo.new(0.3),{TextTransparency = 0.35}):Play()
					showCurrentCategory()
				end)
			end
		end
	end
	
	-- Check if key is already assigned in a keybind.
	local function isKeyAlreadyAssigned (KeyName)
		for _,OtherKeys in pairs(Settings.Keybinds:GetChildren()) do
			if OtherKeys.Value == KeyName then
				return true
			end
		end
		return false
	end
	
	UserInputService.InputBegan:Connect(function(Key)
		if not CommonFuncs.AreInputUIsActive("Settings") then
			if Key.KeyCode == KeybindHandler.Keybind("Settings",Player) then
				if Main.Interactable then -- Hide UI
					Main.Interactable = false
					Modal.Modal = false
					TweenService:Create(Main,TweenInfo.new(0.2),{GroupTransparency = 1}):Play()
					
					-- Disable any keybind setting
					if KeyToSet then
						KeyToSet.Text = string.upper(KeyToSet.Parent.Parent.Setting.Value.Value)
						KeyToSet = nil
					end
					
				else -- Show UI
					Main.Interactable = true
					Modal.Modal = true
					TweenService:Create(Main,TweenInfo.new(0.2),{GroupTransparency = 0}):Play()
				end
			end
			
			if Key.KeyCode ~= Enum.KeyCode.Unknown 
				and KeyToSet
			then
				-- The Key is part of an Assign button type.
				if KeyToSet:GetAttribute("Type") == "Assign" then
					-- Check if key is bound or if it is forbidden.
					if isKeyAlreadyAssigned(Key.KeyCode.Name) and KeyToSet.Parent.Parent.Setting.Value.Value ~= Key.KeyCode.Name 
						or table.find(ForbiddenKeybinds,Key.KeyCode) 
					then
						-- Key is forbidden, notify with red text and error message.
						KeyToSet.Text = string.upper(Key.KeyCode.Name).." IS ALREADY BOUND"
						ColorShiftAssign(KeyToSet,Color3.fromRGB(255, 20, 20))
					else
						-- Bind new key and change text, and give a cool green text for added coolness.
						KeyToSet.Text = string.upper(Key.KeyCode.Name)
						ColorShiftAssign(KeyToSet,Color3.fromRGB(20, 255, 20))
						SetSetting(KeyToSet.Parent.Parent.Setting.Value, Key.KeyCode.Name)
						KeyToSet = nil
					end
				-- The Key is part of a Slider button type.
				elseif KeyToSet:GetAttribute("Type") == "Slider" then
					if table.find(NumberKeys,Key.KeyCode) 
						or Key.KeyCode == Enum.KeyCode.Backspace 
						or Key.KeyCode == Enum.KeyCode.Return 
					then
						local Setting = KeyToSet.Parent.Parent.Setting.Value
						local SliderBar = KeyToSet.Parent.BarFrame.SliderBar
						local UIDragDetector = SliderBar.UIDragDetector
						local Min = Setting:GetAttribute("Min")
						local Max = Setting:GetAttribute("Max")

						-- Enter in the new numbers
						if Key.KeyCode == Enum.KeyCode.Return then
							EnterNewSliderNumber(Setting, UIDragDetector, Min, Max)
						-- Subtract character from number (if it can) if backspace is pressed.
						elseif Key.KeyCode == Enum.KeyCode.Backspace then
							local AmountToSubtract = if #KeyToSet.Text - 1 < 0
								then 0
								else 1
							KeyToSet.Text = string.sub(KeyToSet.Text, 1, #KeyToSet.Text - AmountToSubtract) 
						-- Input character to number (if not exceeding Max's amount of characters) if number key is pressed.	
						elseif #KeyToSet.Text <= #tostring(Max) - 1 and Key.KeyCode ~= Enum.KeyCode.Zero 
							or #KeyToSet.Text <= #tostring(Max) - 1 and (Key.KeyCode == Enum.KeyCode.Zero and #KeyToSet.Text > 0) then
							KeyToSet.Text = KeyToSet.Text .. WordToNumber[Key.KeyCode.Name]
						end	
						
						SetSlider(Setting, UIDragDetector, Min, Max)
					end
				end
			end	
		end
	end)
	
	--Startup
	createSettingsButtons()
	showCurrentCategory()
	createCategoryButtons()
	SettingsUI.Enabled = true
end

return module
