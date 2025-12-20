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
local Deathnote = require(script.Deathnotes)

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
local Interacting = false
local Debounce = false

local CurrentAnimTrack
local Current = nil
local BeginningInput = nil

local function cancelInteraction()
	Interacting = false
	Character:SetAttribute("Interacting", false)
	UserInputService.MouseDeltaSensitivity = 1
	if CurrentAnimTrack then CurrentAnimTrack:Stop() end
end

local function completeInteraction()
	if not Interacting then return end
	Interacting = false
	Character:SetAttribute("Interacting", false)
	UserInputService.MouseDeltaSensitivity = 1
	if CurrentAnimTrack then CurrentAnimTrack:Stop() end
	if InteractClientFunctions[Current:GetAttribute("InteractId")] then
		InteractClientFunctions[Current:GetAttribute("InteractId")](Current)
	end
	if Current:GetAttribute("InteractId2") and InteractClientFunctions[Current:GetAttribute("InteractId2")] then
		InteractClientFunctions[Current:GetAttribute("InteractId2")](Current)
	end
	ReplicatedStorage.Events.Interaction.FinishInteraction:FireServer(Current, Current:GetAttribute("InteractId"))
end

local function startInteraction(InteractTime)
	Interacting = true
	local localInteractionStart = tick()
	lastInteractionStart = localInteractionStart
	if (Current and Current:GetAttribute("InteractAnimationId") and validAnims[Current:GetAttribute("InteractAnimationId")]) then
		CurrentAnimTrack = Animator:LoadAnimation(Animations[tostring(Current:GetAttribute("InteractAnimationId"))])
		if CurrentAnimTrack then CurrentAnimTrack:Play() end
		UserInputService.MouseDeltaSensitivity = 0
	end
	if Current:GetAttribute("FreezePlayer") == true then
		Character:SetAttribute("Interacting", true)
	end
	if InteractTime and InteractTime > 0 then
		task.delay(InteractTime, function()
			if localInteractionStart == lastInteractionStart then
				completeInteraction()
			end
		end)
	else
		completeInteraction()
	end
end

function module.LoadChar(Char)
	Character = Char
	Mouse.TargetFilter = Character
	Humanoid = Char:WaitForChild("Humanoid")
	Animator = Humanoid:WaitForChild("Animator")

	Humanoid.Died:Connect(cancelInteraction)
end

function module.UnloadChar(char)
	Character = nil
end

