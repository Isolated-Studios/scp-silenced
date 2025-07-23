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
			
			-- Reset keybind to default.
			Reset.MouseButton1Click:Connect(function()
				Setting.Value = Setting:GetAttribute("Default")
				Key.Text = string.upper(Setting.Value)
				KeyToSet = nil
			end)
		end,
		["Multistage"] = function(Setting, SettingCategory, SettingButton)
		end,
		["Slider"] = function(Setting, SettingCategory, SettingButton)
		end,
		["Switch"] = function(Setting, SettingCategory, SettingButton)
		end,
		["Toggle"] = function(Setting, SettingCategory, SettingButton)
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
							otherCategoryButton.Frame.Line.Visible = false
							otherCategoryButton.Frame.SettingsLabel.TextTransparency = 0.6
						end
					end
					SelectedCategory = CategoryButton.Name
					CategoryButton.Frame.Line.Visible = true
					CategoryButton.Frame.SettingsLabel.TextTransparency = 0.35
					showCurrentCategory()
				end)
			end
		end
	end
	
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
				-- Check if key is bound or if it is forbidden.
				if isKeyAlreadyAssigned(Key.KeyCode.Name) and KeyToSet.Parent.Parent.Setting.Value.Value ~= Key.KeyCode.Name 
					or table.find(ForbiddenKeybinds,Key.KeyCode) 
				then
					-- Key is forbidden, notify with red text and error message.
					KeyToSet.Text = string.upper(Key.KeyCode.Name).." IS ALREADY BOUND"
					KeyToSet.TextColor3 = Color3.fromRGB(255,0,0)
					KeyToSet.UIStroke.Color = Color3.fromRGB(255,0,0)
					TweenService:Create(KeyToSet, TweenInfo.new(0.7), {TextColor3 = Color3.fromRGB(255,255,255)}):Play()
					TweenService:Create(KeyToSet.UIStroke, TweenInfo.new(0.7), {Color = Color3.fromRGB(255,255,255)}):Play()
				else
					-- Bind new key and change text, and give a cool green text for added coolness.
					KeyToSet.Text = string.upper(Key.KeyCode.Name)
					KeyToSet.TextColor3 = Color3.fromRGB(0,255,0)
					KeyToSet.UIStroke.Color = Color3.fromRGB(0,255,0)
					TweenService:Create(KeyToSet, TweenInfo.new(0.7), {TextColor3 = Color3.fromRGB(255,255,255)}):Play()
					TweenService:Create(KeyToSet.UIStroke, TweenInfo.new(0.7), {Color = Color3.fromRGB(255,255,255)}):Play()
					KeyToSet.Parent.Parent.Setting.Value.Value = Key.KeyCode.Name
					KeyToSet = nil
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
