local module = {}

function module:getDistance(point1 : Vector3, point2 : Vector3)
    local distance
    if point1 and point2 then
        distance = (point1 - point2).Magnitude
    else
        warn("getDistance threw an error: No point1 or point2 provided.")
        return nil
    end
    return distance
end

function module:getTotalNumberOfToolsPlayerHas(Player : Player)
    local numberOfTools = 0
    if Player.Character then
        for _,v in pairs(Player.Character:GetDescendants()) do
            if v:IsA("Tool") then
                numberOfTools += 1
            end
        end
    end
    if Player.Backpack then
        for _,v in pairs(Player.Backpack:GetDescendants()) do
            if v:IsA("Tool") then
                numberOfTools += 1
            end
        end
    end
    return numberOfTools
end


return module