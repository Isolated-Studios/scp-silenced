local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")
local Events = ReplicatedStorage.Events
local Sounds = ReplicatedStorage.Sounds

for _,module in pairs(script:GetChildren()) do
	if module:IsA("ModuleScript") then
		require(module).Init()
	end
end

local Cmdr = require(ReplicatedStorage.Packages.cmdr)
Cmdr:RegisterDefaultCommands() -- This loads the default set of commands that Cmdr comes with. (Optional)
-- Cmdr:RegisterCommandsIn(script.Parent.CmdrCommands) -- Register commands from your own folder. (Optional)
Cmdr:RegisterHooksIn(script.Parent.CmdrHooks)
