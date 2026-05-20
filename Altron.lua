--[[
    LebroTools - Ultimate Premium Edition (V3.1 - Mobile & Aim Update)
    Разработчик: LebroTools Team
    Telegram: https://t.me/LebroToolsRost
    
    Модификация: Улучшенные слайдеры с точкой (Mobile Friendly), мобильный Noclip (Ghost Mode) + Плавность Camera Aimbot.
]]

local CoreGui = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera
local Mouse = LocalPlayer:GetMouse()

print("Инициализация LebroTools Ultimate V3.1...")

-- [ ВСЕ НАСТРОЙКИ (TOGGLES) ] --
local Toggles = {
    -- Combat
    SilentAim = false, CamAimbot = false, TriggerBot = false, AimSmooth = 20, AimPart = "Head",
    DrawFov = false, DynamicFov = false, FovRadius = 150, FovColor = Color3.fromRGB(123, 97, 255),
    IgnoreFriends = false, IgnoreClan = false, OnlyOnHit = false, HitSound = false,
    
    -- Weapon Mods
    NoRecoil = false, NoSpread = false, MaxVel = false, ZeroGrav = false,
    
    -- Visuals / ESP
    PlayerEsp = false, BotEsp = false, VisCheck = false, EspMaxDist = 2000, SmoothSpeed = 8.00,
    EspName = false, EspDistance = false, EspWeapon = false, EspSkeleton = false, EspCount = true,
    FontSize = 14.00, EspBox = false, EspHealth = false,
    EspLines = false, LineThickness = 1.00, TargetMarker = false,
    InventoryViewer = false,
    
    -- Player
    WalkSpeed = 16, JumpPower = 50, InfJump = false, Noclip = false, GhostSpeed = 50,
    
    -- World
    CustomSky = false, Fullbright = false, NoGrass = false, NoLeaves = false, TimeOfDay = 14,
    HempEsp = false, CrateEsp = false, BpEsp = false, TcEsp = false,
    
    -- Misc
    AutoOre = false, AutoTree = false
}

local Cache = { 
    PlayerVisuals = {}, BotVisuals = {}, WorldInstances = {}, 
    SilentTarget = nil, CamTarget = nil, ToolModHooked = false, 
    OriginalLighting = {}
}

-- Глобальная таблица для состояния Freecam
local Freecam = { Active = false, SavedCFrame = nil, CamPart = nil, RenderConn = nil, IsUp = false, IsDown = false }

-- Премиальная палитра UI
local Theme = {
    MainBg = Color3.fromRGB(18, 18, 22),
    TopBar = Color3.fromRGB(13, 13, 16),
    SectionBg = Color3.fromRGB(23, 23, 28),
    Accent = Color3.fromRGB(123, 97, 255),
    AccentDark = Color3.fromRGB(85, 60, 200),
    Text = Color3.fromRGB(245, 245, 245),
    TextDark = Color3.fromRGB(135, 135, 145),
    Border = Color3.fromRGB(35, 35, 45)
}

-- [ СОЗДАНИЕ СЕТКИ GUI ] --
local EspGui = Instance.new("ScreenGui")
EspGui.Name = "LebroToolsGUI_V3_1"
EspGui.ResetOnSpawn = false
EspGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
pcall(function() syn.protect_gui(EspGui) end)
pcall(function() EspGui.Parent = CoreGui end)
if not EspGui.Parent then EspGui.Parent = LocalPlayer:WaitForChild("PlayerGui") end

-- Вспомогательная функция для плавных переходов
local function Tween(obj, props, time, style)
    local tweenInfo = TweenInfo.new(time or 0.2, style or Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    local tw = TweenService:Create(obj, tweenInfo, props)
    tw:Play()
    return tw
end

----------------------------------------------------------------
-- [ КНОПКИ ДЛЯ МОБИЛЬНОГО ПОЛЕТА (NOCLIP) ] --
----------------------------------------------------------------
local MobileNoclipUI = Instance.new("Frame", EspGui)
MobileNoclipUI.Size = UDim2.new(0, 70, 0, 150)
MobileNoclipUI.Position = UDim2.new(1, -90, 0.5, -75)
MobileNoclipUI.BackgroundTransparency = 1
MobileNoclipUI.Visible = false

local btnUp = Instance.new("TextButton", MobileNoclipUI)
btnUp.Size = UDim2.new(1, 0, 0, 70)
btnUp.BackgroundColor3 = Theme.MainBg
btnUp.Text = "ВВЕРХ"
btnUp.TextColor3 = Theme.Text
btnUp.Font = Enum.Font.GothamBold
btnUp.TextSize = 12
Instance.new("UICorner", btnUp).CornerRadius = UDim.new(0, 10)
Instance.new("UIStroke", btnUp).Color = Theme.Accent

local btnDown = Instance.new("TextButton", MobileNoclipUI)
btnDown.Size = UDim2.new(1, 0, 0, 70)
btnDown.Position = UDim2.new(0, 0, 1, -70)
btnDown.BackgroundColor3 = Theme.MainBg
btnDown.Text = "ВНИЗ"
btnDown.TextColor3 = Theme.Text
btnDown.Font = Enum.Font.GothamBold
btnDown.TextSize = 12
Instance.new("UICorner", btnDown).CornerRadius = UDim.new(0, 10)
Instance.new("UIStroke", btnDown).Color = Theme.Accent

btnUp.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then Freecam.IsUp = true; Tween(btnUp, {BackgroundColor3 = Theme.Accent}, 0.1) end end)
btnUp.InputEnded:Connect(function(input) if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then Freecam.IsUp = false; Tween(btnUp, {BackgroundColor3 = Theme.MainBg}, 0.1) end end)
btnDown.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then Freecam.IsDown = true; Tween(btnDown, {BackgroundColor3 = Theme.Accent}, 0.1) end end)
btnDown.InputEnded:Connect(function(input) if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then Freecam.IsDown = false; Tween(btnDown, {BackgroundColor3 = Theme.MainBg}, 0.1) end end)

----------------------------------------------------------------
-- [ АНИМИРОВАННЫЕ ЭЛЕМЕНТЫ FOV И МАРКЕРА ] --
----------------------------------------------------------------
local FOV_State = { CurrentRadius = Toggles.FovRadius, CurrentColor = Toggles.FovColor, CurrentThickness = 1 }
local UI_Elements = { FovCircle = Drawing.new("Circle"), TargetDot = Drawing.new("Circle") }

UI_Elements.FovCircle.Thickness = 1; UI_Elements.FovCircle.NumSides = 64; 
UI_Elements.FovCircle.Filled = false; UI_Elements.FovCircle.Visible = false

UI_Elements.TargetDot.Radius = 4; UI_Elements.TargetDot.Thickness = 1; 
UI_Elements.TargetDot.Color = Theme.Accent; UI_Elements.TargetDot.Filled = true; UI_Elements.TargetDot.Visible = false

----------------------------------------------------------------
-- [ КРАСИВЫЙ СЧЕТЧИК (РАДАР) ] --
----------------------------------------------------------------
local CounterFrame = Instance.new("Frame", EspGui)
CounterFrame.Size = UDim2.new(0, 260, 0, 35)
CounterFrame.Position = UDim2.new(0.5, -130, 0, -50)
CounterFrame.BackgroundColor3 = Theme.MainBg
CounterFrame.BorderSizePixel = 0

