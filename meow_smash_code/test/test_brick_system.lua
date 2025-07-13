--============================================
-- Brick System Tests
--============================================
-- Tests for different brick types, hit mechanics, and brick behaviors

local luaunit = require('luaunit')

-- Test class for brick system
TestBrickSystem = {}

function TestBrickSystem:setUp()
    -- Reset any global state
    bricks = {}
    player_score = 0
    player_combo = 0
end

function TestBrickSystem:tearDown()
    bricks = {}
    player_score = 0
    player_combo = 0
end

--============================================
-- Normal Brick Tests
--============================================

function TestBrickSystem:test_normal_brick_creation()
    local brick = normal_brick:new(50, 20)
    
    luaunit.assertEquals(brick.x, 50)
    luaunit.assertEquals(brick.y, 20)
    luaunit.assertEquals(brick.color, 12)  -- light blue
    luaunit.assertTrue(brick.active)
    luaunit.assertTrue(brick.breakable)
    luaunit.assertEquals(brick.hits_remaining, 1)
end

function TestBrickSystem:test_normal_brick_destruction()
    local brick = normal_brick:new(50, 20)
    
    local destroyed = brick:hit()
    
    luaunit.assertTrue(destroyed, "Normal brick should be destroyed in one hit")
    luaunit.assertFalse(brick.active, "Brick should be inactive after destruction")
end

--============================================
-- Unbreakable Brick Tests
--============================================

function TestBrickSystem:test_unbreakable_brick_creation()
    local brick = unbreakable_brick:new(50, 20)
    
    luaunit.assertEquals(brick.color, 5)  -- dark gray
    luaunit.assertFalse(brick.breakable)
    luaunit.assertTrue(brick.active)
end

function TestBrickSystem:test_unbreakable_brick_hit()
    local brick = unbreakable_brick:new(50, 20)
    
    local destroyed = brick:hit()
    
    luaunit.assertFalse(destroyed, "Unbreakable brick should not be destroyed")
    luaunit.assertTrue(brick.active, "Unbreakable brick should remain active")
end

--============================================
-- Multi-Hit Brick Tests
--============================================

function TestBrickSystem:test_multi_hit_brick_creation()
    local brick = multi_hit_brick:new(50, 20, 3)
    
    luaunit.assertEquals(brick.hits_remaining, 3)
    luaunit.assertEquals(brick.max_hits, 3)
    luaunit.assertTrue(brick.active)
    luaunit.assertTrue(brick.breakable)
end

function TestBrickSystem:test_multi_hit_brick_color_progression()
    local brick = multi_hit_brick:new(50, 20, 5)
    
    -- Initially should be red (high hits >= 4)
    luaunit.assertEquals(brick.color, 8)  -- red
    
    -- Hit it once
    brick:hit()
    luaunit.assertEquals(brick.hits_remaining, 4)
    luaunit.assertEquals(brick.color, 8)  -- still red (>=4 hits)
    
    -- Hit it again
    brick:hit()
    luaunit.assertEquals(brick.hits_remaining, 3)
    luaunit.assertEquals(brick.color, 9)  -- orange (>=2 hits but <4)
    
    -- Hit it once more
    brick:hit()
    luaunit.assertEquals(brick.hits_remaining, 2)
    luaunit.assertEquals(brick.color, 9)  -- still orange (>=2 hits)
    
    -- Hit it again
    brick:hit()
    luaunit.assertEquals(brick.hits_remaining, 1)
    luaunit.assertEquals(brick.color, 10)  -- yellow (1 hit)
    
    -- Final hit should destroy it
    local destroyed = brick:hit()
    luaunit.assertTrue(destroyed)
    luaunit.assertFalse(brick.active)
end

function TestBrickSystem:test_multi_hit_brick_partial_destruction()
    local brick = multi_hit_brick:new(50, 20, 2)
    
    -- First hit should damage but not destroy
    local destroyed = brick:hit()
    luaunit.assertFalse(destroyed, "First hit should not destroy 2-hit brick")
    luaunit.assertTrue(brick.active, "Brick should still be active")
    luaunit.assertEquals(brick.hits_remaining, 1)
    
    -- Second hit should destroy
    destroyed = brick:hit()
    luaunit.assertTrue(destroyed, "Second hit should destroy brick")
    luaunit.assertFalse(brick.active, "Brick should be inactive")
end

--============================================
-- Speed Brick Tests
--============================================

function TestBrickSystem:test_speed_brick_creation()
    local brick = speed_brick:new(50, 20)
    
    luaunit.assertEquals(brick.color, 11)  -- green
    luaunit.assertTrue(brick.breakable)
end

function TestBrickSystem:test_speed_brick_effect()
    local brick = speed_brick:new(50, 20)
    
    local effect = brick:on_destroy()
    luaunit.assertEquals(effect, "speed")
end

--============================================
-- Moving Brick Tests
--============================================

function TestBrickSystem:test_moving_brick_creation()
    local brick = moving_brick:new(50, 20)
    
    luaunit.assertEquals(brick.color, 13)  -- purple
    luaunit.assertEquals(brick.move_direction, 1)  -- moving right initially
    luaunit.assertEquals(brick.move_speed, 0.5)
