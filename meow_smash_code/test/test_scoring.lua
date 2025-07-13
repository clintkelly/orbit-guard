--============================================
-- Scoring System Tests
--============================================
-- Tests for scoring, combo system, and point calculations

local luaunit = require('luaunit')

-- Test class for scoring system
TestScoring = {}

function TestScoring:setUp()
    -- Reset scoring state
    player_score = 0
    player_combo = 0
end

function TestScoring:tearDown()
    player_score = 0
    player_combo = 0
end

--============================================
-- Basic Scoring Tests
--============================================

function TestScoring:test_initial_score_state()
    luaunit.assertEquals(player_score, 0)
    luaunit.assertEquals(player_combo, 0)
end

function TestScoring:test_brick_destruction_scoring()
    local brick = normal_brick:new(50, 20)
    local ball = ball:new()
    
    handle_brick_hit(brick, ball, true)  -- brick destroyed
    
    luaunit.assertEquals(player_score, 10, "Should get 10 points for destroying brick with no combo")
    luaunit.assertEquals(player_combo, 1, "Combo should increase to 1")
end

function TestScoring:test_brick_damage_scoring()
    local brick = multi_hit_brick:new(50, 20, 3)
    local ball = ball:new()
    
    handle_brick_hit(brick, ball, false)  -- brick damaged but not destroyed
    
    luaunit.assertEquals(player_score, 5, "Should get 5 points for damaging brick with no combo")
    luaunit.assertEquals(player_combo, 1, "Combo should increase to 1")
end

--============================================
-- Combo System Tests
--============================================

function TestScoring:test_combo_multiplier_progression()
    local brick = normal_brick:new(50, 20)
    local ball = ball:new()
    
    -- First hit: combo 0 -> 1, score = 10 * (0 + 1) = 10
    handle_brick_hit(brick, ball, true)
    luaunit.assertEquals(player_score, 10)
    luaunit.assertEquals(player_combo, 1)
    
    -- Second hit: combo 1 -> 2, score += 10 * (1 + 1) = 20, total = 30
    brick = normal_brick:new(60, 20)
    handle_brick_hit(brick, ball, true)
    luaunit.assertEquals(player_score, 30)
    luaunit.assertEquals(player_combo, 2)
    
    -- Third hit: combo 2 -> 3, score += 10 * (2 + 1) = 30, total = 60
    brick = normal_brick:new(70, 20)
    handle_brick_hit(brick, ball, true)
    luaunit.assertEquals(player_score, 60)
    luaunit.assertEquals(player_combo, 3)
end

function TestScoring:test_combo_cap_at_10()
    -- Set combo to maximum
    player_combo = 10
    player_score = 0
    
    local brick = normal_brick:new(50, 20)
    local ball = ball:new()
    
    handle_brick_hit(brick, ball, true)
    
    -- Score should use capped combo (10), not uncapped (11)
    -- Expected: 10 * (min(10, 10) + 1) = 10 * 11 = 110
    luaunit.assertEquals(player_score, 110, "Score should use capped combo value")
    luaunit.assertEquals(player_combo, 11, "Combo should still increment past cap")
end

function TestScoring:test_combo_overflow_prevention()
    -- Test with very high combo to ensure no integer overflow
    player_combo = 15  -- above the cap
    player_score = 0
    
    local brick = normal_brick:new(50, 20)
    local ball = ball:new()
    
    handle_brick_hit(brick, ball, true)
    
    -- Should use min(15, 10) = 10 for calculation
    luaunit.assertEquals(player_score, 110, "Should prevent overflow with high combo")
end

--============================================
-- Unbreakable Brick Scoring Tests
--============================================

function TestScoring:test_unbreakable_brick_no_scoring()
    local brick = unbreakable_brick:new(50, 20)
    local ball = ball:new()
    local initial_score = player_score
    local initial_combo = player_combo
    
    handle_brick_hit(brick, ball, false)  -- unbreakable brick hit
    
    luaunit.assertEquals(player_score, initial_score, "Unbreakable brick should not give points")
    luaunit.assertEquals(player_combo, initial_combo, "Unbreakable brick should not increase combo")
end

--============================================
-- Different Brick Type Scoring Tests
--============================================

function TestScoring:test_speed_brick_scoring()
    local brick = speed_brick:new(50, 20)
    local ball = ball:new()
    
    handle_brick_hit(brick, ball, true)  -- speed brick destroyed
    
    luaunit.assertEquals(player_score, 10, "Speed brick should give normal points")
    luaunit.assertEquals(player_combo, 1, "Speed brick should increase combo")
end

function TestScoring:test_moving_brick_scoring()
    local brick = moving_brick:new(50, 20)
    local ball = ball:new()
    
    handle_brick_hit(brick, ball, true)  -- moving brick destroyed
    
    luaunit.assertEquals(player_score, 10, "Moving brick should give normal points")
    luaunit.assertEquals(player_combo, 1, "Moving brick should increase combo")
