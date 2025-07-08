-- asteroid base class --
base = {}
function base:new()
	local obj = {
		x = 64,
		y = 64,
		gun_dir = 0, -- 0=north, 1=east, 2=south, 3=west
		health = 100,
		flash_timer = 0,
		flash_count = 0,
		is_flashing = false
	}
	setmetatable(obj, self)
	self.__index = self
	return obj
end

function base:update()
	-- gun direction control (rotate around 8 directions)
	if btnp(1) then -- right - clockwise
		self.gun_dir = (self.gun_dir + 1) % 8
		sfx(3)
	end
	if btnp(0) then -- left - counterclockwise  
		self.gun_dir = (self.gun_dir - 1) % 8
		if self.gun_dir < 0 then self.gun_dir = 7 end
		sfx(3)
	end
	
	-- shoot bullets
	if btnp(4) then
		self:shoot()
	end
	
	-- handle flashing when hit
	if self.is_flashing then
		self.flash_timer -= 1
		if self.flash_timer <= 0 then
			self.flash_count += 1
			if self.flash_count >= max_flash_count * 2 then -- *2 because we count both on and off states
				self.is_flashing = false
				self.flash_count = 0
			else
				self.flash_timer = flash_duration
			end
		end
	end
end

function base:hit()
	self.health -= 10
	self.is_flashing = true
	self.flash_timer = flash_duration
	self.flash_count = 0
	sfx(2)
end

function base:shoot()
	local bullet_x, bullet_y = self.x, self.y
	local bullet_dx, bullet_dy = 0, 0
	local bullet_speed = 2
	
	if self.gun_dir == 0 then -- north
		bullet_y -= 24
		bullet_dy = -bullet_speed
	elseif self.gun_dir == 1 then -- northeast
		bullet_x += 17
		bullet_y -= 17
		bullet_dx = bullet_speed * 0.707
		bullet_dy = -bullet_speed * 0.707
	elseif self.gun_dir == 2 then -- east
		bullet_x += 24
		bullet_dx = bullet_speed
	elseif self.gun_dir == 3 then -- southeast
		bullet_x += 17
		bullet_y += 17
		bullet_dx = bullet_speed * 0.707
		bullet_dy = bullet_speed * 0.707
	elseif self.gun_dir == 4 then -- south
		bullet_y += 24
		bullet_dy = bullet_speed
	elseif self.gun_dir == 5 then -- southwest
		bullet_x -= 17
		bullet_y += 17
		bullet_dx = -bullet_speed * 0.707
		bullet_dy = bullet_speed * 0.707
	elseif self.gun_dir == 6 then -- west
		bullet_x -= 24
		bullet_dx = -bullet_speed
	elseif self.gun_dir == 7 then -- northwest
		bullet_x -= 17
		bullet_y -= 17
		bullet_dx = -bullet_speed * 0.707
		bullet_dy = -bullet_speed * 0.707
	end
	
	-- main bullet
	add(bullets, bullet:new(bullet_x, bullet_y, bullet_dx, bullet_dy))
	
	-- spread bullets when powered up
	if powered_up then
		if self.gun_dir == 0 or self.gun_dir == 4 then -- pure vertical shots (N/S)
			-- add bullets with slight horizontal spread
			add(bullets, bullet:new(bullet_x, bullet_y, bullet_dx - 0.5, bullet_dy))
			add(bullets, bullet:new(bullet_x, bullet_y, bullet_dx + 0.5, bullet_dy))
			add(bullets, bullet:new(bullet_x, bullet_y, bullet_dx - 1, bullet_dy))
			add(bullets, bullet:new(bullet_x, bullet_y, bullet_dx + 1, bullet_dy))
		elseif self.gun_dir == 2 or self.gun_dir == 6 then -- pure horizontal shots (E/W)
			-- add bullets with slight vertical spread
			add(bullets, bullet:new(bullet_x, bullet_y, bullet_dx, bullet_dy - 0.5))
			add(bullets, bullet:new(bullet_x, bullet_y, bullet_dx, bullet_dy + 0.5))
			add(bullets, bullet:new(bullet_x, bullet_y, bullet_dx, bullet_dy - 1))
			add(bullets, bullet:new(bullet_x, bullet_y, bullet_dx, bullet_dy + 1))
		else -- diagonal shots - spread in both directions
			add(bullets, bullet:new(bullet_x, bullet_y, bullet_dx * 0.8, bullet_dy * 1.2))
			add(bullets, bullet:new(bullet_x, bullet_y, bullet_dx * 1.2, bullet_dy * 0.8))
			add(bullets, bullet:new(bullet_x, bullet_y, bullet_dx * 0.6, bullet_dy * 1.4))
			add(bullets, bullet:new(bullet_x, bullet_y, bullet_dx * 1.4, bullet_dy * 0.6))
		end
	end
	
	sfx(0)
