--============================================
-- Collision Detection Tests
--============================================
-- Tests for the collision detection system, particularly the complex
-- ball vs brick collision logic with corner detection and trajectory analysis

local luaunit = require('luaunit')

-- Test class for collision detection
TestCollision = {}

function TestCollision:setUp()
    -- Create a test ball for collision testing
    self.test_ball = ball:new()
    self.test_ball.x = 64
    self.test_ball.y = 40
    self.test_ball.radius = 2
    self.test_ball.dx = 2
    self.test_ball.dy = 2
end

function TestCollision:tearDown()
    -- Clean up after each test
    self.test_ball = nil
end

--============================================
-- Basic Collision Detection Tests
--============================================

function TestCollision:test_no_collision_when_far_away()
    -- Ball far from box should return "none"
    local result = self.test_ball:check_box_collision(10, 10, 50, 50, 10, 10)
    luaunit.assertEquals(result, "none")
end

function TestCollision:test_collision_from_left_side()
    -- Ball approaching box from left should return "side"
    self.test_ball.dx = 2  -- moving right
    self.test_ball.dy = 0  -- not moving vertically
    
    -- Position ball just to the left of a box
    local result = self.test_ball:check_box_collision(48, 50, 50, 50, 10, 10)
    luaunit.assertEquals(result, "side")
end

function TestCollision:test_collision_from_right_side()
    -- Ball approaching box from right should return "side"
    self.test_ball.dx = -2  -- moving left
    self.test_ball.dy = 0   -- not moving vertically
    
    -- Position ball just to the right of a box
    local result = self.test_ball:check_box_collision(62, 50, 50, 50, 10, 10)
    luaunit.assertEquals(result, "side")
end

function TestCollision:test_collision_from_top()
    -- Ball approaching box from top should return "top"
    self.test_ball.dx = 0  -- not moving horizontally
    self.test_ball.dy = 2  -- moving down
    
    -- Position ball just above a box
    local result = self.test_ball:check_box_collision(55, 48, 50, 50, 10, 10)
    luaunit.assertEquals(result, "top")
end

function TestCollision:test_collision_from_bottom()
    -- Ball approaching box from bottom should return "top"
    self.test_ball.dx = 0   -- not moving horizontally  
    self.test_ball.dy = -2  -- moving up
    
    -- Position ball just below a box
    local result = self.test_ball:check_box_collision(55, 62, 50, 50, 10, 10)
    luaunit.assertEquals(result, "top")
end

--============================================
-- Corner Collision Tests (Advanced)
--============================================

function TestCollision:test_corner_collision_moving_horizontally()
    -- When ball is moving more horizontally at a corner, should prioritize vertical surface
    self.test_ball.dx = 3  -- moving right fast
    self.test_ball.dy = 1  -- moving down slowly
    
    -- Position at corner where both overlaps are similar
    local result = self.test_ball:check_box_collision(48, 48, 50, 50, 10, 10)
    luaunit.assertEquals(result, "top")  -- Should choose vertical surface
end

function TestCollision:test_corner_collision_moving_vertically()
    -- When ball is moving more vertically at a corner, should prioritize horizontal surface
    self.test_ball.dx = 1  -- moving right slowly
    self.test_ball.dy = 3  -- moving down fast
    
    -- Position at corner where both overlaps are similar
    local result = self.test_ball:check_box_collision(48, 48, 50, 50, 10, 10)
    luaunit.assertEquals(result, "side")  -- Should choose horizontal surface
end

function TestCollision:test_corner_collision_equal_velocity()
    -- When ball has equal horizontal and vertical velocity, should still work
    self.test_ball.dx = 2  -- moving right
    self.test_ball.dy = 2  -- moving down (equal)
    
    -- Position at corner 
    local result = self.test_ball:check_box_collision(48, 48, 50, 50, 10, 10)
    -- Should return either "side" or "top" (both are valid for equal velocities)
    luaunit.assertTrue(result == "side" or result == "top")
end

--============================================
-- Edge Case Tests
--============================================

function TestCollision:test_ball_exactly_touching_edge()
    -- Ball exactly touching an edge should detect collision
    -- Ball with radius 2 at x=48 should touch box at x=50
    local result = self.test_ball:check_box_collision(48, 55, 50, 50, 10, 10)
    luaunit.assertNotEquals(result, "none")
