local Nexus = loadstring(game:HttpGet("https://raw.githubusercontent.com/rsalmn/NexusUI/refs/heads/main/NexusUI.lua", true))() -- Replace with the code above
-- 1. Setup
Nexus:SetTheme("Ocean") 
local Window = Nexus:Window({
    Title = "NPN Hub Premium",
    Subtitle = "Universal Script",
    Size = {580, 420},
    Welcome = true,
    Watermark = true
})

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local RepStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")

local NetFolder = RepStorage
    :WaitForChild("Packages")
    :WaitForChild("_Index")
    :WaitForChild("sleitnick_net@0.2.0")
    :WaitForChild("net")
    
    
-- [[ HELPER FUNCTIONS ]] --
local function GetHumanoid()
    local Character = LocalPlayer.Character
    if not Character then Character = LocalPlayer.CharacterAdded:Wait() end
    return Character:FindFirstChildOfClass("Humanoid")
end

local function GetHRP()
    local Character = LocalPlayer.Character
    if not Character then Character = LocalPlayer.CharacterAdded:Wait() end
    return Character:WaitForChild("HumanoidRootPart", 5)
end

local function Notify(title, content, type)
    Nexus:Notify({
        Title = title or "Notification",
        Content = content or "",
        Duration = 3,
        Type = type or "Info"
    })
end

local function getStatus()
    local char = Players.LocalPlayer.Character
    if not char then return "UNKNOWN" end
    
    local hum = char:FindFirstChild("Humanoid")
    local hrp = char:FindFirstChild("HumanoidRootPart")
    
    if not hum or not hrp then return "UNKNOWN" end

    if hum:GetState() == Enum.HumanoidStateType.Swimming then
        return "WATER (SWIMMING)"
    end

    if hum.FloorMaterial == Enum.Material.Water then
        return "WATER"
    end
    
    if hum.FloorMaterial ~= Enum.Material.Air then
        return "LAND"
    end
    
    local origin = hrp.Position
    local direction = Vector3.new(0, -15, 0)

    local params = RaycastParams.new()
    params.FilterDescendantsInstances = {char}
    params.FilterType = Enum.RaycastFilterType.Exclude -- Gunakan Exclude (Modern), Blacklist (Deprecated)
    params.IgnoreWater = false -- PENTING: Jangan abaikan air

    local result = workspace:Raycast(origin, direction, params)

    if result then
        if result.Material == Enum.Material.Water then
            return "WATER"
        else
            return "LAND"
        end
    end

    return "UNKNOWN" -- Melayang tinggi / Void
end

local function TeleportToLookAt(position, lookVector)
    local hrp = GetHRP()
    if hrp and typeof(position) == "Vector3" and typeof(lookVector) == "Vector3" then
        local targetCFrame = CFrame.new(position, position + lookVector)
        hrp.CFrame = targetCFrame * CFrame.new(0, 0.5, 0)
        --WindUI:Notify({ Title = "Teleport Sukses!", Duration = 3, Icon = "map-pin" })
    end
end

-- Remote Handling
local RPath = {"Packages", "_Index", "sleitnick_net@0.2.0", "net"}
local function GetRemote(remotePath, name, timeout)
    local currentInstance = RepStorage
    for _, childName in ipairs(remotePath) do
        currentInstance = currentInstance:WaitForChild(childName, timeout or 0.5)
        if not currentInstance then return nil end
    end
    return currentInstance:FindFirstChild(name)
end

pcall(function()
    local player = game:GetService("Players").LocalPlayer
    
    -- Cek semua koneksi yang terhubung ke event Idled pemain lokal
    for i, v in pairs(getconnections(player.Idled)) do
        if v.Disable then
            v:Disable() -- Menonaktifkan koneksi event
            --print("[RockHub Anti-AFK] ON")
        end
    end
end)

local eventsList = { 
    "Lochness Hunt","Shark Hunt", "Ghost Shark Hunt", "Worm Hunt", "Black Hole", "Shocked", 
    "Ghost Worm", "Meteor Rain", "Megalodon Hunt", "Treasure Event"
}

local autoEventTargetName = nil 
local autoEventTeleportState = false
local autoEventTeleportThread = nil

-- ===== Lochness config & helper (paste dekat deklarasi eventsList) =====
local LOCH_INTERVAL = 4 * 3600    -- 4 jam (detik)
local LOCH_DURATION = 10 * 60     -- 10 menit (detik)

local lochCountdownGui = nil
local lochCountdownThread = nil

local function getLochNextTimes()
    local now = os.time()
    -- Align ke epoch-based 4-hour grid (mis: 0:00, 4:00, 8:00, ...)
    local base = math.floor(now / LOCH_INTERVAL) * LOCH_INTERVAL
    -- Jika periode saat ini sudah lewat durasi, geser ke periode berikutnya
    if now >= base + LOCH_DURATION then
        base = base + LOCH_INTERVAL
    end
    local startTime = base
    local endTime = startTime + LOCH_DURATION
    local active = now >= startTime and now < endTime
    return startTime, endTime, active
end

local function formatTimeSeconds(sec)
    sec = math.max(0, math.floor(sec))
    local m = math.floor(sec / 60)
    local s = sec % 60
    return string.format("%02d:%02d", m, s)
end

local function showLochCountdown()
    -- already shown?
    if lochCountdownGui and lochCountdownGui.Parent then
        lochCountdownGui.Enabled = true
        return
    end

    local playerGui = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
    lochCountdownGui = Instance.new("ScreenGui")
    lochCountdownGui.Name = "LochnessCountdownGUI"
    lochCountdownGui.ResetOnSpawn = false
    lochCountdownGui.IgnoreGuiInset = true
    lochCountdownGui.Parent = playerGui

    local frame = Instance.new("Frame")
    frame.Name = "LochFrame"
    frame.AnchorPoint = Vector2.new(0.5, 0)
    frame.Size = UDim2.new(0, 260, 0, 44)
    frame.Position = UDim2.new(0.5, 0, 0.06, 0)
    frame.BackgroundTransparency = 0.35
    frame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    frame.BorderSizePixel = 0
    frame.Parent = lochCountdownGui

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -12, 1, -8)
    label.Position = UDim2.new(0, 6, 0, 4)
    label.BackgroundTransparency = 1
    label.Font = Enum.Font.GothamBold
    label.TextSize = 18
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.Text = "Lochness: calculating..."
    label.TextXAlignment = Enum.TextXAlignment.Center
    label.Parent = frame

    -- update loop
    if lochCountdownThread then task.cancel(lochCountdownThread) end
    lochCountdownThread = task.spawn(function()
        while lochCountdownGui and lochCountdownGui.Parent do
            local startT, endT, active = getLochNextTimes()
            local now = os.time()
            local remaining = (active and (endT - now)) or (startT - now)
            remaining = math.max(0, remaining)
            if active then
                label.Text = ("Lochness ACTIVE! ends in %s"):format(formatTimeSeconds(remaining))
            else
                label.Text = ("Next Lochness in %s"):format(formatTimeSeconds(remaining))
            end
            task.wait(1)
        end
    end)
end

local function hideLochCountdown()
    if lochCountdownThread then
        pcall(function() task.cancel(lochCountdownThread) end)
        lochCountdownThread = nil
    end
    if lochCountdownGui then
        pcall(function() lochCountdownGui:Destroy() end)
        lochCountdownGui = nil
    end
end

-- ===== Optional: dynamic show/hide of "Lochness Hunt" entry in eventsList =====
local function hasEventInList(tbl, name)
    for i,v in ipairs(tbl) do if v == name then return true, i end end
    return false, nil
end

local function updateLochInEventsList(dropdownElement)
    local startT, endT, active = getLochNextTimes()
    local now = os.time()
    -- show Lochness in dropdown if active OR within 10 minutes to spawn
    local showWindow = active or (startT - now <= 10 * 60)
    local present, idx = hasEventInList(eventsList, "Lochness Hunt")
    if showWindow and not present then
        table.insert(eventsList, "Lochness Hunt")
        if dropdownElement and dropdownElement.Refresh then
            pcall(function() dropdownElement:Refresh(eventsList) end)
        end
    elseif (not showWindow) and present then
        table.remove(eventsList, idx)
        if dropdownElement and dropdownElement.Refresh then
            pcall(function() dropdownElement:Refresh(eventsList) end)
        end
    end
end

local function SanitizeFileName(name)
    name = tostring(name or "")
    name = name:gsub("[^%w%s%-_]", "") -- hapus simbol aneh
    name = name:gsub("%s+", "_")        -- spasi → _
    name = name:sub(1, 32)              -- limit panjang
    return name
end

--------------------------------------------------------------------
-- 🔥 BUILT-IN EVENT TELEPORT ENGINE (NO MODULE REQUIRED)
--------------------------------------------------------------------
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer

local EventTP = {}

EventTP.Events = {
    ["Shark Hunt"] = {
        Vector3.new(1.64999, -1.3500, 2095.72),
        Vector3.new(1369.94, -1.3500, 930.125),
        Vector3.new(-1585.5, -1.3500, 1242.87),
        Vector3.new(-1896.8, -1.3500, 2634.37),
    },

    ["Worm Hunt"] = {
        Vector3.new(2190.85, -1.3999, 97.5749),
        Vector3.new(-2450.6, -1.3999, 139.731),
        Vector3.new(-267.47, -1.3999, 5188.53),
    },

    ["Megalodon Hunt"] = {
        Vector3.new(-1076.3, -1.3999, 1676.19),
        Vector3.new(-1191.8, -1.3999, 3597.30),
        Vector3.new(412.700, -1.3999, 4134.39),
    },

    ["Ghost Shark Hunt"] = {
        Vector3.new(489.558, -1.3500, 25.4060),
        Vector3.new(-1358.2, -1.3500, 4100.55),
        Vector3.new(627.859, -1.3500, 3798.08),
    },

    ["Treasure Hunt"] = nil,
}

EventTP.SearchRadius = 25
EventTP.TeleportCheckInterval = 8
EventTP.HeightOffset = 15
EventTP.SafeZoneRadius = 50
EventTP.RequireEventActive = true
EventTP.UseSmartReteleport = true
EventTP.WaitForEventTimeout = 300

local running = false
local currentEventName = nil
local cachedEventPosition = nil
local eventIsActive = false
local lastTeleportPosition = nil
local lastScanTime = 0
local scanCooldown = 10

local connChild = nil

local function getHRP()
    local c = LocalPlayer.Character
    return c and c:FindFirstChild("HumanoidRootPart")
end

local function applyOffset(v)
    return Vector3.new(v.X, v.Y + EventTP.HeightOffset, v.Z)
end

local function safeCharacter()
    return LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
end

local function doTeleport(pos)
    local ok = pcall(function()
        local c = safeCharacter()
        if not c then return end

        local hrp = c:FindFirstChild("HumanoidRootPart")
        if not hrp then return end

        if c.PrimaryPart then
            c:PivotTo(CFrame.new(pos))
        else
            hrp.CFrame = CFrame.new(pos)
        end
        lastTeleportPosition = pos
    end)
    return ok
end

local function isAlivePart(p)
    if typeof(p) ~= "Instance" then return false end
    if not p:IsA("BasePart") then return false end

    local success = pcall(function()
        return p.Parent ~= nil and p:IsDescendantOf(Workspace)
    end)

    return success
end

-- [[ FIX TICK ERROR ]] --
if not tick then
    getgenv().tick = function() 
        return workspace:GetServerTimeNow() 
    end
end
-- Jika getgenv tidak support, gunakan local fallback:
local function tick()
    return workspace:GetServerTimeNow()
end
--------------------------

local function scan(eventName)
    local now = tick()
    if now - lastScanTime < scanCooldown then
        return cachedEventPosition
    end

    local list = EventTP.Events[eventName]
    if not list or #list == 0 then return nil end

    lastScanTime = now

    for _,coord in ipairs(list) do
        local region = Region3.new(
            coord - Vector3.new(30,30,30),
            coord + Vector3.new(30,30,30)
        ):ExpandToGrid(4)

        local ok, parts = pcall(function()
            return Workspace:FindPartsInRegion3(region,nil,50)
        end)

        if ok and parts and #parts>0 then
            for _,p in ipairs(parts) do
                if isAlivePart(p) then
                    local ps = p.Position
                    if (ps - coord).Magnitude <= EventTP.SearchRadius then
                        local final = applyOffset(ps)
                        cachedEventPosition = final
                        eventIsActive = true
                        return final
                    end
                end
            end
        end
    end
    return nil
end

local function setupListener(eventName)
    if connChild then connChild:Disconnect() connChild=nil end
    local coords = EventTP.Events[eventName]
    if not coords then return end

    connChild = Workspace.ChildAdded:Connect(function(child)
        if not running then return end
        if not isAlivePart(child) then return end

        local pos
        local ok,posTry = pcall(function() return child.Position end)
        if not ok then return end

        for _,coord in ipairs(coords) do
            if (posTry - coord).Magnitude <= EventTP.SearchRadius then
                cachedEventPosition = applyOffset(posTry)
                eventIsActive = true
                return
            end
        end
    end)
end

local function waitActive(eventName)
    local start = tick()
    while tick() - start < EventTP.WaitForEventTimeout do
        local p = scan(eventName)
        if p then return p end
        task.wait(5)
    end
    return nil
end

function EventTP.TeleportNow(name)
    if cachedEventPosition and eventIsActive then
        return doTeleport(cachedEventPosition)
    end
    return false
end

function EventTP.Start(name)
    if running then return false end
    if not EventTP.Events[name] then return false end

    running = true
    currentEventName = name
    cachedEventPosition = nil
    eventIsActive = false
    lastScanTime = 0

    setupListener(name)

    task.spawn(function()
        if EventTP.RequireEventActive then
            local pos = waitActive(name)
            if not pos then
                EventTP.Stop()
                return
            end
            doTeleport(pos)
        end

        local failCount = 0
        while running do
            if cachedEventPosition and eventIsActive then
                doTeleport(cachedEventPosition)
                failCount = 0
            else
                local newPos = scan(name)
                if newPos then
                    cachedEventPosition = newPos
                    eventIsActive = true
                    doTeleport(newPos)
                    failCount = 0
                else
                    -- PERBAIKAN DI SINI:
                    failCount = failCount + 1  -- Jangan pakai +=
                    
                    if failCount >= 3 then
                        EventTP.Stop()
                        break
                    end
                end
            end
            task.wait(EventTP.TeleportCheckInterval)
        end
    end)
    return true
end

function EventTP.Stop()
    running = false
    cachedEventPosition = nil
    currentEventName = nil
    eventIsActive = false
    if connChild then connChild:Disconnect() end
end

_G.EventTP = EventTP
--------------------------------------------------------------------
-- 🔥 END ENGINE
--------------------------------------------------------------------

local function FindAndTeleportToTargetEvent()
    if not autoEventTargetName then
        
        return false
    end

    local eventName = autoEventTargetName

    -------------------------------
    -- 🐍 Special Case: Lochness --
    -------------------------------
    if eventName == "Lochness Hunt" then
        
        -- 1) Cari object Lochness di Workspace
        local foundPart = nil

        for _, inst in ipairs(workspace:GetDescendants()) do
            if inst:IsA("BasePart") then
                local n = inst.Name:lower()
                
                -- ⬇️ ganti keyword sesuai nama asli jika tahu persis
                if string.find(n, "loch") 
                or string.find(n, "ness") 
                or string.find(n, "nessie") then
                    foundPart = inst
                    break
                end
            end
        end

        if foundPart then
            -- Teleport ke object Lochness
            pcall(function()
                local char = Players.LocalPlayer.Character
                if char and char:FindFirstChild("HumanoidRootPart") then
                    char:PivotTo(CFrame.new(foundPart.Position + Vector3.new(0, 6, 0)))
                end
            end)

            
            return true
        end

        -- 2) Jika tidak ditemukan object → coba pakai EventTP Engine (kalau kamu pakai)
        if EventTP and EventTP.TeleportOnce then
            if EventTP.TeleportOnce("Lochness Hunt") then
                return true
            end
        end

        return false
    end


    -- EVENT LAIN pakai engine baru
    if EventTP.TeleportNow(eventName) then
        return true
    end

    return false
end

local function StartAutoEvent()
    -- Simpan posisi awal player sebelum dipaksa ke event
    local hrp = GetHRP()
    if hrp then
        Generic_PreEvent_CFrame = hrp.CFrame
    end

    local ok = EventTP.Start(autoEventTargetName)
    if ok then
    else
        Window:GetElementByTitle("Enable Auto Event Teleport"):Set(false)
    end
end

local function StopAutoEvent()
    EventTP.Stop()
end

-- 🛑 HOOK STOP → balik ke area / posisi lama
do
    local OldStop = EventTP.Stop
    EventTP.Stop = function(...)
        local result = OldStop(...)

        -- Jangan ganggu Lochness karena sudah punya sistem sendiri
        if autoEventTargetName ~= "Lochness Hunt" then
            task.delay(0.5, ReturnAfterAnyEvent)
        end
        
        return result
    end
end
----------------------------------------------------
-- SAFE LAND SPOT
----------------------------------------------------
local SAFE_LAND_POSITION = Vector3.new(6027.88, -585.92, 4710.96)

local Lochness_PreTeleported = false
local Lochness_Returned = false
local Saved_PreLoch_CFrame = nil

-- AREA tujuan setelah event selesai
local Loch_Return_SelectedArea = nil
-- 🌍 GLOBAL RETURN SUPPORT (UNTUK SEMUA EVENT)
local Generic_PreEvent_CFrame = nil

local function ReturnAfterAnyEvent()
    -- PRIORITAS 1 → balik ke Fishing Area jika user pilih
    if Loch_Return_SelectedArea and FishingAreass and FishingAreass[Loch_Return_SelectedArea] then
        local data = FishingAreass[Loch_Return_SelectedArea]
        TeleportToLookAt(data.Pos, data.Look)

        return
    end

    -- PRIORITAS 2 → balik ke posisi awal sebelum event
    if Generic_PreEvent_CFrame then
        local char = Players.LocalPlayer.Character
        if char then
            pcall(function()
                char:PivotTo(Generic_PreEvent_CFrame)
            end)
        end
    end
end

local function TeleportToSafeLand()
    local Players = game:GetService("Players")
    local player = Players.LocalPlayer
    local character = player.Character
    if not character then return end

    local hrp = character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    pcall(function()
        if character.PrimaryPart then
            character:PivotTo(CFrame.new(SAFE_LAND_POSITION))
        else
            hrp.CFrame = CFrame.new(SAFE_LAND_POSITION)
        end
    end)

end

local function RunAutoEventTeleportLoop()
    if autoEventTeleportThread then task.cancel(autoEventTeleportThread) end

    autoEventTeleportThread = task.spawn(function()
        --WindUI:Notify({ Title = "Auto Event TP ON", Content = "Mulai memindai event terpilih.", Duration = 3, Icon = "search" })
        
        while autoEventTeleportState do
            
            if FindAndTeleportToTargetEvent() then
                
                task.wait(900) 
            else
                
                task.wait(10)
            end
        end
        
        --WindUI:Notify({ Title = "Auto Event TP OFF", Duration = 3, Icon = "x" })
    end)
end

-- Remotes Global (Digunakan oleh V3 & Fishing Area)
local RE_EquipToolFromHotbar = GetRemote(RPath, "RE/EquipToolFromHotbar")
local RF_ChargeFishingRod = GetRemote(RPath, "RF/ChargeFishingRod")
local RF_RequestFishingMinigameStarted = GetRemote(RPath, "RF/RequestFishingMinigameStarted")
local RE_FishingCompleted = GetRemote(RPath, "RE/FishingCompleted")
local RF_CancelFishingInputs = GetRemote(RPath, "RF/CancelFishingInputs")
local RF_UpdateAutoFishingState = GetRemote(RPath, "RF/UpdateAutoFishingState")

local function checkFishingRemotes()
    if not (RE_EquipToolFromHotbar and RF_ChargeFishingRod and RF_RequestFishingMinigameStarted and RE_FishingCompleted) then
        --WindUI:Notify({ Title = "Error", Content = "Fishing Remotes not found!", Duration = 5, Icon = "x" })
        return false
    end
    return true
end

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

LocalPlayer.CharacterAdded:Connect(OnCharacterAdded)

