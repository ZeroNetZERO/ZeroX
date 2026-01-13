--====================================================
-- CATRAZ HUB | FISH IT! (DELTA SAFE)
-- FULL FIXED CLEAN (NO AUTO SELL)
-- AUTO TRADE + AUTO ACCEPT INCLUDED
--====================================================

--==============================
-- SAFE LOAD WINDUI
--==============================
local success, WindUI = pcall(function()
    return loadstring(game:HttpGet(
        "https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua"
    ))()
end)

if not success or not WindUI then
    warn("[CatrazHub] WindUI gagal load")
    return
end

--==============================
-- PLAYER GUI (ANTI COREGUI BLOCK)
--==============================
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "CatrazHubSystem"
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true
ScreenGui.Parent = PlayerGui

task.wait(1)

--==============================
-- CREATE WINDOW
--==============================
local Window = WindUI:CreateWindow({
    Title = "Catraz Hub | Fish It!",
    Folder = "CatrazHub",
    Transparent = true,
})

WindUI:Notify({
    Title = "Catraz Hub",
    Content = "UI berhasil dimuat (Delta)",
    Duration = 4,
})

--==============================
-- TABS
--==============================
local automatic = Window:Tab({
    Title = "Automatic",
    Icon = "settings"
})

--==============================
-- REMOTE PATH UTILS
--==============================
local RPath = {"Packages", "_Index", "sleitnick_net@0.2.0", "net"}

local function GetRemote(path, name)
    local obj = game:GetService("ReplicatedStorage")
    for _, v in ipairs(path) do
        obj = obj:WaitForChild(v)
    end
    return obj:FindFirstChild(name)
end

--==============================
-- AUTO ACCEPT TRADE
--==============================
local RE_AcceptTrade = GetRemote(RPath, "RE/AcceptTrade")
local autoAccept = false

automatic:Toggle({
    Title = "Enable Auto Accept Trade",
    Icon = "check-circle",
    Value = false,
    Callback = function(state)
        autoAccept = state
        WindUI:Notify({
            Title = "Auto Accept Trade",
            Content = state and "ON" or "OFF",
            Duration = 2,
        })
    end
})

if RE_AcceptTrade then
    RE_AcceptTrade.OnClientEvent:Connect(function()
        if autoAccept then
            task.wait(0.3)
            pcall(function()
                RE_AcceptTrade:FireServer()
            end)
        end
    end)
end

--==============================
-- AUTO TRADE
--==============================
local RF_InitiateTrade = GetRemote(RPath, "RF/InitiateTrade")

local autoTrade = false
local tradeTargetName = nil
local tradeDelay = 1.2

local function GetPlayerNames()
    local t = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then
            table.insert(t, p.Name)
        end
    end
    return t
end

local targetDropdown = automatic:Dropdown({
    Title = "Trade Target Player",
    Values = GetPlayerNames(),
    Callback = function(v)
        tradeTargetName = v
    end
})

automatic:Button({
    Title = "Refresh Player List",
    Icon = "refresh-ccw",
    Callback = function()
        targetDropdown:Refresh(GetPlayerNames())
    end
})

automatic:Slider({
    Title = "Trade Delay (sec)",
    Value = {Min = 0.5, Max = 5, Default = tradeDelay},
    Step = 0.1,
    Callback = function(v)
        tradeDelay = v
    end
})

automatic:Toggle({
    Title = "Enable Auto Trade",
    Icon = "arrow-left-right",
    Value = false,
    Callback = function(state)
        autoTrade = state
        WindUI:Notify({
            Title = "Auto Trade",
            Content = state and "ON" or "OFF",
            Duration = 2,
        })
    end
})

task.spawn(function()
    while task.wait(tradeDelay) do
        if not autoTrade then continue end
        if not tradeTargetName then continue end
        if not RF_InitiateTrade then continue end

        local target = Players:FindFirstChild(tradeTargetName)
        if not target then continue end

        local backpack = LocalPlayer:FindFirstChild("Backpack")
        if not backpack then continue end

        for _, tool in ipairs(backpack:GetChildren()) do
            if not autoTrade then break end
            if tool:GetAttribute("Favorited") then continue end

            pcall(function()
                RF_InitiateTrade:InvokeServer(target.UserId, tool)
            end)

            task.wait(tradeDelay)
        end
    end
end)

--==============================
-- INFO
--==============================
automatic:Paragraph({
    Title = "Info",
    Content = "✓ Delta Safe\n✓ Auto Trade\n✓ Auto Accept\n✗ No Auto Sell\nGunakan delay ≥ 0.5 detik"
})
