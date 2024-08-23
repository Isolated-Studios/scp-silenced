local module = {}
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")

local Events = ReplicatedStorage.Events
local Tooling = ReplicatedStorage.Tooling
local Modules = ReplicatedStorage.Modules
local Objects = ReplicatedStorage.Objects

local Tracers = Objects.Tracers
local ToolingTools = Tooling.Tools
local ToolingPhysical = Tooling.Physical
local ToolEvents = Events.Tool
local ItemPool = workspace.Items

local Itemize = ToolEvents.Itemize
local TweenObjectEvent = Events.Interaction.TweenObjectEvent
local SetItemHolder = ToolEvents.SetItemHolder
local LandThrow = ToolEvents.LandThrow
local HealEvent = ToolEvents.Heal
local ManageAmmoBox = ToolEvents.ManageAmmoBox

local GrenadeModule = require(Modules.Tool.Grenade)

local function dropItem (Tool,Position,yRotation,noTween)
	local originalToolCFrame = Tool:GetPivot()
	local Model = Instance.new("Model")
	Model.Name = Tool.Name
	Model.Parent = ItemPool
	for _,p in pairs(Tool:GetChildren()) do
		local part = p:Clone()
		if part:IsA("BasePart") then
			part.Parent = Model
			part.CanCollide = false
			part.Anchored = true
		end
		if part:IsA("Configuration") then
			part.Parent = Model
		end
	end
	local Settings = require(ToolingTools[Tool:GetAttribute("ToolName")].Settings)
	local HighlightColor = Settings.HighlightColor

	Model.Hitbox.CanCollide = true
	Model.Hitbox.CollisionGroup = "Item"
	Model.PrimaryPart = Model.Hitbox
	
	--Model:PivotTo(originalToolCFrame)

	local obj = Instance.new("ObjectValue")
	obj.Value = Model
	obj.Name = "Item"
	obj.Parent = Tool
	Tool.Parent = ReplicatedStorage
	Tool:SetAttribute("Removing",true)
	Tool:SetAttribute("Dropping",true)
	Debris:AddItem(Tool,1)

	Model:SetAttribute("freezePlayer",false)
	Model:SetAttribute("interactable",true)
	Model:SetAttribute("interactAnimId",0)
	Model:SetAttribute("interactFinishEventId",3)
	Model:SetAttribute("interactText","PICK UP "..Model.Name)
	Model:SetAttribute("interactTime",0)
	Model:SetAttribute("maxRange",8)
	Model:SetAttribute("NoHighlight",false)
	Model:SetAttribute("HighlightColor",HighlightColor)
	
	Model:PivotTo(CFrame.new(Position) * CFrame.Angles(0, math.rad(yRotation), 0))
	if not noTween then
		TweenObjectEvent:FireAllClients(Model, CFrame.new(Position) * CFrame.Angles(0, math.rad(yRotation), 0),  0.2, 50, Enum.EasingStyle.Quint,Enum.EasingDirection.Out)
	end
end

local landTypes = {
	[0] = function(Settings,Tool,landPosition,Origin,Character,Normal,passableCFrame) -- Destroy

		Tool:Destroy()
	end,
	[1] = function(Settings,Tool,landPosition,Origin,Character,Normal,passableCFrame,Player) -- Grenade-ify
		local Settings = require(ToolingTools[Tool:GetAttribute("ToolName")].Settings)
		local Model = Tracers[Settings.BulletTemplate]:Clone()
		Model.Name = Tool.Name
		Model.Parent = ItemPool
		Model:SetAttribute("PlayerId",Player.UserId)
		for _,part in pairs(Model:GetChildren()) do
			if part:IsA("BasePart") then
				part.Anchored = false
				part.CanCollide = true
				part.CollisionGroup = "Item"
				--part:SetNetworkOwner(Player)
			end
			if part:IsA("Configuration") then
				part.Parent = Model
			end
		end

		Model.Hitbox.CanCollide = true
		Model.Hitbox.CollisionGroup = "Item"
		Model.PrimaryPart = Model.Hitbox
		Model:PivotTo(CFrame.new(landPosition)*passableCFrame.Rotation)
		GrenadeModule.Apply(Settings.GrenadeType or "Fragmentation",Model)
	end,
	[2] = function(Settings,Tool,landPosition,Origin,Character,Normal,passableCFrame) -- Drop
		dropItem(Tool,landPosition,0,true)
	end,
}

function module.Init()
	Itemize.OnServerEvent:Connect(function(_,Tool,Position,yRotation)
		dropItem(Tool,Position,yRotation)
	end)
	SetItemHolder.OnServerEvent:Connect(function(_,Tool,valueName,newValue)
		if Tool and Tool:FindFirstChild("Holder") and Tool["Holder"]:FindFirstChild(valueName) then
			local value = Tool["Holder"][valueName]
			value.Value = newValue
		elseif Tool and Tool:FindFirstChild("Item") and Tool["Item"].Value and Tool["Item"].Value:FindFirstChild("Holder") and Tool["Item"].Value["Holder"]:FindFirstChild(valueName) then
			local value = Tool["Item"].Value["Holder"][valueName]
			value.Value = newValue
		end
	end)
	LandThrow.OnServerEvent:Connect(function(Player,Tool,landPosition,Origin,Character,Normal,passableCFrame)
		if Tool:GetAttribute("ToolName") and ToolingTools:FindFirstChild(Tool:GetAttribute("ToolName")) then
			local Settings = require(ToolingTools[Tool:GetAttribute("ToolName")].Settings)
			local LandType = Settings.LandType or 1
			landTypes[LandType](Settings,Tool,landPosition,Origin,Character,Normal,passableCFrame,Player)
		end
	end)
	ManageAmmoBox.OnServerEvent:Connect(function(Player,Ammo,create)
		if not create then
			if Ammo.Parent == Player.Backpack and Ammo:GetAttribute("ToolType") == 12 then
				Ammo.Parent = ReplicatedStorage
				Ammo:SetAttribute("Removing",true)
				Debris:AddItem(Ammo,1)
			end
		else
			if ToolingPhysical[create] and ToolingPhysical[create]:GetAttribute("ToolType") == 12 then
				local newAmmo = ToolingPhysical[create]:Clone()
				newAmmo:WaitForChild("Holder"):WaitForChild("Capacity").Value = -Ammo
				newAmmo.Parent = Player.Backpack
			end
		end
	end)
end
return module
