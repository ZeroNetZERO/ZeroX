local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()
local Window = WindUI:CreateWindow({
    Title = "RockHub - Fish It",
    Icon = "rbxassetid://116236936447443",
    Author = "Free Version",
    Folder = "RockHub",
    Size = UDim2.fromOffset(600, 360),
    MinSize = Vector2.new(560, 250),
    MaxSize = Vector2.new(950, 760),
    Transparent = true,
    Theme = "Rose",
    Resizable = true,
    SideBarWidth = 190,
    BackgroundImageTransparency = 0.42,
    HideSearchBar = true,
    ScrollBarEnabled = true,
})

local UserInputService = game:GetService("UserInputService")
local InfinityJumpConnection = nil
local LocalPlayer = game.Players.LocalPlayer
local RepStorage = game:GetService("ReplicatedStorage") 
local ItemUtility = require(RepStorage:WaitForChild("Shared"):WaitForChild("ItemUtility", 10))
local TierUtility = require(RepStorage:WaitForChild("Shared"):WaitForChild("TierUtility", 10))

local DEFAULT_SPEED = 18
local DEFAULT_JUMP = 50

local function GetHumanoid()
    local Character = LocalPlayer.Character
    if not Character then
        Character = LocalPlayer.CharacterAdded:Wait()
    end
    return Character:FindFirstChildOfClass("Humanoid")
end

local InitialHumanoid = GetHumanoid()
local currentSpeed = DEFAULT_SPEED
local currentJump = DEFAULT_JUMP

if InitialHumanoid then
    currentSpeed = InitialHumanoid.WalkSpeed
    currentJump = InitialHumanoid.JumpPower
end

local RPath = {"Packages", "_Index", "sleitnick_net@0.2.0", "net"}
local PlayerDataReplion = nil

local function GetRemote(remotePath, name, timeout)
    local currentInstance = RepStorage
    for _, childName in ipairs(remotePath) do
        currentInstance = currentInstance:WaitForChild(childName, timeout or 0.5)
        if not currentInstance then return nil end
    end
    return currentInstance:FindFirstChild(name)
end

local function GetHRP()
    local Character = game.Players.LocalPlayer.Character
    if not Character then
        Character = game.Players.LocalPlayer.CharacterAdded:Wait()
    end
    return Character:WaitForChild("HumanoidRootPart", 5)
end

pcall(function()
    local player = game:GetService("Players").LocalPlayer
    
    -- Cek semua koneksi yang terhubung ke event Idled pemain lokal
    for i, v in pairs(getconnections(player.Idled)) do
        if v.Disable then
            v:Disable() -- Menonaktifkan koneksi event
            print("[RockHub Anti-AFK] ON")
        end
    end
end)

local function TeleportToLookAt(position, lookVector)
    local hrp = GetHRP()
    
    if hrp and typeof(position) == "Vector3" and typeof(lookVector) == "Vector3" then
        local targetCFrame = CFrame.new(position, position + lookVector)
        hrp.CFrame = targetCFrame * CFrame.new(0, 0.5, 0)
        
        WindUI:Notify({ Title = "Teleport Sukses!", Duration = 3, Icon = "map-pin", })
    else
        WindUI:Notify({ Title = "Teleport Gagal", Content = "Data posisi tidak valid.", Duration = 3, Icon = "x", })
    end
end

local function GetPlayerDataReplion()
    if PlayerDataReplion then return PlayerDataReplion end
    local ReplionModule = RepStorage:WaitForChild("Packages"):WaitForChild("Replion", 10)
    if not ReplionModule then return nil end
    local ReplionClient = require(ReplionModule).Client
    PlayerDataReplion = ReplionClient:WaitReplion("Data", 5)
    return PlayerDataReplion
end

local RF_SellAllItems = GetRemote(RPath, "RF/SellAllItems", 5)

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

local ShopItems = {
    ["Rods"] = {
        {Name = "Luck Rod", ID = 79, Price = 325}, {Name = "Carbon Rod", ID = 76, Price = 750},
        {Name = "Grass Rod", ID = 85, Price = 1500}, {Name = "Demascus Rod", ID = 77, Price = 3000},
        {Name = "Ice Rod", ID = 78, Price = 5000}, {Name = "Lucky Rod", ID = 4, Price = 15000},
        {Name = "Midnight Rod", ID = 80, Price = 50000}, {Name = "Steampunk Rod", ID = 6, Price = 215000},
        {Name = "Chrome Rod", ID = 7, Price = 437000}, {Name = "Flourescent Rod", ID = 255, Price = 715000},
        {Name = "Astral Rod", ID = 5, Price = 1000000}, {Name = "Ares Rod", ID = 126, Price = 3000000},
        {Name = "Angler Rod", ID = 168, Price = 8000000},
    },
    ["Bobbers"] = {
        {Name = "Floral Bait", ID = 20, Price = 4000000}, {Name = "Aether Bait", ID = 16, Price = 3700000},
        {Name = "Corrupt Bait", ID = 15, Price = 1148484}, {Name = "Dark Matter Bait", ID = 8, Price = 630000},
        {Name = "Chroma Bait", ID = 6, Price = 290000}, {Name = "Nature Bait", ID = 17, Price = 83500},
        {Name = "Midnight Bait", ID = 3, Price = 3000}, {Name = "Luck Bait", ID = 2, Price = 1000},
        {Name = "Topwater Bait", ID = 10, Price = 100},
    },
    ["Boats"] = {
        {Name = "Mini Yach", ID = 14, Price = 1200000}, {Name = "Fish Boat", ID = 6, Price = 180000},
        {Name = "Speed Boat", ID = 5, Price = 70000}, {Name = "Highfield Boat", ID = 4, Price = 25000},
        {Name = "Jetski", ID = 3, Price = 7500}, {Name = "Kayak", ID = 2, Price = 1100},
        {Name = "Small Boat", ID = 1, Price = 100},
    },
}

do
    local PromptController = nil
    local Promise = nil
    
    pcall(function()
        PromptController = require(RepStorage:WaitForChild("Controllers").PromptController)
        Promise = require(RepStorage:WaitForChild("Packages").Promise)
    end)
    
    _G.RockHub_AutoAcceptTradeEnabled = false 

    if PromptController and PromptController.FirePrompt and Promise then
        local oldFirePrompt = PromptController.FirePrompt
        PromptController.FirePrompt = function(self, promptText, ...)
            
            if _G.RockHub_AutoAcceptTradeEnabled and type(promptText) == "string" and promptText:find("Accept") and promptText:find("from:") then
                
                local initiatorName = string.match(promptText, "from: ([^\n]+)") or "Seseorang"
                
                
                return Promise.new(function(resolve)
                    task.wait(2)
                    resolve(true)
                end)
            end
            
            return oldFirePrompt(self, promptText, ...)
        end
    else
        warn("[RockHub] Gagal memuat PromptController/Promise untuk Auto Accept Trade.")
    end
end

local ENCHANT_MAPPING = {
    ["Cursed I"] = 12,
    ["Big Hunter I"] = 3,
    ["Empowered I"] = 9,
    ["Glistening I"] = 1,
    ["Gold Digger I"] = 4,
    ["Leprechaun I"] = 5,
    ["Leprechaun II"] = 6,
    ["Mutation Hunter I"] = 7,
    ["Mutation Hunter II"] = 14,
    ["Perfection"] = 15,
    ["Prismatic I"] = 13,
    ["Reeler I"] = 2,
    ["Stargazer I"] = 8,
    ["Stormhunter I"] = 11,
    ["Experienced I"] = 10,
}
local ENCHANT_NAMES = {} 
for name, id in pairs(ENCHANT_MAPPING) do table.insert(ENCHANT_NAMES, name) end

local autoEnchantState = false
local autoEnchantThread = nil
local selectedRodUUID = nil
local selectedEnchantNames = {}

local ENCHANT_STONE_ID = 10
_G.RockHub_EnchantStoneUUIDs = {}

local function GetEnchantNameFromId(id)
    id = tonumber(id)
    if not id then return nil end
    for name, eid in pairs(ENCHANT_MAPPING) do
        if eid == id then
            return name
        end
    end
    return nil
end

local function GetRodOptions()
    local rodOptions = {}
    local replion = GetPlayerDataReplion()
    if not replion then return {"(Gagal memuat Inventory)"} end

    local success, inventoryData = pcall(function() return replion:GetExpect("Inventory") end)
    if not success or not inventoryData or not inventoryData["Fishing Rods"] then
        return {"(Tidak ada Rod ditemukan)"}
    end

    local Rods = inventoryData["Fishing Rods"]
    for _, rod in ipairs(Rods) do
        local rodUUID = rod.UUID
        
        if typeof(rodUUID) ~= "string" or string.len(rodUUID) < 10 then
            continue
        end
        
        local rodName, _ = GetFishNameAndRarity(rod)
        
        if not string.find(rodName, "Rod", 1, true) then
            continue
        end

        local enchantStatus = ""
        local metadata = rod.Metadata or {}
        local enchants = {}

        if metadata.EnchantId then table.insert(enchants, metadata.EnchantId) end
        --if metadata.EnchantId2 then table.insert(enchants, metadata.EnchantId2) end

        local resolvedEnchantNames = {}
        for _, eid in ipairs(enchants) do
            local name = GetEnchantNameFromId(eid) or "ID:" .. eid
            table.insert(resolvedEnchantNames, name)
        end
        
        if #resolvedEnchantNames > 0 then
            enchantStatus = " [" .. table.concat(resolvedEnchantNames, ", ") .. "]"
        end

        local shortUUID = string.sub(rodUUID, 1, 8) .. "..."
        table.insert(rodOptions, rodName .. " (" .. shortUUID .. ")" .. enchantStatus)
    end
    
    return rodOptions
end


local function GetUUIDFromFormattedName(formattedName)
    local uuidMatch = formattedName:match("%(([^%)]+)%.%.%.%)")
    if not uuidMatch then return nil end

    local replion = GetPlayerDataReplion()
    local Rods = replion:GetExpect("Inventory")["Fishing Rods"] or {}

    for _, rod in ipairs(Rods) do
        if string.sub(rod.UUID, 1, 8) == uuidMatch then
            return rod.UUID
        end
    end
    return nil
end

local function CheckIfEnchantReached(rodUUID)
    local replion = GetPlayerDataReplion()
    local Rods = replion:GetExpect("Inventory")["Fishing Rods"] or {}
    
    local targetRod = nil
    for _, rod in ipairs(Rods) do
        if rod.UUID == rodUUID then
            targetRod = rod
            break
        end
    end

    if not targetRod then return true end
    
    local metadata = targetRod.Metadata or {}
    local currentEnchants = {}
    if metadata.EnchantId then table.insert(currentEnchants, metadata.EnchantId) end
    --if metadata.EnchantId2 then table.insert(currentEnchants, metadata.EnchantId2) end

    for _, targetName in ipairs(selectedEnchantNames) do
        local targetID = ENCHANT_MAPPING[targetName]
        if targetID and table.find(currentEnchants, targetID) then
            return true
        end
    end

    return false
end

local function GetFirstStoneUUID()
    local replion = GetPlayerDataReplion()
    if not replion then return nil end

    local success, inventoryData = pcall(function() return replion:GetExpect("Inventory") end)
    if not success or not inventoryData or not inventoryData.Items then
        return nil
    end

    local GeneralItems = inventoryData.Items or {}
    for _, item in ipairs(GeneralItems) do
        if tonumber(item.Id) == ENCHANT_STONE_ID and item.UUID and item.Type ~= "Fishing Rods" and item.Type ~= "Bait" then
            return item.UUID
        end
    end
    return nil
end

local function UnequipAllEquippedItems()
    local RE_UnequipItem = GetRemote(RPath, "RE/UnequipItem")
    if not RE_UnequipItem then 
        warn("[Auto Enchant] Gagal menemukan RE/UnequipItem remote.")
        return 
    end

    local replion = GetPlayerDataReplion()
    local EquippedItems = replion:GetExpect("EquippedItems") or {}
    local EquippedSkinUUID = replion:Get("EquippedSkinUUID")

    if EquippedSkinUUID and EquippedSkinUUID ~= "" then
         -- Unequip Rod Skin
         pcall(function() RE_UnequipItem:FireServer(EquippedSkinUUID) end)
         task.wait(0.1)
    end

    for _, uuid in ipairs(EquippedItems) do
        pcall(function() RE_UnequipItem:FireServer(uuid) end)
        task.wait(0.05)
    end
end


local function RunAutoEnchantLoop(rodUUID)
    if autoEnchantThread then task.cancel(autoEnchantThread) end
    
    local ENCHANT_ALTAR_POS = Vector3.new(3236.441, -1302.855, 1397.910)
    local ENCHANT_ALTAR_LOOK = Vector3.new(-0.954, -0.000, 0.299)
    
    local RE_UnequipItem = GetRemote(RPath, "RE/UnequipItem")
    local RE_EquipItem = GetRemote(RPath, "RE/EquipItem")
    local RE_EquipToolFromHotbar = GetRemote(RPath, "RE/EquipToolFromHotbar")
    local RE_ActivateEnchantingAltar = GetRemote(RPath, "RE/ActivateEnchantingAltar")

    if not (RE_UnequipItem and RE_EquipItem and RE_EquipToolFromHotbar and RE_ActivateEnchantingAltar) then
        WindUI:Notify({ Title = "Error Remote", Content = "Remote Enchanting tidak ditemukan.", Duration = 4, Icon = "x" })
        autoEnchantState = false
        return
    end

    autoEnchantThread = task.spawn(function()
        
        UnequipAllEquippedItems()

        task.wait(2.5) 

        TeleportToLookAt(ENCHANT_ALTAR_POS, ENCHANT_ALTAR_LOOK)
        task.wait(1.5)

        WindUI:Notify({ Title = "Auto Enchant Started", Content = "Memulai Roll Enchant...", Duration = 2, Icon = "zap" })

        while autoEnchantState do
            
            if CheckIfEnchantReached(rodUUID) then
                WindUI:Notify({ Title = "Enchant Selesai!", Content = "Rod mencapai salah satu target enchant.", Duration = 5, Icon = "check" })
                break
            end
            
            local enchantStoneUUID = GetFirstStoneUUID() 
            if not enchantStoneUUID then
                WindUI:Notify({ Title = "Stone Habis!", Content = "Tidak ada Enchant Stone yang tersisa di inventaris.", Duration = 5, Icon = "stop-circle" })
                break
            end

            pcall(function() RE_EquipItem:FireServer(rodUUID, "Fishing Rods") end)
            task.wait(0.2)

            pcall(function() RE_EquipItem:FireServer(enchantStoneUUID, "Enchant Stones") end)
            task.wait(0.2)
            
            pcall(function() RE_EquipToolFromHotbar:FireServer(2) end)
            task.wait(0.3)

            pcall(function() RE_ActivateEnchantingAltar:FireServer() end)
            
            task.wait(tradeDelay) 

            pcall(function() RE_EquipToolFromHotbar:FireServer(0) end) 
            
            task.wait(0.5)
        end

        autoEnchantState = false
        local toggle = Window:GetElementByTitle("Enable Auto Enchant") 
        if toggle and toggle.Set then toggle:Set(false) end
        
        WindUI:Notify({ Title = "Auto Enchant Berhenti", Duration = 3, Icon = "x" })
    end)
end

local eventsList = { 
    "Shark Hunt", "Ghost Shark Hunt", "Worm Hunt", "Black Hole", "Shocked", 
    "Ghost Worm", "Meteor Rain", "Megalodon Hunt", "Treasure Event"
}

local autoEventTargetName = nil 
local autoEventTeleportState = false
local autoEventTeleportThread = nil


local function FindAndTeleportToTargetEvent()
    local targetName = autoEventTargetName
    if not targetName or targetName == "" then return false end
    
    local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end
    
    local eventModel = nil
    
    if targetName == "Treasure Event" then
        local sunkenFolder = workspace:FindFirstChild("Sunken Wreckage")
        if sunkenFolder then
            eventModel = sunkenFolder:FindFirstChild("Treasure")
        end
    
    elseif targetName == "Worm Hunt" then
        local menuRingsFolder = workspace:FindFirstChild("!!! MENU RINGS")
        if menuRingsFolder then
            for _, child in ipairs(menuRingsFolder:GetChildren()) do
                if child.Name == "Props" then
                    local specificModel = child:FindFirstChild("Model")
                    if specificModel then
                        eventModel = specificModel
                        break
                    end
                end
            end
        end

    else
        local menuRingsFolder = workspace:FindFirstChild("!!! MENU RINGS") 
        if menuRingsFolder then
            for _, container in ipairs(menuRingsFolder:GetChildren()) do
                if container:FindFirstChild(targetName) then
                    eventModel = container:FindFirstChild(targetName)
                    break
                end
            end
        end
    end
    
    if not eventModel then return false end 

    local targetPart = nil
    local positionOffset = Vector3.new(0, 15, 0) 
    
    if targetName == "Megalodon Hunt" then
        targetPart = eventModel:FindFirstChild("Top") 
        if targetPart then positionOffset = Vector3.new(0, 3, 0) end
    elseif targetName == "Treasure Event" then
        targetPart = eventModel
        positionOffset = Vector3.new(0, 5, 0)
    else
        targetPart = eventModel:FindFirstChild("Fishing Boat")
        if not targetPart then targetPart = eventModel end
        positionOffset = Vector3.new(0, 15, 0)
    end

    if not targetPart then return false end

    local targetCFrame = nil
    
    local success = pcall(function()
        if targetPart:IsA("Model") then
             targetCFrame = targetPart:GetPivot()
        elseif targetPart:IsA("BasePart") then
             targetCFrame = targetPart.CFrame
        end
    end)

    if success and targetCFrame and typeof(targetCFrame) == "CFrame" then
        local position = targetCFrame.p + positionOffset
        local lookVector = targetCFrame.LookVector
        
        TeleportToLookAt(position, lookVector)
        
        WindUI:Notify({
            Title = "Event Found!",
            Content = "Teleported to: " .. targetName,
            Icon = "map-pin",
            Duration = 3
        })
        return true
    end
    
    return false
end

local function RunAutoEventTeleportLoop()
    if autoEventTeleportThread then task.cancel(autoEventTeleportThread) end

    autoEventTeleportThread = task.spawn(function()
        WindUI:Notify({ Title = "Auto Event TP ON", Content = "Mulai memindai event terpilih.", Duration = 3, Icon = "search" })
        
        while autoEventTeleportState do
            
            if FindAndTeleportToTargetEvent() then
                
                task.wait(900) 
            else
                
                task.wait(10)
            end
        end
        
        WindUI:Notify({ Title = "Auto Event TP OFF", Duration = 3, Icon = "x" })
    end)
end

local function CensorName(name)
    if not name or type(name) ~= "string" or #name < 1 then
        return "N/A" 
    end
    
    if #name <= 3 then
        return name
    end

    local prefix = name:sub(1, 3)
    
    local censureLength = #name - 3
    
    local censorString = string.rep("*", censureLength)
    
    return prefix .. censorString
end

local FishingAreas = {
        ["Iron Cavern"] = {Pos = Vector3.new(-8792.546, -588.000, 230.642), Look = Vector3.new(0.718, 0.000, 0.696)},
        ["Disco Event"] = {Pos = Vector3.new(-8641.672, -547.500, 160.322), Look = Vector3.new(0.984, -0.000, 0.176)},
        ["Classic Island"] = {Pos = Vector3.new(1440.843, 46.062, 2777.175), Look = Vector3.new(0.940, -0.000, 0.342)},
        ["Ancient Jungle"] = {Pos = Vector3.new(1535.639, 3.159, -193.352), Look = Vector3.new(0.505, -0.000, 0.863)},
        ["Arrow Lever"] = {Pos = Vector3.new(898.296, 8.449, -361.856), Look = Vector3.new(0.023, -0.000, 1.000)},
        ["Coral Reef"] = {Pos = Vector3.new(-3207.538, 6.087, 2011.079), Look = Vector3.new(0.973, 0.000, 0.229)},
        ["Crater Island"] = {Pos = Vector3.new(1058.976, 2.330, 5032.878), Look = Vector3.new(-0.789, 0.000, 0.615)},
        ["Cresent Lever"] = {Pos = Vector3.new(1419.750, 31.199, 78.570), Look = Vector3.new(0.000, -0.000, -1.000)},
        ["Crystalline Passage"] = {Pos = Vector3.new(6051.567, -538.900, 4370.979), Look = Vector3.new(0.109, 0.000, 0.994)},
        ["Ancient Ruin"] = {Pos = Vector3.new(6031.981, -585.924, 4713.157), Look = Vector3.new(0.316, -0.000, -0.949)},
        ["Diamond Lever"] = {Pos = Vector3.new(1818.930, 8.449, -284.110), Look = Vector3.new(0.000, 0.000, -1.000)},
        ["Enchant Room"] = {Pos = Vector3.new(3255.670, -1301.530, 1371.790), Look = Vector3.new(-0.000, -0.000, -1.000)},
        ["Esoteric Island"] = {Pos = Vector3.new(2164.470, 3.220, 1242.390), Look = Vector3.new(-0.000, -0.000, -1.000)},
        ["Fisherman Island"] = {Pos = Vector3.new(74.030, 9.530, 2705.230), Look = Vector3.new(-0.000, -0.000, -1.000)},
        ["Hourglass Diamond Lever"] = {Pos = Vector3.new(1484.610, 8.450, -861.010), Look = Vector3.new(-0.000, -0.000, -1.000)},
        ["Kohana"] = {Pos = Vector3.new(-668.732, 3.000, 681.580), Look = Vector3.new(0.889, -0.000, 0.458)},
        ["Lost Isle"] = {Pos = Vector3.new(-3804.105, 2.344, -904.653), Look = Vector3.new(-0.901, -0.000, 0.433)},
        --["Ocean (for element)"] = {Pos = Vector3.new(4675.870, 5.210, -554.690), Look = Vector3.new(-0.000, -0.000, -1.000)},
        ["Sacred Temple"] = {Pos = Vector3.new(1461.815, -22.125, -670.234), Look = Vector3.new(-0.990, -0.000, 0.143)},
        ["Second Enchant Altar"] = {Pos = Vector3.new(1479.587, 128.295, -604.224), Look = Vector3.new(-0.298, 0.000, -0.955)},
        ["Sisyphus Statue"] = {Pos = Vector3.new(-3743.745, -135.074, -1007.554), Look = Vector3.new(0.310, 0.000, 0.951)},
        ["Treasure Room"] = {Pos = Vector3.new(-3598.440, -281.274, -1645.855), Look = Vector3.new(-0.065, 0.000, -0.998)},
        ["Tropical Island"] = {Pos = Vector3.new(-2162.920, 2.825, 3638.445), Look = Vector3.new(0.381, -0.000, 0.925)},
        ["Underground Cellar"] = {Pos = Vector3.new(2118.417, -91.448, -733.800), Look = Vector3.new(0.854, 0.000, 0.521)},
        ["Volcano"] = {Pos = Vector3.new(-605.121, 19.516, 160.010), Look = Vector3.new(0.854, 0.000, 0.520)},
        ["Weather Machine"] = {Pos = Vector3.new(-1518.550, 2.875, 1916.148), Look = Vector3.new(0.042, 0.000, 0.999)},
    }
    local AreaNames = {}
    for name, _ in pairs(FishingAreas) do
        table.insert(AreaNames, name)
    end

do
    local player = Window:Tab({
        Title = "Player",
        Icon = "user",
        Locked = false,
    })

    -- MOVEMENT
    local movement = player:Section({
        Title = "Movement",
        TextSize = 20,
    })

    -- 1. SLIDER WALKSPEED
    local SliderSpeed = movement:Slider({
        Title = "WalkSpeed",
        Step = 1,
        Value = {
            Min = 16,
            Max = 200,
            Default = currentSpeed,
        },
        Flag = "slidwalk",
        Callback = function(value)
            local speedValue = tonumber(value)
            if speedValue and speedValue >= 0 then
                local Humanoid = GetHumanoid()
                if Humanoid then
                    Humanoid.WalkSpeed = speedValue
                end
            end
        end,
    })

    -- 2. SLIDER JUMPOWER
    local SliderJump = movement:Slider({
        Title = "JumpPower",
        Step = 1,
        Value = {
            Min = 50,
            Max = 200,
            Default = currentJump,
        },
        Flag = "slidjum",
        Callback = function(value)
            local jumpValue = tonumber(value)
            if jumpValue and jumpValue >= 50 then
                local Humanoid = GetHumanoid()
                if Humanoid then
                    Humanoid.JumpPower = jumpValue
                end
            end
        end,
    })
    
    -- 3. RESET BUTTON
    local reset = movement:Button({
        Title = "Reset Movement",
        Icon = "rotate-ccw",
        Locked = false,
        Callback = function()
            local Humanoid = GetHumanoid()
            if Humanoid then
                Humanoid.WalkSpeed = DEFAULT_SPEED
                Humanoid.JumpPower = DEFAULT_JUMP
                SliderSpeed:Set(DEFAULT_SPEED)
                SliderJump:Set(DEFAULT_JUMP)
                WindUI:Notify({
                    Title = "Movement Direset",
                    Content = "WalkSpeed & JumpPower Reset to default",
                    Duration = 3,
                    Icon = "check",
                })
            end
        end
    })

    -- ABILITIES
    local ability = player:Section({
        Title = "Abilities",
        TextSize = 20,
    })

    -- 1. TOGGLE INFINITE JUMP
    local infjump = ability:Toggle({
        Title = "Infinite Jump",
        Value = false,
        Flag = "infj",
        Callback = function(state)
            if state then
                WindUI:Notify({ Title = "Infinite Jump ON!", Duration = 3, Icon = "check", })
                InfinityJumpConnection = UserInputService.JumpRequest:Connect(function()
                    local Humanoid = GetHumanoid()
                    if Humanoid and Humanoid.Health > 0 then
                        Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
                    end
                end)
            else
                WindUI:Notify({ Title = "Infinite Jump OFF!", Duration = 3, Icon = "check", })
                if InfinityJumpConnection then
                    InfinityJumpConnection:Disconnect()
                    InfinityJumpConnection = nil
                end
            end
        end
    })

    -- 2. TOGGLE NO CLIP
    local noclipConnection = nil
    local isNoClipActive = false
    local noclip = ability:Toggle({
        Title = "No Clip",
        Value = false,
        Flag = "noclip",
        Callback = function(state)
            isNoClipActive = state
            local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()

            if state then
                WindUI:Notify({ Title = "No Clip ON!", Duration = 3, Icon = "check", })
                noclipConnection = game:GetService("RunService").Stepped:Connect(function()
                    if isNoClipActive and character then
                        for _, part in ipairs(character:GetDescendants()) do
                            if part:IsA("BasePart") and part.CanCollide then
                                part.CanCollide = false
                            end
                        end
                    end
                end)
            else
                WindUI:Notify({ Title = "No Clip OFF!", Duration = 3, Icon = "x", })
                if noclipConnection then noclipConnection:Disconnect() noclipConnection = nil end

                for _, part in ipairs(character:GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.CanCollide = true
                    end
                end
            end
        end
    })

    -- 3. TOGGLE FLY MODE
    local flyConnection = nil
    local isFlying = false
    local flySpeed = 60
    local bodyGyro, bodyVel
    local flytog = ability:Toggle({
        Title = "Fly Mode",
        Value = false,
        Flag = "fly",
        Callback = function(state)
            local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
            local humanoidRootPart = character:WaitForChild("HumanoidRootPart")
            local humanoid = character:WaitForChild("Humanoid")

            if state then
                WindUI:Notify({ Title = "Fly Mode ON!", Duration = 3, Icon = "check", })
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
                WindUI:Notify({ Title = "Fly Mode OFF!", Duration = 3, Icon = "x", })
                isFlying = false

                if flyConnection then flyConnection:Disconnect() flyConnection = nil end
                if bodyGyro then bodyGyro:Destroy() bodyGyro = nil end
                if bodyVel then bodyVel:Destroy() bodyVel = nil end
            end
        end
    })

   -- 4. TOGGLE WALK ON WATER (FIXED: RESPAWN SUPPORT)
    local walkOnWaterConnection = nil
    local isWalkOnWater = false
    local waterPlatform = nil
    
    local walkon = ability:Toggle({
        Title = "Walk on Water",
        Value = false,
        Flag = "walkon",
        Callback = function(state)
            -- Kita tidak mendefinisikan 'character' di sini agar logic tidak stuck di char lama

            if state then
                WindUI:Notify({ Title = "Walk on Water ON!", Duration = 3, Icon = "check", })
                isWalkOnWater = true
                
                -- Buat Platform jika belum ada
                if not waterPlatform then
                    waterPlatform = Instance.new("Part")
                    waterPlatform.Name = "WaterPlatform"
                    waterPlatform.Anchored = true
                    waterPlatform.CanCollide = true
                    waterPlatform.Transparency = 1 
                    waterPlatform.Size = Vector3.new(15, 1, 15) -- Ukuran diperbesar sedikit
                    waterPlatform.Parent = workspace
                end

                -- Pastikan koneksi lama mati dulu sebelum buat baru
                if walkOnWaterConnection then walkOnWaterConnection:Disconnect() end

                walkOnWaterConnection = game:GetService("RunService").RenderStepped:Connect(function()
                    -- [FIX] Ambil Karakter TERBARU setiap frame
                    local character = LocalPlayer.Character
                    if not isWalkOnWater or not character then return end
                    
                    local hrp = character:FindFirstChild("HumanoidRootPart")
                    if not hrp then return end

                    -- Pastikan platform masih ada (kadang kehapus oleh game cleanup)
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
                    rayParams.FilterType = Enum.RaycastFilterType.Include -- MODE WHITELIST
                    rayParams.IgnoreWater = false -- Pastikan Air terdeteksi

                    -- Tembak dari ketinggian di atas kepala
                    local rayOrigin = hrp.Position + Vector3.new(0, 5, 0) 
                    local rayDirection = Vector3.new(0, -500, 0)

                    local result = workspace:Raycast(rayOrigin, rayDirection, rayParams)

                    -- 2. LOGIKA DETEKSI
                    if result and result.Material == Enum.Material.Water then
                        -- Jika menabrak AIR (Terrain Water)
                        local waterSurfaceHeight = result.Position.Y
                        
                        -- Taruh platform tepat di permukaan air
                        waterPlatform.Position = Vector3.new(hrp.Position.X, waterSurfaceHeight, hrp.Position.Z)
                        
                        -- Jika kaki player tenggelam sedikit di bawah air, angkat ke atas
                        if hrp.Position.Y < (waterSurfaceHeight + 2) and hrp.Position.Y > (waterSurfaceHeight - 5) then
                             -- Cek input jump biar gak stuck pas mau loncat dari air
                            if not UserInputService:IsKeyDown(Enum.KeyCode.Space) then
                                hrp.CFrame = CFrame.new(hrp.Position.X, waterSurfaceHeight + 3.2, hrp.Position.Z)
                            end
                        end
                    else
                        -- Sembunyikan platform jika di darat
                        waterPlatform.Position = Vector3.new(hrp.Position.X, -500, hrp.Position.Z)
                    end
                end)

            else
                WindUI:Notify({ Title = "Walk on Water OFF!", Duration = 3, Icon = "x", })
                isWalkOnWater = false
                if walkOnWaterConnection then walkOnWaterConnection:Disconnect() walkOnWaterConnection = nil end
                if waterPlatform then waterPlatform:Destroy() waterPlatform = nil end
            end
        end
    })

    -- OTHER
    local other = player:Section({
        Title = "Other",
        TextSize = 20,
    })

    local isHideActive = false
    local hideConnection = nil
    
    local customName = ".gg/RockHub"
    local customLevel = "Lvl. 969" 

    --local custname = other:Input({
     --   Title = "Custom Fake Name",
     --   Desc = "Nama samaran yang akan muncul di atas kepala player.",
     --   Value = customName,
      --  Placeholder = "Hidden User",
      --  Icon = "user-x",
      --  Flag = "cfakename",
       -- Callback = function(text)
       --     customName = text
       -- end
   -- })

  -- local custlvl = other:Input({
    --    Title = "Custom Fake Level",
     --   Desc = "Level samaran (misal: 'Lvl. 100' atau 'Max').",
    --    Value = customLevel,
      --  Placeholder = "Lvl. 999",
      --  Icon = "bar-chart-2",
      --  Flag = "cfakelevel",
       -- Callback = function(text)
       --     customLevel = text
       -- end
   -- })

    local hideusn = other:Toggle({
        Title = "Hide All Usernames (Streamer Mode)",
        Value = false,
        Flag = "hidealluser",
        Callback = function(state)
            isHideActive = state
            
            -- 1. Atur Visibilitas Leaderboard (PlayerList)
            pcall(function()
                game:GetService("StarterGui"):SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, not state)
            end)

            if state then
                WindUI:Notify({ Title = "Hide Name ON", Content = "Nama & Level disamarkan.", Duration = 3, Icon = "eye-off" })
                
                -- 2. Loop Agresif (RenderStepped)
                if hideConnection then hideConnection:Disconnect() end
                hideConnection = game:GetService("RunService").RenderStepped:Connect(function()
                    for _, plr in ipairs(game.Players:GetPlayers()) do
                        if plr.Character then
                            -- A. Ubah Humanoid Name (Standard)
                            local hum = plr.Character:FindFirstChild("Humanoid")
                            if hum and hum.DisplayName ~= customName then 
                                hum.DisplayName = customName 
                            end

                            -- B. Ubah Custom UI (BillboardGui) - Logic Deteksi Cerdas
                            for _, obj in ipairs(plr.Character:GetDescendants()) do
                                if obj:IsA("BillboardGui") then
                                    for _, lbl in ipairs(obj:GetDescendants()) do
                                        if lbl:IsA("TextLabel") or lbl:IsA("TextButton") then
                                            if lbl.Visible then
                                                local txt = lbl.Text
                                                
                                                -- LOGIKA DETEKSI:
                                                -- 1. Jika teks mengandung Nama Asli Player -> Ubah jadi Custom Name
                                                if txt:find(plr.Name) or txt:find(plr.DisplayName) then
                                                    if txt ~= customName then
                                                        lbl.Text = customName
                                                    end
                                                
                                                -- 2. Jika teks terlihat seperti Level (angka atau 'Lvl.') -> Ubah jadi Custom Level
                                                -- Regex sederhana: mengecek apakah ada angka atau kata 'Lvl'
                                                elseif txt:match("%d+") or txt:lower():find("lvl") or txt:lower():find("level") then
                                                    -- Hindari mengubah teks UI lain yang bukan level (misal HP bar angka)
                                                    -- Biasanya level teksnya pendek (< 10 karakter)
                                                    if #txt < 15 and txt ~= customLevel then 
                                                        lbl.Text = customLevel
                                                    end
                                                end
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    end
                end)
            else
                WindUI:Notify({ Title = "Hide Name OFF", Content = "Tampilan dikembalikan.", Duration = 3, Icon = "eye" })
                
                if hideConnection then 
                    hideConnection:Disconnect() 
                    hideConnection = nil 
                end
                
                -- Restore Nama Humanoid
                for _, plr in ipairs(game.Players:GetPlayers()) do
                    if plr.Character then
                        local hum = plr.Character:FindFirstChild("Humanoid")
                        if hum then hum.DisplayName = plr.DisplayName end
                    end
                end
            end
        end
    })

    -- 2. TOGGLE PLAYER ESP
    local runService = game:GetService("RunService")
    local players = game:GetService("Players")
    local STUD_TO_M = 0.28
    local espEnabled = false
    local espConnections = {}

    local function removeESP(targetPlayer)
        if not targetPlayer then return end
        local data = espConnections[targetPlayer]
        if data then
            if data.distanceConn then pcall(function() data.distanceConn:Disconnect() end) end
            if data.charAddedConn then pcall(function() data.charAddedConn:Disconnect() end) end
            if data.billboard and data.billboard.Parent then pcall(function() data.billboard:Destroy() end) end
            espConnections[targetPlayer] = nil
        else
            if targetPlayer.Character then
                for _, v in ipairs(targetPlayer.Character:GetChildren()) do
                    if v.Name == "RockHubESP" and v:IsA("BillboardGui") then pcall(function() v:Destroy() end) end
                end
            end
        end
    end

    local function createESP(targetPlayer)
        if not targetPlayer or not targetPlayer.Character or targetPlayer == LocalPlayer then return end

        removeESP(targetPlayer)
        local char = targetPlayer.Character
        local hrp = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso") or char:FindFirstChild("UpperTorso")
        if not hrp then return end

        local BillboardGui = Instance.new("BillboardGui")
        BillboardGui.Name = "RockHubESP"
        BillboardGui.Adornee = hrp
        BillboardGui.Size = UDim2.new(0, 140, 0, 40)
        BillboardGui.AlwaysOnTop = true
        BillboardGui.StudsOffset = Vector3.new(0, 2.6, 0)
        BillboardGui.Parent = char

        local Frame = Instance.new("Frame")
        Frame.Size = UDim2.new(1, 0, 1, 0)
        Frame.BackgroundTransparency = 1
        Frame.BorderSizePixel = 0
        Frame.Parent = BillboardGui

        local NameLabel = Instance.new("TextLabel")
        NameLabel.Parent = Frame
        NameLabel.Size = UDim2.new(1, 0, 0.6, 0)
        NameLabel.Position = UDim2.new(0, 0, 0, 0)
        NameLabel.BackgroundTransparency = 1
        NameLabel.Text = tostring(targetPlayer.DisplayName or targetPlayer.Name)
        NameLabel.TextColor3 = Color3.fromRGB(255, 230, 230)
        NameLabel.TextStrokeTransparency = 0.7
        NameLabel.Font = Enum.Font.GothamBold
        NameLabel.TextScaled = true

        local DistanceLabel = Instance.new("TextLabel")
        DistanceLabel.Parent = Frame
        DistanceLabel.Size = UDim2.new(1, 0, 0.4, 0)
        DistanceLabel.Position = UDim2.new(0, 0, 0.6, 0)
        DistanceLabel.BackgroundTransparency = 1
        DistanceLabel.Text = "0.0 m"
        DistanceLabel.TextColor3 = Color3.fromRGB(210, 210, 210)
        NameLabel.TextStrokeTransparency = 0.85
        DistanceLabel.Font = Enum.Font.GothamSemibold
        DistanceLabel.TextScaled = true

        espConnections[targetPlayer] = { billboard = BillboardGui }

        local distanceConn = runService.RenderStepped:Connect(function()
            if not espEnabled or not hrp or not hrp.Parent then removeESP(targetPlayer) return end
            local localChar = LocalPlayer.Character
            local localHRP = localChar and localChar:FindFirstChild("HumanoidRootPart")
            if localHRP then
                local distStuds = (localHRP.Position - hrp.Position).Magnitude
                local distMeters = distStuds * STUD_TO_M
                DistanceLabel.Text = string.format("%.1f m", distMeters)
            end
        end)
        espConnections[targetPlayer].distanceConn = distanceConn

        local charAddedConn = targetPlayer.CharacterAdded:Connect(function()
            task.wait(0.8)
            if espEnabled then createESP(targetPlayer) end
        end)
        espConnections[targetPlayer].charAddedConn = charAddedConn
    end

    local espplay = other:Toggle({
        Title = "Player ESP",
        Value = false,
        Flag = "esp",
        Callback = function(state)
            espEnabled = state
            if state then
                WindUI:Notify({ Title = "ESP Aktif", Duration = 3, Icon = "eye", })
                for _, plr in ipairs(players:GetPlayers()) do
                    if plr ~= LocalPlayer then createESP(plr) end
                end
                espConnections["playerAddedConn"] = players.PlayerAdded:Connect(function(plr)
                    task.wait(1)
                    if espEnabled then createESP(plr) end
                end)
                espConnections["playerRemovingConn"] = players.PlayerRemoving:Connect(function(plr)
                    removeESP(plr)
                end)
            else
                WindUI:Notify({ Title = "ESP Nonaktif", Content = "Semua marker ESP dihapus.", Duration = 3, Icon = "eye-off", })
                for plr, _ in pairs(espConnections) do
                    if plr and typeof(plr) == "Instance" then removeESP(plr) end
                end
                if espConnections["playerAddedConn"] then espConnections["playerAddedConn"]:Disconnect() end
                if espConnections["playerRemovingConn"] then espConnections["playerRemovingConn"]:Disconnect() end
                espConnections = {}
            end
        end
    })

    local respawnin = other:Button({
        Title = "Reset Character (In Place)",
        Icon = "refresh-cw",
        Callback = function()
            local character = LocalPlayer.Character
            local hrp = character and character:FindFirstChild("HumanoidRootPart")
            local humanoid = character and character:FindFirstChildOfClass("Humanoid")

            if not character or not hrp or not humanoid then
                WindUI:Notify({ Title = "Gagal Reset", Content = "Karakter tidak ditemukan!", Duration = 3, Icon = "x", })
                return
            end

            local lastPos = hrp.Position

            WindUI:Notify({ Title = "Reset Character...", Content = "Respawning di posisi yang sama...", Duration = 2, Icon = "rotate-cw", })
            humanoid:TakeDamage(999999)

            LocalPlayer.CharacterAdded:Wait()
            task.wait(0.5)
            local newChar = LocalPlayer.Character
            local newHRP = newChar:WaitForChild("HumanoidRootPart", 5)

            if newHRP then
                newHRP.CFrame = CFrame.new(lastPos + Vector3.new(0, 3, 0))
                WindUI:Notify({ Title = "Character Reset Sukses!", Content = "Kamu direspawn di posisi yang sama ✅", Duration = 3, Icon = "check", })
            else
                WindUI:Notify({ Title = "Gagal Reset", Content = "HumanoidRootPart baru tidak ditemukan.", Duration = 3, Icon = "x", })
            end
        end
    })

