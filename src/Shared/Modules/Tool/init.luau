local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local KeybindHandler = require(ReplicatedStorage.Modules.UI.KeybindHandler)
local ViewModelHandler = nil -- STUPID recursive requires() 💔
local Utils = require(ReplicatedStorage.Modules.Utils)
local CTF = nil
local CommonFuncs = nil

-- Preliminary important global variables.
local LocalPlayer = Players.LocalPlayer
local ToolDataFolder = ReplicatedStorage.Tooling.Tools

local CharacterLoaded = false
local Character: Model, Humanoid: Humanoid
local ViewModel: Model, ViewModelAnimator: Animator
local LoadedAnimations = {} -- SEEMS like we WILL be using a lot of memory because the garbage collector breaks animations now
-- at least till the next character loads and clears everything.
-- setmetatable({}, {__mode = "v"}) -- Weak table. We don't like memory leaks :blackops:

local function __load_character(character)
	LoadedAnimations = {} --setmetatable({}, {__mode = "v"})
	Character = character
	Humanoid = Character:WaitForChild("Humanoid")
	Humanoid.Died:Connect(function()
		CharacterLoaded = false
		ViewModel = nil
		ViewModelAnimator = nil
	end)
	ViewModelHandler = ViewModelHandler or require(ReplicatedStorage.ClientSrc.ViewModelHandler)
	CTF = CTF or require(script.CommonToolFunctions)
	CommonFuncs = CommonFuncs or require(ReplicatedStorage.Modules.CommonFuncs)
	ViewModel = ViewModelHandler.getViewModel()
	ViewModelAnimator = ViewModelHandler.getViewModelAnimator()
	while ViewModel == nil or ViewModelAnimator == nil do
		task.wait()
		ViewModel = ViewModelHandler.getViewModel()
		ViewModelAnimator = ViewModelHandler.getViewModelAnimator()
	end
	for _, Motor: Motor6D in ViewModel:GetDescendants() do
		if Motor:IsA("Motor6D") then
			Motor.MaxVelocity = math.huge
		end
	end
	CharacterLoaded = true
end
LocalPlayer.CharacterAdded:Connect(__load_character)
if LocalPlayer.Character then task.defer(__load_character, LocalPlayer.Character) end -- task.defer because STUPID recursive requires() 💔

--[[
	====== TYPE DEFINITIONS ======
	
	This section defines the custom type for 'Tool', and some other
	useful definitions such as the custom Enum 'Tool.State'.
]]

local Tool = {}
Tool.__index = Tool
Tool.ClassName = "Tool"

export type ClassType = typeof(setmetatable(
	{} :: {
		ToolType: string;
		Instance: Tool;
		Handle: BasePart;
		Sounds: Folder;
		Animations: {[string] : Animation};
		
		State: number; -- This is an Enum; Use Tool.State.VALUE to set.
		Bindings: {[string] : {
			InputType: Enum.UserInputType;
			InputState: Enum.UserInputState;
			DebugBinding: Enum.KeyCode; -- useful for testing when you don't wanna create an entirely new keybind; should be nil otherwise.
			Handler: (InputObject, boolean) -> nil};
		}; -- Binding name to binding object map.
		Connections: {[string] : RBXScriptConnection};
		
		Settings: {
			EquipSpeed: number;
			EquipCancel: number;
			UnequipSpeed: number;
			
			Description: string;
			InventorySize: Vector2;
			InventoryImage: string;
		};
	},
	Tool
))

-- Sort of a custom "Enum".
Tool.State = {
	["Unequipped"] = 0;
	["Equipping"] = 1;
	["Equipped"] = 2;
	["Unequipping"] = 3;
}

setmetatable(Tool.State, {
	__index = function(_self, key) -- only called when the indexed member is not present in the table.
		error(`{tostring(key)} is not a valid member of the Enum Tool.State`, 2)
	end
})

--[[
	====== FUNCTION DEFINITIONS ======

	Functions defined here are statically accessible; they are not linked
	to any particular object. This includes the new object function and
	other utilities.
]]

--[=[
	Returns true if the ViewModel's Animator is loaded and
	tools are ready to have their "Init()" function called.
	Otherwise returns false.
]=]
function Tool.isReady()
	return CharacterLoaded
