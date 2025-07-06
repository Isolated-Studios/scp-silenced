--[[
    This script starts all client modules safely.

    Any UI component that relies on the player's character should
    check for the character itself, instead of reloading each time
    the character respawns. This is important so that UI keeps working
    even after the character dies, whether to fade it out or to have
    different behavior.
]]

-- Script should only start if it's a parent of PlayerScripts
if script.Parent.Name == "StarterPlayerScripts" then
	return
end

-- // Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- // Module folders
local ClientSrc = ReplicatedStorage.ClientSrc
local Modules = ReplicatedStorage.Modules

-- // Other stuff
local CommonFunctions = require(Modules.CommonFuncs)

local LocalPlayer = Players.LocalPlayer

local modules = {}

local function loadModule(mod: ModuleScript)
	modules[mod.Name] = CommonFunctions.SafeCallOrNil(require, mod)
end

--------------------
-- INITIALIZATION --
--------------------

-- // UI-specific modules
loadModule(ClientSrc.InteractHandler)
loadModule(ClientSrc.DragHandler)
loadModule(ClientSrc.Cursor)
loadModule(ClientSrc.HotbarHandler)
loadModule(ClientSrc.HUD)
loadModule(ClientSrc.Replication)
loadModule(ClientSrc.StatusEffectsClient)
loadModule(ClientSrc.Environment)
loadModule(ClientSrc.Inventory)
loadModule(ClientSrc.CustomChat)
loadModule(ClientSrc.SettingsHandler)
loadModule(ClientSrc.PlayerHover)

-- // Character-specific modules
--loadModule(ClientSrc.Vaulting)   [[ ON HALT ]]
loadModule(ClientSrc.MechanismHandler)
loadModule(ClientSrc.EnvironmentalDamage)
loadModule(ClientSrc.Movement)
loadModule(ClientSrc.Camera)
loadModule(ClientSrc.ViewModelHandler)
loadModule(ClientSrc.ToolHandler)
loadModule(ClientSrc.Blood)

-- Load and initialize your UI from the "Init()" function.
for _, mod in modules do
	-- Safely run the function and print any errors in output without interrupting the current thread.
	if mod == false or mod.Init == nil then continue end
	CommonFunctions.SafeCall(task.spawn, mod.Init)
end

local Cmdr = require(ReplicatedStorage:WaitForChild("CmdrClient"))
Cmdr:SetActivationKeys({ Enum.KeyCode.F2 })

-- Any module that needs to deal with characters should have a LoadChar function (UnloadChar is optional).
LocalPlayer.CharacterAdded:Connect(function(character)
	for _, mod in modules do
		if mod == false or mod.LoadChar == nil then continue end
		task.spawn(mod.LoadChar, character)
	end
end)

if LocalPlayer.Character then
	for _, mod in modules do
		if mod == false or mod.LoadChar == nil then continue end
		task.spawn(mod.LoadChar, LocalPlayer.Character)
	end
end

LocalPlayer.CharacterRemoving:Connect(function(character)
	for _, mod in modules do
		if mod == false or  mod.UnloadChar == nil then continue end
		task.spawn(mod.UnloadChar, character)
	end
end)
