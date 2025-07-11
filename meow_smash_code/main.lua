-- meow smash game --

-- level data --
levels = {
	-- level 1: simple pattern
	{
		"",
		"",
		"",
		"....N"
	},
	-- level 1: simple pattern
	{
		"N.N.N.N.N.N"
	},
	-- level 2: multi-hit and unbreakable bricks
	{
		"U2222222222U",
		"U3333333333U",
		"U2222222222U",
	},
	-- level 3: mixed with speed bricks
	{
		"N.S.N.S.N.S.N",
		".2.3.2.3.2.3.",
		"S.N.S.N.S.N.S",
		".3.2.3.2.3.2.",
		"N.S.N.S.N.S.N"
	}
}

current_level = 1

-- paddle class --
paddle = {}
function paddle:new()
	local obj = {
		x = 52,
		y = 120,
		width = 24,
		height = 3,
		max_speed = 2.5, -- max speed - you hit then when the button is pressed
		dx = 0, -- current speed
		friction = 1.2, -- factor by which to reduce speed every frame after button is released
		flash_timer = 0, -- timer for red flash effect
		last_direction = 0, -- track last movement direction for ball launch
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
end

function paddle:draw()
	local color = 7 -- default white
	if self.flash_timer > 0 then
		color = 8 -- red when flashing
	end
	rectfill(self.x, self.y, self.x + self.width - 1, self.y + self.height - 1, color)
end

function paddle:flash()
	self.flash_timer = 5
end

-- brick class --
brick = {}
function brick:new(x, y, brick_type)
	local obj = {
		x = x or 60,
		y = y or 20,
		width = 10,
		height = 4,
		active = true,
		brick_type = brick_type or "N",
		hits_remaining = 1,
		breakable = true
	}
	
	-- set properties based on brick type
	if brick_type == "U" then
		obj.breakable = false
	elseif brick_type >= "2" and brick_type <= "9" then
		obj.hits_remaining = tonum(brick_type)
	end
	
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
		local color = 12 -- default normal brick color
		
		if self.brick_type == "U" then
			color = 5 -- dark gray for unbreakable
		elseif self.brick_type >= "2" and self.brick_type <= "9" then
			-- multi-hit bricks get different colors based on remaining hits
			if self.hits_remaining >= 4 then
				color = 8 -- red for high hits
			elseif self.hits_remaining >= 2 then
				color = 9 -- orange for medium hits
			else
				color = 10 -- yellow for low hits
			end
		elseif self.brick_type == "S" then
			color = 11 -- green for speed bricks
		elseif self.brick_type == "M" then
			color = 13 -- purple for moving bricks
		end
		
		rectfill(self.x, self.y, self.x + self.width - 1, self.y + self.height - 1, color)
	end
end

-- ball class --
ball = {}
function ball:new()
	local obj = {
		x = 64,
		y = 40,
		radius = 2,
		dx = 0, -- start stationary
		dy = 0, -- start stationary
		is_sticky = true, -- start attached to paddle
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
	if self.is_sticky then
		-- stick ball to top of paddle
		self.x = player_paddle.x + player_paddle.width / 2
		self.y = player_paddle.y - self.radius
		
		-- check for launch
		if btnp(4) then -- Z button - launch left
			self.is_sticky = false
			player_combo = 0 -- reset combo when ball launches
			local speed = 2
			-- launch 45 degrees to the left
			self.dx = -speed * 0.707 -- cos(45°)
			self.dy = -speed * 0.707 -- sin(45°) - negative for upward
		elseif btnp(5) then -- X button - launch right
			self.is_sticky = false
			player_combo = 0 -- reset combo when ball launches
			local speed = 2
			-- launch 45 degrees to the right
			self.dx = speed * 0.707
			self.dy = -speed * 0.707
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
	
	-- check if ball hits bottom (lose life)
	if next_y + self.radius >= 128 then
		player_lives -= 1
		player_combo = 0 -- reset combo when ball is lost
		sfx(1) -- play life lost sound
		if player_lives <= 0 then
			game_state = "game_over"
		else
			-- reset ball to sticky state
			self.is_sticky = true
			self.dx = 0
			self.dy = 0
		end
	end
	
	-- check paddle collision (only when not sticky)
	if not self.is_sticky then
		local collision = self:check_paddle_collision(next_x, next_y)
		if collision == "side" then
			self.dx = -self.dx
			player_paddle:flash()
			player_score += 1
			player_combo = 0 -- reset combo when ball hits paddle
			sfx(0)
		elseif collision == "top" then
			self.dy = -abs(self.dy)
			player_paddle:flash()
			player_score += 1
			player_combo = 0 -- reset combo when ball hits paddle
			sfx(0)
		end
	end
	
	-- check brick collisions
	local hit_a_brick = false -- make sure we don't bounce twice

	for brick in all(bricks) do
		if brick.active then
			local brick_collision = self:check_box_collision(next_x, next_y, brick.x, brick.y, brick.width, brick.height)
			if brick_collision == "side" then
				if not hit_a_brick then 
					self.dx = -self.dx
					hit_a_brick = true
				end
				local destroyed = brick:hit()
				if destroyed then
					local points = 10 * (player_combo * 10 + 1)
					player_score += points
					player_combo += 1 -- increase combo for each brick hit
					-- handle special brick effects
					if brick.brick_type == "S" then
						-- speed brick: increase ball speed
						self.dx = self.dx * 1.2
						self.dy = self.dy * 1.2
					end
				else
					local points = 5 * (player_combo * 10 + 1)
					player_score += points -- partial points for damaged brick
					player_combo += 1 -- increase combo even for damaged bricks
				end
				sfx(2)
			elseif brick_collision == "top" then
				if not hit_a_brick then 
					self.dy = -self.dy
					hit_a_brick = true
				end
				local destroyed = brick:hit()
				if destroyed then
					local points = 10 * (player_combo * 10 + 1)
					player_score += points
					player_combo += 1 -- increase combo for each brick hit
					-- handle special brick effects
					if brick.brick_type == "S" then
						-- speed brick: increase ball speed
						self.dx = self.dx * 1.2
						self.dy = self.dy * 1.2
					end
				else
					local points = 5 * (player_combo * 10 + 1)
					player_score += points -- partial points for damaged brick
					player_combo += 1 -- increase combo even for damaged bricks
				end
				sfx(2)
			end
		end
	end
	
	-- move ball
	self.x += self.dx
	self.y += self.dy
end

function ball:draw()
	circfill(self.x, self.y, self.radius, 10)
	
	-- draw launch indicators when sticky
	if self.is_sticky then
		self:draw_launch_indicators()
	end
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

-- game state management --
game_state = "start"
player_lives = 5
player_score = 0
player_combo = 0
bricks = {}

function _init()
	player_paddle = paddle:new()
	game_ball = ball:new()
	player_lives = 5
	player_score = 0
	player_combo = 0
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
		for col = 1, #row_string do
			local char = sub(row_string, col, col)
			if char != "." then -- not empty space
				local brick_x = (col - 1) * 10 + 4 -- 10 pixels spacing, start at x=4
				local brick_y = 15 + (row - 1) * 6 -- start at y=15, 6 pixels spacing
				add(bricks, brick:new(brick_x, brick_y, char))
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
		game_ball = ball:new()
		player_lives = 5
		player_score = 0
		player_combo = 0
		current_level = 1
		-- reset bricks
		init_bricks()
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
	game_ball:update()
	
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
	player_paddle:draw()
	game_ball:draw()
	-- draw bricks
	for brick in all(bricks) do
		brick:draw()
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
		game_ball = ball:new()
		player_paddle = paddle:new()
		player_combo = 0
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