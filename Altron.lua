if not game:IsLoaded() then
    game.Loaded:Wait()
end

--------------------------------------------------------------------------------
-- Инициализация сервисов
--------------------------------------------------------------------------------
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Camera = Workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer
local isMobile = UserInputService.TouchEnabled

local Toggles = {} 
local Cache = {CurrentSilentTarget = nil, Connections = {}}

--------------------------------------------------------------------------------
-- АНТИ-ЧИТ БАЙПАСС И ОПТИМИЗИРОВАННЫЕ ХУКИ (С НУЛЕВЫМ ВЛИЯНИЕМ НА FPS)
--------------------------------------------------------------------------------
pcall(function()
    local replicatedStorageService = game:GetService("ReplicatedStorage")
    local rayCastHandlerModule = replicatedStorageService:FindFirstChild("Modules") and replicatedStorageService.Modules:FindFirstChild("Utils") and replicatedStorageService.Modules.Utils:FindFirstChild("RayCastHandler")
    local touchDetectHandlerModule = replicatedStorageService:FindFirstChild("Modules") and replicatedStorageService.Modules:FindFirstChild("Utils") and replicatedStorageService.Modules.Utils:FindFirstChild("TouchDetectHandler")

    if touchDetectHandlerModule then
        local req = require(touchDetectHandlerModule)
        req.init = newcclosure(function() return newcclosure(function() return end) end)
    end
    if rayCastHandlerModule then
        local req = require(rayCastHandlerModule)
        req.init = newcclosure(function() return newcclosure(function() return end) end)
    end
end)

-- 1. Сверхбыстрый хук __index (Скрываем локальную скорость без падения FPS)
local OldIndex
OldIndex = hookmetamethod(game, "__index", function(self, key)
    if not checkcaller() and Toggles.FlyEnabled and Toggles.FlyEnabled.Value then
        -- Быстрая проверка по строке Name не нагружает память
        if key == "Velocity" or key == "AssemblyLinearVelocity" or key == "AssemblyAngularVelocity" then
            if self.Name == "HumanoidRootPart" or self.Name == "Torso" then
                return Vector3.new(0, 0, 0)
            end
        end
    end
    return OldIndex(self, key)
end)

-- 2. Оптимизированный хук __namecall (GetState + Silent Aim)
local OldNamecall
OldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
    local method = getnamecallmethod()
    
    if not checkcaller() then
        -- Байпасс состояний: Говорим серверу, что мы бежим по земле, а не висим в воздухе
        if method == "GetState" and Toggles.FlyEnabled and Toggles.FlyEnabled.Value then
            if self.ClassName == "Humanoid" then
                return Enum.HumanoidStateType.Running
            end
        end

        -- Сайлент Аим хук
        if Toggles.SilentAim and Toggles.SilentAim.Value and Cache.CurrentSilentTarget then
            if method == "Raycast" and self == Workspace then
                local args = {...}
                local origin = args[1]
                local targetPos = Cache.CurrentSilentTarget.Position
                args[2] = (targetPos - origin).Unit * args[2].Magnitude
                return OldNamecall(self, unpack(args))
            elseif method == "FindPartOnRay" or method == "FindPartOnRayWithIgnoreList" then
                local args = {...}
                local targetPos = Cache.CurrentSilentTarget.Position
                args[1] = Ray.new(args[1].Origin, (targetPos - args[1].Origin).Unit * 9999)
                return OldNamecall(self, unpack(args))
            end
        end
    end
    return OldNamecall(self, ...)
end)

--------------------------------------------------------------------------------
-- ЗАГРУЗКА ИНТЕРФЕЙСА
--------------------------------------------------------------------------------
local MobileRepo = 'https://raw.githubusercontent.com/alper213/lianardo-ui-libary-mobil-support/main/'
local Library = loadstring(game:HttpGet(MobileRepo .. 'LinoriaModded.lua'))()

local Window = Library:CreateWindow({
    Title = 'Neverlor | Stealth & Performance', 
    Center = true, 
    AutoShow = true, 
    TabPadding = 8, 
    MenuFadeTime = 0.2
})

local Tabs = {
    Combat = Window:AddTab('Combat'),
    Visuals = Window:AddTab('Visuals'),
    Settings = Window:AddTab('Settings')
}

local ThemeManager = {
    MainColor = Color3.fromRGB(35, 15, 60),       
    AccentColor = Color3.fromRGB(150, 50, 250),   
    BackgroundColor = Color3.fromRGB(15, 10, 22), 
    OutlineColor = Color3.fromRGB(65, 30, 110),   
    TextColor = Color3.fromRGB(240, 230, 255)     
}

