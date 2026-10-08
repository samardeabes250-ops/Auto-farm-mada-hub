--[[
    GAME  : Blox Fruits (Roblox)
    BUILD : Universal — Sea 1, 2, 3  (Update 30)
    EXEC  : Synapse X · KRNL · Fluxus
    ──────────────────────────────────────────────────────────
    Quest system:
      Reads player level → picks correct quest from table →
      fires CommF_:InvokeServer("StartQuest", id, tier) directly
      (no walking to NPC needed) → farms the quest mob by name →
      counts kills by watching mobs vanish → re-accepts on
      completion → loops forever.

    Attack: VirtualInputManager M1 at screen center.
    Tune AttackRate at the top to your weapon:
      Sword           ≈ 0.30 s
      Fighting Style  ≈ 0.45 s
      Gun             ≈ 0.55 s
    ──────────────────────────────────────────────────────────
]]

--// Services
local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local VIM              = game:GetService("VirtualInputManager")
local Camera           = workspace.CurrentCamera
local TweenService     = game:GetService("TweenService")

local Player = Players.LocalPlayer

--// ── Config ──────────────────────────────────────────────
local CFG = {
    AttackOffset  = 5,      -- studs in front of mob
    AttackRate    = 0.30,   -- M1 interval (tune to weapon)
    FarmSpeed     = 40,
    NormalSpeed   = 16,
    ScanRate      = 0.40,
    MaxRadius     = 600,

    AutoFarm    = false,
    AutoRespawn = false,
}

--// ── Quest table ─────────────────────────────────────────
-- { level, quest = RemoteId, tier, mob, kills, name = display name }
-- CommF_:InvokeServer("StartQuest", quest, tier)