Instance.new("UICorner", CounterFrame).CornerRadius = UDim.new(0, 8)
local CounterStroke = Instance.new("UIStroke", CounterFrame)
CounterStroke.Color = Theme.Accent
CounterStroke.Thickness = 1.5

local CounterLabel = Instance.new("TextLabel", CounterFrame)
CounterLabel.Size = UDim2.new(1, 0, 1, 0)
CounterLabel.BackgroundTransparency = 1
CounterLabel.Text = "📡 РАДАР: 0 ИГРОКОВ | 0 БОТОВ"
CounterLabel.TextColor3 = Theme.Text
CounterLabel.Font = Enum.Font.GothamBold
CounterLabel.TextSize = 13

----------------------------------------------------------------
-- [ ИНВЕНТАРЬ ] --
----------------------------------------------------------------
local InvFrame = Instance.new("Frame", EspGui)
InvFrame.Size = UDim2.new(0, 280, 0, 360)
InvFrame.Position = UDim2.new(1, -300, 0.5, -180)
InvFrame.BackgroundColor3 = Theme.MainBg
InvFrame.Visible = false
Instance.new("UICorner", InvFrame).CornerRadius = UDim.new(0, 8)
local InvStroke = Instance.new("UIStroke", InvFrame)
InvStroke.Color = Theme.Border

local InvTitle = Instance.new("TextLabel", InvFrame)
InvTitle.Size = UDim2.new(1, 0, 0, 35)
InvTitle.Text = "🎒 ИНВЕНТАРЬ ЦЕЛИ"
InvTitle.TextColor3 = Theme.Text
InvTitle.Font = Enum.Font.GothamBold
InvTitle.TextSize = 13
InvTitle.BackgroundColor3 = Theme.TopBar
Instance.new("UICorner", InvTitle).CornerRadius = UDim.new(0, 8)
local InvLine = Instance.new("Frame", InvTitle); InvLine.Size = UDim2.new(1,0,0,1); InvLine.Position = UDim2.new(0,0,1,0); InvLine.BackgroundColor3 = Theme.Border; InvLine.BorderSizePixel = 0

local InvList = Instance.new("ScrollingFrame", InvFrame)
InvList.Size = UDim2.new(1, -10, 1, -45)
InvList.Position = UDim2.new(0, 5, 0, 40)
InvList.BackgroundTransparency = 1
InvList.ScrollBarThickness = 2
InvList.ScrollBarImageColor3 = Theme.Accent
local InvLayout = Instance.new("UIGridLayout", InvList)
InvLayout.CellSize = UDim2.new(0, 62, 0, 62)
InvLayout.CellPadding = UDim2.new(0, 6, 0, 6)

local function UpdateInventory(player)
    for _, v in pairs(InvList:GetChildren()) do if v:IsA("Frame") then v:Destroy() end end
    if not player or not player.Character then return end
    InvTitle.Text = "🎒 ИНВ.: " .. player.Name:upper()
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
        Slot.BackgroundColor3 = Theme.SectionBg
        Instance.new("UICorner", Slot).CornerRadius = UDim.new(0, 6)
        Instance.new("UIStroke", Slot).Color = Theme.Border
        
        if data.Tex then
            local Img = Instance.new("ImageLabel", Slot)
            Img.Size = UDim2.new(1, -10, 1, -10); Img.Position = UDim2.new(0, 5, 0, 5)
            Img.BackgroundTransparency = 1; Img.ScaleType = Enum.ScaleType.Fit; Img.Image = data.Tex
        else
            local Txt = Instance.new("TextLabel", Slot)
            Txt.Size = UDim2.new(1, -4, 1, -4); Txt.Position = UDim2.new(0, 2, 0, 2); Txt.BackgroundTransparency = 1
            Txt.Text = data.Name; Txt.TextColor3 = Theme.TextDark; Txt.Font = Enum.Font.Gotham; Txt.TextSize = 10; Txt.TextWrapped = true
        end
        if data.Count > 1 then
            local Cnt = Instance.new("TextLabel", Slot)
            Cnt.Size = UDim2.new(0, 20, 0, 16); Cnt.Position = UDim2.new(1, -22, 1, -18)
            Cnt.BackgroundColor3 = Theme.Accent; Cnt.Text = "x"..data.Count; Cnt.TextColor3 = Color3.fromRGB(255,255,255); Cnt.Font = Enum.Font.GothamBold; Cnt.TextSize = 10
            Instance.new("UICorner", Cnt).CornerRadius = UDim.new(0, 4)
        end
        if data.Using then
            local Usg = Instance.new("Frame", Slot)
            Usg.Size = UDim2.new(1, 0, 0, 4); Usg.Position = UDim2.new(0, 0, 1, -4)
            Usg.BackgroundColor3 = Theme.Accent; Usg.BorderSizePixel = 0
            Instance.new("UICorner", Usg).CornerRadius = UDim.new(0, 4)
        end
    end
end

----------------------------------------------------------------
-- [ UI ФРЕЙМВОРК МЕНЮ (МЕНЮ ЧИТА) ] --
----------------------------------------------------------------
local Main = Instance.new("Frame", EspGui)
Main.Size = UDim2.new(0, 720, 0, 460) 
Main.Position = UDim2.new(0.5, -360, 0.5, -230)
Main.BackgroundColor3 = Theme.MainBg
Main.BorderSizePixel = 0
Main.ClipsDescendants = true
Main.Visible = true -- Сразу видимо
Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 10)
local MainStroke = Instance.new("UIStroke", Main)
MainStroke.Color = Theme.Border

local TopBar = Instance.new("Frame", Main)
TopBar.Size = UDim2.new(1, 0, 0, 45) 
TopBar.BackgroundColor3 = Theme.TopBar
TopBar.BorderSizePixel = 0
local TopBarLine = Instance.new("Frame", TopBar)
TopBarLine.Size = UDim2.new(1, 0, 0, 2); TopBarLine.Position = UDim2.new(0, 0, 1, -2)
TopBarLine.BackgroundColor3 = Theme.Accent; TopBarLine.BorderSizePixel = 0

local Title = Instance.new("TextLabel", TopBar)
Title.Size = UDim2.new(0, 160, 1, 0); Title.Position = UDim2.new(0, 20, 0, 0)
Title.Text = "LEBROTOOLS"; Title.TextColor3 = Theme.Text
Title.Font = Enum.Font.GothamBlack; Title.TextSize = 19; Title.TextXAlignment = Enum.TextXAlignment.Left; Title.BackgroundTransparency = 1

local TabContainer = Instance.new("Frame", TopBar)
TabContainer.Size = UDim2.new(1, -190, 1, 0); TabContainer.Position = UDim2.new(0, 190, 0, 0); TabContainer.BackgroundTransparency = 1
local TabList = Instance.new("UIListLayout", TabContainer)
TabList.FillDirection = Enum.FillDirection.Horizontal; TabList.Padding = UDim.new(0, 8); TabList.VerticalAlignment = Enum.VerticalAlignment.Center

