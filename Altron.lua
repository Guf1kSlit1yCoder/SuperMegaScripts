if not game:IsLoaded() then
    game.Loaded:Wait()
end

--------------------------------------------------------------------------------
-- Анти-чит байпас (Вд)
--------------------------------------------------------------------------------
pcall(function()
    local replicatedStorageService = game:GetService("ReplicatedStorage")
    local rayCastHandlerModule = require(replicatedStorageService.Modules.Utils.RayCastHandler)
    local touchDetectHandlerModule = require(replicatedStorageService.Modules.Utils.TouchDetectHandler)

    touchDetectHandlerModule.init = newcclosure(function()
        return newcclosure(function() return end)
    end)

    rayCastHandlerModule.init = newcclosure(function()
        return newcclosure(function() return end)
    end)
end)

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

-- 1. ЗАГРУЗКА МОБИЛЬНОЙ БИБЛИОТЕКИ ИНТЕРФЕЙСА
local MobileRepo = 'https://raw.githubusercontent.com/alper213/lianardo-ui-libary-mobil-support/main/'
local Library = loadstring(game:HttpGet(MobileRepo .. 'LinoriaModded.lua'))()

-- Создание окна
local Window = Library:CreateWindow({
    Title = 'Neverlor', 
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

--------------------------------------------------------------------------------
-- ФИОЛЕТОВАЯ ТЕМА
--------------------------------------------------------------------------------
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

local Cache = {CurrentSilentTarget = nil, Connections = {}}
local UI_Elements = {
    FovCircle = Drawing.new("Circle"),
    TargetDot = Drawing.new("Circle")
}
UI_Elements.FovCircle.Thickness = 1.5
UI_Elements.FovCircle.NumSides = 64
UI_Elements.FovCircle.Color = ThemeManager.AccentColor
UI_Elements.FovCircle.Filled = false
UI_Elements.TargetDot.Radius = 5
UI_Elements.TargetDot.Thickness = 1
UI_Elements.TargetDot.NumSides = 20
UI_Elements.TargetDot.Color = Color3.fromRGB(255, 0, 150)
UI_Elements.TargetDot.Filled = true

local HUD_Settings = { Enabled = true }
local FlyVelocity = nil
local FlyGyro = nil

-- Кэш для скрытых объектов травы, чтобы возвращать их обратно
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

local MobileFlyGroup = Tabs.Combat:AddRightGroupbox('Fly (Mobile & PC)')
MobileFlyGroup:AddToggle('FlyEnabled', {Text = 'Enable Fly', Default = false})
MobileFlyGroup:AddLabel('Fly Bind'):AddKeyPicker('FlyBind', {Default = 'X', SyncToggleState = true, Mode = 'Toggle', Text = 'Fly'})
MobileFlyGroup:AddSlider('FlySpeed', {Text = 'Fly Speed', Default = 50, Min = 10, Max = 250, Rounding = 0})

-- Левая секция визуалов (Игроки)
local EspGroup = Tabs.Visuals:AddLeftGroupbox('Player ESP')
EspGroup:AddToggle('MasterEsp', {Text = 'Master ESP Enable', Default = true})
EspGroup:AddLabel('ESP Bind'):AddKeyPicker('EspBind', {Default = 'C', SyncToggleState = true, Mode = 'Toggle', Text = 'Master ESP'})

EspGroup:AddToggle('EspBox', {Text = 'Show Box', Default = true})
EspGroup:AddToggle('EspName', {Text = 'Show Name', Default = true})
EspGroup:AddToggle('EspDist', {Text = 'Show Distance', Default = true})
EspGroup:AddToggle('EspHealth', {Text = 'Show Health Bar', Default = true})
EspGroup:AddToggle('EspHighlight', {Text = 'Enable Highlight (Chams)', Default = false})

-- Правая верхняя секция визуалов (Таргет ХУД)
local TargetBox = Tabs.Visuals:AddRightGroupbox('Target HUD Settings')
TargetBox:AddToggle('TargetHUD_Enabled', {
    Text = 'Enable Target HUD',
    Default = true,
    Callback = function(Value) HUD_Settings.Enabled = Value end
})

-- Правая нижняя секция визуалов (Мир, Небо, Трава, Фуллбрайт)
local WorldBox = Tabs.Visuals:AddRightGroupbox('World Visuals')
WorldBox:AddToggle('CustomSkyToggle', {
    Text = 'Custom Sky',
    Default = false,
    Callback = function(Value)
        pcall(function()
            local oldSky = Lighting:FindFirstChild("NeverlorSky")
            if oldSky then oldSky:Destroy() end
            
            if Value then
                local newSky = Instance.new("Sky")
                newSky.Name = "NeverlorSky"
                local skyId = "rbxassetid://82536953791252"
                
                newSky.SkyboxBk = skyId
                newSky.SkyboxDn = skyId
                newSky.SkyboxFt = skyId
                newSky.SkyboxLf = skyId
                newSky.SkyboxRt = skyId
                newSky.SkyboxUp = skyId
                newSky.Parent = Lighting
            end
        end)
    end
})

-- Функция Fullbright
WorldBox:AddToggle('FullbrightToggle', {
    Text = 'Fullbright',
    Default = false
})

-- Улучшенная функция: No Grass (Удаление травы)
WorldBox:AddToggle('NoGrassToggle', {
    Text = 'No Grass',
    Default = false,
    Callback = function(Value)
        pcall(function()
            -- 1. Выключаем встроенный Terrain Декор
            local terrain = Workspace:FindFirstChildOfClass("Terrain")
            if terrain then
                terrain.Decoration = not Value
            end
            
            -- 2. Поиск и скрытие кастомных парт-моделей травы по всей карте
            if Value then
                for _, obj in ipairs(Workspace:GetDescendants()) do
                    if obj:IsA("BasePart") or obj:IsA("MeshPart") then
                        local name = obj.Name:lower()
                        -- Фильтр по названию и материалу травы/фолиажа
                        if name:find("grass") or name:find("foliage") or name:find("bush") or obj.Material == Enum.Material.Grass then
                            if obj.Transparency ~= 1 then
                                HiddenGrass[obj] = obj.Transparency -- запоминаем исходную видимость
                                obj.Transparency = 1
                                obj.CanCollide = false
                            end
                        end
                    end
                end
            else
                -- Возвращаем обратно, если выключили тумблер
                for obj, oldTrans in pairs(HiddenGrass) do
                    if obj and obj.Parent then
                        obj.Transparency = oldTrans
                    end
                end
                table.clear(HiddenGrass)
            end
        end)
    end
})

local MenuGrp = Tabs.Settings:AddLeftGroupbox('Menu Settings')
MenuGrp:AddButton('Unload UI', function() 
    pcall(function()
        for _, conn in pairs(Cache.Connections) do conn:Disconnect() end
        if FlyVelocity then FlyVelocity:Destroy() end
        if FlyGyro then FlyGyro:Destroy() end
        local oldSky = Lighting:FindFirstChild("NeverlorSky")
        if oldSky then oldSky:Destroy() end
        
        -- Возвращаем всю траву при выгрузке скрипта
        local terrain = Workspace:FindFirstChildOfClass("Terrain")
        if terrain then terrain.Decoration = true end
        for obj, oldTrans in pairs(HiddenGrass) do
            if obj and obj.Parent then obj.Transparency = oldTrans end
        end
        
        Library:Unload() 
    end)
end)
MenuGrp:AddLabel('Menu Hide Bind'):AddKeyPicker('MenuBind', {Default = 'RightShift', NoUI = true, Text = 'Menu Bind'})
Library.ToggleKeybind = Options.MenuBind

--------------------------------------------------------------------------------
-- ВСПОМОГАТЕЛЬНЫЕ ФУНКЦИИ
--------------------------------------------------------------------------------
local function IsAliveAndValid(player)
    if not player or not player.Character then return false end
    if Toggles.TeamCheck and Toggles.TeamCheck.Value and player.Team == LocalPlayer.Team then
        return false
    end
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
        if part.Transparency < 0.5 and part.CanCollide and not part:IsDescendantOf(targetPart.Parent) then
            return false
        end
    end
    return true
end

local currentRandomPart = "Head"
task.spawn(function()
    while task.wait(1 + math.random() * 0.3) do 
        if Options.HitboxPart.Value == "Randomize" then 
            currentRandomPart = (currentRandomPart == "Head" and "HumanoidRootPart" or "Head") 
        else 
            currentRandomPart = Options.HitboxPart.Value 
        end
    end
end)

local function GetPlayerInventory(player)
    local items = {}
    if not player or not player.Character then return "None" end
    local tool = player.Character:FindFirstChildOfClass("Tool")
    if tool then table.insert(items, tool.Name .. " (Eq)") end
    local backpack = player:FindFirstChild("Backpack")
    if backpack then
        for _, child in ipairs(backpack:GetChildren()) do
            if child:IsA("Tool") then table.insert(items, child.Name) end
        end
    end
    return #items == 0 and "Empty" or table.concat(items, ", ")
end

local function CleanFly()
    if FlyVelocity then FlyVelocity:Destroy() FlyVelocity = nil end
    if FlyGyro then FlyGyro:Destroy() FlyGyro = nil end
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if hum then hum.PlatformStand = false end
end

--------------------------------------------------------------------------------
-- ТАРГЕТ ХУД СЕТАП
--------------------------------------------------------------------------------
local oldHud = CoreGui:FindFirstChild("LinoriaTargetHUD") or LocalPlayer:WaitForChild("PlayerGui"):FindFirstChild("LinoriaTargetHUD")
if oldHud then oldHud:Destroy() end

local ScreenGui = Instance.new("ScreenGui", CoreGui)
ScreenGui.Name = "LinoriaTargetHUD"
ScreenGui.ResetOnSpawn = false

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 300, 0, 100)
MainFrame.Position = UDim2.new(0.5, -150, 0.72, 0)
MainFrame.BackgroundColor3 = ThemeManager.BackgroundColor
MainFrame.BackgroundTransparency = 0.15
MainFrame.BorderSizePixel = 0
MainFrame.Visible = false

local MainCorner = Instance.new("UICorner", MainFrame)
MainCorner.CornerRadius = UDim.new(0, 10)

local FrameStroke = Instance.new("UIStroke", MainFrame)
FrameStroke.Thickness = 1.5
FrameStroke.Color = ThemeManager.OutlineColor

local AvatarImage = Instance.new("ImageLabel", MainFrame)
AvatarImage.Size = UDim2.new(0, 55, 0, 55)
AvatarImage.Position = UDim2.new(0, 10, 0, 10)
AvatarImage.BackgroundColor3 = ThemeManager.MainColor
AvatarImage.BorderSizePixel = 0
Instance.new("UICorner", AvatarImage).CornerRadius = UDim.new(0, 8)

local NameLabel = Instance.new("TextLabel", MainFrame)
NameLabel.Size = UDim2.new(0, 150, 0, 20)
NameLabel.Position = UDim2.new(0, 75, 0, 10)
NameLabel.BackgroundTransparency = 1
NameLabel.TextColor3 = ThemeManager.TextColor
NameLabel.TextSize = 14
NameLabel.Font = Enum.Font.GothamBold
NameLabel.TextXAlignment = Enum.TextXAlignment.Left

local DistLabel = Instance.new("TextLabel", MainFrame)
DistLabel.Size = UDim2.new(0, 50, 0, 20)
DistLabel.Position = UDim2.new(0, 240, 0, 10)
DistLabel.BackgroundTransparency = 1
DistLabel.TextColor3 = Color3.fromRGB(170, 150, 200)
DistLabel.TextSize = 12
DistLabel.Font = Enum.Font.GothamSemibold
DistLabel.TextXAlignment = Enum.TextXAlignment.Right

local HealthBarBg = Instance.new("Frame", MainFrame)
HealthBarBg.Size = UDim2.new(0, 215, 0, 8)
HealthBarBg.Position = UDim2.new(0, 75, 0, 36)
HealthBarBg.BackgroundColor3 = Color3.fromRGB(35, 25, 45)
Instance.new("UICorner", HealthBarBg).CornerRadius = UDim.new(0, 4)

local HealthBar = Instance.new("Frame", HealthBarBg)
HealthBar.Size = UDim2.new(1, 0, 1, 0)
HealthBar.BackgroundColor3 = ThemeManager.AccentColor
Instance.new("UICorner", HealthBar).CornerRadius = UDim.new(0, 4)

local HealthText = Instance.new("TextLabel", MainFrame)
HealthText.Size = UDim2.new(0, 215, 0, 15)
HealthText.Position = UDim2.new(0, 75, 0, 48)
HealthText.BackgroundTransparency = 1
HealthText.TextColor3 = Color3.fromRGB(210, 200, 230)
HealthText.TextSize = 11
HealthText.Font = Enum.Font.Gotham
HealthText.TextXAlignment = Enum.TextXAlignment.Center

local InvLabel = Instance.new("TextLabel", MainFrame)
InvLabel.Size = UDim2.new(0, 280, 0, 20)
InvLabel.Position = UDim2.new(0, 10, 0, 72)
InvLabel.BackgroundTransparency = 1
InvLabel.TextColor3 = Color3.fromRGB(218, 160, 255)
InvLabel.TextSize = 11
InvLabel.Font = Enum.Font.Code
InvLabel.TextXAlignment = Enum.TextXAlignment.Left
InvLabel.TextTruncate = Enum.TextTruncate.AtEnd

--------------------------------------------------------------------------------
-- ESP СЕТАП
--------------------------------------------------------------------------------
local espObjects = {}
local chamsObjects = {}

local function createESP(player)
    if player == LocalPlayer then return end
    
    local esp = {
        Box = Drawing.new("Square"),
        Name = Drawing.new("Text"),
        Dist = Drawing.new("Text"),
        HealthBg = Drawing.new("Square"),
        HealthBar = Drawing.new("Square")
    }
    esp.Box.Thickness = 1; esp.Box.Color = ThemeManager.AccentColor; esp.Box.Filled = false; esp.Box.Visible = false
    esp.Name.Size = 14; esp.Name.Center = true; esp.Name.Outline = true; esp.Name.Color = Color3.fromRGB(255, 255, 255); esp.Name.Font = 2; esp.Name.Visible = false
    esp.Dist.Size = 12; esp.Dist.Center = true; esp.Dist.Outline = true; esp.Dist.Color = Color3.fromRGB(210, 190, 240); esp.Dist.Font = 2; esp.Dist.Visible = false
    esp.HealthBg.Thickness = 1; esp.HealthBg.Color = Color3.fromRGB(0, 0, 0); esp.HealthBg.Filled = true; esp.HealthBg.Visible = false
    esp.HealthBar.Thickness = 1; esp.HealthBar.Color = ThemeManager.AccentColor; esp.HealthBar.Filled = true; esp.HealthBar.Visible = false
    espObjects[player] = esp

    local highlight = Instance.new("Highlight")
    highlight.Name = "E_Highlight"
    highlight.FillColor = ThemeManager.AccentColor
    highlight.FillTransparency = 0.6
    highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Enabled = false
    highlight.Parent = ScreenGui
    chamsObjects[player] = highlight
end

local function removeESP(player)
    if espObjects[player] then 
        for _, obj in pairs(espObjects[player]) do pcall(function() obj:Remove() end) end 
        espObjects[player] = nil 
    end
    if chamsObjects[player] then 
        pcall(function() chamsObjects[player]:Destroy() end) 
        chamsObjects[player] = nil 
    end
end

for _, p in pairs(Players:GetPlayers()) do createESP(p) end
table.insert(Cache.Connections, Players.PlayerAdded:Connect(createESP))
table.insert(Cache.Connections, Players.PlayerRemoving:Connect(removeESP))

--------------------------------------------------------------------------------
-- ФУНКЦИЯ ПОЛУЧЕНИЯ ЦЕЛИ ИЗ FOV
--------------------------------------------------------------------------------
local function GetTargetFromFOV()
    local best, cRad = nil, Options.FovRadius.Value
    if Toggles.DynamicFov.Value then cRad = (Options.FovRadius.Value / Camera.FieldOfView) * 70 end
    UI_Elements.FovCircle.Radius = cRad
    UI_Elements.FovCircle.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
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

--------------------------------------------------------------------------------
-- ХУКИ И МОДИФИКАЦИЯ ОРУЖИЯ (SILENT AIM & NO RECOIL)
--------------------------------------------------------------------------------
local OldNamecall
OldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
    local args = {...}
    local method = getnamecallmethod()
    
    if Toggles.SilentAim.Value and Cache.CurrentSilentTarget and not checkcaller() then
        if method == "Raycast" and self == Workspace then
            local origin = args[1]
            local targetPos = Cache.CurrentSilentTarget.Position
            args[2] = (targetPos - origin).Unit * args[2].Magnitude
            return OldNamecall(self, unpack(args))
        end
        
        if method == "FindPartOnRay" or method == "FindPartOnRayWithIgnoreList" then
            local targetPos = Cache.CurrentSilentTarget.Position
            args[1] = Ray.new(args[1].Origin, (targetPos - args[1].Origin).Unit * 9999)
            return OldNamecall(self, unpack(args))
        end
    end
    return OldNamecall(self, ...)
end)

