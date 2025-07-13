--============================================
-- Powerup System Tests
--============================================
-- Tests for powerup spawning, collection, effects, and behavior

local luaunit = require('luaunit')

-- Test class for powerup system
TestPowerups = {}

function TestPowerups:setUp()
    -- Set up test environment
    powerups = {}
    balls = {}
    player_lives = 3
    player_shield = nil
    
    -- Create test paddle
    player_paddle = paddle:new()
    player_paddle.x = 52
    player_paddle.y = 120
    player_paddle.width = 24
    player_paddle.height = 3
end

function TestPowerups:tearDown()
    powerups = {}
    balls = {}
    player_lives = 3
    player_shield = nil
    player_paddle = nil
end

--============================================
-- Base Powerup Tests
--============================================

function TestPowerups:test_powerup_creation()
    local powerup = powerup:new(64, 30)
    
    luaunit.assertEquals(powerup.x, 64)
    luaunit.assertEquals(powerup.y, 30)
    luaunit.assertEquals(powerup.dy, powerup_fall_speed)
    luaunit.assertTrue(powerup.active)
    luaunit.assertFalse(powerup.is_paused)
    luaunit.assertEquals(powerup.bottom_pause_timer, 0)
end

function TestPowerups:test_powerup_falling()
    local powerup = powerup:new(64, 30)
    local initial_y = powerup.y
    
    powerup:update()
    
    luaunit.assertTrue(powerup.y > initial_y, "Powerup should fall down")
end

function TestPowerups:test_powerup_paddle_collision()
    local powerup = powerup:new(player_paddle.x + 5, player_paddle.y - 2)
    
    local collides = powerup:check_paddle_collision()
    
    luaunit.assertTrue(collides, "Powerup should collide with paddle")
end

function TestPowerups:test_powerup_bottom_pause()
    local powerup = powerup:new(64, 119)  -- just above bottom pause trigger
    
    powerup:update()
    
    luaunit.assertTrue(powerup.is_paused, "Powerup should pause at bottom")
    luaunit.assertEquals(powerup.y, 120, "Powerup should be locked at bottom position")
    luaunit.assertEquals(powerup.bottom_pause_timer, powerup_bottom_pause)
end

function TestPowerups:test_powerup_pause_expiration()
    local powerup = powerup:new(64, 120)
    powerup.is_paused = true
    powerup.bottom_pause_timer = 1  -- about to expire
    
    powerup:update()
    
    luaunit.assertFalse(powerup.active, "Powerup should become inactive after pause expires")
end

--============================================
-- Extra Life Powerup Tests
--============================================

function TestPowerups:test_extra_life_powerup_creation()
    local powerup = extra_life_powerup:new(64, 30)
    
    luaunit.assertEquals(powerup.sprite_id, 3)
    luaunit.assertTrue(powerup.active)
end

function TestPowerups:test_extra_life_powerup_collection()
    local powerup = extra_life_powerup:new(player_paddle.x + 5, player_paddle.y - 2)
    local initial_lives = player_lives
    
    powerup:collect()
    
    luaunit.assertEquals(player_lives, initial_lives + 1, "Extra life should increase player lives")
end

--============================================
-- Multi-Ball Powerup Tests
--============================================

function TestPowerups:test_multi_ball_powerup_creation()
    local powerup = multi_ball_powerup:new(64, 30)
    
    luaunit.assertEquals(powerup.sprite_id, 4)
end