-- =================================================================
-- MODERN DASHBOARD (CUSTOM UI INJECTION)
-- =================================================================
do
    local DashboardTab = Window:Tab({Text = "Dashboard", Icon = "🏠"})
    
    -- [[ 1. HELPER FUNGSI GUI (Untuk membuat Card Custom) ]]
    local function Create(class, props)
        local inst = Instance.new(class)
        for k, v in pairs(props) do inst[k] = v end
        return inst
    end
    
    local function AddCorner(parent, radius)
        Create("UICorner", {CornerRadius = UDim.new(0, radius or 8), Parent = parent})
    end
    
    local function AddGradient(parent, colors, rotation)
        Create("UIGradient", {
            Color = ColorSequence.new(colors),
            Rotation = rotation or 45,
            Parent = parent
        })
    end

    local Players = game:GetService("Players")
    local LocalPlayer = Players.LocalPlayer
    
    -- Akses halaman scrolling frame dari Tab NexusUI
    local ParentPage = DashboardTab.Page 
    ParentPage.UIListLayout.Padding = UDim.new(0, 12) -- Jarak antar elemen vertikal

    -- =========================================================
    -- [A] PROFILE HEADER
    -- =========================================================
    local ProfileCard = Create("Frame", {
        BackgroundColor3 = Color3.fromRGB(20, 20, 25),
        Size = UDim2.new(1, 0, 0, 70),
        Parent = ParentPage
    })
    AddCorner(ProfileCard, 12)
    Create("UIStroke", {Color = Color3.fromRGB(60, 60, 60), Thickness = 1, Transparency = 0.5, Parent = ProfileCard})

    -- Foto Profil
    local Avatar = Create("ImageLabel", {
        Size = UDim2.fromOffset(50, 50),
        Position = UDim2.new(0, 10, 0.5, -25),
        BackgroundTransparency = 1,
        Parent = ProfileCard
    })
    AddCorner(Avatar, 25) -- Bulat
    
    -- Load Gambar Async
    task.spawn(function()
        local content = Players:GetUserThumbnailAsync(LocalPlayer.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size48x48)
        Avatar.Image = content
    end)

    -- Teks Nama
    Create("TextLabel", {
        Text = "Hello, " .. LocalPlayer.DisplayName,
        Font = Enum.Font.GothamBold, TextSize = 16, TextColor3 = Color3.new(1,1,1),
        BackgroundTransparency = 1, Position = UDim2.new(0, 70, 0, 12), Size = UDim2.new(1, -80, 0, 20),
        TextXAlignment = Enum.TextXAlignment.Left, Parent = ProfileCard
    })
    
    Create("TextLabel", {
        Text = "@" .. LocalPlayer.Name .. " | Script User",
        Font = Enum.Font.Gotham, TextSize = 12, TextColor3 = Color3.fromRGB(150, 150, 150),
        BackgroundTransparency = 1, Position = UDim2.new(0, 70, 0, 34), Size = UDim2.new(1, -80, 0, 16),
        TextXAlignment = Enum.TextXAlignment.Left, Parent = ProfileCard
    })

    -- =========================================================
    -- [B] GRID CONTAINER (Server Info & Exec Info)
    -- =========================================================
    -- Kita buat container horizontal agar Server Card dan Info Card bersebelahan
    local GridContainer = Create("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 260), -- Tinggi total area grid
        Parent = ParentPage
    })
    
    -- Layout Grid (Otomatis bagi 2 kolom)
    local GridLayout = Create("UIGridLayout", {
        CellPadding = UDim2.fromOffset(10, 10),
        CellSize = UDim2.new(0.48, 0, 1, 0), -- Lebar 48% (ada sisa buat padding)
        FillDirection = Enum.FillDirection.Horizontal,
        HorizontalAlignment = Enum.HorizontalAlignment.Center,
        Parent = GridContainer
    })

    -- 1. SERVER INFO CARD (Kiri)
    local ServerCard = Create("Frame", {
        BackgroundColor3 = Color3.fromRGB(15, 15, 20),
        Parent = GridContainer
    })
    AddCorner(ServerCard, 12)
    -- Gradient Hijau Tipis
    AddGradient(ServerCard, {
        ColorSequenceKeypoint.new(0, Color3.fromRGB(20, 50, 30)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(15, 15, 20))
    }, 90)
    Create("UIStroke", {Color = Color3.fromRGB(40, 80, 50), Thickness = 1, Transparency = 0.6, Parent = ServerCard})

    Create("TextLabel", {
        Text = "Server Info", Font = Enum.Font.GothamBold, TextSize = 14, TextColor3 = Color3.new(1,1,1),
        BackgroundTransparency = 1, Position = UDim2.new(0, 12, 0, 12), Size = UDim2.new(1, 0, 0, 16),
        TextXAlignment = Enum.TextXAlignment.Left, Parent = ServerCard
    })

    -- List Info Server
    local InfoList = Create("Frame", {
        BackgroundTransparency = 1, Size = UDim2.new(1, -24, 1, -40),
        Position = UDim2.new(0, 12, 0, 40), Parent = ServerCard
    })
    Create("UIListLayout", {Padding = UDim.new(0, 8), Parent = InfoList})

    local function CreateStatBox(title, valText)
        local Box = Create("Frame", {
            BackgroundColor3 = Color3.fromRGB(25, 25, 30), Size = UDim2.new(1, 0, 0, 40), Parent = InfoList
        })
        AddCorner(Box, 6)
        Create("TextLabel", {
            Text = title, Font = Enum.Font.Gotham, TextSize = 10, TextColor3 = Color3.fromRGB(150, 150, 150),
            BackgroundTransparency = 1, Position = UDim2.new(0, 8, 0, 4), Size = UDim2.new(1, -16, 0, 12),
            TextXAlignment = Enum.TextXAlignment.Left, Parent = Box
        })
        local Val = Create("TextLabel", {
            Text = valText, Font = Enum.Font.GothamBold, TextSize = 12, TextColor3 = Color3.new(1,1,1),
            BackgroundTransparency = 1, Position = UDim2.new(0, 8, 0, 20), Size = UDim2.new(1, -16, 0, 14),
            TextXAlignment = Enum.TextXAlignment.Left, Parent = Box
        })
        return Val
    end

    local PlayerStat = CreateStatBox("Players", "0 / " .. Players.MaxPlayers)
    local PingStat = CreateStatBox("Latency", "0 ms")
    local TimeStat = CreateStatBox("In server for", "00:00:00")
    
    local JoinBtn = Create("TextButton", {
        Text = "Copy Join Script", Font = Enum.Font.GothamBold, TextSize = 11,
        TextColor3 = Color3.new(1,1,1), BackgroundColor3 = Color3.fromRGB(40, 40, 45),
        Size = UDim2.new(1, 0, 0, 32), Parent = InfoList
    })
    AddCorner(JoinBtn, 6)
    JoinBtn.MouseButton1Click:Connect(function()
        if setclipboard then 
            setclipboard('game:GetService("TeleportService"):TeleportToPlaceInstance('..game.PlaceId..', "'..game.JobId..'", game.Players.LocalPlayer)')
            Nexus:Notify({Title="Copied", Content="Join script copied!", Type="Success"})
        end
    end)

    -- 2. RIGHT COLUMN (Executor & Friends)
    local RightCol = Create("Frame", {
        BackgroundTransparency = 1, Parent = GridContainer
    })
    -- Kita tidak pakai layout otomatis di kanan, manual positioning biar mirip gambar
    -- Tapi agar rapi, kita bagi 2 card di kanan: Atas (Wave/Exec) dan Bawah (Friends)
    
    -- [Card Executor]
    local ExecCard = Create("Frame", {
        BackgroundColor3 = Color3.fromRGB(30, 15, 15),
        Size = UDim2.new(1, 0, 0, 80), Position = UDim2.new(0, 0, 0, 0),
        Parent = RightCol
    })
    AddCorner(ExecCard, 12)
    AddGradient(ExecCard, { -- Gradient Merah
        ColorSequenceKeypoint.new(0, Color3.fromRGB(80, 20, 20)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(30, 15, 15))
    }, -45)
    
    local executorName = identifyexecutor and identifyexecutor() or "Unknown"
    Create("TextLabel", {
        Text = executorName, Font = Enum.Font.GothamBold, TextSize = 18, TextColor3 = Color3.new(1,1,1),
        BackgroundTransparency = 1, Position = UDim2.new(0, 12, 0, 12), Size = UDim2.new(1, 0, 0, 20),
        TextXAlignment = Enum.TextXAlignment.Left, Parent = ExecCard
    })
    Create("TextLabel", {
        Text = "Your executor supports this script.", Font = Enum.Font.Gotham, TextSize = 11, 
        TextColor3 = Color3.fromRGB(200, 200, 200), BackgroundTransparency = 1, 
        Position = UDim2.new(0, 12, 0, 36), Size = UDim2.new(1, -24, 0, 30),
        TextXAlignment = Enum.TextXAlignment.Left, TextWrapped = true, Parent = ExecCard
    })

    -- [Card Friends]
    local FriendCard = Create("Frame", {
        BackgroundColor3 = Color3.fromRGB(30, 25, 15),
        Size = UDim2.new(1, 0, 1, -90), Position = UDim2.new(0, 0, 0, 90), -- Di bawah Exec Card
        Parent = RightCol
    })
    AddCorner(FriendCard, 12)
    AddGradient(FriendCard, { -- Gradient Kuning/Emas
        ColorSequenceKeypoint.new(0, Color3.fromRGB(60, 50, 20)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(20, 20, 20))
    }, -45)

    Create("TextLabel", {
        Text = "Friends", Font = Enum.Font.GothamBold, TextSize = 14, TextColor3 = Color3.new(1,1,1),
        BackgroundTransparency = 1, Position = UDim2.new(0, 12, 0, 12), Size = UDim2.new(1, 0, 0, 16),
        TextXAlignment = Enum.TextXAlignment.Left, Parent = FriendCard
    })

    local FriendGrid = Create("Frame", {
        BackgroundTransparency = 1, Size = UDim2.new(1, -24, 1, -40),
        Position = UDim2.new(0, 12, 0, 36), Parent = FriendCard
    })
    Create("UIGridLayout", {
        CellSize = UDim2.new(0.48, 0, 0.45, 0), CellPadding = UDim2.fromOffset(5, 5), Parent = FriendGrid
    })

    local function CreateFriendBox(label)
        local box = Create("Frame", {BackgroundColor3 = Color3.fromRGB(0,0,0), BackgroundTransparency = 0.5, Parent = FriendGrid})
        AddCorner(box, 6)
        Create("TextLabel", {
            Text = label, Font = Enum.Font.GothamBold, TextSize = 11, TextColor3 = Color3.new(1,1,1),
            BackgroundTransparency = 1, Position = UDim2.new(0, 8, 0, 8), Size = UDim2.new(1, 0, 0, 12),
            TextXAlignment = Enum.TextXAlignment.Left, Parent = box
        })
        return Create("TextLabel", {
            Text = "...", Font = Enum.Font.Gotham, TextSize = 10, TextColor3 = Color3.fromRGB(180,180,180),
            BackgroundTransparency = 1, Position = UDim2.new(0, 8, 0, 24), Size = UDim2.new(1, 0, 0, 12),
            TextXAlignment = Enum.TextXAlignment.Left, Parent = box
        })
    end

    local StatInServer = CreateFriendBox("In Server")
    local StatOffline = CreateFriendBox("Offline")
    local StatOnline = CreateFriendBox("Online")
    local StatAll = CreateFriendBox("All")

    -- =========================================================
    -- [C] DISCORD CARD (Full Width Bottom)
    -- =========================================================
    local DiscordCard = Create("Frame", {
        BackgroundColor3 = Color3.fromRGB(20, 20, 35),
        Size = UDim2.new(1, 0, 0, 60),
        Parent = ParentPage
    })
    AddCorner(DiscordCard, 12)
    AddGradient(DiscordCard, { -- Gradient Biru Discord
        ColorSequenceKeypoint.new(0, Color3.fromRGB(88, 101, 242)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(20, 20, 35))
    }, 0)
    
    Create("TextLabel", {
        Text = "Discord Server", Font = Enum.Font.GothamBold, TextSize = 16, TextColor3 = Color3.new(1,1,1),
        BackgroundTransparency = 1, Position = UDim2.new(0, 12, 0, 10), Size = UDim2.new(1, 0, 0, 20),
        TextXAlignment = Enum.TextXAlignment.Left, Parent = DiscordCard
    })
    Create("TextLabel", {
        Text = "Tap to join community", Font = Enum.Font.Gotham, TextSize = 12, TextColor3 = Color3.fromRGB(200, 200, 220),
        BackgroundTransparency = 1, Position = UDim2.new(0, 12, 0, 30), Size = UDim2.new(1, 0, 0, 16),
        TextXAlignment = Enum.TextXAlignment.Left, Parent = DiscordCard
    })
    
    local DiscordBtn = Create("TextButton", {
        Text = "", BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, 0), Parent = DiscordCard
    })
    DiscordBtn.MouseButton1Click:Connect(function()
        if setclipboard then 
            setclipboard("https://discord.gg/SNMrRFySkY")
            Nexus:Notify({Title="Discord", Content="Invite copied to clipboard!", Type="Info"})
        end
    end)

    -- =========================================================
    -- [D] LOGIKA UPDATE DATA REALTIME
    -- =========================================================
    task.spawn(function()
        local startTime = tick()
        while DashboardTab.Page.Parent do -- Stop jika UI di-destroy
            -- Update Ping
            local ping = 0
            pcall(function() ping = game:GetService("Stats").Network.ServerStatsItem["Data Ping"]:GetValue() end)
            PingStat.Text = math.floor(ping) .. " ms"
            
            -- Update Players
            PlayerStat.Text = #Players:GetPlayers() .. " / " .. Players.MaxPlayers
            
            -- Update Time
            local diff = tick() - startTime
            local hrs = math.floor(diff / 3600)
            local mins = math.floor((diff % 3600) / 60)
            local secs = math.floor(diff % 60)
            TimeStat.Text = string.format("%02d:%02d:%02d", hrs, mins, secs)
            
            task.wait(1)
        end
    end)
    
    -- Update Friends (Sekali jalan saja biar gak lag)
    task.spawn(function()
        local friendsOnline = 0
        local friendsOffline = 0
        local friendsInGame = 0
        
        -- Logic simulasi (karena GetFriendsAsync berat)
        -- Anda bisa menambahkan logika GetFriendsAsync asli jika mau
        StatAll.Text = "Unknown" 
        StatOnline.Text = "Checking..."
        
        pcall(function()
            local friends = Players.LocalPlayer:GetFriendsOnline(200)
            StatOnline.Text = #friends .. " Friends"
            
            for _, f in pairs(friends) do
                if f.PlaceId == game.PlaceId then friendsInGame = friendsInGame + 1 end
            end
            StatInServer.Text = friendsInGame .. " Here"
        end)
    end)
end

-- =================================================================
-- 2. TAB PLAYER
-- =================================================================
do
    local PlayerTab = Window:Tab({Text = "Player", Icon = "👤"})
    local MovementSection = PlayerTab:Section("Movement")  -- Create section properly

    -- FIXED: Direct call on tab, not section
    PlayerTab:Slider({
        Text = "Walkspeed",  -- Use Text, not Title
        Min = 16,
        Max = 200,
        Default = 16,
        Callback = function(value)
            local hum = GetHumanoid()
            if hum then 
                hum.WalkSpeed = tonumber(value) 
            end
        end,
        Flag = "SpeedValue"
    })

    PlayerTab:Slider({
        Text = "Jump Power",
        Min = 50,
        Max = 200,
        Default = 50,
        Callback = function(value)
            local hum = GetHumanoid()
            if hum then 
                hum.JumpPower = tonumber(value) 
            end
        end,
        Flag = "JumpValue"
    })

    -- Add button that resets movement
    PlayerTab:Button({
        Text = "Reset Movement",
        Callback = function()
            local hum = GetHumanoid()
            if hum then
                hum.WalkSpeed = 16
                hum.JumpPower = 50
            end
        end
    })

    -- Add freeze toggle
    PlayerTab:Toggle({
        Text = "Freeze Player",
        Default = false,
        Callback = function(state)
            local hrp = GetHRP()
            if hrp then
                hrp.Anchored = state
                if state then 
                    hrp.AssemblyLinearVelocity = Vector3.new(0,0,0) 
                end
            end
        end
    })
    
    do
        local GhostCollapsible = PlayerTab:Collapsible("Ghost Mode")
        
        local GhostConnection = nil
        local IsGhostActive = false
        local RunService = game:GetService("RunService")
        local GhostTransparency = 1 -- Default transparansi (1 = Invisible total)
        
        -- Fungsi Loop yang Lebih Ringan & Dinamis
        local function GhostLoopFunc()
            local char = LocalPlayer.Character
            if not char then return end
            
            for _, v in ipairs(char:GetDescendants()) do
                if v:IsA("BasePart") then
                    if v.Transparency ~= GhostTransparency then
                        v.Transparency = GhostTransparency
                    end
                elseif v:IsA("Decal") then
                    if v.Transparency ~= GhostTransparency then
                        v.Transparency = GhostTransparency
                    end
                elseif v:IsA("BillboardGui") or v:IsA("SurfaceGui") then
                    if v.Enabled then v.Enabled = false end
                end
            end
        end

        -- [TAMBAHAN] Dropdown di dalam Collapsible
        GhostCollapsible:Dropdown({
            Text = "Visibility Level",
            Options = {"Fully Invisible", "Semi-Transparent", "Low Visibility"},
            Default = "Fully Invisible",
            Callback = function(val)
                -- Logika mengubah transparansi berdasarkan pilihan dropdown
                if val == "Fully Invisible" then
                    GhostTransparency = 1
                elseif val == "Semi-Transparent" then
                    GhostTransparency = 0.5
                elseif val == "Low Visibility" then
                    GhostTransparency = 0.8
                end
                
                -- Update notifikasi kecil
                Nexus:Notify({Title = "Ghost Setting", Content = "Mode: " .. val})
            end
        })

        -- Toggle Ghost Mode
        GhostCollapsible:Toggle({
            Text = "Enable Ghost Mode",
            Default = false,
            Flag = "GhostMode",
            Callback = function(state)
                IsGhostActive = state
                
                if state then
                    -- [AKTIFKAN]
                    if GhostConnection then GhostConnection:Disconnect() end
                    GhostConnection = RunService.RenderStepped:Connect(GhostLoopFunc)
                    
                    Nexus:Notify({Title = "Ghost Mode", Content = "Activated!", Type = "Success"})
                else
                    -- [MATIKAN]
                    if GhostConnection then 
                        GhostConnection:Disconnect() 
                        GhostConnection = nil
                    end
                    
                    -- Restore tampilan
                    local char = LocalPlayer.Character
                    if char then
                        for _, v in ipairs(char:GetDescendants()) do
                            if v:IsA("BasePart") and v.Name ~= "HumanoidRootPart" then
                                v.Transparency = 0
                            elseif v:IsA("Decal") then
                                v.Transparency = 0
                            elseif v:IsA("BillboardGui") or v:IsA("SurfaceGui") then
                                v.Enabled = true
                            end
                        end
                    end
                    
                    Nexus:Notify({Title = "Ghost Mode", Content = "Deactivated", Type = "Warning"})
                end
            end
        })
        
        -- Auto-Cleanup
        LocalPlayer.CharacterAdded:Connect(function()
            if IsGhostActive and not GhostConnection then
                GhostConnection = RunService.RenderStepped:Connect(GhostLoopFunc)
            end
        end)
    end

    -- =================================================================
    -- TROLLING SECTION (FLING)
    -- =================================================================
    do
        local TrollSection = PlayerTab:Collapsible("Trolling Server (Fling)")

        local FlingState = false
        local FlingTarget = nil
        local FlingSpeed = 10000 
        local DropdownPlayer = nil -- Variabel untuk dropdown

        -- Fungsi Helper: Ambil nama player
        local function GetPlayerNames()
            local list = {}
            for _, v in pairs(game.Players:GetPlayers()) do
                if v ~= LocalPlayer then
                    table.insert(list, v.Name)
                end
            end
            if #list == 0 then list = {"No Players"} end
            return list
        end

        -- 1. Dropdown Player Selection
        DropdownPlayer = TrollSection:Dropdown({
            Text = "Select Target",
            Options = GetPlayerNames(),
            Default = "Select Player",
            Callback = function(val)
                FlingTarget = game.Players:FindFirstChild(val)
            end
        })

        -- 2. Button Refresh List
        TrollSection:Button({
            Text = "Refresh Player List",
            Callback = function()
                -- [PERBAIKAN] Gunakan SetOptions, bukan SetValues
                if DropdownPlayer then
                    DropdownPlayer:SetOptions(GetPlayerNames()) 
                end
                Nexus:Notify({Title = "Refresh", Content = "Player list updated!"})
            end
        })

        -- 3. Toggle Start Fling
        TrollSection:Toggle({
            Text = "Start Fling",
            Default = false,
            Callback = function(state)
                FlingState = state
                
                if state then
                    if not FlingTarget then
                        Nexus:Notify({Title = "Error", Content = "Please select a target first!", Type = "Error"})
                        -- Matikan toggle secara visual jika gagal (Optional logic but complex to implement back-call here)
                        return
                    end
                    
                    Nexus:Notify({Title = "Fling", Content = "Attacking: " .. FlingTarget.Name, Type = "Warning"})
                    
                    -- Logika Fling (Loop)
                    task.spawn(function()
                        local RunService = game:GetService("RunService")
                        local NoclipConnection
                        
                        -- Noclip saat fling agar tidak nyangkut
                        NoclipConnection = RunService.Stepped:Connect(function()
                            if not FlingState then 
                                NoclipConnection:Disconnect()
                                return 
                            end
                            local char = LocalPlayer.Character
                            if char then
                                for _, part in pairs(char:GetDescendants()) do
                                    if part:IsA("BasePart") then part.CanCollide = false end
                                end
                            end
                        end)

                        while FlingState and FlingTarget and FlingTarget.Character do
                            local MyRoot = GetHRP() -- Pastikan fungsi GetHRP() ada di scope global script anda
                            local TgtRoot = FlingTarget.Character:FindFirstChild("HumanoidRootPart")
                            local TgtHum = FlingTarget.Character:FindFirstChild("Humanoid")
                            
                            if MyRoot and TgtRoot then
                                -- Teleport & Spin
                                MyRoot.CFrame = TgtRoot.CFrame * CFrame.new(0, -2, 0)
                                MyRoot.Velocity = Vector3.new(0, FlingSpeed, 0)
                                MyRoot.RotVelocity = Vector3.new(FlingSpeed, FlingSpeed, FlingSpeed)
                                
                                -- Paksa musuh duduk/jatuh (opsional)
                                if TgtHum then TgtHum.Sit = true end
                            end
                            
                            -- Cek jika target keluar/mati
                            if not FlingTarget.Parent then break end
                            task.wait()
                        end
                        
                        -- Cleanup saat berhenti
                        if NoclipConnection then NoclipConnection:Disconnect() end
                        local hrp = GetHRP()
                        if hrp then hrp.Velocity = Vector3.zero hrp.RotVelocity = Vector3.zero end
                    end)
                else
                    Nexus:Notify({Title = "Fling", Content = "Stopped", Type = "Info"})
                end
            end
        })
    end
end