local function ProcessToolMods()
    pcall(function()
        -- ИНЖЕКТ ФУНКЦИИ NO RECOIL В КЛАСС RECOILHANDLER
        local RecoilPath = game:GetService("ReplicatedStorage"):FindFirstChild("Gun") 
            and game:GetService("ReplicatedStorage").Gun:FindFirstChild("Scripts") 
            and game:GetService("ReplicatedStorage").Gun.Scripts:FindFirstChild("RecoilHandler")
            
        if RecoilPath then
            local RecoilHandler = require(RecoilPath)
            if RecoilHandler and type(RecoilHandler) == "table" and not rawget(RecoilHandler, "__patched") then
                table.clear(RecoilHandler)
                
                RecoilHandler.__index = RecoilHandler
                RecoilHandler.__patched = true 
                
                RecoilHandler.new = function(xFunction, yFunction, startingPoint, step, degreesPerUnit)
                    local recoilFunctionInstance = setmetatable({}, RecoilHandler)
                    recoilFunctionInstance.XFunction = xFunction
                    recoilFunctionInstance.YFunction = yFunction
                    recoilFunctionInstance.StartingPoint = startingPoint or 0
                    recoilFunctionInstance.Step = step or 1
                    recoilFunctionInstance.DegreesPerUnit = degreesPerUnit or 5
                    recoilFunctionInstance.RadiansPerUnit = math.rad(recoilFunctionInstance.DegreesPerUnit)
                    recoilFunctionInstance.RecoilMultiplier = 0
                    recoilFunctionInstance:reset()
                    return recoilFunctionInstance
                end

                RecoilHandler.fromRecoilInfo = function(recoilInfo)
                    return RecoilHandler.new(
                        recoilInfo.XFunction, recoilInfo.YFunction, recoilInfo.StartingPoint, recoilInfo.Step, recoilInfo.DegreesPerUnit
                    )
                end

                RecoilHandler.setRecoilMultiplier = function(recoilInfo, multiplier)
                    recoilInfo.RecoilMultiplier = 0
                end

                RecoilHandler.reset = function(recoilInstance)
                    recoilInstance.CurrentStep = recoilInstance.StartingPoint
                    recoilInstance.PreviousX = recoilInstance.XFunction(recoilInstance.CurrentStep)
                    recoilInstance.PreviousY = recoilInstance.YFunction(recoilInstance.CurrentStep)
                end

                RecoilHandler.getFinalRecoilMultiplier = function(recoilInfo)
                    return 0
                end

                RecoilHandler.nextStep = function(recoilInstance)
                    recoilInstance.CurrentStep = recoilInstance.CurrentStep + recoilInstance.Step
                    local currentX = recoilInstance.XFunction(recoilInstance.CurrentStep)
                    local currentY = recoilInstance.YFunction(recoilInstance.CurrentStep)
                    recoilInstance.PreviousX = currentX
                    recoilInstance.PreviousY = currentY
                end
            end
        end

        -- Классический обход таблиц в памяти (для других пушек)
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
                
                if rawget(v, "BaseBulletVelocity") or rawget(v, "Velocity") then
                    rawset(v, "BaseBulletVelocity", Toggles.SilentAim.Value and 999999 or 200)
                    rawset(v, "Velocity", Toggles.SilentAim.Value and 999999 or 200)
                end

                if Toggles.SilentAim.Value then
                    if rawget(v, "Recoil") or rawget(v, "recoil") then rawset(v, "Recoil", 0); rawset(v, "recoil", 0) end
                    if rawget(v, "Spread") or rawget(v, "spread") then rawset(v, "Spread", 0); rawset(v, "spread", 0) end
                    if rawget(v, "KickUp") or rawget(v, "kickUp") then rawset(v, "KickUp", 0); rawset(v, "kickUp", 0) end
                end
            end
        end
    end)