end

function base:draw()
	-- apply flash effect if needed
	if self.is_flashing and self.flash_count % 2 == 1 then
		pal(13, 8) -- remap color 13 to color 8 for flash effect
		pal(7, 10) -- remap color 7 to color 10 for flash effect
	end
	
	-- draw asteroid base using 16 sprites (4x4 formation, 32x32 pixels)
	-- top row
	spr(8, self.x - 16, self.y - 16)   -- sprite 8
	spr(9, self.x - 8, self.y - 16)    -- sprite 9
	spr(10, self.x, self.y - 16)       -- sprite 10
	spr(11, self.x + 8, self.y - 16)   -- sprite 11
	-- second row
	spr(24, self.x - 16, self.y - 8)   -- sprite 24
	spr(25, self.x - 8, self.y - 8)    -- sprite 25
	spr(26, self.x, self.y - 8)        -- sprite 26
	spr(27, self.x + 8, self.y - 8)    -- sprite 27
	-- third row
	spr(40, self.x - 16, self.y)       -- sprite 40
	spr(41, self.x - 8, self.y)        -- sprite 41
	spr(42, self.x, self.y)            -- sprite 42
	spr(43, self.x + 8, self.y)        -- sprite 43
	-- bottom row
	spr(56, self.x - 16, self.y + 8)   -- sprite 56
	spr(57, self.x - 8, self.y + 8)    -- sprite 57
	spr(58, self.x, self.y + 8)        -- sprite 58
	spr(59, self.x + 8, self.y + 8)    -- sprite 59
	
	-- reset palette after drawing base
	if self.is_flashing and self.flash_count % 2 == 1 then
		pal() -- reset palette to normal
	end
	
	-- draw gun sprite based on direction (center of 4x4 sprite)
	local gun_x, gun_y = self.x - 4, self.y - 4  -- center sprite position
	if self.gun_dir == 0 then -- north
		spr(3, gun_x, gun_y - 16, 1, 1, false, false)
	elseif self.gun_dir == 1 then -- northeast
		spr(19, gun_x + 12, gun_y - 12, 1, 1, false, false)
	elseif self.gun_dir == 2 then -- east
		spr(4, gun_x + 16, gun_y, 1, 1, false, false)
	elseif self.gun_dir == 3 then -- southeast
		spr(19, gun_x + 12, gun_y + 12, 1, 1, false, true)
	elseif self.gun_dir == 4 then -- south
		spr(3, gun_x, gun_y + 16, 1, 1, true, true)
	elseif self.gun_dir == 5 then -- southwest
		spr(19, gun_x - 12, gun_y + 12, 1, 1, true, true)
	elseif self.gun_dir == 6 then -- west
		spr(4, gun_x - 16, gun_y, 1, 1, true, false)
	elseif self.gun_dir == 7 then -- northwest
		spr(19, gun_x - 12, gun_y - 12, 1, 1, true, false)
	end
end

-- bullet class --
bullet = {}
function bullet:new(x, y, dx, dy)
	local obj = {
		x = x,
		y = y,
		dx = dx,
		dy = dy,
		active = true
	}
	setmetatable(obj, self)
	self.__index = self
	return obj
end

