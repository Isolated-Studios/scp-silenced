local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local ViewModelHandler = nil -- has to be injected to avoid circular dependencies
local KeybindHandler = require(ReplicatedStorage.Modules.UI.KeybindHandler)
local CTF = require(ReplicatedStorage.Modules.Tool.CommonToolFunctions)

local module = {}

local AUTOMATIC_ANIMATIONS = {"FirstEquip", "Equip", "Hold", "Unequip"} -- animations that auto-load independantly of the tool script source.

local Tools = ReplicatedStorage.Tooling.Tools

local Character: Model? = nil
local Backpack: Backpack? = nil
local Humanoid: Humanoid? = nil
local Animator: Animator? = nil

local CurrentEquipID = ""
local UnequipFunctions = {}

function module.injectViewModelHandler(h)
	ViewModelHandler = h
end

function module.LoadChar(Char)
	Character = Char
	Backpack = Players.LocalPlayer:WaitForChild("Backpack")
	Humanoid = Char:WaitForChild("Humanoid")
	Animator = Humanoid:WaitForChild("Animator")
end

function module.UnloadChar(char)
	Character = nil
end

function module.EquipTool(Tool: Tool)
	if ViewModelHandler == nil then return end
	if typeof(Tool) ~= "Instance" or not Tool:IsA("Tool") then return end
	Tool:SetAttribute("Unequipping", false)
	Humanoid:EquipTool(Tool)
	Humanoid:SetAttribute("Equipping",true) --/ Used for HotbarHandler so you can't equip other tools while equipping
	local ViewModel = ViewModelHandler.getViewModel()
	local ViewModelAnimator = ViewModelHandler.getViewModelAnimator()
	local ToolObjects = Tools:FindFirstChild(Tool:GetAttribute("ToolName"))
	if ViewModel == nil or ToolObjects == nil then
		Humanoid:UnequipTools()
		warn(ViewModelAnimator == nil and "ViewModel not loaded" or `Invalid ToolName: {Tool:GetAttribute("ToolName")}`)
		return
	end

	CurrentEquipID = tick()
	local thisEquipID = CurrentEquipID

	-- Load default animations (holding and (un)equipping)
	local Settings = require(ToolObjects.Settings)
	local CharacterAnimations: {AnimationTrack} = {}
	local ViewModelAnimations: {AnimationTrack} = {}
	for _, name in AUTOMATIC_ANIMATIONS do
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
	if Settings.EquipSpeed then
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

		local animationEventsList = {}
		local animationEvents = CTF.getAllAnimationEventNames(VMEquip) --/ get event marker names of VMEquip
		if animationEvents then
			for _,event in pairs(animationEvents) do
				local eventFunction = VMEquip:GetMarkerReachedSignal(event):Connect(function(parameter) --/ Marker of any kind was reached
					if ToolObjects.Sounds:FindFirstChild(event) then --/ Play sound for marker with corresponding sound name
						CTF.playSound(ToolObjects.Sounds,"MagOut",ViewModel.MotorModel.Handle,true,true)
					end
				end)
				table.insert(animationEventsList,eventFunction) --/ add to a table to later be disconnected
			end
		end

		task.wait(Settings.EquipCancel or 0)

		for _,animationEvent in pairs(animationEventsList) do --/ Disconnect all animation events
			animationEvent:Disconnect()
		end

		if thisEquipID ~= CurrentEquipID then return end
		if Tool.Parent ~= Character then return end

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
			if Tool.Parent == Character and ViewModelAnimations["Unequip"].TimePosition == 0 then -- Unequip is guaranteed to be played out and Hold can play
				ViewModelAnimations["Hold"]:Play()
				CharacterAnimations["Hold"]:Play()
			end
			if equipInputCancel then equipInputCancel:Disconnect() end
		end)

	else
		ViewModelAnimations["Hold"]:Play()
		CharacterAnimations["Hold"]:Play()
	end

	if thisEquipID ~= CurrentEquipID then return end

	Tool.Unequipped:Once(function()
		ViewModelAnimations["Hold"]:Stop()
		CharacterAnimations["Hold"]:Stop()

		task.wait(0.1)
		for _, animation in pairs(ViewModelAnimations) do
			animation:Destroy()
		end
		for _, animation in pairs(CharacterAnimations) do
			animation:Destroy()
		end
	end)
	
	Tool:GetAttributeChangedSignal("Dropping"):Once(function() --/ Temporary thing until CTF.dropItem() is ported over to this script
		module.DropTool(Tool)
	end)
	
	UnequipFunctions[Tool] = function(playAnimations)
		Tool:SetAttribute("Unequipping", true)
		ViewModelAnimations["Hold"]:Stop()
		CharacterAnimations["Hold"]:Stop()

		for _,PlayingAnimation in pairs(Animator:GetPlayingAnimationTracks()) do -- Because stopping Hold didnt WORK I HATE THIS GAMEEEEE
			if table.find(AUTOMATIC_ANIMATIONS,PlayingAnimation.Name) then
				PlayingAnimation:Stop(0)
			end
		end

		-- play unequip animation at speed { UnequipAnimation.Length / Settings.UnequipSpeed }
		if playAnimations and Settings.UnequipSpeed then
			CharacterAnimations["Unequip"]:Play(nil, nil, CharacterAnimations["Unequip"].Length / Settings.UnequipSpeed)
			ViewModelAnimations["Unequip"]:Play(nil, nil, ViewModelAnimations["Unequip"].Length / Settings.UnequipSpeed)

			-- this is to guarantee that the animation doesn't play forever if it fails to load
			task.wait(Settings.UnequipSpeed)
			ViewModelAnimations["Unequip"]:Stop()
			CharacterAnimations["Unequip"]:Stop()
		elseif Settings.UnequipSpeed then
			CharacterAnimations["Unequip"]:Play(nil, nil, 0)
			ViewModelAnimations["Unequip"]:Play(nil, nil, 0)
			task.wait()
			ViewModelAnimations["Unequip"]:Stop()
			CharacterAnimations["Unequip"]:Stop()
		end

		for _,PlayingAnimation in pairs(Animator:GetPlayingAnimationTracks()) do -- BECAUSE STOPPING STILL DIDN'T WORK I NEED TO TRY AGAIN
			if table.find(AUTOMATIC_ANIMATIONS,PlayingAnimation.Name) then
				PlayingAnimation:Stop(0)
			end
		end
		Humanoid:UnequipTools()
		Tool:SetAttribute("Unequipping", false)
		task.delay(0.1, function()
			for _, animation in pairs(ViewModelAnimations) do
				animation:Destroy()
			end
			for _, animation in pairs(CharacterAnimations) do
				animation:Destroy()
			end
		end)
	end

	Humanoid:SetAttribute("Equipping",nil) --/ Used for HotbarHandler so you can't equip other tools while equipping

	-- Load tool script
	if Tool:GetAttribute("ToolSource") and script:FindFirstChild(Tool:GetAttribute("ToolSource")) then
		local Source = require(script[Tool:GetAttribute("ToolSource")])
		Source.Init(Tool, ToolObjects, Character, ViewModel)
	end
end

function module.DropTool(Tool: Tool)
	CurrentEquipID = ""
	if UnequipFunctions[Tool] then
		UnequipFunctions[Tool]()
		UnequipFunctions[Tool] = nil
	end
end

function module.UnequipTool(Tool: Tool)
	CurrentEquipID = ""
	if UnequipFunctions[Tool] then
		UnequipFunctions[Tool](true)
		UnequipFunctions[Tool] = nil
	end
end

function module.UnequipTools()
	CurrentEquipID = ""
	for Tool, unequipFunction in pairs(UnequipFunctions) do
		unequipFunction(true)
	end
	UnequipFunctions = {}
end

return module
