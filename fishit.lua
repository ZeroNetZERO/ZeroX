local WindUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua"))()

-------- [[ CATRAZ THEME SETUP ]] --------
WindUI:AddTheme({
    Name = "Native Red",
    Accent = Color3.fromHex("#ff5e5e"), 
    Background = Color3.fromHex("#1a0b0b"), 
    BackgroundTransparency = 0.8, 
    Outline = Color3.fromHex("#451a1a"), 
    Text = Color3.fromHex("#fcfcfc"), 
    Placeholder = Color3.fromHex("#8a4b4b"),
    Button = Color3.fromHex("#2b1212"), 
    Icon = Color3.fromHex("#ffcccc"),
    Hover = Color3.fromHex("#3d1a1a"), 
    WindowBackground = Color3.fromHex("#140808"), 
    WindowShadow = Color3.fromHex("#000000"),
    WindowTopbarButtonIcon = Color3.fromHex("#ffcccc"),
    WindowTopbarTitle = Color3.fromHex("#fcfcfc"), 
    WindowTopbarAuthor = Color3.fromHex("#aa5555"),
    WindowTopbarIcon = Color3.fromHex("#ff5e5e"),
    TabBackground = Color3.fromHex("#0f0505"), 
    TabTitle = Color3.fromHex("#fcfcfc"),
    TabIcon = Color3.fromHex("#cc8888"),
    ElementBackground = Color3.fromHex("#260f0f"), 
    ElementTitle = Color3.fromHex("#fcfcfc"),
    ElementDesc = Color3.fromHex("#b36b6b"),
    ElementIcon = Color3.fromHex("#ffcccc"),
    Toggle = Color3.fromHex("#fcfcfc"), 
    ToggleBar = Color3.fromHex("#3d1a1a"),
    Checkbox = Color3.fromHex("#fcfcfc"),
    CheckboxIcon = Color3.fromHex("#1a0b0b"), 
    Slider = Color3.fromHex("#fcfcfc"),
    SliderThumb = Color3.fromHex("#ff5e5e"), 
})

WindUI:SetTheme("Native Red")

local Window = WindUI:CreateWindow({
    Title = "Catraz Hub |Vyn HUB | Fish It!",
    Folder = "CatrazHub",
    Icon = "rbxassetid://124162045221605", 
    NewElements = true,
    Transparent = true,
    Theme = "Native Red",
    HideSearchBar = true,
    BackgroundImageTransparency = 1,
    OpenButton = { Title = "Open Hub", Enabled = false },                                                              
    User = {
        Enabled = true,
        Anonymous = false,
        Callback = function() end,
    },
})

-- [[ 1. VERSION TAG (BETA) ]] --
Window:Tag({
    Title = "v4.0-BETA",
    Icon = "github", -- Ikon Github
    Color = Color3.fromHex("#4a4a4a"), -- Warna Hijau Stabilo
})

Window:Tag({
    Title = "Premium",
    Color = Color3.fromHex("#b80202"), -- Warna Hijau Stabilo
})

Window:DisableTopbarButtons({
    "Close", 
    "Minimize", 
    "Fullscreen",
})

WindUI:Notify({
    Title = "Catraz Hub Loaded",
    Content = "Success load Catraz Hub | FISH IT!",
    Duration = 5,
    Icon = "badge-check", 
})