do
    local farm = Window:Tab({Text = "Fishing", Icon = "🎣"})
    local fishingCollapsible = farm:Collapsible("Fishing")
    -- =====================================================
    -- GLOBAL VARIABLES & REMOTES
    -- =====================================================
    
    -- State Variables
    local legitAutoState = false
    local normalInstantState = false
    local blatantInstantState = false
    local V4_Active = false
    local V5_Active = false
    
    -- Thread Variables
    local legitClickThread, legitEquipThread
    local normalLoopThread, normalEquipThread
    local blatantLoopThread, blatantEquipThread
    local V4_LoopThread, V5_Thread

    local FishingSM = {}
    local RunService = game:GetService("RunService")
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    
    -- [AUTO DETECT REMOTES]
    local RPath = {"Packages", "_Index", "sleitnick_net@0.2.0", "net"}
    local function GetNet(name) 
        local folder = ReplicatedStorage
        for _, v in ipairs(RPath) do folder = folder:FindFirstChild(v) if not folder then return nil end end
        return folder:FindFirstChild(name)
    end
    
    -- Remote Events (Consolidated)
    local Remotes = {
        EquipTool = GetRemote(RPath, "RE/EquipToolFromHotbar"),
        Charge = GetRemote(RPath, "RF/ChargeFishingRod") or NetFolder["RF/ChargeFishingRod"],
        StartMinigame = GetRemote(RPath, "RF/RequestFishingMinigameStarted") or NetFolder["RF/RequestFishingMinigameStarted"],
        Complete = GetRemote(RPath, "RE/FishingCompleted") or NetFolder["RE/FishingCompleted"],
        Cancel = GetRemote(RPath, "RF/CancelFishingInputs") or NetFolder["RF/CancelFishingInputs"],
        UpdateState = GetRemote(RPath, "RF/UpdateAutoFishingState") or NetFolder["RF/UpdateAutoFishingState"],
        MinigameChanged = GetRemote(RPath, "RE/FishingMinigameChanged") or NetFolder["RE/FishingMinigameChanged"],
        REFishCaught = GetRemote(RPath, "RE/FishCaught") or NetFolder["RE/FishCaught"]
    }
    
    local Config = {
        Legit = { speed = 0.05 },
        Normal = { delay = 1.0 },
        V4 = { completeDelay = 0.72, cancelDelay = 0.28, recastDelay = 0.001 },
        V5 = { completeDelay = 0.79, cancelDelay = 0.329 }
    }
    
    -- Helpers
    local function checkFishingRemotes()
        if not (Remotes.EquipTool and Remotes.Charge and Remotes.StartMinigame and Remotes.Complete) then
            Nexus:Notify({ Title = "Error", Content = "Fishing Remotes not found!", Type = "Error" })
            return false
        end
        return true
    end

    ----------------------------------------------------------------
    -- UI IMPLEMENTATION (NEXUS UI)
    ----------------------------------------------------------------
    local selectedMode = "IDLE"

    fishingCollapsible:Dropdown({
        Text = "Fishing Mode",
        Options = {
            "Idle/Stop",
            "Legit",
            "Normal",
            "Blatant V1",
            "Blatant V2",
            "Blatant V3",
            "Blatant (Perfect)"
        },
        Callback = function(v)
            selectedMode = v
        end
    })

    fishingCollapsible:Button({
        Text = "Apply Fishing Mode",
        Callback = function()
            local map = {
                ["Idle/Stop"] = "IDLE",
                ["Legit"] = "LEGIT",
                ["Normal"] = "NORMAL",
                ["Blatant V1"] = "BLATANT_V1",
                ["Blatant V2"] = "BLATANT_V2",
                ["Blatant V3"] = "BLATANT_V3",
                ["Blatant (Perfect)"] = "BLATANT_BETA"
            }

            _G.FishingSM:Set(map[selectedMode])

            Nexus:Notify({
                Title = "Fishing",
                Content = "Mode: " .. selectedMode,
                Type = "Success"
            })
        end
    })

    ----------------------------------------------------------------
    -- 🎛️ BLATANT CONFIG (RESPECT ORIGINAL LOGIC)
    ----------------------------------------------------------------
    local FishingConfig = {
        V1 = { -- V4 Config Mapped Here
            CompleteDelay = 0.72,
            CancelDelay   = 0.28,
            RecastDelay   = 0.001,
            FishNotifyDuration = 6.7
        },
        V2 = {
            CastDelay     = 0.25,
            CompleteDelay = 0.79,
            CancelDelay   = 0.329,
            FishNotifyDuration = 8
        },
        BETA = {
            Interval      = 1.715,
            CompleteDelay = 3.055,
            CancelDelay   = 0.30
        },
        FishingTiming = {
            CompleteDelay = 0.75,
            CancelDelay   = 0.25,
            RecastDelay   = 0.05
        },
        V3 = {
            CastSpam      = 3,      -- berapa kali lempar bait
            CastDelay     = 0.01,   -- jeda antar cast
            CompleteDelay = 0.65,   -- timing utama tarik
            CancelDelay   = 0.12,
            RecastDelay   = 0.04,
            Timeout       = 1.2     -- fallback kalau event ga dateng
        }
    }

    _G.FishingConfig = FishingConfig

    local function safe(fn) task.spawn(function() pcall(fn) end) end
    local function SpoofController(active)
        local s, FishingController = pcall(function() return require(game.ReplicatedStorage.Controllers.FishingController) end)
        if s and FishingController then
            if active then
                FishingController.RequestChargeFishingRod = function(...) end -- Disable client logic
                FishingController.SendFishingRequestToServer = function(...) return false, "Blocked" end
            end
        end
    end
    ----------------------------------------------------------------
    -- 🎣 FISH CAUGHT NOTIFICATION OVERRIDE (CLIENT SIDE)
    ----------------------------------------------------------------
    local FishNotifyEvent = RepStorage
        :WaitForChild("Packages")
        :WaitForChild("_Index")
        :WaitForChild("sleitnick_net@0.2.0")
        :WaitForChild("net")
        :WaitForChild("RE/ObtainedNewFishNotification")

    local FishNotifyConnection
    local FishNotifyHooked = false
    local NotifyHookActive = false
    
    local function ToggleNotifyDurationHook(state)
        local success, TextController = pcall(function() 
            return require(game:GetService("ReplicatedStorage").Controllers.TextNotificationController) 
            
        end)

        if not success or not TextController then return end

        if state then
            if not TextController._OldDeliver then 
                TextController._OldDeliver = TextController.DeliverNotification 
            end

            TextController.DeliverNotification = function(self, data)
                if data and (data.Type == "Item" or data.ItemType == "Fishes") then
                    data.CustomDuration = _G.FishingConfig.V1.FishNotifyDuration or 6.5
                end
                
                return TextController._OldDeliver(self, data)
            end
            NotifyHookActive = true
        else
            if TextController._OldDeliver then
                TextController.DeliverNotification = TextController._OldDeliver
                TextController._OldDeliver = nil
            end
            NotifyHookActive = false
        end
    end

    local function DisableFishNotifyOverride()
        if FishNotifyConnection then
            FishNotifyConnection:Disconnect()
            FishNotifyConnection = nil
        end
        FishNotifyHooked = false
    end
    
    FishingSM.Current = "IDLE"
    FishingSM.Threads = {}

    FishingSM.ValidStates = {
        IDLE = true,
        LEGIT = true,
        NORMAL = true,
        BLATANT_V1 = true,
        BLATANT_V2 = true,
        BLATANT_V3 = true, -- ⬅️ BARU
        BLATANT_BETA = true
    }

    local function KillThreads()
        for _, t in pairs(FishingSM.Threads) do
            if t then task.cancel(t) end
        end
        FishingSM.Threads = {}
    end

    function FishingSM:Stop()
        KillThreads()

        legitAutoState = false
        normalInstantState = false
        V4_Active = false
        V5_Active = false
        blatantInstantState = false
        _G.RockHub_BlatantActive = false
        ToggleNotifyDurationHook(false)
        Stop_Blatant_V3() -- ⬅️ WAJIB

        pcall(function()
            if Remotes and Remotes.Cancel then
                Remotes.Cancel:InvokeServer()
            end
            if Remotes and Remotes.UpdateState then
                Remotes.UpdateState:InvokeServer(false)
            end
        end)

        FishingSM.Current = "IDLE"
    end

    function FishingSM:Set(state)
        if not self.ValidStates[state] then
            warn("Invalid Fishing State:", state)
            return
        end

        if self.Current == state then
            return
        end

        self:Stop()
        self.Current = state

        if state == "LEGIT" then
            Start_Legit()
        elseif state == "NORMAL" then
            Start_Normal()
        elseif state == "BLATANT_V1" then
            Start_Blatant_V1()
        elseif state == "BLATANT_V2" then
            Start_Blatant_V2()
        elseif state == "BLATANT_V3" then
            Start_Blatant_V3() -- ⬅️ INTI
        elseif state == "BLATANT_BETA" then
            Start_Blatant_Beta()
        end
    end

    _G.FishingSM = FishingSM

    ----------------------------------------------------------------
    -- HELPER FUNCTIONS
    ----------------------------------------------------------------
    local function safe(fn)
        task.spawn(function() pcall(fn) end)
    end

    -- Definisi V4 Helpers (Untuk Blatant V1)
    local StatsService = game:GetService("Stats")
    local function GetPing()
        return StatsService.Network.ServerStatsItem["Data Ping"]:GetValue() / 1000
    end
    local V4_State = { lastComplete = 0, cooldown = 0.01 }
    
    local function V4_ProtectedComplete()
        local now = tick()
        if now - V4_State.lastComplete < V4_State.cooldown then return false end
        V4_State.lastComplete = now
        pcall(function() Remotes.Complete:FireServer() end)
        pcall(function() Remotes.Complete:FireServer() end)
        pcall(function() Remotes.Complete:FireServer() end)
        return true
    end

    function Start_Legit()
        legitAutoState = true

        FishingSM.Threads.Main = task.spawn(function()
            while FishingSM.Current == "LEGIT" do
                local FishingController = require(RepStorage.Controllers.FishingController)
                local oldRodStarted = FishingController.FishingRodStarted
                FishingController.FishingRodStarted = function(self, ...)
                    oldRodStarted(self, ...)
                    if legitAutoState then
                        legitClickThread = task.spawn(function()
                            while legitAutoState do
                                FishingController:RequestFishingMinigameClick()
                                task.wait(0.3)
                            end
                        end)
                    end
                end
                
                legitEquipThread = task.spawn(function()
                    while legitAutoState do
                        pcall(function() Remotes.EquipTool:FireServer(1) end)
                        task.wait(0.5)
                    end
                end)
                task.wait(0.1)
            end
        end)
    end

    function Start_Normal()
        normalInstantState = true

        FishingSM.Threads.Main = task.spawn(function()
            while FishingSM.Current == "NORMAL" do
                normalLoopThread = task.spawn(function()
                    while normalInstantState do
                        local ts = os.time() + os.clock()
                        pcall(function() Remotes.Charge:InvokeServer(ts) end)
                        pcall(function() Remotes.StartMinigame:InvokeServer(-139.6, 0.99) end)
                        task.wait(Config.Normal.delay or 1)
                        pcall(function() Remotes.Complete:FireServer() end)
                        task.wait(0.3)
                        pcall(function() Remotes.Cancel:InvokeServer() end)
                        task.wait(0.1)
                    end
                end)
                
                normalEquipThread = task.spawn(function()
                    while normalInstantState do
                        pcall(function() Remotes.EquipTool:FireServer(1) end)
                        task.wait(0.5)
                    end
                end)
                task.wait(1)
            end
        end)
    end

    function Start_Blatant_V1()
        V4_Active = true
        ToggleNotifyDurationHook(true)
        FishingSM.Threads.Main = task.spawn(function()
            -- Loop utama mengikuti State Engine
            while FishingSM.Current == "BLATANT_V1" do
                pcall(function() if RE_EquipToolFromHotbar then RE_EquipToolFromHotbar:FireServer(1) end end)
                task.wait(0.1)

                safe(function() Remotes.Charge:InvokeServer({[30] = tick()}) end)
                safe(function() Remotes.Charge:InvokeServer({[50] = tick()}) end)
                task.wait(0.001)
                
                safe(function() Remotes.StartMinigame:InvokeServer(-139.6, 0.99, tick()) end)
                safe(function() Remotes.StartMinigame:InvokeServer(-139.6, 0.99, tick()) end)
                
                task.wait(_G.FishingConfig.FishingTiming.CompleteDelay)

                if FishingSM.Current == "BLATANT_V1" then 
                    V4_ProtectedComplete() 
                end

                task.wait(_G.FishingConfig.FishingTiming.CancelDelay)

                if FishingSM.Current == "BLATANT_V1" then 
                    safe(function() Remotes.Cancel:InvokeServer() end) 
                end

                local recastTime = (_G.FishingConfig.FishingTiming.RecastDelay or 1) * 0.1
                if recastTime < 0.01 then recastTime = 0.01 end
                
                task.wait(recastTime)
            end
        end)
    end

    local V5_State = { lastComplete = 0, cooldown = 0.05 }
    
    local function V4_ProtectedComplete()
        local now = tick()
        if now - V5_State.lastComplete < V5_State.cooldown then return false end
        V5_State.lastComplete = now
        safe(function() Remotes.Complete:FireServer() end)
        safe(function() Remotes.Complete:FireServer() end)
        return true
    end

    function Start_Blatant_V2()
        V5_Active = true
        ToggleNotifyDurationHook(true)
        FishingSM.Threads.Main = task.spawn(function()
            while FishingSM.Current == "BLATANT_V2" do
                pcall(function() if RE_EquipToolFromHotbar then RE_EquipToolFromHotbar:FireServer(1) end end)
                task.wait(0.01)
                
                safe(function() Remotes.Charge:InvokeServer({[30] = tick()}) end)
                safe(function() Remotes.Charge:InvokeServer({[50] = tick()}) end)
                
                task.wait(0.001)

                safe(function() Remotes.StartMinigame:InvokeServer(-1, 0.99, tick()) end)
                safe(function() Remotes.StartMinigame:InvokeServer(-1.25, 1, tick()) end)
                
                task.wait(_G.FishingConfig.FishingTiming.CompleteDelay)

                if FishingSM.Current == "BLATANT_V2" then 
                    V4_ProtectedComplete() 
                end

                task.wait(_G.FishingConfig.FishingTiming.CancelDelay)

                if FishingSM.Current == "BLATANT_V2" then 
                    safe(function() Remotes.Cancel:InvokeServer() end) 
                end

                task.wait(math.max((_G.FishingConfig.FishingTiming.RecastDelay or 1) * 0.45, 0.05))
            end
        end)
    end

    -- =========================================================
    -- BLATANT BETA: STEALTH EDITION (CONTROLLER KILLER)
    -- =========================================================

    local RunService = game:GetService("RunService")
    local CollectionService = game:GetService("CollectionService")
    local PlayerGui = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    
    -- [1] STEALTH & SPOOFING SYSTEM
    local Hooks = {} -- Simpan fungsi asli di sini untuk restore
    local StealthActive = false

    local function SetupStealthMode()
        if StealthActive then return end
        StealthActive = true
        _G.RockHub_BlatantActive = true
        
        -- A. CONTROLLER KILLER (Lumpuhkan Logika Client)
        task.spawn(function()
            local S1, FishingController = pcall(function() return require(ReplicatedStorage.Controllers.FishingController) end)
            if S1 and FishingController then
                -- Simpan fungsi asli jika belum ada
                if not Hooks.RequestCharge then Hooks.RequestCharge = FishingController.RequestChargeFishingRod end
                if not Hooks.SendRequest then Hooks.SendRequest = FishingController.SendFishingRequestToServer end
                
                -- Override: Blokir request manual
                FishingController.RequestChargeFishingRod = function(...)
                    if _G.RockHub_BlatantActive then return end -- Diam, jangan kirim apa-apa
                    return Hooks.RequestCharge(...)
                end
                FishingController.SendFishingRequestToServer = function(...)
                    if _G.RockHub_BlatantActive then return false, "Blocked by RockHub Stealth" end
                    return Hooks.SendRequest(...)
                end
            end
        end)

        -- B. REMOTE KILLER (Blokir Sinyal Mencurigakan)
        local mt = getrawmetatable(game)
        if not Hooks.OldNamecall then Hooks.OldNamecall = mt.__namecall end
        setreadonly(mt, false)
        
        mt.__namecall = newcclosure(function(self, ...)
            local method = getnamecallmethod()
            if _G.RockHub_BlatantActive and not checkcaller() then
                -- Blokir sinyal manual (karena kita kirim pake script loop, bukan manual input)
                if method == "InvokeServer" and (self.Name == "RequestFishingMinigameStarted" or self.Name == "ChargeFishingRod" or self.Name == "UpdateAutoFishingState") then
                    return nil 
                end
                if method == "FireServer" and self.Name == "FishingCompleted" then
                    return nil
                end
            end
            return Hooks.OldNamecall(self, ...)
        end)
        setreadonly(mt, true)

        -- C. UI SPOOFING (VISUAL KILLER)
        task.spawn(function()
            -- 1. Hook Notifikasi (Supaya gak spam "Auto Fishing Enabled")
            local S2, TextController = pcall(function() return require(ReplicatedStorage.Controllers.TextNotificationController) end)
            if S2 and TextController then
                if not Hooks.DeliverNotification then Hooks.DeliverNotification = TextController.DeliverNotification end
                
                TextController.DeliverNotification = function(self, data)
                    if _G.RockHub_BlatantActive and data and data.Text then
                        local txt = tostring(data.Text)
                        if string.find(txt, "Auto Fishing") or string.find(txt, "Reach Level") then
                            return -- Sembunyikan notifikasi ini
                        end
                    end
                    return Hooks.DeliverNotification(self, data)
                end
            end

            -- 2. Ghost UI (Paksa Tombol Jadi Merah/Inactive)
            local InactiveColor = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.fromHex("ff5d60")), 
                ColorSequenceKeypoint.new(1, Color3.fromHex("ff2256"))
            })

            while _G.RockHub_BlatantActive do
                local targets = {}
                for _, btn in ipairs(CollectionService:GetTagged("AutoFishingButton")) do
                    table.insert(targets, btn)
                end
                if #targets == 0 then -- Fallback search
                    local btn = PlayerGui:FindFirstChild("Backpack") and PlayerGui.Backpack:FindFirstChild("AutoFishingButton")
                    if btn then table.insert(targets, btn) end
                end

                for _, btn in ipairs(targets) do
                    local grad = btn:FindFirstChild("UIGradient")
                    if grad then grad.Color = InactiveColor end
                end
                RunService.RenderStepped:Wait()
            end
        end)
    end

    local function CleanupStealthMode()
        StealthActive = false
        _G.RockHub_BlatantActive = false
        -- Fungsi asli akan otomatis terpakai karena logika hook di atas mengecek flag _G.RockHub_BlatantActive
        -- UI akan kembali normal karena loop spoofing berhenti
    end

    -- [2] CORE BLATANT LOGIC
    local loopInterval = 1.715
    local completeDelay = 3.055
    local cancelDelay = 0.3
    
    local function runBlatantInstant()
        task.spawn(function()
            local startTime = os.clock()
            local timestamp = os.time() + os.clock() -- Timestamp presisi
            
            -- Charge & Start (Instant)
            pcall(function() Remotes.Charge:InvokeServer(timestamp) end)
            -- task.wait(0.001) -- Kita coba hapus wait ini biar makin instan (optional)
            pcall(function() Remotes.StartMinigame:InvokeServer(-139.6, 0.99) end)
            
            -- Smart Wait
            local d = _G.FishingConfig.BETA.CompleteDelay or completeDelay
            local completeWaitTime = d - (os.clock() - startTime)
            if completeWaitTime > 0 then task.wait(completeWaitTime) end
            
            -- Finish & Cancel
            pcall(function() Remotes.Complete:FireServer() end)
            task.wait(_G.FishingConfig.BETA.CancelDelay or cancelDelay)
            pcall(function() Remotes.Cancel:InvokeServer() end)
        end)
    end

    function Start_Blatant_Beta()
        -- 1. Aktifkan Stealth System
        SetupStealthMode()
        blatantInstantState = true
        
        -- 2. Fake Update State (Biar server kira kita auto fishing normal)
        if Remotes.UpdateState then
            pcall(function() Remotes.UpdateState:InvokeServer(true) end)
        end

        -- 3. Main Loop
        FishingSM.Threads.Main = task.spawn(function()
            while FishingSM.Current == "BLATANT_BETA" do
                runBlatantInstant()
                task.wait(_G.FishingConfig.BETA.Interval or loopInterval)
            end
            -- Saat loop selesai (dimatikan), bersihkan jejak
            CleanupStealthMode()
        end)

        -- 4. Anti-AFK Equip Loop
        FishingSM.Threads.Equip = task.spawn(function()
            while FishingSM.Current == "BLATANT_BETA" do
                pcall(function() Remotes.EquipTool:FireServer(1) end)
                task.wait(0.1) -- Spam Equip biar gak dianggap AFK
            end
        end)
    end

    -- ================================
    -- 🔥 BLATANT V3 (V1 SPEED + EVENT)
    -- ================================

    local V3_Runtime = {
        Running = false,
        Waiting = false,
        LastCycle = 0
    }

    local function V3_CastCycle()
        if not V3_Runtime.Running or V3_Runtime.Waiting then return end
        V3_Runtime.Waiting = true
        V3_Runtime.LastCycle = os.clock()

        pcall(function()
            Remotes.EquipTool:FireServer(1)
        end)

        for i = 1, (_G.FishingConfig.V3.CastSpam or 3) do
            safe(function()
                Remotes.Charge:InvokeServer({[30] = tick()})
                Remotes.StartMinigame:InvokeServer(-139.6, 0.99, tick())
            end)
            task.wait(_G.FishingConfig.V3.CastDelay or 0.01)
        end

        task.delay(_G.FishingConfig.V3.CompleteDelay, function()
            if not V3_Runtime.Running or not V3_Runtime.Waiting then return end

            safe(function() Remotes.Complete:FireServer() end)
            safe(function() Remotes.Complete:FireServer() end)

            task.wait(_G.FishingConfig.V3.CancelDelay)
            safe(function() Remotes.Cancel:InvokeServer() end)
        end)

        task.delay(_G.FishingConfig.V3.Timeout, function()
            if not V3_Runtime.Running or not V3_Runtime.Waiting then return end

            V3_Runtime.Waiting = false
            safe(function() Remotes.Cancel:InvokeServer() end)
            task.wait(_G.FishingConfig.V3.RecastDelay)
            V3_CastCycle()
        end)
    end

    function Start_Blatant_V3()
        if V3_Runtime.Running then return end
        V3_Runtime.Running = true
        ToggleNotifyDurationHook(true)
        _G.RockHub_BlatantActive = true
        V3_CastCycle()
    end

    function Stop_Blatant_V3()
        V3_Runtime.Running = false
        V3_Runtime.Waiting = false
    end

    -- HOOK EVENT
    Remotes.MinigameChanged.OnClientEvent:Connect(function(state)
        if not V3_Runtime.Running or not V3_Runtime.Waiting then return end
        if tostring(state):lower():find("hook") then
            V3_Runtime.Waiting = false

            task.spawn(function()
                safe(function() Remotes.Complete:FireServer() end)
                task.wait(_G.FishingConfig.V3.CancelDelay)
                safe(function() Remotes.Cancel:InvokeServer() end)
                task.wait(_G.FishingConfig.V3.RecastDelay)
                V3_CastCycle()
            end)
        end
    end)

    -- FISH CAUGHT EVENT
    Remotes.REFishCaught.OnClientEvent:Connect(function()
        if not V3_Runtime.Running then return end
        V3_Runtime.Waiting = false

        task.spawn(function()
            task.wait(_G.FishingConfig.V3.CancelDelay)
            safe(function() Remotes.Cancel:InvokeServer() end)
            task.wait(_G.FishingConfig.V3.RecastDelay)
            V3_CastCycle()
        end)
    end)


    fishingCollapsible:Input({
        Text = "Complete Delay",
        Placeholder = tostring(_G.FishingConfig.FishingTiming.CompleteDelay),
        Flag = "v1_blatant_CompleteDelay",
        Callback = function(v)
            local n = tonumber(v)
            if n then _G.FishingConfig.FishingTiming.CompleteDelay = n end
        end
    })

    fishingCollapsible:Input({
        Text = "Cancel Delay",
        Placeholder = tostring(_G.FishingConfig.FishingTiming.CancelDelay),
        Flag = "v1_blatant_CancelDelay",
        Callback = function(v)
            local n = tonumber(v)
            if n then _G.FishingConfig.FishingTiming.CancelDelay = n end
        end
    })
    
    fishingCollapsible:Input({
        Text = "Cast Delay (v3)",
        Placeholder = tostring(_G.FishingConfig.V3.CastDelay),
        Flag = "v3_blatant_CompleteDelay",
        Callback = function(v)
            local n = tonumber(v)
            if n then _G.FishingConfig.V3.CastDelay = n end
        end
    })
    
    fishingCollapsible:Input({
        Text = "Cast Spam (v3)",
        Placeholder = tostring(_G.FishingConfig.V3.CastSpam),
        Flag = "v3_blatant_CastSpamDelay",
        Callback = function(v)
            local n = tonumber(v)
            if n then _G.FishingConfig.V3.CastSpam = n end
        end
    })
    
    fishingCollapsible:Input({
        Text = "Recast Delay (v3)",
        Placeholder = tostring(_G.FishingConfig.V3.RecastDelay),
        Flag = "v3_blatant_RecastDelay",
        Callback = function(v)
            local n = tonumber(v)
            if n then _G.FishingConfig.V3.RecastDelay = n end
        end
    })
    
    fishingCollapsible:Input({
        Text = "Cancel Delay (v3)",
        Placeholder = tostring(_G.FishingConfig.V3.CancelDelay),
        Flag = "v3_blatant_CancelDelay",
        Callback = function(v)
            local n = tonumber(v)
            if n then _G.FishingConfig.V3.CancelDelay = n end
        end
    })

    farm:Divider()

    do
    local AnimCollapsible = farm:Collapsible("🎨 Ultimate Animation Changer")
    
    -- =====================================================
    -- SERVICES & INITIALIZATION
    -- =====================================================
    local RunService = game:GetService("RunService")
    local Players = game:GetService("Players")
    local player = Players.LocalPlayer
    local char = player.Character or player.CharacterAdded:Wait()
    local humanoid = char:WaitForChild("Humanoid")
    
    local Animator = humanoid:FindFirstChildOfClass("Animator")
    if not Animator then
        Animator = Instance.new("Animator", humanoid)
    end
    
    -- =====================================================
    -- 🎯 COMPLETE ANIMATION DATABASE (ALL TYPES)
    -- =====================================================
    
    local AnimationDatabase = {
        -- ⚔️ ECLIPSE KATANA
        ["Eclipse Katana"] = {
            FishCaught = "rbxassetid://107940819382815",
            EquipIdle = "rbxassetid://103641983335689",
            RodThrow = "rbxassetid://82600073500966",
            ReelingIdle = "rbxassetid://115229621326605",
            ReelStart = "rbxassetid://115229621326605",
            ReelIntermission = "rbxassetid://115229621326605",
            StartRodCharge = "rbxassetid://115229621326605",
            LoopedRodCharge = "rbxassetid://115229621326605"
        },
        
        -- 🍪 GINGERBREAD KATANA
        ["Gingerbread Katana"] = {
            FishCaught = "rbxassetid://107940819382815",
            EquipIdle = "rbxassetid://103641983335689",
            RodThrow = "rbxassetid://124037675493192",
            ReelingIdle = "rbxassetid://115229621326605",
            ReelStart = "rbxassetid://115229621326605",
            ReelIntermission = "rbxassetid://115229621326605",
            StartRodCharge = "rbxassetid://115229621326605",
            LoopedRodCharge = "rbxassetid://115229621326605"
        },
        
        -- 🔱 HOLY TRIDENT
        ["Holy Trident"] = {
            FishCaught = "rbxassetid://128167068291703",
            EquipIdle = "rbxassetid://83219020397849",
            RodThrow = "rbxassetid://114917462794864",
            ReelingIdle = "rbxassetid://126831815839724",
            ReelStart = "rbxassetid://126831815839724",
            ReelIntermission = "rbxassetid://126831815839724",
            StartRodCharge = "rbxassetid://83219020397849",
            LoopedRodCharge = "rbxassetid://83219020397849"
        },
        
        -- 🔱 OCEANIC HARPOON
        ["Oceanic Harpoon"] = {
            FishCaught = "rbxassetid://76325124055693",
            EquipIdle = "rbxassetid://77549515147440",
            RodThrow = "rbxassetid://127872348080219",
            ReelingIdle = "rbxassetid://76325124055693",
            ReelStart = "rbxassetid://76325124055693",
            ReelIntermission = "rbxassetid://76325124055693",
            StartRodCharge = "rbxassetid://84873660213983",
            LoopedRodCharge = "rbxassetid://76325124055693"
        },
        
        -- 💀 SOUL SCYTHE
        ["Soul Scythe"] = {
            FishCaught = "rbxassetid://82259219343456",
            EquipIdle = "rbxassetid://84686809448947",
            RodThrow = "rbxassetid://104946400643250",
            ReelingIdle = "rbxassetid://95453600470089",
            ReelStart = "rbxassetid://137684649541594",
            ReelIntermission = "rbxassetid://139621583239992",
            StartRodCharge = "rbxassetid://117668204114399",
            LoopedRodCharge = "rbxassetid://88768375910397"
        },
        
        -- 💀 FROZEN KRAMPUS SCYTHE
        ["Frozen Krampus Scythe"] = {
            FishCaught = "rbxassetid://134934781977605",
            EquipIdle = "rbxassetid://124265469726043",
            RodThrow = "rbxassetid://96196869100887",
            ReelingIdle = "rbxassetid://98716967215984",
            ReelStart = "rbxassetid://98716967215984",
            ReelIntermission = "rbxassetid://98716967215984",
            StartRodCharge = "rbxassetid://93987679432095",
            LoopedRodCharge = "rbxassetid://107284147985305"
        },
        
        -- ⚔️ BINARY EDGE
        ["Binary Edge"] = {
            FishCaught = "rbxassetid://109653945741202",
            EquipIdle = "rbxassetid://103714544264522",
            RodThrow = "rbxassetid://104527781253009",
            ReelingIdle = "rbxassetid://81700883907369",
            ReelStart = "rbxassetid://81700883907369",
            ReelIntermission = "rbxassetid://81700883907369",
            StartRodCharge = "rbxassetid://72745361965091",
            LoopedRodCharge = "rbxassetid://98710992523201"
        },
        
        -- ⚔️ THE VANQUISHER
        ["Vanquisher"] = {
            FishCaught = "rbxassetid://93884986836266",
            EquipIdle = "rbxassetid://123194574699925",
            RodThrow = "rbxassetid://102380394663862",
            ReelingIdle = "rbxassetid://138790747812051",
            ReelStart = "rbxassetid://138790747812051",
            ReelIntermission = "rbxassetid://138790747812051",
            StartRodCharge = "rbxassetid://92063415632933",
            LoopedRodCharge = "rbxassetid://92063415632933"
        },
        
        -- 🔨 BAN HAMMER
        ["Ban Hammer"] = {
            FishCaught = "rbxassetid://96285280763544",
            EquipIdle = "rbxassetid://81302570422307",
            RodThrow = "rbxassetid://123133988645038",
            ReelingIdle = "rbxassetid://74643095451174",
            ReelStart = "rbxassetid://74643095451174",
            ReelIntermission = "rbxassetid://74643095451174",
            StartRodCharge = "rbxassetid://134431618143422",
            LoopedRodCharge = "rbxassetid://128538861163297"
        },
        
        -- ⚔️ CORRUPTION EDGE
        ["Corruption Edge"] = {
            FishCaught = "rbxassetid://126613975718573",
            EquipIdle = "rbxassetid://93958525241489",
            RodThrow = "rbxassetid://84892442268560",
            ReelingIdle = "rbxassetid://110738276580375",
            ReelStart = "rbxassetid://110738276580375",
            ReelIntermission = "rbxassetid://110738276580375",
            StartRodCharge = "rbxassetid://112104009500915",
            LoopedRodCharge = "rbxassetid://112104009500915"
        },
        
        -- 🌸 PRINCESS PARASOL
        ["Princess Parasol"] = {
            FishCaught = "rbxassetid://99143072029495",
            EquipIdle = "rbxassetid://79754634120924",
            RodThrow = "rbxassetid://108621937425",
            ReelingIdle = "rbxassetid://104188512165442",
            ReelStart = "rbxassetid://104188512165442",
            ReelIntermission = "rbxassetid://104188512165442",
            StartRodCharge = "rbxassetid://104188512165442",
            LoopedRodCharge = "rbxassetid://104188512165442"
        },
        
        -- 🎄 CHRISTMAS PARASOL
        ["Christmas Parasol"] = {
            FishCaught = "rbxassetid://99143072029495",
            EquipIdle = "rbxassetid://79754634120924",
            RodThrow = "rbxassetid://122784676901871",
            ReelingIdle = "rbxassetid://104188512165442",
            ReelStart = "rbxassetid://104188512165442",
            ReelIntermission = "rbxassetid://104188512165442",
            StartRodCharge = "rbxassetid://104188512165442",
            LoopedRodCharge = "rbxassetid://104188512165442"
        },
        
        -- 🌺 ETERNAL FLOWER
        ["Eternal Flower"] = {
            FishCaught = "rbxassetid://119567958965696",
            EquipIdle = "rbxassetid://115119558523816",
            RodThrow = "rbxassetid://105844949829012",
            ReelingIdle = "rbxassetid://110020934764602",
            ReelStart = "rbxassetid://135819234295555",
            ReelIntermission = "rbxassetid://86376110148779",
            StartRodCharge = "rbxassetid://77131632555646",
            LoopedRodCharge = "rbxassetid://124036821497471"
        },
        
        -- ⚫ BLACKHOLE SWORD
        ["Blackhole Sword"] = {
            FishCaught = "rbxassetid://88993991486322",
            EquipIdle = "rbxassetid://110434285817259",
            RodThrow = "rbxassetid://120554144611008",
            ReelingIdle = "rbxassetid://126645853428201",
            ReelStart = "rbxassetid://80063739027478",
            ReelIntermission = "rbxassetid://92036914464034",
            StartRodCharge = "rbxassetid://106390588424443",
            LoopedRodCharge = "rbxassetid://76049869128172"
        },
        
        -- 🎸 ELECTRIC GUITAR
        ["Electric Guitar"] = {
            FishCaught = "rbxassetid://117319000848286",
            EquipIdle = "rbxassetid://108792932396384",
            RodThrow = "rbxassetid://92624107165273",
            ReelingIdle = "rbxassetid://134965425664034",
            ReelStart = "rbxassetid://136614469321844",
            ReelIntermission = "rbxassetid://114959536562596",
            StartRodCharge = "rbxassetid://108792932396384",
            LoopedRodCharge = "rbxassetid://108792932396384"
        },
        
        -- 🪕 PIRATE BANJO
        ["Pirate Banjo"] = {
            FishCaught = "rbxassetid://117319000848286",
            EquipIdle = "rbxassetid://120677591068007",
            RodThrow = "rbxassetid://92624107165273",
            ReelingIdle = "rbxassetid://134965425664034",
            ReelStart = "rbxassetid://136614469321844",
            ReelIntermission = "rbxassetid://114959536562596",
            StartRodCharge = "rbxassetid://120677591068007",
            LoopedRodCharge = "rbxassetid://120677591068007"
        },
        
        -- ⚓ KRAKEN ANCHOR
        ["Kraken Anchor"] = {
            FishCaught = "rbxassetid://76325124055693",
            EquipIdle = "rbxassetid://126023229958416",
            RodThrow = "rbxassetid://127872348080219",
            ReelingIdle = "rbxassetid://76325124055693",
            ReelStart = "rbxassetid://76325124055693",
            ReelIntermission = "rbxassetid://76325124055693",
            StartRodCharge = "rbxassetid://84873660213983",
            LoopedRodCharge = "rbxassetid://76325124055693"
        },
        
        -- 🎃 HALLOWEEN COLLECTION
        ["Undead Guitar"] = {
            FishCaught = "rbxassetid://117319000848286",
            EquipIdle = "rbxassetid://130474623877752",
            RodThrow = "rbxassetid://92624107165273",
            ReelingIdle = "rbxassetid://134965425664034",
            ReelStart = "rbxassetid://136614469321844",
            ReelIntermission = "rbxassetid://114959536562596",
            StartRodCharge = "rbxassetid://130474623877752",
            LoopedRodCharge = "rbxassetid://130474623877752"
        },
        
        ["Royal Spider"] = {
            FishCaught = "rbxassetid://82259219343456",
            EquipIdle = "rbxassetid://79263851052023",
            RodThrow = "rbxassetid://104946400643250",
            ReelingIdle = "rbxassetid://95453600470089",
            ReelStart = "rbxassetid://137684649541594",
            ReelIntermission = "rbxassetid://139621583239992",
            StartRodCharge = "rbxassetid://117668204114399",
            LoopedRodCharge = "rbxassetid://88768375910397"
        },
        
        ["Trick O' Treat"] = {
            FishCaught = "rbxassetid://99143072029495",
            EquipIdle = "rbxassetid://105569745192317",
            RodThrow = "rbxassetid://108621937425425",
            ReelingIdle = "rbxassetid://104188512165442",
            ReelStart = "rbxassetid://104188512165442",
            ReelIntermission = "rbxassetid://104188512165442",
            StartRodCharge = "rbxassetid://104188512165442",
            LoopedRodCharge = "rbxassetid://104188512165442"
        },
        
        ["Reaver Scythe"] = {
            FishCaught = "rbxassetid://82259219343456",
            EquipIdle = "rbxassetid://79066316609985",
            RodThrow = "rbxassetid://104946400643250",
            ReelingIdle = "rbxassetid://95453600470089",
            ReelStart = "rbxassetid://137684649541594",
            ReelIntermission = "rbxassetid://139621583239992",
            StartRodCharge = "rbxassetid://117668204114399",
            LoopedRodCharge = "rbxassetid://88768375910397"
        },
        
        ["Spirit Staff"] = {
            FishCaught = "rbxassetid://128167068291703",
            EquipIdle = "rbxassetid://77452908864699",
            RodThrow = "rbxassetid://114917462794864",
            ReelingIdle = "rbxassetid://126831815839724",
            ReelStart = "rbxassetid://126831815839724",
            ReelIntermission = "rbxassetid://126831815839724",
            StartRodCharge = "rbxassetid://83219020397849",
            LoopedRodCharge = "rbxassetid://83219020397849"
        },
        
        -- 🎄 CHRISTMAS COLLECTION
        ["Divine Blade"] = {
            FishCaught = "rbxassetid://109653945741202",
            EquipIdle = "rbxassetid://82781088583962",
            RodThrow = "rbxassetid://104527781253009",
            ReelingIdle = "rbxassetid://81700883907369",
            ReelStart = "rbxassetid://81700883907369",
            ReelIntermission = "rbxassetid://81700883907369",
            StartRodCharge = "rbxassetid://72745361965091",
            LoopedRodCharge = "rbxassetid://98710992523201"
        },
        
        ["Heartfelt Blade"] = {
            FishCaught = "rbxassetid://109653945741202",
            EquipIdle = "rbxassetid://111118151202469",
            RodThrow = "rbxassetid://104527781253009",
            ReelingIdle = "rbxassetid://81700883907369",
            ReelStart = "rbxassetid://81700883907369",
            ReelIntermission = "rbxassetid://81700883907369",
            StartRodCharge = "rbxassetid://72745361965091",
            LoopedRodCharge = "rbxassetid://98710992523201"
        },
        
        ["Candy Cane Trident"] = {
            FishCaught = "rbxassetid://128167068291703",
            EquipIdle = "rbxassetid://131643088615283",
            RodThrow = "rbxassetid://114917462794864",
            ReelingIdle = "rbxassetid://126831815839724",
            ReelStart = "rbxassetid://126831815839724",
            ReelIntermission = "rbxassetid://126831815839724",
            StartRodCharge = "rbxassetid://83219020397849",
            LoopedRodCharge = "rbxassetid://83219020397849"
        },
        
        ["Ornament Axe"] = {
            FishCaught = "rbxassetid://93884986836266",
            EquipIdle = "rbxassetid://90021589040653",
            RodThrow = "rbxassetid://102380394663862",
            ReelingIdle = "rbxassetid://138790747812051",
            ReelStart = "rbxassetid://138790747812051",
            ReelIntermission = "rbxassetid://138790747812051",
            StartRodCharge = "rbxassetid://92063415632933",
            LoopedRodCharge = "rbxassetid://92063415632933"
        },
        
        ["Gingerbread Sword"] = {
            FishCaught = "rbxassetid://107940819382815",
            EquipIdle = "rbxassetid://106017647759827",
            RodThrow = "rbxassetid://124037675493192",
            ReelingIdle = "rbxassetid://115229621326605",
            ReelStart = "rbxassetid://115229621326605",
            ReelIntermission = "rbxassetid://115229621326605",
            StartRodCharge = "rbxassetid://115229621326605",
            LoopedRodCharge = "rbxassetid://115229621326605"
        },
        
        ["Xmas Tree Rod"] = {
            FishCaught = "rbxassetid://99143072029495",
            EquipIdle = "rbxassetid://97171752999251",
            RodThrow = "rbxassetid://122784676901871",
            ReelingIdle = "rbxassetid://104188512165442",
            ReelStart = "rbxassetid://104188512165442",
            ReelIntermission = "rbxassetid://104188512165442",
            StartRodCharge = "rbxassetid://104188512165442",
            LoopedRodCharge = "rbxassetid://104188512165442"
        },
        
        ["Pink Present Lance"] = {
            FishCaught = "rbxassetid://128167068291703",
            EquipIdle = "rbxassetid://101986838283328",
            RodThrow = "rbxassetid://114917462794864",
            ReelingIdle = "rbxassetid://126831815839724",
            ReelStart = "rbxassetid://126831815839724",
            ReelIntermission = "rbxassetid://126831815839724",
            StartRodCharge = "rbxassetid://83219020397849",
            LoopedRodCharge = "rbxassetid://83219020397849"
        }
    }
    
    -- =====================================================
    -- 📊 SKIN CATEGORIES (ORGANIZED)
    -- =====================================================
    local SkinCategories = {
        ["⚔️ Katana Series"] = {
            "Eclipse Katana",
            "Gingerbread Katana"
        },
        ["🔱 Trident & Spear"] = {
            "Holy Trident",
            "Oceanic Harpoon",
            "Candy Cane Trident",
            "Pink Present Lance"
        },
        ["💀 Scythe Series"] = {
            "Soul Scythe",
            "Frozen Krampus Scythe",
            "Reaver Scythe"
        },
        ["⚔️ Sword Series"] = {
            "Binary Edge",
            "Vanquisher",
            "Corruption Edge",
            "Blackhole Sword",
            "Divine Blade",
            "Heartfelt Blade",
            "Gingerbread Sword",
            "Ornament Axe"
        },
        ["🔨 Hammer Series"] = {
            "Ban Hammer"
        },
        ["🌸 Parasol Series"] = {
            "Princess Parasol",
            "Christmas Parasol"
        },
        ["🌺 Special Items"] = {
            "Eternal Flower",
            "Kraken Anchor"
        },
        ["🎸 Musical Instruments"] = {
            "Electric Guitar",
            "Pirate Banjo",
            "Undead Guitar"
        },
        ["🎃 Halloween Collection"] = {
            "Royal Spider",
            "Trick O' Treat",
            "Spirit Staff"
        },
        ["🎄 Christmas Collection"] = {
            "Xmas Tree Rod"
        }
    }
    
    -- Create flat list for dropdown
    local SkinNames = {}
    for category, skins in pairs(SkinCategories) do
        table.insert(SkinNames, "━━━ " .. category .. " ━━━")
        for _, skin in ipairs(skins) do
            table.insert(SkinNames, skin)
        end
    end
    
    -- =====================================================
    -- 🎮 ANIMATION SYSTEM VARIABLES
    -- =====================================================
    local CurrentSkin = "Eclipse Katana"
    local AnimationPools = {
        FishCaught = {},
        EquipIdle = {},
        RodThrow = {},
        ReelingIdle = {},
        ReelStart = {},
        ReelIntermission = {},
        StartRodCharge = {},
        LoopedRodCharge = {}
    }
    
    local EnabledAnimations = {
        FishCaught = true,
        EquipIdle = false,
        RodThrow = false,
        ReelingIdle = false,
        ReelStart = false,
        ReelIntermission = false,
        StartRodCharge = false,
        LoopedRodCharge = false
    }
    
    local IsAnimEnabled = false
    local POOL_SIZE = 3
    
    local killedTracks = {}
    local replaceCount = 0
    local currentPoolIndexes = {}
    
    local AnimConnections = {}
    
    -- Statistics
    local AnimStats = {
        totalReplacements = 0,
        successfulReplacements = 0,
        failedReplacements = 0,
        startTime = 0,
        byType = {}
    }
    
    for animType, _ in pairs(AnimationPools) do
        AnimStats.byType[animType] = {
            total = 0,
            success = 0,
            failed = 0
        }
        currentPoolIndexes[animType] = 1
    end
    
    -- =====================================================
    -- 🔍 DETECTION FUNCTIONS (ENHANCED)
    -- =====================================================
    
    local AnimationTypePatterns = {
        FishCaught = {
            names = {"fishcaught", "caught"},
            ids = {
                "117319000848286", "82259219343456", "128167068291703",
                "76325124055693", "109653945741202", "93884986836266",
                "134934781977605", "96285280763544", "126613975718573",
                "99143072029495", "107940819382815", "88993991486322",
                "119567958965696"
            }
        },
        EquipIdle = {
            names = {"equipidle", "equip"},
            ids = {
                "96586569072385", "103641983335689", "83219020397849",
                "77549515147440", "84686809448947", "103714544264522",
                "123194574699925", "81302570422307", "93958525241489",
                "79754634120924", "115119558523816", "110434285817259",
                "108792932396384", "120677591068007", "126023229958416"
            }
        },
        RodThrow = {
            names = {"rodthrow", "throw"},
            ids = {
                "92624107165273", "82600073500966", "114917462794864",
                "127872348080219", "104946400643250", "104527781253009",
                "102380394663862", "123133988645038", "84892442268560",
                "108621937425425", "105844949829012", "120554144611008",
                "124037675493192", "122784676901871", "96196869100887"
            }
        },
        ReelingIdle = {
            names = {"reelingidle", "reeling"},
            ids = {
                "134965425664034", "115229621326605", "126831815839724",
                "76325124055693", "95453600470089", "81700883907369",
                "138790747812051", "74643095451174", "110738276580375",
                "104188512165442", "110020934764602", "126645853428201"
            }
        },
        ReelStart = {
            names = {"reelstart"},
            ids = {
                "136614469321844", "137684649541594", "135819234295555",
                "80063739027478"
            }
        },
        ReelIntermission = {
            names = {"reelintermission", "intermission"},
            ids = {
                "114959536562596", "139621583239992", "86376110148779",
                "92036914464034"
            }
        },
        StartRodCharge = {
            names = {"startrodcharge", "startcharge"},
            ids = {
                "139622307103608", "84873660213983", "117668204114399",
                "72745361965091", "92063415632933", "134431618143422",
                "112104009500915", "77131632555646", "106390588424443"
            }
        },
        LoopedRodCharge = {
            names = {"loopedrodcharge", "loopedcharge"},
            ids = {
                "137429009359442", "88768375910397", "98710992523201",
                "128538861163297", "124036821497471", "76049869128172"
            }
        }
    }
    
    local function DetectAnimationType(track)
        if not track or not track.Animation then return nil end
        
        local trackName = string.lower(track.Name or "")
        local animName = string.lower(track.Animation.Name or "")
        local animId = track.Animation.AnimationId or ""
        
        -- Skip custom animations
        if string.find(trackName, "custom_") or string.find(trackName, "skin_pool") then
            return nil
        end
        
        -- Check each animation type
        for animType, patterns in pairs(AnimationTypePatterns) do
            -- Name-based detection
            for _, pattern in ipairs(patterns.names) do
                if string.find(trackName, pattern) or string.find(animName, pattern) then
                    return animType
                end
            end
            
            -- ID-based detection
            for _, id in ipairs(patterns.ids) do
                if string.find(animId, id) then
                    return animType
                end
            end
        end
        
        return nil
    end
    
    local function IsCustomAnimation(track)
        if not track then return false end
        local trackName = string.lower(track.Name or "")
        return string.find(trackName, "custom_") or string.find(trackName, "skin_pool")
    end
    
    -- =====================================================
    -- 🎯 ANIMATION POOL MANAGEMENT
    -- =====================================================
    
    local function GetNextTrack(animType)
        local pool = AnimationPools[animType]
        if not pool or #pool == 0 then return nil end
        
        -- Try to find non-playing track
        for i = 1, #pool do
            local track = pool[i]
            if track and not track.IsPlaying then
                return track
        end
        
        -- Round-robin if all playing
        currentPoolIndexes[animType] = currentPoolIndexes[animType] % #pool + 1
        return pool[currentPoolIndexes[animType]]
    end
    
    local function LoadAnimationPool(skinId, animType)
        local animData = AnimationDatabase[skinId]
        if not animData or not animData[animType] then
            warn("⚠️ Animation not found for:", skinId, animType)
            return false
        end
        
        local animId = animData[animType]
        local pool = AnimationPools[animType]
        
        -- Cleanup old pool
        for _, track in ipairs(pool) do
            pcall(function()
                if track.IsPlaying then
                    track:Stop(0)
                end
                track:Destroy()
            end)
        end
        
        -- Clear pool
        AnimationPools[animType] = {}
        pool = AnimationPools[animType]
        
        -- Create animation object
        local anim = Instance.new("Animation")
        anim.AnimationId = animId
        anim.Name = "CUSTOM_" .. animType:upper() .. "_ANIM"
        
        -- Load pool
        for i = 1, POOL_SIZE do
            local success, track = pcall(function()
                return Animator:LoadAnimation(anim)
            end)
            
            if success and track then
                track.Priority = Enum.AnimationPriority.Action4
                track.Looped = (animType == "EquipIdle" or animType == "ReelingIdle" or animType == "LoopedRodCharge")
                track.Name = "SKIN_POOL_" .. animType:upper() .. "_" .. i
                
                -- Pre-load animation
                task.spawn(function()
                    pcall(function()
                        track:Play(0, 1, 0)
                        task.wait(0.05)
                        track:Stop(0)
                    end)
                end)
                
                table.insert(pool, track)
            else
                warn("⚠️ Failed to load animation track", animType, i)
            end
        end
        
        currentPoolIndexes[animType] = 1
        
        if #pool > 0 then
            print("✅ Loaded", animType, "pool for:", skinId, "(" .. #pool .. " tracks)")
            return true
        else
            warn("❌ Failed to load any", animType, "tracks for:", skinId)
            return false
        end
    end
    
    local function LoadAllAnimationPools(skinId)
        local successCount = 0
        local totalCount = 0
        
        for animType, enabled in pairs(EnabledAnimations) do
            if enabled then
                totalCount = totalCount + 1
                if LoadAnimationPool(skinId, animType) then
                    successCount = successCount + 1
                end
            end
        end
        
        return successCount, totalCount
    end
    
    -- =====================================================
    -- ⚡ INSTANT REPLACE SYSTEM (ENHANCED)
    -- =====================================================
    
    local function InstantReplace(originalTrack, animType)
        local nextTrack = GetNextTrack(animType)
        if not nextTrack then
            AnimStats.byType[animType].failed = AnimStats.byType[animType].failed + 1
            AnimStats.failedReplacements = AnimStats.failedReplacements + 1
            return
        end
        
        replaceCount = replaceCount + 1
        AnimStats.totalReplacements = AnimStats.totalReplacements + 1
        AnimStats.byType[animType].total = AnimStats.byType[animType].total + 1
        killedTracks[originalTrack] = tick()
        
        -- Kill original animation (aggressive)
        task.spawn(function()
            for i = 1, 15 do
                pcall(function()
                    if originalTrack.IsPlaying then
                        originalTrack:Stop(0)
                        originalTrack:AdjustSpeed(0)
                        originalTrack.TimePosition = 0
                    end
                end)
                task.wait()
            end
        end)
        
        -- Play custom animation
        local success = pcall(function()
            if nextTrack.IsPlaying then
                nextTrack:Stop(0)
            end
            
            if animType == "EquipIdle" or animType == "ReelingIdle" or animType == "LoopedRodCharge" then
                nextTrack.Looped = true
            else
                nextTrack.Looped = false
            end
            
            nextTrack:Play(0, 1, 1)
            nextTrack:AdjustSpeed(1)
        end)
        
        if success then
            AnimStats.successfulReplacements = AnimStats.successfulReplacements + 1
            AnimStats.byType[animType].success = AnimStats.byType[animType].success + 1
        else
            AnimStats.failedReplacements = AnimStats.failedReplacements + 1
            AnimStats.byType[animType].failed = AnimStats.byType[animType].failed + 1
        end
        
        -- Cleanup killed track reference
        task.delay(1.5, function()
            killedTracks[originalTrack] = nil
        end)
    end
    
    -- =====================================================
    -- 📡 MONITORING SYSTEM (MULTI-LAYER)
    -- =====================================================
    
    local function StartMonitoring()
        -- Disconnect existing connections
        for _, connection in pairs(AnimConnections) do
            if connection then connection:Disconnect() end
        end
        AnimConnections = {}
        
        -- Layer 1: AnimationPlayed Hook (Primary)
        AnimConnections.AnimationPlayed = humanoid.AnimationPlayed:Connect(function(track)
            if not IsAnimEnabled then return end
            
            local animType = DetectAnimationType(track)
            if animType and EnabledAnimations[animType] and not IsCustomAnimation(track) then
                task.spawn(function()
                    InstantReplace(track, animType)
                end)
            end
        end)
        
        -- Layer 2: RenderStepped Monitor (Backup)
        AnimConnections.RenderStepped = RunService.RenderStepped:Connect(function()
            if not IsAnimEnabled then return end
            
            local tracks = humanoid:GetPlayingAnimationTracks()
            
            for _, track in ipairs(tracks) do
                if not IsCustomAnimation(track) then
                    -- Check if it's a killed track
                    if killedTracks[track] then
                        if track.IsPlaying then
                            pcall(function()
                                track:Stop(0)
                                track:AdjustSpeed(0)
                            end)
                        end
                    else
                        -- Check if it's a detectable animation
                        local animType = DetectAnimationType(track)
                        if animType and EnabledAnimations[animType] and track.IsPlaying then
                            task.spawn(function()
                                InstantReplace(track, animType)
                            end)
                        end
                    end
                end
            end
        end)
        
        -- Layer 3: Heartbeat Monitor (Extra safety)
        AnimConnections.Heartbeat = RunService.Heartbeat:Connect(function()
            if not IsAnimEnabled then return end
            
            -- Ensure enabled custom animations are working
            for animType, enabled in pairs(EnabledAnimations) do
                if enabled then
                    local pool = AnimationPools[animType]
                    local hasCustomPlaying = false
                    
                    for _, track in ipairs(pool) do
                        if track and track.IsPlaying then
                            hasCustomPlaying = true
                            break
                        end
                    end
                    
                    -- If no custom playing but original should be, force replace
                    if not hasCustomPlaying then
                        local tracks = humanoid:GetPlayingAnimationTracks()
                        for _, track in ipairs(tracks) do
                            local detectedType = DetectAnimationType(track)
                            if detectedType == animType and not IsCustomAnimation(track) then
                                task.spawn(function()
                                    InstantReplace(track, animType)
                                end)
                                break
                            end
                        end
                    end
                end
            end
        end)
        
        print("✅ Animation monitoring started (3 layers active)")
    end
    
    local function StopMonitoring()
        for _, connection in pairs(AnimConnections) do
            if connection then connection:Disconnect() end
        end
        AnimConnections = {}
        
        print("⏹️ Animation monitoring stopped")
    end
    
    -- =====================================================
    -- 🔄 RESPAWN HANDLER
    -- =====================================================
    
    player.CharacterAdded:Connect(function(newChar)
        task.wait(1.5)
        char = newChar
        humanoid = char:WaitForChild("Humanoid")
        Animator = humanoid:FindFirstChildOfClass("Animator")
        if not Animator then
            Animator = Instance.new("Animator", humanoid)
        end
        
        killedTracks = {}
        
        if IsAnimEnabled and CurrentSkin then
            task.wait(0.5)
            local success, total = LoadAllAnimationPools(CurrentSkin)
            if success > 0 then
                StartMonitoring()
                Nexus:Notify({
                    Title = "Animation Restored",
                    Content = string.format("✅ %d/%d animations loaded\nSkin: %s", success, total, CurrentSkin),
                    Type = "Success"
                })
            end
        end
    end)
    
    -- =====================================================
    -- 🎨 UI ELEMENTS (NEXUS COMPATIBLE)
    -- =====================================================
    
    -- Skin Selection Dropdown
    AnimCollapsible:Dropdown({
        Text = "Select Skin Animation",
        Options = SkinNames,
        Default = "Eclipse Katana",
        Flag = "SkinAnimation_Select",
        Callback = function(selected)
            -- Skip category headers
            if string.find(selected, "━━━") then
                return
            end
            
            CurrentSkin = selected
            
            if IsAnimEnabled then
                local success, total = LoadAllAnimationPools(selected)
                if success > 0 then
                    Nexus:Notify({
                        Title = "Animation Changed",
                        Content = string.format("🎨 %s\n✅ %d/%d animations loaded", selected, success, total),
                        Type = "Success"
                    })
                else
                    Nexus:Notify({
                        Title = "Error",
                        Content = "Failed to load: " .. selected,
                        Type = "Error"
                    })
                end
            end
        end
    })
    
    -- Enable/Disable Toggle
    AnimCollapsible:Toggle({
        Text = "Enable Animation Changer",
        Default = false,
        Flag = "EnableAnimationChanger",
        Callback = function(state)
            IsAnimEnabled = state
            
            if IsAnimEnabled then
                if not CurrentSkin then
                    Nexus:Notify({
                        Title = "Error",
                        Content = "Select a skin first!",
                        Type = "Error"
                    })
                    IsAnimEnabled = false
                    return
                end
                
                AnimStats.startTime = tick()
                AnimStats.totalReplacements = 0
                AnimStats.successfulReplacements = 0
                AnimStats.failedReplacements = 0
                for animType, _ in pairs(AnimStats.byType) do
                    AnimStats.byType[animType] = {total = 0, success = 0, failed = 0}
                end
                
                local success, total = LoadAllAnimationPools(CurrentSkin)
                if success > 0 then
                    StartMonitoring()
                    Nexus:Notify({
                        Title = "Animation Changer",
                        Content = string.format("✅ Enabled - %s\n🎯 %d/%d animations active", CurrentSkin, success, total),
                        Type = "Success"
                    })
                else
                    IsAnimEnabled = false
                    Nexus:Notify({
                        Title = "Error",
                        Content = "Failed to load animations",
                        Type = "Error"
                    })
                end
            else
                StopMonitoring()
                killedTracks = {}
                
                -- Stop all custom animations
                for animType, pool in pairs(AnimationPools) do
                    for _, track in ipairs(pool) do
                        pcall(function()
                            if track.IsPlaying then
                                track:Stop(0)
                            end
                        end)
                    end
                end
                
                Nexus:Notify({
                    Title = "Animation Changer",
                    Content = "⏹️ Disabled",
                    Type = "Warning"
                })
            end
        end
    })
    
    -- Animation Type Toggles Section
    local animTypeSection = AnimCollapsible:Collapsible("🎭 Animation Types")
    
    local animTypeDescriptions = {
        FishCaught = "🐟 Fish Caught (Main animation when catching fish)",
        EquipIdle = "⚔️ Equip Idle (Holding rod animation)",
        RodThrow = "🎣 Rod Throw (Casting animation)",
        ReelingIdle = "🔄 Reeling Idle (While reeling animation)",
        ReelStart = "▶️ Reel Start (Start reeling animation)",
        ReelIntermission = "⏸️ Reel Intermission (Between reeling)",
        StartRodCharge = "⚡ Start Rod Charge (Begin charging)",
        LoopedRodCharge = "🔁 Looped Rod Charge (Charging loop)"
    }
    
    for animType, description in pairs(animTypeDescriptions) do
        animTypeSection:Toggle({
            Text = description,
            Default = EnabledAnimations[animType],
            Flag = "Enable_" .. animType,
            Callback = function(state)
                EnabledAnimations[animType] = state
                
                if IsAnimEnabled then
                    if state then
                        -- Load this animation type
                        if LoadAnimationPool(CurrentSkin, animType) then
                            Nexus:Notify({
                                Title = "Animation Type",
                                Content = "✅ Enabled: " .. animType,
                                Type = "Success"
                            })
                        end
                    else
                        -- Stop this animation type
                        local pool = AnimationPools[animType]
                        for _, track in ipairs(pool) do
                            pcall(function()
                                if track.IsPlaying then
                                    track:Stop(0)
                                end
                            end)
                        end
                        Nexus:Notify({
                            Title = "Animation Type",
                            Content = "❌ Disabled: " .. animType,
                            Type = "Warning"
                        })
                    end
                end
            end
        })
    end
    
    -- Advanced Settings Section
    local advancedSettings = AnimCollapsible:Collapsible("⚙️ Advanced Settings")
    
    advancedSettings:Slider({
        Text = "Animation Pool Size",
        Min = 1,
        Max = 5,
        Default = 3,
        Flag = "AnimPoolSize",
        Callback = function(value)
            POOL_SIZE = math.floor(value)
            
            if IsAnimEnabled then
                Nexus:Notify({
                    Title = "Pool Size",
                    Content = "Restart animation changer to apply",
                    Type = "Info"
                })
            end
        end
    })
    
    advancedSettings:Button({
        Text = "🔄 Reload All Animations",
        Callback = function()
            if not IsAnimEnabled then
                Nexus:Notify({
                    Title = "Error",
                    Content = "Enable animation changer first!",
                    Type = "Error"
                })
                return
            end
            
            local success, total = LoadAllAnimationPools(CurrentSkin)
            if success > 0 then
                Nexus:Notify({
                    Title = "Reload",
                    Content = string.format("✅ %d/%d animations reloaded!", success, total),
                    Type = "Success"
                })
            else
                Nexus:Notify({
                    Title = "Error",
                    Content = "Failed to reload animations",
                    Type = "Error"
                })
            end
        end
    })
    
    advancedSettings:Button({
        Text = "📊 Detailed Statistics",
        Callback = function()
            if AnimStats.startTime == 0 then
                Nexus:Notify({
                    Title = "Statistics",
                    Content = "No data yet - enable animation changer first!",
                    Type = "Info"
                })
                return
            end
            
            local runtime = tick() - AnimStats.startTime
            local successRate = 0
            if AnimStats.totalReplacements > 0 then
                successRate = (AnimStats.successfulReplacements / AnimStats.totalReplacements) * 100
            end
            
            print("╔══════════════════════════════════════════╗")
            print("║            ANIMATION STATISTICS           ║")
            print("╠══════════════════════════════════════════╣")
            print(string.format("║ Current Skin: %-26s ║", CurrentSkin))
            print(string.format("║ Runtime: %d seconds                      ║", math.floor(runtime)))
            print(string.format("║ Total Replacements: %-19d ║", AnimStats.totalReplacements))
            print(string.format("║ Success Rate: %.1f%%                     ║", successRate))
            print("╠══════════════════════════════════════════╣")
            print("║              BY ANIMATION TYPE            ║")
            print("╠══════════════════════════════════════════╣")
            
            for animType, stats in pairs(AnimStats.byType) do
                if stats.total > 0 then
                    local typeRate = (stats.success / stats.total) * 100
                    print(string.format("║ %-15s: %3d (%.1f%%) ║", animType, stats.total, typeRate))
                end
            end
            
            print("╚══════════════════════════════════════════╝")
            
            Nexus:Notify({
                Title = "Statistics",
                Content = string.format(
                    "📊 %d total replacements\n" ..
                    "✅ %.1f%% success rate\n" ..
                    "⏱️ %ds runtime\n" ..
                    "📝 Check console (F9) for details",
                    AnimStats.totalReplacements,
                    successRate,
                    math.floor(runtime)
                ),
                Type = "Info",
                Duration = 8
            })
        end
    })
    
    advancedSettings:Button({
        Text = "🔍 Debug: Animation Detection",
        Callback = function()
            local tracks = humanoid:GetPlayingAnimationTracks()
            
            if #tracks == 0 then
                Nexus:Notify({
                    Title = "Debug",
                    Content = "No animations currently playing",
                    Type = "Info"
                })
                return
            end
            
            print("═══════════════════════════════════════")
            print("         ANIMATION DETECTION DEBUG")
            print("═══════════════════════════════════════")
            
            for i, track in ipairs(tracks) do
                local animType = DetectAnimationType(track)
                local isCustom = IsCustomAnimation(track)
                
                print(string.format(
                    "[%d] Name: %s\n" ..
                    "    ID: %s\n" ..
                    "    Type: %s\n" ..
                    "    Custom: %s\n" ..
                    "    Playing: %s\n" ..
                    "    Enabled: %s",
                    i,
                    track.Name or "Unknown",
                    track.Animation.AnimationId or "Unknown",
                    animType or "Not Detected",
                    tostring(isCustom),
                    tostring(track.IsPlaying),
                    animType and tostring(EnabledAnimations[animType]) or "N/A"
                ))
                print("───────────────────────────────────────")
            end
            
            Nexus:Notify({
                Title = "Debug",
                Content = string.format("%d animations analyzed (F9 for details)", #tracks),
                Type = "Info"
            })
        end
    })
    
    advancedSettings:Button({
        Text = "🧹 Emergency Stop All",
        Callback = function()
            local tracks = humanoid:GetPlayingAnimationTracks()
            local stopped = 0
            
            for _, track in ipairs(tracks) do
                pcall(function()
                    track:Stop(0)
                    stopped = stopped + 1
                end)
            end
            
            -- Also clear all pools
            for animType, pool in pairs(AnimationPools) do
                for _, track in ipairs(pool) do
                    pcall(function()
                        track:Destroy()
                    end)
                end
                AnimationPools[animType] = {}
            end
            
            killedTracks = {}
            
            Nexus:Notify({
                Title = "Emergency Stop",
                Content = string.format("🛑 Stopped %d animations\n🧹 Cleared all pools", stopped),
                Type = "Warning"
            })
        end
    })
    
    -- Quick Presets Section
    local quickPresets = AnimCollapsible:Collapsible("⚡ Quick Presets")
    
    local presets = {
        ["🎣 Fishing Only"] = {
            FishCaught = true,
            EquipIdle = false,
            RodThrow = false,
            ReelingIdle = false,
            ReelStart = false,
            ReelIntermission = false,
            StartRodCharge = false,
            LoopedRodCharge = false
        },
        ["⚔️ Combat Style"] = {
            FishCaught = true,
            EquipIdle = true,
            RodThrow = true,
            ReelingIdle = false,
            ReelStart = false,
            ReelIntermission = false,
            StartRodCharge = false,
            LoopedRodCharge = false
        },
        ["🎭 Full Experience"] = {
            FishCaught = true,
            EquipIdle = true,
            RodThrow = true,
            ReelingIdle = true,
            ReelStart = true,
            ReelIntermission = true,
            StartRodCharge = true,
            LoopedRodCharge = true
        },
        ["⚡ Charge Focus"] = {
            FishCaught = true,
            EquipIdle = false,
            RodThrow = false,
            ReelingIdle = false,
            ReelStart = false,
            ReelIntermission = false,
            StartRodCharge = true,
            LoopedRodCharge = true
        }
    }
    
    for presetName, presetConfig in pairs(presets) do
        quickPresets:Button({
            Text = presetName,
            Callback = function()
                -- Apply preset
                for animType, enabled in pairs(presetConfig) do
                    EnabledAnimations[animType] = enabled
                end
                
                -- Reload if enabled
                if IsAnimEnabled then
                    local success, total = LoadAllAnimationPools(CurrentSkin)
                    Nexus:Notify({
                        Title = "Preset Applied",
                        Content = string.format("%s\n✅ %d/%d animations loaded", presetName, success, total),
                        Type = "Success"
                    })
                else
                    Nexus:Notify({
                        Title = "Preset Applied",
                        Content = presetName .. "\n💡 Enable animation changer to apply",
                        Type = "Info"
                    })
                end
            end
        })
    end
    
    -- Quick Actions Section (Popular Skins)
    local quickActions = AnimCollapsible:Collapsible("🌟 Popular Skins")
    
    local popularSkins = {
        {"Eclipse Katana", "⚔️"},
        {"Holy Trident", "🔱"},
        {"Soul Scythe", "💀"},
        {"Princess Parasol", "🌸"},
        {"Ban Hammer", "🔨"},
        {"Eternal Flower", "🌺"}
    }
    
    for _, skinData in ipairs(popularSkins) do
        local skinName, emoji = skinData[1], skinData[2]
        quickActions:Button({
            Text = emoji .. " " .. skinName,
            Callback = function()
                CurrentSkin = skinName
                
                if IsAnimEnabled then
                    local success, total = LoadAllAnimationPools(skinName)
                    if success > 0 then
                        Nexus:Notify({
                            Title = "Quick Switch",
                            Content = string.format("%s %s\n✅ %d/%d animations loaded", emoji, skinName, success, total),
                            Type = "Success"
                        })
                    end
                else
                    Nexus:Notify({
                        Title = "Skin Selected",
                        Content = emoji .. " " .. skinName .. "\n💡 Enable animation changer to apply",
                        Type = "Info"
                    })
                end
            end
        })
    end
    
    -- =====================================================
    -- 🎉 INITIALIZATION MESSAGE
    -- =====================================================
    
    local totalSkins = 0
    for _, _ in pairs(AnimationDatabase) do
        totalSkins = totalSkins + 1
    end
    
    Nexus:Notify({
        Title = "Ultimate Animation Changer",
        Content = string.format("✅ Loaded %d skins with 8 animation types!\n🎯 All fishing animations supported", totalSkins),
        Type = "Success",
        Duration = 5
    })
    
    print("╔═══════════════════════════════════════════════╗")
    print("║     🎨 ULTIMATE ANIMATION CHANGER LOADED      ║")
    print("╠═══════════════════════════════════════════════╣")
    print(string.format("║  ✅ %d Skins Available                        ║", totalSkins))
    print("║  ✅ 8 Animation Types Supported               ║")
    print("║  ✅ Multi-Layer Detection System              ║")
    print("║  ✅ Advanced Statistics & Debug Tools         ║")
    print("║  ✅ Quick Presets & Popular Skins            ║")
    print("╚═══════════════════════════════════════════════╝")
end


    -- =========================================================
    -- FISHING SUPPORT (TOOLS)
    -- =========================================================
    do
        local fishingSupport = farm:Collapsible("Fishing Support (Tools)")
        
        -- Helper Variables
        local RunService = game:GetService("RunService")
        local Players = game:GetService("Players")
        local LocalPlayer = Players.LocalPlayer
        
        -- 1. REMOVE FISH NOTIFICATION POP-UP
        local DisableNotificationConnection = nil
        fishingSupport:Toggle({
            Text = "Remove Fish Notification Pop-up",
            Default = false,
            Flag = "RemoveFishNotifications",
            Callback = function(state)
                local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
                local SmallNotification = PlayerGui:FindFirstChild("Small Notification")
                
                -- Coba tunggu sebentar jika belum ada
                if not SmallNotification then
                    SmallNotification = PlayerGui:WaitForChild("Small Notification", 5)
                end
                
                if not SmallNotification then return end

                if state then
                    -- ON: Gunakan RenderStepped agar notifikasi mati setiap frame
                    if DisableNotificationConnection then DisableNotificationConnection:Disconnect() end
                    
                    DisableNotificationConnection = RunService.RenderStepped:Connect(function()
                        if SmallNotification then
                            SmallNotification.Enabled = false
                        end
                    end)
                    Nexus:Notify({Title = "Notification", Content = "Pop-up Blocked"})
                else
                    -- OFF: Matikan loop dan nyalakan kembali GUI
                    if DisableNotificationConnection then
                        DisableNotificationConnection:Disconnect()
                        DisableNotificationConnection = nil
                    end
                    if SmallNotification then
                        SmallNotification.Enabled = true
                    end
                    Nexus:Notify({Title = "Notification", Content = "Pop-up Restored"})
                end
            end
        })

        -- 2. WALK ON WATER
        local walkOnWaterConnection = nil
        local isWalkOnWater = false
        local waterPlatform = nil
        
        fishingSupport:Toggle({
            Text = "Walk on Water",
            Default = false,
            Flag = "WalkOnWater",
            Callback = function(state)
                isWalkOnWater = state

                if state then
                    -- Buat Platform Awal
                    if not waterPlatform then
                        waterPlatform = Instance.new("Part")
                        waterPlatform.Name = "WaterPlatform"
                        waterPlatform.Anchored = true
                        waterPlatform.CanCollide = true
                        waterPlatform.Transparency = 1 
                        waterPlatform.Size = Vector3.new(20, 1, 20)
                        waterPlatform.Parent = workspace
                    end

                    if walkOnWaterConnection then walkOnWaterConnection:Disconnect() end

                    walkOnWaterConnection = RunService.RenderStepped:Connect(function()
                        local character = LocalPlayer.Character
                        if not isWalkOnWater or not character then return end
                        
                        local hrp = character:FindFirstChild("HumanoidRootPart")
                        if not hrp then return end

                        -- Re-create jika terhapus
                        if not waterPlatform or not waterPlatform.Parent then
                            waterPlatform = Instance.new("Part")
                            waterPlatform.Name = "WaterPlatform"
                            waterPlatform.Anchored = true
                            waterPlatform.CanCollide = true
                            waterPlatform.Transparency = 1 
                            waterPlatform.Size = Vector3.new(20, 1, 20)
                            waterPlatform.Parent = workspace
                        end

                        -- Raycast cari air
                        local rayParams = RaycastParams.new()
                        rayParams.FilterDescendantsInstances = {workspace.Terrain} 
                        rayParams.FilterType = Enum.RaycastFilterType.Include
                        rayParams.IgnoreWater = false 

                        local rayOrigin = hrp.Position + Vector3.new(0, 5, 0) 
                        local rayDirection = Vector3.new(0, -500, 0)
                        local result = workspace:Raycast(rayOrigin, rayDirection, rayParams)

                        if result and result.Material == Enum.Material.Water then
                            local waterSurfaceHeight = result.Position.Y
                            waterPlatform.Position = Vector3.new(hrp.Position.X, waterSurfaceHeight, hrp.Position.Z)
                            
                            -- Fitur lompat otomatis jika tenggelam
                            if hrp.Position.Y < (waterSurfaceHeight + 2) and hrp.Position.Y > (waterSurfaceHeight - 5) then
                                 if not game:GetService("UserInputService"):IsKeyDown(Enum.KeyCode.Space) then
                                    hrp.CFrame = CFrame.new(hrp.Position.X, waterSurfaceHeight + 3.5, hrp.Position.Z)
                                end
                            end
                        else
                            -- Sembunyikan platform jika di darat
                            waterPlatform.Position = Vector3.new(hrp.Position.X, -500, hrp.Position.Z)
                        end
                    end)
                    --Nexus:Notify({Title = "Walk on Water", Content = "Enabled"})
                else
                    -- Cleanup
                    if walkOnWaterConnection then walkOnWaterConnection:Disconnect() walkOnWaterConnection = nil end
                    if waterPlatform then waterPlatform:Destroy() waterPlatform = nil end
                    --Nexus:Notify({Title = "Walk on Water", Content = "Disabled"})
                end
            end
        })

        -- 3. ENABLE FISHING RADAR
        -- Pastikan variabel GetRemote dan RPath sudah ada di global scope script Anda
        fishingSupport:Toggle({
            Text = "Enable Fishing Radar",
            Default = false,
            Flag = "fishingRadar",
            Callback = function(state)
                local RF_UpdateFishingRadar = Remotes.UpdateFishingRadar -- Menggunakan table Remotes yang sudah ada
                if not RF_UpdateFishingRadar then
                    -- Fallback cari manual jika tidak ada di table Remotes
                    RF_UpdateFishingRadar = GetRemote(RPath, "RF/UpdateFishingRadar")
                end
                
                if RF_UpdateFishingRadar then
                    pcall(function() RF_UpdateFishingRadar:InvokeServer(state) end)
                    Nexus:Notify({Title = "Radar", Content = state and "ON" or "OFF"})
                end
            end
        })

        -- =========================================================
        -- 4. REMOVE EFFECTS (VFX & FPS BOOST)
        -- =========================================================
        
        -- [A] SETUP VARIABLES & MODULES
        local VFXControllerModule = nil
        local originalVFXHandle = nil
        local DelEffectsActive = false
        local CharEffectActive = false
        local DummyConnections = {} -- Untuk menyimpan koneksi dummy

        -- Load Modules Game
        pcall(function()
            VFXControllerModule = require(game:GetService("ReplicatedStorage"):WaitForChild("Controllers").VFXController)
            if VFXControllerModule then
                originalVFXHandle = VFXControllerModule.Handle
            end
        end)

        -- Load Remotes (Untuk fitur Event Disabler)
        local RE_PlayFishingEffect = GetRemote(RPath, "RE/PlayFishingEffect")
        local RE_ReplicateTextEffect = GetRemote(RPath, "RE/ReplicateTextEffect")

        -- [B] UI IMPLEMENTATION
        local vfxSection = fishingSupport:Collapsible("VFX & FPS Boost")

        -- 1. REMOVE SKIN EFFECT (Metode Hook Controller - Kode Lama)
        vfxSection:Toggle({
            Text = "Remove Skin Effect (Safe)",
            Default = false,
            Flag = "RemoveskinEffect",
            Callback = function(state)
                if not VFXControllerModule then return end
                
                if state then
                    -- Blokir fungsi rendering visual
                    VFXControllerModule.Handle = function(...) end
                    VFXControllerModule.RenderAtPoint = function(...) end
                    VFXControllerModule.RenderInstance = function(...) end
                    
                    -- Bersihkan folder kosmetik sekali jalan
                    local cosmeticFolder = workspace:FindFirstChild("CosmeticFolder")
                    if cosmeticFolder then pcall(function() cosmeticFolder:ClearAllChildren() end) end
                else
                    -- Restore fungsi asli
                    if originalVFXHandle then
                        VFXControllerModule.Handle = originalVFXHandle
                    end
                end
            end
        })

        -- 2. DISABLE CHAR EFFECT (Metode Disconnect Event - Kode Baru)
        vfxSection:Toggle({
            Text = "Disable Char/Text Effect (Aggressive)",
            Default = false,
            Callback = function(state)
                CharEffectActive = state
                
                -- Cek support executor
                if not getconnections then 
                    Nexus:Notify({Title="Error", Content="Executor tidak support 'getconnections'", Type="Error"}) 
                    return 
                end

                local Events = {RE_PlayFishingEffect, RE_ReplicateTextEffect}

                if state then
                    -- [LOGIC MATIKAN EFEK]
                    DummyConnections = {} -- Reset simpanan
                    
                    for _, event in ipairs(Events) do
                        if event then
                            -- 1. Matikan koneksi asli game (Disable)
                            for _, conn in ipairs(getconnections(event.OnClientEvent)) do
                                conn:Disable() -- Kita pakai Disable() biar bisa dinyalakan lagi (lebih aman dari Disconnect)
                            end
                            
                            -- 2. Tambahkan dummy connection (sesuai request kode, untuk mencegah error nil)
                            local dummy = event.OnClientEvent:Connect(function() end)
                            table.insert(DummyConnections, dummy)
                        end
                    end
                    Nexus:Notify({Title="FPS Boost", Content="Character & Text Effects Disabled!", Type="Success"})
                else
                    -- [LOGIC NYALAKAN KEMBALI]
                    -- 1. Hapus dummy connection kita
                    for _, conn in ipairs(DummyConnections) do
                        if conn then conn:Disconnect() end
                    end
                    DummyConnections = {}

                    -- 2. Hidupkan kembali koneksi asli game
                    for _, event in ipairs(Events) do
                        if event then
                            for _, conn in ipairs(getconnections(event.OnClientEvent)) do
                                conn:Enable()
                            end
                        end
                    end
                    Nexus:Notify({Title="FPS Boost", Content="Effects Restored.", Type="Info"})
                end
            end
        })

        -- 3. DELETE FISHING EFFECTS (Metode Loop Destroy - Kode Baru)
        vfxSection:Toggle({
            Text = "Delete Rod Effects (Loop)",
            Default = false,
            Callback = function(state)
                DelEffectsActive = state
                
                if state then
                    task.spawn(function()
                        while DelEffectsActive do
                            local folder = workspace:FindFirstChild("CosmeticFolder")
                            if folder then
                                folder:Destroy() -- Hapus folder efek
                            end
                            -- Saya percepat dari 60s ke 5s agar efeknya terasa instan
                            task.wait(5) 
                        end
                    end)
                    Nexus:Notify({Title="Cleaner", Content="Auto Delete Cosmetic Active", Type="Success"})
                end
            end
        })

        -- =========================================================
        -- 5. NO CUTSCENE (ULTIMATE: UI RESTORE + SERVER BYPASS)
        -- =========================================================
        local CutsceneController = nil
        local GuiControl = nil
        local OldPlayCutscene = nil
        local isNoCutsceneActive = false
        
        local ProximityPromptService = game:GetService("ProximityPromptService")
        local LocalPlayer = game:GetService("Players").LocalPlayer
        
        -- [NEW] Define Remotes
        -- Asumsi RPath sudah didefinisikan di atas (Packages -> _Index -> net)
        local RE_StopCutscene = GetRemote(RPath, "RE/StopCutscene")
        -- RE/ReplicateCutscene tidak perlu di-hook jika kita sudah mematikan Controllernya langsung,
        -- tapi kita definisikan saja biar lengkap sesuai request.
        local RE_ReplicateCutscene = GetRemote(RPath, "RE/ReplicateCutscene") 

        task.spawn(function()
            local ReplicatedStorage = game:GetService("ReplicatedStorage")
            
            -- 1. Load Game Modules
            pcall(function()
                CutsceneController = require(ReplicatedStorage:WaitForChild("Controllers"):WaitForChild("CutsceneController"))
                GuiControl = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("GuiControl"))
            end)

            -- 2. Hook Controller
            if CutsceneController and CutsceneController.Play then
                if not CutsceneController._OriginalPlay then
                    CutsceneController._OriginalPlay = CutsceneController.Play
                end
                OldPlayCutscene = CutsceneController._OriginalPlay

                -- Overwrite Play Function
                CutsceneController.Play = function(self, ...)
                    if isNoCutsceneActive then
                        -- [A] Skip Animasi Client (Logic Lama)
                        task.spawn(function()
                            task.wait() 
                            
                            -- Restore UI & Controls
                            if GuiControl then GuiControl:SetHUDVisibility(true) end
                            if ProximityPromptService then ProximityPromptService.Enabled = true end
                            if LocalPlayer then LocalPlayer:SetAttribute("IgnoreFOV", false) end
                        end)

                        -- [B] Beritahu Server "Cutscene Selesai" (Logic Baru)
                        -- Ini mencegah delay quest/hadiah dari server
                        if RE_StopCutscene then
                            pcall(function() RE_StopCutscene:FireServer() end)
                        end

                        return -- Stop eksekusi cutscene
                    end
                    
                    return OldPlayCutscene(self, ...)
                end
            end
        end)

        fishingSupport:Toggle({
            Text = "No Cutscene (Skip & Bypass)",
            Default = false,
            Flag = "NoCutsceneAww",
            Callback = function(state)
                isNoCutsceneActive = state
                
                if state then
                    -- Jika dinyalakan saat cutscene jalan
                    if CutsceneController then
                        pcall(function() CutsceneController:Stop() end)
                        -- Manual Restore
                        if GuiControl then GuiControl:SetHUDVisibility(true) end
                        ProximityPromptService.Enabled = true
                        
                        -- Paksa Stop ke Server juga
                        if RE_StopCutscene then pcall(function() RE_StopCutscene:FireServer() end) end
                    end
                    Nexus:Notify({Title = "Cutscene", Content = "Auto Skip + Server Bypass Active!", Type = "Success"})
                else
                    Nexus:Notify({Title = "Cutscene", Content = "Disabled", Type = "Info"})
                end
            end
        })

        -- 6. NO ANIMATION
        -- Pastikan fungsi DisableAnimations dan EnableAnimations sudah ada di script Anda (di bagian helper)
        fishingSupport:Toggle({
            Text = "No Animation",
            Default = false,
            Flag = "noanimation_flag",
            Callback = function(state)
                if state then
                    if DisableAnimations then DisableAnimations() end
                else
                    if EnableAnimations then EnableAnimations() end
                    Nexus:Notify({Title = "Animation", Content = "Restored"})
                end
            end
        })
    end

    do
        local TeleportGroup = farm:Collapsible("Teleport System")
        
        -- Helper Functions Local
        local function GetHRP()
            local c = game.Players.LocalPlayer.Character
            return c and c:FindFirstChild("HumanoidRootPart")
        end

        local function TeleportToLookAt(pos, look)
            local hrp = GetHRP()
            if hrp then
                hrp.CFrame = CFrame.new(pos, pos + look)
            end
        end

        -- =========================================================
        -- 1. TELEPORT TO FISHING AREA
        -- =========================================================
        
        local FishingAreas = {
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
            ["Kohana"] = {Pos = Vector3.new(-855.801, 18.75, 465.677), Look = Vector3.new(-0.695, 0, -0.719)},
            ["Lost Isle"] = {Pos = Vector3.new(-3804.105, 2.344, -904.653), Look = Vector3.new(-0.901, -0.000, 0.433)},
            ["Sacred Temple"] = {Pos = Vector3.new(1461.815, -22.125, -670.234), Look = Vector3.new(-0.990, -0.000, 0.143)},
            ["Second Enchant Altar"] = {Pos = Vector3.new(1479.587, 128.295, -604.224), Look = Vector3.new(-0.298, 0.000, -0.955)},
            ["Sisyphus Statue"] = {Pos = Vector3.new(-3743.745, -135.074, -1007.554), Look = Vector3.new(0.310, 0.000, 0.951)},
            ["Treasure Room"] = {Pos = Vector3.new(-3598.440, -281.274, -1645.855), Look = Vector3.new(-0.065, 0.000, -0.998)},
            ["Tropical Island"] = {Pos = Vector3.new(-2162.920, 2.825, 3638.445), Look = Vector3.new(0.381, -0.000, 0.925)},
            ["Underground Cellar"] = {Pos = Vector3.new(2118.417, -91.448, -733.800), Look = Vector3.new(0.854, 0.000, 0.521)},
            ["Volcano"] = {Pos = Vector3.new(-605.121, 19.516, 160.010), Look = Vector3.new(0.854, 0.000, 0.520)},
            ["Weather Machine"] = {Pos = Vector3.new(-1518.550, 2.875, 1916.148), Look = Vector3.new(0.042, 0.000, 0.999)},
            ["Pirate Cove"] = {Pos = Vector3.new(3413.68, 4.193, 3505.495), Look = Vector3.new(0.644, 0, -0.765)},
        }
        
        local AreaNames = {}
        for name, _ in pairs(FishingAreas) do table.insert(AreaNames, name) end
        table.sort(AreaNames) -- Urutkan abjad biar rapi
        
        local selectedArea = nil

        TeleportGroup:Dropdown({
            Text = "Choose Area", 
            Options = AreaNames, 
            Default = "Select Area",
            Flag = "select_area_teleport_flag_1",
            Callback = function(opt) Nexus.Flags.select_area_teleport_flag_1 = opt end
        })

        TeleportGroup:Button({
            Text = "Teleport to Chosen Area",
            Callback = function()
                local area = Nexus.Flags.select_area_teleport_flag_1

                if area and FishingAreas[area] then
                    local data = FishingAreas[area]
                    TeleportToLookAt(data.Pos, data.Look)
                    Nexus:Notify({
                        Title = "Teleport",
                        Content = "Arrived at " .. area,
                        Type = "Success"
                    })
                else
                    Nexus:Notify({
                        Title = "Error",
                        Content = "Select an area first!",
                        Type = "Error"
                    })
                end
            end
        })
        
        TeleportGroup:Toggle({
            Text = "Teleport & Freeze (Fix Lag)",
            Default = false,
            Flag = "teleport_freeze_flag_1",
            Callback = function(state)
                local hrp = GetHRP()
                if not hrp then return end

                local area = Nexus.Flags.select_area_teleport_flag_1
                if state then
                    if not area or not FishingAreas[area] then
                        Nexus:Notify({
                            Title = "Error",
                            Content = "Select area first!",
                            Type = "Error"
                        })
                        return
                    end

                    local data = FishingAreas[area]
                    hrp.Anchored = false
                    TeleportToLookAt(data.Pos, data.Look)

                    local t = os.clock()
                    while (os.clock() - t) < 1.5 and state do
                        hrp.Velocity = Vector3.zero
                        hrp.CFrame = CFrame.new(data.Pos, data.Pos + data.Look)
                        game:GetService("RunService").Heartbeat:Wait()
                    end

                    if state then hrp.Anchored = true end
                else
                    hrp.Anchored = false
                end
            end
        })

        local selectedTargetPlayer = nil 
        local PlayerDropdown = nil

        -- Helper: Mengambil daftar pemain
        local function GetPlayerListOptions()
            local options = {}
            for _, p in ipairs(game.Players:GetPlayers()) do
                if p ~= game.Players.LocalPlayer then
                    table.insert(options, p.Name)
                end
            end
            if #options == 0 then table.insert(options, "No Players Found") end
            return options
        end

        -- Dropdown Pemain
        PlayerDropdown = TeleportGroup:Dropdown({
            Text = "Select Target Player",
            Options = GetPlayerListOptions(),
            Default = "Select Player",
            Callback = function(name)
                selectedTargetPlayer = name
            end
        })

        -- Tombol Refresh
        TeleportGroup:Button({
            Text = "Refresh Player List",
            Callback = function()
                local newOptions = GetPlayerListOptions()
                if PlayerDropdown then
                    PlayerDropdown:SetOptions(newOptions)
                end
                selectedTargetPlayer = nil
                Nexus:Notify({ Title = "Refresh", Content = "List Updated", Type = "Success" })
            end
        })

        -- Tombol Teleport
        TeleportGroup:Button({
            Text = "Teleport to Player (One-Time)",
            Callback = function()
                if not selectedTargetPlayer or selectedTargetPlayer == "No Players Found" then
                    Nexus:Notify({ Title = "Error", Content = "Select a valid player!", Type = "Error" })
                    return
                end

                local targetPlayer = game.Players:FindFirstChild(selectedTargetPlayer)
                local targetHRP = targetPlayer and targetPlayer.Character and targetPlayer.Character:FindFirstChild("HumanoidRootPart")
                local myHRP = GetHRP()

                if myHRP and targetHRP then
                    -- Teleport 5 stud di atas kepala
                    local targetPos = targetHRP.Position + Vector3.new(0, 5, 0)
                    local lookVector = (targetHRP.Position - myHRP.Position).Unit 
                    
                    myHRP.CFrame = CFrame.new(targetPos, targetPos + lookVector)
                    
                    Nexus:Notify({ Title = "Teleport", Content = "Teleported to " .. selectedTargetPlayer, Type = "Success" })
                else
                    Nexus:Notify({ Title = "Error", Content = "Target/Character not found", Type = "Error" })
                end
            end
        })
    end

    -- =========================================================
    -- SMART EVENT (MULTI PROPS)
    -- =========================================================
    do
        local televent = farm:Collapsible("Smart Event (Multi Props)")

        -- =========================================================
        -- FISHING AREAS
        -- =========================================================
        local FishingAreass = {
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
            ["Kohana"] = {Pos = Vector3.new(-855.801, 18.75, 465.677), Look = Vector3.new(-0.695, 0, -0.719)},
            ["Lost Isle"] = {Pos = Vector3.new(-3804.105, 2.344, -904.653), Look = Vector3.new(-0.901, -0.000, 0.433)},
            ["Sacred Temple"] = {Pos = Vector3.new(1461.815, -22.125, -670.234), Look = Vector3.new(-0.990, -0.000, 0.143)},
            ["Second Enchant Altar"] = {Pos = Vector3.new(1479.587, 128.295, -604.224), Look = Vector3.new(-0.298, 0.000, -0.955)},
            ["Sisyphus Statue"] = {Pos = Vector3.new(-3743.745, -135.074, -1007.554), Look = Vector3.new(0.310, 0.000, 0.951)},
            ["Treasure Room"] = {Pos = Vector3.new(-3598.440, -281.274, -1645.855), Look = Vector3.new(-0.065, 0.000, -0.998)},
            ["Tropical Island"] = {Pos = Vector3.new(-2162.920, 2.825, 3638.445), Look = Vector3.new(0.381, -0.000, 0.925)},
            ["Underground Cellar"] = {Pos = Vector3.new(2118.417, -91.448, -733.800), Look = Vector3.new(0.854, 0.000, 0.521)},
            ["Volcano"] = {Pos = Vector3.new(-605.121, 19.516, 160.010), Look = Vector3.new(0.854, 0.000, 0.520)},
            ["Weather Machine"] = {Pos = Vector3.new(-1518.550, 2.875, 1916.148), Look = Vector3.new(0.042, 0.000, 0.999)},
            ["Pirate Cove"] = {Pos = Vector3.new(3413.68, 4.193, 3505.495), Look = Vector3.new(0.644, 0, -0.765)},
        }
        
        local AreaNamess = {}
        for name, _ in pairs(FishingAreass) do table.insert(AreaNamess, name) end
        table.sort(AreaNamess)

        -- Pastikan eventsList ada
        local eventsList = eventsList or {
            "Shark Hunt", "Megalodon Hunt", "Worm Hunt", "Ghost Shark Hunt", "Treasure Event", "Black Hole"
        }

        -- =========================================================
        -- VARIABLES
        -- =========================================================
        local SelectedPriorityEvent = nil
        local SelectedNormalEvents = {}
        local Loch_Return_SelectedArea = nil 
        local SmartEventState = false
        local SmartEventThread = nil

        -- =========================================================
        -- EVENT SEARCH PATTERNS
        -- =========================================================
        local EventSearchPatterns = {
            ["Shark Hunt"] = {"Shark Hunt"},
            ["Megalodon Hunt"] = {"Megalodon Hunt"}, 
            ["Worm Hunt"] = {"BlackHole", "Model"}, 
            ["Ghost Shark Hunt"] = {"Ghost Shark Hunt", "Ghost"},
            ["Treasure Event"] = {"Treasure Event"},
            ["Black Hole"] = {"Black Hole"}
        }

        local function IsEventAlive(obj)
            if not obj then return false end
            local success = pcall(function()
                return obj.Parent ~= nil and obj:IsDescendantOf(workspace)
            end)
            return success
        end

        local function SearchInAllProps(eventName)
            local patterns = EventSearchPatterns[eventName]
            if not patterns then return false, nil, nil end
            
            local allProps = {}
            for _, child in ipairs(workspace:GetChildren()) do
                if child.Name == "Props" and child:IsA("Model") then
                    table.insert(allProps, child)
                end
            end
            
            for _, props in ipairs(allProps) do
                for _, pattern in ipairs(patterns) do
                    for _, child in ipairs(props:GetChildren()) do
                        if child.Name == pattern and IsEventAlive(child) then
                            local position = nil
                            if child:IsA("Model") then
                                if child.PrimaryPart then position = child.PrimaryPart.Position
                                else local cf, size = child:GetBoundingBox(); position = cf.Position end
                            elseif child:IsA("BasePart") then
                                position = child.Position
                            end
                            
                            if position then return true, position, child end
                        end
                    end
                end
            end

            if eventName == "Lochness Hunt" then
                for _, obj in ipairs(workspace:GetChildren()) do
                    if obj.Name:find("Nessie") or obj.Name:find("Lochness") then
                        return true, obj:GetPivot().Position, obj
                    end
                end
            end
            return false, nil, nil
        end

        local function DebugAllProps()
            
        end

        local ActiveEventsCache = {
            events = {}, lastFullScan = 0, scanInterval = 60
        }

        function ActiveEventsCache:GetAll() return self.events or {} end
        
        function ActiveEventsCache:Add(eventName, position, model)
            if not self.events then self.events = {} end
            self.events[eventName] = {
                position = position, model = model, foundAt = tick(),
                lastVisit = 0, visitCount = 0
            }
        end

        function ActiveEventsCache:Clear() self.events = {} end

        function ActiveEventsCache:IsEventStillActive(eventName)
            if not self.events or not self.events[eventName] then return false end
            local success, stillExists = pcall(function()
                local found, pos, obj = SearchInAllProps(eventName)
                return found and obj and IsEventAlive(obj)
            end)
            if not success or not stillExists then
                self.events[eventName] = nil
                return false
            end
            return true
        end

        function ActiveEventsCache:ShouldScan()
            local timeSinceLastScan = tick() - self.lastFullScan
            local hasNoEvents = next(self.events or {}) == nil
            return hasNoEvents or timeSinceLastScan >= self.scanInterval
        end

        function ActiveEventsCache:MarkScanned() self.lastFullScan = tick() end

        function ActiveEventsCache:MarkVisited(eventName)
            if self.events and self.events[eventName] then
                self.events[eventName].lastVisit = tick()
                self.events[eventName].visitCount = (self.events[eventName].visitCount or 0) + 1
            end
        end
        
        local RotationSystem = { interval = 10, lastRotation = 0, currentIndex = 0, queue = {} }

        function RotationSystem:BuildQueue()
            self.queue = {}
            local events = ActiveEventsCache:GetAll()
            
            if SelectedPriorityEvent and events[SelectedPriorityEvent] then
                for i = 1, 2 do table.insert(self.queue, {name = SelectedPriorityEvent, data = events[SelectedPriorityEvent]}) end
            end
            
            for eventName, data in pairs(events) do
                if eventName ~= SelectedPriorityEvent then
                    table.insert(self.queue, {name = eventName, data = data})
                end
            end
        end

        function RotationSystem:GetNext()
            if #self.queue == 0 then self:BuildQueue() end
            if #self.queue == 0 then return nil end
            
            self.currentIndex = self.currentIndex + 1
            if self.currentIndex > #self.queue then self.currentIndex = 1 end
            
            local event = self.queue[self.currentIndex]
            if not ActiveEventsCache:IsEventStillActive(event.name) then
                self:BuildQueue()
                return self:GetNext()
            end
            return event
        end

        function RotationSystem:ShouldRotate()
            if self.lastRotation == 0 then return true end
            return (tick() - self.lastRotation) >= self.interval
        end

        function RotationSystem:MarkRotated() self.lastRotation = tick() end
        function RotationSystem:SetInterval(s) self.interval = math.max(5, math.min(60, s)) end

        -- =========================================================
        -- TELEPORT MANAGER
        -- =========================================================
        local TeleportManager = { lastTeleport = 0, minInterval = 1.0 }

        function TeleportManager:Teleport(pos)
            local now = tick()
            if now - self.lastTeleport < self.minInterval then return false end
            
            local char = game.Players.LocalPlayer.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if not hrp then return false end
            
            local success = pcall(function()
                local offset = Vector3.new(math.random(-5, 5), math.random(5, 15), math.random(-5, 5))
                char:PivotTo(CFrame.new(pos + offset))
                hrp.Anchored = false 
                hrp.Velocity = Vector3.zero
                self.lastTeleport = now
            end)
            return success
        end

        televent:Dropdown({
            Text = "Priority Event",
            Options = eventsList,
            Default = "Select Priority",
            Flag = "priority_event_flag",
            Callback = function(opt) SelectedPriorityEvent = opt end
        })

        televent:Dropdown({
            Text = "Normal Events",
            Options = eventsList,
            MultiSelect = true,
            Flag = "normal_event_flag",
            Callback = function(opts) SelectedNormalEvents = opts or {} end
        })

        televent:Input({
            Text = "Rotation Interval (s)",
            Value = tostring(RotationSystem.interval),
            Placeholder = "10",
            Flag = "rotation_interval_flag",
            Callback = function(text)
                local val = tonumber(text)
                if val then RotationSystem:SetInterval(val) end
            end
        })

        televent:Dropdown({
            Text = "Idle Area (When No Event)",
            Options = AreaNamess,
            Default = "Select Area",
            Flag = "idle_area_flag",
            Callback = function(opt) Loch_Return_SelectedArea = opt end
        })

        televent:Toggle({
            Text = "Enable Auto Event Mode",
            Default = false,
            Flag = "enable_auto_event_mode",
            Callback = function(state)
                SmartEventState = state

                if SmartEventState then
                    ActiveEventsCache:Clear()
                    RotationSystem.lastRotation = 0
                    RotationSystem.currentIndex = 0
                    RotationSystem.queue = {}
                    
                    SmartEventThread = task.spawn(function()
                        while SmartEventState do
                            pcall(function()
                                local activeCount = 0
                                local cachedEvents = ActiveEventsCache:GetAll()
                                
                                for eventName, _ in pairs(cachedEvents) do
                                    if ActiveEventsCache:IsEventStillActive(eventName) then
                                        activeCount = activeCount + 1
                                    end
                                end

                                -- SCANNING LOGIC
                                if ActiveEventsCache:ShouldScan() then
                                    local eventsToFind = {}
                                    if SelectedPriorityEvent then table.insert(eventsToFind, SelectedPriorityEvent) end
                                    for _, eventName in ipairs(SelectedNormalEvents) do
                                        if eventName ~= SelectedPriorityEvent then table.insert(eventsToFind, eventName) end
                                    end
                                    
                                    local newFound = 0
                                    for _, eventName in ipairs(eventsToFind) do
                                        if not SmartEventState then break end
                                        if not ActiveEventsCache:GetAll()[eventName] then
                                            local found, position, model = SearchInAllProps(eventName)
                                            if found then
                                                ActiveEventsCache:Add(eventName, position, model)
                                                newFound = newFound + 1
                                            end
                                        end
                                        task.wait(0.1)
                                    end
                                    ActiveEventsCache:MarkScanned()
                                    if newFound > 0 then RotationSystem.queue = {} end
                                end

                                if activeCount > 0 then
                                    if RotationSystem:ShouldRotate() then
                                        local nextEvent = RotationSystem:GetNext()
                                        if nextEvent then
                                            if TeleportManager:Teleport(nextEvent.data.position) then
                                                ActiveEventsCache:MarkVisited(nextEvent.name)
                                                RotationSystem:MarkRotated()
                                                task.wait(8)
                                            end
                                        end
                                    else
                                        task.wait(1)
                                    end
                                else
                                    if Loch_Return_SelectedArea and FishingAreass[Loch_Return_SelectedArea] then
                                        local idlePos = FishingAreass[Loch_Return_SelectedArea].Pos
                                        TeleportManager:Teleport(idlePos)
                                    end
                                    task.wait(5)
                                end
                            end)
                            task.wait(0.1)
                        end
                    end)
                    Nexus:Notify({Title = "Smart Event", Content = "Started", Type = "Success"})
                else
                    if SmartEventThread then task.cancel(SmartEventThread) end
                    ActiveEventsCache:Clear()
                    Nexus:Notify({Title = "Smart Event", Content = "Stopped", Type = "Warning"})
                end
            end
        })
    end
end

do
    local shop = Window:Tab({Text = "Shop & Items", Icon = "🛒"})

    do
        --local ManagerTab = Window:Tab({Text = "Item Manager", Icon = "⭐"})
        local FavSection = shop:Collapsible("Auto Favorite / Unfavorite")

        -- [[ SERVICES & VARIABLES ]]
        local ReplicatedStorage = game:GetService("ReplicatedStorage")
        local AutoFavEnabled = false
        local AutoUnfavEnabled = false
        
        local SelectedRarities = {}
        local SelectedMutations = {}
        local SelectedItemNames = {}
        
        local NetFolder = ReplicatedStorage:WaitForChild("Packages"):WaitForChild("_Index"):WaitForChild("sleitnick_net@0.2.0"):WaitForChild("net")
        local RE_FavoriteItem = NetFolder:WaitForChild("RE/FavoriteItem")
        local RE_ObtainedNewFish = NetFolder:WaitForChild("RE/ObtainedNewFishNotification")
        local ItemsModule = require(ReplicatedStorage:WaitForChild("Items"))

        local TIER_MAP = {
            [1] = "Common", [2] = "Uncommon", [3] = "Rare", [4] = "Epic",
            [5] = "Legendary", [6] = "Mythic", [7] = "SECRET"
        }

        local function GetFishData(itemId)
            for _, fish in pairs(ItemsModule) do
                if fish.Data and fish.Data.Id == itemId then return fish end
            end
            return nil
        end

        local function GetAllMutations()
            return {
                "Galaxy", "Corrupt", "Gemstone", "Fairy Dust", "Midnight",
                "Color Burn", "Holographic", "Lightning", "Radioactive",
                "Ghost", "Gold", "Frozen", "1x1x1x1", "Stone", "Sandy",
                "Noob", "Moon Fragment", "Festive", "Albino", "Arctic Frost", "Disco", 
                "Big", "Giant", "Shiny", "Sparkling", "Leviatan"
            }
        end

        local function GetAllItemNames()
            local names = {}
            for _, item in pairs(ItemsModule) do
                if item.Data and item.Data.Name then table.insert(names, item.Data.Name) end
            end
            table.sort(names)
            return names
        end

        local function IsMatch(itemId, metadata, extraData)
            local fishData = GetFishData(itemId)
            if not fishData then return false end

            local tierName = TIER_MAP[fishData.Data.Tier] or "Unknown"
            if #SelectedRarities > 0 and table.find(SelectedRarities, tierName) then
                return true, "Rarity: " .. tierName
            end

            if #SelectedItemNames > 0 and table.find(SelectedItemNames, fishData.Data.Name) then
                return true, "Name: " .. fishData.Data.Name
            end

            local mutation = "None"
            if metadata and metadata.VariantId and metadata.VariantId ~= "None" then mutation = metadata.VariantId end
            if extraData and extraData.Variant and extraData.Variant ~= "None" then mutation = extraData.Variant end
            
            -- Cek Shiny manual
            if (metadata and metadata.Shiny) or (extraData and extraData.Shiny) then 
                if #SelectedMutations > 0 and table.find(SelectedMutations, "Shiny") then return true, "Mutation: Shiny" end
            end

            if #SelectedMutations > 0 and table.find(SelectedMutations, mutation) then
                return true, "Mutation: " .. mutation
            end

            return false
        end
        
        local FavConnection = nil
        
        local function ToggleAutoManager(state)
            if state then
                if FavConnection then FavConnection:Disconnect() end
                
                FavConnection = RE_ObtainedNewFish.OnClientEvent:Connect(function(itemId, metadata, extraData)
                    local inventoryItem = extraData and extraData.InventoryItem
                    local uuid = inventoryItem and inventoryItem.UUID
                    
                    if not uuid then return end

                    local isMatching, reason = IsMatch(itemId, metadata, extraData)
                    if AutoFavEnabled and isMatching then
                        task.delay(0.5, function()
                            pcall(function() RE_FavoriteItem:FireServer(uuid) end)
                            Nexus:Notify({Title="Auto Fav", Content=reason, Type="Success", Duration=2})
                        end)
                    end

                    -- LOGIKA AUTO UNFAVORITE (Kebalikan)
                    -- Hapus favorite jika TIDAK match filter tapi entah kenapa ke-fav (jarang terjadi, tapi buat jaga2)
                    -- ATAU jika kamu ingin fitur: "Unfav semua yang tidak masuk list"
                    -- (Biasanya Unfav dipakai manual looping inventory, tapi di sini kita fokus real-time capture)
                end)
            else
                if FavConnection then FavConnection:Disconnect() FavConnection = nil end
            end
        end

        -- [[ MANUAL SCAN (UNTUK UNFAVORITE MASSAL) ]]
        -- Karena Unfavorite biasanya untuk membersihkan inventory yang SUDAH ADA, kita butuh scan manual.
        local function RunBatchUnfavorite()
            local Replion = require(ReplicatedStorage.Packages.Replion).Client
            local Data = Replion:WaitReplion("Data", 5)
            if not Data then return end
            
            local success, inv = pcall(function() return Data:GetExpect("Inventory") end)
            if not success or not inv or not inv.Items then return end

            local count = 0
            for _, item in ipairs(inv.Items) do
                -- Kita hanya unfavorite item yang SUDAH Favorite
                if item.Favorited or item.IsFavorite then
                    -- Cek apakah item ini MATCHING dengan filter kita?
                    local dummyMeta = item.Metadata or {}
                    local dummyExtra = {Variant = dummyMeta.VariantId, Shiny = dummyMeta.Shiny}
                    
                    -- Jika item ini MATCH dengan filter "Sampah" yang user pilih untuk di UNFAV
                    -- Disini logikanya: User memilih Rarity untuk di-UNFAVORITE
                    local isMatch, _ = IsMatch(item.Id, dummyMeta, dummyExtra)
                    
                    if isMatch then
                        pcall(function() RE_FavoriteItem:FireServer(item.UUID) end)
                        count = count + 1
                        task.wait(0.1) -- Delay biar gak kick
                    end
                end
            end
            
            if count > 0 then
                Nexus:Notify({Title="Unfavorite", Content="Removed " .. count .. " favorites.", Type="Warning"})
            else
                Nexus:Notify({Title="Unfavorite", Content="No matching favorites found.", Type="Info"})
            end
        end

        -- [[ UI IMPLEMENTATION ]]
        
        FavSection:Dropdown({
            Text = "Filter Rarity",
            Options = {"Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic", "SECRET"},
            MultiSelect = true,
            Callback = function(v) SelectedRarities = v or {} end
        })

        FavSection:Dropdown({
            Text = "Filter Mutation",
            Options = GetAllMutations(),
            MultiSelect = true,
            Callback = function(v) SelectedMutations = v or {} end
        })

        FavSection:Dropdown({
            Text = "Filter Fish Name",
            Options = GetAllItemNames(),
            MultiSelect = true,
            Callback = function(v) SelectedItemNames = v or {} end
        })

        FavSection:Toggle({
            Text = "Enable Auto Favorite (Real-Time)",
            Default = false,
            Callback = function(state)
                AutoFavEnabled = state
                ToggleAutoManager(state or AutoUnfavEnabled) -- Nyalakan listener jika salah satu aktif
                
                if state then
                    Nexus:Notify({Title="Auto Favorite", Content="ON! Menunggu ikan...", Type="Success"})
                end
            end
        })

        -- Auto Unfavorite di sini saya buat manual button saja agar lebih aman
        -- Karena Auto Unfavorite real-time itu aneh (masa baru dapet langsung di unfav?)
        FavSection:Button({
            Text = "Unfavorite Matching Items (Scan Inventory)",
            Callback = function()
                if #SelectedRarities == 0 and #SelectedMutations == 0 and #SelectedItemNames == 0 then
                    Nexus:Notify({Title="Warning", Content="Pilih filter dulu (Item yang mau di-Unfav)", Type="Warning"})
                    return
                end
                
                Nexus:Notify({Title="Scanning", Content="Memproses inventory...", Type="Info"})
                RunBatchUnfavorite()
            end
        })
        
        FavSection:Label({Text = "Note: Untuk Auto Favorite, pilih item BAGUS. Untuk Unfavorite Button, pilih item JELEK yang mau dihapus bintangnya.", Color = Color3.fromRGB(200, 200, 200)})

    end
    
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local Players = game:GetService("Players")
    local LocalPlayer = Players.LocalPlayer
    local RunService = game:GetService("RunService")

    local function SafeRequire(path)
        local success, result = pcall(function()
            return require(path)
        end)
        if success then
            return result
        else
            warn("[Xeno Fix] Gagal require module: " .. tostring(path))
            return nil
        end
    end

    local ItemUtility = SafeRequire(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("ItemUtility", 2))
    local TierUtility = SafeRequire(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("TierUtility", 2))
    local ReplionModule = SafeRequire(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Replion", 2))

    local PlayerDataReplion = nil
    
    local function GetPlayerDataReplion()
        if PlayerDataReplion then return PlayerDataReplion end
        local ReplionModule = RepStorage:WaitForChild("Packages"):WaitForChild("Replion", 10)
        if not ReplionModule then return nil end
        local ReplionClient = require(ReplionModule).Client
        PlayerDataReplion = ReplionClient:WaitReplion("Data", 5)
        return PlayerDataReplion
    end

    -- Helper function to find remotes safely
    local function GetRemoteSafe(name)
        -- Coba cari di NetPackage
        local s, r = pcall(function() 
            local p = ReplicatedStorage.Packages._Index["sleitnick_net@0.2.0"].net
            return p:FindFirstChild("RF/" .. name) or p:FindFirstChild("RE/" .. name)
        end)
        if s and r then return r end
        return nil
    end

    -- =========================================================
    -- 1. AUTO BUY WEATHER
    -- =========================================================
    local weatherSection = shop:Collapsible("Auto Buy Weather")
    
    local RFPurchaseWeatherEvent = GetRemoteSafe("PurchaseWeatherEvent")
    local AutoBuyWeather = {
        Running = false,
        Selected = {},
        AllWeathers = {"Cloudy", "Storm", "Wind", "Snow", "Radiant", "Shark Hunt"}
    }
    
    local weatherStatusLabel = nil

    -- Dropdown Multi Select
    weatherSection:Dropdown({
        Text = "Select Weathers Target",
        Options = AutoBuyWeather.AllWeathers,
        MultiSelect = true,
        Callback = function(items)
            AutoBuyWeather.Selected = items or {}
        end
    })
    
    -- Logic Loop
    local weatherThread = nil
    local function StartWeatherLoop()
        if weatherThread then task.cancel(weatherThread) end
        weatherThread = task.spawn(function()
            while AutoBuyWeather.Running do
                for _, weather in ipairs(AutoBuyWeather.Selected) do
                    if not AutoBuyWeather.Running then break end
                    if RFPurchaseWeatherEvent then
                        pcall(function() RFPurchaseWeatherEvent:InvokeServer(weather) end)
                    end
                    task.wait(0.1)
                end
                task.wait(10)
            end
        end)
    end

    -- Buttons
    weatherSection:Button({
        Text = "Start Auto Buy",
        Callback = function()
            if #AutoBuyWeather.Selected == 0 then
                Nexus:Notify({Title = "Error", Content = "Select weather first!", Type = "Error"})
                return
            end
            AutoBuyWeather.Running = true
            StartWeatherLoop()
            Nexus:Notify({Title = "Auto Buy", Content = "Started", Type = "Success"})
        end
    })
    
    weatherSection:Button({
        Text = "Stop Auto Buy",
        Callback = function()
            AutoBuyWeather.Running = false
            if weatherThread then task.cancel(weatherThread) end
            Nexus:Notify({Title = "Auto Buy", Content = "Stopped", Type = "Warning"})
        end
    })
    
    local RE_SpawnTotem = GetRemote(RPath, "RE/SpawnTotem")
    local RF_EquipOxygenTank = GetRemote(RPath, "RF/EquipOxygenTank")
    local RF_UnequipOxygenTank = GetRemote(RPath, "RF/UnequipOxygenTank")

    local function debugLog(msg)
        warn("[TOTEM SYSTEM] " .. msg)
    end

    if not RE_SpawnTotem then
        debugLog("WARNING: RE/SpawnTotem tidak ditemukan! Pastikan ini game 'Fish It'.")
    end

    -- [2] UI & VARIABLES
    local totemSection = shop:Collapsible("Auto Spawn Totem")
    local TOTEM_STATUS_PARAGRAPH = totemSection:Paragraph({Title = "Status", Content = "Idle"})

    local TOTEM_DATA = {
        ["Luck Totem"]={Id=1, Duration=3600}, 
        ["Mutation Totem"]={Id=2, Duration=3600}, 
        ["Shiny Totem"]={Id=3, Duration=3600}
    }
    local TOTEM_NAMES = {"Luck Totem", "Mutation Totem", "Shiny Totem"}
    local selectedTotemName = "Luck Totem"
    local currentTotemExpiry = 0
    
    local AUTO_TOTEM_ACTIVE = false
    local AUTO_TOTEM_THREAD = nil
    
    local AUTO_9_TOTEM_ACTIVE = false
    local AUTO_9_TOTEM_THREAD = nil

    -- [3] COORDINATES (9 SPOTS)
    local REF_CENTER = Vector3.new(93.932, 9.532, 2684.134)
    local REF_SPOTS = {
        Vector3.new(45.046, 9.516, 2730.190),   -- 1
        Vector3.new(145.644, 9.516, 2721.907),  -- 2
        Vector3.new(84.640, 10.217, 2636.057),  -- 3
        Vector3.new(45.046, 110.516, 2730.190), -- 4
        Vector3.new(145.644, 110.516, 2721.907),-- 5
        Vector3.new(84.640, 111.217, 2636.057), -- 6
        Vector3.new(45.046, -92.483, 2730.190), -- 7
        Vector3.new(145.644, -92.483, 2721.907),-- 8
        Vector3.new(84.640, -93.782, 2636.057), -- 9
    }

    -- =========================================================
    -- FLY ENGINE V3 (PHYSICS + ANTI-FALL)
    -- =========================================================
    local RunService = game:GetService("RunService")
    local LocalPlayer = game:GetService("Players").LocalPlayer
    local stateConnection = nil

    local function GetFlyPart()
        local char = LocalPlayer.Character
        if not char then return nil end
        return char:FindFirstChild("Torso") or char:FindFirstChild("UpperTorso") or char:FindFirstChild("HumanoidRootPart")
    end

    local function MaintainAntiFallState(enable)
        local char = LocalPlayer.Character
        local hum = char and char:FindFirstChild("Humanoid")
        if not hum then return end

        if enable then
            -- Paksa matikan state jatuh
            hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
            hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
            hum:SetStateEnabled(Enum.HumanoidStateType.Freefall, false) -- Kunci utama anti-guling

            if not stateConnection then
                stateConnection = RunService.Heartbeat:Connect(function()
                    if hum and (AUTO_9_TOTEM_ACTIVE or AUTO_TOTEM_ACTIVE) then
                        hum:ChangeState(Enum.HumanoidStateType.Swimming) -- State paling stabil
                    end
                end)
            end
        else
            if stateConnection then stateConnection:Disconnect(); stateConnection = nil end
            hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, true)
            hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, true)
            hum:SetStateEnabled(Enum.HumanoidStateType.Freefall, true)
            hum:ChangeState(Enum.HumanoidStateType.RunningNoPhysics)
        end
    end

    local function EnableV3Physics()
        local char = LocalPlayer.Character
        local hum = char and char:FindFirstChild("Humanoid")
        local mainPart = GetFlyPart()
        if not mainPart or not hum then return end

        hum.PlatformStand = true 
        MaintainAntiFallState(true)

        local bg = mainPart:FindFirstChild("FlyGuiGyro") or Instance.new("BodyGyro", mainPart)
        bg.Name = "FlyGuiGyro"; bg.P = 9e4; bg.maxTorque = Vector3.new(9e9, 9e9, 9e9); bg.CFrame = mainPart.CFrame

        local bv = mainPart:FindFirstChild("FlyGuiVelocity") or Instance.new("BodyVelocity", mainPart)
        bv.Name = "FlyGuiVelocity"; bv.velocity = Vector3.zero; bv.maxForce = Vector3.new(9e9, 9e9, 9e9)

        -- Noclip
        task.spawn(function()
            while (AUTO_9_TOTEM_ACTIVE or AUTO_TOTEM_ACTIVE) and char do
                for _, v in ipairs(char:GetDescendants()) do
                    if v:IsA("BasePart") then v.CanCollide = false end
                end
                task.wait(0.5)
            end
        end)
    end

    local function DisableV3Physics()
        local char = LocalPlayer.Character
        local hum = char and char:FindFirstChild("Humanoid")
        local mainPart = GetFlyPart()

        if mainPart then
            if mainPart:FindFirstChild("FlyGuiGyro") then mainPart.FlyGuiGyro:Destroy() end
            if mainPart:FindFirstChild("FlyGuiVelocity") then mainPart.FlyGuiVelocity:Destroy() end
            mainPart.Velocity = Vector3.zero
        end

        if hum then hum.PlatformStand = false end
        MaintainAntiFallState(false)
        
        -- Restore Collision
        if char then
            for _, v in ipairs(char:GetDescendants()) do
                if v:IsA("BasePart") then v.CanCollide = true end
            end
        end
    end

    local function FlyPhysicsTo(targetPos)
        local mainPart = GetFlyPart()
        if not mainPart then return end
        
        local bv = mainPart:FindFirstChild("FlyGuiVelocity")
        local bg = mainPart:FindFirstChild("FlyGuiGyro")
        if not bv or not bg then EnableV3Physics(); bv = mainPart.FlyGuiVelocity; bg = mainPart.FlyGuiGyro end

        local SPEED = 85 -- Kecepatan Terbang
        
        while (AUTO_9_TOTEM_ACTIVE or AUTO_TOTEM_ACTIVE) do
            local currentPos = mainPart.Position
            local diff = targetPos - currentPos
            local dist = diff.Magnitude
            
            bg.CFrame = CFrame.lookAt(currentPos, targetPos)

            if dist < 2.0 then -- Sampai target
                bv.velocity = Vector3.zero
                break
            else
                bv.velocity = diff.Unit * SPEED
            end
            RunService.Heartbeat:Wait()
        end
    end

    local ReplionModule = SafeRequire(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Replion", 2))

    local function GetPlayerDataReplion()
        if PlayerDataReplion then return PlayerDataReplion end
        local ReplionModule = RepStorage:WaitForChild("Packages"):WaitForChild("Replion", 10)
        if not ReplionModule then return nil end
        local ReplionClient = require(ReplionModule).Client
        PlayerDataReplion = ReplionClient:WaitReplion("Data", 5)
        return PlayerDataReplion
    end

    -- =========================================================
    -- HELPER: GET UUID
    -- =========================================================
    local function GetTotemUUID(name)
        -- Gunakan fungsi GetPlayerDataReplion() yang sudah ada di script hub Anda
        local r = GetPlayerDataReplion() 
        if not r then return nil end
        
        local s, d = pcall(function() return r:GetExpect("Inventory") end)
        if s and d.Totems then 
            for _, i in ipairs(d.Totems) do 
                -- Cocokkan ID Totem
                if tonumber(i.Id) == TOTEM_DATA[name].Id and (i.Count or 1) >= 1 then 
                    return i.UUID 
                end 
            end 
        end
        return nil
    end

    local function Run9TotemLoop()
        if AUTO_9_TOTEM_THREAD then task.cancel(AUTO_9_TOTEM_THREAD) end
        
        AUTO_9_TOTEM_THREAD = task.spawn(function()
            -- Cek Remote
            if not RE_SpawnTotem then
                Nexus:Notify({Title="Error", Content="Remote SpawnTotem tidak ditemukan!", Type="Error"})
                return
            end

            -- Cek UUID Awal
            local uuid = GetTotemUUID(selectedTotemName)
            if not uuid then 
                Nexus:Notify({Title="Error", Content="Tidak ada stock " .. selectedTotemName, Type="Error"})
                local t = totemSection:GetElementByTitle("Auto Spawn 9 Totem Formation")
                if t then t:Set(false) end
                return 
            end

            local char = LocalPlayer.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if not hrp then return end
            
            local myStartPos = hrp.Position 
            Nexus:Notify({Title="Started", Content="Formation Sequence Started", Type="Info"})
            
            -- Equip Oxygen
            if RF_EquipOxygenTank then pcall(function() RF_EquipOxygenTank:InvokeServer(105) end) end
            
            EnableV3Physics()

            for i, refSpot in ipairs(REF_SPOTS) do
                if not AUTO_9_TOTEM_ACTIVE then break end
                
                -- Hitung posisi relatif
                local relativePos = refSpot - REF_CENTER
                local targetPos = myStartPos + relativePos
                
                TOTEM_STATUS_PARAGRAPH:SetDesc("Flying to Spot #" .. i)
                FlyPhysicsTo(targetPos) 
                task.wait(0.3) -- Stabilisasi singkat

                -- Ambil UUID terbaru (takutnya berubah/stack berkurang)
                uuid = GetTotemUUID(selectedTotemName)
                if uuid then
                    TOTEM_STATUS_PARAGRAPH:SetDesc("Spawning #" .. i)
                    
                    -- [THE MAGIC LINE] Direct Spawn via Remote
                    RE_SpawnTotem:FireServer(uuid)
                    
                    -- Fake Equip (Opsional: Biar inventory refresh di UI)
                    pcall(function() game:GetService("ReplicatedStorage").Packages._Index["sleitnick_net@0.2.0"].net["RE/EquipToolFromHotbar"]:FireServer(1) end)
                else
                    Nexus:Notify({Title="Habis", Content="Stock Totem Habis!", Type="Warning"})
                    break
                end
                
                task.wait(0.5) -- Delay antar spawn
            end

            if AUTO_9_TOTEM_ACTIVE then
                TOTEM_STATUS_PARAGRAPH:SetDesc("Returning...")
                FlyPhysicsTo(myStartPos)
                Nexus:Notify({Title="Selesai", Content="9 Totem Placed!", Type="Success"})
            end
            
            if RF_UnequipOxygenTank then pcall(function() RF_UnequipOxygenTank:InvokeServer() end) end
            
            DisableV3Physics() 
            AUTO_9_TOTEM_ACTIVE = false
            local t = totemSection:GetElementByTitle("Auto Spawn 9 Totem Formation")
            if t then t:Set(false) end
        end)
    end

    -- =========================================================
    -- LOGIC 2: SINGLE AUTO TOTEM (TIMER)
    -- =========================================================
    local function RunAutoTotemLoop()
        if AUTO_TOTEM_THREAD then task.cancel(AUTO_TOTEM_THREAD) end
        
        AUTO_TOTEM_THREAD = task.spawn(function()
            if not RE_SpawnTotem then
                Nexus:Notify({Title="Error", Content="Remote SpawnTotem Missing", Type="Error"})
                return
            end

            while AUTO_TOTEM_ACTIVE do
                local timeLeft = currentTotemExpiry - os.time()
                
                if timeLeft > 0 then
                    local m = math.floor((timeLeft % 3600) / 60)
                    local s = math.floor(timeLeft % 60)
                    TOTEM_STATUS_PARAGRAPH:SetDesc("Next: %02d:%02d", m, s)
                else
                    TOTEM_STATUS_PARAGRAPH:SetDesc("Spawning Single...")
                    
                    local uuid = GetTotemUUID(selectedTotemName)
                    if uuid then
                        -- Direct Spawn
                        RE_SpawnTotem:FireServer(uuid)
                        
                        Nexus:Notify({Title="Spawned", Content=selectedTotemName, Type="Success"})
                        
                        -- Update Timer
                        local duration = TOTEM_DATA[selectedTotemName].Duration or 3600
                        currentTotemExpiry = os.time() + duration
                    else
                        TOTEM_STATUS_PARAGRAPH:SetDesc("No Stock!")
                    end
                end
                task.wait(1)
            end
        end)
    end
    
    totemSection:Dropdown({
        Text = "Select Totem Type",
        Options = TOTEM_NAMES,
        Default = "Luck Totem",
        Callback = function(n) selectedTotemName = n; currentTotemExpiry = 0 end
    })

    totemSection:Toggle({
        Text = "Enable Auto Totem (Timer/Single)",
        Default = false,
        Callback = function(state)
            AUTO_TOTEM_ACTIVE = state
            if state then RunAutoTotemLoop() 
            elseif AUTO_TOTEM_THREAD then task.cancel(AUTO_TOTEM_THREAD) end
        end
    })
    
    totemSection:Toggle({
        Text = "Auto Spawn 9 Totem Formation",
        Default = false,
        Callback = function(state)
            AUTO_9_TOTEM_ACTIVE = state
            if state then
                Run9TotemLoop()
            else
                if AUTO_9_TOTEM_THREAD then task.cancel(AUTO_9_TOTEM_THREAD) end
                DisableV3Physics()
                Nexus:Notify({Title="Stopped", Content="9 Totem Stopped", Type="Warning"})
            end
        end
    })
    
    local autoSellSection = shop:Collapsible("Auto Sell Items")
    
    local SellRemote = GetRemoteSafe("SellAllItems")
    local AutoSell = {
        TotalSells = 0,
        Timer = { Enabled = false, Interval = 5, Thread = nil },
        Count = { Enabled = false, Target = 200, Thread = nil, LastSell = 0 }
    }

    local function executeSell()
        if not SellRemote then return false end
        local s, r = pcall(function() return SellRemote:InvokeServer() end)
        if s then AutoSell.TotalSells = AutoSell.TotalSells + 1 return true end
        return false
    end
    
    local function getBagCount()
        -- Helper bag parser simple
        local gui = LocalPlayer:FindFirstChild("PlayerGui")
        local label = gui and gui:FindFirstChild("Inventory") and gui.Inventory.Main.Top.Options.Fish.Label.BagSize
        if label then
            local cur = label.Text:match("(%d+)/")
            local max = label.Text:match("/(%d+)")
            return tonumber(cur) or 0, tonumber(max) or 0
        end
        return 0, 0
    end

    autoSellSection:Button({
        Text = "Sell All Items Now",
        Callback = function()
            if executeSell() then
                Nexus:Notify({Title = "Sold", Content = "Items sold successfully", Type = "Success"})
            else
                Nexus:Notify({Title = "Error", Content = "Sell Failed / Remote Missing", Type = "Error"})
            end
        end
    })

    -- Timer Mode
    autoSellSection:Input({
        Text = "Timer Interval (s)",
        Value = "5",
        Placeholder = "5",
        Callback = function(v)
            local n = tonumber(v)
            if n and n >= 1 then AutoSell.Timer.Interval = n end
        end
    })

    autoSellSection:Toggle({
        Text = "Enable Auto Sell (Timer)",
        Default = false,
        Callback = function(state)
            AutoSell.Timer.Enabled = state
            if state then
                AutoSell.Timer.Thread = task.spawn(function()
                    while AutoSell.Timer.Enabled do
                        task.wait(AutoSell.Timer.Interval)
                        if not AutoSell.Timer.Enabled then break end
                        executeSell()
                    end
                end)
            elseif AutoSell.Timer.Thread then
                task.cancel(AutoSell.Timer.Thread)
            end
        end
    })

    -- Count Mode
    autoSellSection:Input({
        Text = "Sell at Bag Count",
        Value = "200",
        Placeholder = "200",
        Callback = function(v)
            local n = tonumber(v)
            if n and n > 0 then AutoSell.Count.Target = n end
        end
    })

    autoSellSection:Toggle({
        Text = "Enable Auto Sell (By Count)",
        Default = false,
        Callback = function(state)
            AutoSell.Count.Enabled = state
            if state then
                AutoSell.Count.Thread = task.spawn(function()
                    while AutoSell.Count.Enabled do
                        task.wait(1.5)
                        if not AutoSell.Count.Enabled then break end
                        local cur, _ = getBagCount()
                        if cur >= AutoSell.Count.Target then
                            if tick() - AutoSell.Count.LastSell > 3 then
                                AutoSell.Count.LastSell = tick()
                                executeSell()
                                task.wait(2)
                            end
                        end
                    end
                end)
            elseif AutoSell.Count.Thread then
                task.cancel(AutoSell.Count.Thread)
            end
        end
    })
    
    local merchantSection = shop:Collapsible("Merchant Access")

    merchantSection:Toggle({
        Text = "Open Merchant GUI",
        Default = false,
        Callback = function(state)
            local pGui = LocalPlayer:WaitForChild("PlayerGui")
            local merchantUI = pGui:FindFirstChild("Merchant")
            if merchantUI then
                merchantUI.Enabled = state
                if state then Nexus:Notify({Title = "Shop", Content = "Opened"}) end
            else
                Nexus:Notify({Title = "Error", Content = "Merchant UI Not Found", Type = "Error"})
            end
        end
    })

    merchantSection:Button({
        Text = "Fix / Refresh Merchant UI",
        Callback = function()
            local pGui = LocalPlayer:WaitForChild("PlayerGui")
            local merchantUI = pGui:FindFirstChild("Merchant")
            if merchantUI then
                merchantUI.Enabled = false
                task.wait(0.1)
                merchantUI.Enabled = true
                Nexus:Notify({Title = "Refreshed", Content = "UI Reset Done"})
            end
        end
    })
end

do
    local SettingsTab = Window:Tab({Text = "Settings", Icon = "⚙️"})
    local MiscSection = SettingsTab:Collapsible("Misc. Area")
    
    local RunService = game:GetService("RunService")
    local LocalPlayer = game:GetService("Players").LocalPlayer
    local CoreGui = game:GetService("CoreGui")
    local UserInputService = game:GetService("UserInputService")

    -- 1. DISABLE 3D RENDERING (SAVER MODE)
    local BlackScreenGUI = nil
    local OldCamType = nil

    -- =================================================================
    -- CONFIGURATION SYSTEM UI
    -- =================================================================
    local ConfigSection = SettingsTab:Collapsible("Configuration Manager")
    
    local ConfigName = ""
    local SelectedConfig = nil
    
    -- Input Nama Config Baru
    ConfigSection:Input({
        Text = "Create Config Name",
        Placeholder = "Ex: Legit Farm",
        Callback = function(text)
            ConfigName = text
        end
    })
    
    -- Tombol Save Baru
    ConfigSection:Button({
        Text = "Save New Config",
        Callback = function()
            if ConfigName == "" then 
                Nexus:Notify({Title = "Error", Content = "Input config name first!", Type = "Error"})
                return 
            end

            local FileName = SanitizeFileName(ConfigName)
            if FileName == "" then
                Nexus:Notify({
                    Title = "Error",
                    Content = "Invalid config name!",
                    Type = "Error"
                })
                return
            end

            local success = Nexus:SaveConfig(FileName)
            if success then
                Nexus.AutoSave.ActiveConfig = FileName
                Nexus:Notify({
                    Title = "Config",
                    Content = "Saved: " .. ConfigName .. " (" .. FileName .. ")",
                    Type = "Success"
                })
            else
                Nexus:Notify({
                    Title = "Error",
                    Content = "Save Failed (Check Executor)",
                    Type = "Error"
                })
            end
        end
    })

    ConfigSection:Toggle({
        Text = "Auto Save Config",
        Default = true,
        Callback = function(state)
            Nexus.AutoSave.Enabled = state
            Nexus:Notify({
                Title = "Auto Save",
                Content = state and "Enabled" or "Disabled",
                Type = state and "Success" or "Warning"
            })
        end
    })
    
    -- Dropdown List Config
    local ConfigDropdown = nil
    ConfigDropdown = ConfigSection:Dropdown({
        Text = "Select Config",
        Options = Nexus:GetConfigs(), -- Ambil list file dari folder NexusUI
        Default = "Select Config",
        Callback = function(opt)
            SelectedConfig = opt
        end
    })
    
    -- Tombol Refresh List (Berguna setelah save baru)
    ConfigSection:Button({
        Text = "Refresh Config List",
        Callback = function()
            local cfgs = Nexus:GetConfigs()
            if ConfigDropdown then
                ConfigDropdown:SetOptions(cfgs)
            end
            Nexus:Notify({Title = "Config", Content = "List Refreshed", Type = "Info"})
        end
    })
    
    -- Divider Visual
    ConfigSection:Label({Text = "Actions for Selected Config:", Color = Color3.fromRGB(150, 150, 150)})
    
    -- Tombol Load
    ConfigSection:Button({
        Text = "Load Selected Config",
        Callback = function()
            if not SelectedConfig or SelectedConfig == "Select Config" then 
                Nexus:Notify({Title = "Error", Content = "Select a config first!", Type = "Error"})
                return 
            end
            
            local success = Nexus:LoadConfig(SelectedConfig)
            if success then
                Nexus.AutoSave.ActiveConfig = FileName
            end
            if success then
                Nexus:Notify({Title = "Config", Content = "Loaded: " .. SelectedConfig, Type = "Success"})
            else
                Nexus:Notify({Title = "Error", Content = "Load Failed", Type = "Error"})
            end
        end
    })
    
    -- Tombol Overwrite (Timpa)
    ConfigSection:Button({
        Text = "Overwrite Selected",
        Callback = function()
            if not SelectedConfig or SelectedConfig == "Select Config" then 
                Nexus:Notify({Title = "Error", Content = "Select a config first!", Type = "Error"})
                return 
            end

            local success = Nexus:SaveConfig(SelectedConfig)
            if success then
                Nexus:Notify({
                    Title = "Config",
                    Content = "Overwritten: " .. SelectedConfig,
                    Type = "Success"
                })
            else
                Nexus:Notify({
                    Title = "Error",
                    Content = "Overwrite failed",
                    Type = "Error"
                })
            end
        end
    })
    
    -- [[ BONUS: AUTO LOAD FEATURE ]]
    -- Mengecek apakah ada file penanda autoload
    local AutoLoadState = false
    if isfile and isfile("NexusConfig/autoload.txt") then
        AutoLoadState = true
    end
    
    ConfigSection:Toggle({
        Text = "Auto Load Selected on Start",
        Default = AutoLoadState,
        Callback = function(state)
            if state then
                if SelectedConfig and SelectedConfig ~= "Select Config" then
                    writefile("NexusConfig/autoload.txt", SelectedConfig)
                    Nexus:Notify({Title = "Auto Load", Content = "Set to: " .. SelectedConfig, Type = "Success"})
                else
                    Nexus:Notify({Title = "Error", Content = "Select a config to autoload!", Type = "Error"})
                end
            else
                if isfile and isfile("NexusConfig/autoload.txt") then
                    delfile("NexusConfig/autoload.txt")
                end
                Nexus:Notify({Title = "Auto Load", Content = "Disabled", Type = "Warning"})
            end
        end
    })
    
    -- Logic Auto Load saat Script Jalan
    task.spawn(function()
        if AutoLoadState and isfile and isfile("NexusConfig/autoload.txt") then
            local cfgToLoad = readfile("NexusConfig/autoload.txt")
            if cfgToLoad then
                task.wait(1) -- Tunggu UI loading selesai
                Nexus:LoadConfig(cfgToLoad)
                Nexus:Notify({Title = "Auto Load", Content = "Loaded: " .. cfgToLoad, Type = "Success"})
            end
        end
    end)
    
    MiscSection:Toggle({
        Text = "Disable 3D Rendering (Saver)",
        Default = false,
        Callback = function(state)
            local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
            local Camera = workspace.CurrentCamera
            
            if state then
                -- Buat GUI Hitam
                if not BlackScreenGUI then
                    BlackScreenGUI = Instance.new("ScreenGui")
                    BlackScreenGUI.Name = "NPN_Background"
                    BlackScreenGUI.IgnoreGuiInset = true
                    BlackScreenGUI.DisplayOrder = -999  -- Paling atas
                    BlackScreenGUI.Parent = PlayerGui
                    
                    local Frame = Instance.new("Frame", BlackScreenGUI)
                    Frame.Size = UDim2.new(1, 0, 1, 0)
                    Frame.BackgroundColor3 = Color3.new(0, 0, 0)
                    Frame.BorderSizePixel = 0
                    
                    local Label = Instance.new("TextLabel", Frame)
                    Label.Size = UDim2.new(1, 0, 0.1, 0)
                    Label.Position = UDim2.new(0, 0, 0.1, 0)
                    Label.BackgroundTransparency = 1
                    Label.Text = "Saver Mode Active\nRendering Disabled"
                    Label.TextColor3 = Color3.fromRGB(150, 150, 150)
                    Label.TextSize = 24
                    Label.Font = Enum.Font.GothamBold
                end
                
                BlackScreenGUI.Enabled = true
                
                -- Pindahkan Kamera ke Void
                OldCamType = Camera.CameraType
                Camera.CameraType = Enum.CameraType.Scriptable
                Camera.CFrame = CFrame.new(0, 100000, 0)
                
                -- Matikan Rendering Engine (Jika executor support)
                pcall(function() RunService:Set3dRenderingEnabled(false) end)
                
                Nexus:Notify({Title = "Saver Mode", Content = "Enabled", Type = "Success"})
            else
                -- Restore
                if OldCamType then Camera.CameraType = OldCamType else Camera.CameraType = Enum.CameraType.Custom end
                if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
                    Camera.CameraSubject = LocalPlayer.Character.Humanoid
                end
                
                if BlackScreenGUI then BlackScreenGUI.Enabled = false end
                
                pcall(function() RunService:Set3dRenderingEnabled(true) end)
                Nexus:Notify({Title = "Saver Mode", Content = "Disabled", Type = "Warning"})
            end
        end
    })

    -- 2. FPS BOOST
    -- =========================================================
    -- FPS ULTRA BOOST (CPU & GPU SAVER)
    -- =========================================================
    MiscSection:Toggle({
        Text = "FPS Ultra Boost",
        Default = false,
        Callback = function(state)
            if state then
                Nexus:Notify({Title = "FPS Boost", Content = "Processing... Screen may freeze slightly."})
                
                task.spawn(function()
                    -- 1. Optimasi Global Settings (Rendering)
                    local Lighting = game:GetService("Lighting")
                    local Terrain = workspace:WaitForChild("Terrain")
                    
                    pcall(function()
                        -- Matikan Shadow & Efek Cahaya
                        Lighting.GlobalShadows = false
                        Lighting.FogEnd = 9e9 -- Hapus kabut
                        Lighting.Brightness = 0
                        
                        -- Hapus Efek Post-Processing (Blur, Bloom, SunRays)
                        for _, v in pairs(Lighting:GetChildren()) do
                            if v:IsA("PostEffect") or v:IsA("Atmosphere") or v:IsA("Sky") then
                                v:Destroy()
                            end
                        end

                        -- Matikan Efek Air & Terrain
                        Terrain.WaterWaveSize = 0
                        Terrain.WaterWaveSpeed = 0
                        Terrain.WaterReflectance = 0
                        Terrain.WaterTransparency = 0
                        settings().Rendering.QualityLevel = 1
                        settings().Rendering.MeshPartDetailLevel = Enum.MeshPartDetailLevel.Level04
                    end)

                    -- 2. Optimasi Objek Workspace (Looping Cerdas)
                    -- Kita pakai wait() setiap 1000 part biar game gak crash/freeze total
                    local count = 0
                    for _, v in pairs(workspace:GetDescendants()) do
                        count = count + 1
                        if count % 1000 == 0 then task.wait() end -- Anti-Freeze

                        if v:IsA("BasePart") then
                            -- Ubah jadi plastik & hilangkan pantulan
                            v.Material = Enum.Material.SmoothPlastic
                            v.Reflectance = 0
                            v.CastShadow = false -- PENTING: Matikan bayangan per part
                            
                            -- Matikan Texture Terrain (Grass)
                            if v:IsA("Terrain") then 
                                v.Decoration = false 
                            end
                            
                        elseif v:IsA("Decal") or v:IsA("Texture") then
                            -- Hapus gambar tempelan
                            v.Transparency = 1
                            
                        elseif v:IsA("ParticleEmitter") or v:IsA("Trail") or v:IsA("Smoke") or v:IsA("Fire") or v:IsA("Sparkles") then
                            -- Matikan efek partikel (Berat di GPU)
                            v.Enabled = false
                            
                        elseif v:IsA("MeshPart") then
                            -- Ubah material Mesh jadi halus
                            v.Material = Enum.Material.SmoothPlastic
                            v.Reflectance = 0
                            v.TextureID = "" -- Hapus tekstur mesh (Opsional, bikin jadi abu-abu)
                        end
                    end
                    
                    Nexus:Notify({Title = "FPS Boost", Content = "Ultra Boost Applied!", Type = "Success"})
                end)
            else
                Nexus:Notify({Title = "FPS Boost", Content = "Rejoin to revert changes.", Type = "Warning"})
            end
        end
    })

    MiscSection:Toggle({
        Text = "CPU Saver (Freeze World)",
        Default = false,
        Callback = function(state)
            if state then
                Nexus:Notify({Title = "CPU Saver", Content = "Freezing Physics & Cleaning Characters..."})
                
                task.spawn(function()
                    local LocalPlayer = game:GetService("Players").LocalPlayer
                    local MyChar = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
                    
                    -- 1. BEKUKAN MAP (MATIKAN FISIKA)
                    -- Ini menghentikan kalkulasi gravitasi & collision untuk objek map
                    for _, v in pairs(workspace:GetDescendants()) do
                        -- Cek apakah object ini bagian dari Karakter Kita? (Jangan dibekukan)
                        if v:IsA("BasePart") and not v:IsDescendantOf(MyChar) then
                            v.Anchored = true 
                            v.CanTouch = false -- Matikan event .Touched (Hemat CPU banget)
                            
                            -- Opsional: Matikan CanCollide untuk object kecil biar gak nyangkut
                            if v.Size.Magnitude < 5 then
                                v.CanCollide = false
                            end
                        end
                    end

                    -- 2. HAPUS BEBAN KARAKTER LAIN (ENTITY OPTIMIZER)
                    for _, player in pairs(game:GetService("Players"):GetPlayers()) do
                        if player ~= LocalPlayer and player.Character then
                            local char = player.Character
                            
                            -- Hapus Aksesoris (Sayap, Topi, Tas) -> Mengurangi Part Count
                            for _, acc in pairs(char:GetChildren()) do
                                if acc:IsA("Accessory") or acc:IsA("Shirt") or acc:IsA("Pants") then
                                    acc:Destroy()
                                end
                            end
                            
                            -- Matikan Animasi Orang Lain (Berat di CPU)
                            local animate = char:FindFirstChild("Animate")
                            if animate then animate:Destroy() end
                            
                            -- Ubah jadi kotak polos (R6/R15 Simplified)
                            for _, part in pairs(char:GetChildren()) do
                                if part:IsA("BasePart") then
                                    part.Material = Enum.Material.SmoothPlastic
                                    part.Reflectance = 0
                                end
                            end
                        end
                    end
                    
                    Nexus:Notify({Title = "CPU Saver", Content = "World Frozen & Entities Cleaned!", Type = "Success"})
                end)
            end
        end
    })

    local AutoClaimPirate = false
    
    MiscSection:Toggle({
        Text = "Auto Claim Pirate Doubloons",
        Default = false,
        Callback = function(state)
            AutoClaimPirate = state
            
            if state then
                task.spawn(function()
                    local NPCs = {
                        "Alien Merchant", "Billy Bob", "Seth", "Joe", "Aura Kid", 
                        "Boat Expert", "Scott", "Ron", "Jeffery", "McBoatson", 
                        "Scientist", "Silly Fisherman", "Tim", "Pierre", "Phineas"
                    }
                    
                    -- 1. Cari Remote dengan Path Aman (Loop Search jika belum ketemu)
                    local Remote = nil
                    local attempt = 0
                    
                    while not Remote and attempt < 10 do
                        local s, r = pcall(function()
                            return game:GetService("ReplicatedStorage")
                                .Packages._Index["sleitnick_net@0.2.0"]
                                .net["RF/SpecialDialogueEvent"]
                        end)
                        if s and r then Remote = r end
                        attempt = attempt + 1
                        task.wait(0.5)
                    end

                    if not Remote then 
                        Nexus:Notify({Title = "Error", Content = "Remote Gagal Dimuat!", Type = "Error"})
                        AutoClaimPirate = false
                        return
                    end

                    -- 2. Debug Status (Hanya muncul di F9 untuk konfirmasi)
                    warn("[PIRATE] Remote Found: " .. Remote.Name .. " [" .. Remote.ClassName .. "]")

                    -- 3. Main Loop
                    while AutoClaimPirate do
                        for _, npc in ipairs(NPCs) do
                            if not AutoClaimPirate then break end
                            
                            -- Safe Execution: Cek apakah InvokeServer ada di object tersebut
                            pcall(function()
                                if Remote.ClassName == "RemoteFunction" then
                                    -- Coba string "PirateDoubloons" (Default)
                                    Remote:InvokeServer(npc, "PirateDoubloons")
                                    
                                    -- Opsional: Spam juga string lama/alternatif jaga-jaga
                                    -- Remote:InvokeServer(npc, "PirateGold") 
                                elseif Remote.ClassName == "RemoteEvent" then
                                    Remote:FireServer(npc, "PirateDoubloons")
                                end
                            end)
                            
                            task.wait(0.1) -- Delay aman biar gak kena rate limit
                        end
                        task.wait(2.5) -- Loop ulang setiap 2.5 detik
                    end
                end)
                Nexus:Notify({Title = "Pirate Event", Content = "Farming Started!", Type = "Success"})
            else
                Nexus:Notify({Title = "Pirate Event", Content = "Stopped", Type = "Info"})
            end
        end
    })

    local LynxMonitor = {}
    local LynxUI = nil
    local LynxConnections = {}

    local function CreateLynxPanel()
        if LynxUI then return LynxUI end
        
        local Screen = Instance.new("ScreenGui")
        Screen.Name = "NPN_StatsPanel"
        Screen.ResetOnSpawn = false
        pcall(function() Screen.Parent = CoreGui end)
        if not Screen.Parent then Screen.Parent = LocalPlayer:WaitForChild("PlayerGui") end
        
        local Container = Instance.new("Frame", Screen)
        Container.Size = UDim2.new(0, 190, 0, 65)
        Container.Position = UDim2.new(0, 50, 0.5, -32)
        Container.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
        Container.BackgroundTransparency = 0.2
        
        Instance.new("UICorner", Container).CornerRadius = UDim.new(0, 8)
        local Stroke = Instance.new("UIStroke", Container)
        Stroke.Color = Color3.fromRGB(255, 140, 50)
        Stroke.Thickness = 1.5
        Stroke.Transparency = 0.4
        
        -- Header
        local Header = Instance.new("Frame", Container)
        Header.Size = UDim2.new(1, 0, 0, 30)
        Header.BackgroundTransparency = 1
        
        local Title = Instance.new("TextLabel", Header)
        Title.Size = UDim2.new(1, -10, 1, 0)
        Title.Position = UDim2.new(0, 10, 0, 0)
        Title.BackgroundTransparency = 1
        Title.Text = "NPN HUB STATS"
        Title.TextColor3 = Color3.fromRGB(255, 140, 50)
        Title.TextSize = 12
        Title.Font = Enum.Font.GothamBold
        Title.TextXAlignment = Enum.TextXAlignment.Left
        
        -- Content
        local PingLbl = Instance.new("TextLabel", Container)
        PingLbl.Size = UDim2.new(0.5, -10, 0, 20)
        PingLbl.Position = UDim2.new(0, 10, 0, 35)
        PingLbl.BackgroundTransparency = 1
        PingLbl.Text = "Ping: --"
        PingLbl.TextColor3 = Color3.new(1,1,1)
        PingLbl.Font = Enum.Font.GothamBold
        PingLbl.TextSize = 12
        PingLbl.TextXAlignment = Enum.TextXAlignment.Left
        
        local FpsLbl = Instance.new("TextLabel", Container)
        FpsLbl.Size = UDim2.new(0.5, -10, 0, 20)
        FpsLbl.Position = UDim2.new(0.5, 0, 0, 35)
        FpsLbl.BackgroundTransparency = 1
        FpsLbl.Text = "FPS: --"
        FpsLbl.TextColor3 = Color3.new(1,1,1)
        FpsLbl.Font = Enum.Font.GothamBold
        FpsLbl.TextSize = 12
        FpsLbl.TextXAlignment = Enum.TextXAlignment.Right
        
        -- Drag Logic
        local dragging, dragInput, dragStart, startPos
        Container.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                dragging = true
                dragStart = input.Position
                startPos = Container.Position
            end
        end)
        Container.InputChanged:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseMovement then dragInput = input end
        end)
        UserInputService.InputChanged:Connect(function(input)
            if input == dragInput and dragging then
                local delta = input.Position - dragStart
                Container.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
            end
        end)
        UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
        end)
        
        LynxUI = {Screen = Screen, PingLbl = PingLbl, FpsLbl = FpsLbl}
        return LynxUI
    end

    MiscSection:Toggle({
        Text = "Show Ping & FPS Panel",
        Default = false,
        Callback = function(state)
            if state then
                local ui = CreateLynxPanel()
                ui.Screen.Enabled = true
                
                -- Update Loop
                local lastTick = tick()
                local c1 = RunService.RenderStepped:Connect(function()
                    local fps = math.floor(1 / (tick() - lastTick))
                    lastTick = tick()
                    ui.FpsLbl.Text = "FPS: " .. fps
                    ui.FpsLbl.TextColor3 = fps > 50 and Color3.fromRGB(100,255,100) or Color3.fromRGB(255,100,100)
                end)
                
                local c2 = RunService.Heartbeat:Connect(function()
                    local ping = math.floor(LocalPlayer:GetNetworkPing() * 1000 * 2) -- Est. Ping
                    ui.PingLbl.Text = "Ping: " .. ping .. "ms"
                    ui.PingLbl.TextColor3 = ping < 100 and Color3.fromRGB(100,255,100) or Color3.fromRGB(255,100,100)
                end)
                
                table.insert(LynxConnections, c1)
                table.insert(LynxConnections, c2)
                Nexus:Notify({Title = "Panel", Content = "Shown"})
            else
                if LynxUI then LynxUI.Screen.Enabled = false end
                for _, c in pairs(LynxConnections) do c:Disconnect() end
                LynxConnections = {}
                Nexus:Notify({Title = "Panel", Content = "Hidden"})
            end
        end
    })

    -- =========================================================
    -- STAFF DETECTOR
    -- =========================================================
    local AntiStaffSection = SettingsTab:Collapsible("Security (Anti-Staff)")
    
    local StaffList = {40397833, 75974130} -- Tambah ID di sini
    local GameGroupID = 121864768012064 
    local MinStaffRank = 200 
    
    local function IsStaff(p)
        if table.find(StaffList, p.UserId) then return true end
        local s, rank = pcall(function() return p:GetRankInGroup(GameGroupID) end)
        if s and rank and rank >= MinStaffRank then return true end
        if p.Name:lower():find("admin") or p.Name:lower():find("mod") then return true end -- Optional
        return false
    end
    
    local AntiStaffConn = nil
    
    AntiStaffSection:Toggle({
        Text = "Staff Detector (Auto Kick)",
        Default = false,
        Callback = function(state)
            if state then
                -- Cek existing players
                for _, p in ipairs(game.Players:GetPlayers()) do
                    if p ~= LocalPlayer and IsStaff(p) then
                        LocalPlayer:Kick("\n[NPN Security]\nStaff Detected: " .. p.Name)
                    end
                end
                
                -- Cek new players
                AntiStaffConn = game.Players.PlayerAdded:Connect(function(p)
                    if IsStaff(p) then
                        LocalPlayer:Kick("\n[NPN Security]\nStaff Detected: " .. p.Name)
                    end
                end)
                Nexus:Notify({Title = "Security", Content = "Monitoring Staff...", Type = "Info"})
            else
                if AntiStaffConn then AntiStaffConn:Disconnect() end
                Nexus:Notify({Title = "Security", Content = "Disabled", Type = "Warning"})
            end
        end
    })
