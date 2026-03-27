-- leaf_particles/init.lua

local wind_mod = dofile(core.get_modpath('breasy') .. '/init.lua')

local scan_box_top = vector.new(32, 16, 32)
local scan_box_bottom = vector.new(-32, 0, -32)
local update_distance = 4
local gravity = vector.new(0,-0.5, 0)

local spawn_interval = 20
local particles_per_interval = 2
local player_cache = {}
local jitter = {min = {x=-6,y=-6,z=-6}, max ={x=6,y=6,z=6}, bias = 0}

local function get_player_cache(player)
    local name = player:get_player_name()
    player_cache[name] = player_cache[name] or {}
    return player_cache[name]
end

local function update_leaf_cache(player)
    local pos = player:get_pos()

    if pos.y < -10 then
        return false
    end

    local rounded = vector.round(pos)
    local cache = get_player_cache(player)

    if cache.last_pos == nil or vector.distance(cache.last_pos, rounded) >= update_distance then
        cache.last_pos = rounded
        cache.leaves = core.find_nodes_in_area(
            vector.add(rounded, scan_box_bottom),
            vector.add(rounded, scan_box_top),
            {"group:leaves"},
            true -- grouped makes it so no get_node_or_nil calls are necessary.
        )
    end

    return true
end

local function pick_random(items, amount)
    local r = {}
    for _ = 1, amount do
        table.insert(r, items[math.random(0, #items)])
    end
    return r
end

local function spawn_particles()

    for _, player in ipairs(core.get_connected_players()) do
        local found = update_leaf_cache(player)

        -- The player is too far down in a cave.
        if not found then
            goto continue
        end

        local cache = get_player_cache(player)
        if not cache.leaves then goto continue end

        -- Will spawn more particles if the wind is blowing hard.
        local spawn_ratio = vector.length(wind_mod.get_wind(cache.last_pos)) / 4

        for node_name, positions in pairs(cache.leaves) do
        for _, lpos in ipairs(pick_random(positions, #positions * spawn_ratio)) do
            local posmin = vector.offset(lpos, -0.5, -0.55, -0.5)
            local posmax = vector.offset(lpos,  0.5, -0.55,  0.5)

            -- wind-based velocity and acceleration
            local w = wind_mod.get_wind(lpos)
            local vel = w:add(gravity, 0.9)

            core.add_particlespawner({
                size = 0.5,
                -- Should randomize
                amount = particles_per_interval,
                alpha = 0.1,
                time = spawn_interval,
                node = { name = node_name },
                playername = player:get_player_name(),
                exptime = 15,
                collisiondetection = true,
                collision_removal = true,
                vertical = true,
                minpos = posmin,
                maxpos = posmax,
                pos = {min = posmin, max = posmax},
                jitter = jitter,
                vel = vel,
                acc = vel,
            })
        end
        end

        ::continue::
    end

    core.after(spawn_interval, spawn_particles)
end

core.after(0, spawn_particles)
