--[[
	WARNING: Heads up! This script has not been verified by ScriptBlox. Use at your own risk!
]]
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local UserInputService = game:GetService("UserInputService")
local Camera = Workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

local repo = 'https://raw.githubusercontent.com/alper213/lianardo-ui-libary-mobil-support/main/'
local Library = loadstring(game:HttpGet(repo .. 'LinoriaModded.lua'))()

local Window = Library:CreateWindow({Title = 'Altron Engine [ROST]', Center = true, AutoShow = true, TabPadding = 8, MenuFadeTime = 0.2})

local Tabs = {
    Combat = Window:AddTab('Combat'),
    Visuals = Window:AddTab('Visuals'),
    World = Window:AddTab('World'),
    Misc = Window:AddTab('Misc'),
    Settings = Window:AddTab('Settings')
}

local Cache = {Players = {}, WorldInstances = {}, CurrentSilentTarget = nil, ToolModHooked = false}
local UI_Elements = {
    FovCircle = Drawing.new("Circle"),
    TargetDot = Drawing.new("Circle")
}
UI_Elements.FovCircle.Thickness = 1
UI_Elements.FovCircle.NumSides = 64
UI_Elements.FovCircle.Color = Color3.fromRGB(255, 255, 255)
UI_Elements.FovCircle.Filled = false
UI_Elements.TargetDot.Radius = 4
UI_Elements.TargetDot.Thickness = 1
UI_Elements.TargetDot.NumSides = 20
UI_Elements.TargetDot.Color = Color3.fromRGB(255, 0, 0)
UI_Elements.TargetDot.Filled = true

local CombatAimGroup = Tabs.Combat:AddLeftGroupbox('Silent Aim')
CombatAimGroup:AddToggle('SilentAim', {Text = 'Enable Silent Aim'})
CombatAimGroup:AddToggle('WallCheck', {Text = 'Wall Check '})
CombatAimGroup:AddDropdown('HitboxPart', {Values = {'Head', 'HumanoidRootPart', 'Randomize'}, Default = 1, Multi = false, Text = 'Target Hitbox'})

local CombatFovGroup = Tabs.Combat:AddLeftGroupbox('FOV Settings')
CombatFovGroup:AddToggle('DrawFov', {Text = 'Draw FOV Circle'})
CombatFovGroup:AddToggle('DynamicFov', {Text = 'Dynamic FOV '})
CombatFovGroup:AddSlider('FovRadius', {Text = 'FOV Radius', Default = 150, Min = 10, Max = 1000, Rounding = 0})

local CombatModsGroup = Tabs.Combat:AddRightGroupbox('Weapon Mods')
CombatModsGroup:AddToggle('NoSpread', {Text = 'No Spread '})
CombatModsGroup:AddToggle('NoRecoil', {Text = 'No Recoil '})
CombatModsGroup:AddToggle('MaxVel', {Text = 'Max Velocity '})
CombatModsGroup:AddToggle('ZeroGrav', {Text = 'Zero Gravity '})

local EspGroup = Tabs.Visuals:AddLeftGroupbox('Player ESP')
EspGroup:AddToggle('MasterEsp', {Text = 'Master ESP Enable'})
EspGroup:AddToggle('EspBox', {Text = 'Show Box'})
EspGroup:AddToggle('EspName', {Text = 'Show Name'})
EspGroup:AddToggle('EspDist', {Text = 'Show Distance'})
EspGroup:AddToggle('EspHealth', {Text = 'Show Health Bar (Pink)'})
EspGroup:AddToggle('EspItem', {Text = 'Show Equipped Item/Icon'})

local BpGroup = Tabs.Visuals:AddRightGroupbox('Backpack Viewer')
BpGroup:AddToggle('BpView', {Text = 'Enable Target Backpack Viewer'})
BpGroup:AddDropdown('BpTargetMode', {Values = {'FOV Target', 'Closest Player'}, Default = 1, Multi = false, Text = 'Target Method'})

