-- ZeroX Fish It - Remade from WindUI
-- Premium Version

local ZeroX = loadstring(game:HttpGet("https://raw.githubusercontent.com/ZeroNetZERO/ZeroFISH/refs/heads/main/Library.lua"))() 
-- OR use local: local ZeroX = loadfile("Library.lua")()

local HttpService = game:GetService("HttpService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local LocalPlayer = game:GetService("Players").LocalPlayer
local RepStorage = game:GetService("ReplicatedStorage")
local CoreGui = game:GetService("CoreGui")

-- Utilities
local ItemUtility = require(RepStorage:WaitForChild("Shared"):WaitForChild("ItemUtility", 10))
local TierUtility = require(RepStorage:WaitForChild("Shared"):WaitForChild("TierUtility", 10))

local pos_saved = nil
local look_saved = nil
local stealthMode = false
local stealthHight = 110

local RPath = {"Packages", "_Index", "sleitnick_net@0.2.0", "net"}
local PlayerDataReplion = nil

-- Helper Functions
local function GetRemote(name, timeout)
    local currentInstance = RepStorage
    for _, childName in ipairs(RPath) do
        currentInstance = currentInstance:WaitForChild(childName, timeout or 0.5)
        if not currentInstance then return nil end
    end
    return currentInstance:FindFirstChild(name)
end

local function GetHumanoid()
    local Character = LocalPlayer.Character
    if not Character then
        Character = LocalPlayer.CharacterAdded:Wait()
    end
    return Character:FindFirstChildOfClass("Humanoid")
end

local function GetHRP()
    local Character = LocalPlayer.Character
    if not Character then
        Character = LocalPlayer.CharacterAdded:Wait()
    end
    return Character:WaitForChild("HumanoidRootPart", 5)
end

local function TeleportStealth()
    local hrp = GetHRP()
    if hrp and typeof(pos_saved) == "Vector3" and typeof(look_saved) == "Vector3" then
        local targetCFrame = CFrame.new(pos_saved, pos_saved + look_saved)
        hrp.CFrame = targetCFrame * CFrame.new(0, stealthHight, 0)
    end
end

local function TeleportToLookAt()
    local hrp = GetHRP()
    hrp.Anchored = false
    if hrp and typeof(pos_saved) == "Vector3" and typeof(look_saved) == "Vector3" then
        local targetCFrame = CFrame.new(pos_saved, pos_saved + look_saved)
        hrp.CFrame = targetCFrame * CFrame.new(0, 0.5, 0)
        if stealthMode then
            TeleportStealth()
            wait(0.1)
            hrp.Anchored = true
        end
        zerox("Teleport Sukses!", 3, Color3.fromRGB(0, 255, 0), "ZeroX", "Teleport")
    else
        zerox("Data posisi tidak valid.", 3, Color3.fromRGB(255, 0, 0), "ZeroX", "Error")
    end
end

-- Anti AFK
pcall(function()
    for i, v in pairs(getconnections(LocalPlayer.Idled)) do
        if v.Disable then v:Disable() end
    end
end)

local function GetPlayerDataReplion()
    if PlayerDataReplion then return PlayerDataReplion end
    local ReplionModule = RepStorage:WaitForChild("Packages"):WaitForChild("Replion", 10)
    if not ReplionModule then return nil end
    local ReplionClient = require(ReplionModule).Client
    PlayerDataReplion = ReplionClient:WaitReplion("Data", 5)
    return PlayerDataReplion
end

local RF_SellAllItems = GetRemote("RF/SellAllItems", 5)

local function GetFishNameAndRarity(item)
    local name = item.Identifier or "Unknown"
    local rarity = item.Metadata and item.Metadata.Rarity or "COMMON"
    local itemID = item.Id
    local itemData = nil

    if ItemUtility and itemID then
        pcall(function()
            itemData = ItemUtility:GetItemData(itemID)
            if not itemData then
                local numericID = tonumber(item.Id) or tonumber(item.Identifier)
                if numericID then
                    itemData = ItemUtility:GetItemData(numericID)
                end
            end
        end)
    end

    if itemData and itemData.Data and itemData.Data.Name then
        name = itemData.Data.Name
    end

    if item.Metadata and item.Metadata.Rarity then
        rarity = item.Metadata.Rarity
    elseif itemData and itemData.Probability and itemData.Probability.Chance and TierUtility then
        local tierObj = nil
        pcall(function()
            tierObj = TierUtility:GetTierFromRarity(itemData.Probability.Chance)
        end)
        if tierObj and tierObj.Name then
            rarity = tierObj.Name
        end
    end

    return name, rarity
end

local function GetItemMutationString(item)
    if item.Metadata and item.Metadata.Shiny == true then return "Shiny" end
    return item.Metadata and item.Metadata.VariantId or ""
end

local function CensorName(name)
    if not name or type(name) ~= "string" or #name < 1 then return "N/A" end
    if #name <= 3 then return name end
    local prefix = name:sub(1, 3)
    local censureLength = #name - 3
    local censorString = string.rep("*", censureLength)
    return prefix .. censorString
end

-- Auto Accept Trade Hook
do
    local PromptController = nil
    local Promise = nil
    pcall(function()
        PromptController = require(RepStorage:WaitForChild("Controllers").PromptController)
        Promise = require(RepStorage:WaitForChild("Packages").Promise)
    end)
    
    _G.BloxFish_AutoAcceptTradeEnabled = false

    if PromptController and PromptController.FirePrompt and Promise then
        local oldFirePrompt = PromptController.FirePrompt
        PromptController.FirePrompt = function(self, promptText, ...)
            if _G.BloxFish_AutoAcceptTradeEnabled and type(promptText) == "string" and promptText:find("Accept") and promptText:find("from:") then
                return Promise.new(function(resolve)
                    task.wait(2)
                    resolve(true)
                end)
            end
            return oldFirePrompt(self, promptText, ...)
        end
    end
end

-- Fishing Areas
local FishingAreas = {
    ["Ancient Jungle"] = { cframe = Vector3.new(1896.9, 8.4, -578.7), lookup = Vector3.new(0.973, 0.000, 0.229) },
    ["Ancient Ruins"] = { cframe = Vector3.new(6081.4, -585.9, 4634.5), lookup = Vector3.new(-0.619, -0.000, 0.785) },
    ["Christmast Island"] = { cframe = Vector3.new(1175.3,23.5,1545.3), lookup = Vector3.new(-0.787,-0.000,0.616) },
    ["Coral Reefs"] = { cframe = Vector3.new(-2935.1,4.8,2050.9), lookup = Vector3.new(-0.306,-0.000,0.952) },
    ["Crater Island"] = { cframe = Vector3.new(1077.6, 2.8, 5080.9), lookup = Vector3.new(-0.987, 0.000, -0.159) },
    ["Esoteric Deep"] = { cframe = Vector3.new(3202.2, -1302.9, 1432.7), lookup = Vector3.new(0.896, 0.000, -0.444) },
    ["Iron Cavern"] = { cframe = Vector3.new(-8794.5, -585.0, 89.0), lookup = Vector3.new(0.741, -0.000, -0.672) },
    ["Kohana"] = { cframe = Vector3.new(-367.8, 6.8, 521.9), lookup = Vector3.new(0.000, -0.000, -1.000) },
    ["Sacred Temple"] = { cframe = Vector3.new(1466.6, -22.8, -618.8), lookup = Vector3.new(-0.389, 0.000, 0.921) },
    ["Tropical Grove"] = { cframe = Vector3.new(-2173.3,53.5,3632.3), lookup = Vector3.new(0.729,0.000,0.684) },
    ["Underground Cellar"] = { cframe = Vector3.new(2136.0, -91.2, -699.0), lookup = Vector3.new(-0.000, 0.000, -1.000) }
}

local AreaNames = {}
for name, _ in pairs(FishingAreas) do
    table.insert(AreaNames, name)
end
table.sort(AreaNames)

-- ==================== CREATE UI ====================
local Window = ZeroX:Window({
    Title = "ZeroX",
    Footer = "| Fish It Premium",
    Color = Color3.fromRGB(138, 43, 226),
    ["Tab Width"] = 130,
    Version = 1
})

local Tabs = Window:AddTab({ Name = "Fishing", Icon = "rod" })

-- ==================== FISHING TAB ====================
local RE_EquipToolFromHotbar = GetRemote("RE/EquipToolFromHotbar")
local RF_ChargeFishingRod = GetRemote("RF/ChargeFishingRod")
local RF_RequestFishingMinigameStarted = GetRemote("RF/RequestFishingMinigameStarted")
local RE_FishingCompleted = GetRemote("RE/FishingCompleted")
local RF_CancelFishingInputs = GetRemote("RF/CancelFishingInputs")
local RF_UpdateAutoFishingState = GetRemote("RF/UpdateAutoFishingState")

local instantLoopThread = nil
local blatantFishv1LoopThread = nil
local blatantFishv2LoopThread = nil
local InstantState = nil
local blatantV1State = nil
local blatantV2State = nil
local minigameDelay = 1
local cycleDelay = 1.97

local walkOnWaterConnection = nil
local isWalkOnWater = false
local waterPlatform = nil
local autoERodConn = nil
local isNoAnimationActive = false
local originalAnimator = nil
local originalAnimateScript = nil

-- Walk on Water Function
local function WoW()
    if not waterPlatform then
        waterPlatform = Instance.new("Part")
        waterPlatform.Name = "WaterPlatform"
        waterPlatform.Anchored = true
        waterPlatform.CanCollide = true
        waterPlatform.Transparency = 1
        waterPlatform.Size = Vector3.new(15, 1, 15)
        waterPlatform.Parent = workspace
    end
    
    if walkOnWaterConnection then walkOnWaterConnection:Disconnect() end
    
    walkOnWaterConnection = game:GetService("RunService").RenderStepped:Connect(function()
        local character = LocalPlayer.Character
        if not isWalkOnWater or not character then return end
        
        local hrp = character:FindFirstChild("HumanoidRootPart")
        if not hrp then return end
        
        if not waterPlatform or not waterPlatform.Parent then
            waterPlatform = Instance.new("Part")
            waterPlatform.Name = "WaterPlatform"
            waterPlatform.Anchored = true
            waterPlatform.CanCollide = true
            waterPlatform.Transparency = 1
            waterPlatform.Size = Vector3.new(15, 1, 15)
            waterPlatform.Parent = workspace
        end
        
        local rayParams = RaycastParams.new()
        rayParams.FilterDescendantsInstances = {workspace.Terrain}
        rayParams.FilterType = Enum.RaycastFilterType.Include
        rayParams.IgnoreWater = false
        
        local rayOrigin = hrp.Position + Vector3.new(0, 5, 0)
        local rayDirection = Vector3.new(0, -200, 0)
        local result = workspace:Raycast(rayOrigin, rayDirection, rayParams)
        
        if result and result.Material == Enum.Material.Water then
            local waterSurfaceHeight = result.Position.Y
            waterPlatform.Position = Vector3.new(hrp.Position.X, waterSurfaceHeight, hrp.Position.Z)
            if hrp.Position.Y < (waterSurfaceHeight + 2) and hrp.Position.Y > (waterSurfaceHeight - 5) then
                if not UserInputService:IsKeyDown(Enum.KeyCode.Space) then
                    hrp.CFrame = CFrame.new(hrp.Position.X, waterSurfaceHeight + 3.2, hrp.Position.Z)
                end
            end
        else
            waterPlatform.Position = Vector3.new(hrp.Position.X, -500, hrp.Position.Z)
        end
    end)
end

-- Disable/Enable Animations
local function DisableAnimations()
    local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local humanoid = GetHumanoid()
    if not humanoid then return end

    local animateScript = character:FindFirstChild("Animate")
    if animateScript and animateScript:IsA("LocalScript") and animateScript.Enabled then
        originalAnimateScript = animateScript.Enabled
        animateScript.Enabled = false
    end

    local animator = humanoid:FindFirstChildOfClass("Animator")
    if animator then
        originalAnimator = animator
        animator:Destroy()
    end
end

local function EnableAnimations()
    local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local animateScript = character:FindFirstChild("Animate")
    if animateScript and originalAnimateScript ~= nil then
        animateScript.Enabled = originalAnimateScript
    end
    
    local humanoid = GetHumanoid()
    if not humanoid then return end

    local existingAnimator = humanoid:FindFirstChildOfClass("Animator")
    if not existingAnimator then
        if originalAnimator and not originalAnimator.Parent then
            originalAnimator.Parent = humanoid
        else
            Instance.new("Animator").Parent = humanoid
        end
    end
    originalAnimator = nil
end

local function OnCharacterAdded(newCharacter)
    if isNoAnimationActive then
        task.wait(0.2)
        DisableAnimations()
    end
end

-- Fishing Functions
local function instantOk()
    RF_ChargeFishingRod:InvokeServer(1, 0.999)
    RF_RequestFishingMinigameStarted:InvokeServer(1, 0.999)
    task.wait(minigameDelay)
    RE_FishingCompleted:FireServer()
    task.wait(0.3)
    RF_CancelFishingInputs:InvokeServer()
end

local function blatantFishv1()
    task.spawn(function() RF_CancelFishingInputs:InvokeServer(1, 0.99) end)
    task.spawn(function() RF_ChargeFishingRod:InvokeServer(1, 0.99) end)
    task.spawn(function()
        task.wait(0.016)
        RF_RequestFishingMinigameStarted:InvokeServer(1, 0.99)
        task.wait(minigameDelay)
        RE_FishingCompleted:FireServer()
    end)
end

local function blatantFishv2()
    task.spawn(function() pcall(function() RF_CancelFishingInputs:InvokeServer() end) end)
    task.spawn(function() pcall(function() RF_ChargeFishingRod:InvokeServer(1, 0.999) end) end)
    task.spawn(function()
        task.wait(0.016)
        pcall(function() RF_RequestFishingMinigameStarted:InvokeServer(1, 0.999) end)
    end)
    task.spawn(function()
        task.wait(minigameDelay)
        pcall(function() RE_FishingCompleted:FireServer() end)
    end)
end

_G.BloxFish_BlatantActive = false

-- Hook Fishing Controller
task.spawn(function()
    local S1, FishingController = pcall(function() return require(RepStorage.Controllers.FishingController) end)
    if S1 and FishingController then
        local Old_Charge = FishingController.RequestChargeFishingRod
        local Old_Cast = FishingController.SendFishingRequestToServer
        
        FishingController.RequestChargeFishingRod = function(...)
            if _G.BloxFish_BlatantActive then return end
            return Old_Charge(...)
        end
        FishingController.SendFishingRequestToServer = function(...)
            if _G.BloxFish_BlatantActive then return false, "Blocked" end
            return Old_Cast(...)
        end
    end
end)

-- Remote Blocker
local mt = getrawmetatable(game)
local old_namecall = mt.__namecall
setreadonly(mt, false)
mt.__namecall = newcclosure(function(self, ...)
    local method = getnamecallmethod()
    if _G.BloxFish_BlatantActive and not checkcaller() then
        if method == "InvokeServer" and (self.Name == "RequestFishingMinigameStarted" or self.Name == "ChargeFishingRod" or self.Name == "UpdateAutoFishingState") then
            return nil
        end
        if method == "FireServer" and self.Name == "FishingCompleted" then
            return nil
        end
    end
    return old_namecall(self, ...)
end)
setreadonly(mt, true)

-- Legit Auto Fish Logic
local FishingController = require(RepStorage:WaitForChild("Controllers").FishingController)
local AutoFishingController = require(RepStorage:WaitForChild("Controllers").AutoFishingController)

local AutoFishState = { IsActive = false, MinigameActive = false }
local SPEED_LEGIT = 0.05
local legitClickThread = nil

local function performClick()
    if FishingController then
        FishingController:RequestFishingMinigameClick()
        task.wait(SPEED_LEGIT)
    end
end

local originalRodStarted = FishingController.FishingRodStarted
FishingController.FishingRodStarted = function(self, arg1, arg2)
    originalRodStarted(self, arg1, arg2)
    if AutoFishState.IsActive and not AutoFishState.MinigameActive then
        AutoFishState.MinigameActive = true
        if legitClickThread then task.cancel(legitClickThread) end
        legitClickThread = task.spawn(function()
            while AutoFishState.IsActive and AutoFishState.MinigameActive do
                performClick()
            end
        end)
    end
end

local originalFishingStopped = FishingController.FishingStopped
FishingController.FishingStopped = function(self, arg1)
    originalFishingStopped(self, arg1)
    if AutoFishState.MinigameActive then
        AutoFishState.MinigameActive = false
    end
end

local function ToggleAutoClick(shouldActivate)
    if not FishingController or not AutoFishingController then
        zerox("Gagal memuat Fishing Controllers.", 4, Color3.fromRGB(255, 0, 0), "ZeroX", "Error")
        return
    end
    
    AutoFishState.IsActive = shouldActivate
    local playerGui = LocalPlayer:WaitForChild("PlayerGui")
    local fishingGui = playerGui:FindFirstChild("Fishing") and playerGui.Fishing:FindFirstChild("Main")
    local chargeGui = playerGui:FindFirstChild("Charge") and playerGui.Charge:FindFirstChild("Main")

    if shouldActivate then
        pcall(function() RE_EquipToolFromHotbar:FireServer(1) end)
        pcall(function() RF_UpdateAutoFishingState:InvokeServer(true) end)
        if fishingGui then fishingGui.Visible = false end
        if chargeGui then chargeGui.Visible = false end
    else
        pcall(function() RF_UpdateAutoFishingState:InvokeServer(false) end)
        if legitClickThread then
            task.cancel(legitClickThread)
            legitClickThread = nil
        end
        AutoFishState.MinigameActive = false
        if fishingGui then fishingGui.Visible = true end
        if chargeGui then chargeGui.Visible = true end
    end
end

-- ==================== UI SECTIONS ====================

-- Fishing Support Section
local FishSupport = Tabs:AddSection("Fishing Support", false)

FishSupport:AddToggle({
    Title = "Walk On Water",
    Default = false,
    Callback = function(state)
        if state then
            isWalkOnWater = true
            WoW()
        else
            isWalkOnWater = false
            if walkOnWaterConnection then walkOnWaterConnection:Disconnect() walkOnWaterConnection = nil end
            if waterPlatform then waterPlatform:Destroy() waterPlatform = nil end
        end
    end
})

FishSupport:AddToggle({
    Title = "Auto Equip Rod",
    Default = false,
    Callback = function(b)
        if b then
            if autoERodConn then task.cancel(autoERodConn) autoERodConn = nil end
            autoERodConn = task.spawn(function()
                while b do
                    pcall(function() RE_EquipToolFromHotbar:FireServer(1) end)
                    task.wait(1)
                end
            end)
        else
            if autoERodConn then task.cancel(autoERodConn) autoERodConn = nil end
        end
    end
})

FishSupport:AddToggle({
    Title = "Disable Animation",
    Default = false,
    Callback = function(b)
        isNoAnimationActive = b
        if b then DisableAnimations() else EnableAnimations() end
    end
})

FishSupport:AddToggle({
    Title = "Disable Fish Notif",
    Default = false,
    Callback = function(s)
        s = not s
        pcall(function() LocalPlayer.PlayerGui["Small Notification"].Display.Visible = s end)
    end
})

FishSupport:AddToggle({
    Title = "Auto Accept Trade",
    Default = false,
    Callback = function(c)
        _G.BloxFish_AutoAcceptTradeEnabled = c
    end
})

FishSupport:AddInput({
    Title = "Stealth Height",
    Default = tostring(stealthHight),
    Callback = function(s)
        stealthHight = tonumber(s) or 110
    end
})

FishSupport:AddToggle({
    Title = "Stealth Mode",
    Default = false,
    Callback = function(state)
        local hrp = GetHRP()
        pos_saved = hrp.Position
        look_saved = hrp.CFrame.LookVector
        stealthMode = state
        if state then
            TeleportToLookAt()
        else
            hrp.Anchored = state
            wait(0.1)
            TeleportToLookAt()
        end
    end
})

-- Auto Fishing Section
local AutoFish = Tabs:AddSection("Auto Fishing", false)

AutoFish:AddSlider({
    Title = "Legit Click Speed",
    Min = 0.01,
    Max = 0.5,
    Default = SPEED_LEGIT,
    Increment = 0.01,
    Callback = function(value)
        local newSpeed = tonumber(value)
        if newSpeed and newSpeed >= 0.01 then
            SPEED_LEGIT = newSpeed
        end
    end
})

AutoFish:AddToggle({
    Title = "Auto Fish (Legit)",
    Default = false,
    Callback = function(state)
        ToggleAutoClick(state)
    end
})

-- Instant Fishing Section
local InstantFish = Tabs:AddSection("Instant Fishing", false)

InstantFish:AddInput({
    Title = "Complete Delay",
    Default = "1",
    Callback = function(s)
        minigameDelay = tonumber(s) or 1
    end
})

InstantFish:AddToggle({
    Title = "Instant Fish",
    Default = false,
    Callback = function(state)
        InstantState = state
        _G.BloxFish_BlatantActive = state
        pcall(function() RF_UpdateAutoFishingState:InvokeServer(state) end)
        
        if state then
            instantLoopThread = task.spawn(function()
                while InstantState do
                    instantOk()
                    task.wait(0.1)
                end
            end)
        else
            if instantLoopThread then task.cancel(instantLoopThread) instantLoopThread = nil end
        end
    end
})

-- Blatant V1 Section
local BlatantV1 = Tabs:AddSection("BlatantV1 Fishing", false)

BlatantV1:AddInput({
    Title = "Cast Delay",
    Default = "1.97",
    Callback = function(s)
        cycleDelay = tonumber(s) or 1.97
    end
})

BlatantV1:AddInput({
    Title = "Complete Delay",
    Default = "0.97",
    Callback = function(s)
        minigameDelay = tonumber(s) or 0.97
    end
})

BlatantV1:AddToggle({
    Title = "BlatantV1 Fish",
    Default = false,
    Callback = function(state)
        blatantV1State = state
        _G.BloxFish_BlatantActive = state
        pcall(function() RF_UpdateAutoFishingState:InvokeServer(state) end)
        
        if state then
            blatantFishv1LoopThread = task.spawn(function()
                while blatantV1State do
                    blatantFishv1()
                    task.wait(cycleDelay)
                end
            end)
        else
            if blatantFishv1LoopThread then task.cancel(blatantFishv1LoopThread) blatantFishv1LoopThread = nil end
        end
    end
})

-- Blatant V2 Section
local BlatantV2 = Tabs:AddSection("BlatantV2 Fishing", false)

BlatantV2:AddInput({
    Title = "Bait Delay",
    Default = "0.36",
    Callback = function(s)
        cycleDelay = tonumber(s) or 0.36
    end
})

BlatantV2:AddInput({
    Title = "Complete Delay",
    Default = "0.97",
    Callback = function(s)
        minigameDelay = tonumber(s) or 0.97
    end
})

BlatantV2:AddToggle({
    Title = "BlatantV2 Fish",
    Default = false,
    Callback = function(state)
        blatantV2State = state
        _G.BloxFish_BlatantActive = state
        pcall(function() RF_UpdateAutoFishingState:InvokeServer(state) end)
        
        if state then
            blatantFishv2LoopThread = task.spawn(function()
                while blatantV2State do
                    blatantFishv2()
                    task.wait(cycleDelay + minigameDelay)
                end
            end)
        else
            if blatantFishv2LoopThread then task.cancel(blatantFishv2LoopThread) blatantFishv2LoopThread = nil end
        end
    end
})

-- ==================== AUTO FAVORITE/UNFAVORITE ====================
local autoFavoriteState = false
local autoFavoriteThread = nil
local autoUnfavoriteState = false
local autoUnfavoriteThread = nil
local selectedRarities = {}
local selectedItemNames = {}
local selectedMutations = {}

local RE_FavoriteItem = GetRemote("RE/FavoriteItem")

local function getAutoFavoriteItemOptions()
    local itemNames = {}
    local itemsContainer = RepStorage:FindFirstChild("Items")
    if not itemsContainer then return {"(Items not found)"} end

    for _, itemObject in ipairs(itemsContainer:GetChildren()) do
        local itemName = itemObject.Name
        if type(itemName) == "string" and #itemName >= 3 then
            local prefix = itemName:sub(1, 3)
            if prefix ~= "!!!" then
                table.insert(itemNames, itemName)
            end
        end
    end
    table.sort(itemNames)
    if #itemNames == 0 then return {"(Empty)"} end
    return itemNames
end

local allItemNames = getAutoFavoriteItemOptions()

local function GetItemsToFavorite()
    local replion = GetPlayerDataReplion()
    if not replion or not ItemUtility or not TierUtility then return {} end

    local success, inventoryData = pcall(function() return replion:GetExpect("Inventory") end)
    if not success or not inventoryData or not inventoryData.Items then return {} end

    local itemsToFavorite = {}
    local isRarityFilterActive = #selectedRarities > 0
    local isNameFilterActive = #selectedItemNames > 0
    local isMutationFilterActive = #selectedMutations > 0

    if not (isRarityFilterActive or isNameFilterActive or isMutationFilterActive) then
        return {}
    end

    for _, item in ipairs(inventoryData.Items) do
        if item.IsFavorite or item.Favorited then continue end
        
        local itemUUID = item.UUID
        if typeof(itemUUID) ~= "string" or itemUUID:len() < 10 then continue end
        
        local name, rarity = GetFishNameAndRarity(item)
        local mutationFilterString = GetItemMutationString(item)
        
        local isMatch = false

        if isRarityFilterActive and table.find(selectedRarities, rarity) then
            isMatch = true
        end

        if not isMatch and isNameFilterActive and table.find(selectedItemNames, name) then
            isMatch = true
        end

        if not isMatch and isMutationFilterActive and table.find(selectedMutations, mutationFilterString) then
            isMatch = true
        end

        if isMatch then
            table.insert(itemsToFavorite, itemUUID)
        end
    end

    return itemsToFavorite
end

local function GetItemsToUnfavorite()
    local replion = GetPlayerDataReplion()
    if not replion or not ItemUtility or not TierUtility then return {} end

    local success, inventoryData = pcall(function() return replion:GetExpect("Inventory") end)
    if not success or not inventoryData or not inventoryData.Items then return {} end

    local itemsToUnfavorite = {}
    
    for _, item in ipairs(inventoryData.Items) do
        if not (item.IsFavorite or item.Favorited) then continue end
        local itemUUID = item.UUID
        if typeof(itemUUID) ~= "string" or itemUUID:len() < 10 then continue end
        
        local name, rarity = GetFishNameAndRarity(item)
        local mutationFilterString = GetItemMutationString(item)
        
        local passesRarity = #selectedRarities > 0 and table.find(selectedRarities, rarity)
        local passesName = #selectedItemNames > 0 and table.find(selectedItemNames, name)
        local passesMutation = #selectedMutations > 0 and table.find(selectedMutations, mutationFilterString)
        
        local isTargetedForUnfavorite = passesRarity or passesName or passesMutation
        
        if isTargetedForUnfavorite then
            table.insert(itemsToUnfavorite, itemUUID)
        end
    end

    return itemsToUnfavorite
end

local function SetItemFavoriteState(itemUUID, isFavorite)
    if not RE_FavoriteItem then return false end
    pcall(function() RE_FavoriteItem:FireServer(itemUUID) end)
    return true
end

local function RunAutoFavoriteLoop()
    if autoFavoriteThread then task.cancel(autoFavoriteThread) end
    
    autoFavoriteThread = task.spawn(function()
        local waitTime = 1
        local actionDelay = 0.5
        
        while autoFavoriteState do
            local itemsToFavorite = GetItemsToFavorite()
            
            if #itemsToFavorite > 0 then
                zerox(string.format("Mem-favorite %d item...", #itemsToFavorite), 1, Color3.fromRGB(255, 215, 0), "ZeroX", "Auto Favorite")
                for _, itemUUID in ipairs(itemsToFavorite) do
                    SetItemFavoriteState(itemUUID, true)
                    task.wait(actionDelay)
                end
            end
            
            task.wait(waitTime)
        end
    end)
end

local function RunAutoUnfavoriteLoop()
    if autoUnfavoriteThread then task.cancel(autoUnfavoriteThread) end
    
    autoUnfavoriteThread = task.spawn(function()
        local waitTime = 1
        local actionDelay = 0.5
        
        while autoUnfavoriteState do
            local itemsToUnfavorite = GetItemsToUnfavorite()
            
            if #itemsToUnfavorite > 0 then
                zerox(string.format("Menghapus favorite dari %d item...", #itemsToUnfavorite), 1, Color3.fromRGB(255, 100, 100), "ZeroX", "Auto Unfavorite")
                for _, itemUUID in ipairs(itemsToUnfavorite) do
                    SetItemFavoriteState(itemUUID, false)
                    task.wait(actionDelay)
                end
            end
            
            task.wait(waitTime)
        end
    end)
end

-- Auto Favorite Section
local FavSection = Tabs:AddSection("Auto Favorite/Unfavorite", false)

FavSection:AddDropdown({
    Title = "by Rarity",
    Options = {"Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic", "SECRET"},
    Multi = true,
    Default = {},
    Callback = function(values)
        selectedRarities = values or {}
    end
})

FavSection:AddDropdown({
    Title = "by Item Name",
    Options = allItemNames,
    Multi = true,
    Default = {},
    Callback = function(values)
        selectedItemNames = values or {}
    end
})

FavSection:AddDropdown({
    Title = "by Mutation",
    Options = {"Shiny", "Gemstone", "Corrupt", "Galaxy", "Holographic", "Ghost", "Lightning", "Fairy Dust", "Gold", "Midnight", "Radioactive", "Stone", "Albino", "Sandy", "Acidic", "Disco", "Frozen", "Noob"},
    Multi = true,
    Default = {},
    Callback = function(values)
        selectedMutations = values or {}
    end
})

FavSection:AddToggle({
    Title = "Enable Auto Favorite",
    Default = false,
    Callback = function(state)
        autoFavoriteState = state
        if state then
            if not GetPlayerDataReplion() or not ItemUtility or not TierUtility then
                return false
            end
            RunAutoFavoriteLoop()
        else
            if autoFavoriteThread then
                task.cancel(autoFavoriteThread)
                autoFavoriteThread = nil
            end
        end
    end
})

FavSection:AddToggle({
    Title = "Enable Auto Unfavorite",
    Default = false,
    Callback = function(state)
        autoUnfavoriteState = state
        if state then
            if #selectedRarities == 0 and #selectedItemNames == 0 and #selectedMutations == 0 then
                return false
            end
            RunAutoUnfavoriteLoop()
        else
            if autoUnfavoriteThread then task.cancel(autoUnfavoriteThread) autoUnfavoriteThread = nil end
        end
    end
})

-- ==================== AUTO SELL ====================
local function GetFishCount()
    local replion = GetPlayerDataReplion()
    if not replion then return 0 end

    local totalFishCount = 0
    local success, inventoryData = pcall(function() return replion:GetExpect("Inventory") end)
    
    if not success or not inventoryData or not inventoryData.Items or typeof(inventoryData.Items) ~= "table" then
        return 0
    end

    for _, item in ipairs(inventoryData.Items) do
        local isSellableFish = false

        if item.Type == "Fishing Rods" or item.Type == "Boats" or item.Type == "Bait" or item.Type == "Pets" or item.Type == "Chests" or item.Type == "Crates" or item.Type == "Totems" then
            continue
        end
        if item.Identifier and (item.Identifier:match("Artifact") or item.Identifier:match("Key") or item.Identifier:match("Token") or item.Identifier:match("Booster") or item.Identifier:match("hourglass")) then
            continue
        end
        
        if item.Metadata and item.Metadata.Weight then
            isSellableFish = true
        elseif item.Type == "Fish" or (item.Identifier and item.Identifier:match("fish")) then
            isSellableFish = true
        end

        if isSellableFish then
            totalFishCount = totalFishCount + (item.Count or 1)
        end
    end
    
    return totalFishCount
end

local autoSellMethod = "Delay"
local autoSellValue = 50
local autoSellState = false
local autoSellThread = nil

local function RunAutoSellLoop()
    if autoSellThread then task.cancel(autoSellThread) end
    
    autoSellThread = task.spawn(function()
        while autoSellState do
            if autoSellMethod == "Delay" then
                if RF_SellAllItems then
                    pcall(function() RF_SellAllItems:InvokeServer() end)
                end
                task.wait(math.max(autoSellValue, 1))
            elseif autoSellMethod == "Count" then
                local currentCount = GetFishCount()
                if currentCount >= autoSellValue then
                    if RF_SellAllItems then
                        pcall(function() RF_SellAllItems:InvokeServer() end)
                        zerox("Menjual " .. currentCount .. " items.", 2, Color3.fromRGB(0, 255, 0), "ZeroX", "Auto Sell")
                        task.wait(2)
                    end
                end
                task.wait(1)
            end
        end
    end)
end

local SellSection = Tabs:AddSection("Autosell Fish", false)

SellSection:AddDropdown({
    Title = "Select Method",
    Options = {"Delay", "Count"},
    Default = "Delay",
    Callback = function(val)
        autoSellMethod = val
        if autoSellState then
            RunAutoSellLoop()
        end
    end
})

SellSection:AddInput({
    Title = "Sell Value",
    Default = "50",
    Callback = function(text)
        local num = tonumber(text)
        if num then autoSellValue = num end
    end
})

local fishCountParagraph = SellSection:AddParagraph({
    Title = "Current Fish Count: 0",
    Content = ""
})

task.spawn(function()
    while true do
        if fishCountParagraph and GetPlayerDataReplion() then
            local count = GetFishCount()
            pcall(function() fishCountParagraph:SetTitle("Current Fish Count: " .. tostring(count)) end)
        end
        task.wait(1)
    end
end)

SellSection:AddToggle({
    Title = "Enable Auto Sell",
    Default = false,
    Callback = function(state)
        autoSellState = state
        if state then
            if not RF_SellAllItems then
                zerox("Remote Sell tidak ditemukan.", 3, Color3.fromRGB(255, 0, 0), "ZeroX", "Error")
                return false
            end
            RunAutoSellLoop()
        else
            if autoSellThread then task.cancel(autoSellThread) autoSellThread = nil end
        end
    end
})

-- ==================== PLAYER TAB ====================
local PlayerTab = Window:AddTab({ Name = "Player", Icon = "player" })

local InfinityJumpConnection = nil
local DEFAULT_SPEED = 18
local DEFAULT_JUMP = 50
local currentSpeed = DEFAULT_SPEED
local currentJump = DEFAULT_JUMP

local MovementSection = PlayerTab:AddSection("Movement", false)

MovementSection:AddSlider({
    Title = "WalkSpeed",
    Min = 16,
    Max = 200,
    Default = currentSpeed,
    Increment = 1,
    Callback = function(value)
        local speedValue = tonumber(value)
        if speedValue and speedValue >= 0 then
            local Humanoid = GetHumanoid()
            if Humanoid then
                Humanoid.WalkSpeed = speedValue
            end
        end
    end
})

MovementSection:AddSlider({
    Title = "JumpPower",
    Min = 50,
    Max = 200,
    Default = currentJump,
    Increment = 1,
    Callback = function(value)
        local jumpValue = tonumber(value)
        if jumpValue and jumpValue >= 50 then
            local Humanoid = GetHumanoid()
            if Humanoid then
                Humanoid.JumpPower = jumpValue
            end
        end
    end
})

MovementSection:AddButton({
    Title = "Reset Movement",
    Callback = function()
        local Humanoid = GetHumanoid()
        if Humanoid then
            Humanoid.WalkSpeed = DEFAULT_SPEED
            Humanoid.JumpPower = DEFAULT_JUMP
        end
    end
})

MovementSection:AddToggle({
    Title = "Freeze Player",
    Default = false,
    Callback = function(state)
        local character = LocalPlayer.Character
        if not character then return end
        
        local hrp = character:FindFirstChild("HumanoidRootPart")
        if hrp then
            hrp.Anchored = state
            if state then
                hrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                hrp.Velocity = Vector3.new(0, 0, 0)
            end
        end
    end
})

-- Abilities Section
local AbilitySection = PlayerTab:AddSection("Abilities", false)

AbilitySection:AddToggle({
    Title = "Infinite Jump",
    Default = false,
    Callback = function(state)
        if state then
            InfinityJumpConnection = UserInputService.JumpRequest:Connect(function()
                local Humanoid = GetHumanoid()
                if Humanoid and Humanoid.Health > 0 then
                    Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
                end
            end)
        else
            if InfinityJumpConnection then
                InfinityJumpConnection:Disconnect()
                InfinityJumpConnection = nil
            end
        end
    end
})

local noclipConnection = nil
local isNoClipActive = false

AbilitySection:AddToggle({
    Title = "No Clip",
    Default = false,
    Callback = function(state)
        isNoClipActive = state
        if state then
            noclipConnection = game:GetService("RunService").Stepped:Connect(function()
                local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
                if isNoClipActive and character then
                    for _, part in ipairs(character:GetDescendants()) do
                        if part:IsA("BasePart") and part.CanCollide then
                            part.CanCollide = false
                        end
                    end
                end
            end)
        else
            if noclipConnection then noclipConnection:Disconnect() noclipConnection = nil end
            local character = LocalPlayer.Character
            if character then
                for _, part in ipairs(character:GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.CanCollide = true
                    end
                end
            end
        end
    end
})

local flyConnection = nil
local isFlying = false
local flySpeed = 60
local bodyGyro, bodyVel

AbilitySection:AddToggle({
    Title = "Fly Mode",
    Default = false,
    Callback = function(state)
        local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
        local humanoidRootPart = character:WaitForChild("HumanoidRootPart")
        local humanoid = character:WaitForChild("Humanoid")

        if state then
            isFlying = true

            bodyGyro = Instance.new("BodyGyro")
            bodyGyro.P = 9e4
            bodyGyro.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
            bodyGyro.CFrame = humanoidRootPart.CFrame
            bodyGyro.Parent = humanoidRootPart

            bodyVel = Instance.new("BodyVelocity")
            bodyVel.Velocity = Vector3.zero
            bodyVel.MaxForce = Vector3.new(9e9, 9e9, 9e9)
            bodyVel.Parent = humanoidRootPart

            local cam = workspace.CurrentCamera
            local moveDir = Vector3.zero
            local jumpPressed = false

            UserInputService.JumpRequest:Connect(function()
                if isFlying then jumpPressed = true task.delay(0.2, function() jumpPressed = false end) end
            end)

            flyConnection = game:GetService("RunService").RenderStepped:Connect(function()
                if not isFlying or not humanoidRootPart or not bodyGyro or not bodyVel then return end
                
                bodyGyro.CFrame = cam.CFrame
                moveDir = humanoid.MoveDirection

                if jumpPressed then
                    moveDir = moveDir + Vector3.new(0, 1, 0)
                elseif UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
                    moveDir = moveDir - Vector3.new(0, 1, 0)
                end

                if moveDir.Magnitude > 0 then moveDir = moveDir.Unit * flySpeed end

                bodyVel.Velocity = moveDir
            end)
        else
            isFlying = false
            if flyConnection then flyConnection:Disconnect() flyConnection = nil end
            if bodyGyro then bodyGyro:Destroy() bodyGyro = nil end
            if bodyVel then bodyVel:Destroy() bodyVel = nil end
        end
    end
})

-- Other Section
local OtherSection = PlayerTab:AddSection("Other", false)

local customName = "ZeroXUser"
local customLevel = "Lvl. 01"
local isHideActive = false
local hideConnection = nil

OtherSection:AddInput({
    Title = "Custom Fake Name",
    Default = customName,
    Callback = function(text)
        customName = text
    end
})

OtherSection:AddInput({
    Title = "Custom Fake Level",
    Default = customLevel,
    Callback = function(text)
        customLevel = text
    end
})

OtherSection:AddToggle({
    Title = "Hide All Usernames",
    Default = false,
    Callback = function(state)
        isHideActive = state
        
        pcall(function()
            game:GetService("StarterGui"):SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, not state)
        end)

        if state then
            if hideConnection then hideConnection:Disconnect() end
            hideConnection = game:GetService("RunService").RenderStepped:Connect(function()
                for _, plr in ipairs(game.Players:GetPlayers()) do
                    if plr.Character then
                        local hum = plr.Character:FindFirstChild("Humanoid")
                        if hum then
                            hum.DisplayName = customName
                        end
                    end
                end
            end)
        else
            if hideConnection then
                hideConnection:Disconnect()
                hideConnection = nil
            end
            for _, plr in ipairs(game.Players:GetPlayers()) do
                if plr.Character then
                    local hum = plr.Character:FindFirstChild("Humanoid")
                    if hum then hum.DisplayName = plr.DisplayName end
                end
            end
        end
    end
})

OtherSection:AddButton({
    Title = "Reset Character (In Place)",
    Callback = function()
        local character = LocalPlayer.Character
        local hrp = character and character:FindFirstChild("HumanoidRootPart")
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")

        if not character or not hrp or not humanoid then
            zerox("Karakter tidak ditemukan!", 3, Color3.fromRGB(255, 0, 0), "ZeroX", "Error")
            return
        end

        local lastPos = hrp.Position
        zerox("Respawning...", 2, Color3.fromRGB(255, 255, 0), "ZeroX", "Reset")
        humanoid:TakeDamage(999999)

        LocalPlayer.CharacterAdded:Wait()
        task.wait(0.5)
        local newChar = LocalPlayer.Character
        local newHRP = newChar:WaitForChild("HumanoidRootPart", 5)

        if newHRP then
            newHRP.CFrame = CFrame.new(lastPos + Vector3.new(0, 3, 0))
            zerox("Respawn sukses!", 3, Color3.fromRGB(0, 255, 0), "ZeroX", "Success")
        end
    end
})

-- ==================== TELEPORT TAB ====================
local TeleportTab = Window:AddTab({ Name = "Teleport", Icon = "gps" })

local selectedTargetPlayer = nil
local selectedTargetArea = nil

local function GetPlayerListOptions()
    local options = {}
    for _, player in ipairs(game.Players:GetPlayers()) do
        if player ~= LocalPlayer then
            table.insert(options, player.Name)
        end
    end
    table.sort(options)
    return options
end

local function GetTargetHRP(playerName)
    local targetPlayer = game.Players:FindFirstChild(playerName)
    local character = targetPlayer and targetPlayer.Character
    if character then
        return character:FindFirstChild("HumanoidRootPart")
    end
    return nil
end

local TelePlayerSection = TeleportTab:AddSection("Teleport to Player", false)

TelePlayerSection:AddDropdown({
    Title = "Select Target Player",
    Options = GetPlayerListOptions(),
    Callback = function(name)
        selectedTargetPlayer = name
    end
})

TelePlayerSection:AddButton({
    Title = "Refresh Player List",
    Callback = function()
        zerox("Player list refreshed", 2, Color3.fromRGB(0, 255, 0), "ZeroX", "Info")
    end
})

TelePlayerSection:AddButton({
    Title = "Teleport to Player",
    Callback = function()
        local hrp = GetHRP()
        local targetHRP = GetTargetHRP(selectedTargetPlayer)
        
        if not selectedTargetPlayer then
            zerox("Pilih pemain target!", 3, Color3.fromRGB(255, 0, 0), "ZeroX", "Error")
            return
        end

        if hrp and targetHRP then
            local targetPos = targetHRP.Position + Vector3.new(0, 5, 0)
            local lookVector = (targetHRP.Position - hrp.Position).Unit
            hrp.CFrame = CFrame.new(targetPos, targetPos + lookVector)
            zerox("Teleported ke " .. selectedTargetPlayer, 3, Color3.fromRGB(0, 255, 0), "ZeroX", "Success")
        else
            zerox("Target tidak ditemukan!", 3, Color3.fromRGB(255, 0, 0), "ZeroX", "Error")
        end
    end
})

local TeleAreaSection = TeleportTab:AddSection("Teleport to Area", false)

TeleAreaSection:AddDropdown({
    Title = "Select Target Area",
    Options = AreaNames,
    Callback = function(name)
        selectedTargetArea = name
    end
})

TeleAreaSection:AddButton({
    Title = "Teleport to Area",
    Callback = function()
        if not selectedTargetArea or not FishingAreas[selectedTargetArea] then
            zerox("Pilih area target!", 3, Color3.fromRGB(255, 0, 0), "ZeroX", "Error")
            return
        end
        
        local areaData = FishingAreas[selectedTargetArea]
        pos_saved = areaData.cframe
        look_saved = areaData.lookup
        TeleportToLookAt()
    end
})

-- ==================== SETTINGS TAB ====================
local SettingsTab = Window:AddTab({ Name = "Settings", Icon = "menu" })

local MiscSection = SettingsTab:AddSection("MISC", false)

MiscSection:AddToggle({
    Title = "FPS Ultra Boost",
    Default = false,
    Callback = function(state)
        local Lighting = game:GetService("Lighting")
        local Terrain = workspace:FindFirstChildOfClass("Terrain")
        
        if state then
            pcall(function()
                for _, v in pairs(workspace:GetDescendants()) do
                    if v:IsA("ParticleEmitter") or v:IsA("Trail") or v:IsA("Smoke") or v:IsA("Fire") then
                        v.Enabled = false
                    elseif v:IsA("Beam") or v:IsA("Light") then
                        v.Enabled = false
                    end
                end
            end)
            
            pcall(function()
                for _, effect in pairs(Lighting:GetChildren()) do
                    if effect:IsA("PostEffect") then effect.Enabled = false end
                end
                Lighting.GlobalShadows = false
                Lighting.FogEnd = 9e9
            end)
            
            if Terrain then
                pcall(function()
                    Terrain.WaterWaveSize = 0
                    Terrain.WaterWaveSpeed = 0
                    Terrain.WaterReflectance = 0
                end)
            end
            
            pcall(function()
                settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
            end)
            
            if type(setfpscap) == "function" then pcall(function() setfpscap(100) end) end
            if type(collectgarbage) == "function" then collectgarbage("collect") end
        else
            pcall(function()
                Lighting.GlobalShadows = true
                settings().Rendering.QualityLevel = Enum.QualityLevel.Automatic
                for _, effect in pairs(Lighting:GetChildren()) do
                    if effect:IsA("PostEffect") then effect.Enabled = true end
                end
            end)
            if type(setfpscap) == "function" then pcall(function() setfpscap(60) end) end
        end
    end
})

MiscSection:AddToggle({
    Title = "Disable 3D Rendering",
    Default = false,
    Callback = function(state)
        local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
        local Camera = workspace.CurrentCamera
        
        if state then
            if not _G.BlackScreenGUI then
                _G.BlackScreenGUI = Instance.new("ScreenGui")
                _G.BlackScreenGUI.Name = "ZeroX_BlackBackground"
                _G.BlackScreenGUI.IgnoreGuiInset = true
                _G.BlackScreenGUI.DisplayOrder = -999
                _G.BlackScreenGUI.Parent = PlayerGui
                
                local Frame = Instance.new("Frame")
                Frame.Size = UDim2.new(1, 0, 1, 0)
                Frame.BackgroundColor3 = Color3.new(0, 0, 0)
                Frame.BorderSizePixel = 0
                Frame.Parent = _G.BlackScreenGUI
                
                local Label = Instance.new("TextLabel")
                Label.Size = UDim2.new(1, 0, 0.1, 0)
                Label.Position = UDim2.new(0, 0, 0.1, 0)
                Label.BackgroundTransparency = 1
                Label.Text = "Saver Mode Active"
                Label.TextColor3 = Color3.fromRGB(60, 60, 60)
                Label.TextSize = 16
                Label.Font = Enum.Font.GothamBold
                Label.Parent = Frame
            end
            
            _G.BlackScreenGUI.Enabled = true
            _G.OldCamType = Camera.CameraType
            Camera.CameraType = Enum.CameraType.Scriptable
            Camera.CFrame = CFrame.new(0, 100000, 0)
        else
            if _G.OldCamType then
                Camera.CameraType = _G.OldCamType
            else
                Camera.CameraType = Enum.CameraType.Custom
            end
            
            if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
                Camera.CameraSubject = LocalPlayer.Character.Humanoid
            end

            if _G.BlackScreenGUI then
                _G.BlackScreenGUI.Enabled = false
            end
        end
    end
})

local UtilitySection = SettingsTab:AddSection("Utility", false)

local RF_UnequipOxygenTank = GetRemote("RF/UnequipOxygenTank")
local RF_EquipOxygenTank = GetRemote("RF/EquipOxygenTank")
local RF_UpdateFishingRadar = GetRemote("RF/UpdateFishingRadar")

UtilitySection:AddToggle({
    Title = "Bypass Radar",
    Default = false,
    Callback = function(state)
        if RF_UpdateFishingRadar then
            RF_UpdateFishingRadar:InvokeServer(state)
        end
    end
})

UtilitySection:AddToggle({
    Title = "Bypass Oksigen",
    Default = false,
    Callback = function(state)
        if state then
            if RF_EquipOxygenTank then RF_EquipOxygenTank:InvokeServer(105) end
        else
            if RF_UnequipOxygenTank then RF_UnequipOxygenTank:InvokeServer() end
        end
    end
})

local defaultMaxZoom = LocalPlayer.CameraMaxZoomDistance or 128
local zoomLoopConnection = nil

UtilitySection:AddToggle({
    Title = "Infinite Zoom Out",
    Default = false,
    Callback = function(state)
        if state then
            defaultMaxZoom = LocalPlayer.CameraMaxZoomDistance
            LocalPlayer.CameraMaxZoomDistance = 100000
            if zoomLoopConnection then zoomLoopConnection:Disconnect() end
            zoomLoopConnection = game:GetService("RunService").RenderStepped:Connect(function()
                LocalPlayer.CameraMaxZoomDistance = 100000
            end)
        else
            if zoomLoopConnection then
                zoomLoopConnection:Disconnect()
                zoomLoopConnection = nil
            end
            LocalPlayer.CameraMaxZoomDistance = defaultMaxZoom
        end
    end
})

-- Auto Reload on Respawn
LocalPlayer.CharacterAdded:Connect(function(char)
    OnCharacterAdded(char)
end)

zerox("ZeroX Fish It loaded successfully!", 5, Color3.fromRGB(138, 43, 226), "ZeroX", "Welcome")