local ContentArea = Instance.new("Frame", Main)
ContentArea.Size = UDim2.new(1, 0, 1, -47); ContentArea.Position = UDim2.new(0, 0, 0, 47); ContentArea.BackgroundTransparency = 1

local ToggleBtn = Instance.new("TextButton", EspGui)
ToggleBtn.Size = UDim2.new(0, 50, 0, 50); ToggleBtn.Position = UDim2.new(0, 15, 0, 15)
ToggleBtn.BackgroundColor3 = Theme.MainBg; ToggleBtn.Text = "LT"; ToggleBtn.TextColor3 = Theme.Accent
ToggleBtn.Font = Enum.Font.GothamBlack; ToggleBtn.TextSize = 20
ToggleBtn.Visible = true -- Сразу видимо
Instance.new("UICorner", ToggleBtn).CornerRadius = UDim.new(0, 8)
local ToggleBtnStroke = Instance.new("UIStroke", ToggleBtn)
ToggleBtnStroke.Color = Theme.Accent

ToggleBtn.MouseButton1Click:Connect(function() 
    Main.Visible = not Main.Visible 
end)

local Tabs = {}
local TabBtns = {}

local function SelectTab(name)
    for n, f in pairs(Tabs) do f.Visible = (n == name) end
    for n, b in pairs(TabBtns) do
        local isSelected = (n == name)
        Tween(b, {TextColor3 = isSelected and Theme.Accent or Theme.TextDark}, 0.2)
    end
end

local function CreateTab(name)
    local btn = Instance.new("TextButton", TabContainer)
    btn.Size = UDim2.new(0, 0, 0, 32); btn.AutomaticSize = Enum.AutomaticSize.X; btn.BackgroundTransparency = 1
    btn.Text = name; btn.Font = Enum.Font.GothamBold; btn.TextSize = 13; btn.TextColor3 = Theme.TextDark
    
    local pad = Instance.new("UIPadding", btn)
    pad.PaddingLeft = UDim.new(0, 12); pad.PaddingRight = UDim.new(0, 12)
    
    TabBtns[name] = btn

    local page = Instance.new("ScrollingFrame", ContentArea)
    page.Size = UDim2.new(1, -20, 1, -20); page.Position = UDim2.new(0, 10, 0, 10); page.BackgroundTransparency = 1; page.Visible = false
    page.ScrollBarThickness = 3; page.ScrollBarImageColor3 = Theme.Accent; page.BorderSizePixel = 0
    
    local leftCol = Instance.new("Frame", page); leftCol.Size = UDim2.new(0.485, 0, 1, 0); leftCol.BackgroundTransparency = 1
    local rightCol = Instance.new("Frame", page); rightCol.Size = UDim2.new(0.485, 0, 1, 0); rightCol.Position = UDim2.new(0.515, 0, 0, 0); rightCol.BackgroundTransparency = 1
    
    local lLayout = Instance.new("UIListLayout", leftCol); lLayout.Padding = UDim.new(0, 12); lLayout.SortOrder = Enum.SortOrder.LayoutOrder
    local rLayout = Instance.new("UIListLayout", rightCol); rLayout.Padding = UDim.new(0, 12); rLayout.SortOrder = Enum.SortOrder.LayoutOrder

    local function updateSize()
        local h = math.max(lLayout.AbsoluteContentSize.Y, rLayout.AbsoluteContentSize.Y)
        page.CanvasSize = UDim2.new(0, 0, 0, h + 25)
    end
    lLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(updateSize)
    rLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(updateSize)

    Tabs[name] = page
    btn.MouseButton1Click:Connect(function() SelectTab(name) end)
    return leftCol, rightCol
end

local function CreateSection(parent, title)
    local sec = Instance.new("Frame", parent)
    sec.Size = UDim2.new(1, 0, 0, 0); sec.AutomaticSize = Enum.AutomaticSize.Y; sec.BackgroundColor3 = Theme.SectionBg
    Instance.new("UICorner", sec).CornerRadius = UDim.new(0, 8)
    local secStroke = Instance.new("UIStroke", sec)
    secStroke.Color = Theme.Border

    local lbl = Instance.new("TextLabel", sec)
    lbl.Size = UDim2.new(1, -20, 0, 35); lbl.Position = UDim2.new(0, 10, 0, 0); lbl.BackgroundTransparency = 1
    lbl.Text = title:upper(); lbl.TextColor3 = Theme.Accent; lbl.Font = Enum.Font.GothamBold; lbl.TextSize = 11; lbl.TextXAlignment = Enum.TextXAlignment.Left

    local container = Instance.new("Frame", sec)
    container.Size = UDim2.new(1, -20, 0, 0); container.Position = UDim2.new(0, 10, 0, 35); container.AutomaticSize = Enum.AutomaticSize.Y; container.BackgroundTransparency = 1
    local layout = Instance.new("UIListLayout", container)
    layout.Padding = UDim.new(0, 10); layout.SortOrder = Enum.SortOrder.LayoutOrder
    
    local pad = Instance.new("UIPadding", container); pad.PaddingBottom = UDim.new(0, 12)

    return container
end

local function AddCheckbox(parent, text, key, callback)
    local f = Instance.new("Frame", parent)
    f.Size = UDim2.new(1, 0, 0, 26); f.BackgroundTransparency = 1

    local btn = Instance.new("TextButton", f)
    btn.Size = UDim2.new(0, 22, 0, 22); btn.BackgroundColor3 = Theme.MainBg
    btn.BorderSizePixel = 0; btn.Text = ""; btn.Position = UDim2.new(0, 0, 0.5, -11)
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 5)
    local stroke = Instance.new("UIStroke", btn); stroke.Color = Theme.Border

    local check = Instance.new("Frame", btn)
    check.Size = UDim2.new(0, 12, 0, 12); check.Position = UDim2.new(0.5, -6, 0.5, -6)
    check.BackgroundColor3 = Theme.Accent; check.BackgroundTransparency = Toggles[key] and 0 or 1
    Instance.new("UICorner", check).CornerRadius = UDim.new(0, 3)

    local lbl = Instance.new("TextLabel", f)
    lbl.Size = UDim2.new(1, -34, 1, 0); lbl.Position = UDim2.new(0, 34, 0, 0); lbl.BackgroundTransparency = 1
    lbl.Text = text; lbl.TextColor3 = Theme.TextDark; lbl.Font = Enum.Font.GothamMedium; lbl.TextSize = 13; lbl.TextXAlignment = Enum.TextXAlignment.Left

    local function update()
        Toggles[key] = not Toggles[key]
        Tween(check, {BackgroundTransparency = Toggles[key] and 0 or 1}, 0.15)
        Tween(stroke, {Color = Toggles[key] and Theme.Accent or Theme.Border}, 0.15)
        Tween(lbl, {TextColor3 = Toggles[key] and Theme.Text or Theme.TextDark}, 0.15)
        if callback then callback(Toggles[key]) end
    end
    btn.MouseButton1Click:Connect(update)
    
    if Toggles[key] then 
        stroke.Color = Theme.Accent
        lbl.TextColor3 = Theme.Text 
    end