end

task.spawn(function()
    while task.wait(1.5 + math.random()) do 
        if Toggles.SilentAim.Value then ProcessToolMods() end 
    end
end)

table.insert(Cache.Connections, LocalPlayer.CharacterAdded:Connect(function(char)
    CleanFly()
    char.ChildAdded:Connect(function(c) if c:IsA("Tool") then task.spawn(ProcessToolMods) end end)
end))

--------------------------------------------------------------------------------
-- ГЛАВНЫЙ ЦИКЛ ОБНОВЛЕНИЯ
--------------------------------------------------------------------------------
local lastTargetPlr = nil

table.insert(Cache.Connections, RunService.RenderStepped:Connect(function()
    local Character = LocalPlayer.Character
    local RootPart = Character and Character:FindFirstChild("HumanoidRootPart")
    local Humanoid = Character and Character:FindFirstChildOfClass("Humanoid")
    
    -- Цикл Fullbright
    if Toggles.FullbrightToggle and Toggles.FullbrightToggle.Value then
        Lighting.Brightness = 2
        Lighting.ClockTime = 14
        Lighting.FogEnd = 999999
        Lighting.GlobalShadows = false
        Lighting.OutdoorAmbient = Color3.fromRGB(128, 128, 128)
    end

    -- 1. Сбор цели для Silent Aim
    local targetPart = GetTargetFromFOV()
    Cache.CurrentSilentTarget = targetPart
    
    -- Отрисовка точки таргета
    if targetPart and Toggles.SilentAim.Value then
        local targetPos, onScreen = Camera:WorldToViewportPoint(targetPart.Position)
        if onScreen then
            UI_Elements.TargetDot.Position = Vector2.new(targetPos.X, targetPos.Y)
            UI_Elements.TargetDot.Visible = true
        else
            UI_Elements.TargetDot.Visible = false
        end
    else
        UI_Elements.TargetDot.Visible = false
    end
    
    -- 2. Логика Target HUD
    if HUD_Settings.Enabled and targetPart then
        local targetPlayer = Players:GetPlayerFromCharacter(targetPart.Parent)
        if targetPlayer and targetPlayer ~= LocalPlayer then
            local tAlive, tHum, tRoot = IsAliveAndValid(targetPlayer)
            if tAlive then
                lastTargetPlr = targetPlayer
                NameLabel.Text = targetPlayer.Name
                DistLabel.Text = math.floor((tRoot.Position - (RootPart and RootPart.Position or Vector3.new())).Magnitude) .. " studs"
                
                -- Расчет здоровья
                local healthRatio = math.clamp(tHum.Health / tHum.MaxHealth, 0, 1)
                TweenService:Create(HealthBar, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                    Size = UDim2.new(healthRatio, 0, 1, 0)
                }):Play()
                
                HealthText.Text = math.floor(tHum.Health) .. " / " .. math.floor(tHum.MaxHealth)
                InvLabel.Text = "Inventory: " .. GetPlayerInventory(targetPlayer)
                
                -- Аватарка
                AvatarImage.Image = "rbxthumb://type=AvatarHeadShot&id=" .. targetPlayer.UserId .. "&w=150&h=150"
                MainFrame.Visible = true
            else
                MainFrame.Visible = false
            end
        end
    else
        MainFrame.Visible = false
    end
    
    -- 3. Логика Управления Fly
    if Toggles.FlyEnabled and Toggles.FlyEnabled.Value and RootPart and Humanoid then
        if not FlyVelocity then
            FlyVelocity = Instance.new("BodyVelocity")
            FlyVelocity.MaxForce = Vector3.new(1e5, 1e5, 1e5)
            FlyVelocity.Parent = RootPart
        end
        if not FlyGyro then
            FlyGyro = Instance.new("BodyGyro")
            FlyGyro.MaxTorque = Vector3.new(1e5, 1e5, 1e5)
            FlyGyro.CFrame = Camera.CFrame
            FlyGyro.Parent = RootPart
        end
        
        Humanoid.PlatformStand = true
        FlyGyro.CFrame = Camera.CFrame
        
        local moveDir = Humanoid.MoveDirection
        if moveDir.Magnitude > 0 then
            FlyVelocity.Velocity = moveDir * Options.FlySpeed.Value
        else
            FlyVelocity.Velocity = Vector3.new(0, 0, 0)
        end
    else
        CleanFly()
    end
    
    -- 4. Отрисовка ESP & Chams
    local masterEsp = Toggles.MasterEsp and Toggles.MasterEsp.Value
    
    for player, esp in pairs(espObjects) do
        local alive, hum, root = IsAliveAndValid(player)
        local chams = chamsObjects[player]
        
        if masterEsp and alive then
            local char = player.Character
            local head = char:FindFirstChild("Head")
            
            if head then
                local rootPos, rootPosOnScreen = Camera:WorldToViewportPoint(root.Position)
                local headPos, headPosOnScreen = Camera:WorldToViewportPoint(head.Position + Vector3.new(0, 0.5, 0))
                local legPos, legPosOnScreen = Camera:WorldToViewportPoint(root.Position - Vector3.new(0, 3, 0))
                
                if rootPosOnScreen then
                    local boxHeight = math.abs(headPos.Y - legPos.Y)
                    local boxWidth = boxHeight * 0.6
                    
                    -- Box ESP
                    if Toggles.EspBox and Toggles.EspBox.Value then
                        esp.Box.Size = Vector2.new(boxWidth, boxHeight)
                        esp.Box.Position = Vector2.new(rootPos.X - boxWidth / 2, headPos.Y)
                        esp.Box.Visible = true
                    else
                        esp.Box.Visible = false
                    end
                    
                    -- Name ESP
                    if Toggles.EspName and Toggles.EspName.Value then
                        esp.Name.Text = player.Name
                        esp.Name.Position = Vector2.new(rootPos.X, headPos.Y - 20)
                        esp.Name.Visible = true
                    else
                        esp.Name.Visible = false
                    end
                    
                    -- Distance ESP
                    if Toggles.EspDist and Toggles.EspDist.Value then
                        local distance = RootPart and math.floor((root.Position - RootPart.Position).Magnitude) or 0
                        esp.Dist.Text = tostring(distance) .. "m"
                        esp.Dist.Position = Vector2.new(rootPos.X, legPos.Y + 5)
                        esp.Dist.Visible = true
                    else
                        esp.Dist.Visible = false
                    end
                    
                    -- Health Bar ESP
                    if Toggles.EspHealth and Toggles.EspHealth.Value then
                        local barHeight = boxHeight
                        local barWidth = 3
                        local barPosX = rootPos.X - (boxWidth / 2) - 7
                        local barPosY = headPos.Y
                        
                        esp.HealthBg.Size = Vector2.new(barWidth, barHeight)
                        esp.HealthBg.Position = Vector2.new(barPosX, barPosY)
                        esp.HealthBg.Visible = true
                        
                        local healthFactor = math.clamp(hum.Health / hum.MaxHealth, 0, 1)
                        esp.HealthBar.Size = Vector2.new(barWidth, barHeight * healthFactor)
                        esp.HealthBar.Position = Vector2.new(barPosX, barPosY + (barHeight * (1 - healthFactor)))
                        esp.HealthBar.Visible = true
                    else
                        esp.HealthBg.Visible = false
                        esp.HealthBar.Visible = false
                    end
                else
                    for _, drawing in pairs(esp) do drawing.Visible = false end
                end
            else
                for _, drawing in pairs(esp) do drawing.Visible = false end
            end
            
            -- Chams
            if chams then
                chams.Enabled = Toggles.EspHighlight and Toggles.EspHighlight.Value or false
                if chams.Enabled then chams.Adornee = char else chams.Adornee = nil end
            end
        else
            for _, drawing in pairs(esp) do drawing.Visible = false end
            if chams then chams.Enabled = false chams.Adornee = nil end
        end
    end
end))

