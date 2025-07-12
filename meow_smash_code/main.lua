--===============================================
--  __  __ _____ _____ _    _   _____ __  __           _____ _    _ 
-- |  \/  |  ___|  _  | |  | | /  ___/  \/  |   /\    /  ___| |  | |
-- | |\/| | |__ | | | | |  | | \ `--.|      |  /  \   \ `--| |__| |
-- | |  | |  __|| | | | |/\| |  `--. | |\/| | / /\ \   `--. |  __  |
-- | |  | | |___\ \_/ \  /\  / /\__/ | |  | |/ ____ \/\__/ | |  | |
-- |_|  |_\____/ \___/ \/  \/ \____/|_|  |_/_/    \_\____/|_|  |_|
--===============================================

--===============================
-- ██      ███████ ██    ██ ███████ ██      ███████ 
-- ██      ██      ██    ██ ██      ██      ██      
-- ██      █████   ██    ██ █████   ██      ███████ 
-- ██      ██       ██  ██  ██      ██           ██ 
-- ███████ ███████   ████   ███████ ███████ ███████ 
--===============================

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
	-- level 1: simple pattern
	{
		"...N..N...",
		"...P..P...",
		"...P.PP...",
		"....NP...."
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
		"S.N.S.N.S.",
		".3.2.3.2.3",
		"N.S.N.P.N."
	},
	-- level 4: moving bricks test
	{
		"UUUUUUUUUU",
		"M.P.M.M.M.",
		".M.M.M.M.M",
		"M.M.P.M.M.",
		"UUUUUUUUUU"
	},
	-- level 5: powerup bricks test
	{
		"NNNNNNNNNN",
		"N.P.N.P.N.",
		"NNNNNNNNNN",
		"P.N.P.N.P.",
		"NNNNNNNNNN"
	}
}

current_level = 1

--========================================
-- ██████   █████  ██████  ██████  ██      ███████ 
-- ██   ██ ██   ██ ██   ██ ██   ██ ██      ██      
-- ██████  ███████ ██   ██ ██   ██ ██      █████   
-- ██      ██   ██ ██   ██ ██   ██ ██      ██      
-- ██      ██   ██ ██████  ██████  ███████ ███████ 
--========================================
paddle = {}
function paddle:new()
	local obj = {
		x = 52,
		y = 120,
		width = 24,
		height = 3,
		base_width = 24, -- original width for powerup calculations
		max_speed = 2.5, -- max speed - you hit then when the button is pressed
		dx = 0, -- current speed
		friction = 1.2, -- factor by which to reduce speed every frame after button is released
		flash_timer = 0, -- timer for red flash effect
		last_direction = 0, -- track last movement direction for ball launch
		size_timer = 0, -- timer for temporary size effects
		size_multiplier = 1.0, -- current size multiplier
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
			self:reset_size()
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
	elseif self.size_multiplier > 1.0 then
		color = 14 -- pink when expanded
	end
	rectfill(self.x, self.y, self.x + self.width - 1, self.y + self.height - 1, color)
end

function paddle:flash()
	self.flash_timer = 5
end

function paddle:set_temporary_size(multiplier, duration)
	-- set temporary size multiplier and duration
	self.size_multiplier = multiplier
	self.size_timer = duration
	
	-- update width immediately, keeping paddle centered
	local old_width = self.width
	self.width = self.base_width * multiplier
	
	-- adjust x position to keep paddle centered
	self.x = self.x + (old_width - self.width) / 2
	
	-- ensure paddle stays on screen
	if self.x < 0 then
		self.x = 0
	elseif self.x + self.width > 128 then
		self.x = 128 - self.width
	end
end

function paddle:reset_size()
	-- reset to normal size, keeping paddle centered
	local old_width = self.width
	self.size_multiplier = 1.0
	self.width = self.base_width
	
	-- adjust x position to keep paddle centered
	self.x = self.x + (old_width - self.width) / 2
	
	-- ensure paddle stays on screen
	if self.x < 0 then
		self.x = 0
	elseif self.x + self.width > 128 then
		self.x = 128 - self.width
	end
end

--======================================
-- ██████  ██████  ██  ██████ ██   ██ ███████ 
-- ██   ██ ██   ██ ██ ██      ██  ██  ██      
-- ██████  ██████  ██ ██      █████   ███████ 
-- ██   ██ ██   ██ ██ ██      ██  ██       ██ 
-- ██████  ██   ██ ██  ██████ ██   ██ ███████ 
--======================================
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

--=======================================
-- ██████   ██████  ██     ██ ███████ ██████  ██    ██ ██████  ███████ 
-- ██   ██ ██    ██ ██     ██ ██      ██   ██ ██    ██ ██   ██ ██      
-- ██████  ██    ██ ██  █  ██ █████   ██████  ██    ██ ██████  ███████ 
-- ██      ██    ██ ██ ███ ██ ██      ██   ██ ██    ██ ██      ██      
-- ██       ██████   ███ ███   ███████ ██   ██  ██████  ██      ███████ 
--=======================================

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
		sprite_id = 0
	}
	setmetatable(obj, self)
	self.__index = self
	return obj