end

local WebhookManager = (function()
    -- [[ PASTE KODE MODULE ANDA DI SINI (SAYA SUDAH RAPIKAN SEDIKIT) ]]
    local WebhookModule = {}
    local Players = game:GetService("Players")
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local HttpService = game:GetService("HttpService")
    local LocalPlayer = Players.LocalPlayer
    
    -- 1. FUNGSI PENCARI HTTP REQUEST (Supaya support semua Executor)
    local function getHTTPRequest()
        local requestFunctions = {
            request,
            http_request,
            (syn and syn.request),
            (fluxus and fluxus.request),
            (http and http.request),
            (solara and solara.request)
        }
        
        for _, func in ipairs(requestFunctions) do
            if func and type(func) == "function" then
                return func
            end
        end
        return nil
    end

    local httpRequest = getHTTPRequest()

    -- 2. FUNGSI SEND (Menggunakan style kodemu)
    local function sendExploitWebhook(url, username, embed_data, content_msg)
        -- Cek dulu apakah executor support
        if not httpRequest then
            return false, "Executor not supported (No HTTP Request)"
        end

        local payload = {
            username = username,
            content = content_msg or "", 
            embeds = {embed_data} 
        }
        
        local json_data = HttpService:JSONEncode(payload)
        
        local success, response = pcall(function()
            return httpRequest({ -- Pakai variabel httpRequest yang sudah dicari di atas
                Url = url,
                Method = "POST",
                Headers = { ["Content-Type"] = "application/json" },
                Body = json_data
            })
        end)
        
        if success and response then
            -- 200 = OK, 204 = No Content (Sukses tapi ga ada balasan body, standar Discord)
            if response.StatusCode == 200 or response.StatusCode == 204 then
                return true, "Sent"
            else
                return false, "Failed: " .. tostring(response.StatusCode)
            end
        elseif not success then
            return false, "Error: " .. tostring(response)
        end
        
        return false, "Unknown Error"
    end
    
    WebhookModule.Config = {
        WebhookURL = "",
        DiscordUserID = "",
        EnabledRarities = {}, -- Default kosong (semua mati)
    }

    local Items, Variants
    local TIER_NAMES = {[1]="Common",[2]="Uncommon",[3]="Rare",[4]="Epic",[5]="Legendary",[6]="Mythic",[7]="SECRET"}
    local TIER_COLORS = {[1]=9807270,[2]=3066993,[3]=3447003,[4]=10181046,[5]=15844367,[6]=15548997,[7]=16711680}
    local isRunning = false
    local eventConnection = nil

    local function loadGameModules()
        local success, err = pcall(function()
            -- Coba cari Items & Variants (Fisch/Fish It logic)
            if ReplicatedStorage:FindFirstChild("Items") then Items = require(ReplicatedStorage.Items) end
            if ReplicatedStorage:FindFirstChild("Variants") then Variants = require(ReplicatedStorage.Variants) end
        end)
        return success
    end

    local function getDiscordImageUrl(assetId)
        if not assetId then return "https://i.imgur.com/8yZqFqM.png" end
        -- Fallback cepat tanpa API request biar tidak lag
        return string.format("https://tr.rbxcdn.com/180DAY-%s/420/420/Image/Png", tostring(assetId))
    end

    local function getFishImageUrl(fish)
        local assetId = nil
        if fish.Data.Icon then assetId = tostring(fish.Data.Icon):match("%d+")
        elseif fish.Data.ImageId then assetId = tostring(fish.Data.ImageId)
        elseif fish.Data.Image then assetId = tostring(fish.Data.Image):match("%d+") end
        return getDiscordImageUrl(assetId)
    end

    local function getFish(itemId)
        if not Items then return nil end
        for _, f in pairs(Items) do if f.Data and f.Data.Id == itemId then return f end end
    end

    local function getVariant(id)
        if not id or not Variants then return nil end
        for _, v in pairs(Variants) do 
            if v.Data and (tostring(v.Data.Id) == tostring(id) or tostring(v.Data.Name) == tostring(id)) then return v end 
        end
        return nil
    end

    local function send(fish, meta, extra)
        if not WebhookModule.Config.WebhookURL or WebhookModule.Config.WebhookURL == "" then return end
        
        local tier = TIER_NAMES[fish.Data.Tier] or "Unknown"
        local color = TIER_COLORS[fish.Data.Tier] or 3447003

        -- FILTER CHECK
        local allowed = false
        if #WebhookModule.Config.EnabledRarities > 0 then
            for _, t in ipairs(WebhookModule.Config.EnabledRarities) do
                if t == tier then allowed = true break end
            end
        else
            allowed = false -- Jika tidak ada rarity dipilih, jangan kirim apa-apa
        end
        if not allowed then return end

        local mutationText = "None"
        local finalPrice = fish.SellPrice or 0
        local variantId = (extra and (extra.Variant or extra.Mutation or extra.VariantId)) or (meta and (meta.Variant or meta.Mutation))
        local isShiny = (meta and meta.Shiny) or (extra and extra.Shiny)

        if isShiny then mutationText = "Shiny"; finalPrice = finalPrice * 2 end
        if variantId then
            local v = getVariant(variantId)
            if v then mutationText = v.Data.Name .. " (" .. v.SellMultiplier .. "x)"; finalPrice = finalPrice * v.SellMultiplier
            else mutationText = tostring(variantId) end
        end

        local payload = {
            embeds = {{
                title = "🎣 Fish Caught!",
                description = string.format("User: ||%s||\nHas caught a **%s** fish!", LocalPlayer.Name, tier),
                color = color,
                fields = {
                    {name="Fish Name", value=fish.Data.Name, inline=true},
                    {name="Rarity", value=tier, inline=true},
                    {name="Weight", value=string.format("%.1f kg", meta.Weight or 0), inline=true},
                    {name="Mutation", value=mutationText, inline=true},
                    {name="Value", value="$"..math.floor(finalPrice), inline=true}
                },
                thumbnail = { url = getFishImageUrl(fish) },
                footer = { text = "Nexus Webhook System" },
                timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")
            }}
        }
        
        if WebhookModule.Config.DiscordUserID ~= "" then
            payload.content = "<@"..WebhookModule.Config.DiscordUserID..">"
        end

        pcall(function()
            httpRequest({
                Url = WebhookModule.Config.WebhookURL, Method = "POST",
                Headers = {["Content-Type"] = "application/json"},
                Body = HttpService:JSONEncode(payload)
            })
        end)
    end

    function WebhookModule:Start()
        if isRunning then return true end
        if not httpRequest then return false end
        loadGameModules()

        -- Cari Remote yang benar
        local success, Event = pcall(function()
            return ReplicatedStorage.Packages._Index["sleitnick_net@0.2.0"].net["RE/ObtainedNewFishNotification"]
        end)

        if not success or not Event then return false end

        eventConnection = Event.OnClientEvent:Connect(function(itemId, metadata, extraData)
            local fish = getFish(itemId)
            if fish then task.spawn(function() send(fish, metadata, extraData) end) end
        end)

        isRunning = true
        return true
    end

    function WebhookModule:Stop()
        if eventConnection then eventConnection:Disconnect() eventConnection = nil end
        isRunning = false
    end

    return WebhookModule
end)()

