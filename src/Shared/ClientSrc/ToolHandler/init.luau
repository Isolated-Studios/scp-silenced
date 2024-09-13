local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local ViewModelHandler = require(script.Parent.ViewmodelHandler)
local KeybindHandler = require(ReplicatedStorage.Modules.UI.KeybindHandler)

local module = {}

local AUTOMATIC_ANIMTAIONS = {"FirstEquip", "Equip", "Hold", "Unequip"} -- animations that auto-load independantly of the tool script source.

local Tools = ReplicatedStorage.Tooling.Tools

local Character: Model? = nil
local Humanoid: Humanoid? = nil
local Animator: Animator? = nil

--[[
NOTE TO SELF !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
	instead of relying on Character.ChildAdded to detect newly added tools, use a new function called EquipTool()
	paired with UnequipTool() and call them from HotbarHandler so we don't have to rely on events like UnequipTool event
	lololoolololollol pls dont forget future me plsssssssss
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
]]

function module.LoadChar(char)
	Character = char
	Humanoid = char:WaitForChild("Humanoid")
	Animator = Humanoid:WaitForChild("Animator")

	-- this var keeps track of the count of equipped tools, this is to make sure that at any point if
	-- code below is still running, that the tool it is running on is the currently equipped one.
	local lastToolEquipId = 0
	Character.ChildAdded:Connect(function(Tool: Tool)
		if not Tool:IsA("Tool") then return end
		local ViewModel = ViewModelHandler.getViewModel()
		local ViewModelAnimator = ViewModelHandler.getViewModelAnimator()
		local ToolObjects = Tools:FindFirstChild(Tool:GetAttribute("ToolName"))
		if ViewModel == nil or ToolObjects == nil then
			Humanoid:UnequipTools()
			warn(ViewModelAnimator == nil and "ViewModel not loaded" or `Invalid ToolName: {Tool:GetAttribute("ToolName")}`)
			return
		end

		lastToolEquipId += 1
		local thisToolEquipId = lastToolEquipId

		-- Load default animations (holding and (un)equipping)
		local Settings = require(ToolObjects.Settings)
		local CharacterAnimations: {AnimationTrack} = {}
		local ViewModelAnimations: {AnimationTrack} = {}
		for _, name in AUTOMATIC_ANIMTAIONS do
			local CharAnim = ToolObjects.CharacterAnimations:FindFirstChild(name)
			local VMAnim = ToolObjects.VMAnimations:FindFirstChild(name)
			if CharAnim then
				CharacterAnimations[name] = Animator:LoadAnimation(CharAnim)
			end
			if VMAnim then
				ViewModelAnimations[name] = ViewModelAnimator:LoadAnimation(VMAnim)
			end
		end

		-- Play the (first)equip animations then the hold animation
		if Settings.EquipTime then
			Humanoid:SetAttribute("DisableEquip", true)
			local VMEquip, CharEquip = ViewModelAnimations["Equip"], CharacterAnimations["Equip"]

			local t = os.clock()
			if ViewModelAnimations["FirstEquip"] and not Tool:GetAttribute("FirstEquipActivated") then
				VMEquip, CharEquip = ViewModelAnimations["FirstEquip"], CharacterAnimations["FirstEquip"]
				VMEquip:Play()
				CharEquip:Play()
			else
				VMEquip:Play(nil, nil, VMEquip.Length / Settings.EquipSpeed)
				CharEquip:Play(nil, nil, CharEquip.Length / Settings.EquipSpeed)
				task.delay(Settings.EquipSpeed + 0.1, function() -- this is to guarantee that the animation doesn't play forever if it fails to load
					VMEquip:Stop()
					CharEquip:Stop()
				end)
			end

			task.wait(Settings.EquipTime)
			Humanoid:SetAttribute("DisableEquip", nil)

			Tool:SetAttribute("FirstEquipActivated",true)
			local inputsThatCancel = {
				KeybindHandler.Keybind("Reload", Players.LocalPlayer).Name,
				KeybindHandler.Keybind("Drop", Players.LocalPlayer).Name,
				KeybindHandler.Keybind("Feint", Players.LocalPlayer).Name,
				KeybindHandler.Keybind("Sprint", Players.LocalPlayer).Name,
				Enum.UserInputType.MouseButton1.Name,
				Enum.UserInputType.MouseButton2.Name,
			}
			local equipInputCancel = nil
			equipInputCancel = UserInputService.InputBegan:Connect(function(Input, GameProcessedEvent)
				if GameProcessedEvent then return end
				if VMEquip.IsPlaying and (table.find(inputsThatCancel, Input.UserInputType.Name) or table.find(inputsThatCancel, Input.KeyCode.Name)) then
					VMEquip:Stop(0)
					CharEquip:Stop(0)
					equipInputCancel:Disconnect()
					equipInputCancel = nil
				end
			end)

			VMEquip.Stopped:Once(function()
				ViewModelAnimations["Hold"]:Play()
				CharacterAnimations["Hold"]:Play()
				if equipInputCancel then equipInputCancel:Disconnect() end
			end)
		else
			ViewModelAnimations["Hold"]:Play()
			CharacterAnimations["Hold"]:Play()
		end

		if thisToolEquipId ~= lastToolEquipId then return end


		Tool.Unequipped:Once(function()
			ViewModelAnimations["Hold"]:Stop()
			CharacterAnimations["Hold"]:Stop()
		end)

		ReplicatedStorage.Events.Viewmodel.UnequipTool.Event:Once(function(t)
			if t ~= Tool then return end
			ViewModelAnimations["Hold"]:Stop()
			CharacterAnimations["Hold"]:Stop()
			-- play unequip animation at speed { UnequipAnimation.Length / Settings.UnequipSpeed }
			if Settings.UnequipSpeed then
				ViewModelAnimations["Unequip"]:Play(nil, nil, ViewModelAnimations["Unequip"].Length / Settings.EquipSpeed)
				CharacterAnimations["Unequip"]:Play(nil, nil, CharacterAnimations["Unequip"].Length / Settings.EquipSpeed)
				task.delay(Settings.EquipSpeed + 0.1, function() -- this is to guarantee that the animation doesn't play forever if it fails to load
					ViewModelAnimations["Unequip"]:Stop()
					CharacterAnimations["Unequip"]:Stop()
				end)
			end
		end)

		-- Load tool script
		if Tool:GetAttribute("ToolSource") and script:FindFirstChild(Tool:GetAttribute("ToolSource")) then
			local Source = require(script[Tool:GetAttribute("ToolSource")])
			Source.Init(Tool, ToolObjects, Character, ViewModel)
		end
	end)
end

function module.UnloadChar(char)
	Character = nil
end

return module
