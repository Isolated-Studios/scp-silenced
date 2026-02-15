local ToolWeldsModule = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ToolEvents = ReplicatedStorage.Events.Tool
local WeldTool = ToolEvents.WeldTool
local DestroyToolWeld = ToolEvents.DestroyToolWeld

function ToolWeldsModule.Init ()
	WeldTool.OnServerInvoke = function (Player, Tool)
		if Player.Character and Tool.Parent == Player.Character then
			local Character = Player.Character
			local Handle = Tool.Handle
			local RightHand = Character.RightHand

			if RightHand:FindFirstChild("RightGrip") then
				RightHand.RightGrip:Destroy()
			end

			local Weld = Instance.new("Motor6D")
			Weld.Name = "GripWeld"
			Weld.Part0 = RightHand
			Weld.Part1 = Handle
			Weld.C1 = Tool.Grip
			Weld.Parent = RightHand
			return Weld
		end
	end

	DestroyToolWeld.OnServerEvent:Connect(function (Player)
		if Player.Character 
			and Player.Character:FindFirstChild("RightHand") 
			and Player.Character.RightHand:FindFirstChild("GripWeld") 
		then
			Player.Character.RightHand.GripWeld:Destroy()
		end
	end)
end

return ToolWeldsModule
