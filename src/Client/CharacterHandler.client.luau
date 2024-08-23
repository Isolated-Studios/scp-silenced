--disable
--[[
    This is an alternative to LocalReplicationScript.
    Any logic that should happen when the character loads should be ran
    from here with a module script.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer

local Modules = ReplicatedStorage.Modules
local CommonFunctions = require(Modules.CommonFuncs)

local modules = {}
local StartupLoaded = false

local function loadModule(mod: ModuleScript)
    modules[mod.Name] = CommonFunctions.SafeCallOrNil(require, mod)
end

--------------------
-- INITIALIZATION --
--------------------

loadModule(script.Vaulting)
loadModule(script.MechanismHandler)
loadModule(script.EnvironmentalDamage)
loadModule(script.Movement)
loadModule(script.Camera)
loadModule(script.Blood)

LocalPlayer.CharacterAdded:Connect(function(character)
    StartupLoaded = true
    for _, mod in modules do
        task.spawn(mod.LoadChar, character)
    end
end)
if LocalPlayer.Character and not StartupLoaded then
    for _, mod in modules do
        task.spawn(mod.LoadChar, LocalPlayer.Character)
    end
end


Players.LocalPlayer.CharacterRemoving:Connect(function(character)
    for _, mod in modules do
        if mod.UnloadChar == nil then continue end
        task.spawn(mod.UnloadChar, character)
    end
end)