function bullet:update()
	self.x += self.dx
	self.y += self.dy
	
	-- remove bullets that go off screen
	if self.x < 0 or self.x > 127 or self.y < 0 or self.y > 127 then
		self.active = false
	end
end

function bullet:draw()
	if self.active then
		pset(self.x, self.y, 10)
	end
end

-- base enemy class --
enemy = {}
function enemy:new()
	local obj = {
		x = 0,
		y = 0,
		health = 1,
		active = true,
		frame = 0,
		sprite_index = 0,
		enemy_type = "base"
	}
	setmetatable(obj, self)
	self.__index = self
	return obj
end

function enemy:is_transformer()
	return false
end

function enemy:get_type()
	return self.enemy_type or "unknown"
end


function enemy:update()
	-- animate sprite
	self.frame += 1
	if self.frame >= enemy_animation_delay then
		self.frame = 0
		self.sprite_index += 1
		if self.sprite_index > 2 then
			self.sprite_index = 0
		end
	end
end

function enemy:draw()
	-- override in subclasses
end

-- weaver enemy subclass --
weaver = {}
setmetatable(weaver, enemy)
weaver.__index = weaver

function weaver:new()
	local obj = enemy:new()
	obj.enemy_type = "weaver"
	obj.dx = 0
	obj.dy = 0
	obj.primary_dx = 0
	obj.primary_dy = 0
	obj.weave_speed = 2.0 + rnd(0.8)
	obj.weave_counter = 0
	
	-- spawn from random edge
	local edge = flr(rnd(4))
	local base_speed = 0.3 + rnd(0.4)
	
	if edge == 0 then -- top
		obj.x = 32 + rnd(64)
		obj.y = 0
		obj.primary_dy = base_speed
		obj.primary_dx = 0
	elseif edge == 1 then -- right
		obj.x = 127
		obj.y = 32 + rnd(64)
		obj.primary_dx = -base_speed
		obj.primary_dy = 0
	elseif edge == 2 then -- bottom
		obj.x = 32 + rnd(64)
		obj.y = 127
		obj.primary_dy = -base_speed
		obj.primary_dx = 0
	elseif edge == 3 then -- left
		obj.x = 0
		obj.y = 32 + rnd(64)
		obj.primary_dx = base_speed
		obj.primary_dy = 0
	end
	
	setmetatable(obj, self)
	self.__index = self
	return obj
end

function weaver:update()
	-- weaving movement
	self.weave_counter += 0.02
	
	-- calculate movement with weaving
	if self.primary_dx != 0 then -- moving horizontally
		self.dx = self.primary_dx
		self.dy = sin(self.weave_counter) * self.weave_speed
	else -- moving vertically
		self.dy = self.primary_dy
		self.dx = sin(self.weave_counter) * self.weave_speed
	end
	
	self.x += self.dx
	self.y += self.dy
	
	-- remove if off screen
	if self.x < -10 or self.x > 137 or self.y < -10 or self.y > 137 then
		self.active = false
	end
	
	-- call parent update for animation
	enemy.update(self)
end

function weaver:draw()
	if self.active then
		local sprite_id = 33 + self.sprite_index
		spr(sprite_id, self.x - 4, self.y - 4)
	end
end

-- shared circling behavior mixin --
function init_circling(obj, start_x, start_y)
	obj.circle_radius = 50 + rnd(25)
	obj.circle_angle = rnd(6.28)
	obj.circle_speed = 0.02 + rnd(0.015)
	obj.target_x = 64
	obj.target_y = 64
	
	-- if start position provided, calculate angle/radius from that position
	if start_x and start_y then
		local dx = start_x - obj.target_x
		local dy = start_y - obj.target_y
		obj.circle_radius = sqrt(dx*dx + dy*dy)
		obj.circle_angle = atan2(dy, dx)
		obj.x = start_x
		obj.y = start_y
	else
		-- position based on angle and radius from center
		obj.x = obj.target_x + cos(obj.circle_angle) * obj.circle_radius
		obj.y = obj.target_y + sin(obj.circle_angle) * obj.circle_radius
	end
end