end

-- ОБНОВЛЕННАЯ ФУНКЦИЯ ПОЛЗУНКА (SLIDER) - С ТОЧКОЙ И ПОДДЕРЖКОЙ МОБИЛОК
local function AddSlider(parent, text, min, max, default, key, isFloat, callback)
    local f = Instance.new("Frame", parent)
    f.Size = UDim2.new(1, 0, 0, 42); f.BackgroundTransparency = 1

    local lbl = Instance.new("TextLabel", f)
    lbl.Size = UDim2.new(1, 0, 0, 18); lbl.BackgroundTransparency = 1
    lbl.Text = text; lbl.TextColor3 = Theme.Text; lbl.Font = Enum.Font.GothamMedium; lbl.TextSize = 13; lbl.TextXAlignment = Enum.TextXAlignment.Left

    local valText = Instance.new("TextLabel", f)
    valText.Size = UDim2.new(0, 60, 0, 18); valText.Position = UDim2.new(1, -60, 0, 0); valText.BackgroundTransparency = 1
    valText.Text = isFloat and string.format("%.2f", default) or tostring(default)
    valText.TextColor3 = Theme.Accent; valText.Font = Enum.Font.GothamBold; valText.TextSize = 13; valText.TextXAlignment = Enum.TextXAlignment.Right

    local barBg = Instance.new("Frame", f)
    barBg.Size = UDim2.new(1, -14, 0, 6); barBg.Position = UDim2.new(0, 7, 0, 26); barBg.BackgroundColor3 = Theme.MainBg; barBg.BorderSizePixel = 0
    Instance.new("UICorner", barBg).CornerRadius = UDim.new(1, 0)

    local barFill = Instance.new("Frame", barBg)
    barFill.Size = UDim2.new((default-min)/(max-min), 0, 1, 0); barFill.BackgroundColor3 = Theme.Accent; barFill.BorderSizePixel = 0
    Instance.new("UICorner", barFill).CornerRadius = UDim.new(1, 0)

    -- Добавляем белую точку (Dot) на ползунок
    local dragDot = Instance.new("Frame", barFill)
    dragDot.Size = UDim2.new(0, 14, 0, 14)
    dragDot.Position = UDim2.new(1, -7, 0.5, -7)
    dragDot.BackgroundColor3 = Color3.fromRGB(245, 245, 245)
    Instance.new("UICorner", dragDot).CornerRadius = UDim.new(1, 0)

    -- Увеличенный хитбокс кнопки для мобилок
    local btn = Instance.new("TextButton", barBg)
    btn.Size = UDim2.new(1, 30, 1, 24); btn.Position = UDim2.new(0, -15, 0, -12); btn.BackgroundTransparency = 1; btn.Text = ""

    local dragging = false
    btn.MouseButton1Down:Connect(function() dragging = true; Tween(dragDot, {Size = UDim2.new(0, 18, 0, 18), Position = UDim2.new(1, -9, 0.5, -9)}, 0.1) end)
    UserInputService.InputEnded:Connect(function(input) 
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then 
            dragging = false
            Tween(dragDot, {Size = UDim2.new(0, 14, 0, 14), Position = UDim2.new(1, -7, 0.5, -7)}, 0.1)
        end 
    end)
    
    local function updateValue(input)
        local pct = math.clamp((input.Position.X - barBg.AbsolutePosition.X) / barBg.AbsoluteSize.X, 0, 1)
        Tween(barFill, {Size = UDim2.new(pct, 0, 1, 0)}, 0.05)
        local val = min + (max - min) * pct
        if not isFloat then val = math.floor(val) end
        valText.Text = isFloat and string.format("%.2f", val) or tostring(val)
        Toggles[key] = val
        if callback then callback(val) end
    end

    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            updateValue(input)
        end
    end)
    btn.MouseButton1Click:Connect(function()
        local mousePos = UserInputService:GetMouseLocation()
        local framePos = barBg.AbsolutePosition
        local pct = math.clamp((mousePos.X - framePos.X) / barBg.AbsoluteSize.X, 0, 1)
        Tween(barFill, {Size = UDim2.new(pct, 0, 1, 0)}, 0.05)
        local val = min + (max - min) * pct
        if not isFloat then val = math.floor(val) end
        valText.Text = isFloat and string.format("%.2f", val) or tostring(val)
        Toggles[key] = val
        if callback then callback(val) end
    end)
end

local function AddDropdown(parent, text, options, default, key, callback)
    local f = Instance.new("Frame", parent)
    f.Size = UDim2.new(1, 0, 0, 52); f.BackgroundTransparency = 1
    
    local lbl = Instance.new("TextLabel", f)
    lbl.Size = UDim2.new(1, 0, 0, 18); lbl.BackgroundTransparency = 1
    lbl.Text = text; lbl.TextColor3 = Theme.Text; lbl.Font = Enum.Font.GothamMedium; lbl.TextSize = 13; lbl.TextXAlignment = Enum.TextXAlignment.Left
    
    local btn = Instance.new("TextButton", f)
    btn.Size = UDim2.new(1, 0, 0, 28); btn.Position = UDim2.new(0, 0, 0, 22); btn.BackgroundColor3 = Theme.MainBg
    btn.Text = "  " .. default; btn.TextColor3 = Theme.Accent; btn.Font = Enum.Font.GothamBold; btn.TextSize = 13; btn.TextXAlignment = Enum.TextXAlignment.Left
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 5)
    local stroke = Instance.new("UIStroke", btn); stroke.Color = Theme.Border
    
    local dropIcon = Instance.new("TextLabel", btn)
    dropIcon.Size = UDim2.new(0, 20, 1, 0); dropIcon.Position = UDim2.new(1, -25, 0, 0); dropIcon.BackgroundTransparency = 1
    dropIcon.Text = "▼"; dropIcon.TextColor3 = Theme.TextDark; dropIcon.Font = Enum.Font.Gotham; dropIcon.TextSize = 11
    
    local currentIndex = 1
    for i, v in ipairs(options) do if v == default then currentIndex = i break end end
    
    btn.MouseButton1Click:Connect(function()
        currentIndex = currentIndex + 1
        if currentIndex > #options then currentIndex = 1 end
        Toggles[key] = options[currentIndex]
        btn.Text = "  " .. options[currentIndex]
        if callback then callback(options[currentIndex]) end
    end)
end

----------------------------------------------------------------
-- [ ПОСТРОЕНИЕ ВКЛАДОК ] --
----------------------------------------------------------------
local lAim, rAim = CreateTab("Aimbot")
local lWeap, rWeap = CreateTab("Weapon")
local lEsp, rEsp = CreateTab("ESP")
local lPlr, rPlr = CreateTab("Player")
local lWld, rWld = CreateTab("World")

-- Вкладка: Aimbot
local secAimMain = CreateSection(lAim, "Основной Aimbot")
AddCheckbox(secAimMain, "Включить Silent Aim", "SilentAim")
AddCheckbox(secAimMain, "Включить Camera Aimbot", "CamAimbot")
AddCheckbox(secAimMain, "Включить TriggerBot", "TriggerBot")
AddDropdown(secAimMain, "Часть Тела", {"Head", "Torso", "Random"}, "Head", "AimPart")
AddSlider(secAimMain, "Скорость/Плавность аима", 1, 100, 20, "AimSmooth") -- Обновленный слайдер до 100