pcall(function()
    Library.BackgroundColor = ThemeManager.BackgroundColor
    Library.AccentColor = ThemeManager.AccentColor
    Library.MainColor = ThemeManager.MainColor
    Library.TextColor = ThemeManager.TextColor
    Library.OutlineColor = ThemeManager.OutlineColor
end)

local UI_Elements = {
    FovCircle = Drawing.new("Circle"),
    TargetDot = Drawing.new("Circle")
}
UI_Elements.FovCircle.Thickness = 1.5; UI_Elements.FovCircle.NumSides = 64
UI_Elements.FovCircle.Color = ThemeManager.AccentColor; UI_Elements.FovCircle.Filled = false
UI_Elements.TargetDot.Radius = 5; UI_Elements.TargetDot.Thickness = 1; UI_Elements.TargetDot.NumSides = 20
UI_Elements.TargetDot.Color = Color3.fromRGB(255, 0, 150); UI_Elements.TargetDot.Filled = true

local HUD_Settings = { Enabled = true }
local flyUpPressed, flyDownPressed = false, false
local HiddenGrass = {}

--------------------------------------------------------------------------------
-- ЭЛЕМЕНТЫ МЕНЮ И КЕЙБИНДЫ
--------------------------------------------------------------------------------
local CombatAimGroup = Tabs.Combat:AddLeftGroupbox('Silent Aim Pro')
CombatAimGroup:AddToggle('SilentAim', {Text = 'Enable Silent Aim', Default = true})
CombatAimGroup:AddLabel('Silent Aim Bind'):AddKeyPicker('SilentAimBind', {Default = 'V', SyncToggleState = true, Mode = 'Toggle', Text = 'Silent Aim'})
CombatAimGroup:AddToggle('WallCheck', {Text = 'Wall Check', Default = true})
CombatAimGroup:AddToggle('TeamCheck', {Text = 'Team Check', Default = true})
CombatAimGroup:AddDropdown('HitboxPart', {Values = {'Head', 'HumanoidRootPart', 'Randomize'}, Default = 1, Multi = false, Text = 'Target Hitbox'})

local CombatFovGroup = Tabs.Combat:AddLeftGroupbox('FOV Settings')
CombatFovGroup:AddToggle('DrawFov', {Text = 'Draw FOV Circle', Default = true})
CombatFovGroup:AddToggle('DynamicFov', {Text = 'Dynamic FOV'})
CombatFovGroup:AddSlider('FovRadius', {Text = 'FOV Radius', Default = 150, Min = 10, Max = 1000, Rounding = 0})

local MobileFlyGroup = Tabs.Combat:AddRightGroupbox('Undetected Fly')
MobileFlyGroup:AddToggle('FlyEnabled', {Text = 'Enable Fly (Bypass)', Default = false})
MobileFlyGroup:AddLabel('Fly Bind'):AddKeyPicker('FlyBind', {Default = 'X', SyncToggleState = true, Mode = 'Toggle', Text = 'Fly'})
MobileFlyGroup:AddSlider('FlySpeed', {Text = 'Fly Speed', Default = 50, Min = 10, Max = 150, Rounding = 0})

local EspGroup = Tabs.Visuals:AddLeftGroupbox('Player ESP')
EspGroup:AddToggle('MasterEsp', {Text = 'Master ESP Enable', Default = true})
EspGroup:AddLabel('ESP Bind'):AddKeyPicker('EspBind', {Default = 'C', SyncToggleState = true, Mode = 'Toggle', Text = 'Master ESP'})
EspGroup:AddToggle('EspBox', {Text = 'Show Box', Default = true})
EspGroup:AddToggle('EspName', {Text = 'Show Name', Default = true})
EspGroup:AddToggle('EspDist', {Text = 'Show Distance', Default = true})
EspGroup:AddToggle('EspHealth', {Text = 'Show Health Bar', Default = true})
EspGroup:AddToggle('EspHighlight', {Text = 'Enable Highlight (Chams)', Default = false})

local TargetBox = Tabs.Visuals:AddRightGroupbox('Target HUD Settings')
TargetBox:AddToggle('TargetHUD_Enabled', { Text = 'Enable Target HUD', Default = true, Callback = function(Value) HUD_Settings.Enabled = Value end })