function update_circling(obj)
	-- circling movement - spiral toward center
	obj.circle_angle += obj.circle_speed
	obj.circle_radius -= 0.08
	
	-- calculate new position
	obj.x = obj.target_x + cos(obj.circle_angle) * obj.circle_radius
	obj.y = obj.target_y + sin(obj.circle_angle) * obj.circle_radius
	
	-- remove if too close to center or off screen
	if obj.circle_radius < 5 or obj.x < -10 or obj.x > 137 or obj.y < -10 or obj.y > 137 then
		obj.active = false
		return true -- indicate removal
	end
	return false
end

-- circler enemy subclass --
circler = {}
setmetatable(circler, enemy)
circler.__index = circler

function circler:new()
	local obj = enemy:new()
	obj.enemy_type = "circler"
	init_circling(obj)
	
	setmetatable(obj, self)
	self.__index = self
	return obj
end

function circler:update()
	update_circling(self)
	-- circlers don't animate, so skip parent update
end

function circler:draw()
	if self.active then
		spr(37, self.x - 4, self.y - 4)
	end
end

-- transformer enemy subclass --
transformer = {}
setmetatable(transformer, enemy)
transformer.__index = transformer

function transformer:new()
	local obj = weaver:new() -- start with weaver behavior
	obj.enemy_type = "transformer"
	obj.sprite_index = 0 -- only use sprites 49, 50
	
	setmetatable(obj, self)
	self.__index = self
	return obj
end

function transformer:is_transformer()
	return true
end

function transformer:update()
	-- use weaving behavior before transformation
	weaver.update(self)
end

function transformer:draw()
	if self.active then
		local sprite_id = 49 + (self.sprite_index % 2) -- only use sprites 49, 50
		spr(sprite_id, self.x - 4, self.y - 4)
	end
end

-- zoggon enemy subclass --
zoggon = {}
setmetatable(zoggon, enemy)
zoggon.__index = zoggon

function zoggon:new(start_x, start_y)
	local obj = enemy:new()
	obj.enemy_type = "zoggon"
	obj.x = start_x or 64
	obj.y = start_y or 64
	obj.target_x = 64
	obj.target_y = 64
	obj.speed = 0.3 + rnd(0.4)
	obj.invincible = true
	obj.invincible_timer = zoggon_invincible_duration
	obj.flash_timer = 0
	obj.flash_count = 0
	obj.is_flashing = true
	
	setmetatable(obj, self)
	self.__index = self
	return obj
end

function zoggon:update()
	-- handle invincibility and flashing
	if self.invincible then
		self.invincible_timer -= 1
		if self.invincible_timer <= 0 then
			self.invincible = false
			self.is_flashing = false
		else
			-- handle flashing animation
			self.flash_timer -= 1
			if self.flash_timer <= 0 then
				self.flash_count += 1
				if self.flash_count >= zoggon_max_flash_count * 2 then
					-- stop flashing but keep invincible until timer runs out
					self.is_flashing = false
				else
					self.flash_timer = zoggon_flash_duration
				end
			end
		end
	end
	
	-- move directly toward the player base
	local dx = self.target_x - self.x
	local dy = self.target_y - self.y
	local distance = sqrt(dx*dx + dy*dy)
	
	if distance > 1 then
		-- normalize and apply speed
		self.x += (dx / distance) * self.speed
		self.y += (dy / distance) * self.speed
	end
	
	-- remove if reached center or off screen
	if distance < 3 or self.x < -10 or self.x > 137 or self.y < -10 or self.y > 137 then
		self.active = false
	end
	
	-- zoggons don't animate, so skip parent update
end

function zoggon:draw()
	if self.active then
		-- apply flash effect if needed
		if self.is_flashing and self.flash_count % 2 == 1 then
			pal(11, 7) -- remap color 11 to color 7 for flash effect
			pal(3, 6)  -- remap color 3 to color 6 for flash effect
		end
		
		spr(51, self.x - 4, self.y - 4)
		
		-- reset palette after drawing
		if self.is_flashing and self.flash_count % 2 == 1 then
			pal() -- reset palette to normal
		end
	end
