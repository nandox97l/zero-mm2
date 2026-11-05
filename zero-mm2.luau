-- SPDX-License-Identifier: MIT
-- Creator: Nandox | Open source, unobfuscated
-- Language: Luau | File: zero-mm2.luau | Runtime: Real | Target: MM2, place 142823291 v1460
-- UI: WindUI, Rayfield Gen2 or Fluent. Gameplay implementation derived from live v1460 inspection.
-- Reference: OminousVibes MM2, role-color ESP, GunDrop discovery and velocity prediction patterns.
-- References: EdgeIY/infiniteyield, Zyn-ic/MM2-AutoFarm, fleecewtf/MonoMM2, Aluxis/MM2-Utilities.
-- https://github.com/OminousVibes-Exploit/Scripts/blob/main/Murder%20Mystery%202.lua
local load_started = os.clock()
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local local_player = Players.LocalPlayer
assert(game.PlaceId == 142823291, "ZERO MM2: este script pertence ao Murder Mystery 2.")
local modules = assert(ReplicatedStorage:WaitForChild("Modules", 20), "MM2 ainda nao carregou Modules")
local client_services = assert(ReplicatedStorage:WaitForChild("ClientServices", 20), "MM2 ainda nao carregou ClientServices")

local env = type(getgenv) == "function" and getgenv() or _G
if env.ZERO_MM2 and env.ZERO_MM2.destroy then env.ZERO_MM2.destroy() end
local reload_state = env.__ZERO_RELOAD_STATE
env.__ZERO_RELOAD_STATE = nil
local app: any = {
    restore_movement = nil :: any, dashboard = nil :: Frame?, finish_active = false, forced_target = nil :: any,
    alive = true, connections = {}, drawings = {}, visuals = {}, controls = {},
    errors = {}, bags = {}, ignored_coins = {}, coin_parts = {}, target = nil,
    window = nil :: any, gun_drop = nil :: Instance?, last_touch = 0,
    stats = { frames = 0, aim_moves = 0, silent_calls = 0, collected_events = 0, collected = 0 },
    settings = {
        esp = false, boxes = true, names = true, chams = true, lobby = false,
        cinematic_fov = false, camera_fov = 70, fullbright = false, health_bar = false, streamer = false, spin_speed_clip = 240, skeleton = false, trigger = false, gun_esp = false, coin_esp = false, aim = false, silent = false,
        fov_circle = false, fov = 180, smoothing = 8, prediction = 0,
        wall_check = true, target_mode = "By role", target_part = "HumanoidRootPart",
        farm = false, farm_mode = "Normal", farm_speed = 14,
        aim_activation = "Hold", aim_priority = "Cursor", aim_distance = 600, hit_chance = 100,
        fov_color = Color3.fromRGB(126, 164, 255), esp_distance = 1200, line_thickness = 1,
        text_size = 15, highlight_opacity = 0.3, role_labels = true, distance_labels = true,
        health = false, tracers = false, show_innocents = true, esp_visible = false,
        underground_depth = 3, full_action = "Wait", innocent_action = "Wait for gun",
        xp_farm = false, xp_distance = 40, flight = false, flight_speed = 20,
        speed_enabled = false, walk_speed = 20, jump_enabled = false, jump_power = 60,
        noclip = false, infinite_jump = false, auto_gun = false,
        anti_afk = true, troll_target = "None", troll_follow = false, troll_orbit = false,
        troll_spin = false, troll_spectate = false, troll_rainbow = false, orbit_radius = 5,
        orbit_height = 0, orbit_speed = 30, spin_speed = 180,
        skins = false, knife_skin = "Original", gun_skin = "Original", skin_style = "Original",
        skin_effect = "None", skin_color = Color3.fromRGB(110, 170, 255),
        locale = "pt", language = "Portugues", theme = "cobalt", box_count = 1,
        farm_kind = "Todos", avoid_radius = 12, max_distance = 1200,
    },
    farm_status = "Desligado", collisions = {}, farm_target = nil, farm_started = 0,
}
env.ZERO_MM2 = app
local capabilities = {
    Drawing = type(Drawing) == "table" and type(Drawing.new) == "function",
    mousemoverel = type(mousemoverel) == "function", firetouchinterest = type(firetouchinterest) == "function",
    getconnections = type(getconnections) == "function", gethui = type(gethui) == "function",
    identifyexecutor = type(identifyexecutor) == "function", isrbxactive = type(isrbxactive) == "function",
    gethiddenproperty = type(gethiddenproperty) == "function", sethiddenproperty = type(sethiddenproperty) == "function",
    readfile = type(readfile) == "function", writefile = type(writefile) == "function", isfile = type(isfile) == "function",
}
-- Optional false-only overrides let compatibility checks be reproduced without removing executor APIs.
if type(env.ZERO_MM2_CAPABILITIES_OVERRIDE) == "table" then
    for key, value in pairs(env.ZERO_MM2_CAPABILITIES_OVERRIDE) do if value == false then capabilities[key] = false end end