local WorldBox = Tabs.Visuals:AddRightGroupbox('World Visuals')
WorldBox:AddToggle('CustomSkyToggle', {
    Text = 'Custom Sky', Default = false,
    Callback = function(Value)
        pcall(function()
            local oldSky = Lighting:FindFirstChild("NeverlorSky")
            if oldSky then oldSky:Destroy() end
            if Value then
                local newSky = Instance.new("Sky")
                newSky.Name = "NeverlorSky"
                local skyId = "rbxassetid://82536953791252"
                newSky.SkyboxBk, newSky.SkyboxDn, newSky.SkyboxFt, newSky.SkyboxLf, newSky.SkyboxRt, newSky.SkyboxUp = skyId, skyId, skyId, skyId, skyId, skyId
                newSky.Parent = Lighting
            end
        end)
    end
})
WorldBox:AddToggle('FullbrightToggle', { Text = 'Fullbright', Default = false })
WorldBox:AddToggle('NoGrassToggle', {
    Text = 'No Grass', Default = false,
    Callback = function(Value)
        pcall(function()
            local terrain = Workspace:FindFirstChildOfClass("Terrain")
            if terrain then terrain.Decoration = not Value end
            if Value then
                for _, obj in ipairs(Workspace:GetDescendants()) do
                    if obj:IsA("BasePart") or obj:IsA("MeshPart") then
                        if obj.Name:lower():find("grass") or obj.Material == Enum.Material.Grass then
                            if obj.Transparency ~= 1 then HiddenGrass[obj] = obj.Transparency; obj.Transparency = 1; obj.CanCollide = false end
                        end
                    end
                end
            else
                for obj, oldTrans in pairs(HiddenGrass) do if obj and obj.Parent then obj.Transparency = oldTrans end end
                table.clear(HiddenGrass)
            end
        end)
    end
})

local MenuGrp = Tabs.Settings:AddLeftGroupbox('Menu Settings')
MenuGrp:AddButton('Unload UI', function() 
    pcall(function()
        for _, conn in pairs(Cache.Connections) do conn:Disconnect() end
        local char = LocalPlayer.Character
        if char and char:FindFirstChildOfClass("Humanoid") then char:FindFirstChildOfClass("Humanoid").PlatformStand = false end
        local oldSky = Lighting:FindFirstChild("NeverlorSky")
        if oldSky then oldSky:Destroy() end
        local terrain = Workspace:FindFirstChildOfClass("Terrain")
        if terrain then terrain.Decoration = true end
        for obj, oldTrans in pairs(HiddenGrass) do if obj and obj.Parent then obj.Transparency = oldTrans end end
        if CoreGui:FindFirstChild("LinoriaTargetHUD") then CoreGui:FindFirstChild("LinoriaTargetHUD"):Destroy() end
        if CoreGui:FindFirstChild("LinoriaFlyMobile") then CoreGui:FindFirstChild("LinoriaFlyMobile"):Destroy() end
        Library:Unload() 
    end)
end)
MenuGrp:AddLabel('Menu Hide Bind'):AddKeyPicker('MenuBind', {Default = 'RightShift', NoUI = true, Text = 'Menu Bind'})
Library.ToggleKeybind = Options.MenuBind

Toggles = _G.LinoriaToggles or getgenv().Toggles

--------------------------------------------------------------------------------
-- МОБИЛЬНЫЕ КНОПКИ ДЛЯ ПОЛЕТА (ВВЕРХ / ВНИЗ)
--------------------------------------------------------------------------------
local oldFlyUI = CoreGui:FindFirstChild("LinoriaFlyMobile")
if oldFlyUI then oldFlyUI:Destroy() end

local FlyMobileScreen = Instance.new("ScreenGui", CoreGui)
FlyMobileScreen.Name = "LinoriaFlyMobile"
FlyMobileScreen.ResetOnSpawn = false
FlyMobileScreen.Enabled = false

local FlyUpBtn = Instance.new("TextButton", FlyMobileScreen)
FlyUpBtn.Size = UDim2.new(0, 55, 0, 55); FlyUpBtn.Position = UDim2.new(1, -75, 0.5, -65)
FlyUpBtn.Text = "▲"; FlyUpBtn.TextSize = 24; FlyUpBtn.BackgroundColor3 = ThemeManager.BackgroundColor
FlyUpBtn.TextColor3 = ThemeManager.AccentColor; FlyUpBtn.BackgroundTransparency = 0.2
Instance.new("UICorner", FlyUpBtn).CornerRadius = UDim.new(0, 10); Instance.new("UIStroke", FlyUpBtn).Color = ThemeManager.OutlineColor