end

-- star background class --
star = {}
function star:new(star_type)
	local obj = {
		x = rnd(128),
		y = -5,
		speed = 0,
		size = 0,
		color = 6,
		star_type = star_type or "far",
		active = true
	}
	
	if star_type == "close" then
		obj.speed = 3 + rnd(1)
		obj.size = 2
		obj.color = 7
	elseif star_type == "mid" then
		obj.speed = 1.5 + rnd(0.8)
		obj.size = 1
		obj.color = 6
	else -- far
		obj.speed = 0.8 + rnd(0.5)
		obj.size = 0
		obj.color = 6
	end
	
	setmetatable(obj, self)
	self.__index = self
	return obj
end

function star:update()
	self.y += self.speed
	if self.y > 133 then
		self.active = false
	end
end

function star:draw()
	if self.active then
		if self.size == 0 then
			pset(self.x, self.y, self.color)
		elseif self.size == 2 then
			-- draw plus sign for biggest stars
			line(self.x - 2, self.y, self.x + 2, self.y, self.color) -- horizontal line
			line(self.x, self.y - 2, self.x, self.y + 2, self.color) -- vertical line
		else
			circfill(self.x, self.y, self.size, self.color)
		end
	end
end

-- powerup class --
powerup = {}
function powerup:new()
	local obj = {
		x = 0,
		y = 16,
		dx = 1,
		active = true
	}
	setmetatable(obj, self)
	self.__index = self
	return obj
end

function powerup:update()
	self.x += self.dx
	-- remove powerup if it goes off screen
	if self.x > 135 then
		self.active = false
	end
end

function powerup:draw()
	if self.active then
		spr(36, self.x - 4, self.y - 4)
	end
end

-- collision detection --
function check_collisions()
	-- bullet vs enemy collisions
	for b in all(bullets) do
		if b.active then
			for e in all(enemies) do
				if e.active then
					if abs(b.x - e.x) < 6 and abs(b.y - e.y) < 6 then
						-- check if enemy is invincible (zoggons)
						if e.invincible then
							-- bullet hits invincible enemy, destroy bullet but don't damage enemy
							b.active = false
						else
							b.active = false
							e.health -= 1
							if e.health <= 0 then
							add(explosions, explosion:new(e.x, e.y))
							e.active = false
							score += 1
							
							-- check if transformer after death
							if e:is_transformer() then
								-- transformer: spawn 3 zoggons in a spread pattern
								local base_x, base_y = 64, 64
								local dx = e.x - base_x
								local dy = e.y - base_y
								local distance = sqrt(dx*dx + dy*dy)
								
								-- calculate base position 30 pixels further from base
								local base_spawn_x, base_spawn_y
								if distance > 0 then
									local norm_x = dx / distance
									local norm_y = dy / distance
									base_spawn_x = e.x + norm_x * 30
									base_spawn_y = e.y + norm_y * 30
								else
									-- fallback if transformer dies exactly on base
									base_spawn_x = e.x + 30
									base_spawn_y = e.y
								end
								
								-- spawn 3 zoggons in a spread pattern
								for i = 1, 3 do
									local angle_offset = (i - 2) * 0.3 -- -0.3, 0, 0.3 radians spread
									local spread_x = base_spawn_x + cos(angle_offset) * 10
									local spread_y = base_spawn_y + sin(angle_offset) * 10
									local new_zoggon = zoggon:new(spread_x, spread_y)
									add(enemies, new_zoggon)
									printh("adding zoggon "..i.." at "..spread_x..", "..spread_y, "log.txt")
								end
								sfx(5)
							else
								-- normal enemy death sound
								sfx(1)
							end
							end
						end
					end
				end
			end
		end
	end
	
	-- bullet vs powerup collisions
	for b in all(bullets) do
		if b.active then
			for p in all(powerups) do
				if p.active then
					if abs(b.x - p.x) < 6 and abs(b.y - p.y) < 6 then
						b.active = false
						p.active = false
						powered_up = true
						powerup_timer = powerup_duration
						sfx(4)
					end
				end
			end
		end
	end
	
	-- enemy vs base collisions (pixel-perfect detection)
	for e in all(enemies) do
		if e.active then
			-- first do a rough distance check for performance
			if abs(e.x - player_base.x) < 14 and abs(e.y - player_base.y) < 14 then
				-- then check for actual pixel collision
				local collision = false
				-- check a 3x3 grid around enemy center for non-black pixels
				for dx = -1, 1 do
					for dy = -1, 1 do
						local check_x = flr(e.x + dx)
						local check_y = flr(e.y + dy)
						-- make sure we're checking within screen bounds
						if check_x >= 0 and check_x < 128 and check_y >= 0 and check_y < 128 then
							local pixel = pget(check_x, check_y)
							-- check if pixel is not black (0) and not the enemy color
							if pixel != 0 and pixel != 8 and pixel != 9 and pixel != 10 then
								collision = true
								break
							end
						end
					end
					if collision then break end
				end
				
				if collision then
					e.active = false
					add(explosions, explosion:new(e.x, e.y, "base"))
					player_base:hit()
				end
			end
		end
	end