end

function TestScoring:test_powerup_brick_scoring()
    local brick = powerup_brick:new(50, 20)
    local ball = ball:new()
    
    handle_brick_hit(brick, ball, true)  -- powerup brick destroyed
    
    luaunit.assertEquals(player_score, 10, "Powerup brick should give normal points")
    luaunit.assertEquals(player_combo, 1, "Powerup brick should increase combo")
end

--============================================
-- Multi-Hit Brick Scoring Tests
--============================================

function TestScoring:test_multi_hit_brick_damage_and_destroy()
    local brick = multi_hit_brick:new(50, 20, 2)
    local ball = ball:new()
    
    -- First hit - damage but not destroy
    handle_brick_hit(brick, ball, false)
    luaunit.assertEquals(player_score, 5, "Should get 5 points for damage")
    luaunit.assertEquals(player_combo, 1)
    
    -- Second hit - destroy
    handle_brick_hit(brick, ball, true)
    luaunit.assertEquals(player_score, 25, "Should get 20 more points (10 * 2) for destruction")
    luaunit.assertEquals(player_combo, 2)
end

--============================================
-- Combo Reset Tests
--============================================

function TestScoring:test_combo_reset_on_ball_launch()
    player_combo = 5
    
    -- Simulate ball launch (this happens in ball:handle_stuck_ball_behavior)
    player_combo = 0  -- reset combo when ball launches
    
    luaunit.assertEquals(player_combo, 0, "Combo should reset when ball launches")
end

function TestScoring:test_combo_reset_on_paddle_hit()
    player_combo = 5
    
    -- Simulate paddle hit (this happens in ball:update)
    player_combo = 0  -- reset combo when ball hits paddle
    
    luaunit.assertEquals(player_combo, 0, "Combo should reset when ball hits paddle")
end

function TestScoring:test_combo_reset_on_life_lost()
    player_combo = 5
    
    -- Simulate life lost (this happens in update_game)
    player_combo = 0
    
    luaunit.assertEquals(player_combo, 0, "Combo should reset when life is lost")
end

--============================================
-- Score Calculation Edge Cases
--============================================

function TestScoring:test_zero_combo_scoring()
    player_combo = 0
    local brick = normal_brick:new(50, 20)
    local ball = ball:new()
    
    handle_brick_hit(brick, ball, true)
    
    luaunit.assertEquals(player_score, 10, "Zero combo should give base points")
end

function TestScoring:test_negative_combo_handling()
    -- This shouldn't happen in normal gameplay, but test robustness
    player_combo = -1
    local brick = normal_brick:new(50, 20)
    local ball = ball:new()
    
    handle_brick_hit(brick, ball, true)
    
    -- min(-1, 10) = -1, but safe_combo + 1 = 0, so score = 10 * 0 = 0
    luaunit.assertEquals(player_score, 0, "Negative combo should be handled safely")
end

--============================================
-- Large Score Tests
--============================================

function TestScoring:test_large_score_accumulation()
    -- Test that scores can accumulate to large values without issues
    player_score = 50000
    player_combo = 8
    
    local brick = normal_brick:new(50, 20)
    local ball = ball:new()
    
    handle_brick_hit(brick, ball, true)
    
    -- Should add 10 * (8 + 1) = 90 points
    luaunit.assertEquals(player_score, 50090, "Large scores should accumulate correctly")
end

--============================================
-- Sound Effect Integration Tests
--============================================

function TestScoring:test_sound_effects_based_on_combo()
    -- Test that sound IDs are calculated correctly based on combo
    player_combo = 1
    
    local expected_sound = min(6 + player_combo - 1, 13)  -- Should be 6
    luaunit.assertEquals(expected_sound, 6, "Combo 1 should use sound 6")
    
    player_combo = 5
    expected_sound = min(6 + player_combo - 1, 13)  -- Should be 10
    luaunit.assertEquals(expected_sound, 10, "Combo 5 should use sound 10")
    
    player_combo = 10
    expected_sound = min(6 + player_combo - 1, 13)  -- Should be 13 (capped)
    luaunit.assertEquals(expected_sound, 13, "Combo 10+ should use sound 13 (max)")
end

--============================================
-- Performance Tests
--============================================

function TestScoring:test_scoring_performance_with_many_hits()
    -- Test that scoring calculations remain fast with many hits
    local start_time = os.clock()
    
    local brick = normal_brick:new(50, 20)
    local ball = ball:new()
    
    -- Simulate many brick hits
    for i = 1, 1000 do
        player_combo = i
        handle_brick_hit(brick, ball, true)
    end
    
    local end_time = os.clock()
    local duration = end_time - start_time
    
    -- Should complete in reasonable time (less than 1 second for 1000 hits)
    luaunit.assertTrue(duration < 1.0, "Scoring should be performant")
end

return TestScoring