end

function powerup:update()
	if not self.active then return end
	
	-- fall down
	self.y += self.dy
	
	-- check if hit paddle
	if self:check_paddle_collision() then
		self:collect()
		self.active = false
		sfx(4) -- play powerup collected sound
	end
	
	-- check if hit bottom of screen
	if self.y >= 128 then
		self.active = false
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
		spr(self.sprite_id, self.x, self.y)
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
	-- expand paddle by 50% for 10 seconds (600 frames at 60fps)
	player_paddle:set_temporary_size(1.5, 600)
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
	-- create a shield at bottom of paddle
	player_shield = {
		active = true,
		y = player_paddle.y + player_paddle.height, -- position shield at bottom of paddle
		color = 12
	}
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
		local speed = 2
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

--========================================================
--  ██████  ██████  ██      ██      ██ ███████ ██  ██████  ███    ██ 
-- ██      ██    ██ ██      ██      ██ ██      ██ ██    ██ ████   ██ 
-- ██      ██    ██ ██      ██      ██ ███████ ██ ██    ██ ██ ██  ██ 
-- ██      ██    ██ ██      ██      ██      ██ ██ ██    ██ ██  ██ ██ 
--  ██████  ██████  ███████ ███████ ██ ███████ ██  ██████  ██   ████ 
--========================================================
function handle_brick_hit(brick, ball, destroyed)
	if destroyed then
		local points = 10 * (player_combo * 10 + 1)
		player_score += points
		player_combo += 1 -- increase combo for each brick hit
		-- handle special brick effects
		local effect = brick:on_destroy()
		if effect == "speed" then
			-- speed brick: increase ball speed
			ball.dx = ball.dx * 1.2
			ball.dy = ball.dy * 1.2
		elseif brick.drops_powerup and effect then
			-- powerup brick: spawn powerup
			spawn_powerup(effect, brick.x + brick.width/2, brick.y + brick.height)
		end
	else
		local points = 5 * (player_combo * 10 + 1)
		player_score += points -- partial points for damaged brick
		player_combo += 1 -- increase combo even for damaged bricks
	end
	sfx(2)
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
	
	for brick in all(bricks) do
		if brick.active then
			local brick_collision = ball:check_box_collision(next_x, next_y, brick.x, brick.y, brick.width, brick.height)
			if brick_collision == "side" then
				if not hit_a_brick then 
					ball.dx = -ball.dx
					hit_a_brick = true
				end
				local destroyed = brick:hit()
				handle_brick_hit(brick, ball, destroyed)
			elseif brick_collision == "top" then
				if not hit_a_brick then 
					ball.dy = -ball.dy
					hit_a_brick = true
				end
				local destroyed = brick:hit()
				handle_brick_hit(brick, ball, destroyed)
			end
		end
	end
end