local secAimSet = CreateSection(rAim, "Фильтры и Настройки")
AddCheckbox(secAimSet, "Игнорировать друзей", "IgnoreFriends")
AddCheckbox(secAimSet, "Игнорировать клан/тимейтов", "IgnoreClan")
AddCheckbox(secAimSet, "Только на ЛКМ", "OnlyOnHit")
AddCheckbox(secAimSet, "Звук попадания", "HitSound")

local secFov = CreateSection(rAim, "Настройки FOV")
AddCheckbox(secFov, "Показать FOV", "DrawFov")
AddCheckbox(secFov, "Динамический FOV", "DynamicFov")
AddSlider(secFov, "Радиус FOV", 50, 1000, 150, "FovRadius")

-- Вкладка: Weapon
local secWeapMods = CreateSection(lWeap, "Модификации Оружия")
AddCheckbox(secWeapMods, "Без отдачи (No Recoil)", "NoRecoil")
AddCheckbox(secWeapMods, "Без разброса (No Spread)", "NoSpread")
AddCheckbox(secWeapMods, "Макс. скорость пули", "MaxVel")
AddCheckbox(secWeapMods, "Нулевая гравитация пуль", "ZeroGrav")

local secMiscFarm = CreateSection(rWeap, "Авто-Фарм")
AddCheckbox(secMiscFarm, "Авто-удары по руде (Звезда)", "AutoOre")
AddCheckbox(secMiscFarm, "Авто-удары по дереву (Крестик)", "AutoTree")

-- Вкладка: ESP
local secEspMain = CreateSection(lEsp, "Визуальные Функции")
AddCheckbox(secEspMain, "ESP на Игроков", "PlayerEsp")
AddCheckbox(secEspMain, "ESP на Ботов", "BotEsp")
AddCheckbox(secEspMain, "2D Боксы", "EspBox")
AddCheckbox(secEspMain, "Скелеты", "EspSkeleton")
AddCheckbox(secEspMain, "Линии (Tracers)", "EspLines")
AddCheckbox(secEspMain, "Проверка видимости (VisCheck)", "VisCheck")

local secDisplay = CreateSection(rEsp, "Отображение Информации")
AddCheckbox(secDisplay, "Имена", "EspName")
AddCheckbox(secDisplay, "Дистанция", "EspDistance")
AddCheckbox(secDisplay, "Здоровье", "EspHealth")
AddCheckbox(secDisplay, "Иконка оружия", "EspWeapon")
AddCheckbox(secDisplay, "Маркер цели", "TargetMarker")
AddCheckbox(secDisplay, "Панель радара", "EspCount")

local secEspSet = CreateSection(lEsp, "Настройки ESP")
AddSlider(secEspSet, "Макс. дистанция", 50, 5000, 2000, "EspMaxDist")
AddSlider(secEspSet, "Размер шрифта", 10, 30, 12, "FontSize")
AddSlider(secEspSet, "Толщина линий", 1, 5, 1, "LineThickness", true)
AddSlider(secEspSet, "Плавность маркера", 1, 20, 8, "SmoothSpeed")

----------------------------------------------------------------
-- [ ВИЗУАЛЬНЫЙ NOCLIP / GHOST MODE (МОБИЛЬНАЯ ВЕРСИЯ) ] --
----------------------------------------------------------------
local secPlrMove = CreateSection(lPlr, "Движение Персонажа")
AddCheckbox(secPlrMove, "Visual Noclip (Ghost Mode / TP back)", "Noclip", function(val)
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChild("Humanoid")
    
    if val then
        if UserInputService.TouchEnabled then MobileNoclipUI.Visible = true end -- Показываем кнопки для мобилок
        
        if hrp and hum then
            Freecam.SavedCFrame = hrp.CFrame
            hrp.Anchored = true 
            
            Freecam.CamPart = Instance.new("Part")
            Freecam.CamPart.Size = Vector3.new(1, 1, 1)
            Freecam.CamPart.Transparency = 1
            Freecam.CamPart.CanCollide = false
            Freecam.CamPart.Anchored = true
            Freecam.CamPart.CFrame = hrp.CFrame
            Freecam.CamPart.Parent = Workspace
            
            Camera.CameraSubject = Freecam.CamPart
            
            Freecam.RenderConn = RunService.RenderStepped:Connect(function(dt)
                if not Freecam.CamPart then return end
                local moveDir = Vector3.new()
                local lookVec = Camera.CFrame.LookVector
                local rightVec = Camera.CFrame.RightVector
                
                -- Поддержка ПК клавиатуры
                if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveDir = moveDir + lookVec end
                if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveDir = moveDir - lookVec end
                if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveDir = moveDir - rightVec end
                if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveDir = moveDir + rightVec end
                if UserInputService:IsKeyDown(Enum.KeyCode.Space) or Freecam.IsUp then moveDir = moveDir + Vector3.new(0, 1, 0) end
                if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) or Freecam.IsDown then moveDir = moveDir - Vector3.new(0, 1, 0) end
                
                -- Поддержка Мобильного джойстика
                if hum.MoveDirection.Magnitude > 0 then
                    moveDir = moveDir + hum.MoveDirection
                end
                
                if moveDir.Magnitude > 0 then
                    moveDir = moveDir.Unit
                end
                
                local speed = Toggles.GhostSpeed or 50
                Freecam.CamPart.CFrame = Freecam.CamPart.CFrame + (moveDir * speed * dt)
            end)
        end
    else
        MobileNoclipUI.Visible = false -- Скрываем мобильный UI
        Freecam.Active = false
        if Freecam.RenderConn then Freecam.RenderConn:Disconnect() end
        if Freecam.CamPart then Freecam.CamPart:Destroy() end
        
        if hrp then
            if Freecam.SavedCFrame then
                hrp.CFrame = Freecam.SavedCFrame
            end
            hrp.Anchored = false
        end
        
        if hum then Camera.CameraSubject = hum end
    end
end)
AddSlider(secPlrMove, "Скорость полета (Ghost)", 10, 300, 50, "GhostSpeed")

AddCheckbox(secPlrMove, "Бесконечный прыжок", "InfJump")

AddSlider(secPlrMove, "Скорость бега (WalkSpeed)", 16, 250, 16, "WalkSpeed", false, function(val)
    local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid")
    if hum then hum.WalkSpeed = val end
end)

AddSlider(secPlrMove, "Сила прыжка (JumpPower)", 50, 350, 50, "JumpPower", false, function(val)
    local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid")
    if hum then 
        hum.JumpPower = val 
        hum.UseJumpPower = true
    end
end)

local secPlrMisc = CreateSection(rPlr, "Дополнительно")
AddCheckbox(secPlrMisc, "Просмотрщик инвентаря цели", "InventoryViewer")