local FlyDownBtn = Instance.new("TextButton", FlyMobileScreen)
FlyDownBtn.Size = UDim2.new(0, 55, 0, 55); FlyDownBtn.Position = UDim2.new(1, -75, 0.5, 5)
FlyDownBtn.Text = "▼"; FlyDownBtn.TextSize = 24; FlyDownBtn.BackgroundColor3 = ThemeManager.BackgroundColor
FlyDownBtn.TextColor3 = ThemeManager.AccentColor; FlyDownBtn.BackgroundTransparency = 0.2
Instance.new("UICorner", FlyDownBtn).CornerRadius = UDim.new(0, 10); Instance.new("UIStroke", FlyDownBtn).Color = ThemeManager.OutlineColor

FlyUpBtn.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then flyUpPressed = true end end)
FlyUpBtn.InputEnded:Connect(function(input) if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then flyUpPressed = false end end)
FlyDownBtn.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then flyDownPressed = true end end)
FlyDownBtn.InputEnded:Connect(function(input) if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then flyDownPressed = false end end)

--------------------------------------------------------------------------------
-- ВСПОМОГАТЕЛЬНЫЕ ФУНКЦИИ
--------------------------------------------------------------------------------
local function IsAliveAndValid(player)
    if not player or not player.Character then return false end
    if Toggles.TeamCheck and Toggles.TeamCheck.Value and player.Team == LocalPlayer.Team then return false end
    local hum = player.Character:FindFirstChildOfClass("Humanoid")
    local root = player.Character:FindFirstChild("HumanoidRootPart")
    if not hum or not root or hum.Health <= 0 then return false end
    return true, hum, root
end

local function IsVisibleOnScreen(targetPart)
    if not Toggles.WallCheck.Value then return true end
    local myChar = LocalPlayer.Character
    if not myChar then return false end
    local castPoints = {targetPart.Position}
    local ignoreList = {myChar, targetPart.Parent}
    local obscured = Camera:GetPartsObscuringTarget(castPoints, ignoreList)
    for _, part in ipairs(obscured) do
        if part.Transparency < 0.5 and part.CanCollide and not part:IsDescendantOf(targetPart.Parent) then return false end
    end
    return true
end

local currentRandomPart = "Head"
task.spawn(function()
    while task.wait(1 + math.random() * 0.3) do 
        currentRandomPart = Options.HitboxPart.Value == "Randomize" and (currentRandomPart == "Head" and "HumanoidRootPart" or "Head") or Options.HitboxPart.Value 
    end
end)

local function GetInventoryString(player)
    local s = ""
    if not player or not player.Character then return s end
    local tool = player.Character:FindFirstChildOfClass("Tool")
    if tool then s = s .. tool.Name .. ";" end
    local bp = player:FindFirstChild("Backpack")
    if bp then for _, child in ipairs(bp:GetChildren()) do if child:IsA("Tool") then s = s .. child.Name .. ";" end end end
    return s
end

--------------------------------------------------------------------------------
-- ТАРГЕТ ХУД & ИНВЕНТАРЬ ОКНО
--------------------------------------------------------------------------------
local oldHud = CoreGui:FindFirstChild("LinoriaTargetHUD")
if oldHud then oldHud:Destroy() end

local ScreenGui = Instance.new("ScreenGui", CoreGui)
ScreenGui.Name = "LinoriaTargetHUD"; ScreenGui.ResetOnSpawn = false

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 300, 0, 75); MainFrame.Position = UDim2.new(0.5, -150, 0.72, 0)
MainFrame.BackgroundColor3 = ThemeManager.BackgroundColor; MainFrame.BackgroundTransparency = 0.15
MainFrame.BorderSizePixel = 0; MainFrame.Visible = false
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 10)
local FrameStroke = Instance.new("UIStroke", MainFrame); FrameStroke.Thickness = 1.5; FrameStroke.Color = ThemeManager.OutlineColor

local AvatarImage = Instance.new("ImageLabel", MainFrame)
AvatarImage.Size = UDim2.new(0, 55, 0, 55); AvatarImage.Position = UDim2.new(0, 10, 0, 10)
AvatarImage.BackgroundColor3 = ThemeManager.MainColor; Instance.new("UICorner", AvatarImage).CornerRadius = UDim.new(0, 8)

