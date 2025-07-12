local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextService = game:GetService("TextService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local Modules = ReplicatedStorage.Modules
local InteractPrimes = ReplicatedStorage.PlayerAssets.Interact
local Animations = InteractPrimes.Animations

local CommonToolFunctions = require(Modules.Tool.CommonToolFunctions)
local CommonFunctions = require(Modules.CommonFuncs)
local KeybindHandler = require(Modules.UI.KeybindHandler)
local TeamHandler = require(Modules.Interaction.TeamHandler)

local module = {}

-- Player & character stuff
local LocalPlayer = Players.LocalPlayer
local PlayerGui: PlayerGui = nil
local Mouse = LocalPlayer:GetMouse()
local Character: Model? = nil
local Backpack: Backpack? = nil
local Humanoid: Humanoid? = nil
local Animator: Animator? = nil

-- Constants (sort of)
local InteractClientFunctions = {}
local validAnims = {}

-- Variables
local lastInteractionStart = 0
local MaxRange = 50
local Interacting = false
local Debounce = false

local CurrentAnimTrack
local Current = nil
local BeginningInput = nil


function module.LoadChar(Char)
	Character = Char
	Mouse.TargetFilter = Character
	Humanoid = Char:WaitForChild("Humanoid")
	Animator = Humanoid:WaitForChild("Animator")
end

function module.UnloadChar(char)
	Character = nil
end

local function getStatusWithHealth (CurrentHealth,MaxHealth)
	local Ratio = CurrentHealth/MaxHealth
	if Ratio >= 0.8 then
		return "HEALTHY", Color3.fromRGB(0,255,0), Ratio
	elseif Ratio < 0.8 and Ratio >= 0.3 then
		return "INJURED", Color3.fromRGB(255,255,0), Ratio
	elseif Ratio < 0.3 then
		return "CRITICAL", Color3.fromRGB(255,60,0), Ratio
	end
end

function module.Init()
	
	local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
	
	local MouseUI = PlayerGui:WaitForChild("MouseUI")
	local Dot: Frame = MouseUI:WaitForChild("Dot")
	local Texts: Frame = Dot:WaitForChild("Texts")
	local PlayerDisplay: Folder = Texts:WaitForChild("PlayerDisplay")
	local PlayerName: TextLabel = PlayerDisplay:WaitForChild("PlayerName")
	local PlayerRole: TextLabel = PlayerDisplay:WaitForChild("Role")
	local PlayerHealthStatus: TextLabel = PlayerDisplay:WaitForChild("HealthStatus")


	RunService.RenderStepped:Connect(function(dt)
		-- update the text labels to tell the name, role, and health status of the current player.
		if Current 
			and Current:FindFirstChild("Profile")
			and Current:FindFirstChild("Humanoid") 
		then
			local CurrentPlayer = Players:GetPlayerFromCharacter(Current)
			local Profile = Current.Profile
			local Humanoid = Current.Humanoid
			
			PlayerName.Text = Profile:GetAttribute("FirstName").." "..Profile:GetAttribute("LastName") .." ("..CurrentPlayer.Name..")"
			PlayerRole.Text = Profile:GetAttribute("Role")
			PlayerRole.TextColor3 = Profile:GetAttribute("RoleColor")
			
			PlayerName.Visible = true
			PlayerRole.Visible = true
			
			if TeamHandler.Check(Players.LocalPlayer,CurrentPlayer) ~= 1 then
				local StatusText, TextColor, Ratio = getStatusWithHealth(Humanoid.Health,Humanoid.MaxHealth) 
				PlayerHealthStatus.Text = StatusText
				PlayerHealthStatus.TextColor3 = TextColor
				PlayerHealthStatus.Visible = true
			else
				PlayerHealthStatus.Visible = false
			end
		else
			PlayerName.Visible = false
			PlayerRole.Visible = false
			PlayerHealthStatus.Visible = false
		end

		-- cancel any current interactions if the player is dead, and skip search
		if not Character or not Humanoid or Humanoid.Health <= 0 then
			Current = nil
			return
		end

		-- search for interactable objects
		if Current and Interacting then return end -- skip if currently interacting, allowing user to continue interacting after breaking line of sight with object
		Current = Mouse.Target and Mouse.Target:FindFirstAncestorOfClass("Model")
		if Current and not Current:GetAttribute("isCharacter") then Current = Current:FindFirstAncestorOfClass("Model") end
		if Current and not Current:GetAttribute("isCharacter") then Current = nil end
		if Current and not Current.PrimaryPart then Current = nil end
		if Current and Current.PrimaryPart and CommonToolFunctions.getDistance(Current.PrimaryPart.Position, Character.PrimaryPart.Position) > MaxRange then Current = nil end

	end)
end

return module