local QUESTS = {
    sea1 = {
        { level = 1,   quest = "BanditQuest1",     tier = 1, mob = "Bandit",           kills = 8,  name = "Bandit Quest"        },
        { level = 10,  quest = "JungleQuest",       tier = 1, mob = "Monkey",           kills = 8,  name = "Jungle Quest"        },
        { level = 30,  quest = "BuggyQuest1",       tier = 1, mob = "Pirate",           kills = 8,  name = "Pirate Quest"        },
        { level = 60,  quest = "DesertQuest1",      tier = 1, mob = "Desert Bandit",    kills = 8,  name = "Desert Quest"        },
        { level = 90,  quest = "SnowQuest",         tier = 1, mob = "Snow Bandits",     kills = 8,  name = "Snow Quest"          },
        { level = 120, quest = "MarineBaseQuest",   tier = 1, mob = "Marine",           kills = 8,  name = "Marine Base Quest"   },
        { level = 150, quest = "SkyQuest",          tier = 1, mob = "Sky Bandit",       kills = 8,  name = "Sky Island Quest"    },
        { level = 195, quest = "PrisonQuest1",      tier = 1, mob = "Prisoner",         kills = 8,  name = "Prison Quest"        },
        { level = 225, quest = "ColosseumQuest",    tier = 1, mob = "Toga Warrior",     kills = 8,  name = "Colosseum Quest"     },
        { level = 275, quest = "VolcanoQuest1",     tier = 1, mob = "Lava Pirate",      kills = 8,  name = "Volcano Quest"       },
        { level = 325, quest = "FishmanQuest1",     tier = 1, mob = "Fishman Warrior",  kills = 8,  name = "Fishman Quest"       },
        { level = 375, quest = "SkyIslandQuest",    tier = 1, mob = "Dark Master",      kills = 8,  name = "Upper Sky Quest"     },
        { level = 425, quest = "Water7Quest",       tier = 1, mob = "Police",           kills = 8,  name = "Water 7 Quest"       },
        { level = 475, quest = "MaggotQuest",       tier = 1, mob = "Galley Captain",   kills = 8,  name = "Galley Quest"        },
        { level = 550, quest = "PirateQuest",       tier = 2, mob = "Galley Captain",   kills = 8,  name = "Galley Quest T2"     },
        { level = 625, quest = "FountainQuest",     tier = 2, mob = "Galley Captain",   kills = 8,  name = "Fountain Quest"      },
    },
    sea2 = {
        { level = 700,  quest = "Area1Quest",        tier = 1, mob = "Raider",            kills = 8,  name = "Raider Quest"        },
        { level = 750,  quest = "Area1Quest",        tier = 2, mob = "Mercenary",         kills = 8,  name = "Mercenary Quest"     },
        { level = 800,  quest = "MansonQuest",       tier = 1, mob = "Swan Pirate",       kills = 8,  name = "Swan Quest"          },
        { level = 875,  quest = "ColosseumQuest2",   tier = 1, mob = "Gladiator",         kills = 8,  name = "Colosseum Quest S2"  },
        { level = 950,  quest = "FactoryQuest",      tier = 1, mob = "Factory Staff",     kills = 8,  name = "Factory Quest"       },
        { level = 1000, quest = "GreenZoneQuest",    tier = 1, mob = "Zombie",            kills = 8,  name = "Green Zone Quest"    },
        { level = 1050, quest = "GraveyardQuest",    tier = 1, mob = "Living Zombie",     kills = 8,  name = "Graveyard Quest"     },
        { level = 1100, quest = "IceCastleQuest",    tier = 1, mob = "Snow Wolf",         kills = 8,  name = "Ice Castle Quest"    },
        { level = 1200, quest = "HotColdQuest",      tier = 1, mob = "Ice Fighter",       kills = 8,  name = "Hot & Cold Quest"    },
        { level = 1275, quest = "CursedShipQuest",   tier = 1, mob = "Cursed Skeleton",   kills = 8,  name = "Cursed Ship Quest"   },
        { level = 1350, quest = "ForgottenQuest",    tier = 1, mob = "Water Fighter",     kills = 8,  name = "Forgotten Quest"     },
        { level = 1450, quest = "ForgottenQuest",    tier = 2, mob = "Water Fighter",     kills = 8,  name = "Forgotten Quest T2"  },
    },
    sea3 = {
        { level = 1500, quest = "PiratePortQuest",   tier = 1, mob = "Pirate Millionaire",   kills = 10, name = "Port Town Quest"     },
        { level = 1575, quest = "DragonDojoQuest",   tier = 1, mob = "Dragon Crew Warrior",  kills = 10, name = "Dragon Dojo Quest"   },
        { level = 1650, quest = "DragonDojoQuest",   tier = 2, mob = "Dragon Crew Archer",   kills = 10, name = "Dragon Dojo T2"      },
        { level = 1725, quest = "CastleQuest",       tier = 1, mob = "Royal Soldier",        kills = 10, name = "Castle Quest"        },
        { level = 1800, quest = "TurtleQuest",       tier = 1, mob = "Fishman Raider",       kills = 10, name = "Turtle Quest"        },
        { level = 1875, quest = "GreatTreeQuest",    tier = 1, mob = "Forest Pirate",        kills = 10, name = "Great Tree Quest"    },
        { level = 1950, quest = "HauntedQuest",      tier = 1, mob = "Demonic Soul",         kills = 10, name = "Haunted Castle Quest" },
        { level = 2025, quest = "BeautifulQuest",    tier = 1, mob = "Beautiful Pirate",     kills = 10, name = "Beautiful Pirate Q"  },
        { level = 2100, quest = "NorthPoleQuest",    tier = 1, mob = "Snow Lurker",          kills = 10, name = "North Pole Quest"    },
        { level = 2200, quest = "TreatQuest",        tier = 1, mob = "Cookie Crafter",       kills = 10, name = "Sea of Treats Quest" },
        { level = 2300, quest = "TreatQuest",        tier = 2, mob = "Candy Pirate",         kills = 10, name = "Treats Quest T2"     },
        { level = 2425, quest = "SecretTempleQuest", tier = 1, mob = "Order",                kills = 10, name = "Secret Temple Quest" },
        { level = 2550, quest = "TikiQuest",         tier = 1, mob = "Tiki Outpost Warrior", kills = 10, name = "Tiki Outpost Quest"  },
        { level = 2650, quest = "HeavenlyQuest",     tier = 1, mob = "Celestial Dragon",     kills = 10, name = "Heavenly Quest"      },
        { level = 2700, quest = "SubmergedQuest3",   tier = 2, mob = "Grand Devotee",        kills = 10, name = "Submerged Quest"     },
    },
}

--// ── State ────────────────────────────────────────────────
local Character, Humanoid, Root
local Target
local DiedConn
local ActiveQuest    = nil    -- current quest entry
local KillCount      = 0
local PrevMobSet     = {}     -- for kill counting
local AttackClock    = 0
local ScanClock      = 0
local QuestClock     = 0