-- Вкладка: World
local secWorldEnv = CreateSection(lWld, "Окружение мира")
AddCheckbox(secWorldEnv, "Режим Fullbright", "Fullbright")
AddCheckbox(secWorldEnv, "Убрать траву", "NoGrass")
AddCheckbox(secWorldEnv, "Убрать листья", "NoLeaves")
AddSlider(secWorldEnv, "Время суток (Часы)", 0, 24, 14, "TimeOfDay")

local secWorldChams = CreateSection(rWld, "Подсветка ресурсов")
AddCheckbox(secWorldChams, "Hemp (Конопля) ESP", "HempEsp")
AddCheckbox(secWorldChams, "Crates (Ящики) ESP", "CrateEsp")
AddCheckbox(secWorldChams, "Рюкзаки после смерти ESP", "BpEsp")
AddCheckbox(secWorldChams, "Шкафы (Tool Cupboards) ESP", "TcEsp")

SelectTab("Aimbot")

----------------------------------------------------------------
-- [ ЛОГИКА ФИЛЬТРОВ И ВАЛИДАЦИИ ЦЕЛИ ] --
----------------------------------------------------------------
local function IsValidTarget(player)
    if player == LocalPlayer then return false end
    if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then return false end
    if player.Character:FindFirstChild("Humanoid") and player.Character.Humanoid.Health <= 0 then return false end
    if Toggles.IgnoreFriends and LocalPlayer:IsFriendsWith(player.UserId) then return false end
    if Toggles.IgnoreClan and player.Team ~= nil and player.Team == LocalPlayer.Team then return false end
    return true
end

-- Логика хит-маркера
local function SetupHitDetection(player)
    local function onChar(char)
        local hum = char:WaitForChild("Humanoid", 5)
        if hum then
            local oldHp = hum.Health
            hum.HealthChanged:Connect(function(newHp)
                if newHp < oldHp and Toggles.HitSound then
                    if Cache.SilentTarget and Cache.SilentTarget.Parent == char then
                        local snd = Instance.new("Sound", SoundService)
                        snd.SoundId = "rbxassetid://135478009117226"; snd.Volume = 3; snd:Play()
                        snd.Ended:Connect(function() snd:Destroy() end)
                    end
                end
                oldHp = newHp
            end)
        end
    end
    player.CharacterAdded:Connect(onChar)
    if player.Character then onChar(player.Character) end
end
for _, p in pairs(Players:GetPlayers()) do if p ~= LocalPlayer then SetupHitDetection(p) end end
Players.PlayerAdded:Connect(SetupHitDetection)

----------------------------------------------------------------
-- [ ОБНОВЛЕНИЕ ОКРУЖЕНИЯ И ХАРАКТЕРИСТИК ] --
----------------------------------------------------------------
local function UpdateEnv()
    Lighting.ClockTime = Toggles.TimeOfDay
    if Toggles.Fullbright then 
        Lighting.Ambient = Color3.fromRGB(255,255,255); Lighting.OutdoorAmbient = Color3.fromRGB(255,255,255)
        Lighting.GlobalShadows = false 
    else 
        Lighting.Ambient = Color3.fromRGB(127,127,127); Lighting.OutdoorAmbient = Color3.fromRGB(127,127,127)
        Lighting.GlobalShadows = true 
    end
    
    pcall(function() if Workspace:FindFirstChild("Terrain") then Workspace.Terrain.Decoration = not Toggles.NoGrass end end)
    
    if Toggles.NoLeaves then 
        local tr = Workspace:FindFirstChild("trees") or Workspace:FindFirstChild("Trees")
        if tr then for _, i in ipairs(tr:GetDescendants()) do 
            if i:IsA("BasePart") and (i.Name:lower():find("leaf") or i.Name:lower():find("leavestop")) then 
                i.Transparency = 1; i.CanCollide = false 
            end 
        end end 
    end
end

-- Бесконечный прыжок
UserInputService.JumpRequest:Connect(function()
    if Toggles.InfJump and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
        LocalPlayer.Character.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
    end
end)

-- Постоянный цикл проверки характеристик (Защита от сброса при спавне)
task.spawn(function()
    while task.wait(0.2) do
        local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid")
        if hum then
            if hum.WalkSpeed ~= Toggles.WalkSpeed then 
                hum.WalkSpeed = Toggles.WalkSpeed 
            end
            if Toggles.JumpPower ~= 50 then 
                hum.JumpPower = Toggles.JumpPower
                hum.UseJumpPower = true 
            end
        end
    end
end)

----------------------------------------------------------------
-- [ ОРУЖЕЙНЫЕ МОДЫ И СТРУКТУРА HOOKS ] --
----------------------------------------------------------------
task.spawn(function()
    while task.wait(2) do
        pcall(function()
            for _, v in pairs(getgc(true)) do
                if type(v) == "table" then
                    if rawget(v, "BaseBulletVelocity") and Toggles.MaxVel then v.BaseBulletVelocity = 999999; v.Velocity = 999999 end
                    if rawget(v, "BulletGravity") and Toggles.ZeroGrav then v.BulletGravity = 0; v.Gravity = 0 end
                    if rawget(v, "TotalAttachmentStats") then
                        local s = v.TotalAttachmentStats
                        if Toggles.NoSpread then s.SpreadMult = 0; s.PelletSpread = 0 end
                        if Toggles.NoRecoil then s.RecoilMult = 0; s.KickMult = 0 end
                    end
                    
                    if rawget(v, "getfireDirection") and not Cache.ToolModHooked then
                        local oldDir = v.getfireDirection
                        v.getfireDirection = function(self, origin, raycast)
                            local isShooting = UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) or UserInputService:IsMouseButtonPressed(Enum.UserInputType.Touch)
                            if Toggles.SilentAim and Cache.SilentTarget then 
                                if not Toggles.OnlyOnHit or (Toggles.OnlyOnHit and isShooting) then
                                    return (Cache.SilentTarget.Position - origin).Unit 
                                end
                            end
                            return oldDir(self, origin, raycast)
                        end
                        
                        if rawget(v, "hit") then
                            local oldHit = v.hit
                            v.hit = function(self, inst, pos)
                                local tI, tP = inst, pos
                                if Toggles.AutoOre or Toggles.AutoTree then
                                    local c = self.OwnerPlayer and self.OwnerPlayer.Character
                                    if c and c:FindFirstChild("HumanoidRootPart") then
                                        local mp = c.HumanoidRootPart.Position; local cp, md = nil, 20
                                        for _, obj in ipairs(Workspace:GetDescendants()) do
                                            if obj:IsA("BasePart") and ((obj.Name == "star" and Toggles.AutoOre) or (obj.Name == "cross" and Toggles.AutoTree)) then
                                                local d = (mp - obj.Position).Magnitude
                                                if d < md then cp = obj; md = d end
                                            end
                                        end
                                        if cp then tI = cp; tP = cp.Position end
                                    end
                                end
                                return oldHit(self, tI, tP)
                            end
                        end
                        Cache.ToolModHooked = true
                    end
                end
            end
        end)
    end
end)

