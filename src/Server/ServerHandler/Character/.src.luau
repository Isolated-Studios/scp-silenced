local module = {}
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Debris = game:GetService("Debris")
local Events = ReplicatedStorage.Events
local Sounds = ReplicatedStorage.Sounds
local CharacterEvents = Events.Character
local VaultEvent = CharacterEvents.VaultEvent
local LookEvent = CharacterEvents.LookEvent
function module.Init()
	VaultEvent.OnServerEvent:Connect(function(player,CollisionBox,Running)
		if Running then
			local VaultSound = Sounds.VaultSound:Clone()
			VaultSound.Parent = CollisionBox
			Debris:AddItem(VaultSound,VaultSound.TimeLength)
			VaultSound.PlaybackSpeed = Random.new():NextNumber(0.8,1.1)
			VaultSound:Play()
		end
		--local LinearVelocity = Instance.new("LinearVelocity")
		--CollisionBox:SetNetworkOwner(game.Players.LocalPlayer)
		--LinearVelocity.Parent = CollisionBox
		--LinearVelocity.MaxForce = math.huge
		--LinearVelocity.Attachment0 = CollisionBox.VaultEnd

		--if Running then
		--	LinearVelocity.VectorVelocity = Vector3.new( 
		--		CollisionBox.CFrame.LookVector.X*20,
		--		6,
		--		CollisionBox.CFrame.LookVector.Z*20)
		--else
		--	LinearVelocity.VectorVelocity = Vector3.new( 
		--		CollisionBox.CFrame.LookVector.X*10,
		--		3,
		--		CollisionBox.CFrame.LookVector.Z*10)
		--end
		--LinearVelocity.Enabled = true
		--CollisionBox:SetNetworkOwner(player)
		--CollisionBox.CanCollide = false

		--Debris:AddItem(LinearVelocity,Running and 0.3 or 0.5)
		--task.delay(Running and 0.3 or 0.5, function()
		--	CollisionBox.CanCollide = true
		--end)
	end)
	LookEvent.OnServerEvent:Connect(function(player,CameraDirection,LeftShoulder,RightShoulder,Neck,HeldType)
		for _,otherPlayer in pairs(Players:GetPlayers()) do
			if otherPlayer ~= player then
				LookEvent:FireClient(otherPlayer,CameraDirection,LeftShoulder,RightShoulder,Neck,HeldType)
			end
		end
	end)
	game.Players.PlayerAdded:Connect(function(Player)
		Player.CharacterAdded:Connect(function(Character)	
			for _,module in pairs(script:GetChildren()) do
				if module:IsA("ModuleScript") then
					require(module).Init(Character)
				end
			end
			Character:WaitForChild("Health"):Destroy()
		end)
	end)
end
return module