function TestPowerups:test_multi_ball_spawn()
    -- Set up a base ball
    local base_ball = ball:new()
    base_ball.x = 64
    base_ball.y = 50
    balls = {base_ball}
    
    local initial_ball_count = #balls
    
    spawn_additional_balls()
    
    luaunit.assertEquals(#balls, initial_ball_count + 2, "Should spawn 2 additional balls")
    
    -- Check that new balls have proper velocities
    for i = 2, #balls do
        local new_ball = balls[i]
        luaunit.assertFalse(new_ball.is_stuck_to_paddle, "New balls should not be stuck")
        luaunit.assertTrue(new_ball.dy < 0, "New balls should move upward")
        
        -- Check speed is reasonable
        local speed = sqrt(new_ball.dx^2 + new_ball.dy^2)
        luaunit.assertAlmostEquals(speed, default_ball_speed, 0.1)
    end
end

--============================================
-- Bigger Paddle Powerup Tests
--============================================

function TestPowerups:test_bigger_paddle_powerup_creation()
    local powerup = bigger_paddle_powerup:new(64, 30)
    
    luaunit.assertEquals(powerup.sprite_id, 5)
end

function TestPowerups:test_expand_paddle()
    local original_width = player_paddle.width
    
    expand_paddle()
    
    luaunit.assertTrue(player_paddle.width > original_width, "Paddle should be wider")
    luaunit.assertEquals(player_paddle.size_multiplier, 1.5, "Size multiplier should be 1.5")
    luaunit.assertTrue(player_paddle.size_timer > 0, "Size timer should be active")
end

--============================================
-- Sticky Paddle Powerup Tests
--============================================

function TestPowerups:test_sticky_paddle_powerup_creation()
    local powerup = sticky_paddle_powerup:new(64, 30)
    
    luaunit.assertEquals(powerup.sprite_id, 6)
end

function TestPowerups:test_activate_sticky_paddle()
    luaunit.assertFalse(player_paddle.is_sticky, "Paddle should not be sticky initially")
    
    activate_sticky_paddle()
    
    luaunit.assertTrue(player_paddle.is_sticky, "Paddle should become sticky")
    luaunit.assertTrue(player_paddle.sticky_timer > 0, "Sticky timer should be active")
end

--============================================
-- Shield Powerup Tests
--============================================

function TestPowerups:test_shield_powerup_creation()
    local powerup = shield_powerup:new(64, 30)
    
    luaunit.assertEquals(powerup.sprite_id, 7)
end

function TestPowerups:test_activate_shield()
    luaunit.assertNil(player_shield, "Shield should not exist initially")
    
    activate_shield()
    
    luaunit.assertNotNil(player_shield, "Shield should be created")
    luaunit.assertTrue(player_shield.active, "Shield should be active")
    luaunit.assertEquals(player_shield.y, player_paddle.y + player_paddle.height)
end

--============================================
-- Powerup Spawning Tests
--============================================

function TestPowerups:test_spawn_powerup_extra_life()
    local initial_count = #powerups
    
    spawn_powerup("extra_life", 64, 30)
    
    luaunit.assertEquals(#powerups, initial_count + 1, "Should spawn one powerup")
    luaunit.assertEquals(powerups[#powerups].sprite_id, 3, "Should be extra life powerup")
end

function TestPowerups:test_spawn_powerup_multi_ball()
    spawn_powerup("multi_ball", 64, 30)
    
    luaunit.assertEquals(powerups[#powerups].sprite_id, 4, "Should be multi ball powerup")
end

function TestPowerups:test_spawn_powerup_bigger_paddle()
    spawn_powerup("bigger_paddle", 64, 30)
    
    luaunit.assertEquals(powerups[#powerups].sprite_id, 5, "Should be bigger paddle powerup")
end

function TestPowerups:test_spawn_powerup_sticky_paddle()
    spawn_powerup("sticky_paddle", 64, 30)
    
    luaunit.assertEquals(powerups[#powerups].sprite_id, 6, "Should be sticky paddle powerup")
end

function TestPowerups:test_spawn_powerup_shield()
    spawn_powerup("shield", 64, 30)
    
    luaunit.assertEquals(powerups[#powerups].sprite_id, 7, "Should be shield powerup")
end

function TestPowerups:test_spawn_powerup_unknown_type()
    -- Unknown type should default to extra life
    spawn_powerup("unknown_type", 64, 30)
    
    luaunit.assertEquals(powerups[#powerups].sprite_id, 3, "Unknown type should default to extra life")
end

--============================================
-- Powerup Collection Tests
--============================================

function TestPowerups:test_powerup_collection_during_fall()
    local powerup = extra_life_powerup:new(player_paddle.x + 5, player_paddle.y - 1)
    local initial_lives = player_lives
    
    powerup:update()  -- This should trigger collection
    
    luaunit.assertEquals(player_lives, initial_lives + 1, "Lives should increase")
    luaunit.assertFalse(powerup.active, "Powerup should become inactive")
end

function TestPowerups:test_powerup_collection_during_pause()
    local powerup = extra_life_powerup:new(player_paddle.x + 5, 120)
    powerup.is_paused = true
    powerup.bottom_pause_timer = 30
    local initial_lives = player_lives
    
    powerup:update()  -- Should check for paddle collision while paused
    
    luaunit.assertEquals(player_lives, initial_lives + 1, "Lives should increase")
    luaunit.assertFalse(powerup.active, "Powerup should become inactive")
end

--============================================
-- Powerup Visual Tests
--============================================

function TestPowerups:test_powerup_flashing_when_paused()
    local powerup = powerup:new(64, 120)
    powerup.is_paused = true
    powerup.flash_timer = 0
    
    -- Flash timer should increment when paused
    powerup:update()
    
    luaunit.assertTrue(powerup.flash_timer > 0, "Flash timer should increment when paused")
end

function TestPowerups:test_powerup_draw_does_not_crash()
    local powerup = powerup:new(64, 30)
    
    -- Should not crash when drawing
    powerup:draw()
    
    -- Should not crash when drawing while paused
    powerup.is_paused = true
    powerup.flash_timer = 5
    powerup:draw()
end

--============================================
-- Integration Tests
--============================================

function TestPowerups:test_powerup_lifecycle()
    -- Test complete powerup lifecycle: spawn -> fall -> pause -> collect
    local powerup = extra_life_powerup:new(player_paddle.x + 5, 50)
    local initial_lives = player_lives
    
    -- Fall until near bottom
    while powerup.y < 115 and powerup.active do
        powerup:update()
    end
    
    luaunit.assertTrue(powerup.active, "Powerup should still be active")
    
    -- Next update should trigger pause
    powerup:update()
    
    luaunit.assertTrue(powerup.is_paused, "Powerup should be paused at bottom")
    luaunit.assertEquals(powerup.y, 120, "Powerup should be at bottom position")
    
    -- Collection should work while paused
    powerup:update()
    
    luaunit.assertEquals(player_lives, initial_lives + 1, "Lives should increase from collection")
    luaunit.assertFalse(powerup.active, "Powerup should be inactive after collection")
end

return TestPowerups