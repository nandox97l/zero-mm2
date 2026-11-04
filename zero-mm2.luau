-- SPDX-License-Identifier: MIT
-- Creator: Nandox | Open source, unobfuscated
-- Language: Luau | File: zero-mm2.luau | Runtime: Real | Target: MM2, place 142823291 v1460
-- UI: Sirius Rayfield Gen2 (MPL-2.0). Gameplay implementation derived from live v1460 inspection.
-- Reference: OminousVibes MM2, role-color ESP, GunDrop discovery and velocity prediction patterns.
-- References: EdgeIY/infiniteyield, Zyn-ic/MM2-AutoFarm, fleecewtf/MonoMM2.
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
        gun_esp = false, coin_esp = false, aim = false, silent = false,
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
    {"player", "Player", {}, {}}, {"ui", "Rayfield Gen2", {}, {"ui"}},
    {"esp", "ESP / FOV", {"Drawing"}, {"round"}}, {"aim", "Aimbot", {"mousemoverel"}, {"round"}},
    {"silent", "Silent aim", {}, {"weapon", "round"}}, {"farm", "Farm", {"firetouchinterest"}, {"round"}},
    {"xp", "XP", {}, {"round"}}, {"gun", "Gun pickup", {"firetouchinterest"}, {"round"}},
    {"movement", "Movement", {}, {}}, {"troll", "Troll", {}, {}},
    {"fling", "Fling", {"gethiddenproperty", "sethiddenproperty"}, {}}, {"skins", "Local skins", {}, {}},
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
    if app.cleanup_extras then app.cleanup_extras() end
    if app.restore_movement then app.restore_movement() end
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
        if app.alive and equipped_weapon() and (app.finish_active or (app.settings.silent and math.random(1, 100) <= app.settings.hit_chance)) then
            local target = app.finish_active and app.forced_target or app.select_target()
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
        for _, object in ipairs({visual.box, visual.text, visual.tracer}) do
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
    if app.flight_force then app.flight_force:Destroy(); app.flight_force = nil end
    if fling_state and fling_state.claimed and fling_state.root.Parent then
        pcall(sethiddenproperty, fling_state.root, "PhysicsRepRootPart", fling_state.previous_rep_root)
    end
    if fling_state and fling_state.spin then fling_state.spin:Destroy() end
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
    app.finish_active, app.pickup_requested, app.box_running, app.troll_fling_active = false, false, false, false
    for _, key in ipairs({"esp", "gun_esp", "coin_esp", "aim", "silent", "farm", "xp_farm",
        "flight", "noclip", "speed_enabled", "jump_enabled", "auto_gun", "infinite_jump",
        "troll_follow", "troll_orbit", "troll_spin", "troll_spectate", "troll_rainbow", "skins"}) do
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
    noclip_character(character)
    remember_property(humanoid, "AutoRotate", false)
    remember_property(humanoid, "PlatformStand", true)
    local delta = destination - root.Position
    local speed = math.max(6, app.settings.farm_speed * (0.75 ^ motion.corrections))
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
    if not root or (root.Position - part.Position).Magnitude > app.settings.max_distance then return false end
    app.farm_status = "Picking up gun"
    if move_to(part.Position + Vector3.new(0, 1, 0), dt, "gun", false, false) and os.clock() - app.last_touch > 0.4 then
        app.last_touch = os.clock()
        firetouchinterest(root, part, 1)
        firetouchinterest(root, part, 0)
    end
    return true
end

function app.request_finish()
    if not active_player(local_player) then return false, "No active round" end
    app.finish_active = true
    app.finish_started = os.clock()
    app.finish_target_seen = false
    return true
end