end

do
    local farm = Window:Tab({
        Title = "Fishing",
        Icon = "fish",
        Locked = false,
    })

    -----------------------------------------------------------------
    -- 🚩 VARIABEL GLOBAL UNTUK TAB FARM
    -----------------------------------------------------------------
    -- Variabel Auto Fishing
    local legitAutoState = false
    local normalInstantState = false
    local blatantInstantState = false
    
    -- Thread Utama
    local normalLoopThread = nil
    local blatantLoopThread = nil
    
    -- Thread Khusus Auto Equip (Anti-Stuck)
    local normalEquipThread = nil
    local blatantEquipThread = nil
    local legitEquipThread = nil -- Thread baru untuk Legit

    local NormalInstantSlider = nil

    -- Variabel Fishing Area
    local isTeleportFreezeActive = false
    local freezeToggle = nil
    local selectedArea = nil
    
    local savedPosition = nil -- Menyimpan {Pos = Vector3, Look = Vector3}

    -----------------------------------------------------------------
    -- 🛠️ FUNGSI HELPER
    -----------------------------------------------------------------
    
    local function GetHRP()
        local Character = game.Players.LocalPlayer.Character
        if not Character then
            Character = game.Players.LocalPlayer.CharacterAdded:Wait()
        end
        return Character:WaitForChild("HumanoidRootPart", 5)
    end
    
    local function TeleportToLookAt(position, lookVector)
        local hrp = GetHRP()
        
        if hrp and typeof(position) == "Vector3" and typeof(lookVector) == "Vector3" then
            local targetCFrame = CFrame.new(position, position + lookVector)
            hrp.CFrame = targetCFrame * CFrame.new(0, 0.5, 0)
            
            WindUI:Notify({ Title = "Teleport Sukses!", Duration = 3, Icon = "map-pin", })
        else
            WindUI:Notify({ Title = "Teleport Gagal", Duration = 3, Icon = "x", })
        end
    end
    
    local RPath = {"Packages", "_Index", "sleitnick_net@0.2.0", "net"}
    local RE_EquipToolFromHotbar = GetRemote(RPath, "RE/EquipToolFromHotbar")
    local RF_ChargeFishingRod = GetRemote(RPath, "RF/ChargeFishingRod")
    local RF_RequestFishingMinigameStarted = GetRemote(RPath, "RF/RequestFishingMinigameStarted")
    local RE_FishingCompleted = GetRemote(RPath, "RE/FishingCompleted")
    local RF_CancelFishingInputs = GetRemote(RPath, "RF/CancelFishingInputs")
    local RF_UpdateAutoFishingState = GetRemote(RPath, "RF/UpdateAutoFishingState")

    local function checkFishingRemotes(silent)
        local remotes = { RE_EquipToolFromHotbar, RF_ChargeFishingRod, RF_RequestFishingMinigameStarted,
                          RE_FishingCompleted, RF_CancelFishingInputs, RF_UpdateAutoFishingState }
        for _, remote in ipairs(remotes) do
            if not remote then
                if not silent then
                    WindUI:Notify({ Title = "Remote Error!", Content = "Remote Fishing tidak ditemukan! Cek jalur RPath.", Duration = 5, Icon = "x", })
                end
                return false
            end
        end
        return true
    end

    local function disableOtherModes(currentMode)
        pcall(function()
            -- Find Toggles based on titles
            local toggleLegit = farm:GetElementByTitle("Auto Fish (Legit)")
            local toggleNormal = farm:GetElementByTitle("Normal Instant Fish")
            local toggleBlatant = farm:GetElementByTitle("Instant Fishing (Blatant)")

            if currentMode ~= "legit" and legitAutoState then 
                legitAutoState = false
                if toggleLegit and toggleLegit.Set then toggleLegit:Set(false) end
                if legitClickThread then task.cancel(legitClickThread) legitClickThread = nil end
                if legitEquipThread then task.cancel(legitEquipThread) legitEquipThread = nil end -- Matikan Equip Thread
            end
            if currentMode ~= "normal" and normalInstantState then 
                normalInstantState = false
                if toggleNormal and toggleNormal.Set then toggleNormal:Set(false) end
                if normalLoopThread then task.cancel(normalLoopThread) normalLoopThread = nil end
                if normalEquipThread then task.cancel(normalEquipThread) normalEquipThread = nil end
            end
            if currentMode ~= "blatant" and blatantInstantState then 
                blatantInstantState = false
                if toggleBlatant and toggleBlatant.Set then toggleBlatant:Set(false) end
                if blatantLoopThread then task.cancel(blatantLoopThread) blatantLoopThread = nil end
                if blatantEquipThread then task.cancel(blatantEquipThread) blatantEquipThread = nil end -- Matikan Equip Thread
            end
        end)
        
        -- Reset server-side auto fishing state if moving away from Legit mode
        if currentMode ~= "legit" then
            pcall(function() if RF_UpdateAutoFishingState then RF_UpdateAutoFishingState:InvokeServer(false) end end)
        end
    end
    
    -- ===================================================================
    -- LOGIKA BARU UNTUK AUTO FISH LEGIT
    -- ===================================================================

    local FishingController = require(RepStorage:WaitForChild("Controllers").FishingController)
    local AutoFishingController = require(RepStorage:WaitForChild("Controllers").AutoFishingController)

    local AutoFishState = {
        IsActive = false,
        MinigameActive = false
    }

    local SPEED_LEGIT = 0.05
    local legitClickThread = nil

    local function performClick()
        if FishingController then
            FishingController:RequestFishingMinigameClick()
            task.wait(SPEED_LEGIT)
        end
    end
    
    -- Hook FishingRodStarted (Minigame Aktif)
    local originalRodStarted = FishingController.FishingRodStarted
    FishingController.FishingRodStarted = function(self, arg1, arg2)
        originalRodStarted(self, arg1, arg2)

        if AutoFishState.IsActive and not AutoFishState.MinigameActive then
            AutoFishState.MinigameActive = true

            if legitClickThread then
                task.cancel(legitClickThread)
            end

            legitClickThread = task.spawn(function()
                while AutoFishState.IsActive and AutoFishState.MinigameActive do
                    performClick()
                end
            end)
        end
    end

    -- Hook FishingStopped
    local originalFishingStopped = FishingController.FishingStopped
    FishingController.FishingStopped = function(self, arg1)
        originalFishingStopped(self, arg1)

        if AutoFishState.MinigameActive then
            AutoFishState.MinigameActive = false
        end
    end

    local function ensureServerAutoFishingOn()
        local replionClient = require(RepStorage:WaitForChild("Packages").Replion).Client
        local replionData = replionClient:WaitReplion("Data", 5)

        local remoteFunctionName = "RF/UpdateAutoFishingState"
        local UpdateAutoFishingRemote = GetRemote(RPath, remoteFunctionName)

        if UpdateAutoFishingRemote then
            pcall(function()
                UpdateAutoFishingRemote:InvokeServer(true)
            end)
        end
    end
    
    local function ToggleAutoClick(shouldActivate)
        if not FishingController or not AutoFishingController then
            WindUI:Notify({ Title = "Error", Content = "Gagal memuat Fishing Controllers.", Duration = 4, Icon = "x" })
            return
        end
        
        AutoFishState.IsActive = shouldActivate

        local playerGui = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
        local fishingGui = playerGui:FindFirstChild("Fishing") and playerGui.Fishing:FindFirstChild("Main")
        local chargeGui = playerGui:FindFirstChild("Charge") and playerGui.Charge:FindFirstChild("Main")


        if shouldActivate then
            -- 1. Equip Rod Awal
            pcall(function() RE_EquipToolFromHotbar:FireServer(1) end)
            
            -- 2. Force Server AutoFishing State
            ensureServerAutoFishingOn()
            
            -- 3. Sembunyikan UI Minigame
            if fishingGui then fishingGui.Visible = false end
            if chargeGui then chargeGui.Visible = false end

            WindUI:Notify({ Title = "Auto Fish Legit ON!", Content = "Auto-Equip Protection Active.", Duration = 3, Icon = "check" })

        else
            if legitClickThread then
                task.cancel(legitClickThread)
                legitClickThread = nil
            end
            AutoFishState.MinigameActive = false
            
            -- 4. Tampilkan kembali UI Minigame
            if fishingGui then fishingGui.Visible = true end
            if chargeGui then chargeGui.Visible = true end

            WindUI:Notify({ Title = "Auto Fish Legit OFF!", Duration = 3, Icon = "x" })
        end
    end

    -- =================================================================
    -- 🎣 AUTO FISHING SECTION UI
    -- =================================================================
    local autofish = farm:Section({
        Title = "Auto Fishing",
        TextSize = 20,
        FontWeight = Enum.FontWeight.SemiBold,
    })

    -- 1. TOGGLE AUTO FISH (LEGIT - UPDATED)
    local slidlegit = autofish:Slider({
        Title = "Legit Click Speed (Delay)",
        Step = 0.01,
        Value = { Min = 0.01, Max = 0.5, Default = SPEED_LEGIT },
        Flag = "klikd",
        Callback = function(value)
            local newSpeed = tonumber(value)
            if newSpeed and newSpeed >= 0.01 then
                SPEED_LEGIT = newSpeed
            end
        end
    })

    local toglegit = autofish:Toggle({
        Title = "Auto Fish (Legit)",
        Value = false,
        Flag = "legit",
        Callback = function(state)
            if not checkFishingRemotes() then return false end
            disableOtherModes("legit")
            legitAutoState = state
            ToggleAutoClick(state)

            -- [THREAD BARU] AUTO EQUIP BACKGROUND - LEGIT MODE
            if state then
                if legitEquipThread then task.cancel(legitEquipThread) end
                legitEquipThread = task.spawn(function()
                    while legitAutoState do
                        pcall(function() RE_EquipToolFromHotbar:FireServer(1) end)
                        task.wait(0.1) -- Delay spam 0.1 detik
                    end
                end)
            else
                if legitEquipThread then task.cancel(legitEquipThread) legitEquipThread = nil end
            end
        end
    })

    --farm:Divider()
    
    -- Variabel & Slider Delay
    local normalCompleteDelay = 1.50

    NormalInstantSlider = autofish:Slider({
        Title = "Normal Complete Delay",
        Step = 0.05,
        Value = { Min = 0.5, Max = 5.0, Default = normalCompleteDelay },
        Flag = "slidn",
        Callback = function(value) normalCompleteDelay = tonumber(value) end
    })

    -- Fungsi Utama Mancing (Looping Action)
    local function runNormalInstant()
        if not normalInstantState then return end
        if not checkFishingRemotes(true) then normalInstantState = false return end
        
        local timestamp = os.time() + os.clock()
        pcall(function() RF_ChargeFishingRod:InvokeServer(timestamp) end)
        pcall(function() RF_RequestFishingMinigameStarted:InvokeServer(-139.630452165, 0.99647927980797) end)
        
        task.wait(normalCompleteDelay)
        
        pcall(function() RE_FishingCompleted:FireServer() end)
        task.wait(0.3)
        pcall(function() RF_CancelFishingInputs:InvokeServer() end)
        task.wait(0.3)
    end

    local normalins = autofish:Toggle({
        Title = "Normal Instant Fish",
        Value = false,
        Flag = "norins",
        Callback = function(state)
            if not checkFishingRemotes() then return end
            disableOtherModes("normal")
            normalInstantState = state
            
            if state then
                -- THREAD 1: Logic Mancing Utama
                normalLoopThread = task.spawn(function()
                    while normalInstantState do
                        runNormalInstant()
                        task.wait(0.1) 
                    end
                end)

                -- THREAD 2: Background Auto Equip (Anti-Stuck)
                if normalEquipThread then task.cancel(normalEquipThread) end
                normalEquipThread = task.spawn(function()
                    while normalInstantState do
                        pcall(function() RE_EquipToolFromHotbar:FireServer(1) end)
                        task.wait(0.1) -- Delay spam 0.1 detik
                    end
                end)
                
                WindUI:Notify({ Title = "Auto Fish ON", Content = "Auto-Equip Protection Active.", Duration = 3, Icon = "fish" })
            else
                -- Matikan kedua thread saat toggle OFF
                if normalLoopThread then task.cancel(normalLoopThread) normalLoopThread = nil end
                if normalEquipThread then task.cancel(normalEquipThread) normalEquipThread = nil end
                
                pcall(function() RE_EquipToolFromHotbar:FireServer(0) end)
                WindUI:Notify({ Title = "Auto Fish OFF", Duration = 3, Icon = "x" })
            end
        end
    })


    -- 3. INSTANT FISHING (BLATANT / ADVANCED)
    --local blatant = farm:Section({ Title = "Blatant Mode", TextSize = 20, })

    --local completeDelay = 3.055
    --local cancelDelay = 0.3
    --local loopInterval = 1.715

    --local LoopIntervalInput = blatant:Input({
       --Title = "Blatant Interval", Value = tostring(loopInterval), Icon = "fast-forward", Type = "Input", Placeholder = "1.58", Flag = "intbl",
        --Callback = function(input)
            --local newInterval = tonumber(input)
            --if newInterval and newInterval >= 0.5 then loopInterval = newInterval end
        --end
    --})

    --local CompleteDelayInput = blatant:Input({
        --Title = "Complete Delay", Value = tostring(completeDelay), Icon = "loader", Type = "Input", Placeholder = "2.75", Flag = "comlay",
        --Callback = function(input)
            --local newDelay = tonumber(input)
            --if newDelay and newDelay >= 0.5 then completeDelay = newDelay end
        --end
    --})

    --local CancelDelayInput = blatant:Input({
      --  Title = "Cancel Delay", Value = tostring(cancelDelay), Icon = "clock", Type = "Input", Placeholder = "0.3", Flag = "canlay",
        --Callback = function(input)
          --  local newDelay = tonumber(input)
            --if newDelay and newDelay >= 0.1 then cancelDelay = newDelay end
        --end
    --})

    local function runBlatantInstant()
        if not blatantInstantState then return end
        if not checkFishingRemotes(true) then blatantInstantState = false return end

        task.spawn(function()
            local startTime = os.clock()
            
            local timestamp = os.time() + os.clock()
            pcall(function() RF_ChargeFishingRod:InvokeServer(timestamp) end)
            task.wait(0.001)
            pcall(function() RF_RequestFishingMinigameStarted:InvokeServer(-139.6379699707, 0.99647927980797) end)
            
            local completeWaitTime = completeDelay - (os.clock() - startTime)
            if completeWaitTime > 0 then task.wait(completeWaitTime) end
            
            pcall(function() RE_FishingCompleted:FireServer() end)
            task.wait(cancelDelay)
            pcall(function() RF_CancelFishingInputs:InvokeServer() end)
        end)
    end

    --local togblat = blatant:Toggle({
        --Title = "Instant Fishing (Blatant)",
        --Value = false,
        --Flag = "blat",
        --Callback = function(state)
            --if not checkFishingRemotes() then return end
            --disableOtherModes("blatant")
            --blatantInstantState = state
            --if state then
                -- THREAD 1: LOGIC UTAMA
               -- blatantLoopThread = task.spawn(function()
                   -- while blatantInstantState do
                       -- runBlatantInstant()
                        --task.wait(loopInterval)
                    --end
                --end)

                -- [THREAD BARU] THREAD 2: AUTO EQUIP BACKGROUND - BLATANT MODE
                --if blatantEquipThread then task.cancel(blatantEquipThread) end
                --blatantEquipThread = task.spawn(function()
                --    while blatantInstantState do
                 --       pcall(function() RE_EquipToolFromHotbar:FireServer(1) end)
                 --       task.wait(0.1) -- Delay spam 0.1 detik
                 --   end
               -- end)
                
              --  WindUI:Notify({ Title = "Blatant Fish ON", Content = "Auto-Equip Protection Active.", Duration = 3, Icon = "zap" })
           -- else
              --  if blatantLoopThread then task.cancel(blatantLoopThread) blatantLoopThread = nil end
               -- if blatantEquipThread then task.cancel(blatantEquipThread) blatantEquipThread = nil end -- Matikan thread equip
           -- end
        --end
    --})

    farm:Divider()

    -- -----------------------------------------------------------------
    -- 🎯 FISHING AREA SECTION (POSITION + LOOKVECTOR)
    -- -----------------------------------------------------------------
    local areafish = farm:Section({
        Title = "Fishing Area",
        TextSize = 20,
    })

    -- 1. DROPDOWN Choose Area
    local choosearea = areafish:Dropdown({
        Title = "Choose Area",
        Values = AreaNames,
        AllowNone = true,
        Value = nil,
        Flag = "tchus",
        Callback = function(option)
            selectedArea = option
            local display = option or "None"
        end
    })

    local freezeToggle = areafish :Toggle({
        Title = "Teleport & Freeze at Area",
        Value = false,
        Flag = "tfrez",
        Callback = function(state)
            isTeleportFreezeActive = state
            
            local hrp = GetHRP()
            if not hrp then
                if freezeToggle and freezeToggle.Set then freezeToggle:Set(false) end
                return
            end

            if state then
                if not selectedArea then
                    WindUI:Notify({ Title = "Aksi Gagal", Content = "Pilih Area dulu di Dropdown!", Duration = 3, Icon = "alert-triangle", })
                    if freezeToggle and freezeToggle.Set then freezeToggle:Set(false) end
                    return
                end
                
                local areaData = (selectedArea == "Custom: Saved" and savedPosition) or FishingAreas[selectedArea]

                if not areaData or not areaData.Pos or not areaData.Look then
                    WindUI:Notify({ Title = "Aksi Gagal", Duration = 3, Icon = "alert-triangle", })
                    if freezeToggle and freezeToggle.Set then freezeToggle:Set(false) end
                    return
                end
                
                -- 1. Pastikan Unanchor dulu biar bisa pindah
                hrp.Anchored = false
                
                -- 2. Teleport ke Posisi Target
                TeleportToLookAt(areaData.Pos, areaData.Look)
                
                -- 3. Tunggu sebentar agar Server mendeteksi kepindahan kita
                task.wait(0.175) 
                
                -- 4. Baru Freeze (Anchor)
                if isTeleportFreezeActive then
                    hrp.Velocity = Vector3.new(0,0,0)
                    hrp.AssemblyLinearVelocity = Vector3.new(0,0,0)
                    hrp.Anchored = true
                    WindUI:Notify({ Title = "Frozen", Content = "Posisi dikunci di area.", Duration = 2, Icon = "lock" })
                end
                
            else
                -- Matikan Freeze (UNANCHORED)
                hrp.Anchored = false
                WindUI:Notify({ Title = "Unfrozen", Content = "Gerakan kembali normal.", Duration = 2, Icon = "unlock" })
            end
        end
    })

    local teleto = areafish:Button({
        Title = "Teleport to Choosen Area",
        Icon = "corner-down-right",
        Callback = function()
            if not selectedArea then
                WindUI:Notify({ Title = "Teleport Gagal", Content = "Pilih Area dulu di Dropdown.", Duration = 3, Icon = "alert-triangle", })
                return
            end

            local areaData = (selectedArea == "Custom: Saved" and savedPosition) or FishingAreas[selectedArea]
            
            if not areaData or not areaData.Pos or not areaData.Look then
                WindUI:Notify({ Title = "Teleport Gagal",Duration = 3, Icon = "alert-triangle", })
                return
            end

            if isTeleportFreezeActive and freezeToggle then
                freezeToggle:Set(false)
                task.wait(0.1)
            end
            
            TeleportToLookAt(areaData.Pos, areaData.Look)
        end
    })

    farm:Divider()

    -- 3. BUTTON Save Current Position
    local savepos = areafish:Button({
        Title = "Save Current Position",
        Icon = "map-pin",
        Callback = function()
            local hrp = GetHRP()
            if hrp then
                savedPosition = {
                    Pos = hrp.Position,
                    Look = hrp.CFrame.LookVector
                }
                FishingAreas["Custom: Saved"] = savedPosition
                WindUI:Notify({
                    Title = "Posisi Disimpan!",
                    Duration = 3,
                    Icon = "save",
                })
            else
                WindUI:Notify({ Title = "Gagal Simpan", Duration = 3, Icon = "x", })
            end
        end
    })

    
    -- 6. BUTTON Teleport to SAVED POS
    local teletosave = areafish:Button({
        Title = "Teleport to SAVED Pos",
        Icon = "navigation",
        Callback = function()
            if not savedPosition then
                WindUI:Notify({ Title = "Teleport Gagal", Content = "Belum ada posisi yang disimpan.", Duration = 3, Icon = "alert-triangle", })
                return
            end
            
            local areaData = savedPosition
            
            if isTeleportFreezeActive and freezeToggle then
                freezeToggle:Set(false)
                task.wait(0.1)
            end
            
            TeleportToLookAt(areaData.Pos, areaData.Look)
        end
    })
end