-- [[ CUSTOM TOGGLE UI SYSTEM & MINI DASHBOARD (DRAGGABLE VERSION) ]] --
task.spawn(function()
    local CoreGui = game:GetService("CoreGui")
    local TweenService = game:GetService("TweenService")
    local RunService = game:GetService("RunService")
    local UserInputService = game:GetService("UserInputService") -- Tambahan Service
    local Stats = game:GetService("Stats")
    
    local NameUI = "CatrazHubSystem"
    if CoreGui:FindFirstChild(NameUI) then CoreGui[NameUI]:Destroy() end
    
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = NameUI
    ScreenGui.Parent = CoreGui
    ScreenGui.ResetOnSpawn = false
    
    -- [[ FUNGSI DRAGGABLE (BIAR BISA DIGESER) ]] --
    local function MakeDraggable(topbarobject, object)
        local Dragging = nil
        local DragInput = nil
        local DragStart = nil
        local StartPosition = nil

        local function Update(input)
            local Delta = input.Position - DragStart
            local pos = UDim2.new(StartPosition.X.Scale, StartPosition.X.Offset + Delta.X, StartPosition.Y.Scale, StartPosition.Y.Offset + Delta.Y)
            -- Pakai Tween biar smooth pas ditarik
            local Tween = TweenService:Create(object, TweenInfo.new(0.15), {Position = pos})
            Tween:Play()
        end

        topbarobject.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                Dragging = true
                DragStart = input.Position
                StartPosition = object.Position

                input.Changed:Connect(function()
                    if input.UserInputState == Enum.UserInputState.End then
                        Dragging = false
                    end
                end)
            end
        end)

        topbarobject.InputChanged:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
                DragInput = input
            end
        end)

        UserInputService.InputChanged:Connect(function(input)
            if input == DragInput and Dragging then
                Update(input)
            end
        end)
    end
    -- [[ END FUNGSI DRAGGABLE ]] --

    -- Variables State
    local IsMenuOpen = true 
    
    -- 1. TOGGLE BUTTON
    local ToggleBtn = Instance.new("ImageButton")
    ToggleBtn.Name = "MainButton"
    ToggleBtn.Parent = ScreenGui
    ToggleBtn.Position = UDim2.new(0.05, 0, 0.45, 0)
    ToggleBtn.Size = UDim2.new(0, 50, 0, 50)
    ToggleBtn.BackgroundColor3 = Color3.fromHex("#140808")
    ToggleBtn.BackgroundTransparency = 0.2
    ToggleBtn.AutoButtonColor = false 
    
    -- Bikin Tombolnya Draggable juga (Pakai fungsi baru biar smooth)
    MakeDraggable(ToggleBtn, ToggleBtn)

    local BtnCorner = Instance.new("UICorner")
    BtnCorner.CornerRadius = UDim.new(0.3, 0)
    BtnCorner.Parent = ToggleBtn

    local BtnStroke = Instance.new("UIStroke")
    BtnStroke.Parent = ToggleBtn
    BtnStroke.Color = Color3.fromHex("#ff5e5e")
    BtnStroke.Thickness = 2.5
    BtnStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

    local IconImage = Instance.new("ImageLabel")
    IconImage.Parent = ToggleBtn
    IconImage.BackgroundTransparency = 1 
    IconImage.AnchorPoint = Vector2.new(0.5, 0.5)
    IconImage.Position = UDim2.new(0.5, 0, 0.5, 0)
    IconImage.Size = UDim2.new(0.7, 0, 0.7, 0)
    IconImage.Image = "rbxassetid://124162045221605" 
    IconImage.ScaleType = Enum.ScaleType.Fit
    
    -- 2. MINI DASHBOARD (Status Box)
    local StatusFrame = Instance.new("Frame")
    StatusFrame.Name = "StatusDashboard"
    StatusFrame.Parent = ScreenGui
    StatusFrame.Position = UDim2.new(0.5, 0, 0.05, 0) 
    StatusFrame.AnchorPoint = Vector2.new(0.5, 0)
    StatusFrame.Size = UDim2.new(0, 300, 0, 65)
    StatusFrame.BackgroundColor3 = Color3.fromHex("#0f0505")
    StatusFrame.BackgroundTransparency = 0.1
    StatusFrame.Visible = false 
    
    -- [[ TERAPKAN DRAGGABLE DI SINI ]]
    -- Kita bikin StatusFrame bisa ditarik
    MakeDraggable(StatusFrame, StatusFrame)

    local StatusCorner = Instance.new("UICorner")
    StatusCorner.CornerRadius = UDim.new(0, 8)
    StatusCorner.Parent = StatusFrame
    
    local StatusStroke = Instance.new("UIStroke")
    StatusStroke.Parent = StatusFrame
    StatusStroke.Color = Color3.fromHex("#451a1a")
    StatusStroke.Thickness = 2
    
    local AccentBar = Instance.new("Frame")
    AccentBar.Parent = StatusFrame
    AccentBar.BackgroundColor3 = Color3.fromHex("#ff5e5e")
    AccentBar.Size = UDim2.new(0, 4, 1, 0)
    AccentBar.BorderSizePixel = 0
    local BarCorner = Instance.new("UICorner"); BarCorner.Parent = AccentBar

    local TitleLabel = Instance.new("TextLabel")
    TitleLabel.Parent = StatusFrame
    TitleLabel.BackgroundTransparency = 1
    TitleLabel.Position = UDim2.new(0, 15, 0, 5)
    TitleLabel.Size = UDim2.new(1, -20, 0, 20)
    TitleLabel.Font = Enum.Font.GothamBold
    TitleLabel.Text = "CATRAZ HUB | <font color='#ff5e5e'>FISH IT!</font>"
    TitleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    TitleLabel.TextSize = 14
    TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
    TitleLabel.RichText = true

    local StatsLabel = Instance.new("TextLabel")
    StatsLabel.Parent = StatusFrame
    StatsLabel.BackgroundTransparency = 1
    StatsLabel.Position = UDim2.new(0, 15, 0, 28)
    StatsLabel.Size = UDim2.new(1, -20, 0, 30) 
    StatsLabel.Font = Enum.Font.GothamMedium
    StatsLabel.Text = "Loading Stats..."
    StatsLabel.TextColor3 = Color3.fromHex("#cccccc")
    StatsLabel.TextSize = 12
    StatsLabel.TextXAlignment = Enum.TextXAlignment.Left
    
    -- 3. ANIMATION & LOGIC
    local function PlayClickAnim()
        TweenService:Create(ToggleBtn, TweenInfo.new(0.1), {Size = UDim2.new(0, 40, 0, 40)}):Play()
        task.wait(0.1)
        TweenService:Create(ToggleBtn, TweenInfo.new(0.3, Enum.EasingStyle.Elastic), {Size = UDim2.new(0, 50, 0, 50)}):Play()
    end

    local function FormatTime(seconds)
        local h = math.floor(seconds / 3600)
        local m = math.floor((seconds % 3600) / 60)
        local s = math.floor(seconds % 60)
        return string.format("%02d:%02d:%02d", h, m, s)
    end

    ToggleBtn.MouseButton1Click:Connect(function()
        PlayClickAnim()
        Window:Toggle() 
        IsMenuOpen = not IsMenuOpen
        StatusFrame.Visible = not IsMenuOpen 
        
        if not IsMenuOpen then
            StatusFrame.BackgroundTransparency = 1
            TitleLabel.TextTransparency = 1
            StatsLabel.TextTransparency = 1
            TweenService:Create(StatusFrame, TweenInfo.new(0.3), {BackgroundTransparency = 0.1}):Play()
            TweenService:Create(TitleLabel, TweenInfo.new(0.3), {TextTransparency = 0}):Play()
            TweenService:Create(StatsLabel, TweenInfo.new(0.3), {TextTransparency = 0}):Play()
        end
    end)

    -- 4. LIVE VISUAL UPDATE
    RunService.RenderStepped:Connect(function(deltaTime)
        if StatusFrame.Visible then
            local fps = math.floor(1 / deltaTime)
            local ping = math.floor(Stats.Network.ServerStatsItem["Data Ping"]:GetValue())
            local runtime = FormatTime(workspace.DistributedGameTime)
            
            StatsLabel.Text = string.format("FPS: %d  |  Ping: %d ms\nRuntime: %s", fps, ping, runtime)
        end
    end)