local WorldEspGroup = Tabs.World:AddLeftGroupbox('World ESP (Chams) (ai)')
WorldEspGroup:AddToggle('HempEsp', {Text = 'Hemp ESP'})
WorldEspGroup:AddToggle('CrateEsp', {Text = 'Crates & ToolBox ESP'})
WorldEspGroup:AddToggle('BpEsp', {Text = 'Death Backpacks ESP'})
WorldEspGroup:AddToggle('TcEsp', {Text = 'Tool Cupboard ESP'})

local EnvGroup = Tabs.World:AddRightGroupbox('Environment')
EnvGroup:AddToggle('Fullbright', {Text = 'Fullbright'})
EnvGroup:AddToggle('NoGrass', {Text = 'Remove Grass'})
EnvGroup:AddToggle('NoLeaves', {Text = 'Remove Tree Leaves'})

local MiscGroup = Tabs.Misc:AddLeftGroupbox('Auto Critical ')
MiscGroup:AddToggle('AutoOre', {Text = 'Auto Hit Ore '})
MiscGroup:AddToggle('AutoTree', {Text = 'Auto Hit Tree '})

local MenuGrp = Tabs.Settings:AddLeftGroupbox('Menu Settings')
MenuGrp:AddButton('Unload UI', function() Library:Unload() end)
MenuGrp:AddLabel('Menu Bind'):AddKeyPicker('MenuBind', {Default = 'RightShift', NoUI = true, Text = 'Menu Bind'})
Library.ToggleKeybind = Options.MenuBind

local function IsAliveAndValid(player)
    if not player or not player.Character then return false end
    local hum = player.Character:FindFirstChild("Humanoid")
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
        if part.Transparency < 0.9 and part.CanCollide then
            return false
        end
    end
    return true
end

local espGui = Instance.new("ScreenGui")
espGui.Name = "awdhauashd"
espGui.IgnoreGuiInset = true
local succ = pcall(function() espGui.Parent = CoreGui end)
if not succ then espGui.Parent = LocalPlayer:WaitForChild("PlayerGui") end

local espObjects = {}
local function createESP(player)
    local esp = {
        Box = Instance.new("Frame"), Name = Instance.new("TextLabel"), Dist = Instance.new("TextLabel"),
        HealthBg = Instance.new("Frame"), HealthBar = Instance.new("Frame"), HealthLabel = Instance.new("TextLabel"),
        ItemIcon = Instance.new("ImageLabel"), ItemLabel = Instance.new("TextLabel")
    }
    esp.Box.BackgroundTransparency = 1; esp.Box.BorderColor3 = Color3.fromRGB(255, 255, 255); esp.Box.BorderSizePixel = 1; esp.Box.Parent = espGui
    esp.Name.BackgroundTransparency = 1; esp.Name.TextColor3 = Color3.fromRGB(255, 255, 255); esp.Name.TextStrokeTransparency = 0.5; esp.Name.Font = Enum.Font.Code; esp.Name.TextSize = 14; esp.Name.Parent = espGui
    esp.Dist.BackgroundTransparency = 1; esp.Dist.TextColor3 = Color3.fromRGB(200, 200, 200); esp.Dist.TextStrokeTransparency = 0.5; esp.Dist.Font = Enum.Font.Code; esp.Dist.TextSize = 12; esp.Dist.Parent = espGui
    esp.HealthBg.BackgroundColor3 = Color3.fromRGB(0, 0, 0); esp.HealthBg.BorderSizePixel = 0; esp.HealthBg.Parent = espGui
    esp.HealthBar.BackgroundColor3 = Color3.fromRGB(255, 105, 180); esp.HealthBar.BorderSizePixel = 0; esp.HealthBar.Parent = esp.HealthBg
    esp.HealthLabel.BackgroundTransparency = 1; esp.HealthLabel.TextColor3 = Color3.fromRGB(255, 255, 255); esp.HealthLabel.TextStrokeTransparency = 0.8; esp.HealthLabel.Font = Enum.Font.Code; esp.HealthLabel.TextSize = 11; esp.HealthLabel.Parent = espGui
    esp.ItemIcon.BackgroundTransparency = 1; esp.ItemIcon.ScaleType = Enum.ScaleType.Fit; esp.ItemIcon.Parent = espGui
    esp.ItemLabel.BackgroundTransparency = 1; esp.ItemLabel.TextColor3 = Color3.fromRGB(255, 215, 0); esp.ItemLabel.TextStrokeTransparency = 0.5; esp.ItemLabel.Font = Enum.Font.Code; esp.ItemLabel.TextSize = 12; esp.ItemLabel.Parent = espGui
    espObjects[player] = esp