----------------------------------------------------------------
-- [ ESP И ИНТЕЛЛЕКТУАЛЬНЫЙ РЕНДЕР ] --
----------------------------------------------------------------
local function CreateVisualsStruct()
    local obj = {
        Box = Drawing.new("Square"), BoxOut = Drawing.new("Square"),
        Name = Drawing.new("Text"), Dist = Drawing.new("Text"), Health = Drawing.new("Text"),
        Line = Drawing.new("Line"), Img = Instance.new("ImageLabel", EspGui),
        Skeleton = {}
    }
    obj.Box.Thickness = 1; obj.Box.Color = Color3.new(1,1,1); obj.Box.Transparency = 1; obj.Box.Filled = false
    obj.BoxOut.Thickness = 3; obj.BoxOut.Color = Color3.new(0,0,0); obj.BoxOut.Transparency = 0.5; obj.BoxOut.Filled = false
    obj.Name.Outline = true; obj.Name.Center = true; obj.Name.Font = 2; obj.Name.Color = Color3.new(1,1,1)
    obj.Dist.Outline = true; obj.Dist.Center = true; obj.Dist.Color = Theme.TextDark; obj.Dist.Font = 2
    obj.Health.Outline = true; obj.Health.Center = true; obj.Health.Color = Color3.new(0, 1, 0); obj.Health.Font = 2
    obj.Line.Color = Color3.new(1,1,1); obj.Img.BackgroundTransparency = 1; obj.Img.Size = UDim2.new(0, 50, 0, 50); obj.Img.Visible = false
    for i = 1, 15 do local l = Drawing.new("Line"); l.Thickness = 1; l.Color = Color3.new(1,1,1); table.insert(obj.Skeleton, l) end
    return obj
end

local function CleanStruct(struct)
    if not struct then return end
    for _, v in pairs(struct) do
        if type(v) == "table" then for _, l in pairs(v) do l:Remove() end
        elseif typeof(v) == "Instance" then v:Destroy() else v:Remove() end 
    end
end

for _, p in pairs(Players:GetPlayers()) do if p ~= LocalPlayer then Cache.PlayerVisuals[p] = CreateVisualsStruct() end end
Players.PlayerAdded:Connect(function(p) Cache.PlayerVisuals[p] = CreateVisualsStruct() end)
Players.PlayerRemoving:Connect(function(p) CleanStruct(Cache.PlayerVisuals[p]); Cache.PlayerVisuals[p] = nil end)

local function DrawSkeleton(char, espTable)
    for i = 1, 15 do espTable.Skeleton[i].Visible = false end
    if not Toggles.EspSkeleton then return end
    local isR15 = char:FindFirstChild("UpperTorso") ~= nil
    local pairsToDraw = isR15 and {
        {"Head", "UpperTorso"}, {"UpperTorso", "LowerTorso"}, {"UpperTorso", "LeftUpperArm"}, {"LeftUpperArm", "LeftLowerArm"}, {"LeftLowerArm", "LeftHand"},
        {"UpperTorso", "RightUpperArm"}, {"RightUpperArm", "RightLowerArm"}, {"RightLowerArm", "RightHand"},
        {"LowerTorso", "LeftUpperLeg"}, {"LeftUpperLeg", "LeftLowerLeg"}, {"LeftLowerLeg", "LeftFoot"},
        {"LowerTorso", "RightUpperLeg"}, {"RightUpperLeg", "RightLowerLeg"}, {"RightLowerLeg", "RightFoot"}
    } or { {"Head", "Torso"}, {"Torso", "Left Arm"}, {"Torso", "Right Arm"}, {"Torso", "Left Leg"}, {"Torso", "Right Leg"} }

    for i, pair in ipairs(pairsToDraw) do
        local p1, p2 = char:FindFirstChild(pair[1]), char:FindFirstChild(pair[2])
        if p1 and p2 then
            local pos1, on1 = Camera:WorldToViewportPoint(p1.Position)
            local pos2, on2 = Camera:WorldToViewportPoint(p2.Position)
            if on1 and on2 then
                espTable.Skeleton[i].Visible = true
                espTable.Skeleton[i].From = Vector2.new(pos1.X, pos1.Y)
                espTable.Skeleton[i].To = Vector2.new(pos2.X, pos2.Y)
            end
        end
    end
end

local function GetBots()
    local bots = {}
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("Model") and obj:FindFirstChild("Humanoid") and obj:FindFirstChild("HumanoidRootPart") then
            if not Players:GetPlayerFromCharacter(obj) and obj ~= LocalPlayer.Character then table.insert(bots, obj) end
        end
    end
    return bots
end

task.spawn(function()
    while task.wait(2) do
        UpdateEnv()
        if Toggles.BotEsp then
            local cb = GetBots(); local map = {}
            for _, b in ipairs(cb) do
                map[b] = true
                if not Cache.BotVisuals[b] then Cache.BotVisuals[b] = CreateVisualsStruct(); Cache.BotVisuals[b].Box.Color = Color3.fromRGB(155, 89, 182) end
            end
            for b, v in pairs(Cache.BotVisuals) do if not map[b] or not b.Parent then CleanStruct(v); Cache.BotVisuals[b] = nil end end
        else
            for b, v in pairs(Cache.BotVisuals) do CleanStruct(v) end; table.clear(Cache.BotVisuals)
        end
    end
end)

