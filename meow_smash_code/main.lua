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

-- ball class --
ball = {}
function ball:new()
	local obj = {
		x = 64,
		y = 15,
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

function ball:check_paddle_collision(next_x, next_y)

	-- Detect if there is any collision at all - if not, just return
	if next_x + self.radius < player_paddle.x  then return "none" end
	if next_x - self.radius > player_paddle.x + player_paddle.width then return "none" end
	if next_y + self.radius < player_paddle.y then return "none" end
	if next_y - self.radius > player_paddle.y + player_paddle.height then return "none" end

	-- First just check for any ovelap - if none exists, then exit early
	-- RHS of ball / LHS of paddle
	local overlap_left = next_x + self.radius - player_paddle.x
	-- LHS of ball / RHS of paddle
	local overlap_right = player_paddle.x + player_paddle.width - (next_x - self.radius)
	-- Bottom of ball / top of paddle
	local overlap_top = next_y + self.radius - player_paddle.y
	-- Top of ball / bottom of paddle (maybe doesn't matter)
	local overlap_bottom = player_paddle.y + player_paddle.height - (next_y - self.radius)

	printh("-------------------", "log.txt")
	printh("ol="..overlap_left, "log.txt")
	printh("or="..overlap_right, "log.txt")
	printh("ot="..overlap_top, "log.txt")
	printh("ob="..overlap_bottom, "log.txt")

	min_overlap = min_all(overlap_left, overlap_right, overlap_top, overlap_bottom)
	printh("min="..min_overlap, "log.txt")
	if min_overlap == overlap_left or min_overlap == overlap_right then
		printh("side", "log.txt")
		return "side"
	end
	print("top", "log.txt")
	return "top"
end

function ball:update()
	-- calculate next position
	local next_x = self.x + self.dx
	local next_y = self.y + self.dy
	
	-- check wall collisions
	if next_x - self.radius <= 0 or next_x + self.radius >= 128 then
		self.dx = -self.dx
	end
	
	-- bounce off top bar (7 pixels tall)
	if next_y - self.radius <= 7 then
		self.dy = -self.dy
	end
	
	-- check if ball hits bottom (lose life)
	if next_y + self.radius >= 128 then
		player_lives -= 1
		sfx(1) -- play life lost sound
		if player_lives <= 0 then
			game_state = "game_over"
		else
			-- reset ball position (below the black bar)
			self.x = 64
			self.y = 15
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
		sfx(0)
	elseif collision == "top" then
		self.dy = -abs(self.dy)
		player_paddle:flash()
		sfx(0)
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

function _init()
	player_paddle = paddle:new()
	game_ball = ball:new()
	player_lives = 5
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
	-- display lives in the black bar
	print("lives: "..player_lives, 2, 1, 7)
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