do
    local automatic = Window:Tab({
        Title = "Automatic",
        Icon = "loader",
        Locked = false,
    })

    -- Variabel untuk Auto Sell
    local sellDelay = 50
    local autoSellDelayState = false
    local autoSellDelayThread = nil
    local sellCount = 50
    local autoSellCountState = false
    local autoSellCountThread = nil

    -- Variabel Auto Favorite/Unfavorite
    local autoFavoriteState = false
    local autoFavoriteThread = nil
    local autoUnfavoriteState = false
    local autoUnfavoriteThread = nil
    local selectedRarities = {}
    local selectedItemNames = {}
    local selectedMutations = {}

    local RE_FavoriteItem = GetRemote(RPath, "RE/FavoriteItem")

    -- Helper Function: Get Fish/Item Count
    local function GetFishCount()
        local replion = GetPlayerDataReplion()
        if not replion then return 0 end

        local totalFishCount = 0
        local success, inventoryData = pcall(function()
            return replion:GetExpect("Inventory")
        end)
        
        if not success or not inventoryData or not inventoryData.Items or typeof(inventoryData.Items) ~= "table" then
            return 0
        end

        for _, item in ipairs(inventoryData.Items) do
            local isSellableFish = false

            -- EKSKLUSI GEAR/CRATE/ETC.
            if item.Type == "Fishing Rods" or item.Type == "Boats" or item.Type == "Bait" or item.Type == "Pets" or item.Type == "Chests" or item.Type == "Crates" or item.Type == "Totems" then
                continue
            end
            if item.Identifier and (item.Identifier:match("Artifact") or item.Identifier:match("Key") or item.Identifier:match("Token") or item.Identifier:match("Booster") or item.Identifier:match("hourglass")) then
                continue
            end
            
            -- INKLUSI JIKA ITEM MEMILIKI WEIGHT METADATA
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

    -- Helper Function: Menonaktifkan mode Auto Sell lain
    local function disableOtherAutoSell(currentMode)
        if currentMode ~= "delay" and autoSellDelayState then
            autoSellDelayState = false
            local toggle = automatic:GetElementByTitle("Auto Sell All (Delay)")
            if toggle and toggle.Set then toggle:Set(false) end
            if autoSellDelayThread then task.cancel(autoSellDelayThread) autoSellDelayThread = nil end
        end
        if currentMode ~= "count" and autoSellCountState then
            autoSellCountState = false
            local toggle = automatic:GetElementByTitle("Auto Sell by Count")
            if toggle and toggle.Set then toggle:Set(false) end
            if autoSellCountThread then task.cancel(autoSellCountThread) autoSellCountThread = nil end
        end
    end

    -- LOGIC AUTO SELL BY DELAY
    local function RunAutoSellDelayLoop()
        if autoSellDelayThread then task.cancel(autoSellDelayThread) end
        autoSellDelayThread = task.spawn(function()
            while autoSellDelayState do
                if RF_SellAllItems then
                    pcall(function() RF_SellAllItems:InvokeServer() end)
                end
                task.wait(math.max(sellDelay, 1))
            end
        end)
    end
    
    -- LOGIC AUTO SELL BY COUNT
    local function RunAutoSellCountLoop()
        if autoSellCountThread then task.cancel(autoSellCountThread) end
        autoSellCountThread = task.spawn(function()
            while autoSellCountState do
                local currentCount = GetFishCount()
                
                if currentCount >= sellCount then
                    if RF_SellAllItems then
                        pcall(function() RF_SellAllItems:InvokeServer() end)
                        task.wait(1)
                    end
                end
                task.wait(1)
            end
        end)
    end


    -- =================================================================
    -- 💰 UNIFIED AUTO SELL SYSTEM (BY DELAY / BY COUNT)
    -- =================================================================
    local sellall = automatic:Section({ Title = "Autosell Fish", TextSize = 20 })

    -- Variabel Global Auto Sell Baru
    local autoSellMethod = "Delay" -- Default: Delay
    local autoSellValue = 50       -- Default Value (Detik atau Jumlah)
    local autoSellState = false
    local autoSellThread = nil

    -- 1. Helper: Unified Loop Logic
    local function RunAutoSellLoop()
        if autoSellThread then task.cancel(autoSellThread) end
        
        autoSellThread = task.spawn(function()
            while autoSellState do
                if autoSellMethod == "Delay" then
                    -- === LOGIC BY DELAY ===
                    if RF_SellAllItems then
                        pcall(function() RF_SellAllItems:InvokeServer() end)
                    end
                    -- Wait sesuai input (minimal 1 detik biar ga crash)
                    task.wait(math.max(autoSellValue, 1))

                elseif autoSellMethod == "Count" then
                    -- === LOGIC BY COUNT ===
                    local currentCount = GetFishCount() -- Pastikan fungsi GetFishCount ada di atas
                    
                    if currentCount >= autoSellValue then
                        if RF_SellAllItems then
                            pcall(function() RF_SellAllItems:InvokeServer() end)
                            WindUI:Notify({ Title = "Auto Sell", Content = "Menjual " .. currentCount .. " items.", Duration = 2, Icon = "dollar-sign" })
                            task.wait(2) -- Cooldown sebentar setelah jual
                        end
                    end
                    task.wait(1) -- Cek setiap 1 detik
                end
            end
        end)
    end

    -- 2. UI Elements
    
    -- Dropdown untuk memilih metode
    local inputElement -- Forward declaration untuk update judul input
    
    local dropMethod = sellall:Dropdown({
        Title = "Select Method",
        Values = {"Delay", "Count"},
        Value = "Delay",
        Multi = false,
        AllowNone = false,
        Flag = "sellmethod",
        Callback = function(val)
            autoSellMethod = val
            
            -- Update Judul Input agar user paham
            if inputElement then
                if val == "Delay" then
                    inputElement:SetTitle("Sell Delay (Seconds)")
                    inputElement:SetPlaceholder("e.g. 50")
                else
                    inputElement:SetTitle("Sell at Item Count")
                    inputElement:SetPlaceholder("e.g. 100")
                end
            end
            
            -- Restart loop jika sedang aktif agar logika langsung berubah
            if autoSellState then
                RunAutoSellLoop()
            end
        end
    })

    -- Input Tunggal (Dinamis)
    inputElement = sellall:Input({
        Title = "Sell Delay (Seconds)", -- Judul awal
        Value = tostring(autoSellValue),
        Placeholder = "50",
        Flag = "sellval",
        Icon = "hash",
        Callback = function(text)
            local num = tonumber(text)
            if num then
                autoSellValue = num
            end
        end
    })

    -- Display Jumlah Ikan Saat Ini (Berguna untuk mode Count)
    local CurrentCountDisplay = sellall:Paragraph({ Title = "Current Fish Count: 0", Icon = "package" })
    task.spawn(function() 
        while true do 
            if CurrentCountDisplay and GetPlayerDataReplion() then 
                local count = GetFishCount() 
                CurrentCountDisplay:SetTitle("Current Fish Count: " .. tostring(count)) 
            end 
            task.wait(1) 
        end 
    end)

    -- Toggle Tunggal
    local togSell = sellall:Toggle({
        Title = "Enable Auto Sell",
        Desc = "Menjalankan auto sell sesuai metode di atas.",
        Value = false,
        Flag = "tsellmaster",
        Callback = function(state)
            autoSellState = state
            if state then
                if not RF_SellAllItems then
                    WindUI:Notify({ Title = "Error", Content = "Remote Sell tidak ditemukan.", Duration = 3, Icon = "x" })
                    return false
                end
                
                local msg = (autoSellMethod == "Delay") and ("Setiap " .. autoSellValue .. " detik.") or ("Saat jumlah >= " .. autoSellValue)
                WindUI:Notify({ Title = "Auto Sell ON (" .. autoSellMethod .. ")", Content = msg, Duration = 3, Icon = "check" })
                RunAutoSellLoop()
            else
                WindUI:Notify({ Title = "Auto Sell OFF", Duration = 3, Icon = "x" })
                if autoSellThread then task.cancel(autoSellThread) autoSellThread = nil end
            end
        end
    })

    automatic:Divider()
    
    local favsec = automatic:Section({ Title = "Auto Favorite / Unfavorite", TextSize = 20, })
    
    -- 1. FUNGSI BARU UNTUK MENGAMBIL SEMUA NAMA ITEM (GLOBAL)
    local function getAutoFavoriteItemOptions()
        local itemNames = {}
        local ReplicatedStorage = game:GetService("ReplicatedStorage")
        local itemsContainer = ReplicatedStorage:FindFirstChild("Items")

        if not itemsContainer then
            return {"(Kontainer 'Items' di ReplicatedStorage Tidak Ditemukan)"}
        end

        for _, itemObject in ipairs(itemsContainer:GetChildren()) do
            local itemName = itemObject.Name
            
            if type(itemName) == "string" and #itemName >= 3 then
                -- Menggunakan string:sub untuk mengecek prefix '!!!'
                local prefix = itemName:sub(1, 3)
                
                if prefix ~= "!!!" then
                    table.insert(itemNames, itemName)
                end
            end
        end

        table.sort(itemNames)
        
        if #itemNames == 0 then
            return {"(Kontainer 'Items' Kosong atau Semua Item '!!!')"}
        end
        
        return itemNames
    end
    
    local allItemNames = getAutoFavoriteItemOptions()
    
    -- FUNGSI HELPER: Mendapatkan semua item yang memenuhi kriteria (DIFORWARD KE FAVORITE)
    -- GANTI FUNGSI LAMA 'GetItemsToFavorite' DENGAN YANG INI:

local function GetItemsToFavorite()
    local replion = GetPlayerDataReplion()
    if not replion or not ItemUtility or not TierUtility then return {} end

    local success, inventoryData = pcall(function() return replion:GetExpect("Inventory") end)
    if not success or not inventoryData or not inventoryData.Items then return {} end

    local itemsToFavorite = {}
    
    -- Cek apakah ada filter yang aktif? (Kalau semua kosong, jangan favorite apa-apa biar aman)
    local isRarityFilterActive = #selectedRarities > 0
    local isNameFilterActive = #selectedItemNames > 0
    local isMutationFilterActive = #selectedMutations > 0

    if not (isRarityFilterActive or isNameFilterActive or isMutationFilterActive) then
        return {} -- Tidak ada filter dipilih, return kosong.
    end

    for _, item in ipairs(inventoryData.Items) do
        -- SKIP JIKA SUDAH FAVORIT
        if item.IsFavorite or item.Favorited then continue end
        
        local itemUUID = item.UUID
        if typeof(itemUUID) ~= "string" or itemUUID:len() < 10 then continue end
        
        local name, rarity = GetFishNameAndRarity(item)
        local mutationFilterString = GetItemMutationString(item)
        
        -- LOGIKA BARU (MULTI-SUPPORT / OR LOGIC)
        local isMatch = false

        -- 1. Cek Rarity (Hanya jika filter rarity dipilih)
        if isRarityFilterActive and table.find(selectedRarities, rarity) then
            isMatch = true
        end

        -- 2. Cek Nama (Hanya jika filter nama dipilih)
        -- Kita pakai 'if not isMatch' biar gak double check kalau udah match di rarity
        if not isMatch and isNameFilterActive and table.find(selectedItemNames, name) then
            isMatch = true
        end

        -- 3. Cek Mutasi (Hanya jika filter mutasi dipilih)
        if not isMatch and isMutationFilterActive and table.find(selectedMutations, mutationFilterString) then
            isMatch = true
        end

        -- Jika SALAH SATU kondisi di atas terpenuhi, masukkan ke daftar favorite
        if isMatch then
            table.insert(itemsToFavorite, itemUUID)
        end
    end

    return itemsToFavorite
