getgenv().WhitelistSettings = {
    Enabled = false,
    Players = {
        1,
        2,
        3
    }
}

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local AlertSound = Instance.new("Sound")
AlertSound.SoundId = "rbxassetid://102770722936174"
AlertSound.Volume = 1
AlertSound.Parent = game:GetService("SoundService")

local function IsWhitelisted(plr)
    for _,id in ipairs(WhitelistSettings.Players) do
        if plr.UserId == id then
            return true
        end
    end
    return false
end

local function ApplySpeed()
    local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local humanoid = char:WaitForChild("Humanoid")

    task.spawn(function()
        while WhitelistSettings.Enabled do
            humanoid.WalkSpeed = 100
            humanoid.JumpPower = 100
            task.wait()
        end
    end)
end

local function CheckWhitelist()

    if not WhitelistSettings.Enabled then
        return
    end

    for _,plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and not IsWhitelisted(plr) then
            AlertSound:Play()
            ApplySpeed()
            break
        end
    end

end

CheckWhitelist()

Players.PlayerAdded:Connect(function(plr)
    if WhitelistSettings.Enabled and not IsWhitelisted(plr) then
        AlertSound:Play()
        ApplySpeed()
    end
end)

getgenv().S_Hold = {
    Enabled = false;
    Notifications = true;
    Keybind = '9';
}

local OriginalTouchStates = {}
local RunService = game:GetService("RunService")
local BoostLoop = nil

local HookedHandles = {}

local function HookHandle(Handle)
    if HookedHandles[Handle] then return end
    HookedHandles[Handle] = true

    local OriginalProps = OriginalTouchStates[Handle]
    if not OriginalProps then return end

    local mt = getrawmetatable(Handle)
    local oldIndex = mt.__index
    local oldNewIndex = mt.__newindex

    setreadonly(mt, false)

    mt.__index = newcclosure(function(t, k)
        if t == Handle and S_Hold.Enabled then
            if k == "CanTouch" then
                return OriginalProps.CanTouch
            end
        end
        return oldIndex(t, k)
    end)

    mt.__newindex = newcclosure(function(t, k, v)
        if t == Handle and S_Hold.Enabled then
            if k == "CanTouch" then
                return
            end
        end
        return oldNewIndex(t, k, v)
    end)

    setreadonly(mt, true)
end

local FireDamageBoost = function()
    if not S_Hold.Enabled then return end

    local char = game.Players.LocalPlayer.Character
    if not char then return end

    local tool = char:FindFirstChildWhichIsA("Tool")
    if not tool then return end

    local handle = tool:FindFirstChild("Handle")
    if not handle then return end

    for _, plr in ipairs(game.Players:GetPlayers()) do
        if plr ~= game.Players.LocalPlayer and plr.Character then
            local target = plr.Character

            for _, part in ipairs(target:GetChildren()) do
                if part:IsA("BasePart") then
                    local touchCount = math.random(12, 18)
                    for i = 1, touchCount do
                        handle:TouchStarted(part)
                        handle:TouchEnded(part)
                    end
                end
            end
        end
    end
end

local StartBoostLoop = function()
    if BoostLoop then return end

    BoostLoop = RunService.RenderStepped:Connect(function()
        if S_Hold.Enabled then
            FireDamageBoost()
        end
    end)
end

local StopBoostLoop = function()
    if BoostLoop then
        BoostLoop:Disconnect()
        BoostLoop = nil
    end
end

local UpdateEnemyHandles = function()
    for _, Player in pairs(game.Players:GetPlayers()) do
        if Player == game.Players.LocalPlayer then continue end

        local Character = Player.Character
        if not Character then continue end

        for _, Child in pairs(Character:GetChildren()) do
            if Child:IsA('Tool') then
                local Handle = Child:FindFirstChild('Handle')
                if Handle then
                    if not OriginalTouchStates[Handle] then
                        OriginalTouchStates[Handle] = {
                            CanTouch = Handle.CanTouch,
                        }
                    end

                    if S_Hold.Enabled then
                        Handle.CanTouch = false
                        HookHandle(Handle)
                    else
                        Handle.CanTouch = OriginalTouchStates[Handle].CanTouch
                    end
                end
            end
        end
    end
end
