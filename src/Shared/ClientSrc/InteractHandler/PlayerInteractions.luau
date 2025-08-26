local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Player = game:GetService("Players").LocalPlayer

local Modules = ReplicatedStorage.Modules
local Events = ReplicatedStorage.Events
local Tooling = ReplicatedStorage.Tooling
local Sounds = ReplicatedStorage.Sounds

local ToolingTools = Tooling.Tools
local ReviveEvent = Events.Character.ReviveEvent

local DefaultPlayerAnimations = ReplicatedStorage.PlayerAssets.Animations
local OtherCharacterAnimations = DefaultPlayerAnimations.Character.Other
local OtherVMAnimations = DefaultPlayerAnimations.Viewmodel.Other

local Utils = require(Modules.Utils)
local ViewModelHandler = require(ReplicatedStorage.ClientSrc.ViewModelHandler)
local KeybindHandler = require(Modules.UI.KeybindHandler)
local Deathnotes = require(script.Parent.Deathnotes)
local Messager = require(Modules.UI.Messager)
local CommonFuncs = require(Modules.CommonFuncs)

--local ExecuteAnim = Animator:LoadAnimation(OtherCharacterAnimations.Execute)
--local ExecuteTargetAnim = Animator:LoadAnimation(OtherCharacterAnimations.Execute)
--local ExecuteVMAnim = Animator:LoadAnimation(OtherVMAnimations.Execute)

return {
	[0] = function(InteractObject) -- Message from Deathnote
		local Profile = InteractObject.Profile
		
		local TextToMessage = Deathnotes.Messages(Player, Profile)
		Messager.SendMessage(TextToMessage)
	end,
	
	[6] = function(InteractObject) -- Chair
		local Camera = workspace.CurrentCamera
		local Character = Player.Character
		local Humanoid = Player.Character:FindFirstChild("Humanoid")
		local HumanoidSeat = Humanoid:WaitForChild("Seat")
		local Seat = nil
		local InputBegan = nil
		local NoSeatFound = true
		
		if Humanoid:GetAttribute("Sitting") then
			Messager.SendMessage("Already Seated.")
			return
		end
		
		if InteractObject:GetAttribute("Seats") then
			for i=1,InteractObject:GetAttribute("Seats"),1 do
				local Seat = InteractObject:FindFirstChild("Seat"..i)
				if not Seat.Occupant then
					Camera.CFrame = Seat.CFrame
					HumanoidSeat.Value = Seat
					Humanoid:SetAttribute("Sitting", true)
					Seat:Sit(Humanoid)
					HumanoidSeat.Value = Seat
					NoSeatFound = false
					break
				end
			end
		else
			local Seat = InteractObject:FindFirstChild("Seat") or InteractObject:FindFirstChild("Seat1")
			if not Seat.Occupant then
				Camera.CFrame = Seat.CFrame
				HumanoidSeat.Value = Seat
				Humanoid:SetAttribute("Sitting", true)
				Seat:Sit(Humanoid)
				NoSeatFound = false
			end
		end
		
		if NoSeatFound then
			Messager.SendMessage("Seat is Occupied.")
		end
	end,
	
	[7] = function(InteractObject) -- Vending Machine

	end,
	
	[8] = function(InteractObject) -- the cat.
		Utils.SFX.playSound(Sounds.Miscellaneous.Cat.Meow, nil, InteractObject, true, true)
	end,
	
	["Revive"] = function(InteractObject)
		task.defer(function()
			local Character = Player.Character
			local Animator = Character.Humanoid.Animator
			local ReviveAnim = Animator:LoadAnimation(OtherCharacterAnimations.Revive)
			local ReviveVMAnim = Animator:LoadAnimation(OtherVMAnimations.Revive)
			InteractObject:SetAttribute("freezePlayer",nil)
			InteractObject:SetAttribute("interactable",nil)
			InteractObject:SetAttribute("interactAnimId",nil)
			InteractObject:SetAttribute("interactFinishEventId",nil)
			InteractObject:SetAttribute("interactText",nil)
			InteractObject:SetAttribute("interactTime",nil)
			InteractObject:SetAttribute("maxRange",nil)
			InteractObject:SetAttribute("NoHighlight",nil)
			local reviveTime = 5
			local currentReviveAnimation = ReviveAnim
			local currentVMReviveAnimation = ReviveVMAnim
			if Player.Character:FindFirstChildOfClass("Tool") and Player.Character:FindFirstChildOfClass("Tool"):GetAttribute("ToolName") then
				local ToolsFolder = ToolingTools[Player.Character:FindFirstChildOfClass("Tool"):GetAttribute("ToolName")]
				if ToolsFolder.CharacterAnimations:FindFirstChild("Revive") then
					currentReviveAnimation = Animator:LoadAnimation(ToolsFolder.CharacterAnimations.Revive)
				end
				if ToolsFolder.VMAnimations:FindFirstChild("Revive") then
					currentVMReviveAnimation = ViewModelHandler.getAnimation(ToolsFolder.VMAnimations.Revive)
				end
				local Settings = require(ToolsFolder.Settings)
				if Settings.CanRevive then
					reviveTime = Settings.ReviveTime or reviveTime
				end
			end
			Character.Humanoid:SetAttribute("DisableEquip",true)
			currentReviveAnimation:Play()
			currentVMReviveAnimation:Play()
			currentVMReviveAnimation:AdjustSpeed(currentVMReviveAnimation.Length/reviveTime)
			currentReviveAnimation:AdjustSpeed(currentReviveAnimation.Length/reviveTime)
			local severFromInput = false
			local currentTime = tick()
			local downedHumanoid = InteractObject:WaitForChild("Humanoid")
			local CircularTweenUp = TweenService:Create(CircularNum,TweenInfo.new(reviveTime,Enum.EasingStyle.Sine,Enum.EasingDirection.InOut),{Value = 100})
			local CircularTweenDown = TweenService:Create(CircularNum,TweenInfo.new(0.1,Enum.EasingStyle.Sine,Enum.EasingDirection.InOut),{Value = 0})
			CircularTweenUp:Play()
			local reviveInputBegan = UserInputService.InputBegan:Connect(function(key)
				if key.KeyCode == Enum.KeyCode.W or
					key.KeyCode == Enum.KeyCode.S or
					key.KeyCode == Enum.KeyCode.A or
					key.KeyCode == Enum.KeyCode.D or
					key.KeyCode == KeybindHandler.Keybind("Interact",Player) or
					key.KeyCode == KeybindHandler.Keybind("Reload",Player) or
					key.UserInputType == Enum.UserInputType.MouseButton1 and Character:FindFirstChildOfClass("Tool") then
					severFromInput = true
				end
			end)
			while tick()-currentTime < reviveTime do
				if severFromInput or downedHumanoid.Health <= 0 then
					break
				end
				task.wait()
			end
			Character.Humanoid:SetAttribute("DisableEquip",nil)
			currentReviveAnimation:Stop()
			currentVMReviveAnimation:Stop()
			CircularTweenDown:Play()
			if tick()-currentTime >= reviveTime then
				ReviveEvent:FireServer(Character,InteractObject)
			else
				ReviveEvent:FireServer(Character,InteractObject,true)
			end
			reviveInputBegan:Disconnect()
		end)
	end;

	["Execute"] = function(Player, InteractObject)
		MessageText.Text = "EXECUTING: "..string.upper(InteractObject.Name)
		local character = Player.Character
		character.Humanoid:SetAttribute("DisableEquip",true)

		if character:FindFirstChildOfClass("Tool") then

		end
	end
}