local function fling_step(target, dt)
    local character, root, humanoid = character_parts(local_player)
    local _, target_root = character_parts(target)
    if not target_root or not root then return false end
    if not fling_state then
        if (root.Position - target_root.Position).Magnitude > 5 then
            move_to(target_root.Position, dt, "approach", false, false)
            return true
        end
        app.restore_movement()
        fling_state = {root = root, started = os.clock(), origin = root.CFrame,
            target_origin = target_root.Position, peak_speed = 0, previous_velocity = root.AssemblyLinearVelocity}
        local read_ok, previous = pcall(gethiddenproperty, root, "PhysicsRepRootPart")
        if read_ok then
            local write_ok, hidden = pcall(sethiddenproperty, root, "PhysicsRepRootPart", target_root)
            fling_state.claimed = write_ok and hidden == true
            fling_state.previous_rep_root = previous
        end
        for _, part in ipairs(character:GetDescendants()) do
            if part:IsA("BasePart") then
                remember_property(part, "CanCollide", true)
                remember_property(part, "Massless", true)
                remember_property(part, "CustomPhysicalProperties", PhysicalProperties.new(100, 0.3, 0.5))
            end
        end
        remember_property(humanoid, "PlatformStand", true)
        motion.root, motion.owner = root, "fling"
    end
    local elapsed = os.clock() - fling_state.started
    fling_state.peak_speed = math.max(fling_state.peak_speed, target_root.AssemblyLinearVelocity.Magnitude)
    app.stats.last_fling_peak_speed = fling_state.peak_speed
    app.stats.last_fling_displacement = (target_root.Position - fling_state.target_origin).Magnitude
    app.stats.last_fling_vertical = target_root.Position.Y - fling_state.target_origin.Y
    app.farm_status = "Fling: " .. target.DisplayName
    if elapsed > 6 or (target_root.Position - fling_state.target_origin).Magnitude > 150 then
        app.stats.last_fling_displacement = (target_root.Position - fling_state.target_origin).Magnitude
        local origin = fling_state.origin
        app.restore_movement()
        root.CFrame = origin
        app.finish_active, app.troll_fling_active = false, false
        return false
    end
    local angle = elapsed * 45
    -- MonoMM2 / fleecewtf: pulse velocity between physics and rendering, restore afterwards.
    root.CFrame = target_root.CFrame * CFrame.new(math.cos(angle) * 0.1, 0, math.sin(angle) * 0.1)
    fling_state.previous_velocity = Vector3.zero
    root.AssemblyLinearVelocity = Vector3.new(math.cos(angle) * 100, 10000, math.sin(angle) * 100)
    return true
end

connect(RunService.RenderStepped, function()
    if fling_state and fling_state.root.Parent then
        fling_state.root.AssemblyLinearVelocity = fling_state.previous_velocity
    end
end)

local function finish_step(dt)
    if not app.finish_active then return false end
    if not active_player(local_player) or os.clock() - app.finish_started > 90 then
        app.finish_active = false; app.forced_target = nil; end_motion(); return false
    end
    local role = player_role(local_player)
    local _, root, humanoid = character_parts(local_player)
    local target = murderer()
    if role == "Murderer" then
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
    app.farm_status = "Finish round: " .. target.DisplayName
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
            else app.farm_status = "No collectible in range" end
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
    if app.settings.noclip or (motion.owner and motion.owner ~= "fling" and motion.owner ~= "flight") then
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

local function target_player()
    local selected = Players:FindFirstChild(app.settings.troll_target)
    if not selected or selected == local_player then return nil end
    local _, root, humanoid = character_parts(selected)
    return root and humanoid and humanoid.Health > 0 and selected or nil
end

function app.refresh_targets()
    local options = {"None"}
    for _, player in ipairs(Players:GetPlayers()) do if player ~= local_player then table.insert(options, player.Name) end end
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
    local cloned = source:Clone()
    if not cloned then return nil end
    local model = Instance.new("Model")
    model.Name = "ZERO_LocalSkin"
    cloned.Parent = model
    for _, object in ipairs(model:GetDescendants()) do
        if object:IsA("LuaSourceContainer") or object:IsA("JointInstance") or object:IsA("WeldConstraint")
            or object:IsA("Sound") or object:IsA("ParticleEmitter") or object:IsA("Trail") or object:IsA("Beam")
            or object:IsA("Fire") or object:IsA("Smoke") or object:IsA("Sparkles") then object:Destroy()
        elseif object:IsA("BasePart") then
            object.Anchored, object.CanCollide, object.CanTouch, object.CanQuery, object.Massless = true, false, false, false, true
            object.LocalTransparencyModifier = 0
        end
    end
    local primary = cloned:IsA("BasePart") and cloned or model:FindFirstChildWhichIsA("BasePart", true)
    if not primary then model:Destroy(); return nil end
    model.PrimaryPart = primary
    model:PivotTo(CFrame.identity)
    return model
end