end

-- cleanup inactive objects --
function cleanup()
	-- remove inactive bullets
	for b in all(bullets) do
		if not b.active then
			del(bullets, b)
		end
	end
	
	-- remove inactive enemies
	printh("cleanup: checking "..#enemies.." enemies", "log.txt")
	for e in all(enemies) do
		if not e.active then
			printh("cleanup: removing inactive "..e:get_type(), "log.txt")
			del(enemies, e)
		else
			printh("cleanup: keeping active "..e:get_type().." at "..e.x..", "..e.y, "log.txt")
		end
	end
	printh("cleanup: "..#enemies.." enemies remain", "log.txt")
	
	-- remove inactive explosions
	for ex in all(explosions) do
		if not ex.active then
			del(explosions, ex)
		end
	end
	
	-- remove inactive powerups
	for p in all(powerups) do
		if not p.active then
			del(powerups, p)
		end
	end
	
	-- always cleanup inactive stars
	for s in all(stars) do
		if not s.active then
			del(stars, s)
		end
	end
end

-- explosion class --
explosion = {}
function explosion:new(x, y, explosion_type)
	local obj = {
		x = x,
		y = y,
		frame = 0,
		sprite_index = 0,
		active = true,
		explosion_type = explosion_type or "enemy" -- "enemy" or "base"
	}
	setmetatable(obj, self)
	self.__index = self
	return obj
end

function explosion:update()
	self.frame += 1
	if self.frame >= explosion_frame_duration then
		self.frame = 0
		self.sprite_index += 1
		if self.sprite_index > 2 then
			self.active = false
		end
	end
end

function explosion:draw()
	if self.active then
		local sprite_id
		if self.explosion_type == "base" then
			sprite_id = 21 + self.sprite_index -- sprites 21, 22, 23
		else
			sprite_id = 5 + self.sprite_index -- sprites 5, 6, 7
		end
		spr(sprite_id, self.x - 4, self.y - 4)
	end
end

-- main game code --
function _init()
	player_base = base:new()
	bullets = {}
	enemies = {}
	explosions = {}
	powerups = {}
	stars = {}
	enemy_spawn_timer = 0
	powerup_spawn_timer = 0
	star_spawn_timer = 0
	game_over = false
	game_started = false
	score = 0
	powered_up = false
	powerup_timer = 0
	explosion_frame_duration = 5 -- frames per explosion sprite
	enemy_animation_delay = 15 -- frames per enemy animation frame
	flash_duration = 4 -- frames each flash state lasts
	max_flash_count = 4 -- total number of flashes (on/off cycles)
	powerup_spawn_interval = 600 -- frames between powerups (10 seconds at 60fps)
	powerup_duration = 300 -- frames powerup lasts (5 seconds)
	zoggon_invincible_duration = 30 -- frames zoggons are invincible (0.5 seconds)
	zoggon_flash_duration = 6 -- frames each flash state lasts for zoggons
	zoggon_max_flash_count = 8 -- total number of flashes for zoggons
end

function _update()
	-- always update stars on all screens
	star_spawn_timer += 1
	if star_spawn_timer > 15 then
		local star_type_roll = rnd()
		local star_type
		if star_type_roll < 0.2 then
			star_type = "close"
		elseif star_type_roll < 0.5 then
			star_type = "mid"
		else
			star_type = "far"
		end
		add(stars, star:new(star_type))
		star_spawn_timer = 0
	end
	
	-- update stars
	for s in all(stars) do
		s:update()
	end
	
	if not game_started then
		-- check for any button press to start
		if btnp(0) or btnp(1) or btnp(2) or btnp(3) or btnp(4) or btnp(5) then
			game_started = true
		end
	elseif not game_over then
		player_base:update()
		
		-- update bullets
		for b in all(bullets) do
			b:update()
		end
		
		-- spawn enemies
		enemy_spawn_timer += 1
		if enemy_spawn_timer > 45 then
			-- randomly spawn weaver, circler, or transformer enemy
			local enemy_roll = rnd()
			if enemy_roll < 0.5 then
				add(enemies, weaver:new())
			elseif enemy_roll < 0.8 then
				add(enemies, circler:new())
			else
				add(enemies, transformer:new())
			end
			enemy_spawn_timer = 0
		end
		
		-- spawn powerups
		powerup_spawn_timer += 1
		if powerup_spawn_timer > powerup_spawn_interval then
			add(powerups, powerup:new())
			powerup_spawn_timer = 0
		end
		
		-- update powerups
		for p in all(powerups) do
			p:update()
		end
		
		-- update powerup timer
		if powered_up then
			powerup_timer -= 1
			if powerup_timer <= 0 then
				powered_up = false
			end
		end
		
		
		-- update enemies
		printh("---- Updating enemies: there are "..#enemies.." total enemies.", "log.txt")
		for e in all(enemies) do
			e:update()
		end
		
		-- update explosions
		for ex in all(explosions) do
			ex:update()
		end
		
		check_collisions()
		cleanup()
		
		-- check game over
		if player_base.health <= 0 then
			game_over = true
		end
	end
end

function _draw()
	cls()
	
	if not game_started then
		-- draw background stars on title screen
		for s in all(stars) do
			s:draw()
		end
		
		-- title screen
		print("orbit guard", 40, 30, 7)
		print("defend your lonely rock", 20, 40, 6)
		print("from endless waves!", 28, 48, 6)
		
		print("controls:", 2, 60, 7)
		print("left/right - rotate gun", 2, 68, 6)
		print("z - shoot", 2, 76, 6)
		print("shoot power-ups for spread!", 2, 84, 5)
		
		print("press any button to start", 18, 100, 7)
	elseif not game_over then
		-- draw background stars first
		for s in all(stars) do
			s:draw()
		end
		
		player_base:draw()
		
		-- draw bullets
		for b in all(bullets) do
			b:draw()
		end
		
		-- draw enemies
		for e in all(enemies) do
			if e.x and e.y then
				printh("drawing "..e:get_type().." at "..e.x..", "..e.y.." active: "..tostr(e.active), "log.txt")
			end
			e:draw()
		end
		
		-- draw explosions
		for ex in all(explosions) do
			ex:draw()
		end
		
		-- draw powerups
		for p in all(powerups) do
			p:draw()
		end
		
		-- draw ui
		print("health: "..player_base.health, 2, 2, 7)
		local score_text = "score: "..score
		if powered_up then
			local seconds_left = flr(powerup_timer / 60) + 1
			score_text = score_text.." | powered up! "..seconds_left
		end
		print(score_text, 2, 9, 7)
	else
		-- draw background stars on game over screen
		for s in all(stars) do
			s:draw()
		end
		
		print("game over!", 44, 60, 8)
		print("press any button to restart", 16, 70, 7)
		
		if btnp(0) or btnp(1) or btnp(2) or btnp(3) or btnp(4) or btnp(5) then
			_init()
		end
	end
end