end

function Tool.getHumanoid()
	return Humanoid
end

function Tool.new(ToolInstance: Tool): ClassType
	assert(ToolInstance and typeof(ToolInstance) == "Instance" and ToolInstance:IsA("Tool"), `You must provide a 'Tool' instance, got {ToolInstance}.`)
	local self: ClassType = setmetatable({}, Tool)
	
	local ToolObjects = ToolDataFolder:FindFirstChild(ToolInstance:GetAttribute("ToolName") or "undefined tool name") or error(`Failed to find ToolObjects for {ToolInstance:GetFullName()}`)
	self.Settings = require(ToolObjects.Settings)

	self.Instance = ToolInstance
	self.Handle = ToolInstance:FindFirstChild("Handle")
	self.Sounds = ToolObjects.Sounds
	
	self.Instance.Destroying:Once(Utils.wrapMethod(self, self.Destroy))
	for _, Motor: Motor6D in self.Instance:GetDescendants() do
		if Motor:IsA("Motor6D") then
			Motor.MaxVelocity = math.huge
		end
	end
	
	self.State = Tool.State.Unequipped
	self.Bindings = {}
	self.AnimationEvents = {}
	self.Connections = {} -- All connections here are disconnected automatically on unequipping.
	-- Animations
	self.Animations = {}
	for _, v in ToolObjects.VMAnimations:GetChildren() do
		self.Animations[v.Name] = v
	end
	self.__loaded_animations = {} -- Don't use this, it's only used as a strong reference to loaded animations, as the global one is a weak table.
	
	self.Bindings = {
		["Drop"] = {
			InputType = Enum.UserInputType.Keyboard;
			InputState = Enum.UserInputState.Begin;
			DebugBinding = nil;
			Handler = Utils.wrapMethod(self, self.Drop);
		}
	}
	
	return self
end

--[[
	====== METHOD DEFINITIONS ======

	Functions defined here are associated with unique objects.
	This includes functions for animation handling, default methods, etc.
]]

function Tool:Init()
	for animationName, Animation in self.Animations do
		self:GetAnimation(animationName, Animation)
	end
end

-- REMEMBER TO CALL THIS BEFORE DEREFERENCING TO AVOID MEMORY LEAKS!!!
function Tool:Destroy()
	self:__disable()
	for i, _ in self do
		self[i] = nil
	end
	setmetatable(self, {__index = function()
		error("This object was destroyed and is no longer accessible")
	end})
end

function Tool:Equip()
	if self.State ~= Tool.State.Unequipped then return end
	self.State = Tool.State.Equipping
	Humanoid:EquipTool(self.Instance)
	self.Instance.Unequipped:Once(Utils.wrapMethod(self, self.Unequip))
	self:PlayAnimationFor("Equip", self.Settings.EquipSpeed)
	self.__task = task.delay(self.Settings.EquipSpeed, self.PlayAnimation, self, "Hold")
	task.wait(self.Settings.EquipCancel)
	self:__enable()
end

function Tool:Unequip()
	if self.State ~= Tool.State.Equipped then return end
	self.State = Tool.State.Unequipping
	self:PlayAnimationFor("Unequip", self.Settings.UnequipSpeed)
	self:StopAnimation("Equip")
	self:StopAnimation("Hold")
	task.wait(self.Settings.UnequipSpeed)
	for _, PlayingAnimation in ViewModelAnimator:GetPlayingAnimationTracks() do
		-- this down here looks stupid, but don't remove it. you have to PLAY the animation with the desired fadeTime and weight
		-- if you want them to work, because fadeTime and weight parameters of both :Stop() and :AdjustWeight() DON'T EVEN WORK.
		-- in fact, im pretty sure removing the 0.0001 parameter in StopAnimation() will have NO impact whatsoever.
		PlayingAnimation:Play(0.0001, 0.0001)
		PlayingAnimation:Stop(0.0001)
	end
	Humanoid:UnequipTools()
	self:__disable()
end

