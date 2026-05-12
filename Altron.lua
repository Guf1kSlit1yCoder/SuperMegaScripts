--https://discord.gg/2KxEtmuKxq
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local LocalPlayer = Players.LocalPlayer
local v5 = LocalPlayer
local v6 = Workspace.CurrentCamera
local v11 = Workspace

if not newcclosure then getgenv().newcclosure = function(f) return f end end
if not checkcaller then getgenv().checkcaller = function() return false end end
if not hookmetamethod then getgenv().hookmetamethod = function() end end
if not getnamecallmethod then getgenv().getnamecallmethod = function() return "" end end

local mathFloor = math.floor
local mathClamp = math.clamp
local mathAbs = math.abs
local mathRad = math.rad
local Vector2New = Vector2.new
local Vector3New = Vector3.new
local CFrameNew = CFrame.new
local tick = tick
local typeof = typeof
local pairs = pairs
local ipairs = ipairs
local pcall = pcall
local next = next
local string_format = string.format
local string_find = string.find
local task_spawn = task.spawn
local task_delay = task.delay
local task_wait = task.wait
local task_defer = task.defer

local DrawingOK = pcall(function() local t = Drawing.new("Line"); t:Remove() end)

local playerCache = {}
local function onPAdd(p) if p ~= LocalPlayer then playerCache[p] = true end end
local function onPRem(p) playerCache[p] = nil end
for _, p in ipairs(Players:GetPlayers()) do onPAdd(p) end
Players.PlayerAdded:Connect(onPAdd)
Players.PlayerRemoving:Connect(onPRem)

local cachedChar = LocalPlayer.Character
local cachedHumanoid = cachedChar and cachedChar:FindFirstChildWhichIsA("Humanoid")

local function updateCharCache(c)
    cachedChar = c
    cachedHumanoid = nil
    if c then
        local h = c:FindFirstChildWhichIsA("Humanoid")
        if h then cachedHumanoid = h
        else task_spawn(function()
            local h2 = c:WaitForChild("Humanoid", 15)
            if h2 and cachedChar == c then cachedHumanoid = h2 end
        end) end
    end
end

LocalPlayer.CharacterAdded:Connect(function(c) updateCharCache(c) end)
LocalPlayer.CharacterRemoving:Connect(function() cachedChar = nil; cachedHumanoid = nil end)
if cachedChar then updateCharCache(cachedChar) end

local Toggles = { SA_Enabled = {Value = false}, XRay = {Value = false} }
local Options = { SA_FOVRadius = {Value = 150} }

local v13 = {
    Enabled = false, TargetPart = "HumanoidRootPart",
    UseFOV = true, FOVRadius = 150, FOVRadiusSq = 22500,
    FOVColor = Color3.fromRGB(255,255,255),
    FOVColorNoTarget = Color3.fromRGB(255,0,0),
    FOVColorOnTarget = Color3.fromRGB(0,255,0),
    Snapline = false, SnaplineColor = Color3.fromRGB(255,255,255), SnaplineThickness = 2,
    WallCheck = false, Priority = "Crosshair",
    MaxDistance = 500, MaxDistanceSq = 250000,
}

local TracerSettings = { Enabled = false, Color = Color3.fromRGB(255,255,255), TextureID = "rbxassetid://12781852245", Width = 1.5, Transparency = 0, LifeTime = 0.5 }
local ESPOptions = { Enabled = false, Box = false, Name = false, Distance = false, HealthBar = false, Chams = false, TargetHUD = false }
local ESPColors = { Box1 = Color3.fromRGB(255,255,255), Name = Color3.fromRGB(255,255,255), Distance = Color3.fromRGB(255,255,255) }
local XRaySettings = { Enabled = false, Transparency = 0.5 }
local ForceFieldSettings = { Enabled = false, Color = Color3.fromRGB(128,128,128) }
local JumpCircleSettings = { Enabled = false, Color = Color3.fromRGB(0,170,255) }
local HitSoundSettings = { Enabled = false, Choice = "None", Volume = 1, OriginalSounds = {} }
local SpeedSettings = { Enabled = false, Value = 30 }
local NoJumpDelaySettings = { Enabled = false, Delay = 0.1, LastJumpTime = 0, Conn = nil }
local FOVSettings = { Enabled = false, Value = 70 }
local ThirdPersonSettings = { Enabled = false, Distance = 10 }
local AutoFireSettings = { Enabled = false, Delay = 0.05, LastFire = 0 }
local StretchSettings = { Enabled = false, Value = 0.65 }
local SpiderSettings = { Enabled = false, Speed = 50 }
local JumpStunSettings = { Enabled = false, Height = 100 }
local WaterSpeed = { Enabled = false, Value = 50 }
local NoDecorationEnabled = false
local SkyColorSettings = { Enabled = false, Color = Color3.fromRGB(135,200,255) }
local DeleteSpikesSettings = { Enabled = false }
local ToolHighlightSettings = { Enabled = false, Color = Color3.new(1,1,1) }
local KillNotify = false
local CurrentAimTarget = nil
local LibraryUnloaded = false
local jumpShootEnabled = false
local jumpShootPatched = {}
local SimpleJumpShootEnabled = false
local simpleJumpShootPatched = {}

local screenCenter = Vector2New(0,0)
local function getMousePosition()
    local cam = Workspace.CurrentCamera
    if cam then local vp = cam.ViewportSize; screenCenter = Vector2New(vp.X*0.5, vp.Y*0.5) end
    return screenCenter
end
local function getPositionOnScreen(pos)
    local cam = Workspace.CurrentCamera
    if not cam then return Vector2New(0,0), false end
    local p, v = cam:WorldToViewportPoint(pos)
    return Vector2New(p.X, p.Y), v
end
local function distSq2D(a, b) local dx, dy = a.X-b.X, a.Y-b.Y; return dx*dx+dy*dy end
local function distSq3D(a, b) local dx,dy,dz = a.X-b.X, a.Y-b.Y, a.Z-b.Z; return dx*dx+dy*dy+dz*dz end

local ignoreFolderNames = {"Viewmodel","ViewModel","Ignore","Debris","BulletTraces","Effects","GunEffects","Arms","FPSArms","Particles","Bullets"}
local wallRayP = RaycastParams.new()
wallRayP.FilterType = Enum.RaycastFilterType.Exclude
wallRayP.IgnoreWater = true

