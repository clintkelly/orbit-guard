

--[[
LEVEL ENCODING SYSTEM:
Each level is defined as an array of strings, with one string per row of bricks.
Each character in the string represents a single brick position.

CHARACTER MEANINGS:
  .  = Empty space (no brick)
  N  = Normal brick (light blue, 1 hit to destroy, 10 points)
  U  = Unbreakable brick (dark gray, cannot be destroyed)
  2-9 = Multi-hit brick (requires 2-9 hits to destroy)
        - Color changes as hits decrease: red→orange→yellow
        - Full points (10) when destroyed, partial points (5) when damaged
  S  = Speed brick (green, increases ball speed when destroyed)
  M  = Moving brick (purple, moves left/right across screen)
  P  = Powerup brick (looks like normal brick, drops random powerup when destroyed)

LAYOUT RULES:
- Each character position is 12 pixels apart (10px brick + 2px gap)
- Rows are 6 pixels apart (4px brick height + 2px gap)
- Level starts at position (4, 15) for top-left brick
- Maximum 10 characters per row (fits screen width of 128 pixels)
- Empty strings or dots create gaps in the brick pattern

SCORING:
- Normal/Speed bricks: 10 points when destroyed
- Multi-hit bricks: 5 points per hit, 10 points when fully destroyed  
- Points are multiplied by combo system: points * (combo * 10 + 1)
--]]

levels = {
	-- level 1: C-shaped pattern
	{
		"NPPPPPPPPN",
		"N.........",
		"N.........",
		"N.........",
		"NPPPPPPPPN"
	},
	-- level 2: alternating staggered rows
	{
		".N.N.NPN.N",
		"N.N.N.N.N.",
		".N.P.N.N.N",
		"N.N.N.N.N.",
		".N.N.P.N.N",
		"N.P.N.N.N.",
		".N.N.N.P.N"
	},
	-- level 3: mixed with speed bricks
	{
		"N.S.P.S.N.",
		".2.3.2.3.2",
		"S.N.S.P.S.",
		".3.2.3.2.3",
		"N.S.N.P.N."
	},
	-- level 4: moving bricks test
	{
		"...........",
		"M.P.M.M.M.",
		".M...M...M",
		"M..NPN..M.",
		"..........."
	},
	-- level 5: powerup bricks test
	{
		"NNNNNNNNNN",
		"N.P.N.P.N.",
		"NNNNNNNNNN",
		"P.N.P.N.P.",
		"NNNNNNNNNN"
	},
	-- level 6: basic mixed types
	{
		"N.N.N.N.N.",
		".2.2.2.2.2",
		"N.N.N.N.N.",
		".S.P.S.P.S"
	},
	-- level 7: unbreakable walls with gaps
	{
		"..U......U",
		"NNNNNNNNNN",
		"P.2.P.2.P.",
		"NNNNNNNNNN",
		"..U......U"
	},
	-- level 8: moving brick challenge
	{
		".M.M.M.M.M",
		"N.N.N.N.N.",
		"M.M.M.M.M.",
		".3.P.3.P.3",
		"N.N.N.N.N."
	},
	-- level 9: fortress pattern
	{
		"...........",
		"..N2PP2N..",
		"..N3SS3N..",
		"..N2PP2N..",
		".........."
	},
	-- level 10: speed brick maze
	{
		"S.S.S.S.S.",
		".N.P.N.P.N",
		"S.2.3.2.S.",
		".N.P.N.P.N",
		"S.S.S.S.S."
	},
	-- level 11: heavy defense
	{
		"..U......U",
		".4.4.4.4.4",
		"...........",
		".4.4.4.4.4",
		"..U......U"
	},
	-- level 12: mixed chaos
	{
		"M.3.S.3.M.",
		".P.....P..",
		"2.M.P.M.2.",
		".P.....P..",
		".M.3.S.3.M"
	},
	-- level 13: tight corridors
	{
		"..N.N.N...",
		"...........",
		"N.P.5.P.N.",
		"...........",
		"..N.N.N..."
	},
	-- level 14: final gauntlet
	{
		"..M.P.M...",
		".5.....5..",
		"M.3.S.3.M.",
		".5.....5..",
		"..M.P.M..."
	},
	-- level 15: ultimate challenge
	{
		"...........",
		"..6.P.6...",
		"..M.S.M...",
		"..6.P.6...",
		"..........."
	}
}

current_level = 1
shuffled_levels = {} -- will hold shuffled level order after level 1

-- global game variables
game_state = "start"
player_lives = 5
player_score = 0
player_combo = 0
powerup_fall_speed = 0.5 -- speed at which powerups fall
powerup_bottom_pause = 60 -- frames to pause at bottom before disappearing (1 second at 60fps)
max_ball_dx_dy_ratio = 3.0 -- maximum ratio of horizontal to vertical velocity (3:1)
default_ball_speed = 2.0 -- default ball speed
default_paddle_width = 24 -- normal paddle width
expanded_paddle_width = 36 -- expanded paddle width (24 * 1.5)
bricks = {}
powerups = {}
balls = {} -- array to track multiple balls
player_shield = nil -- shield object (nil when inactive)
player_paddle = nil -- paddle object (initialized in _init)
floating_texts = {} -- array to track floating score texts

-- title screen animation variables
title_frame_counter = 0
title_fast_blink_timer = 0
title_is_fast_blinking = false

-- screen shake system
screen_shaker = nil -- will be initialized in _init

-- screen fade system
fadeperc = 0 -- fade percentage: 0 = normal, 1 = completely black

-- game over sequence variables
game_over_shake_timer = 0 -- timer for game over shake delay
game_over_text_visible = false -- whether to show game over text
game_over_blink_timer = 0 -- timer for blinking text
game_over_fade_started = false -- whether fade has started

-- level clear sequence variables
level_clear_fade_started = false -- whether fade has started for level transition

-- victory sequence variables
victory_fade_started = false -- whether fade has started for victory screen

-- launch indicator animation variables
launch_indicator_timer = 0 -- timer for particle animation

-- single brick challenge variables
single_brick_paddle_hits = 0 -- track paddle hits when only one brick left
single_brick_randomness_active = false -- whether to add randomness to paddle bounces

-- combo milestone tracking
combo_milestones_reached = {} -- track which combo milestones have been reached

paddle = {}
function paddle:new()
	local obj = {
		x = 52,
		y = 120,
		width = default_paddle_width,
		height = 3,
		max_speed = 2.5, -- max speed - you hit then when the button is pressed
		dx = 0, -- current speed
		friction = 1.2, -- factor by which to reduce speed every frame after button is released
		flash_timer = 0, -- timer for red flash effect
		last_direction = 0, -- track last movement direction for ball launch
		size_timer = 0, -- timer for temporary size effects
		sticky_timer = 0, -- timer for sticky paddle effect
		is_sticky = false -- whether paddle is currently sticky
	}
	setmetatable(obj, self)
	self.__index = self
	return obj
end

function paddle:update()
	local button_pressed = false
	-- left/right movement
	if btn(0) then -- left
		self.dx = -1 * self.max_speed
		self.last_direction = -1
		button_pressed = true
	end
	if btn(1) then -- right
		self.dx = self.max_speed
		self.last_direction = 1
		button_pressed = true
	end

	if not button_pressed then
		self.dx = self.dx / self.friction
	end

	self.x += self.dx
	
	-- keep paddle on screen
	if self.x < 0 then
		self.x = 0
	end
	if self.x + self.width > 128 then
		self.x = 128 - self.width
	end
	
	-- update flash timer
	if self.flash_timer > 0 then
		self.flash_timer -= 1
	end
	
	-- update size timer
	if self.size_timer > 0 then
		self.size_timer -= 1
		if self.size_timer <= 0 then
			-- size effect expired, reset to normal
			self:set_size(default_paddle_width)
		end
	end
	
	-- update sticky timer
	if self.sticky_timer > 0 then
		self.sticky_timer -= 1
		if self.sticky_timer <= 0 then
			-- sticky effect expired
			self.is_sticky = false
		end
	end
end

