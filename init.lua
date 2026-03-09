-- leaf_particles/init.lua

leaf_particles = {}

local leaf_speed = 0.3
local scan_box = vector.new(32, 8, 32)
local update_distance = 4

local spawn_interval = 0.3
local scan_interval = 5

local player_cache = {}

leaf_particles.wind = vector.new(0.2, 0, 0.1)

local function update_wind()
	local dir = vector.normalize(vector.new(
		math.random(-100,100) / 100,
		0,
		math.random(-100,100) / 100
	))

	local strength = math.random() * 0.6 + 0.2
	leaf_particles.wind = vector.multiply(dir, strength)
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

		if cache.last_pos and vector.distance(cache.last_pos, rounded) < update_distance then
			goto continue
		end

		cache.last_pos = rounded
		cache.leaves = core.find_nodes_in_area(
			rounded - scan_box,
			rounded + scan_box,
			"group:leaves"
		)

		update_wind()

		::continue::
	end

	core.after(scan_interval, update_leaf_cache)
end

local function spawn_particles()
	for _, player in ipairs(core.get_connected_players()) do
		local cache = player_cache[player:get_player_name()]
		if not cache or not cache.leaves then goto continue end

		local wind = vector.multiply(leaf_particles.wind, leaf_speed)

		local velmin = vector.add(wind, vector.multiply(vector.new(-0.2, -0.2, -0.2), leaf_speed))
		local velmax = vector.add(wind, vector.multiply(vector.new( 0.1,  0.0,  0.1), leaf_speed))

		local accmin = vector.new(wind.x * 0.5 - 0.2 * leaf_speed, -2 * leaf_speed, wind.z * 0.5 - 0.2 * leaf_speed)
		local accmax = vector.new(wind.x * 0.5 + 0.2 * leaf_speed, -2 * leaf_speed, wind.z * 0.5 + 0.2 * leaf_speed)

		for i = 1, #cache.leaves do
			local lpos = cache.leaves[i]
			local node = core.get_node_or_nil(lpos)

			if node and core.get_item_group(node.name, "leaves") > 0 then
				local below = vector.offset(lpos, 0, -1, 0)
				local node_below = core.get_node(below)

				if node_below.name == "air" and math.random(1,30) == 1 then
					local posmin = vector.offset(below, -0.5, 0.8, -0.5)
					local posmax = vector.offset(below,  0.5, 0.8,  0.5)

					core.add_particlespawner({
						size = 0.5,
						amount = 1,
						time = 30,
						node = {name = node.name},
						playername = player:get_player_name(),
						collisiondetection = true,
						collision_removal = true,
						exptime = 15,
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

update_leaf_cache()
spawn_particles()
