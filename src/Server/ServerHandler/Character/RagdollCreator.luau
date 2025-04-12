local module = {}
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Modules = ReplicatedStorage.Modules
local Events = ReplicatedStorage.Events
local RagdollHandler = require(Modules.Character.Ragdoll)
local DownedEvent = Events.Character.DownedEvent

local function roundNumber (number, numPlaces)
return math.floor(number*(10^numPlaces))/(10^numPlaces)
end

local ignoreCharPart = {"HumanoidRootPart","UpperTorso","Head","CollisionBox"}

function module.Init(Character)
	local Died = false
	for _,charPart in pairs(Character:GetDescendants()) do
		if charPart:IsA("BasePart") then
			charPart.CollisionGroup = "Character"
		end
	end
	local Humanoid = Character:WaitForChild("Humanoid")	
	Humanoid.BreakJointsOnDeath = false
	
	local healthChanged = nil
	healthChanged = Humanoid.HealthChanged:Connect(function(health)
		if roundNumber(health,3) == 0.001 then --/ Player gets downed
			task.defer(function()
				if Humanoid:GetAttribute("Downed") or Humanoid:GetAttribute("DownedOnceAlready") then Humanoid.Health = 0 return end
				Humanoid:UnequipTools()
				Humanoid:SetAttribute("Downed",true)
				Humanoid:SetAttribute("DownedRagdolling",true)
				RagdollHandler.Joints(Character)
				Humanoid.Health = 50
				Humanoid.EvaluateStateMachine = false
				for _,joint in pairs(Character:GetDescendants()) do
					if joint:IsA("HingeConstraint") or joint:IsA("BallSocketConstraint") then
						joint.Enabled = true
					elseif joint:IsA("Motor6D") then
						joint.Enabled = false
					elseif joint:IsA("BasePart") and joint.Parent == Character and not table.find(ignoreCharPart,joint.Name) then
						joint.CanCollide = true
					end
				end
				Character.HumanoidRootPart:SetNetworkOwner(nil)
				task.wait(1)
				Humanoid:SetAttribute("DownedRagdolling",nil)
				Character:PivotTo(CFrame.new(Character:GetPivot().X, Character:GetPivot().Y, Character:GetPivot().Z) * CFrame.Angles(0,math.rad(180),0)+Vector3.new(0,3,0))
				Humanoid.EvaluateStateMachine = true
				for _,joint in pairs(Character:GetDescendants()) do
					if joint:IsA("HingeConstraint") or joint:IsA("BallSocketConstraint") then
						joint:Destroy()
					elseif joint:IsA("Motor6D") then
						joint.Enabled = true
					elseif joint:IsA("BasePart") and joint.Parent == Character and not table.find(ignoreCharPart,joint.Name) then
						joint.CollisionGroup = "Character"
						if joint.Parent == Character and not table.find(ignoreCharPart,joint.Name) then
							joint.CanCollide = false
						end
					end
				end
				
				Character:SetAttribute("freezePlayer",false)
				Character:SetAttribute("interactable",true)
				Character:SetAttribute("interactAnimId",0)
				Character:SetAttribute("interactFinishEventId",4)
				Character:SetAttribute("interactText","REVIVE")
				Character:SetAttribute("interactTime",0)
				Character:SetAttribute("maxRange",10)
				Character:SetAttribute("NoHighlight",false)
				
				DownedEvent:FireAllClients(Character)
				
				DownedEvent:FireClient(Players:GetPlayerFromCharacter(Character))
			end)
		elseif health <= 0 and not Died then --/ Player died (I can't use Humanoid.Died for some reason it does not work)
			Died = true
			healthChanged:Disconnect()
			local ragdoll = Instance.new("Model")
			ragdoll:SetAttribute("Ragdoll",true)
			ragdoll.Name = Character.Name.."'s Ragdoll"
			ragdoll.Parent = workspace.Corpses
			local objVal = Instance.new("ObjectValue")
			objVal.Name = "Ragdoll"
			objVal.Value = ragdoll
			objVal.Parent = Character
			local ragdollHumanoid = Character:FindFirstChildOfClass("Humanoid"):Clone()
			local ragdollHRP = Character:FindFirstChild("HumanoidRootPart"):Clone()
			ragdollHumanoid.Parent = ragdoll
			ragdollHRP.Parent = ragdoll
			ragdollHRP.CanCollide = false
			ragdollHRP.CanQuery = false
			ragdollHRP.CanTouch = false
			ragdoll.PrimaryPart = ragdollHRP
			for _,part in pairs(Character:GetChildren()) do
				if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" and part.Name ~= "CollisionBox" or part:IsA("Model") or part:IsA("Clothing") or part:IsA("Accessory") then
					part.Parent = ragdoll
				elseif part.Name == "CollisionBox" then
					part.CanCollide = false
				elseif part.Name == "Profile" then
					part:Clone().Parent = ragdoll
				end
			end
			RagdollHandler.Joints(ragdoll)
			RagdollHandler.Bot(ragdoll)
		end
	end)
end
return module