--// ── CommF_ reference ────────────────────────────────────
local CommF_ = workspace:WaitForChild("_Remotes", 10)
    and workspace._Remotes:WaitForChild("CommF_", 10)
    or  game:GetService("ReplicatedStorage"):WaitForChild("CommF_", 5)

--// ── Helpers ──────────────────────────────────────────────
local function getLevel()
    local ls = Player:FindFirstChild("Data")
        or Player:FindFirstChild("leaderstats")
    if ls then
        local lv = ls:FindFirstChild("Level")
        if lv then return lv.Value end
    end
    return 1
end

local function pickQuest(level)
    local sea
    if level >= 1500 then sea = QUESTS.sea3
    elseif level >= 700 then sea = QUESTS.sea2
    else sea = QUESTS.sea1 end

    local best = sea[1]
    for _, entry in ipairs(sea) do
        if entry.level <= level then
            best = entry
        else
            break
        end
    end
    return best
end

local function acceptQuest(entry)
    if not CommF_ then return end
    pcall(function()
        CommF_:InvokeServer("StartQuest", entry.quest, entry.tier)
    end)
end

--// ── Character ────────────────────────────────────────────
local function onCharacter(char)
    Character = char
    Humanoid  = char:WaitForChild("Humanoid", 10)
    Root      = char:WaitForChild("HumanoidRootPart", 10)
    Target    = nil
    KillCount = 0

    if DiedConn then DiedConn:Disconnect() end

    if Humanoid then
        Humanoid.WalkSpeed = CFG.NormalSpeed
        DiedConn = Humanoid.Died:Connect(function()
            Target    = nil
            KillCount = 0

            if CFG.AutoRespawn then
                task.delay(3.5, function()
                    if Player.Character == Character then
                        Player:LoadCharacter()
                    end
                end)
            end
        end)
    end
end

if Player.Character then onCharacter(Player.Character) end
Player.CharacterAdded:Connect(onCharacter)

--// ── Player set ───────────────────────────────────────────
local PlayerChars = {}
local function rebuildPlayerSet()
    PlayerChars = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p.Character then PlayerChars[p.Character] = true end
    end
end
Players.PlayerAdded:Connect(rebuildPlayerSet)
Players.PlayerRemoving:Connect(rebuildPlayerSet)
Player.CharacterAdded:Connect(function() task.defer(rebuildPlayerSet) end)
rebuildPlayerSet()

--// ── Mob detection ────────────────────────────────────────
local function isMob(model, mobName)
    if not model:IsA("Model") then return false end
    if PlayerChars[model] or model == Character then return false end
    if mobName and not model.Name:lower():find(mobName:lower(), 1, true) then
        return false
    end
    local hum  = model:FindFirstChildOfClass("Humanoid")
    local root = model:FindFirstChild("HumanoidRootPart")
    if not hum or not root then return false end
    if hum.Health <= 0 then return false end
    return true
end

local function getNearestMob(mobName)
    if not Root then return nil end
    local nearest, nearestDist = nil, math.huge
    for _, obj in ipairs(workspace:GetDescendants()) do
        if isMob(obj, mobName) then
            local root = obj:FindFirstChild("HumanoidRootPart")
            if root then
                local dist = (Root.Position - root.Position).Magnitude
                if dist < nearestDist and dist <= CFG.MaxRadius then
                    nearestDist = dist
                    nearest     = obj
                end
            end
        end
    end
    return nearest
end

--// ── Kill counting ────────────────────────────────────────
-- Compares living quest mobs this tick vs last tick.
-- Mobs that vanished = killed.
local function countKills(mobName)
    local currentSet = {}
    for _, obj in ipairs(workspace:GetDescendants()) do
        if isMob(obj, mobName) then
            currentSet[obj] = true
        end
    end

    local killed = 0
    for mob in pairs(PrevMobSet) do
        if not currentSet[mob] then
            killed = killed + 1
        end
    end

    PrevMobSet = currentSet
    return killed
end

--// ── Movement ─────────────────────────────────────────────
-- Tweens toward the mob so it looks natural and triggers
-- server-side proximity checks. Falls back to instant CFrame
-- if the tween can't complete (mob died mid-flight).
local ActiveTween = nil

