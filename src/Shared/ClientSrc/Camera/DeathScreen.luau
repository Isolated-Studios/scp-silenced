local DeathScreen = {}
local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")

local Player = game.Players.LocalPlayer

local EvilDeathCC = Lighting.EvilDeathCC
local respawnFadeTime = 1

-- Set death screen on character respawn
function DeathScreen.Set ()
	local HUD = Player.PlayerGui:WaitForChild("HUD")
	local MouseUI = Player.PlayerGui.MouseUI
	
	task.defer(function()
		EvilDeathCC.Brightness = -1 -- Darkness
		HUD.EffectFrame.GroupTransparency = 1
		HUD.RightFrame.GroupTransparency = 1
		HUD.Bars.GroupTransparency = 1
		task.wait(0.1)
		TweenService:Create(EvilDeathCC,TweenInfo.new(respawnFadeTime),{Brightness = 0}):Play() -- Fade in back to normal brightness
		TweenService:Create(HUD.EffectFrame,TweenInfo.new(respawnFadeTime),{GroupTransparency = 0}):Play()
		TweenService:Create(HUD.RightFrame,TweenInfo.new(respawnFadeTime),{GroupTransparency = 0}):Play()
		TweenService:Create(HUD.Bars,TweenInfo.new(respawnFadeTime),{GroupTransparency = 0}):Play()
	end)

	local DeathMessage = Player.PlayerGui.HUD.DeathMessage
	DeathMessage.BeginningText.TextTransparency = 1
	DeathMessage.NameText.TextTransparency = 1
	DeathMessage.NameText.Text = "YOURSELF" -- Default death name text
	
	MouseUI.Enabled = true
end

-- Display death screen on death
function DeathScreen.Display (Humanoid: Humanoid)
	local HUD = Player.PlayerGui:WaitForChild("HUD")
	local MouseUI = Player.PlayerGui.MouseUI
	local DeathMessage = Player.PlayerGui.HUD.DeathMessage
	
	task.defer(function()
		-- turn main HUD and mouse ui invisible
		MouseUI.Enabled = false
		HUD.EffectFrame.GroupTransparency = 1
		HUD.RightFrame.GroupTransparency = 1
		HUD.Bars.GroupTransparency = 1

		if Humanoid:GetAttribute("Killer") and Humanoid:GetAttribute("Killer") ~= Player.Name then -- display Killer's name if Killer exist
			DeathMessage.NameText.Text = string.upper(Humanoid:GetAttribute("Killer"))
		end

		if HUD:FindFirstChild("BloodScreen") then
			TweenService:Create(HUD.BloodScreen,TweenInfo.new(Players.RespawnTime/6),{ImageTransparency = 1}):Play()
		end
		-- Flash of white
		EvilDeathCC.Brightness = 1 
		task.wait(Players.RespawnTime/20)
		-- Back to normal brightness
		TweenService:Create(EvilDeathCC,TweenInfo.new(Players.RespawnTime/20),{Brightness = 0}):Play()
		task.wait(Players.RespawnTime/20)
		-- Fade to black
		TweenService:Create(EvilDeathCC,TweenInfo.new(Players.RespawnTime/2),{Brightness = -1}):Play()
		task.wait(Players.RespawnTime/3)
		-- Display beginning message
		TweenService:Create(DeathMessage.BeginningText,TweenInfo.new(Players.RespawnTime/6),{TextTransparency = 0}):Play()
		task.wait(Players.RespawnTime/6)
		-- Display killer name
		TweenService:Create(DeathMessage.NameText,TweenInfo.new(Players.RespawnTime/6),{TextTransparency = 0}):Play() 
	end)
end

return DeathScreen