end

local function removeESP(player)
    if espObjects[player] then for _, v in pairs(espObjects[player]) do v:Destroy() end; espObjects[player] = nil end
end

for _, p in pairs(Players:GetPlayers()) do if p ~= LocalPlayer then createESP(p) end end
Players.PlayerAdded:Connect(function(p) createESP(p) end)
Players.PlayerRemoving:Connect(function(p) removeESP(p) end)

local bpGui = Instance.new("ScreenGui")
bpGui.Name = "ServerBackpackViewer"
bpGui.IgnoreGuiInset = true
pcall(function() bpGui.Parent = CoreGui end)

local bpFrame = Instance.new("Frame")
bpFrame.Size = UDim2.new(0, 240, 0, 300)
bpFrame.Position = UDim2.new(0.8, -20, 0.4, 0)
bpFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
bpFrame.BorderSizePixel = 0
bpFrame.Visible = false 
bpFrame.Parent = bpGui

local bpTitle = Instance.new("TextLabel", bpFrame)
bpTitle.Size = UDim2.new(1, 0, 0, 25)
bpTitle.BackgroundColor3 = Color3.fromRGB(255, 105, 180)
bpTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
bpTitle.Text = " Player Inventory"
bpTitle.Font = Enum.Font.Code
bpTitle.TextSize = 14
bpTitle.TextXAlignment = Enum.TextXAlignment.Left

local bpList = Instance.new("ScrollingFrame", bpFrame)
bpList.Size = UDim2.new(1, 0, 1, -25)
bpList.Position = UDim2.new(0, 0, 0, 25)
bpList.BackgroundTransparency = 1
bpList.BorderSizePixel = 0
bpList.ScrollBarThickness = 4
local bpLayout = Instance.new("UIGridLayout", bpList)
bpLayout.CellSize = UDim2.new(0, 45, 0, 45)
bpLayout.CellPadding = UDim2.new(0, 5, 0, 5)

local dragging, dragInput, mousePos, framePos = false, nil, nil, nil
bpTitle.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true; mousePos = input.Position; framePos = bpFrame.Position
        input.Changed:Connect(function() if input.UserInputState == Enum.UserInputState.End then dragging = false end end)
    end
end)
bpTitle.InputChanged:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseMovement then dragInput = input end end)
UserInputService.InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        local delta = input.Position - mousePos
        bpFrame.Position = UDim2.new(framePos.X.Scale, framePos.X.Offset + delta.X, framePos.Y.Scale, framePos.Y.Offset + delta.Y)
    end
end)

local currentRandomPart = "Head"
task.spawn(function()
    while task.wait(1.5) do
        if Options.HitboxPart.Value == "Randomize" then currentRandomPart = (currentRandomPart == "Head" and "HumanoidRootPart" or "Head") else currentRandomPart = Options.HitboxPart.Value end
    end
end)