local function moveToMob(mob)
    if not Root then return end
    local mobRoot = mob:FindFirstChild("HumanoidRootPart")
    if not mobRoot then return end

    local dir = Root.Position - mobRoot.Position
    dir = Vector3.new(dir.X, 0, dir.Z)
    if dir.Magnitude < 0.01 then dir = Vector3.new(1, 0, 0) end
    dir = dir.Unit

    local targetPos  = mobRoot.Position + dir * CFG.AttackOffset
    local targetCF   = CFrame.lookAt(targetPos, mobRoot.Position)
    local dist       = (Root.Position - targetPos).Magnitude

    -- Already in range — no tween needed
    if dist <= CFG.AttackOffset + 1 then return end

    -- Cancel any previous tween
    if ActiveTween then
        ActiveTween:Cancel()
        ActiveTween = nil
    end

    -- Speed of 80 studs/s feels natural, min 0.05s
    local duration = math.max(dist / 80, 0.05)

    pcall(function()
        local tween = TweenService:Create(
            Root,
            TweenInfo.new(duration, Enum.EasingStyle.Linear),
            { CFrame = targetCF }
        )
        ActiveTween = tween
        tween:Play()
    end)
end

--// ── Attack ───────────────────────────────────────────────
local function m1()
    local vp = Camera.ViewportSize
    local cx  = math.floor(vp.X * 0.5)
    local cy  = math.floor(vp.Y * 0.5)
    pcall(function()
        VIM:SendMouseButtonEvent(cx, cy, 0, true,  game, 1)
    end)
    task.wait(0.05)
    pcall(function()
        VIM:SendMouseButtonEvent(cx, cy, 0, false, game, 1)
    end)
end

--// ── GUI ──────────────────────────────────────────────────
local Gui = Instance.new("ScreenGui")
Gui.Name           = "BFHubUI"
Gui.ResetOnSpawn   = false
Gui.IgnoreGuiInset = true
Gui.Parent         = Player:WaitForChild("PlayerGui")

local Main = Instance.new("Frame")
Main.Name             = "Main"
Main.Size             = UDim2.fromOffset(300, 340)
Main.Position         = UDim2.new(0.5, -150, 0.5, -170)
Main.BackgroundColor3 = Color3.fromRGB(16, 16, 20)
Main.BorderSizePixel  = 0
Main.ClipsDescendants = true
Main.Parent           = Gui

do
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 14)
    c.Parent       = Main
end

-- Header
local Header = Instance.new("Frame")
Header.Size             = UDim2.new(1, 0, 0, 46)
Header.BackgroundColor3 = Color3.fromRGB(22, 22, 28)
Header.BorderSizePixel  = 0
Header.Parent           = Main

local TitleLbl = Instance.new("TextLabel")
TitleLbl.BackgroundTransparency = 1
TitleLbl.Position               = UDim2.fromOffset(14, 5)
TitleLbl.Size                   = UDim2.new(1, -28, 0, 18)
TitleLbl.Font                   = Enum.Font.GothamBold
TitleLbl.Text                   = "BLOX FRUITS · AUTO FARM"
TitleLbl.TextColor3             = Color3.fromRGB(235, 235, 242)
TitleLbl.TextSize               = 13
TitleLbl.TextXAlignment         = Enum.TextXAlignment.Left
TitleLbl.Parent                 = Header

local InfoLbl = Instance.new("TextLabel")
InfoLbl.BackgroundTransparency = 1
InfoLbl.Position               = UDim2.fromOffset(14, 24)
InfoLbl.Size                   = UDim2.new(1, -28, 0, 16)
InfoLbl.Font                   = Enum.Font.Gotham
InfoLbl.Text                   = "Level: --  |  Quest: --"
InfoLbl.TextColor3             = Color3.fromRGB(130, 130, 148)
InfoLbl.TextSize               = 11
InfoLbl.TextXAlignment         = Enum.TextXAlignment.Left
InfoLbl.Parent                 = Header

-- Button factory
local function makeBtn(text, y)
    local b = Instance.new("TextButton")
    b.Size             = UDim2.new(1, -28, 0, 50)
    b.Position         = UDim2.fromOffset(14, y)
    b.BackgroundColor3 = Color3.fromRGB(28, 28, 36)
    b.BorderSizePixel  = 0
    b.AutoButtonColor  = false
    b.Font             = Enum.Font.GothamMedium
    b.Text             = text
    b.TextColor3       = Color3.fromRGB(225, 225, 232)
    b.TextSize         = 13
    b.Parent           = Main
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 10)
    c.Parent       = b
    return b
