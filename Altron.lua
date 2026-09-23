do
    if getgenv().__VOMAGLA_UNLOAD then pcall(getgenv().__VOMAGLA_UNLOAD) end
    task.wait(0.2)
end
    local cg = game:GetService("CoreGui")
    for _, n in ipairs({ "VOMAGLA_FOV", "VOMAGLA_HitLogs", "VOMAGLA_ESP", "STHUD", "VOMAGLA_RL" }) do
        local g = cg:FindFirstChild(n)
        if g then pcall(function() g:Destroy() end) end
    end

do
    if not newcclosure then getgenv().newcclosure = function(f) return f end end
    if not checkcaller then getgenv().checkcaller = function() return false end end
    if not hookmetamethod then getgenv().hookmetamethod = function() end end
    if not getnamecallmethod then getgenv().getnamecallmethod = function() return "" end end
end

local Svc = {
    Players = game:GetService("Players"),
    RunService = game:GetService("RunService"),
    UIS = game:GetService("UserInputService"),
    RS = game:GetService("ReplicatedStorage"),
    WS = game:GetService("Workspace"),
    TS = game:GetService("TweenService"),
    Light = game:GetService("Lighting"),
    CoreGui = game:GetService("CoreGui"),
    SS = game:GetService("SoundService"),
    Debris = game:GetService("Debris"),
    InsertService = game:GetService("InsertService"),
}
local LP = Svc.Players.LocalPlayer
local v6 = Svc.WS.CurrentCamera
local v11 = Svc.WS

local DrawingOK = pcall(function() local t = Drawing.new("Line"); t:Remove() end)

local S = {
    Unloaded = false,
    KillNotify = false,
    NoDecoration = false,
    Manipulation = false,

    SA = { Enabled = false, TargetPart = "HeadHitbox", FOVRadius = 200, MaxDistance = 500,
           UseFOV = true, VisibleCheck = true, HitChance = 100, ShowFOV = true },
    SAColor = { NoTarget = Color3.fromRGB(255,255,255), Target = Color3.fromRGB(255,0,0) },

    Tracers = { Enabled = false, Color = Color3.fromRGB(255,255,255), TextureID = "rbxassetid://12781852245",
                Width = 1.5, Transparency = 0, LifeTime = 0.5 },

    ESP = { Enabled = false, Box = false, Name = false, Distance = false, HealthBar = false,
            Chams = false, TargetHUD = false, Weapon = false },
    ESPColors = { Box1 = Color3.fromRGB(255,255,255), Name = Color3.fromRGB(255,255,255), Distance = Color3.fromRGB(255,255,255) },

    IOS = { Enabled = false, Box = false, Name = false, Distance = false,
            HealthBar = false, Chams = false, Weapon = false, MaxDistance = 1500,
            BoxWidth = 34, BoxHeight = 52, UpdateRate = 0.05 },
    IOSColors = { Box = Color3.fromRGB(255,255,255), Name = Color3.fromRGB(255,255,255),
                  Distance = Color3.fromRGB(255,255,255), Visible = Color3.fromRGB(0,255,120),
                  Hidden = Color3.fromRGB(255,70,70) },

    Inspector = { Enabled = false, UpdateRate = 0.25 },

    Hitbox = { Enabled = false, Size = 5, Color = Color3.fromRGB(255,0,0), Transparency = 0.2 },

    Guns = { RapidFire = false, RapidSpeed = 0.02, FullAuto = false,
             MeleeMods = false, MeleeSpeed = 0.05, MeleeRange = 5 },

    ResourceCrit = { Ore = false, Tree = false, Range = 20, RefreshRate = 0.15 },

    Reload = { Enabled = false },

    AutoFire = { Enabled = false, Delay = 0.05, LastFire = 0 },
    Speed = { Enabled = false, Value = 30 },
    CopterSpeed = { Enabled = false, Value = 50 },
    WaterSpeed = { Enabled = false, Value = 50 },
    NoJumpDelay = { Enabled = false, Conn = nil, LastJump = 0 },
    FOVCam = { Enabled = false, Value = 70 },
    ThirdPerson = { Enabled = false, Distance = 10 },
    Stretch = { Enabled = false, Value = 0.65 },
    Spider = { Enabled = false, Speed = 50 },
    JumpStun = { Enabled = false, Height = 100 },
    JumpCircle = { Enabled = false, Color = Color3.fromRGB(0,170,255) },
    CopterFly = { Enabled = false, Speed = 100, bodyVel = nil, bodyGyro = nil },
    Spinner = { Enabled = false, Speed = 180 },
    Skin = { Selected = "Floppa", CustomID = "" },
    XRay = { Enabled = false, Transparency = 0.5 },
    SkyColor = { Enabled = false, Color = Color3.fromRGB(135,200,255) },
    Water = { Enabled = false, Color = Color3.fromRGB(128,128,128), Reflectance = 0.3, OrigColor = nil, OrigRef = nil },
    ToolHL = { Enabled = false, Color = Color3.new(1,1,1) },
    HitSound = { Enabled = false, Choice = "None", Volume = 1, Originals = {} },
    KillSound = { Enabled = false, Volume = 1 },

    DamageFX = { Enabled = false, Style = "Foam", Color = Color3.fromRGB(255,60,60),
                 Count = 12, Speed = 20, Size = 0.25, Lifetime = 0.8, Rainbow = false },
    HL = { Enabled = false, Color = Color3.fromRGB(176,176,209), Position = "Center", Duration = 5 },
    HM = { Enabled = false, Color = Color3.new(1,1,1), KillColor = Color3.fromRGB(220,80,80),
           Size = 12, Thickness = 2, Duration = 2.5 },
    CH = { Enabled = false, Color = Color3.new(1,1,1), Rainbow = false, Length = 8, Gap = 4,
           Thickness = 1.5, Dot = false, RotationSpeed = 0, Pulse = false, PulseSpeed = 3,
           FollowTarget = false, FollowSmooth = 8, FollowAimPoint = false },
}

local F = {
    char = nil, hum = nil,
    targetPart = nil, targetPos = nil,
    aimScreenPos = nil,
    lastTargetPlayer = nil, lastTargetTime = 0,
    conns = {},
    Notify = function() end,
}

local mathFloor, mathClamp, mathAbs, mathRad, mathExp = math.floor, math.clamp, math.abs, math.rad, math.exp
local mathCos, mathSin = math.cos, math.sin
local Vector2New, Vector3New, CFrameNew = Vector2.new, Vector3.new, CFrame.new
local tick, typeof, pairs, ipairs, pcall, next = tick, typeof, pairs, ipairs, pcall, next
local unpack = table.unpack or unpack
local string_format, string_find = string.format, string.find
local task_spawn, task_delay, task_wait, task_defer = task.spawn, task.delay, task.wait, task.defer
local osClock = os.clock

