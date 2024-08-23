--disable
--[[
    This script starts all UI modules safely.

    Any UI component that relies on the player's character should
    check for the character itself, instead of reloading each time
    the character respawns. This is important so that UI keeps working
    even after the character dies, whether to fade it out or to have
    different behavior.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Modules = ReplicatedStorage.Modules
local CommonFunctions = require(Modules.CommonFuncs)

local modules = {}

local function loadModule(mod: ModuleScript)
    modules[mod.Name] = CommonFunctions.SafeCallOrNil(require, mod)
end

--------------------
-- INITIALIZATION --
--------------------

local PlayerGui = Players.LocalPlayer:WaitForChild("PlayerGui")

loadModule(script.InteractHandler)
loadModule(script.DragHandler)
loadModule(script.Cursor)
loadModule(script.ViewmodelHandler)
loadModule(script.HotbarHandler)
loadModule(script.HUD)
loadModule(script.Replication)
loadModule(script.StatusEffectsClient)
loadModule(script.Environment)
loadModule(script.Inventory)
loadModule(script.CustomChat)
-- Load and initialize your UI from the "Init(Gui: PlayerGui)" function.
for _, mod in modules do
    -- Safely run the function and print any errors in output without interrupting the current thread.
    CommonFunctions.SafeCall(task.spawn, mod.Init, PlayerGui)
end

local Cmdr = require(ReplicatedStorage:WaitForChild("CmdrClient"))
Cmdr:SetActivationKeys({ Enum.KeyCode.F2 })