local NameLabel = Instance.new("TextLabel", MainFrame)
NameLabel.Size = UDim2.new(0, 150, 0, 20); NameLabel.Position = UDim2.new(0, 75, 0, 10)
NameLabel.BackgroundTransparency = 1; NameLabel.TextColor3 = ThemeManager.TextColor; NameLabel.Font = Enum.Font.GothamBold; NameLabel.TextXAlignment = Enum.TextXAlignment.Left; NameLabel.TextSize = 14

local DistLabel = Instance.new("TextLabel", MainFrame)
DistLabel.Size = UDim2.new(0, 50, 0, 20); DistLabel.Position = UDim2.new(0, 240, 0, 10)
DistLabel.BackgroundTransparency = 1; DistLabel.TextColor3 = Color3.fromRGB(170, 150, 200); DistLabel.Font = Enum.Font.GothamSemibold; DistLabel.TextXAlignment = Enum.TextXAlignment.Right; DistLabel.TextSize = 12

local HealthBarBg = Instance.new("Frame", MainFrame)
HealthBarBg.Size = UDim2.new(0, 215, 0, 8); HealthBarBg.Position = UDim2.new(0, 75, 0, 36)
HealthBarBg.BackgroundColor3 = Color3.fromRGB(35, 25, 45); Instance.new("UICorner", HealthBarBg).CornerRadius = UDim.new(0, 4)

local HealthBar = Instance.new("Frame", HealthBarBg)
HealthBar.Size = UDim2.new(1, 0, 1, 0); HealthBar.BackgroundColor3 = ThemeManager.AccentColor
Instance.new("UICorner", HealthBar).CornerRadius = UDim.new(0, 4)

local HealthText = Instance.new("TextLabel", MainFrame)
HealthText.Size = UDim2.new(0, 215, 0, 15); HealthText.Position = UDim2.new(0, 75, 0, 48)
HealthText.BackgroundTransparency = 1; HealthText.TextColor3 = Color3.fromRGB(210, 200, 230); HealthText.Font = Enum.Font.Gotham; HealthText.TextXAlignment = Enum.TextXAlignment.Center; HealthText.TextSize = 11

local InvWindow = Instance.new("Frame", ScreenGui)
InvWindow.Size = UDim2.new(0, 200, 0, 150); InvWindow.Position = UDim2.new(0.5, 160, 0.72, -75)
InvWindow.BackgroundColor3 = ThemeManager.BackgroundColor; InvWindow.BackgroundTransparency = 0.15; InvWindow.Visible = false
Instance.new("UICorner", InvWindow).CornerRadius = UDim.new(0, 10)
local InvStroke = Instance.new("UIStroke", InvWindow); InvStroke.Thickness = 1.5; InvStroke.Color = ThemeManager.OutlineColor

local InvTitle = Instance.new("TextLabel", InvWindow)
InvTitle.Size = UDim2.new(1, 0, 0, 25); InvTitle.Position = UDim2.new(0, 0, 0, 5)
InvTitle.BackgroundTransparency = 1; InvTitle.Text = "Inventory"; InvTitle.TextColor3 = ThemeManager.TextColor; InvTitle.Font = Enum.Font.GothamBold; InvTitle.TextSize = 12

local InvContainer = Instance.new("ScrollingFrame", InvWindow)
InvContainer.Size = UDim2.new(1, -10, 1, -35); InvContainer.Position = UDim2.new(0, 5, 0, 30)
InvContainer.BackgroundTransparency = 1; InvContainer.ScrollBarThickness = 3; InvContainer.CanvasSize = UDim2.new(0, 0, 0, 0)
local UIGrid = Instance.new("UIGridLayout", InvContainer)
UIGrid.CellSize = UDim2.new(0, 40, 0, 40); UIGrid.CellPadding = UDim2.new(0, 5, 0, 5)

