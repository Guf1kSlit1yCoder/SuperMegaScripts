--[[
    ALTRON PIN-PAD LOGIN SYSTEM - OPTIMIZED & FIXED
]]

local HttpService = game:GetService("HttpService")
local CoreGui = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")
local HWID = game:GetService("RbxAnalyticsService"):GetClientId()

-- ССЫЛКА НА ТВОЙ API 
local API_URL = "http://fi7.bot-hosting.net:20159/verify"

----------------------------------------------------------------
-- [ UI ЛОГИНА ] --
----------------------------------------------------------------
local LoginGui = Instance.new("ScreenGui")
LoginGui.Name = "AltronLoginSystem"
pcall(function() LoginGui.Parent = CoreGui end)
if not LoginGui.Parent then LoginGui.Parent = game.Players.LocalPlayer:WaitForChild("PlayerGui") end

local LoginFrame = Instance.new("Frame", LoginGui)
LoginFrame.Size = UDim2.new(0, 260, 0, 320)
LoginFrame.Position = UDim2.new(0.5, -130, 0.5, -160)
LoginFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
LoginFrame.BorderSizePixel = 0
Instance.new("UICorner", LoginFrame).CornerRadius = UDim.new(0, 10)

local DisplayBox = Instance.new("TextBox", LoginFrame)
DisplayBox.Size = UDim2.new(1, -30, 0, 45)
DisplayBox.Position = UDim2.new(0, 15, 0, 15)
DisplayBox.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
DisplayBox.Text = ""
DisplayBox.PlaceholderText = "********"
DisplayBox.TextColor3 = Color3.fromRGB(255, 255, 255)
DisplayBox.TextScaled = true
DisplayBox.Font = Enum.Font.Code
DisplayBox.TextEditable = false
Instance.new("UICorner", DisplayBox)

local StatusText = Instance.new("TextLabel", LoginFrame)
StatusText.Size = UDim2.new(1, -30, 0, 20)
StatusText.Position = UDim2.new(0, 15, 0, 65)
StatusText.BackgroundTransparency = 1
StatusText.Text = "ВВЕДИТЕ ПИН-КОД"
StatusText.TextColor3 = Color3.fromRGB(200, 200, 200)
StatusText.Font = Enum.Font.SourceSans
StatusText.TextSize = 14

local Keypad = Instance.new("Frame", LoginFrame)
Keypad.Size = UDim2.new(1, -30, 1, -110)
Keypad.Position = UDim2.new(0, 15, 0, 95)
Keypad.BackgroundTransparency = 1

local bw, bh, pad = 70, 45, 10
local keys = {
    {"1", 0, 0}, {"2", 1, 0}, {"3", 2, 0},
    {"4", 0, 1}, {"5", 1, 1}, {"6", 2, 1},
    {"7", 0, 2}, {"8", 1, 2}, {"9", 2, 2}
}

for _, k in ipairs(keys) do
    local btn = Instance.new("TextButton", Keypad)
    btn.Size = UDim2.new(0, bw, 0, bh)
    btn.Position = UDim2.new(0, k[2]*(bw+pad), 0, k[3]*(bh+pad))
    btn.Text = k[1]
    btn.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
    btn.TextColor3 = Color3.new(1,1,1)
    btn.Font = Enum.Font.SourceSansBold
    btn.TextSize = 22
    Instance.new("UICorner", btn)
    
    btn.MouseButton1Click:Connect(function()
        if #DisplayBox.Text < 8 then DisplayBox.Text = DisplayBox.Text .. k[1] end
    end)
end

local bottom_w = (230 - 3*6) / 4
local function CreateBottomBtn(txt, index, color, txtColor)
    local btn = Instance.new("TextButton", Keypad)
    btn.Size = UDim2.new(0, bottom_w, 0, bh)
    btn.Position = UDim2.new(0, index*(bottom_w+6), 0, 3*(bh+pad))
    btn.Text = txt
    btn.BackgroundColor3 = color
    btn.TextColor3 = txtColor
    btn.Font = Enum.Font.SourceSansBold
    btn.TextSize = 14
    Instance.new("UICorner", btn)
    return btn
end