end
app.capabilities = capabilities
app.features, app.module_ready, app.runtime_failures = {}, {}, {}
app.focused = true
local feature_specs = {
    {"player", "Player", {}, {}}, {"ui", "Interface", {}, {"ui"}},
    {"esp", "ESP / FOV", {"Drawing"}, {"round"}}, {"aim", "Aimbot", {"mousemoverel"}, {"round"}},
    {"silent", "Silent aim", {}, {"weapon", "round"}}, {"farm", "Farm", {"firetouchinterest"}, {"round"}},
    {"xp", "XP", {}, {"round"}}, {"gun", "Gun pickup", {"firetouchinterest"}, {"round"}},
    {"movement", "Movement", {}, {}}, {"troll", "Troll", {}, {}},
    {"fling", "Fling", {}, {}}, {"skins", "Local skins", {}, {}},
    {"afk", "Anti-AFK", {"getconnections"}, {}}, {"boxes", "Boxes", {}, {"catalog", "profile"}},
    {"config", "Configurations", {"readfile", "writefile", "isfile"}, {}}, {"language", "Languages", {}, {"ui"}},
}
function app.refresh_features()
    local ready, missing = 0, {}
    for _, spec in ipairs(feature_specs) do
        local reasons = {}
        for _, api in ipairs(spec[3]) do if not capabilities[api] then table.insert(reasons, api) end end
        for _, module_name in ipairs(spec[4]) do
            if not app.module_ready[module_name] then table.insert(reasons, "module: " .. module_name) end
        end
        if app.runtime_failures[spec[1]] then table.insert(reasons, app.runtime_failures[spec[1]]) end
        local ok = #reasons == 0
        app.features[spec[1]] = {name = spec[2], loaded = ok, reason = table.concat(reasons, ", ")}
        if ok then ready += 1 else table.insert(missing, spec[2] .. ": " .. table.concat(reasons, ", ")) end
    end
    app.load_percent = math.floor(ready / #feature_specs * 100 + 0.5)
    return app.load_percent, missing
end
function app.feature_available(key)
    app.refresh_features()
    return app.features[key] and app.features[key].loaded
end
function app.has_focus()
    return capabilities.isrbxactive and isrbxactive() or (not capabilities.isrbxactive and app.focused)
end
function app.ui_parent()
    if capabilities.gethui then local ok, parent = pcall(gethui); if ok and parent then return parent end end
    return local_player.PlayerGui
end
function app.load_module(container, name, key, fallback)
    local instance = container and container:FindFirstChild(name)
    local ok, result = pcall(function() return require(instance) end)
    app.module_ready[key] = ok and type(result) == "table"
    if not app.module_ready[key] then return fallback end
    return result
end
function app.executor_report()
    local missing = {}
    for name, supported in pairs(capabilities) do if not supported then table.insert(missing, name) end end
    table.sort(missing)
    return missing
end
app.refresh_features()


local function connect(signal, fn)
    local connection = signal:Connect(fn)
    table.insert(app.connections, connection)
    return connection
end

local function report_error(label, err)
    local message = label .. ": " .. tostring(err)
    if app.errors[#app.errors] ~= message then
        table.insert(app.errors, message)
        if #app.errors > 25 then table.remove(app.errors, 1) end
        warn("ZERO MM2 | " .. message)
    end
end

local function draw(kind, properties)
    if not capabilities.Drawing then return {Visible = false, Remove = function() end} end
    local ok, object = pcall(Drawing.new, kind)
    if not ok then
        capabilities.Drawing = false
        app.runtime_failures.esp = tostring(object)
        return {Visible = false, Remove = function() end}
    end
    for key, value in pairs(properties) do object[key] = value end
    table.insert(app.drawings, object)
    return object
end

local function restore_collisions()
    for part, value in pairs(app.collisions) do
        if part.Parent then part.CanCollide = value end
    end
    table.clear(app.collisions)
end

local original_methods = {}
local WeaponService
function app.destroy()
    if not app.alive then return end
    app.alive = false
    app.box_running = false
    if app.stop_clip then app.stop_clip() end
    if app.set_stream then app.set_stream(false) end
    if app.cleanup_extras then app.cleanup_extras() end
    if app.reset_cinematic then app.reset_cinematic() end
    if app.restore_movement then app.restore_movement() end
    if app.launcher then app.launcher:Destroy() end
    if app.dashboard then app.dashboard:Destroy() end
    for _, connection in ipairs(app.connections) do connection:Disconnect() end
    restore_collisions()
    for key, original in pairs(original_methods) do
        if WeaponService and WeaponService[key] == original.wrapper then
            WeaponService[key] = original.fn
        end
    end
    for _, visual in pairs(app.visuals) do if visual.highlight then visual.highlight:Destroy() end end
    for _, object in ipairs(app.drawings) do pcall(function() object:Remove() end) end
    if app.window and not app.window.unloaded then app.window:Unload() end
    if env.ZERO_MM2 == app then env.ZERO_MM2 = nil end
end
if reload_state and reload_state.onCleanup then reload_state.onCleanup(app.destroy) end

local runtime_require: any = require
local RoundClient = app.load_module(modules, "CurrentRoundClient", "round", {PlayerData = {}})
WeaponService = app.load_module(client_services, "WeaponService", "weapon", {})
local Gameplay = ReplicatedStorage.Remotes.Gameplay
local colors = {
    Murderer = Color3.fromRGB(255, 81, 104), Sheriff = Color3.fromRGB(72, 160, 255),
    Hero = Color3.fromRGB(255, 205, 85), Innocent = Color3.fromRGB(85, 220, 155),
    Lobby = Color3.fromRGB(160, 168, 184),
}
local role_names = {Murderer = "Assassino", Sheriff = "Xerife", Hero = "Heroi", Innocent = "Inocente", Lobby = "Lobby"}

local function character_parts(player)
    local character = player.Character
    if not character then return nil, nil, nil end
    return character, character:FindFirstChild("HumanoidRootPart"), character:FindFirstChildOfClass("Humanoid")
end

local function active_player(player)
    if player:GetAttribute("Alive") == false then return false end
    local _, root, humanoid = character_parts(player)
    local data = RoundClient.PlayerData[player.Name]
    return root ~= nil and humanoid ~= nil and humanoid.Health > 0
        and data ~= nil and not data.Dead and not data.Killed
end

local function has_weapon(player, name)
    local character = player.Character
    local backpack = player:FindFirstChildOfClass("Backpack")
    return (character and character:FindFirstChild(name)) or (backpack and backpack:FindFirstChild(name))
end

local function player_role(player)
    if not active_player(player) then return "Lobby" end
    local data = RoundClient.PlayerData[player.Name]
    if data.Role == "Innocent" and has_weapon(player, "Gun") then return "Hero" end
    return data.Role or "Innocent"
end

local aliases = setmetatable({}, {__mode="k"})
local alias_count=0
local function identity(player)
    if not app.settings.streamer then return player.DisplayName end
    if player == local_player then return "Player" end
    if not aliases[player] then alias_count+=1; aliases[player]=string.format("Player %02d",alias_count) end
    return aliases[player]
end
app.player_role = player_role
app.active_player = active_player

local function cursor_position(camera)
    local lock = local_player.PlayerScripts:FindFirstChild("MouseLock")
    if UserInputService.MouseBehavior == Enum.MouseBehavior.LockCenter
        or (lock and lock:GetAttribute("Enabled")) then return camera.ViewportSize / 2 end
    return UserInputService:GetMouseLocation()
end

local ray_params = RaycastParams.new()
ray_params.FilterType = Enum.RaycastFilterType.Exclude
local function visible_target(part, camera)
    local ignore = CollectionService:GetTagged("WeaponPassthrough")
    if local_player.Character then table.insert(ignore, local_player.Character) end
    for _ = 1, 8 do
        ray_params.FilterDescendantsInstances = ignore
        local hit = workspace:Raycast(camera.CFrame.Position, part.Position - camera.CFrame.Position, ray_params)
        if not hit or hit.Instance:IsDescendantOf(part.Parent) then return true end
        if hit.Instance.Transparency < 1 then return false end
        table.insert(ignore, hit.Instance)
    end
    return false
end

local function eligible_target(player)
    if player == local_player or not active_player(player) then return false end
    if app.settings.target_mode == "All" then return true end
    if player_role(local_player) == "Murderer" then return true end
    return player_role(player) == "Murderer"
end

function app.select_target()
    local camera = workspace.CurrentCamera
    if not camera or not active_player(local_player) then return nil end
    local cursor = cursor_position(camera)
    local best, best_distance = nil, math.huge
    for _, player in ipairs(Players:GetPlayers()) do
        if eligible_target(player) then
            local character, root = character_parts(player)
            local part = character:FindFirstChild(app.settings.target_part) or root
            if part and part:IsA("BasePart") then
                local point, on_screen = camera:WorldToViewportPoint(part.Position)
                local distance = (Vector2.new(point.X, point.Y) - cursor).Magnitude
                local world_distance = (camera.CFrame.Position - part.Position).Magnitude
                local score = app.settings.aim_priority == "Distance" and world_distance or distance
                if on_screen and distance <= app.settings.fov and world_distance <= app.settings.aim_distance and score < best_distance
                    and (not app.settings.wall_check or visible_target(part, camera)) then
                    best = {player = player, part = part, distance = distance}
                    best_distance = score
                end
            end
        end
    end
    return best
end

local function predicted_position(target)
    return target.part.Position + target.part.AssemblyLinearVelocity * app.settings.prediction
end

local function equipped_weapon()
    local character = local_player.Character
    if not character then return nil end
    return character:FindFirstChild("Gun") or character:FindFirstChild("Knife")
end

for _, key in ipairs({"GetMouseTargetCFrame", "GetTargetPosition"}) do
    local original = WeaponService[key]
    if type(original) ~= "function" then app.module_ready.weapon = false else
    local wrapper = function(self, ...)
        if app.alive and equipped_weapon() and (app.finish_active or os.clock() < (app.clip_target_until or 0) or (app.settings.silent and math.random(1, 100) <= app.settings.hit_chance)) then
            local target = app.finish_active and app.forced_target or (app.trigger_target and os.clock() < app.trigger_until and app.trigger_target) or app.select_target()
            if target and not active_player(target.player) then target = nil end
            if target then
                app.stats.silent_calls += 1
                app.stats.last_silent_target = target.player.Name
                return CFrame.new(predicted_position(target))
            end
        end
        return original(self, ...)
    end
    original_methods[key] = {fn = original, wrapper = wrapper}
    if reload_state and reload_state.override then reload_state.override(WeaponService, key, wrapper)
    else WeaponService[key] = wrapper end
    end
end

local fov = draw("Circle", {Radius = 180, Thickness = 1, Filled = false, Transparency = 0.8,
    Color = Color3.fromRGB(126, 164, 255), Visible = false})
local gun_label = draw("Text", {Size = 16, Center = true, Outline = true, Color = colors.Hero, Visible = false})
local coin_labels = {}
for _ = 1, 24 do
    table.insert(coin_labels, draw("Text", {Size = 13, Center = true, Outline = true,
        Color = Color3.fromRGB(255, 183, 80), Visible = false}))
end

local rigs = {
    R15 = {{"Head","UpperTorso"},{"UpperTorso","LowerTorso"}},
    R6 = {{"Head","Torso"},{"Torso","Left Arm"},{"Torso","Right Arm"},{"Torso","Left Leg"},{"Torso","Right Leg"}},
}
for _, side in ipairs({"Left", "Right"}) do
    for _, chain in ipairs({{"UpperTorso","UpperArm","LowerArm","Hand"},{"LowerTorso","UpperLeg","LowerLeg","Foot"}}) do
        local parent = chain[1]
        for i = 2, #chain do
            local child = side .. chain[i]
            table.insert(rigs.R15,{parent,child})
            parent = child
        end
    end
end
local function skeleton_step(visual, character, camera, enabled, color)
    if not enabled and not visual.bones then return end
    visual.bones = visual.bones or {}
    local links = enabled and (character:FindFirstChild("UpperTorso") and rigs.R15 or rigs.R6) or {}
    for i = 1, math.max(#links, #visual.bones) do
        local line = visual.bones[i]
        if not line then line = draw("Line",{Visible=false, Transparency=1}); visual.bones[i]=line end
        line.Visible = false
        local link=links[i]
        if link then
            local a,b=character:FindFirstChild(link[1]),character:FindFirstChild(link[2])
            if a and b then
                local u,visibleA=camera:WorldToViewportPoint(a.Position)
                local v,visibleB=camera:WorldToViewportPoint(b.Position)
                if visibleA and visibleB then
                    line.From,line.To=Vector2.new(u.X,u.Y),Vector2.new(v.X,v.Y)
                    line.Color,line.Thickness,line.Visible=color,app.settings.line_thickness,true
                end
            end
        end
    end
end

local function add_player(player)
    if player == local_player or app.visuals[player] then return end
    local highlight = Instance.new("Highlight")
    highlight.Name = "ZERO_MM2_ESP"
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.FillTransparency = 0.7
    highlight.OutlineTransparency = 0.1
    highlight.Enabled = false
    highlight.Parent = app.ui_parent()
    app.visuals[player] = {
        highlight = highlight,
        hp_track = draw("Line", {Thickness=4, Color=Color3.fromRGB(24,24,30), Visible=false, Transparency=1}),
        hp_fill = draw("Line", {Thickness=2, Visible=false, Transparency=1}),
        tracer = draw("Line", {Thickness = 1, Transparency = 1, Visible = false}),
        box = draw("Square", {Thickness = 1, Filled = false, Transparency = 1, Visible = false}),
        text = draw("Text", {Size = 15, Center = true, Outline = true, Visible = false}),
    }
end
for _, player in ipairs(Players:GetPlayers()) do add_player(player) end
connect(Players.PlayerAdded, add_player)
connect(Players.PlayerRemoving, function(player)
    local visual = app.visuals[player]
    if visual then
        visual.highlight:Destroy()
        local handles = visual.bones or {}
        table.insert(handles,visual.hp_track); table.insert(handles,visual.hp_fill)
        table.insert(handles,visual.box); table.insert(handles,visual.text); table.insert(handles,visual.tracer)
        for _, object in ipairs(handles) do
            object:Remove()
            local index = table.find(app.drawings, object)
            if index then table.remove(app.drawings, index) end
        end
        app.visuals[player] = nil
    end
end)

local function valid_coin(coin)
    if not coin.Parent or not coin:IsDescendantOf(workspace) then return false end
    if coin:GetAttribute("Collected") or coin:GetAttribute("Delete") then return false end
    if (app.ignored_coins[coin] or 0) > os.clock() then return false end
    local visual = coin:FindFirstChild("CoinVisual")
    if visual and (visual:GetAttribute("Collected") or visual:GetAttribute("Delete")) then return false end
    local kind = coin:GetAttribute("CoinID") or "Coins"
    local bag = app.bags[kind]
    if bag and bag.current >= bag.capacity then return false end
    return app.settings.farm_kind == "Todos" or kind == app.settings.farm_kind
end

function app.nearest_coin()
    local _, root = character_parts(local_player)
    if not root or not active_player(local_player) then return nil end
    local murderer_root
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= local_player and player_role(player) == "Murderer" then
            local _, other_root = character_parts(player)
            murderer_root = other_root
            break
        end
    end
    local best, distance = nil, app.settings.max_distance
    for _, coin in ipairs(app.coin_parts) do
        if valid_coin(coin) then
            local d = (coin.Position - root.Position).Magnitude
            local clear = not murderer_root or (coin.Position - murderer_root.Position).Magnitude >= app.settings.avoid_radius
            if d < distance and clear then best, distance = coin, d end
        end
    end
    return best, distance
end

connect(Gameplay.CoinCollected.OnClientEvent, function(kind, current, capacity)
    if type(kind) ~= "string" or type(current) ~= "number" or type(capacity) ~= "number" then return end
    local old = app.bags[kind]
    app.stats.collected += math.max(0, current - (old and old.current or 0))
    app.stats.collected_events += 1
    app.bags[kind] = {current = current, capacity = capacity}
    if app.farm_target then app.ignored_coins[app.farm_target] = os.clock() + 20 end
    app.farm_target = nil
end)
connect(Gameplay.CoinsStarted.OnClientEvent, function()
    table.clear(app.bags)
    table.clear(app.ignored_coins)
    app.farm_target = nil
end)
connect(local_player.CharacterAdded, function()
    restore_collisions()
    app.farm_target = nil
end)

-- Movement concepts: Infinite Yield sFLY/noclip/fling; rewritten with exact property restoration.
-- Coin selection/interpolation: Zynic MM2 AutoFarm; uses the current game's tagged coins.
local ProfileData = app.load_module(modules, "ProfileData", "profile", {Materials = {Owned = {}}})
local Sync = app.load_module(ReplicatedStorage:FindFirstChild("Database"), "Sync", "catalog", {NewShop = {}, MysteryBox = {}, Item = {}})
local movement_originals = {}
local underground_return = nil
local motion = {root = nil, expected = nil, paused_until = 0, corrections = 0, owner = nil}
local fling_state = nil
app.stats.corrections = 0
app.stats.shots = 0
app.stats.stabs = 0
app.stats.guns_picked = 0
app.stats.xp_start = local_player:GetAttribute("XP") or 0
app.box_results = {}
app.box_status = "Idle"
app.flight_force = nil :: any
app.finish_active = false
app.pickup_requested = false
app.full_handled = false
app.aim_key = Enum.UserInputType.MouseButton2
app.aim_latched = false
local last_attack = 0
local last_gun = has_weapon(local_player, "Gun") ~= nil

local function remember_property(object, key, value)
    local entry = movement_originals[object]
    if not entry then entry = {}; movement_originals[object] = entry end
    if not entry[key] then entry[key] = {value = object[key]} end
    object[key] = value
end

local function restore_property(object, key)
    local entry = movement_originals[object]
    if entry and entry[key] then
        if object.Parent then object[key] = entry[key].value end
        entry[key] = nil
        if not next(entry) then movement_originals[object] = nil end
    end
end

function app.restore_movement()
    local saved = underground_return
    underground_return = nil
    if saved and saved.root.Parent == local_player.Character and saved.floor:IsDescendantOf(workspace) then
        saved.root.CFrame = saved.floor.CFrame * saved.offset
    end
    if app.flight_force then app.flight_force:Destroy(); app.flight_force = nil end
    if fling_state and fling_state.root.Parent and local_player.Character and fling_state.root == local_player.Character:FindFirstChild("HumanoidRootPart") then
        fling_state.root.CFrame = fling_state.origin
    end
    fling_state = nil
    for object, entry in pairs(movement_originals) do
        if object.Parent then for key, old in pairs(entry) do object[key] = old.value end end
    end
    table.clear(movement_originals)
    restore_collisions()
    if motion.root and motion.root.Parent then
        motion.root.AssemblyLinearVelocity = Vector3.zero
        motion.root.AssemblyAngularVelocity = Vector3.zero
    end
    motion.root, motion.expected, motion.owner = nil, nil, nil
end

local function set_enabled(key, value)
    app.settings[key] = value
    if app.controls[key] then app.controls[key]:Set(value) end
end

function app.stop_all()
    if app.stop_clip then app.stop_clip() end
    app.finish_active, app.pickup_requested, app.box_running, app.troll_fling_active = false, false, false, false
    for _, key in ipairs({"esp", "gun_esp", "coin_esp", "aim", "silent", "trigger", "farm", "xp_farm",
        "flight", "noclip", "speed_enabled", "jump_enabled", "auto_gun", "infinite_jump",
        "troll_follow", "troll_orbit", "troll_spin", "troll_spectate", "troll_rainbow", "skins", "cinematic_fov", "fullbright"}) do
        set_enabled(key, false)
    end
    app.restore_movement()
end

local function noclip_character(character)
    for _, part in ipairs(character:GetDescendants()) do
        if part:IsA("BasePart") then
            if app.collisions[part] == nil then app.collisions[part] = part.CanCollide end
            part.CanCollide = false
        end
    end
end

local function murderer()
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= local_player and player_role(player) == "Murderer" then return player end
    end
    return nil
end

local function move_to(destination, dt, owner, teleport, underground)
    local character, root, humanoid = character_parts(local_player)
    if not root or not humanoid or humanoid.Health <= 0 then return false end
    local now = os.clock()
    if motion.root ~= root then motion.root, motion.expected = root, nil end
    if now < motion.paused_until then
        app.farm_status = "Movement correction: paused"
        return false
    end
    if motion.expected and (root.Position - motion.expected).Magnitude > 12 then
        motion.corrections += 1
        app.stats.corrections += 1
        motion.expected = nil
        motion.paused_until = now + 3
        app.restore_movement()
        if motion.corrections >= 3 then
            app.stop_all()
            app.farm_status = "Stopped after 3 movement corrections"
        end
        return false
    end
    if underground and not underground_return then
        local params = RaycastParams.new()
        params.FilterType = Enum.RaycastFilterType.Exclude
        params.FilterDescendantsInstances = {character}
        params.RespectCanCollide = true
        local hit = workspace:Raycast(root.Position + Vector3.yAxis * 2, -Vector3.yAxis * 40, params)
        if not hit or not hit.Instance:IsA("BasePart") then return false end
        local standing = CFrame.new(hit.Position + Vector3.yAxis * (math.max(humanoid.HipHeight, 2) + root.Size.Y/2 + 0.2))
        underground_return = {root=root, floor=hit.Instance, offset=hit.Instance.CFrame:ToObjectSpace(standing)}
    elseif underground_return and not underground then
        app.restore_movement()
    end
    noclip_character(character)
    remember_property(humanoid, "AutoRotate", false)
    remember_property(humanoid, "PlatformStand", true)
    local delta = destination - root.Position
    local speed = owner == "fling approach" and 75 or math.max(6, app.settings.farm_speed * (0.75 ^ motion.corrections))
    local step = speed * math.min(dt, 0.06)
    local position = teleport and destination or root.Position + (delta.Magnitude > step and delta.Unit * step or delta)
    local rotation = underground and CFrame.Angles(math.rad(90), 0, 0) or CFrame.Angles(0, select(2, root.CFrame:ToOrientation()), 0)
    root.AssemblyLinearVelocity, root.AssemblyAngularVelocity = Vector3.zero, Vector3.zero
    root.CFrame = CFrame.new(position) * rotation
    motion.expected, motion.owner = position, owner
    return (destination - position).Magnitude < 2.5
end

local function end_motion()
    if motion.owner then app.restore_movement() end
end

local function gun_part()
    local drop = app.gun_drop
    if not drop or not drop.Parent then return nil end
    return drop:IsA("BasePart") and drop or drop:FindFirstChildWhichIsA("BasePart", true)
end

local function pickup_step(dt)
    if has_weapon(local_player, "Gun") then app.pickup_requested = false; return false end
    local part = gun_part()
    if not part then app.farm_status = "Waiting for dropped gun"; return false end
    local _, root = character_parts(local_player)
    if not root then return false end
    app.farm_status = "Picking up gun"
    if os.clock() - app.last_touch >= 0.45 then
        app.restore_movement()
        root.CFrame = CFrame.new(part.Position + Vector3.yAxis * 0.5) * root.CFrame.Rotation
        root.AssemblyLinearVelocity = Vector3.zero
        app.last_touch = os.clock()
        firetouchinterest(root, part, 0)
        firetouchinterest(root, part, 1)
    end
    return true
end

function app.request_finish(murder_only)
    if murder_only and player_role(local_player) ~= "Murderer" then return false, "Murderer role required" end
    app.finish_murder_only = murder_only == true
    if not active_player(local_player) then return false, "No active round" end
    app.finish_active = true
    app.finish_started = os.clock()
    app.finish_target_seen = false
    return true
end

local function launch_direction(map, root, bounds, half)
    local pos = bounds:PointToObjectSpace(root.Position)
    local filter = RaycastParams.new()
    filter.FilterType = Enum.RaycastFilterType.Include
    filter.FilterDescendantsInstances = {map}
    filter.RespectCanCollide = true
    local best, score = Vector3.yAxis, -math.huge
    -- Prefer an unobstructed exit; in rooms pick the longest unobstructed run.
    for i=0,16 do
        local angle = i * math.pi/4
        local vertical = i < 8 and 0.25 or 1
        local localDir = i == 16 and Vector3.yAxis or Vector3.new(math.cos(angle),vertical,math.sin(angle)).Unit
        local function to_edge(p, d, h)
            if math.abs(d)<0.001 then return math.huge end
            return ((d>0 and h or -h)-p)/d
        end
        local distance=math.max(4,math.min(to_edge(pos.X,localDir.X,half.X),to_edge(pos.Y,localDir.Y,half.Y),to_edge(pos.Z,localDir.Z,half.Z))+8)
        local dir=bounds:VectorToWorldSpace(localDir)
        local hit=workspace:Raycast(root.Position,dir*distance,filter)
        local rating=hit and hit.Distance or 10000-distance
        if rating>score then best,score=dir,rating end
    end
    return best
end

local function fling_step(target, dt)
    local character, root, humanoid = character_parts(local_player)
    local _, target_root = character_parts(target)
    if not target_root or not root then return false end
    if fling_state and (fling_state.target ~= target_root or fling_state.root ~= root) then app.restore_movement() end
    if not fling_state then
        local distance = (root.Position - target_root.Position).Magnitude
        if distance > 9 then
            local lead = math.clamp(distance / 75, 0, 0.25)
            move_to(target_root.Position + target_root.AssemblyLinearVelocity * lead, dt, "fling approach", false, false)
            return true
        end
        app.restore_movement()
        fling_state = {root = root, started = os.clock(), origin = root.CFrame,
            target_origin = target_root.Position, peak_speed = 0}
        local offset = target_root.Position - root.Position
        local horizontal = Vector3.new(offset.X, 0, offset.Z)
        fling_state.heading = horizontal.Magnitude > 0.1 and horizontal.Unit or Vector3.xAxis
        local map
        for _,candidate in ipairs(workspace:GetChildren()) do
            if candidate:IsA("Model") and candidate:FindFirstChild("CoinContainer") then map=candidate;break end
        end
        if map then
            local bounds, size = map:GetBoundingBox()
            local localPos = bounds:PointToObjectSpace(target_root.Position)
            if math.abs(localPos.X) <= size.X/2 and math.abs(localPos.Z) <= size.Z/2 and math.abs(localPos.Y) <= size.Y/2+10 then
                fling_state.bounds, fling_state.extents = bounds, size/2
                fling_state.map = map
                fling_state.exit = launch_direction(map,target_root,bounds,size/2)
                fling_state.next_scan = os.clock()+0.4
            end
        end
        app.stats.fling_outside_map = false
        fling_state.target = target_root
        fling_state.strikes = 0
        app.stats.last_fling_strikes = 0
        remember_property(root, "CanCollide", true)
        remember_property(root, "CollisionGroup", "Default")
        remember_property(root, "Massless", false)
        remember_property(root, "CustomPhysicalProperties", PhysicalProperties.new(100, 0.1, 0.5))
        remember_property(humanoid, "PlatformStand", true)
        motion.root, motion.owner = root, "fling"
    end
    local elapsed = os.clock() - fling_state.started
    fling_state.peak_speed = math.max(fling_state.peak_speed, target_root.AssemblyLinearVelocity.Magnitude)
    app.stats.last_fling_peak_speed = fling_state.peak_speed
    app.stats.last_fling_displacement = (target_root.Position - fling_state.target_origin).Magnitude
    app.stats.last_fling_vertical = target_root.Position.Y - fling_state.target_origin.Y
    app.farm_status = "Fling: " .. identity(target)
    local outside = false
    if fling_state.bounds then
        local pos = fling_state.bounds:PointToObjectSpace(target_root.Position)
        local extents = fling_state.extents
        outside = math.abs(pos.X)>extents.X+5 or math.abs(pos.Z)>extents.Z+5 or math.abs(pos.Y)>extents.Y+5
    end
    app.stats.fling_outside_map = outside
    if elapsed > 6 or outside or (not fling_state.bounds and (target_root.Position-fling_state.target_origin).Magnitude>150) then
        app.stats.last_fling_displacement = (target_root.Position - fling_state.target_origin).Magnitude
        app.restore_movement()
        app.finish_active, app.troll_fling_active = false, false
        return false
    end
    return true
end

-- Launch from just outside the target towards its torso before each physics step.
connect(RunService.PreSimulation, function(dt)
    local state = fling_state
    if not state or not state.root.Parent or not state.target.Parent then return end
    local root, target = state.root, state.target
    local velocity = target.AssemblyLinearVelocity
    local horizontal = Vector3.new(velocity.X, 0, velocity.Z)
    local heading = not state.bounds and horizontal.Magnitude > 4 and horizontal.Unit or state.heading
    local side = Vector3.new(-heading.Z, 0, heading.X)
    local direction = (heading + side * (math.sin(state.strikes * 0.38) * 0.12) + Vector3.yAxis * 0.8).Unit
    if state.map and state.map.Parent then
        if os.clock() >= state.next_scan then
            state.exit = launch_direction(state.map,target,state.bounds,state.extents)
            state.next_scan = os.clock()+0.4
        end
        direction = state.exit
        if math.abs(direction.Y)>0.9 then side = Vector3.xAxis end
    end
    local speed = 2600
    local travel = math.clamp(dt, 1/120, 1/30)
    local lead = velocity * (travel + math.clamp(local_player:GetNetworkPing(), 0, 0.12))
    if lead.Magnitude > 4 then lead = lead.Unit * 4 end
    local contact = target.Position + lead
    local start = contact - direction * 0.65
    root.CFrame = CFrame.lookAt(start, contact)
    root.AssemblyLinearVelocity = velocity + direction * speed
    root.AssemblyAngularVelocity = side * 280 + Vector3.yAxis * 65
    state.strikes += 1
    app.stats.last_fling_strikes = state.strikes
end)

-- Keep the rendered character at the target after the physics solver has handled contact.
connect(RunService.PostSimulation, function()
    local state = fling_state
    if not state or not state.root.Parent or not state.target.Parent then return end
    local root, target = state.root, state.target
    root.CFrame = CFrame.new(target.Position) * root.CFrame.Rotation
    if target.AssemblyLinearVelocity.Magnitude > 5 then
        app.stats.fling_moving_frames = (app.stats.fling_moving_frames or 0) + 1
    end
end)

local function finish_step(dt)
    if not app.finish_active then return false end
    if not active_player(local_player) or os.clock() - app.finish_started > 90 then
        app.finish_active = false; app.forced_target = nil; end_motion(); return false
    end
    local role = player_role(local_player)
    if app.finish_murder_only and role ~= "Murderer" then
        app.finish_active, app.forced_target = false, nil
        end_motion()
        return false
    end
    local _, root, humanoid = character_parts(local_player)
    local target = murderer()
    if role == "Murderer" then
        target = nil
        local distance = math.huge
        for _, other in ipairs(Players:GetPlayers()) do
            if other ~= local_player and active_player(other) then
                local _, other_root = character_parts(other)
                local d = (root.Position - other_root.Position).Magnitude
                if d < distance then target, distance = other, d end
            end
        end
    end
    if not target then
        app.forced_target = nil
        end_motion()
        if app.finish_target_seen then app.finish_active = false; return false end
        app.farm_status = "Waiting for roles"
        return true
    end
    app.finish_target_seen = true
    local target_character, target_root = character_parts(target)
    local tool = has_weapon(local_player, role == "Murderer" and "Knife" or "Gun")
    if not tool then
        if role == "Murderer" or role == "Sheriff" then app.farm_status = "Waiting for weapon"; return true end
        if app.settings.innocent_action == "Fling" then return fling_step(target, dt) end
        return pickup_step(dt)
    end
    if tool.Parent ~= local_player.Character then humanoid:EquipTool(tool) end
    app.farm_status = "Finish round: " .. identity(target)
    if role == "Murderer" and app.finish_murder_only then
        end_motion()
        if os.clock()-last_attack >= 1 then
            last_attack=os.clock()
            local events=tool:FindFirstChild("Events")
            local stab=events and events:FindFirstChild("KnifeStabbed")
            local touch=events and events:FindFirstChild("HandleTouched")
            if stab and touch then
                stab:FireServer()
                for _,enemy in ipairs(Players:GetPlayers()) do
                    if enemy~=local_player and active_player(enemy) then
                        local body,torso=character_parts(enemy)
                        touch:FireServer(body:FindFirstChild("UpperTorso") or torso)
                        app.stats.stabs+=1
                    end
                end
            end
        end
        return true
    end
    if role == "Murderer" then
        local arrived = move_to(target_root.Position + target_root.CFrame.LookVector * -2, dt, "combat", false, false)
        if arrived and os.clock() - last_attack > 0.9 then
            last_attack = os.clock()
            local events = tool:FindFirstChild("Events")
            if events and events:FindFirstChild("KnifeStabbed") and events:FindFirstChild("HandleTouched") then
                events.KnifeStabbed:FireServer()
                events.HandleTouched:FireServer(target_character:FindFirstChild("UpperTorso") or target_root)
                app.stats.stabs += 1
            end
        end
    elseif visible_target(target_root, workspace.CurrentCamera) then
        end_motion()
        if os.clock() - last_attack > 3.1 then
            last_attack = os.clock()
            app.forced_target = {player = target, part = target_root}
            tool:Activate()
            app.stats.shots += 1
        end
    else
        move_to(target_root.Position + (root.Position - target_root.Position).Unit * 18, dt, "combat", false, false)
    end
    return true
end

local function flight_step()
    local _, root, humanoid = character_parts(local_player)
    local camera = workspace.CurrentCamera
    if not root or not camera or not humanoid or humanoid.Health <= 0 then return end
    if motion.owner and motion.owner ~= "flight" then app.restore_movement() end
    motion.root, motion.owner, motion.expected = root, "flight", nil
    remember_property(humanoid, "PlatformStand", true)
    remember_property(humanoid, "AutoRotate", false)
    local velocity = Vector3.zero
    if not UserInputService:GetFocusedTextBox() and app.has_focus() then
        local function key(k) return UserInputService:IsKeyDown(k) and 1 or 0 end
        velocity = camera.CFrame.LookVector * (key(Enum.KeyCode.W) - key(Enum.KeyCode.S))
            + camera.CFrame.RightVector * (key(Enum.KeyCode.D) - key(Enum.KeyCode.A))
            + Vector3.yAxis * (key(Enum.KeyCode.E) - key(Enum.KeyCode.Q))
    end
    if velocity.Magnitude > 1 then velocity = velocity.Unit end
    -- Compensate gravity through a force, without accumulating a second body mover on reload.
    local force = root:FindFirstChild("ZERO_FlightVelocity")
    if not force then
        force = Instance.new("BodyVelocity")
        force.Name = "ZERO_FlightVelocity"
        force.MaxForce = Vector3.new(1e6, 1e6, 1e6)
        force.P = 1e4
        force.Parent = root
        app.flight_force = force
    end
    force.Velocity = velocity * app.settings.flight_speed
    root.AssemblyAngularVelocity = Vector3.zero
    root.CFrame = CFrame.new(root.Position) * camera.CFrame.Rotation
end

function app.farm_step(dt)
    local character, root, humanoid = character_parts(local_player)
    if not root or not humanoid or humanoid.Health <= 0 then end_motion(); return end
    local has_gun_now = has_weapon(local_player, "Gun") ~= nil
    if has_gun_now and not last_gun then app.stats.guns_picked += 1 end
    last_gun = has_gun_now
    local in_round = active_player(local_player)
    local used = false
    if app.finish_active then used = finish_step(dt) end
    if not used and app.troll_move_step then used = app.troll_move_step(dt) end
    if not used and in_round and (app.pickup_requested or app.settings.auto_gun) then used = pickup_step(dt) end
    if not used and in_round and app.settings.farm then
        local full = false
        for kind, bag in pairs(app.bags) do
            if (app.settings.farm_kind == "Todos" or app.settings.farm_kind == kind) and bag.current >= bag.capacity then full = true end
        end
        if full then
            if underground_return then app.restore_movement() end
            app.farm_status = "Bag full"
            if not app.full_handled then
                app.full_handled = true
                if app.settings.full_action == "Reset" or app.settings.full_action == "Lobby" then
                    if app.settings.full_action == "Lobby" then set_enabled("farm", false); set_enabled("xp_farm", false) end
                    humanoid.Health = 0
                elseif app.settings.full_action == "Finish round" then app.request_finish() end
            end
        else
            local coin = app.farm_target
            if coin and (not valid_coin(coin) or os.clock() - app.farm_started > 18) then
                app.ignored_coins[coin] = os.clock() + 10; coin = nil
            end
            if not coin then coin = app.nearest_coin(); app.farm_target, app.farm_started = coin, os.clock() end
            if coin then
                local underground = app.settings.farm_mode == "Underground"
                local destination = coin.Position + Vector3.new(0, underground and -app.settings.underground_depth or 1.2, 0)
                used = true
                app.farm_status = "Collecting " .. tostring(coin:GetAttribute("CoinID") or "Coins")
                local arrived = move_to(destination, dt, "farm", app.settings.farm_mode == "Teleport", underground)
                if arrived and os.clock() - app.last_touch > 0.4 then
                    app.last_touch = os.clock()
                    firetouchinterest(root, coin, 1); firetouchinterest(root, coin, 0)
                end
            else
                if underground_return then app.restore_movement() end
                app.farm_status = "No collectible in range"
            end
        end
    end
    if not used and in_round and app.settings.xp_farm then
        local threat = murderer()
        if threat then
            local _, other_root = character_parts(threat)
            local nearest, distance = nil, 0
            for _, coin in ipairs(app.coin_parts) do
                if coin.Parent and (coin.Position - root.Position).Magnitude < app.settings.max_distance then
                    local d = (coin.Position - other_root.Position).Magnitude
                    if d > distance then nearest, distance = coin, d end
                end
            end
            if nearest and (root.Position - other_root.Position).Magnitude < app.settings.xp_distance then
                move_to(nearest.Position + Vector3.new(0, 2, 0), dt, "xp", false, false)
                used = true
            end
        end
        app.farm_status = "XP: surviving the round"
    end
    if not used and app.settings.flight then flight_step(); used = true end
    if not used then
        end_motion()
        if not in_round then app.farm_status = "Waiting for round"
        elseif not app.settings.farm and not app.settings.xp_farm then app.farm_status = "Idle" end
    end
    if (app.settings.noclip and not fling_state) or (motion.owner and motion.owner ~= "fling" and motion.owner ~= "flight") then
        noclip_character(character)
    elseif not fling_state then restore_collisions() end
    if app.settings.speed_enabled then remember_property(humanoid, "WalkSpeed", app.settings.walk_speed)
    else restore_property(humanoid, "WalkSpeed") end
    if app.settings.jump_enabled then
        remember_property(humanoid, "UseJumpPower", true)
        remember_property(humanoid, "JumpPower", app.settings.jump_power)
    else restore_property(humanoid, "UseJumpPower"); restore_property(humanoid, "JumpPower") end
end

connect(Gameplay.CoinsStarted.OnClientEvent, function()
    app.full_handled, app.finish_active, app.forced_target = false, false, nil
    motion.corrections, motion.paused_until = 0, 0
end)
connect(local_player.CharacterAdded, function()
    app.restore_movement()
    app.forced_target, app.finish_active = nil, false
end)
connect(UserInputService.JumpRequest, function()
    local _, _, humanoid = character_parts(local_player)
    if app.settings.infinite_jump and humanoid then humanoid:ChangeState(Enum.HumanoidStateType.Jumping) end
end)
connect(UserInputService.InputBegan, function(input, processed)
    if not processed and (input.KeyCode == app.aim_key or input.UserInputType == app.aim_key) then app.aim_latched = not app.aim_latched end
end)

function app.aim_pressed()
    if app.settings.aim_activation == "Always" then return true end
    if app.settings.aim_activation == "Toggle" then return app.aim_latched end
    if app.aim_key.EnumType == Enum.UserInputType then return UserInputService:IsMouseButtonPressed(app.aim_key) end
    return UserInputService:IsKeyDown(app.aim_key)
end

function app.box_quote(box_id, currency, count)
    count = tonumber(count)
    if not count or count % 1 ~= 0 or count < 1 or count > 10 then return nil, "Quantity must be 1–10" end
    local item = Sync.NewShop[box_id]
    local price = item and item.Type == "MysteryBox" and item.Price[currency]
    if currency == "Robux" or type(price) ~= "number" or price <= 0 then return nil, "Unavailable price" end
    local owned = ProfileData.Materials.Owned[currency] or 0
    return {id = box_id, currency = currency, count = count, unit = price, total = price * count,
        balance = owned, affordable = owned >= price * count, name = Sync.MysteryBox[box_id].Name or box_id}
end

function app.open_boxes(quote)
    if app.box_running then return false, "Already opening" end
    local fresh, err = app.box_quote(quote.id, quote.currency, quote.count)
    if not fresh or not fresh.affordable or fresh.total ~= quote.total then return false, err or "Balance or price changed" end
    app.box_running = true
    task.spawn(function()
        local ok, failure = pcall(function()
            local shop_gui = local_player.PlayerGui:FindFirstChild("CrossPlatform")
            local service = shop_gui and shop_gui:FindFirstChild("Shop") and shop_gui.Shop:FindFirstChild("ShopScript")
            assert(service and service:FindFirstChild("ShopService"), "Shop service unavailable")
            local shop = runtime_require(service.ShopService)
            for index = 1, quote.count do
                if not app.alive or not app.box_running then break end
                local current = app.box_quote(quote.id, quote.currency, 1)
                if not current or not current.affordable or current.unit ~= quote.unit then break end
                app.box_status = string.format("Opening %d / %d", index, quote.count)
                local result = shop:RequestUnbox(quote.id, quote.currency, 1)
                if not result or not result[1] then error("Server declined purchase") end
                table.insert(app.box_results, result[1])
                if index < quote.count then
                    local until_time = os.clock() + 10
                    repeat task.wait(0.2) until not app.alive or not app.box_running or os.clock() >= until_time
                end
            end
        end)
        app.box_running = false
        app.box_status = ok and "Finished" or tostring(failure)
        if not ok then report_error("Boxes", failure) end
    end)
    return true
end

function app.performance_color(value, ping)
    if value == nil then return Color3.fromRGB(150, 160, 180) end
    if ping then
        return value <= 80 and Color3.fromRGB(85, 220, 155) or value <= 150 and Color3.fromRGB(255, 205, 85) or Color3.fromRGB(255, 81, 104)
    end
    return value >= 55 and Color3.fromRGB(85, 220, 155) or value >= 30 and Color3.fromRGB(255, 205, 85) or Color3.fromRGB(255, 81, 104)
end


local idle_connections = {}
local skin_templates = {Knife = {}, Gun = {}}
local native_grips = {}
local skin_overlays = {}
local skin_hidden = {}
local spectate_original = nil
local rainbow_originals = {}
app.skin_revision = 0
app.troll_fling_active = false
app.skin_status = "Original"
app.stats.afk_disabled = 0

function app.set_anti_afk(enabled)
    if not enabled then
        for _, connection in ipairs(idle_connections) do pcall(function() connection:Enable() end) end
        table.clear(idle_connections)
        app.stats.afk_disabled = 0
        return true
    end
    if not capabilities.getconnections then return false end
    local ok, connections = pcall(getconnections, local_player.Idled)
    if not ok then app.runtime_failures.afk = tostring(connections); return false end
    for _, connection in ipairs(connections) do
        if connection.Enabled and type(connection.Disable) == "function" and type(connection.Enable) == "function" then
            local disabled = pcall(function() connection:Disable() end)
            if disabled then table.insert(idle_connections, connection) end
        end
    end
    app.stats.afk_disabled = #idle_connections
    return true
end

local target_options = {}
local function target_player()
    local selected = target_options[app.settings.troll_target]
    if not selected or selected == local_player then return nil end
    local _, root, humanoid = character_parts(selected)
    return root and humanoid and humanoid.Health > 0 and selected or nil
end

function app.refresh_targets()
    local options = {"None"}
    table.clear(target_options)
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= local_player then
            local label=app.settings.streamer and identity(player) or player.Name
            target_options[label]=player
            table.insert(options,label)
        end
    end
    table.sort(options, function(a, b)
        if a == b then return false end
        if a == "None" then return true elseif b == "None" then return false end
        return a < b
    end)
    if app.controls.troll_target then app.controls.troll_target:Refresh(options) end
    return options
end

function app.request_target_fling()
    if not app.feature_available("fling") or not target_player() then return false end
    app.troll_fling_active = true
    app.troll_started = os.clock()
    return true
end

function app.stop_troll()
    app.troll_fling_active = false
    for _, key in ipairs({"troll_follow", "troll_orbit", "troll_spin", "troll_spectate", "troll_rainbow"}) do set_enabled(key, false) end
    app.restore_movement()
end

function app.troll_move_step(dt)
    local target = target_player()
    if app.troll_fling_active then
        if not target or os.clock() - app.troll_started > 45 then
            app.troll_fling_active = false; app.restore_movement(); return false
        end
        return fling_step(target, dt)
    end
    if not target or (not app.settings.troll_follow and not app.settings.troll_orbit) then return false end
    local _, root = character_parts(local_player)
    local _, other_root = character_parts(target)
    if not root or (root.Position - other_root.Position).Magnitude > app.settings.max_distance then return false end
    local offset
    if app.settings.troll_orbit then
        local angle = os.clock() * math.rad(app.settings.orbit_speed)
        offset = Vector3.new(math.cos(angle) * app.settings.orbit_radius, app.settings.orbit_height, math.sin(angle) * app.settings.orbit_radius)
    else offset = -other_root.CFrame.LookVector * app.settings.orbit_radius end
    move_to(other_root.Position + offset, dt, "troll", false, false)
    app.farm_status = app.settings.troll_orbit and "Orbiting target" or "Following target"
    return true
end

local function clean_visual_clone(source)
    -- A display's rigid constraint also references the live character. Keep only geometry.
    local mount = CFrame.identity
    local rigid = source:FindFirstChildWhichIsA("RigidConstraint", true)
    if source:IsA("BasePart") and rigid then
        for _, attachment in ipairs({rigid.Attachment1, rigid.Attachment0}) do
            if attachment and attachment:IsDescendantOf(source) then
                mount = source.CFrame:ToObjectSpace(attachment.WorldCFrame)
                break
            end
        end
    end
    local cloned = source:Clone()
    if not cloned then return nil end
    local model = Instance.new("Model")
    model.Name = "ZERO_LocalSkin"
    cloned.Parent = model
    for _, object in ipairs(model:GetDescendants()) do
        if object:IsA("Constraint") or object:IsA("BodyMover") or object:IsA("ObjectValue") or object:IsA("LuaSourceContainer") or object:IsA("JointInstance") or object:IsA("WeldConstraint")
            or object:IsA("Sound") or object:IsA("ParticleEmitter") or object:IsA("Trail") or object:IsA("Beam")
            or object:IsA("Fire") or object:IsA("Smoke") or object:IsA("Sparkles") then object:Destroy()
        elseif object:IsA("BasePart") then
            object.Anchored, object.CanCollide, object.CanTouch, object.CanQuery, object.Massless = true, false, false, false, true
            object.LocalTransparencyModifier = 0
        end
    end
    local primary = cloned:IsA("BasePart") and cloned or model:FindFirstChildWhichIsA("BasePart", true)
    if not primary then model:Destroy(); return nil end
    local grip = source:FindFirstChild("RightGripAttachment", true) or source:FindFirstChild("CustomAttachment", true)
    if grip and grip:IsA("Attachment") then mount = primary.CFrame:ToObjectSpace(grip.WorldCFrame) end
    primary.PivotOffset = CFrame.identity
    model:SetAttribute("Mount", mount)
    if rigid and rigid.Attachment0 and rigid.Attachment1 then
        local own, body = rigid.Attachment1, rigid.Attachment0
        if not own:IsDescendantOf(source) then own, body = body, own end
        if own:IsDescendantOf(source) and source:IsA("BasePart") and body.Parent and body.Parent:IsA("BasePart") then
            model:SetAttribute("BeltMount", source.CFrame:ToObjectSpace(own.WorldCFrame))
            model:SetAttribute("BeltPosition", body.Position / body.Parent.Size)
            model:SetAttribute("BeltRotation", body.CFrame.Rotation)
            model:SetAttribute("NativeDisplay", true)
        end
    end
    model.PrimaryPart = primary
    model:PivotTo(CFrame.identity)
    return model
end

local skin_messages = {Gun = "", Knife = ""}
local catalog_ids = {Gun = {}, Knife = {}}
local http = game:GetService("HttpService")

function app.refresh_skin_catalog(force)
    local changed = false
    for _, player in ipairs(Players:GetPlayers()) do
        local character = player.Character
        for _, kind in ipairs({"Knife", "Gun"}) do
            local ref = character and character:FindFirstChild("DisplayRef" .. kind)
            local source = ref and ref:IsA("ObjectValue") and ref.Value
            local id = player:GetAttribute("Equipped" .. kind)
            local tool = character and character:FindFirstChild(kind)
            if not tool and player == local_player then tool = local_player.Backpack:FindFirstChild(kind) end
            if tool and tool:IsA("Tool") then
                native_grips[kind] = tool.Grip
                if skin_templates[kind][id] then skin_templates[kind][id]:SetAttribute("HandMount", tool.Grip) end
            end
            if source and type(id) == "string" and not skin_templates[kind][id] then
                local clone = clean_visual_clone(source)
                if clone then
                    if clone:GetAttribute("NativeDisplay") then
                        skin_templates[kind][id] = clone
                        if tool and tool:IsA("Tool") then clone:SetAttribute("HandMount", tool.Grip) end
                        changed = true
                    else clone:Destroy() end
                end
            end
        end
    end
    if force == true then
        app.skin_catalog = nil
    end
    if app.skin_catalog and not changed then return app.skin_catalog end
    if changed then app.skin_revision += 1 end
    local options = {Knife = {"Original"}, Gun = {"Original"}}
    local weapons = Sync.Weapons or Sync.Item or {}
    local counts = {Knife = {}, Gun = {}}
    for _, item in pairs(weapons) do
        if type(item) == "table" and counts[item.ItemType] then
            local name = tostring(item.ItemName or "Unknown")
            counts[item.ItemType][name] = (counts[item.ItemType][name] or 0) + 1
        end
    end
    for _, kind in ipairs({"Knife", "Gun"}) do
        table.clear(catalog_ids[kind])
        local labels = {}
        for id, item in pairs(weapons) do
            if type(item) == "table" and item.ItemType == kind and skin_templates[kind][id] and skin_templates[kind][id]:GetAttribute("NativeDisplay") then
                local name = tostring(item.ItemName or id)
                local label = (counts[kind][name] > 1 or name == "Original") and (name .. " [" .. tostring(id) .. "]") or name
                catalog_ids[kind][label] = id
                table.insert(labels, label)
            end
        end
        table.sort(labels)
        for _, label in ipairs(labels) do table.insert(options[kind], label) end
    end
    app.skin_catalog = options
    return options
end

local function restore_skin_hidden(kind)
    for object, record in pairs(skin_hidden[kind] or {}) do
        if object.Parent then object[record.key] = record.value end
    end
    skin_hidden[kind] = {}
end

local function clear_skin(kind)
    if skin_overlays[kind] then skin_overlays[kind].model:Destroy(); skin_overlays[kind] = nil end
    restore_skin_hidden(kind)
end

local function weapon_visual(kind)
    local character = local_player.Character
    if not character then return nil end
    local tool = character:FindFirstChild(kind)
    if tool and tool:IsA("Tool") then return tool:FindFirstChild("Handle") end
    local ref = character:FindFirstChild("DisplayRef" .. kind)
    return ref and ref:IsA("ObjectValue") and ref.Value or nil
end

local function attach_effect(model)
    local root = model.PrimaryPart
    local color = app.settings.skin_color
    local choice = app.settings.skin_effect
    if choice == "Fire" then
        local effect = Instance.new("Fire"); effect.Color, effect.SecondaryColor = color, Color3.new(1, 1, 1)
        effect.Size, effect.Heat, effect.Parent = 3, 2, root
    elseif choice == "Sparkles" then
        local effect = Instance.new("Sparkles"); effect.SparkleColor, effect.Parent = color, root
    elseif choice == "Smoke" then
        local effect = Instance.new("Smoke"); effect.Color, effect.Opacity, effect.Size, effect.RiseVelocity, effect.Parent = color, 0.25, 2, 2, root
    elseif choice == "Trail" then
        local first, second = Instance.new("Attachment"), Instance.new("Attachment")
        first.Position, second.Position = Vector3.new(0, 0.6, 0), Vector3.new(0, -0.6, 0)
        first.Parent, second.Parent = root, root
        local trail = Instance.new("Trail")
        trail.Attachment0, trail.Attachment1 = first, second
        trail.Color, trail.Lifetime, trail.LightEmission = ColorSequence.new(color), 0.3, 1
        trail.Parent = root
    end
end

local function update_skin(kind)
    local target = weapon_visual(kind)
    if not app.settings.skins or not target or not target.Parent then
        if skin_overlays[kind] then clear_skin(kind) end
        if not app.settings.skins then app.skin_status = "Original" end
        return
    end
    local part = target:IsA("BasePart") and target or target:FindFirstChildWhichIsA("BasePart", true)
    if not part then clear_skin(kind); return end
    local selection_key = kind == "Knife" and "knife_skin" or "gun_skin"
    local selection = app.settings[selection_key] or "Original"
    if selection ~= "Original" and not table.find(app.skin_catalog[kind], selection) then
        selection = "Original"
        app.settings[selection_key] = selection
    end
    if selection == "Original" and app.settings.skin_style == "Original" and app.settings.skin_effect == "None" then
        clear_skin(kind)
        skin_messages[kind] = "Original"
        return
    end
    local stamp = tostring(app.skin_revision) .. selection .. app.settings.skin_style .. app.settings.skin_effect .. tostring(app.settings.skin_color)
    local overlay = skin_overlays[kind]
    if not overlay or overlay.target ~= target or overlay.stamp ~= stamp then
        if overlay then clear_skin(kind) end
        local template = skin_templates[kind][catalog_ids[kind][selection] or selection]
        if selection ~= "Original" and not template then
            app.settings[selection_key] = "Original"
            app.skin_status = kind .. ": Original"
            return
        end
        local model = template and template:Clone() or clean_visual_clone(target)
        if not model then app.runtime_failures.skins = "Visual model unavailable"; return end
        if selection ~= "Original" and not template then app.skin_status = "Selected skin is not loaded in this server"
        else skin_messages[kind] = selection .. " — active" end
        app.skin_status = "Gun: " .. skin_messages.Gun .. " | Knife: " .. skin_messages.Knife
        local style = app.settings.skin_style
        for _, object in ipairs(model:GetDescendants()) do
            if object:IsA("BasePart") and style ~= "Original" then
                object.Color = style == "Gold" and Color3.fromRGB(255, 194, 50) or app.settings.skin_color
                object.Material = style == "Gold" and Enum.Material.Metal or style == "Ice" and Enum.Material.Glass or Enum.Material.Neon
                if object:IsA("MeshPart") then object.TextureID = "" end
            elseif object:IsA("SpecialMesh") and style ~= "Original" then object.TextureId = "" end
        end
        local objects = target:GetDescendants(); table.insert(objects, target)
        skin_hidden[kind] = {}
        for _, object in ipairs(objects) do
            if object:IsA("BasePart") then
                skin_hidden[kind][object] = {key = "LocalTransparencyModifier", value = object.LocalTransparencyModifier}
                object.LocalTransparencyModifier = 1
            elseif object:IsA("ParticleEmitter") or object:IsA("Trail") or object:IsA("Beam") or object:IsA("Fire") or object:IsA("Smoke") or object:IsA("Sparkles") then
                skin_hidden[kind][object] = {key = "Enabled", value = object.Enabled}; object.Enabled = false
            end
        end
        attach_effect(model)
        model:SetAttribute("Skin", selection)
        model:SetAttribute("Kind", kind)
        model.Parent = workspace.CurrentCamera
        local target_mount = CFrame.identity
        local rigid = target:FindFirstChildWhichIsA("RigidConstraint", true)
        if rigid then
            for _, attachment in ipairs({rigid.Attachment1, rigid.Attachment0}) do
                if attachment and attachment:IsDescendantOf(target) then
                    target_mount = part.CFrame:ToObjectSpace(attachment.WorldCFrame)
                    break
                end
            end
        else
            local character = local_player.Character
            for _, joint in ipairs(character and character:GetDescendants() or {}) do
                if joint:IsA("JointInstance") and joint.Part1 == part and joint.Name == "RightGrip" then
                    target_mount = joint.C1
                    break
                end
            end
        end
        local hand_mount = model:GetAttribute("HandMount") or native_grips[kind] or target_mount
        local correction = target_mount * hand_mount:Inverse()
        local body = rigid and (rigid.Attachment0 and rigid.Attachment0.Parent)
        if body and body:IsDescendantOf(target) then body = rigid.Attachment1 and rigid.Attachment1.Parent end
        local belt_offset
        if body and body:IsA("BasePart") and model:GetAttribute("NativeDisplay") then
            belt_offset = CFrame.new(model:GetAttribute("BeltPosition") * body.Size)
                * model:GetAttribute("BeltRotation") * model:GetAttribute("BeltMount"):Inverse()
        end
        overlay = {model = model, target = target, stamp = stamp, correction = correction, body = body, belt_offset = belt_offset}
        skin_overlays[kind] = overlay
    end
    if overlay.belt_offset and overlay.body and overlay.body.Parent then
        overlay.model:PivotTo(overlay.body.CFrame * overlay.belt_offset)
    else
        overlay.model:PivotTo(part.CFrame * overlay.correction)
    end
    for object, record in pairs(skin_hidden[kind]) do
        if object.Parent then object[record.key] = record.key == "LocalTransparencyModifier" and 1 or false end
    end
    if app.settings.skin_style == "Rainbow" then
        local color = Color3.fromHSV((os.clock() * 0.15) % 1, 0.8, 1)
        for _, object in ipairs(overlay.model:GetDescendants()) do if object:IsA("BasePart") then object.Color = color end end
    end
end

function app.extra_diagnostics()
    local overlays = 0
    for _ in pairs(skin_overlays) do overlays += 1 end
    local percent, unavailable = app.refresh_features()
    return {load_percent = percent, unavailable = unavailable, executor_missing = app.executor_report(),
        overlays = overlays, skin_status = app.skin_status, anti_afk_connections = #idle_connections}
end

function app.cleanup_extras()
    app.set_anti_afk(false)
    for _, kind in ipairs({"Knife", "Gun"}) do
        clear_skin(kind)
        for _, template in pairs(skin_templates[kind]) do template:Destroy() end
        table.clear(skin_templates[kind])
    end
    if spectate_original and workspace.CurrentCamera then workspace.CurrentCamera.CameraSubject = spectate_original end
    spectate_original = nil
    for part, color in pairs(rainbow_originals) do if part.Parent then part.Color = color end end
    table.clear(rainbow_originals)
end

local cinematic_originals = {}
function app.update_cinematic()
    local camera = workspace.CurrentCamera
    local lighting = game:GetService("Lighting")
    local function apply(object, key, enabled, value)
        local record = cinematic_originals[object]
        if enabled then
            if not record then record = {}; cinematic_originals[object] = record end
            if record[key] == nil then record[key] = object[key] end
            object[key] = value
        elseif record and record[key] ~= nil then
            object[key] = record[key]
            record[key] = nil
        end
    end
    if camera then apply(camera, "FieldOfView", app.settings.cinematic_fov, app.settings.camera_fov) end
    apply(lighting, "Brightness", app.settings.fullbright, 3)
    apply(lighting, "Ambient", app.settings.fullbright, Color3.fromRGB(220,220,220))
    apply(lighting, "GlobalShadows", app.settings.fullbright, false)
end
function app.reset_cinematic()
    for object, record in pairs(cinematic_originals) do
        if object.Parent then for key, value in pairs(record) do object[key] = value end end
    end
    table.clear(cinematic_originals)
end
local extras_elapsed = 0
function app.extra_render(dt)
    app.update_cinematic()
    local character, root, humanoid = character_parts(local_player)
    local camera = workspace.CurrentCamera
    local target = target_player()
    if app.settings.troll_spectate and target and camera then
        if not spectate_original then spectate_original = camera.CameraSubject end
        camera.CameraSubject = target.Character:FindFirstChildOfClass("Humanoid")
    elseif spectate_original and camera then
        camera.CameraSubject = (humanoid and humanoid.Health > 0) and humanoid or spectate_original
        spectate_original = nil
    end
    if app.settings.troll_spin and root and not motion.owner then
        remember_property(humanoid, "AutoRotate", false)
        root.CFrame *= CFrame.Angles(0, math.rad(app.settings.spin_speed) * math.min(dt, 0.1), 0)
    elseif humanoid and not motion.owner then restore_property(humanoid, "AutoRotate") end
    if app.settings.troll_rainbow and character then
        local color = Color3.fromHSV((os.clock() * 0.2) % 1, 0.8, 1)
        for _, part in ipairs(character:GetChildren()) do
            if part:IsA("BasePart") then
                if not rainbow_originals[part] then rainbow_originals[part] = part.Color end
                part.Color = color
            end
        end
    elseif next(rainbow_originals) then
        for part, color in pairs(rainbow_originals) do if part.Parent then part.Color = color end end
        table.clear(rainbow_originals)
    end
    update_skin("Knife"); update_skin("Gun")
    if app.settings.skins then
        local messages = {}
        for _, kind in ipairs({"Gun", "Knife"}) do
            local selection = app.settings[kind == "Gun" and "gun_skin" or "knife_skin"]
            if selection ~= "Original" and not skin_templates[kind][catalog_ids[kind][selection] or selection] then
                table.insert(messages, selection .. (skin_messages[kind]:find("unavailable") and " — 3D unavailable" or " — loading"))
            end
        end
        if #messages > 0 then app.skin_status = table.concat(messages, " / ") end
    end
    extras_elapsed += dt
    if app.settings.skins and (not app.next_skin_scan or os.clock() >= app.next_skin_scan) then
        app.next_skin_scan = os.clock() + 1
        app.refresh_skin_catalog()
    end
    if extras_elapsed >= 10 then
        extras_elapsed = 0
        if app.settings.anti_afk then app.set_anti_afk(true) end
        app.refresh_skin_catalog()
    end
end
connect(UserInputService.WindowFocused, function() app.focused = true end)
connect(UserInputService.WindowFocusReleased, function() app.focused = false end)
connect(Players.PlayerAdded, function() app.refresh_targets() end)
connect(Players.PlayerRemoving, function() task.defer(app.refresh_targets) end)


local trigger_params = RaycastParams.new()
trigger_params.FilterType = Enum.RaycastFilterType.Exclude
local function trigger_step(camera, cursor, clip)
    if (not clip and not app.settings.trigger) or app.finish_active or not app.has_focus() or UserInputService:GetFocusedTextBox() then return end
    local gun = equipped_weapon()
    if not gun or gun.Name ~= "Gun" or not active_player(local_player) or os.clock()-last_attack < 3.1 then return end
    trigger_params.FilterDescendantsInstances = {local_player.Character, camera}
    local ray = camera:ViewportPointToRay(cursor.X, cursor.Y)
    local hit = workspace:Raycast(ray.Origin,ray.Direction * app.settings.aim_distance,trigger_params)
    local body = hit and hit.Instance:FindFirstAncestorOfClass("Model")
    local target = body and Players:GetPlayerFromCharacter(body)
    if target and eligible_target(target) then
        app.trigger_target = {player=target,part=hit.Instance}
        app.trigger_until = os.clock()+0.15
        if clip then app.clip_target_until = app.trigger_until end
        last_attack=os.clock()
        gun:Activate()
        app.stats.trigger_shots=(app.stats.trigger_shots or 0)+1
        return true
    end
    return false
end

local stream_core = {}
function app.set_stream(enabled)
    local was = app.settings.streamer
    app.settings.streamer = enabled == true
    local starter = game:GetService("StarterGui")
    for _,key in ipairs({Enum.CoreGuiType.Chat,Enum.CoreGuiType.PlayerList}) do
        if enabled and stream_core[key]==nil then
            local ok,visible=pcall(starter.GetCoreGuiEnabled,starter,key)
            if ok then
                stream_core[key]=visible
                pcall(starter.SetCoreGuiEnabled,starter,key,false)
            end
        elseif not enabled and stream_core[key]~=nil then
            pcall(starter.SetCoreGuiEnabled,starter,key,stream_core[key])
            stream_core[key]=nil
        end
    end
    if was~=enabled and app.alive then
        app.settings.troll_target="None"
        app.refresh_targets()
        if app.controls.troll_target then app.controls.troll_target:Set("None") end
    end
end

local bomb_ready=0
function app.stop_clip()
    local spin=app.clip_spin
    app.clip_spin=nil
    if spin and spin.camera.Parent then
        spin.camera.CFrame=spin.start
        spin.camera.CameraType=spin.mode
    end
    local bomb=app.clip_bomb
    app.clip_bomb=nil
    if bomb and bomb.tool.Parent==bomb.character then
        bomb.tool.Parent=bomb.folder
        if bomb.previous and bomb.previous.Parent and bomb.humanoid.Health>0 then bomb.humanoid:EquipTool(bomb.previous) end
    end
end

function app.bomb_jump()
    if os.clock()<bomb_ready then return false,string.format("%.0fs",math.ceil(bomb_ready-os.clock())) end
    local character,root,humanoid=character_parts(local_player)
    local backpack=local_player:FindFirstChildOfClass("Backpack")
    local toy=character and character:FindFirstChild("FakeBomb") or backpack and backpack:FindFirstChild("FakeBomb",true)
    if not root or not humanoid or humanoid.Health<=0 or not toy or not toy:IsA("Tool") or not toy:FindFirstChild("Remote") then return false,"FakeBomb indisponível / unavailable" end
    if humanoid.FloorMaterial==Enum.Material.Air then return false,"Começa no chão / start on the ground" end
    app.stop_clip()
    local state={tool=toy,folder=toy.Parent==character and backpack or toy.Parent,previous=character:FindFirstChildOfClass("Tool"),character=character,humanoid=humanoid}
    app.clip_bomb=state
    if toy.Parent~=character then toy.Parent=backpack;humanoid:EquipTool(toy) end
    humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
    task.spawn(function()
        local start=os.clock()
        repeat RunService.Heartbeat:Wait() until app.clip_bomb~=state or not root.Parent or os.clock()-start>.55 or (os.clock()-start>.1 and root.AssemblyLinearVelocity.Y<5)
        if app.clip_bomb~=state then return end
        if not root.Parent or humanoid.Health<=0 or toy.Parent~=character then app.stop_clip();return end
        bomb_ready=os.clock()+22
        toy.Remote:FireServer(CFrame.new(root.Position-Vector3.yAxis*3),50)
        local v=root.AssemblyLinearVelocity
        local jump=humanoid.UseJumpPower and humanoid.JumpPower or math.sqrt(2*workspace.Gravity*humanoid.JumpHeight)
        root.AssemblyLinearVelocity=Vector3.new(v.X,math.max(v.Y,jump),v.Z)
        app.stats.bomb_jump_velocity=root.AssemblyLinearVelocity.Y
        task.wait(.35)
        if app.clip_bomb==state then app.stop_clip() end
    end)
    return true
end

function app.start_spin()
    local gun=has_weapon(local_player,"Gun")
    local _,root,humanoid=character_parts(local_player)
    local camera=workspace.CurrentCamera
    if not gun or not root or not humanoid or not camera or not active_player(local_player) then return false,"É preciso uma pistola na ronda / gun required" end
    app.stop_clip()
    if gun.Parent~=local_player.Character then humanoid:EquipTool(gun) end
    app.clip_spin={start=camera.CFrame, mode=camera.CameraType,camera=camera,root=root,origin=root.Position,angle=0}
    camera.CameraType=Enum.CameraType.Scriptable
    return true
end

function app.spin_step(camera,dt)
    local state=app.clip_spin
    if state.camera~=camera or not state.root.Parent or not active_player(local_player) or not app.has_focus() then app.stop_clip();return end
    local finish=math.min(360,state.angle+app.settings.spin_speed_clip*math.min(dt,.08))
    local steps=math.max(1,math.ceil((finish-state.angle)/1.5))
    for i=1,steps do
        local yaw=math.rad(state.angle+(finish-state.angle)*i/steps)
        camera.CFrame=CFrame.new(state.start.Position+state.root.Position-state.origin)*CFrame.Angles(0,yaw,0)*state.start.Rotation
        if trigger_step(camera,camera.ViewportSize/2,true) then
            app.stats.clip_shots=(app.stats.clip_shots or 0)+1
            app.stop_clip()
            return
        end
    end
    state.angle=finish
    if finish>=360 then app.stop_clip() end
end

function app.render_step(dt)
    if not app.alive or app.rebuilding then return end
    local camera = workspace.CurrentCamera
    if not camera then return end
    app.stats.frames += 1
    app.extra_render(dt)
    local cursor = cursor_position(camera)
    if app.clip_spin then app.spin_step(camera,dt) else trigger_step(camera,cursor) end
    fov.Color = app.settings.fov_color
    fov.Position = cursor
    fov.Radius = app.settings.fov
    fov.Visible = app.settings.fov_circle and (app.settings.aim or app.settings.silent)
    for player, visual in pairs(app.visuals) do
        local character, root, humanoid = character_parts(player)
        local role = player_role(player)
        local show = app.settings.esp and root ~= nil and humanoid ~= nil and humanoid.Health > 0
            and (role ~= "Lobby" or app.settings.lobby)
            and (role ~= "Innocent" or app.settings.show_innocents)
            and (camera.CFrame.Position - root.Position).Magnitude <= app.settings.esp_distance
            and (not app.settings.esp_visible or visible_target(root, camera))
        skeleton_step(visual,character,camera,show and app.settings.skeleton,colors[role] or colors.Innocent)
        visual.hp_track.Visible, visual.hp_fill.Visible = false, false
        visual.tracer.Visible = false
        visual.box.Visible = false
        visual.text.Visible = false
        visual.highlight.Enabled = show and app.settings.chams
        visual.highlight.Adornee = character
        if show then
            local color = colors[role] or colors.Innocent
            visual.highlight.FillTransparency = 1 - app.settings.highlight_opacity
            visual.highlight.FillColor = color
            visual.highlight.OutlineColor = color
            local top, on_screen = camera:WorldToViewportPoint(root.Position + Vector3.new(0, 3, 0))
            local bottom = camera:WorldToViewportPoint(root.Position - Vector3.new(0, 3, 0))
            if on_screen and bottom.Z > 0 then
                local height = math.abs(bottom.Y - top.Y)
                local width = height * 0.58
                if app.settings.health_bar then
                    local ratio=math.clamp(humanoid.Health/math.max(1,humanoid.MaxHealth),0,1)
                    local x=top.X-width/2-5
                    local y=math.max(top.Y,bottom.Y)
                    visual.hp_track.From,visual.hp_track.To=Vector2.new(x,y),Vector2.new(x,y-height)
                    visual.hp_fill.From,visual.hp_fill.To=visual.hp_track.From,Vector2.new(x,y-height*ratio)
                    visual.hp_fill.Color=Color3.fromHSV(ratio/3,0.85,0.95)
                    visual.hp_track.Visible,visual.hp_fill.Visible=true,ratio>0
                end
                visual.box.Position = Vector2.new(top.X - width / 2, math.min(top.Y, bottom.Y))
                visual.box.Size = Vector2.new(width, height)
                visual.box.Thickness = app.settings.line_thickness
                visual.box.Color = color
                visual.box.Visible = app.settings.boxes
                visual.text.Position = Vector2.new(top.X, math.min(top.Y, bottom.Y) - 18)
                local caption = {}
                if app.settings.names then table.insert(caption, identity(player)) end
                if app.settings.role_labels then table.insert(caption, app.settings.locale == "pt" and (role_names[role] or role) or role) end
                if app.settings.distance_labels then table.insert(caption, string.format("%.0fm", (camera.CFrame.Position - root.Position).Magnitude / 3.57)) end
                if app.settings.health then table.insert(caption, string.format("HP %.0f", humanoid.Health)) end
                visual.text.Text = table.concat(caption, " | ")
                visual.text.Size = app.settings.text_size
                visual.text.Color = color
                visual.text.Visible = #caption > 0
                visual.tracer.From = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y)
                visual.tracer.To = Vector2.new(bottom.X, bottom.Y)
                visual.tracer.Color = color
                visual.tracer.Thickness = app.settings.line_thickness
                visual.tracer.Visible = app.settings.tracers
            end
        end
    end
    gun_label.Visible = false
    if app.settings.gun_esp and app.gun_drop and app.gun_drop.Parent then
        local part = app.gun_drop:IsA("BasePart") and app.gun_drop or app.gun_drop:FindFirstChildWhichIsA("BasePart", true)
        if part then
            local point, shown = camera:WorldToViewportPoint(part.Position)
            gun_label.Position = Vector2.new(point.X, point.Y)
            gun_label.Text = app.settings.locale == "pt" and "ARMA NO CHAO" or "DROPPED GUN"
            gun_label.Visible = shown
        end
    end
    local label_index = 0
    for _, label in ipairs(coin_labels) do label.Visible = false end
    if app.settings.coin_esp then
        for _, coin in ipairs(app.coin_parts) do
            if label_index >= #coin_labels then break end
            if valid_coin(coin) then
                local point, shown = camera:WorldToViewportPoint(coin.Position)
                if shown then
                    label_index += 1
                    local label = coin_labels[label_index]
                    label.Position = Vector2.new(point.X, point.Y)
                    label.Text = tostring(coin:GetAttribute("CoinID") or "Coins")
                    label.Visible = true
                end
            end
        end
    end
    app.target = nil
    if not app.clip_spin and app.settings.aim and app.aim_pressed()
        and not UserInputService:GetFocusedTextBox() and app.has_focus() then
        local target = app.select_target()
        app.target = target
        if target then
            local point = camera:WorldToViewportPoint(predicted_position(target))
            local delta = Vector2.new(point.X, point.Y) - cursor
            local alpha = 1 - math.exp(-60 * dt / app.settings.smoothing)
            mousemoverel(math.clamp(delta.X * alpha, -80, 80), math.clamp(delta.Y * alpha, -80, 80))
            app.stats.aim_moves += 1
        end
    end
end

function app.diagnostics()
    local visible, highlights, connections, boxes, names, coin_markers, collision_overrides = 0, 0, 0, 0, 0, 0, 0
    for _, object in ipairs(app.drawings) do if object.Visible then visible += 1 end end
    for _, visual in pairs(app.visuals) do
        if visual.highlight.Enabled then highlights += 1 end
        if visual.box.Visible then boxes += 1 end
        if visual.text.Visible then names += 1 end
    end
    for _, label in ipairs(coin_labels) do if label.Visible then coin_markers += 1 end end
    for _ in pairs(app.collisions) do collision_overrides += 1 end
    for _, connection in ipairs(app.connections) do if connection.Connected then connections += 1 end end
    local target = app.select_target()
    return {alive = app.alive, role = player_role(local_player), active = active_player(local_player),
        farm = app.farm_status, coins = #app.coin_parts, bags = app.bags, stats = app.stats,
        visible_drawings = visible, highlights = highlights, connections = connections,
        boxes = boxes, names = names, coin_markers = coin_markers, gun_marker = gun_label.Visible,
        fov_visible = fov.Visible, fov_radius = fov.Radius, collision_overrides = collision_overrides,
        drawing_handles = #app.drawings,
        target = target and target.player.Name or "nenhum", errors = app.errors,
        weapon = equipped_weapon() and equipped_weapon().Name or "nenhuma"}
end

local translations = {pt = {
    ["Round"]="Ronda",["Clips"]="Clipes",["Health bar"]="Barra de vida",["Streamer mode"]="Modo streamer",
    ["Choose a gun"]="Escolher pistola",["Choose a knife"]="Escolher faca",["Bomb double jump"]="Salto duplo com bomba",
    ["Spin and shoot"]="Girar e disparar",["Cancel clip"]="Cancelar clipe",["Rotation speed"]="Velocidade do giro",
    ["Only loaded models appear. Refresh to discover newly replicated skins."]="Apenas modelos carregados. Atualiza para encontrar novas skins disponíveis.",
    ["Skeleton"]="Esqueleto", ["Trigger bot"]="Disparo ao passar a mira", ["Kill all as Murderer"]="Eliminar todos como Murderer", ["Murderer role required"]="É preciso ser o Murderer",
    ["UI library"]="Biblioteca da interface", ["Gun A–Z"]="Pistolas A–Z", ["Knife A–Z"]="Facas A–Z",
    ["Local skins"] = "Skins locais", ["Target player"] = "Jogador alvo", ["Refresh players"] = "Atualizar jogadores",
    ["Follow target"] = "Seguir alvo", ["Orbit target"] = "Orbitar alvo", ["Orbit radius"] = "Raio da orbita",
    ["Orbit height"] = "Altura da orbita", ["Orbit speed"] = "Velocidade da orbita", ["Spectate target"] = "Observar alvo",
    ["Spin"] = "Girar", ["Spin speed"] = "Velocidade de rotacao", ["Rainbow character (local)"] = "Personagem arco-iris (local)",
    ["Fling selected target"] = "Fling no alvo selecionado", ["Stop Troll"] = "Parar Troll", ["None"] = "Nenhum",
    ["Select an available target and check executor compatibility."] = "Seleciona um alvo disponivel e verifica a compatibilidade do executor.",
    ["Fling is experimental; server physics can reject it. Each attempt is bounded."] = "Fling experimental: a fisica do servidor pode rejeitar. Cada tentativa tem limite de tempo.",
    ["Local skin changer"] = "Skins locais", ["Knife model"] = "Modelo da faca", ["Gun model"] = "Modelo da pistola",
    ["Material / style"] = "Material / estilo", ["Local effect"] = "Efeito local", ["Skin color"] = "Cor da skin",
    ["Refresh skin catalog"] = "Atualizar catalogo de skins", ["Restore original visuals"] = "Restaurar visual original",
    ["Local visuals active"] = "Visuais locais ativos", ["Selected skin is not loaded in this server"] = "Skin selecionada nao carregada neste servidor",
    ["Following target"] = "A seguir alvo", ["Orbiting target"] = "A orbitar alvo", ["Load status"] = "Estado do carregamento",
    ["Executor compatibility"] = "Compatibilidade do executor", ["All modules loaded"] = "Todos os modulos carregados",
    ["Missing APIs"] = "APIs em falta", ["All required APIs available"] = "Todas as APIs necessarias disponiveis",
    ["Unavailable feature"] = "Funcao indisponivel", ["Disabled modules"] = "Modulos indisponiveis",
    ["Disables idle callbacks without clicking or activating weapons."] = "Desativa callbacks de inatividade sem clicar nem ativar armas.",
    ["Custom camera FOV"]="Campo de visão da câmara", ["Camera FOV"]="Ângulo da câmara", ["Fullbright"]="Iluminação clara",
    ["Aimbot"]="Mira", ["Farm"]="Farm", ["Skins"]="Aparências", ["Visuals"] = "Visuais", ["Movement"] = "Movimento", ["Boxes"] = "Caixas", ["Settings"] = "Configuracoes", ["About"] = "Sobre",
    ["Account age"] = "Dias da conta", ["Executor"] = "Executor", ["Load time"] = "Carregamento", ["Session XP"] = "XP da sessao",
    ["Role ESP"] = "ESP por papel", ["Player names"] = "Nomes dos jogadores", ["Role labels"] = "Mostrar papeis",
    ["Distance labels"] = "Mostrar distancia", ["Health"] = "Vida", ["Tracers"] = "Linhas", ["Highlights"] = "Contornos",
    ["Show lobby"] = "Mostrar lobby", ["Show innocents"] = "Mostrar inocentes", ["Visible only"] = "Apenas visiveis",
    ["Dropped gun ESP"] = "ESP da arma no chao", ["Coin ESP"] = "ESP de moedas", ["ESP distance"] = "Distancia do ESP",
    ["Line thickness"] = "Espessura das linhas", ["Text size"] = "Tamanho do texto", ["Highlight opacity"] = "Opacidade do contorno",
    ["Murderer"] = "Assassino", ["Sheriff"] = "Xerife", ["Hero"] = "Heroi", ["Innocent"] = "Inocente",
    ["Activation"] = "Ativacao", ["Hold"] = "Segurar", ["Toggle"] = "Alternar", ["Always"] = "Sempre",
    ["Aim key"] = "Tecla de mira", ["Show FOV"] = "Mostrar FOV", ["Wall check"] = "Verificar paredes",
    ["Targets"] = "Alvos", ["By role"] = "Por papel", ["All"] = "Todos", ["Target part"] = "Parte do corpo",
    ["Target priority"] = "Prioridade do alvo", ["Cursor"] = "Cursor", ["Distance"] = "Distancia",
    ["Aim distance"] = "Distancia de mira", ["FOV radius"] = "Raio do FOV", ["Smoothing"] = "Suavizacao",
    ["Prediction (seconds)"] = "Previsao (segundos)", ["Silent hit chance"] = "Probabilidade do silent", ["FOV color"] = "Cor do FOV",
    ["Auto farm"] = "Auto farm", ["Movement mode"] = "Metodo de movimento", ["Underground"] = "Por baixo", ["Teleport"] = "Teleporte",
    ["Collectibles"] = "Colecionaveis", ["Farm speed"] = "Velocidade do farm", ["Underground depth"] = "Profundidade por baixo",
    ["Avoid murderer"] = "Distancia do assassino", ["When bag is full"] = "Quando a mochila encher",
    ["Wait"] = "Esperar", ["Reset"] = "Dar reset", ["Lobby"] = "Voltar ao lobby", ["Finish round"] = "Acabar a rodada",
    ["Innocent action"] = "Acao como inocente", ["Wait for gun"] = "Esperar pela arma", ["XP farm"] = "Farm de XP",
    ["XP escape distance"] = "Distancia de fuga no farm XP", ["Auto pickup gun"] = "Apanhar arma automaticamente",
    ["Pick up gun now"] = "Apanhar arma agora", ["Finish this round"] = "Acabar esta rodada", ["Stop round action"] = "Parar acao da rodada",
    ["Flight"] = "Voo", ["Flight speed"] = "Velocidade do voo", ["Custom speed"] = "Alterar velocidade",
    ["Walk speed"] = "Velocidade", ["Custom jump"] = "Alterar salto", ["Jump power"] = "Forca do salto", ["Infinite jump"] = "Salto infinito",
    ["Flight key"] = "Tecla de voo", ["Box"] = "Caixa", ["Currency"] = "Moeda", ["Quantity"] = "Quantidade",
    ["Review purchase"] = "Rever compra", ["Stop opening"] = "Parar abertura", ["Cancel"] = "Cancelar", ["Confirm purchase"] = "Confirmar compra",
    ["Language"] = "Idioma", ["Save configuration"] = "Guardar configuracao", ["Load configuration"] = "Carregar configuracao",
    ["Theme"] = "Tema", ["Diagnostics"] = "Diagnostico", ["Stop all"] = "Desligar tudo", ["Unload"] = "Fechar e limpar",
    ["Menu key"] = "Tecla do menu", ["Creator"] = "Criador", ["Library"] = "Library", ["References"] = "Referencias",
    ["Normal uses gradual movement. Teleport can be rejected by the server."] = "Normal move-se gradualmente. O servidor pode rejeitar teleporte.",
    ["Reset resumes farming next round. Lobby stops farming and returns through respawn."] = "Reset retoma o farm na rodada seguinte. Lobby para o farm e regressa pelo respawn.",
    ["Survives rounds and retreats from the murderer. XP is awarded by the server."] = "Sobrevive as rodadas e afasta-se do assassino. O servidor atribui o XP.",
    ["WASD moves; E rises; Q descends. Fling is a separate round action."] = "WASD move; E sobe; Q desce. Fling e uma acao separada da rodada.",
    ["Purchases always require a fresh cost confirmation; opening never resumes from a config."] = "Cada compra exige confirmacao do custo; a abertura nunca reinicia pela configuracao.",
    ["Idle"] = "Desligado", ["Waiting for round"] = "A aguardar rodada", ["Bag full"] = "Mochila cheia",
    ["XP: surviving the round"] = "XP: a sobreviver a rodada", ["Waiting for dropped gun"] = "A esperar pela arma",
    ["Picking up gun"] = "A apanhar arma", ["Movement correction: paused"] = "Correcao de posicao: pausa",
    ["No collectible in range"] = "Sem colecionaveis ao alcance", ["Finished"] = "Concluido",
    ["No active round"] = "Sem rodada ativa", ["Collecting"] = "A recolher", ["Opening"] = "A abrir",
    ["Waiting for roles"] = "A aguardar papeis", ["Waiting for weapon"] = "A aguardar arma",
    ["Stopped after 3 movement corrections"] = "Parado apos 3 correcoes de posicao",
    ["A fling attempt lasts 6 seconds and restores physics afterwards."] = "Uma tentativa de fling dura 6 segundos e restaura a fisica no fim.",
    ["Infinite Yield / EdgeIY: flight, noclip, fling concepts.\nZynic MM2 AutoFarm: closest coin and timed movement.\nOminousVibes MM2: role ESP, gun drop and prediction.\nCurrent game inspection: weapons, shop, coin bag events."] = "Infinite Yield / EdgeIY: conceitos de voo, noclip e fling.\nZynic MM2 AutoFarm: moeda mais proxima e movimento gradual.\nOminousVibes MM2: ESP por papel, arma e previsao.\nInspecao do jogo atual: armas, loja e eventos da mochila.",
}, en = {["Todos"] = "All"}}
local function tr(text)
    local pack = translations[app.settings.locale]
    if not pack then return text end
    if pack[text] then return pack[text] end
    for _, prefix in ipairs({"Collecting", "Opening", "Finish round"}) do
        if text:sub(1, #prefix) == prefix then return (pack[prefix] or prefix) .. text:sub(#prefix + 1) end
    end
    return text
end
app.translate = tr
function app.open_gallery(kind)
    app.refresh_skin_catalog()
    if app.gallery then app.gallery:Destroy() end
    local layer=Instance.new("Frame")
    layer.Name="SkinGallery"
    layer.Size=UDim2.fromScale(1,1)
    layer.BackgroundColor3=Color3.new(0,0,0)
    layer.BackgroundTransparency=.35
    layer.Active=true
    layer.ZIndex=10
    layer.Parent=app.launcher
    app.gallery=layer
    local frame=Instance.new("Frame")
    frame.Size=UDim2.fromScale(.85,.76)
    local limit=Instance.new("UISizeConstraint")
    limit.MaxSize=Vector2.new(660,510)
    limit.Parent=frame
    frame.AnchorPoint=Vector2.new(.5,.5)
    frame.Position=UDim2.fromScale(.5,.5)
    frame.BackgroundColor3=Color3.fromRGB(25,30,43)
    frame.ZIndex=11
    frame.Parent=layer
    Instance.new("UICorner",frame).CornerRadius=UDim.new(0,12)
    local title=Instance.new("TextLabel")
    title.Size=UDim2.new(1,-62,0,46)
    title.Position=UDim2.fromOffset(16,0)
    title.BackgroundTransparency=1
    title.TextColor3=Color3.fromRGB(240,243,251)
    title.TextXAlignment=Enum.TextXAlignment.Left
    title.Font=Enum.Font.GothamBold
    title.TextSize=19
    title.Text=tr(kind=="Gun" and "Choose a gun" or "Choose a knife")
    title.ZIndex=12
    title.Parent=frame
    local close=Instance.new("TextButton")
    close.Name="Close"
    close.Size=UDim2.fromOffset(36,30)
    close.Position=UDim2.new(1,-44,0,8)
    close.Text="×"
    close.TextSize=22
    close.TextColor3=Color3.new(1,1,1)
    close.BackgroundColor3=Color3.fromRGB(50,55,72)
    close.ZIndex=12
    close.Parent=frame
    close.Activated:Connect(function() layer:Destroy();app.gallery=nil end)
    local search=Instance.new("TextBox")
    search.Name="Search"
    search.PlaceholderText=app.settings.locale=="pt" and "Pesquisar skins" or "Search skins"
    search.Text=""
    search.ClearTextOnFocus=false
    search.Size=UDim2.new(1,-24,0,30)
    search.Position=UDim2.fromOffset(12,46)
    search.TextColor3=Color3.new(1,1,1)
    search.BackgroundColor3=Color3.fromRGB(39,45,62)
    search.ZIndex=12
    search.Parent=frame
    local footer=Instance.new("TextButton")
    footer.Name="NextPage"
    footer.Size=UDim2.new(1,-24,0,28)
    footer.Position=UDim2.new(0,12,1,-32)
    footer.TextColor3=Color3.new(1,1,1)
    footer.BackgroundColor3=Color3.fromRGB(39,45,62)
    footer.ZIndex=12
    footer.Parent=frame
    local scroll=Instance.new("ScrollingFrame")
    scroll.Size=UDim2.new(1,-24,1,-120)
    scroll.Position=UDim2.fromOffset(12,82)
    scroll.BackgroundTransparency=1
    scroll.BorderSizePixel=0
    scroll.ScrollBarThickness=4
    scroll.CanvasSize=UDim2.new()
    scroll.AutomaticCanvasSize=Enum.AutomaticSize.Y
    scroll.ZIndex=12
    scroll.Parent=frame
    local grid=Instance.new("UIGridLayout")
    grid.CellSize=UDim2.new(.32,-4,0,106)
    grid.CellPadding=UDim2.fromOffset(6,6)
    grid.SortOrder=Enum.SortOrder.LayoutOrder
    grid.Parent=scroll
    local key=kind:lower().."_skin"
    local page=1
    local function render()
        for _, child in ipairs(scroll:GetChildren()) do
            if child:IsA("GuiObject") then child:Destroy() end
        end
        local matches={}
        local query=search.Text:lower()
        for _, name in ipairs(app.skin_catalog[kind]) do
            if name:lower():find(query,1,true) then table.insert(matches,name) end
        end
        local pages=math.max(1,math.ceil(#matches/30))
        page=math.clamp(page,1,pages)
        footer.Text=string.format("%d / %d · %d skins   >",page,pages,#matches)
        scroll.CanvasPosition=Vector2.zero
        for i=(page-1)*30+1,math.min(page*30,#matches) do
        local name=matches[i]
        local id=catalog_ids[kind][name] or ("Default"..kind)
        local item=(Sync.Weapons or Sync.Item)[id]
        local tile=Instance.new("ImageButton")
        tile.Name=name
        tile.LayoutOrder=name=="Original" and 0 or i
        tile.BackgroundColor3=app.settings[key]==name and Color3.fromRGB(43,79,116) or Color3.fromRGB(39,45,62)
        tile.ScaleType=Enum.ScaleType.Fit
        local image = item and tostring(item.Image or "") or ""
        local image_id = image:match("[?&]assetId=(%d+)") or image:match("[?&]id=(%d+)")
        tile.Image = image:match("^rbxassetid://%d+") or (item and ("rbxthumb://type=Asset&id=" .. tostring(image_id or item.ItemID) .. "&w=150&h=150")) or ""
        tile.ZIndex=13
        tile.Parent=scroll
        Instance.new("UICorner",tile).CornerRadius=UDim.new(0,8)
        local label=Instance.new("TextLabel")
        label.Size=UDim2.new(1,0,0,24)
        label.Position=UDim2.new(0,0,1,-24)
        label.BackgroundColor3=Color3.fromRGB(23,27,37)
        label.BackgroundTransparency=.12
        label.TextColor3=Color3.new(1,1,1)
        label.Font=Enum.Font.GothamMedium
        label.TextSize=13
        label.Text=name
        label.ZIndex=14
        label.Parent=tile
        tile.Activated:Connect(function()
            app.settings[key]=name
            if name~="Original" then set_enabled("skins",true) end
            if capabilities.writefile and not env.ZERO_MM2_TEST then
                pcall(writefile,"ZERO-MM2-skins.json",http:JSONEncode({Gun=app.settings.gun_skin,Knife=app.settings.knife_skin}))
            end
            layer:Destroy()
            app.gallery=nil
        end)
        end
    end
    search:GetPropertyChangedSignal("Text"):Connect(function() page=1;render() end)
    footer.Activated:Connect(function()
        page+=1
        local query=search.Text:lower()
        local count=0
        for _, name in ipairs(app.skin_catalog[kind]) do
            if name:lower():find(query,1,true) then count+=1 end
        end
        if page>math.max(1,math.ceil(count/30)) then page=1 end
        render()
    end)
    render()
end

local libraries = {"WindUI", "Rayfield Gen2", "Fluent"}
local gui_file = "ZERO-MM2-library.txt"
local library_name = "WindUI"
if capabilities.isfile and capabilities.readfile then
    local ok, saved = pcall(function() return isfile(gui_file) and readfile(gui_file) end)
    if ok and table.find(libraries, saved) then library_name = saved end
end
local ui_urls = {
    WindUI = "https://github.com/Footagesus/WindUI/releases/latest/download/main.lua",
    Fluent = "https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua",
    ["Rayfield Gen2"] = "https://sirius.menu/gen2",
}
local rebuild_ui
local function adapted_window(engine, wind)
    local native = engine:CreateWindow(wind and {Title="ZERO | MM2", Author="Nandox", Folder="ZERO-MM2", Size=UDim2.fromOffset(650,490), ToggleKey=Enum.KeyCode.RightControl}
        or {Title="ZERO | MM2",SubTitle="Nandox",TabWidth=145,Size=UDim2.fromOffset(650,490),Theme="Dark",MinimizeKey=Enum.KeyCode.RightControl})
    local w = {unloaded=false}
    if wind then native:OnDestroy(function() w.unloaded=true end) end
    local states = {}
    local locale_items = {}
    local function localize(fn) table.insert(locale_items,fn) end
    function w:SetLocale()
        for _,fn in ipairs(locale_items) do pcall(fn) end
    end
    function w:Unload() self.unloaded=true; if wind then native:Destroy() else engine:Destroy() end end
    function w:Notify(o) engine:Notify({Title=o.title,Desc=o.content,Content=o.content,Duration=4}) end
    function w:ChangeTheme(theme)
        local themes = wind and {cobalt="Indigo",ember="Amber",amethyst="Violet",frost="Sky",rose="Rose",default="Dark"}
            or {cobalt="Dark",ember="Darker",amethyst="Amethyst",frost="Light",rose="Rose",default="Dark"}
        pcall(function() engine:SetTheme(themes[theme] or "Dark") end)
    end
    function w:ToggleHide() if wind then native:Toggle() else native:Minimize() end end
    function w:Popup(o)
        local buttons = {}
        for _, b in ipairs(o.options) do table.insert(buttons,{Title=b.text,Callback=b.callback or function() end}) end
        local dialog=native:Dialog({Title=o.title,Content=o.content,Buttons=buttons})
        if wind then dialog:Open() end
    end
    function w:Save()
        local data={}
        for key,row in pairs(states) do
            local value=row.value
            if typeof(value)=="Color3" then value={color=value:ToHex()} elseif typeof(value)=="EnumItem" then value={key=value.Name} end
            data[key]=value
        end
        writefile("ZERO-MM2-ui-settings.json", http:JSONEncode(data))
    end
    function w:Load()
        if not isfile("ZERO-MM2-ui-settings.json") then return end
        local ok,data=pcall(function() return http:JSONDecode(readfile("ZERO-MM2-ui-settings.json")) end)
        if not ok or type(data)~="table" then return end
        for key,value in pairs(data) do
            local row=states[key]
            if row then pcall(function()
                if type(value)=="table" then value=value.color and Color3.fromHex(value.color) or Enum.KeyCode[value.key] end
                row.control:Set(value)
            end) end
        end
    end
    function w:CreateTab(o)
        local tab=wind and native:Tab({Title=tr(o.name)}) or native:AddTab({Title=tr(o.name)})
        local labelRoot = wind and tab.UIElements.Main or tab.Frame
        local titles = {}
        if labelRoot then
            for _, node in ipairs(labelRoot:GetDescendants()) do
                if node:IsA("TextLabel") and node.Text == tr(o.name) then table.insert(titles,node) end
            end
        end
        localize(function()
            for _, label in ipairs(titles) do if label.Parent then label.Text=tr(o.name) end end
        end)
        local t={tabPage=wind and tab.UIElements.ContainerFrameCanvas or tab.Container}
        function t:Select() native:SelectTab(wind and tab.Index or 1) end
        local function create(kind,d)
            local row: any = {value=d.value}
            if row.value==nil then row.value=d.color end
            local function changed(v)
                if v==nil then return end
                row.value=v
                if kind=="Keybind" then if d.onChanged then d.onChanged(typeof(v)=="EnumItem" and v or Enum.KeyCode[v]) end
                elseif d.callback then d.callback(v) end
            end
            local title=tr(d.name or " ")
            local text=d.text or d.description or ""
            local args={Title=title,Desc=tr(text),Description=tr(text),Content=tr(text),Value=d.value,Default=d.value,Callback=changed}
            local element
            if kind=="Text" then element=wind and tab:Paragraph(args) or tab:AddParagraph(args)
            elseif kind=="Button" then args.Callback=d.callback; element=wind and tab:Button(args) or tab:AddButton(args)
            else
                if kind=="Dropdown" then args.Values=d.options;args.AllowNone=false
                elseif kind=="Slider" then
                    args.Min,args.Max=d.range[1],d.range[2];args.Step=d.increment;args.Rounding=math.max(0,math.ceil(-math.log10(d.increment)))
                    if wind then args.Value={Min=args.Min,Max=args.Max,Default=d.value} end
                elseif kind=="ColorPicker" then args.Default=d.color;args.Value=d.color
                elseif kind=="Keybind" then
                    args.Value=d.value.Name;args.Default=d.value.Name;args.Callback=d.flag=="menu_key" and function() end or d.callback or function() end
                    local function key_changed(v)
                        if d.flag=="menu_key" then
                            local key=typeof(v)=="EnumItem" and v or Enum.KeyCode[v]
                            if wind then native:SetToggleKey(key) else native.MinimizeKey=key end
                        end
                        changed(v)
                    end
                    args.ChangedCallback=key_changed;args.OnChanged=key_changed
                end
                local method=kind=="ColorPicker" and "Colorpicker" or kind
                if wind then element=tab[method](tab,args) else element=tab["Add"..method](tab,d.flag,args) end
            end
            local c={}
            function c:Set(v)
                if kind=="Text" then if row.last~=v then element:SetDesc(v);row.last=v end
                elseif wind and kind=="Dropdown" then element:Select(v)
                elseif wind then element:Set(v)
                elseif kind=="ColorPicker" then element:SetValueRGB(v)
                else element:SetValue(v) end
            end
            function c:Refresh(values) if wind then element:Refresh(values) else element:SetValues(values) end end
            localize(function()
                if element.SetTitle then element:SetTitle(tr(d.name or " ")) end
                if text~="" and element.SetDesc then element:SetDesc(tr(text)) end
            end)
            if d.flag and d.flag~="library" and not d.forgetState then row.control=c;states[d.flag]=row end
            return c
        end
        for _,kind in ipairs({"Text","Button","Dropdown","Toggle","ColorPicker","Keybind","Slider"}) do
            t["Create"..kind]=function(_,d) return create(kind,d) end
        end
        return t
    end
    return w
end

local function build_ui()
    local engine = loadstring(game:HttpGet(ui_urls[library_name]))()
    local testing = env.ZERO_MM2_TEST == true
    local window = library_name ~= "Rayfield Gen2" and adapted_window(engine, library_name == "WindUI") or engine:CreateWindow({name = "ZERO | MM2", subtitle = "Nandox · v3", sidebarLayout = true,
        theme = "cobalt", showName = "ZERO MM2", locale = "pt", translations = translations,
        configuration = {autoSave = not testing and app.feature_available("config"), autoLoad = not testing and app.feature_available("config"), fileName = "ZERO-MM2-v2", customFolder = "ZERO"}})
    app.window = window
    app.module_ready.ui = true
    local tabs = {}
    for _, name in ipairs({"Player", "Aimbot", "Visuals", "Round", "Farm", "Movement", "Clips", "Troll", "Skins", "Boxes", "Settings", "About"}) do
        tabs[name] = window:CreateTab({name = name})
    end
    app.tabs = tabs
    local gated_controls = {esp = "esp", gun_esp = "esp", coin_esp = "esp", fov_circle = "esp", aim = "aim", silent = "silent",
        farm = "farm", xp_farm = "xp", auto_gun = "gun", anti_afk = "afk", skins = "skins"}
    local function toggle(tab, key, name, description, transient)
        local dependency = gated_controls[key]
        if dependency and not app.feature_available(dependency) then app.settings[key] = false end
        app.controls[key] = tab:CreateToggle({name = name, description = description, flag = key,
            value = app.settings[key], forgetState = transient == true, callback = function(value)
                local feature = gated_controls[key]
                if value and feature and not app.feature_available(feature) then
                    app.settings[key] = false
                    task.defer(function() if app.controls[key] then app.controls[key]:Set(false) end end)
                    window:Notify({title = tr("Unavailable feature"), content = app.features[feature].reason})
                    return
                end
                app.settings[key] = value
                if key == "anti_afk" then app.set_anti_afk(value) end
            end})
    end
    local function slider(tab, key, name, minimum, maximum, increment)
        app.controls[key] = tab:CreateSlider({name = name, flag = key, range = {minimum, maximum},
            increment = increment, value = app.settings[key], callback = function(value) app.settings[key] = value end})
    end
    local function dropdown(tab, key, name, options, callback)
        app.controls[key] = tab:CreateDropdown({name = name, flag = key, options = options,
            value = app.settings[key], callback = function(value)
                if type(value) == "table" then value = value[1] end
                if value == nil then return end
                app.settings[key] = value
                if callback then callback(value) end
            end})
    end
    local panel = Instance.new("Frame")
    panel.Name = "ZERO_PlayerDashboard"
    panel.Size = UDim2.new(1, 0, 0, 274)
    panel.BackgroundColor3 = Color3.fromRGB(22, 27, 39)
    panel.BorderSizePixel = 0
    panel.LayoutOrder = -100
    panel.Parent = tabs.Player.tabPage
    local corner = Instance.new("UICorner"); corner.CornerRadius = UDim.new(0, 12); corner.Parent = panel
    app.dashboard = panel
    local avatar = Instance.new("ImageLabel")
    avatar.BackgroundColor3 = Color3.fromRGB(32, 40, 56)
    avatar.BorderSizePixel = 0
    avatar.Position, avatar.Size = UDim2.fromOffset(18, 20), UDim2.fromOffset(108, 108)
    avatar.Parent = panel
    app.avatar = avatar
    local avatar_corner = Instance.new("UICorner"); avatar_corner.CornerRadius = UDim.new(0, 10); avatar_corner.Parent = avatar
    task.spawn(function()
        local ok, url = pcall(Players.GetUserThumbnailAsync, Players, local_player.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size180x180)
        if ok and app.alive then avatar.Image = url end
    end)
    local labels = {}
    local function label(key, x, y, width, size)
        local item = Instance.new("TextLabel")
        item.BackgroundTransparency = 1
        item.Position = UDim2.fromOffset(x, y)
        item.Size = UDim2.new(width, -x - 12, 0, 28)
        item.Font = Enum.Font.GothamMedium
        item.TextSize = size or 14
        item.TextColor3 = Color3.fromRGB(224, 232, 248)
        item.TextXAlignment = Enum.TextXAlignment.Left
        item.TextTruncate = Enum.TextTruncate.AtEnd
        item.Parent = panel
        labels[key] = item
        return item
    end
    label("name", 18, 140, 1, 18).Text = local_player.DisplayName
    label("username", 18, 168, 1, 13).Text = "@" .. local_player.Name
    label("age", 18, 198, 1)
    label("xp", 18, 228, 1)
    label("fps", 150, 20, 1, 19)
    label("ping", 150, 55, 1, 19)
    label("executor", 150, 90, 1, 12)
    label("load", 150, 116, 1, 12)
    app.player_labels = labels
    app.status_text = tabs.Player:CreateText({name = "Status", text = "Loading"})
    app.load_text = tabs.Player:CreateText({name = "Load status", text = "Loading"})
    app.executor_text = tabs.Player:CreateText({name = "Executor compatibility", text = "Loading"})
    local combat = tabs.Aimbot
    toggle(combat, "aim", "Aimbot")
    toggle(combat, "silent", "Silent aim")
    toggle(combat, "trigger", "Trigger bot", nil, true)
    dropdown(combat, "aim_activation", "Activation", {"Hold", "Toggle", "Always"})
    app.controls.aim_key = combat:CreateKeybind({name = "Aim key", flag = "aim_key", value = app.aim_key,
        onChanged = function(key) app.aim_key = key; app.aim_latched = false end})
    toggle(combat, "fov_circle", "Show FOV")
    toggle(combat, "wall_check", "Wall check")
    dropdown(combat, "target_mode", "Targets", {"By role", "All"})
    dropdown(combat, "target_part", "Target part", {"HumanoidRootPart", "Head", "UpperTorso"})
    dropdown(combat, "aim_priority", "Target priority", {"Cursor", "Distance"})
    slider(combat, "aim_distance", "Aim distance", 20, 1200, 10)
    slider(combat, "fov", "FOV radius", 30, 800, 10)
    slider(combat, "smoothing", "Smoothing", 1, 30, 1)
    slider(combat, "prediction", "Prediction (seconds)", 0, 0.3, 0.01)
    slider(combat, "hit_chance", "Silent hit chance", 0, 100, 1)
    combat:CreateColorPicker({name = "FOV color", flag = "fov_color", color = app.settings.fov_color,
        callback = function(value) app.settings.fov_color = value end})
    local visual = tabs.Visuals
    for _, spec in ipairs({{"esp", "Role ESP"}, {"boxes", "Boxes"}, {"names", "Player names"}, {"role_labels", "Role labels"},
        {"health_bar","Health bar"}, {"skeleton", "Skeleton"}, {"distance_labels", "Distance labels"}, {"health", "Health"}, {"tracers", "Tracers"}, {"chams", "Highlights"},
        {"lobby", "Show lobby"}, {"show_innocents", "Show innocents"}, {"esp_visible", "Visible only"},
        {"gun_esp", "Dropped gun ESP"}, {"coin_esp", "Coin ESP"}}) do toggle(visual, spec[1], spec[2]) end
    slider(visual, "esp_distance", "ESP distance", 20, 1500, 10)
    slider(visual, "line_thickness", "Line thickness", 1, 5, 1)
    slider(visual, "text_size", "Text size", 11, 24, 1)
    slider(visual, "highlight_opacity", "Highlight opacity", 0, 1, 0.05)
    for _, role in ipairs({"Murderer", "Sheriff", "Hero", "Innocent"}) do
        visual:CreateColorPicker({name = role, flag = "color_" .. role, color = colors[role], callback = function(color) colors[role] = color end})
    end
    local farm = tabs.Farm
    toggle(farm, "farm", "Auto farm", nil, true)
    dropdown(farm, "farm_mode", "Movement mode", {"Normal", "Underground", "Teleport"})
    farm:CreateText({text = "Normal uses gradual movement. Teleport can be rejected by the server."})
    dropdown(farm, "farm_kind", "Collectibles", {"Todos", "Candy", "Coins"})
    slider(farm, "farm_speed", "Farm speed", 6, 30, 1)
    slider(farm, "underground_depth", "Underground depth", 2, 6, 0.5)
    slider(farm, "avoid_radius", "Avoid murderer", 0, 60, 2)
    dropdown(farm, "full_action", "When bag is full", {"Wait", "Reset", "Lobby", "Finish round"})
    farm:CreateText({text = "Reset resumes farming next round. Lobby stops farming and returns through respawn."})
    dropdown(farm, "innocent_action", "Innocent action", {"Wait for gun", "Fling"})
    farm:CreateText({text = "A fling attempt lasts 6 seconds and restores physics afterwards."})
    toggle(farm, "xp_farm", "XP farm", "Survives rounds and retreats from the murderer. XP is awarded by the server.", true)
    slider(farm, "xp_distance", "XP escape distance", 15, 100, 5)
    local round=tabs.Round
    toggle(round, "auto_gun", "Auto pickup gun", nil, true)
    round:CreateButton({name = "Pick up gun now", callback = function() app.pickup_requested = true end})
    round:CreateButton({name = "Kill all as Murderer", callback = function()
        local ok, reason = app.request_finish(true)
        if not ok then window:Notify({title = tr("Kill all as Murderer"), content = tr(reason)}) end
    end})
    round:CreateButton({name = "Finish this round", callback = function()
        local ok, reason = app.request_finish()
        if not ok then window:Notify({title = tr("Finish round"), content = tr(reason)}) end
    end})
    round:CreateButton({name = "Stop round action", callback = function()
        app.finish_active, app.forced_target, app.pickup_requested = false, nil, false; app.restore_movement()
    end})
    local clips=tabs.Clips
    toggle(clips, "cinematic_fov", "Custom camera FOV")
    slider(clips, "camera_fov", "Camera FOV", 40, 120, 1)
    toggle(clips, "fullbright", "Fullbright")
    local function clip_button(title, action)
        clips:CreateButton({name=title,callback=function()
            local ok,reason=action()
            if not ok then window:Notify({title=tr(title),content=reason}) end
        end})
    end
    clip_button("Bomb double jump",app.bomb_jump)
    clip_button("Spin and shoot",app.start_spin)
    slider(clips,"spin_speed_clip","Rotation speed",90,540,15)
    clips:CreateButton({name="Cancel clip",callback=app.stop_clip})
    app.controls.streamer=clips:CreateToggle({name="Streamer mode",flag="streamer",value=app.settings.streamer,callback=app.set_stream})
    local movement = tabs.Movement
    toggle(movement, "flight", "Flight", "WASD moves; E rises; Q descends. Fling is a separate round action.", true)
    slider(movement, "flight_speed", "Flight speed", 6, 60, 1)
    movement:CreateKeybind({name = "Flight key", flag = "flight_key", value = Enum.KeyCode.F,
        callback = function() set_enabled("flight", not app.settings.flight) end})
    toggle(movement, "speed_enabled", "Custom speed", nil, true)
    slider(movement, "walk_speed", "Walk speed", 8, 80, 1)
    toggle(movement, "jump_enabled", "Custom jump", nil, true)
    slider(movement, "jump_power", "Jump power", 20, 150, 5)
    toggle(movement, "noclip", "Noclip", nil, true)
    toggle(movement, "infinite_jump", "Infinite jump", nil, true)
    local troll = tabs.Troll
    dropdown(troll, "troll_target", "Target player", app.refresh_targets())
    troll:CreateButton({name = "Refresh players", callback = app.refresh_targets})
    toggle(troll, "troll_follow", "Follow target", nil, true)
    toggle(troll, "troll_orbit", "Orbit target", nil, true)
    slider(troll, "orbit_radius", "Orbit radius", 2, 20, 1)
    slider(troll, "orbit_height", "Orbit height", -3, 10, 0.5)
    slider(troll, "orbit_speed", "Orbit speed", 5, 120, 5)
    toggle(troll, "troll_spectate", "Spectate target", nil, true)
    toggle(troll, "troll_spin", "Spin", nil, true)
    slider(troll, "spin_speed", "Spin speed", 30, 720, 15)
    toggle(troll, "troll_rainbow", "Rainbow character (local)", nil, true)
    troll:CreateButton({name = "Fling selected target", callback = function()
        if not app.request_target_fling() then window:Notify({title = "Troll", content = tr("Select an available target and check executor compatibility.")}) end
    end})
    troll:CreateText({text = "Fling is experimental; server physics can reject it. Each attempt is bounded."})
    troll:CreateButton({name = "Stop Troll", callback = app.stop_troll})
    local skins = tabs.Skins
    local catalog = app.refresh_skin_catalog()
    if not app.load_seconds and capabilities.readfile and capabilities.isfile and not env.ZERO_MM2_TEST then
        pcall(function()
            if isfile("ZERO-MM2-skins.json") then
                local prefs=http:JSONDecode(readfile("ZERO-MM2-skins.json"))
                for _,kind in ipairs({"Gun","Knife"}) do
                    if table.find(catalog[kind],prefs[kind]) then app.settings[kind:lower().."_skin"]=prefs[kind] end
                end
            end
        end)
    end
    toggle(skins, "skins", "Local skin changer")
    for _, kind in ipairs({"Knife","Gun"}) do
        local key=kind:lower().."_skin"
        if not table.find(catalog[kind],app.settings[key]) then app.settings[key]="Original" end
        skins:CreateButton({name=kind=="Gun" and "Choose a gun" or "Choose a knife",callback=function() app.open_gallery(kind) end})
    end
    dropdown(skins, "skin_style", "Material / style", {"Original", "Gold", "Neon", "Ice", "Rainbow"})
    dropdown(skins, "skin_effect", "Local effect", {"None", "Fire", "Sparkles", "Smoke", "Trail"})
    skins:CreateColorPicker({name = "Skin color", flag = "skin_color", color = app.settings.skin_color,
        callback = function(color) app.settings.skin_color = color end})
    skins:CreateButton({name = "Refresh skin catalog", callback = function() app.refresh_skin_catalog(true) end})
    skins:CreateButton({name = "Restore original visuals", callback = function() set_enabled("skins", false) end})
    skins:CreateText({text = "Only loaded models appear. Refresh to discover newly replicated skins."})
    app.skin_text = skins:CreateText({name = "Status", text = "Original"})

    local boxes = tabs.Boxes
    local box_ids, currencies, known = {}, {}, {}
    for id, item in pairs(Sync.NewShop) do
        if item.Type == "MysteryBox" and Sync.MysteryBox[id] then
            table.insert(box_ids, id)
            for currency in pairs(item.Price) do
                if currency ~= "Robux" and not known[currency] then known[currency] = true; table.insert(currencies, currency) end
            end
        end
    end
    table.sort(box_ids); table.sort(currencies)
    if #box_ids == 0 then box_ids = {"Unavailable"} end
    if #currencies == 0 then currencies = {"Unavailable"} end
    app.settings.box_id = table.find(box_ids, "Halloween2026Box") and "Halloween2026Box" or box_ids[1]
    app.settings.box_currency = table.find(currencies, "Candies2026") and "Candies2026" or currencies[1]
    dropdown(boxes, "box_id", "Box", box_ids)
    dropdown(boxes, "box_currency", "Currency", currencies)
    slider(boxes, "box_count", "Quantity", 1, 10, 1)
    app.box_text = boxes:CreateText({name = "Status", text = "Idle"})
    boxes:CreateText({text = "Purchases always require a fresh cost confirmation; opening never resumes from a config."})
    boxes:CreateButton({name = "Review purchase", callback = function()
        local quote, err = app.box_quote(app.settings.box_id, app.settings.box_currency, app.settings.box_count)
        if not quote or not quote.affordable then window:Notify({title = tr("Boxes"), content = err or "Saldo insuficiente / insufficient balance"}); return end
        window:Popup({title = tr("Confirm purchase"), content = string.format("%d × %s\n%d %s\nSaldo / balance: %d → %d", quote.count, quote.name, quote.total, quote.currency, quote.balance, quote.balance - quote.total),
            options = {{text = tr("Cancel")}, {text = tr("Confirm purchase"), style = "primary", callback = function() app.open_boxes(quote) end}}})
    end})
    boxes:CreateButton({name = "Stop opening", callback = function() app.box_running = false end})
    local settings = tabs.Settings
    app.settings.library = library_name
    dropdown(settings, "library", "UI library", libraries, function(choice)
        if choice ~= library_name and table.find(libraries, choice) and not app.rebuilding then task.defer(rebuild_ui, choice) end
    end)
    toggle(settings, "anti_afk", "Anti-AFK", "Disables idle callbacks without clicking or activating weapons.")
    dropdown(settings, "language", "Language", {"Portugues", "English"}, function(value)
        app.settings.locale = value == "English" and "en" or "pt"
        window:SetLocale(app.settings.locale)
    end)
    dropdown(settings, "theme", "Theme", {"cobalt", "ember", "amethyst", "frost", "rose", "default"}, function(value) window:ChangeTheme(value) end)
    settings:CreateButton({name = "Save configuration", callback = function() if app.feature_available("config") then window:Save() else window:Notify({title = "Config", content = app.features.config.reason}) end end})
    settings:CreateButton({name = "Load configuration", callback = function() if app.feature_available("config") then window:Load() else window:Notify({title = "Config", content = app.features.config.reason}) end end})
    settings:CreateButton({name = "Diagnostics", callback = function()
        local d = app.diagnostics()
        window:Notify({title = "ZERO MM2", content = string.format("%s | %s\n%d eventos | %d correcoes | %d erros", d.role, tr(d.farm), d.stats.collected_events, d.stats.corrections, #d.errors)})
    end})
    settings:CreateButton({name = "Stop all", callback = app.stop_all})
    settings:CreateButton({name = "Unload", callback = app.destroy})
    settings:CreateKeybind({name = "Menu key", flag = "menu_key", value = Enum.KeyCode.RightControl, callback = function() window:ToggleHide() end})
    tabs.About:CreateText({name = "Creator", text = "Nandox\nZERO MM2 · v3 — Open source"})
    tabs.About:CreateText({name = "Library", text = "" .. library_name .. "\n" .. ui_urls[library_name]})
    tabs.About:CreateText({name = "References", text = "Infinite Yield / EdgeIY: flight, noclip, fling concepts.\nZynic MM2 AutoFarm: closest coin and timed movement.\nOminousVibes MM2: role ESP, gun drop and prediction.\nCurrent game inspection: weapons, shop, coin bag events."})
    tabs.About:CreateText({text = "MonoMM2 / fleecewtf: fling physics pulse.\nhttps://github.com/fleecewtf/MonoMM2\nhttps://github.com/EdgeIY/infiniteyield\nhttps://github.com/Zyn-ic/MM2-AutoFarm"})
    tabs.Player:Select(true)
end
rebuild_ui = function(choice)
    if app.rebuilding or not app.alive then return end
    app.rebuilding = true
    local old, previous = app.window, library_name
    local previous_controls, previous_tabs, previous_labels = app.controls, app.tabs, app.player_labels
    library_name = choice
    app.controls = {}
    local ok, err = pcall(build_ui)
    if ok then
        if not old.unloaded then old:Unload() end
        if capabilities.writefile and not env.ZERO_MM2_TEST then pcall(writefile, gui_file, choice) end
    else
        if app.window ~= old then pcall(function() app.window:Unload() end) end
        app.window, app.controls, app.tabs, app.player_labels = old, previous_controls, previous_tabs, previous_labels
        library_name, app.settings.library = previous, previous
        old:Notify({title="UI", content=tostring(err)})
    end
    app.rebuilding = false
end
app.switch_library = rebuild_ui
local ok_ui, ui_result = pcall(build_ui)
if ok_ui and library_name ~= "Rayfield Gen2" and not env.ZERO_MM2_TEST and app.feature_available("config") then
    pcall(function() app.window:Load() end)
end
if not ok_ui then app.destroy(); error("ZERO MM2 UI: " .. tostring(ui_result)) end
do
    local overlay = Instance.new("ScreenGui")
    overlay.Name, overlay.ResetOnSpawn, overlay.DisplayOrder = "ZERO_MenuLauncher", false, 1000000
    overlay.Parent = app.ui_parent()
    app.launcher = overlay
    local button = Instance.new("TextButton")
    button.Name, button.Text = "ToggleMenu", "ZERO  ·  Menu"
    button.AnchorPoint = Vector2.new(0.5, 0)
    button.Position, button.Size = UDim2.new(0.5, 0, 0, 2), UDim2.fromOffset(112, 30)
    button.BackgroundColor3, button.TextColor3 = Color3.fromRGB(33, 39, 60), Color3.new(1, 1, 1)
    button.Font, button.TextSize = Enum.Font.GothamMedium, 14
    button.Parent = overlay
    local corner = Instance.new("UICorner")
    corner.CornerRadius, corner.Parent = UDim.new(0, 8), button
    connect(button.Activated, function()
        if app.rebuilding then return end
        if app.gallery then app.gallery:Destroy();app.gallery=nil end
        if app.window.unloaded or not app.dashboard:IsDescendantOf(game) then rebuild_ui(library_name)
        else app.window:ToggleHide() end
    end)
end
app.load_seconds = os.clock() - load_started
local fps_frames, fps_elapsed = 0, 0
local executor_name, executor_version = "Unknown", ""
if capabilities.identifyexecutor then executor_name, executor_version = identifyexecutor() end
if app.settings.anti_afk then app.set_anti_afk(true) end
app.refresh_features()
function app.update_dashboard(dt)
    if app.rebuilding or app.window.unloaded or not app.dashboard:IsDescendantOf(game) then return end
    fps_frames += 1; fps_elapsed += dt
    if fps_elapsed < 0.5 then return end
    app.stats.fps = fps_frames / fps_elapsed
    fps_frames, fps_elapsed = 0, 0
    local ok_ping, ping = pcall(function()
        local stats: any = game:GetService("Stats")
        return stats.Network.ServerStatsItem["Data Ping"]:GetValue()
    end)
    app.stats.ping = ok_ping and ping or nil
    app.stats.xp_delta = (local_player:GetAttribute("XP") or app.stats.xp_start) - app.stats.xp_start
    local labels = app.player_labels
    labels.name.Text = identity(local_player)
    labels.username.Text = app.settings.streamer and "" or ("@" .. local_player.Name)
    app.avatar.Visible = not app.settings.streamer
    labels.fps.Text = string.format("FPS  %.0f", app.stats.fps)
    labels.fps.TextColor3 = app.performance_color(app.stats.fps, false)
    labels.ping.Text = ok_ping and string.format("Ping  %.0f ms", ping) or "Ping  —"
    labels.ping.TextColor3 = app.performance_color(app.stats.ping, true)
    labels.age.Text = tr("Account age") .. ": " .. local_player.AccountAge
    labels.executor.Text = tr("Executor") .. ": " .. tostring(executor_name) .. " " .. tostring(executor_version or "")
    labels.load.Text = tr("Load time") .. string.format(": %.2f s", app.load_seconds)
    labels.xp.Text = tr("Session XP") .. ": " .. app.stats.xp_delta
    app.status_text:Set(app.settings.streamer and tr("Streamer mode") or tr(app.farm_status))
    local percent, unavailable = app.refresh_features()
    app.load_text:Set(string.format("%d%% — %s", percent, #unavailable == 0 and tr("All modules loaded") or tr("Disabled modules") .. "\n" .. table.concat(unavailable, "\n")))
    local missing = app.executor_report()
    app.executor_text:Set(#missing == 0 and tr("All required APIs available") or tr("Missing APIs") .. ": " .. table.concat(missing, ", "))
    app.skin_text:Set(tr(app.skin_status))
    local quote = app.box_quote(app.settings.box_id, app.settings.box_currency, app.settings.box_count)
    app.box_text:Set(tr(app.box_status) .. (quote and string.format("\n%d × %s = %d %s | saldo/balance %d", quote.count, quote.name, quote.total, quote.currency, quote.balance) or "\nMoeda indisponivel / unavailable currency"))
end


app.coin_parts = CollectionService:GetTagged("ServerCoinPart")
local cache_elapsed = 0
connect(RunService.Heartbeat, function(dt)
    if not app.alive then return end
    if app.rebuilding then return end

    cache_elapsed += dt
    if cache_elapsed >= 0.5 then
        cache_elapsed = 0
        app.coin_parts = CollectionService:GetTagged("ServerCoinPart")
        app.gun_drop = workspace:FindFirstChild("GunDrop", true)
        for coin, deadline in pairs(app.ignored_coins) do
            if not coin.Parent or deadline < os.clock() then app.ignored_coins[coin] = nil end
        end
    end
    local ok, err = pcall(app.farm_step, dt)
    if not ok then
        report_error("Farm", err)
        app.runtime_failures.movement = tostring(err)
        app.stop_all()
    end
end)
connect(RunService.RenderStepped, function(dt)
    local ok_dashboard, dashboard_error = pcall(app.update_dashboard, dt)
    if not ok_dashboard then report_error("Dashboard", dashboard_error) end
    local ok, err = pcall(app.render_step, dt)
    if not ok then app.runtime_failures.troll = tostring(err); report_error("Render", err) end
end)
app.window:Notify({title = "ZERO MM2 pronto", content = "Ctrl direito: menu. F: voo. Preferencias guardadas em Configuracoes."})
return app.diagnostics()