function module.Init()
	local function loadInteractionModule(mod)
		local funcs = CommonFunctions.SafeCallOrNil(require, mod)
		if typeof(funcs) == "table" then
			for name, func in pairs(funcs) do
				InteractClientFunctions[name] = func
			end
		end
	end
	
	-- add interaction modules here
	loadInteractionModule(script.PlayerInteractions)

	PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
	local InteractUI = PlayerGui:WaitForChild("InteractUI")
	local InteractElements: CanvasGroup = InteractUI:WaitForChild("InteractElements")
	local InteractFrame: Frame = InteractElements:WaitForChild("InteractFrame")
	local GuideLabel: TextLabel = InteractFrame:WaitForChild("Guide")
	local ProgressBar: CanvasGroup = InteractFrame:WaitForChild("ProgressBar")
	local Title: TextLabel = InteractElements:WaitForChild("Title")
	local Subtext: TextLabel = InteractElements:WaitForChild("Subtext")
	
	ProgressBar:WaitForChild("Fill")
	
	local Highlight = Instance.new("Highlight")
	Highlight.FillColor = Color3.fromRGB(255, 255, 255)
	Highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
	Highlight.FillTransparency = 1
	Highlight.OutlineTransparency = 1
	Highlight.Adornee = nil
	Highlight.Parent = script

	RunService.RenderStepped:Connect(function(dt)
		-- update interaction progress bar if currently interacting
		if Current then
			Highlight.FillTransparency = math.clamp(Highlight.FillTransparency - dt * 2, 0.85, 1)
			
			-- Will show information pertaining to corpses
			if Current:GetAttribute("Ragdoll")
				and Current:FindFirstChild("Profile")
			then
				local Profile = Current.Profile
				Title.Text = Profile:GetAttribute("FirstName").." "..Profile:GetAttribute("LastName") .." ("..string.gsub(Current.Name, "'s Ragdoll", "")..")" or ""
				Subtext.Text = Profile:GetAttribute("Role") or ""
				Subtext.TextColor3 = Profile:GetAttribute("RoleColor") or Color3.fromRGB(255,255,255)
				
				Title.TextTransparency = math.clamp(Title.TextTransparency - dt * 8, 0, 1)
				Title.TextStrokeTransparency = math.clamp(Title.TextStrokeTransparency - dt * 3.2, 0.6, 1)
				Subtext.TextTransparency = math.clamp(Subtext.TextTransparency - dt * 8, 0, 1)
				Subtext.TextStrokeTransparency = math.clamp(Subtext.TextStrokeTransparency - dt * 3.2, 0.6, 1)
				
				Title.Visible = true
				Subtext.Visible = true
			else
				Title.TextTransparency = math.clamp(Title.TextTransparency + dt * 8, 0, 1)
				Title.TextStrokeTransparency = math.clamp(Title.TextStrokeTransparency + dt * 3.2, 0.6, 1)
				Subtext.TextTransparency = math.clamp(Subtext.TextTransparency + dt * 8, 0, 1)
				Subtext.TextStrokeTransparency = math.clamp(Subtext.TextStrokeTransparency + dt * 3.2, 0.6, 1)
				
				Title.Visible = Title.TextTransparency > 0
				Subtext.Visible = Subtext.TextTransparency > 0
			end
			
			if Interacting and Current:GetAttribute("InteractTime") then
				-- if interacting, guide label (the one that says "E | Interact")
				ProgressBar.Fill.Size = UDim2.new((tick() - lastInteractionStart) / Current:GetAttribute("InteractTime"), 0, 1, 0)
				ProgressBar.GroupTransparency = math.clamp(ProgressBar.GroupTransparency - dt * 8, 0, 1)
				GuideLabel.TextTransparency = math.clamp(GuideLabel.TextTransparency + dt * 8, 0, 1)
				GuideLabel.TextStrokeTransparency = math.clamp(GuideLabel.TextStrokeTransparency + dt * 3.2, 0.6, 1)
			else
				-- ...otherwise show the guide label
				ProgressBar.GroupTransparency = math.clamp(ProgressBar.GroupTransparency + dt * 8, 0, 1)

				local InteractText = if Current:GetAttribute("InteractText") then "E | " .. Current:GetAttribute("InteractText") else "E"
				if InteractText ~= GuideLabel.Text then
					local c = GuideLabel:Clone()
					c.Parent = GuideLabel.Parent
					local t = (1 - c.TextTransparency) / 8
					TweenService:Create(c, TweenInfo.new(t, Enum.EasingStyle.Linear), {TextTransparency = 1, TextStrokeTransparency = 1}):Play()
					Debris:AddItem(c, 0.3)
				end
				GuideLabel.Text = InteractText
				GuideLabel.TextTransparency = math.clamp(GuideLabel.TextTransparency - dt * 8, 0, 1)
				GuideLabel.TextStrokeTransparency = math.clamp(GuideLabel.TextStrokeTransparency - dt * 3.2, 0.6, 1)
			end
		else
			ProgressBar.GroupTransparency = math.clamp(ProgressBar.GroupTransparency + dt * 8, 0, 1)
			Highlight.FillTransparency = math.clamp(Highlight.FillTransparency + dt * 2, 0.85, 1)
			GuideLabel.TextTransparency = math.clamp(GuideLabel.TextTransparency + dt * 8, 0, 1)
			GuideLabel.TextStrokeTransparency = math.clamp(GuideLabel.TextStrokeTransparency + dt * 3.2, 0.6, 1)
			
			Title.TextTransparency = math.clamp(Title.TextTransparency + dt * 8, 0, 1)
			Title.TextStrokeTransparency = math.clamp(Title.TextStrokeTransparency + dt * 3.2, 0.6, 1)
			Subtext.TextTransparency = math.clamp(Subtext.TextTransparency + dt * 8, 0, 1)
			Subtext.TextStrokeTransparency = math.clamp(Subtext.TextStrokeTransparency + dt * 3.2, 0.6, 1)
			
			Title.Visible = Title.TextTransparency > 0
			Subtext.Visible = Subtext.TextTransparency > 0
		end

		-- cancel any current interactions if the player is dead, and skip search
		if not Character or not Humanoid or Humanoid.Health <= 0 then
			Current = nil
			if Interacting then
				cancelInteraction()
			end
			return
		end

		-- search for interactable objects
		if Current and Interacting then 
			return -- skip if currently interacting, allowing user to continue interacting after breaking line of sight with object
		end 

		Current = Mouse.Target and Mouse.Target:FindFirstAncestorOfClass("Model")
		if Current and not Current:GetAttribute("Interactable") then Current = CommonFunctions.GetAncestorFromAttribute(Current, "Interactable", true) end
		if Current and not Current:GetAttribute("Interactable") then Current = nil end
		if Current and not Current.PrimaryPart then Current = nil end
		if Current and Current.PrimaryPart and CommonToolFunctions.getDistance(Current.PrimaryPart.Position, Character.PrimaryPart.Position) > Current:GetAttribute("Range") then Current = nil end
		if Highlight.Adornee ~= Current  and Highlight.FillTransparency ~= 1 then
			local c = Highlight:Clone()
			c.Parent = script
			local t = (1 - c.FillTransparency) / 2
			TweenService:Create(c, TweenInfo.new(t, Enum.EasingStyle.Linear), {FillTransparency = 1}):Play()
			Debris:AddItem(c, 0.1)
		end
		if Current then
			Highlight.Adornee = Current
			Highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
		else
			Highlight.Adornee = nil
		end
	end)

	UserInputService.InputBegan:Connect(function(Input, gameProcessed)
		if Debounce or Interacting or gameProcessed or PlayerGui.Inventory.Main.GroupTransparency == 0 or not Character then return end
		
		if Input.KeyCode == KeybindHandler.Keybind("Interact", LocalPlayer) or (Input.UserInputType == Enum.UserInputType.MouseButton1 and (not Character:FindFirstChildOfClass("Tool") or (Character:FindFirstChildOfClass("Tool") and Character:FindFirstChildOfClass("Tool"):GetAttribute("CanInteractWithTool")))) then
			if Current then
				Debounce = true
				BeginningInput = Input
				startInteraction(Current:GetAttribute("InteractTime"))

				task.wait()
				Debounce = false
			end
		end
	end)

	UserInputService.InputEnded:Connect(function(Input)
		if Input == BeginningInput and Interacting then
			cancelInteraction()
		end
	end)
end

return module