local function ProcessToolMods()
    pcall(function()
        for _, v in pairs(getgc(true)) do
            if type(v) == "table" then
                -- Gun Mods
                if rawget(v, "getfireDirection") then
                    v.getfireDirection = function(self, origin, raycast)
                        if Toggles.SilentAim.Value and Cache.CurrentSilentTarget then return (Cache.CurrentSilentTarget.Position - origin).Unit end
                        return Camera.CFrame.LookVector
                    end
                end
                if rawget(v, "BaseBulletVelocity") or rawget(v, "Velocity") then
                    if Toggles.MaxVel.Value then v.BaseBulletVelocity = 999999; v.Velocity = 999999 end
                end
                if rawget(v, "BulletGravity") or rawget(v, "Gravity") then
                    if Toggles.ZeroGrav.Value then v.BulletGravity = 0; v.Gravity = 0 end
                end
                if rawget(v, "TotalAttachmentStats") then
                    local s = v.TotalAttachmentStats
                    if Toggles.NoSpread.Value then s.SpreadMult = 0; s.AimSpreadMult = 0; s.PelletSpread = 0 end
                    if Toggles.NoRecoil.Value then s.RecoilMult = 0; s.AimRecoilMult = 0; s.KickMult = 0 end
                end
                

                if rawget(v, "hit") and rawget(v, "use") then
                    if not Cache.ToolModHooked then
                        local oldH = v.hit
                        v.hit = function(self, inst, pos)
                            local tI, tP = inst, pos
                            if Toggles.AutoOre.Value or Toggles.AutoTree.Value then
                                local c = self.OwnerPlayer and self.OwnerPlayer.Character
                                if c and c:FindFirstChild("HumanoidRootPart") then
                                    local mp = c.HumanoidRootPart.Position
                                    local cp, md = nil, 20
                                    for _, obj in ipairs(Workspace:GetDescendants()) do
                                        if obj:IsA("BasePart") then
                                            if (obj.Name == "star" and Toggles.AutoOre.Value) or (obj.Name == "cross" and Toggles.AutoTree.Value) then
                                                local d = (mp - obj.Position).Magnitude
                                                if d < md then cp = obj; md = d end
                                            end
                                        end
                                    end
                                    if cp then tI = cp; tP = cp.Position end
                                end
                            end
                            return oldH(self, tI, tP)
                        end
                        Cache.ToolModHooked = true
                    end
                    v.Range = 20
                end
            end
        end
    end)
end

local gcDebounce = false
local function SafeHook()
    if gcDebounce then return end
    gcDebounce = true
    task.wait(1)
    ProcessToolMods()
    gcDebounce = false
end

local function HookEquip(char)
    char.ChildAdded:Connect(function(c) if c:IsA("Tool") then task.spawn(SafeHook) end end)
end
if LocalPlayer.Character then
    HookEquip(LocalPlayer.Character)
    if LocalPlayer.Character:FindFirstChildOfClass("Tool") then task.spawn(SafeHook) end
end
LocalPlayer.CharacterAdded:Connect(HookEquip)

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
                        local dC = (Vector2.new(sp.X, sp.Y) - Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)).Magnitude
                        if dC < sDist then sDist = dC; best = hitb end
                    end
                end
            end
        end
    end
    return best
end