end
    
    -- PERBAIKAN LOGIKA UNFAVORITE: Mendapatkan item yang SUDAH FAVORIT dan MASUK filter (untuk di-unfavorite)
    local function GetItemsToUnfavorite()
        local replion = GetPlayerDataReplion()
        if not replion or not ItemUtility or not TierUtility then return {} end

        local success, inventoryData = pcall(function() return replion:GetExpect("Inventory") end)
        if not success or not inventoryData or not inventoryData.Items then return {} end

        local itemsToUnfavorite = {}
        
        for _, item in ipairs(inventoryData.Items) do
            -- 1. HANYA PROSES ITEM YANG SUDAH FAVORIT
            if not (item.IsFavorite or item.Favorited) then
                continue
            end
            local itemUUID = item.UUID
            if typeof(itemUUID) ~= "string" or itemUUID:len() < 10 then
                continue
            end
            
            -- 2. CHECK APAKAH MASUK KE CRITERIA FILTER YANG DIPILIH
            local name, rarity = GetFishNameAndRarity(item)
            local mutationFilterString = GetItemMutationString(item)
            
            local passesRarity = #selectedRarities > 0 and table.find(selectedRarities, rarity)
            local passesName = #selectedItemNames > 0 and table.find(selectedItemNames, name)
            local passesMutation = #selectedMutations > 0 and table.find(selectedMutations, mutationFilterString)
            
            -- LOGIKA BARU: Unfavorite JIKA item SUDAH FAVORIT DAN MEMENUHI SALAH SATU CRITERIA FILTER.
            local isTargetedForUnfavorite = passesRarity or passesName or passesMutation
            
            if isTargetedForUnfavorite then
                table.insert(itemsToUnfavorite, itemUUID)
            end
        end

        return itemsToUnfavorite
    end

    -- FUNGSI UTAMA: Mengirim Remote untuk Favorite/Unfavorite
    local function SetItemFavoriteState(itemUUID, isFavorite)
        if not RE_FavoriteItem then return false end
        pcall(function() RE_FavoriteItem:FireServer(itemUUID) end)
        return true
    end

    -- LOGIC AUTO FAVORITE LOOP
    local function RunAutoFavoriteLoop()
        if autoFavoriteThread then task.cancel(autoFavoriteThread) end
        
        autoFavoriteThread = task.spawn(function()
            local waitTime = 1
            local actionDelay = 0.5
            
            while autoFavoriteState do
                local itemsToFavorite = GetItemsToFavorite()
                
                if #itemsToFavorite > 0 then
                    WindUI:Notify({ Title = "Auto Favorite", Content = string.format("Mem-favorite %d item...", #itemsToFavorite), Duration = 1, Icon = "star" })
                    for _, itemUUID in ipairs(itemsToFavorite) do
                        SetItemFavoriteState(itemUUID, true)
                        task.wait(actionDelay)
                    end
                end
                
                task.wait(waitTime)
            end
        end)
    end

    -- LOGIC AUTO UNFAVORITE LOOP
    local function RunAutoUnfavoriteLoop()
        if autoUnfavoriteThread then task.cancel(autoUnfavoriteThread) end
        
        autoUnfavoriteThread = task.spawn(function()
            local waitTime = 1
            local actionDelay = 0.5
            
            while autoUnfavoriteState do
                local itemsToUnfavorite = GetItemsToUnfavorite()
                
                if #itemsToUnfavorite > 0 then
                    WindUI:Notify({ Title = "Auto Unfavorite", Content = string.format("Menghapus favorite dari %d item yang dipilih...", #itemsToUnfavorite), Duration = 1, Icon = "x" })
                    for _, itemUUID in ipairs(itemsToUnfavorite) do
                        SetItemFavoriteState(itemUUID, false)
                        task.wait(actionDelay)
                    end
                end
                
                task.wait(waitTime)
            end
        end)
    end


    -- UI ELEMENTS FAVORITE / UNFAVORITE --
    
    local RarityDropdown = favsec:Dropdown({
        Title = "by Rarity",
        Values = {"Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic", "SECRET", "Trophy", "Collectible", "DEV"},
        Multi = true, AllowNone = true, Value = false,
        Flag = "drer",
        Callback = function(values) selectedRarities = values or {} end
    })

   -- local ItemNameDropdown = favsec:Dropdown({
       -- Title = "by Item Name",
     --   Values = allItemNames, -- Menggunakan daftar nama item universal
       -- Multi = true, AllowNone = true, Value = false,
      --  Flag = "dtem",
       -- Callback = function(values) selectedItemNames = values or {} end -- Multi select untuk nama
   -- })

    --local MutationDropdown = favsec:Dropdown({
      --  Title = "by Mutation",
       -- Values = {"Shiny", "Gemstone", "Corrupt", "Galaxy", "Holographic", "Ghost", "Lightning", "Fairy Dust", "Gold", "Midnight", "Radioactive", "Stone", "Albino", "Sandy", "Acidic", "Frozen", "Disco"},
        --Multi = true, AllowNone = true, Value = false,
       -- Flag = "dmut",
       -- Callback = function(values) selectedMutations = values or {} end
    --})

    -- Toggle Auto Favorite
    local togglefav = favsec:Toggle({
        Title = "Enable Auto Favorite",
        Value = false,
        Flag = "fav",
        Callback = function(state)
            autoFavoriteState = state
            if state then
                if autoUnfavoriteState then -- Menonaktifkan Unfavorite jika Favorite ON
                    autoUnfavoriteState = false
                    local unfavToggle = automatic:GetElementByTitle("Enable Auto Unfavorite")
                    if unfavToggle and unfavToggle.Set then unfavToggle:Set(false) end
                    if autoUnfavoriteThread then task.cancel(autoUnfavoriteThread) autoUnfavoriteThread = nil end
                end

                if not GetPlayerDataReplion() or not ItemUtility or not TierUtility then WindUI:Notify({ Title = "Error", Content = "Gagal memuat data ItemUtility/TierUtility/Replion.", Duration = 3, Icon = "x" }) return false end
                
                WindUI:Notify({ Title = "Auto Favorite ON!", Duration = 3, Icon = "check", })
                RunAutoFavoriteLoop()
            else
                WindUI:Notify({ Title = "Auto Favorite OFF!", Duration = 3, Icon = "x", })
                if autoFavoriteThread then task.cancel(autoFavoriteThread) autoFavoriteThread = nil end
            end
        end
    })
    
    -- Toggle Auto Unfavorite (LOGIKA YANG DIPERBAIKI)
    local toggleunfav = favsec:Toggle({
        Title = "Enable Auto Unfavorite",
        Value = false,
        Flag = "unfa",
        Callback = function(state)
            autoUnfavoriteState = state
            if state then
                if autoFavoriteState then -- Menonaktifkan Favorite jika Unfavorite ON
                    autoFavoriteState = false
                    local favToggle = automatic:GetElementByTitle("Enable Auto Favorite")
                    if favToggle and favToggle.Set then favToggle:Set(false) end
                    if autoFavoriteThread then task.cancel(autoFavoriteThread) autoFavoriteThread = nil end
                end
                
                if #selectedRarities == 0 and #selectedItemNames == 0 and #selectedMutations == 0 then
                    WindUI:Notify({ Title = "Peringatan!", Content = "Semua filter kosong. Non-aktifkan toggle ini.", Duration = 5, Icon = "alert-triangle" })
                    return false -- Batalkan aksi jika tidak ada filter
                end

                WindUI:Notify({ Title = "Auto Unfavorite ON!", Content = "Menghapus favorit item yang dipilih.", Duration = 3, Icon = "check", })
                RunAutoUnfavoriteLoop()
            else
                WindUI:Notify({ Title = "Auto Unfavorite OFF!", Duration = 3, Icon = "x", })
                if autoUnfavoriteThread then task.cancel(autoUnfavoriteThread) autoUnfavoriteThread = nil end
            end
        end
    })
    
    automatic:Divider()

    local trade = automatic:Section({ Title = "Auto Trade", TextSize = 20})

    -- Variabel Lokal Auto Trade (Diperbaiki ke Single Target)
    local autoTradeState = false
    local autoTradeThread = nil
    local tradeHoldFavorite = false
    local selectedTradeTargetId = nil
    local selectedTradeItemName = nil
    local selectedTradeRarity = nil
    local tradeDelay = 1.0
    local tradeAmount = 0

    -- Player Target Dropdown (Diperkuat)
    local PlayerList = {}
    local function GetPlayerOptions()
        local options = {}
        PlayerList = {} -- Reset mapping ID
        for _, player in ipairs(game.Players:GetPlayers()) do
            if player ~= LocalPlayer then
                table.insert(options, player.Name)
                PlayerList[player.Name] = player.UserId
            end
        end
        return options
    end

    local PlayerDropdown
    PlayerDropdown = trade:Dropdown({
        Title = "Pilih Pemain Target",
        Values = GetPlayerOptions(),
        Value = false,
        Multi = false,
        AllowNone = false,
        Callback = function(name) -- Callback menerima SATU nama (atau nil jika 'None')
            local player = game.Players:FindFirstChild(name)
            
            if player and player.UserId then
                selectedTradeTargetId = player.UserId
                WindUI:Notify({ Title = "Target Dipilih", Content = "Target set: " .. player.Name, Duration = 2, Icon = "user" })
            else
                selectedTradeTargetId = nil
            end
        end
    })

    local listplay = trade:Button({
        Title = "Refresh Player List",
        Icon = "refresh-ccw",
        Callback = function()
            
            local newOptions = GetPlayerOptions()
            
            -- 1. Perbarui nilai di dropdown dengan daftar baru
            pcall(function() PlayerDropdown:Refresh(newOptions) end) -- Gunakan pcall sebagai safety
            
            -- 2. Tunda reset tampilan agar UI sempat memproses SetValues
            task.wait(0.05)
            
            -- 3. Reset tampilan dropdown ke 'None' atau nilai default pertama jika tidak ada
            pcall(function() PlayerDropdown:Set(false) end)
            
            -- 4. Reset ID target (wajib)
            selectedTradeTargetId = nil
            
            -- 5. Berikan notifikasi yang jelas
            if #newOptions > 0 then
                WindUI:Notify({ Title = "List Diperbarui", Content = string.format("%d pemain ditemukan.", #newOptions), Duration = 2, Icon = "check" })
            else
                WindUI:Notify({ Title = "List Diperbarui", Content = "Tidak ada pemain lain di server.", Duration = 2, Icon = "check" })
            end
        end
    })
    
    automatic:Divider()
    
    -- 1. Item Auto-Populate Dropdown (SINGLE SELECT)
    local function getTradeableItemOptions()
        local itemNames = {}
        local ReplicatedStorage = game:GetService("ReplicatedStorage")
        local itemsContainer = ReplicatedStorage:FindFirstChild("Items")

        if not itemsContainer then
            return {"(Kontainer 'Items' di ReplicatedStorage Tidak Ditemukan)"}
        end

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
        
        if #itemNames == 0 then
            return {"(Kontainer 'Items' Kosong atau Semua Item '!!!')"}
        end
        
        return itemNames
    end

    local ItemNameDropdown
    ItemNameDropdown = trade:Dropdown({
        Title = "Filter Item Name",
        Values = getTradeableItemOptions(),
        Value = false,
        Multi = false,
        AllowNone = true,
        Flag = "nmtrd",
        Callback = function(name)
            selectedTradeItemName = name or nil -- Set ke nil jika "None"
        end
    })

    -- 2. Filter Rarity Dropdown (SINGLE SELECT)
    local raretrade = trade:Dropdown({
        Title = "Filter Item Rarity",
        Values = {"Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic", "SECRET", "Trophy", "Collectible", "DEV", "Default"},
        Value = false,
        Multi = false,
        AllowNone = true,
        Flag = "rartrd",
        Callback = function(rarity)
            selectedTradeRarity = rarity or nil -- Set ke nil jika "None"
        end
    })
    
    
    -- 3. Limit Trade Input (Amount)
    local InputAmount = trade:Input({
        Title = "Trade Amount (0 = Unlimited)",
        Value = tostring(tradeAmount),
        Placeholder = "0 (Unlimited)",
        Icon = "hash",
        Flag = "amtrd",
        Callback = function(input)
            local newAmount = tonumber(input)
            if newAmount == nil or newAmount < 0 then
                tradeAmount = 0
            else
                tradeAmount = math.floor(newAmount)
            end
        end
    })

    -- 4. Trade Delay Slider
    local DelaySlider = trade:Slider({
        Title = "Trade Delay (Seconds)",
        Step = 0.1,
        Value = { Min = 0.5, Max = 5.0, Default = tradeDelay },
        Flag = "tredlay",
        Callback = function(value)
            local newDelay = tonumber(value)
            if newDelay and newDelay >= 0.5 then
                tradeDelay = newDelay
            else
                tradeDelay = 1.0
            end
        end
    })


    local function GetItemsToTrade()
        local replion = GetPlayerDataReplion()
        if not replion then return {} end

        local success, inventoryData = pcall(function() return replion:GetExpect("Inventory") end)
        if not success or not inventoryData or not inventoryData.Items then return {} end

        local itemsToTrade = {}
        
        for _, item in ipairs(inventoryData.Items) do
            -- [[ LOGIKA HOLD FAVORITE ]]
            -- Jika Toggle Hold Favorite ON, dan item ini statusnya Favorite, maka SKIP.
            local isFavorited = item.IsFavorite or item.Favorited
            if tradeHoldFavorite and isFavorited then
                continue 
            end
            
            -- Cek validitas UUID
            if typeof(item.UUID) ~= "string" or item.UUID:len() < 10 then
                continue -- SKIP jika UUID tidak valid
            end
            
            local name, rarity = GetFishNameAndRarity(item)
            
            -- Menghandle item tanpa rarity (set ke "Default" untuk difilter)
            local itemRarity = (rarity and rarity:upper() ~= "COMMON") and rarity or "Default"
            
            -- 1. Cek Filter Rarity: TRUE jika filter NIL atau jika rarity item MATCH
            local passesRarity = not selectedTradeRarity or
                                     (selectedTradeRarity and itemRarity:upper() == selectedTradeRarity:upper())
            
            -- 2. Cek Filter Name: TRUE jika filter NIL atau jika name item MATCH
            local passesName = not selectedTradeItemName or
                                     (name == selectedTradeItemName)
            
            if passesRarity and passesName then
                -- Masukkan item ke daftar trade
                table.insert(itemsToTrade, { UUID = item.UUID, Name = name, Rarity = rarity, Identifier = item.Identifier })
            end
        end
        return itemsToTrade
    end

    -- LOGIC LOOP UTAMA: Run Auto Trade (MENGGUNAKAN SINGLE TARGET ID)
    local function RunAutoTradeLoop()
        if autoTradeThread then task.cancel(autoTradeThread) end
        
        autoTradeThread = task.spawn(function()
            local tradeCount = 0
            local targetId = selectedTradeTargetId -- Menggunakan ID target tunggal
            
            if not targetId or typeof(targetId) ~= "number" then
                WindUI:Notify({ Title = "Trade Gagal", Content = "Pilih Target valid (refresh list jika perlu).", Duration = 5, Icon = "x" })
                local toggle = automatic:GetElementByTitle("Enable Auto Trade")
                if toggle and toggle.Set then toggle:Set(false) end
                return
            end

            local RF_InitiateTrade_Local = GetRemote(RPath, "RF/InitiateTrade", 5)
            if not RF_InitiateTrade_Local then
                WindUI:Notify({ Title = "Trade Gagal", Content = "RF/InitiateTrade remote function tidak ditemukan.", Duration = 5, Icon = "x" })
                local toggle = automatic:GetElementByTitle("Enable Auto Trade")
                if toggle and toggle.Set then toggle:Set(false) end
                return
            end

            WindUI:Notify({ Title = "Auto Trade ON", Content = "Mulai Trade Otomatis ke ID: " .. targetId, Duration = 2, Icon = "zap" })

            while autoTradeState do
                local itemsToTrade = GetItemsToTrade()
                
                if #itemsToTrade > 0 then
                    local itemToTrade = itemsToTrade[1]
                    
                    if tradeAmount > 0 and tradeCount >= tradeAmount then
                        WindUI:Notify({ Title = "Limit Tercapai", Content = string.format("Batas trade (%d) tercapai.", tradeAmount), Duration = 5, Icon = "stop-circle" })
                        local toggle = automatic:GetElementByTitle("Enable Auto Trade")
                        if toggle and toggle.Set then toggle:Set(false) end
                        break
                    end

                    pcall(function()
                        -- Argumen 1: TargetId (NUMBER), Argumen 2: ItemUUID (STRING)
                        RF_InitiateTrade_Local:InvokeServer(targetId, itemToTrade.UUID)
                    end)
                    
                    tradeCount = tradeCount + 1
                    WindUI:Notify({
                        Title = "Trading...",
                        Content = string.format("Trade #%d: %s (%s) ke ID %d", tradeCount, itemToTrade.Name, itemToTrade.Rarity, targetId),
                        Duration = 0.5,
                        Icon = "repeat"
                    })
                    
                    task.wait(tradeDelay)
                else
                    -- Jika tidak ada item yang memenuhi kriteria, tunggu sebentar sebelum cek lagi
                    task.wait(2)
                end
            end
            
            WindUI:Notify({ Title = "Auto Trade Berhenti", Content = "Trade Otomatis dihentikan.", Duration = 3, Icon = "x" })
        end)
    end
    
    local togglehold = trade:Toggle({
        Title = "Hold Favorite Items",
        Desc = "Jika ON, item yang di-Favorite tidak akan ikut di-trade.",
        Value = false,
        Flag = "tholdfav",
        Callback = function(state)
            tradeHoldFavorite = state
            if state then
                WindUI:Notify({ Title = "Safe Mode", Content = "Item Favorite aman dari Auto Trade.", Duration = 2, Icon = "lock" })
            else
                WindUI:Notify({ Title = "Warning", Content = "Item Favorite bisa ikut ter-trade!", Duration = 2, Icon = "alert-triangle" })
            end
        end
    })

    -- UI Toggle Auto Trade
    local autotrd = trade:Toggle({
        Title = "Enable Auto Trade",
        Icon = "arrow-right-left",
        Value = false,
        Flag = "ttrade",
        Callback = function(state)
            autoTradeState = state
            if state then
                if not selectedTradeTargetId or typeof(selectedTradeTargetId) ~= "number" then
                    WindUI:Notify({ Title = "Error", Content = "Pilih pemain target yang valid terlebih dahulu!", Duration = 3, Icon = "alert-triangle" })
                    return false
                end
                RunAutoTradeLoop()
            else
                if autoTradeThread then task.cancel(autoTradeThread) autoTradeThread = nil end
            end
        end
    })


    -- UI Toggle Auto Accept Trade
    local accept = trade:Toggle({
        Title = "Enable Auto Accept Trade",
        Icon = "arrow-right-left",
        Value = false,
        Flag = "tatrade",
        Callback = function(state)
            _G.RockHub_AutoAcceptTradeEnabled = state
            
            if state then
                WindUI:Notify({
                    Title = "Auto Accept Trade ON! ✅",
                    Content = "Menerima semua permintaan trade secara otomatis.",
                    Duration = 3,
                    Icon = "check"
                })
            else
                WindUI:Notify({
                    Title = "Auto Accept Trade OFF! ❌",
                    Content = "Menerima trade secara manual.",
                    Duration = 3,
                    Icon = "x"
                })
            end
        end
    })


    local enchant = automatic:Section({ Title = "Auto Enchant Rod", TextSize = 20,})
    
    local RodDropdown = enchant:Dropdown({
        Title = "Select Rod From Inventory",
        Values = GetRodOptions(), -- Panggil fungsi untuk mengisi Rods
        Multi = false,
        AllowNone = true,
        Callback = function(name)
            selectedRodUUID = GetUUIDFromFormattedName(name)
            if selectedRodUUID then
                WindUI:Notify({ Title = "Rod Dipilih", Content = "UUID Rod disiapkan untuk enchant.", Duration = 2, Icon = "tool" })
            end
        end
    })
    
    -- Tombol untuk Refresh Rod List
    local rodlist = enchant:Button({
        Title = "Refresh Rod List",
        Icon = "refresh-ccw",
        Callback = function()
            local newOptions = GetRodOptions()
            pcall(function() RodDropdown:Refresh(newOptions) end)
            task.wait(0.1)
            pcall(function() RodDropdown:Set(false) end)
            selectedRodUUID = nil
            
            WindUI:Notify({ 
                Title = "Daftar Rod Diperbarui", 
                Content = string.format("%d Rods ditemukan. Pilih target baru.", #newOptions), 
                Duration = 2, 
                Icon = "check" 
            })
        end 
    })

    -- Dropdown untuk memilih Enchant Target
    local dropenchant = enchant:Dropdown({
        Title = "Enchant To Apply (stop when reached)",
        Desc = "Pilih enchant yang diinginkan. Auto-roll akan berhenti jika salah satu enchant ini didapat.",
        Values = ENCHANT_NAMES,
        Multi = true,
        AllowNone = false,
        Flag = "dchant", -- Wajib pilih minimal satu target
        Callback = function(names)
            selectedEnchantNames = names or {}
        end
    })

    -- Toggle Auto Enchant
    local autoenc = enchant:Toggle({
        Title = "Enable Auto Enchant",
        Value = false,
        Flag = "Tchant",
        Callback = function(state)
            autoEnchantState = state
            if state then
                if not selectedRodUUID then
                    WindUI:Notify({ Title = "Error", Content = "Pilih Rod target terlebih dahulu.", Duration = 3, Icon = "alert-triangle" })
                    return false
                end
                if #selectedEnchantNames == 0 then
                    WindUI:Notify({ Title = "Error", Content = "Pilih minimal satu Enchant target.", Duration = 3, Icon = "alert-triangle" })
                    return false
                end
                
                -- Stone akan dicari di dalam loop RunAutoEnchantLoop
                RunAutoEnchantLoop(selectedRodUUID)
            else
                if autoEnchantThread then task.cancel(autoEnchantThread) autoEnchantThread = nil end
                WindUI:Notify({ Title = "Auto Enchant OFF!", Duration = 3, Icon = "x",})
            end
        end
    })

-- =================================================================
    -- 🔮 AUTO SECOND ENCHANT & STONE CREATION
    -- =================================================================
    automatic:Divider()
    --local enchant2 = automatic:Section({ Title = "Second Enchant Rod", TextSize = 20})

    -- --- VARIABLES ---
    local makeStoneState = false
    local makeStoneThread = nil
    local secondEnchantState = false
    local secondEnchantThread = nil
    
    local selectedSecretFishUUIDs = {} -- List UUID ikan secret yang dipilih
    local targetStoneAmount = 1 -- Default jumlah batu yang mau dibuat
    
    local TRANSCENDED_STONE_ID = 246
    local SECOND_ALTAR_POS = FishingAreas["Second Enchant Altar"].Pos
    local SECOND_ALTAR_LOOK = FishingAreas["Second Enchant Altar"].Look

    -- Remote Definitions (Lokal untuk section ini)
    local RF_CreateTranscendedStone = GetRemote(RPath, "RF/CreateTranscendedStone")
    local RE_ActivateSecondEnchantingAltar = GetRemote(RPath, "RE/ActivateSecondEnchantingAltar")
    local RE_EquipItem = GetRemote(RPath, "RE/EquipItem")
    local RE_EquipToolFromHotbar = GetRemote(RPath, "RE/EquipToolFromHotbar")

    -- --- HELPER: GET SECRET FISH (FIXED DETECTION) ---
    local function GetSecretFishOptions()
        local options = {}
        local uuidMap = {} -- Mapping Nama -> UUID untuk diproses nanti
        
        local replion = GetPlayerDataReplion()
        if not replion then return {}, {} end

        local success, inventoryData = pcall(function() return replion:GetExpect("Inventory") end)
        if not success or not inventoryData or not inventoryData.Items then return {}, {} end

        for _, item in ipairs(inventoryData.Items) do
            -- PERBAIKAN 1: Deteksi Ikan berdasarkan 'Weight' (Sama seperti Scan Backpack)
            -- Karena semua ikan hasil tangkapan pasti punya Metadata Weight
            local hasWeight = item.Metadata and item.Metadata.Weight
            
            -- Fallback: Cek tipe jika weight tidak terbaca
            local isFishType = item.Type == "Fish" or (item.Identifier and tostring(item.Identifier):lower():find("fish"))
            
            if not hasWeight and not isFishType then continue end

            -- PERBAIKAN 2: Ambil Rarity dan paksa Uppercase agar "Secret" == "SECRET"
            local _, rarity = GetFishNameAndRarity(item)
            
            if not rarity or rarity:upper() ~= "SECRET" then continue end

            -- Ambil Nama yang lebih akurat (Dari ItemUtility jika ada)
            local name = item.Identifier or "Unknown"
            if ItemUtility then
                local itemData = ItemUtility:GetItemData(item.Id)
                if itemData and itemData.Data and itemData.Data.Name then
                    name = itemData.Data.Name
                end
            end

            if item.Metadata and item.Metadata.Weight then
                name = string.format("%s (%.1fkg)", name, item.Metadata.Weight)
            end
            
            -- Tambahkan penanda jika Favorite
            if item.IsFavorite or item.Favorited then
                name = name .. " [⭐]"
            end

            table.insert(options, name)
            uuidMap[name] = item.UUID
        end
        
        table.sort(options) -- Urutkan abjad biar rapi
        return options, uuidMap
    end

    local secretFishOptions, secretFishUUIDMap = GetSecretFishOptions()

    -- --- HELPER: CEK ENCHANT ID 2 (KHUSUS SECOND ENCHANT) ---
    local function CheckIfSecondEnchantReached(rodUUID)
        local replion = GetPlayerDataReplion()
        local Rods = replion:GetExpect("Inventory")["Fishing Rods"] or {}
        
        local targetRod = nil
        for _, rod in ipairs(Rods) do
            if rod.UUID == rodUUID then
                targetRod = rod
                break
            end
        end

        if not targetRod then return true end -- Stop jika rod hilang
        
        local metadata = targetRod.Metadata or {}
        
        -- PENTING: Cek EnchantId2 (Slot kedua)
        local currentEnchant2 = metadata.EnchantId2
        
        if not currentEnchant2 then return false end -- Belum ada enchant ke-2

        -- Cek apakah enchant ke-2 sesuai target
        for _, targetName in ipairs(selectedEnchantNames) do
            local targetID = ENCHANT_MAPPING[targetName]
            if targetID and currentEnchant2 == targetID then
                return true -- Berhenti: Enchant target tercapai di slot 2
            end
        end

        return false
    end

    -- --- HELPER: CARI TRANSCENDED STONE (ID 246) ---
    local function GetTranscendedStoneUUID()
        local replion = GetPlayerDataReplion()
        if not replion then return nil end
        local inventoryData = replion:GetExpect("Inventory")
        
        if inventoryData and inventoryData.Items then
            for _, item in ipairs(inventoryData.Items) do
                if tonumber(item.Id) == TRANSCENDED_STONE_ID and item.UUID then
                    return item.UUID
                end
            end
        end
        return nil
    end

    -- --- LOGIC 1: MAKE TRANSCENDED STONE ---
    local function RunMakeStoneLoop()
        if makeStoneThread then task.cancel(makeStoneThread) end

        makeStoneThread = task.spawn(function()
            local createdCount = 0
            
            -- 1. Teleport ke Altar dulu biar aman
            TeleportToLookAt(SECOND_ALTAR_POS, SECOND_ALTAR_LOOK)
            task.wait(1)

            while makeStoneState and createdCount < targetStoneAmount do
                -- Ambil list baru (jika ada perubahan inventory)
                local _, currentMap = GetSecretFishOptions()
                local fishToSacrifice = nil
                
                -- Cari ikan pertama yang cocok dengan seleksi user
                for name, uuid in pairs(currentMap) do
                    -- Cek apakah nama ini ada di daftar yang dipilih user (selectedSecretFishUUIDs menyimpan Nama di dropdown logic ini)
                    if table.find(selectedSecretFishUUIDs, name) then
                        fishToSacrifice = uuid
                        break
                    end
                end

                if not fishToSacrifice then
                    WindUI:Notify({ Title = "Selesai / Habis", Content = "Tidak ada ikan target tersisa.", Duration = 5, Icon = "check" })
                    break
                end

                -- Proses Pembuatan
                WindUI:Notify({ Title = "Sacrificing...", Content = "Memproses ikan...", Duration = 1, Icon = "refresh-cw" })

                -- 1. Unequip Semua
                UnequipAllEquippedItems()
                task.wait(0.3)

                -- 2. Equip Ikan
                pcall(function() 
                    RE_EquipItem:FireServer(fishToSacrifice, "Fish") 
                end)
                task.wait(0.5)

                -- 3. Equip ke Hotbar (Slot 2 sesuai request)
                pcall(function() 
                    RE_EquipToolFromHotbar:FireServer(2) 
                end)
                task.wait(0.8) -- Tunggu animasi equip

                -- 4. Create Stone
                local success = pcall(function() 
                    RF_CreateTranscendedStone:InvokeServer() 
                end)

                if success then
                    createdCount = createdCount + 1
                    WindUI:Notify({ Title = "Stone Created!", Content = string.format("Total: %d / %d", createdCount, targetStoneAmount), Duration = 2, Icon = "gem" })
                else
                    WindUI:Notify({ Title = "Gagal", Content = "Gagal membuat batu (Mungkin bukan secret?).", Duration = 2, Icon = "x" })
                end

                task.wait(1.5) -- Cooldown antar pembuatan
            end

            makeStoneState = false
            local toggle = automatic:GetElementByTitle("Start Make Stones")
            if toggle and toggle.Set then toggle:Set(false) end
            
            -- Unequip tool terakhir
            pcall(function() RE_EquipToolFromHotbar:FireServer(0) end)
        end)
    end

    -- --- LOGIC 2: SECOND ENCHANT LOOP ---
    local function RunSecondEnchantLoop(rodUUID)
        if secondEnchantThread then task.cancel(secondEnchantThread) end

        secondEnchantThread = task.spawn(function()
            -- 1. Unequip Awal
            UnequipAllEquippedItems()
            task.wait(0.5)

            -- 2. Teleport ke Second Altar
            TeleportToLookAt(SECOND_ALTAR_POS, SECOND_ALTAR_LOOK)
            task.wait(1.5)

            WindUI:Notify({ Title = "2nd Enchant Started", Content = "Rolling Slot 2...", Duration = 2, Icon = "sparkles" })

            while secondEnchantState do
                -- 3. Cek Enchant Slot 2
                if CheckIfSecondEnchantReached(rodUUID) then
                    WindUI:Notify({ Title = "GG!", Content = "Enchant ke-2 didapatkan!", Duration = 5, Icon = "check" })
                    break
                end

                -- 4. Cari Transcended Stone (ID 246)
                local stoneUUID = GetTranscendedStoneUUID()
                if not stoneUUID then
                    WindUI:Notify({ Title = "Stone Habis!", Content = "Butuh Transcended Stone", Duration = 5, Icon = "stop-circle" })
                    break
                end

                -- === ALUR ENCHANT ===
                
                -- 5. Equip Rod
                pcall(function() RE_EquipItem:FireServer(rodUUID, "Fishing Rods") end)
                task.wait(0.2)

                -- 6. Equip Transcended Stone
                pcall(function() RE_EquipItem:FireServer(stoneUUID, "Enchant Stones") end)
                task.wait(0.2)

                -- 7. Equip Stone ke Hotbar (Slot 2)
                pcall(function() RE_EquipToolFromHotbar:FireServer(2) end)
                task.wait(0.3)

                -- 8. Activate Second Altar
                pcall(function() RE_ActivateSecondEnchantingAltar:FireServer() end)

                -- 9. Tunggu (Trade Delay)
                task.wait(tradeDelay)

                -- 10. Unequip
                pcall(function() RE_EquipToolFromHotbar:FireServer(0) end)
                task.wait(0.5)
            end

            secondEnchantState = false
            local toggle = automatic:GetElementByTitle("Start Second Enchant")
            if toggle and toggle.Set then toggle:Set(false) end
        end)
    end


    -- --- UI COMPONENTS ---

    -- A. BAGIAN MAKE STONE
    --local SecretFishDropdown = enchant2:Dropdown({
      --  Title = "Select Secret Fish (Sacrifice)",
      --  Desc = "Pilih ikan SECRET untuk dijadikan Transcended Stone.",
      --  Values = secretFishOptions,
      --  Multi = true,
       -- AllowNone = true,
      --  Flag = "dsecretfish",
      --  Callback = function(values)
            -- Di sini kita simpan Namanya saja, nanti di loop kita cocokan Nama -> UUID map terbaru
            -- karena UUID bisa berubah/item bisa hilang setelah sacrifice
      --      selectedSecretFishUUIDs = values or {} 
      --  end
    --})

   -- local butfish = enchant2:Button({
      --  Title = "Refresh Secret Fish List",
       -- Icon = "refresh-ccw",
      --  Callback = function()
        --    local newOptions, newMap = GetSecretFishOptions()
        --    secretFishUUIDMap = newMap -- Update map global
          --  pcall(function() SecretFishDropdown:Refresh(newOptions) end)
          --  pcall(function() SecretFishDropdown:Set(false) end)
          --  selectedSecretFishUUIDs = {}
          --  WindUI:Notify({ Title = "Refreshed", Content = #newOptions .. " ikan secret ditemukan.", Duration = 2, Icon = "check" })
       -- end
   -- })

    --local amountmake = enchant2:Input({
      --  Title = "Amount to Make",
      --  Desc = "Berapa banyak batu yang ingin dibuat?",
      --  Value = "1",
      --  Placeholder = "1",
      --  Icon = "hash",
       -- Flag = "iamountstone",
       -- Callback = function(input)
      --      targetStoneAmount = tonumber(input) or 1
      --  end
    --})

    --local togglestone = enchant2:Toggle({
     --   Title = "Start Make Stones",
      --  Desc = "Otomatis ubah ikan terpilih menjadi Transcended Stone.",
       -- Value = false,
       -- Flag = "tmakestone",
      --  Callback = function(state)
       --     makeStoneState = state
      --      if state then
      --          if #selectedSecretFishUUIDs == 0 then
       --             WindUI:Notify({ Title = "Error", Content = "Pilih minimal 1 jenis ikan secret.", Duration = 3, Icon = "alert-triangle" })
       --             return false
        --        end
         --       RunMakeStoneLoop()
          --  else
           --     if makeStoneThread then task.cancel(makeStoneThread) end
         --       WindUI:Notify({ Title = "Stopped", Duration = 2, Icon = "x" })
        ---    end
       -- end
    --})

    --automatic:Divider()
    
    --local SecondRodDropdown = enchant2:Dropdown({
      --  Title = "Select Rod for 2nd Enchant",
      --  Values = GetRodOptions(),
       -- Multi = false,
       -- AllowNone = true,
      --  Flag = "drod2",
      --  Callback = function(name)
       --     selectedRodUUID = GetUUIDFromFormattedName(name)
       --     if selectedRodUUID then
        --         WindUI:Notify({ Title = "Rod Selected", Content = "Target ID disimpan.", Duration = 1.5, Icon = "check" })
        --    end
       -- end
    --})
    
   -- local rodlist2 = enchant2:Button({
    --    Title = "Refresh Rod List",
    --    Icon = "refresh-ccw",
    --    Callback = function()
    --         local newOptions = GetRodOptions()
     --        pcall(function() SecondRodDropdown:Refresh(newOptions) end)
      --  end
   -- })

   -- local targetenchant2 = enchant2:Dropdown({
      --  Title = "Target 2nd Enchant",
       -- Desc = "Pilih enchant yang diinginkan di slot ke-2.",
      --  Values = ENCHANT_NAMES,
      --  Multi = true,
       -- AllowNone = false,
       -- Flag = "dchant2",
       -- Callback = function(names)
       --     selectedEnchantNames = names or {}
       -- end
    --})

    --local start2ndenchant = enchant2:Toggle({
       -- Title = "Start Second Enchant",
      --  Desc = "Auto roll slot ke-2 menggunakan Transcended Stone.",
      --  Value = false,
     --   Flag = "tsecondenchant",
      --  Callback = function(state)
      --      secondEnchantState = state
       --     if state then
       --         if not selectedRodUUID then
        --            WindUI:Notify({ Title = "Error", Content = "Pilih Rod terlebih dahulu.", Duration = 3, Icon = "alert-triangle" })
          --          return false
           --     end
           --     if #selectedEnchantNames == 0 then
           --         WindUI:Notify({ Title = "Error", Content = "Pilih target enchant.", Duration = 3, Icon = "alert-triangle" })
          --          return false
           --     end
           --     RunSecondEnchantLoop(selectedRodUUID)
           -- else
          --      if secondEnchantThread then task.cancel(secondEnchantThread) end
           --     WindUI:Notify({ Title = "Stopped", Duration = 2, Icon = "x" })
          --  end
       -- end
    --})
    
end

do
    local teleport = Window:Tab({
        Title = "Teleport",
        Icon = "map-pin",
        Locked = false,
        
    })

    local selectedTargetPlayer = nil -- Nama pemain yang dipilih
    local selectedTargetArea = nil -- Nama area yang dipilih

    -- Helper: Mengambil daftar pemain yang sedang di server (diambil dari kode Automatic)
    local function GetPlayerListOptions()
        local options = {}
        for _, player in ipairs(game.Players:GetPlayers()) do
            if player ~= LocalPlayer then
                table.insert(options, player.Name)
            end
        end
        return options
    end

    -- Helper: Mendapatkan HRP target
    local function GetTargetHRP(playerName)
        local targetPlayer = game.Players:FindFirstChild(playerName)
        local character = targetPlayer and targetPlayer.Character
        if character then
            return character:FindFirstChild("HumanoidRootPart")
        end
        return nil
    end


    -- =================================================================
    -- A. TELEPORT KE PEMAIN (Button)
    -- =================================================================
    local teleplay = teleport:Section({
        Title = "Teleport to Player",
        TextSize = 20,
    })

    local PlayerDropdown = teleplay:Dropdown({
        Title = "Select Target Player",
        Values = GetPlayerListOptions(),
        AllowNone = true,
        Callback = function(name)
            selectedTargetPlayer = name
        end
    })

    local listplaytel = teleplay:Button({
        Title = "Refresh Player List",
        Icon = "refresh-ccw",
        Callback = function()
            local newOptions = GetPlayerListOptions()
            pcall(function() PlayerDropdown:Refresh(newOptions) end)
            task.wait(0.1)
            pcall(function() PlayerDropdown:Set(false) end)
            selectedTargetPlayer = nil
            WindUI:Notify({ Title = "List Diperbarui", Content = string.format("%d pemain ditemukan.", #newOptions), Duration = 2, Icon = "check" })
        end
    })

    local teletoplay = teleplay:Button({
        Title = "Teleport to Player (One-Time)",
        Content = "Teleport satu kali ke lokasi pemain yang dipilih.",
        Icon = "corner-down-right",
        Callback = function()
            local hrp = GetHRP()
            local targetHRP = GetTargetHRP(selectedTargetPlayer)
            
            if not selectedTargetPlayer then
                WindUI:Notify({ Title = "Error", Content = "Pilih pemain target terlebih dahulu.", Duration = 3, Icon = "alert-triangle" })
                return
            end

            if hrp and targetHRP then
                -- Teleport 5 unit di atas target
                local targetPos = targetHRP.Position + Vector3.new(0, 5, 0)
                local lookVector = (targetHRP.Position - hrp.Position).Unit 
                
                hrp.CFrame = CFrame.new(targetPos, targetPos + lookVector)
                
                WindUI:Notify({ Title = "Teleport Sukses", Content = "Teleported ke " .. selectedTargetPlayer, Duration = 3, Icon = "user-check" })
            else
                 WindUI:Notify({ Title = "Error", Content = "Gagal menemukan target atau karakter Anda.", Duration = 3, Icon = "x" })
            end
        end
    })
    
    teleport:Divider()

    -- =================================================================
    -- B. TELEPORT KE AREA (Button)
    -- =================================================================
    
    local telearea = teleport:Section({
        Title = "Teleport to Fishing Area",
        TextSize = 20,
    })

    local AreaDropdown = telearea:Dropdown({
        Title = "Select Target Area",
        Values = AreaNames, -- Menggunakan variabel AreaNames dari Fishing Tab
        AllowNone = true,
        Callback = function(name)
            selectedTargetArea = name
        end
    })

    local butelearea = telearea:Button({
        Title = "Teleport to Area (One-Time)",
        Content = "Teleport satu kali ke area yang dipilih.",
        Icon = "corner-down-right",
        Callback = function()
            if not selectedTargetArea or not FishingAreas[selectedTargetArea] then
                WindUI:Notify({ Title = "Error", Content = "Pilih area target terlebih dahulu.", Duration = 3, Icon = "alert-triangle" })
                return
            end
            
            local areaData = FishingAreas[selectedTargetArea]
            
            TeleportToLookAt(areaData.Pos, areaData.Look)
            WindUI:Notify({ Title = "Teleport Sukses", Content = "Teleported ke " .. selectedTargetArea, Duration = 3, Icon = "map" })
        end
    })

    teleport:Divider()

    local televent = teleport:Section({
        Title = "Auto Teleport Event",
        TextSize = 20,
    })

    local dropvent = televent:Dropdown({
        Title = "Select Target Event",
        Content = "Pilih event yang ingin di-monitor secara otomatis.",
        Values = eventsList,
        AllowNone = true,
        Value = false,
        Flag = "devent",
        Callback = function(option)
            autoEventTargetName = option -- Simpan nama event sebagai target
            if autoEventTeleportState then
                 -- Force stop auto-teleport jika target diubah saat sedang aktif
                 autoEventTeleportState = false
                 if autoEventTeleportThread then task.cancel(autoEventTeleportThread) autoEventTeleportThread = nil end
                 Window:GetElementByTitle("Enable Auto Event Teleport"):Set(false)
            end
        end
    })

    local tovent = televent:Button({
        Title = "Teleport to Chosen Event (Once)",
        Icon = "corner-down-right",
        Callback = function()
            if not autoEventTargetName then
                WindUI:Notify({ Title = "Error", Content = "Pilih event dulu di dropdown!", Duration = 3, Icon = "alert-triangle" })
                return
            end
            
            WindUI:Notify({ Title = "Searching...", Content = "Mencari keberadaan event...", Duration = 2, Icon = "search" })
            
            local found = FindAndTeleportToTargetEvent()
            if not found then
                WindUI:Notify({ Title = "Gagal", Content = "Event tidak ditemukan / belum spawn.", Duration = 3, Icon = "x" })
            end
        end
    })


    local togventel = televent:Toggle({
        Title = "Enable Auto Event Teleport",
        Content = "Secara otomatis mencari dan teleport ke event yang dipilih.",
        Value = false,
        Flag = "tpevent",
        Callback = function(state)
            if not autoEventTargetName then
                 WindUI:Notify({ Title = "Error", Content = "Pilih Event Target terlebih dahulu di dropdown.", Duration = 3, Icon = "alert-triangle" })
                 return false
            end
            
            autoEventTeleportState = state
            if state then
                RunAutoEventTeleportLoop()
            else
                if autoEventTeleportThread then task.cancel(autoEventTeleportThread) autoEventTeleportThread = nil end
                WindUI:Notify({ Title = "Auto Event TP OFF", Duration = 3, Icon = "x" })
            end
        end
    })
    
end

do
    local shop = Window:Tab({
        Title = "Shop",
        Icon = "shopping-bag",
        Locked = false,
    })

    -- === DEFINISI FUNGSI NOTIFIKASI LOKAL UNTUK MENGAKSES WindUI:Notify ===
    -- Ditinggalkan agar lebih bersih, menggunakan WindUI:Notify() secara langsung

    -- Variabel Tracking Tombol Dinamis
    local MerchantButtons = {}
    
    -- VARIABEL LOKAL DAN FUNGSI HELPER
    local MerchantReplion = nil
    local UpdateCleanupFunction = nil
    local MainDisplayElement = nil
    local UpdateThread = nil
    
    -- Variabel Auto Buy Merchant Statis & Dinamis
    local selectedStaticItemName = nil
    local autoBuySelectedState = false
    local autoBuyStockState = false
    local autoBuyThread = nil

    -- FUNGSI HELPER: Format Angka
    local function FormatNumber(n)
        if n >= 1000000000 then return string.format("%.1fB", n / 1000000000)
        elseif n >= 1000000 then return string.format("%.1fM", n / 1000000)
        elseif n >= 1000 then return string.format("%.1fK", n / 1000)
        else return tostring(n) end
    end

    -- Data Item Shop & Merchant Item STATIS (CLEANED)
    local ShopItems = {
        ["Rods"] = {
            {Name = "Luck Rod", ID = 70, Price = 325}, {Name = "Carbon Rod", ID = 76, Price = 750},
            {Name = "Grass Rod", ID = 85, Price = 1500}, {Name = "Demascus Rod", ID = 77, Price = 3000},
            {Name = "Ice Rod", ID = 78, Price = 5000}, {Name = "Lucky Rod", ID = 4, Price = 15000},
            {Name = "Midnight Rod", ID = 80, Price = 50000}, {Name = "Steampunk Rod", ID = 6, Price = 215000},
            {Name = "Chrome Rod", ID = 7, Price = 437000}, {Name = "Flourescent Rod", ID = 255, Price = 715000},
            {Name = "Astral Rod", ID = 5, Price = 1000000}, {Name = "Ares Rod", ID = 126, Price = 3000000},
            {Name = "Angler Rod", ID = 168, Price = 8000000},
        },
        ["Bobbers"] = {
            {Name = "Floral Bait", ID = 20, Price = 4000000}, {Name = "Aether Bait", ID = 16, Price = 3700000},
            {Name = "Corrupt Bait", ID = 15, Price = 1148484}, {Name = "Dark Matter Bait", ID = 8, Price = 630000},
            {Name = "Chroma Bait", ID = 6, Price = 290000}, {Name = "Nature Bait", ID = 17, Price = 83500},
            {Name = "Midnight Bait", ID = 3, Price = 3000}, {Name = "Luck Bait", ID = 2, Price = 1000},
            {Name = "Topwater Bait", ID = 10, Price = 100},
        },
        ["Boats"] = {
            {Name = "Mini Yach", ID = 14, Price = 1200000}, {Name = "Fish Boat", ID = 6, Price = 180000},
            {Name = "Speed Boat", ID = 5, Price = 70000}, {Name = "Highfield Boat", ID = 4, Price = 25000},
            {Name = "Jetski", ID = 3, Price = 7500}, {Name = "Kayak", ID = 2, Price = 1100},
            {Name = "Small Boat", ID = 1, Price = 100},
        },
    }

    local MerchantStaticItems = {
        {Name = "Fluorescent Rod", ID = 1, Identifier = "Fluorescent Rod", Price = 685000},
        {Name = "Hazmat Rod", ID = 2, Identifier = "Hazmat Rod", Price = 1380000},
        {Name = "Singularity Bait", ID = 3, Identifier = "Singularity Bait", Price = 8200000},
        {Name = "Royal Bait", ID = 4, Identifier = "Royal Bait", Price = 425000},
        {Name = "Luck Totem", ID = 5, Identifier = "Luck Totem", Price = 650000},
        {Name = "Shiny Totem", ID = 7, Identifier = "Shiny Totem", Price = 400000},
        {Name = "Mutation Totem", ID = 8, Identifier = "Mutation Totem", Price = 800000}
    }
    
    local selectedRodName = ShopItems["Rods"][1].Name
    local selectedBobberName = ShopItems["Bobbers"][1].Name
    local selectedBoatName = ShopItems["Boats"][1].Name

    -- Remote Functions & Data (diambil dari Global Scope)
    local RF_PurchaseBait = GetRemote(RPath, "RF/PurchaseBait", 5)
    local RF_PurchaseFishingRod = GetRemote(RPath, "RF/PurchaseFishingRod", 5)
    local RF_PurchaseBoat = GetRemote(RPath, "RF/PurchaseBoat", 5)
    local RF_PurchaseMarketItem = GetRemote(RPath, "RF/PurchaseMarketItem", 5)
    -- REMOTE KHUSUS UNTUK WEATHER
    local RF_PurchaseWeatherEvent = GetRemote(RPath, "RF/PurchaseWeatherEvent", 5)
    
    local ShopRemotes = {
        ["Rods"] = RF_PurchaseFishingRod, ["Bobbers"] = RF_PurchaseBait, ["Boats"] = RF_PurchaseBoat,
    }

    -- FUNGSI UNTUK DROPDOWN STATIS (CLEANED)
    local function GetStaticMerchantOptions()
        local options = {}
        for _, item in ipairs(MerchantStaticItems) do
            local formattedPrice = FormatNumber(item.Price)
            -- HANYA MENAMPILKAN HARGA TANPA JENIS MATA UANG
            table.insert(options, string.format("%s (%s)", item.Name, formattedPrice))
        end
        return options
    end

    -- (Fungsi Helper lainnya)
    local function GetStaticMerchantItemID(dropdownValue)
        for _, item in ipairs(MerchantStaticItems) do
            if dropdownValue:match("^" .. item.Name:gsub("%%", "%%%%") .. " ") then
                return item.ID, item.Name
            end
        end
        return nil, nil
    end

    local function getDropdownOptions(itemType)
        local options = {}
        for _, item in ipairs(ShopItems[itemType]) do
            local formattedPrice = FormatNumber(item.Price)
            table.insert(options, string.format("%s (%s)", item.Name, formattedPrice))
        end
        return options
    end
    local function getItemID(itemType, dropdownValue)
        local itemName = dropdownValue:match("^([^%s]+%s[^%s]+)")
        if not itemName then itemName = dropdownValue:match("^[^%s]+") end
        for _, item in ipairs(ShopItems[itemType]) do
            if item.Name == itemName then return item.ID end
        end
        return nil
    end
    local function handlePurchase(itemType, selectedValue)
        local itemID = getItemID(itemType, selectedValue)
        local remote = ShopRemotes[itemType]
        if not remote or not itemID then
            WindUI:Notify({ Title = "Purchase Error",Duration = 4, Icon = "x", })
            return
        end
        pcall(function() remote:InvokeServer(itemID) end)
        WindUI:Notify({ Title = "Purchase Attempted!", Duration = 3, Icon = "check", })
    end
    
    local function GetReplions()
        if MerchantReplion then return true end
        local ReplionModule = RepStorage:WaitForChild("Packages"):WaitForChild("Replion", 10)
        if not ReplionModule then return false end
        local ReplionClient = require(ReplionModule).Client
        MerchantReplion = ReplionClient:WaitReplion("Merchant", 5)
        return MerchantReplion
    end

    local function getNextRefreshTimeString()
        local serverTime = workspace:GetServerTimeNow()
        local secondsInDay = 86400
        local nextRefreshTime = (math.floor(serverTime / secondsInDay) + 1) * secondsInDay
        local timeRemaining = math.max(nextRefreshTime - serverTime, 0)
        local h = math.floor(timeRemaining / 3600)
        local m = math.floor((timeRemaining % 3600) / 60)
        local s = math.floor(timeRemaining % 60)
        local timeString = string.format("Next Refresh: %dH, %dM, %dS", h, m, s)
        return timeString
    end
    
    -- FUNGSI UNTUK MENDAPATKAN DETAIL ITEM LENGKAP
    local function GetMerchantStockDetails(merchantData)
        local itemDetails = {}
        local MarketItemData = RepStorage:WaitForChild("Shared"):WaitForChild("MarketItemData", 0.1) and require(RepStorage.Shared.MarketItemData)
        
        if merchantData and merchantData.Items and type(merchantData.Items) == "table" and MarketItemData and ItemUtility then
            for _, itemID in ipairs(merchantData.Items) do
                local marketData = nil
                for _, data in ipairs(MarketItemData) do
                    if data.Id == itemID then marketData = data; break end
                end

                if marketData and not marketData.SkinCrate and marketData.Price and marketData.Currency then
                    local itemDetail = nil
                    pcall(function() itemDetail = ItemUtility:GetItemDataFromItemType(marketData.Type, marketData.Identifier) end)
                    
                    local name = (itemDetail and itemDetail.Data and itemDetail.Data.Name) or marketData.Identifier or "Unknown Item"
                    
                    table.insert(itemDetails, {
                        Name = name,
                        ID = itemID,
                        Price = marketData.Price,
                        Currency = marketData.Currency,
                    })
                end
            end
        end
        return itemDetails
    end

    -- FUNGSI LOGIC PEMBELIAN ITEM MERCHANT
    local function BuyMerchantItem(itemID, itemName)
        if not RF_PurchaseMarketItem then
            WindUI:Notify({ Title = "Purchase Failed", Content = "Remote Purchase Market Item tidak ditemukan.", Duration = 4, Icon = "x", })
            return false
        end
        
        local success, result = pcall(function()
            return RF_PurchaseMarketItem:InvokeServer(itemID)
        end)

        if success then
            WindUI:Notify({ Title = "Purchase Attempted!", Content = "Mencoba membeli: " .. itemName, Duration = 1.5, Icon = "check", })
            return true
        else
            WindUI:Notify({ Title = "Purchase Failed", Content = "Gagal: " .. (result or "Unknown Error"), Duration = 2, Icon = "x", })
            return false
        end
    end
    
    -- FUNGSI UNTUK MENGHAPUS TOMBOL LAMA
    local function ClearOldMerchantButtons()
        for _, btn in ipairs(MerchantButtons) do
            if btn and type(btn) == "table" and btn.Destroy then
                pcall(function()
                    btn:Destroy()
                end)
            end
        end
        MerchantButtons = {}
    end

    -- FUNGSI UNTUK MEMBUAT STRING STOCK LIST
    local function CreateStockListString(itemDetails)
        local list = {"--- CURRENT STOCK ---"}
        if #itemDetails == 0 then
            table.insert(list, "Stok Item unik kosong saat ini.")
            return table.concat(list, "\n")
        end

        for _, item in ipairs(itemDetails) do
            local formattedPrice = FormatNumber(item.Price)
            local currency = item.Currency or "Coins"
            table.insert(list, string.format(" • %s: %s %s", item.Name, formattedPrice, currency))
        end
        
        return table.concat(list, "\n")
    end

    -- FUNGSI UNTUK MENGGAMBAR ULANG TOMBOL DINAMIS
    local function RedrawMerchantButtons(itemDetails)
        ClearOldMerchantButtons()
        
        if #itemDetails > 0 then
            for _, item in ipairs(itemDetails) do
                local formattedPrice = FormatNumber(item.Price)
                local currency = item.Currency or "Coins"
                
                local newButton = shop:Button({
                    Title = string.format("BUY: %s", item.Name),
                    Desc = string.format("Price: %s %s", formattedPrice, currency),
                    Icon = "shopping-cart",
                    Callback = function()
                        BuyMerchantItem(item.ID, item.Name)
                    end
                })
                table.insert(MerchantButtons, newButton)
            end
        else
            local noStockIndicator = shop:Paragraph({
                Title = "No Buyable Items",
                Desc = "Tidak ada tombol yang tersedia.",
                Icon = "info",
            })
            table.insert(MerchantButtons, noStockIndicator)
        end
    end

    -- 💡 FUNGSI AUTO BUY DINAMIS (Current Stock)
    local function RunAutoBuyStockLoop()
        if autoBuyThread then task.cancel(autoBuyThread) end
        
        autoBuyThread = task.spawn(function()
            while autoBuyStockState do
                if MerchantReplion then
                    local currentDetails = GetMerchantStockDetails(MerchantReplion.Data)
                    for _, item in ipairs(currentDetails) do
                        BuyMerchantItem(item.ID, item.Name)
                        task.wait(0.5)
                    end
                end
                task.wait(3)
            end
        end)
    end

    -- 💡 FUNGSI AUTO BUY STATIS (Selected Item)
    local function RunAutoBuySelectedLoop(itemID, itemName)
        if autoBuyThread then task.cancel(autoBuyThread) end

        autoBuyThread = task.spawn(function()
            while autoBuySelectedState do
                BuyMerchantItem(itemID, itemName)
                task.wait(1)
            end
        end)
    end


    local function RunMerchantSyncLoop(mainDisplay)
        if UpdateThread then task.cancel(UpdateThread) end

        local initialDetails = GetMerchantStockDetails(MerchantReplion.Data)
        RedrawMerchantButtons(initialDetails)
        
        local stockUpdateConnection = MerchantReplion:OnChange("Items", function(newItems)
            local currentDetails = GetMerchantStockDetails(MerchantReplion.Data)
            RedrawMerchantButtons(currentDetails)
            
            local timeString = getNextRefreshTimeString()
            local stockListString = CreateStockListString(currentDetails)
            mainDisplay:SetTitle(timeString .. "\n" .. stockListString)
        end)
        
        local isRunning = true
        
        UpdateThread = task.spawn(function()
            while isRunning do
                local timeString = getNextRefreshTimeString()
                local currentDetails = GetMerchantStockDetails(MerchantReplion.Data)
                local stockListString = CreateStockListString(currentDetails)
                
                mainDisplay:SetTitle(timeString .. "\n" .. stockListString)
                
                task.wait(1)
            end
            if stockUpdateConnection then stockUpdateConnection:Disconnect() end
            ClearOldMerchantButtons()
        end)
        
        return function()
            isRunning = false
            if UpdateThread then task.cancel(UpdateThread) UpdateThread = nil end
            if stockUpdateConnection then stockUpdateConnection:Disconnect() end
            ClearOldMerchantButtons()
        end
    end
    
    local function ToggleMerchantSync(state, mainDisplay)
        if state then
            task.spawn(function()
                if not GetReplions() then
                    WindUI:Notify({ Title = "Sync Gagal", Content = "Gagal memuat Replion Merchant.", Duration = 4, Icon = "x", })
                    mainDisplay:SetTitle("Sync Gagal: Merchant Replion missing/timeout.")
                    mainDisplay:SetDesc("Toggle OFF dan coba lagi.")
                    return
                end

                WindUI:Notify({ Title = "Sync ON!", Content = "Memulai live update stok dan tombol beli.", Duration = 2, Icon = "check", })
                mainDisplay:SetDesc("Waktu refresh dihitung akurat dari server.")
                UpdateCleanupFunction = RunMerchantSyncLoop(mainDisplay)
            end)
            
            return true
        else
            WindUI:Notify({ Title = "Sync OFF!", Duration = 3, Icon = "x", })
            
            if UpdateCleanupFunction then
                UpdateCleanupFunction()
                UpdateCleanupFunction = nil
            end
            
            mainDisplay:SetTitle("Merchant Live Data OFF.")
            mainDisplay:SetDesc("Toggle ON untuk melihat status live.")
            ClearOldMerchantButtons()
            
            return false
        end
    end

    -- ** START WIDGETS **

    local WeatherList = { "Storm", "Cloudy", "Snow", "Wind", "Radiant", "Shark Hunt" }
    local AutoWeatherState = false
    local AutoWeatherThread = nil
    -- UBAH INI MENJADI TABEL UNTUK MENYIMPAN MULTI-SELEKSI
    local SelectedWeatherTypes = { WeatherList[1] }
    
    local function RunAutoBuyWeatherLoop(weatherTypes)
    
    -- AGGRESSIVE CHECK/FALLBACK UNTUK REMOTE
    local PurchaseRemote = RF_PurchaseWeatherEvent
    if not PurchaseRemote then
        PurchaseRemote = GetRemote(RPath, "RF/PurchaseWeatherEvent", 1)
        
        if not PurchaseRemote then
            WindUI:Notify({ Title = "Weather Buy Error", Content = "Remote RF/PurchaseWeatherEvent tidak ditemukan setelah coba agresif!", Duration = 5, Icon = "x" })
            AutoWeatherState = false
            return
        end
    end

    if AutoWeatherThread then task.cancel(AutoWeatherThread) end

    print("[DEBUG WEATHER] Starting MULTI-BUY loop for: " .. table.concat(weatherTypes, ", "))
    
    AutoWeatherThread = task.spawn(function()
        local successfulBuyTime = 10 -- Catatan: Nilai ini kemungkinan harus 900 detik (15 menit) untuk cooldown game yang sebenarnya.
        local attempts = 0
        
        while AutoWeatherState and #weatherTypes > 0 do
            local totalSuccessfulBuysInCycle = 0
            local weatherBought = {}

            -- === FASE 1: INSTANTLY TRY ALL SELECTED WEATHERS (Satu Cycle Penuh) ===
            for i, weatherToBuy in ipairs(weatherTypes) do
                
                attempts = attempts + 1
                
                -- Notifikasi mencoba membeli (delay sangat singkat: 0.05 detik)
                task.wait(0.05)
                
                local success_buy, err_msg = pcall(function()
                    return PurchaseRemote:InvokeServer(weatherToBuy)
                end)

                if success_buy then
                    -- Pembelian sukses, catat dan segera coba item berikutnya di daftar
                    totalSuccessfulBuysInCycle = totalSuccessfulBuysInCycle + 1
                    table.insert(weatherBought, weatherToBuy)
                    -- Tambahkan notifikasi sukses (opsional, untuk feedback cepat)
                end
            end
            
            -- === FASE 2: CHECK RESULT AND WAIT ===
            if totalSuccessfulBuysInCycle > 0 then
                -- Setidaknya satu cuaca berhasil dibeli. Tunggu cooldown 15 menit.
                local boughtList = table.concat(weatherBought, ", ")
                
                attempts = 0 -- Reset attempts
                task.wait(successfulBuyTime) -- TUNGGU COOLDOWN LAMA DI SINI
            else
                task.wait(5)
            end
        end
        AutoWeatherThread = nil
        local toggle = shop:GetElementByTitle("Enable Auto Buy Weather")
        if toggle and toggle.Set then toggle:Set(false) end
    end)
end
    
    -- 3. UI UNTUK AUTO BUY WEATHER
    local weathershop = shop:Section({ Title = "Auto Buy Weather", TextSize = 20, })
    
    local WeatherDropdown = weathershop:Dropdown({
        Title = "Select Weather Type",
        Values = WeatherList,
        Value = SelectedWeatherTypes, -- Menggunakan tabel
        Multi = true, -- UBAH MENJADI MULTI SELECTION
        AllowNone = false,
        Flag = "dweat",
        Callback = function(selected)
            SelectedWeatherTypes = selected or {} -- Ambil daftar yang dipilih
            if #SelectedWeatherTypes == 0 then
                -- Jika tidak ada yang dipilih, kembalikan ke nilai default pertama
                SelectedWeatherTypes = { WeatherList[1] }
            end
            if AutoWeatherState then
                -- Jika sedang aktif, restart loop dengan weather baru
                RunAutoBuyWeatherLoop(SelectedWeatherTypes)
            end
        end
    })
    
    local ToggleAutoBuy = weathershop:Toggle({
        Title = "Enable Auto Buy Weather",
        Value = false,
        Flag = "weather",
        Callback = function(state)
            AutoWeatherState = state
            if state then
                if #SelectedWeatherTypes == 0 then
                    -- NOTIFIKASI ERROR: Belum memilih Weather
                    WindUI:Notify({ Title = "Error", Content = "Pilih minimal satu jenis Weather terlebih dahulu.", Duration = 3, Icon = "x" })
                    AutoWeatherState = false
                    return false
                end
                RunAutoBuyWeatherLoop(SelectedWeatherTypes)
                
            else
                if AutoWeatherThread then task.cancel(AutoWeatherThread) end
                -- NOTIFIKASI WARNING: Auto Buy Dimatikan
                WindUI:Notify({ Title = "Auto Weather", Content = "Auto Buy dimatikan.", Duration = 3, Icon = "x" })
            end
        end
    })
    shop:Divider()
    
    -- Rods, Bobbers, Boats
    local prod = shop:Section({ Title = "Purchase Rods", TextSize = 20, })
    shop:Divider()
    local rodOptions = getDropdownOptions("Rods")
    local droprod = prod:Dropdown({ Title = "Select Rod", Values = rodOptions, Value = false, Flag = "rod", Callback = function(value) selectedRodName = value end })
    local butrod = prod:Button({ Title = "Purchase Selected Rod", Icon = "mouse-pointer-click", Callback = function() handlePurchase("Rods", selectedRodName) end })

    local pbait = shop:Section({ Title = "Purchase Bobbers", TextSize = 20, })
    shop:Divider()
    local bobberOptions = getDropdownOptions("Bobbers")
    local dbait = pbait:Dropdown({ Title = "Select Bobber", Values = bobberOptions, Value = false, Flag = "bober", Callback = function(value) selectedBobberName = value end })
    local butbait = pbait:Button({ Title = "Purchase Selected Bobber", Icon = "mouse-pointer-click", Callback = function() handlePurchase("Bobbers", selectedBobberName) end })

    local pboat = shop:Section({ Title = "Purchase Boats", TextSize = 20, })
    shop:Divider()
    local boatOptions = getDropdownOptions("Boats")
    local dboat = pboat:Dropdown({ Title = "Select Boat", Values = boatOptions, Value = false, Flag = "boat", Callback = function(value) selectedBoatName = value end })
    local butboat = pboat:Button({ Title = "Purchase Selected Boat", Icon = "mouse-pointer-click", Callback = function() handlePurchase("Boats", selectedBoatName) end })

    local ptele = shop:Section({ Title = "Shop Teleports", TextSize = 20, })
    shop:Divider()
    local buttele = ptele:Button({ Title = "Skin Crate Shop", Icon = "mouse-pointer-click", Callback = function() TeleportToLookAt(Vector3.new(79.038, 17.284, 2869.537), Vector3.new(-0.893, -0.000, 0.450)) end })
    local bututil = ptele:Button({ Title = "Utility Shop", Icon = "mouse-pointer-click", Callback = function() TeleportToLookAt(Vector3.new(-41.260, 20.460, 2877.561), Vector3.new(-0.893, -0.000, 0.450)) end })

    local merchant = shop:Section({
        Title = "Traveling Merchant",
        TextSize = 20,
    })
    shop:Divider()

    -- 1. Display Waktu & Stok (Paragraph)
    MainDisplayElement = merchant:Paragraph({
        Title = "Merchant Live Data OFF.",
        Desc = "Toggle ON untuk melihat status live.",
        Icon = "clock"
    })

    -- ** DI SINI TOMBOL BUY DINAMIS BERDASARKAN LIVE STOCK MUNCUL **

    local tlive = merchant:Toggle({
        Title = "Live Stock & Buy Actions",
        Icon = "rotate-ccw",
        Value = false,
        Flag = "tlive",
        Callback = function(state)
            return ToggleMerchantSync(state, MainDisplayElement)
        end,
    })


    local tcurst = merchant:Toggle({
        Title = "Auto Buy Current Stock",
        Value = false,
        Flag = "tcurst",
        Callback = function(state)
            autoBuyStockState = state
            if state then
                RunAutoBuyStockLoop()
                if autoBuySelectedState then
                    autoBuySelectedState = false
                    shop:GetElementByTitle("Auto Buy Item Terpilih"):Set(false)
                end
            else
                if autoBuyThread then task.cancel(autoBuyThread) autoBuyThread = nil end
            end
        end
    })
    

    local merchantStaticOptions = GetStaticMerchantOptions()
    local StaticDropdown = merchant:Dropdown({
        Title = "Pilih Item Merchant",
        Values = merchantStaticOptions,
        Value = false,
        Multi = true,
        AllowNone = true,
        Flag = "dmerc",
        Callback = function(value)
            selectedStaticItemName = value
            if autoBuySelectedState then
                autoBuySelectedState = false
                shop:GetElementByTitle("Auto Buy Item Terpilih"):Set(false)
            end
        end
    })

    local butmerc = merchant:Button({
        Title = "Beli Sekali Item Terpilih",
        Icon = "mouse-pointer-click",
        Callback = function()
            local itemID, itemName = GetStaticMerchantItemID(selectedStaticItemName)
            if itemID then
                BuyMerchantItem(itemID, itemName)
            else
                WindUI:Notify({ Title = "Error", Content = "Item tidak valid.", Duration = 3, Icon = "x" })
            end
        end
    })

    local ToggleSelectedBuy = merchant:Toggle({
        Title = "Auto Buy Item Terpilih",
        Value = false,
        Flag = "curst",
        Callback = function(state)
            autoBuySelectedState = state
            if state then
                local itemID, itemName = GetStaticMerchantItemID(selectedStaticItemName)
                if itemID then
                    RunAutoBuySelectedLoop(itemID, itemName)
                    if autoBuyStockState then
                        autoBuyStockState = false
                        shop:GetElementByTitle("Auto Buy Current Stock"):Set(false)
                    end
                else
                    WindUI:Notify({ Title = "Error", Content = "Pilih item valid di dropdown.", Duration = 3, Icon = "x" })
                    return false
                end
            else
                if autoBuyThread then task.cancel(autoBuyThread) autoBuyThread = nil end
            end
        end
    })

    local telemerc = merchant:Button({ Title = "Teleport To Merchant Shop", Icon = "mouse-pointer-click", Callback = function() TeleportToLookAt(Vector3.new(-127.747, 2.718, 2759.031), Vector3.new(-0.920, 0.000, -0.392)) end })
    
    
end

do
    local quest = Window:Tab({
        Title = "Quests",
        Icon = "scroll",
        Locked = false,
    })

    -- =================================================================
    -- CONFIG & VARIABLES
    -- =================================================================
    local ID_GHOSTFIN_ROD = 169
    
    local GHOSTFIN_QUEST_ACTIVE = false
    local GHOSTFIN_MAIN_THREAD = nil
    
    local ELEMENT_QUEST_ACTIVE = false
    local ELEMENT_MAIN_THREAD = nil

    -- [THREAD] AUTO EQUIP (Background)
    local QUEST_AUTO_EQUIP_THREAD = nil 

    -- Controller & Remotes
    local RPath = {"Packages", "_Index", "sleitnick_net@0.2.0", "net"}
    
    local function GetRemote(remotePath, name, timeout)
        local currentInstance = game:GetService("ReplicatedStorage")
        for _, childName in ipairs(remotePath) do
            currentInstance = currentInstance:WaitForChild(childName, timeout or 0.5)
            if not currentInstance then return nil end
        end
        return currentInstance:FindFirstChild(name)
    end

    local RE_EquipToolFromHotbar = GetRemote(RPath, "RE/EquipToolFromHotbar")
    local RF_ChargeFishingRod = GetRemote(RPath, "RF/ChargeFishingRod")
    local RF_RequestFishingMinigameStarted = GetRemote(RPath, "RF/RequestFishingMinigameStarted")
    local RE_FishingCompleted = GetRemote(RPath, "RE/FishingCompleted")
    local RF_CancelFishingInputs = GetRemote(RPath, "RF/CancelFishingInputs")
    local RF_UpdateAutoFishingState = GetRemote(RPath, "RF/UpdateAutoFishingState")
    
    -- Remotes Tambahan
    local RF_CreateTranscendedStone = GetRemote(RPath, "RF/CreateTranscendedStone")
    local RF_PlaceLeverItem = GetRemote(RPath, "RE/PlaceLeverItem")
    local RE_EquipItem = GetRemote(RPath, "RE/EquipItem")
    local RE_UnequipItem = GetRemote(RPath, "RE/UnequipItem")

    -- Lokasi Penting
    local TREASURE_ROOM_POS = Vector3.new(-3598.440, -281.274, -1645.855)
    local TREASURE_ROOM_LOOK = Vector3.new(-0.065, 0.000, -0.998)
    local SISYPHUS_POS = Vector3.new(-3743.745, -135.074, -1007.554)
    local SISYPHUS_LOOK = Vector3.new(0.310, 0.000, 0.951)
    local ANCIENT_JUNGLE_POS = Vector3.new(1535.639, 3.159, -193.352)
    local ANCIENT_JUNGLE_LOOK = Vector3.new(0.505, -0.000, 0.863)
    local SACRED_TEMPLE_POS = Vector3.new(1461.815, -22.125, -670.234)
    local SACRED_TEMPLE_LOOK = Vector3.new(-0.990, -0.000, 0.143)
    local SECOND_ALTAR_POS = Vector3.new(1479.587, 128.295, -604.224)
    local SECOND_ALTAR_LOOK = Vector3.new(-0.298, 0.000, -0.955)

    -- Data Artifact
    local ArtifactData = {
        ["Hourglass Diamond Artifact"] = {
            ItemName = "Hourglass Diamond Artifact", LeverName = "Hourglass Diamond Lever", ChildReference = 6, CrystalPathSuffix = "Crystal",
            UnlockColor = Color3.fromRGB(255, 248, 49),
            FishingPos = {Pos = Vector3.new(1490.144, 3.312, -843.171), Look = Vector3.new(0.115, 0.000, 0.993)},
        },
        ["Diamond Artifact"] = {
            ItemName = "Diamond Artifact", LeverName = "Diamond Lever", ChildReference = "TempleLever", CrystalPathSuffix = "Crystal",
            UnlockColor = Color3.fromRGB(219, 38, 255),
            FishingPos = {Pos = Vector3.new(1844.159, 2.530, -288.755), Look = Vector3.new(0.981, 0.000, -0.193)},
        },
        ["Arrow Artifact"] = {
            ItemName = "Arrow Artifact", LeverName = "Arrow Lever", ChildReference = 5, CrystalPathSuffix = "Crystal",
            UnlockColor = Color3.fromRGB(255, 47, 47),
            FishingPos = {Pos = Vector3.new(874.365, 2.530, -358.484), Look = Vector3.new(-0.990, 0.000, 0.144)},
        },
        ["Crescent Artifact"] = {
            ItemName = "Crescent Artifact", LeverName = "Crescent Lever", ChildReference = 4, CrystalPathSuffix = "Crystal",
            UnlockColor = Color3.fromRGB(112, 255, 69),
            FishingPos = {Pos = Vector3.new(1401.070, 6.489, 116.738), Look = Vector3.new(-0.500, -0.000, 0.866)},
        },
    }
    local ArtifactOrder = {"Hourglass Diamond Artifact", "Diamond Artifact", "Arrow Artifact", "Crescent Artifact"}

    -- =================================================================
    -- [DATA] PRICES FOR LOGIC
    -- =================================================================
    local SPECIAL_ROD_IDS = {[169] = {Name = "Ghostfin Rod", Price = 99999999}, [257] = {Name = "Element Rod", Price = 999999999}}
    local ShopItems = {
        ["Rods"] = {
            {Name="Luck Rod",ID=79,Price=325},{Name="Carbon Rod",ID=76,Price=750},{Name="Grass Rod",ID=85,Price=1500},{Name="Demascus Rod",ID=77,Price=3000},
            {Name="Ice Rod",ID=78,Price=5000},{Name="Lucky Rod",ID=4,Price=15000},{Name="Midnight Rod",ID=80,Price=50000},{Name="Steampunk Rod",ID=6,Price=215000},
            {Name="Chrome Rod",ID=7,Price=437000},{Name="Flourescent Rod",ID=255,Price=715000},{Name="Astral Rod",ID=5,Price=1000000},
            {Name="Ares Rod",ID=126,Price=3000000},{Name="Angler Rod",ID=168,Price=8000000}
        }
    }
    
    local ROD_DELAYS = {
    -- [Starter / Cheap Rods]
    [79]  = 4.6, -- Luck Rod
    [76]  = 4.35, -- Carbon Rod
    [85]  = 4.2, -- Grass Rod
    [77]  = 4.35, -- Demascus Rod
    [78]  = 3.85, -- Ice Rod
    
    -- [Mid Tier Rods]
    [4]   = 3.5, -- Lucky Rod
    [80]  = 2.7, -- Midnight Rod
    
    -- [High Tier Rods]
    [6]   = 2.3, -- Steampunk Rod
    [7]   = 2.2, -- Chrome Rod
    [255] = 2.2, -- Flourescent Rod
    [5]   = 1.85, -- Astral Rod
    
    -- [God Tier Rods]
    [126] = 1.7, -- Ares Rod
    [168] = 1.6, -- Angler Rod
    
    -- [Quest / Special Rods]
    [169] = 1.2, -- Ghostfin Rod
    [257] = 1, -- Element Rod
}

local DEFAULT_ROD_DELAY = 3.85

    local function GetRodPriceByID(id)
        id = tonumber(id)
        if SPECIAL_ROD_IDS[id] then return SPECIAL_ROD_IDS[id].Price, SPECIAL_ROD_IDS[id].Name end
        for _, item in ipairs(ShopItems["Rods"]) do if item.ID == id then return item.Price, item.Name end end
        return 0, "Unknown Rod"
    end

    -- =================================================================
    -- [CORE] EQUIP BEST ROD ONLY & GET PRECISE DELAY
    -- =================================================================
    local function EquipBestRod()
        local replion = require(game:GetService("ReplicatedStorage"):WaitForChild("Packages"):WaitForChild("Replion")).Client:WaitReplion("Data", 5)
        if not replion then return DEFAULT_ROD_DELAY end 
        
        local success, inventoryData = pcall(function() return replion:GetExpect("Inventory") end)
        if not success or not inventoryData then return DEFAULT_ROD_DELAY end

        -- 1. Find Best Rod (Highest Price logic is still good for selection)
        local bestRodUUID, bestRodPrice = nil, -1
        local bestRodId = nil -- Kita simpan ID-nya untuk cek delay

        if inventoryData["Fishing Rods"] then
            for _, rod in ipairs(inventoryData["Fishing Rods"]) do
                local price = GetRodPriceByID(rod.Id)
                if price > bestRodPrice then 
                    bestRodPrice = price
                    bestRodUUID = rod.UUID 
                    bestRodId = tonumber(rod.Id) -- Simpan ID
                end
            end
        end

        -- 2. Equip Best Rod
        if bestRodUUID then 
            pcall(function() RE_EquipItem:FireServer(bestRodUUID, "Fishing Rods") end) 
        end
        
        -- 3. Hold Tool
        pcall(function() RE_EquipToolFromHotbar:FireServer(1) end)

        -- 4. Calculate Delay (NEW PRECISE LOGIC)
        if bestRodId and ROD_DELAYS[bestRodId] then
            return ROD_DELAYS[bestRodId]
        else
            return DEFAULT_ROD_DELAY
        end
    end

    -- =================================================================
    -- [CORE] INSTANT FISH (DYNAMIC DELAY)
    -- =================================================================
    local function RunQuestInstantFish(dynamicDelay)
        if not (RE_EquipToolFromHotbar and RF_ChargeFishingRod and RF_RequestFishingMinigameStarted and RE_FishingCompleted and RF_CancelFishingInputs) then return end
        
        -- 1. Charge Rod
        local timestamp = os.time() + os.clock()
        pcall(function() RF_ChargeFishingRod:InvokeServer(timestamp) end)
        
        -- 2. Cast Rod
        pcall(function() RF_RequestFishingMinigameStarted:InvokeServer(-139.630452165, 0.99647927980797) end)
        
        -- 3. Wait Smart Delay
        task.wait(dynamicDelay)
        
        -- 4. Complete & Reset
        pcall(function() RE_FishingCompleted:FireServer() end)
        task.wait(0.3)
        pcall(function() RF_CancelFishingInputs:InvokeServer() end)
    end

    -- [THREAD] AUTO EQUIP BACKGROUND (Rod Only)
    local function StartQuestAutoEquip()
        if QUEST_AUTO_EQUIP_THREAD then task.cancel(QUEST_AUTO_EQUIP_THREAD) end
        QUEST_AUTO_EQUIP_THREAD = task.spawn(function()
            local tick = 0
            while GHOSTFIN_QUEST_ACTIVE or ELEMENT_QUEST_ACTIVE do
                -- Equip Rod Slot 1 setiap 0.5 detik
                pcall(function() RE_EquipToolFromHotbar:FireServer(1) end)
                
                -- Setiap 5 detik, paksa re-check & equip best rod (jaga-jaga ganti item)
                if tick % 10 == 0 then
                    EquipBestRod() 
                end
                
                tick = tick + 1
                task.wait(0.5)
            end
        end)
    end

    local function StopQuestAutoEquip()
        if QUEST_AUTO_EQUIP_THREAD then task.cancel(QUEST_AUTO_EQUIP_THREAD) QUEST_AUTO_EQUIP_THREAD = nil end
        pcall(function() RE_EquipToolFromHotbar:FireServer(0) end) 
    end

    -- =================================================================
    -- QUEST LOGIC HELPERS
    -- =================================================================
    local function HasGhostfinRod()
        local replion = require(game:GetService("ReplicatedStorage"):WaitForChild("Packages"):WaitForChild("Replion")).Client:WaitReplion("Data", 5)
        if not replion then return false end
        local success, inventoryData = pcall(function() return replion:GetExpect("Inventory") end)
        if not success or not inventoryData or not inventoryData["Fishing Rods"] then return false end
        for _, rod in ipairs(inventoryData["Fishing Rods"]) do
            if tonumber(rod.Id) == ID_GHOSTFIN_ROD then return true end
        end
        return false
    end

    local function GetLowestWeightSecrets(limit)
        local secrets = {}
        local replion = require(game:GetService("ReplicatedStorage"):WaitForChild("Packages"):WaitForChild("Replion")).Client:WaitReplion("Data", 5)
        if not replion then return {} end
        local success, inventoryData = pcall(function() return replion:GetExpect("Inventory") end)
        if success and inventoryData and inventoryData.Items then
            for _, item in ipairs(inventoryData.Items) do
                local rarity = item.Metadata and item.Metadata.Rarity or "Unknown"
                if rarity:upper() == "SECRET" and item.Metadata and item.Metadata.Weight then
                    if not (item.IsFavorite or item.Favorited or item.Locked) then
                        table.insert(secrets, {UUID = item.UUID, Weight = item.Metadata.Weight})
                    end
                end
            end
        end
        table.sort(secrets, function(a, b) return a.Weight < b.Weight end)
        local result = {}
        for i = 1, math.min(limit, #secrets) do table.insert(result, secrets[i].UUID) end
        return result
    end

    -- Lever Helpers
    local function IsLeverUnlocked(artifactName)
        local JUNGLE_INTERACTIONS = workspace:FindFirstChild("JUNGLE INTERACTIONS")
        if not JUNGLE_INTERACTIONS then return false end
        local data = ArtifactData[artifactName]
        if not data then return false end
        
        local leverFolder = nil
        if type(data.ChildReference) == "string" then leverFolder = JUNGLE_INTERACTIONS:FindFirstChild(data.ChildReference) end
        if not leverFolder and type(data.ChildReference) == "number" then local c = JUNGLE_INTERACTIONS:GetChildren() leverFolder = c[data.ChildReference] end
        if not leverFolder then return false end
        
        local crystal = leverFolder:FindFirstChild(data.CrystalPathSuffix)
        if not crystal or not crystal:IsA("BasePart") then return false end
        
        local cC, tC = crystal.Color, data.UnlockColor
        return (math.abs(cC.R*255 - tC.R*255) < 1.1 and math.abs(cC.G*255 - tC.G*255) < 1.1 and math.abs(cC.B*255 - tC.B*255) < 1.1)
    end

    local function HasArtifactItem(artifactName)
        local replion = require(game:GetService("ReplicatedStorage"):WaitForChild("Packages"):WaitForChild("Replion")).Client:WaitReplion("Data", 5)
        if not replion then return false end
        local success, inventoryData = pcall(function() return replion:GetExpect("Inventory") end)
        if not success or not inventoryData or not inventoryData.Items then return false end
        for _, item in ipairs(inventoryData.Items) do
            if item.Identifier == artifactName then return true end
        end
        return false
    end

    -- =================================================================
    -- QUEST 1: GHOSTFIN
    -- =================================================================
    local ghostfin = quest:Section({ Title = "Ghostfin Rod Quest", TextSize = 20 })
    local GhostfinStatus = ghostfin:Paragraph({ Title = "Quest Status: Idle", Content = "Waiting...", Icon = "activity" })

    -- Fungsi Baca Data Aman
    local function GetGhostfinProgressSafe()
        local data = { Header = "Loading...", Q1={Text="...",Done=false}, Q2={Text="...",Done=false}, Q3={Text="...",Done=false}, Q4={Text="...",Done=false}, AllDone=false, BoardFound=false }
        local board = workspace:FindFirstChild("!!! MENU RINGS") and workspace["!!! MENU RINGS"]:FindFirstChild("Deep Sea Tracker") and workspace["!!! MENU RINGS"]["Deep Sea Tracker"]:FindFirstChild("Board")
        if board then
            data.BoardFound = true 
            pcall(function()
                local c = board.Gui.Content
                data.Header = c.Header.ContentText ~= "" and c.Header.ContentText or c.Header.Text
                local function proc(lbl) local t = lbl.ContentText~="" and lbl.ContentText or lbl.Text return {Text=t, Done=string.find(t, "100%%")~=nil} end
                data.Q1 = proc(c.Label1); data.Q2 = proc(c.Label2); data.Q3 = proc(c.Label3); data.Q4 = proc(c.Label4)
                if data.Q1.Done and data.Q2.Done and data.Q3.Done and data.Q4.Done then data.AllDone = true end
            end)
        end
        return data
    end

    local function RunGhostfinLoop()
        if GHOSTFIN_MAIN_THREAD then task.cancel(GHOSTFIN_MAIN_THREAD) end
        StartQuestAutoEquip() -- Nyalakan Auto Equip Background

        GHOSTFIN_MAIN_THREAD = task.spawn(function()
            local currentTarget = "None"
            
            while GHOSTFIN_QUEST_ACTIVE do
                local p = GetGhostfinProgressSafe()
                
                -- Teleport ke Altar jika board tidak ketemu
                if not p.BoardFound then
                    GhostfinStatus:SetTitle("Status: Loading Board Data...")
                    GhostfinStatus:SetDesc("Mendekat ke Altar untuk membaca Quest...")
                    local hrp = game.Players.LocalPlayer.Character and game.Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                    if hrp and (hrp.Position - SECOND_ALTAR_POS).Magnitude > 20 then
                        local tCFrame = CFrame.new(SECOND_ALTAR_POS, SECOND_ALTAR_POS + SECOND_ALTAR_LOOK)
                        hrp.CFrame = tCFrame
                        task.wait(2) 
                    end
                    task.wait(1)
                    continue 
                end

                GhostfinStatus:SetTitle(p.Header)
                GhostfinStatus:SetDesc(string.format("1. %s [%s]\n2. %s [%s]\n3. %s [%s]\n4. %s [%s]", p.Q1.Text, p.Q1.Done and "✅" or "❌", p.Q2.Text, p.Q2.Done and "✅" or "❌", p.Q3.Text, p.Q3.Done and "✅" or "❌", p.Q4.Text, p.Q4.Done and "✅" or "❌"))

                if p.AllDone then 
                    WindUI:Notify({ Title = "Selesai!", Content = "Ghostfin Quest Complete.", Duration = 5, Icon = "trophy" }) 
                    break 
                end

                local hrp = game.Players.LocalPlayer.Character and game.Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                if not hrp then task.wait(1) continue end
                
                -- Auto Equip & Hitung Delay Cerdas
                local smartDelay = EquipBestRod() -- Returns 2.0 or 3.0 based on rod price

                -- LOGIC FARMING
                if not p.Q1.Done then
                    if currentTarget ~= "Treasure" then
                        local tCFrame = CFrame.new(TREASURE_ROOM_POS, TREASURE_ROOM_POS + TREASURE_ROOM_LOOK)
                        hrp.CFrame = tCFrame
                        currentTarget = "Treasure"
                        task.wait(1.5)
                    elseif (hrp.Position - TREASURE_ROOM_POS).Magnitude > 15 then
                        local tCFrame = CFrame.new(TREASURE_ROOM_POS, TREASURE_ROOM_POS + TREASURE_ROOM_LOOK)
                        hrp.CFrame = tCFrame
                        task.wait(0.5)
                    else
                        RunQuestInstantFish(smartDelay) -- Pakai delay dari best rod
                    end

                elseif not p.Q2.Done or not p.Q3.Done or not p.Q4.Done then
                    if currentTarget ~= "Sisyphus" then
                        local tCFrame = CFrame.new(SISYPHUS_POS, SISYPHUS_POS + SISYPHUS_LOOK)
                        hrp.CFrame = tCFrame
                        currentTarget = "Sisyphus"
                        task.wait(1.5)
                    elseif (hrp.Position - SISYPHUS_POS).Magnitude > 15 then
                        local tCFrame = CFrame.new(SISYPHUS_POS, SISYPHUS_POS + SISYPHUS_LOOK)
                        hrp.CFrame = tCFrame
                        task.wait(0.5)
                    else
                        RunQuestInstantFish(smartDelay) -- Pakai delay dari best rod
                    end
                end
                
                task.wait(0.1)
            end
            
            GHOSTFIN_QUEST_ACTIVE = false
            StopQuestAutoEquip()
            local toggle = ghostfin:GetElementByTitle("Auto Quest Ghostfin")
            if toggle and toggle.Set then toggle:Set(false) end
        end)
    end

    local tghostfin = ghostfin:Toggle({
        Title = "Auto Quest Ghostfin",
        Value = false,
        Flag = "tghostfin",
        Callback = function(state)
            GHOSTFIN_QUEST_ACTIVE = state
            if state then
                WindUI:Notify({ Title = "Ghostfin Quest", Content = "Started (Auto Best Rod & Smart Delay).", Duration = 3, Icon = "play" })
                RunGhostfinLoop()
            else
                StopQuestAutoEquip()
                if GHOSTFIN_MAIN_THREAD then task.cancel(GHOSTFIN_MAIN_THREAD) end
                WindUI:Notify({ Title = "Ghostfin Quest", Content = "Stopped.", Duration = 3, Icon = "square" })
            end
        end
    })

    -- =================================================================
    -- SECTION 2: ELEMENT ROD QUEST
    -- =================================================================
    quest:Divider()
    local element = quest:Section({ Title = "Element Rod Quest", TextSize = 20 })
    local ElementStatus = element:Paragraph({ Title = "Quest Status: Idle", Content = "Waiting...", Icon = "activity" })

    local function GetElementProgressSafe()
        local data = { Header = "Loading...", Q1={Text="...",Done=false}, Q2={Text="...",Done=false}, Q3={Text="...",Done=false}, Q4={Text="...",Done=false}, AllDone=false, BoardFound=false }
        local board = workspace:FindFirstChild("!!! MENU RINGS") and workspace["!!! MENU RINGS"]:FindFirstChild("Element Tracker") and workspace["!!! MENU RINGS"]["Element Tracker"]:FindFirstChild("Board")
        if board then
            data.BoardFound = true
            pcall(function()
                local c = board.Gui.Content
                data.Header = c.Header.ContentText ~= "" and c.Header.ContentText or c.Header.Text
                local function proc(lbl) local t = lbl.ContentText~="" and lbl.ContentText or lbl.Text return {Text=t, Done=string.find(t, "100%%")~=nil} end
                data.Q1 = proc(c.Label1); data.Q2 = proc(c.Label2); data.Q3 = proc(c.Label3); data.Q4 = proc(c.Label4)
                if data.Q1.Done and data.Q2.Done and data.Q3.Done and data.Q4.Done then data.AllDone = true end
            end)
        end
        return data
    end

    local function RunElementLoop()
        if ELEMENT_MAIN_THREAD then task.cancel(ELEMENT_MAIN_THREAD) end
        
        if not HasGhostfinRod() then
            WindUI:Notify({ Title = "Gagal", Content = "Butuh Ghostfin Rod (ID 169) di Inventory.", Duration = 5, Icon = "x" })
            quest:GetElementByTitle("Auto Quest Element"):Set(false)
            return
        end

        StartQuestAutoEquip()

        ELEMENT_MAIN_THREAD = task.spawn(function()
            local currentTarget = "None"

            while ELEMENT_QUEST_ACTIVE do
                local p = GetElementProgressSafe()
                
                if not p.BoardFound then
                    ElementStatus:SetTitle("Status: Loading Board Data...")
                    ElementStatus:SetDesc("Mendekat ke Altar untuk membaca Quest Element...")
                    local hrp = game.Players.LocalPlayer.Character and game.Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                    if hrp and (hrp.Position - SECOND_ALTAR_POS).Magnitude > 20 then
                        local tCFrame = CFrame.new(SECOND_ALTAR_POS, SECOND_ALTAR_POS + SECOND_ALTAR_LOOK)
                        hrp.CFrame = tCFrame
                        task.wait(2)
                    end
                    task.wait(1)
                    continue
                end

                ElementStatus:SetTitle(p.Header)
                ElementStatus:SetDesc(string.format("1. %s [%s]\n2. %s [%s]\n3. %s [%s]\n4. %s [%s]", p.Q1.Text, p.Q1.Done and "✅" or "❌", p.Q2.Text, p.Q2.Done and "✅" or "❌", p.Q3.Text, p.Q3.Done and "✅" or "❌", p.Q4.Text, p.Q4.Done and "✅" or "❌"))

                if p.AllDone then WindUI:Notify({ Title = "Selesai!", Content = "Element Quest Complete.", Duration = 5, Icon = "trophy" }) break end

                local hrp = game.Players.LocalPlayer.Character and game.Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                if not hrp then task.wait(1) continue end

                -- Hitung Delay Cerdas
                local smartDelay = EquipBestRod()

                if not p.Q2.Done then
                    -- Quest Catch Fish in Ancient Jungle
                    if currentTarget ~= "Jungle" then
                        local tCFrame = CFrame.new(ANCIENT_JUNGLE_POS, ANCIENT_JUNGLE_POS + ANCIENT_JUNGLE_LOOK)
                        hrp.CFrame = tCFrame
                        currentTarget = "Jungle"
                        task.wait(1.5)
                    elseif (hrp.Position - ANCIENT_JUNGLE_POS).Magnitude > 15 then
                        local tCFrame = CFrame.new(ANCIENT_JUNGLE_POS, ANCIENT_JUNGLE_POS + ANCIENT_JUNGLE_LOOK)
                        hrp.CFrame = tCFrame
                        task.wait(0.5)
                    else
                        RunQuestInstantFish(smartDelay)
                    end

                elseif not p.Q3.Done then
                    -- Quest Levers
                    local allLeversOpen = true
                    local missingLever = nil
                    for _, artName in ipairs(ArtifactOrder) do
                        if not IsLeverUnlocked(artName) then
                            allLeversOpen = false
                            missingLever = artName
                            break
                        end
                    end

                    if not allLeversOpen and missingLever then
                        local artData = ArtifactData[missingLever]
                        local hasIt = HasArtifactItem(missingLever)
                        if hasIt then
                            if currentTarget ~= "PlaceLever" then
                                local tCFrame = CFrame.new(artData.FishingPos.Pos, artData.FishingPos.Pos + artData.FishingPos.Look)
                                hrp.CFrame = tCFrame
                                currentTarget = "PlaceLever"
                                WindUI:Notify({ Title = "Puzzle", Content = "Memasang " .. missingLever, Duration = 3 })
                                task.wait(1.5)
                            end
                            pcall(function() RF_PlaceLeverItem:FireServer(missingLever) end)
                            task.wait(1)
                        else
                            if currentTarget ~= missingLever then
                                local tCFrame = CFrame.new(artData.FishingPos.Pos, artData.FishingPos.Pos + artData.FishingPos.Look)
                                hrp.CFrame = tCFrame
                                currentTarget = missingLever
                                WindUI:Notify({ Title = "Puzzle", Content = "Farming " .. missingLever, Duration = 3 })
                                task.wait(1.5)
                            elseif (hrp.Position - artData.FishingPos.Pos).Magnitude > 10 then
                                local tCFrame = CFrame.new(artData.FishingPos.Pos, artData.FishingPos.Pos + artData.FishingPos.Look)
                                hrp.CFrame = tCFrame
                                task.wait(0.5)
                            else
                                RunQuestInstantFish(smartDelay)
                            end
                        end
                    else
                        -- Jika semua lever terbuka, farm di Sacred Temple
                        if currentTarget ~= "Temple" then
                            local tCFrame = CFrame.new(SACRED_TEMPLE_POS, SACRED_TEMPLE_POS + SACRED_TEMPLE_LOOK)
                            hrp.CFrame = tCFrame
                            currentTarget = "Temple"
                            WindUI:Notify({ Title = "Element Quest", Content = "Temple Unlocked! Farming...", Duration = 3 })
                            task.wait(1.5)
                        elseif (hrp.Position - SACRED_TEMPLE_POS).Magnitude > 15 then
                            local tCFrame = CFrame.new(SACRED_TEMPLE_POS, SACRED_TEMPLE_POS + SACRED_TEMPLE_LOOK)
                            hrp.CFrame = tCFrame
                            task.wait(0.5)
                        else
                            RunQuestInstantFish(smartDelay)
                        end
                    end

                elseif not p.Q4.Done then
                    -- Quest Create Stone (Sacrifice Secrets)
                    if currentTarget ~= "Altar" then
                        local tCFrame = CFrame.new(SECOND_ALTAR_POS, SECOND_ALTAR_POS + SECOND_ALTAR_LOOK)
                        hrp.CFrame = tCFrame
                        currentTarget = "Altar"
                        task.wait(1.5)
                    end
                    
                    local trashSecrets = GetLowestWeightSecrets(3)
                    if #trashSecrets == 0 then
                        WindUI:Notify({ Title = "Bahan Kurang", Content = "Tidak ada ikan SECRET di tas.", Duration = 5, Icon = "alert-triangle" })
                        task.wait(5)
                    else
                        pcall(function() if RE_UnequipItem then RE_UnequipItem:FireServer("all") end end)
                        task.wait(0.5)
                        for i, fishUUID in ipairs(trashSecrets) do
                            if not ELEMENT_QUEST_ACTIVE then break end
                            pcall(function() RE_EquipItem:FireServer(fishUUID, "Fish") end)
                            task.wait(0.3)
                            pcall(function() RE_EquipToolFromHotbar:FireServer(2) end)
                            task.wait(0.5)
                            pcall(function() RF_CreateTranscendedStone:InvokeServer() end)
                            task.wait(1.5)
                        end
                        pcall(function() RE_EquipToolFromHotbar:FireServer(0) end)
                        task.wait(2)
                    end
                end
                task.wait(0.1)
            end
            
            ELEMENT_QUEST_ACTIVE = false
            StopQuestAutoEquip()
            local toggle = element:GetElementByTitle("Auto Quest Element")
            if toggle and toggle.Set then toggle:Set(false) end
        end)
    end

    local telement = element:Toggle({
        Title = "Auto Quest Element",
        Value = false,
        Flag = "telement",
        Callback = function(state)
            ELEMENT_QUEST_ACTIVE = state
            if state then
                WindUI:Notify({ Title = "Element Quest", Content = "Started (Auto Best Rod & Smart Delay).", Duration = 3, Icon = "play" })
                RunElementLoop()
            else
                if ELEMENT_MAIN_THREAD then task.cancel(ELEMENT_MAIN_THREAD) end
                StopQuestAutoEquip()
                WindUI:Notify({ Title = "Element Quest", Content = "Stopped.", Duration = 3, Icon = "square" })
            end
        end
    })
end

-- =================================================================
-- VARIABLES & CORE HELPERS FOR EVENTS TAB (UPDATED)
-- =================================================================

local lastPositionBeforeEvent = nil
local autoJoinEventActive = false
local LOCHNESS_POS = Vector3.new(6063.347, -585.925, 4713.696)
local LOCHNESS_LOOK = Vector3.new(-0.376, -0.000, -0.927)

-- *** AUTO UNLOCK RUIN DOOR ***
local AUTO_UNLOCK_STATE = false
local AUTO_UNLOCK_THREAD = nil
local AUTO_UNLOCK_ATTEMPT_THREAD = nil -- NEW THREAD FOR AGGRESSIVE UNLOCK
local RUIN_COMPLETE_DELAY = 1.5
local RUIN_DOOR_PATH = workspace["RUIN INTERACTIONS"] and workspace["RUIN INTERACTIONS"].Door
local ITEM_FISH_NAMES = {"Freshwater Piranha", "Goliath Tiger", "Sacred Guardian Squid", "Crocodile"}
local SACRED_TEMPLE_POS = FishingAreas["Sacred Temple"].Pos
local SACRED_TEMPLE_LOOK = FishingAreas["Sacred Temple"].Look
local RUIN_DOOR_REMOTE = GetRemote(RPath, "RE/PlacePressureItem")
local RUIN_DOOR_STATUS_PARAGRAPH
local RUIN_AUTO_UNLOCK_TOGGLE
local RF_UpdateAutoFishingState = GetRemote(RPath, "RF/UpdateAutoFishingState")
local RE_EquipToolFromHotbar = GetRemote(RPath, "RE/EquipToolFromHotbar")
local RF_ChargeFishingRod = GetRemote(RPath, "RF/ChargeFishingRod")
local RF_RequestFishingMinigameStarted = GetRemote(RPath, "RF/RequestFishingMinigameStarted")
local RE_FishingCompleted = GetRemote(RPath, "RE/FishingCompleted")
local RF_CancelFishingInputs = GetRemote(RPath, "RF/CancelFishingInputs")


local function GetEventGUI()
	local success, gui = pcall(function()
		local menuRings = workspace:WaitForChild("!!! MENU RINGS", 5)
		local eventTracker = menuRings:WaitForChild("Event Tracker", 5)
		local contentItems = eventTracker.Main.Gui.Content.Items

		local countdown = contentItems.Countdown:WaitForChild("Label")	
		local statsContainer = contentItems:WaitForChild("Stats")	
		local timer = statsContainer.Timer:WaitForChild("Label")	
		
		local quantity = statsContainer:WaitForChild("Quantity")	
		local odds = statsContainer:WaitForChild("Odds")

		return {
			Countdown = countdown,
			Timer = timer,
			Quantity = quantity,
			Odds = odds,
		}
	end)
	
	if success and gui then
		return gui
	end
	return nil
end

-- Fungsi Anda yang sudah diperbaiki (dan kini selalu mengupdate UI)
local function GetRuinDoorStatus()
	local ruinDoor = RUIN_DOOR_PATH -- Pathing ke model pintu
	local status = "LOCKED 🔒"
	
	if ruinDoor and ruinDoor:FindFirstChild("RuinDoor") then
		local LDoor = ruinDoor.RuinDoor:FindFirstChild("LDoor")
		
		if LDoor then
			local currentX = nil
			
			if LDoor:IsA("BasePart") then
				currentX = LDoor.Position.X
			elseif LDoor:IsA("Model") then
				-- Menggunakan GetPivot() untuk model
				local success, pivot = pcall(function() return LDoor:GetPivot() end)
                if success and pivot then
                    currentX = pivot.Position.X
                end
			end
			
			if currentX ~= nil then
				-- Gunakan ambang batas 6075 atau yang Anda temukan
				if currentX > 6075 then
					status = "UNLOCKED ✅"
				end
			end
		end
	end
	
    -- PENTING: Update elemen UI di sini
	RUIN_DOOR_STATUS_PARAGRAPH:SetTitle("Ruin Door Status: " .. status)
	return status
end



local function IsItemAvailable(itemName)
	local replion = GetPlayerDataReplion()
	if not replion then return false end
	local success, inventoryData = pcall(function() return replion:GetExpect("Inventory") end)
	if not success or not inventoryData or not inventoryData.Items then return false end

	for _, item in ipairs(inventoryData.Items) do
		if item.Identifier == itemName then
			return true
		end
		
		local name, _ = GetFishNameAndRarity(item)
		if name == itemName and (item.Count or 1) >= 1 then
			return true
		end
	end
	return false
end

local function GetMissingItem()
	for _, name in ipairs(ITEM_FISH_NAMES) do
		if not IsItemAvailable(name) then
			return name
		end
	end
	return nil
end

local function runInstantFish()
	if not (RE_EquipToolFromHotbar and RF_ChargeFishingRod and RF_RequestFishingMinigameStarted and RE_FishingCompleted and RF_CancelFishingInputs) then
		return false
	end
	
	pcall(function() RE_EquipToolFromHotbar:FireServer(1) end)
	
	local timestamp = os.time() + os.clock()
	pcall(function() RF_ChargeFishingRod:InvokeServer(timestamp) end)
	pcall(function() RF_RequestFishingMinigameStarted:InvokeServer(-139.630452165, 0.99647927980797) end)
	
	task.wait(RUIN_COMPLETE_DELAY)

	pcall(function() RE_FishingCompleted:FireServer() end)
	task.wait(0.3)
	pcall(function() RF_CancelFishingInputs:FireServer() end)
	
	return true
end

local function RunRuinDoorUnlockAttemptLoop()
	if AUTO_UNLOCK_ATTEMPT_THREAD then task.cancel(AUTO_UNLOCK_ATTEMPT_THREAD) end

	if not RUIN_DOOR_REMOTE then
		WindUI:Notify({ Title = "Error Remote", Content = "Remote Ruin Door (RE/PlacePressureItem) tidak ditemukan.", Duration = 4, Icon = "x" })
		return
	end
	
	AUTO_UNLOCK_ATTEMPT_THREAD = task.spawn(function()
		local RUIN_DOOR_POS = FishingAreas["Ancient Ruin"].Pos
		local RUIN_DOOR_LOOK = FishingAreas["Ancient Ruin"].Look
		
		TeleportToLookAt(RUIN_DOOR_POS, RUIN_DOOR_LOOK)
		task.wait(1.5)
		
		WindUI:Notify({ Title = "Unlock Attempt ON", Content = "Mulai agresif kirim remote PlacePressureItem...", Duration = 3, Icon = "zap" })

		while AUTO_UNLOCK_STATE and GetRuinDoorStatus() == "LOCKED 🔒" do
			for i, name in ipairs(ITEM_FISH_NAMES) do
				task.wait(2.1)
				pcall(function() RUIN_DOOR_REMOTE:FireServer(name) end)
			end
			
			task.wait(5)
		end
	end)
end

local function RunAutoUnlockLoop()
	if AUTO_UNLOCK_THREAD then task.cancel(AUTO_UNLOCK_THREAD) end
	if AUTO_UNLOCK_ATTEMPT_THREAD then task.cancel(AUTO_UNLOCK_ATTEMPT_THREAD) end
	
	pcall(function()
		local toggleLegit = Window:GetElementByTitle("Auto Fish (Legit)")
		local toggleNormal = Window:GetElementByTitle("Normal Instant Fish")
		local toggleBlatant = Window:GetElementByTitle("Instant Fishing (Blatant)")
		
		if toggleLegit and toggleLegit.Value then toggleLegit:Set(false) end
		if toggleNormal and toggleNormal.Value then toggleNormal:Set(false) end
		if toggleBlatant and toggleBlatant.Value then toggleBlatant:Set(false) end
		if RF_UpdateAutoFishingState then RF_UpdateAutoFishingState:InvokeServer(false) end
	end)

	AUTO_UNLOCK_THREAD = task.spawn(function()
		local isFarming = false
		local lastPositionBeforeEvent_Ruin = nil
		
		RunRuinDoorUnlockAttemptLoop()
		
		while AUTO_UNLOCK_STATE do
			local doorStatus = GetRuinDoorStatus()
			RUIN_DOOR_STATUS_PARAGRAPH:SetTitle("Ruin Door Status: " .. doorStatus)

			if doorStatus == "LOCKED 🔒" then
				local missingItem = GetMissingItem()

				if missingItem then
					
					if not isFarming then
						local hrp = GetHRP()
						if hrp and lastPositionBeforeEvent_Ruin == nil then
							lastPositionBeforeEvent_Ruin = {Pos = hrp.Position, Look = hrp.CFrame.LookVector}
							WindUI:Notify({ Title = "Posisi Disimpan", Content = "Posisi sebelum Ruin Door farm disimpan.", Duration = 2, Icon = "save" })
						end
						TeleportToLookAt(SACRED_TEMPLE_POS, SACRED_TEMPLE_LOOK)
						task.wait(1.5)
						isFarming = true
						WindUI:Notify({ Title = "Ruin Door: Farming", Content = "Mencari " .. missingItem .. ". Fishing ON (Delay: "..RUIN_COMPLETE_DELAY.."s).", Duration = 4, Icon = "fish" })
					end
					
					RUIN_DOOR_STATUS_PARAGRAPH:SetDesc("Mencari item: " .. missingItem .. ". Fishing...")
					runInstantFish()
					task.wait(RUIN_COMPLETE_DELAY + 0.5)
					
				else
					RUIN_DOOR_STATUS_PARAGRAPH:SetDesc("Semua item ada! Loop Unlock Agresif berjalan...")
					isFarming = false
					
					task.wait(1)
				end
				
			elseif doorStatus == "UNLOCKED ✅" then
				RUIN_DOOR_STATUS_PARAGRAPH:SetDesc("Pintu sudah tidak terkunci. Auto Unlock berhenti.")
				
				if lastPositionBeforeEvent_Ruin then
					TeleportToLookAt(lastPositionBeforeEvent_Ruin.Pos, lastPositionBeforeEvent_Ruin.Look)
					lastPositionBeforeEvent_Ruin = nil
					WindUI:Notify({ Title = "Kembali ke Posisi Awal", Content = "Door UNLOCKED, melanjutkan farm.", Duration = 4, Icon = "repeat" })
				end
				break
				
			else
				RUIN_DOOR_STATUS_PARAGRAPH:SetDesc("Status Pintu tidak terdeteksi. Memeriksa ulang...")
				task.wait(5)
			end
		end
		
		pcall(function()
			if RE_EquipToolFromHotbar then RE_EquipToolFromHotbar:FireServer(0) end
		end)
		
		AUTO_UNLOCK_STATE = false
		if AUTO_UNLOCK_ATTEMPT_THREAD then task.cancel(AUTO_UNLOCK_ATTEMPT_THREAD) AUTO_UNLOCK_ATTEMPT_THREAD = nil end
		if RUIN_AUTO_UNLOCK_TOGGLE and RUIN_AUTO_UNLOCK_TOGGLE.Set then RUIN_AUTO_UNLOCK_TOGGLE:Set(false) end
		WindUI:Notify({ Title = "Auto Unlock OFF", Content = "Proses Ruin Door dihentikan.", Duration = 3, Icon = "x" })
	end)
end

do
	local Event = Window:Tab({
		Title = "Events",
		Icon = "calendar",
		Locked = false,
	})

	local EventSyncThread = nil
    local loknes = Event:Section({
        Title = "Ancient Lochness Event",
        TextSize = 20,
    })
	local CountdownParagraph = loknes:Paragraph({
		Title = "Event Countdown: Waiting...",
		Content = "Status: Mencoba sinkronisasi event...",
		Icon = "clock"
	})
	local StatsParagraph = loknes:Paragraph({
		Title = "Event Stats: N/A",
		Content = "Timer: N/A\nCaught: N/A\nChance: N/A",
		Icon = "trending-up"
	})
	
	local LochnessToggle
	
	local function UpdateEventStats()
		local gui = GetEventGUI()
		
		if not gui then
			CountdownParagraph:SetTitle("Event Countdown: GUI Not Found ❌")
			CountdownParagraph:SetDesc("Pastikan 'Event Tracker' sudah dimuat di workspace.")
			StatsParagraph:SetTitle("Event Stats: N/A")
			StatsParagraph:SetDesc("Timer: N/A\nCaught: N/A\nChance: N/A")
			return false
		end
		
		local countdownText = gui.Countdown and (gui.Countdown.ContentText or gui.Countdown.Text) or "N/A"
		local timerText = gui.Timer and (gui.Timer.ContentText or gui.Timer.Text) or "N/A"
		local quantityText = gui.Quantity and (gui.Quantity.ContentText or gui.Quantity.Text) or "N/A"
		local oddsText = gui.Odds and (gui.Odds.ContentText or gui.Odds.Text) or "N/A"

		CountdownParagraph:SetTitle("Ancient Lochness Start In:")
		CountdownParagraph:SetDesc(countdownText)

		StatsParagraph:SetTitle("Ancient Lochness Stats")
		StatsParagraph:SetDesc(string.format("- Timer: %s\n- Caught: %s\n- Chance: %s",
			timerText, quantityText, oddsText))

		local isEventActive = timerText:find("M") and timerText:find("S") and not timerText:match("^0M 0S")
		
		return isEventActive
	end

	local function RunEventSyncLoop()
	if EventSyncThread then task.cancel(EventSyncThread) end

	EventSyncThread = task.spawn(function()
		local isTeleportedToEvent = false
		
		while true do
			local isEventActive = UpdateEventStats()
			
			if autoJoinEventActive then
				if isEventActive and not isTeleportedToEvent then
					if lastPositionBeforeEvent == nil then
						local hrp = GetHRP()
						if hrp then
							lastPositionBeforeEvent = {Pos = hrp.Position, Look = hrp.CFrame.LookVector}
							WindUI:Notify({ Title = "Posisi Disimpan", Content = "Posisi sebelum Event disimpan.", Duration = 2, Icon = "save" })
						end
					end
					
					TeleportToLookAt(LOCHNESS_POS, LOCHNESS_LOOK)
					isTeleportedToEvent = true
					WindUI:Notify({ Title = "Auto Join ON", Content = "Teleport ke Ancient Lochness.", Duration = 4, Icon = "zap" })

				elseif isTeleportedToEvent and not isEventActive and lastPositionBeforeEvent ~= nil then
					TeleportToLookAt(lastPositionBeforeEvent.Pos, lastPositionBeforeEvent.Look)
					lastPositionBeforeEvent = nil
					isTeleportedToEvent = false
					WindUI:Notify({ Title = "Event Selesai", Content = "Otomatis kembali ke posisi semula.", Duration = 4, Icon = "repeat" })
				end
			end

			task.wait(0.5)
		end
	end)
end
	
	RunEventSyncLoop()
	
	local LochnessToggle = loknes:Toggle({
		Title = "Auto Join Ancient Lochness Event",
		Desc = "Otomatis Teleport ke event saat aktif, dan kembali saat event berakhir.",
		Value = false,
        Flag = "Toggleloch",
		Callback = function(state)
			autoJoinEventActive = state
			if state then
				WindUI:Notify({ Title = "Auto Join ON", Content = "Mulai memantau event Ancient Lochness.", Duration = 3, Icon = "check" })
			else
				WindUI:Notify({ Title = "Auto Join OFF", Content = "Pemantauan dihentikan.", Duration = 3, Icon = "x" })
			end
		end
	})

	
	--RUIN_DOOR_STATUS_PARAGRAPH = loknes:Paragraph({
	--	Title = "Ruin Door Status: N/A",
	--	Content = "Status Locked/Unlocked. Tekan Toggle untuk memulai monitor."
	--})

	--local lochnessdelay = loknes:Input({
		--Title = "Ruin Door Instant Delay",
		--Desc = "Delay (dalam detik) untuk Normal Instant Fish saat farming item Ruin Door. Default: 1.5s.",
		--Value = tostring(RUIN_COMPLETE_DELAY),
       -- Flag = "inputruin",
		--Placeholder = "1.5",
		--Callback = function(input)
		--	local newDelay = tonumber(input)
		--	if newDelay and newDelay >= 0.5 then
		--		RUIN_COMPLETE_DELAY = newDelay
		--	else
		--		WindUI:Notify({ Title = "Input Invalid", Content = "Minimal delay 0.5 detik.", Duration = 2, Icon = "alert-triangle" })
		--	end
		--end
	--})

	--local RUIN_AUTO_UNLOCK_TOGGLE = loknes:Toggle({
		--Title = "Auto Unlock Ruin Door",
		--Desc = "Otomatis memfarm 4 item yang hilang menggunakan Normal Instant Fish, lalu unlock pintu.",
		--Value = false,
       -- Flag = "Toggleruin",
		--Callback = function(state)
		--AUTO_UNLOCK_STATE = state
		--if state then
		--	if GetRuinDoorStatus() == "UNLOCKED ✅" then
		--		WindUI:Notify({ Title = "Ruin Door", Content = "Pintu sudah terbuka. Auto Unlock tidak berjalan.", Duration = 4, Icon = "info" })
		--			return false
		--	end	
		--	WindUI:Notify({ Title = "Auto Unlock ON", Content = "Mulai memantau Ruin Door dan Inventory.", Duration = 3, Icon = "check" })
		--	RunAutoUnlockLoop()
		--	else
		--			if AUTO_UNLOCK_THREAD then task.cancel(AUTO_UNLOCK_THREAD) AUTO_UNLOCK_THREAD = nil end
		--			if AUTO_UNLOCK_ATTEMPT_THREAD then task.cancel(AUTO_UNLOCK_ATTEMPT_THREAD) AUTO_UNLOCK_ATTEMPT_THREAD = nil end
		--	WindUI:Notify({ Title = "Auto Unlock OFF", Content = "Proses Ruin Door dihentikan.", Duration = 3, Icon = "x" })
		--end
--end
	--})
	-- =================================================================
    -- 🕺 DISCO EVENT (AUTO STATUS UPDATE + BRUTE FORCE + LEGIT FISHING FIX)
    -- =================================================================
    Event:Divider()
    local disco = Event:Section({ Title = "Disco Event", TextSize = 20,})

    -- --- VARIABLES & CONFIGS ---
    local DISCO_UNLOCK_STATE = false
    local DISCO_UNLOCK_THREAD = nil
    local DISCO_SPAM_THREAD = nil
    local DISCO_EQUIP_THREAD = nil 
    local DISCO_PILLARS = { "Brighteyes Guppy", "Builderman Guppy", "Guest Guppy", "Shedletsky Guppy" }
    
    -- [[ GATE LOCKED DATA ]]
    local LOCKED_CFRAME = CFrame.new(-8804.5, -575.5, 168.625, 0, 0, 1, 0, 1, 0, -1, 0, 0)

    -- POSISI
    local IRON_CAVERN_POS_FIXED = Vector3.new(-8792.546, -588.000, 230.642)
    local IRON_CAVERN_LOOK_FIXED = Vector3.new(0.718, 0.000, 0.696)
    local DISCO_EVENT_POS = Vector3.new(-8641.672, -547.500, 160.322)
    local DISCO_EVENT_LOOK = Vector3.new(0.984, -0.000, 0.176)

    local FishingController = require(game:GetService("ReplicatedStorage"):WaitForChild("Controllers").FishingController)

    -- REMOTE FIX
    local RE_PlaceCavernTotemItem = nil
    pcall(function()
        RE_PlaceCavernTotemItem = game:GetService("ReplicatedStorage").Packages._Index["sleitnick_net@0.2.0"].net:WaitForChild("RE/PlaceCavernTotemItem", 5)
    end)

    -- UI STATUS
    --local DISCO_STATUS_PARAGRAPH = disco:Paragraph({ 
       -- Title = "Disco Gate Status: Checking...", 
       ---- Content = "Menunggu data...",
        --Icon = "door-open"
    --})
    -- =================================================================
    -- 🛠️ HELPER LEGIT FISHING KHUSUS DISCO (PORTED FROM FISHING TAB)
    -- =================================================================
    local Disco_LegitActive = false
    local Disco_ClickThread = nil
    local Disco_ClickSpeed = 0.05 -- Kecepatan klik legit

    local function performDiscoClick()
        if FishingController and Disco_LegitActive then
            FishingController:RequestFishingMinigameClick()
            task.wait(Disco_ClickSpeed)
        end
    end

    -- Hook FishingRodStarted (Menangani Minigame Otomatis)
    local oldRodStarted_Disco = FishingController.FishingRodStarted
    FishingController.FishingRodStarted = function(self, ...)
        oldRodStarted_Disco(self, ...) -- Jalankan fungsi asli biar game ga error
        
        if Disco_LegitActive then
            if Disco_ClickThread then task.cancel(Disco_ClickThread) end
            
            Disco_ClickThread = task.spawn(function()
                while Disco_LegitActive do
                    performDiscoClick()
                end
            end)
        end
    end

    -- Hook FishingStopped (Mematikan Thread Klik)
    local oldRodStopped_Disco = FishingController.FishingStopped
    FishingController.FishingStopped = function(self, ...)
        oldRodStopped_Disco(self, ...) -- Jalankan fungsi asli
        
        if Disco_ClickThread then 
            task.cancel(Disco_ClickThread) 
            Disco_ClickThread = nil 
        end
    end

    -- Fungsi Toggle State Legit Disco
    local function SetDiscoLegitState(bool)
        Disco_LegitActive = bool
        if not bool and Disco_ClickThread then
            task.cancel(Disco_ClickThread)
            Disco_ClickThread = nil
        end
    end
    -- =================================================================

    -- [[ FUNGSI CEK GATE ]]
    local function IsGateLocked()
        local gateModel = workspace:FindFirstChild("ClassicEvent") 
            and workspace.ClassicEvent:FindFirstChild("Finished") 
            and workspace.ClassicEvent.Finished:FindFirstChild("Gate") 
            and workspace.ClassicEvent.Finished.Gate:FindFirstChild("LeftGate")
        
        if not gateModel then return true end 

        local currentLook = gateModel:GetPivot().LookVector
        local lockedLook = LOCKED_CFRAME.LookVector
        return currentLook:Dot(lockedLook) > 0.99
    end

    -- [[ MONITOR STATUS GATE ]]
    task.spawn(function()
        while true do
            if not DISCO_UNLOCK_STATE and DISCO_STATUS_PARAGRAPH then
                if IsGateLocked() then
                    DISCO_STATUS_PARAGRAPH:SetTitle("Disco Gate: LOCKED 🔒")
                    DISCO_STATUS_PARAGRAPH:SetDesc("Gate terkunci. aktifkan auto unlock.")
                else
                    DISCO_STATUS_PARAGRAPH:SetTitle("Disco Gate: UNLOCKED ✅")
                    DISCO_STATUS_PARAGRAPH:SetDesc("Gate terbuka!")
                end
            end
            task.wait(0.5)
        end
    end)

    -- Helper Inventory
    local function IsItemAvailable_Disco(itemName)
        local replion = GetPlayerDataReplion()
        if not replion then return false end
        local success, inventoryData = pcall(function() return replion:GetExpect("Inventory") end)
        if not success or not inventoryData or not inventoryData.Items then return false end
        for _, item in ipairs(inventoryData.Items) do
            if item.Identifier == itemName then return true end
            local name, _ = GetFishNameAndRarity(item)
            if name == itemName and (item.Count or 1) >= 1 then return true end
        end
        return false
    end

    -- MAIN LOGIC LOOP
    local function RunDiscoLoop()
        if DISCO_UNLOCK_THREAD then task.cancel(DISCO_UNLOCK_THREAD) end
        if DISCO_SPAM_THREAD then task.cancel(DISCO_SPAM_THREAD) end
        if DISCO_EQUIP_THREAD then task.cancel(DISCO_EQUIP_THREAD) end
        
        -- Matikan Server Auto Fishing biar ga bentrok
        if RF_UpdateAutoFishingState then RF_UpdateAutoFishingState:InvokeServer(false) end

        -- [THREAD 1] BACKGROUND SPAMMER (Unlock Gate)
        DISCO_SPAM_THREAD = task.spawn(function()
            while DISCO_UNLOCK_STATE do
                if RE_PlaceCavernTotemItem then
                    for _, pillar in ipairs(DISCO_PILLARS) do
                        pcall(function() RE_PlaceCavernTotemItem:FireServer(pillar) end)
                        task.wait(2.1)
                        if not DISCO_UNLOCK_STATE then break end
                    end
                else
                    task.wait(1)
                end
            end
        end)

        -- [THREAD 2] AUTO EQUIP ROD (Anti-Stuck)
        DISCO_EQUIP_THREAD = task.spawn(function()
            while DISCO_UNLOCK_STATE do
                pcall(function() if RE_EquipToolFromHotbar then RE_EquipToolFromHotbar:FireServer(1) end end)
                task.wait(0.1) -- Spam equip agar selalu pegang rod
            end
        end)

        -- [THREAD 3] FARMING LOGIC (MAIN)
        DISCO_UNLOCK_THREAD = task.spawn(function()
            local isFarming = false
            
            -- Teleport ke Iron Cavern (Sekali di awal)
            if IsGateLocked() then
                TeleportToLookAt(IRON_CAVERN_POS_FIXED, IRON_CAVERN_LOOK_FIXED)
                task.wait(1.0)
                isFarming = true
            end

            while DISCO_UNLOCK_STATE do
                -- 1. Cek Status Gate
                if not IsGateLocked() then
                    DISCO_STATUS_PARAGRAPH:SetTitle("Disco Gate: UNLOCKED ✅")
                    DISCO_STATUS_PARAGRAPH:SetDesc("Event Selesai. Stop Farming.")
                    WindUI:Notify({ Title = "Gate Terbuka!", Content = "Auto Unlock Selesai.", Duration = 5, Icon = "check" })
                    break
                else
                    DISCO_STATUS_PARAGRAPH:SetTitle("Disco Gate: LOCKED 🔒")
                end

                -- 2. Cek Ikan apa yang kurang di tas
                local missingItem = nil
                for _, pillar in ipairs(DISCO_PILLARS) do
                    if not IsItemAvailable_Disco(pillar) then
                        missingItem = pillar
                        break 
                    end
                end

                -- 3. Logic Farming (Menggunakan Helper Legit Baru)
                if missingItem then
                    -- Cek posisi, balikin kalau kejauhan (jatuh/mati)
                    local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                    if hrp and (hrp.Position - IRON_CAVERN_POS_FIXED).Magnitude > 50 then
                        TeleportToLookAt(IRON_CAVERN_POS_FIXED, IRON_CAVERN_LOOK_FIXED)
                        task.wait(0.5)
                    end

                    DISCO_STATUS_PARAGRAPH:SetDesc("Farming: " .. missingItem)
                    
                    -- Aktifkan Legit Fishing State
                    SetDiscoLegitState(true) 
                    if RF_UpdateAutoFishingState then RF_UpdateAutoFishingState:InvokeServer(true) end

                else
                    -- Item lengkap, matikan fishing, fokus spam remote (Thread 1)
                    DISCO_STATUS_PARAGRAPH:SetDesc("Item Lengkap. Mencoba membuka gate...")
                    SetDiscoLegitState(false)
                    if RF_UpdateAutoFishingState then RF_UpdateAutoFishingState:InvokeServer(false) end
                end
                
                task.wait(0.5)
            end

            -- Cleanup saat loop berhenti
            DISCO_UNLOCK_STATE = false
            SetDiscoLegitState(false) -- Matikan clicker
            if DISCO_SPAM_THREAD then task.cancel(DISCO_SPAM_THREAD) end
            if DISCO_EQUIP_THREAD then task.cancel(DISCO_EQUIP_THREAD) end
            if RF_UpdateAutoFishingState then RF_UpdateAutoFishingState:InvokeServer(false) end
            
            Event:GetElementByTitle("Auto Unlock Disco Gate"):Set(false)
            pcall(function() RE_EquipToolFromHotbar:FireServer(0) end)
        end)
    end

    --local tdisco = disco:Toggle({
     --   Title = "Auto Unlock Disco Gate",
      --  Value = false,
       -- Flag = "toggledisco",
      --  Callback = function(state)
       --     DISCO_UNLOCK_STATE = state
        --    if state then
        --        if not RE_PlaceCavernTotemItem then
          ---           RE_PlaceCavernTotemItem = game:GetService("ReplicatedStorage").Packages._Index["sleitnick_net@0.2.0"].net:FindFirstChild("RE/PlaceCavernTotemItem")
          --      end
                
          --      if not IsGateLocked() then
          --           WindUI:Notify({ Title = "Info", Content = "Gate sudah terbuka.", Duration = 3 })
            --         return false
            --    end

             --   RunDiscoLoop()
             --   WindUI:Notify({ Title = "Disco Brute Force", Content = "Legit Farming + Spam Remote Started.", Duration = 3, Icon = "music" })
           -- else
                -- Matikan semua thread dan helper
              --  if DISCO_UNLOCK_THREAD then task.cancel(DISCO_UNLOCK_THREAD) end
              --  if DISCO_SPAM_THREAD then task.cancel(DISCO_SPAM_THREAD) end
               -- if DISCO_EQUIP_THREAD then task.cancel(DISCO_EQUIP_THREAD) end
                --SetDiscoLegitState(false) -- PENTING: Matikan state klik
                
               -- if RF_UpdateAutoFishingState then RF_UpdateAutoFishingState:InvokeServer(false) end
               -- WindUI:Notify({ Title = "Stopped", Duration = 2 })
            --end
        --end
    --})
    

    -- [LOGIKA BARU] AUTO JOIN DISCO + STATUS UI
    local autoJoinDiscoState = false
    local autoJoinDiscoThread = nil
    local lastPositionBeforeDisco = nil
    
    -- Tambahkan Paragraph Status Baru
    local DISCO_EVENT_STATUS_PARAGRAPH = disco:Paragraph({
        Title = "Disco Event Status: OFF",
        Content = "Aktifkan toggle untuk memantau status event...",
        Icon = "activity"
    })
    
    local function IsDiscoOpen()
        -- Cek Model Locked di path yang kamu berikan
        local lockedPath = workspace:FindFirstChild("ClassicEvent") 
            and workspace.ClassicEvent:FindFirstChild("DiscoEvent") 
            and workspace.ClassicEvent.DiscoEvent:FindFirstChild("Locked")
            
        if lockedPath then
            -- Menggunakan GetPivot() agar kompatibel jika itu Model atau BasePart
            local pivot = lockedPath:GetPivot()
            
            -- Data kamu:
            -- Locked Open (Turun): Y = -642.64
            -- Locked Closed (Naik): Y = -556.89
            -- Kita pakai threshold -600. Jika Y lebih KECIL dari -600 (lebih dalam), berarti OPEN.
            
            if pivot.Position.Y < -600 then
                return true -- OPEN / ACTIVE
            else
                return false -- CLOSED / INACTIVE
            end
        end
        return false -- Default closed if not found
    end

    local function RunAutoJoinDiscoLoop()
        if autoJoinDiscoThread then task.cancel(autoJoinDiscoThread) end
        
        autoJoinDiscoThread = task.spawn(function()
            local isAtDisco = false
            
            -- Update status awal
            DISCO_EVENT_STATUS_PARAGRAPH:SetTitle("Disco Event Status: MONITORING...")
            
            while autoJoinDiscoState do
                local isOpen = IsDiscoOpen()
                
                -- UPDATE STATUS PANEL (REAL-TIME)
                if isOpen then
                    DISCO_EVENT_STATUS_PARAGRAPH:SetTitle("Disco Event: OPEN 🕺")
                    DISCO_EVENT_STATUS_PARAGRAPH:SetDesc("Kolam disco terbuka! (Event Aktif)")
                else
                    DISCO_EVENT_STATUS_PARAGRAPH:SetTitle("Disco Event: CLOSED 💤")
                    DISCO_EVENT_STATUS_PARAGRAPH:SetDesc("Event belum dimulai / sudah berakhir.")
                end
                
                -- LOGIKA TELEPORT
                if isOpen and not isAtDisco then
                    -- Event Buka: Simpan posisi & Teleport
                    local hrp = GetHRP()
                    if hrp then
                        lastPositionBeforeDisco = {Pos = hrp.Position, Look = hrp.CFrame.LookVector}
                    end
                    
                    TeleportToLookAt(DISCO_EVENT_POS, DISCO_EVENT_LOOK)
                    isAtDisco = true
                    WindUI:Notify({ Title = "Disco Open!", Content = "Teleporting to Disco Event...", Duration = 4, Icon = "music" })
                    
                elseif not isOpen and isAtDisco then
                    -- Event Tutup: Balik ke posisi awal
                    if lastPositionBeforeDisco then
                        TeleportToLookAt(lastPositionBeforeDisco.Pos, lastPositionBeforeDisco.Look)
                        lastPositionBeforeDisco = nil
                        WindUI:Notify({ Title = "Disco Selesai", Content = "Kembali ke posisi semula.", Duration = 4, Icon = "repeat" })
                    end
                    isAtDisco = false
                end
                
                task.wait(1) -- Cek setiap 1 detik
            end
        end)
    end

    -- TOGGLE AUTO JOIN DISCO (Updated)
    local joindisco = disco:Toggle({
        Title = "Auto Join Disco Event",
        Desc = "Otomatis TP saat event aktif dan kembali ke tempat awal saat event berakhir",
        Value = false,
        Flag = "tjoindisco",
        Callback = function(state)
            autoJoinDiscoState = state
            if state then
                WindUI:Notify({ Title = "Auto Join Disco ON", Content = "Memantau status Disco Gate...", Duration = 3, Icon = "check" })
                RunAutoJoinDiscoLoop()
            else
                if autoJoinDiscoThread then task.cancel(autoJoinDiscoThread) end
                
                -- Reset Status Panel saat dimatikan
                DISCO_EVENT_STATUS_PARAGRAPH:SetTitle("Disco Event Status: OFF")
                DISCO_EVENT_STATUS_PARAGRAPH:SetDesc("Aktifkan toggle untuk memantau status event...")
                
                WindUI:Notify({ Title = "Auto Join Disco OFF", Duration = 3, Icon = "x" })
            end
        end
    })

    local bdisco = disco:Button({
        Title = "Teleport to Disco Event",
        Icon = "map-pin",
        Callback = function()
            TeleportToLookAt(DISCO_EVENT_POS, DISCO_EVENT_LOOK)
        end
    })

Event:Divider()

    -- =================================================================
    -- 🎁 AUTO CLAIM CLASSIC REWARDS (1-15)
    -- =================================================================
    
    local autoClaimClassicState = false
    local autoClaimClassicThread = nil
    
    -- Definisi Remote Claim
    local RE_ClaimEventReward = nil
    pcall(function()
        RE_ClaimEventReward = game:GetService("ReplicatedStorage")
            :WaitForChild("Packages", 10)
            :WaitForChild("_Index", 10)
            :WaitForChild("sleitnick_net@0.2.0", 10)
            :WaitForChild("net", 10)
            :WaitForChild("RE/ClaimEventReward", 10)
    end)
    local sectionclassic = Event:Section({
        Title = "Classic Event Rewards",
        TextSize = 20,
    })
    local tclassic = sectionclassic:Toggle({
        Title = "Auto Claim Classic Event Rewards",
        Value = false,
        Flag = "taclaimclassic",
        Icon = "gift",
        Callback = function(state)
            autoClaimClassicState = state
            
            if state then
                -- Cek remote dulu
                if not RE_ClaimEventReward then
                    RE_ClaimEventReward = game:GetService("ReplicatedStorage").Packages._Index["sleitnick_net@0.2.0"].net:FindFirstChild("RE/ClaimEventReward")
                end
                
                if not RE_ClaimEventReward then
                    WindUI:Notify({ Title = "Error", Content = "Remote Claim Reward tidak ditemukan.", Duration = 3, Icon = "x" })
                    return false
                end

                WindUI:Notify({ Title = "Auto Claim ON", Duration = 3, Icon = "gift" })

                if autoClaimClassicThread then task.cancel(autoClaimClassicThread) end
                
                autoClaimClassicThread = task.spawn(function()
                    while autoClaimClassicState do
                        -- Loop 1 sampai 15
                        for i = 1, 15 do
                            if not autoClaimClassicState then break end
                            
                            pcall(function()
                                RE_ClaimEventReward:FireServer(i)
                            end)
                            
                            -- Jeda sangat singkat antar claim biar aman
                            task.wait(0.1) 
                        end
                        
                        -- Ulangi cek setiap 10 detik (jaga-jaga baru naik level)
                        task.wait(60)
                    end
                end)
            else
                if autoClaimClassicThread then task.cancel(autoClaimClassicThread) autoClaimClassicThread = nil end
                WindUI:Notify({ Title = "Auto Claim OFF", Duration = 2, Icon = "x" })
            end
        end
    })
end

--GetRuinDoorStatus()

do
local utility = Window:Tab({
    Title = "Tools",
    Icon = "box",
    Locked = false,
})

-- =================================================================
-- 🐟 FUNGSI SCAN BACKPACK
-- =================================================================
--local backpack = utility:Section({ Title = "Backpack Scanner", TextSize = 20, })
--local FishScanDisplay = backpack:Paragraph({
  --  Title = "Status: Scan untuk melihat detail item...",
   -- Desc = "Klik tombol 'Scan Backpack' untuk mendapatkan daftar ikan di inventaris Anda.",
   -- Icon = "clipboard-list"
--})

local function RunBackpackScan()
    local fishData = {}
    local totalCount = 0

    local replion = GetPlayerDataReplion()
    if not replion or not ItemUtility or not TierUtility then
        FishScanDisplay:SetTitle("Scan Gagal: Data Utility/Replion Missing.")
        FishScanDisplay:SetDesc("Pastikan ItemUtility & TierUtility sudah di-require & Replion aktif.")
        return
    end

    local success, inventoryData = pcall(function() return replion:GetExpect("Inventory") end)

    if not success or not inventoryData or not inventoryData.Items then
        FishScanDisplay:SetTitle("Scan Gagal: Gagal membaca Inventory.")
        return
    end

    -- Mengumpulkan data ikan
    for _, item in ipairs(inventoryData.Items) do
        if item.Metadata and item.Metadata.Weight then
            local name, rarity = GetFishNameAndRarity(item)
            
            local mutation = GetItemMutationString(item)
            local count = item.Count or 1
            local favoriteStatus = (item.IsFavorite or item.Favorited) and "⭐" or " "
            
            local key = name .. rarity .. mutation
            
            if not fishData[key] then
                fishData[key] = { Count = 0, Rarity = rarity, Mutation = mutation, Favorite = favoriteStatus, Name = name }
            end

            fishData[key].Count = fishData[key].Count + count
            totalCount = totalCount + count
        end
    end

    -- Memformat hasil ke dalam string display
    local details = {"\n**--- FISH DETAILS (" .. totalCount .. " items) ---**"}
    
    local sortedFish = {}
    for _, data in pairs(fishData) do table.insert(sortedFish, data) end
    
    local rarityOrder = { ["COMMON"] = 1, ["UNCOMMON"] = 2, ["RARE"] = 3, ["EPIC"] = 4, ["LEGENDARY"] = 5, ["MYTHIC"] = 6, ["SECRET"] = 7, ["TROPHY"] = 8, ["COLLECTIBLE"] = 9, ["DEV"] = 10 }
    table.sort(sortedFish, function(a, b)
        local orderA = rarityOrder[a.Rarity:upper()] or 0
        local orderB = rarityOrder[b.Rarity:upper()] or 0
        return orderA > orderB
    end)
    
    for _, item in ipairs(sortedFish) do
        local mutationString = item.Mutation ~= "" and string.format(" [%s]", item.Mutation) or ""
        
        table.insert(details, string.format("%s %s%s (%s) x%d",
            item.Favorite, item.Name, mutationString, item.Rarity, item.Count
        ))
    end
    
    FishScanDisplay:SetTitle(string.format("Scan Selesai! Total Ikan: %d", totalCount))
    FishScanDisplay:SetDesc(table.concat(details, "\n"))
    
    WindUI:Notify({ Title = "Backpack Scanned!", Content = "Lihat detail di UI.", Duration = 3, Icon = "package" })
end

--local scanow = backpack:Button({ Title = "Scan Backpack Now", Icon = "search", Callback = RunBackpackScan })


--utility:Divider()

local misc = utility:Section({ Title = "Misc. Area", TextSize = 20})

local RF_UpdateFishingRadar = GetRemote(RPath, "RF/UpdateFishingRadar")

local tfishradar = misc:Toggle({
    Title = "Enable Fishing Radar",
    Desc = "ON/OFF Fishing Radar",
    Value = false,
    Flag = "Toggleradar",
    Icon = "compass",
    Callback = function(state)
        if not RF_UpdateFishingRadar then
            WindUI:Notify({ Title = "Error", Content = "Remote 'RF/UpdateFishingRadar' tidak ditemukan.", Duration = 3, Icon = "x" })
            return false
        end

        pcall(function()
            RF_UpdateFishingRadar:InvokeServer(state)
        end)

        if state then
            WindUI:Notify({ Title = "Fishing Radar ON", Content = "Fishing Radar diaktifkan.", Duration = 3, Icon = "check" })
        else
            WindUI:Notify({ Title = "Fishing Radar OFF", Content = "Fishing Radar dinonaktifkan.", Duration = 3, Icon = "x" })
        end
    end
})

-- 💧 FUNGSI BARU: EQUIP OXYGEN TANK
local RF_EquipOxygenTank = GetRemote(RPath, "RF/EquipOxygenTank")
local RF_UnequipOxygenTank = GetRemote(RPath, "RF/UnequipOxygenTank")

local ttank = misc:Toggle({
    Title = "Equip Oxigen Tank",
    Desc = "infinite oxygen",
    Value = false,
    Flag = "Toggletank",
    Icon = "life-buoy",
    Callback = function(state)
        if state then
            if not RF_EquipOxygenTank then
                WindUI:Notify({ Title = "Error", Duration = 3, Icon = "x" })
                return false
            end
            
            pcall(function()
                RF_EquipOxygenTank:InvokeServer(105) -- ID 105 untuk Oxygen Tank
            end)
            WindUI:Notify({ Title = "Oxygen Tank Equipped", Duration = 3, Icon = "check" })
        else
            if not RF_UnequipOxygenTank then
                WindUI:Notify({ Title = "Error", Duration = 3, Icon = "x" })
                return true -- Tetap kembalikan true agar toggle tidak stuck
            end
            
            pcall(function()
                RF_UnequipOxygenTank:InvokeServer()
            end)
            WindUI:Notify({ Title = "Oxygen Tank Unequipped", Content = "Oxygen Tank dilepas.", Duration = 3, Icon = "x" })
        end
    end
})

local REObtainedNewFishNotification = GetRemote(RPath, "RE/ObtainedNewFishNotification")
local RunService = game:GetService("RunService")

local notif = misc:Toggle({
    Title = "Remove Fish Notification Pop-up",
    Value = false,
    Flag = "togglenotif",
    Icon = "slash",
    Callback = function(state)
        local PlayerGui = game:GetService("Players").LocalPlayer.PlayerGui
        local SmallNotification = PlayerGui:FindFirstChild("Small Notification")
        
        if not SmallNotification then
            SmallNotification = PlayerGui:WaitForChild("Small Notification", 5)
            if not SmallNotification then
                WindUI:Notify({ Title = "Error", Duration = 3, Icon = "x" })
                return false
            end
        end

        if state then
            -- ON: Menggunakan RenderStepped untuk pemblokiran per-frame
            DisableNotificationConnection = RunService.RenderStepped:Connect(function()
                -- Memastikan GUI selalu mati pada setiap frame render
                SmallNotification.Enabled = false
            end)
            
            WindUI:Notify({ Title = "Pop-up Diblokir",Duration = 3, Icon = "check" })
        else
            -- OFF: Putuskan koneksi RenderStepped
            if DisableNotificationConnection then
                DisableNotificationConnection:Disconnect()
                DisableNotificationConnection = nil
            end

            -- Kembalikan GUI ke status normal (aktif)
            SmallNotification.Enabled = true
            
            WindUI:Notify({ Title = "Pop-up Diaktifkan", Content = "Notifikasi kembali normal.", Duration = 3, Icon = "x" })
        end
    end
})


local isNoAnimationActive = false
local originalAnimator = nil
local originalAnimateScript = nil

local function DisableAnimations()
    local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    
    if not humanoid then return end

    -- 1. Blokir script 'Animate' bawaan (yang memuat default anim)
    local animateScript = character:FindFirstChild("Animate")
    if animateScript and animateScript:IsA("LocalScript") and animateScript.Enabled then
        originalAnimateScript = animateScript.Enabled
        animateScript.Enabled = false
    end

    -- 2. Hapus Animator (menghalangi semua animasi dimainkan/dimuat)
    local animator = humanoid:FindFirstChildOfClass("Animator")
    if animator then
        -- Simpan referensi objek Animator aslinya
        originalAnimator = animator 
        animator:Destroy()
    end
end

local function EnableAnimations()
    local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    
    -- 1. Restore script 'Animate'
    local animateScript = character:FindFirstChild("Animate")
    if animateScript and originalAnimateScript ~= nil then
        animateScript.Enabled = originalAnimateScript
    end
    
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid then return end

    -- 2. Restore/Tambahkan Animator
    local existingAnimator = humanoid:FindFirstChildOfClass("Animator")
    if not existingAnimator then
        -- Jika Animator tidak ada, dan kita memiliki objek aslinya, restore
        if originalAnimator and not originalAnimator.Parent then
            originalAnimator.Parent = humanoid
        else
            -- Jika objek asli hilang, buat yang baru
            Instance.new("Animator").Parent = humanoid
        end
    end
    originalAnimator = nil -- Bersihkan referensi lama
end

local function OnCharacterAdded(newCharacter)
    if isNoAnimationActive then
        task.wait(0.2) -- Tunggu sebentar agar LoadCharacter selesai
        DisableAnimations()
    end
end

-- Hubungkan ke CharacterAdded agar tetap berfungsi saat respawn
LocalPlayer.CharacterAdded:Connect(OnCharacterAdded)

local anim = misc:Toggle({
    Title = "No Animation",
    Value = false,
    Flag = "toggleanim",
    Icon = "skull",
    Callback = function(state)
        isNoAnimationActive = state
        if state then
            DisableAnimations()
            WindUI:Notify({ Title = "No Animation ON!", Duration = 3, Icon = "zap" })
        else
            EnableAnimations()
            WindUI:Notify({ Title = "No Animation OFF!", Duration = 3, Icon = "x" })
        end
    end
})

-- Tambahkan di bagian atas blok 'utility'
local VFXControllerModule = require(game:GetService("ReplicatedStorage"):WaitForChild("Controllers").VFXController)
local originalVFXHandle = VFXControllerModule.Handle
local originalPlayVFX = VFXControllerModule.PlayVFX.Fire -- Asumsi PlayVFX adalah Signal/Event yang memiliki Fire

-- Variabel global untuk status VFX
local isVFXDisabled = false


local tskin = misc:Toggle({
    Title = "Remove Skin Effect",
    Value = false,
    Flag = "toggleskin",
    Icon = "slash",
    Callback = function(state)
        isVFXDisabled = state

        if state then
            -- 1. Blokir fungsi Handle (dipanggil oleh Handle Remote dan PlayVFX Signal)
            VFXControllerModule.Handle = function(...) 
                -- Memastikan tidak ada kode efek yang berjalan 
            end

            -- 2. Blokir fungsi RenderAtPoint dan RenderInstance (untuk jaga-jaga)
            VFXControllerModule.RenderAtPoint = function(...) end
            VFXControllerModule.RenderInstance = function(...) end
            
            -- 3. Hapus semua efek yang sedang aktif (opsional, untuk membersihkan layar)
            local cosmeticFolder = workspace:FindFirstChild("CosmeticFolder")
            if cosmeticFolder then
                pcall(function() cosmeticFolder:ClearAllChildren() end)
            end

            WindUI:Notify({ Title = "No Skin Effect ON", Duration = 3, Icon = "eye-off" })
        else
            -- 1. Kembalikan fungsi Handle asli
            VFXControllerModule.Handle = originalVFXHandle
        end
    end
})

local CutsceneController = nil
    local OldPlayCutscene = nil
    local isNoCutsceneActive = false

    -- Mencoba require module CutsceneController dengan aman
    pcall(function()
        CutsceneController = require(game:GetService("ReplicatedStorage"):WaitForChild("Controllers"):WaitForChild("CutsceneController"))
        if CutsceneController and CutsceneController.Play then
            OldPlayCutscene = CutsceneController.Play
            
            -- Overwrite fungsi Play
            CutsceneController.Play = function(self, ...)
                if isNoCutsceneActive then
                    -- Jika aktif, jangan jalankan apa-apa (Skip Cutscene)
                    return 
                end
                -- Jika tidak aktif, jalankan fungsi asli
                return OldPlayCutscene(self, ...)
            end
        end
    end)

    local tcutscen = misc:Toggle({
        Title = "No Cutscene",
        Value = false,
        Flag = "tnocut",
        Icon = "film", -- Icon film strip
        Callback = function(state)
            isNoCutsceneActive = state
            
            if not CutsceneController then
                WindUI:Notify({ Title = "Gagal Hook", Content = "Module CutsceneController tidak ditemukan.", Duration = 3, Icon = "x" })
                return
            end

            if state then
                WindUI:Notify({ Title = "No Cutscene ON", Content = "Animasi tangkapan dimatikan.", Duration = 3, Icon = "video-off" })
            else
                WindUI:Notify({ Title = "No Cutscene OFF", Content = "Animasi kembali normal.", Duration = 3, Icon = "video" })
            end
        end
    })

    local defaultMaxZoom = LocalPlayer.CameraMaxZoomDistance or 128
    local zoomLoopConnection = nil

    --local tzoom = misc:Toggle({
      --  Title = "Infinite Zoom Out",
       -- Value = false,
       -- Flag = "infzoom",
       -- Icon = "maximize",
       -- Callback = function(state)
         --   if state then
                -- 1. Simpan nilai asli dulu buat jaga-jaga
          --      defaultMaxZoom = LocalPlayer.CameraMaxZoomDistance
                
                -- 2. Paksa nilai zoom jadi besar
          --      LocalPlayer.CameraMaxZoomDistance = 100000
                
                -- 3. Pasang loop (RenderStepped) untuk memaksa nilai tetap besar
                -- Ini berguna kalau game mencoba mengembalikan zoom ke normal
            --    if zoomLoopConnection then zoomLoopConnection:Disconnect() end
             --   zoomLoopConnection = game:GetService("RunService").RenderStepped:Connect(function()
              --      LocalPlayer.CameraMaxZoomDistance = 100000
              --  end)
                
               -- WindUI:Notify({ Title = "Zoom Unlocked", Content = "Sekarang bisa zoom out sejauh mungkin.", Duration = 3, Icon = "maximize" })
            --else
                -- 1. Matikan loop pemaksa
            --    if zoomLoopConnection then 
             --       zoomLoopConnection:Disconnect() 
             --       zoomLoopConnection = nil
            --    end
           --     
                -- 2. Kembalikan ke nilai asli
          --      LocalPlayer.CameraMaxZoomDistance = defaultMaxZoom
          --      
        --        WindUI:Notify({ Title = "Zoom Normal", Content = "Limit zoom dikembalikan.", Duration = 3, Icon = "minimize" })
      --      end
      --  end
   -- })

    -- 1. Toggle Disable 3D Rendering
    local is3DDisabled = false
    local t3d = misc:Toggle({
        Title = "Disable 3D Rendering",
        Value = false,
        Flag = "Toggle3d",
        Callback = function(state)
            is3DDisabled = state
            local camera = workspace.CurrentCamera
            
            if state then
                WindUI:Notify({
                    Title = "3D Rendering OFF",
                    Content = "Semua objek 3D disembunyikan untuk FPS maksimal.",
                    Duration = 3,
                    Icon = "eye-off",
                })
                camera:GetPropertyChangedSignal("CFrame"):Connect(function()
                    if is3DDisabled then
                        camera.CFrame = camera.CFrame
                    end
                end)
                game:GetService("RunService"):Set3dRenderingEnabled(false)
            else
                WindUI:Notify({
                    Title = "3D Rendering ON",
                    Content = "Visual kembali normal.",
                    Duration = 3,
                    Icon = "eye",
                })
                game:GetService("RunService"):Set3dRenderingEnabled(true)
            end
        end
    })

    -- 2. FPS Ultra Boost (fungsi helper)
    -- Tambahkan/Ganti di dekat helper global Anda
local isBoostActive = false
local originalLightingValues = {}

local function ToggleFPSBoost(enabled)
    isBoostActive = enabled
    local Lighting = game:GetService("Lighting")
    local Terrain = workspace:FindFirstChildOfClass("Terrain")

    if enabled then
        -- Simpan nilai asli sekali saja
        if not next(originalLightingValues) then
            originalLightingValues.GlobalShadows = Lighting.GlobalShadows
            originalLightingValues.FogEnd = Lighting.FogEnd
            originalLightingValues.Brightness = Lighting.Brightness
            originalLightingValues.ClockTime = Lighting.ClockTime
            originalLightingValues.Ambient = Lighting.Ambient
            originalLightingValues.OutdoorAmbient = Lighting.OutdoorAmbient
        end
        
        -- 1. VISUAL & EFEK (Hanya mematikan)
        pcall(function()
            for _, v in pairs(workspace:GetDescendants()) do
                if v:IsA("ParticleEmitter") or v:IsA("Trail") or v:IsA("Smoke") or v:IsA("Fire") or v:IsA("Explosion") then
                    v.Enabled = false
                elseif v:IsA("Beam") or v:IsA("Light") then
                    v.Enabled = false
                elseif v:IsA("Decal") or v:IsA("Texture") then
                    v.Transparency = 1 
                end
            end
        end)
        
        -- 2. LIGHTING & ENVIRONMENT (Pengaturan Minimalis)
        pcall(function()
            for _, effect in pairs(Lighting:GetChildren()) do
                if effect:IsA("PostEffect") then effect.Enabled = false end
            end
            Lighting.GlobalShadows = false
            Lighting.FogEnd = 9e9
            Lighting.Brightness = 0 -- Lebih gelap/kontras untuk efisiensi
            Lighting.ClockTime = 14 -- Siang tanpa bayangan
            Lighting.Ambient = Color3.new(0, 0, 0)
            Lighting.OutdoorAmbient = Color3.new(0, 0, 0)
        end)
        
        -- 3. TERRAIN & WATER
        if Terrain then
            pcall(function()
                Terrain.WaterWaveSize = 0
                Terrain.WaterWaveSpeed = 0
                Terrain.WaterReflectance = 0
                Terrain.WaterTransparency = 1
                Terrain.Decoration = false
            end)
        end
        
        -- 4. QUALITY & EXPLOIT TRICKS
        pcall(function()
            settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
            settings().Rendering.MeshPartDetailLevel = Enum.MeshPartDetailLevel.Level01
            settings().Rendering.TextureQuality = Enum.TextureQuality.Low
        end)

        if type(setfpscap) == "function" then pcall(function() setfpscap(100) end) end 
        if type(collectgarbage) == "function" then collectgarbage("collect") end

        WindUI:Notify({ Title = "FPS Boost", Content = "Maximum FPS mode enabled (Minimal Graphics).", Duration = 3, Icon = "zap" })
    else
        -- RESET
        pcall(function()
            if originalLightingValues.GlobalShadows ~= nil then
                Lighting.GlobalShadows = originalLightingValues.GlobalShadows
                Lighting.FogEnd = originalLightingValues.FogEnd
                Lighting.Brightness = originalLightingValues.Brightness
                Lighting.ClockTime = originalLightingValues.ClockTime
                Lighting.Ambient = originalLightingValues.Ambient
                Lighting.OutdoorAmbient = originalLightingValues.OutdoorAmbient
            end
            settings().Rendering.QualityLevel = Enum.QualityLevel.Automatic
            
            for _, effect in pairs(Lighting:GetChildren()) do
                if effect:IsA("PostEffect") then effect.Enabled = true end
            end
        end)
        
        if type(setfpscap) == "function" then pcall(function() setfpscap(60) end) end
        
        WindUI:Notify({ Title = "FPS Boost", Content = "Graphics reset to default/automatic. Rejoin recommended.", Duration = 3, Icon = "rotate-ccw" })
    end
end

    local tfps = misc:Toggle({
        Title = "FPS Ultra Boost",
        Value = false,
        Flag = "Togglefps",
        Callback = function(state)
            ToggleFPSBoost(state)
        end
    })

utility:Divider()

-- =================================================================
    -- 🌐 SERVER MANAGEMENT (REJOIN & HOP)
    -- =================================================================
    local serverm = utility:Section({ Title = "Server Management", TextSize = 20})

    local TeleportService = game:GetService("TeleportService")
    local HttpService = game:GetService("HttpService")
    local Players = game:GetService("Players")

    -- 1. REJOIN SERVER
    local brejoin = serverm:Button({
        Title = "Rejoin Server",
        Desc = "Masuk ulang ke server ini (Refresh game).",
        Icon = "rotate-cw",
        Callback = function()
            WindUI:Notify({ Title = "Rejoining...", Content = "Tunggu sebentar...", Duration = 3, Icon = "loader" })
            
            -- Queue script agar dieksekusi lagi pas rejoin (Optional, tergantung executor support)
            if syn and syn.queue_on_teleport then
                syn.queue_on_teleport('loadstring(game:HttpGet("URL_SCRIPT_KAMU_DISINI"))()')
            elseif queue_on_teleport then
                queue_on_teleport('loadstring(game:HttpGet("URL_SCRIPT_KAMU_DISINI"))()')
            end

            if #Players:GetPlayers() <= 1 then
                -- Kalau sendiri, Teleport biasa (akan buat server baru/masuk ulang)
                Players.LocalPlayer:Kick("\n[RockHub] Rejoining...")
                task.wait()
                TeleportService:Teleport(game.PlaceId, Players.LocalPlayer)
            else
                -- Kalau rame, masuk ke Instance yang sama
                TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, Players.LocalPlayer)
            end
        end
    })

    -- 2. SERVER HOP (RANDOM)
    local bhop = serverm:Button({
        Title = "Server Hop (Random)",
        Desc = "Pindah ke server lain secara acak.",
        Icon = "arrow-right-circle",
        Callback = function()
            WindUI:Notify({ Title = "Hopping...", Content = "Mencari server baru...", Duration = 3, Icon = "search" })
            
            task.spawn(function()
                local PlaceId = game.PlaceId
                local JobId = game.JobId
                
                local sfUrl = "https://games.roblox.com/v1/games/%s/servers/Public?sortOrder=Desc&limit=100&excludeFullGames=true"
                local req = game:HttpGet(string.format(sfUrl, PlaceId))
                local body = HttpService:JSONDecode(req)
        
                if body and body.data then
                    local servers = {}
                    for _, v in ipairs(body.data) do
                        -- Filter: Bukan server saat ini, dan belum penuh
                        if type(v) == "table" and v.maxPlayers > v.playing and v.id ~= JobId then
                            table.insert(servers, v.id)
                        end
                    end
        
                    if #servers > 0 then
                        local randomServerId = servers[math.random(1, #servers)]
                        WindUI:Notify({ Title = "Server Found", Content = "Teleporting...", Duration = 3, Icon = "plane" })
                        TeleportService:TeleportToPlaceInstance(PlaceId, randomServerId, Players.LocalPlayer)
                    else
                        WindUI:Notify({ Title = "Gagal Hop", Content = "Tidak menemukan server lain yang cocok.", Duration = 3, Icon = "x" })
                    end
                else
                    WindUI:Notify({ Title = "API Error", Content = "Gagal mengambil daftar server.", Duration = 3, Icon = "alert-triangle" })
                end
            end)
        end
    })

    -- 1. COPY JOB ID SAAT INI
    local copyjobid = serverm:Button({
        Title = "Copy Current Job ID",
        Desc = "Salin ID Server ini ke clipboard.",
        Icon = "copy",
        Callback = function()
            local jobId = game.JobId
            setclipboard(jobId)
            WindUI:Notify({ 
                Title = "Copied!", 
                Content = "Job ID disalin ke clipboard.", 
                Duration = 3, 
                Icon = "check" 
            })
        end
    })

    -- Variabel penyimpanan input
    local targetJoinID = ""

    -- 2. INPUT FIELD JOB ID
    local injobid = serverm:Input({
        Title = "Target Job ID",
        Desc = "Paste Job ID server tujuan di sini.",
        Value = "",
        Placeholder = "Paste Job ID here...",
        Icon = "keyboard",
        Flag = "jobidinput",
        Callback = function(text)
            targetJoinID = text
        end
    })

    -- 3. TOMBOL JOIN
    local joinid = serverm:Button({
        Title = "Join Server by ID",
        Desc = "Teleport ke Job ID yang dimasukkan di atas.",
        Icon = "log-in",
        Callback = function()
            if targetJoinID == "" then
                WindUI:Notify({ Title = "Error", Content = "Masukkan Job ID dulu di kolom input!", Duration = 3, Icon = "alert-triangle" })
                return
            end

            -- Cek apakah ID-nya sama dengan server sekarang (biar gak buang waktu)
            if targetJoinID == game.JobId then
                WindUI:Notify({ Title = "Info", Content = "Kamu sudah berada di server ini!", Duration = 3, Icon = "info" })
                return
            end

            WindUI:Notify({ Title = "Joining...", Content = "Mencoba masuk ke server ID...", Duration = 3, Icon = "plane" })
            
            -- Eksekusi Teleport
            local success, err = pcall(function()
                game:GetService("TeleportService"):TeleportToPlaceInstance(game.PlaceId, targetJoinID, game.Players.LocalPlayer)
            end)

            if not success then
                WindUI:Notify({ Title = "Gagal", Content = "ID Server Salah / Server Penuh / Expired.", Duration = 5, Icon = "x" })
            end
        end
    })
    --utility:Divider()
utility:Keybind({
    Title = "Keybind",
    Desc = "Keybind to open/close ui",
    Value = "F",
    Callback = function(v)
        Window:SetToggleKey(Enum.KeyCode[v])
    end
})
end

do
    local webhook = Window:Tab({
        Title = "Webhook",
        Icon = "send",
        Locked = false,
    })

    -- Variabel lokal untuk menyimpan data
    local WEBHOOK_URL = ""
    local WEBHOOK_USERNAME = "RockHub Notify" 
    local isWebhookEnabled = false
    local SelectedRarityCategories = {}
    
    -- Variabel KHUSUS untuk Global Webhook
    local GLOBAL_WEBHOOK_URL = "https://discord.com/api/webhooks/1438756450972471387/gHuV9K4UmiTjqK3F9KRt720HkGvLJGogwJ9uh17b7QpqMd1ieBC_UdKAX95ozTanWH37"
    local GLOBAL_WEBHOOK_USERNAME = "RockHub | Community"
    local GLOBAL_RARITY_FILTER = {"SECRET", "TROPHY", "COLLECTIBLE", "DEV"}

    local RarityList = {"Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic", "Secret", "Trophy", "Collectible", "DEV"}
    
    local REObtainedNewFishNotification = GetRemote(RPath, "RE/ObtainedNewFishNotification")
    local HttpService = game:GetService("HttpService")
    local WebhookStatusParagraph -- Forward declaration

    -- ============================================================
    -- 🖼️ SISTEM CACHE GAMBAR (BARU)
    -- ============================================================
    local ImageURLCache = {} -- Table untuk menyimpan Link Gambar (ID -> URL)

    -- FUNGSI HELPER: Format Angka (Updated: Full Digit dengan Titik)
    local function FormatNumber(n)
        n = math.floor(n) -- Bulatkan ke bawah biar ga ada desimal aneh
        -- Logic: Balik string -> Tambah titik tiap 3 digit -> Balik lagi
        local formatted = tostring(n):reverse():gsub("%d%d%d", "%1."):reverse()
        -- Hapus titik di paling depan jika ada (clean up)
        return formatted:gsub("^%.", "")
    end
    
    local function UpdateWebhookStatus(title, content, icon)
        if WebhookStatusParagraph then
            WebhookStatusParagraph:SetTitle(title)
            WebhookStatusParagraph:SetDesc(content)
        end
    end

    -- FUNGSI GET IMAGE DENGAN CACHE
    local function GetRobloxAssetImage(assetId)
        if not assetId or assetId == 0 then return nil end
        
        -- 1. Cek Cache dulu!
        if ImageURLCache[assetId] then
            return ImageURLCache[assetId]
        end
        
        -- 2. Jika tidak ada di cache, baru panggil API
        local url = string.format("https://thumbnails.roblox.com/v1/assets?assetIds=%d&size=420x420&format=Png&isCircular=false", assetId)
        local success, response = pcall(game.HttpGet, game, url)
        
        if success then
            local ok, data = pcall(HttpService.JSONDecode, HttpService, response)
            if ok and data and data.data and data.data[1] and data.data[1].imageUrl then
                local finalUrl = data.data[1].imageUrl
                
                -- 3. Simpan ke Cache agar request berikutnya instan
                ImageURLCache[assetId] = finalUrl
                return finalUrl
            end
        end
        return nil
    end

    local function sendExploitWebhook(url, username, embed_data)
        local payload = {
            username = username,
            embeds = {embed_data} 
        }
        
        local json_data = HttpService:JSONEncode(payload)
        
        if typeof(request) == "function" then
            local success, response = pcall(function()
                return request({
                    Url = url,
                    Method = "POST",
                    Headers = { ["Content-Type"] = "application/json" },
                    Body = json_data
                })
            end)
            
            if success and (response.StatusCode == 200 or response.StatusCode == 204) then
                 return true, "Sent"
            elseif success and response.StatusCode then
                return false, "Failed: " .. response.StatusCode
            elseif not success then
                return false, "Error: " .. tostring(response)
            end
        end
        return false, "No Request Func"
    end
    
    local function getRarityColor(rarity)
        local r = rarity:upper()
        if r == "SECRET" then return 0xFFD700 end
        if r == "MYTHIC" then return 0x9400D3 end
        if r == "LEGENDARY" then return 0xFF4500 end
        if r == "EPIC" then return 0x8A2BE2 end
        if r == "RARE" then return 0x0000FF end
        if r == "UNCOMMON" then return 0x00FF00 end
        return 0x00BFFF
    end

    local function shouldNotify(fishRarityUpper, fishMetadata)
        if not SelectedRarityCategories or #SelectedRarityCategories == 0 then
            return false
        end
        
        if table.find(SelectedRarityCategories, fishRarityUpper) then
            return true
        end

        if _G.NotifyOnMutation and (fishMetadata.Shiny or fishMetadata.VariantId) then
             return true
        end
        
        return false
    end
    
    -- FUNGSI UNTUK MENGIRIM PESAN IKAN AKTUAL (FIXED PATH: {"Coins"})
    local function onFishObtained(itemId, metadata, fullData)
        local success, results = pcall(function()
            local dummyItem = {Id = itemId, Metadata = metadata}
            local fishName, fishRarity = GetFishNameAndRarity(dummyItem)
            local fishRarityUpper = fishRarity:upper()

            -- --- START: Ambil Data Embed Umum ---
            local fishWeight = string.format("%.2fkg", metadata.Weight or 0)
            local mutationString = GetItemMutationString(dummyItem)
            local mutationDisplay = mutationString ~= "" and mutationString or "N/A"
            local itemData = ItemUtility:GetItemData(itemId)
            
            -- Handling Image
            local assetId = nil
            if itemData and itemData.Data then
                local iconRaw = itemData.Data.Icon or itemData.Data.ImageId
                if iconRaw then
                    assetId = tonumber(string.match(tostring(iconRaw), "%d+"))
                end
            end

            local imageUrl = assetId and GetRobloxAssetImage(assetId)
            if not imageUrl then
                imageUrl = "https://tr.rbxcdn.com/53eb9b170bea9855c45c9356fb33c070/420/420/Image/Png" 
            end
            
            local basePrice = itemData and itemData.SellPrice or 0
            local sellPrice = basePrice * (metadata.SellMultiplier or 1)
            local formattedSellPrice = string.format("%s$", FormatNumber(sellPrice))
            
            -- 1. GET TOTAL CAUGHT (Untuk Footer)
            local leaderstats = LocalPlayer:FindFirstChild("leaderstats")
            local caughtStat = leaderstats and leaderstats:FindFirstChild("Caught")
            local caughtDisplay = caughtStat and FormatNumber(caughtStat.Value) or "N/A"

            -- 2. GET CURRENT COINS (FIXED LOGIC BASED ON DUMP)
            local currentCoins = 0
            local replion = GetPlayerDataReplion()
            
            if replion then
                -- Cara 1: Ambil Path Resmi dari Module (Paling Aman)
                local success_curr, CurrencyConfig = pcall(function()
                    return require(game:GetService("ReplicatedStorage").Modules.CurrencyUtility.Currency)
                end)

                if success_curr and CurrencyConfig and CurrencyConfig["Coins"] then
                    -- Path adalah table: { "Coins" }
                    -- Replion library di game ini support passing table path langsung
                    currentCoins = replion:Get(CurrencyConfig["Coins"].Path) or 0
                else
                    -- Cara 2: Fallback Manual (Root "Coins", bukan "Currency/Coins")
                    -- Kita coba unpack table manual atau string langsung
                    currentCoins = replion:Get("Coins") or replion:Get({"Coins"}) or 0
                end
            else
                -- Fallback Terakhir: Leaderstats
                if leaderstats then
                    local coinStat = leaderstats:FindFirstChild("Coins") or leaderstats:FindFirstChild("C$")
                    currentCoins = coinStat and coinStat.Value or 0
                end
            end

            local formattedCoins = FormatNumber(currentCoins)
            -- --- END: Ambil Data Embed Umum ---

            
            -- ************************************************************
            -- 1. LOGIKA WEBHOOK PRIBADI (USER'S WEBHOOK)
            -- ************************************************************
            local isUserFilterMatch = shouldNotify(fishRarityUpper, metadata)

            if isWebhookEnabled and WEBHOOK_URL ~= "" and isUserFilterMatch then
                local title_private = string.format("<:TEXTURENOBG:1438662703722790992> RockHub | Webhook\n\n<a:ChipiChapa:1438661193857503304> New Fish Caught! (%s)", fishName)
                
                local embed = {
                    title = title_private,
                    description = string.format("Found by **%s**.", LocalPlayer.DisplayName or LocalPlayer.Name),
                    color = getRarityColor(fishRarityUpper),
                    fields = {
                        { name = "<a:ARROW:1438758883203223605> Fish Name", value = string.format("`%s`", fishName), inline = true },
                        { name = "<a:ARROW:1438758883203223605> Rarity", value = string.format("`%s`", fishRarityUpper), inline = true },
                        { name = "<a:ARROW:1438758883203223605> Weight", value = string.format("`%s`", fishWeight), inline = true },
                        
                        { name = "<a:ARROW:1438758883203223605> Mutation", value = string.format("`%s`", mutationDisplay), inline = true },
                        { name = "<a:coines:1438758976992051231> Sell Price", value = string.format("`%s`", formattedSellPrice), inline = true },
                        { name = "<a:coines:1438758976992051231> Current Coins", value = string.format("`%s`", formattedCoins), inline = true },
                    },
                    thumbnail = { url = imageUrl },
                    footer = {
                        text = string.format("RockHub Webhook • Total Caught: %s • %s", caughtDisplay, os.date("%Y-%m-%d %H:%M:%S"))
                    }
                }
                local success_send, message = sendExploitWebhook(WEBHOOK_URL, WEBHOOK_USERNAME, embed)
                
                if success_send then
                    UpdateWebhookStatus("Webhook Aktif", "Terkirim: " .. fishName, "check")
                else
                    UpdateWebhookStatus("Webhook Gagal", "Error: " .. message, "x")
                end
            end

            -- ************************************************************
            -- 2. LOGIKA WEBHOOK GLOBAL (COMMUNITY WEBHOOK)
            -- ************************************************************
            local isGlobalTarget = table.find(GLOBAL_RARITY_FILTER, fishRarityUpper)

            if isGlobalTarget and GLOBAL_WEBHOOK_URL ~= "" then 
                local playerName = LocalPlayer.DisplayName or LocalPlayer.Name
                local censoredPlayerName = CensorName(playerName)
                
                local title_global = string.format("<:TEXTURENOBG:1438662703722790992> RockHub | Global Tracker\n\n<a:globe:1438758633151266818> GLOBAL CATCH! %s", fishName)

                local globalEmbed = {
                    title = title_global,
                    description = string.format("Pemain **%s** baru saja menangkap ikan **%s**!", censoredPlayerName, fishRarityUpper),
                    color = getRarityColor(fishRarityUpper),
                    fields = {
                        { name = "<a:ARROW:1438758883203223605> Rarity", value = string.format("`%s`", fishRarityUpper), inline = true },
                        { name = "<a:ARROW:1438758883203223605> Weight", value = string.format("`%s`", fishWeight), inline = true },
                        { name = "<a:ARROW:1438758883203223605> Mutation", value = string.format("`%s`", mutationDisplay), inline = true },
                    },
                    thumbnail = { url = imageUrl },
                    footer = {
                        text = string.format("RockHub Community| Player: %s | %s", censoredPlayerName, os.date("%Y-%m-%d %H:%M:%S"))
                    }
                }
                
                sendExploitWebhook(GLOBAL_WEBHOOK_URL, GLOBAL_WEBHOOK_USERNAME, globalEmbed)
            end
            
            return true
        end)
        
        if not success then
            warn("[RockHub Webhook] Error processing fish data:", results)
        end
    end
    
    if REObtainedNewFishNotification then
        REObtainedNewFishNotification.OnClientEvent:Connect(function(itemId, metadata, fullData)
            pcall(function() onFishObtained(itemId, metadata, fullData) end)
        end)
    end
    

    -- =================================================================
    -- UI IMPLEMENTATION (LANJUTAN)
    -- =================================================================
    webhook:Section({
        Title = "Webhook Setup",
        TextSize = 20,
        FontWeight = Enum.FontWeight.SemiBold,
    })

    webhook:Input({
        Title = "Discord Webhook URL",
        Desc = "URL tempat notifikasi akan dikirim.",
        Value = "",
        Placeholder = "https://discord.com/api/webhooks/...",
        Icon = "link",
        Type = "Input",
        Flag = "inweb",
        Callback = function(input)
            WEBHOOK_URL = input
        end
    })

    webhook:Divider()
    
   local ToggleNotif = webhook:Toggle({
        Title = "Enable Fish Notifications",
        Desc = "Aktifkan/nonaktifkan pengiriman notifikasi ikan.",
        Value = false,
        Flag = "tweb",
        Icon = "cloud-upload",
        Callback = function(state)
            isWebhookEnabled = state
            if state then
                if WEBHOOK_URL == "" or not WEBHOOK_URL:find("discord.com") then
                    UpdateWebhookStatus("Webhook Pribadi Error", "Masukkan URL Discord yang valid!", "alert-triangle")
                    return false
                end
                WindUI:Notify({ Title = "Webhook ON!", Duration = 4, Icon = "check" })
                UpdateWebhookStatus("Status: Listening", "Menunggu tangkapan ikan...", "ear")
            else
                WindUI:Notify({ Title = "Webhook OFF!", Duration = 4, Icon = "x" })
                UpdateWebhookStatus("Webhook Status", "Aktifkan 'Enable Fish Notifications' untuk mulai mendengarkan tangkapan ikan.", "info")
            end
        end
    })

    webhook:Dropdown({
        Title = "Rarity to Notify",
        Desc = "Hanya notifikasi ikan rarity yang dipilih.",
        Values = RarityList, -- Menggunakan list yang sudah distandarisasi
        Value = SelectedRarityCategories,
        Multi = true,
        AllowNone = true,
        Flag = "dweb",
        Callback = function(categories)
            SelectedRarityCategories = {}
            for _, cat in ipairs(categories or {}) do
                table.insert(SelectedRarityCategories, cat:upper()) 
            end
        end
    })

    WebhookStatusParagraph = webhook:Paragraph({
        Title = "Webhook Status",
        Content = "Aktifkan 'Enable Fish Notifications' untuk mulai mendengarkan tangkapan ikan.",
        Icon = "info",
    })
    

    webhook:Button({
        Title = "Test Webhook ",
        Icon = "send",
        Desc = "Mengirim Webhook Test",
        Callback = function()
            if WEBHOOK_URL == "" then
                WindUI:Notify({ Title = "Error", Content = "Masukkan URL Webhook terlebih dahulu.", Duration = 3, Icon = "alert-triangle" })
                return
            end
            local testEmbed = {
                title = "RockHub Webhook Test",
                description = "Success <a:ChipiChapa:1438661193857503304>",
                color = 0x00FF00,
                fields = {
                    { name = "Name Player", value = LocalPlayer.DisplayName or LocalPlayer.Name, inline = true },
                    { name = "Status", value = "Success", inline = true },
                    { name = "Cache System", value = "Active ✅", inline = true }
                },
                footer = {
                    text = "RockHub Webhook Test"
                }
            }
            local success, message = sendExploitWebhook(WEBHOOK_URL, WEBHOOK_USERNAME, testEmbed)
            if success then
                 WindUI:Notify({ Title = "Test Sukses!", Content = "Cek channel Discord Anda. " .. message, Duration = 4, Icon = "check" })
            else
                 WindUI:Notify({ Title = "Test Gagal!", Content = "Cek console (Output) untuk error. " .. message, Duration = 5, Icon = "x" })
            end
        end
    })
end

do
    local SettingsTab = Window:Tab({
        Title = "Configuration",
        Icon = "settings",
        Locked = false,
    })

    local ConfigSection = SettingsTab:Section({
        Title = "Configuration System",
        TextSize = 20,
    })

    local ConfigManager = Window.ConfigManager
    local CurrentConfigName = "default"

    -- 1. Input Nama Config
    local ConfigNameInput = ConfigSection:Input({
        Title = "Config Name",
        Desc = "Masukkan nama config baru atau pilih dari dropdown",
        Value = "default",
        Placeholder = "e.g. AutoFarm1",
        Icon = "file-pen",
        Callback = function(value)
            CurrentConfigName = value
        end
    })

    -- Helper: Update Dropdown List
    local function RefreshConfigList(dropdown)
        local list = ConfigManager:AllConfigs()
        if #list == 0 then list = {"None"} end
        pcall(function() dropdown:Refresh(list) end)
    end

    -- 2. Dropdown List Config
    local ConfigDropdown = ConfigSection:Dropdown({
        Title = "Saved Configs",
        Desc = "Pilih config yang sudah tersimpan",
        Values = ConfigManager:AllConfigs() or {"default"},
        Value = "default",
        AllowNone = true,
        Callback = function(value)
            if value and value ~= "None" then
                CurrentConfigName = value
                ConfigNameInput:Set(value) -- Update text input biar sinkron
            end
        end
    })

    -- 3. Tombol Refresh List
    ConfigSection:Button({
        Title = "Refresh Config List",
        Icon = "refresh-ccw",
        Callback = function()
            RefreshConfigList(ConfigDropdown)
            WindUI:Notify({ Title = "Refreshed", Content = "Daftar config diperbarui.", Duration = 1.5, Icon = "check" })
        end
    })

    ConfigSection:Divider()

    -- 4. Tombol Save
    ConfigSection:Button({
        Title = "Save Config",
        Desc = "Simpan pengaturan saat ini",
        Icon = "save",
        Callback = function()
            if CurrentConfigName == "" then 
                WindUI:Notify({ Title = "Error", Content = "Nama Config tidak boleh kosong!", Duration = 3, Icon = "alert-triangle" })
                return 
            end

            -- WindUI otomatis menghandle path saat CreateConfig/Save
            Window.CurrentConfig = ConfigManager:CreateConfig(CurrentConfigName)
            
            local success, err = pcall(function()
                Window.CurrentConfig:Save()
            end)

            if success then
                WindUI:Notify({ Title = "Saved!", Content = "Config '" .. CurrentConfigName .. "' disimpan.", Duration = 3, Icon = "check" })
                RefreshConfigList(ConfigDropdown)
            else
                WindUI:Notify({ Title = "Save Error", Content = tostring(err), Duration = 5, Icon = "x" })
            end
        end
    })

    -- 5. Tombol Load
    ConfigSection:Button({
        Title = "Load Config",
        Desc = "Muat pengaturan dari file",
        Icon = "download",
        Callback = function()
            if CurrentConfigName == "" then return end

            local success, err = pcall(function()
                Window.CurrentConfig = ConfigManager:CreateConfig(CurrentConfigName)
                Window.CurrentConfig:Load()
            end)

            if success then
                WindUI:Notify({ Title = "Loaded!", Content = "Config '" .. CurrentConfigName .. "' dimuat.", Duration = 3, Icon = "check" })
            else
                WindUI:Notify({ Title = "Load Error", Content = "Gagal memuat (Mungkin file tidak ada?)", Duration = 5, Icon = "x" })
            end
        end
    })

    -- 6. Tombol Delete Config (DIPERBAIKI PATH-NYA)
    ConfigSection:Button({
        Title = "Delete Config",
        Desc = "Hapus file config permanen",
        Icon = "trash-2",
        Color = Color3.fromRGB(255, 80, 80), -- Merah
        Callback = function()
            if CurrentConfigName == "" or CurrentConfigName == "None" then return end
            
            -- Cek apakah executor mendukung manipulasi file
            if not isfile or not delfile then
                WindUI:Notify({ Title = "Unsupported", Content = "Executormu tidak support hapus file.", Duration = 3, Icon = "x" })
                return
            end

            -- MENYUSUN PATH BERDASARKAN TEMUAN KAMU
            -- Struktur: WindUI / [NamaFolderWindow] / config / [NamaConfig].json
            local folderName = Window.Folder or "RockHub" -- Mengambil dari Window setting, fallback ke RockHub
            local targetPath = "WindUI/" .. folderName .. "/config/" .. CurrentConfigName .. ".json"
            
            -- Debugging print (cek console (F9) kalau masih gagal)
            print("[RockHub Debug] Trying to delete: " .. targetPath)

            if isfile(targetPath) then
                delfile(targetPath)
                WindUI:Notify({ Title = "Deleted", Content = "File dihapus: " .. CurrentConfigName, Duration = 3, Icon = "trash" })
                
                -- Reset Input & Dropdown
                ConfigNameInput:Set("default")
                RefreshConfigList(ConfigDropdown)
            else
                -- Coba path alternatif (Jaga-jaga kalau WindUI versi lain tdk pakai subfolder 'config')
                local altPath = "WindUI/" .. folderName .. "/" .. CurrentConfigName .. ".json"
                if isfile(altPath) then
                    delfile(altPath)
                    WindUI:Notify({ Title = "Deleted", Content = "File (Alt Path) dihapus.", Duration = 3, Icon = "trash" })
                    RefreshConfigList(ConfigDropdown)
                else
                    WindUI:Notify({ Title = "Gagal Hapus", Content = "File tidak ditemukan di path:\n" .. targetPath, Duration = 5, Icon = "alert-triangle" })
                end
            end
        end
    })
end

do
    local about = Window:Tab({
        Title = "About",
        Icon = "info",
        Locked = false,
    })

    about:Section({
        Title = "Join Discord Server RockHub",
        TextSize = 20,
    })

    about:Paragraph({
        Title = "RockHub Community",
        Desc = "Join Our Community Discord Server to get the latest updates, support, and connect with other users!",
        Image = "rbxassetid://122210708834535",
        ImageSize = 24,
        Buttons = {
            {
                Title = "Copy Link",
                Icon = "link",
                Callback = function()
                    setclipboard("https://dsc.gg/rockhub")
                    WindUI:Notify({
                        Title = "Link Disalin!",
                        Content = "Link Discord RockHub berhasil disalin.",
                        Duration = 3,
                        Icon = "copy",
                    })
                end,
            }
        }
    })

    about:Divider()
    
    about:Section({
        Title = "What's New?",
        TextSize = 24,
        FontWeight = Enum.FontWeight.SemiBold,
    })

    about:Image({
        Image = "rbxassetid://122210708834535",
        AspectRatio = "16:9",
        Radius = 9,
    })

    about:Space()

    about:Paragraph({
        Title = "Free Version",
        Desc = "- 28 Nov 2025 Release Free Version\n\n\n\n buy premium? join discord!",
    })
end

--Window:Tag({
  --  Title = "V 1.0.0",
    --Color = Color3.fromHex("#F5C527"),
    --Radius = 9,
--})

Window:EditOpenButton({
    Title = "RockHub - Fish It",
    Icon = "rbxassetid://116236936447443",
    CornerRadius = UDim.new(0,30),
    StrokeThickness = 1.5,
    Color = ColorSequence.new(
        Color3.fromHex("FF0F7B"),
        Color3.fromHex("F89B29")
    ),
    OnlyMobile = false,
    Enabled = true,
    Draggable = true,
})

-- =================================================================
-- FLOATING ICON (FIXED: NO GLITCH & SMOOTH DRAG)
-- =================================================================
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local PlayerGui = game.Players.LocalPlayer:WaitForChild("PlayerGui")

-- Variabel Koneksi Global (PENTING BIAR GA TUMPUK)
local uisConnection = nil

-- Variabel Logika Dragging
local dragging = false
local dragInput = nil
local dragStart = nil
local startPos = nil

local function CreateFloatingIcon()
    local existingGui = PlayerGui:FindFirstChild("CustomFloatingIcon_RockHub")
    if existingGui then existingGui:Destroy() end

    local FloatingIconGui = Instance.new("ScreenGui")
    FloatingIconGui.Name = "CustomFloatingIcon_RockHub"
    FloatingIconGui.DisplayOrder = 999
    FloatingIconGui.ResetOnSpawn = false 

    local FloatingFrame = Instance.new("Frame")
    FloatingFrame.Name = "FloatingFrame"
    -- Posisi Default (Tengah Kiri aman)
    FloatingFrame.Position = UDim2.new(0, 50, 0.4, 0) 
    FloatingFrame.Size = UDim2.fromOffset(45, 45) 
    FloatingFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    FloatingFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    FloatingFrame.BackgroundTransparency = 0 -- Hitam Pekat
    FloatingFrame.BorderSizePixel = 0
    FloatingFrame.Parent = FloatingIconGui

    -- Stroke/Garis Tepi
    local FrameStroke = Instance.new("UIStroke")
    FrameStroke.Color = Color3.fromHex("FF0F7B")
    FrameStroke.Thickness = 2
    FrameStroke.Transparency = 0
    FrameStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    FrameStroke.Parent = FloatingFrame

    -- Sudut Tumpul (Rounded Square)
    local FrameCorner = Instance.new("UICorner")
    FrameCorner.CornerRadius = UDim.new(0, 12) 
    FrameCorner.Parent = FloatingFrame

    -- Icon Gambar
    local IconImage = Instance.new("ImageLabel")
    IconImage.Name = "Icon"
    IconImage.Image = "rbxassetid://122210708834535"
    IconImage.BackgroundTransparency = 1
    IconImage.Size = UDim2.new(1, -4, 1, -4) 
    IconImage.Position = UDim2.new(0.5, 0, 0.5, 0)
    IconImage.AnchorPoint = Vector2.new(0.5, 0.5)
    IconImage.Parent = FloatingFrame

    -- Corner untuk Gambar
    local ImageCorner = Instance.new("UICorner")
    ImageCorner.CornerRadius = UDim.new(0, 10)
    ImageCorner.Parent = IconImage
    
    FloatingIconGui.Parent = PlayerGui
    return FloatingIconGui, FloatingFrame
end

local function SetupFloatingIcon(FloatingIconGui, FloatingFrame)
    -- [FIX] Putuskan koneksi lama jika ada (Mencegah glitch tumpuk)
    if uisConnection then 
        uisConnection:Disconnect() 
        uisConnection = nil
    end

    local function update(input)
        local delta = input.Position - dragStart
        FloatingFrame.Position = UDim2.new(
            startPos.X.Scale, 
            startPos.X.Offset + delta.X, 
            startPos.Y.Scale, 
            startPos.Y.Offset + delta.Y
        )
    end

    -- Event: Mulai Sentuh/Klik
    FloatingFrame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = FloatingFrame.Position
            
            local didMove = false

            -- Tracking release
            local connection
            connection = input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                    connection:Disconnect()
                    
                    -- Logika: Jika tidak geser (atau geser dikit banget), berarti KLIK
                    if not didMove then
                        if Window and Window.Toggle then
                            Window:Toggle()
                        end
                    end
                end
            end)
            
            -- Tracking movement khusus input ini untuk status 'didMove'
            local moveConnection
            moveConnection = input.Changed:Connect(function()
                 if dragging and (input.Position - dragStart).Magnitude > 5 then
                     didMove = true
                     moveConnection:Disconnect()
                 end
            end)
        end
    end)

    -- Event: Pergerakan Input (Menyiapkan dragInput)
    FloatingFrame.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)

    -- [FIX] Event Global Disimpan ke Variabel uisConnection
    uisConnection = UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            update(input)
        end
    end)

    -- Handler: Sembunyikan Icon saat UI Terbuka
    if Window then
        Window:OnOpen(function()
            FloatingIconGui.Enabled = false
        end)
        Window:OnClose(function()
            FloatingIconGui.Enabled = true
        end)
    end
end

local function InitializeIcon()
    -- Pastikan karakter sudah load
    if not game.Players.LocalPlayer.Character then
        game.Players.LocalPlayer.CharacterAdded:Wait()
    end
    
    local gui, frame = CreateFloatingIcon()
    if gui and frame then
        SetupFloatingIcon(gui, frame)
    end
end

-- Auto Reload Icon saat Respawn
game.Players.LocalPlayer.CharacterAdded:Connect(function()
    task.wait(1) 
    InitializeIcon()
end)

WindUI:Notify({ Title = "RockHub Was Loaded", Content = "Press [F] to open/close the menu", Duration = 5, Icon = "info" })

InitializeIcon()
