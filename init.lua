-- leaf_particles/init.lua

local leaf_speed = 0.3
local scan_box = vector.new(32, 8, 32)
local update_distance = 4

local spawn_interval = 20
local particles_per_interval = 10

local player_cache = {}
local wind = vector.new(0.2, 0, 0.1)

local function update_wind()
    local dir = vector.normalize(vector.new(
        math.random(-100,100)/100, 0, math.random(-100,100)/100
    ))
    local strength = math.random() * 0.6 + 0.2
    wind = vector.multiply(dir, strength)
end

local function get_player_cache(player)
    local name = player:get_player_name()
    player_cache[name] = player_cache[name] or {}
    return player_cache[name]
end

local function update_leaf_cache()
    for _, player in ipairs(core.get_connected_players()) do
        local pos = player:get_pos()
        local rounded = vector.new(math.floor(pos.x), math.floor(pos.y), math.floor(pos.z))
        local cache = get_player_cache(player)

        if not cache.last_pos or vector.distance(cache.last_pos, rounded) >= update_distance then
            cache.last_pos = rounded
            cache.leaves = core.find_nodes_in_area(
                vector.subtract(rounded, scan_box),
                vector.add(rounded, scan_box),
                "group:leaves"
            )
        end
    end
end

local function spawn_particles()
		update_leaf_cache()
    update_wind()

    for _, player in ipairs(core.get_connected_players()) do
        local cache = get_player_cache(player)
        if not cache.leaves then goto continue end

        local w = vector.multiply(wind, leaf_speed)
        local velmin = vector.add(w, vector.new(-0.06, -0.06, -0.06))
        local velmax = vector.add(w, vector.new(0.03, 0, 0.03))
        local accmin = vector.new(w.x*0.5-0.06, -0.6, w.z*0.5-0.06)
        local accmax = vector.new(w.x*0.5+0.06, -0.6, w.z*0.5+0.06)

        for _, lpos in ipairs(cache.leaves) do
            local node = core.get_node_or_nil(lpos)
            if node and core.get_item_group(node.name, "leaves") > 0 then
                local below = vector.offset(lpos, 0, -1, 0)
                if core.get_node(below).name == "air" then
                    local posmin = vector.offset(below, -0.5, 0.8, -0.5)
                    local posmax = vector.offset(below,  0.5, 0.8,  0.5)

                    core.add_particlespawner({
                        size = 0.5,
                        amount = spawn_interval / particles_per_interval,
                        alpha = 0.1,
                        time = spawn_interval,
                        node = {name = node.name},
                        playername = player:get_player_name(),
                        collisiondetection = true,
                        collision_removal = true,
                        exptime = 1500,
                        minpos = posmin,
                        maxpos = posmax,
                        pos = {min = posmin, max = posmax},
                        mminvel = velmin,
                        maxvel = velmax,
                        vel = {min = velmin, max = velmax},
                        minacc = accmin,
                        maxacc = accmax,
                        acc = {min = accmin, max = accmax}
                    })
                end
            end
        end

        ::continue::
    end

    core.after(spawn_interval, spawn_particles)
end

-- start loops
core.after(0, spawn_particles)