local b0 = CreateBottomBtn("0", 0, Color3.fromRGB(70, 70, 70), Color3.new(1,1,1))
b0.MouseButton1Click:Connect(function() if #DisplayBox.Text < 8 then DisplayBox.Text = DisplayBox.Text .. "0" end end)
local bDel = CreateBottomBtn("DEL", 1, Color3.fromRGB(70, 70, 70), Color3.new(1,1,1))
bDel.MouseButton1Click:Connect(function() DisplayBox.Text = string.sub(DisplayBox.Text, 1, -2) end)
local bPast = CreateBottomBtn("PAST", 2, Color3.fromRGB(70, 70, 70), Color3.new(1,1,1))
bPast.MouseButton1Click:Connect(function() pcall(function() DisplayBox.Text = string.sub(tostring(getclipboard()), 1, 8) end) end)
local bGo = CreateBottomBtn("GO", 3, Color3.new(1,1,1), Color3.new(0,0,0))

----------------------------------------------------------------
-- [ MAIN CHEAT CORE ] --
----------------------------------------------------------------
local function StartCheat()
    print("Авторизация успешна! Запуск LebroTools...")
    
    local Players = game:GetService("Players")
    local RunService = game:GetService("RunService")
    local Workspace = game:GetService("Workspace")
    local Lighting = game:GetService("Lighting")
    local SoundService = game:GetService("SoundService")
    local LocalPlayer = Players.LocalPlayer
    local Camera = Workspace.CurrentCamera

    local Toggles = {
        SilentAim = false, DrawFov = false, DynamicFov = false, FovRadius = 150,
        IgnoreFriends = false, IgnoreClan = false, OnlyOnHit = false, HitSound = false,
        NoRecoil = false, NoSpread = false, MaxVel = false, ZeroGrav = false,
        PlayerEsp = false, VisCheck = false, EspMaxDist = 2000, SmoothSpeed = 8.00,
        EspName = false, EspDistance = false, EspWeapon = false, EspSkeleton = false, EspCount = false,
        FontSize = 16.00, EspBox = false, EspHealth = false,
        EspLines = false, LineThickness = 0.80, TargetMarker = false,
        InventoryViewer = false,
        CustomSky = false, Fullbright = false, NoGrass = false, NoLeaves = false,
        HempEsp = false, CrateEsp = false, BpEsp = false, TcEsp = false,
        AutoOre = false, AutoTree = false
    }

    local Cache = { 
        PlayerVisuals = {}, 
        WorldInstances = {}, 
        SilentTarget = nil, 
        OriginalLighting = {},
        HookedWeaponTables = {} -- Кэш для таблиц оружия (устраняет фризы)
    }

    local UI_Elements = { FovCircle = Drawing.new("Circle"), TargetDot = Drawing.new("Circle") }
    UI_Elements.FovCircle.Thickness = 1; UI_Elements.FovCircle.NumSides = 64; 
    UI_Elements.FovCircle.Filled = false; UI_Elements.FovCircle.Color = Color3.fromRGB(255, 255, 255); UI_Elements.FovCircle.Visible = false
    UI_Elements.TargetDot.Radius = 5; UI_Elements.TargetDot.Thickness = 1; UI_Elements.TargetDot.Color = Color3.fromRGB(255, 0, 127); UI_Elements.TargetDot.Filled = true; UI_Elements.TargetDot.Visible = false

    local EspGui = Instance.new("ScreenGui")
    EspGui.Name = "LebroToolsGUI"
    EspGui.ResetOnSpawn = false
    pcall(function() EspGui.Parent = CoreGui end)
    if not EspGui.Parent then EspGui.Parent = LocalPlayer:WaitForChild("PlayerGui") end

    -- GUI Элементы
    local ToggleBtn = Instance.new("TextButton", EspGui)
    ToggleBtn.Size = UDim2.new(0, 50, 0, 50); ToggleBtn.Position = UDim2.new(0, 15, 0, 15)
    ToggleBtn.BackgroundColor3 = Color3.fromRGB(75, 75, 75); ToggleBtn.Text = "A"; ToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    ToggleBtn.Font = Enum.Font.SourceSansBold; ToggleBtn.TextSize = 28
    Instance.new("UICorner", ToggleBtn).CornerRadius = UDim.new(0, 5)
    Instance.new("UIStroke", ToggleBtn).Color = Color3.fromRGB(150, 150, 150)

    local InvFrame = Instance.new("Frame", EspGui)
    InvFrame.Size = UDim2.new(0, 280, 0, 360); InvFrame.Position = UDim2.new(1, -300, 0.5, -180)
    InvFrame.BackgroundColor3 = Color3.fromRGB(65, 65, 65); InvFrame.Visible = false
    Instance.new("UICorner", InvFrame)
    local InvTitle = Instance.new("TextLabel", InvFrame)
    InvTitle.Size = UDim2.new(1, 0, 0, 40); InvTitle.Text = " ИНВЕНТАРЬ ЦЕЛИ"; InvTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
    InvTitle.Font = Enum.Font.SourceSansBold; InvTitle.TextSize = 16; InvTitle.TextXAlignment = Enum.TextXAlignment.Left; InvTitle.BackgroundColor3 = Color3.fromRGB(55, 55, 55)
    local InvList = Instance.new("ScrollingFrame", InvFrame)
    InvList.Size = UDim2.new(1, -10, 1, -50); InvList.Position = UDim2.new(0, 5, 0, 45); InvList.BackgroundTransparency = 1
    local InvLayout = Instance.new("UIGridLayout", InvList)
    InvLayout.CellSize = UDim2.new(0, 60, 0, 60); InvLayout.CellPadding = UDim2.new(0, 6, 0, 6)

    local function UpdateInventory(player)
        for _, v in pairs(InvList:GetChildren()) do if v:IsA("Frame") then v:Destroy() end end
        if not player or not player.Character then return end
        InvTitle.Text = " ИНВ.: " .. player.Name:upper()
        local items = {}
        local function parseItem(tool, isUsing)
            local id = (tool.TextureId and tool.TextureId ~= "" and tool.TextureId) or nil
            local key = tool.Name .. (id or "")
            if items[key] then items[key].Count = items[key].Count + 1; if isUsing then items[key].Using = true end
            else items[key] = {Name = tool.Name, Tex = id, Count = 1, Using = isUsing} end
        end
        if player.Character then for _, t in pairs(player.Character:GetChildren()) do if t:IsA("Tool") then parseItem(t, true) end end end
        local bp = player:FindFirstChild("Backpack")
        if bp then for _, t in pairs(bp:GetChildren()) do if t:IsA("Tool") then parseItem(t, false) end end end

        for _, data in pairs(items) do
            local Slot = Instance.new("Frame", InvList); Slot.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
            Instance.new("UICorner", Slot).CornerRadius = UDim.new(0, 4)
            if data.Tex then
                local Img = Instance.new("ImageLabel", Slot); Img.Size = UDim2.new(1, -4, 1, -4); Img.Position = UDim2.new(0, 2, 0, 2); Img.BackgroundTransparency = 1; Img.ScaleType = Enum.ScaleType.Fit; Img.Image = data.Tex
            else
                local Txt = Instance.new("TextLabel", Slot); Txt.Size = UDim2.new(1, 0, 1, 0); Txt.BackgroundTransparency = 1; Txt.Text = data.Name; Txt.TextColor3 = Color3.new(0.8,0.8,0.8); Txt.Font = Enum.Font.SourceSans; Txt.TextSize = 12; Txt.TextWrapped = true
            end
        end
    end

    local Main = Instance.new("Frame", EspGui)
    Main.Size = UDim2.new(0, 850, 0, 480); Main.Position = UDim2.new(0.5, -425, 0.5, -240)
    Main.BackgroundColor3 = Color3.fromRGB(85, 85, 85); Main.BorderSizePixel = 0
    Instance.new("UIStroke", Main).Color = Color3.fromRGB(120, 120, 120)
    ToggleBtn.MouseButton1Click:Connect(function() Main.Visible = not Main.Visible end)

    local TopBar = Instance.new("Frame", Main)
    TopBar.Size = UDim2.new(1, 0, 0, 35); TopBar.BackgroundColor3 = Color3.fromRGB(75, 75, 75)
    local Title = Instance.new("TextLabel", TopBar)
    Title.Size = UDim2.new(0, 100, 1, 0); Title.Position = UDim2.new(0, 10, 0, 0); Title.Text = "LebroTools"; Title.TextColor3 = Color3.new(1,1,1); Title.Font = Enum.Font.SourceSans; Title.TextSize = 20; Title.BackgroundTransparency = 1
    
    local TabContainer = Instance.new("Frame", TopBar)
    TabContainer.Size = UDim2.new(1, -110, 1, 0); TabContainer.Position = UDim2.new(0, 110, 0, 0); TabContainer.BackgroundTransparency = 1
    local TabList = Instance.new("UIListLayout", TabContainer); TabList.FillDirection = Enum.FillDirection.Horizontal; TabList.Padding = UDim.new(0, 16)
    local ContentArea = Instance.new("Frame", Main)
    ContentArea.Size = UDim2.new(1, 0, 1, -36); ContentArea.Position = UDim2.new(0, 0, 0, 36); ContentArea.BackgroundTransparency = 1

    local Tabs, TabBtns = {}, {}
    local function SelectTab(name)
        for n, f in pairs(Tabs) do f.Visible = (n == name) end
        for n, b in pairs(TabBtns) do b.TextColor3 = (n == name) and Color3.new(1,1,1) or Color3.fromRGB(180, 180, 180) end
    end
    local function CreateTab(name)
        local btn = Instance.new("TextButton", TabContainer); btn.Size = UDim2.new(0, 0, 1, 0); btn.AutomaticSize = Enum.AutomaticSize.X; btn.BackgroundTransparency = 1; btn.Text = name; btn.Font = Enum.Font.SourceSans; btn.TextSize = 18; TabBtns[name] = btn
        local page = Instance.new("Frame", ContentArea); page.Size = UDim2.new(1, 0, 1, 0); page.BackgroundTransparency = 1; page.Visible = false; Tabs[name] = page
        btn.MouseButton1Click:Connect(function() SelectTab(name) end)
        return page
    end
    local function CreateSection(parent, title, x, y, w, h)
        local sec = Instance.new("Frame", parent); sec.Position = UDim2.new(0, x, 0, y); sec.Size = UDim2.new(0, w, 0, h); sec.BackgroundTransparency = 1
        local lbl = Instance.new("TextLabel", sec); lbl.Size = UDim2.new(1, 0, 0, 20); lbl.Text = title; lbl.TextColor3 = Color3.fromRGB(220, 220, 220); lbl.Font = Enum.Font.SourceSans; lbl.TextSize = 16; lbl.TextXAlignment = Enum.TextXAlignment.Left; lbl.BackgroundTransparency = 1
        local container = Instance.new("Frame", sec); container.Size = UDim2.new(1, 0, 1, -28); container.Position = UDim2.new(0, 0, 0, 28); container.BackgroundTransparency = 1
        Instance.new("UIListLayout", container).Padding = UDim.new(0, 8)
        return container
    end
    local function AddCheckbox(parent, text, key)
        local f = Instance.new("Frame", parent); f.Size = UDim2.new(1, 0, 0, 24); f.BackgroundTransparency = 1
        local btn = Instance.new("TextButton", f); btn.Size = UDim2.new(0, 20, 0, 20); btn.BackgroundColor3 = Color3.fromRGB(90, 90, 90); btn.Text = ""; btn.Position = UDim2.new(0, 0, 0.5, -10)
        local check = Instance.new("TextLabel", btn); check.Size = UDim2.new(1, 0, 1, 0); check.BackgroundTransparency = 1; check.Text = "✓"; check.TextColor3 = Color3.new(1,1,1); check.Font = Enum.Font.SourceSansBold; check.TextSize = 18; check.Visible = Toggles[key]
        local lbl = Instance.new("TextLabel", f); lbl.Size = UDim2.new(1, -28, 1, 0); lbl.Position = UDim2.new(0, 28, 0, 0); lbl.BackgroundTransparency = 1; lbl.Text = text; lbl.TextColor3 = Color3.fromRGB(220, 220, 220); lbl.Font = Enum.Font.SourceSans; lbl.TextSize = 16; lbl.TextXAlignment = Enum.TextXAlignment.Left
        btn.MouseButton1Click:Connect(function() Toggles[key] = not Toggles[key]; check.Visible = Toggles[key] end)
    end
    local function AddSlider(parent, text, min, max, default, key, isFloat)
        local f = Instance.new("Frame", parent); f.Size = UDim2.new(1, 0, 0, 45); f.BackgroundTransparency = 1
        local lbl = Instance.new("TextLabel", f); lbl.Size = UDim2.new(1, 0, 0, 18); lbl.BackgroundTransparency = 1; lbl.Text = text; lbl.TextColor3 = Color3.fromRGB(220, 220, 220); lbl.Font = Enum.Font.SourceSans; lbl.TextSize = 16; lbl.TextXAlignment = Enum.TextXAlignment.Left
        local bar = Instance.new("Frame", f); bar.Size = UDim2.new(1, -10, 0, 20); bar.Position = UDim2.new(0, 0, 0, 22); bar.BackgroundColor3 = Color3.fromRGB(110, 110, 110)
        local valText = Instance.new("TextLabel", bar); valText.Size = UDim2.new(1, 0, 1, 0); valText.BackgroundTransparency = 1; valText.Text = isFloat and string.format("%.2f", default) or tostring(default); valText.TextColor3 = Color3.new(1,1,1); valText.Font = Enum.Font.SourceSansBold; valText.TextSize = 14; valText.ZIndex = 2
        local knob = Instance.new("Frame", bar); knob.Size = UDim2.new(0, 12, 1, 4); knob.Position = UDim2.new((default-min)/(max-min), -6, 0, -2); knob.BackgroundColor3 = Color3.new(1,1,1); knob.ZIndex = 3
        local btn = Instance.new("TextButton", bar); btn.Size = UDim2.new(1, 0, 1, 0); btn.BackgroundTransparency = 1; btn.Text = ""
        local dragging = false
        btn.MouseButton1Down:Connect(function() dragging = true end)
        UserInputService.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end end)
        UserInputService.InputChanged:Connect(function(i)
            if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then
                local pct = math.clamp((i.Position.X - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
                knob.Position = UDim2.new(pct, -6, 0, -2); local val = min + (max - min) * pct; if not isFloat then val = math.floor(val) end
                valText.Text = isFloat and string.format("%.2f", val) or tostring(val); Toggles[key] = val
            end
        end)
    end

    local tabAimbot = CreateTab("Aimbot"); local tabWeapon = CreateTab("Weapon"); local tabESP = CreateTab("ESP"); local tabWorld = CreateTab("World"); local tabPlayer = CreateTab("Player"); local tabMisc = CreateTab("Misc")
    local col1, col2, col3, colW = 15, 295, 575, 260

    local secAim = CreateSection(tabAimbot, "Aimbot", col1, 15, colW, 400); AddCheckbox(secAim, "Enable Aimbot", "SilentAim")
    local secFov = CreateSection(tabAimbot, "FOV", col2, 15, colW, 400); AddCheckbox(secFov, "Draw FOV", "DrawFov"); AddSlider(secFov, "Radius", 50, 1500, 150, "FovRadius", false)
    
    local secEspMain = CreateSection(tabESP, "ESP Main", col1, 15, colW, 400); AddCheckbox(secEspMain, "Enable ESP", "PlayerEsp"); AddCheckbox(secEspMain, "Draw Boxes", "EspBox"); AddSlider(secEspMain, "Max Distance", 50, 5000, 2000, "EspMaxDist", true)
    local secDisplay = CreateSection(tabESP, "Display", col2, 15, colW, 400); AddCheckbox(secDisplay, "Names", "EspName"); AddCheckbox(secDisplay, "Distance", "EspDistance"); AddCheckbox(secDisplay, "Health", "EspHealth"); AddCheckbox(secDisplay, "Weapon", "EspWeapon")
    
    local secWeapMods = CreateSection(tabWeapon, "Gun Mods", col1, 15, colW, 400); AddCheckbox(secWeapMods, "No Recoil", "NoRecoil"); AddCheckbox(secWeapMods, "No Spread", "NoSpread"); AddCheckbox(secWeapMods, "Max Velocity", "MaxVel"); AddCheckbox(secWeapMods, "Zero Gravity", "ZeroGrav")
    
    local secWorldChams = CreateSection(tabWorld, "World ESP", col1, 15, colW, 400); AddCheckbox(secWorldChams, "Hemp ESP", "HempEsp"); AddCheckbox(secWorldChams, "Crates ESP", "CrateEsp"); AddCheckbox(secWorldChams, "Tool Cupboards", "TcEsp")
    local secWorldEnv = CreateSection(tabWorld, "Environment", col2, 15, colW, 400); AddCheckbox(secWorldEnv, "Fullbright", "Fullbright"); AddCheckbox(secWorldEnv, "Custom Sky", "CustomSky")
    
    local secPlyInfo = CreateSection(tabPlayer, "Info", col1, 15, colW, 400); AddCheckbox(secPlyInfo, "Inventory Viewer", "InventoryViewer")
    local secMiscFarm = CreateSection(tabMisc, "Farming", col1, 15, colW, 400); AddCheckbox(secMiscFarm, "Auto Hit Ore", "AutoOre"); AddCheckbox(secMiscFarm, "Auto Hit Tree", "AutoTree")

    SelectTab("Aimbot")

    ----------------------------------------------------------------
    -- [ ESP МИРА (БЕЗ ЛИМИТА НА ВХ И БЕЗ ФРИЗОВ) ] --
    ----------------------------------------------------------------
    local function AddChams(inst, col, txt, typ)
        if Cache.WorldInstances[inst] then return end
        
        -- BoxHandleAdornment работает стабильно, в отличие от Highlight с лимитом в 31
        local box = Instance.new("BoxHandleAdornment")
        box.Size = inst:IsA("Model") and (inst.PrimaryPart and inst.PrimaryPart.Size or Vector3.new(2,2,2)) or inst.Size
        box.Color3 = col; box.Transparency = 0.6; box.AlwaysOnTop = true; box.ZIndex = 0
        box.Adornee = inst:IsA("Model") and inst.PrimaryPart or inst
        pcall(function() box.Parent = CoreGui end)

        local bg = Instance.new("BillboardGui")
        bg.Adornee = inst:IsA("Model") and inst.PrimaryPart or inst
        bg.Size = UDim2.new(0, 100, 0, 20); bg.AlwaysOnTop = true
        local tl = Instance.new("TextLabel", bg)
        tl.Size = UDim2.new(1,0,1,0); tl.BackgroundTransparency = 1; tl.TextColor3 = col
        tl.TextStrokeTransparency = 0 -- Обводка текста для четкости
        tl.Text = txt; tl.Font = Enum.Font.SourceSansBold; tl.TextSize = 14
        pcall(function() bg.Parent = CoreGui end)

        Cache.WorldInstances[inst] = {H = box, B = bg, Type = typ}
    end

    local function RefWEsp()
        -- 1. Удаляем только то, что пропало с карты, и обновляем видимость
        for inst, d in pairs(Cache.WorldInstances) do
            if not inst or not inst.Parent then
                if d.H then d.H:Destroy() end
                if d.B then d.B:Destroy() end
                Cache.WorldInstances[inst] = nil
            else
                local isVisible = false
                if d.Type == "Hemp" and Toggles.HempEsp then isVisible = true end
                if d.Type == "Crate" and Toggles.CrateEsp then isVisible = true end
                if d.Type == "Backpack" and Toggles.BpEsp then isVisible = true end
                if d.Type == "TC" and Toggles.TcEsp then isVisible = true end
if d.H then d.H.Visible = isVisible end
                if d.B then d.B.Enabled = isVisible end
            end
        end

        -- 2. Добавляем новые предметы (поиск)
        local function scanFolder(folderName, typeName, color)
            local f = Workspace:FindFirstChild(folderName)
            if not f then -- Если папки нет в корне, ищем в Map
                local map = Workspace:FindFirstChild("Map")
                if map then f = map:FindFirstChild(folderName) end
            end
            if f then
                for _, i in ipairs(f:GetDescendants()) do
                    if i:IsA("Model") or i:IsA("BasePart") then
                        if typeName == "Crate" and (i.Name == "MilitaryCrate" or i.Name == "Crate" or i.Name == "ToolBox") then AddChams(i, color, i.Name, typeName)
                        elseif typeName == "TC" and i.Name == "ToolCupboardModel" then AddChams(i, color, "TC", typeName)
                        elseif (typeName == "Hemp" or typeName == "Backpack") and i.Parent == f then AddChams(i, color, typeName, typeName) end
                    end
                end
            end
        end

        if Toggles.HempEsp then scanFolder("Hemp", "Hemp", Color3.fromRGB(0, 255, 0)) end
        if Toggles.CrateEsp then scanFolder("crates", "Crate", Color3.fromRGB(255, 165, 0)); scanFolder("Crates", "Crate", Color3.fromRGB(255, 165, 0)) end
        if Toggles.BpEsp then scanFolder("DeathBackpacks", "Backpack", Color3.fromRGB(255, 0, 0)) end
        if Toggles.TcEsp then scanFolder("Builds", "TC", Color3.fromRGB(0, 150, 255)) end
    end

    ----------------------------------------------------------------
    -- [ ОПТИМИЗИРОВАННЫЙ ХУК ПАМЯТИ (ФИКС ФРИЗОВ) ] --
    ----------------------------------------------------------------
    task.spawn(function()
        -- Первичный поиск таблиц оружия 
        while task.wait(5) do
            pcall(function()
                local gc = getgc(true)
                for i, v in ipairs(gc) do
                    -- Делаем паузу каждые 500 итераций, чтобы не фризить игру
                    if i % 500 == 0 then task.wait() end 
                    
                    if type(v) == "table" and not Cache.HookedWeaponTables[v] then
                        local isWepTable = false
                        
                        -- Хук Silent Aim
                        if rawget(v, "getfireDirection") and not rawget(v, "_lebroAimHooked") then
                            local old = v.getfireDirection
                            v.getfireDirection = function(self, origin, raycast)
                                if Toggles.SilentAim and Cache.SilentTarget then return (Cache.SilentTarget.Position - origin).Unit end
                                return old(self, origin, raycast)
                            end
                            rawset(v, "_lebroAimHooked", true)
                            isWepTable = true
                        end
                        
                        -- Хук Авто-фарма (руда/деревья)
                        if rawget(v, "hit") and not rawget(v, "_lebroHitHooked") then
                            local oldH = v.hit
                            v.hit = function(self, inst, pos)
                                local tI, tP = inst, pos
                                if Toggles.AutoOre or Toggles.AutoTree then
                                    local c = LocalPlayer.Character
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
                            rawset(v, "_lebroHitHooked", true)
                            isWepTable = true
                        end

                        -- Если это таблица со статами пули
                        if rawget(v, "BaseBulletVelocity") or rawget(v, "TotalAttachmentStats") then
                            isWepTable = true
                        end

                        -- Сохраняем в кэш
                        if isWepTable then Cache.HookedWeaponTables[v] = v end
                    end
                end
            end)
        end
    end)

    -- Быстрое обновление параметров оружия из кэша (БЕЗ лагов)
    RunService.RenderStepped:Connect(function()
        for _, v in pairs(Cache.HookedWeaponTables) do
            if rawget(v, "BaseBulletVelocity") and Toggles.MaxVel then v.BaseBulletVelocity = 999999; v.Velocity = 999999 end
            if rawget(v, "BulletGravity") and Toggles.ZeroGrav then v.BulletGravity = 0; v.Gravity = 0 end
            if rawget(v, "TotalAttachmentStats") then
                local s = v.TotalAttachmentStats
                if Toggles.NoSpread then s.SpreadMult = 0; s.PelletSpread = 0 end
                if Toggles.NoRecoil then s.RecoilMult = 0; s.KickMult = 0 end
            end
        end
    end)

    task.spawn(function()
        while task.wait(1) do
            RefWEsp()
            if Toggles.Fullbright then Lighting.Ambient = Color3.new(1,1,1); Lighting.OutdoorAmbient = Color3.new(1,1,1); Lighting.GlobalShadows = false else Lighting.Ambient = Color3.fromRGB(127,127,127); Lighting.OutdoorAmbient = Color3.fromRGB(127,127,127); Lighting.GlobalShadows = true end
            if Workspace:FindFirstChild("Terrain") then Workspace.Terrain.Decoration = not Toggles.NoGrass end
            if Toggles.CustomSky and not Lighting:FindFirstChild("LebroSky") then
                for _, obj in pairs(Lighting:GetChildren()) do if obj:IsA("Atmosphere") or obj:IsA("Sky") then table.insert(Cache.OriginalLighting, obj); obj.Parent = nil end end
                local s = Instance.new("Sky", Lighting); s.Name = "LebroSky"; local id = "rbxassetid://2758029221"
                s.SkyboxBk = id; s.SkyboxDn = id; s.SkyboxFt = id; s.SkyboxLf = id; s.SkyboxRt = id; s.SkyboxUp = id
            elseif not Toggles.CustomSky and Lighting:FindFirstChild("LebroSky") then
                Lighting.LebroSky:Destroy(); for _, obj in pairs(Cache.OriginalLighting) do obj.Parent = Lighting end; table.clear(Cache.OriginalLighting)
            end
        end
    end)

    ----------------------------------------------------------------
    -- [ ESP ИГРОКОВ ] --
    ----------------------------------------------------------------
    local function CreateEsp(player)
        local obj = { Box = Drawing.new("Square"), Name = Drawing.new("Text"), Dist = Drawing.new("Text"), Health = Drawing.new("Text") }
        obj.Box.Thickness = 1; obj.Box.Color = Color3.new(1,1,1); obj.Box.Transparency = 1
        obj.Name.Outline = true; obj.Name.Center = true; obj.Name.Font = 0; obj.Name.Color = Color3.new(1,1,1)
        obj.Dist.Outline = true; obj.Dist.Center = true; obj.Dist.Color = Color3.new(0.8, 0.8, 0.8); obj.Dist.Font = 0
        obj.Health.Outline = true; obj.Health.Center = true; obj.Health.Color = Color3.new(0, 1, 0); obj.Health.Font = 0
        Cache.PlayerVisuals[player] = obj
    end

    for _, p in pairs(Players:GetPlayers()) do if p ~= LocalPlayer then CreateEsp(p) end end
    Players.PlayerAdded:Connect(CreateEsp)
    Players.PlayerRemoving:Connect(function(p) if Cache.PlayerVisuals[p] then for _, v in pairs(Cache.PlayerVisuals[p]) do v:Remove() end; Cache.PlayerVisuals[p] = nil end end)

    RunService.RenderStepped:Connect(function()
        local center = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
        local rad = Toggles.DynamicFov and (Toggles.FovRadius / Camera.FieldOfView) * 80 or Toggles.FovRadius
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
                    if m < t_dist then t_dist = m; target = p.Character.Head end

                    if Toggles.PlayerEsp and dist <= Toggles.EspMaxDist then
                        isVisible = true
                        local h = math.abs(headPos.Y - (Camera:WorldToViewportPoint(hrp.Position - Vector3.new(0, 3, 0))).Y)
                        local w = h / 1.5
                        esp.Box.Visible = Toggles.EspBox; esp.Box.Size = Vector2.new(w, h); esp.Box.Position = Vector2.new(pos.X - w/2, pos.Y - h/2)
                        esp.Name.Visible = Toggles.EspName; esp.Name.Text = p.Name; esp.Name.Position = Vector2.new(pos.X, pos.Y - h/2 - Toggles.FontSize - 5); esp.Name.Size = Toggles.FontSize
                        local bottom = pos.Y + h/2
                        esp.Health.Visible = Toggles.EspHealth; if Toggles.EspHealth then esp.Health.Text = math.floor(p.Character.Humanoid.Health) .. " HP"; esp.Health.Position = Vector2.new(pos.X, bottom); esp.Health.Size = Toggles.FontSize - 2; bottom = bottom + Toggles.FontSize end
                        esp.Dist.Visible = Toggles.EspDistance; if Toggles.EspDistance then esp.Dist.Text = math.floor(dist) .. "m"; esp.Dist.Position = Vector2.new(pos.X, bottom); esp.Dist.Size = Toggles.FontSize - 2 end
                    end
                end
            end
            if not isVisible then esp.Box.Visible = false; esp.Name.Visible = false; esp.Dist.Visible = false; esp.Health.Visible = false end
        end
        Cache.SilentTarget = target
        UI_Elements.TargetDot.Visible = (target ~= nil and Toggles.TargetMarker)
        if target then UI_Elements.TargetDot.Position = Vector2.new((Camera:WorldToViewportPoint(target.Position)).X, (Camera:WorldToViewportPoint(target.Position)).Y) end
    end)

    task.spawn(function() while task.wait(1) do if Toggles.InventoryViewer and Cache.SilentTarget then UpdateInventory(Players:GetPlayerFromCharacter(Cache.SilentTarget.Parent)); InvFrame.Visible = true else InvFrame.Visible = false end end end)

    local function MakeDraggable(t, f)
        local d, ds, sp; t.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then d = true; ds = i.Position; sp = f.Position end end)
        UserInputService.InputChanged:Connect(function(i) if d and i.UserInputType == Enum.UserInputType.MouseMovement then f.Position = UDim2.new(sp.X.Scale, sp.X.Offset + (i.Position - ds).X, sp.Y.Scale, sp.Y.Offset + (i.Position - ds).Y) end end)
        UserInputService.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then d = false end end)
    end
    MakeDraggable(TopBar, Main); MakeDraggable(InvTitle, InvFrame)
