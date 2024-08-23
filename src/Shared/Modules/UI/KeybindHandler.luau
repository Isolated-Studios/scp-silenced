local PlayerData = game:GetService("ReplicatedStorage"):WaitForChild("Players")
local module = {}
function module.Keybind(BindName,Player)
    if Player and Player.UserId and PlayerData:FindFirstChild(tostring(Player.UserId)) then
        local UserKeybindsList = PlayerData:FindFirstChild(tostring(Player.UserId)):WaitForChild("Settings"):WaitForChild("Keybinds")
        if UserKeybindsList:FindFirstChild(BindName) then
            return Enum.KeyCode[UserKeybindsList:FindFirstChild(BindName).Value]
        else
            warn(Player.Name.." entered invalid BindName: "..BindName)
        end
    end
end
return module