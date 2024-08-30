local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ViewModelHandler = require(script.Parent.ViewmodelHandler)

local module = {}

local Tools = ReplicatedStorage.Tooling.Tools

local Character: Model = nil

function module.LoadChar(char)
	Character = char
	Character.ChildAdded:Connect(function(Tool: Tool)
		local ViewModel = ViewModelHandler.getViewModel()
		if not ViewModel then return end
		if Tool:IsA("Tool") then
			local ToolObjects = Tools:FindFirstChild(Tool:GetAttribute("ToolName"))
			if Tool:GetAttribute("ToolSource") and script:FindFirstChild(Tool:GetAttribute("ToolSource")) then
				local Source = require(script[Tool:GetAttribute("ToolSource")])
				Source.Init(Tool, ToolObjects, Character, ViewModel)
			end
		end
	end)
end

function module.UnloadChar(char)
	Character = nil
end

return module