local function isPartVisible(origin, targetPos, targetChar)
    local il = {}
    if cachedChar then il[#il+1] = cachedChar end
    local cam = Workspace.CurrentCamera
    if cam then il[#il+1] = cam end
    for i = 1, #ignoreFolderNames do
        local f = Workspace:FindFirstChild(ignoreFolderNames[i])
        if f then il[#il+1] = f end
    end
    wallRayP.FilterDescendantsInstances = il
    for _ = 1, 4 do
        local dir = targetPos - origin
        if dir.Magnitude < 0.5 then return true end
        local r = Workspace:Raycast(origin, dir, wallRayP)
        if not r then return true end
        if r.Instance:IsDescendantOf(targetChar) then return true end
        if r.Instance:IsA("BasePart") and r.Instance.Transparency >= 0.9 then
            il[#il+1] = r.Instance; wallRayP.FilterDescendantsInstances = il; continue
        end
        local hitO = false
        for plr in next, playerCache do
            if plr.Character and r.Instance:IsDescendantOf(plr.Character) then
                il[#il+1] = plr.Character; wallRayP.FilterDescendantsInstances = il; hitO = true; break
            end
        end
        if hitO then continue end
        return false
    end
    return false
end

local function getClosestPlayer()
    local cam = Workspace.CurrentCamera
    if not cam then return nil end
    v6 = cam
    local myRoot = cachedChar and cachedChar:FindFirstChild("HumanoidRootPart")
    local myPos = myRoot and myRoot.Position
    local mousePos = getMousePosition()
    local camPos = cam.CFrame.Position
    local best, bestD = nil, nil
    for plr in next, playerCache do
        local ch = plr.Character; if not ch then continue end
        local part = ch:FindFirstChild(v13.TargetPart) or ch:FindFirstChild("HumanoidRootPart") or ch:FindFirstChild("Head")
        if not part or not part.Parent then continue end
        local hum = ch:FindFirstChild("Humanoid")
        if not hum or hum.Health <= 0 then continue end
        local pp = part.Position
        if myPos and distSq3D(myPos, pp) > v13.MaxDistanceSq then continue end
        local sp, vis = getPositionOnScreen(pp)
        if not vis then continue end
        local sd = distSq2D(mousePos, sp)
        if v13.UseFOV and sd > v13.FOVRadiusSq then continue end
        if v13.WallCheck and not isPartVisible(camPos, pp, ch) then continue end
        local cd = (v13.Priority == "Distance" and myPos) and distSq3D(myPos, pp) or sd
        if not bestD or cd < bestD then best = part; bestD = cd end
    end
    return best
end

local trPool, trSize = {}, 0
local function getTr()
    if trSize > 0 then local p = trPool[trSize]; trPool[trSize] = nil; trSize -= 1; return p end
    local p = Instance.new("Part"); p.Anchored = true; p.CanCollide = false; p.Transparency = 1; p.Size = Vector3New(0.1,0.1,0.1)
    local a0 = Instance.new("Attachment",p); a0.Name = "A0"
    local a1 = Instance.new("Attachment",p); a1.Name = "A1"
    local b = Instance.new("Beam"); b.Name = "B"; b.Attachment0 = a0; b.Attachment1 = a1
    b.FaceCamera = true; b.LightEmission = 1; b.LightInfluence = 0; b.TextureLength = 2; b.TextureSpeed = 2; b.Parent = p
    return p
end

local function createTrace(startPos, endPos)
    if LibraryUnloaded then return end
    local p = getTr(); p.Parent = Workspace
    local a0 = p:FindFirstChild("A0"); local a1 = p:FindFirstChild("A1")
    if a0 then a0.WorldPosition = startPos end
    if a1 then a1.WorldPosition = endPos end
    local b = p:FindFirstChild("B")
    if b then
        b.Color = ColorSequence.new(TracerSettings.Color)
        b.Transparency = NumberSequence.new(TracerSettings.Transparency)
        b.Texture = TracerSettings.TextureID
        b.Width0 = TracerSettings.Width; b.Width1 = TracerSettings.Width; b.Enabled = true
    end
    task_delay(TracerSettings.LifeTime, function()
        if p then if b then b.Enabled = false end; p.Parent = nil; trSize += 1; trPool[trSize] = p end
    end)
end

local function doAutoFire()
    if mouse1click then mouse1click() else
        local s, vim = pcall(game.GetService, game, "VirtualInputManager")
        if s and vim then vim:SendMouseButtonEvent(0,0,0,true,game,0); task_defer(function() vim:SendMouseButtonEvent(0,0,0,false,game,0) end) end
    end
end

local espCache = {}
local function mkEsp()
    if not DrawingOK then return nil end
    local e = {}
    e.Box = Drawing.new("Square"); e.Box.Visible = false; e.Box.Thickness = 1; e.Box.Filled = false; e.Box.Transparency = 1
    e.BoxOutline = Drawing.new("Square"); e.BoxOutline.Visible = false; e.BoxOutline.Thickness = 3; e.BoxOutline.Filled = false; e.BoxOutline.Color = Color3.new(0,0,0); e.BoxOutline.Transparency = 1
    e.Name = Drawing.new("Text"); e.Name.Visible = false; e.Name.Center = true; e.Name.Outline = true; e.Name.Size = 13; e.Name.Font = 2
    e.Dist = Drawing.new("Text"); e.Dist.Visible = false; e.Dist.Center = true; e.Dist.Outline = true; e.Dist.Size = 13; e.Dist.Font = 2
    e.HpBg = Drawing.new("Square"); e.HpBg.Visible = false; e.HpBg.Filled = true; e.HpBg.Color = Color3.new(0,0,0); e.HpBg.Transparency = 0.5
    e.Hp = Drawing.new("Square"); e.Hp.Visible = false; e.Hp.Filled = true; e.Hp.Transparency = 1
    e.Chams = nil; e.VisibleNow = false; e.LastVisCheck = 0
    return e
end

local function hideEsp(e)
    if not e then return end
    if e.Box then e.Box.Visible = false end
    if e.BoxOutline then e.BoxOutline.Visible = false end
    if e.Name then e.Name.Visible = false end
    if e.Dist then e.Dist.Visible = false end
    if e.HpBg then e.HpBg.Visible = false end
    if e.Hp then e.Hp.Visible = false end
    if e.Chams then pcall(function() e.Chams:Destroy() end); e.Chams = nil end
end

local function rmEsp(plr)
    local e = espCache[plr]; if not e then return end
    pcall(function()
        if e.Box then e.Box:Remove() end; if e.BoxOutline then e.BoxOutline:Remove() end
        if e.Name then e.Name:Remove() end; if e.Dist then e.Dist:Remove() end
        if e.HpBg then e.HpBg:Remove() end; if e.Hp then e.Hp:Remove() end
        if e.Chams then e.Chams:Destroy() end
    end)
    espCache[plr] = nil
end
Players.PlayerRemoving:Connect(rmEsp)

local function updateESP()
    if not ESPOptions.Enabled then for _, e in pairs(espCache) do hideEsp(e) end; return end
    if not DrawingOK then return end
    local cam = Workspace.CurrentCamera; if not cam then return end
    local camPos = cam.CFrame.Position
    local myRoot = cachedChar and cachedChar:FindFirstChild("HumanoidRootPart")
    local now = tick()
    for plr in next, playerCache do
        local ch = plr.Character
        if not ch then if espCache[plr] then hideEsp(espCache[plr]) end; continue end
        local hrp = ch:FindFirstChild("HumanoidRootPart"); local hum = ch:FindFirstChild("Humanoid")
        if not hrp or not hum or hum.Health <= 0 then if espCache[plr] then hideEsp(espCache[plr]) end; continue end
        local pos = hrp.Position
        local topS = cam:WorldToViewportPoint(pos + Vector3New(0,3,0))
        local botS = cam:WorldToViewportPoint(pos - Vector3New(0,3,0))
        if topS.Z < 0 and botS.Z < 0 then if espCache[plr] then hideEsp(espCache[plr]) end; continue end
        if not espCache[plr] then espCache[plr] = mkEsp() end
        local e = espCache[plr]; if not e then continue end
        local h = mathAbs(botS.Y - topS.Y); local w = h*0.6
        local cx = (topS.X+botS.X)*0.5; local bx = cx-w*0.5; local by = topS.Y
        if ESPOptions.Box then
            e.BoxOutline.Visible = true; e.BoxOutline.Position = Vector2New(bx,by); e.BoxOutline.Size = Vector2New(w,h)
            e.Box.Visible = true; e.Box.Position = Vector2New(bx,by); e.Box.Size = Vector2New(w,h); e.Box.Color = ESPColors.Box1
        else e.Box.Visible = false; e.BoxOutline.Visible = false end
        if ESPOptions.Name then e.Name.Visible = true; e.Name.Position = Vector2New(cx,by-16); e.Name.Text = plr.DisplayName; e.Name.Color = ESPColors.Name
        else e.Name.Visible = false end
        if ESPOptions.Distance and myRoot then e.Dist.Visible = true; e.Dist.Position = Vector2New(cx,by+h+2); e.Dist.Text = mathFloor((myRoot.Position-pos).Magnitude).."m"; e.Dist.Color = ESPColors.Distance
        else e.Dist.Visible = false end
        if ESPOptions.HealthBar then
            local barX = bx-6; local barW = 3; local hp = mathClamp(hum.Health/hum.MaxHealth,0,1)
            e.HpBg.Visible = true; e.HpBg.Position = Vector2New(barX,by); e.HpBg.Size = Vector2New(barW,h)
            e.Hp.Visible = true; e.Hp.Position = Vector2New(barX,by+h*(1-hp)); e.Hp.Size = Vector2New(barW,h*hp); e.Hp.Color = Color3.fromRGB(255*(1-hp),255*hp,0)
        else e.HpBg.Visible = false; e.Hp.Visible = false end
        if ESPOptions.Chams then
            local isVis = false
            if now-(e.LastVisCheck or 0) >= 0.1 then e.LastVisCheck = now; isVis = isPartVisible(camPos,pos,ch); e.VisibleNow = isVis else isVis = e.VisibleNow end
            local col = isVis and Color3.fromRGB(0,255,0) or Color3.fromRGB(255,0,0)
            if not e.Chams or not e.Chams.Parent then
                if e.Chams then pcall(function() e.Chams:Destroy() end) end
                local hl = Instance.new("Highlight"); hl.FillTransparency = 0.5; hl.OutlineTransparency = 0.8; hl.FillColor = col; hl.Adornee = ch; hl.Parent = ch; e.Chams = hl
            else e.Chams.FillColor = col end
        else if e.Chams then pcall(function() e.Chams:Destroy() end); e.Chams = nil end end
    end
end

local function patchModuleForJumpShoot(modInst, patchList)
    local s, tbl = pcall(require, modInst)
    if not s or type(tbl) ~= "table" then return end
    local funcNames = {"canFire","canShoot","CanFire","CanShoot","isGrounded","IsGrounded","onGround","OnGround","checkGround","CheckGround","groundCheck","GroundCheck","canUse","CanUse"}
    local boolPatches = {
        {n="requireGrounded",g=false},{n="RequireGrounded",g=false},{n="canFireInAir",g=true},{n="canShootInAir",g=true},
        {n="canFireWhileSwimming",g=true},{n="CanFireInAir",g=true},{n="CanShootInAir",g=true},{n="canFireWhileJumping",g=true},
        {n="CanFireWhileJumping",g=true},{n="requireOnGround",g=false},{n="RequireOnGround",g=false},{n="groundedOnly",g=false},{n="GroundedOnly",g=false},
    }
    local function patchTable(t)
        for _, fname in ipairs(funcNames) do
            if type(t[fname]) == "function" then
                local key = "_jsp_"..fname
                if not t[key] then t[key] = t[fname]; t[fname] = function(...) return true end; patchList[#patchList+1] = {t=t,n=fname,k=key} end
            end
        end
        for _, bp in ipairs(boolPatches) do
            if t[bp.n] ~= nil then
                local key = "_jsp_"..bp.n
                if not t[key] then t[key] = t[bp.n]; t[bp.n] = bp.g; patchList[#patchList+1] = {t=t,n=bp.n,k=key} end
            end
        end
    end
    patchTable(tbl)
    for _, v in pairs(tbl) do if type(v) == "table" then patchTable(v) end end
end

local function scanAndPatchModules(patchList)
    local kws = {"client","gun","weapon","fire","shoot","tool","combat","arm","fps","controller","input","action"}
    local function ok(name) local low = name:lower(); for _,kw in ipairs(kws) do if low:find(kw) then return true end end; return false end
    local function scanContainer(container)
        if not container then return end
        for _, v in ipairs(container:GetDescendants()) do
            if v:IsA("ModuleScript") and ok(v.Name) then pcall(patchModuleForJumpShoot, v, patchList) end
        end
    end
    scanContainer(ReplicatedStorage)
    scanContainer(game:FindFirstChild("StarterPlayer"))
    scanContainer(LocalPlayer:FindFirstChild("PlayerScripts"))
    scanContainer(LocalPlayer:FindFirstChild("Backpack"))
    if cachedChar then scanContainer(cachedChar) end
end

local function unpatchAll(patchList)
    for _, p in ipairs(patchList) do pcall(function() p.t[p.n] = p.t[p.k]; p.t[p.k] = nil end) end
end

local function toggleJumpShoot(en)
    jumpShootEnabled = en
    if en then jumpShootPatched = {}; task_spawn(function() scanAndPatchModules(jumpShootPatched) end)
    else unpatchAll(jumpShootPatched); jumpShootPatched = {} end
end

local function toggleSimpleJumpShoot(en)
    SimpleJumpShootEnabled = en
    if en then simpleJumpShootPatched = {}; task_spawn(function() scanAndPatchModules(simpleJumpShootPatched) end)
    else unpatchAll(simpleJumpShootPatched); simpleJumpShootPatched = {} end
end

local spikesConn = nil
local function removeAllSpikes()
    local count = 0
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj.Name == "Spikes" then pcall(function() obj:Destroy() end); count += 1 end
    end
    if count > 0 then pcall(function() Settings:Notify("Removed "..count.." spikes", 3) end) end
end
local function toggleDeleteSpikes(en)
    DeleteSpikesSettings.Enabled = en
    if en then
        removeAllSpikes()
        if spikesConn then pcall(function() spikesConn:Disconnect() end) end
        spikesConn = Workspace.DescendantAdded:Connect(function(obj)
            if DeleteSpikesSettings.Enabled and obj.Name == "Spikes" then task_defer(function() pcall(function() obj:Destroy() end) end) end
        end)
    else
        if spikesConn then pcall(function() spikesConn:Disconnect() end); spikesConn = nil end
    end
end

local toolHighlightConns = {}
local allToolHighlights = {}

local function applyHighlightToTool(tool)
    if not tool:IsA("Tool") then return end
    local oldHl = tool:FindFirstChild("VomToolHL")
    if oldHl then oldHl:Destroy() end
    if not ToolHighlightSettings.Enabled then return end
    local hl = Instance.new("Highlight"); hl.Name = "VomToolHL"; hl.Adornee = tool
    hl.FillTransparency = 1; hl.OutlineColor = ToolHighlightSettings.Color; hl.OutlineTransparency = 0; hl.Parent = tool
    allToolHighlights[tool] = hl
end

local function removeAllToolHighlights()
    for _, hl in pairs(allToolHighlights) do if hl and hl.Parent then pcall(function() hl:Destroy() end) end end
    allToolHighlights = {}
end

local function setupToolHighlights()
    for _, conn in pairs(toolHighlightConns) do pcall(function() conn:Disconnect() end) end
    toolHighlightConns = {}
    if not ToolHighlightSettings.Enabled then removeAllToolHighlights(); return end
    local bp = LocalPlayer:FindFirstChild("Backpack")
    if bp then
        for _, tool in pairs(bp:GetChildren()) do applyHighlightToTool(tool) end
        toolHighlightConns[#toolHighlightConns+1] = bp.ChildAdded:Connect(function(tool)
            if ToolHighlightSettings.Enabled and tool:IsA("Tool") then task_defer(function() applyHighlightToTool(tool) end) end
        end)
    end
    if cachedChar then
        for _, tool in pairs(cachedChar:GetChildren()) do if tool:IsA("Tool") then applyHighlightToTool(tool) end end
        toolHighlightConns[#toolHighlightConns+1] = cachedChar.ChildAdded:Connect(function(tool)
            if ToolHighlightSettings.Enabled and tool:IsA("Tool") then task_defer(function() applyHighlightToTool(tool) end) end
        end)
    end
    toolHighlightConns[#toolHighlightConns+1] = LocalPlayer.CharacterAdded:Connect(function(ch)
        task_wait(1)
        local newBp = LocalPlayer:FindFirstChild("Backpack")
        if newBp then
            for _, tool in pairs(newBp:GetChildren()) do applyHighlightToTool(tool) end
            toolHighlightConns[#toolHighlightConns+1] = newBp.ChildAdded:Connect(function(tool)
                if ToolHighlightSettings.Enabled and tool:IsA("Tool") then task_defer(function() applyHighlightToTool(tool) end) end
            end)
        end
        toolHighlightConns[#toolHighlightConns+1] = ch.ChildAdded:Connect(function(tool)
            if ToolHighlightSettings.Enabled and tool:IsA("Tool") then task_defer(function() applyHighlightToTool(tool) end) end
        end)
    end)
end

local StellarHubMenu = (function() local s,r = pcall(function() return loadstring(game:HttpGet("https://raw.githubusercontent.com/ImNotFatBitch/uimenu/main/StellarhubMenu"))() end); return s and r end)()
local Settings = (function() local s,r = pcall(function() return loadstring(game:HttpGet("https://raw.githubusercontent.com/ImNotFatBitch/uimenu/main/StellarhubSettings"))() end); return s and r end)()
if not StellarHubMenu or not Settings then return end

local Window = StellarHubMenu:Create({
    Title = 'AltronEngine [ROST]', Size = UDim2.new(0, 200, 0, 150).
    Position = UDim2.new(0.5,0,0.5,0), ShowOnCreate = true, PerformanceMode = false,
    TweenSpeed = 0.3, UnloadTotal = true, PlayerListEnabled = false,
    WatermarkEnabled = true, WatermarkText = 'ALTRON rost alpha',
    CanChangeTitleWatermark = true, ObfuscateConfig = false,
    MobileLogo = 'rbxassetid://14768967526',
})

local Tabs = { Combat = Window:AddTab('Combat'), Visual = Window:AddTab('Visual'), Player = Window:AddTab('Player') }
Settings:InitializeSettingsTab(Window, 'ALTRONConfig', 'Config')

local SABox = Tabs.Combat:AddLeftGroupbox('Silent Aim')
SABox:AddToggle('SA_Enabled', { Text = 'Silent Aim Enabled', Default = false, Callback = function(v) v13.Enabled = v; Toggles.SA_Enabled.Value = v end }):AddKeybind('SA_Key', { Default = 'P', Mode = 'Toggle', Title = 'Keybind' })
SABox:AddToggle('SA_WallCheck', { Text = 'Wall Check', Default = false, Callback = function(v) v13.WallCheck = v end })
SABox:AddDropdown('SA_TargetPart', { Values = {"Head","HumanoidRootPart"}, Default = 2, Multi = false, Text = 'Target Part', Callback = function(v) v13.TargetPart = v end })
SABox:AddDropdown('SA_Priority', { Values = {"Crosshair","Distance"}, Default = 1, Multi = false, Text = 'Priority', Callback = function(v) v13.Priority = v end })
SABox:AddToggle('SA_UseFOV', { Text = 'Use FOV', Default = true, Callback = function(v) v13.UseFOV = v end }):AddColorPicker('SA_FOVColor', { Default = v13.FOVColor, Title = 'FOV Color', Callback = function(v) v13.FOVColor = v end })
SABox:AddSlider('SA_FOVRadius', { Text = 'FOV Radius', Default = 150, Min = 50, Max = 1000, Rounding = 0, Callback = function(v) v13.FOVRadius = v; v13.FOVRadiusSq = v*v; Options.SA_FOVRadius.Value = v end })
SABox:AddSlider('SA_MaxDistance', { Text = 'Max Distance', Default = 500, Min = 50, Max = 3000, Rounding = 0, Callback = function(v) v13.MaxDistance = v; v13.MaxDistanceSq = v*v end })
SABox:AddToggle('AutoFireToggle', { Text = 'Auto Fire', Default = false, Callback = function(v) AutoFireSettings.Enabled = v end })
SABox:AddSlider('AutoFireDelay', { Text = 'Fire Delay', Default = 0.05, Min = 0.01, Max = 0.5, Rounding = 2, Callback = function(v) AutoFireSettings.Delay = v end })

local CMods = Tabs.Combat:AddRightGroupbox('Gun Mods')
local recoilMod = nil
local function setupNoRecoil(val)
    if val then
        if not recoilMod then pcall(function() recoilMod = require(ReplicatedStorage:WaitForChild("Gun"):WaitForChild("Scripts"):WaitForChild("RecoilHandler")) end) end
        if recoilMod then
            if not recoilMod._o_nS then recoilMod._o_nS = recoilMod.nextStep end
            if not recoilMod._o_sRM then recoilMod._o_sRM = recoilMod.setRecoilMultiplier end
            recoilMod.nextStep = function() end; recoilMod.setRecoilMultiplier = function() end
        end
    elseif recoilMod then
        if recoilMod._o_nS then recoilMod.nextStep = recoilMod._o_nS; recoilMod._o_nS = nil end
        if recoilMod._o_sRM then recoilMod.setRecoilMultiplier = recoilMod._o_sRM; recoilMod._o_sRM = nil end
    end
end
CMods:AddToggle('NoRecoil', { Text = 'No Recoil', Default = false, Callback = function(v) setupNoRecoil(v) end })
CMods:AddToggle('JumpShoot', { Text = 'Jump Shoot', Default = false, Callback = function(v) toggleJumpShoot(v) end })
CMods:AddToggle('SimpleShootJump', { Text = 'Air/Jump Shoot (Buggy)', Default = false, Callback = function(v)
    toggleSimpleJumpShoot(v)
    if v then pcall(function() Settings:Notify("WARNING: You enabled a buggy feature. When you run out of ammo, bullet visuals will persist. Enable 'Jump Shoot' instead - it does not have this bug.", 8) end) end
end })

local EBox = Tabs.Visual:AddLeftGroupbox('ESP Settings')
EBox:AddToggle('ESPEnabled', { Text = 'Master Switch', Default = false, Callback = function(v) ESPOptions.Enabled = v; if not v then for _,e in pairs(espCache) do hideEsp(e) end end end })
EBox:AddToggle('ESPBox', { Text = 'Box', Default = false, Callback = function(v) ESPOptions.Box = v end }):AddColorPicker('BoxColor', { Default = ESPColors.Box1, Title = 'Color', Callback = function(v) ESPColors.Box1 = v end })
EBox:AddToggle('ESPChams', { Text = 'Chams (Green=Visible)', Default = false, Callback = function(v) ESPOptions.Chams = v; if not v then for _,e in pairs(espCache) do if e.Chams then pcall(function() e.Chams:Destroy() end); e.Chams = nil end end end end })
EBox:AddToggle('ESPName', { Text = 'Name', Default = false, Callback = function(v) ESPOptions.Name = v end })
EBox:AddToggle('ESPDistance', { Text = 'Distance', Default = false, Callback = function(v) ESPOptions.Distance = v end })
EBox:AddToggle('ESPHealthBar', { Text = 'Health Bar', Default = false, Callback = function(v) ESPOptions.HealthBar = v end })

local VOther = Tabs.Visual:AddRightGroupbox('Features')
VOther:AddToggle('TargetHUDToggle', { Text = 'Target HUD', Default = false, Callback = function(v) ESPOptions.TargetHUD = v end })
VOther:AddToggle('KillNotify', { Text = 'Global Kill Notify', Default = false, Callback = function(v) KillNotify = v end })
VOther:AddToggle('DeleteSpikes', { Text = 'Delete Spikes', Default = false, Callback = function(v) toggleDeleteSpikes(v) end })
VOther:AddToggle('ToolHighlight', { Text = 'Tool Outline', Default = false, Callback = function(v) ToolHighlightSettings.Enabled = v; setupToolHighlights() end
}):AddColorPicker('ToolHighlightColor', { Default = Color3.new(1,1,1), Title = 'Outline Color', Callback = function(v)
    ToolHighlightSettings.Color = v
    for _, hl in pairs(allToolHighlights) do if hl and hl.Parent then pcall(function() hl.OutlineColor = v end) end end
end })

local SG = Tabs.Visual:AddRightGroupbox('Stretch Resolution')
SG:AddToggle('StretchToggle', { Text = 'Stretch Enabled', Default = false, Callback = function(v) StretchSettings.Enabled = v end })
SG:AddSlider('StretchValue', { Text = 'Stretch Amount', Default = 0.65, Min = 0.3, Max = 1.0, Rounding = 2, Callback = function(v) StretchSettings.Value = v end })

local BTG = Tabs.Visual:AddRightGroupbox('Bullet Tracers')
BTG:AddToggle('BulletTrace', { Text = 'Enabled', Default = false, Callback = function(v) TracerSettings.Enabled = v end }):AddColorPicker('TraceColor', { Default = TracerSettings.Color, Title = 'Color', Callback = function(v) TracerSettings.Color = v end })
BTG:AddDropdown('BulletTracersTexture', { Values = {"Beam","Lightning","Heartrate","Chain","Glitch","Swirl"}, Default = 1, Multi = false, Text = 'Texture',
    Callback = function(V) local m = {Beam="rbxassetid://12781852245",Lightning="rbxassetid://446111271",Heartrate="rbxassetid://5830549480",Chain="rbxassetid://9632168658",Glitch="rbxassetid://8089467613",Swirl="rbxassetid://5638168605"}; TracerSettings.TextureID = m[V] or m.Beam end })
BTG:AddSlider('TracerWidth', { Text = 'Width', Min = 0.1, Max = 5, Default = 1.5, Rounding = 1, Callback = function(v) TracerSettings.Width = v end })
BTG:AddSlider('TracerTransparency', { Text = 'Transparency', Min = 0, Max = 1, Default = 0, Rounding = 2, Callback = function(v) TracerSettings.Transparency = v end })
BTG:AddSlider('TracerLifeTime', { Text = 'Life Time', Min = 0.1, Max = 3, Default = 0.5, Rounding = 1, Callback = function(v) TracerSettings.LifeTime = v end })

VOther:AddToggle('FOVChangerToggle', { Text = 'FOV Changer', Default = false, Callback = function(v) FOVSettings.Enabled = v end })
VOther:AddSlider('FOVChangerValue', { Text = 'FOV Value', Min = 50, Max = 120, Default = 70, Rounding = 0, Callback = function(v) FOVSettings.Value = v end })
VOther:AddToggle('ThirdPersonToggle', { Text = 'Third Person', Default = false, Callback = function(v) ThirdPersonSettings.Enabled = v end })
VOther:AddSlider('ThirdPersonDistance', { Text = 'Camera Distance', Min = 5, Max = 50, Default = 10, Rounding = 0, Callback = function(v) ThirdPersonSettings.Distance = v end })
VOther:AddToggle('JumpCircles', { Text = 'Jump Circles', Default = false, Callback = function(v) JumpCircleSettings.Enabled = v end }):AddColorPicker('JumpCircleColor', { Default = Color3.fromRGB(0,170,255), Title = 'Circle Color', Callback = function(v) JumpCircleSettings.Color = v end })
VOther:AddToggle('XRay', { Text = 'X-Ray', Default = false, Callback = function(v) XRaySettings.Enabled = v; Toggles.XRay.Value = v; setXrayState(v, XRaySettings.Transparency) end
}):AddKeybind('XRayKey', { Default = 'X', Mode = 'Toggle', Title = 'Key' })
VOther:AddSlider('XRayTrans', { Text = 'XRay Transparency', Default = 0.5, Min = 0, Max = 1, Rounding = 2, Callback = function(v) XRaySettings.Transparency = v; if Toggles.XRay.Value then setXrayState(true,v) end end })

local WV = Tabs.Visual:AddLeftGroupbox('World Visuals')
local FB = { Enabled = false, Conn = nil }
local OL = { Brightness = Lighting.Brightness, ClockTime = Lighting.ClockTime, FogEnd = Lighting.FogEnd, GlobalShadows = Lighting.GlobalShadows, Ambient = Lighting.Ambient }
local function ToggleFB(st)
    FB.Enabled = st
    if st then
        Lighting.Brightness = 2; Lighting.ClockTime = 14; Lighting.FogEnd = 100000; Lighting.GlobalShadows = false; Lighting.Ambient = Color3.fromRGB(178,178,178)
        if not FB.Conn then FB.Conn = Lighting.Changed:Connect(function()
            if FB.Enabled then Lighting.Brightness = 2; Lighting.ClockTime = 14; Lighting.FogEnd = 100000; Lighting.GlobalShadows = false; Lighting.Ambient = Color3.fromRGB(178,178,178) end
        end) end
    else if FB.Conn then FB.Conn:Disconnect(); FB.Conn = nil end
        Lighting.Brightness = OL.Brightness; Lighting.ClockTime = OL.ClockTime; Lighting.FogEnd = OL.FogEnd; Lighting.GlobalShadows = OL.GlobalShadows; Lighting.Ambient = OL.Ambient end
end
WV:AddToggle('Fullbright', { Text = 'Fullbright', Default = false, Callback = function(v) ToggleFB(v) end })
WV:AddToggle('NoDecoration', { Text = 'No Decoration', Default = false, Callback = function(v) NoDecorationEnabled = v; pcall(function() local t = Workspace:FindFirstChildOfClass("Terrain"); if t and sethiddenproperty then sethiddenproperty(t,"Decoration",not v) end end) end })

local skyFx = nil
WV:AddToggle('SkyColorToggle', { Text = 'Sky Color', Default = false,
    Callback = function(v) SkyColorSettings.Enabled = v
        if v then if not skyFx then skyFx = Instance.new("ColorCorrectionEffect"); skyFx.Name = "VomSky"; skyFx.Parent = Lighting end; skyFx.TintColor = SkyColorSettings.Color
        elseif skyFx then skyFx:Destroy(); skyFx = nil end
    end
}):AddColorPicker('SkyColorPicker', { Default = Color3.fromRGB(135,200,255), Title = 'Sky Color', Callback = function(v) SkyColorSettings.Color = v; if SkyColorSettings.Enabled and skyFx then skyFx.TintColor = v end end })

local SkyData = {["Sky 1"]={Bk=271042516,Dn=271077243,Ft=271042556,Lf=271042310,Rt=271042467,Up=271077958},["Sky 2"]={Bk=17279854976,Dn=17279856318,Ft=17279858447,Lf=17279860360,Rt=17279862234,Up=17279864507},["Sky 3"]={Bk=12064107,Dn=12064152,Ft=12064121,Lf=12063984,Rt=12064115,Up=12064131}}
WV:AddDropdown('SkyboxChanger', { Values = {"Default","Sky 1","Sky 2","Sky 3"}, Default = 1, Multi = false, Text = 'Skybox',
    Callback = function(v) local sky = Lighting:FindFirstChildOfClass("Sky")
        if v == "Default" then if sky then sky:Destroy() end
        elseif SkyData[v] then if not sky then sky = Instance.new("Sky"); sky.Parent = Lighting end; local d = SkyData[v]
            sky.SkyboxBk="rbxassetid://"..d.Bk; sky.SkyboxDn="rbxassetid://"..d.Dn; sky.SkyboxFt="rbxassetid://"..d.Ft
            sky.SkyboxLf="rbxassetid://"..d.Lf; sky.SkyboxRt="rbxassetid://"..d.Rt; sky.SkyboxUp="rbxassetid://"..d.Up end end })

local HSBox = Tabs.Visual:AddLeftGroupbox('Hit Sounds')
local HSList = {None="",Skeet="rbxassetid://83717596220569",["Sonic checkpoint"]="rbxassetid://6817150445",["Sonic.exe laugh"]="rbxassetid://18379039436",["Windows XP Error"]="rbxassetid://9066167010",["Minecraft Hit"]="rbxassetid://8766809464",["one sit nn dog"]="rbxassetid://7380502345",["Door Bell"]="rbxassetid://131845870598154",Duck="rbxassetid://1139819274",Mgs="rbxassetid://81845122657643",Money="rbxassetid://3020841054",Fart="rbxassetid://4809574295",Meow="rbxassetid://7148585764",byebye="rbxassetid://70888261086432"}
local HSNames = {} for n in pairs(HSList) do HSNames[#HSNames+1] = n end
local function applyHS(snd, vol) if not snd or not snd.Parent then return end; if not HitSoundSettings.OriginalSounds[snd] then HitSoundSettings.OriginalSounds[snd] = {SoundId=snd.SoundId,Volume=snd.Volume} end; local id = HSList[HitSoundSettings.Choice] or ""; if id ~= "" then snd.SoundId = id else local o = HitSoundSettings.OriginalSounds[snd]; if o then snd.SoundId = o.SoundId end end; snd.Volume = vol end
local function restoreHS() for snd,d in pairs(HitSoundSettings.OriginalSounds) do if snd and snd.Parent then pcall(function() snd.SoundId = d.SoundId; snd.Volume = d.Volume end) end end; HitSoundSettings.OriginalSounds = {} end
local function chkTool(tool) if not tool or not tool:IsA("Tool") then return end; task_spawn(function() local ba = tool:FindFirstChild("BodyAttach") or tool:WaitForChild("BodyAttach",5); if ba then for _,sn in ipairs({"HitClient","HeadShotClient","HitCharacterClient"}) do local s = ba:FindFirstChild(sn) or ba:WaitForChild(sn,3); if s and s:IsA("Sound") then applyHS(s, HitSoundSettings.Volume) end end end end) end
local function applyHSChar(ch) if not ch then return end; for _,c in pairs(ch:GetChildren()) do if c:IsA("Tool") then chkTool(c) end end end
HSBox:AddToggle('HitSoundEnabled', { Text = 'Hit Sound Enabled', Default = false, Callback = function(v) HitSoundSettings.Enabled = v; if v then if LocalPlayer.Character then applyHSChar(LocalPlayer.Character) end else restoreHS() end end })
HSBox:AddDropdown('HitSoundChoice', { Values = HSNames, Default = 1, Multi = false, Text = 'Sound', Callback = function(v) HitSoundSettings.Choice = v; if HitSoundSettings.Enabled and LocalPlayer.Character then applyHSChar(LocalPlayer.Character) end end })
HSBox:AddSlider('HitSoundVolume', { Text = 'Volume', Min = 0, Max = 10, Default = 1, Rounding = 1, Callback = function(v) HitSoundSettings.Volume = v; if HitSoundSettings.Enabled and LocalPlayer.Character then applyHSChar(LocalPlayer.Character) end end })

local hsConn = nil
local function setupHSChar(ch) if hsConn then pcall(function() hsConn:Disconnect() end); hsConn = nil end
    hsConn = ch.ChildAdded:Connect(function(c) if HitSoundSettings.Enabled and not LibraryUnloaded and c:IsA("Tool") then task_delay(0.3, function() chkTool(c) end) end end)
    task_spawn(function() task_wait(1.5); if HitSoundSettings.Enabled and ch and ch.Parent then applyHSChar(ch) end end) end

local LV = Tabs.Visual:AddLeftGroupbox('Local Player')
local function UpdateFF() local ch = LocalPlayer.Character; if not ch then return end
    if ForceFieldSettings.Enabled then for _,p in pairs(ch:GetDescendants()) do if p:IsA("BasePart") then p.Material = Enum.Material.ForceField; p.Color = ForceFieldSettings.Color end end
    else for _,p in pairs(ch:GetDescendants()) do if p:IsA("BasePart") and p.Material == Enum.Material.ForceField then p.Material = Enum.Material.Plastic; p.Color = Color3.fromRGB(255,255,255) end end end end
LV:AddToggle('ForceFieldChams', { Text = 'ForceField Material', Default = false, Callback = function(v) ForceFieldSettings.Enabled = v; UpdateFF() end
}):AddColorPicker('ForceFieldColor', { Default = Color3.fromRGB(128,128,128), Title = 'Color', Callback = function(v) ForceFieldSettings.Color = v; if ForceFieldSettings.Enabled then UpdateFF() end end })

local MBox = Tabs.Player:AddLeftGroupbox('Movement')
MBox:AddToggle('SpeedEnabled', { Text = 'Speed', Default = false, Callback = function(v) SpeedSettings.Enabled = v end }):AddKeybind('SpeedKey', { Default = 'G', Mode = 'Toggle', Title = 'Speed Key' })
MBox:AddSlider('SpeedValue', { Text = 'Speed Value', Min = 0, Max = 60, Default = 30, Rounding = 0, Callback = function(v) SpeedSettings.Value = v end })
MBox:AddToggle('WaterSpeed', { Text = 'Swim Speed', Default = false, Callback = function(v) WaterSpeed.Enabled = v end }):AddKeybind('WaterSpeedKey', { Default = 'C', Mode = 'Toggle', Title = 'Water Speed' })
MBox:AddSlider('SwimSpeedVal', { Text = 'Water Speed Value', Min = 20, Max = 200, Default = 50, Rounding = 0, Callback = function(v) WaterSpeed.Value = v end })

MBox:AddToggle('NoJumpDelay', { Text = 'No Jump Delay', Default = false,
    Callback = function(v)
        NoJumpDelaySettings.Enabled = v
        if NoJumpDelaySettings.Conn then NoJumpDelaySettings.Conn:Disconnect(); NoJumpDelaySettings.Conn = nil end
        if v then
            NoJumpDelaySettings.Conn = RunService.RenderStepped:Connect(function()
                if not NoJumpDelaySettings.Enabled or LibraryUnloaded then return end
                local ch = cachedChar; if not ch then return end
                local hum = ch:FindFirstChildWhichIsA("Humanoid")
                if not hum or hum.Health <= 0 then return end
                if UserInputService:IsKeyDown(Enum.KeyCode.Space) and hum.FloorMaterial ~= Enum.Material.Air then
                    local now = tick()
                    if now - NoJumpDelaySettings.LastJumpTime >= NoJumpDelaySettings.Delay then
                        hum.Jump = true
                        hum:ChangeState(Enum.HumanoidStateType.Jumping)
                        NoJumpDelaySettings.LastJumpTime = now
                    end
                end
            end)
        end
    end
})
MBox:AddSlider('NoJumpDelayVal', { Text = 'Jump Delay (sec)', Default = 0.1, Min = 0, Max = 0.5, Rounding = 2, Callback = function(v) NoJumpDelaySettings.Delay = v end })

local JSBox = Tabs.Player:AddLeftGroupbox('Super Jump')
JSBox:AddToggle('JumpStunEnabled', { Text = 'Enable Super Jump', Default = false, Callback = function(v) JumpStunSettings.Enabled = v end
}):AddKeybind('JumpStunKey', { Default = 'H', Mode = 'Toggle', Title = 'Super Jump Key' })
JSBox:AddSlider('JumpStunHeight', { Text = 'Jump Height', Default = 100, Min = 60, Max = 200, Rounding = 0, Callback = function(v) JumpStunSettings.Height = v end })

UserInputService.JumpRequest:Connect(function()
    if LibraryUnloaded or not JumpStunSettings.Enabled then return end
    local r = cachedChar and cachedChar:FindFirstChild("HumanoidRootPart")
    if r then r.AssemblyLinearVelocity = Vector3New(r.AssemblyLinearVelocity.X, JumpStunSettings.Height, r.AssemblyLinearVelocity.Z) end
end)

local SpBox = Tabs.Player:AddRightGroupbox('Spider')
local spRay = RaycastParams.new(); spRay.FilterType = Enum.RaycastFilterType.Exclude; spRay.IgnoreWater = true
SpBox:AddToggle('SpiderEnabled', { Text = 'Spider Climb', Default = false, Callback = function(v) SpiderSettings.Enabled = v end }):AddKeybind('SpiderKey', { Default = 'V', Mode = 'Toggle', Title = 'Spider Key' })
SpBox:AddSlider('SpiderSpeed', { Text = 'Climb Speed', Default = 50, Min = 20, Max = 150, Rounding = 0, Callback = function(v) SpiderSettings.Speed = v end })

local function onJump(_, new)
    if new == Enum.HumanoidStateType.Jumping and JumpCircleSettings.Enabled then
        local r = cachedChar and cachedChar:FindFirstChild("HumanoidRootPart")
        if r then
            local p = Instance.new("Part",workspace); p.Anchored = true; p.CanCollide = false; p.Material = Enum.Material.Neon; p.Color = JumpCircleSettings.Color
            p.CFrame = CFrameNew(r.Position - Vector3New(0,2.9,0)) * CFrame.Angles(mathRad(90),0,0)
            local m = Instance.new("SpecialMesh",p); m.MeshId = "rbxassetid://3270017"; m.MeshType = Enum.MeshType.FileMesh
            TweenService:Create(p, TweenInfo.new(0.4), {Transparency=1}):Play()
            TweenService:Create(m, TweenInfo.new(0.4,Enum.EasingStyle.Quad,Enum.EasingDirection.Out), {Scale=Vector3New(8,8,0.2)}):Play()
            task_delay(0.4, function() if p then p:Destroy() end end)
        end
    end
end

local wlK = {"TwigWall","SoloTwigFrame","TrigTwigRoof","TwigFrame","TwigWindow","TwigRoof"}
local xrT = {}
local function isWL(n) for _,k in ipairs(wlK) do if string_find(n,k) then return true end end; return false end
local function regXR(o) if xrT[o] then return end; if (o:IsA("BasePart") or o:IsA("MeshPart") or o:IsA("UnionOperation")) and isWL(o.Name) then xrT[o] = {OT=o.Transparency} end end
function setXrayState(a,t) for p,d in pairs(xrT) do if p and p:IsDescendantOf(Workspace) then p.Transparency = a and t or d.OT end end end
task_spawn(function() for _,o in pairs(Workspace:GetDescendants()) do regXR(o) end end)
Workspace.DescendantAdded:Connect(function(o) regXR(o); if XRaySettings.Enabled and (o:IsA("BasePart") or o:IsA("MeshPart") or o:IsA("UnionOperation")) and isWL(o.Name) then o.Transparency = XRaySettings.Transparency end end)

local HG = Instance.new("ScreenGui"); HG.Name = "STHUD"; HG.Parent = game.CoreGui; HG.Enabled = false
local MF = Instance.new("Frame"); MF.Size = UDim2.new(0,320,0,90); MF.AnchorPoint = Vector2.new(0.5,0.5); MF.Position = UDim2.new(0.5, 0, 0.5, 0); MF.BackgroundColor3 = Color3.fromRGB(30,30,30); MF.BackgroundTransparency = 0.1; MF.BorderSizePixel = 0; MF.Parent = HG
local AI = Instance.new("ImageLabel"); AI.Size = UDim2.new(0,60,0,60); AI.Position = UDim2.new(0,15,0,15); AI.BackgroundTransparency = 1; AI.Parent = MF
local TC = Instance.new("Frame"); TC.BackgroundTransparency = 1; TC.Position = UDim2.new(0,85,0,10); TC.Size = UDim2.new(1,-95,0,50); TC.Parent = MF
local NL = Instance.new("TextLabel"); NL.Size = UDim2.new(1,0,0,25); NL.BackgroundTransparency = 1; NL.Text = ""; NL.Font = Enum.Font.GothamBold; NL.TextSize = 20; NL.TextColor3 = Color3.new(1,1,1); NL.TextXAlignment = Enum.TextXAlignment.Left; NL.Parent = TC
local DL = Instance.new("TextLabel"); DL.Size = UDim2.new(1,0,0,20); DL.Position = UDim2.new(0,0,0,25); DL.BackgroundTransparency = 1; DL.Text = ""; DL.Font = Enum.Font.Gotham; DL.TextSize = 16; DL.TextColor3 = Color3.fromRGB(200,200,200); DL.TextXAlignment = Enum.TextXAlignment.Left; DL.Parent = TC
local HBG2 = Instance.new("Frame"); HBG2.Size = UDim2.new(1,-30,0,12); HBG2.Position = UDim2.new(0,15,1,-20); HBG2.BackgroundColor3 = Color3.fromRGB(15,15,15); HBG2.BorderSizePixel = 0; HBG2.Parent = MF
local HBF2 = Instance.new("Frame"); HBF2.Size = UDim2.new(1,0,1,0); HBF2.BackgroundColor3 = Color3.new(1,1,1); HBF2.BorderSizePixel = 0; HBF2.Parent = HBG2
Instance.new("UIGradient",HBF2).Color = ColorSequence.new{ColorSequenceKeypoint.new(0,Color3.fromRGB(255,60,150)),ColorSequenceKeypoint.new(1,Color3.fromRGB(255,230,50))}

local lastTH = 0
local function UpdTH(now)
    if not ESPOptions.TargetHUD or not v13.Enabled then HG.Enabled = false; return end
    if now-lastTH < 0.15 then return end; lastTH = now
    local ch = CurrentAimTarget and CurrentAimTarget.Parent
    if ch and ch:FindFirstChild("Humanoid") and ch:FindFirstChild("HumanoidRootPart") and ch.Humanoid.Health > 0 then
        HG.Enabled = true
        local pl = Players:GetPlayerFromCharacter(ch)
        if pl then NL.Text = pl.DisplayName; pcall(function() AI.Image = Players:GetUserThumbnailAsync(pl.UserId,Enum.ThumbnailType.HeadShot,Enum.ThumbnailSize.Size150x150) end)
        else NL.Text = ch.Name; AI.Image = "" end
        local mr = cachedChar and cachedChar:FindFirstChild("HumanoidRootPart")
        if mr then DL.Text = "Distance: "..string_format("%.1f",(mr.Position-ch.HumanoidRootPart.Position).Magnitude).."m" end
        TweenService:Create(HBF2,TweenInfo.new(0.15),{Size=UDim2.new(mathClamp(ch.Humanoid.Health/ch.Humanoid.MaxHealth,0,1),0,1,0)}):Play()
    else HG.Enabled = false end
end

local function OnDied(v) if KillNotify then pcall(function() Settings:Notify(v.DisplayName.." ("..v.Name..") died!",3) end) end end
local function hookDeath(p)
    if p == LocalPlayer then return end
    local function hc(c) local h = c:WaitForChild("Humanoid",10); if h then h.Died:Connect(function() OnDied(p) end) end end
    if p.Character then task_spawn(hc,p.Character) end; p.CharacterAdded:Connect(hc)
end
for _,p in pairs(Players:GetPlayers()) do hookDeath(p) end
Players.PlayerAdded:Connect(hookDeath)

local function onCharAdd(ch)
    local h = ch:WaitForChild("Humanoid",10)
    if h then h.StateChanged:Connect(onJump); if cachedChar == ch then cachedHumanoid = h end end
    ch:WaitForChild("HumanoidRootPart",10); task_wait(0.5)
    if ForceFieldSettings.Enabled then UpdateFF() end
    setupHSChar(ch)
    if jumpShootEnabled then task_spawn(function() task_wait(1); scanAndPatchModules(jumpShootPatched) end) end
    if SimpleJumpShootEnabled then task_spawn(function() task_wait(1); scanAndPatchModules(simpleJumpShootPatched) end) end
end
LocalPlayer.CharacterAdded:Connect(onCharAdd)
if LocalPlayer.Character then task_spawn(function()
    local h = LocalPlayer.Character:FindFirstChild("Humanoid"); if h then h.StateChanged:Connect(onJump) end
    setupHSChar(LocalPlayer.Character)
end) end

local fovGui = Instance.new("ScreenGui"); fovGui.Name = "FOVGui"; fovGui.Parent = game.CoreGui; fovGui.IgnoreGuiInset = false; fovGui.DisplayOrder = 100; fovGui.ResetOnSpawn = false
local fovFrame = Instance.new("Frame"); fovFrame.BackgroundTransparency = 1; fovFrame.AnchorPoint = Vector2.new(0.5,0.5); fovFrame.Position = UDim2.new(0.5,0,0.5,0); fovFrame.Visible = false; fovFrame.Parent = fovGui
Instance.new("UICorner",fovFrame).CornerRadius = UDim.new(1,0)
local fovStroke = Instance.new("UIStroke"); fovStroke.Thickness = 1.5; fovStroke.Color = Color3.new(1,1,1); fovStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border; fovStroke.Parent = fovFrame

local snapline = nil
if DrawingOK then snapline = Drawing.new("Line"); snapline.Visible = false; snapline.Thickness = 2; snapline.Color = Color3.new(1,1,1); snapline.ZIndex = 2; snapline.Transparency = 1 end

local cachedFovD = 300
local lastAim = 0
local ffTick = 0

local physConn = RunService.Heartbeat:Connect(function()
    if LibraryUnloaded then return end
    local ch = cachedChar; if not ch then return end
    local hrp = ch:FindFirstChild("HumanoidRootPart")
    local hum = cachedHumanoid
    if not hrp or not hum or hum.Health <= 0 then return end

    if SpeedSettings.Enabled then
        local md = hum.MoveDirection
        if md.Magnitude > 0 then hrp.AssemblyLinearVelocity = Vector3New(md.X*SpeedSettings.Value, hrp.AssemblyLinearVelocity.Y, md.Z*SpeedSettings.Value) end
    end

    if WaterSpeed.Enabled then
        local bn = "WSV"
        if hum:GetState() == Enum.HumanoidStateType.Swimming then
            local bv = hrp:FindFirstChild(bn); if not bv then bv = Instance.new("BodyVelocity",hrp); bv.Name = bn; bv.MaxForce = Vector3New(1e5,1e5,1e5) end
            bv.Velocity = hum.MoveDirection * WaterSpeed.Value
        else local bv = hrp:FindFirstChild(bn); if bv then bv:Destroy() end end
    end

    if SpiderSettings.Enabled then
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then
            spRay.FilterDescendantsInstances = {ch}
            local result = Workspace:Raycast(hrp.Position, hrp.CFrame.LookVector * 2.5, spRay)
            if result and mathAbs(result.Normal.Y) < 0.5 then
                hrp.AssemblyLinearVelocity = Vector3New(hrp.AssemblyLinearVelocity.X, SpiderSettings.Speed, hrp.AssemblyLinearVelocity.Z)
            end
        end
    end
end)

local visConn = RunService.RenderStepped:Connect(function()
    if LibraryUnloaded then fovFrame.Visible = false; if snapline then snapline.Visible = false end; return end
    local cam = Workspace.CurrentCamera; if not cam then return end; v6 = cam
    local now = tick()

    if StretchSettings.Enabled then cam.CFrame = cam.CFrame * CFrameNew(0,0,0, 1,0,0, 0,StretchSettings.Value,0, 0,0,1) end
    if FOVSettings.Enabled then cam.FieldOfView = FOVSettings.Value end
    if ThirdPersonSettings.Enabled then
        local hrp = cachedChar and cachedChar:FindFirstChild("HumanoidRootPart")
        if hrp then cam.CFrame = CFrameNew(hrp.Position-(cam.CFrame.LookVector*ThirdPersonSettings.Distance), hrp.Position) end
    end

    local nd = v13.FOVRadius * 2
    if nd ~= cachedFovD then cachedFovD = nd; fovFrame.Size = UDim2.new(0,nd,0,nd) end
    fovFrame.Visible = v13.Enabled and v13.UseFOV

    if now - lastAim >= 0.033 then lastAim = now; CurrentAimTarget = v13.Enabled and getClosestPlayer() or nil end
    if v13.Enabled and v13.UseFOV then fovStroke.Color = CurrentAimTarget and v13.FOVColorOnTarget or v13.FOVColorNoTarget end
    if AutoFireSettings.Enabled and v13.Enabled and CurrentAimTarget then
        if now - AutoFireSettings.LastFire >= AutoFireSettings.Delay then AutoFireSettings.LastFire = now; doAutoFire() end
    end

    if snapline then
        if v13.Enabled and v13.Snapline and CurrentAimTarget then
            local p,vis = cam:WorldToViewportPoint(CurrentAimTarget.Position)
            if vis then snapline.Visible = true; snapline.From = getMousePosition(); snapline.To = Vector2New(p.X,p.Y); snapline.Color = v13.SnaplineColor; snapline.Thickness = v13.SnaplineThickness
            else snapline.Visible = false end
        else snapline.Visible = false end
    end

    UpdTH(now)
    updateESP()
    if ForceFieldSettings.Enabled and now - ffTick >= 3 then ffTick = now; UpdateFF() end
end)

if hookmetamethod and getnamecallmethod then
    local v113
    v113 = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
        local method = getnamecallmethod()
        if method == "Raycast" and self == v11 then
            if checkcaller() then return v113(self, ...) end
            local args = {...}
            local origin = args[1]
            local direction = args[2]
            local rayParams = args[3]
            if typeof(origin) == "Vector3" and typeof(direction) == "Vector3" then
                local mag = direction.Magnitude
                if mag > 50 then
                    local target = CurrentAimTarget
                    if v13.Enabled and target and target.Parent then
                        local newDir = (target.Position - origin).Unit * mag
                        local result = v113(self, origin, newDir, rayParams)
                        if TracerSettings.Enabled then task_spawn(createTrace, origin, target.Position) end
                        return result
                    else
                        local result = v113(self, origin, direction, rayParams)
                        if TracerSettings.Enabled then
                            local endPoint = result and result.Position or (origin + direction)
                            task_spawn(createTrace, origin, endPoint)
                        end
                        return result
                    end
                end
            end
        end
        return v113(self, ...)
    end))
end

Settings:OnUnload(function()
    LibraryUnloaded = true
    pcall(function() fovGui:Destroy() end)
    if snapline then pcall(function() snapline:Remove() end) end
    pcall(function() HG:Destroy() end)
    if physConn then pcall(function() physConn:Disconnect() end) end
    if visConn then pcall(function() visConn:Disconnect() end) end
    if NoJumpDelaySettings.Conn then pcall(function() NoJumpDelaySettings.Conn:Disconnect() end) end
    if hsConn then pcall(function() hsConn:Disconnect() end) end
    if spikesConn then pcall(function() spikesConn:Disconnect() end) end
    pcall(function() unpatchAll(jumpShootPatched); jumpShootPatched = {} end)
    pcall(function() unpatchAll(simpleJumpShootPatched); simpleJumpShootPatched = {} end)
    jumpShootEnabled = false; SimpleJumpShootEnabled = false
    pcall(removeAllToolHighlights)
    for _, conn in pairs(toolHighlightConns) do pcall(function() conn:Disconnect() end) end; toolHighlightConns = {}
    pcall(function() local ch = LocalPlayer.Character; if ch then local hrp = ch:FindFirstChild("HumanoidRootPart"); if hrp then local bv = hrp:FindFirstChild("WSV"); if bv then bv:Destroy() end end end end)
    pcall(function() if ForceFieldSettings.Enabled and LocalPlayer.Character then for _,p in pairs(LocalPlayer.Character:GetDescendants()) do if p:IsA("BasePart") and p.Material == Enum.Material.ForceField then p.Material = Enum.Material.Plastic; p.Color = Color3.fromRGB(255,255,255) end end end end)
    pcall(function() if FB.Conn then FB.Conn:Disconnect() end; Lighting.Brightness = OL.Brightness; Lighting.ClockTime = OL.ClockTime; Lighting.FogEnd = OL.FogEnd; Lighting.GlobalShadows = OL.GlobalShadows; Lighting.Ambient = OL.Ambient end)
    pcall(function() local s = Lighting:FindFirstChildOfClass("Sky"); if s then s:Destroy() end end)
    pcall(function() if skyFx then skyFx:Destroy() end end)
    pcall(function() if NoDecorationEnabled then local t = Workspace:FindFirstChildOfClass("Terrain"); if t and sethiddenproperty then sethiddenproperty(t,"Decoration",true) end end end)
    pcall(restoreHS)
    pcall(function() setXrayState(false,0) end)
    for plr in pairs(espCache) do rmEsp(plr) end
    for i = 1, trSize do pcall(function() trPool[i]:Destroy() end) end; trPool = {}; trSize = 0
end)