local function RefreshInventoryUI(player)
    for _, v in pairs(InvContainer:GetChildren()) do if v:IsA("Frame") then v:Destroy() end end
    if not player or not player.Character then return end
    local items = {}
    local tool = player.Character:FindFirstChildOfClass("Tool")
    if tool then table.insert(items, {tool, true}) end
    local bp = player:FindFirstChild("Backpack")
    if bp then for _, child in ipairs(bp:GetChildren()) do if child:IsA("Tool") then table.insert(items, {child, false}) end end end
    local count = 0
    for _, data in pairs(items) do
        local t, isEq = data[1], data[2]
        count = count + 1
        local itemBg = Instance.new("Frame", InvContainer)
        itemBg.BackgroundColor3 = Color3.fromRGB(20, 15, 30); Instance.new("UICorner", itemBg).CornerRadius = UDim.new(0, 5)
        local stroke = Instance.new("UIStroke", itemBg)
        stroke.Color = isEq and Color3.fromRGB(0, 255, 100) or ThemeManager.OutlineColor
        stroke.Thickness = isEq and 2 or 1
        local itemImg = Instance.new("ImageLabel", itemBg)
        itemImg.Size = UDim2.new(1, -4, 1, -4); itemImg.Position = UDim2.new(0, 2, 0, 2); itemImg.BackgroundTransparency = 1
        if t.TextureId and t.TextureId ~= "" then itemImg.Image = t.TextureId else
            local txt = Instance.new("TextLabel", itemImg)
            txt.Size = UDim2.new(1, 0, 1, 0); txt.BackgroundTransparency = 1; txt.TextScaled = true; txt.Text = t.Name; txt.TextColor3 = Color3.fromRGB(200,200,200)
        end
    end
    InvContainer.CanvasSize = UDim2.new(0, 0, 0, math.ceil(count / 4) * 45)
end

--------------------------------------------------------------------------------
-- ESP СЕТАП
--------------------------------------------------------------------------------
local espObjects = {}
local chamsObjects = {}
local function createESP(player)
    if player == LocalPlayer then return end
    local esp = {
        Box = Drawing.new("Square"), Name = Drawing.new("Text"), Dist = Drawing.new("Text"),
        HealthBg = Drawing.new("Square"), HealthBar = Drawing.new("Square")
    }
    esp.Box.Thickness = 1; esp.Box.Color = ThemeManager.AccentColor; esp.Box.Filled = false; esp.Box.Visible = false
    esp.Name.Size = 14; esp.Name.Center = true; esp.Name.Outline = true; esp.Name.Color = Color3.fromRGB(255, 255, 255); esp.Name.Font = 2; esp.Name.Visible = false
    esp.Dist.Size = 12; esp.Dist.Center = true; esp.Dist.Outline = true; esp.Dist.Color = Color3.fromRGB(210, 190, 240); esp.Dist.Font = 2; esp.Dist.Visible = false
    esp.HealthBg.Thickness = 1; esp.HealthBg.Color = Color3.fromRGB(0, 0, 0); esp.HealthBg.Filled = true; esp.HealthBg.Visible = false
    esp.HealthBar.Thickness = 1; esp.HealthBar.Color = ThemeManager.AccentColor; esp.HealthBar.Filled = true; esp.HealthBar.Visible = false
    espObjects[player] = esp
    local highlight = Instance.new("Highlight")
    highlight.Name = "E_Highlight"; highlight.FillColor = ThemeManager.AccentColor; highlight.FillTransparency = 0.6
    highlight.OutlineColor = Color3.fromRGB(255, 255, 255); highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Enabled = false; highlight.Parent = ScreenGui; chamsObjects[player] = highlight
end
local function removeESP(player)
    if espObjects[player] then for _, obj in pairs(espObjects[player]) do pcall(function() obj:Remove() end) end; espObjects[player] = nil end
    if chamsObjects[player] then pcall(function() chamsObjects[player]:Destroy() end); chamsObjects[player] = nil end
end
for _, p in pairs(Players:GetPlayers()) do createESP(p) end
table.insert(Cache.Connections, Players.PlayerAdded:Connect(createESP))
table.insert(Cache.Connections, Players.PlayerRemoving:Connect(removeESP))

--------------------------------------------------------------------------------
-- ОПТИМИЗИРОВАННЫЕ МОДЫ ОРУЖИЯ
--------------------------------------------------------------------------------
local function GetTargetFromFOV()
    local best, cRad = nil, Options.FovRadius.Value
    if Toggles.DynamicFov.Value then cRad = (Options.FovRadius.Value / Camera.FieldOfView) * 70 end
    UI_Elements.FovCircle.Radius = cRad; UI_Elements.FovCircle.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    UI_Elements.FovCircle.Visible = Toggles.DrawFov.Value
    local sDist = cRad
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then
            local alive, hum, root = IsAliveAndValid(p)
            if alive then
                local hitb = p.Character:FindFirstChild(currentRandomPart)
                if hitb then
                    local sp, onS = Camera:WorldToViewportPoint(hitb.Position)
                    if onS and IsVisibleOnScreen(hitb) then
                        local dC = (Vector2.new(sp.X, sp.Y) - UI_Elements.FovCircle.Position).Magnitude
                        local realDist = (root.Position - Camera.CFrame.Position).Magnitude
                        if realDist < 15 then dC = dC * 0.5 end
                        if dC < sDist then sDist = dC; best = hitb end
                    end
                end
            end
        end
    end
    return best