end)

-- [[ 1. CONFIGURATION SYSTEM SETUP ]] --
local CatrazHubConfig = Window.ConfigManager:CreateConfig("catrazhub")

-- [BARU] Tabel untuk menyimpan semua elemen UI agar bisa dicek valuenya
local ElementRegistry = {} 

-- Fungsi Helper Reg yang sudah di-upgrade
local function Reg(id, element)
    CatrazHubConfig:Register(id, element)
    -- Simpan elemen ke tabel lokal kita
    ElementRegistry[id] = element 
    return element
end

local HttpService = game:GetService("HttpService")
local BaseFolder = "WindUI/" .. (Window.Folder or "CatrazHub") .. "/config/"

local function SmartLoadConfig(configName)
    local path = BaseFolder .. configName .. ".json"
    
    -- 1. Cek File
    if not isfile(path) then 
        WindUI:Notify({ Title = "Gagal Load", Content = "File tidak ditemukan: " .. configName, Duration = 3, Icon = "x" })
        return 
    end

    -- 2. Cek Isi File & Decode
    local content = readfile(path)
    local success, decodedData = pcall(function() return HttpService:JSONDecode(content) end)

    if not success or not decodedData then 
        WindUI:Notify({ Title = "Gagal Load", Content = "File JSON rusak/kosong.", Duration = 3, Icon = "alert-triangle" })
        return 
    end

    -- [FIX PENTING] Ambil data dari '__elements' jika ada
    local realData = decodedData
    if decodedData["__elements"] then
        realData = decodedData["__elements"]
    end

    local changeCount = 0
    local foundCount = 0

    -- Debug: Hitung total registry script saat ini
    for _ in pairs(ElementRegistry) do foundCount = foundCount + 1 end
    print("------------------------------------------------")
    print("[SmartLoad] Target Config: " .. configName)
    print("[SmartLoad] Elemen terdaftar di Script: " .. foundCount)

    -- 3. Loop Data
    for id, itemData in pairs(realData) do
        local element = ElementRegistry[id] -- Cari elemen di script kita
        
        if element then
            -- [FIX PENTING] Ambil 'value' dari dalam object JSON WindUI
            -- Struktur JSON kamu: "tognorm": {"value": true, "__type": "Toggle"}
            local finalValue = itemData
            
            if type(itemData) == "table" and itemData.value ~= nil then
                finalValue = itemData.value
            end

            -- Cek Tipe Data (Safety)
            local currentVal = element.Value
            
            -- Cek Perbedaan (Support Table/Array untuk Dropdown)
            local isDifferent = false
            
            if type(finalValue) == "table" then
                -- Jika dropdown/multi-select, kita asumsikan selalu update biar aman
                -- atau bandingkan panjang table (simple check)
                isDifferent = true 
            elseif currentVal ~= finalValue then
                isDifferent = true
            end

            -- Eksekusi Perubahan
            if isDifferent then
                pcall(function() 
                    element:Set(finalValue) 
                end)
                changeCount = changeCount + 1
                
                -- Anti-Freeze: Jeda mikro setiap 10 perubahan
                if changeCount % 10 == 0 then task.wait() end
            end
        end
    end

    print("[SmartLoad] Selesai. Total Update: " .. changeCount)
    print("------------------------------------------------")

    WindUI:Notify({ 
        Title = "Config Loaded", 
        Content = string.format("Updated: %d settings", changeCount), 
        Duration = 3, 
        Icon = "check" 
    })