--[=[
	Gets the 'AnimationTrack' instance for the given animation name.

	If the animation is not already loaded, it loads the animation if provided with an Animation instance.
]=]
function Tool:GetAnimation(name: string, Animation: Animation?): AnimationTrack?
	if not CharacterLoaded then return nil end
	
	name = self.Instance.Name .. "." .. name
	if LoadedAnimations[name] then return LoadedAnimations[name] end
	if not Animation then return nil end

	local LoadedAnimation = ViewModelAnimator:LoadAnimation(Animation)
	LoadedAnimation.Name = self.Instance.Name .. "." .. name
	LoadedAnimations[name] = LoadedAnimation
	self.__loaded_animations[name] = LoadedAnimation
end

--[=[
	Plays the animation with the provided name.

	If the animation is not already loaded, it loads and plays it.
	This function may yield if the animation was not preloaded, or
	if "waitForEnd" is set to true, yielding till the animation ends.

	Returns the AnimationTrack if it successfully gets it.
]=]
function Tool:PlayAnimation(name: string, fadeTime: number?, weight: number?, speed: number?, waitForEnd: boolean?): AnimationTrack?
	local Animation = self:GetAnimation(name, self.Animations[name])
	if not Animation then return nil end
	for event, callback in self.AnimationEvents do
		self:__connect(name .. "Event" .. event, Animation:GetMarkerReachedSignal(event), callback)
	end
	Animation:Play(fadeTime, weight, speed)
	if waitForEnd then
		task.wait(Animation.Length)
	end
	
	return Animation
end

--[=[
	Plays the animation with the provided name for the given amount of time, changing speed if necessary.

	If the animation is not already loaded, it loads and plays it.
	This function may yield if the animation was not preloaded.

	Returns the AnimationTrack if it successfully gets it.
]=]
function Tool:PlayAnimationFor(name: string, playTime: number, fadeTime: number?, weight: number?): AnimationTrack?
	local Animation = self:GetAnimation(name, self.Animations[name])
	if not Animation then return nil end
	Animation:Play(fadeTime, weight, Animation.Length / (playTime or 1))
	return Animation
end

--[=[
	Stops the animation with the provided name.

	Returns the AnimationTrack if it successfully gets it.
]=]
function Tool:StopAnimation(name: string, fadeTime: number?): AnimationTrack?
	local Animation = self:GetAnimation(name)
	if not Animation then return nil end
	Animation:Stop(fadeTime)
	return Animation
end

function Tool:Drop()
	if self.State ~= Tool.State.Equipped then return end
	self:Unequip()
	CTF.dropItem(Character, self.Instance)
end

function Tool:__connect(name: string, signal: RBXScriptSignal, handler: (...any) -> (any...)): RBXScriptConnection
	if self.Connections[name] and self.Connections[name].Connected then
		self.Connections[name]:Disconnect()
	end
	self.Connections[name] = signal:Connect(handler)
	return self.Connections[name]
end

function Tool:__enable()
	self.State = Tool.State.Equipped
	local function handleInput(input: InputObject, gameProcessedEvent)
		for bindingName, binding in self.Bindings do
			local keybind = binding.DebugBinding or KeybindHandler.Keybind(bindingName, LocalPlayer)
			if keybind
			and self.State == Tool.State.Equipped
			and not CommonFuncs.AreInputUIsActive()
			and input.UserInputType == binding.InputType
			and (binding.InputState == nil or input.UserInputState == binding.InputState)
			and (if input.UserInputType == Enum.UserInputType.Keyboard then (input.KeyCode == keybind) else true)
			then
				binding.Handler(input, gameProcessedEvent)
			end
		end
	end
	self:__connect("InputHandler1", UserInputService.InputBegan, handleInput)
	self:__connect("InputHandler2", UserInputService.InputChanged, handleInput)
	self:__connect("InputHandler3", UserInputService.InputEnded, handleInput)
end

function Tool:__disable()
	self.State = Tool.State.Unequipped
	for _, connection in self.Connections do
		if connection.Connected then
			connection:Disconnect()
		end
	end
	if self.__task then
		task.cancel(self.__task)
		self.__task = nil
	end
	for animationName, _ in self.Animations do
		self:StopAnimation(animationName)
	end
end

return Tool