RunService.RenderStepped:Connect(function()
    if Toggles.SilentAim.Value then
        Cache.CurrentSilentTarget = GetTargetFromFOV()
        if Cache.CurrentSilentTarget then
            local p, o = Camera:WorldToViewportPoint(Cache.CurrentSilentTarget.Position)
            UI_Elements.TargetDot.Position = Vector2.new(p.X, p.Y)
            UI_Elements.TargetDot.Visible = o
        else UI_Elements.TargetDot.Visible = false end
    else UI_Elements.FovCircle.Visible = false; UI_Elements.TargetDot.Visible = false; Cache.CurrentSilentTarget = nil end

    for p, esp in pairs(espObjects) do
        local alive, hum, root = IsAliveAndValid(p)
        if Toggles.MasterEsp.Value and alive then
            local head = p.Character:FindFirstChild("Head")
            local pos, onS = Camera:WorldToViewportPoint(root.Position)
            if onS and head then
                local hp = Camera:WorldToViewportPoint(head.Position + Vector3.new(0, 0.5, 0))
                local lp = Camera:WorldToViewportPoint(root.Position - Vector3.new(0, 3, 0))
                local h = math.abs(hp.Y - lp.Y)
                local w = h * 0.55
                esp.Box.Size = UDim2.new(0, w, 0, h); esp.Box.Position = UDim2.new(0, pos.X - w/2, 0, hp.Y); esp.Box.Visible = Toggles.EspBox.Value
                esp.Name.Text = p.Name; esp.Name.Position = UDim2.new(0, pos.X - 50, 0, hp.Y - 20); esp.Name.Size = UDim2.new(0, 100, 0, 20); esp.Name.Visible = Toggles.EspName.Value
                local dist = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") and math.floor((LocalPlayer.Character.HumanoidRootPart.Position - root.Position).Magnitude) or 0
                esp.Dist.Text = "[" .. dist .. "m]"; esp.Dist.Position = UDim2.new(0, pos.X - 50, 0, lp.Y + 2); esp.Dist.Size = UDim2.new(0, 100, 0, 20); esp.Dist.Visible = Toggles.EspDist.Value
                local hPct = math.clamp(hum.Health / hum.MaxHealth, 0, 1)
                esp.HealthBg.Size = UDim2.new(0, 4, 0, h); esp.HealthBg.Position = UDim2.new(0, (pos.X - w/2) - 7, 0, hp.Y); esp.HealthBg.Visible = Toggles.EspHealth.Value
                esp.HealthBar.Size = UDim2.new(1, 0, hPct, 0); esp.HealthBar.Position = UDim2.new(0, 0, 1 - hPct, 0)
                esp.HealthLabel.Text = tostring(math.floor(hum.Health)); esp.HealthLabel.Position = UDim2.new(0, (pos.X - w/2) - 28, 0, hp.Y + (h * (1 - hPct)) - 5); esp.HealthLabel.Size = UDim2.new(0, 20, 0, 10); esp.HealthLabel.Visible = Toggles.EspHealth.Value
                local t = p.Character:FindFirstChildOfClass("Tool")
                if Toggles.EspItem.Value and t then
                    if t.TextureId and t.TextureId ~= "" then esp.ItemIcon.Image = t.TextureId; esp.ItemIcon.Size = UDim2.new(0, 24, 0, 24); esp.ItemIcon.Position = UDim2.new(0, pos.X - 12, 0, lp.Y + 18); esp.ItemIcon.Visible = true; esp.ItemLabel.Visible = false
                    else esp.ItemLabel.Text = t.Name; esp.ItemLabel.Size = UDim2.new(0, 100, 0, 20); esp.ItemLabel.Position = UDim2.new(0, pos.X - 50, 0, lp.Y + 18); esp.ItemLabel.Visible = true; esp.ItemIcon.Visible = false end
                else esp.ItemIcon.Visible = false; esp.ItemLabel.Visible = false end
            else for _, v in pairs(esp) do v.Visible = false end end
        else for _, v in pairs(esp) do v.Visible = false end end
    end
end)