end

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

local function GetPlayerDataReplion()
    if PlayerDataReplion then return PlayerDataReplion end
    local ReplionModule = RepStorage:WaitForChild("Packages"):WaitForChild("Replion", 10)
    if not ReplionModule then return nil end
    local ReplionClient = require(ReplionModule).Client
    PlayerDataReplion = ReplionClient:WaitReplion("Data", 5)
    return PlayerDataReplion
end

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

--automatic
do
    local automatic = Window:Tab({
        Title = "Automatic",
        Icon = "loader",
        Locked = false,
    })


    -- Variabel Auto Favorite/Unfavorite
    local autoFavoriteState = false
    local autoFavoriteThread = nil
    local autoUnfavoriteState = false
    local autoUnfavoriteThread = nil
    local selectedRarities = {}
    local selectedItemNames = {}
    local selectedMutations = {}

    local RE_FavoriteItem = GetRemote(RPath, "RE/FavoriteItem")



    
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
    
    local RarityDropdown = Reg("drer",favsec:Dropdown({
        Title = "by Rarity",
        Values = {"Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic", "SECRET"},
        Multi = true, AllowNone = true, Value = false,
        Callback = function(values) selectedRarities = values or {} end
    }))

    local ItemNameDropdown = Reg("dtem",favsec:Dropdown({
        Title = "by Item Name",
        Values = allItemNames, -- Menggunakan daftar nama item universal
        Multi = true, AllowNone = true, Value = false,
        Callback = function(values) selectedItemNames = values or {} end -- Multi select untuk nama
    }))

    local MutationDropdown = Reg("dmut",favsec:Dropdown({
        Title = "by Mutation",
        Values = {"Shiny", "Gemstone", "Corrupt", "Galaxy", "Holographic", "Ghost", "Lightning", "Fairy Dust", "Gold", "Midnight", "Radioactive", "Stone", "Albino", "Sandy", "Acidic", "Disco", "Frozen","Noob"},
        Multi = true, AllowNone = true, Value = false,
        Callback = function(values) selectedMutations = values or {} end
    }))

    -- Toggle Auto Favorite
    local togglefav = Reg("tvav",favsec:Toggle({
        Title = "Enable Auto Favorite",
        Value = false,
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
    }))
    
    -- Toggle Auto Unfavorite (LOGIKA YANG DIPERBAIKI)
    local toggleunfav = Reg("tunfa",favsec:Toggle({
        Title = "Enable Auto Unfavorite",
        Value = false,
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
    }))
    
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
    local tradeStopAtCoins = 0
    local isTradeByCoinActive = false

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
        Callback = function(rarity)
            selectedTradeRarity = rarity or nil -- Set ke nil jika "None"
        end
    })

    local ToggleCoinStop = trade:Toggle({
        Title = "Stop at Coin Amount",
        Desc = "Berhenti trade jika koin mencapai target.",
        Value = false,
        Callback = function(state) isTradeByCoinActive = state end
    })

    local inputcoint = trade:Input({
        Title = "Target Coin Amount",
        Placeholder = "1000000",
        Value = "0",
        Icon = "dollar-sign",
        Callback = function(val)
            tradeStopAtCoins = tonumber(val) or 0
        end
    })
    
    
    -- 3. Limit Trade Input (Amount)
    local InputAmount = trade:Input({
        Title = "Trade Amount (0 = Unlimited)",
        Value = tostring(tradeAmount),
        Placeholder = "0 (Unlimited)",
        Icon = "hash",
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
            local isFavorited = item.IsFavorite or item.Favorited
            if tradeHoldFavorite and isFavorited then
                continue 
            end
            
            if typeof(item.UUID) ~= "string" or item.UUID:len() < 10 then continue end
            
            local name, rarity = GetFishNameAndRarity(item)
            local itemRarity = (rarity and rarity:upper() ~= "COMMON") and rarity or "Default"
            
            -- Filter Logic
            local passesRarity = not selectedTradeRarity or (selectedTradeRarity and itemRarity:upper() == selectedTradeRarity:upper())
            local passesName = not selectedTradeItemName or (name == selectedTradeItemName)
            
            if passesRarity and passesName then
                -- [UPDATE] Masukkan Id dan Metadata juga untuk hitung harga
                table.insert(itemsToTrade, { 
                    UUID = item.UUID, 
                    Name = name, 
                    Rarity = rarity, 
                    Identifier = item.Identifier,
                    Id = item.Id,
                    Metadata = item.Metadata or {}
                })
            end
        end
        return itemsToTrade
    end

    -- Helper: Cek apakah item dengan UUID tertentu masih ada di inventory
    local function IsItemStillInInventory(targetUUID)
        local replion = GetPlayerDataReplion()
        if not replion then return true end -- Asumsikan masih ada biar ga error
        
        local success, inventoryData = pcall(function() return replion:GetExpect("Inventory") end)
        if not success or not inventoryData or not inventoryData.Items then return true end

        for _, item in ipairs(inventoryData.Items) do
            if item.UUID == targetUUID then
                return true -- Item masih ada!
            end
        end
        return false -- Item sudah hilang (Berhasil Trade)
    end

    -- LOGIC LOOP UTAMA: Run Auto Trade (MENGGUNAKAN SINGLE TARGET ID)
    local function RunAutoTradeLoop()
        if autoTradeThread then task.cancel(autoTradeThread) end
        
        autoTradeThread = task.spawn(function()
            local tradeCount = 0
            local accumulatedValue = 0 -- [BARU] Penghitung total nilai coin yang SUDAH di-trade sesi ini
            local targetId = selectedTradeTargetId
            
            if not targetId or typeof(targetId) ~= "number" then
                WindUI:Notify({ Title = "Trade Gagal", Content = "Pilih Target valid.", Duration = 5, Icon = "x" })
                local toggle = automatic:GetElementByTitle("Enable Auto Trade")
                if toggle and toggle.Set then toggle:Set(false) end
                return
            end

            local RF_InitiateTrade_Local = GetRemote(RPath, "RF/InitiateTrade", 5)
            if not RF_InitiateTrade_Local then return end

            WindUI:Notify({ Title = "Auto Trade ON", Content = "Tracking Value dimulai (0/"..tradeStopAtCoins..")", Duration = 2, Icon = "zap" })

            while autoTradeState do
                -- 1. [LOGIKA BARU] Cek Limit Coin Berdasarkan AKUMULASI TRADE
                if isTradeByCoinActive and tradeStopAtCoins > 0 then
                    if accumulatedValue >= tradeStopAtCoins then
                        WindUI:Notify({ 
                            Title = "Target Value Tercapai!", 
                            Content = string.format("Total Trade: %s coins.", accumulatedValue), 
                            Duration = 5, 
                            Icon = "dollar-sign" 
                        })
                        local toggle = automatic:GetElementByTitle("Enable Auto Trade")
                        if toggle and toggle.Set then toggle:Set(false) end
                        break
                    end
                end

                -- 2. Cek Limit Jumlah Item
                if tradeAmount > 0 and tradeCount >= tradeAmount then
                    WindUI:Notify({ Title = "Limit Item Tercapai", Content = "Batas jumlah item terpenuhi.", Duration = 5, Icon = "stop-circle" })
                    local toggle = automatic:GetElementByTitle("Enable Auto Trade")
                    if toggle and toggle.Set then toggle:Set(false) end
                    break
                end

                -- 3. Ambil Item Target
                local itemsToTrade = GetItemsToTrade()
                
                if #itemsToTrade > 0 then
                    local itemToTrade = itemsToTrade[1]
                    local targetUUID = itemToTrade.UUID
                    
                    -- Hitung Estimasi Harga Item INI
                    local itemBasePrice = 0
                    if ItemUtility then
                        local iData = ItemUtility:GetItemData(itemToTrade.Id)
                        if iData then itemBasePrice = iData.SellPrice or 0 end
                    end
                    local multiplier = itemToTrade.Metadata.SellMultiplier or 1
                    local itemValue = math.floor(itemBasePrice * multiplier)

                    -- Kirim Trade
                    local successCall = pcall(function()
                        RF_InitiateTrade_Local:InvokeServer(targetId, targetUUID)
                    end)

                    if successCall then
                        -- Verifikasi item hilang dari BP
                        local startTime = os.clock()
                        local isTraded = false
                        repeat
                            task.wait(0.5)
                            if not IsItemStillInInventory(targetUUID) then isTraded = true end
                        until isTraded or (os.clock() - startTime > 5)
                        
                        if isTraded then
                            tradeCount = tradeCount + 1
                            
                            -- [BARU] Tambahkan value item ini ke akumulasi
                            accumulatedValue = accumulatedValue + itemValue
                            
                            WindUI:Notify({
                                Title = "Trade Sukses!",
                                Content = string.format("Item: %s\nValue: %d | Total: %d/%d", itemToTrade.Name, itemValue, accumulatedValue, (isTradeByCoinActive and tradeStopAtCoins or 0)),
                                Duration = 2,
                                Icon = "check"
                            })
                            task.wait(tradeDelay)
                        else
                            WindUI:Notify({ Title = "Trade Gagal/Lag", Content = "Item tidak terkirim.", Duration = 2, Icon = "alert-triangle" })
                            task.wait(1.5)
                        end
                    else
                        task.wait(1)
                    end
                else
                    task.wait(2)
                end
            end
            WindUI:Notify({ Title = "Auto Trade Berhenti", Duration = 3, Icon = "x" })
        end)
    end
    
    local togglehold = trade:Toggle({
        Title = "Hold Favorite Items",
        Desc = "Jika ON, item yang di-Favorite tidak akan ikut di-trade.",
        Value = false,
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
        Callback = function(state)
            autoTradeState = state
            
            if state then
                -- 1. Validasi Target ID
                if not selectedTradeTargetId or typeof(selectedTradeTargetId) ~= "number" then
                    WindUI:Notify({ Title = "Error", Content = "Pilih pemain target yang valid terlebih dahulu!", Duration = 3, Icon = "alert-triangle" })
                    return false
                end

                -- 2. [FITUR BARU] TELEPORT KE TARGET
                local targetPlayer = game.Players:GetPlayerByUserId(selectedTradeTargetId)
                
                if targetPlayer then
                    local targetChar = targetPlayer.Character
                    local targetHRP = targetChar and targetChar:FindFirstChild("HumanoidRootPart")
                    
                    local myChar = LocalPlayer.Character
                    local myHRP = myChar and myChar:FindFirstChild("HumanoidRootPart")

                    if targetHRP and myHRP then
                        WindUI:Notify({ Title = "Teleporting...", Content = "Menuju ke posisi " .. targetPlayer.Name, Duration = 2, Icon = "map-pin" })
                        
                        -- Teleport 5 stud di atas target
                        myHRP.CFrame = targetHRP.CFrame * CFrame.new(0, 5, 0)
                        
                        -- Freeze sebentar biar loading map (Opsional, 0.5 detik)
                        task.wait(0.5)
                    else
                        WindUI:Notify({ Title = "Teleport Gagal", Content = "Karakter target tidak ditemukan (Mungkin mati/belum load).", Duration = 3, Icon = "alert-triangle" })
                    end
                else
                    WindUI:Notify({ Title = "Teleport Gagal", Content = "Pemain target sudah keluar server.", Duration = 3, Icon = "x" })
                    return false
                end

                -- 3. Jalankan Loop Trade
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
        Callback = function(state)
            _G.CatrazHub_AutoAcceptTradeEnabled = state
            
            if state then
                WindUI:Notify({
                    Title = "Auto Accept Trade ON!",
                    Content = "Menerima semua permintaan trade.",
                    Duration = 3,
                    Icon = "check"
                })
            else
                WindUI:Notify({
                    Title = "Auto Accept Trade OFF!",
                    Content = "Trade manual.",
                    Duration = 3,
                    Icon = "x"
                })
            end
        end
    })
end
