local module = {}

local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local TextChatService = game:GetService("TextChatService")
local Player = game:GetService("Players").LocalPlayer

local KeybindHandler = require(ReplicatedStorage.Modules.UI.KeybindHandler)

local SelectedCategory = "General"


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
	
	local typeCreation = { -- Creation functions of each button type
		["Assign"] = function(Setting,SettingCategory,SettingButton)
		end,
		["Multistage"] = function(Setting,SettingCategory,SettingButton)
		end,
		["Slider"] = function(Setting,SettingCategory,SettingButton)
		end,
		["Switch"] = function(Setting,SettingCategory,SettingButton)
		end,
		["Toggle"] = function(Setting,SettingCategory,SettingButton)
		end,
	}
	
	local function createSettingsButtons () -- create all buttons of all categories. Only fire once at the beginning of player loading.
		for _,SettingCategory in pairs(Settings:GetChildren()) do
			for _,Setting in pairs(SettingCategory:GetChildren()) do
				if Setting:GetAttribute("Show") and Setting:GetAttribute("Type") and typeCreation[Setting:GetAttribute("Type")] then
					local SettingButton = ButtonPrimes[Setting:GetAttribute("Type")]:Clone()
					SettingButton.Visible = false
					SettingButton.Interactable = false
					SettingButton.Title.Text = Setting.Name
					SettingButton.Name = Setting.Name
					if Setting:GetAttribute("LayoutOrder") then
						SettingButton.LayoutOrder = Setting:GetAttribute("LayoutOrder")
					end
					SettingButton.Parent = ContainerFrame[SettingCategory.Name]
					
					typeCreation[Setting:GetAttribute("Type")](Setting,SettingCategory,SettingButton)
				end
			end
		end
	end
	
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
	
	local function createCategoryButtons ()
		for _,CategoryButton in pairs(CategoryFrame:GetChildren()) do
			if CategoryButton:IsA("ImageButton") then
				CategoryButton.MouseButton1Click:Connect(function()
					for _,CategoryButton in pairs(CategoryFrame:GetChildren()) do
						if CategoryButton:IsA("ImageButton") then
							CategoryButton.Frame.Line.Visible = false
							CategoryButton.Frame.SettingsLabel.TextTransparency = 0.6
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
	
	UserInputService.InputBegan:Connect(function(Key)
		if not TextChatService.ChatInputBarConfiguration.IsFocused then
			if Key.KeyCode == KeybindHandler.Keybind("Settings",Player) then
				if Main.Interactable then -- Hide UI
					Main.Interactable = false
					Modal.Modal = false
					TweenService:Create(Main,TweenInfo.new(0.2),{GroupTransparency = 1}):Play()
				else -- Show UI
					Main.Interactable = true
					Modal.Modal = true
					TweenService:Create(Main,TweenInfo.new(0.2),{GroupTransparency = 0}):Play()
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