--=========================
-- ██████   █████  ██      ██      
-- ██   ██ ██   ██ ██      ██      
-- ██████  ███████ ██      ██      
-- ██   ██ ██   ██ ██      ██      
-- ██████  ██   ██ ███████ ███████ 
--=========================
ball = {}
function ball:new()
	local obj = {
		x = 64,
		y = 40,
		radius = 2,
		dx = 0, -- start stationary
		dy = 0, -- start stationary
		is_stuck_to_paddle = true, -- start attached to paddle
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

	min_overlap = min_all(overlap_left, overlap_right, overlap_top, overlap_bottom)
	if min_overlap == overlap_left or min_overlap == overlap_right then
		return "side"
	end
	return "top"
end

function ball:check_paddle_collision(next_x, next_y)
	return self:check_box_collision(next_x, next_y, player_paddle.x, player_paddle.y, player_paddle.width, player_paddle.height)
end

function ball:update()
	-- handle sticky state
	if self.is_stuck_to_paddle then
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
					player_combo = 0 -- reset combo when ball launches
					local speed = 2
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
		return -- don't do normal physics when sticky
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
	
	-- check shield collision - only if ball has passed paddle level
	if player_shield and player_shield.active and next_y + self.radius >= player_shield.y and next_y > player_paddle.y + player_paddle.height then
		-- ball hit shield after passing paddle, bounce back up and destroy shield
		self.dy = -abs(self.dy)
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
				-- normal bounce behavior
				if collision == "side" then
					self.dx = -self.dx
				elseif collision == "top" then
					self.dy = -abs(self.dy)
				end
				-- add paddle velocity influence with speed cap
				self:apply_paddle_velocity_with_cap()
			end
			player_paddle:flash()
			player_score += 1
			player_combo = 0 -- reset combo when ball hits paddle
			sfx(0)
		end
	end
	
	-- check brick collisions
	check_brick_collisions(self, next_x, next_y)
	
	-- move ball
	self.x += self.dx
	self.y += self.dy
end

function ball:draw()
	circfill(self.x, self.y, self.radius, 10)
	
	-- draw launch indicators when sticky
	if self.is_stuck_to_paddle then
		self:draw_launch_indicators()
	end
end

function ball:apply_paddle_velocity_with_cap()
	-- calculate current ball speed
	local current_speed = sqrt(self.dx * self.dx + self.dy * self.dy)
	
	-- calculate proposed new dx with paddle velocity
	local paddle_influence = player_paddle.dx * paddle_velocity_transfer
	local new_dx = self.dx + paddle_influence
	local new_dy = self.dy
	
	-- check dx:dy ratio limit
	local abs_dx = abs(new_dx)
	local abs_dy = abs(new_dy)
	
	if abs_dy > 0 and abs_dx / abs_dy > max_ball_dx_dy_ratio then
		-- ratio is too high, need to adjust while conserving total velocity
		-- we want: abs(dx) / abs(dy) = max_ratio
		-- and: dx^2 + dy^2 = current_speed^2
		
		local ratio = max_ball_dx_dy_ratio
		-- solve: (ratio * dy)^2 + dy^2 = speed^2
		-- dy^2 * (ratio^2 + 1) = speed^2
		-- dy^2 = speed^2 / (ratio^2 + 1)
		
		local new_dy_magnitude = current_speed / sqrt(ratio * ratio + 1)
		local new_dx_magnitude = new_dy_magnitude * ratio
		
		-- preserve original signs
		new_dx = new_dx >= 0 and new_dx_magnitude or -new_dx_magnitude
		new_dy = new_dy >= 0 and new_dy_magnitude or -new_dy_magnitude
	else
		-- ratio is fine, apply speed cap
		local new_speed_uncapped = sqrt(new_dx * new_dx + new_dy * new_dy)
		local max_speed = current_speed * (1 + ball_speed_increase_cap)
		
		if new_speed_uncapped > max_speed then
			-- scale down proportionally to maintain direction
			local scale_factor = max_speed / new_speed_uncapped
			new_dx = new_dx * scale_factor
			new_dy = new_dy * scale_factor
		end
	end
	
	self.dx = new_dx
	self.dy = new_dy
end

function ball:draw_launch_indicators()
	local line_length = 15
	local speed = 2
	
	-- left launch indicator (Z button)
	local left_dx = -speed * 0.707
	local left_dy = -speed * 0.707
	local left_end_x = self.x + left_dx * line_length / 2
	local left_end_y = self.y + left_dy * line_length / 2
	line(self.x, self.y, left_end_x, left_end_y, 6) -- cyan line
	print("z", left_end_x - 2, left_end_y - 3, 6)
	
	-- right launch indicator (X button)
	local right_dx = speed * 0.707
	local right_dy = -speed * 0.707
	local right_end_x = self.x + right_dx * line_length / 2
	local right_end_y = self.y + right_dy * line_length / 2
	line(self.x, self.y, right_end_x, right_end_y, 6) -- cyan line
	print("x", right_end_x - 2, right_end_y - 3, 6)
end

--=========================================================
--  ██████   █████  ███    ███ ███████     ███████ ████████  █████  ████████ ███████ 
-- ██       ██   ██ ████  ████ ██          ██         ██    ██   ██    ██    ██      
-- ██   ███ ███████ ██ ████ ██ █████       ███████    ██    ███████    ██    █████   
-- ██    ██ ██   ██ ██  ██  ██ ██               ██    ██    ██   ██    ██    ██      
--  ██████  ██   ██ ██      ██ ███████     ███████    ██    ██   ██    ██    ███████ 
--=========================================================
game_state = "start"
player_lives = 5
player_score = 0
player_combo = 0
paddle_velocity_transfer = 0.2 -- factor for transferring paddle velocity to ball
powerup_fall_speed = 0.5 -- speed at which powerups fall
ball_speed_increase_cap = 0.1 -- maximum ball speed increase from paddle velocity (10%)
max_ball_dx_dy_ratio = 3.0 -- maximum ratio of horizontal to vertical velocity (3:1)
bricks = {}
powerups = {}
balls = {} -- array to track multiple balls
player_shield = nil -- shield object (nil when inactive)

function _init()
	player_paddle = paddle:new()
	balls = {ball:new()} -- initialize with first ball
	player_lives = 5
	player_score = 0
	player_combo = 0
	player_shield = nil -- clear shield
	-- initialize bricks
	init_bricks()
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
	
	local level_data = levels[level_num]
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
end

-- start screen functions --
function update_start()
	if btnp(0) or btnp(1) or btnp(2) or btnp(3) or btnp(4) or btnp(5) then
		game_state = "game"
		-- reset game objects
		player_paddle = paddle:new()
		balls = {ball:new()} -- reset to single ball
		player_lives = 5
		player_score = 0
		player_combo = 0
		current_level = 1
		player_shield = nil -- clear shield
		-- reset bricks and powerups
		init_bricks()
		powerups = {}
	end
end

function draw_start()
	cls()
	print("MEOW SMASH!", 35, 50, 7)
	print("Press any key to play", 20, 70, 6)
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
		sfx(1) -- play life lost sound
		if player_lives <= 0 then
			game_state = "game_over"
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
	
	-- remove inactive powerups
	for i = #powerups, 1, -1 do
		if not powerups[i].active then
			del(powerups, powerups[i])
		end
	end
	
	-- check if level is complete
	if count_breakable_bricks() == 0 then
		current_level += 1
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
	if player_shield and player_shield.active then
		line(0, player_shield.y, 127, player_shield.y, player_shield.color)
		line(0, player_shield.y + 1, 127, player_shield.y + 1, player_shield.color)
	end
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
	-- display lives and score in the black bar
	print("lives: "..player_lives, 2, 1, 7)
	print("score: "..player_score, 70, 1, 7)
	print("combo: "..player_combo, 2, 122, 7)
	print("level: "..current_level, 65, 122, 7)
end

-- game over functions --
function update_game_over()
	if btnp(0) or btnp(1) or btnp(2) or btnp(3) or btnp(4) or btnp(5) then
		game_state = "start"
	end
end

function draw_game_over()
	-- don't clear screen - keep last game image
	-- draw black rectangle for game over text
	rectfill(10, 40, 117, 80, 0)
	rect(10, 40, 117, 80, 7) -- white border
	print("GAME OVER!", 40, 50, 8)
	print("Press any key to continue", 15, 65, 6)
end

-- level clear functions --
function update_level_clear()
	if btnp(0) or btnp(1) or btnp(2) or btnp(3) or btnp(4) or btnp(5) then
		sfx(0)
		-- reset ball and paddle for next level
		balls = {ball:new()} -- reset to single ball
		player_paddle = paddle:new()
		player_combo = 0
		powerups = {} -- clear any remaining powerups
		player_shield = nil -- clear shield for next level
		load_level(current_level)
		game_state = "game"
	end
end

function draw_level_clear()
	-- don't clear screen - keep last game image
	-- draw black rectangle for level clear text
	-- draw the screen one more time so that we can clear the last brick
	draw_game()
	rectfill(10, 40, 117, 80, 0)
	rect(10, 40, 117, 80, 7) -- white border
	print("LEVEL "..tostr(current_level-1).." CLEAR!", 25, 50, 11)
	print("Press any key for next level", 15, 65, 6)
end

-- victory functions --
function update_victory()
	if btnp(0) or btnp(1) or btnp(2) or btnp(3) or btnp(4) or btnp(5) then
		game_state = "start"
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