function app.refresh_skin_catalog()
    for _, player in ipairs(Players:GetPlayers()) do
        local character = player.Character
        for _, kind in ipairs({"Knife", "Gun"}) do
            local ref = character and character:FindFirstChild("DisplayRef" .. kind)
            local source = ref and ref:IsA("ObjectValue") and ref.Value
            local id = player:GetAttribute("Equipped" .. kind)
            if source and type(id) == "string" and not skin_templates[kind][id] then
                local clone = clean_visual_clone(source)
                if clone then skin_templates[kind][id] = clone end
            end
        end
    end
    local options = {Knife = {"Original"}, Gun = {"Original"}}
    for _, kind in ipairs({"Knife", "Gun"}) do
        for id in pairs(skin_templates[kind]) do table.insert(options[kind], id) end
        table.sort(options[kind])
        local control = app.controls[kind == "Knife" and "knife_skin" or "gun_skin"]
        if control then control:Refresh(options[kind]) end
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
    local selection = app.settings[kind == "Knife" and "knife_skin" or "gun_skin"] or "Original"
    local stamp = selection .. app.settings.skin_style .. app.settings.skin_effect .. tostring(app.settings.skin_color)
    local overlay = skin_overlays[kind]
    if not overlay or overlay.target ~= target or overlay.stamp ~= stamp then
        clear_skin(kind)
        local template = skin_templates[kind][selection]
        local model = template and template:Clone() or clean_visual_clone(target)
        if not model then app.runtime_failures.skins = "Visual model unavailable"; return end
        if selection ~= "Original" and not template then app.skin_status = "Selected skin is not loaded in this server"
        else app.skin_status = "Local visuals active" end
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
        model.Parent = workspace.CurrentCamera
        overlay = {model = model, target = target, stamp = stamp}
        skin_overlays[kind] = overlay
    end
    overlay.model:PivotTo(part.CFrame)
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

local extras_elapsed = 0
function app.extra_render(dt)
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
    extras_elapsed += dt
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


