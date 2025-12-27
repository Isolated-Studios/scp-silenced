local module = {}
--//Services
local UIS = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

--//Service Objects
local TemporaryParts = workspace:WaitForChild("TemporaryParts")
local Objects = ReplicatedStorage.Objects
local Modules = ReplicatedStorage.Modules
local Events = ReplicatedStorage.Events
local ClientSrc = ReplicatedStorage.ClientSrc
local CameraModule = require(ClientSrc.Camera)

local Casings = Objects.Casings
local ToolEvents = Events.Tool
local ViewmodelEvents = Events.Viewmodel
local CharacterEvents = Events.Character

local ToolModules = Modules.Tool
local UIModules = Modules.UI

--//Modules
local CTF = require(ToolModules.CommonToolFunctions)
local CustomMouse = require(UIModules.CustomMouse)
local KeybindHandler = require(UIModules.KeybindHandler)
local springModule = require(ToolModules.spring)
local ScopeModule = require(ToolModules.Scope)

--//Events
local HumanoidAttributeEvent = CharacterEvents.HumanoidAttribute
local Aim = ViewmodelEvents.Aim
local SetItemHolder = ToolEvents.SetItemHolder
local AnimationModifier = ToolEvents.AnimationModifier

---//Module Setup
local recoilSpring = springModule.new(nil,nil,nil,nil,6)