end

function TestCollision:test_zero_velocity_collision()
    -- Ball with zero velocity should still detect collision based on position
    self.test_ball.dx = 0
    self.test_ball.dy = 0
    
    local result = self.test_ball:check_box_collision(48, 55, 50, 50, 10, 10)
    luaunit.assertNotEquals(result, "none")
end

function TestCollision:test_very_small_box()
    -- Collision with very small box (1x1 pixel)
    local result = self.test_ball:check_box_collision(50, 50, 50, 50, 1, 1)
    luaunit.assertNotEquals(result, "none")
end

function TestCollision:test_very_large_box()
    -- Collision with very large box
    local result = self.test_ball:check_box_collision(55, 55, 0, 0, 100, 100)
    luaunit.assertNotEquals(result, "none")
end

--============================================
-- Paddle Collision Tests
--============================================

function TestCollision:test_paddle_collision_detection()
    -- Set up a test paddle
    player_paddle = paddle:new()
    player_paddle.x = 50
    player_paddle.y = 120
    player_paddle.width = 24
    player_paddle.height = 3
    
    -- Test collision with paddle
    local result = self.test_ball:check_paddle_collision(55, 118)
    luaunit.assertNotEquals(result, "none")
end

--============================================
-- Swept Collision Tests  
--============================================

function TestCollision:test_swept_collision_no_tunneling()
    -- Test that swept collision prevents tunneling through thin objects
    self.test_ball.x = 45
    self.test_ball.y = 55
    self.test_ball.dx = 10  -- very fast movement
    self.test_ball.dy = 0
    
    -- Create a thin brick that could be tunneled through
    local test_brick = normal_brick:new(50, 54)
    test_brick.width = 2  -- very thin
    test_brick.height = 4
    
    -- Add brick to global bricks array for collision detection
    bricks = {test_brick}
    
    -- Run swept collision
    self.test_ball:move_with_collision_sweep()
    
    -- Ball should have stopped at brick, not tunneled through
    luaunit.assertTrue(self.test_ball.x < 55, "Ball should have stopped before tunneling")
    
    -- Clean up
    bricks = {}
end

--============================================
-- Position Correction Tests
--============================================

function TestCollision:test_position_correction_after_collision()
    -- Test that position is corrected after collision to prevent overlap
    self.test_ball.x = 47  -- positioned to collide
    self.test_ball.y = 55
    self.test_ball.dx = 2   -- moving right toward brick
    self.test_ball.dy = 0
    
    local test_brick = normal_brick:new(50, 54)
    bricks = {test_brick}
    
    -- Check collision and get corrected position
    local corrected_x, corrected_y = check_brick_collisions(self.test_ball, self.test_ball.x + self.test_ball.dx, self.test_ball.y)
    
    if corrected_x then
        -- Position should be corrected to not overlap with brick
        luaunit.assertTrue(corrected_x <= test_brick.x - self.test_ball.radius, 
                          "Ball position should be corrected to not overlap brick")
    end
    
    -- Clean up
    bricks = {}
end

--============================================
-- Multiple Collision Tests
--============================================

function TestCollision:test_multiple_brick_collision_handling()
    -- Test that only one collision is processed per frame
    self.test_ball.x = 55
    self.test_ball.y = 55  
    self.test_ball.dx = 2
    self.test_ball.dy = 2
    
    -- Create two overlapping bricks
    local brick1 = normal_brick:new(50, 50)
    local brick2 = normal_brick:new(52, 52)
    bricks = {brick1, brick2}
    
    local initial_dx = self.test_ball.dx
    local initial_dy = self.test_ball.dy
    
    -- Check collision
    check_brick_collisions(self.test_ball, self.test_ball.x + self.test_ball.dx, self.test_ball.y + self.test_ball.dy)
    
    -- Only one direction should have been reversed
    local dx_changed = (self.test_ball.dx ~= initial_dx)
    local dy_changed = (self.test_ball.dy ~= initial_dy)
    luaunit.assertFalse(dx_changed and dy_changed, "Both directions should not be reversed simultaneously")
    
    -- Clean up
    bricks = {}
end

return TestCollision