end

local function ProcessToolMods()
    if not Toggles.SilentAim.Value then return end
    pcall(function()
        for _, v in pairs(getgc(true)) do
            if type(v) == "table" then
                if rawget(v, "getfireDirection") or rawget(v, "GetFireDirection") then
                    local key = rawget(v, "getfireDirection") and "getfireDirection" or "GetFireDirection"
                    v[key] = function(self, origin, ...)
                        if Toggles.SilentAim.Value and Cache.CurrentSilentTarget and not checkcaller() then 
                            return (Cache.CurrentSilentTarget.Position - origin).Unit 
                        end
                        return Camera.CFrame.LookVector
                    end
                end
            end
        end
    end)
end

local function SetupCharacterHooks(char)
    char.ChildAdded:Connect(function(c) 
        if c:IsA("Tool") then 
            task.wait(0.1) 
            task.spawn(ProcessToolMods) 
        end 
    end)
end
if LocalPlayer.Character then SetupCharacterHooks(LocalPlayer.Character) end
table.insert(Cache.Connections, LocalPlayer.CharacterAdded:Connect(SetupCharacterHooks))

--------------------------------------------------------------------------------
-- ГЛАВНЫЕ ЦИКЛЫ ОБНОВЛЕНИЯ (Stepped + RenderStepped)
--------------------------------------------------------------------------------
local lastTargetPlr = nil
local lastInvCache = ""

-- Физический цикл (Stepped - До просчета физики движком = Лучший байпасс)
table.insert(Cache.Connections, RunService.Stepped:Connect(function(time, deltaTime)
    local Character = LocalPlayer.Character
    local RootPart = Character and Character:FindFirstChild("HumanoidRootPart")
    local Humanoid = Character and Character:FindFirstChildOfClass("Humanoid")
    
    if Toggles.FlyEnabled and Toggles.FlyEnabled.Value and RootPart and Humanoid then
        if isMobile then FlyMobileScreen.Enabled = true end
        
        -- Ультимативный байпасс: отправляем серверу микро-падение (-0.5 Y), чтобы обмануть проверки на левитацию
        RootPart.AssemblyLinearVelocity = Vector3.new(0, -0.5, 0)
        RootPart.AssemblyAngularVelocity = Vector3.zero
        Humanoid.PlatformStand = true
        
        local moveDir = Humanoid.MoveDirection
        local speed = Options.FlySpeed.Value
        
        local yMove = 0
        if flyUpPressed or UserInputService:IsKeyDown(Enum.KeyCode.Space) then yMove = 1 end
        if flyDownPressed or UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then yMove = -1 end
        
        -- Ограничиваем скорость взлета до 50%, чтобы сервер не детектил резкий скачок высоты (Rubberband fix)
        local ySpeedMulti = yMove > 0 and 0.5 or 0.8
        local velocityToApply = (moveDir * speed * deltaTime) + (Vector3.new(0, yMove, 0) * (speed * ySpeedMulti * deltaTime))
        
        local lookVector = Camera.CFrame.LookVector
        local targetRotation = CFrame.new(RootPart.Position, RootPart.Position + Vector3.new(lookVector.X, 0, lookVector.Z))
        
        RootPart.CFrame = targetRotation + velocityToApply
    else
        if isMobile then FlyMobileScreen.Enabled = false end
        if Humanoid then Humanoid.PlatformStand = false end
        flyUpPressed = false; flyDownPressed = false
    end
end))