----------------------------------------------------------------
-- [ ГЛАВНЫЙ ЦИКЛ RENDER STEPPED ] --
----------------------------------------------------------------
RunService.RenderStepped:Connect(function()
    local center = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
    -- Проверка на стрельбу/зажатие с мобилки и ПК
    local isShooting = UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) or UserInputService:IsMouseButtonPressed(Enum.UserInputType.Touch)
    
    local targetRadius = Toggles.DynamicFov and (Toggles.FovRadius / Camera.FieldOfView) * 80 or Toggles.FovRadius
    local targetColor = isShooting and Color3.fromRGB(255, 50, 50) or Toggles.FovColor
    local targetThickness = isShooting and 2 or Toggles.LineThickness
    
    FOV_State.CurrentRadius = FOV_State.CurrentRadius + (targetRadius - FOV_State.CurrentRadius) * 0.2
    FOV_State.CurrentColor = FOV_State.CurrentColor:Lerp(targetColor, 0.2)
    FOV_State.CurrentThickness = FOV_State.CurrentThickness + (targetThickness - FOV_State.CurrentThickness) * 0.2
    
    UI_Elements.FovCircle.Position = center; UI_Elements.FovCircle.Radius = FOV_State.CurrentRadius
    UI_Elements.FovCircle.Color = FOV_State.CurrentColor; UI_Elements.FovCircle.Thickness = FOV_State.CurrentThickness
    UI_Elements.FovCircle.Visible = Toggles.DrawFov
    
    local target, t_dist = nil, FOV_State.CurrentRadius
    local countPlr, countBot = 0, 0

    local function ProcessESP(entity, esp, isBot)
        local isVisible = false
        if entity and entity:FindFirstChild("HumanoidRootPart") and entity:FindFirstChild("Humanoid") and entity.Humanoid.Health > 0 then
            local hrp = entity.HumanoidRootPart
            local dist = (Camera.CFrame.Position - hrp.Position).Magnitude
            local pos, on = Camera:WorldToViewportPoint(hrp.Position)
            
            if on then
                local aimPartObj = entity:FindFirstChild(Toggles.AimPart == "Random" and (math.random(1,2)==1 and "Head" or "HumanoidRootPart") or (Toggles.AimPart == "Torso" and "HumanoidRootPart" or "Head")) or entity:FindFirstChild("Head")
                if aimPartObj and not isBot and IsValidTarget(Players:GetPlayerFromCharacter(entity)) then
                    local partPos = Camera:WorldToViewportPoint(aimPartObj.Position)
                    local m = (Vector2.new(partPos.X, partPos.Y) - center).Magnitude
                    if m < t_dist then t_dist = m; target = aimPartObj end
                end

                if (isBot and Toggles.BotEsp or not isBot and Toggles.PlayerEsp) and dist <= Toggles.EspMaxDist then
                    local passVis = true
                    if Toggles.VisCheck then
                        local ray = Ray.new(Camera.CFrame.Position, (hrp.Position - Camera.CFrame.Position).Unit * 500)
                        local hit = Workspace:FindPartOnRayWithIgnoreList(ray, {LocalPlayer.Character, entity})
                        if hit then passVis = false end
                    end

                    if passVis then
                        isVisible = true
                        if isBot then countBot = countBot + 1 else countPlr = countPlr + 1 end

                        local head = Camera:WorldToViewportPoint(entity:FindFirstChild("Head").Position + Vector3.new(0, 0.5, 0))
                        local foot = Camera:WorldToViewportPoint(hrp.Position - Vector3.new(0, 3, 0))
                        local h = math.abs(head.Y - foot.Y); local w = h / 1.5
                        
                        esp.Box.Visible = Toggles.EspBox; esp.Box.Size = Vector2.new(w, h); esp.Box.Position = Vector2.new(pos.X - w/2, pos.Y - h/2)
                        esp.BoxOut.Visible = Toggles.EspBox; esp.BoxOut.Size = esp.Box.Size; esp.BoxOut.Position = esp.Box.Position
                        
                        esp.Name.Visible = Toggles.EspName; esp.Name.Text = (isBot and "[BOT] " or "") .. entity.Name
                        esp.Name.Position = Vector2.new(pos.X, pos.Y - h/2 - Toggles.FontSize - 5); esp.Name.Size = Toggles.FontSize
                        if isBot then esp.Name.Color = Color3.fromRGB(155, 89, 182) end

                        local bottom = pos.Y + h/2
                        esp.Health.Visible = Toggles.EspHealth
                        if Toggles.EspHealth then 
                            esp.Health.Text = math.floor(entity.Humanoid.Health).." HP"
                            esp.Health.Position = Vector2.new(pos.X, bottom); esp.Health.Size = Toggles.FontSize - 2; bottom = bottom + Toggles.FontSize 
                            esp.Health.Color = Color3.fromHSV(math.clamp(entity.Humanoid.Health / entity.Humanoid.MaxHealth, 0, 1) * 0.3, 1, 1)
                        end

                        esp.Dist.Visible = Toggles.EspDistance
                        if Toggles.EspDistance then esp.Dist.Text = math.floor(dist).."m"; esp.Dist.Position = Vector2.new(pos.X, bottom); esp.Dist.Size = Toggles.FontSize - 2; bottom = bottom + Toggles.FontSize end
                        
                        esp.Img.Visible = false
                        if Toggles.EspWeapon and not isBot then
                            local tool = entity:FindFirstChildOfClass("Tool")
                            if tool and tool.TextureId ~= "" then esp.Img.Visible = true; esp.Img.Image = tool.TextureId; esp.Img.Position = UDim2.new(0, pos.X - 25, 0, bottom - 5) end
                        end
                        
                        esp.Line.Visible = Toggles.EspLines; esp.Line.Thickness = Toggles.LineThickness; esp.Line.From = Vector2.new(center.X, Camera.ViewportSize.Y); esp.Line.To = Vector2.new(pos.X, pos.Y + h/2)
                        if isBot then esp.Line.Color = Color3.fromRGB(155, 89, 182) end
                        
                        DrawSkeleton(entity, esp)
                    end
                end
            end
        end
        if not isVisible then 
            esp.Box.Visible = false; esp.BoxOut.Visible = false; esp.Name.Visible = false; esp.Dist.Visible = false
            esp.Health.Visible = false; esp.Line.Visible = false; esp.Img.Visible = false
            for i = 1, 15 do esp.Skeleton[i].Visible = false end
        end
    end

    for p, esp in pairs(Cache.PlayerVisuals) do ProcessESP(p.Character, esp, false) end
    for b, esp in pairs(Cache.BotVisuals) do ProcessESP(b, esp, true) end
    
    CounterFrame.Visible = Toggles.EspCount
    if Toggles.EspCount then CounterLabel.Text = string.format("📡 РАДАР: %d ИГРОКОВ | %d БОТОВ", countPlr, countBot) end

    Cache.SilentTarget = target
    
    UI_Elements.TargetDot.Visible = (target ~= nil and Toggles.TargetMarker)
    if target then 
        local p = Camera:WorldToViewportPoint(target.Position)
        local endPos = Vector2.new(p.X, p.Y)
        if Toggles.SmoothSpeed < 20 then
            UI_Elements.TargetDot.Position = UI_Elements.TargetDot.Position:Lerp(endPos, Toggles.SmoothSpeed / 30)
        else UI_Elements.TargetDot.Position = endPos end
        
        -- Обновленный Camera Aimbot (Плавная доводка)
        if Toggles.CamAimbot and isShooting then
            local targetCFrame = CFrame.new(Camera.CFrame.Position, target.Position)
            -- Формула плавности (100 - моментально, 1 - очень плавно)
            local smoothAmount = math.clamp(Toggles.AimSmooth / 100, 0.01, 1)
            Camera.CFrame = Camera.CFrame:Lerp(targetCFrame, smoothAmount)
        end
        
        if Toggles.TriggerBot and not isShooting then
            local mTarget = Mouse.Target
            if mTarget and mTarget:IsDescendantOf(target.Parent) then
                if mouse1click then mouse1click() end
            end
        end
    end
end)

task.spawn(function()
    while task.wait(1) do
        if Toggles.InventoryViewer and Cache.SilentTarget then
            UpdateInventory(Players:GetPlayerFromCharacter(Cache.SilentTarget.Parent))
            InvFrame.Visible = true
        else InvFrame.Visible = false end
    end
end)

----------------------------------------------------------------
-- [ ПЕРЕТАСКИВАНИЕ ОКОН (DRAG) ] --
----------------------------------------------------------------
local function MakeDraggable(topbar, frame)
    local dragging, dragStart, startPos
    topbar.InputBegan:Connect(function(input) 
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then 
            dragging = true; dragStart = input.Position; startPos = frame.Position 
        end 
    end)
    UserInputService.InputChanged:Connect(function(input) 
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then 
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y) 
        end 
    end)
    UserInputService.InputEnded:Connect(function(input) 
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = false end 
    end)
end

MakeDraggable(TopBar, Main)
MakeDraggable(InvTitle, InvFrame)

print("LebroTools V3.1 успешно запущен! Нажми 'LT' для открытия/закрытия меню.")