end

local BtnFarm    = makeBtn("Auto Farm: OFF",    58)
local BtnRespawn = makeBtn("Auto Respawn: OFF", 118)

-- WalkSpeed
local SpeedLbl = Instance.new("TextLabel")
SpeedLbl.BackgroundTransparency = 1
SpeedLbl.Position               = UDim2.fromOffset(14, 184)
SpeedLbl.Size                   = UDim2.fromOffset(110, 38)
SpeedLbl.Font                   = Enum.Font.Gotham
SpeedLbl.Text                   = "WalkSpeed"
SpeedLbl.TextColor3             = Color3.fromRGB(170, 170, 185)
SpeedLbl.TextSize               = 12
SpeedLbl.TextXAlignment         = Enum.TextXAlignment.Left
SpeedLbl.Parent                 = Main

local SpeedBox = Instance.new("TextBox")
SpeedBox.Size             = UDim2.fromOffset(130, 40)
SpeedBox.Position         = UDim2.new(1, -144, 0, 182)
SpeedBox.BackgroundColor3 = Color3.fromRGB(26, 26, 34)
SpeedBox.BorderSizePixel  = 0
SpeedBox.Font             = Enum.Font.Gotham
SpeedBox.Text             = tostring(CFG.NormalSpeed)
SpeedBox.TextColor3       = Color3.fromRGB(225, 225, 232)
SpeedBox.TextSize         = 13
SpeedBox.ClearTextOnFocus = false
SpeedBox.Parent           = Main
do
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 8)
    c.Parent       = SpeedBox
end

-- Status lines
local TargetLbl = Instance.new("TextLabel")
TargetLbl.BackgroundTransparency = 1
TargetLbl.Position               = UDim2.fromOffset(14, 238)
TargetLbl.Size                   = UDim2.new(1, -28, 0, 22)
TargetLbl.Font                   = Enum.Font.Gotham
TargetLbl.Text                   = "Target: none"
TargetLbl.TextColor3             = Color3.fromRGB(115, 115, 132)
TargetLbl.TextSize               = 11
TargetLbl.TextXAlignment         = Enum.TextXAlignment.Left
TargetLbl.Parent                 = Main

local KillLbl = Instance.new("TextLabel")
KillLbl.BackgroundTransparency = 1
KillLbl.Position               = UDim2.fromOffset(14, 260)
KillLbl.Size                   = UDim2.new(1, -28, 0, 22)
KillLbl.Font                   = Enum.Font.Gotham
KillLbl.Text                   = "Kills: 0 / --"
KillLbl.TextColor3             = Color3.fromRGB(115, 115, 132)
KillLbl.TextSize               = 11
KillLbl.TextXAlignment         = Enum.TextXAlignment.Left
KillLbl.Parent                 = Main

local HintLbl = Instance.new("TextLabel")
HintLbl.BackgroundTransparency = 1
HintLbl.Position               = UDim2.fromOffset(14, 298)
HintLbl.Size                   = UDim2.new(1, -28, 0, 32)
HintLbl.Font                   = Enum.Font.Gotham
HintLbl.Text                   = "Adjust AttackRate in CFG at top of script"
HintLbl.TextColor3             = Color3.fromRGB(75, 75, 92)
HintLbl.TextSize               = 10
HintLbl.TextXAlignment         = Enum.TextXAlignment.Left
HintLbl.TextWrapped            = true
HintLbl.Parent                 = Main

--// ── Button logic ─────────────────────────────────────────
local function setBtn(btn, label, on)
    btn.Text             = label .. ": " .. (on and "ON" or "OFF")
    btn.BackgroundColor3 = on
        and Color3.fromRGB(38, 76, 52)
        or  Color3.fromRGB(28, 28, 36)
end