end

----------------------------------------------------------------
-- [ ЛОГИКА ПРОВЕРКИ PIN ] --
----------------------------------------------------------------
bGo.MouseButton1Click:Connect(function()
    local pin = DisplayBox.Text
    if #pin < 8 then StatusText.Text = "ОШИБКА: НУЖНО 8 ЦИФР"; StatusText.TextColor3 = Color3.new(1,0,0); return end
    StatusText.Text = "ПРОВЕРКА..."; StatusText.TextColor3 = Color3.new(1,1,0)
    
    local reqFunc = request or http_request or (syn and syn.request) or function(data) return HttpService:RequestAsync(data) end
    local success, response = pcall(function()
        return reqFunc({
            Url = API_URL, Method = "POST",
            Headers = {["Content-Type"] = "application/json"},
            Body = HttpService:JSONEncode({
    ["key"] = pin, 
    ["hwid"] = HWID, 
    ["roblox_name"] = game.Players.LocalPlayer.Name -- ДОБАВЛЕНО
})
        })
    end)
    
    if success then
        local result = HttpService:JSONDecode(response.Body)
        if result.status == "success" then
            StatusText.Text = "ДОСТУП РАЗРЕШЕН!"; StatusText.TextColor3 = Color3.new(0,1,0); task.wait(0.5); LoginGui:Destroy(); StartCheat()
        else
            StatusText.Text = "ОШИБКА: " .. (result.message or "НЕВЕРНЫЙ ПИН"); StatusText.TextColor3 = Color3.new(1,0,0); DisplayBox.Text = ""
        end
    else
        StatusText.Text = "СЕРВЕР НЕДОСТУПЕН"; StatusText.TextColor3 = Color3.new(1,0,0)
    end
end)

local d, ds, sp; LoginFrame.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then d = true; ds = i.Position; sp = LoginFrame.Position end end)
UserInputService.InputChanged:Connect(function(i) if d and i.UserInputType == Enum.UserInputType.MouseMovement then LoginFrame.Position = UDim2.new(sp.X.Scale, sp.X.Offset+(i.Position-ds).X, sp.Y.Scale, sp.Y.Offset+(i.Position-ds).Y) end end)
UserInputService.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then d = false end end)                
