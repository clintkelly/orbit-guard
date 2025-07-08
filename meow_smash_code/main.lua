-- meow smash game --

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
		button_pressed = true
	end
	if btn(1) then -- right
		self.dx = self.max_speed
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
function brick:new(x, y)
	local obj = {
		x = x or 60,
		y = y or 20,
		width = 10,
		height = 4,
		active = true
	}
	setmetatable(obj, self)
	self.__index = self
	return obj
end

function brick:draw()
	if self.active then
		rectfill(self.x, self.y, self.x + self.width - 1, self.y + self.height - 1, 12)
	end
end

-- ball class --
ball = {}
function ball:new()
	local obj = {
		x = 64,
		y = 40,
		radius = 2,
		dx = 1 + rnd(1), -- random x speed 1-3
		dy = 1 + rnd(1)  -- random y speed 1-2
	}
	-- randomize initial direction
	if rnd(1) < 0.5 then
		obj.dx = -obj.dx
	end
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
		sfx(1) -- play life lost sound
		if player_lives <= 0 then
			game_state = "game_over"
		else
			-- reset ball position (below the bricks)
			self.x = 64
			self.y = 40
			self.dx = 1 + rnd(1)
			self.dy = 1 + rnd(1)
			if rnd(1) < 0.5 then
				self.dx = -self.dx
			end
		end
	end
	
	-- check paddle collision
	local collision = self:check_paddle_collision(next_x, next_y)
	if collision == "side" then
		self.dx = -self.dx
		player_paddle:flash()
		player_score += 1
		sfx(0)
	elseif collision == "top" then
		self.dy = -abs(self.dy)
		player_paddle:flash()
		player_score += 1
		sfx(0)
	end
	
	-- check brick collisions
	for brick in all(bricks) do
		if brick.active then
			local brick_collision = self:check_box_collision(next_x, next_y, brick.x, brick.y, brick.width, brick.height)
			if brick_collision == "side" then
				self.dx = -self.dx
				brick.active = false
				player_score += 10
				sfx(2)
				break
			elseif brick_collision == "top" then
				self.dy = -self.dy
				brick.active = false
				player_score += 10
				sfx(2)
				break
			end
		end
	end
	
	-- move ball
	self.x += self.dx
	self.y += self.dy
end

function ball:draw()
	circfill(self.x, self.y, self.radius, 10)
end

-- game state management --
game_state = "start"
player_lives = 5
player_score = 0
bricks = {}

function _init()
	player_paddle = paddle:new()
	game_ball = ball:new()
	player_lives = 5
	player_score = 0
	-- initialize bricks
	init_bricks()
end

function init_bricks()
	bricks = {}
	-- create 3 rows of bricks
	for row = 0, 2 do
		for col = 0, 11 do
			local brick_x = col * 11 + 1 -- 11 pixels spacing (10 width + 1 gap)
			local brick_y = 15 + row * 6 -- start at y=15, 6 pixels spacing (4 height + 2 gap)
			add(bricks, brick:new(brick_x, brick_y))
		end
	end
end

function _update60()
	if game_state == "start" then
		update_start()
	elseif game_state == "game" then
		update_game()
	elseif game_state == "game_over" then
		update_game_over()
	end
end

function _draw()
	if game_state == "start" then
		draw_start()
	elseif game_state == "game" then
		draw_game()
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