-- Визуальный цикл (RenderStepped) - Отрисовка ESP и Аима
table.insert(Cache.Connections, RunService.RenderStepped:Connect(function()
    if Toggles.FullbrightToggle and Toggles.FullbrightToggle.Value then
        Lighting.Brightness = 2; Lighting.ClockTime = 14; Lighting.FogEnd = 999999
        Lighting.GlobalShadows = false; Lighting.OutdoorAmbient = Color3.fromRGB(128, 128, 128)
    end

    local targetPart = GetTargetFromFOV()
    Cache.CurrentSilentTarget = targetPart
    
    if targetPart and Toggles.SilentAim.Value then
        local targetPos, onScreen = Camera:WorldToViewportPoint(targetPart.Position)
        if onScreen then
            UI_Elements.TargetDot.Position = Vector2.new(targetPos.X, targetPos.Y); UI_Elements.TargetDot.Visible = true
        else UI_Elements.TargetDot.Visible = false end
    else UI_Elements.TargetDot.Visible = false end
    
    local RootPart = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    
    if HUD_Settings.Enabled and targetPart then
        local targetPlayer = Players:GetPlayerFromCharacter(targetPart.Parent)
        if targetPlayer and targetPlayer ~= LocalPlayer then
            local tAlive, tHum, tRoot = IsAliveAndValid(targetPlayer)
            if tAlive then
                NameLabel.Text = targetPlayer.Name
                DistLabel.Text = math.floor((tRoot.Position - (RootPart and RootPart.Position or Vector3.new())).Magnitude) .. " studs"
                local healthRatio = math.clamp(tHum.Health / tHum.MaxHealth, 0, 1)
                TweenService:Create(HealthBar, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = UDim2.new(healthRatio, 0, 1, 0)}):Play()
                HealthText.Text = math.floor(tHum.Health) .. " / " .. math.floor(tHum.MaxHealth)
                AvatarImage.Image = "rbxthumb://type=AvatarHeadShot&id=" .. targetPlayer.UserId .. "&w=150&h=150"
                
                local currentInv = GetInventoryString(targetPlayer)
                if lastTargetPlr ~= targetPlayer or currentInv ~= lastInvCache then RefreshInventoryUI(targetPlayer); lastInvCache = currentInv end
                lastTargetPlr = targetPlayer
                
                MainFrame.Visible = true; InvWindow.Visible = true
            else MainFrame.Visible = false; InvWindow.Visible = false end
        end
    else MainFrame.Visible = false; InvWindow.Visible = false end
    
    local masterEsp = Toggles.MasterEsp and Toggles.MasterEsp.Value
    for player, esp in pairs(espObjects) do
        local alive, hum, root = IsAliveAndValid(player)
        local chams = chamsObjects[player]
        if masterEsp and alive then
            local char = player.Character; local head = char:FindFirstChild("Head")
            if head then
                local rootPos, rootPosOnScreen = Camera:WorldToViewportPoint(root.Position)
                local headPos = Camera:WorldToViewportPoint(head.Position + Vector3.new(0, 0.5, 0))
                local legPos = Camera:WorldToViewportPoint(root.Position - Vector3.new(0, 3, 0))
                if rootPosOnScreen then
                    local boxHeight = math.abs(headPos.Y - legPos.Y); local boxWidth = boxHeight * 0.6
                    if Toggles.EspBox and Toggles.EspBox.Value then esp.Box.Size = Vector2.new(boxWidth, boxHeight); esp.Box.Position = Vector2.new(rootPos.X - boxWidth / 2, headPos.Y); esp.Box.Visible = true else esp.Box.Visible = false end
                    if Toggles.EspName and Toggles.EspName.Value then esp.Name.Text = player.Name; esp.Name.Position = Vector2.new(rootPos.X, headPos.Y - 20); esp.Name.Visible = true else esp.Name.Visible = false end
                    if Toggles.EspDist and Toggles.EspDist.Value then esp.Dist.Text = tostring(RootPart and math.floor((root.Position - RootPart.Position).Magnitude) or 0) .. "m"; esp.Dist.Position = Vector2.new(rootPos.X, legPos.Y + 5); esp.Dist.Visible = true else esp.Dist.Visible = false end
                    if Toggles.EspHealth and Toggles.EspHealth.Value then
                        local barWidth = 3; local barPosX = rootPos.X - (boxWidth / 2) - 7
                        esp.HealthBg.Size = Vector2.new(barWidth, boxHeight); esp.HealthBg.Position = Vector2.new(barPosX, headPos.Y); esp.HealthBg.Visible = true
                        local hF = math.clamp(hum.Health / hum.MaxHealth, 0, 1)
                        esp.HealthBar.Size = Vector2.new(barWidth, boxHeight * hF); esp.HealthBar.Position = Vector2.new(barPosX, headPos.Y + (boxHeight * (1 - hF))); esp.HealthBar.Visible = true
                    else esp.HealthBg.Visible = false; esp.HealthBar.Visible = false end
                else for _, drawing in pairs(esp) do drawing.Visible = false end end
            else for _, drawing in pairs(esp) do drawing.Visible = false end end
            if chams then chams.Enabled = Toggles.EspHighlight and Toggles.EspHighlight.Value or false; chams.Adornee = chams.Enabled and char or nil end
        else for _, drawing in pairs(esp) do drawing.Visible = false end; if chams then chams.Enabled = false; chams.Adornee = nil end end
    end
end))