-- =================================================================
-- TAB: WEBHOOK UI IMPLEMENTATION (NEXUS UI)
-- =================================================================
do
    local WebhookTab = Window:Tab({Text = "Webhook", Icon = "📢"}) -- Icon Link
    local WebhookSection = WebhookTab:Collapsible("Discord Settings")

    -- 1. STATUS CHECK
    if not identifyexecutor then
        WebhookSection:Label({Text = "Warning: Executor might not support HTTP Requests.", Color = Color3.fromRGB(255, 100, 100)})
    end

    -- 2. URL INPUT
    WebhookSection:Input({
        Text = "Webhook URL",
        Placeholder = "https://discord.com/api/webhooks/...",
        Callback = function(url)
            WebhookManager.Config.WebhookURL = url
        end
    })

    -- 3. USER ID INPUT
    WebhookSection:Input({
        Text = "Discord User ID (For Ping)",
        Placeholder = "1234567890",
        Callback = function(id)
            WebhookManager.Config.DiscordUserID = id
        end
    })

    -- 4. RARITY FILTER (MULTI SELECT)
    WebhookSection:Dropdown({
        Text = "Select Rarities to Send",
        Options = {"Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic", "SECRET"},
        MultiSelect = true,
        Default = {"Legendary", "Mythic", "SECRET"}, -- Default yang mahal saja biar gak spam
        Callback = function(selected)
            WebhookManager.Config.EnabledRarities = selected or {}
        end
    })

    -- 5. ENABLE TOGGLE
    WebhookSection:Toggle({
        Text = "Enable Webhook Notification",
        Default = false,
        Callback = function(state)
            if state then
                if WebhookManager.Config.WebhookURL == "" then
                    Nexus:Notify({Title = "Error", Content = "Masukkan Webhook URL terlebih dahulu!", Type = "Error"})
                    -- Secara visual toggle mungkin tetap nyala, tapi logic tidak jalan
                    return
                end
                
                local started = WebhookManager:Start()
                if started then
                    Nexus:Notify({Title = "Webhook", Content = "Service Started!", Type = "Success"})
                else
                    Nexus:Notify({Title = "Error", Content = "Gagal memulai service (Remote not found / Exec not support)", Type = "Error"})
                end
            else
                WebhookManager:Stop()
                Nexus:Notify({Title = "Webhook", Content = "Service Stopped", Type = "Warning"})
            end
        end
    })
    
    -- 6. TEST BUTTON
    WebhookSection:Button({
        Text = "Test Webhook (Fake Data)",
        Callback = function()
             if WebhookManager.Config.WebhookURL == "" then
                Nexus:Notify({Title="Error", Content="No URL Provided", Type="Error"})
                return
            end
            
            -- Kirim test ping manual
            local HttpService = game:GetService("HttpService")
            local request = (syn and syn.request) or (http and http.request) or http_request or (fluxus and fluxus.request) or request
            if request then
                request({
                    Url = WebhookManager.Config.WebhookURL,
                    Method = "POST",
                    Headers = {["Content-Type"] = "application/json"},
                    Body = HttpService:JSONEncode({
                        content = "🔔 **Test Notification from Nexus Hub**\nWebhook is working correctly!"
                    })
                })
                Nexus:Notify({Title="Sent", Content="Check your discord!", Type="Success"})
            else
                Nexus:Notify({Title="Error", Content="Executor not supported", Type="Error"})
            end
        end
    })
end