BtnFarm.Activated:Connect(function()
    CFG.AutoFarm = not CFG.AutoFarm

    if not CFG.AutoFarm then
        Target        = nil
        ActiveQuest   = nil
        KillCount     = 0
        if Humanoid then Humanoid.WalkSpeed = CFG.NormalSpeed end
    else
        if Humanoid then Humanoid.WalkSpeed = CFG.FarmSpeed end
        -- Accept first quest immediately
        local q = pickQuest(getLevel())
        ActiveQuest = q
        KillCount   = 0
        acceptQuest(q)
    end

    setBtn(BtnFarm, "Auto Farm", CFG.AutoFarm)
end)

BtnRespawn.Activated:Connect(function()
    CFG.AutoRespawn = not CFG.AutoRespawn
    setBtn(BtnRespawn, "Auto Respawn", CFG.AutoRespawn)
end)

SpeedBox.FocusLost:Connect(function()
    local v = tonumber(SpeedBox.Text)
    if v then
        v = math.clamp(v, 1, 250)
        CFG.NormalSpeed = v
        if not CFG.AutoFarm and Humanoid then Humanoid.WalkSpeed = v end
        SpeedBox.Text = tostring(v)
    else
        SpeedBox.Text = tostring(CFG.NormalSpeed)
    end
end)

--// ── Dragging ─────────────────────────────────────────────
local dragging, dragOrigin, frameOrigin = false, nil, nil

Header.InputBegan:Connect(function(input)
    local t = input.UserInputType
    if t == Enum.UserInputType.MouseButton1
    or t == Enum.UserInputType.Touch then
        dragging    = true
        dragOrigin  = input.Position
        frameOrigin = Main.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if not dragging then return end
    local t = input.UserInputType
    if t ~= Enum.UserInputType.MouseMovement
    and t ~= Enum.UserInputType.Touch then return end
    local d = input.Position - dragOrigin
    Main.Position = UDim2.new(
        frameOrigin.X.Scale, frameOrigin.X.Offset + d.X,
        frameOrigin.Y.Scale, frameOrigin.Y.Offset + d.Y
    )
end)

--// ── Main loop ────────────────────────────────────────────
local statsClock  = 0
local killClock   = 0

RunService.Heartbeat:Connect(function(dt)
    statsClock  += dt
    AttackClock += dt
    ScanClock   += dt
    killClock   += dt

    -- UI update
    if statsClock >= 0.25 then
        statsClock = 0
        local level = getLevel()
        local qname = ActiveQuest and ActiveQuest.name or "--"
        InfoLbl.Text = "Level: " .. level .. "  |  " .. qname

        if Target and Target.Parent then
            TargetLbl.Text = "Target: " .. Target.Name
        else
            TargetLbl.Text = "Target: none"
        end

        local req = ActiveQuest and ActiveQuest.kills or 0
        KillLbl.Text = "Kills: " .. KillCount .. " / " .. req
    end

    if not CFG.AutoFarm then return end
    if not Character or not Humanoid or not Root then return end
    if Humanoid.Health <= 0 then return end

    -- Pick or refresh quest
    if not ActiveQuest then
        ActiveQuest = pickQuest(getLevel())
        KillCount   = 0
        acceptQuest(ActiveQuest)
        PrevMobSet  = {}
        return
    end

    -- Count kills every 0.5s
    if killClock >= 0.5 then
        killClock  = 0
        KillCount += countKills(ActiveQuest.mob)

        -- Quest complete — turn in and re-accept
        if KillCount >= ActiveQuest.kills then
            KillCount   = 0
            ActiveQuest = pickQuest(getLevel())   -- re-evaluate level
            acceptQuest(ActiveQuest)
            Target      = nil
            PrevMobSet  = {}
        end
    end

    -- Refresh target
    if ScanClock >= CFG.ScanRate then
        ScanClock = 0
        local hum = Target and Target:FindFirstChildOfClass("Humanoid")
        if not hum or hum.Health <= 0 then
            Target = getNearestMob(ActiveQuest.mob)
        end
    end

    if not Target then return end

    local mobHum = Target:FindFirstChildOfClass("Humanoid")
    if not mobHum or mobHum.Health <= 0 then
        Target = nil
        return
    end

    -- Move + attack
    moveToMob(Target)

    if AttackClock >= CFG.AttackRate then
        AttackClock = 0
        m1()
    end
end)

-- Restore speed after respawn
Player.CharacterAdded:Connect(function()
    task.wait(0.5)
    if CFG.AutoFarm and Humanoid then
        Humanoid.WalkSpeed = CFG.FarmSpeed
    end
end)
