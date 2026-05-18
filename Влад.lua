--[[
    ALTRON PIN-PAD LOGIN SYSTEM
]]


local CoreGui = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")
local HWID = game:GetService("RbxAnalyticsService"):GetClientId()


local function StartCheat()
    print("Авторизация успешна! Запуск LebroTools...")
    
    local Players = game:GetService("Players")
    local RunService = game:GetService("RunService")
    local Workspace = game:GetService("Workspace")
    local Lighting = game:GetService("Lighting")
    local SoundService = game:GetService("SoundService")
    local LocalPlayer = Players.LocalPlayer
    local Camera = Workspace.CurrentCamera

    -- Все настройки
    local Toggles = {
        -- Combat / Aimbot
        SilentAim = false, DrawFov = false, DynamicFov = false, FovRadius = 150,
        IgnoreFriends = false, IgnoreClan = false, OnlyOnHit = false, HitSound = false,
        -- Weapon
        NoRecoil = false, NoSpread = false, MaxVel = false, ZeroGrav = false,
        -- Visuals / ESP
        PlayerEsp = false, VisCheck = false, EspMaxDist = 2000, SmoothSpeed = 8.00,
        EspName = false, EspDistance = false, EspWeapon = false, EspSkeleton = false, EspCount = false,
        FontSize = 16.00, EspBox = false, EspHealth = false,
        EspLines = false, LineThickness = 0.80, TargetMarker = false,
        InventoryViewer = false,
        -- World
        CustomSky = false, Fullbright = false, NoGrass = false, NoLeaves = false,
        HempEsp = false, CrateEsp = false, BpEsp = false, TcEsp = false,
        -- Misc
        AutoOre = false, AutoTree = false
    }

    local Cache = { PlayerVisuals = {}, WorldInstances = {}, SilentTarget = nil, ToolModHooked = false, OriginalLighting = {} }

    -- [ ФОВ И ЦЕЛЬ ] --
    local UI_Elements = { FovCircle = Drawing.new("Circle"), TargetDot = Drawing.new("Circle") }
    UI_Elements.FovCircle.Thickness = 1; UI_Elements.FovCircle.NumSides = 64; 
    UI_Elements.FovCircle.Filled = false; UI_Elements.FovCircle.Color = Color3.fromRGB(255, 255, 255); UI_Elements.FovCircle.Visible = false
    UI_Elements.TargetDot.Radius = 5; UI_Elements.TargetDot.Thickness = 1; UI_Elements.TargetDot.Color = Color3.fromRGB(255, 0, 127); UI_Elements.TargetDot.Filled = true; UI_Elements.TargetDot.Visible = false

    local EspGui = Instance.new("ScreenGui")
    EspGui.Name = "LebroToolsGUI"
    pcall(function() EspGui.Parent = CoreGui end)
    if not EspGui.Parent then EspGui.Parent = LocalPlayer:WaitForChild("PlayerGui") end

    ----------------------------------------------------------------
    -- [ КНОПКА СКРЫТИЯ МЕНЮ ] --
    ----------------------------------------------------------------
    local ToggleBtn = Instance.new("TextButton", EspGui)
    ToggleBtn.Size = UDim2.new(0, 50, 0, 50)
    ToggleBtn.Position = UDim2.new(0, 15, 0, 15)
    ToggleBtn.BackgroundColor3 = Color3.fromRGB(75, 75, 75)
    ToggleBtn.Text = "A"
    ToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    ToggleBtn.Font = Enum.Font.SourceSansBold
    ToggleBtn.TextSize = 28
    Instance.new("UICorner", ToggleBtn).CornerRadius = UDim.new(0, 5)
    local ToggleStroke = Instance.new("UIStroke", ToggleBtn)
    ToggleStroke.Color = Color3.fromRGB(150, 150, 150)
    ToggleStroke.Thickness = 1

    ----------------------------------------------------------------
    -- [ INVENTORY VIEWER ] --
    ----------------------------------------------------------------
    local InvFrame = Instance.new("Frame", EspGui)
    InvFrame.Size = UDim2.new(0, 280, 0, 360)
    InvFrame.Position = UDim2.new(1, -300, 0.5, -180)
    InvFrame.BackgroundColor3 = Color3.fromRGB(65, 65, 65)
    InvFrame.Visible = false
    Instance.new("UICorner", InvFrame)
    Instance.new("UIStroke", InvFrame).Color = Color3.fromRGB(150, 150, 150)

    local InvTitle = Instance.new("TextLabel", InvFrame)
    InvTitle.Size = UDim2.new(1, 0, 0, 40)
    InvTitle.Text = " ИНВЕНТАРЬ ЦЕЛИ"
    InvTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
    InvTitle.Font = Enum.Font.SourceSansBold
    InvTitle.TextSize = 16
    InvTitle.TextXAlignment = Enum.TextXAlignment.Left
    InvTitle.BackgroundColor3 = Color3.fromRGB(55, 55, 55)
    Instance.new("UICorner", InvTitle)

    local InvList = Instance.new("ScrollingFrame", InvFrame)
    InvList.Size = UDim2.new(1, -10, 1, -50)
    InvList.Position = UDim2.new(0, 5, 0, 45)
    InvList.BackgroundTransparency = 1
    InvList.ScrollBarThickness = 4
    local InvLayout = Instance.new("UIGridLayout", InvList)
    InvLayout.CellSize = UDim2.new(0, 60, 0, 60)
    InvLayout.CellPadding = UDim2.new(0, 6, 0, 6)

    local function UpdateInventory(player)
        for _, v in pairs(InvList:GetChildren()) do if v:IsA("Frame") then v:Destroy() end end
        if not player or not player.Character then return end
        InvTitle.Text = " ИНВ.: " .. player.Name:upper()
        local items = {}
        local function parseItem(tool, isUsing)
            local id = (tool.TextureId and tool.TextureId ~= "" and tool.TextureId) or nil
            local name = tool.Name
            local key = name .. (id or "")
            if items[key] then
                items[key].Count = items[key].Count + 1
                if isUsing then items[key].Using = true end
            else
                items[key] = {Name = name, Tex = id, Count = 1, Using = isUsing}
            end
        end

        if player.Character then for _, t in pairs(player.Character:GetChildren()) do if t:IsA("Tool") then parseItem(t, true) end end end
        local bp = player:FindFirstChild("Backpack")
        if bp then for _, t in pairs(bp:GetChildren()) do if t:IsA("Tool") then parseItem(t, false) end end end

        for _, data in pairs(items) do
            local Slot = Instance.new("Frame", InvList)
            Slot.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
            Instance.new("UICorner", Slot).CornerRadius = UDim.new(0, 4)
            if data.Tex then
                local Img = Instance.new("ImageLabel", Slot)
                Img.Size = UDim2.new(1, -4, 1, -4); Img.Position = UDim2.new(0, 2, 0, 2)
                Img.BackgroundTransparency = 1; Img.ScaleType = Enum.ScaleType.Fit; Img.Image = data.Tex
            else
                local Txt = Instance.new("TextLabel", Slot)
                Txt.Size = UDim2.new(1, 0, 1, 0); Txt.BackgroundTransparency = 1
                Txt.Text = data.Name; Txt.TextColor3 = Color3.fromRGB(200, 200, 200); Txt.Font = Enum.Font.SourceSans; Txt.TextSize = 12; Txt.TextWrapped = true
            end
            if data.Count > 1 then
                local Cnt = Instance.new("TextLabel", Slot)
                Cnt.Size = UDim2.new(0, 24, 0, 18); Cnt.Position = UDim2.new(1, -24, 1, -18)
                Cnt.BackgroundColor3 = Color3.fromRGB(40, 40, 40); Cnt.BackgroundTransparency = 0.5
                Cnt.Text = "x" .. data.Count; Cnt.TextColor3 = Color3.fromRGB(255, 255, 255); Cnt.Font = Enum.Font.SourceSansBold; Cnt.TextSize = 12
                Instance.new("UICorner", Cnt)
            end
            if data.Using then
                local Usg = Instance.new("TextLabel", Slot)
                Usg.Size = UDim2.new(1, 0, 0, 14); Usg.Position = UDim2.new(0, 0, 0, 0)
                Usg.BackgroundColor3 = Color3.fromRGB(150, 150, 150); Usg.BackgroundTransparency = 0.2
                Usg.Text = "В РУКАХ"; Usg.TextColor3 = Color3.fromRGB(255, 255, 255); Usg.Font = Enum.Font.SourceSansBold; Usg.TextSize = 10
                Instance.new("UICorner", Usg)
            end
        end
    end

    ----------------------------------------------------------------
    -- [ LEBROTOOLS МЕНЮ ] --
    ----------------------------------------------------------------
    local Main = Instance.new("Frame", EspGui)
    Main.Size = UDim2.new(0, 850, 0, 480) 
    Main.Position = UDim2.new(0.5, -425, 0.5, -240)
    Main.BackgroundColor3 = Color3.fromRGB(85, 85, 85)
    Main.BorderSizePixel = 0
    Main.Visible = true -- ИСПРАВЛЕНИЕ: гарантированно делаем меню видимым при запуске
    local MainStroke = Instance.new("UIStroke", Main)
    MainStroke.Color = Color3.fromRGB(120, 120, 120)
    MainStroke.Thickness = 1

    ToggleBtn.MouseButton1Click:Connect(function() Main.Visible = not Main.Visible end)

    local TopBar = Instance.new("Frame", Main)
    TopBar.Size = UDim2.new(1, 0, 0, 35) 
    TopBar.BackgroundColor3 = Color3.fromRGB(75, 75, 75)
    TopBar.BorderSizePixel = 0
    local TopBarLine = Instance.new("Frame", TopBar)
    TopBarLine.Size = UDim2.new(1, 0, 0, 1)
    TopBarLine.Position = UDim2.new(0, 0, 1, 0)
    TopBarLine.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
    TopBarLine.BorderSizePixel = 0

    local Title = Instance.new("TextLabel", TopBar)
    Title.Size = UDim2.new(0, 100, 1, 0)
    Title.Position = UDim2.new(0, 10, 0, 0)
    Title.Text = "LebroTools"
    Title.TextColor3 = Color3.fromRGB(255, 255, 255)
    Title.Font = Enum.Font.SourceSans
    Title.TextSize = 20 
    Title.TextXAlignment = Enum.TextXAlignment.Left
    Title.BackgroundTransparency = 1

    local TabContainer = Instance.new("Frame", TopBar)
    TabContainer.Size = UDim2.new(1, -110, 1, 0)
    TabContainer.Position = UDim2.new(0, 110, 0, 0)
    TabContainer.BackgroundTransparency = 1
    local TabList = Instance.new("UIListLayout", TabContainer)
    TabList.FillDirection = Enum.FillDirection.Horizontal
    TabList.Padding = UDim.new(0, 16)

    local ContentArea = Instance.new("Frame", Main)
    ContentArea.Size = UDim2.new(1, 0, 1, -36)
    ContentArea.Position = UDim2.new(0, 0, 0, 36)
    ContentArea.BackgroundTransparency = 1

    local Tabs = {}
    local TabBtns = {}

    local function SelectTab(name)
        for n, f in pairs(Tabs) do f.Visible = (n == name) end
        for n, b in pairs(TabBtns) do
            b.TextColor3 = (n == name) and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(180, 180, 180)
        end
    end

    local function CreateTab(name)
        local btn = Instance.new("TextButton", TabContainer)
        btn.Size = UDim2.new(0, 0, 1, 0); btn.AutomaticSize = Enum.AutomaticSize.X
        btn.BackgroundTransparency = 1
        btn.Text = name; btn.Font = Enum.Font.SourceSans; btn.TextSize = 18 
        btn.TextColor3 = Color3.fromRGB(180, 180, 180)
        TabBtns[name] = btn

        local page = Instance.new("Frame", ContentArea)
        page.Size = UDim2.new(1, 0, 1, 0)
        page.BackgroundTransparency = 1
        page.Visible = false
        Tabs[name] = page

        btn.MouseButton1Click:Connect(function() SelectTab(name) end)
        return page
    end

    local function CreateSection(parent, title, x, y, w, h)
        local sec = Instance.new("Frame", parent)
        sec.Position = UDim2.new(0, x, 0, y)
        sec.Size = UDim2.new(0, w, 0, h)
        sec.BackgroundTransparency = 1

        local lbl = Instance.new("TextLabel", sec)
        lbl.Size = UDim2.new(1, 0, 0, 20)
        lbl.Text = title
        lbl.TextColor3 = Color3.fromRGB(220, 220, 220)
        lbl.Font = Enum.Font.SourceSans
        lbl.TextSize = 16 
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.BackgroundTransparency = 1

        local line = Instance.new("Frame", sec)
        line.Size = UDim2.new(1, 0, 0, 1)
        line.Position = UDim2.new(0, 0, 0, 24)
        line.BackgroundColor3 = Color3.fromRGB(110, 110, 110)
        line.BorderSizePixel = 0

        local container = Instance.new("Frame", sec)
        container.Size = UDim2.new(1, 0, 1, -28)
        container.Position = UDim2.new(0, 0, 0, 28)
        container.BackgroundTransparency = 1
        local layout = Instance.new("UIListLayout", container)
        layout.Padding = UDim.new(0, 8) 

        return container
    end

    local function AddCheckbox(parent, text, key, callback)
        local f = Instance.new("Frame", parent)
        f.Size = UDim2.new(1, 0, 0, 24) 
        f.BackgroundTransparency = 1

        local btn = Instance.new("TextButton", f)
        btn.Size = UDim2.new(0, 20, 0, 20) 
        btn.BackgroundColor3 = Color3.fromRGB(90, 90, 90)
        btn.BorderSizePixel = 0; btn.Text = ""
        btn.Position = UDim2.new(0, 0, 0.5, -10)

        local check = Instance.new("TextLabel", btn)
        check.Size = UDim2.new(1, 0, 1, 0)
        check.BackgroundTransparency = 1
        check.Text = "✓"; check.TextColor3 = Color3.fromRGB(255, 255, 255)
        check.Font = Enum.Font.SourceSansBold; check.TextSize = 18 
        check.Visible = Toggles[key]

        local lbl = Instance.new("TextLabel", f)
        lbl.Size = UDim2.new(1, -28, 1, 0)
        lbl.Position = UDim2.new(0, 28, 0, 0)
        lbl.BackgroundTransparency = 1
        lbl.Text = text; lbl.TextColor3 = Color3.fromRGB(220, 220, 220)
        lbl.Font = Enum.Font.SourceSans; lbl.TextSize = 16 
        lbl.TextXAlignment = Enum.TextXAlignment.Left

        btn.MouseButton1Click:Connect(function()
            Toggles[key] = not Toggles[key]
            check.Visible = Toggles[key]
            if callback then callback(Toggles[key]) end
        end)
    end

    local function AddSlider(parent, text, min, max, default, key, isFloat)
        local f = Instance.new("Frame", parent)
        f.Size = UDim2.new(1, 0, 0, 45) 
        f.BackgroundTransparency = 1

        local lbl = Instance.new("TextLabel", f)
        lbl.Size = UDim2.new(1, 0, 0, 18)
        lbl.BackgroundTransparency = 1
        lbl.Text = text; lbl.TextColor3 = Color3.fromRGB(220, 220, 220)
        lbl.Font = Enum.Font.SourceSans; lbl.TextSize = 16 
        lbl.TextXAlignment = Enum.TextXAlignment.Left

        local bar = Instance.new("Frame", f)
        bar.Size = UDim2.new(1, -10, 0, 20) 
        bar.Position = UDim2.new(0, 0, 0, 22)
        bar.BackgroundColor3 = Color3.fromRGB(110, 110, 110)
        bar.BorderSizePixel = 0

        local valText = Instance.new("TextLabel", bar)
        valText.Size = UDim2.new(1, 0, 1, 0)
        valText.BackgroundTransparency = 1
        valText.Text = isFloat and string.format("%.2f", default) or tostring(default)
        valText.TextColor3 = Color3.fromRGB(255, 255, 255)
        valText.Font = Enum.Font.SourceSansBold; valText.TextSize = 14; valText.ZIndex = 2 

        local knob = Instance.new("Frame", bar)
        knob.Size = UDim2.new(0, 12, 1, 4) 
        knob.Position = UDim2.new((default-min)/(max-min), -6, 0, -2)
        knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        knob.BorderSizePixel = 0; knob.ZIndex = 3

        local btn = Instance.new("TextButton", bar)
        btn.Size = UDim2.new(1, 0, 1, 0); btn.BackgroundTransparency = 1; btn.Text = ""

        local dragging = false
        btn.MouseButton1Down:Connect(function() dragging = true end)
        UserInputService.InputEnded:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end end)
        UserInputService.InputChanged:Connect(function(input)
            if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
                local pct = math.clamp((input.Position.X - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
                knob.Position = UDim2.new(pct, -6, 0, -2)
                local val = min + (max - min) * pct
                if not isFloat then val = math.floor(val) end
                valText.Text = isFloat and string.format("%.2f", val) or tostring(val)
                Toggles[key] = val
            end
        end)
    end

    ----------------------------------------------------------------
    -- [ ПОСТРОЕНИЕ ВЗЛАДОК ] --
    ----------------------------------------------------------------
    local tabColors = CreateTab("Colors")
    local tabAimbot = CreateTab("Aimbot")
    local tabWeapon = CreateTab("Weapon")
    local tabPlayer = CreateTab("Player")
    local tabESP = CreateTab("ESP")
    local tabWorld = CreateTab("World")
    local tabMisc = CreateTab("Misc")

    local col1, col2, col3 = 15, 295, 575
    local colW = 260

    -- Вкладка Aimbot
    local secGen = CreateSection(tabAimbot, "General", col1, 15, colW, 400)
    AddCheckbox(secGen, "Ignore Friends", "IgnoreFriends")
    AddCheckbox(secGen, "Ignore Clan", "IgnoreClan")
    AddCheckbox(secGen, "OnlyOnHit Bullet", "OnlyOnHit")
    AddCheckbox(secGen, "Play Hit Sound", "HitSound")

    local secAim = CreateSection(tabAimbot, "Aimbot", col2, 15, colW, 400)
    AddCheckbox(secAim, "Enable Aimbot", "SilentAim")

    local secFov = CreateSection(tabAimbot, "FOV Settings", col3, 15, colW, 400)
    AddCheckbox(secFov, "Draw FOV", "DrawFov")
    AddCheckbox(secFov, "Dynamic FOV", "DynamicFov")
    AddSlider(secFov, "FOV Radius", 50, 1500, 150, "FovRadius", false)

    -- Вкладка ESP
    local secEspMain = CreateSection(tabESP, "ESP Main", col1, 15, colW, 400)
    AddCheckbox(secEspMain, "Enable ESP", "PlayerEsp")
    AddCheckbox(secEspMain, "Visibility Check", "VisCheck")
    AddCheckbox(secEspMain, "Draw 2D Boxes", "EspBox")
    AddSlider(secEspMain, "Max Distance", 50, 5000, 2000.00, "EspMaxDist", true)
    AddSlider(secEspMain, "Smooth Speed", 1, 20, 8.00, "SmoothSpeed", true)

    local secDisplay = CreateSection(tabESP, "Display", col2, 15, colW, 400)
    AddCheckbox(secDisplay, "Show Names", "EspName")
    AddCheckbox(secDisplay, "Show Distance", "EspDistance")
    AddCheckbox(secDisplay, "Show Weapon", "EspWeapon")
    AddCheckbox(secDisplay, "Show Skeleton", "EspSkeleton")
    AddCheckbox(secDisplay, "Show Count", "EspCount")
    AddCheckbox(secDisplay, "Show Health", "EspHealth")
    AddSlider(secDisplay, "Font Size", 10, 40, 16.00, "FontSize", true)

    local secLines = CreateSection(tabESP, "Lines", col3, 15, colW, 400)
    AddCheckbox(secLines, "Show Line", "EspLines")
    AddSlider(secLines, "Line Thickness", 0.1, 5, 0.80, "LineThickness", true)
    AddCheckbox(secLines, "Target Marker", "TargetMarker")

    -- Вкладка Weapon
    local secWeapMods = CreateSection(tabWeapon, "Gun Modifications", col1, 15, colW, 400)
    AddCheckbox(secWeapMods, "No Recoil", "NoRecoil")
    AddCheckbox(secWeapMods, "No Spread", "NoSpread")
    AddCheckbox(secWeapMods, "Max Velocity", "MaxVel")
    AddCheckbox(secWeapMods, "Zero Gravity", "ZeroGrav")

    -- Вкладка Player
    local secPlyInfo = CreateSection(tabPlayer, "Player Info", col1, 15, colW, 400)
    AddCheckbox(secPlyInfo, "Target Inventory Viewer", "InventoryViewer")

    -- Вкладка World
    local secWorldChams = CreateSection(tabWorld, "Chams & Visuals", col1, 15, colW, 400)
    AddCheckbox(secWorldChams, "Hemp ESP", "HempEsp")
    AddCheckbox(secWorldChams, "Crates ESP", "CrateEsp")
    AddCheckbox(secWorldChams, "Death Backpacks", "BpEsp")
    AddCheckbox(secWorldChams, "Tool Cupboard", "TcEsp")

    local secWorldEnv = CreateSection(tabWorld, "Environment", col2, 15, colW, 400)
    AddCheckbox(secWorldEnv, "Fullbright", "Fullbright")
    AddCheckbox(secWorldEnv, "Custom Sky", "CustomSky")
    AddCheckbox(secWorldEnv, "Remove Grass", "NoGrass")
    AddCheckbox(secWorldEnv, "Remove Leaves", "NoLeaves")

    -- Вкладка Misc
    local secMiscFarm = CreateSection(tabMisc, "Farming", col1, 15, colW, 400)
    AddCheckbox(secMiscFarm, "Auto Hit Ore (Star)", "AutoOre")
    AddCheckbox(secMiscFarm, "Auto Hit Tree (Cross)", "AutoTree")

    SelectTab("Aimbot")

    ----------------------------------------------------------------
    -- [ WORLD, AUDIO & MODS ВНЕДРЕНИЕ ] --
    ----------------------------------------------------------------

    local function PlayHitSound()
        if not Toggles.HitSound then return end
        local sound = Instance.new("Sound", SoundService)
        sound.SoundId = "rbxassetid://135478009117226" -- ОБНОВЛЕННЫЙ ЗВУК
        sound.Volume = 3
        sound:Play()
        sound.Ended:Connect(function() sound:Destroy() end)
    end

    -- ИСПРАВЛЕННАЯ ЛОГИКА РЕГИСТРАЦИИ ПОПАДАНИЙ ПО ИГРОКУ
    local function SetupHitDetection(player)
        local function onCharacterAdded(char)
            local hum = char:WaitForChild("Humanoid", 5)
            if hum then
                local oldHealth = hum.Health
                hum.HealthChanged:Connect(function(newHealth)
                    if newHealth < oldHealth and Toggles.HitSound then
                        -- Если включен аим и мы стреляли по этому таргету, либо мы просто в кого-то попали
                        if Cache.SilentTarget and Cache.SilentTarget.Parent == char then
                            PlayHitSound()
                        end
                    end
                    oldHealth = newHealth
                end)
            end
        end
        
        player.CharacterAdded:Connect(onCharacterAdded)
        if player.Character then onCharacterAdded(player.Character) end
    end

    for _, p in pairs(Players:GetPlayers()) do 
        if p ~= LocalPlayer then SetupHitDetection(p) end 
    end
    Players.PlayerAdded:Connect(SetupHitDetection)

    local function UpdateEnv()
        if Toggles.Fullbright then Lighting.Ambient = Color3.fromRGB(255,255,255); Lighting.OutdoorAmbient = Color3.fromRGB(255,255,255); Lighting.GlobalShadows = false else Lighting.Ambient = Color3.fromRGB(127,127,127); Lighting.OutdoorAmbient = Color3.fromRGB(127,127,127); Lighting.GlobalShadows = true end
        if Workspace:FindFirstChild("Terrain") then Workspace.Terrain.Decoration = not Toggles.NoGrass end
        if Toggles.NoLeaves then local tr = Workspace:FindFirstChild("trees") or Workspace:FindFirstChild("Trees"); if tr then for _, i in ipairs(tr:GetDescendants()) do if i:IsA("BasePart") and (string.find(string.lower(i.Name), "leaf") or string.find(string.lower(i.Name), "leavestop")) then i.Transparency = 1; i.CanCollide = false end end end end
    end

    local function AddChams(inst, col, txt)
        if Cache.WorldInstances[inst] then return end
        local hl = Instance.new("Highlight", CoreGui); hl.Adornee = inst; hl.FillTransparency = 0.5; hl.FillColor = col
        local bg = Instance.new("BillboardGui", CoreGui); bg.Adornee = inst; bg.Size = UDim2.new(0, 100, 0, 20); bg.AlwaysOnTop = true
        local tl = Instance.new("TextLabel", bg); tl.Size = UDim2.new(1,0,1,0); tl.BackgroundTransparency = 1; tl.TextColor3 = col; tl.Text = txt; tl.Font = Enum.Font.SourceSansBold; tl.TextSize = 14
        Cache.WorldInstances[inst] = {H = hl, B = bg}
    end

    local function RefWEsp()
        for i, d in pairs(Cache.WorldInstances) do if d.H then d.H:Destroy() end; if d.B then d.B:Destroy() end end; table.clear(Cache.WorldInstances)
        if Toggles.HempEsp then local f = Workspace:FindFirstChild("Hemp"); if f then for _, i in ipairs(f:GetChildren()) do AddChams(i, Color3.fromRGB(0, 255, 0), "Hemp") end end end
        if Toggles.CrateEsp then local f = Workspace:FindFirstChild("crates") or Workspace:FindFirstChild("Crates"); if f then for _, i in ipairs(f:GetDescendants()) do if i.Name == "MilitaryCrate" or i.Name == "Crate" or i.Name == "ToolBox" then AddChams(i, Color3.fromRGB(255, 165, 0), i.Name) end end end end
        if Toggles.BpEsp then local f = Workspace:FindFirstChild("DeathBackpacks"); if f then for _, i in ipairs(f:GetChildren()) do AddChams(i, Color3.fromRGB(255, 0, 0), "Backpack") end end end
        if Toggles.TcEsp then local f = Workspace:FindFirstChild("Builds"); if f then for _, i in ipairs(f:GetDescendants()) do if i.Name == "ToolCupboardModel" then AddChams(i, Color3.fromRGB(0, 150, 255), "TC") end end end end
    end

    task.spawn(function()
        while task.wait(3) do
            UpdateEnv()
            RefWEsp()
            -- ОБНОВЛЕННОЕ КАСТОМНОЕ НЕБО (ID: 2758029221)
            if Toggles.CustomSky and not Lighting:FindFirstChild("LebroSky") then
                for _, obj in pairs(Lighting:GetChildren()) do if obj:IsA("Atmosphere") or obj:IsA("Sky") then table.insert(Cache.OriginalLighting, obj); obj.Parent = nil end end
                local s = Instance.new("Sky", Lighting); s.Name = "LebroSky"; 
                local id = "rbxassetid://2758029221"; 
                s.SkyboxBk = id; s.SkyboxDn = id; s.SkyboxFt = id; s.SkyboxLf = id; s.SkyboxRt = id; s.SkyboxUp = id
            elseif not Toggles.CustomSky and Lighting:FindFirstChild("LebroSky") then
                Lighting.LebroSky:Destroy()
                for _, obj in pairs(Cache.OriginalLighting) do obj.Parent = Lighting end; table.clear(Cache.OriginalLighting)
            end
        end
    end)

    task.spawn(function()
        while task.wait(1) do
            pcall(function()
                for _, v in pairs(getgc(true)) do
                    if type(v) == "table" then
                        if rawget(v, "getfireDirection") then
                            local old = v.getfireDirection
                            v.getfireDirection = function(self, origin, raycast)
                                if Toggles.SilentAim and Cache.SilentTarget then return (Cache.SilentTarget.Position - origin).Unit end
                                return old(self, origin, raycast)
                            end
                        end
                        if rawget(v, "BaseBulletVelocity") and Toggles.MaxVel then v.BaseBulletVelocity = 999999; v.Velocity = 999999 end
                        if rawget(v, "BulletGravity") and Toggles.ZeroGrav then v.BulletGravity = 0; v.Gravity = 0 end
                        if rawget(v, "TotalAttachmentStats") then
                            local s = v.TotalAttachmentStats
                            if Toggles.NoSpread then s.SpreadMult = 0; s.PelletSpread = 0 end
                            if Toggles.NoRecoil then s.RecoilMult = 0; s.KickMult = 0 end
                        end
                        if rawget(v, "hit") and not Cache.ToolModHooked then
                            local oldH = v.hit
                            v.hit = function(self, inst, pos)
                                local tI, tP = inst, pos
                                if Toggles.AutoOre or Toggles.AutoTree then
                                    local c = self.OwnerPlayer and self.OwnerPlayer.Character
                                    if c and c:FindFirstChild("HumanoidRootPart") then
                                        local mp = c.HumanoidRootPart.Position; local cp, md = nil, 20
                                        for _, obj in ipairs(Workspace:GetDescendants()) do
                                            if obj:IsA("BasePart") and ((obj.Name == "star" and Toggles.AutoOre) or (obj.Name == "cross" and Toggles.AutoTree)) then
                                                local d = (mp - obj.Position).Magnitude; if d < md then cp = obj; md = d end
                                            end
                                        end
                                        if cp then tI = cp; tP = cp.Position end
                                    end
                                end
                                return oldH(self, tI, tP)
                            end
                            Cache.ToolModHooked = true
                        end
                    end
                end
            end)
        end
    end)

    ----------------------------------------------------------------
    -- [ ESP & SILENT AIM ENGINE ] --
    ----------------------------------------------------------------

    local function CreateEsp(player)
        local obj = {
            Box = Drawing.new("Square"), BoxOut = Drawing.new("Square"),
            Name = Drawing.new("Text"), Dist = Drawing.new("Text"), Health = Drawing.new("Text"),
            Line = Drawing.new("Line"), Img = Instance.new("ImageLabel", EspGui)
        }
        obj.Box.Thickness = 1; obj.Box.Color = Color3.fromRGB(255, 255, 255); obj.Box.Transparency = 1
        obj.BoxOut.Thickness = 3; obj.BoxOut.Color = Color3.new(0,0,0); obj.BoxOut.Transparency = 0.5
        
        -- ШРИФТ ИЗМЕНЕН НА 0 (UI Font) - Выглядит как SourceSans из менюшки
        obj.Name.Outline = true; obj.Name.Center = true; obj.Name.Font = 0; obj.Name.Color = Color3.new(1,1,1)
        obj.Dist.Outline = true; obj.Dist.Center = true; obj.Dist.Color = Color3.new(0.8, 0.8, 0.8); obj.Dist.Font = 0
        obj.Health.Outline = true; obj.Health.Center = true; obj.Health.Color = Color3.new(0, 1, 0); obj.Health.Font = 0
        
        obj.Line.Color = Color3.fromRGB(255, 255, 255)
        obj.Img.BackgroundTransparency = 1; obj.Img.Size = UDim2.new(0, 70, 0, 70); obj.Img.Visible = false
        Cache.PlayerVisuals[player] = obj
    end

    for _, p in pairs(Players:GetPlayers()) do if p ~= LocalPlayer then CreateEsp(p) end end
    Players.PlayerAdded:Connect(function(p) CreateEsp(p) end)
    Players.PlayerRemoving:Connect(function(p) if Cache.PlayerVisuals[p] then for _, v in pairs(Cache.PlayerVisuals[p]) do if typeof(v)=="Instance" then v:Destroy() else v:Remove() end end; Cache.PlayerVisuals[p] = nil end end)

    RunService.RenderStepped:Connect(function()
        local center = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
        local rad = Toggles.FovRadius
        if Toggles.DynamicFov then rad = (Toggles.FovRadius / Camera.FieldOfView) * 80 end
        UI_Elements.FovCircle.Position = center; UI_Elements.FovCircle.Radius = rad; UI_Elements.FovCircle.Visible = Toggles.DrawFov
        
        local target, t_dist = nil, rad
        
        for p, esp in pairs(Cache.PlayerVisuals) do
            local isVisible = false
            if p.Character and p.Character:FindFirstChild("HumanoidRootPart") and p.Character.Humanoid.Health > 0 then
                local hrp = p.Character.HumanoidRootPart
                local dist = (Camera.CFrame.Position - hrp.Position).Magnitude
                local pos, on = Camera:WorldToViewportPoint(hrp.Position)
                
                if on then
                    local headPos = Camera:WorldToViewportPoint(p.Character.Head.Position)
                    local m = (Vector2.new(headPos.X, headPos.Y) - center).Magnitude
                    if m < t_dist then
                        t_dist = m
                        target = p.Character.Head
                    end

                    if Toggles.PlayerEsp and dist <= Toggles.EspMaxDist then
                        
                        local passVis = true
                        if Toggles.VisCheck then
                            local ray = Ray.new(Camera.CFrame.Position, (hrp.Position - Camera.CFrame.Position).Unit * 500)
                            local hitPart = Workspace:FindPartOnRayWithIgnoreList(ray, {LocalPlayer.Character, p.Character})
                            if hitPart then passVis = false end
                        end

                        if passVis then
                            isVisible = true
                            local head = Camera:WorldToViewportPoint(p.Character.Head.Position + Vector3.new(0, 0.5, 0))
                            local foot = Camera:WorldToViewportPoint(hrp.Position - Vector3.new(0, 3, 0))
                            local h = math.abs(head.Y - foot.Y); local w = h / 1.5
                            
                            esp.Box.Visible = Toggles.EspBox; esp.Box.Size = Vector2.new(w, h); esp.Box.Position = Vector2.new(pos.X - w/2, pos.Y - h/2)
                            esp.BoxOut.Visible = Toggles.EspBox; esp.BoxOut.Size = esp.Box.Size; esp.BoxOut.Position = esp.Box.Position
                            
                            esp.Name.Visible = Toggles.EspName; esp.Name.Text = p.Name; esp.Name.Position = Vector2.new(pos.X, pos.Y - h/2 - Toggles.FontSize - 5); esp.Name.Size = Toggles.FontSize
                            
                            local bottom = pos.Y + h/2
                            esp.Health.Visible = Toggles.EspHealth
                            if Toggles.EspHealth then esp.Health.Text = math.floor(p.Character.Humanoid.Health) .. " HP"; esp.Health.Position = Vector2.new(pos.X, bottom); esp.Health.Size = Toggles.FontSize - 2; bottom = bottom + Toggles.FontSize end

                            esp.Dist.Visible = Toggles.EspDistance
                            if Toggles.EspDistance then esp.Dist.Text = math.floor(dist) .. "m"; esp.Dist.Position = Vector2.new(pos.X, bottom); esp.Dist.Size = Toggles.FontSize - 2; bottom = bottom + Toggles.FontSize end
                            
                            esp.Img.Visible = false
                            if Toggles.EspWeapon then
                                local tool = p.Character:FindFirstChildOfClass("Tool")
                                if tool and tool.TextureId ~= "" then esp.Img.Visible = true; esp.Img.Image = tool.TextureId; esp.Img.Position = UDim2.new(0, pos.X - 35, 0, bottom - 10) end
                            end
                            
                            esp.Line.Visible = Toggles.EspLines; esp.Line.Thickness = Toggles.LineThickness; esp.Line.From = Vector2.new(Camera.ViewportSize.X/2, 0); esp.Line.To = Vector2.new(pos.X, pos.Y - h/2)
                        end
                    end
                end
            end
            
            if not isVisible then 
                esp.Box.Visible = false
                esp.BoxOut.Visible = false
                esp.Name.Visible = false
                esp.Dist.Visible = false
                esp.Health.Visible = false
                esp.Line.Visible = false
                esp.Img.Visible = false
            end
        end
        
        Cache.SilentTarget = target
        UI_Elements.TargetDot.Visible = (target ~= nil and Toggles.TargetMarker)
        if target then 
            local p = Camera:WorldToViewportPoint(target.Position)
            UI_Elements.TargetDot.Position = Vector2.new(p.X, p.Y)
        end
    end)

    -- Обновление Инвентаря
    task.spawn(function()
        while task.wait(1) do
            if Toggles.InventoryViewer and Cache.SilentTarget then
                UpdateInventory(Players:GetPlayerFromCharacter(Cache.SilentTarget.Parent))
                InvFrame.Visible = true
            else
                InvFrame.Visible = false
            end
        end
    end)

    ----------------------------------------------------------------
    -- [ ПЕРЕТАСКИВАНИЕ ОКОН (DRAG) ] --
    ----------------------------------------------------------------
    local function MakeDraggable(topbar, frame)
        local dragging, dragStart, startPos
        topbar.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = true; dragStart = input.Position; startPos = frame.Position end end)
        UserInputService.InputChanged:Connect(function(input) if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then local delta = input.Position - dragStart; frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y) end end)
        UserInputService.InputEnded:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end end)
    end

    MakeDraggable(TopBar, Main)
    MakeDraggable(InvTitle, InvFrame)

    print("LebroTools UI Integration Complete. Fixed HitSound, CustomSky & ESP Font.")
end

----------------------------------------------------------------
-- [ ЛОГИКА ПРОВЕРКИ ] --
----------------------------------------------------------------


-- Перетаскивание окна логина
local d, ds, sp
LoginFrame.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then d = true; ds = i.Position; sp = LoginFrame.Position end end)
UserInputService.InputChanged:Connect(function(i) if d and i.UserInputType == Enum.UserInputType.MouseMovement then local dl = i.Position - ds; LoginFrame.Position = UDim2.new(sp.X.Scale, sp.X.Offset+dl.X, sp.Y.Scale, sp.Y.Offset+dl.Y) end end)
UserInputService.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then d = false end end)