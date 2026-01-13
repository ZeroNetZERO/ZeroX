--====================================================
-- CATRAZ HUB | FISH IT! (DELTA SAFE)
-- FULL FIXED CLEAN
-- AUTO TRADE + AUTO ACCEPT
-- NO AUTO SELL
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
-- SERVICES
--==============================
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer

--==============================
-- WINDOW
--==============================
local Window = WindUI:CreateWindow({
    Title = "Catraz Hub | Fish It!",
    Folder = "CatrazHub",
    Transparent = true,
})

WindUI:Notify({
    Title = "Catraz Hub",
    Content = "Loaded successfully (Delta)",
    Duration = 3
})

--==============================
-- TAB
--==============================
local automatic = Window:Tab({
    Title = "Automatic",
    Icon = "settings"
})

--==============================
-- REMOTE UTILS
--==============================
local RPath = {"Packages","_Index","sleitnick_net@0.2.0","net"}

local function GetRemote(path, name)
    local obj = ReplicatedStorage
    for _, v in ipairs(path) do
        obj = obj:WaitForChild(v)
    end
    return obj:FindFirstChild(name)
end

--==============================
-- SAFE FALLBACK DATA (WAJIB)
--==============================
local function GetPlayerDataReplion()
    local replion = ReplicatedStorage:FindFirstChild("Replion")
    if not replion then return nil end
    local ok, data = pcall(function()
        return replion:WaitForChild("PlayerData")
    end)
    return ok and data or nil
end

local function GetFishNameAndRarity(item)
    if not item then return "Unknown","Default" end
    local name = tostring(item.Id or "Unknown")
    local rarity = "Default"
    if item.Metadata and item.Metadata.Rarity then
        rarity = tostring(item.Metadata.Rarity)
    end
    return name, rarity
end

--====================================================
-- AUTO TRADE
--====================================================
local trade = automatic:Section({ Title = "Auto Trade", TextSize = 20 })

local autoTrade = false
local tradeThread = nil
local tradeDelay = 1
local tradeAmount = 0
local tradedCount = 0
local holdFavorite = false

local selectedTargetId = nil
local selectedItemName = nil
local selectedRarity = nil

--==============================
-- PLAYER LIST
--==============================
local function GetPlayersList()
    local t = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then
            table.insert(t, p.Name)
        end
    end
    return t
end

local targetDropdown = trade:Dropdown({
    Title = "Trade Target",
    Values = GetPlayersList(),
    AllowNone = true,
    Callback = function(name)
        local p = Players:FindFirstChild(name or "")
        selectedTargetId = p and p.UserId or nil
    end
})

trade:Button({
    Title = "Refresh Player List",
    Callback = function()
        targetDropdown:Refresh(GetPlayersList())
        selectedTargetId = nil
    end
})

--==============================
-- FILTER
--==============================
trade:Dropdown({
    Title = "Filter Item Name",
    Values = {},
    AllowNone = true,
    Callback = function(v)
        selectedItemName = v
    end
})

trade:Dropdown({
    Title = "Filter Rarity",
    Values = {"Common","Uncommon","Rare","Epic","Legendary","Mythic","SECRET","Default"},
    AllowNone = true,
    Callback = function(v)
        selectedRarity = v
    end
})

--==============================
-- SETTINGS
--==============================
trade:Input({
    Title = "Trade Amount (0 = Unlimited)",
    Placeholder = "0",
    Callback = function(v)
        tradeAmount = math.max(0, tonumber(v) or 0)
    end
})

trade:Slider({
    Title = "Trade Delay (sec)",
    Value = {Min = 0.5, Max = 5, Default = 1},
    Step = 0.1,
    Callback = function(v)
        tradeDelay = math.max(0.5, v)
    end
})

trade:Toggle({
    Title = "Hold Favorite Items",
    Value = false,
    Callback = function(v)
        holdFavorite = v
    end
})

--==============================
-- INVENTORY
--==============================
local function GetTradeItems()
    local replion = GetPlayerDataReplion()
    if not replion then return {} end

    local ok, inv = pcall(function()
        return replion:GetExpect("Inventory")
    end)
    if not ok or not inv or not inv.Items then return {} end

    local list = {}

    for _, item in ipairs(inv.Items) do
        if holdFavorite and (item.IsFavorite or item.Favorited) then
            continue
        end

        local name, rarity = GetFishNameAndRarity(item)

        if selectedItemName and name ~= selectedItemName then continue end
        if selectedRarity and rarity:upper() ~= selectedRarity:upper() then continue end

        table.insert(list, {
            UUID = tostring(item.UUID),
            Name = name
        })
    end

    return list
end

--==============================
-- AUTO TRADE LOOP
--==============================
local function StartAutoTrade()
    if tradeThread then
        task.cancel(tradeThread)
    end

    tradeThread = task.spawn(function()
        local RF = GetRemote(RPath,"RF/InitiateTrade")
        if not RF or not selectedTargetId then
            WindUI:Notify({
                Title = "Auto Trade",
                Content = "Target belum dipilih",
                Duration = 3,
                Icon = "alert-triangle"
            })
            autoTrade = false
            return
        end

        tradedCount = 0

        while autoTrade do
            if tradeAmount > 0 and tradedCount >= tradeAmount then
                break
            end

            local items = GetTradeItems()
            if #items == 0 then
                task.wait(1)
                continue
            end

            local item = items[1]

            pcall(function()
                RF:InvokeServer(selectedTargetId, item.UUID)
            end)

            tradedCount += 1
            task.wait(tradeDelay)
        end

        autoTrade = false
    end)
end

trade:Toggle({
    Title = "Enable Auto Trade",
    Icon = "arrow-left-right",
    Callback = function(v)
        autoTrade = v
        if v then
            StartAutoTrade()
        else
            if tradeThread then
                task.cancel(tradeThread)
                tradeThread = nil
            end
        end
    end
})

--====================================================
-- AUTO ACCEPT TRADE
--====================================================
local RE_AcceptTrade = GetRemote(RPath,"RE/AcceptTrade")
_G.Catraz_AutoAccept = false

trade:Toggle({
    Title = "Auto Accept Trade",
    Value = false,
    Callback = function(v)
        _G.Catraz_AutoAccept = v
    end
})

if RE_AcceptTrade then
    RE_AcceptTrade.OnClientEvent:Connect(function()
        if _G.Catraz_AutoAccept then
            task.wait(0.25)
            pcall(function()
                RE_AcceptTrade:FireServer()
            end)
        end
    end)
end

--==============================
-- INFO
--==============================
automatic:Paragraph({
    Title = "Info",
    Content = "✓ Delta Safe\n✓ Auto Trade\n✓ Auto Accept\n✗ No Auto Sell\nGunakan delay ≥ 0.5 detik"
})