function paddle:draw()
	local color = 7 -- default white
	if self.flash_timer > 0 then
		color = 8 -- red when flashing
	end
	-- keep white color even when expanded
	
	-- draw paddle as three lines to simulate curve for 7 zones (A-G)
	-- bottom line: full width (covers all zones A through G)
	line(self.x, self.y + 2, self.x + self.width - 1, self.y + 2, color)
	
	-- middle line: covers zones B, C, D, E, F (from ~14.3% to ~85.7% of width)
	local middle_start = self.x + self.width * 0.143
	local middle_end = self.x + self.width * 0.857
	line(middle_start, self.y + 1, middle_end, self.y + 1, color)
	
	-- top line: covers zones C, D, E (from ~28.6% to ~71.4% of width)
	local top_start = self.x + self.width * 0.286
	local top_end = self.x + self.width * 0.714
	line(top_start, self.y, top_end, self.y, color)
end

function paddle:flash()
	self.flash_timer = 5
end

function paddle:set_size(new_width, duration)
	-- set paddle width and optional duration
	if duration then
		self.size_timer = duration
	end
	
	-- update width immediately, keeping paddle centered
	local old_width = self.width
	self.width = new_width
	
	-- adjust x position to keep paddle centered
	self.x += (old_width - self.width) / 2
	
	-- ensure paddle stays on screen
	if self.x < 0 then
		self.x = 0
	elseif self.x + self.width > 128 then
		self.x = 128 - self.width
	end
end

particle_trail = {}
function particle_trail:new(max_particles, fade_speed)
	local obj = {
		particles = {}, -- array of particle positions and data
		max_particles = max_particles or 8, -- maximum number of trail particles
		fade_speed = fade_speed or 0.15, -- how fast particles fade (higher = faster fade)
		enabled = true -- whether trail is active
	}
	setmetatable(obj, self)
	self.__index = self
	return obj
end

function particle_trail:add_particle(x, y, color)
	if not self.enabled then return end
	
	-- add new particle at the front
	add(self.particles, {
		x = x,
		y = y,
		color = color or 10, -- default yellow
		age = 0, -- how long particle has existed
		life = 1.0 -- particle life (1.0 = fully visible, 0.0 = invisible)
	})
	
	-- remove oldest particles if we exceed max
	while #self.particles > self.max_particles do
		del(self.particles, self.particles[1])
	end
end

function particle_trail:update()
	if not self.enabled then return end
	
	-- update all particles
	for i = #self.particles, 1, -1 do
		local particle = self.particles[i]
		particle.age += 1
		particle.life -= self.fade_speed
		
		-- remove dead particles
		if particle.life <= 0 then
			del(self.particles, particle)
		end
	end
end

function particle_trail:draw()
	if not self.enabled then return end
	
	-- draw particles from oldest to newest (back to front)
	for i = 1, #self.particles do
		local particle = self.particles[i]
		
		-- determine color based on particle age and life
		local draw_color = particle.color
		local age_ratio = 1 - particle.life -- 0 = new, 1 = old
		
		-- color transition based on age (customize per trail type)
		if particle.color == 10 then -- yellow trail
			if age_ratio < 0.3 then
				draw_color = 10 -- bright yellow
			elseif age_ratio < 0.6 then
				draw_color = 9 -- orange
			else
				draw_color = 8 -- red
			end
		elseif particle.color == 9 then -- orange trail (speed boost)
			if age_ratio < 0.3 then
				draw_color = 9 -- bright orange
			elseif age_ratio < 0.6 then
				draw_color = 8 -- red
			else
				draw_color = 2 -- dark red
			end
		end
		
		-- fade particle based on life remaining with transparency
		if particle.life > 0.7 then
			-- full brightness
			pset(particle.x, particle.y, draw_color)
		elseif particle.life > 0.4 then
			-- medium brightness - draw with slight transparency effect
			if rnd(1) < particle.life then
				pset(particle.x, particle.y, draw_color)
			end
		elseif particle.life > 0.1 then
			-- low brightness - very transparent
			if rnd(1) < particle.life * 0.5 then
				pset(particle.x, particle.y, draw_color)
			end
		end
	end
end

function particle_trail:clear()
	self.particles = {}
end

function particle_trail:set_enabled(enabled)
	self.enabled = enabled
	if not enabled then
		self:clear()
	end
end

floating_text = {}
function floating_text:new(x, y, text, color, shadow_color)
	local obj = {
		x = x,
		y = y,
		start_y = y,
		text = text,
		color = color or 7, -- default white
		shadow_color = shadow_color or 0, -- default black shadow
		life = 60, -- 1 second at 60fps
		max_life = 60,
		dy = -0.5 -- float upward speed
	}
	setmetatable(obj, self)
	self.__index = self
	return obj
end

function floating_text:update()
	-- move upward
	self.y += self.dy
	
	-- reduce life
	self.life -= 1
	
	-- return true if expired
	return self.life <= 0
end

function floating_text:draw()
	if self.life <= 0 then return end
	
	-- calculate fade based on remaining life
	local fade_ratio = self.life / self.max_life
	
	-- only draw if fade ratio is high enough (prevents flickering at end)
	if fade_ratio > 0.1 then
		-- draw shadow (offset by 1 pixel down and right)
		if rnd(1) < fade_ratio then -- fade shadow with transparency
			print(self.text, self.x + 1, self.y + 1, self.shadow_color)
		end
		
		-- draw main text
		if rnd(1) < fade_ratio then -- fade main text with transparency
			print(self.text, self.x, self.y, self.color)
		end
	end
end

-- global array to track floating texts
floating_texts = {}

function add_floating_text(x, y, text, color, shadow_color)
	add(floating_texts, floating_text:new(x, y, text, color, shadow_color))
end

function update_floating_texts()
	-- update all floating texts and remove expired ones
	for i = #floating_texts, 1, -1 do
		if floating_texts[i]:update() then
			del(floating_texts, floating_texts[i])
		end
	end
end

function draw_floating_texts()
	-- draw all floating texts
	for text_obj in all(floating_texts) do
		text_obj:draw()
	end
end

shaker = {}
function shaker:new()
	local obj = {
		shake = 0 -- current shake intensity (0 = no shake)
	}
	setmetatable(obj, self)
	self.__index = self
	return obj
end

function shaker:small_shake()
	-- initiate a small screen shake
	self.shake = 0.3
end

function shaker:large_shake()
	-- initiate a large screen shake
	self.shake = 1.0
end

function shaker:shake_screen()
	if self.shake <= 0 then
		-- no shake, reset camera to normal
		camera(0, 0)
		return
	end
	
	-- calculate random shake offset based on your provided algorithm
	-- -16 +16 range
	local shakex = 16 - rnd(32)
	local shakey = 16 - rnd(32)
	
	-- scale by current shake intensity
	shakex *= self.shake
	shakey *= self.shake
	
	-- apply camera shake
	camera(shakex, shakey)
	
	-- reduce shake intensity over time
	self.shake *= 0.95
	if self.shake < 0.05 then
		self.shake = 0
		camera(0, 0) -- ensure camera is reset when shake ends
	end
end

function fadepal(_perc)
	-- 0 means normal
	-- 1 is completely black
	
	local p = flr(mid(0, _perc, 1) * 100)
	
	-- these are helper variables
	local kmax, col, dpal, j, k
	dpal = {0, 1, 1, 2, 1, 13, 6, 
	        4, 4, 9, 3, 13, 1, 13, 14}
	
	-- now we go through all colors
	for j = 1, 15 do
		-- grab the current color
		col = j
		
		-- now calculate how many
		-- times we want to fade the
		-- color.
		kmax = (p + (j * 1.46)) / 22
		for k = 1, kmax do
			col = dpal[col]
		end
		
		-- finally, we change the
		-- palette
		pal(j, col, 1)
	end
end

brick = {}
function brick:new(x, y)
	local obj = {
		x = x or 60,
		y = y or 20,
		width = 10,
		height = 4,
		active = true,
		breakable = true,
		hits_remaining = 1,
		color = 12,
		drops_powerup = false
	}
	setmetatable(obj, self)
	self.__index = self
	return obj
end

function brick:hit()
	if not self.breakable then
		return false -- unbreakable brick
	end
	
	self.hits_remaining -= 1
	if self.hits_remaining <= 0 then
		self.active = false
		return true -- brick destroyed
	end
	return false -- brick damaged but not destroyed
end

function brick:draw()
	if self.active then
		rectfill(self.x, self.y, self.x + self.width - 1, self.y + self.height - 1, self.color)
	end
end

function brick:on_destroy()
	-- override in subclasses for special effects
end

-- normal brick subclass --
normal_brick = {}
setmetatable(normal_brick, {__index = brick})

function normal_brick:new(x, y)
	local obj = brick.new(self, x, y)
	obj.color = 12 -- light blue
	return obj
end

-- unbreakable brick subclass --
unbreakable_brick = {}
setmetatable(unbreakable_brick, {__index = brick})

