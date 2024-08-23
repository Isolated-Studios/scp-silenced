local module = {}

function module.Init()
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local UserInputService = game:GetService("UserInputService")
    local TweenService = game:GetService("TweenService")
    local RunService = game:GetService("RunService")
	local Players = game:GetService("Players")
	local Modules = ReplicatedStorage:WaitForChild("Modules")
	local Events = ReplicatedStorage:WaitForChild("Events")
	local Tooling = ReplicatedStorage:WaitForChild("Tooling")
	local DefaultPlayerAnimations = ReplicatedStorage:WaitForChild("PlayerAssets"):WaitForChild("Animations")
	local OtherCharacterAnimations = DefaultPlayerAnimations:WaitForChild("Character"):WaitForChild("Other")
	local OtherVMAnimations = DefaultPlayerAnimations:WaitForChild("Viewmodel"):WaitForChild("Other")
	local ToolingTools = Tooling:WaitForChild("Tools")
	local UIModules = Modules:WaitForChild("UI")
	local ReviveEvent = Events:WaitForChild("Character"):WaitForChild("ReviveEvent")
	local CommonFunctions = require(Modules:WaitForChild("Tool"):WaitForChild("CommonToolFunctions"))
	local KeybindHandler = require(UIModules:WaitForChild("KeybindHandler"))
	local CameraManipulator = require(UIModules:WaitForChild("CameraManipulator"))
	local ViewmodelHandler = require(script.Parent.ViewmodelHandler)
	local InteractPrimes = ReplicatedStorage:WaitForChild("PlayerAssets"):WaitForChild("Interact")
	
    local Animations = InteractPrimes:WaitForChild("Animations"):Clone()
    Animations.Parent = script
    local SelectionBox = InteractPrimes:WaitForChild("SelectionBox"):Clone()
	SelectionBox.Parent = script

    local localPlayer = Players.LocalPlayer
    local Mouse = localPlayer:GetMouse()

    local Character = localPlayer.Character
    while Character == nil or Character.Parent == nil do
        Character = localPlayer.Character
        task.wait(.2)
    end

	local Humanoid = Character:WaitForChild("Humanoid")
	local Animator = Humanoid:WaitForChild("Animator")
	
	--local ExecuteAnim = Animator:LoadAnimation(OtherCharacterAnimations:WaitForChild("Execute"))
	--local ExecuteTargetAnim = Animator:LoadAnimation(OtherCharacterAnimations:WaitForChild("Execute"))
	--local ExecuteVMAnim = Animator:LoadAnimation(OtherVMAnimations:WaitForChild("Execute"))
	local ReviveAnim = Animator:LoadAnimation(OtherCharacterAnimations:WaitForChild("Revive"))
	local ReviveVMAnim = Animator:LoadAnimation(OtherVMAnimations:WaitForChild("Revive"))
	
	local CircularUI = localPlayer.PlayerGui:WaitForChild("MouseUI")
	local InteractText = CircularUI:WaitForChild("Dot"):WaitForChild("Texts"):WaitForChild("InteractText")
	local MessageText = CircularUI:WaitForChild("Dot"):WaitForChild("Texts"):WaitForChild("MessageText")
    local CircularNum = CircularUI.Percentage

    local CircularTweenDown = TweenService:Create(CircularNum,TweenInfo.new(0.1,Enum.EasingStyle.Sine,Enum.EasingDirection.InOut),{Value = 0})
    local Interacting = false
    local CanChange = false
    local Debounce = false

    local TaskDelayId = 0
    local InteractTime

    local validAnims = {

    }
    local CurrentAnimTrack
	local Current = nil
	local BeginningInput = nil
	
	local insecureIds = {4,5}

    local InteractClientFunctions = {
        [1] = function(interactObject, player)
        end,

        [2] = function(interactObject, player) 
        end,
		[3] = function(interactObject, player) 
		end,
		[4] = function(interactObject,player) -- revive
			task.defer(function()
				interactObject:SetAttribute("freezePlayer",nil)
				interactObject:SetAttribute("interactable",nil)
				interactObject:SetAttribute("interactAnimId",nil)
				interactObject:SetAttribute("interactFinishEventId",nil)
				interactObject:SetAttribute("interactText",nil)
				interactObject:SetAttribute("interactTime",nil)
				interactObject:SetAttribute("maxRange",nil)
				interactObject:SetAttribute("NoHighlight",nil)
				local reviveTime = 5
				local currentReviveAnimation = ReviveAnim
				local currentVMReviveAnimation = ReviveVMAnim
				if player.Character:FindFirstChildOfClass("Tool") and player.Character:FindFirstChildOfClass("Tool"):GetAttribute("ToolName") then
					local ToolsFolder = ToolingTools[player.Character:FindFirstChildOfClass("Tool"):GetAttribute("ToolName")]
					if ToolsFolder.CharacterAnimations:FindFirstChild("Revive") then
						currentReviveAnimation = Animator:LoadAnimation(ToolsFolder.CharacterAnimations.Revive)
					end
					if ToolsFolder.VMAnimations:FindFirstChild("Revive") then
						currentVMReviveAnimation = ViewmodelHandler.getAnimation(ToolsFolder.VMAnimations.Revive)
					end
					local Settings = require(ToolsFolder.Settings)
					if Settings.CanRevive then
						reviveTime = Settings.ReviveTime or reviveTime
					end
				end
				Character.Humanoid:SetAttribute("DisableEquip",true)
				currentReviveAnimation:Play()
				currentVMReviveAnimation:Play()
				currentVMReviveAnimation:AdjustSpeed(currentVMReviveAnimation.Length/reviveTime)
				currentReviveAnimation:AdjustSpeed(currentReviveAnimation.Length/reviveTime)
				local severFromInput = false
				local currentTime = tick()
				local downedHumanoid = interactObject:WaitForChild("Humanoid")
				local CircularTweenUp = TweenService:Create(CircularNum,TweenInfo.new(reviveTime,Enum.EasingStyle.Sine,Enum.EasingDirection.InOut),{Value = 100})
				local CircularTweenDown = TweenService:Create(CircularNum,TweenInfo.new(0.1,Enum.EasingStyle.Sine,Enum.EasingDirection.InOut),{Value = 0})
				CircularTweenUp:Play()
				MessageText.Visible = true
				MessageText.Text = "REVIVING: "..string.upper(interactObject.Name)
				local reviveInputBegan = UserInputService.InputBegan:Connect(function(key)
					if key.KeyCode == Enum.KeyCode.W or
						key.KeyCode == Enum.KeyCode.S or
						key.KeyCode == Enum.KeyCode.A or
						key.KeyCode == Enum.KeyCode.D or 
						key.KeyCode == KeybindHandler.Keybind("Interact",player) or 
						key.KeyCode == KeybindHandler.Keybind("Reload",player) or 
						key.UserInputType == Enum.UserInputType.MouseButton1 and Character:FindFirstChildOfClass("Tool") then
						severFromInput = true
					end 
				end)
				while tick()-currentTime < reviveTime do
					if severFromInput or downedHumanoid.Health <= 0 then
						break
					end
					task.wait()
				end
				Character.Humanoid:SetAttribute("DisableEquip",nil)
				currentReviveAnimation:Stop()
				currentVMReviveAnimation:Stop()
				CircularTweenDown:Play()
				MessageText.Visible = false
				MessageText.Text = ""
				if tick()-currentTime >= reviveTime then
					ReviveEvent:FireServer(Character,interactObject)
				else
					ReviveEvent:FireServer(Character,interactObject,true)
				end
				reviveInputBegan:Disconnect()
			end)
		end,
		[5] = function(interactObject, player) -- execute
			MessageText.Text = "EXECUTING: "..string.upper(interactObject.Name)
			local character = player.Character
			character.Humanoid:SetAttribute("DisableEquip",true)
			
			if character:FindFirstChildOfClass("Tool") then

			end
		end,
    }

    local function failedComplete()
        local Char = localPlayer.Character
        Interacting = false
        UserInputService.MouseDeltaSensitivity = 1
        if CurrentAnimTrack then CurrentAnimTrack:Stop() end
        Char:SetAttribute("Interacting", false)
        CanChange = false
        Current = nil
    end

    local function correctComplete()
        local Char = localPlayer.Character
        if Interacting then
            Interacting = false
            UserInputService.MouseDeltaSensitivity = 1
            if CurrentAnimTrack then CurrentAnimTrack:Stop() end
            Char:SetAttribute("Interacting", false)
            CircularTweenDown:Play()
			InteractClientFunctions[Current:GetAttribute("interactFinishEventId")](Current, localPlayer)
			if table.find(insecureIds,Current:GetAttribute("interactFinishEventId")) then
				ReplicatedStorage.Events.Interaction.FinishInteraction:FireServer(Current,Current:GetAttribute("interactFinishEventId"))
			else
				ReplicatedStorage.Events.Interaction.FinishInteraction:FireServer(Current)
			end
            CanChange = false
            Current = nil
        end
    end

   local function startInteraction(InteractTime,textColor)
        local localPlayer = Players.LocalPlayer
        local Animator = Humanoid:WaitForChild("Animator")
        Interacting = true
        if (Current and Current:GetAttribute("interactAnimId") and validAnims[Current:GetAttribute("interactAnimId")] ) then
            CurrentAnimTrack = Animator:LoadAnimation(Animations:WaitForChild(tostring(Current:GetAttribute("interactAnimId"))))
            if CurrentAnimTrack then CurrentAnimTrack:Play() end
            UserInputService.MouseDeltaSensitivity = 0
        end
        if Current:GetAttribute("freezePlayer") == true then
            Character:SetAttribute("Interacting", true)
        end
		local CircularTweenUp = TweenService:Create(CircularNum,TweenInfo.new(InteractTime,Enum.EasingStyle.Sine,Enum.EasingDirection.InOut),{Value = 100})
		if InteractTime > 0 then
			CircularTweenUp:Play()
			CircularTweenUp.Completed:Connect(function()
				correctComplete()
			end)
		else
			correctComplete()
		end
        CanChange = false

    end


    localPlayer.CharacterAdded:Connect(function(char)
        Character = char
        Humanoid = Character:WaitForChild("Humanoid")
        Mouse.TargetFilter = Character
		CircularUI = localPlayer.PlayerGui:WaitForChild("MouseUI")
		InteractText = CircularUI:WaitForChild("Dot"):WaitForChild("Texts"):WaitForChild("InteractText")
        CircularNum = CircularUI.Percentage
        CircularTweenDown = TweenService:Create(CircularNum,TweenInfo.new(0.1,Enum.EasingStyle.Sine,Enum.EasingDirection.InOut),{Value = 0})
        Humanoid.Died:Once(function()
            SelectionBox.Adornee = nil
            SelectionBox.Parent = script
            Interacting = false
            failedComplete()
            CircularTweenDown:Play()
            Character = nil
            Humanoid = nil
        end)
    end)

    Humanoid.Died:Once(function()
        SelectionBox.Adornee = nil
        SelectionBox.Parent = script
        Interacting = false
        failedComplete()
        CircularTweenDown:Play()
        Character = nil
        Humanoid = nil
    end)

    RunService.RenderStepped:Connect(function()
		if Character and Character.PrimaryPart and Humanoid and Humanoid.Health > 0 then
            if Mouse.Target and Mouse.Target.Parent and Mouse.Target.Parent.Parent and not Humanoid:GetAttribute("Downed") then
                if Mouse.Target.Parent:GetAttribute("interactable") and CommonFunctions:getDistance(Mouse.Target.Parent.PrimaryPart.Position, Character.PrimaryPart.Position) <= Mouse.Target.Parent:GetAttribute("maxRange") then
                    SelectionBox.Adornee = Mouse.Target.Parent
                    SelectionBox.Parent = Mouse.Target.Parent
					SelectionBox.OutlineColor = Color3.fromRGB(255, 255, 255)
					if Mouse.Target.Parent:GetAttribute("NoHighlight") then
						SelectionBox.OutlineTransparency = 1
					else
						SelectionBox.OutlineTransparency = 0
					end
					if Mouse.Target.Parent:GetAttribute("interactText") then
						local interactText = string.upper(Mouse.Target.Parent:GetAttribute("interactText")).." : ".."["..KeybindHandler.Keybind("Interact",localPlayer).Name.."]"
						if string.find(InteractText.Text,"REVIVE") and Character:FindFirstChildOfClass("Tool") and Character:FindFirstChildOfClass("Tool"):GetAttribute("CanRevive") then
							interactText = string.upper(Mouse.Target.Parent:GetAttribute("interactText")).." WITH "..string.upper(Character:FindFirstChildOfClass("Tool").Name).." : ".."["..KeybindHandler.Keybind("Interact",localPlayer).Name.."]"
						end
						InteractText.Text = interactText
					else
						InteractText.Text = "INTERACT".." : ".."["..KeybindHandler.Keybind("Interact",localPlayer).Name.."]"
					end
					if not Mouse.Target.Parent:GetAttribute("DisableName") then InteractText.Visible = true end
                    if Mouse.Target.Parent.PrimaryPart and Mouse.Target.Parent:GetAttribute("HighlightColor") then
                        SelectionBox.OutlineColor = Mouse.Target.Parent:GetAttribute("HighlightColor") 
                    end
                elseif Mouse.Target.Parent.Parent:GetAttribute("interactable") and CommonFunctions:getDistance(Mouse.Target.Parent.Parent.PrimaryPart.Position, Character.PrimaryPart.Position) <= Mouse.Target.Parent.Parent:GetAttribute("maxRange") then
					SelectionBox.Adornee = Mouse.Target.Parent.Parent
                    SelectionBox.Parent = Mouse.Target.Parent.Parent
					SelectionBox.OutlineColor = Color3.fromRGB(255, 255, 255)
					if Mouse.Target.Parent.Parent:GetAttribute("NoHighlight") then
						SelectionBox.OutlineTransparency = 1
					else
						SelectionBox.OutlineTransparency = 0
					end
					if Mouse.Target.Parent.Parent:GetAttribute("interactText") then
						local interactText = string.upper(Mouse.Target.Parent.Parent:GetAttribute("interactText")).." : ".."["..KeybindHandler.Keybind("Interact",localPlayer).Name.."]"
						if string.find(InteractText.Text,"REVIVE") and Character:FindFirstChildOfClass("Tool") and Character:FindFirstChildOfClass("Tool"):GetAttribute("CanRevive") then
							interactText = string.upper(Mouse.Target.Parent.Parent:GetAttribute("interactText")).." WITH "..string.upper(Character:FindFirstChildOfClass("Tool").Name).." : ".."["..KeybindHandler.Keybind("Interact",localPlayer).Name.."]"
						end
						InteractText.Text = interactText
					else
						InteractText.Text = "INTERACT".." : ".."["..KeybindHandler.Keybind("Interact",localPlayer).Name.."]"
					end
					if not Mouse.Target.Parent.Parent:GetAttribute("DisableName") then InteractText.Visible = true end
                    if Mouse.Target.Parent.PrimaryPart and Mouse.Target.Parent.Parent:GetAttribute("HighlightColor") then
                        SelectionBox.OutlineColor = Mouse.Target.Parent.Parent:GetAttribute("HighlightColor") 
                    end
				else
					if Interacting then
						CircularTweenDown:Play()
					end
					InteractText.Visible = false
					InteractText.Text = ""
                    SelectionBox.Adornee = nil
                    SelectionBox.Parent = script
                    Interacting = false
					failedComplete()
                end
			else
				if Interacting then
					CircularTweenDown:Play()
				end
				InteractText.Visible = false
				InteractText.Text = ""
                SelectionBox.Adornee = nil
                SelectionBox.Parent = script
                Interacting = false
                failedComplete()
            end
            if Interacting and Current and Character and Character.PrimaryPart and Current.PrimaryPart and CommonFunctions:getDistance(Character.PrimaryPart.Position, Current.PrimaryPart.Position) > Current:GetAttribute("maxRange") then
                Interacting = false
                failedComplete()
                CircularTweenDown:Play()
            end
        end
    end)

	UserInputService.InputBegan:Connect(function(Input)
		if Debounce then return end
		if Interacting then return end
		if localPlayer.PlayerGui.Inventory.Main.GroupTransparency == 0 then return end
		if Input.KeyCode == KeybindHandler.Keybind("Interact",localPlayer) or (Input.UserInputType == Enum.UserInputType.MouseButton1 and (not Character:FindFirstChildOfClass("Tool") or (Character:FindFirstChildOfClass("Tool") and Character:FindFirstChildOfClass("Tool"):GetAttribute("CanInteractWithTool")))) then
	        if Character and (Mouse.Target) and (Mouse.Target.Parent) and (Mouse.Target.Parent:GetAttribute("interactable") and Mouse.Target.Parent:GetAttribute("interactable") == true) then
	            --if CommonFunctions:getDistance(Character.PrimaryPart.Position, Mouse.Target.Position) > Mouse.Target.Parent:GetAttribute("maxRange") then return end
	            Current = Mouse.Target.Parent
				Debounce = true
				BeginningInput = Input
	            InteractTime = Mouse.Target.Parent:GetAttribute("interactTime")
	            local textColor = Color3.fromRGB(20, 140, 200)
	            if Mouse.Target.Parent:FindFirstChild("Hitbox") then
	                textColor = Mouse.Target.Parent.Hitbox:GetAttribute("HighlightColor")
	            end
	            startInteraction(InteractTime,textColor)

				task.delay(0.05, function()
	                Debounce = false
	            end)
	        elseif Character and (Mouse.Target) and (Mouse.Target.Parent) and (Mouse.Target.Parent.Parent) and (Mouse.Target.Parent.Parent:GetAttribute("interactable") and Mouse.Target.Parent.Parent:GetAttribute("interactable") == true) then
	          --  if CommonFunctions:getDistance(Character.PrimaryPart.Position, Mouse.Target.Position) > Mouse.Target.Parent.Parent:GetAttribute("maxRange") then return end
	            Current = Mouse.Target.Parent.Parent
				Debounce = true
				BeginningInput = Input
                InteractTime = Mouse.Target.Parent.Parent:GetAttribute("interactTime")
                local textColor = Color3.fromRGB(20, 140, 200)
                if Mouse.Target.Parent.Parent:FindFirstChild("Hitbox") then
                    textColor = Mouse.Target.Parent.Parent:GetAttribute("HighlightColor")
                end

                startInteraction(InteractTime,textColor)

                task.delay(0.05, function()
                    Debounce = false
                end)
            end
        end
    end)
    UserInputService.InputEnded:Connect(function(Input, gameProcessed)
		if gameProcessed and Humanoid and not Humanoid:GetAttribute("Dragging") then return end
		if Input == BeginningInput and Interacting then
            Interacting = false
            failedComplete()
            CircularTweenDown:Play()
        end
    end)
end

return module