end

function TestBrickSystem:test_moving_brick_movement()
    local brick = moving_brick:new(50, 20)
    local initial_x = brick.x
    
    -- Update should move the brick
    brick:update()
    
    luaunit.assertTrue(brick.x > initial_x, "Brick should move right initially")
end

function TestBrickSystem:test_moving_brick_boundary_collision()
    local brick = moving_brick:new(120, 20)  -- near right edge
    brick.move_direction = 1  -- moving right
    
    -- Update should hit boundary and reverse direction
    brick:update()
    
    luaunit.assertEquals(brick.move_direction, -1, "Brick should reverse direction at boundary")
    luaunit.assertEquals(brick.x, 128 - brick.width, "Brick should be positioned at right boundary")
end

function TestBrickSystem:test_moving_brick_left_boundary()
    local brick = moving_brick:new(0.4, 20)  -- near left edge (slightly more than 0 to trigger boundary)
    brick.move_direction = -1  -- moving left
    
    -- Update should hit boundary and reverse direction
    brick:update()
    
    luaunit.assertEquals(brick.move_direction, 1, "Brick should reverse direction at left boundary")
    luaunit.assertEquals(brick.x, 0, "Brick should be positioned at left boundary")
end

--============================================
-- Powerup Brick Tests
--============================================

function TestBrickSystem:test_powerup_brick_creation()
    local brick = powerup_brick:new(50, 20)
    
    luaunit.assertEquals(brick.color, 12)  -- looks like normal brick
    luaunit.assertTrue(brick.drops_powerup)
end

function TestBrickSystem:test_powerup_brick_effect()
    local brick = powerup_brick:new(50, 20)
    
    local effect = brick:on_destroy()
    
    -- Should return one of the valid powerup types
    local valid_types = {"extra_life", "multi_ball", "bigger_paddle", "sticky_paddle", "shield"}
    local is_valid = false
    for _, valid_type in ipairs(valid_types) do
        if effect == valid_type then
            is_valid = true
            break
        end
    end
    luaunit.assertTrue(is_valid, "Powerup brick should return valid powerup type")
end

--============================================
-- Brick Hit Handling Tests
--============================================

function TestBrickSystem:test_handle_brick_hit_destroyed()
    local brick = normal_brick:new(50, 20)
    local test_ball = ball:new()
    
    local initial_score = player_score
    local initial_combo = player_combo
    
    handle_brick_hit(brick, test_ball, true)  -- brick destroyed
    
    luaunit.assertTrue(player_score > initial_score, "Score should increase when brick destroyed")
    luaunit.assertTrue(player_combo > initial_combo, "Combo should increase when brick destroyed")
end

function TestBrickSystem:test_handle_brick_hit_damaged_breakable()
    local brick = multi_hit_brick:new(50, 20, 3)
    local test_ball = ball:new()
    
    local initial_score = player_score
    local initial_combo = player_combo
    
    handle_brick_hit(brick, test_ball, false)  -- brick damaged but not destroyed
    
    luaunit.assertTrue(player_score > initial_score, "Score should increase when breakable brick damaged")
    luaunit.assertTrue(player_combo > initial_combo, "Combo should increase when breakable brick damaged")
end

function TestBrickSystem:test_handle_brick_hit_unbreakable()
    local brick = unbreakable_brick:new(50, 20)
    local test_ball = ball:new()
    
    local initial_score = player_score
    local initial_combo = player_combo
    
    handle_brick_hit(brick, test_ball, false)  -- unbreakable brick hit
    
    luaunit.assertEquals(player_score, initial_score, "Score should not increase for unbreakable brick")
    luaunit.assertEquals(player_combo, initial_combo, "Combo should not increase for unbreakable brick")
end

--============================================
-- Brick Collection Tests
--============================================

function TestBrickSystem:test_count_breakable_bricks()
    -- Create mix of breakable and unbreakable bricks
    local normal = normal_brick:new(50, 20)
    local unbreakable = unbreakable_brick:new(60, 20)
    local multi_hit = multi_hit_brick:new(70, 20, 2)
    local speed = speed_brick:new(80, 20)
    
    bricks = {normal, unbreakable, multi_hit, speed}
    
    local count = count_breakable_bricks()
    luaunit.assertEquals(count, 3, "Should count 3 breakable bricks (excluding unbreakable)")
    
    -- Destroy one brick
    normal.active = false
    count = count_breakable_bricks()
    luaunit.assertEquals(count, 2, "Should count 2 breakable bricks after one destroyed")
end

--============================================
-- Brick Drawing Tests (Basic)
--============================================

function TestBrickSystem:test_brick_draw_when_active()
    local brick = normal_brick:new(50, 20)
    
    -- Drawing should not crash (we can't test visual output, but can test it doesn't error)
    luaunit.assertNotNil(brick.draw, "Brick should have draw method")
    
    -- This should not crash
    brick:draw()
end

function TestBrickSystem:test_brick_no_draw_when_inactive()
    local brick = normal_brick:new(50, 20)
    brick.active = false
    
    -- Should still be able to call draw without crashing
    brick:draw()
end

return TestBrickSystem