function unbreakable_brick:new(x, y)
	local obj = brick.new(self, x, y)
	obj.breakable = false
	obj.color = 5 -- dark gray
	return obj
end

-- multi-hit brick subclass --
multi_hit_brick = {}
setmetatable(multi_hit_brick, {__index = brick})

function multi_hit_brick:new(x, y, hits)
	local obj = brick.new(self, x, y)
	obj.hits_remaining = hits or 2
	obj.max_hits = obj.hits_remaining
	obj:update_color()
	return obj
end

function multi_hit_brick:hit()
	local destroyed = brick.hit(self)
	if not destroyed and self.active then
		self:update_color()
	end
	return destroyed
end

function multi_hit_brick:update_color()
	-- color changes based on remaining hits
	if self.hits_remaining >= 4 then
		self.color = 8 -- red for high hits
	elseif self.hits_remaining >= 2 then
		self.color = 9 -- orange for medium hits
	else
		self.color = 10 -- yellow for low hits
	end
end

-- speed brick subclass --
speed_brick = {}
setmetatable(speed_brick, {__index = brick})

function speed_brick:new(x, y)
	local obj = brick.new(self, x, y)
	obj.color = 11 -- green
	return obj
end

function speed_brick:on_destroy()
	-- speed effect will be handled in ball collision
	return "speed"
end

-- moving brick subclass --
moving_brick = {}
setmetatable(moving_brick, {__index = brick})

function moving_brick:new(x, y)
	local obj = brick.new(self, x, y)
	obj.color = 13 -- purple
	obj.move_direction = 1 -- 1 for right, -1 for left
	obj.move_speed = 0.5
	return obj
end

function moving_brick:update()
	-- move the brick back and forth
	self.x += self.move_direction * self.move_speed
	
	-- bounce off screen edges
	if self.x <= 0 then
		self.x = 0
		self.move_direction = 1
	elseif self.x >= 128 - self.width then
		self.x = 128 - self.width
		self.move_direction = -1
	end
end

-- powerup brick subclass --
powerup_brick = {}
setmetatable(powerup_brick, {__index = brick})

function powerup_brick:new(x, y)
	local obj = brick.new(self, x, y)
	obj.color = 12 -- looks like normal brick
	obj.drops_powerup = true
	return obj
end

