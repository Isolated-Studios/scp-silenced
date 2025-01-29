local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local module = {}
local DRAG_RANGE = 58
local MIN_MOVEMENT_TIME = 10

local DragEvent = ReplicatedStorage.Events.Interaction.Drag

local function getDistance(point1 : Vector3, point2 : Vector3)
	return (point1 - point2).Magnitude
end

local playerLeaveConnections = {}
local unoptimizedParts = {}

local function stopDragging(inst: BasePart)
	inst:SetAttribute("DraggerID", nil)
	if inst:HasTag("Lever") then
		inst.Anchored = true
	else
		table.insert(unoptimizedParts, {time(), inst})
	end
	playerLeaveConnections[inst] = nil
end

function onDrag(Player: Player, state, Object)
	if Object and typeof(Object) == "Instance" and Object:IsA("BasePart") then
		if not Object:HasTag("Draggable") then return end
		if Player.Character and Player.Character.PrimaryPart and getDistance(Player.Character.PrimaryPart.Position, Object.Position) <= DRAG_RANGE then
			if state then
				if (Object:GetAttribute("DraggerID") or Player.UserId) ~= Player.UserId then return end
				for i, v in unoptimizedParts do
					if v[2] == Object then
						table.remove(unoptimizedParts, i)
						break
					end
				end
				Object:SetAttribute("DraggerID", Player.UserId)
				Object.Anchored = false
				Object:SetNetworkOwner(Player)
				playerLeaveConnections[Object] = {Player, Player.Destroying:Connect(function() stopDragging(Object) end)}
			else
				local conn = playerLeaveConnections[Object]
				if conn and conn[1] == Player then stopDragging(Object) end
			end
		end
	end
end

local function optimizeProps()
	local i, v = 0, nil
	while true do
		i += 1
		v = unoptimizedParts[i]
		if v == nil then break end

		if v[1] + MIN_MOVEMENT_TIME < time() and v[2].AssemblyLinearVelocity.Magnitude < 0.01 and v[2].AssemblyAngularVelocity.Magnitude < 0.01 then
			v[2].Anchored = true
			table.remove(unoptimizedParts, i)
			i -= 1
		end
	end
end

function module.Init()
	DragEvent.OnServerEvent:Connect(onDrag)
	task.defer(function()
		while true do
			task.wait(1)
			optimizeProps()
		end
	end)
end

return module