function module.Init(Tool,ToolObjects,Character,Viewmodel)
	if Tool.Parent ~= Character then return end
	Tool:SetAttribute("Activated",true)
	local Settings = require(ToolObjects:WaitForChild("Settings"))
	--//Player
	local AmmoList = Character:WaitForChild("Ammo")
	local MotorModel = Viewmodel:WaitForChild("MotorModel")
	local Player = game.Players.LocalPlayer
	local Mouse = Player:GetMouse()
	local PlayerGui = Player:WaitForChild("PlayerGui")
	local Camera = workspace.CurrentCamera
	local Humanoid = Character:WaitForChild("Humanoid")
	local HRP = Character:WaitForChild("HumanoidRootPart")

	--UI
	local HUD = PlayerGui:WaitForChild("HUD")
	local CrosshairPercent = PlayerGui:WaitForChild("MouseUI"):WaitForChild("Crosshair")
	local GunVignette = HUD:WaitForChild("GunVignette")
	local VignetteAmount = GunVignette.Gradient.VignetteAmount

	--//Tool Objects
	local Sounds = ToolObjects:WaitForChild("Sounds")
	local Handle = MotorModel:WaitForChild("Handle")
	local Flash = Handle:WaitForChild("Flash")
	local Eject = Handle:WaitForChild("Eject")
	local PrimeCasing = Casings["Air"]
	local Holder = Tool:WaitForChild("Holder")
	local boltInstanceValue = Holder:WaitForChild("Bolted")
	local magInstanceValue= Holder:WaitForChild("Mag")
	local ammoInstanceValue = AmmoList:WaitForChild(Settings.AmmoType)

	--//Bools
	local Hammer = nil
	local Cylinder = nil
	local BackBoltC1 = nil
	local DefaultBoltC1 = nil
	local BoltBackTween = nil
	local Equipped = true
	local HoldFire = false
	local FireCooldown = false
	local Aiming = false
	local Bolted = false
	local Bursting = false
	local Reloading = false
	local CancelReload = false
	local spreadReduction = false

	--//Sets
	local BulletSpread = math.round(Settings.MinSpread)
	local BoltPosition = Settings.BoltPosition or {"LookVector",0.2}
	local VignetteTween = nil
	local ModificationList = {}

	--//Beginning Priming
	CrosshairPercent.Value = BulletSpread
	
	if Handle:FindFirstChild("Hammer") then
		Hammer = Handle.Hammer
	end
	if Handle:FindFirstChild("Cylinder") then
		Cylinder = Handle.Cylinder
	end

	local function boltGun ()

		if VMBolt then
			animationHandle("Bolt","Play")
			if not Settings.BoltRoundEvent then
				VMBolt.Stopped:Wait()
				animationHandle("Bolt","Stop")
			end
		end
		if not Settings.BoltRoundEvent then
			SetItemHolder:FireServer(Tool,"Bolted",true)
			Bolted = true
			HoldFire = false
		end
	end

	local function fireGun () --/ Big evil function that fires the gun
		if Bolted == false then return end --/ the mag is empty

		Bolted = false --/ subtract a round from the mag

		SetItemHolder:FireServer(Tool,"Mag",magInstanceValue.Value) -- UI shenanigans

		if magInstanceValue.Value == 0 and Settings.BoltBackWhenEmpty and Handle:FindFirstChild("Bolt") then
			--/ pushes the bolt back if BoltBackWhenEmpty is true and mag is empty
			local Bolt = Handle.Bolt
			BoltBackTween:Play()
			Tool:SetAttribute("BoltSet",true)
		end

		task.wait(60/Settings.RPM)
		boltGun()
		HoldFire = false
	end

	local function checkRunning ()
		if Humanoid:GetAttribute("Running") then
			if Aiming then
				AimGun(false)
			end
			if Reloading and not CancelReload and Settings.ReloadStyle == 0 and not Settings.RunAndReload then
				CancelReload = true
			elseif Reloading and Settings.ReloadStyle == 1 and not Settings.RunAndReload then
				Reloading = false
				animationHandle("Reload1","Stop",0.1)
				if Settings.EmptyReload then
					animationHandle("EmptyReload","Stop",0.1)
				end
			end
			if not Settings.RunAndGun then
				animationHandle("Run","Play",0.3)
			end
		else
			if UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
				AimGun(true)
			end
			if UIS:IsKeyDown(KeybindHandler.Keybind("Reload",Player)) then
				Reload()
			end
			animationHandle("Run","Stop",0.3)
		end
	end

	--//Actions
	if Humanoid:GetAttribute("Running") then
		checkRunning()
	end

	if UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
		AimGun(true)
	end

	if boltInstanceValue.Value then
		if Settings.HammerAngle then
			Hammer.C0 = CFrame.new(Hammer.C0.Position)*CFrame.Angles(math.rad(Settings.HammerAngle.X),math.rad(Settings.HammerAngle.Y),math.rad(Settings.HammerAngle.Z))
		end
		if Settings.CylinderAngle then
			Cylinder.C0 = CFrame.new(Cylinder.C0.Position)*CFrame.Angles(math.rad(Settings.CylinderAngle.X),math.rad(Settings.CylinderAngle.Y),math.rad(Settings.CylinderAngle.Z))
		end
		Bolted = true
		SetItemHolder:FireServer(Tool, "Bolted", true)
	else
		if Settings.HammerAngle then
			Hammer.C0 = CFrame.new(Hammer.C0.Position)*CFrame.Angles(math.rad(0),math.rad(0),math.rad(0))
		end
		if Settings.CylinderAngle then
			Cylinder.C0 = CFrame.new(Cylinder.C0.Position)*CFrame.Angles(math.rad(0),math.rad(0),math.rad(0))
		end
		if Settings.AutomaticBolt and not Bolted then
			boltGun()
		end
	end

	local unequippedTool = Tool:GetAttributeChangedSignal("Unequipping"):Connect(function()
		if Tool:GetAttribute("Unequipping") then
			Equipped = false
			AimGun(false)
			for index,_ in pairs(animationTable) do
				animationHandle(index,"Stop",0)
			end
			if Settings.BoltBackWhenEmpty and magInstanceValue.Value == 0 then -- If gun is empty and BoltBackWhenEmpty, set bolt because reload could be cancelled
				Handle.Bolt.C1 = BackBoltC1
			end
		end
	end)

	local inputEnded = UIS.InputEnded:Connect(function(Input)
		if Input.UserInputType == Enum.UserInputType.MouseButton2 then
			AimGun(false)
		end
	end)

	local runChange = Humanoid:GetAttributeChangedSignal("Running"):Connect(function()
		checkRunning()
	end)

	Tool.AncestryChanged:Once(function()
		SetItemHolder:FireServer(Tool, "Mag", magInstanceValue.Value)
		SetItemHolder:FireServer(Tool, "Bolted", Bolted)
		for index,_ in pairs(animationTable) do
			animationHandle(index, "Stop", 0)
		end
		for _,animationFunction in pairs(animationFunctionsList) do
			animationFunction:Disconnect()
		end
		
		for _,TargetName in pairs(ModificationList) do -- Reset any animation modified parts
			if Tool:FindFirstChild(TargetName) then
				if Tool[TargetName]:GetAttribute("OriginalTransparency") then
					Tool[TargetName].Transparency = Tool[TargetName]:GetAttribute("OriginalTransparency")
					AnimationModifier:FireServer("Transparency",Tool[TargetName]:GetAttribute("OriginalTransparency"),Tool,TargetName)
					Tool[TargetName]:SetAttribute("OriginalTransparency",nil)
				end
			end
		end

		if MotorModel:FindFirstChild("ScopeObject") then
			ScopeModule.SetEnabled(false)
		end
		
		if Settings.BoltBackWhenEmpty and magInstanceValue.Value == 0 and Handle:FindFirstChild("Bolt") then -- If gun is empty and BoltBackWhenEmpty, set bolt because reload could be cancelled
			Handle.Bolt.C1 = BackBoltC1
		end
		Equipped = false
		HoldFire = false
		Bolted = false
		FireCooldown = false
		Bursting = false
		Aiming = false
		Reloading = false
		CancelReload = false
		spreadReduction = false
		CrosshairPercent.Value = 0
		if VignetteTween then -- Reset Vignette	
			VignetteTween:Play()
		else
			VignetteAmount.Value = 1
		end
		--ChargePercent.Value = 0
		Humanoid:SetAttribute("Aiming",nil)
		if Flash:FindFirstChild("FlashLight") then
			Flash.FlashLight.Enabled = false
		end
		disconnectFunctions{inputBegan,inputEnded,renderStep,runChange,unequippedTool}
		Tool:SetAttribute("Activated",nil)
	end)
	--\\
end

return module