function app.render_step(dt)
    if not app.alive then return end
    local camera = workspace.CurrentCamera
    if not camera then return end
    app.stats.frames += 1
    app.extra_render(dt)
    local cursor = cursor_position(camera)
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
                visual.box.Position = Vector2.new(top.X - width / 2, math.min(top.Y, bottom.Y))
                visual.box.Size = Vector2.new(width, height)
                visual.box.Thickness = app.settings.line_thickness
                visual.box.Color = color
                visual.box.Visible = app.settings.boxes
                visual.text.Position = Vector2.new(top.X, math.min(top.Y, bottom.Y) - 18)
                local caption = {}
                if app.settings.names then table.insert(caption, player.DisplayName) end
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
    if app.settings.aim and app.aim_pressed()
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
    ["Models come from weapons already loaded in this server. Changes are visible only to you and do not alter inventory."] = "Modelos de armas ja carregadas neste servidor. Alteracoes visiveis apenas para ti; o inventario nao muda.",
    ["Local visuals active"] = "Visuais locais ativos", ["Selected skin is not loaded in this server"] = "Skin selecionada nao carregada neste servidor",
    ["Following target"] = "A seguir alvo", ["Orbiting target"] = "A orbitar alvo", ["Load status"] = "Estado do carregamento",
    ["Executor compatibility"] = "Compatibilidade do executor", ["All modules loaded"] = "Todos os modulos carregados",
    ["Missing APIs"] = "APIs em falta", ["All required APIs available"] = "Todas as APIs necessarias disponiveis",
    ["Unavailable feature"] = "Funcao indisponivel", ["Disabled modules"] = "Modulos indisponiveis",
    ["Disables idle callbacks without clicking or activating weapons."] = "Desativa callbacks de inatividade sem clicar nem ativar armas.",
    ["Visuals"] = "Visuais", ["Movement"] = "Movimento", ["Boxes"] = "Caixas", ["Settings"] = "Configuracoes", ["About"] = "Sobre",
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
local ok_ui, ui_result = pcall(function()
    local Rayfield = loadstring(game:HttpGet("https://sirius.menu/gen2"))()
    local testing = env.ZERO_MM2_TEST == true
    local window = Rayfield:CreateWindow({name = "ZERO | MM2", subtitle = "Nandox · v3", sidebarLayout = true,
        theme = "cobalt", showName = "ZERO MM2", locale = "pt", translations = translations,
        configuration = {autoSave = not testing and app.feature_available("config"), autoLoad = not testing and app.feature_available("config"), fileName = "ZERO-MM2-v2", customFolder = "ZERO"}})
    app.window = window
    app.module_ready.ui = true
    local tabs = {}
    for _, name in ipairs({"Player", "Aimbot", "Visuals", "Farm", "Movement", "Troll", "Skins", "Boxes", "Settings", "About"}) do
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
        {"distance_labels", "Distance labels"}, {"health", "Health"}, {"tracers", "Tracers"}, {"chams", "Highlights"},
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
    toggle(farm, "auto_gun", "Auto pickup gun", nil, true)
    farm:CreateButton({name = "Pick up gun now", callback = function() app.pickup_requested = true end})
    farm:CreateButton({name = "Finish this round", callback = function()
        local ok, reason = app.request_finish()
        if not ok then window:Notify({title = tr("Finish round"), content = tr(reason)}) end
    end})
    farm:CreateButton({name = "Stop round action", callback = function()
        app.finish_active, app.forced_target, app.pickup_requested = false, nil, false; app.restore_movement()
    end})
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
    toggle(skins, "skins", "Local skin changer")
    dropdown(skins, "knife_skin", "Knife model", catalog.Knife)
    dropdown(skins, "gun_skin", "Gun model", catalog.Gun)
    dropdown(skins, "skin_style", "Material / style", {"Original", "Gold", "Neon", "Ice", "Rainbow"})
    dropdown(skins, "skin_effect", "Local effect", {"None", "Fire", "Sparkles", "Smoke", "Trail"})
    skins:CreateColorPicker({name = "Skin color", flag = "skin_color", color = app.settings.skin_color,
        callback = function(color) app.settings.skin_color = color end})
    skins:CreateButton({name = "Refresh skin catalog", callback = app.refresh_skin_catalog})
    skins:CreateButton({name = "Restore original visuals", callback = function() set_enabled("skins", false) end})
    skins:CreateText({text = "Models come from weapons already loaded in this server. Changes are visible only to you and do not alter inventory."})
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
    tabs.About:CreateText({name = "Library", text = "Sirius Rayfield Gen2 · MPL-2.0\nhttps://sirius.menu/gen2"})
    tabs.About:CreateText({name = "References", text = "Infinite Yield / EdgeIY: flight, noclip, fling concepts.\nZynic MM2 AutoFarm: closest coin and timed movement.\nOminousVibes MM2: role ESP, gun drop and prediction.\nCurrent game inspection: weapons, shop, coin bag events."})
    tabs.About:CreateText({text = "MonoMM2 / fleecewtf: fling physics pulse.\nhttps://github.com/fleecewtf/MonoMM2\nhttps://github.com/EdgeIY/infiniteyield\nhttps://github.com/Zyn-ic/MM2-AutoFarm"})
    tabs.Player:Select(true)
end)
if not ok_ui then app.destroy(); error("ZERO MM2 UI: " .. tostring(ui_result)) end
app.load_seconds = os.clock() - load_started
local fps_frames, fps_elapsed = 0, 0
local executor_name, executor_version = "Unknown", ""
if capabilities.identifyexecutor then executor_name, executor_version = identifyexecutor() end
if app.settings.anti_afk then app.set_anti_afk(true) end
app.refresh_features()
function app.update_dashboard(dt)
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
    labels.fps.Text = string.format("FPS  %.0f", app.stats.fps)
    labels.fps.TextColor3 = app.performance_color(app.stats.fps, false)
    labels.ping.Text = ok_ping and string.format("Ping  %.0f ms", ping) or "Ping  —"
    labels.ping.TextColor3 = app.performance_color(app.stats.ping, true)
    labels.age.Text = tr("Account age") .. ": " .. local_player.AccountAge
    labels.executor.Text = tr("Executor") .. ": " .. tostring(executor_name) .. " " .. tostring(executor_version or "")
    labels.load.Text = tr("Load time") .. string.format(": %.2f s", app.load_seconds)
    labels.xp.Text = tr("Session XP") .. ": " .. app.stats.xp_delta
    app.status_text:Set(tr(app.farm_status))
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
    if app.window.unloaded then
        app.destroy()
        return
    end
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