task.spawn(function()
    while task.wait(0.5) do
        local hI = false
        for _, c in ipairs(bpList:GetChildren()) do if c:IsA("ImageLabel") then c:Destroy() end end
        if Toggles.BpView.Value then
            local tP = nil
            if Options.BpTargetMode.Value == "FOV Target" then
                if Cache.CurrentSilentTarget and Cache.CurrentSilentTarget.Parent then tP = Players:GetPlayerFromCharacter(Cache.CurrentSilentTarget.Parent) end
                if not tP then
                    local sD = Options.FovRadius.Value; local sc = Camera.ViewportSize / 2
                    for _, p in pairs(Players:GetPlayers()) do
                        if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                            local pP, oS = Camera:WorldToViewportPoint(p.Character.HumanoidRootPart.Position)
                            if oS then local d = (Vector2.new(pP.X, pP.Y) - sc).Magnitude; if d <= sD then sD = d; tP = p end end
                        end
                    end
                end
            else
                local sD = math.huge; local mp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") and LocalPlayer.Character.HumanoidRootPart.Position
                if mp then
                    for _, p in pairs(Players:GetPlayers()) do
                        if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                            local d = (p.Character.HumanoidRootPart.Position - mp).Magnitude; if d < sD then sD = d; tP = p end
                        end
                    end
                end
            end

            if tP and tP.Character then
                local b, cI = tP:FindFirstChild("Backpack"), {}
                for _, i in ipairs(tP.Character:GetChildren()) do if i:IsA("Tool") and i.TextureId and i.TextureId ~= "" then table.insert(cI, {I = i.TextureId, U = true}) end end
                if b then for _, i in ipairs(b:GetChildren()) do if i:IsA("Tool") and i.TextureId and i.TextureId ~= "" then table.insert(cI, {I = i.TextureId, U = false}) end end end
                if #cI > 0 then
                    hI = true
                    bpTitle.Text = " ["..tP.Name.."] Inventory"
                    for _, v in ipairs(cI) do
                        local ic = Instance.new("ImageLabel"); ic.Size = UDim2.new(1, 0, 1, 0); ic.BackgroundTransparency = 1; ic.ScaleType = Enum.ScaleType.Fit; ic.Image = v.I; ic.Parent = bpList
                        if v.U then
                            local uL = Instance.new("TextLabel"); uL.Size = UDim2.new(1, 0, 0, 15); uL.Position = UDim2.new(0, 0, 1, -15); uL.BackgroundTransparency = 0.5; uL.BackgroundColor3 = Color3.fromRGB(0,0,0); uL.TextColor3 = Color3.fromRGB(255, 50, 50); uL.Text = "USING"; uL.Font = Enum.Font.Code; uL.TextSize = 10; uL.Parent = ic
                        end
                    end
                end
            end
        end
        bpFrame.Visible = hI
        bpList.CanvasSize = UDim2.new(0, 0, 0, math.ceil(#bpList:GetChildren() / 4) * 50)
    end
end)

local O_A, O_OA, O_GS = Lighting.Ambient, Lighting.OutdoorAmbient, Lighting.GlobalShadows
local function UpdateEnv()
    if Toggles.Fullbright.Value then Lighting.Ambient = Color3.fromRGB(255, 255, 255); Lighting.OutdoorAmbient = Color3.fromRGB(255, 255, 255); Lighting.GlobalShadows = false else Lighting.Ambient = O_A; Lighting.OutdoorAmbient = O_OA; Lighting.GlobalShadows = O_GS end
    if Workspace:FindFirstChild("Terrain") then Workspace.Terrain.Decoration = not Toggles.NoGrass.Value end
    if Toggles.NoLeaves.Value then local tr = Workspace:FindFirstChild("trees") or Workspace:FindFirstChild("Trees"); if tr then for _, i in ipairs(tr:GetDescendants()) do if i:IsA("BasePart") and (string.find(string.lower(i.Name), "leaf") or string.find(string.lower(i.Name), "leavestop")) then i.Transparency = 1; i.CanCollide = false end end end end
end

local function AddChams(inst, col, lblTxt)
    if Cache.WorldInstances[inst] then return end
    local hl = Instance.new("Highlight"); hl.Adornee = inst; hl.FillTransparency = 0.5; hl.OutlineTransparency = 0; hl.FillColor = col; hl.Parent = CoreGui
    local obj = {H = hl}
    if lblTxt then
        local bg = Instance.new("BillboardGui"); bg.Adornee = inst; bg.Size = UDim2.new(0, 200, 0, 50); bg.AlwaysOnTop = true; bg.MaxDistance = 1500; bg.Parent = CoreGui
        local tl = Instance.new("TextLabel"); tl.Parent = bg; tl.Size = UDim2.new(1, 0, 1, 0); tl.BackgroundTransparency = 1; tl.TextColor3 = Color3.fromRGB(255, 255, 255); tl.Font = Enum.Font.Code; tl.TextSize = 14; tl.Text = lblTxt
        obj.L = tl; obj.B = bg
    end
    Cache.WorldInstances[inst] = obj
end

local function RefWEsp()
    for i, d in pairs(Cache.WorldInstances) do if d.H then d.H:Destroy() end; if d.B then d.B:Destroy() end end; table.clear(Cache.WorldInstances)
    pcall(function()
        if Toggles.HempEsp.Value then local f = Workspace:FindFirstChild("Hemp"); if f then for _, i in ipairs(f:GetChildren()) do AddChams(i, Color3.fromRGB(0, 255, 0)) end end end
        if Toggles.CrateEsp.Value then
    local f = Workspace:FindFirstChild("crates") or Workspace:FindFirstChild("Crates")
    if f then
        for _, i in ipairs(f:GetDescendants()) do
            if i:IsA("Model") or i:IsA("BasePart") then
                -- Расчет дистанции
                local char = LocalPlayer.Character
                local distText = ""
                if char and char:FindFirstChild("HumanoidRootPart") then
                    local mag = math.floor((char.HumanoidRootPart.Position - (i:IsA("Model") and i.PrimaryPart or i).Position).Magnitude)
                    distText = " [" .. mag .. "m]"
                end

                -- Определение цвета и вызов функции
                if i.Name == "ToolBox" then
                    -- Розовый цвет для Тулбокса
                    AddChams(i, Color3.fromRGB(255, 105, 180), i.Name .. distText)
                elseif i.Name == "Crate" then
                    -- Желтый цвет для обычного Крейта
                    AddChams(i, Color3.fromRGB(255, 255, 0), i.Name .. distText)
                elseif i.Name == "MilitaryCrate" then
                    -- Военный (оливковый/зеленый) цвет для Милитари
                    AddChams(i, Color3.fromRGB(75, 83, 32), i.Name .. distText)
                end
            end
        end
    end
end
        if Toggles.BpEsp.Value then local f = Workspace:FindFirstChild("DeathBackpacks"); if f then for _, i in ipairs(f:GetChildren()) do AddChams(i, Color3.fromRGB(255, 0, 0), "Backpack") end end end
        if Toggles.TcEsp.Value then local f = Workspace:FindFirstChild("Builds"); if f then for _, i in ipairs(f:GetDescendants()) do if i.Name == "ToolCupboardModel" then AddChams(i, Color3.fromRGB(0, 150, 255)) end end end end
    end)
end

Toggles.HempEsp:OnChanged(RefWEsp); Toggles.CrateEsp:OnChanged(RefWEsp); Toggles.BpEsp:OnChanged(RefWEsp); Toggles.TcEsp:OnChanged(RefWEsp)
Toggles.Fullbright:OnChanged(UpdateEnv); Toggles.NoGrass:OnChanged(UpdateEnv); Toggles.NoLeaves:OnChanged(UpdateEnv)

task.spawn(function() while task.wait(3) do UpdateEnv() end end)
task.spawn(function()
    while task.wait(0.5) do
        local mp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") and LocalPlayer.Character.HumanoidRootPart.Position
        if mp then
            for i, d in pairs(Cache.WorldInstances) do
                if d.L then
                    local tp = (i:IsA("Model") and i.PrimaryPart and i.PrimaryPart.Position) or (i:IsA("BasePart") and i.Position)
                    if tp then d.L.Text = string.format("%s\n[%dm]", i.Name == "ToolCupboardModel" and "TC" or i.Name, math.floor((mp - tp).Magnitude)) end
                end
            end
        end
    end
end)