function F.trackConn(c) F.conns[#F.conns + 1] = c; return c end

do
    F.char = LP.Character
    F.hum = F.char and F.char:FindFirstChildWhichIsA("Humanoid")
    local function upd(c)
        F.char = c
        F.hum = nil
        if c then
            local h = c:FindFirstChildWhichIsA("Humanoid")
            if h then F.hum = h
            else task_spawn(function()
                local h2 = c:WaitForChild("Humanoid", 15)
                if h2 and F.char == c then F.hum = h2 end
            end) end
        end
    end
    F.trackConn(LP.CharacterAdded:Connect(upd))
    F.trackConn(LP.CharacterRemoving:Connect(function() F.char = nil; F.hum = nil end))
    if F.char then upd(F.char) end

    F.playerCache = {}
    for _, p in ipairs(Svc.Players:GetPlayers()) do
        if p ~= LP then F.playerCache[p] = true end
    end
    F.trackConn(Svc.Players.PlayerAdded:Connect(function(p) if p ~= LP then F.playerCache[p] = true end end))
    F.trackConn(Svc.Players.PlayerRemoving:Connect(function(p) F.playerCache[p] = nil end))
end

do
    local gui = Instance.new("ScreenGui")
    gui.Name = "VOMAGLA_FOV"
    gui.ResetOnSpawn = false
    gui.IgnoreGuiInset = true
    gui.DisplayOrder = 999
    pcall(function() gui.Parent = Svc.CoreGui end)
    if not gui.Parent then gui.Parent = LP:WaitForChild("PlayerGui") end

    local fill = Instance.new("Frame")
    fill.AnchorPoint = Vector2.new(0.5, 0.5)
    fill.Position = UDim2.new(0.5, 0, 0.5, 0)
    fill.BackgroundColor3 = S.SAColor.NoTarget
    fill.BackgroundTransparency = 0.93
    fill.BorderSizePixel = 0
    fill.Visible = false
    fill.Parent = gui
    Instance.new("UICorner", fill).CornerRadius = UDim.new(0.5, 0)

    local stroke = Instance.new("UIStroke")
    stroke.Color = S.SAColor.NoTarget
    stroke.Thickness = 1.5
    stroke.Transparency = 0.25
    stroke.Parent = fill

    F.fovGui = gui
    F.fovFill = fill
    F.fovStroke = stroke
end

do
    local ignoreCache = {}
    local lastIgnore = 0

    local function getFovOrigin()
        local cam = Svc.WS.CurrentCamera
        if not cam then return Vector2New(0, 0) end
        local vp = cam.ViewportSize
        return Vector2New(vp.X * 0.5, vp.Y * 0.5)
    end

    local rayParams = RaycastParams.new()
    rayParams.FilterType = Enum.RaycastFilterType.Exclude
    rayParams.IgnoreWater = true

    local function getIgnoreList()
        local now = tick()
        if now - lastIgnore < 0.5 then return ignoreCache end
        lastIgnore = now
        ignoreCache = { LP.Character, Svc.WS.CurrentCamera }
        for plr in next, F.playerCache do
            if plr.Character then ignoreCache[#ignoreCache + 1] = plr.Character end
        end
        return ignoreCache
    end

    function F.pointVisible(character, worldPoint)
        local cam = Svc.WS.CurrentCamera
        if not cam then return false end
        local origin = cam.CFrame.Position
        local ignored = {}
        for _, inst in ipairs(getIgnoreList()) do
            if inst then ignored[#ignored + 1] = inst end
        end

        -- Continue through transparent/non-collidable decoration instead of treating it as open sky.
        for _ = 1, 8 do
            local delta = worldPoint - origin
            if delta.Magnitude <= 0.05 then return true end
            rayParams.FilterDescendantsInstances = ignored
            local result = Svc.WS:Raycast(origin, delta, rayParams)
            if not result then return true end
            local hit = result.Instance
            if hit and hit:IsDescendantOf(character) then return true end
            local hitName = hit and string.lower(hit.Name) or ""
            local decoration = hit and hit:IsA("BasePart") and not hit.CanCollide
                and (string_find(hitName, "leaf") or string_find(hitName, "grass")
                    or string_find(hitName, "bush") or string_find(hitName, "foliage"))
            if hit and hit:IsA("BasePart") and (hit.Transparency >= 0.82 or decoration) then
                ignored[#ignored + 1] = hit
                origin = result.Position + delta.Unit * 0.03
            else
                return false
            end
        end
        return false
    end

    local TEST_OFFSETS = (function()
        local t = { Vector3.new(0, 0, 0) }
        for x = -1, 1, 2 do
            for y = -1, 1, 2 do
                for z = -1, 1, 2 do t[#t + 1] = Vector3.new(x * 0.5, y * 0.5, z * 0.5) end
            end
        end
        t[#t+1] = Vector3.new(0.5, 0, 0)
        t[#t+1] = Vector3.new(-0.5, 0, 0)
        t[#t+1] = Vector3.new(0, 0.5, 0)
        t[#t+1] = Vector3.new(0, -0.5, 0)
        t[#t+1] = Vector3.new(0, 0, 0.5)
        t[#t+1] = Vector3.new(0, 0, -0.5)
        return t
    end)()

    local function getVisiblePointOfHitbox(hitbox, character)
        if not hitbox or not hitbox:IsA("BasePart") then return nil end
        local cf, size = hitbox.CFrame, hitbox.Size
        local sx, sy, sz, n = 0, 0, 0, 0
        for i = 1, #TEST_OFFSETS do
            local wp = cf:PointToWorldSpace(TEST_OFFSETS[i] * size)
            if F.pointVisible(character, wp) then
                sx = sx + wp.X
                sy = sy + wp.Y
                sz = sz + wp.Z
                n = n + 1
            end
        end
        if n == 0 then return nil end
        return Vector3.new(sx / n, sy / n, sz / n)
    end

    function F.getClosestPlayerPW()
        local closestPart, closestPos, bestScore = nil, nil, math.huge
        local fovOrigin = getFovOrigin()
        local camPos = v6.CFrame.Position
        local myRoot = F.char and F.char:FindFirstChild("HumanoidRootPart")
        local myPos = myRoot and myRoot.Position or camPos

        for _, player in ipairs(Svc.Players:GetPlayers()) do
            if player ~= LP then
                local char = player.Character
                if char then
                    local hum = char:FindFirstChild("Humanoid")
                    if hum and hum.Health > 0 then
                        local part = char:FindFirstChild(S.SA.TargetPart) or char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Head")
                        if part then
                            local worldDist = (part.Position - myPos).Magnitude
                            if worldDist <= S.SA.MaxDistance then
                                local targetPos = part.Position
                                if S.SA.VisibleCheck then
                                    local vp = getVisiblePointOfHitbox(part, char)
                                    if not vp then continue end
                                    targetPos = vp
                                end
                                local cam = Svc.WS.CurrentCamera
                                local sp, onScreen = cam:WorldToViewportPoint(targetPos)
                                if onScreen then
                                    local fovDist = (fovOrigin - Vector2New(sp.X, sp.Y)).Magnitude
                                    if not S.SA.UseFOV or fovDist <= S.SA.FOVRadius then
                                        local score = worldDist + fovDist * 0.5
                                        if score < bestScore then
                                            bestScore = score
                                            closestPart = part
                                            closestPos = targetPos
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
        return closestPart, closestPos
    end
end

do
    local shots = {}

    function F.recordShot(origin, dirUnit)
        shots[#shots + 1] = { time = osClock(), origin = origin, dir = dirUnit }
        if #shots > 25 then table.remove(shots, 1) end
    end

    function F.isOnOurShot(rootPos)
        local now = osClock()
        for i = #shots, 1, -1 do
            local shot = shots[i]
            if now - shot.time > 1.5 then
                table.remove(shots, i)
            else
                local toTarget = rootPos - shot.origin
                local along = toTarget:Dot(shot.dir)
                if along > 0 then
                    local perp = (toTarget - shot.dir * along).Magnitude
                    if perp <= 6 then return true end
                end
            end
        end
        return false
    end
end

do
    local pool, poolSize = {}, 0
    local active = {}

    local function getTr()
        if poolSize > 0 then
            local p = pool[poolSize]
            pool[poolSize] = nil
            poolSize = poolSize - 1
            return p
        end
        local p = Instance.new("Part")
        p.Anchored = true
        p.CanCollide = false
        p.Transparency = 1
        p.Size = Vector3New(0.1, 0.1, 0.1)
        local a0 = Instance.new("Attachment", p)
        a0.Name = "A0"
        local a1 = Instance.new("Attachment", p)
        a1.Name = "A1"
        local b = Instance.new("Beam")
        b.Name = "B"
        b.Attachment0 = a0
        b.Attachment1 = a1
        b.FaceCamera = true
        b.LightEmission = 1
        b.LightInfluence = 0
        b.TextureLength = 2
        b.TextureSpeed = 2
        b.Parent = p
        return p
    end

    local function release(p, b)
        if b then b.Enabled = false end
        if p then
            p.Parent = nil
            poolSize = poolSize + 1
            pool[poolSize] = p
        end
    end

    F.createTrace = function(startPos, endPos)
        if S.Unloaded then return end
        local cam = Svc.WS.CurrentCamera
        if cam then
            local d = (startPos - cam.CFrame.Position).Magnitude
            if d < 4 then
                startPos = (cam.CFrame * CFrame.new(2.5, -1.5, -1)).Position
            end
        end
        local p = getTr()
        p.Parent = Svc.WS
        local a0 = p:FindFirstChild("A0")
        local a1 = p:FindFirstChild("A1")
        if a0 then a0.WorldPosition = startPos end
        if a1 then a1.WorldPosition = endPos end
        local b = p:FindFirstChild("B")
        if not b then release(p) return end
        b.Color = ColorSequence.new(S.Tracers.Color)
        b.Transparency = NumberSequence.new(S.Tracers.Transparency)
        b.Texture = S.Tracers.TextureID
        b.Width0 = S.Tracers.Width
        b.Width1 = S.Tracers.Width
        b.Enabled = true
        active[#active + 1] = { p = p, b = b, start = tick() }
    end

    F.updateTracers = function()
        if #active == 0 then return end
        local lt = S.Tracers.LifeTime
        for i = #active, 1, -1 do
            local t = active[i]
            local p, b = t.p, t.b
            if not p or not p.Parent then
                table.remove(active, i)
            else
                local alpha = 1 - ((tick() - t.start) / lt)
                if alpha <= 0 then
                    release(p, b)
                    table.remove(active, i)
                elseif b then
                    b.Transparency = NumberSequence.new(alpha * S.Tracers.Transparency)
                end
            end
        end
    end

    F.destroyAllTracers = function()
        for i = #active, 1, -1 do
            local t = active[i]
            if t and t.p then pcall(function() t.p:Destroy() end) end
            active[i] = nil
        end
        for i = 1, poolSize do pcall(function() pool[i]:Destroy() end) end
        pool = {}
        poolSize = 0
    end
end

do
    if hookmetamethod and getnamecallmethod and newcclosure then
        local old
        old = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
            local method = getnamecallmethod()

            if method == "FireServer" and S.SA.Enabled and F.targetPos then
                if math.random(1, 100) <= S.SA.HitChance then
                    local args = table.pack(...)
                    for i = 1, args.n do
                        local a = args[i]
                        if typeof(a) == "Vector3" then
                            args[i] = F.targetPos
                        elseif typeof(a) == "CFrame" then
                            args[i] = CFrame.new(F.targetPos)
                        end
                    end
                    return old(self, unpack(args, 1, args.n))
                end
            elseif method == "Raycast" and self == v11 then
                if checkcaller() then return old(self, ...) end
                local origin, direction, rayParams = ...
                if typeof(origin) ~= "Vector3" or typeof(direction) ~= "Vector3" then
                    return old(self, ...)
                end
                local mag = direction.Magnitude
                if mag <= 50 then return old(self, ...) end

                local camPos = v6.CFrame.Position
                if (origin - camPos).Magnitude <= 5 then
                    F.recordShot(origin, direction.Unit)
                end

                local newOrigin, newDir = origin, direction
                if S.SA.Enabled and F.targetPos then
                    if S.Manipulation then newOrigin = v6.CFrame.Position end
                    newDir = (F.targetPos - newOrigin).Unit * mag
                elseif S.Manipulation then
                    newOrigin = v6.CFrame.Position
                end

                local result = old(self, newOrigin, newDir, rayParams)
                if S.Tracers.Enabled and result then
                    task_spawn(F.createTrace, newOrigin, result.Position)
                end
                return result
            end

            return old(self, ...)
        end))
    end
end

do
    local ok, GunBase = pcall(function()
        return require(Svc.RS:WaitForChild("Gun"):WaitForChild("Scripts"):WaitForChild("GunBase"))
    end)
    if ok and type(GunBase) == "table" and GunBase.fire then
        local origFire = GunBase.fire
        GunBase.fire = function(self, ...)
            if S.SA.Enabled and F.targetPos then
                local args = table.pack(...)
                local patched = false
                local pos = F.targetPos
                for i = 1, args.n do
                    local v = args[i]
                    if typeof(v) == "Vector3" and not patched then
                        args[i] = pos
                        patched = true
                    elseif typeof(v) == "buffer" and not patched then
                        pcall(function()
                            buffer.writef32(v, 4, pos.X)
                            buffer.writef32(v, 8, pos.Y)
                            buffer.writef32(v, 12, pos.Z)
                        end)
                        patched = true
                    end
                end
                if patched then return origFire(self, unpack(args, 1, args.n)) end
            end
            return origFire(self, ...)
        end
    end
end

do
    local gui = Instance.new("ScreenGui")
    gui.Name = "VOMAGLA_RL"
    gui.ResetOnSpawn = false
    gui.IgnoreGuiInset = true
    gui.DisplayOrder = 998
    pcall(function() gui.Parent = Svc.CoreGui end)
    if not gui.Parent then gui.Parent = LP:WaitForChild("PlayerGui") end

    local holder = Instance.new("Frame")
    holder.AnchorPoint = Vector2.new(0.5, 1)
    holder.Position = UDim2.new(0.5, 0, 1, -80)
    holder.Size = UDim2.new(0, 160, 0, 16)
    holder.BackgroundTransparency = 1
    holder.Visible = false
    holder.Parent = gui

    local bg = Instance.new("Frame")
    bg.Size = UDim2.new(1, 0, 0, 6)
    bg.Position = UDim2.new(0, 0, 0.5, -3)
    bg.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    bg.BorderSizePixel = 0
    bg.Parent = holder
    Instance.new("UICorner", bg).CornerRadius = UDim.new(1, 0)

    local fill = Instance.new("Frame")
    fill.Size = UDim2.new(0, 0, 1, 0)
    fill.BackgroundColor3 = Color3.fromRGB(255, 200, 50)
    fill.BorderSizePixel = 0
    fill.Parent = bg
    Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)

    local rlStart, rlDur, active = 0, 0, false

    local ok, GunBase = pcall(function()
        return require(Svc.RS:WaitForChild("Gun"):WaitForChild("Scripts"):WaitForChild("GunBase"))
    end)
    if ok and type(GunBase) == "table" then
        for _, name in ipairs({ "reload", "Reload", "startReload", "beginReload" }) do
            local orig = GunBase[name]
            if type(orig) == "function" then
                GunBase[name] = function(self, ...)
                    local d = rawget(self, "ReloadTime") or rawget(self, "ReloadDuration")
                        or rawget(self, "reload_time") or rawget(self, "reloadTime") or 2
                    rlStart = osClock()
                    rlDur = tonumber(d) or 2
                    active = true
                    return orig(self, ...)
                end
                break
            end
        end
    end

    F.updateReloadBar = function()
        if S.Unloaded or not S.Reload.Enabled or not active then
            holder.Visible = false
            return
        end
        local progress = (osClock() - rlStart) / math.max(rlDur, 0.01)
        if progress >= 1 then
            active = false
            holder.Visible = false
            return
        end
        holder.Visible = true
        fill.Size = UDim2.new(progress, 0, 1, 0)
        fill.BackgroundColor3 = Color3.fromRGB(
            mathFloor(255 * (1 - progress) + 0.5),
            mathFloor(180 + 75 * progress + 0.5), 50)
    end

    F.cleanupReload = function()
        pcall(function() gui:Destroy() end)
    end
end

do
    local gunCache, meleeCache = {}, {}
    local built, scanning = false, false

    local function buildCaches()
        if scanning then return end
        scanning = true
        task_spawn(function()
            gunCache = {}
            meleeCache = {}
            local ok, objs = pcall(function() return getgc(true) end)
            if ok and type(objs) == "table" then
                for _, v in pairs(objs) do
                    if type(v) == "table" then
                        if rawget(v, "FireDelay") ~= nil and rawget(v, "FiringOnCooldown") ~= nil and rawget(v, "OwnerPlayer") ~= nil then
                            gunCache[#gunCache + 1] = v
                        end
                        if rawget(v, "UseDelay") ~= nil and rawget(v, "Range") ~= nil and rawget(v, "UsingOnCooldown") ~= nil and rawget(v, "Destroyed") ~= true then
                            meleeCache[#meleeCache + 1] = v
                        end
                    end
                end
            end
            built = true
            scanning = false
        end)
    end

    F.applyGunMods = function()
        if not built then return end
        if S.Guns.RapidFire or S.Guns.FullAuto then
            local spd = S.Guns.RapidSpeed or 0.02
            for _, v in ipairs(gunCache) do
                pcall(function()
                    if S.Guns.RapidFire then
                        rawset(v, "FireDelay", spd)
                        if rawget(v, "FireRate") ~= nil then rawset(v, "FireRate", math.floor(1 / spd)) end
                        rawset(v, "FiringOnCooldown", false)
                    end
                    if S.Guns.FullAuto then
                        if rawget(v, "FiringType") ~= nil then rawset(v, "FiringType", 2) end
                        if rawget(v, "FireMode") ~= nil then rawset(v, "FireMode", "Auto") end
                        if rawget(v, "Auto") ~= nil then rawset(v, "Auto", true) end
                    end
                end)
            end
        end
        if S.Guns.MeleeMods then
            local spd = S.Guns.MeleeSpeed or 0.05
            local rng = S.Guns.MeleeRange or 5
            for _, v in ipairs(meleeCache) do
                pcall(function()
                    if rawget(v, "Destroyed") == true then return end
                    rawset(v, "UseDelay", spd)
                    rawset(v, "UseTime", spd)
                    rawset(v, "Range", rng)
                    rawset(v, "CharacterRange", rng)
                    rawset(v, "UsingOnCooldown", false)
                end)
            end
        end
    end

    if F.char then buildCaches() end
    F.trackConn(LP.CharacterAdded:Connect(function(char)
        built = false
        buildCaches()
        char.ChildAdded:Connect(function(child)
            if child:IsA("Tool") then
                task_wait(0.1)
                buildCaches()
            end
        end)
    end))
end

do
    -- Redirect melee/tool hits to the nearest resource critical point.
    local hooked = setmetatable({}, { __mode = "k" })
    local critCache = { ore = {}, tree = {}, refreshed = 0 }
    local scanning = false

    local function isCriticalPart(obj, wanted)
        if not obj or not obj:IsA("BasePart") then return false end
        local name = string.lower(obj.Name)
        return (wanted == "ore" and name == "star") or (wanted == "tree" and name == "cross")
    end

    local function refreshCriticalCache(force)
        local now = osClock()
        if not force and now - critCache.refreshed < S.ResourceCrit.RefreshRate then return end
        critCache.refreshed = now
        table.clear(critCache.ore)
        table.clear(critCache.tree)
        for _, obj in ipairs(Svc.WS:GetDescendants()) do
            if obj:IsA("BasePart") then
                local name = string.lower(obj.Name)
                if name == "star" then
                    critCache.ore[#critCache.ore + 1] = obj
                elseif name == "cross" then
                    critCache.tree[#critCache.tree + 1] = obj
                end
            end
        end
    end

    local function wantedType()
        if S.ResourceCrit.Ore and S.ResourceCrit.Tree then return "both" end
        if S.ResourceCrit.Ore then return "ore" end
        if S.ResourceCrit.Tree then return "tree" end
        return nil
    end

    local function findInsideResource(inst, wanted, origin)
        if not inst then return nil end
        local node = inst
        for _ = 1, 5 do
            if not node or node == Svc.WS then break end
            if isCriticalPart(node, wanted) then return node end
            for _, desc in ipairs(node:GetDescendants()) do
                if isCriticalPart(desc, wanted) and (desc.Position - origin).Magnitude <= S.ResourceCrit.Range then
                    return desc
                end
            end
            node = node.Parent
        end
        return nil
    end

    local function nearestCritical(inst, origin)
        local mode = wantedType()
        if not mode then return nil end

        -- Same resource first. Prevents redirecting a tree hit to a nearby ore node or vice versa.
        if mode == "ore" or mode == "both" then
            local localOre = findInsideResource(inst, "ore", origin)
            if localOre then return localOre end
        end
        if mode == "tree" or mode == "both" then
            local localTree = findInsideResource(inst, "tree", origin)
            if localTree then return localTree end
        end

        if critCache.refreshed == 0 then refreshCriticalCache(true) end
        local best, bestDistance = nil, S.ResourceCrit.Range
        local function test(list)
            for i = #list, 1, -1 do
                local point = list[i]
                if not point or not point.Parent then
                    table.remove(list, i)
                else
                    local distance = (point.Position - origin).Magnitude
                    if distance < bestDistance then
                        best, bestDistance = point, distance
                    end
                end
            end
        end
        if mode == "ore" or mode == "both" then test(critCache.ore) end
        if mode == "tree" or mode == "both" then test(critCache.tree) end
        return best
    end

    local function hookToolState(state)
        if hooked[state] or type(state) ~= "table" then return end
        local originalHit = rawget(state, "hit")
        if type(originalHit) ~= "function" then return end
        if rawget(state, "use") == nil and rawget(state, "OwnerPlayer") == nil
            and rawget(state, "Range") == nil and rawget(state, "UseDelay") == nil then return end

        hooked[state] = originalHit
        state.hit = function(self, inst, pos, ...)
            if S.ResourceCrit.Ore or S.ResourceCrit.Tree then
                local owner = rawget(self, "OwnerPlayer") or LP
                local char = owner and owner.Character or F.char
                local root = char and char:FindFirstChild("HumanoidRootPart")
                if root then
                    local critical = nearestCritical(inst, root.Position)
                    if critical then
                        inst = critical
                        pos = critical.Position
                    end
                end
            end
            return originalHit(self, inst, pos, ...)
        end

        if rawget(state, "Range") ~= nil then
            rawset(state, "Range", math.max(tonumber(rawget(state, "Range")) or 0, S.ResourceCrit.Range))
        end
    end

    function F.scanResourceTools()
        if scanning or (not S.ResourceCrit.Ore and not S.ResourceCrit.Tree) then return end
        scanning = true
        task_spawn(function()
            local ok, objects = pcall(function() return getgc(true) end)
            if ok and type(objects) == "table" then
                for _, state in pairs(objects) do
                    if type(state) == "table" then hookToolState(state) end
                end
            end
            if critCache.refreshed == 0 then refreshCriticalCache(true) end
            scanning = false
        end)
    end

    function F.armResourceCrit()
        F.scanResourceTools()
        task_delay(0.35, function()
            if not S.Unloaded and (S.ResourceCrit.Ore or S.ResourceCrit.Tree) then F.scanResourceTools() end
        end)
        task_delay(1.0, function()
            if not S.Unloaded and (S.ResourceCrit.Ore or S.ResourceCrit.Tree) then F.scanResourceTools() end
        end)
    end

    function F.cleanupResourceCrit()
        for state, originalHit in pairs(hooked) do
            if type(state) == "table" and type(originalHit) == "function" then
                pcall(function() state.hit = originalHit end)
            end
        end
        table.clear(hooked)
        table.clear(critCache.ore)
        table.clear(critCache.tree)
    end

    F.trackConn(Svc.WS.DescendantAdded:Connect(function(obj)
        if obj:IsA("BasePart") then
            local name = string.lower(obj.Name)
            if name == "star" then critCache.ore[#critCache.ore + 1] = obj end
            if name == "cross" then critCache.tree[#critCache.tree + 1] = obj end
        end
    end))

    local watchedTools = setmetatable({}, { __mode = "k" })

    local function watchTool(tool)
        if not tool or not tool:IsA("Tool") or watchedTools[tool] then return end
        watchedTools[tool] = true
        F.trackConn(tool.Equipped:Connect(function()
            if S.ResourceCrit.Ore or S.ResourceCrit.Tree then task_delay(0.1, F.armResourceCrit) end
        end))
        F.trackConn(tool.Activated:Connect(function()
            if S.ResourceCrit.Ore or S.ResourceCrit.Tree then F.scanResourceTools() end
        end))
    end

    local function watchToolContainer(container)
        if not container then return end
        for _, child in ipairs(container:GetChildren()) do watchTool(child) end
        F.trackConn(container.ChildAdded:Connect(function(child)
            watchTool(child)
            if child:IsA("Tool") and (S.ResourceCrit.Ore or S.ResourceCrit.Tree) then
                task_delay(0.1, F.armResourceCrit)
            end
        end))
    end

    if LP:FindFirstChild("Backpack") then watchToolContainer(LP.Backpack) end
    if LP.Character then watchToolContainer(LP.Character) end
    F.trackConn(LP.CharacterAdded:Connect(function(char) watchToolContainer(char) end))
end

do
    local enlarged = {}
    local charConns = {}
    local watchConn = nil
    local watchInit = false

    local function getCharsFolder()
        return Svc.WS:FindFirstChild("Characters") or (Svc.WS:FindFirstChild("Spawned") and Svc.WS.Spawned:FindFirstChild("Characters"))
    end
    F.getCharactersFolder = getCharsFolder

    local function enlarge(obj)
        if not obj or not obj.Parent then return end
        if enlarged[obj] then return end
        enlarged[obj] = { Size = obj.Size, Color = obj.Color, Transparency = obj.Transparency, Material = obj.Material }
        obj.Size = obj.Size * S.Hitbox.Size
        obj.Color = S.Hitbox.Color
        obj.Transparency = S.Hitbox.Transparency
        obj.Material = Enum.Material.Neon
    end

    local function restore(obj)
        local orig = enlarged[obj]
        if not orig then return end
        if not obj or not obj.Parent then enlarged[obj] = nil return end
        obj.Size = orig.Size
        obj.Color = orig.Color
        obj.Transparency = orig.Transparency
        obj.Material = orig.Material
        enlarged[obj] = nil
    end

    function F.RestoreAllHitboxes()
        for obj in pairs(enlarged) do restore(obj) end
    end

    function F.UpdateAllHitboxes()
        for obj in pairs(enlarged) do
            if obj and obj.Parent then
                obj.Size = enlarged[obj].Size * S.Hitbox.Size
                obj.Color = S.Hitbox.Color
                obj.Transparency = S.Hitbox.Transparency
            end
        end
    end

    function F.ApplyHitboxVisuals()
        for obj in pairs(enlarged) do
            if obj and obj.Parent then
                obj.Transparency = S.Hitbox.Transparency
                obj.Color = S.Hitbox.Color
            end
        end
    end

    local function processChar(character)
        if not character or charConns[character] then return end
        if Svc.Players:GetPlayerFromCharacter(character) == LP then return end
        local hitbox = character:FindFirstChild("HeadHitbox")
        local humanoid = character:FindFirstChild("Humanoid")
        if not hitbox or not humanoid then return end

        charConns[character] = {}
        local function upd()
            if hitbox and hitbox.Parent then
                if humanoid.Health > 0 and S.Hitbox.Enabled then
                    enlarge(hitbox)
                else
                    restore(hitbox)
                end
            end
        end
        upd()
        local cs = charConns[character]
        cs[#cs+1] = humanoid.HealthChanged:Connect(upd)
        cs[#cs+1] = humanoid.Died:Connect(function() restore(hitbox) end)
        cs[#cs+1] = character.AncestryChanged:Connect(function()
            if not character.Parent then
                local list = charConns[character]
                if list then
                    for _, c in ipairs(list) do pcall(function() c:Disconnect() end) end
                end
                charConns[character] = nil
                restore(hitbox)
            end
        end)
    end

    function F.InitHitboxWatchers()
        local chars = getCharsFolder()
        if not chars then return end
        for _, c in pairs(chars:GetChildren()) do task_spawn(processChar, c) end
        if not watchInit then
            watchInit = true
            watchConn = chars.ChildAdded:Connect(function(c)
                task_wait(0.5)
                task_spawn(processChar, c)
            end)
        end
    end

    F.cleanupHitboxes = function()
        if watchConn then pcall(function() watchConn:Disconnect() end) watchConn = nil end
        watchInit = false
        for _, list in pairs(charConns) do
            for _, c in ipairs(list) do pcall(function() c:Disconnect() end) end
        end
        charConns = {}
    end
end

do
    local gui = Instance.new("ScreenGui")
    gui.Name = "VOMAGLA_ESP"
    gui.ResetOnSpawn = false
    gui.IgnoreGuiInset = true
    gui.DisplayOrder = 997
    pcall(function() gui.Parent = Svc.CoreGui end)
    if not gui.Parent then gui.Parent = LP:WaitForChild("PlayerGui") end

    local cache = {}

    local function mkLabel(parent, size)
        local l = Instance.new("TextLabel")
        l.BackgroundTransparency = 1
        l.BorderSizePixel = 0
        l.Font = Enum.Font.GothamBold
        l.TextSize = size
        l.TextColor3 = Color3.new(1, 1, 1)
        l.Text = ""
        l.AutomaticSize = Enum.AutomaticSize.XY
        l.Size = UDim2.fromOffset(0, 0)
        l.Parent = parent
        local st = Instance.new("UIStroke")
        st.LineJoinMode = Enum.LineJoinMode.Miter
        st.Thickness = 1
        st.Parent = l
        return l
    end

    local function mk(plr)
        local holder = Instance.new("Frame")
        holder.Visible = false
        holder.BackgroundTransparency = 1
        holder.BorderSizePixel = 0
        holder.Parent = gui

        local box = Instance.new("Frame")
        box.Name = "Box"
        box.BackgroundTransparency = 1
        box.BorderSizePixel = 0
        box.Size = UDim2.fromScale(1, 1)
        box.Parent = holder
        local stroke = Instance.new("UIStroke")
        stroke.Thickness = 1.2
        stroke.LineJoinMode = Enum.LineJoinMode.Miter
        stroke.Color = S.ESPColors.Box1
        stroke.Parent = box

        local name = mkLabel(holder, 13)
        name.AnchorPoint = Vector2.new(0.5, 1)
        name.Position = UDim2.new(0.5, 0, 0, -2)
        name.Text = plr.DisplayName

        local dist = mkLabel(holder, 12)
        dist.AnchorPoint = Vector2.new(0.5, 0)
        dist.Position = UDim2.new(0.5, 0, 1, 2)

        local wep = mkLabel(holder, 11)
        wep.AnchorPoint = Vector2.new(0.5, 0)
        wep.Position = UDim2.new(0.5, 0, 1, 18)
        wep.TextColor3 = Color3.fromRGB(255, 200, 100)

        local hpBg = Instance.new("Frame")
        hpBg.AnchorPoint = Vector2.new(1, 0)
        hpBg.Position = UDim2.new(0, -6, 0, 0)
        hpBg.Size = UDim2.new(0, 3, 1, 0)
        hpBg.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
        hpBg.BorderSizePixel = 0
        hpBg.Parent = holder

        local hp = Instance.new("Frame")
        hp.AnchorPoint = Vector2.new(0, 1)
        hp.Position = UDim2.new(0, 0, 1, 0)
        hp.Size = UDim2.new(1, 0, 1, 0)
        hp.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
        hp.BorderSizePixel = 0
        hp.Parent = hpBg

        local data = {
            Holder = holder, Box = box, Stroke = stroke,
            Name = name, Dist = dist, Wep = wep,
            HpBg = hpBg, Hp = hp,
            Chams = nil, VisibleNow = false, LastVisCheck = 0,
        }
        cache[plr] = data
        return data
    end

    local function hide(d)
        if not d then return end
        d.Holder.Visible = false
        if d.Chams then pcall(function() d.Chams:Destroy() end) d.Chams = nil end
    end

    local function rm(plr)
        local d = cache[plr]
        if not d then return end
        pcall(function()
            if d.Chams then d.Chams:Destroy() end
            d.Holder:Destroy()
        end)
        cache[plr] = nil
    end
    F.trackConn(Svc.Players.PlayerRemoving:Connect(rm))

    local function getWeapon(plr)
        local char = plr.Character
        if char then
            for _, c in pairs(char:GetChildren()) do
                if c:IsA("Tool") then return c.Name end
            end
        end
        return ""
    end

    function F.updateESP()
        if S.Unloaded then return end
        if not S.ESP.Enabled then
            for _, d in pairs(cache) do hide(d) end
            return
        end
        local cam = Svc.WS.CurrentCamera
        if not cam then return end
        local myRoot = F.char and F.char:FindFirstChild("HumanoidRootPart")
        local now = tick()

        for plr in next, F.playerCache do
            local d = cache[plr]
            local ch = plr.Character
            if not ch then if d then hide(d) end continue end
            local hrp = ch:FindFirstChild("HumanoidRootPart")
            local hum = ch:FindFirstChild("Humanoid")
            if not hrp or not hum or hum.Health <= 0 then if d then hide(d) end continue end
            local pos = hrp.Position
            local topS = cam:WorldToViewportPoint(pos + Vector3New(0, 3, 0))
            local botS = cam:WorldToViewportPoint(pos - Vector3New(0, 3, 0))
            if topS.Z < 0 and botS.Z < 0 then if d then hide(d) end continue end
            if not d then d = mk(plr) end

            local h = math.abs(botS.Y - topS.Y)
            local w = math.max(h * 0.6, 8)
            local bx = (topS.X + botS.X) * 0.5 - w * 0.5
            local by = math.min(topS.Y, botS.Y)

            d.Holder.Visible = true
            d.Holder.Position = UDim2.fromOffset(mathFloor(bx), mathFloor(by))
            d.Holder.Size = UDim2.fromOffset(mathFloor(w), mathFloor(h))

            d.Box.Visible = S.ESP.Box
            d.Stroke.Color = S.ESPColors.Box1
            d.Name.Visible = S.ESP.Name
            d.Name.TextColor3 = S.ESPColors.Name
            d.Dist.Visible = S.ESP.Distance and myRoot ~= nil
            if d.Dist.Visible then
                d.Dist.Text = mathFloor((myRoot.Position - pos).Magnitude) .. "m"
                d.Dist.TextColor3 = S.ESPColors.Distance
            end
            d.Wep.Visible = S.ESP.Weapon
            if d.Wep.Visible then
                d.Wep.Text = getWeapon(plr)
            end
            d.HpBg.Visible = S.ESP.HealthBar
            if S.ESP.HealthBar then
                local frac = mathClamp(hum.Health / hum.MaxHealth, 0, 1)
                d.Hp.Size = UDim2.new(1, 0, frac, 0)
                d.Hp.BackgroundColor3 = Color3.fromRGB(mathFloor(255 * (1 - frac)), mathFloor(255 * frac), 0)
            end

            if S.ESP.Chams then
                local isVis = d.VisibleNow
                if now - d.LastVisCheck >= 0.2 then
                    d.LastVisCheck = now
                    local hb = ch:FindFirstChild("HeadHitbox")
                    isVis = hb and F.pointVisible(ch, hb.Position) or false
                    d.VisibleNow = isVis
                end
                local col = isVis and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 0, 0)
                if not d.Chams or not d.Chams.Parent then
                    if d.Chams then pcall(function() d.Chams:Destroy() end) end
                    local hl = Instance.new("Highlight")
                    hl.FillTransparency = 0.5
                    hl.OutlineTransparency = 0.8
                    hl.FillColor = col
                    hl.Adornee = ch
                    hl.Parent = ch
                    d.Chams = hl
                else
                    d.Chams.FillColor = col
                end
            elseif d.Chams then
                pcall(function() d.Chams:Destroy() end)
                d.Chams = nil
            end
        end
    end

    F.rmAllEsp = function()
        for plr in pairs(cache) do rm(plr) end
        pcall(function() gui:Destroy() end)
    end
end

do
    -- Fixed-size screen-space ESP for iOS. Native Roblox GUI only; no Drawing/Billboard scaling.
    local cache = {}
    local playerGui = LP:WaitForChild("PlayerGui")
    local rootGui = Instance.new("ScreenGui")
    rootGui.Name = "VOMAGLA_ESP_IOS"
    rootGui.ResetOnSpawn = false
    rootGui.IgnoreGuiInset = true
    rootGui.DisplayOrder = 996
    rootGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    rootGui.Parent = playerGui


    local function textLabel(parent, height, y, size)
        local label = Instance.new("TextLabel")
        label.BackgroundTransparency = 1
        label.BorderSizePixel = 0
        label.Position = UDim2.new(0, -35, y, 0)
        label.Size = UDim2.new(1, 70, 0, height)
        label.Font = Enum.Font.GothamBold
        label.TextSize = size
        label.TextColor3 = Color3.new(1, 1, 1)
        label.TextStrokeColor3 = Color3.new(0, 0, 0)
        label.TextStrokeTransparency = 0.25
        label.Text = ""
        label.ZIndex = 4
        label.Parent = parent
        return label
    end

    local function createEntry(plr, char, hrp)
        local old = cache[plr]
        if old then
            pcall(function() old.Gui:Destroy() end)
            if old.Highlight then pcall(function() old.Highlight:Destroy() end) end
        end

        local gui = Instance.new("Frame")
        gui.Name = "VOM_IOS_" .. plr.UserId
        gui.AnchorPoint = Vector2.new(0.5, 0.5)
        gui.Size = UDim2.fromOffset(S.IOS.BoxWidth, S.IOS.BoxHeight)
        gui.BackgroundTransparency = 1
        gui.BorderSizePixel = 0
        gui.Visible = false
        gui.ZIndex = 2
        gui.Parent = rootGui

        local box = Instance.new("Frame")
        box.Name = "Box"
        box.BackgroundTransparency = 1
        box.BorderSizePixel = 0
        box.Size = UDim2.fromScale(1, 1)
        box.ZIndex = 2
        box.Parent = gui

        local stroke = Instance.new("UIStroke")
        stroke.Name = "Stroke"
        stroke.Thickness = 1.4
        stroke.LineJoinMode = Enum.LineJoinMode.Miter
        stroke.Color = S.IOSColors.Box
        stroke.Parent = box

        local name = textLabel(gui, 18, 0, 13)
        name.AnchorPoint = Vector2.new(0, 1)
        name.Text = plr.DisplayName

        local distance = textLabel(gui, 16, 1, 12)
        distance.TextColor3 = S.IOSColors.Distance

        local weapon = textLabel(gui, 16, 1, 11)
        weapon.Position = UDim2.new(0, -35, 1, 15)
        weapon.TextColor3 = Color3.fromRGB(255, 205, 95)

        local hpBg = Instance.new("Frame")
        hpBg.Name = "HealthBackground"
        hpBg.AnchorPoint = Vector2.new(1, 0)
        hpBg.Position = UDim2.new(0, -4, 0, 0)
        hpBg.Size = UDim2.new(0, 4, 1, 0)
        hpBg.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
        hpBg.BorderSizePixel = 0
        hpBg.ZIndex = 3
        hpBg.Parent = gui

        local hp = Instance.new("Frame")
        hp.Name = "Health"
        hp.AnchorPoint = Vector2.new(0, 1)
        hp.Position = UDim2.new(0, 0, 1, 0)
        hp.Size = UDim2.fromScale(1, 1)
        hp.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
        hp.BorderSizePixel = 0
        hp.ZIndex = 4
        hp.Parent = hpBg

        local highlight = Instance.new("Highlight")
        highlight.Name = "VOM_IOS_Chams"
        highlight.Adornee = char
        highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        highlight.FillTransparency = 0.55
        highlight.OutlineTransparency = 0.15
        highlight.Enabled = false
        highlight.Parent = char

        local data = {
            Character = char, Root = hrp, Gui = gui, Box = box, Stroke = stroke,
            Name = name, Distance = distance, Weapon = weapon,
            HealthBackground = hpBg, Health = hp, Highlight = highlight,
            LastVisible = false, LastVisibleCheck = 0,
        }
        cache[plr] = data
        return data
    end

    local function removeEntry(plr)
        local data = cache[plr]
        if not data then return end
        pcall(function() data.Gui:Destroy() end)
        if data.Highlight then pcall(function() data.Highlight:Destroy() end) end
        cache[plr] = nil
    end

    local function heldWeapon(char)
        for _, child in ipairs(char:GetChildren()) do
            if child:IsA("Tool") then return child.Name end
        end
        return ""
    end

    function F.updateIOSESP(now)
        if S.Unloaded then return end
        if not S.IOS.Enabled then
            rootGui.Enabled = false
            for _, data in pairs(cache) do
                data.Gui.Visible = false
                if data.Highlight then data.Highlight.Enabled = false end
            end
            return
        end
        rootGui.Enabled = true

        local cam = Svc.WS.CurrentCamera
        if not cam then return end
        local myRoot = F.char and F.char:FindFirstChild("HumanoidRootPart")
        for plr in next, F.playerCache do
            local char = plr.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            local hum = char and char:FindFirstChildWhichIsA("Humanoid")
            local data = cache[plr]

            if not char or not hrp or not hum or hum.Health <= 0 then
                if data then
                    data.Gui.Visible = false
                    if data.Highlight then data.Highlight.Enabled = false end
                end
                continue
            end

            if not data or data.Character ~= char or data.Root ~= hrp or not data.Gui.Parent then
                data = createEntry(plr, char, hrp)
            end

            local distance = myRoot and (myRoot.Position - hrp.Position).Magnitude or 0
            local screen, onScreen = cam:WorldToViewportPoint(hrp.Position + Vector3.new(0, 0.35, 0))
            local inRange = (not myRoot or distance <= S.IOS.MaxDistance)
            local visibleOnScreen = onScreen and screen.Z > 0 and inRange

            -- Constant pixel dimensions. Distance never changes the ESP box size.
            data.Gui.Size = UDim2.fromOffset(S.IOS.BoxWidth, S.IOS.BoxHeight)
            data.Gui.Position = UDim2.fromOffset(mathFloor(screen.X), mathFloor(screen.Y))
            data.Gui.Visible = visibleOnScreen
            data.Box.Visible = S.IOS.Box
            data.Stroke.Color = S.IOSColors.Box
            data.Name.Visible = S.IOS.Name
            data.Name.Text = plr.DisplayName
            data.Name.TextColor3 = S.IOSColors.Name
            data.Distance.Visible = S.IOS.Distance and myRoot ~= nil
            data.Distance.Text = myRoot and (mathFloor(distance) .. "m") or ""
            data.Distance.TextColor3 = S.IOSColors.Distance
            data.Weapon.Visible = S.IOS.Weapon
            data.Weapon.Text = S.IOS.Weapon and heldWeapon(char) or ""
            data.HealthBackground.Visible = S.IOS.HealthBar

            local frac = mathClamp(hum.Health / math.max(hum.MaxHealth, 1), 0, 1)
            data.Health.Size = UDim2.new(1, 0, frac, 0)
            data.Health.BackgroundColor3 = Color3.fromRGB(
                mathFloor(255 * (1 - frac)), mathFloor(255 * frac), 0)

            if now - data.LastVisibleCheck >= 0.2 then
                data.LastVisibleCheck = now
                local head = char:FindFirstChild("HeadHitbox") or char:FindFirstChild("Head") or hrp
                data.LastVisible = F.pointVisible(char, head.Position)
            end

            if data.Highlight then
                data.Highlight.Enabled = inRange and S.IOS.Chams
                local color = data.LastVisible and S.IOSColors.Visible or S.IOSColors.Hidden
                data.Highlight.FillColor = color
                data.Highlight.OutlineColor = color
            end
        end
    end

    F.cleanupIOSESP = function()
        for plr in pairs(cache) do removeEntry(plr) end
        pcall(function() rootGui:Destroy() end)
    end

    F.trackConn(Svc.Players.PlayerRemoving:Connect(removeEntry))
end

do
    -- Inventory checker extracted from the reference script: Character + Backpack Tools.
    -- Visibility is bound to the player currently selected inside Silent Aim FOV.
    local playerGui = LP:WaitForChild("PlayerGui")
    local gui = Instance.new("ScreenGui")
    gui.Name = "VOMAGLA_FOV_INVENTORY"
    gui.ResetOnSpawn = false
    gui.IgnoreGuiInset = true
    gui.DisplayOrder = 9996
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.Parent = playerGui

    local frame = Instance.new("Frame")
    frame.Name = "InventoryChecker"
    frame.Size = UDim2.fromOffset(250, 218)
    frame.Position = UDim2.new(1, -270, 0.5, -109)
    frame.BackgroundColor3 = Color3.fromRGB(14, 14, 17)
    frame.BackgroundTransparency = 0
    frame.BorderSizePixel = 0
    frame.Visible = false
    frame.Active = true
    frame.Parent = gui
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 4)
    local border = Instance.new("UIStroke", frame)
    border.Color = Color3.fromRGB(55, 55, 65)
    border.Thickness = 1
    border.Transparency = 0

    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.Size = UDim2.new(1, 0, 0, 30)
    title.BackgroundColor3 = Color3.fromRGB(22, 22, 27)
    title.BorderSizePixel = 0
    title.Font = Enum.Font.GothamBold
    title.TextSize = 13
    title.TextColor3 = Color3.new(1, 1, 1)
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Text = "  VOMAGLA  |  INVENTORY"
    title.Active = true
    title.Parent = frame
    Instance.new("UICorner", title).CornerRadius = UDim.new(0, 4)
    local accent = Instance.new("Frame")
    accent.Size = UDim2.new(1, 0, 0, 2)
    accent.Position = UDim2.new(0, 0, 1, -2)
    accent.BackgroundColor3 = Color3.fromRGB(120, 120, 150)
    accent.BorderSizePixel = 0
    accent.Parent = title

    local status = Instance.new("TextLabel")
    status.Position = UDim2.fromOffset(8, 32)
    status.Size = UDim2.new(1, -16, 0, 18)
    status.BackgroundTransparency = 1
    status.Font = Enum.Font.Gotham
    status.TextSize = 10
    status.TextColor3 = Color3.fromRGB(180, 180, 195)
    status.TextXAlignment = Enum.TextXAlignment.Left
    status.Text = "Target must be inside Silent Aim FOV"
    status.Parent = frame

    local list = Instance.new("ScrollingFrame")
    list.Position = UDim2.fromOffset(8, 53)
    list.Size = UDim2.new(1, -16, 1, -61)
    list.BackgroundTransparency = 1
    list.BorderSizePixel = 0
    list.ScrollBarThickness = 3
    list.ScrollBarImageColor3 = Color3.fromRGB(120, 120, 145)
    list.CanvasSize = UDim2.fromOffset(0, 0)
    list.Parent = frame

    local layout = Instance.new("UIGridLayout")
    layout.CellSize = UDim2.fromOffset(50, 56)
    layout.CellPadding = UDim2.fromOffset(6, 6)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Parent = list
    F.trackConn(layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        list.CanvasSize = UDim2.fromOffset(0, layout.AbsoluteContentSize.Y + 4)
    end))

    -- Draggable with both touch and mouse.
    local dragging, dragInput, dragStart, startPosition = false, nil, nil, nil
    F.trackConn(title.InputBegan:Connect(function(input)
        local inputType = input.UserInputType
        if inputType == Enum.UserInputType.MouseButton1 or inputType == Enum.UserInputType.Touch then
            dragging = true
            dragInput = input
            dragStart = input.Position
            startPosition = frame.Position
            F.trackConn(input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
            end))
        end
    end))
    F.trackConn(title.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch then dragInput = input end
    end))
    F.trackConn(Svc.UIS.InputChanged:Connect(function(input)
        if not dragging or input ~= dragInput or not dragStart or not startPosition then return end
        local delta = input.Position - dragStart
        frame.Position = UDim2.new(startPosition.X.Scale, startPosition.X.Offset + delta.X,
            startPosition.Y.Scale, startPosition.Y.Offset + delta.Y)
    end))

    local function clearGrid()
        for _, child in ipairs(list:GetChildren()) do
            if child ~= layout then child:Destroy() end
        end
    end

    local function toolIcon(tool)
        local icon = ""
        pcall(function() icon = tool.TextureId or "" end)
        if icon ~= "" then return icon end
        for _, key in ipairs({ "Icon", "Image", "TextureId", "ItemIcon" }) do
            local value = tool:GetAttribute(key)
            if type(value) == "string" and value ~= "" then return value end
            local child = tool:FindFirstChild(key)
            if child and child:IsA("StringValue") and child.Value ~= "" then return child.Value end
        end
        return ""
    end

    local function toolAmount(tool)
        for _, key in ipairs({ "Amount", "Count", "Quantity", "Stack", "StackSize" }) do
            local value = tool:GetAttribute(key)
            if type(value) == "number" then return math.max(1, mathFloor(value)) end
            local child = tool:FindFirstChild(key)
            if child and (child:IsA("IntValue") or child:IsA("NumberValue")) then
                return math.max(1, mathFloor(child.Value))
            end
        end
        return 1
    end

    local function collectTools(plr)
        local aggregated = {}
        local function add(tool, equipped)
            local image = toolIcon(tool)
            local key = string.lower(tool.Name) .. "|" .. image .. "|" .. tostring(equipped)
            local existing = aggregated[key]
            if existing then
                existing.Amount = existing.Amount + toolAmount(tool)
            else
                aggregated[key] = {
                    Name = tool.Name, Image = image, Amount = toolAmount(tool), Equipped = equipped
                }
            end
        end

        local char = plr.Character
        if char then
            for _, item in ipairs(char:GetChildren()) do
                if item:IsA("Tool") then add(item, true) end
            end
        end
        local backpack = plr:FindFirstChild("Backpack")
        if backpack then
            for _, item in ipairs(backpack:GetChildren()) do
                if item:IsA("Tool") then add(item, false) end
            end
        end

        local result = {}
        for _, item in pairs(aggregated) do result[#result + 1] = item end
        table.sort(result, function(a, b)
            if a.Equipped ~= b.Equipped then return a.Equipped end
            return string.lower(a.Name) < string.lower(b.Name)
        end)
        return result
    end

    local function render(items)
        clearGrid()
        for index, item in ipairs(items) do
            local cell = Instance.new("Frame")
            cell.LayoutOrder = index
            cell.BackgroundColor3 = Color3.fromRGB(23, 23, 28)
            cell.BorderSizePixel = 0
            cell.Parent = list
            Instance.new("UICorner", cell).CornerRadius = UDim.new(0, 3)
            local cellStroke = Instance.new("UIStroke", cell)
            cellStroke.Color = Color3.fromRGB(48, 48, 58)
            cellStroke.Thickness = 1

            local icon = Instance.new("ImageLabel")
            icon.Size = UDim2.new(1, -8, 1, -18)
            icon.Position = UDim2.fromOffset(4, 3)
            icon.BackgroundTransparency = 1
            icon.ScaleType = Enum.ScaleType.Fit
            icon.Image = item.Image
            icon.Parent = cell

            if item.Image == "" then
                local fallback = Instance.new("TextLabel")
                fallback.Size = icon.Size
                fallback.Position = icon.Position
                fallback.BackgroundTransparency = 1
                fallback.Font = Enum.Font.GothamBold
                fallback.TextSize = 9
                fallback.TextWrapped = true
                fallback.TextColor3 = Color3.fromRGB(225, 225, 235)
                fallback.Text = item.Name
                fallback.Parent = cell
            end

            local name = Instance.new("TextLabel")
            name.AnchorPoint = Vector2.new(0, 1)
            name.Position = UDim2.new(0, 2, 1, -1)
            name.Size = UDim2.new(1, -4, 0, 14)
            name.BackgroundTransparency = 1
            name.Font = Enum.Font.Gotham
            name.TextSize = 8
            name.TextTruncate = Enum.TextTruncate.AtEnd
            name.TextColor3 = item.Equipped and Color3.fromRGB(255, 85, 85) or Color3.fromRGB(205, 205, 215)
            name.Text = item.Name
            name.Parent = cell

            if item.Equipped then
                local using = Instance.new("TextLabel")
                using.Size = UDim2.new(1, 0, 0, 12)
                using.Position = UDim2.new(0, 0, 0, 0)
                using.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
                using.BackgroundTransparency = 0.25
                using.Font = Enum.Font.GothamBold
                using.TextSize = 8
                using.TextColor3 = Color3.fromRGB(255, 80, 80)
                using.Text = "USING"
                using.Parent = cell
            end

            if item.Amount > 1 then
                local amount = Instance.new("TextLabel")
                amount.AnchorPoint = Vector2.new(1, 0)
                amount.Position = UDim2.new(1, -2, 0, 14)
                amount.Size = UDim2.fromOffset(28, 13)
                amount.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
                amount.BackgroundTransparency = 0.25
                amount.Font = Enum.Font.GothamBold
                amount.TextSize = 8
                amount.TextColor3 = Color3.new(1, 1, 1)
                amount.Text = "x" .. item.Amount
                amount.Parent = cell
                Instance.new("UICorner", amount).CornerRadius = UDim.new(0, 3)
            end
        end
    end

    local function silentAimFovPlayer()
        if not S.SA.Enabled or not F.targetPart or not F.targetPart.Parent then return nil end
        local char = F.targetPart:FindFirstAncestorOfClass("Model")
        if not char then return nil end
        local plr = Svc.Players:GetPlayerFromCharacter(char)
        if not plr or plr == LP then return nil end

        local cam = Svc.WS.CurrentCamera
        if not cam then return nil end
        local screen, onScreen = cam:WorldToViewportPoint(F.targetPart.Position)
        if not onScreen or screen.Z <= 0 then return nil end
        local center = cam.ViewportSize * 0.5
        if (Vector2New(screen.X, screen.Y) - center).Magnitude > S.SA.FOVRadius then return nil end
        return plr
    end

    local lastPlayer, lastSignature = nil, ""

    function F.updateInventoryInspector(now)
        if S.Unloaded or not S.Inspector.Enabled then
            frame.Visible = false
            lastPlayer, lastSignature = nil, ""
            return
        end

        local plr = silentAimFovPlayer()
        if not plr then
            frame.Visible = false
            lastPlayer, lastSignature = nil, ""
            return
        end

        local items = collectTools(plr)
        local signatureParts = { tostring(plr.UserId) }
        for _, item in ipairs(items) do
            signatureParts[#signatureParts + 1] = item.Name .. ":" .. item.Image .. ":"
                .. item.Amount .. ":" .. tostring(item.Equipped)
        end
        local signature = table.concat(signatureParts, "|")

        frame.Visible = true
        title.Text = "  VOMAGLA  |  " .. string.upper(plr.DisplayName)
        status.Text = #items > 0 and (tostring(#items) .. " item type(s)  •  red = equipped") or "Inventory is empty"
        if plr ~= lastPlayer or signature ~= lastSignature then
            render(items)
            lastPlayer, lastSignature = plr, signature
        end
    end

    F.cleanupInventoryInspector = function()
        pcall(function() gui:Destroy() end)
    end
end

do
    local spikesConn, leavesConn = nil, nil

    local function rmSpikes()
        local n = 0
        for _, o in ipairs(Svc.WS:GetDescendants()) do
            if o.Name == "Spikes" then pcall(function() o:Destroy() end) n = n + 1 end
        end
        if n > 0 then pcall(F.Notify, "Removed " .. n .. " spikes", 3) end
    end

    function F.toggleSpikes(en)
        if en then
            rmSpikes()
            if spikesConn then pcall(function() spikesConn:Disconnect() end) end
            spikesConn = Svc.WS.DescendantAdded:Connect(function(o)
                if o.Name == "Spikes" then task_defer(function() pcall(function() o:Destroy() end) end) end
            end)
        else
            if spikesConn then pcall(function() spikesConn:Disconnect() end) spikesConn = nil end
        end
    end

    local function rmLeaves()
        local n = 0
        for _, o in ipairs(Svc.WS:GetDescendants()) do
            if o.Name == "LeavesTop" or o.Name == "Leafs" then
                pcall(function() o:Destroy() end)
                n = n + 1
            end
        end
        if n > 0 then pcall(F.Notify, "Removed " .. n .. " leaves", 3) end
    end

    function F.toggleLeaves(en)
        if en then
            rmLeaves()
            if leavesConn then pcall(function() leavesConn:Disconnect() end) end
            leavesConn = Svc.WS.DescendantAdded:Connect(function(o)
                if o.Name == "LeavesTop" or o.Name == "Leafs" then
                    task_defer(function() pcall(function() o:Destroy() end) end)
                end
            end)
        else
            if leavesConn then pcall(function() leavesConn:Disconnect() end) leavesConn = nil end
        end
    end

    F.cleanupWorldConns = function()
        if spikesConn then pcall(function() spikesConn:Disconnect() end) spikesConn = nil end
        if leavesConn then pcall(function() leavesConn:Disconnect() end) leavesConn = nil end
    end
end

do
    local conns = {}
    local highlights = {}

    local function apply(tool)
        if not tool:IsA("Tool") then return end
        local old = tool:FindFirstChild("VomToolHL")
        if old then old:Destroy() end
        if not S.ToolHL.Enabled then return end
        local hl = Instance.new("Highlight")
        hl.Name = "VomToolHL"
        hl.Adornee = tool
        hl.FillTransparency = 1
        hl.OutlineColor = S.ToolHL.Color
        hl.OutlineTransparency = 0
        hl.Parent = tool
        highlights[tool] = hl
    end

    local function rmAll()
        for _, hl in pairs(highlights) do
            if hl and hl.Parent then pcall(function() hl:Destroy() end) end
        end
        highlights = {}
    end

    function F.setupToolHL()
        for _, c in pairs(conns) do pcall(function() c:Disconnect() end) end
        conns = {}
        if not S.ToolHL.Enabled then rmAll() return end
        local bp = LP:FindFirstChild("Backpack")
        if bp then
            for _, t in pairs(bp:GetChildren()) do apply(t) end
            conns[#conns+1] = bp.ChildAdded:Connect(function(t)
                if S.ToolHL.Enabled and t:IsA("Tool") then task_defer(function() apply(t) end) end
            end)
        end
        if F.char then
            for _, t in pairs(F.char:GetChildren()) do if t:IsA("Tool") then apply(t) end end
            conns[#conns+1] = F.char.ChildAdded:Connect(function(t)
                if S.ToolHL.Enabled and t:IsA("Tool") then task_defer(function() apply(t) end) end
            end)
        end
        conns[#conns+1] = LP.CharacterAdded:Connect(function(ch)
            task_wait(1)
            local nbp = LP:FindFirstChild("Backpack")
            if nbp then
                for _, t in pairs(nbp:GetChildren()) do apply(t) end
                conns[#conns+1] = nbp.ChildAdded:Connect(function(t)
                    if S.ToolHL.Enabled and t:IsA("Tool") then task_defer(function() apply(t) end) end
                end)
            end
        end)
    end

    F.cleanupToolHL = function()
        rmAll()
        for _, c in pairs(conns) do pcall(function() c:Disconnect() end) end
        conns = {}
    end

    F.setToolHLColor = function(col)
        for _, hl in pairs(highlights) do
            if hl and hl.Parent then pcall(function() hl.OutlineColor = col end) end
        end
    end
end

do
    local conn = nil
    local rp = RaycastParams.new()
    rp.FilterType = Enum.RaycastFilterType.Exclude

    function F.toggleNoFall(en)
        if conn then pcall(function() conn:Disconnect() end) conn = nil end
        if en then
            conn = Svc.RunService.Heartbeat:Connect(function()
                local char = LP.Character
                if not char then return end
                local root = char:FindFirstChild("HumanoidRootPart")
                local hum = char:FindFirstChildWhichIsA("Humanoid")
                if root and hum and hum.Health > 0 and root.AssemblyLinearVelocity.Y < -55 then
                    rp.FilterDescendantsInstances = { char }
                    local result = Svc.WS:Raycast(root.Position, Vector3New(0, -10, 0), rp)
                    if result then
                        root.AssemblyLinearVelocity = Vector3New(
                            root.AssemblyLinearVelocity.X, -2, root.AssemblyLinearVelocity.Z)
                    end
                end
            end)
        end
    end

    F.cleanupNoFall = function() if conn then pcall(function() conn:Disconnect() end) conn = nil end end
end

do
    function F.applyWater()
        local terrain = Svc.WS.Terrain
        if S.Water.Enabled then
            if not S.Water.OrigColor then
                S.Water.OrigColor = terrain.WaterColor
                S.Water.OrigRef = terrain.WaterReflectance
            end
            terrain.WaterColor = S.Water.Color
            terrain.WaterReflectance = S.Water.Reflectance
        elseif S.Water.OrigColor then
            terrain.WaterColor = S.Water.OrigColor
            terrain.WaterReflectance = S.Water.OrigRef
        end
    end
end

do
    local function getHum()
        return LP.Character and LP.Character:FindFirstChildWhichIsA("Humanoid")
    end

    function F.disableCopterFly()
        S.CopterFly.Enabled = false
        if S.CopterFly.bodyVel then pcall(function() S.CopterFly.bodyVel:Destroy() end) S.CopterFly.bodyVel = nil end
        if S.CopterFly.bodyGyro then pcall(function() S.CopterFly.bodyGyro:Destroy() end) S.CopterFly.bodyGyro = nil end
        local hum = getHum()
        if hum then hum.AutoRotate = true end
    end

    function F.toggleCopterFly()
        local hum = getHum()
        if S.CopterFly.Enabled then F.disableCopterFly() return end
        if hum and hum.SeatPart then
            S.CopterFly.Enabled = true
            hum.AutoRotate = false
            local target = hum.SeatPart
            S.CopterFly.bodyVel = Instance.new("BodyVelocity")
            S.CopterFly.bodyVel.MaxForce = Vector3.new(1, 1, 1) * 9e9
            S.CopterFly.bodyVel.Velocity = Vector3.new(0, 0, 0)
            S.CopterFly.bodyVel.Parent = target
            S.CopterFly.bodyGyro = Instance.new("BodyGyro")
            S.CopterFly.bodyGyro.MaxTorque = Vector3.new(1, 1, 1) * 9e9
            S.CopterFly.bodyGyro.P = 9000
            S.CopterFly.bodyGyro.CFrame = target.CFrame
            S.CopterFly.bodyGyro.Parent = target
        end
    end

    function F.copterFlyStep(hum)
        if not hum or not hum.SeatPart then F.disableCopterFly() return end
        local target = hum.SeatPart
        local cam = Svc.WS.CurrentCamera
        hum.Sit = true
        local moveVec = Vector3.new(0, 0, 0)
        local camCF = cam.CFrame
        if Svc.UIS:IsKeyDown(Enum.KeyCode.W) then moveVec = moveVec + camCF.LookVector end
        if Svc.UIS:IsKeyDown(Enum.KeyCode.S) then moveVec = moveVec - camCF.LookVector end
        if Svc.UIS:IsKeyDown(Enum.KeyCode.D) then moveVec = moveVec + camCF.RightVector end
        if Svc.UIS:IsKeyDown(Enum.KeyCode.A) then moveVec = moveVec - camCF.RightVector end
        local vert = 0
        if Svc.UIS:IsKeyDown(Enum.KeyCode.LeftShift) or Svc.UIS:IsKeyDown(Enum.KeyCode.RightShift) then vert = 1 end
        if Svc.UIS:IsKeyDown(Enum.KeyCode.LeftControl) or Svc.UIS:IsKeyDown(Enum.KeyCode.RightControl) then vert = -1 end
        if S.CopterFly.bodyVel and S.CopterFly.bodyVel.Parent == target then
            if moveVec.Magnitude > 0 or vert ~= 0 then
                S.CopterFly.bodyVel.Velocity = (moveVec + Vector3.new(0, vert, 0)).Unit * S.CopterFly.Speed
            else
                S.CopterFly.bodyVel.Velocity = Vector3.new(0, 0, 0)
            end
        end
        if S.CopterFly.bodyGyro and S.CopterFly.bodyGyro.Parent == target then
            S.CopterFly.bodyGyro.CFrame = camCF
        end
    end
end

do
    local keywords = { "TwigWall", "SoloTwigFrame", "TrigTwigRoof", "TwigFrame", "TwigWindow", "TwigRoof" }
    local cacheX = {}

    local function isTwig(name)
        for _, k in ipairs(keywords) do
            if string_find(name, k) then return true end
        end
        return false
    end

    local function reg(o)
        if cacheX[o] then return end
        if (o:IsA("BasePart") or o:IsA("MeshPart") or o:IsA("UnionOperation")) and isTwig(o.Name) then
            cacheX[o] = { OT = o.Transparency }
        end
    end

    function F.setXrayState(on, t)
        for p, d in pairs(cacheX) do
            if p and p.Parent and p:IsDescendantOf(Svc.WS) then
                p.Transparency = on and t or d.OT
            else
                cacheX[p] = nil
            end
        end
    end

    task_spawn(function()
        for _, o in pairs(Svc.WS:GetDescendants()) do reg(o) end
    end)
    F.trackConn(Svc.WS.DescendantAdded:Connect(function(o)
        reg(o)
        if S.XRay.Enabled and (o:IsA("BasePart") or o:IsA("MeshPart") or o:IsA("UnionOperation")) and isTwig(o.Name) then
            o.Transparency = S.XRay.Transparency
        end
    end))
end

do
    local gui = Instance.new("ScreenGui")
    gui.Name = "VOMAGLA_HitLogs"
    gui.ResetOnSpawn = false
    gui.IgnoreGuiInset = true
    gui.DisplayOrder = 9998
    pcall(function() gui.Parent = Svc.CoreGui end)
    if not gui.Parent then gui.Parent = LP:WaitForChild("PlayerGui") end

    local holder = Instance.new("Frame")
    holder.BackgroundTransparency = 1
    holder.BorderSizePixel = 0
    holder.AutomaticSize = Enum.AutomaticSize.XY
    holder.Size = UDim2.fromOffset(0, 0)
    holder.AnchorPoint = Vector2.new(0.5, 0)
    holder.Position = UDim2.new(0.5, 0, 0.62, 0)
    holder.Parent = gui

    local layout = Instance.new("UIListLayout")
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Parent = holder

    local order = 0

    local function setPos()
        if S.HL.Position == "Center" then
            holder.AnchorPoint = Vector2.new(0.5, 0)
            holder.Position = UDim2.new(0.5, 0, 0.62, 0)
        elseif S.HL.Position == "Left" then
            holder.AnchorPoint = Vector2.new(0, 0.5)
            holder.Position = UDim2.new(0, 18, 0.5, 0)
        elseif S.HL.Position == "Top" then
            holder.AnchorPoint = Vector2.new(0.5, 0)
            holder.Position = UDim2.new(0.5, 0, 0, 78)
        else
            holder.AnchorPoint = Vector2.new(0, 0)
            holder.Position = UDim2.new(0, 18, 0, 78)
        end
    end
    setPos()
    F.setHLPos = setPos

    local function esc(t)
        return (tostring(t):gsub("&", "&amp;"):gsub("<", "&lt;"):gsub(">", "&gt;"):gsub('"', "&quot;"):gsub("'", "&apos;"))
    end

    F.showHitLog = function(playerName, partName, dmg, health)
        local r = mathFloor(S.HL.Color.R * 255)
        local g = mathFloor(S.HL.Color.G * 255)
        local b = mathFloor(S.HL.Color.B * 255)
        local label = Instance.new("TextLabel")
        order = order + 1
        label.LayoutOrder = -order
        label.Parent = holder
        label.BackgroundTransparency = 1
        label.BorderSizePixel = 0
        label.AutomaticSize = Enum.AutomaticSize.X
        label.Size = UDim2.fromOffset(0, 18)
        label.Font = Enum.Font.Code
        label.TextSize = 13
        label.TextColor3 = Color3.new(1, 1, 1)
        label.TextStrokeColor3 = Color3.new(0, 0, 0)
        label.TextStrokeTransparency = 1
        label.TextTransparency = 1
        label.RichText = true
        label.Text = string_format(
            '[ <font color="rgb(%d, %d, %d)">VOMAGLA</font> ] Hit %s in the %s for %s damage (%s health remaining)',
            r, g, b, esc(playerName), esc(partName), esc(dmg), esc(health))
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.ZIndex = 10

        Svc.TS:Create(label, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            TextTransparency = 0, TextStrokeTransparency = 0.35
        }):Play()

        task_delay(S.HL.Duration, function()
            if not label or not label.Parent then return end
            local tw = Svc.TS:Create(label, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                TextTransparency = 1, TextStrokeTransparency = 1
            })
            tw:Play()
            tw.Completed:Wait()
            pcall(function() label:Destroy() end)
        end)
    end

    F.cleanupHitLogs = function() pcall(function() gui:Destroy() end) end
end

do
    local queue = {}
    local DIRS = { {1,1}, {-1,1}, {1,-1}, {-1,-1} }

    if DrawingOK then
        F.spawnHitMarker = function(worldPos, isKill)
            local lines = {}
            for i = 1, 4 do
                local l = Drawing.new("Line")
                l.Visible = false
                l.Thickness = S.HM.Thickness
                l.ZIndex = 5
                lines[i] = l
            end
            queue[#queue + 1] = { pos = worldPos, born = osClock(), isKill = isKill, lines = lines }
        end
    else
        F.spawnHitMarker = function() end
    end

    F.processHitMarkers = function()
        if not DrawingOK or #queue == 0 then return end
        local cam = Svc.WS.CurrentCamera
        local now = osClock()
        for i = #queue, 1, -1 do
            local m = queue[i]
            local age = now - m.born
            if age > S.HM.Duration then
                for _, l in ipairs(m.lines) do pcall(function() l:Remove() end) end
                table.remove(queue, i)
            elseif not S.HM.Enabled then
                for _, l in ipairs(m.lines) do l.Visible = false end
            elseif cam and m.pos then
                local sp, vis = cam:WorldToViewportPoint(m.pos)
                local alpha = 1 - (age / S.HM.Duration)
                local col = m.isKill and S.HM.KillColor or S.HM.Color
                local cx, cy = sp.X, sp.Y
                for j = 1, 4 do
                    local l = m.lines[j]
                    local d = DIRS[j]
                    l.Visible = vis
                    l.Transparency = alpha
                    l.Color = col
                    l.Thickness = S.HM.Thickness
                    l.From = Vector2New(cx + d[1] * S.HM.Size * 0.3, cy + d[2] * S.HM.Size * 0.3)
                    l.To = Vector2New(cx + d[1] * S.HM.Size, cy + d[2] * S.HM.Size)
                end
            end
        end
    end

    F.cleanupHitMarkers = function()
        for i = #queue, 1, -1 do
            local m = queue[i]
            if m and m.lines then
                for _, l in ipairs(m.lines) do pcall(function() l:Remove() end) end
            end
            queue[i] = nil
        end
    end
end

do
    local function scaleSeqKeys(keys, f)
        local out = {}
        for i, kp in ipairs(keys) do
            out[i] = NumberSequenceKeypoint.new(kp.Time, kp.Value * f, kp.Envelope * f)
        end
        return NumberSequence.new(out)
    end

    local function scaleRange(min, max, f)
        return NumberRange.new(min * f, max * f)
    end

    local function makeEmitter(attachment, style, colorSeq)
        local e = Instance.new("ParticleEmitter")
        e.Enabled = false
        e.Color = colorSeq
        local szF = S.DamageFX.Size * 4
        local lfF = S.DamageFX.Lifetime / 0.8
        local spF = S.DamageFX.Speed / 20

        if style == "Foam" then
            e.LightInfluence = 0.5
            e.Lifetime = scaleRange(1, 1, lfF)
            e.SpreadAngle = Vector2.new(360, -360)
            e.Squash = NumberSequence.new(1)
            e.Speed = scaleRange(20, 20, spF)
            e.Brightness = 2.5
            e.Size = scaleSeqKeys({
                NumberSequenceKeypoint.new(0, 0),
                NumberSequenceKeypoint.new(0.1, 0.65, 0.65),
                NumberSequenceKeypoint.new(0.65, 1.42, 0.41),
                NumberSequenceKeypoint.new(1, 0),
            }, szF)
            e.Acceleration = Vector3.new(0, -66, 0)
            e.Rate = 100
            e.Texture = "rbxassetid://8297030850"
            e.Rotation = NumberRange.new(-90, -90)
            e.Orientation = Enum.ParticleOrientation.VelocityParallel
        elseif style == "Crescents" then
            e.Lifetime = scaleRange(0.19, 0.38, lfF)
            e.SpreadAngle = Vector2.new(-360, 360)
            e.Transparency = NumberSequence.new({
                NumberSequenceKeypoint.new(0, 1),
                NumberSequenceKeypoint.new(0.19, 0),
                NumberSequenceKeypoint.new(0.78, 0),
                NumberSequenceKeypoint.new(1, 1),
            })
            e.LightEmission = 10
            e.Speed = scaleRange(0.08, 0.08, spF)
            e.Brightness = 4
            e.Size = scaleSeqKeys({
                NumberSequenceKeypoint.new(0, 0),
                NumberSequenceKeypoint.new(0.4, 8.8, 2.28),
                NumberSequenceKeypoint.new(1, 11.5, 1.86),
            }, szF)
            e.Texture = "rbxassetid://12509373457"
            e.RotSpeed = NumberRange.new(800, 1000)
            e.Rotation = NumberRange.new(-360, 360)
            e.Orientation = Enum.ParticleOrientation.VelocityPerpendicular
        elseif style == "Residue" then
            e.Acceleration = Vector3.new(0, -25, 0)
            e.Drag = 2
            e.Lifetime = scaleRange(0.25, 0.5, lfF)
            e.LightEmission = 1
            e.Orientation = Enum.ParticleOrientation.VelocityParallel
            e.Rate = 100
            e.Rotation = NumberRange.new(90, 90)
            e.Size = scaleSeqKeys({
                NumberSequenceKeypoint.new(0, 2),
                NumberSequenceKeypoint.new(1, 0),
            }, szF)
            e.Speed = scaleRange(25, 50, spF)
            e.SpreadAngle = Vector2.new(-90, 90)
            e.Texture = "rbxassetid://4509687978"
            e.Transparency = NumberSequence.new({
                NumberSequenceKeypoint.new(0, 0),
                NumberSequenceKeypoint.new(0.25, 1),
                NumberSequenceKeypoint.new(1, 1),
            })
        else
            e.Brightness = 3
            e.FlipbookLayout = Enum.ParticleFlipbookLayout.Grid8x8
            e.FlipbookMode = Enum.ParticleFlipbookMode.OneShot
            e.Lifetime = scaleRange(0.5, 1, lfF)
            e.LightEmission = 2
            e.Orientation = Enum.ParticleOrientation.FacingCameraWorldUp
            e.Rate = 12
            e.Size = scaleSeqKeys({
                NumberSequenceKeypoint.new(0, 25),
                NumberSequenceKeypoint.new(1, 0),
            }, szF)
            e.Speed = NumberRange.new(0, 0)
            e.Texture = "rbxassetid://10547286472"
            e.Transparency = NumberSequence.new({
                NumberSequenceKeypoint.new(0, 0),
                NumberSequenceKeypoint.new(0.25, 1),
                NumberSequenceKeypoint.new(1, 1),
            })
        end
        e.Parent = attachment
        return e
    end

    F.spawnDamageFX = function(pos, scale)
        if S.Unloaded or not pos or not S.DamageFX.Enabled then return end
        scale = scale or 1
        local p = Instance.new("Part")
        p.Size = Vector3.new(0.2, 0.2, 0.2)
        p.Transparency = 1
        p.Anchored = true
        p.CanCollide = false
        p.CanQuery = false
        p.CanTouch = false
        p.CastShadow = false
        p.Position = pos + Vector3.new(0, 1, 0)
        p.Parent = Svc.WS

        local att = Instance.new("Attachment")
        att.Parent = p

        local col
        if S.DamageFX.Rainbow then
            col = ColorSequence.new(Color3.fromHSV(math.random(), 1, 1))
        else
            col = ColorSequence.new(S.DamageFX.Color)
        end

        local ok, emitter = pcall(makeEmitter, att, S.DamageFX.Style, col)
        if ok and emitter then
            emitter:Emit(math.max(1, mathFloor(S.DamageFX.Count * scale)))
        end

        Svc.Debris:AddItem(p, math.max(1, S.DamageFX.Lifetime + 1.2))
    end
end

do
    local KILL_SOUNDS = { "6350854289", "132050044560917", "125662494668382", "130940311850179" }
    local DOUBLE = "116907610084760"
    local times = {}
    local lastDouble = 0

    F.playKillSound = function()
        if not S.KillSound.Enabled or S.Unloaded then return end
        local now = osClock()
        times[#times + 1] = now
        for i = #times, 1, -1 do
            if now - times[i] > 10 then table.remove(times, i) end
        end
        local s = Instance.new("Sound")
        s.Volume = S.KillSound.Volume
        s.Parent = Svc.SS
        if #times >= 2 and now - lastDouble > 1 then
            s.SoundId = "rbxassetid://" .. DOUBLE
            lastDouble = now
        else
            s.SoundId = "rbxassetid://" .. KILL_SOUNDS[math.random(#KILL_SOUNDS)]
        end
        s:Play()
        Svc.Debris:AddItem(s, 6)
    end
end

do
    local lines, dot = {}, nil
    local smoothX, smoothY = nil, nil
    local elapsed = 0
    local rot = 0

    if DrawingOK then
        for i = 1, 4 do
            local l = Drawing.new("Line")
            l.Visible = false
            l.Thickness = S.CH.Thickness
            l.Color = S.CH.Color
            l.ZIndex = 3
            lines[i] = l
        end
        dot = Drawing.new("Square")
        dot.Visible = false
        dot.Filled = true
        dot.Thickness = 1
        dot.Size = Vector2New(2, 2)
        dot.Color = S.CH.Color
        dot.ZIndex = 3
    end

    F.updateCrosshair = function(dt)
        if not DrawingOK then return end
        if not S.CH.Enabled or S.Unloaded then
            for _, l in ipairs(lines) do l.Visible = false end
            if dot then dot.Visible = false end
            return
        end
        local cam = Svc.WS.CurrentCamera
        if not cam then return end
        local vp = cam.ViewportSize
        local cx, cy = vp.X * 0.5, vp.Y * 0.5

        if S.CH.FollowAimPoint and F.aimScreenPos then
            cx, cy = F.aimScreenPos.X, F.aimScreenPos.Y
        elseif S.CH.FollowTarget and F.targetPart and F.targetPart.Parent then
            local sp, vis = cam:WorldToViewportPoint(F.targetPart.Position)
            if vis then cx, cy = sp.X, sp.Y end
        end

        local smooth = mathClamp(S.CH.FollowSmooth, 1, 20)
        local a = 1 - mathExp(-dt * smooth)
        if smoothX == nil then
            smoothX, smoothY = cx, cy
        end
        smoothX = smoothX + (cx - smoothX) * a
        smoothY = smoothY + (cy - smoothY) * a

        elapsed = elapsed + dt
        rot = (rot + dt * S.CH.RotationSpeed) % 360

        local col = S.CH.Color
        if S.CH.Rainbow then
            col = Color3.fromHSV((elapsed * 0.5) % 1, 1, 1)
        end

        local gap = S.CH.Gap
        if S.CH.Pulse then
            gap = gap + mathSin(elapsed * S.CH.PulseSpeed) * math.max(S.CH.Gap * 0.4, 2)
        end
        local len = S.CH.Length

        for i = 0, 3 do
            local l = lines[i + 1]
            local ang = mathRad(rot + i * 90)
            local dx, dy = mathCos(ang), mathSin(ang)
            l.Visible = true
            l.Thickness = S.CH.Thickness
            l.Color = col
            l.From = Vector2New(smoothX + dx * gap, smoothY + dy * gap)
            l.To = Vector2New(smoothX + dx * (gap + len), smoothY + dy * (gap + len))
        end

        if dot then
            dot.Visible = S.CH.Dot
            dot.Color = col
            dot.Position = Vector2New(smoothX - 1, smoothY - 1)
        end
    end

    F.cleanupCrosshair = function()
        for _, l in ipairs(lines) do pcall(function() l:Remove() end) end
        if dot then pcall(function() dot:Remove() end) end
    end
end

do
    local HSList = { None = "", Skeet = "rbxassetid://83717596220569", ["Sonic checkpoint"] = "rbxassetid://6817150445",
        ["Sonic.exe laugh"] = "rbxassetid://18379039436", ["Windows XP Error"] = "rbxassetid://9066167010",
        ["Minecraft Hit"] = "rbxassetid://8766809464", ["one sit nn dog"] = "rbxassetid://7380502345",
        ["Door Bell"] = "rbxassetid://131845870598154", Duck = "rbxassetid://1139819274",
        Mgs = "rbxassetid://81845122657643", Money = "rbxassetid://3020841054", Fart = "rbxassetid://4809574295",
        Meow = "rbxassetid://7148585764", byebye = "rbxassetid://70888261086432" }
    local names = {}
    for n in pairs(HSList) do names[#names + 1] = n end
    F.HSNames = names

    local function apply(snd, vol)
        if not snd or not snd.Parent then return end
        if not S.HitSound.Originals[snd] then
            S.HitSound.Originals[snd] = { SoundId = snd.SoundId, Volume = snd.Volume }
        end
        local id = HSList[S.HitSound.Choice] or ""
        if id ~= "" then
            snd.SoundId = id
        else
            local o = S.HitSound.Originals[snd]
            if o then snd.SoundId = o.SoundId end
        end
        snd.Volume = vol
    end

    function F.restoreHS()
        for snd, d in pairs(S.HitSound.Originals) do
            if snd and snd.Parent then
                pcall(function() snd.SoundId = d.SoundId; snd.Volume = d.Volume end)
            end
        end
        S.HitSound.Originals = {}
    end

    local function chkTool(tool)
        if not tool or not tool:IsA("Tool") then return end
        task_spawn(function()
            local ba = tool:FindFirstChild("BodyAttach") or tool:WaitForChild("BodyAttach", 5)
            if ba then
                for _, sn in ipairs({ "HitClient", "HeadShotClient", "HitCharacterClient" }) do
                    local s = ba:FindFirstChild(sn) or ba:WaitForChild(sn, 3)
                    if s and s:IsA("Sound") then apply(s, S.HitSound.Volume) end
                end
            end
        end)
    end

    function F.applyHSChar(ch)
        if not ch then return end
        for _, c in pairs(ch:GetChildren()) do
            if c:IsA("Tool") then chkTool(c) end
        end
    end

    local hsConn = nil
    function F.setupHSChar(ch)
        if hsConn then pcall(function() hsConn:Disconnect() end) hsConn = nil end
        hsConn = ch.ChildAdded:Connect(function(c)
            if S.HitSound.Enabled and not S.Unloaded and c:IsA("Tool") then
                task_delay(0.3, function() chkTool(c) end)
            end
        end)
        task_spawn(function()
            task_wait(1.5)
            if S.HitSound.Enabled and ch and ch.Parent then F.applyHSChar(ch) end
        end)
    end

    F.cleanupHSChar = function() if hsConn then pcall(function() hsConn:Disconnect() end) hsConn = nil end end
end

do
    function F.onJump(_, new)
        if new ~= Enum.HumanoidStateType.Jumping or not S.JumpCircle.Enabled then return end
        local r = F.char and F.char:FindFirstChild("HumanoidRootPart")
        if r then
            local p = Instance.new("Part", Svc.WS)
            p.Anchored = true
            p.CanCollide = false
            p.Material = Enum.Material.Neon
            p.Color = S.JumpCircle.Color
            p.CFrame = CFrameNew(r.Position - Vector3New(0, 2.9, 0)) * CFrame.Angles(mathRad(90), 0, 0)
            local m = Instance.new("SpecialMesh", p)
            m.MeshId = "rbxassetid://3270017"
            m.MeshType = Enum.MeshType.FileMesh
            Svc.TS:Create(p, TweenInfo.new(0.4), { Transparency = 1 }):Play()
            Svc.TS:Create(m, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Scale = Vector3New(8, 8, 0.2) }):Play()
            task_delay(0.4, function() if p then p:Destroy() end end)
        end
    end
end

do
    local FB = { Conn = nil }
    local OL = {
        Brightness = Svc.Light.Brightness, ClockTime = Svc.Light.ClockTime,
        FogEnd = Svc.Light.FogEnd, GlobalShadows = Svc.Light.GlobalShadows, Ambient = Svc.Light.Ambient
    }

    function F.toggleFB(st)
        if st then
            Svc.Light.Brightness = 2
            Svc.Light.ClockTime = 14
            Svc.Light.FogEnd = 100000
            Svc.Light.GlobalShadows = false
            Svc.Light.Ambient = Color3.fromRGB(178, 178, 178)
            if not FB.Conn then
                FB.Conn = Svc.Light.Changed:Connect(function()
                    if FB.Conn then
                        Svc.Light.Brightness = 2
                        Svc.Light.ClockTime = 14
                        Svc.Light.FogEnd = 100000
                        Svc.Light.GlobalShadows = false
                        Svc.Light.Ambient = Color3.fromRGB(178, 178, 178)
                    end
                end)
            end
        else
            if FB.Conn then pcall(function() FB.Conn:Disconnect() end) FB.Conn = nil end
            Svc.Light.Brightness = OL.Brightness
            Svc.Light.ClockTime = OL.ClockTime
            Svc.Light.FogEnd = OL.FogEnd
            Svc.Light.GlobalShadows = OL.GlobalShadows
            Svc.Light.Ambient = OL.Ambient
        end
    end

    F.cleanupFB = function()
        if FB.Conn then pcall(function() FB.Conn:Disconnect() end) FB.Conn = nil end
        Svc.Light.Brightness = OL.Brightness
        Svc.Light.ClockTime = OL.ClockTime
        Svc.Light.FogEnd = OL.FogEnd
        Svc.Light.GlobalShadows = OL.GlobalShadows
        Svc.Light.Ambient = OL.Ambient
    end

    local skyFx = nil
    function F.toggleSkyColor(on)
        S.SkyColor.Enabled = on
        if on then
            if not skyFx then
                skyFx = Instance.new("ColorCorrectionEffect")
                skyFx.Name = "VomSky"
                skyFx.Parent = Svc.Light
            end
            skyFx.TintColor = S.SkyColor.Color
        elseif skyFx then
            skyFx:Destroy()
            skyFx = nil
        end
    end

    F.setSkyColor = function(col)
        S.SkyColor.Color = col
        if S.SkyColor.Enabled and skyFx then skyFx.TintColor = col end
    end

    F.cleanupSky = function()
        pcall(function()
            local s = Svc.Light:FindFirstChildOfClass("Sky")
            if s then s:Destroy() end
        end)
        if skyFx then pcall(function() skyFx:Destroy() end) skyFx = nil end
    end
end

do
    local skinConfigs = {
        ["Floppa"] = { assetId = 10092677135, scale = 0.6, yOffset = -1.5 },
        ["Minecraft Villager"] = { assetId = 90405905565781, scale = 1.4, yOffset = 0 },
        ["Cat"] = { assetId = 18314616360, scale = 0.5, yOffset = -1.5 },
        ["Drone"] = { assetId = 703305954, scale = 0.5, yOffset = 2 },
        ["Tung Tung Sahur"] = { assetId = 138151705692565, scale = 1.6, yOffset = 0 },
        ["Freddy Fazbear"] = { assetId = 14474779021, scale = 1.6, yOffset = 0 },
        ["Maxwell the Cat"] = { assetId = 15765967358, scale = 0.5, yOffset = -1.5 },
        ["Furry"] = { assetId = 15539009025, scale = 1.0, yOffset = 0 },
    }
    F.SkinNames = {
        "Floppa", "Minecraft Villager", "Cat", "Drone", "Tung Tung Sahur",
        "Freddy Fazbear", "Maxwell the Cat", "Furry",
    }

    local currentModel = nil
    local currentSkinName = nil
    local templateCache = {}
    local originalVisuals = setmetatable({}, { __mode = "k" })
    local applying = false

    local function skinStatus(text, isError)
        pcall(F.Notify, (isError and "Model error: " or "Model: ") .. text, isError and 5 or 3)
        if isError then warn("[VOMAGLA ModelChanger] " .. text) end
    end

    local function setCharacterVisible(character, visible)
        if not character then return end
        for _, inst in ipairs(character:GetDescendants()) do
            if inst:IsA("BasePart") then
                if not visible then
                    if not originalVisuals[inst] then
                        originalVisuals[inst] = {
                            Transparency = inst.Transparency,
                            LocalTransparencyModifier = inst.LocalTransparencyModifier,
                        }
                    end
                    inst.Transparency = 1
                    inst.LocalTransparencyModifier = 1
                else
                    local original = originalVisuals[inst]
                    if original then
                        inst.Transparency = original.Transparency
                        inst.LocalTransparencyModifier = original.LocalTransparencyModifier
                        originalVisuals[inst] = nil
                    end
                end
            elseif inst:IsA("Decal") or inst:IsA("Texture") then
                if not visible then
                    if not originalVisuals[inst] then originalVisuals[inst] = { Transparency = inst.Transparency } end
                    inst.Transparency = 1
                else
                    local original = originalVisuals[inst]
                    if original then inst.Transparency = original.Transparency; originalVisuals[inst] = nil end
                end
            end
        end
    end

    local function normalizeModel(raw)
        if not raw then return nil end
        if raw:IsA("Model") then return raw end
        local nested = raw:FindFirstChildWhichIsA("Model", true)
        if nested then
            nested.Parent = nil
            raw:Destroy()
            return nested
        end
        if raw:IsA("Tool") or raw:IsA("Accessory") then
            local handle = raw:FindFirstChild("Handle")
            if handle then
                local wrapper = Instance.new("Model")
                handle.Parent = wrapper
                wrapper.PrimaryPart = handle
                raw:Destroy()
                return wrapper
            end
        end
        if raw:IsA("BasePart") then
            local wrapper = Instance.new("Model")
            raw.Parent = wrapper
            wrapper.PrimaryPart = raw
            return wrapper
        end
        local anyPart = raw:FindFirstChildWhichIsA("BasePart", true)
        if anyPart then
            local wrapper = Instance.new("Model")
            raw.Parent = wrapper
            return wrapper
        end
        return nil
    end

    local function loadTemplate(name, assetId)
        if templateCache[name] then return templateCache[name] end
        local objects, loadError
        local ok, result = pcall(function()
            return game:GetObjects("rbxassetid://" .. tostring(assetId))
        end)
        if ok and result and #result > 0 then
            objects = result
        else
            loadError = result
            local okInsert, inserted = pcall(function() return Svc.InsertService:LoadAsset(assetId) end)
            if okInsert and inserted then objects = { inserted } else loadError = inserted end
        end
        if not objects then return nil, tostring(loadError) end

        local modelTemplate = normalizeModel(objects[1])
        if not modelTemplate then return nil, "asset has no model or BasePart" end
        for _, inst in ipairs(modelTemplate:GetDescendants()) do
            if inst:IsA("Humanoid") or inst:IsA("Animator") or inst:IsA("AnimationController")
                or inst:IsA("Script") or inst:IsA("LocalScript") or inst:IsA("BodyMover") then
                inst:Destroy()
            elseif inst:IsA("BasePart") then
                inst.CanCollide = false
                inst.CanQuery = false
                inst.CanTouch = false
                inst.Anchored = true
                inst.Massless = true
            end
        end
        if not modelTemplate.PrimaryPart then
            modelTemplate.PrimaryPart = modelTemplate:FindFirstChild("HumanoidRootPart", true)
                or modelTemplate:FindFirstChild("Torso", true)
                or modelTemplate:FindFirstChild("UpperTorso", true)
                or modelTemplate:FindFirstChild("Root", true)
                or modelTemplate:FindFirstChildWhichIsA("BasePart", true)
        end
        if not modelTemplate.PrimaryPart then
            modelTemplate:Destroy()
            return nil, "asset has no BasePart"
        end
        modelTemplate.Parent = nil
        templateCache[name] = modelTemplate
        return modelTemplate
    end

    function F.clearSkin(keepSelection)
        if currentModel then pcall(function() currentModel:Destroy() end) currentModel = nil end
        setCharacterVisible(F.char or LP.Character, true)
        if not keepSelection then currentSkinName = nil end
    end

    function F.applySkin(name)
        if applying then return end
        local config = skinConfigs[name]
        if not config then skinStatus("unknown skin " .. tostring(name), true) return end
        local character = F.char or LP.Character
        local root = character and character:FindFirstChild("HumanoidRootPart")
        if not character or not root then skinStatus("character is not ready", true) return end

        applying = true
        skinStatus("loading " .. name, false)
        local template, err = loadTemplate(name, config.assetId)
        if not template then applying = false; skinStatus(name .. ": " .. tostring(err), true) return end

        F.clearSkin(true)
        local clone = template:Clone()
        clone.Name = "VOMAGLA_Skin_" .. name
        local okScale, scaleError = pcall(function() clone:ScaleTo(config.scale or 1) end)
        if not okScale then warn("[VOMAGLA ModelChanger] ScaleTo: " .. tostring(scaleError)) end
        clone.Parent = Svc.WS
        setCharacterVisible(character, false)
        currentModel = clone
        currentSkinName = name
        S.Skin.Selected = name
        applying = false
        skinStatus(name .. " applied", false)
    end

    function F.applyCustomSkin(rawId)
        local id = tonumber(rawId)
        if not id then skinStatus("invalid custom asset ID", true) return end
        if templateCache.Custom then pcall(function() templateCache.Custom:Destroy() end) end
        templateCache.Custom = nil
        skinConfigs.Custom = { assetId = id, scale = 1, yOffset = 0 }
        F.applySkin("Custom")
    end

    function F.setSkinScale(value)
        if not currentSkinName or not skinConfigs[currentSkinName] then return end
        skinConfigs[currentSkinName].scale = value
        if currentModel then pcall(function() currentModel:ScaleTo(value) end) end
    end

    function F.setSkinYOffset(value)
        if not currentSkinName or not skinConfigs[currentSkinName] then return end
        skinConfigs[currentSkinName].yOffset = value
    end

    function F.updateSkinModel()
        if not currentModel then return end
        local character = F.char or LP.Character
        local root = character and character:FindFirstChild("HumanoidRootPart")
        local config = currentSkinName and skinConfigs[currentSkinName]
        if not root or not config or not currentModel.Parent then
            F.clearSkin(true)
            return
        end
        pcall(function()
            currentModel:PivotTo(root.CFrame * CFrame.new(0, config.yOffset or 0, 0))
        end)
    end

    function F.setSpinnerEnabled(enabled)
        S.Spinner.Enabled = enabled
        local hum = F.hum or (F.char and F.char:FindFirstChildWhichIsA("Humanoid"))
        if hum then hum.AutoRotate = not enabled end
    end

    function F.spinnerStep(dt)
        if not S.Spinner.Enabled then return end
        local char = F.char
        local root = char and char:FindFirstChild("HumanoidRootPart")
        local hum = F.hum
        if not root or not hum or hum.Health <= 0 then return end
        hum.AutoRotate = false
        root.CFrame = root.CFrame * CFrame.Angles(0, mathRad(S.Spinner.Speed * dt), 0)
    end

    function F.cleanupModelChanger()
        F.setSpinnerEnabled(false)
        F.clearSkin(false)
        for _, template in pairs(templateCache) do pcall(function() template:Destroy() end) end
        table.clear(templateCache)
    end

    F.trackConn(LP.CharacterAdded:Connect(function()
        local reapply = currentSkinName
        originalVisuals = setmetatable({}, { __mode = "k" })
        if reapply then task_delay(0.8, function()
            if not S.Unloaded then F.applySkin(reapply) end
        end) end
    end))

    getgenv().ApplySkin = F.applySkin
    getgenv().ApplyCustomSkin = F.applyCustomSkin
    getgenv().ClearSkin = F.clearSkin
end

do
    local StellarHubMenu = (function()
        local s, r = pcall(function()
            return loadstring(game:HttpGet("https://raw.githubusercontent.com/ImNotFatBitch/uimenu/main/StellarhubMenu"))()
        end)
        return s and r
    end)()
    local Settings = (function()
        local s, r = pcall(function()
            return loadstring(game:HttpGet("https://raw.githubusercontent.com/ImNotFatBitch/uimenu/main/StellarhubSettings"))()
        end)
        return s and r
    end)()
    if not StellarHubMenu or not Settings then return end

    F.Notify = function(msg, dur)
        pcall(function() Settings:Notify(msg, dur) end)
    end

    local Window = StellarHubMenu:Create({
        Title = 'vomagla crack by @nullwavve', Size = UDim2.new(0, 700, 0, 550),
        Position = UDim2.new(0.5, 0, 0.5, 0), ShowOnCreate = true, PerformanceMode = false,
        TweenSpeed = 0.3, UnloadTotal = true, PlayerListEnabled = false,
        WatermarkEnabled = true, WatermarkText = 'vomagla crack by @nullwavve',
        CanChangeTitleWatermark = true, ObfuscateConfig = false,
        MobileLogo = 'rbxassetid://14768967526',
    })

    local Tabs = {
        Combat = Window:AddTab('Combat'),
        Visual = Window:AddTab('Visual'),
        VisualIOS = Window:AddTab('VISUAL IOS'),
        ModelChanger = Window:AddTab('MODEL CHANGER'),
        Player = Window:AddTab('Player'),
    }
    Settings:InitializeSettingsTab(Window, 'VomaglaConfig', 'Config')

    do
        local SABox = Tabs.Combat:AddLeftGroupbox('Silent Aim')
        SABox:AddToggle('SA_Enabled_PW', { Text = 'Silent Aim', Default = false,
            Callback = function(v) S.SA.Enabled = v end })
            :AddKeybind('SA_Key_PW', { Default = 'P', Mode = 'Toggle', Title = 'Keybind' })
        SABox:AddDropdown('SA_TargetPart_PW', { Values = { "HeadHitbox", "Head", "HumanoidRootPart" },
            Default = 1, Multi = false, Text = 'Target Part',
            Callback = function(v) S.SA.TargetPart = v end })
        SABox:AddToggle('SA_UseFOV_PW', { Text = 'Use FOV Filter', Default = true,
            Callback = function(v) S.SA.UseFOV = v end })
        SABox:AddToggle('SA_Manip_PW', { Text = 'Включи если не регает', Default = false,
            Callback = function(v) S.Manipulation = v end })
        SABox:AddToggle('SA_VisibleCheck_PW', { Text = 'Wall Check', Default = true,
            Callback = function(v) S.SA.VisibleCheck = v end })
        SABox:AddSlider('SA_FOVRadius_PW', { Text = 'FOV Radius', Default = 200, Min = 10, Max = 500,
            Rounding = 0, Callback = function(v) S.SA.FOVRadius = v end })
        SABox:AddSlider('SA_MaxDistance_PW', { Text = 'Max Distance', Default = 500, Min = 50, Max = 3000,
            Rounding = 0, Callback = function(v) S.SA.MaxDistance = v end })
        SABox:AddSlider('SA_HitChance_PW', { Text = 'Hit Chance %', Default = 100, Min = 0, Max = 100,
            Rounding = 0, Callback = function(v) S.SA.HitChance = v end })
        SABox:AddToggle('SA_ShowFOV_PW', { Text = 'Show FOV Circle', Default = true,
            Callback = function(v) S.SA.ShowFOV = v end })

        local AutoBox = Tabs.Combat:AddLeftGroupbox('Auto Fire')
        AutoBox:AddToggle('AutoFireToggle', { Text = 'Auto Fire', Default = false,
            Callback = function(v) S.AutoFire.Enabled = v end })
        AutoBox:AddSlider('AutoFireDelay', { Text = 'Fire Delay', Default = 0.05, Min = 0.01, Max = 0.5,
            Rounding = 2, Callback = function(v) S.AutoFire.Delay = v end })

        local IC = Tabs.Combat:AddLeftGroupbox('Inventory Checker')
        IC:AddToggle('FOVInventoryChecker', { Text = 'Show Target Inventory', Default = false,
            Callback = function(v) S.Inspector.Enabled = v end })
        IC:AddLabel('Uses Silent Aim FOV target')
        IC:AddLabel('Window is draggable')

        local HB = Tabs.Combat:AddRightGroupbox('Hitbox Expander')
        HB:AddToggle('HitboxEnabled', { Text = 'Expand Hitboxes', Default = false, Callback = function(v)
            S.Hitbox.Enabled = v
            if v then
                F.InitHitboxWatchers()
            else
                F.RestoreAllHitboxes()
            end
        end })
        HB:AddSlider('HitboxSize', { Text = 'Hitbox Size Multiplier', Default = 5, Min = 5, Max = 20.5,
            Rounding = 1, Callback = function(v) S.Hitbox.Size = v; F.UpdateAllHitboxes() end })
        HB:AddSlider('HitboxTransparency', { Text = 'Hitbox Transparency', Default = 0.2, Min = 0, Max = 1,
            Rounding = 2, Callback = function(v) S.Hitbox.Transparency = v; F.ApplyHitboxVisuals() end })
        HB:AddLabel('Hitbox Color'):AddColorPicker('HitboxColor', {
            Default = Color3.fromRGB(255, 0, 0), Title = 'Color',
            Callback = function(v) S.Hitbox.Color = v; F.ApplyHitboxVisuals() end })

        local GM = Tabs.Combat:AddRightGroupbox('Gun Mods')
        local recoilMod = nil
        GM:AddToggle('NoRecoil', { Text = 'No Recoil', Default = false, Callback = function(v)
            if v then
                if not recoilMod then
                    pcall(function()
                        recoilMod = require(Svc.RS:WaitForChild("Gun"):WaitForChild("Scripts"):WaitForChild("RecoilHandler"))
                    end)
                end
                if recoilMod then
                    if not recoilMod._o_nS then recoilMod._o_nS = recoilMod.nextStep end
                    if not recoilMod._o_sRM then recoilMod._o_sRM = recoilMod.setRecoilMultiplier end
                    recoilMod.nextStep = function() end
                    recoilMod.setRecoilMultiplier = function() end
                end
            elseif recoilMod then
                if recoilMod._o_nS then recoilMod.nextStep = recoilMod._o_nS; recoilMod._o_nS = nil end
                if recoilMod._o_sRM then recoilMod.setRecoilMultiplier = recoilMod._o_sRM; recoilMod._o_sRM = nil end
            end
        end })
        GM:AddToggle('RapidFireT', { Text = 'Rapid Fire', Default = false,
            Callback = function(v) S.Guns.RapidFire = v end })
        GM:AddSlider('RapidFireSpeed', { Text = 'Rapid Fire Speed', Default = 0.02, Min = 0.01, Max = 0.5,
            Rounding = 2, Callback = function(v) S.Guns.RapidSpeed = v end })
        GM:AddToggle('FullAutoT', { Text = 'Full Auto', Default = false,
            Callback = function(v) S.Guns.FullAuto = v end })

        local MM = Tabs.Combat:AddRightGroupbox('Melee Mods')
        MM:AddToggle('MeleeModsT', { Text = 'Melee Mods', Default = false,
            Callback = function(v) S.Guns.MeleeMods = v end })
        MM:AddSlider('MeleeSwingSpeed', { Text = 'Swing Speed', Default = 0.05, Min = 0.01, Max = 0.5,
            Rounding = 2, Callback = function(v) S.Guns.MeleeSpeed = v end })
        MM:AddSlider('MeleeSwingRange', { Text = 'Range', Default = 5, Min = 5, Max = 30,
            Rounding = 0, Callback = function(v) S.Guns.MeleeRange = v end })

        local RC = Tabs.Combat:AddRightGroupbox('Resource Critical')
        RC:AddToggle('OneHitOre', { Text = 'One Hit Ore', Default = false, Callback = function(v)
            S.ResourceCrit.Ore = v
            if v then F.armResourceCrit() end
        end })
        RC:AddToggle('OneHitTree', { Text = 'One Hit Tree', Default = false, Callback = function(v)
            S.ResourceCrit.Tree = v
            if v then F.armResourceCrit() end
        end })
        RC:AddSlider('ResourceCritRange', { Text = 'Critical Range', Default = 20, Min = 5, Max = 30,
            Rounding = 0, Callback = function(v) S.ResourceCrit.Range = v end })
    end

    do
        local EB = Tabs.Visual:AddLeftGroupbox('ESP Settings')
        EB:AddToggle('ESPEnabled', { Text = 'Master Switch', Default = false, Callback = function(v) S.ESP.Enabled = v end })
        EB:AddToggle('ESPBox', { Text = 'Box', Default = false, Callback = function(v) S.ESP.Box = v end })
            :AddColorPicker('BoxColor', { Default = S.ESPColors.Box1, Title = 'Color',
                Callback = function(v) S.ESPColors.Box1 = v end })
        EB:AddToggle('ESPChams', { Text = 'Chams (Green=Visible)', Default = false,
            Callback = function(v) S.ESP.Chams = v end })
        EB:AddToggle('ESPName', { Text = 'Name', Default = false, Callback = function(v) S.ESP.Name = v end })
        EB:AddToggle('ESPDistance', { Text = 'Distance', Default = false, Callback = function(v) S.ESP.Distance = v end })
        EB:AddToggle('ESPWeapon', { Text = 'Weapon (Held Item)', Default = false, Callback = function(v) S.ESP.Weapon = v end })
        EB:AddToggle('ESPHealthBar', { Text = 'Health Bar', Default = false, Callback = function(v) S.ESP.HealthBar = v end })

        local VO = Tabs.Visual:AddRightGroupbox('Features')
        VO:AddToggle('TargetHUDToggle', { Text = 'Target HUD', Default = false,
            Callback = function(v) S.ESP.TargetHUD = v end })
        VO:AddToggle('ReloadIndicatorT', { Text = 'Reload Indicator', Default = false,
            Callback = function(v) S.Reload.Enabled = v end })
        VO:AddToggle('KillNotify', { Text = 'Global Kill Notify', Default = false,
            Callback = function(v) S.KillNotify = v end })
        VO:AddToggle('DeleteSpikes', { Text = 'Delete Spikes', Default = false,
            Callback = function(v) F.toggleSpikes(v) end })
        VO:AddToggle('DeleteLeaves', { Text = 'Delete Leaves', Default = false,
            Callback = function(v) F.toggleLeaves(v) end })
        VO:AddToggle('ToolHighlight', { Text = 'Tool Outline', Default = false,
            Callback = function(v) S.ToolHL.Enabled = v; F.setupToolHL() end })
            :AddColorPicker('ToolHighlightColor', { Default = Color3.new(1, 1, 1), Title = 'Outline Color',
                Callback = function(v) S.ToolHL.Color = v; F.setToolHLColor(v) end })
        VO:AddToggle('FOVChangerToggle', { Text = 'FOV Changer', Default = false,
            Callback = function(v) S.FOVCam.Enabled = v end })
        VO:AddSlider('FOVChangerValue', { Text = 'FOV Value', Min = 50, Max = 120, Default = 70,
            Rounding = 0, Callback = function(v) S.FOVCam.Value = v end })
        VO:AddToggle('ThirdPersonToggle', { Text = 'Third Person', Default = false,
            Callback = function(v) S.ThirdPerson.Enabled = v end })
        VO:AddSlider('ThirdPersonDistance', { Text = 'Camera Distance', Min = 5, Max = 50, Default = 10,
            Rounding = 0, Callback = function(v) S.ThirdPerson.Distance = v end })
        VO:AddToggle('JumpCircles', { Text = 'Jump Circles', Default = false,
            Callback = function(v) S.JumpCircle.Enabled = v end })
            :AddColorPicker('JumpCircleColor', { Default = Color3.fromRGB(0, 170, 255), Title = 'Circle Color',
                Callback = function(v) S.JumpCircle.Color = v end })
        VO:AddToggle('XRay', { Text = 'X-Ray', Default = false, Callback = function(v)
            S.XRay.Enabled = v
            F.setXrayState(v, S.XRay.Transparency)
        end }):AddKeybind('XRayKey', { Default = 'X', Mode = 'Toggle', Title = 'Key' })
        VO:AddSlider('XRayTrans', { Text = 'XRay Transparency', Default = 0.5, Min = 0, Max = 1,
            Rounding = 2, Callback = function(v)
                S.XRay.Transparency = v
                if S.XRay.Enabled then F.setXrayState(true, v) end
            end })
    end

    do
        local IOS = Tabs.VisualIOS:AddLeftGroupbox('iOS ESP')
        IOS:AddToggle('IOSESPEnabled', { Text = 'Master Switch', Default = false,
            Callback = function(v) S.IOS.Enabled = v end })
        IOS:AddToggle('IOSESPBox', { Text = 'Box', Default = false,
            Callback = function(v) S.IOS.Box = v end })
            :AddColorPicker('IOSESPBoxColor', { Default = S.IOSColors.Box, Title = 'Box Color',
                Callback = function(v) S.IOSColors.Box = v end })
        IOS:AddToggle('IOSESPName', { Text = 'Name', Default = false,
            Callback = function(v) S.IOS.Name = v end })
            :AddColorPicker('IOSESPNameColor', { Default = S.IOSColors.Name, Title = 'Name Color',
                Callback = function(v) S.IOSColors.Name = v end })
        IOS:AddToggle('IOSESPDistance', { Text = 'Distance', Default = false,
            Callback = function(v) S.IOS.Distance = v end })
            :AddColorPicker('IOSESPDistanceColor', { Default = S.IOSColors.Distance, Title = 'Distance Color',
                Callback = function(v) S.IOSColors.Distance = v end })
        IOS:AddToggle('IOSESPWeapon', { Text = 'Weapon', Default = false,
            Callback = function(v) S.IOS.Weapon = v end })
        IOS:AddToggle('IOSESPHealth', { Text = 'Health Bar', Default = false,
            Callback = function(v) S.IOS.HealthBar = v end })
        IOS:AddToggle('IOSESPChams', { Text = 'Chams', Default = false,
            Callback = function(v) S.IOS.Chams = v end })
        IOS:AddSlider('IOSESPDistanceLimit', { Text = 'Max Distance', Default = 1500,
            Min = 100, Max = 5000, Rounding = 0,
            Callback = function(v) S.IOS.MaxDistance = v end })
        IOS:AddSlider('IOSESPBoxWidth', { Text = 'Fixed Box Width', Default = 34,
            Min = 16, Max = 80, Rounding = 0,
            Callback = function(v) S.IOS.BoxWidth = v end })
        IOS:AddSlider('IOSESPBoxHeight', { Text = 'Fixed Box Height', Default = 52,
            Min = 24, Max = 120, Rounding = 0,
            Callback = function(v) S.IOS.BoxHeight = v end })

        local IOSCH = Tabs.VisualIOS:AddRightGroupbox('iOS Chams Colors')
        IOSCH:AddLabel('Visible Color'):AddColorPicker('IOSVisibleColor', {
            Default = S.IOSColors.Visible, Title = 'Visible',
            Callback = function(v) S.IOSColors.Visible = v end })
        IOSCH:AddLabel('Hidden Color'):AddColorPicker('IOSHiddenColor', {
            Default = S.IOSColors.Hidden, Title = 'Hidden',
            Callback = function(v) S.IOSColors.Hidden = v end })
        IOSCH:AddLabel('Native Instance ESP')
        IOSCH:AddLabel('No Drawing API / CoreGui required')
    end


    do
        local SG = Tabs.Visual:AddRightGroupbox('Stretch Resolution')
        SG:AddToggle('StretchToggle', { Text = 'Stretch Enabled', Default = false,
            Callback = function(v) S.Stretch.Enabled = v end })
        SG:AddSlider('StretchValue', { Text = 'Stretch Amount', Default = 0.65, Min = 0.3, Max = 1.0,
            Rounding = 2, Callback = function(v) S.Stretch.Value = v end })

        local BT = Tabs.Visual:AddRightGroupbox('Bullet Tracers')
        BT:AddToggle('BulletTrace', { Text = 'Enabled', Default = false,
            Callback = function(v) S.Tracers.Enabled = v end })
        BT:AddDropdown('BulletTracersTexture', {
            Values = { "Beam", "Lightning", "Heartrate", "Chain", "Glitch", "Swirl" },
            Default = 1, Multi = false, Text = 'Texture',
            Callback = function(V)
                local m = { Beam = "rbxassetid://12781852245", Lightning = "rbxassetid://446111271",
                    Heartrate = "rbxassetid://5830549480", Chain = "rbxassetid://9632168658",
                    Glitch = "rbxassetid://8089467613", Swirl = "rbxassetid://5638168605" }
                S.Tracers.TextureID = m[V] or m.Beam
            end })
        BT:AddSlider('TracerWidth', { Text = 'Width', Min = 0.1, Max = 5, Default = 1.5,
            Rounding = 1, Callback = function(v) S.Tracers.Width = v end })
        BT:AddSlider('TracerTransparency', { Text = 'Transparency', Min = 0, Max = 1, Default = 0,
            Rounding = 2, Callback = function(v) S.Tracers.Transparency = v end })
        BT:AddSlider('TracerLifeTime', { Text = 'Life Time', Min = 0.1, Max = 3, Default = 0.5,
            Rounding = 1, Callback = function(v) S.Tracers.LifeTime = v end })
    end

    do
        local HFX = Tabs.Visual:AddLeftGroupbox('Hit Effects (Particles)')
        HFX:AddToggle('DamageFXEnabled', { Text = 'Damage Particles', Default = false,
            Callback = function(v) S.DamageFX.Enabled = v end })
        HFX:AddDropdown('DamageFXStyle', { Values = { "Foam", "Crescents", "Residue", "Electric" },
            Default = 1, Multi = false, Text = 'Style',
            Callback = function(v) S.DamageFX.Style = v end })
        HFX:AddSlider('DamageFXCount', { Text = 'Count (all styles)', Default = 12, Min = 1, Max = 60,
            Rounding = 0, Callback = function(v) S.DamageFX.Count = v end })
        HFX:AddSlider('DamageFXSpeed', { Text = 'Speed (all styles)', Default = 20, Min = 5, Max = 60,
            Rounding = 0, Callback = function(v) S.DamageFX.Speed = v end })
        HFX:AddSlider('DamageFXSize', { Text = 'Size (all styles)', Default = 0.25, Min = 0.05, Max = 1.5,
            Rounding = 2, Callback = function(v) S.DamageFX.Size = v end })
        HFX:AddSlider('DamageFXLifetime', { Text = 'Lifetime (all styles)', Default = 0.8, Min = 0.2, Max = 4,
            Rounding = 2, Callback = function(v) S.DamageFX.Lifetime = v end })
        HFX:AddToggle('DamageFXRainbow', { Text = 'Rainbow (all styles)', Default = false,
            Callback = function(v) S.DamageFX.Rainbow = v end })
        HFX:AddLabel('Particle Color'):AddColorPicker('DamageFXColor', {
            Default = Color3.fromRGB(255, 60, 60), Title = 'Color',
            Callback = function(v) S.DamageFX.Color = v end })
    end

    do
        local HLB = Tabs.Visual:AddLeftGroupbox('Hit Logs')
        HLB:AddToggle('HitLogsEnabled', { Text = 'Enabled', Default = false,
            Callback = function(v) S.HL.Enabled = v end })
        HLB:AddDropdown('HitLogsPos', { Values = { "Center", "Left", "Top", "LeftTop" },
            Default = 1, Multi = false, Text = 'Position',
            Callback = function(v) S.HL.Position = v; F.setHLPos() end })
        HLB:AddSlider('HitLogsDuration', { Text = 'Duration', Default = 5, Min = 1, Max = 15,
            Rounding = 0, Callback = function(v) S.HL.Duration = v end })
        HLB:AddLabel('Log Color'):AddColorPicker('HitLogsColor', {
            Default = Color3.fromRGB(176, 176, 209), Title = 'Color',
            Callback = function(v) S.HL.Color = v end })

        local HMB = Tabs.Visual:AddLeftGroupbox('Hitmarker')
        HMB:AddToggle('HitMarkerEnabled', { Text = 'Enabled', Default = false,
            Callback = function(v) S.HM.Enabled = v end })
        HMB:AddSlider('HMSize', { Text = 'Size', Default = 12, Min = 5, Max = 40,
            Rounding = 0, Callback = function(v) S.HM.Size = v end })
        HMB:AddSlider('HMThickness', { Text = 'Thickness', Default = 2, Min = 1, Max = 5,
            Rounding = 1, Callback = function(v) S.HM.Thickness = v end })
        HMB:AddSlider('HMDuration', { Text = 'Duration', Default = 2.5, Min = 0.5, Max = 6,
            Rounding = 1, Callback = function(v) S.HM.Duration = v end })
        HMB:AddLabel('Hit Color'):AddColorPicker('HMColor', {
            Default = Color3.new(1, 1, 1), Title = 'Color',
            Callback = function(v) S.HM.Color = v end })
        HMB:AddLabel('Kill Color'):AddColorPicker('HMKillColor', {
            Default = Color3.fromRGB(220, 80, 80), Title = 'Color',
            Callback = function(v) S.HM.KillColor = v end })

        local CHB = Tabs.Visual:AddLeftGroupbox('Crosshair')
        CHB:AddToggle('CrosshairEnabled', { Text = 'Enabled', Default = false,
            Callback = function(v) S.CH.Enabled = v end })
        CHB:AddToggle('CrosshairRainbow', { Text = 'Rainbow', Default = false,
            Callback = function(v) S.CH.Rainbow = v end })
        CHB:AddToggle('CrosshairDot', { Text = 'Dot', Default = false,
            Callback = function(v) S.CH.Dot = v end })
        CHB:AddToggle('CrosshairPulse', { Text = 'Pulse', Default = false,
            Callback = function(v) S.CH.Pulse = v end })
        CHB:AddSlider('CHPulseSpeed', { Text = 'Pulse Speed', Default = 3, Min = 0.5, Max = 10,
            Rounding = 1, Callback = function(v) S.CH.PulseSpeed = v end })
        CHB:AddToggle('CrosshairAimPoint', { Text = 'Follow Aim Point', Default = false,
            Callback = function(v) S.CH.FollowAimPoint = v end })
        CHB:AddToggle('CrosshairFollow', { Text = 'Follow Target', Default = false,
            Callback = function(v) S.CH.FollowTarget = v end })
        CHB:AddSlider('CHFollowSmooth', { Text = 'Follow Smoothness', Default = 8, Min = 1, Max = 20,
            Rounding = 0, Callback = function(v) S.CH.FollowSmooth = v end })
        CHB:AddSlider('CHLength', { Text = 'Length', Default = 8, Min = 2, Max = 40,
            Rounding = 0, Callback = function(v) S.CH.Length = v end })
        CHB:AddSlider('CHGap', { Text = 'Gap', Default = 4, Min = 0, Max = 25,
            Rounding = 0, Callback = function(v) S.CH.Gap = v end })
        CHB:AddSlider('CHRotation', { Text = 'Rotation Speed', Default = 0, Min = -360, Max = 360,
            Rounding = 0, Callback = function(v) S.CH.RotationSpeed = v end })
        CHB:AddSlider('CHThickness', { Text = 'Thickness', Default = 1.5, Min = 0.5, Max = 5,
            Rounding = 1, Callback = function(v) S.CH.Thickness = v end })
        CHB:AddLabel('Crosshair Color'):AddColorPicker('CrosshairColor', {
            Default = Color3.new(1, 1, 1), Title = 'Color',
            Callback = function(v) S.CH.Color = v end })
    end

    do
        local WV = Tabs.Visual:AddLeftGroupbox('World Visuals')
        WV:AddToggle('Fullbright', { Text = 'Fullbright', Default = false,
            Callback = function(v) F.toggleFB(v) end })
        WV:AddToggle('NoDecoration', { Text = 'No Decoration', Default = false, Callback = function(v)
            S.NoDecoration = v
            pcall(function()
                local t = Svc.WS:FindFirstChildOfClass("Terrain")
                if t and sethiddenproperty then sethiddenproperty(t, "Decoration", not v) end
            end)
        end })

        local WB = Tabs.Visual:AddLeftGroupbox('Water Settings')
        WB:AddToggle('WaterEnabled', { Text = 'Custom Water', Default = false,
            Callback = function(v) S.Water.Enabled = v; F.applyWater() end })
        WB:AddLabel('Water Color'):AddColorPicker('WaterColorPicker', {
            Default = Color3.fromRGB(128, 128, 128), Title = 'Color',
            Callback = function(v) S.Water.Color = v; if S.Water.Enabled then F.applyWater() end end })
        WB:AddSlider('WaterReflectance', { Text = 'Reflectance', Default = 0.3, Min = 0, Max = 1,
            Rounding = 2, Callback = function(v)
                S.Water.Reflectance = v
                if S.Water.Enabled then F.applyWater() end
            end })

        WV:AddToggle('SkyColorToggle', { Text = 'Sky Color', Default = false,
            Callback = function(v) F.toggleSkyColor(v) end })
            :AddColorPicker('SkyColorPicker', { Default = Color3.fromRGB(135, 200, 255), Title = 'Sky Color',
                Callback = function(v) F.setSkyColor(v) end })

        local SkyData = {
            ["Blue Sky"]   = { 591058823, 591059876, 591058104, 591057861, 591057625, 591059642 },
            ["Vaporwave"]  = { 1417494030, 1417494146, 1417494253, 1417494402, 1417494499, 1417494643 },
            ["Redshift"]   = { 401664839, 401664862, 401664960, 401664881, 401664901, 401664936 },
            ["Blaze"]      = { 150939022, 150939038, 150939047, 150939056, 150939063, 150939082 },
            ["Among Us"]   = { 5752463190, 5752463190, 5752463190, 5752463190, 5752463190, 5752463190 },
            ["Dark Night"] = { 6285719338, 6285721078, 6285722964, 6285724682, 6285726335, 6285730635 },
            ["Bright Pink"] = { 271042516, 271077243, 271042556, 271042310, 271042467, 271077958 },
            ["Purple Sky"] = { 570557514, 570557775, 570557559, 570557620, 570557672, 570557727 },
            ["Galaxy"]     = { 15125283003, 15125281008, 15125277539, 15125279325, 15125274388, 15125275800 },
            ["Pinky Sky"]  = { 11427769401, 11427770685, 11427769401, 11427769401, 11427769401, 11427771954 },
            ["Sky 2"]      = { 17279854976, 17279856318, 17279858447, 17279860360, 17279862234, 17279864507 },
            ["Sky 3"]      = { 12064107, 12064152, 12064121, 12063984, 12064115, 12064131 },
        }
        local skyNames = { "Default", "Blue Sky", "Vaporwave", "Redshift", "Blaze", "Among Us",
            "Dark Night", "Bright Pink", "Purple Sky", "Galaxy", "Pinky Sky", "Sky 2", "Sky 3" }
        WV:AddDropdown('SkyboxChanger', { Values = skyNames, Default = 1, Multi = false, Text = 'Skybox',
            Callback = function(v)
                local sky = Svc.Light:FindFirstChildOfClass("Sky")
                if v == "Default" then
                    if sky then sky:Destroy() end
                elseif SkyData[v] then
                    if not sky then sky = Instance.new("Sky"); sky.Parent = Svc.Light end
                    local d = SkyData[v]
                    sky.SkyboxBk = "rbxassetid://" .. d[1]
                    sky.SkyboxDn = "rbxassetid://" .. d[2]
                    sky.SkyboxFt = "rbxassetid://" .. d[3]
                    sky.SkyboxLf = "rbxassetid://" .. d[4]
                    sky.SkyboxRt = "rbxassetid://" .. d[5]
                    sky.SkyboxUp = "rbxassetid://" .. d[6]
                end
            end })

        local HSB = Tabs.Visual:AddLeftGroupbox('Hit Sounds')
        HSB:AddToggle('HitSoundEnabled', { Text = 'Hit Sound Enabled', Default = false, Callback = function(v)
            S.HitSound.Enabled = v
            if v then
                if LP.Character then F.applyHSChar(LP.Character) end
            else
                F.restoreHS()
            end
        end })
        HSB:AddDropdown('HitSoundChoice', { Values = F.HSNames, Default = 1, Multi = false, Text = 'Sound',
            Callback = function(v)
                S.HitSound.Choice = v
                if S.HitSound.Enabled and LP.Character then F.applyHSChar(LP.Character) end
            end })
        HSB:AddSlider('HitSoundVolume', { Text = 'Volume', Min = 0, Max = 10, Default = 1,
            Rounding = 1, Callback = function(v)
                S.HitSound.Volume = v
                if S.HitSound.Enabled and LP.Character then F.applyHSChar(LP.Character) end
            end })
        HSB:AddToggle('KillSoundT', { Text = 'Kill Sound (Double Kill)', Default = false,
            Callback = function(v) S.KillSound.Enabled = v end })
        HSB:AddSlider('KillVolumeS', { Text = 'Kill Volume', Default = 1, Min = 0, Max = 5,
            Rounding = 1, Callback = function(v) S.KillSound.Volume = v end })
    end

    do
        local modelChoices = {
            "Select Model", "Default Character", "Floppa", "Minecraft Villager", "Cat", "Drone",
            "Tung Tung Sahur", "Freddy Fazbear", "Maxwell the Cat", "Furry",
        }
        local MC = Tabs.ModelChanger:AddLeftGroupbox('Character Models')
        MC:AddDropdown('ModelSkinSelect', { Values = modelChoices, Default = 1, Multi = false,
            Text = 'Model', Callback = function(v)
                if v == "Default Character" then
                    F.clearSkin(false)
                elseif v ~= "Select Model" then
                    S.Skin.Selected = v
                    task_defer(F.applySkin, v)
                end
            end })
        MC:AddSlider('ModelScale', { Text = 'Model Scale', Default = 1, Min = 0.1, Max = 3,
            Rounding = 2, Callback = function(v) F.setSkinScale(v) end })
        MC:AddSlider('ModelYOffset', { Text = 'Y Offset', Default = 0, Min = -5, Max = 5,
            Rounding = 2, Callback = function(v) F.setSkinYOffset(v) end })

        local CUSTOM_OK = pcall(function()
            MC:AddInput('CustomModelAssetID', { Default = '', Numeric = true, Finished = true,
                Text = 'Custom Asset ID', Placeholder = 'enter ID and press Enter', Callback = function(v)
                    local value = tostring(v or '')
                    S.Skin.CustomID = value
                    if value ~= "" and tonumber(value) then task_defer(F.applyCustomSkin, value) end
                end })
        end)
        if not CUSTOM_OK then
            MC:AddLabel('Custom ID: getgenv().ApplyCustomSkin(ID)')
        end
        MC:AddLabel('Selecting a model applies it immediately')

        local SPIN = Tabs.ModelChanger:AddRightGroupbox('Character Spinner')
        SPIN:AddToggle('CharacterSpinner', { Text = 'Spin Character', Default = false,
            Callback = function(v) F.setSpinnerEnabled(v) end })
            :AddKeybind('CharacterSpinnerKey', { Default = 'B', Mode = 'Toggle', Title = 'Spinner Key' })
        SPIN:AddSlider('CharacterSpinnerSpeed', { Text = 'Spin Speed (deg/s)', Default = 180,
            Min = 10, Max = 1440, Rounding = 0, Callback = function(v) S.Spinner.Speed = v end })
        SPIN:AddLabel('Local visual character replacement')
        SPIN:AddLabel('Models automatically follow movement')
    end

    do
        local MB = Tabs.Player:AddLeftGroupbox('Movement')
        MB:AddToggle('SpeedEnabled', { Text = 'Speed', Default = false,
            Callback = function(v) S.Speed.Enabled = v end })
            :AddKeybind('SpeedKey', { Default = 'G', Mode = 'Toggle', Title = 'Speed Key' })
        MB:AddSlider('SpeedValue', { Text = 'Speed Value', Min = 0, Max = 60, Default = 30,
            Rounding = 0, Callback = function(v) S.Speed.Value = v end })
        MB:AddToggle('CopterSpeedEnabled', { Text = 'Copter Speed (Sit)', Default = false,
            Callback = function(v) S.CopterSpeed.Enabled = v end })
            :AddKeybind('CopterSpeedKey', { Default = 'U', Mode = 'Toggle', Title = 'Copter Speed Key' })
        MB:AddSlider('CopterSpeedValue', { Text = 'Copter Speed Value', Min = 20, Max = 100, Default = 50,
            Rounding = 0, Callback = function(v) S.CopterSpeed.Value = v end })
        MB:AddToggle('WaterSpeed', { Text = 'Swim Speed', Default = false,
            Callback = function(v) S.WaterSpeed.Enabled = v end })
            :AddKeybind('WaterSpeedKey', { Default = 'C', Mode = 'Toggle', Title = 'Water Speed' })
        MB:AddSlider('SwimSpeedVal', { Text = 'Water Speed Value', Min = 20, Max = 200, Default = 50,
            Rounding = 0, Callback = function(v) S.WaterSpeed.Value = v end })
        MB:AddToggle('NoFallDamage', { Text = 'No Fall Damage', Default = false,
            Callback = function(v) F.toggleNoFall(v) end })
        MB:AddToggle('NoJumpDelay', { Text = 'No Jump Delay', Default = false, Callback = function(v)
            S.NoJumpDelay.Enabled = v
            if S.NoJumpDelay.Conn then
                pcall(function() S.NoJumpDelay.Conn:Disconnect() end)
                S.NoJumpDelay.Conn = nil
            end
            if v then
                S.NoJumpDelay.Conn = Svc.UIS.JumpRequest:Connect(function()
                    if not S.NoJumpDelay.Enabled or S.Unloaded then return end
                    local now = tick()
                    if now - S.NoJumpDelay.LastJump < 0.1 then return end
                    S.NoJumpDelay.LastJump = now
                    local ch = F.char
                    if not ch then return end
                    local hum = ch:FindFirstChildWhichIsA("Humanoid")
                    if not hum or hum.Health <= 0 then return end
                    local st = hum:GetState()
                    if st ~= Enum.HumanoidStateType.Freefall and st ~= Enum.HumanoidStateType.Flying then
                        hum:ChangeState(Enum.HumanoidStateType.Jumping)
                    end
                end)
            end
        end })

        local CF = Tabs.Player:AddRightGroupbox('Copter Fly (SHIFT=UP, CTRL=DOWN)')
        CF:AddToggle('CopterFlyEnabled', { Text = 'Enable Copter Fly', Default = false, Callback = function(v)
            if v then
                F.Notify("сядьте на коптер (вертолет) и нажмите клавишу Z и вы будете летать.", 5)
                F.Notify("НА ТЕЛЕФОНЕ ФУНКЦИЯ НЕРАБОТАЕТ!", 5)
                F.toggleCopterFly()
            else
                F.disableCopterFly()
            end
        end }):AddKeybind('CopterFlyKey', { Default = 'Z', Mode = 'Toggle', Title = 'Toggle Key' })
        CF:AddSlider('CopterFlySpeed', { Text = 'Fly Speed', Default = 100, Min = 50, Max = 450,
            Rounding = 0, Callback = function(v) S.CopterFly.Speed = v end })

        local JS = Tabs.Player:AddLeftGroupbox('Super Jump')
        JS:AddToggle('JumpStunEnabled', { Text = 'Enable Super Jump', Default = false,
            Callback = function(v) S.JumpStun.Enabled = v end })
            :AddKeybind('JumpStunKey', { Default = 'H', Mode = 'Toggle', Title = 'Super Jump Key' })
        JS:AddSlider('JumpStunHeight', { Text = 'Jump Height', Default = 100, Min = 60, Max = 200,
            Rounding = 0, Callback = function(v) S.JumpStun.Height = v end })

        local SP = Tabs.Player:AddRightGroupbox('Spider')
        SP:AddToggle('SpiderEnabled', { Text = 'Spider Climb', Default = false,
            Callback = function(v) S.Spider.Enabled = v end })
            :AddKeybind('SpiderKey', { Default = 'V', Mode = 'Toggle', Title = 'Spider Key' })
        SP:AddSlider('SpiderSpeed', { Text = 'Climb Speed', Default = 50, Min = 20, Max = 150,
            Rounding = 0, Callback = function(v) S.Spider.Speed = v end })

        local lastSuper = 0
        F.trackConn(Svc.UIS.JumpRequest:Connect(function()
            if S.Unloaded or not S.JumpStun.Enabled then return end
            local now = tick()
            if now - lastSuper < 0.5 then return end
            lastSuper = now
            local r = F.char and F.char:FindFirstChild("HumanoidRootPart")
            if r then
                r.AssemblyLinearVelocity = Vector3New(
                    r.AssemblyLinearVelocity.X, S.JumpStun.Height, r.AssemblyLinearVelocity.Z)
            end
        end))

        F.doAutoFire = function()
            if mouse1click then
                mouse1click()
            else
                local s, vim = pcall(game.GetService, game, "VirtualInputManager")
                if s and vim then
                    vim:SendMouseButtonEvent(0, 0, 0, true, game, 0)
                    task_defer(function() vim:SendMouseButtonEvent(0, 0, 0, false, game, 0) end)
                end
            end
        end
    end

    do
        F.unload = function()
            S.Unloaded = true
            pcall(function() F.fovGui:Destroy() end)
            pcall(F.cleanupHitLogs)
            pcall(F.cleanupHitMarkers)
            pcall(F.cleanupCrosshair)
            pcall(F.cleanupHitboxes)
            pcall(F.cleanupWorldConns)
            pcall(F.cleanupInventoryInspector)
            pcall(F.cleanupModelChanger)
            pcall(F.cleanupToolHL)
            pcall(F.cleanupNoFall)
            pcall(F.cleanupHSChar)
            pcall(F.cleanupFB)
            pcall(F.cleanupSky)
            pcall(F.cleanupReload)
            pcall(F.cleanupResourceCrit)
            pcall(F.destroyAllTracers)
            pcall(F.restoreHS)
            pcall(function() F.setXrayState(false, 0) end)
            pcall(F.rmAllEsp)
            pcall(F.cleanupIOSESP)
            pcall(F.RestoreAllHitboxes)
            pcall(function()
                local ch = LP.Character
                if ch then
                    local hrp = ch:FindFirstChild("HumanoidRootPart")
                    if hrp then
                        local bv = hrp:FindFirstChild("WSV")
                        if bv then bv:Destroy() end
                    end
                end
            end)
            pcall(function() F.applyWater() end)
            pcall(function()
                if S.NoDecoration then
                    local t = Svc.WS:FindFirstChildOfClass("Terrain")
                    if t and sethiddenproperty then sethiddenproperty(t, "Decoration", true) end
                end
            end)
            pcall(function()
                local cam = Svc.WS.CurrentCamera
                if cam then cam.FieldOfView = 70 end
            end)
            pcall(F.disableCopterFly)
            for _, c in pairs(F.conns) do pcall(function() c:Disconnect() end) end
            F.conns = {}
        end

        Settings:OnUnload(function() F.unload() end)
        getgenv().__VOMAGLA_UNLOAD = function() F.unload() end
    end
end

do
    local HG = Instance.new("ScreenGui")
    HG.Name = "STHUD"
    HG.Parent = Svc.CoreGui
    HG.Enabled = false
    local MF = Instance.new("Frame")
    MF.Size = UDim2.new(0, 320, 0, 104)
    MF.AnchorPoint = Vector2.new(0.5, 0.5)
    MF.Position = UDim2.new(0.5, 0, 0.85, 0)
    MF.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    MF.BackgroundTransparency = 0.1
    MF.BorderSizePixel = 0
    MF.Parent = HG
    local AI = Instance.new("ImageLabel")
    AI.Size = UDim2.new(0, 60, 0, 60)
    AI.Position = UDim2.new(0, 15, 0, 15)
    AI.BackgroundTransparency = 1
    AI.Parent = MF
    local TC = Instance.new("Frame")
    TC.BackgroundTransparency = 1
    TC.Position = UDim2.new(0, 85, 0, 10)
    TC.Size = UDim2.new(1, -95, 0, 64)
    TC.Parent = MF
    local NL = Instance.new("TextLabel")
    NL.Size = UDim2.new(1, 0, 0, 25)
    NL.BackgroundTransparency = 1
    NL.Text = ""
    NL.Font = Enum.Font.GothamBold
    NL.TextSize = 20
    NL.TextColor3 = Color3.new(1, 1, 1)
    NL.TextXAlignment = Enum.TextXAlignment.Left
    NL.Parent = TC
    local DL = Instance.new("TextLabel")
    DL.Size = UDim2.new(1, 0, 0, 20)
    DL.Position = UDim2.new(0, 0, 0, 25)
    DL.BackgroundTransparency = 1
    DL.Text = ""
    DL.Font = Enum.Font.Gotham
    DL.TextSize = 16
    DL.TextColor3 = Color3.fromRGB(200, 200, 200)
    DL.TextXAlignment = Enum.TextXAlignment.Left
    DL.Parent = TC
    local WL = Instance.new("TextLabel")
    WL.Size = UDim2.new(1, 0, 0, 18)
    WL.Position = UDim2.new(0, 0, 0, 45)
    WL.BackgroundTransparency = 1
    WL.Text = ""
    WL.Font = Enum.Font.Gotham
    WL.TextSize = 14
    WL.TextColor3 = Color3.fromRGB(255, 200, 100)
    WL.TextXAlignment = Enum.TextXAlignment.Left
    WL.Parent = TC
    local HBG = Instance.new("Frame")
    HBG.Size = UDim2.new(1, -30, 0, 12)
    HBG.Position = UDim2.new(0, 15, 1, -20)
    HBG.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
    HBG.BorderSizePixel = 0
    HBG.Parent = MF
    local HBF = Instance.new("Frame")
    HBF.Size = UDim2.new(1, 0, 1, 0)
    HBF.BackgroundColor3 = Color3.new(1, 1, 1)
    HBF.BorderSizePixel = 0
    HBF.Parent = HBG
    Instance.new("UIGradient", HBF).Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 60, 150)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 230, 50))
    }

    local lastTH = 0
    function F.updTH(now)
        if not S.ESP.TargetHUD or not S.SA.Enabled or S.Unloaded then HG.Enabled = false return end
        if now - lastTH < 0.15 then return end
        lastTH = now
        local ch = F.targetPart and F.targetPart.Parent
        if ch and ch:FindFirstChild("Humanoid") and ch:FindFirstChild("HumanoidRootPart") and ch.Humanoid.Health > 0 then
            HG.Enabled = true
            local pl = Svc.Players:GetPlayerFromCharacter(ch)
            if pl then
                NL.Text = pl.DisplayName
                pcall(function()
                    AI.Image = Svc.Players:GetUserThumbnailAsync(pl.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size150x150)
                end)
                local held = ""
                for _, c in pairs(ch:GetChildren()) do
                    if c:IsA("Tool") then held = c.Name break end
                end
                if held == "" and pl:FindFirstChild("Backpack") then
                    for _, c in pairs(pl.Backpack:GetChildren()) do
                        if c:IsA("Tool") then held = c.Name break end
                    end
                end
                WL.Text = held ~= "" and ("Holding: " .. held) or ""
            else
                NL.Text = ch.Name
                AI.Image = ""
                WL.Text = ""
            end
            local mr = F.char and F.char:FindFirstChild("HumanoidRootPart")
            if mr then
                DL.Text = "Distance: " .. string_format("%.1f", (mr.Position - ch.HumanoidRootPart.Position).Magnitude) .. "m"
            end
            Svc.TS:Create(HBF, TweenInfo.new(0.15), {
                Size = UDim2.new(mathClamp(ch.Humanoid.Health / ch.Humanoid.MaxHealth, 0, 1), 0, 1, 0)
            }):Play()
        else
            HG.Enabled = false
        end
    end
end

do
    local lastHit = {}
    local dmgConns = {}
    local humHealth = {}

    local function isOurDamage(plr, char)
        if F.targetPart and F.targetPart.Parent == char then return true end
        if F.lastTargetPlayer == plr and (osClock() - F.lastTargetTime) < 2 then return true end
        local part = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Head")
        if part and F.isOnOurShot(part.Position) then return true end
        return false
    end

    local function onPlayerDied(plr, char)
        if lastHit[plr] and (osClock() - lastHit[plr]) <= 5 then
            F.playKillSound()
            local root = char and char:FindFirstChild("HumanoidRootPart")
            local pos = root and root.Position
            if S.HM.Enabled and pos then
                F.spawnHitMarker(pos, true)
            end
        end
        lastHit[plr] = nil
    end

    local function onDamaged(plr, char, dmg, newHealth)
        if S.Unloaded or dmg <= 0.01 then return end
        if not isOurDamage(plr, char) then return end

        local part = char:FindFirstChild(S.SA.TargetPart) or char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Head")
        if not part then return end
        local myRoot = F.char and F.char:FindFirstChild("HumanoidRootPart")
        if myRoot and (myRoot.Position - part.Position).Magnitude > 600 then return end

        lastHit[plr] = osClock()

        if S.DamageFX.Enabled then F.spawnDamageFX(part.Position, 1) end
        if S.HM.Enabled then F.spawnHitMarker(part.Position, false) end
        if S.HL.Enabled then
            F.showHitLog(plr.DisplayName, S.SA.TargetPart, string_format("%.0f", dmg), string_format("%.0f", newHealth))
        end
    end

    local function trackDeath(plr)
        if plr == LP then return end
        local function hc(c)
            task_spawn(function()
                local h = c:WaitForChild("Humanoid", 10)
                if h then
                    h.Died:Connect(function()
                        if S.KillNotify then
                            pcall(F.Notify, plr.DisplayName .. " (" .. plr.Name .. ") died!", 3)
                        end
                        onPlayerDied(plr, c)
                    end)
                end
            end)
        end
        if plr.Character then task_spawn(hc, plr.Character) end
        F.trackConn(plr.CharacterAdded:Connect(hc))
    end
    for _, p in ipairs(Svc.Players:GetPlayers()) do trackDeath(p) end
    F.trackConn(Svc.Players.PlayerAdded:Connect(trackDeath))

    local function trackDamage(plr)
        if plr == LP then return end
        local function hc(char)
            task_spawn(function()
                local hum = char:WaitForChild("Humanoid", 10)
                if not hum then return end
                local old = dmgConns[hum]
                if old then pcall(function() old:Disconnect() end) end
                humHealth[hum] = hum.Health
                dmgConns[hum] = hum.HealthChanged:Connect(function(new)
                    local prev = humHealth[hum] or new
                    humHealth[hum] = new
                    if new < prev - 0.05 then
                        onDamaged(plr, char, prev - new, new)
                    end
                end)
            end)
        end
        if plr.Character then hc(plr.Character) end
        F.trackConn(plr.CharacterAdded:Connect(hc))
    end
    for _, plr in ipairs(Svc.Players:GetPlayers()) do trackDamage(plr) end
    F.trackConn(Svc.Players.PlayerAdded:Connect(trackDamage))
end

do
    local function onCharAdd(ch)
        local h = ch:WaitForChild("Humanoid", 10)
        if h then
            h.StateChanged:Connect(function(oldState, newState)
                F.onJump(oldState, newState)
            end)
            if F.char == ch then F.hum = h end
        end
        ch:WaitForChild("HumanoidRootPart", 10)
        task_wait(0.5)
        F.setupHSChar(ch)
    end
    F.trackConn(LP.CharacterAdded:Connect(onCharAdd))
    if LP.Character then
        task_spawn(function()
            local h = LP.Character:FindFirstChild("Humanoid")
            if h then
                h.StateChanged:Connect(function(oldState, newState)
                    F.onJump(oldState, newState)
                end)
            end
            F.setupHSChar(LP.Character)
        end)
    end
end

do
    local spRay = RaycastParams.new()
    spRay.FilterType = Enum.RaycastFilterType.Exclude
    spRay.IgnoreWater = true

    F.physConn = Svc.RunService.Heartbeat:Connect(function(dt)
        if S.Unloaded then return end
        F.updateTracers()
        F.applyGunMods()
        F.updateReloadBar()

        local ch = F.char
        if not ch then return end
        local hrp = ch:FindFirstChild("HumanoidRootPart")
        local hum = F.hum
        if not hrp or not hum or hum.Health <= 0 then return end

        if S.Speed.Enabled then
            local md = hum.MoveDirection
            if md.Magnitude > 0 then
                hrp.AssemblyLinearVelocity = Vector3New(md.X * S.Speed.Value, hrp.AssemblyLinearVelocity.Y, md.Z * S.Speed.Value)
            end
        end

        if S.CopterSpeed.Enabled and hum.Sit then
            local md = hum.MoveDirection
            if md.Magnitude > 0 then
                hrp.AssemblyLinearVelocity = Vector3New(md.X * S.CopterSpeed.Value, hrp.AssemblyLinearVelocity.Y, md.Z * S.CopterSpeed.Value)
            end
        end

        if S.WaterSpeed.Enabled then
            if hum:GetState() == Enum.HumanoidStateType.Swimming then
                local bv = hrp:FindFirstChild("WSV")
                if not bv then
                    bv = Instance.new("BodyVelocity", hrp)
                    bv.Name = "WSV"
                    bv.MaxForce = Vector3New(1e5, 1e5, 1e5)
                end
                bv.Velocity = hum.MoveDirection * S.WaterSpeed.Value
            else
                local bv = hrp:FindFirstChild("WSV")
                if bv then bv:Destroy() end
            end
        end

        if S.Spider.Enabled and Svc.UIS:IsKeyDown(Enum.KeyCode.W) then
            spRay.FilterDescendantsInstances = { ch }
            local result = Svc.WS:Raycast(hrp.Position, hrp.CFrame.LookVector * 2.5, spRay)
            if result then
                local hp = result.Instance
                if hp:IsA("BasePart") and hp.Transparency >= 0.8 then
                elseif hp:IsA("BasePart") and not hp.CanCollide then
                elseif math.abs(result.Normal.Y) < 0.5 then
                    hrp.AssemblyLinearVelocity = Vector3New(
                        hrp.AssemblyLinearVelocity.X, S.Spider.Speed, hrp.AssemblyLinearVelocity.Z)
                end
            end
        end

        if S.CopterFly.Enabled then
            F.copterFlyStep(hum)
        end
        F.spinnerStep(dt)
    end)

    F.visConn = Svc.RunService.RenderStepped:Connect(function(dt)
        if S.Unloaded then
            F.fovFill.Visible = false
            return
        end
        local cam = Svc.WS.CurrentCamera
        if not cam then return end
        v6 = cam
        local now = tick()

        if S.ThirdPerson.Enabled then
            local hrp = F.char and F.char:FindFirstChild("HumanoidRootPart")
            if hrp then
                cam.CFrame = CFrameNew(hrp.Position - (cam.CFrame.LookVector * S.ThirdPerson.Distance), hrp.Position)
            end
        end
        if S.Stretch.Enabled then
            cam.CFrame = cam.CFrame * CFrameNew(0, 0, 0, 1, 0, 0, 0, S.Stretch.Value, 0, 0, 0, 1)
        end
        if S.FOVCam.Enabled then
            cam.FieldOfView = S.FOVCam.Value
        end

        if S.SA.Enabled then
            local part, pos = F.getClosestPlayerPW()
            F.targetPart = part
            F.targetPos = pos
            if part and part.Parent then
                local pl = Svc.Players:GetPlayerFromCharacter(part.Parent)
                if pl then
                    F.lastTargetPlayer = pl
                    F.lastTargetTime = osClock()
                end
            end
        else
            F.targetPart = nil
            F.targetPos = nil
        end

        if F.targetPos then
            local sp = cam:WorldToViewportPoint(F.targetPos)
            if sp then
                F.aimScreenPos = Vector2New(sp.X, sp.Y)
            else
                F.aimScreenPos = nil
            end
        else
            F.aimScreenPos = nil
        end

        if S.SA.ShowFOV and S.SA.Enabled then
            F.fovFill.Visible = true
            local vp = cam.ViewportSize
            F.fovFill.Position = UDim2.new(0, vp.X * 0.5, 0, vp.Y * 0.5)
            F.fovFill.Size = UDim2.new(0, S.SA.FOVRadius * 2, 0, S.SA.FOVRadius * 2)
            local col = F.targetPart and S.SAColor.Target or S.SAColor.NoTarget
            F.fovFill.BackgroundColor3 = col
            F.fovStroke.Color = col
        else
            F.fovFill.Visible = false
        end

        if S.AutoFire.Enabled and S.SA.Enabled and F.targetPart then
            if now - S.AutoFire.LastFire >= S.AutoFire.Delay then
                S.AutoFire.LastFire = now
                F.doAutoFire()
            end
        end

        F.updateSkinModel()
        F.updateCrosshair(dt)
        F.processHitMarkers()
        F.updTH(now)
        F.updateESP()
        if not F._iosNextUpdate or now >= F._iosNextUpdate then
            F._iosNextUpdate = now + S.IOS.UpdateRate
            F.updateIOSESP(now)
        end
        if not F._inspectorNextUpdate or now >= F._inspectorNextUpdate then
            F._inspectorNextUpdate = now + S.Inspector.UpdateRate
            F.updateInventoryInspector(now)
        end
    end)
end