function powerup_brick:on_destroy()
	-- return random powerup type
	local powerup_types = {"extra_life", "multi_ball", "bigger_paddle", "sticky_paddle", "shield"}
	local random_index = flr(rnd(#powerup_types)) + 1
	return powerup_types[random_index]
end


-- base powerup class --
powerup = {}
function powerup:new(x, y)
	local obj = {
		x = x or 64,
		y = y or 20,
		width = 8,
		height = 8,
		dy = powerup_fall_speed,
		active = true,
		sprite_id = 0,
		bottom_pause_timer = 0, -- timer for pausing at bottom
		is_paused = false, -- whether powerup is paused at bottom
		flash_timer = 0 -- timer for flashing effect
	}
	setmetatable(obj, self)
	self.__index = self
	return obj
end

function powerup:update()
	if not self.active then return end
	
	-- handle paused state at bottom
	if self.is_paused then
		self.bottom_pause_timer -= 1
		self.flash_timer += 1
		
		-- check if hit paddle while paused
		if self:check_paddle_collision() then
			self:collect()
			self.active = false
			sfx(4) -- play powerup collected sound
		end
		
		-- check if pause timer expired
		if self.bottom_pause_timer <= 0 then
			self.active = false
		end
		return
	end
	
	-- fall down normally
	self.y += self.dy
	
	-- check if hit paddle
	if self:check_paddle_collision() then
		self:collect()
		self.active = false
		sfx(4) -- play powerup collected sound
	end
	
	-- check if hit bottom of screen
	if self.y >= 120 then -- start pause slightly above bottom
		self.is_paused = true
		self.bottom_pause_timer = powerup_bottom_pause
		self.flash_timer = 0
		self.y = 120 -- lock position at bottom
	end
end

function powerup:check_paddle_collision()
	-- simple box collision with paddle
	return self.x < player_paddle.x + player_paddle.width and
	       self.x + self.width > player_paddle.x and
	       self.y < player_paddle.y + player_paddle.height and
	       self.y + self.height > player_paddle.y
end

function powerup:collect()
	-- override in subclasses
end

function powerup:draw()
	if self.active then
		-- flash effect when paused at bottom
		if self.is_paused then
			-- flash every 4 frames (fast blinking)
			if self.flash_timer % 8 < 4 then
				spr(self.sprite_id, self.x, self.y)
			end
		else
			-- normal drawing
			spr(self.sprite_id, self.x, self.y)
		end
	end
end

-- extra life powerup subclass --
extra_life_powerup = {}
setmetatable(extra_life_powerup, {__index = powerup})

function extra_life_powerup:new(x, y)
	local obj = powerup.new(self, x, y)
	obj.sprite_id = 3
	return obj
end

function extra_life_powerup:collect()
	player_lives += 1
end

-- multi-ball powerup subclass --
multi_ball_powerup = {}
setmetatable(multi_ball_powerup, {__index = powerup})

function multi_ball_powerup:new(x, y)
	local obj = powerup.new(self, x, y)
	obj.sprite_id = 4
	return obj
end

function multi_ball_powerup:collect()
	spawn_additional_balls()
	sfx(5) -- play multi-ball sound
end

-- bigger paddle powerup subclass --
bigger_paddle_powerup = {}
setmetatable(bigger_paddle_powerup, {__index = powerup})

function bigger_paddle_powerup:new(x, y)
	local obj = powerup.new(self, x, y)
	obj.sprite_id = 5
	return obj
end

function bigger_paddle_powerup:collect()
	expand_paddle()
end

function expand_paddle()
	-- expand paddle for 10 seconds (600 frames at 60fps)
	player_paddle:set_size(expanded_paddle_width, 600)
end

-- sticky paddle powerup subclass --
sticky_paddle_powerup = {}
setmetatable(sticky_paddle_powerup, {__index = powerup})

function sticky_paddle_powerup:new(x, y)
	local obj = powerup.new(self, x, y)
	obj.sprite_id = 6
	return obj
end

function sticky_paddle_powerup:collect()
	activate_sticky_paddle()
end

function activate_sticky_paddle()
	-- activate sticky paddle for 10 seconds (600 frames at 60fps)
	player_paddle.is_sticky = true
	player_paddle.sticky_timer = 600
end

-- shield powerup subclass --
shield_powerup = {}
setmetatable(shield_powerup, {__index = powerup})

function shield_powerup:new(x, y)
	local obj = powerup.new(self, x, y)
	obj.sprite_id = 7
	return obj
end

function shield_powerup:collect()
	activate_shield()
end

function activate_shield()
	-- create a shield at bottom of paddle with particle system
	player_shield = {
		active = true,
		y = player_paddle.y + player_paddle.height, -- position shield at bottom of paddle
		color = 12,
		particles = {} -- array to hold shield particles
	}
	
	-- initialize shield particles across the screen width
	for i = 0, 127, 2 do -- every 2 pixels across screen width
		add(player_shield.particles, {
			x = i,
			base_y = player_shield.y,
			y = player_shield.y,
			offset_y = 0,
			speed = 0.2 + rnd(0.4), -- random speed between 0.2 and 0.6
			phase = rnd(1), -- random phase for wave motion
			color = 12 -- default light blue
		})
	end
end

function update_shield()
	if not player_shield or not player_shield.active then
		return
	end
	
	-- update each shield particle
	for particle in all(player_shield.particles) do
		-- update wave motion phase
		particle.phase += particle.speed
		if particle.phase > 1 then
			particle.phase -= 1
		end
		
		-- calculate wave offset (sine wave for smooth motion)
		particle.offset_y = sin(particle.phase * 2) * 2 -- 2 pixel amplitude
		particle.y = particle.base_y + particle.offset_y
		
		-- randomly change particle color for sparkle effect
		if rnd(1) < 0.1 then -- 10% chance each frame
			local colors = {12, 6, 7} -- light blue, light grey, white
			particle.color = colors[flr(rnd(3)) + 1]
		end
	end
end

function draw_shield()
	if not player_shield or not player_shield.active then
		return
	end
	
	-- draw each shield particle
	for particle in all(player_shield.particles) do
		-- draw particle as a single pixel
		pset(particle.x, particle.y, particle.color)
		-- add slight vertical spread for thickness
		if rnd(1) < 0.5 then
			pset(particle.x, particle.y + 1, particle.color)
		end
	end
end

function spawn_additional_balls()
	-- spawn two new balls based on current ball position
	local base_ball = balls[1] -- use first ball as reference
	
	-- create two new balls with slightly random directions
	for i = 1, 2 do
		local new_ball = ball:new()
		new_ball.x = base_ball.x
		new_ball.y = base_ball.y
		new_ball.is_stuck_to_paddle = false
		
		-- set random direction with negative dy (upward) and respect dx:dy ratio
		local angle_offset = (rnd(0.6) - 0.3) -- random between -0.3 and 0.3
		local speed = default_ball_speed
		local proposed_dx = speed * sin(angle_offset)
		local proposed_dy = -speed * cos(angle_offset) -- negative for upward
		
		-- check and enforce dx:dy ratio limit
		local abs_dx = abs(proposed_dx)
		local abs_dy = abs(proposed_dy)
		
		if abs_dy > 0 and abs_dx / abs_dy > max_ball_dx_dy_ratio then
			-- ratio is too high, adjust to max ratio while conserving speed
			local ratio = max_ball_dx_dy_ratio
			local new_dy_magnitude = speed / sqrt(ratio * ratio + 1)
			local new_dx_magnitude = new_dy_magnitude * ratio
			
			-- preserve signs
			new_ball.dx = proposed_dx >= 0 and new_dx_magnitude or -new_dx_magnitude
			new_ball.dy = proposed_dy >= 0 and new_dy_magnitude or -new_dy_magnitude
		else
			-- ratio is fine, use proposed values
			new_ball.dx = proposed_dx
			new_ball.dy = proposed_dy
		end
		
		add(balls, new_ball)
	end
end

function handle_brick_hit(brick, ball, destroyed)
	if destroyed then
		-- cap combo to prevent integer overflow and balance gameplay
		local safe_combo = min(player_combo, 20)
		local points = 10 * (safe_combo + 1)
		player_score += points
		player_combo += 1 -- increase combo for each brick hit
		
		-- create floating score text
		local text_x = brick.x + brick.width / 2 - 8 -- center text on brick
		local text_y = brick.y - 5 -- position above brick
		local score_text = "+" .. tostr(points)
		local text_color = 10 -- yellow for normal scores
		
		-- different colors based on combo level
		if safe_combo >= 15 then
			text_color = 8 -- red for ultimate combo
		elseif safe_combo >= 10 then
			text_color = 14 -- pink for incredible combo
		elseif safe_combo >= 5 then
			text_color = 9 -- orange for high combo
		elseif safe_combo >= 3 then
			text_color = 11 -- green for medium combo
		end
		
		add_floating_text(text_x, text_y, score_text, text_color, 1) -- dark blue shadow
		
		-- special combo messages and rewards (only once per milestone)
		if player_combo == 5 and not combo_milestones_reached[5] then
			add_floating_text(text_x, text_y - 10, "awesome combo!", 11, 5) -- green with dark grey shadow
			sfx(15) -- combo milestone sound 1
			sfx(16) -- combo milestone sound 2
			combo_milestones_reached[5] = true
		elseif player_combo == 10 and not combo_milestones_reached[10] then
			add_floating_text(text_x, text_y - 10, "incredible!", 14, 0) -- pink with black shadow
			add_floating_text(text_x, text_y - 18, "+1 life", 14, 0) -- pink with black shadow
			player_lives += 1
			sfx(15) -- combo milestone sound 1
			sfx(16) -- combo milestone sound 2
			combo_milestones_reached[10] = true
		elseif player_combo == 15 and not combo_milestones_reached[15] then
			add_floating_text(text_x, text_y - 10, "mind blown!!!!", 8, 0) -- red with black shadow
			add_floating_text(text_x, text_y - 18, "+2 lives", 8, 0) -- red with black shadow
			player_lives += 2
			sfx(15) -- combo milestone sound 1
			sfx(16) -- combo milestone sound 2
			combo_milestones_reached[15] = true
		elseif player_combo == 20 and not combo_milestones_reached[20] then
			add_floating_text(text_x, text_y - 10, "you're on fire!", 10, 8) -- yellow with red shadow
			add_floating_text(text_x, text_y - 18, "+4 lives", 10, 8) -- yellow with red shadow
			player_lives += 4
			sfx(15) -- combo milestone sound 1
			sfx(16) -- combo milestone sound 2
			combo_milestones_reached[20] = true
		end
		
		-- handle special brick effects
		local effect = brick:on_destroy()
		if effect == "speed" then
			-- speed brick: increase ball speed and activate decay timer
			ball.dx *= 1.2
			ball.dy *= 1.2
			ball.speed_boost_timer = 300 -- 5 seconds at 60fps
			ball.speed_boost_active = true
		elseif brick.drops_powerup and effect then
			-- powerup brick: spawn powerup
			spawn_powerup(effect, brick.x + brick.width/2, brick.y + brick.height)
		end
	elseif brick.breakable then
		-- only increase combo and give points for breakable bricks that are damaged
		local safe_combo = min(player_combo, 20)
		local points = 5 * (safe_combo + 1)
		player_score += points -- partial points for damaged brick
		player_combo += 1 -- increase combo for damaged breakable bricks
		
		-- create floating score text for damaged bricks
		local text_x = brick.x + brick.width / 2 - 6 -- center text on brick
		local text_y = brick.y - 5 -- position above brick
		local score_text = "+" .. tostr(points)
		add_floating_text(text_x, text_y, score_text, 6, 5) -- light grey with dark grey shadow
		
		-- special combo messages and rewards (only once per milestone)
		if player_combo == 5 and not combo_milestones_reached[5] then
			add_floating_text(text_x, text_y - 10, "awesome combo!", 11, 5) -- green with dark grey shadow
			combo_milestones_reached[5] = true
		elseif player_combo == 10 and not combo_milestones_reached[10] then
			add_floating_text(text_x, text_y - 10, "incredible!", 14, 0) -- pink with black shadow
			add_floating_text(text_x, text_y - 18, "+1 life", 14, 0) -- pink with black shadow
			player_lives += 1
			sfx(15) -- combo milestone sound 1
			sfx(16) -- combo milestone sound 2
			combo_milestones_reached[10] = true
		elseif player_combo == 15 and not combo_milestones_reached[15] then
			add_floating_text(text_x, text_y - 10, "mind blown!!!!", 8, 0) -- red with black shadow
			add_floating_text(text_x, text_y - 18, "+2 lives", 8, 0) -- red with black shadow
			player_lives += 2
			sfx(15) -- combo milestone sound 1
			sfx(16) -- combo milestone sound 2
			combo_milestones_reached[15] = true
		elseif player_combo == 20 and not combo_milestones_reached[20] then
			add_floating_text(text_x, text_y - 10, "you're on fire!", 10, 8) -- yellow with red shadow
			add_floating_text(text_x, text_y - 18, "+4 lives", 10, 8) -- yellow with red shadow
			player_lives += 4
			sfx(15) -- combo milestone sound 1
			sfx(16) -- combo milestone sound 2
			combo_milestones_reached[20] = true
		end
	end
	-- if brick is unbreakable, no points or combo increase
	
	-- play sound based on combo length (sound 6 to 13 max)
	local sound_id = min(6 + player_combo - 1, 13)
	sfx(sound_id)
end

function spawn_powerup(powerup_type, x, y)
	local new_powerup
	if powerup_type == "extra_life" then
		new_powerup = extra_life_powerup:new(x - 4, y) -- center on brick
	elseif powerup_type == "multi_ball" then
		new_powerup = multi_ball_powerup:new(x - 4, y) -- center on brick
	elseif powerup_type == "bigger_paddle" then
		new_powerup = bigger_paddle_powerup:new(x - 4, y) -- center on brick
	elseif powerup_type == "sticky_paddle" then
		new_powerup = sticky_paddle_powerup:new(x - 4, y) -- center on brick
	elseif powerup_type == "shield" then
		new_powerup = shield_powerup:new(x - 4, y) -- center on brick
	else
		-- default to extra life for now
		new_powerup = extra_life_powerup:new(x - 4, y)
	end
	
	if new_powerup then
		add(powerups, new_powerup)
	end
end

function check_brick_collisions(ball, next_x, next_y)
	local hit_a_brick = false -- make sure we don't bounce twice
	local corrected_x = next_x
	local corrected_y = next_y
	
	for brick in all(bricks) do
		if brick.active then
			local brick_collision = ball:check_box_collision(next_x, next_y, brick.x, brick.y, brick.width, brick.height)
			if brick_collision == "side" then
				if not hit_a_brick then 
					-- correct position before reversing direction
					if ball.dx > 0 then
						-- was moving right, hit left side of brick
						corrected_x = brick.x - ball.radius
					else
						-- was moving left, hit right side of brick  
						corrected_x = brick.x + brick.width + ball.radius
					end
					ball.dx = -ball.dx
					hit_a_brick = true
				end
				local destroyed = brick:hit()
				handle_brick_hit(brick, ball, destroyed)
			elseif brick_collision == "top" then
				if not hit_a_brick then 
					-- correct position before reversing direction
					if ball.dy > 0 then
						-- was moving down, hit top of brick
						corrected_y = brick.y - ball.radius
					else
						-- was moving up, hit bottom of brick
						corrected_y = brick.y + brick.height + ball.radius
					end
					ball.dy = -ball.dy
					hit_a_brick = true
				end
				local destroyed = brick:hit()
				handle_brick_hit(brick, ball, destroyed)
			end
		end
	end
	
	-- return corrected position if any collision occurred
	if hit_a_brick then
		return corrected_x, corrected_y
	else
		return nil, nil -- no collision, use normal movement
	end
end

ball = {}
function ball:new()
	local obj = {
		x = 64,
		y = 40,
		radius = 2,
		dx = 0, -- start stationary
		dy = 0, -- start stationary
		is_stuck_to_paddle = true, -- start attached to paddle
		speed_boost_timer = 0, -- timer for speed boost decay
		speed_boost_active = false, -- whether speed boost is currently active
		trail = particle_trail:new(12, 0.08) -- particle trail with 12 particles, slower fade for color transitions
	}
	setmetatable(obj, self)
	self.__index = self
	return obj
end

function min_all(...)
    local args = {...}
    local m = args[1]
    for i=2,#args do
        m = min(m, args[i])
    end
    return m
end

function ball:check_box_collision(next_x, next_y, box_x, box_y, box_w, box_h)
	-- Detect if there is any collision at all - if not, just return
	if next_x + self.radius < box_x then return "none" end
	if next_x - self.radius > box_x + box_w then return "none" end
	if next_y + self.radius < box_y then return "none" end
	if next_y - self.radius > box_y + box_h then return "none" end

	-- Calculate overlaps to determine collision direction
	-- RHS of ball / LHS of box
	local overlap_left = next_x + self.radius - box_x
	-- LHS of ball / RHS of box
	local overlap_right = box_x + box_w - (next_x - self.radius)
	-- Bottom of ball / top of box
	local overlap_top = next_y + self.radius - box_y
	-- Top of ball / bottom of box
	local overlap_bottom = box_y + box_h - (next_y - self.radius)

	-- Find minimum overlaps for horizontal and vertical
	local min_horizontal = min(overlap_left, overlap_right)
	local min_vertical = min(overlap_top, overlap_bottom)
	
	-- Consider ball's trajectory direction for better corner collision detection
	-- If overlaps are similar (corner collision), use velocity to determine surface
	local overlap_diff = abs(min_horizontal - min_vertical)
	local corner_threshold = 1.0 -- pixels - consider it a corner if overlaps are close
	
	if overlap_diff <= corner_threshold then
		-- Corner collision - use ball velocity to determine which surface to prioritize
		-- For corner hits, prioritize the surface that would give the most "natural" bounce
		
		-- Determine which corner we hit based on ball position and movement
		local ball_center_x = next_x
		local ball_center_y = next_y
		local brick_center_x = box_x + box_w / 2
		local brick_center_y = box_y + box_h / 2
		
		-- Determine which quadrant of the brick the ball hit
		local hit_left_side = ball_center_x < brick_center_x
		local hit_top_side = ball_center_y < brick_center_y
		
		-- For corner collisions, choose surface based on ball trajectory
		-- If ball is moving more horizontally, prioritize vertical surfaces (top/bottom)
		-- If ball is moving more vertically, prioritize horizontal surfaces (left/right)
		local abs_dx = abs(self.dx)
		local abs_dy = abs(self.dy)
		
		if abs_dx > abs_dy then
			-- Ball moving more horizontally - hit vertical surface (top/bottom)
			return "top"
		else
			-- Ball moving more vertically - hit horizontal surface (left/right)  
			return "side"
		end
	end
	
	-- Fallback to original logic: use minimum overlap
	if min_horizontal < min_vertical then
		return "side"
	else
		return "top"
	end
end

function ball:check_paddle_collision(next_x, next_y)
	return self:check_box_collision(next_x, next_y, player_paddle.x, player_paddle.y, player_paddle.width, player_paddle.height)
end

function ball:handle_stuck_ball_behavior()
	-- return immediately if ball is not stuck to paddle
	if not self.is_stuck_to_paddle then
		return false
	end
	
	-- position stuck balls across the paddle width
	local stuck_balls = {}
	for ball_obj in all(balls) do
		if ball_obj.is_stuck_to_paddle then
			add(stuck_balls, ball_obj)
		end
	end
	
	-- distribute stuck balls across paddle width
	local ball_index = 0
	for i, ball_obj in pairs(stuck_balls) do
		if ball_obj == self then
			ball_index = i
			break
		end
	end
	
	local spacing = player_paddle.width / (#stuck_balls + 1)
	self.x = player_paddle.x + spacing * ball_index
	self.y = player_paddle.y - self.radius
	
	-- check for launch - only launch one ball per button press
	if btnp(4) or btnp(5) then -- Z or X button
		-- find first stuck ball and launch it
		for ball_obj in all(balls) do
			if ball_obj.is_stuck_to_paddle then
				ball_obj.is_stuck_to_paddle = false
				player_combo = 0
	combo_milestones_reached = {} -- reset combo milestones -- reset combo when ball launches
			combo_milestones_reached = {} -- reset combo milestones
				local speed = default_ball_speed
				if btnp(4) then -- Z button - launch left
					ball_obj.dx = -speed * 0.707
					ball_obj.dy = -speed * 0.707
				else -- X button - launch right
					ball_obj.dx = speed * 0.707
					ball_obj.dy = -speed * 0.707
				end
				break -- only launch one ball
			end
		end
	end
	
	return true -- ball was stuck and handled
end

function ball:update()
	-- handle sticky state
	if self:handle_stuck_ball_behavior() then
		return -- ball was stuck, skip normal physics
	end
	
	-- calculate next position
	local next_x = self.x + self.dx
	local next_y = self.y + self.dy
	
	-- check wall collisions
	if next_x - self.radius <= 0 or next_x + self.radius >= 128 then
		self.dx = -self.dx
		sfx(3)
	end
	
	-- bounce off top bar (7 pixels tall)
	if next_y - self.radius <= 7 then
		self.dy = -self.dy
		sfx(3)
	end
	
	-- check shield collision - only if ball has passed paddle level and is moving down
	if player_shield and player_shield.active and self.dy > 0 and next_y + self.radius >= player_shield.y and self.y < player_shield.y then
		-- ball hit shield from above, bounce back up and destroy shield
		self.dy = -abs(self.dy)
		self.y = player_shield.y - self.radius - 1 -- position ball above shield to prevent sticking
		player_shield.active = false
		player_shield = nil
		sfx(0) -- play bounce sound
		return -- don't continue to bottom check
	end
	
	-- check if ball hits bottom - just mark position, life loss handled in main game loop
	if next_y + self.radius >= 128 then
		self.y = 128 + self.radius -- move ball off screen to mark as lost
		return -- don't continue processing this ball
	end
	
	-- check paddle collision (only when not sticky)
	if not self.is_stuck_to_paddle then
		local collision = self:check_paddle_collision(next_x, next_y)
		if collision == "side" or collision == "top" then
			-- check if paddle is sticky
			if player_paddle.is_sticky then
				-- stick ball to paddle
				self.is_stuck_to_paddle = true
				self.dx = 0
				self.dy = 0
			else
				-- arkanoid-style zone-based bouncing
				self:bounce_off_paddle_zone()
			end
			player_paddle:flash()
			player_score += 1
			player_combo = 0
	combo_milestones_reached = {} -- reset combo milestones -- reset combo when ball hits paddle
		combo_milestones_reached = {} -- reset combo milestones
			
			-- track paddle hits when only one brick remains
			if count_breakable_bricks() == 1 then
				single_brick_paddle_hits += 1
				
				-- drop multi-ball powerup after 4+ hits with one brick left
				if single_brick_paddle_hits >= 4 then
					-- spawn multi-ball powerup at paddle location
					local powerup_x = player_paddle.x + player_paddle.width / 2 - 4
					local powerup_y = player_paddle.y - 10
					local multi_ball_powerup = multi_ball_powerup:new(powerup_x, powerup_y)
					add(powerups, multi_ball_powerup)
					
					-- reset counter so we don't spam powerups
					single_brick_paddle_hits = 0
				end
				
				-- activate randomness after 6+ hits
				if single_brick_paddle_hits >= 6 then
					single_brick_randomness_active = true
				end
			end
			
			sfx(0)
		end
	end
	
	-- use swept collision detection to prevent tunneling
	self:move_with_collision_sweep()
	
	-- handle speed boost decay
	self:update_speed_boost()
	
	-- update particle trail
	if not self.is_stuck_to_paddle then
		-- add trail particles when ball is moving
		local speed = sqrt(self.dx * self.dx + self.dy * self.dy)
		if speed > 0.3 then -- create trail when moving (lower threshold)
			-- determine trail color based on speed
			local trail_color = 10 -- default yellow
			if self.speed_boost_active then
				trail_color = 9 -- orange for speed boost
			end
			
			-- add main particle at ball center
			self.trail:add_particle(self.x, self.y, trail_color)
			
			-- add additional particles with slight randomness for fuller trail
			if speed > 1.0 then -- only add extra particles when moving fast
				local offset_x = rnd(2) - 1 -- -1 to 1 pixel offset
				local offset_y = rnd(2) - 1
				self.trail:add_particle(self.x + offset_x, self.y + offset_y, trail_color)
			end
		end
	end
	self.trail:update()
end

function ball:move_with_collision_sweep()
	-- calculate total movement distance
	local total_distance = sqrt(self.dx * self.dx + self.dy * self.dy)
	
	-- if moving very slowly, use simple movement
	if total_distance < 0.5 then
		local corrected_x, corrected_y = check_brick_collisions(self, self.x + self.dx, self.y + self.dy)
		if corrected_x and corrected_y then
			self.x = corrected_x
			self.y = corrected_y
		else
			self.x += self.dx
			self.y += self.dy
		end
		return
	end
	
	-- for faster movement, step through the path
	local steps = ceil(total_distance)
	local step_dx = self.dx / steps
	local step_dy = self.dy / steps
	
	-- move step by step, checking for collisions
	for i = 1, steps do
		local next_x = self.x + step_dx
		local next_y = self.y + step_dy
		
		-- check for collision at this step
		local corrected_x, corrected_y = check_brick_collisions(self, next_x, next_y)
		
		if corrected_x and corrected_y then
			-- collision occurred - stop here with corrected position
			self.x = corrected_x
			self.y = corrected_y
			return
		else
			-- no collision - continue moving
			self.x = next_x
			self.y = next_y
		end
	end -- close for loop
end -- close function

function ball:update_speed_boost()
	-- handle speed boost decay
	if self.speed_boost_active then
		self.speed_boost_timer -= 1
		if self.speed_boost_timer <= 0 then
			-- speed boost expired, stop decay
			self.speed_boost_active = false
		else
			-- gradually reduce speed back to default
			local current_speed = sqrt(self.dx * self.dx + self.dy * self.dy)
			if current_speed > default_ball_speed then
				-- apply friction to reduce speed
				local friction = 0.99 -- friction coefficient
				self.dx *= friction
				self.dy *= friction
				
				-- check if we've reached default speed
				local new_speed = sqrt(self.dx * self.dx + self.dy * self.dy)
				if new_speed <= default_ball_speed then
					-- clamp to default speed
					local scale = default_ball_speed / new_speed
					self.dx *= scale
					self.dy *= scale
					self.speed_boost_active = false
				end
			end
		end
	end
end

function ball:draw()
	-- draw particle trail behind the ball
	self.trail:draw()
	
	-- draw the ball itself
	circfill(self.x, self.y, self.radius, 10)
	
	-- draw launch indicators when sticky
	if self.is_stuck_to_paddle then
		self:draw_launch_indicators()
	end
end

function ball:bounce_off_paddle_zone()
	-- calculate current ball speed to maintain it
	local current_speed = sqrt(self.dx * self.dx + self.dy * self.dy)
	
	-- find where ball hit paddle (center of ball relative to paddle)
	local ball_center_x = self.x
	local paddle_left = player_paddle.x
	local paddle_width = player_paddle.width
	
	-- calculate relative position on paddle (0 to 1)
	local relative_pos = (ball_center_x - paddle_left) / paddle_width
	
	-- clamp to paddle bounds
	relative_pos = max(0, min(1, relative_pos))
	
	local bounce_angle_degrees

	local middle_zone = false
	
	-- determine zone and bounce angle (7 zones: A, B, C, D, E, F, G)
	-- each zone is ~14.3% of paddle width (1/7 ≈ 0.143)
	if relative_pos <= 0.143 then
		-- zone A (leftmost ~14.3%)
		bounce_angle_degrees = 150
	elseif relative_pos <= 0.286 then
		-- zone B (~14.3% to 28.6%)
		bounce_angle_degrees = 135
	elseif relative_pos <= 0.429 then
		-- zone C (~28.6% to 42.9%)
		bounce_angle_degrees = 120
	elseif relative_pos <= 0.571 then
		-- zone D (middle ~42.9% to 57.1%)
		middle_zone = true
	elseif relative_pos <= 0.714 then
		-- zone E (~57.1% to 71.4%)
		bounce_angle_degrees = 60
	elseif relative_pos <= 0.857 then
		-- zone F (~71.4% to 85.7%)
		bounce_angle_degrees = 45
	else
		-- zone G (rightmost ~85.7% to 100%)
		bounce_angle_degrees = 30
	end

	if middle_zone then
		-- middle zone (D): bounce straight up
		self.dy = -self.dy
		
		-- add slight randomness if single brick randomness is active
		if single_brick_randomness_active then
			local random_dx = (rnd(0.4) - 0.2) -- -0.2 to 0.2 random horizontal component
			self.dx += random_dx
		end
	else
		-- convert angle to radians (pico-8 uses different angle system)
		-- in pico-8: 0 = right, 0.25 = up, 0.5 = left, 0.75 = down
		-- convert degrees to pico-8 angle units
		local angle_pico8 = bounce_angle_degrees / 360
		
		-- add slight randomness to angle if single brick randomness is active
		if single_brick_randomness_active then
			local random_angle_offset = (rnd(8) - 4) -- -4 to 4 degree variation
			bounce_angle_degrees += random_angle_offset
			angle_pico8 = bounce_angle_degrees / 360
		end
		
		-- calculate new velocity components maintaining speed
		self.dx = current_speed * cos(angle_pico8)
		self.dy = current_speed * sin(angle_pico8)
	end
	
end

function ball:draw_launch_indicators()
	-- update launch indicator animation timer (slower)
	launch_indicator_timer += 1
	
	local line_length = 15
	local speed = default_ball_speed
	local num_particles = 8 -- more particles for better spacing control
	
	-- left launch indicator (Z button)
	local left_dx = -speed * 0.707
	local left_dy = -speed * 0.707
	local left_end_x = self.x + left_dx * line_length / 2
	local left_end_y = self.y + left_dy * line_length / 2
	
	-- draw animated particle stream for left direction
	for i = 1, num_particles do
		-- calculate particle position along trajectory with slower animation
		local progress = (i - 1) / (num_particles - 1) -- 0 to 1
		local anim_offset = (launch_indicator_timer * 0.05 + i * 0.15) % 1 -- slower flowing animation
		local total_progress = (progress + anim_offset) % 1
		
		-- create gaps in the stream - only draw some particles
		local gap_pattern = (i + flr(launch_indicator_timer * 0.05)) % 3 -- creates moving gaps
		if gap_pattern != 0 then -- skip every 3rd particle position for gaps
			local particle_x = self.x + left_dx * line_length / 2 * total_progress
			local particle_y = self.y + left_dy * line_length / 2 * total_progress
			
			-- use colors 8 (red) and 9 (orange) for shading
			local color = (i % 2 == 0) and 8 or 9 -- alternate between red and orange
			pset(particle_x, particle_y, color)
			
			-- add some particle spread for thickness (reduced probability)
			if rnd(1) < 0.4 then
				pset(particle_x + 1, particle_y, color)
			end
			if rnd(1) < 0.3 then
				pset(particle_x, particle_y + 1, color)
			end
		end
	end
	
	-- draw Z button label
	print("z", left_end_x - 2, left_end_y - 3, 6)
	
	-- right launch indicator (X button)
	local right_dx = speed * 0.707
	local right_dy = -speed * 0.707
	local right_end_x = self.x + right_dx * line_length / 2
	local right_end_y = self.y + right_dy * line_length / 2
	
	-- draw animated particle stream for right direction
	for i = 1, num_particles do
		-- calculate particle position along trajectory with slower animation
		local progress = (i - 1) / (num_particles - 1) -- 0 to 1
		local anim_offset = (launch_indicator_timer * 0.05 + i * 0.15) % 1 -- slower flowing animation
		local total_progress = (progress + anim_offset) % 1
		
		-- create gaps in the stream - only draw some particles
		local gap_pattern = (i + flr(launch_indicator_timer * 0.05)) % 3 -- creates moving gaps
		if gap_pattern != 0 then -- skip every 3rd particle position for gaps
			local particle_x = self.x + right_dx * line_length / 2 * total_progress
			local particle_y = self.y + right_dy * line_length / 2 * total_progress
			
			-- use colors 8 (red) and 9 (orange) for shading
			local color = (i % 2 == 0) and 8 or 9 -- alternate between red and orange
			pset(particle_x, particle_y, color)
			
			-- add some particle spread for thickness (reduced probability)
			if rnd(1) < 0.4 then
				pset(particle_x + 1, particle_y, color)
			end
			if rnd(1) < 0.3 then
				pset(particle_x, particle_y + 1, color)
			end
		end
	end
	
	-- draw X button label
	print("x", right_end_x - 2, right_end_y - 3, 6)
end


function _init()
	player_paddle = paddle:new()
	balls = {ball:new()} -- initialize with first ball
	player_lives = 5
	player_score = 0
	player_combo = 0
	combo_milestones_reached = {} -- reset combo milestones
	combo_milestones_reached = {} -- initialize combo milestone tracking
	player_shield = nil -- clear shield
	floating_texts = {} -- initialize floating score texts
	-- initialize screen shaker
	screen_shaker = shaker:new()
	-- initialize title screen animation
	title_frame_counter = 0
	title_fast_blink_timer = 0
	title_is_fast_blinking = false
	-- create shuffled level order (levels 2-15, level 1 stays first)
	create_shuffled_levels()
	-- initialize bricks
	init_bricks()
	-- initialize single brick challenge tracking
	single_brick_paddle_hits = 0
	single_brick_randomness_active = false
end

function create_shuffled_levels()
	-- create array of level indices 2 through total levels
	shuffled_levels = {}
	for i = 2, #levels do
		add(shuffled_levels, i)
	end
	
	-- shuffle the array using fisher-yates algorithm
	for i = #shuffled_levels, 2, -1 do
		local j = flr(rnd(i)) + 1
		local temp = shuffled_levels[i]
		shuffled_levels[i] = shuffled_levels[j]
		shuffled_levels[j] = temp
	end
end

function init_bricks()
	bricks = {}
	load_level(current_level)
end

function load_level(level_num)
	bricks = {}
	if level_num > #levels then
		return -- no more levels
	end
	
	-- determine actual level index to use
	local actual_level_index
	if level_num == 1 then
		actual_level_index = 1 -- always use level 1 first
	else
		-- use shuffled order for levels after 1
		local shuffled_index = level_num - 1 -- convert to shuffled array index
		if shuffled_index > #shuffled_levels then
			return -- no more shuffled levels
		end
		actual_level_index = shuffled_levels[shuffled_index]
	end
	
	local level_data = levels[actual_level_index]
	for row = 1, #level_data do
		local row_string = level_data[row]
		local max_cols = min(10, #row_string) -- limit to 10 bricks per row
		for col = 1, max_cols do
			local char = sub(row_string, col, col)
			if char != "." then -- not empty space
				local brick_x = (col - 1) * 12 + 4 -- 12 pixels spacing (10 width + 2 gap), start at x=4
				local brick_y = 15 + (row - 1) * 6 -- start at y=15, 6 pixels spacing (4 height + 2 gap)
				
				local new_brick
				if char == "U" then
					new_brick = unbreakable_brick:new(brick_x, brick_y)
				elseif char >= "2" and char <= "9" then
					new_brick = multi_hit_brick:new(brick_x, brick_y, tonum(char))
				elseif char == "S" then
					new_brick = speed_brick:new(brick_x, brick_y)
				elseif char == "M" then
					new_brick = moving_brick:new(brick_x, brick_y)
				elseif char == "P" then
					new_brick = powerup_brick:new(brick_x, brick_y)
				else -- "N" or any other character defaults to normal
					new_brick = normal_brick:new(brick_x, brick_y)
				end
				
				add(bricks, new_brick)
			end
		end
	end
end

function count_breakable_bricks()
	local count = 0
	for brick in all(bricks) do
		if brick.active and brick.breakable then
			count += 1
		end
	end
	return count
end

function _update60()
	if game_state == "start" then
		update_start()
	elseif game_state == "game" then
		update_game()
	elseif game_state == "level_clear" then
		update_level_clear()
	elseif game_state == "victory" then
		update_victory()
	elseif game_state == "game_over" then
		update_game_over()
	end
end

function _draw()
	-- apply screen shake before drawing anything
	screen_shaker:shake_screen()
	
	if game_state == "start" then
		draw_start()
	elseif game_state == "game" then
		draw_game()
	elseif game_state == "level_clear" then
		draw_level_clear()
	elseif game_state == "victory" then
		draw_victory()
	elseif game_state == "game_over" then
		draw_game_over()
	end
	
	-- fade the screen
	pal()
	if fadeperc != 0 then
		fadepal(fadeperc)
	end
end

-- start screen functions --
function update_start()
	-- update animation frame counter
	title_frame_counter += 1
	
	-- handle fast blinking timer
	if title_is_fast_blinking then
		title_fast_blink_timer -= 1
		if title_fast_blink_timer <= 0 then
			title_is_fast_blinking = false
		end
	end
	
	if btnp(0) or btnp(1) or btnp(2) or btnp(3) or btnp(4) or btnp(5) then
		-- start fast blinking effect
		title_is_fast_blinking = true
		title_fast_blink_timer = 60 -- blink fast for 1 second (60 frames)
		
		-- play start game sound
		sfx(14)
		
		-- delay game start slightly to show the fast blink effect
		-- we'll change state after a short delay instead of immediately
		if title_fast_blink_timer == 60 then
			-- just started fast blinking, don't start game yet
			return
		end
	end
	
	-- start fade after fast blink effect is mostly done
	if title_is_fast_blinking and title_fast_blink_timer <= 45 then
		-- start fade to black
		fadeperc += 0.025  -- fade speed (2x slower)
		
		-- once fully faded, start the game
		if fadeperc >= 1.0 then
			game_state = "game"
			-- reset game objects
			player_paddle = paddle:new()
			balls = {ball:new()} -- reset to single ball
			player_lives = 5
			player_score = 0
			player_combo = 0
	combo_milestones_reached = {} -- reset combo milestones
			current_level = 1
			player_shield = nil -- clear shield
			-- create new shuffled level order
			create_shuffled_levels()
			-- reset bricks and powerups
			init_bricks()
			powerups = {}
			
			-- reset title screen variables and fade
			title_frame_counter = 0
			title_fast_blink_timer = 0
			title_is_fast_blinking = false
			fadeperc = 0  -- reset fade for game
		end
	end
end

function draw_start()
	cls()
	
	-- title box and text positioning
	local title_text = "MEOW SMASH!"
	local title_x = 35
	local title_y = 50
	local box_padding = 4
	local box_x1 = title_x - box_padding
	local box_y1 = title_y - box_padding
	local box_x2 = title_x + #title_text * 4 + box_padding - 1  -- 4 pixels per character
	local box_y2 = title_y + 6 + box_padding  -- text height is about 6 pixels
	
	-- title is always white with white box
	local title_color = 7  -- white
	rect(box_x1, box_y1, box_x2, box_y2, title_color)
	print(title_text, title_x, title_y, title_color)
	
	-- determine instruction text color based on animation state
	local instruction_color = 6  -- default light grey
	
	if title_is_fast_blinking then
		-- very fast blinking: every 2 frames (faster than before)
		if title_fast_blink_timer % 4 < 2 then
			instruction_color = 6  -- light grey
		else
			instruction_color = 0  -- black (invisible)
		end
	else
		-- faster pulsing through color cycle: white -> grey -> dark -> light green -> back
		-- cycle every 80 frames (faster than before - about 1.3 seconds at 60fps)
		local cycle_position = (title_frame_counter % 80) / 80
		
		if cycle_position < 0.25 then
			-- white
			instruction_color = 7  -- white
		elseif cycle_position < 0.5 then
			-- light grey
			instruction_color = 6  -- light grey
		elseif cycle_position < 0.75 then
			-- dark grey
			instruction_color = 5  -- dark grey
		else
			-- light green
			instruction_color = 11  -- light green
		end
	end
	
	-- draw instruction text (only if visible)
	if instruction_color != 0 then
		print("Press any key to play", 20, 70, instruction_color)
	end
end

-- game functions --
function update_game()
	player_paddle:update()
	
	-- update all balls
	for ball_obj in all(balls) do
		ball_obj:update()
	end
	
	-- remove inactive balls (those that hit bottom)
	for i = #balls, 1, -1 do
		if balls[i].y >= 128 then
			del(balls, balls[i])
		end
	end
	
	-- check if all balls are lost
	if #balls == 0 then
		player_lives -= 1
		player_combo = 0
	combo_milestones_reached = {} -- reset combo milestones
		-- reset single brick challenge tracking when losing life
		single_brick_paddle_hits = 0
		single_brick_randomness_active = false
		sfx(1) -- play life lost sound
		screen_shaker:small_shake() -- shake screen when losing life
		if player_lives <= 0 then
			game_state = "game_over"
			screen_shaker:large_shake() -- big shake for game over
			-- initialize game over sequence
			game_over_shake_timer = 120 -- 2 seconds of shake/delay before showing text
			game_over_text_visible = false
			game_over_blink_timer = 0
			game_over_fade_started = false
		else
			-- reset to single sticky ball
			balls = {ball:new()}
			player_shield = nil -- clear shield when losing life
		end
	end
	
	-- update bricks (for moving bricks)
	for brick in all(bricks) do
		if brick.active and brick.update then
			brick:update()
		end
	end
	
	-- update powerups
	for powerup in all(powerups) do
		powerup:update()
	end
	
	-- update shield particles
	update_shield()
	
	-- update floating score texts
	update_floating_texts()
	
	-- remove inactive powerups
	for i = #powerups, 1, -1 do
		if not powerups[i].active then
			del(powerups, powerups[i])
		end
	end
	
	-- check if level is complete
	if count_breakable_bricks() == 0 then
		current_level += 1
		-- reset single brick challenge tracking for next level
		single_brick_paddle_hits = 0
		single_brick_randomness_active = false
		if current_level > #levels then
			game_state = "victory"
		else
			game_state = "level_clear"
		end
	end
end

function draw_game()
	cls()
	rectfill(0, 0, 127, 127, 1)
	-- draw black bar at top for lives display
	rectfill(0, 0, 127, 6, 0)
	-- draw shield if active (drawn before paddle so paddle appears on top)
	draw_shield()
	player_paddle:draw()
	-- draw all balls
	for ball_obj in all(balls) do
		ball_obj:draw()
	end
	-- draw bricks
	for brick in all(bricks) do
		brick:draw()
	end
	-- draw powerups
	for powerup in all(powerups) do
		powerup:draw()
	end
	-- draw floating score texts (drawn on top of everything else)
	draw_floating_texts()
	-- display lives and score in the black bar
	print("lives: "..player_lives, 2, 1, 7)
	print("score: "..player_score, 70, 1, 7)
	print("combo: "..player_combo, 2, 122, 7)
	print("level: "..current_level, 65, 122, 7)
end

-- game over functions --
function update_game_over()
	-- handle shake timer countdown
	if game_over_shake_timer > 0 then
		game_over_shake_timer -= 1
		if game_over_shake_timer <= 0 then
			-- shake period over, show game over text
			game_over_text_visible = true
		end
		return -- don't process button input during shake
	end
	
	-- update blink timer for game over text
	if game_over_text_visible then
		game_over_blink_timer += 1
	end
	
	-- handle fade sequence
	if game_over_fade_started then
		fadeperc += 0.025 -- same fade speed as title screen
		if fadeperc >= 1.0 then
			-- fade complete, go to start screen
			game_state = "start"
			-- reset all game over variables
			game_over_shake_timer = 0
			game_over_text_visible = false
			game_over_blink_timer = 0
			game_over_fade_started = false
			fadeperc = 0
		end
		return -- don't process button input during fade
	end
	
	-- handle button press (only when text is visible and not fading)
	if game_over_text_visible and btnp(0) or btnp(1) or btnp(2) or btnp(3) or btnp(4) or btnp(5) then
		-- start fade sequence
		game_over_fade_started = true
		sfx(14) -- play same sound as title screen
	end
end

function draw_game_over()
	-- during shake timer, just draw the game normally (keep last game image)
	if game_over_shake_timer > 0 then
		-- draw the normal game screen to show shake effect
		draw_game()
		return
	end
	
	-- only show game over text after shake is done
	if not game_over_text_visible then
		return
	end
	
	-- don't clear screen - keep last game image
	-- draw black rectangle for game over text
	rectfill(10, 40, 117, 80, 0)
	rect(10, 40, 117, 80, 7) -- white border
	print("GAME OVER!", 40, 50, 8)
	
	-- blinking "press any key" text (similar to title screen)
	local instruction_color = 6 -- default light grey
	
	-- faster pulsing through color cycle like title screen
	-- cycle every 80 frames (about 1.3 seconds at 60fps)
	local cycle_position = (game_over_blink_timer % 80) / 80
	
	if cycle_position < 0.25 then
		instruction_color = 7  -- white
	elseif cycle_position < 0.5 then
		instruction_color = 6  -- light grey
	elseif cycle_position < 0.75 then
		instruction_color = 5  -- dark grey
	else
		instruction_color = 11  -- light green
	end
	
	print("Press any key to continue", 15, 65, instruction_color)
end

-- level clear functions --
function update_level_clear()
	-- handle fade sequence
	if level_clear_fade_started then
		fadeperc += 0.025 -- same fade speed as other screens
		if fadeperc >= 1.0 then
			-- fade complete, load next level and start game
			sfx(0)
			-- reset ball and paddle for next level
			balls = {ball:new()} -- reset to single ball
			player_paddle = paddle:new()
			player_combo = 0
	combo_milestones_reached = {} -- reset combo milestones
			powerups = {} -- clear any remaining powerups
			player_shield = nil -- clear shield for next level
			load_level(current_level)
			game_state = "game"
			-- reset level clear variables
			level_clear_fade_started = false
			fadeperc = 0
		end
		return -- don't process button input during fade
	end
	
	-- handle button press to start fade
	if btnp(0) or btnp(1) or btnp(2) or btnp(3) or btnp(4) or btnp(5) then
		-- start fade sequence
		level_clear_fade_started = true
		sfx(14) -- play same sound as other transitions
	end
end

function draw_level_clear()
	-- don't clear screen - keep last game image
	-- draw black rectangle for level clear text
	-- render the current game state first to show final brick destruction
	draw_game()
	rectfill(10, 40, 117, 80, 0)
	rect(10, 40, 117, 80, 7) -- white border
	print("LEVEL "..tostr(current_level-1).." CLEAR!", 25, 50, 11)
	print("Press any key for next level", 15, 65, 6)
end

-- victory functions --
function update_victory()
	-- handle fade sequence
	if victory_fade_started then
		fadeperc += 0.025 -- same fade speed as other screens
		if fadeperc >= 1.0 then
			-- fade complete, go to start screen
			game_state = "start"
			-- reset victory variables
			victory_fade_started = false
			fadeperc = 0
		end
		return -- don't process button input during fade
	end
	
	-- handle button press to start fade
	if btnp(0) or btnp(1) or btnp(2) or btnp(3) or btnp(4) or btnp(5) then
		-- start fade sequence
		victory_fade_started = true
		sfx(14) -- play same sound as other transitions
	end
end

function draw_victory()
	-- don't clear screen - keep last game image
	-- draw black rectangle for victory text
	rectfill(10, 30, 117, 90, 0)
	rect(10, 30, 117, 90, 7) -- white border
	print("CONGRATULATIONS!", 25, 40, 10)
	print("You beat all levels!", 20, 55, 11)
	print("Final Score: "..player_score, 25, 70, 7)
	print("Press any key to continue", 15, 80, 6)
end
