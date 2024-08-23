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

local function stopDragging(inst)
	inst:RemoveTag("Dragging")
	if inst:HasTag("Lever") then
		inst.Anchored = true
	else
		table.insert(unoptimizedParts, {time(), inst})
	end
	playerLeaveConnections[inst] = nil
end

function onDrag(player: Player, state, inst)
	if inst and typeof(inst) == "Instance" and inst:IsA("BasePart") then
		if not inst:HasTag("Draggable") then return end
		if player.Character and player.Character.PrimaryPart and getDistance(player.Character.PrimaryPart.Position, inst.Position) <= DRAG_RANGE then
			if state then
				if inst:HasTag("Dragging") then return end
				for i, v in unoptimizedParts do
					if v[2] == inst then
						table.remove(unoptimizedParts, i)
						break
					end
				end
				inst:AddTag("Dragging")
				inst.Anchored = false
				inst:SetNetworkOwner(player)
				playerLeaveConnections[inst] = {player, player.Destroying:Connect(function() stopDragging(inst) end)}
			else
				local conn = playerLeaveConnections[inst]
				if conn and conn[1] == player then stopDragging(inst) end
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
