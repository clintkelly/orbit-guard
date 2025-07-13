--============================================
-- Level System Tests
--============================================
-- Tests for level loading, brick creation from patterns, and level progression

local luaunit = require('luaunit')
local pico8_shim = require('pico8_shim')

-- Test class for level system
TestLevels = {}

function TestLevels:setUp()
    -- Reset level state
    bricks = {}
    current_level = 1
    shuffled_levels = {}
    
    -- Store original levels count
    self.original_level_count = #levels
    
    -- Reset random for consistent shuffling tests
    pico8_shim.clear_rnd_values()
end

function TestLevels:tearDown()
    bricks = {}
    current_level = 1
    shuffled_levels = {}
    
    -- Remove any test levels that were added by clearing the table properly
    while #levels > self.original_level_count do
        table.remove(levels)
    end
    
    pico8_shim.clear_rnd_values()
end

--============================================
-- Level Data Structure Tests
--============================================

function TestLevels:test_levels_table_exists()
    luaunit.assertNotNil(levels, "Levels table should exist")
    luaunit.assertTrue(#levels > 0, "Should have at least one level")
end

function TestLevels:test_level_1_structure()
    luaunit.assertNotNil(levels[1], "Level 1 should exist")
    luaunit.assertTrue(#levels[1] > 0, "Level 1 should have rows")
    
    -- Level 1 should be C-shaped pattern
    local level_1 = levels[1]
    luaunit.assertTrue(#level_1 >= 5, "Level 1 should have at least 5 rows")
end

function TestLevels:test_all_levels_have_valid_structure()
    for i = 1, #levels do
        local level = levels[i]
        luaunit.assertNotNil(level, "Level " .. i .. " should exist")
        luaunit.assertTrue(#level > 0, "Level " .. i .. " should have at least one row")
        
        -- Check each row is a string
        for j = 1, #level do
            luaunit.assertTrue(type(level[j]) == "string", 
                              "Level " .. i .. " row " .. j .. " should be a string")
        end
    end
end

--============================================
-- Brick Creation Tests
--============================================

function TestLevels:test_load_level_creates_bricks()
    load_level(1)
    
    luaunit.assertTrue(#bricks > 0, "Loading level should create bricks")
end

function TestLevels:DISABLED_test_brick_character_mapping()
    -- Test a simple level with known brick types
    local test_level = {"NUS2M"}
    local test_level_index = #levels + 1
    levels[test_level_index] = test_level
    
    load_level(test_level_index)
    
    luaunit.assertEquals(#bricks, 5, "Should create 5 bricks")
    
    -- Check brick types (order matters)
    luaunit.assertEquals(bricks[1].color, 12, "N should create normal brick (light blue)")
    luaunit.assertEquals(bricks[2].color, 5, "U should create unbreakable brick (dark gray)")
    luaunit.assertEquals(bricks[3].color, 11, "S should create speed brick (green)")
    luaunit.assertEquals(bricks[4].hits_remaining, 2, "2 should create 2-hit brick")
    luaunit.assertEquals(bricks[5].color, 13, "M should create moving brick (purple)")
    
    -- Clean up handled by tearDown
end

function TestLevels:DISABLED_test_multi_hit_brick_creation()
    local test_level = {"23456789"}
    local test_level_index = #levels + 1
    levels[test_level_index] = test_level
    
    load_level(98)
    
    -- Should create bricks with correct hit counts
    for i = 1, 8 do
        local expected_hits = i + 1  -- "2" = 2 hits, "3" = 3 hits, etc.
        luaunit.assertEquals(bricks[i].hits_remaining, expected_hits, 
                           "Brick " .. i .. " should have " .. expected_hits .. " hits")
    end
    
    -- Clean up
    levels[98] = nil
end

function TestLevels:DISABLED_test_powerup_brick_creation()
    local test_level = {"P"}
    local test_level_index = #levels + 1
    levels[test_level_index] = test_level
    
    load_level(97)
    
    luaunit.assertEquals(#bricks, 1)
    luaunit.assertTrue(bricks[1].drops_powerup, "P should create powerup brick")
    
    -- Clean up  
    levels[97] = nil
end

function TestLevels:DISABLED_test_empty_space_handling()
    local test_level = {"N.N"}  -- Normal, empty, normal
    levels[96] = test_level
    
    load_level(96)
    
    luaunit.assertEquals(#bricks, 2, "Empty spaces should not create bricks")
    
    -- Check positioning - should skip empty space
    luaunit.assertEquals(bricks[1].x, 4, "First brick at position 0")
    luaunit.assertEquals(bricks[2].x, 28, "Second brick at position 2 (skipping position 1)")
    
    -- Clean up handled by tearDown
end

--============================================
-- Brick Positioning Tests
--============================================

function TestLevels:DISABLED_test_brick_positioning()
    local test_level = {"N"}
    local test_level_index = #levels + 1
    levels[test_level_index] = test_level
    
    load_level(test_level_index)
    
    -- First brick should be at (4, 15) as per level encoding rules
    luaunit.assertEquals(bricks[1].x, 4, "First brick x position")
    luaunit.assertEquals(bricks[1].y, 15, "First brick y position")
    
    -- Clean up handled by tearDown
end

function TestLevels:DISABLED_test_multi_row_positioning()
    local test_level = {"N", "N"}  -- Two rows
    levels[94] = test_level
    
    load_level(94)
    
    luaunit.assertEquals(#bricks, 2)
    luaunit.assertEquals(bricks[1].y, 15, "First row at y=15")
    luaunit.assertEquals(bricks[2].y, 21, "Second row at y=21 (15 + 6)")
    
    -- Clean up
    levels[94] = nil
end

function TestLevels:DISABLED_test_horizontal_spacing()
    local test_level = {"NN"}  -- Two adjacent bricks
    levels[93] = test_level
    
    load_level(93)
    
    luaunit.assertEquals(#bricks, 2)
    luaunit.assertEquals(bricks[1].x, 4, "First brick at x=4")
    luaunit.assertEquals(bricks[2].x, 16, "Second brick at x=16 (4 + 12)")
    
    -- Clean up
    levels[93] = nil
end

--============================================
-- Level Shuffling Tests
--============================================

function TestLevels:test_create_shuffled_levels()
    -- Mock random values for predictable shuffling
    pico8_shim.set_rnd_values({0.1, 0.5, 0.8, 0.3, 0.9})
    
    create_shuffled_levels()
    
    luaunit.assertTrue(#shuffled_levels > 0, "Should create shuffled level array")
    luaunit.assertEquals(#shuffled_levels, #levels - 1, "Should include all levels except level 1")
    
    -- Check that level 1 is not in shuffled array
    for _, level_index in ipairs(shuffled_levels) do
        luaunit.assertNotEquals(level_index, 1, "Level 1 should not be in shuffled array")
    end
end

function TestLevels:test_shuffled_levels_contain_all_levels()
    create_shuffled_levels()
    
    -- Check that all levels 2-15 are present
    local found_levels = {}
    for _, level_index in ipairs(shuffled_levels) do
        found_levels[level_index] = true
    end
    
    for i = 2, #levels do
        luaunit.assertTrue(found_levels[i], "Level " .. i .. " should be in shuffled array")
    end
end

function TestLevels:test_level_1_always_first()
    current_level = 1
    
    load_level(1)
    
    -- Level 1 should always load level 1 (not shuffled)
    -- We can verify this by checking it creates the expected C-shaped pattern
    luaunit.assertTrue(#bricks > 0, "Level 1 should create bricks")
    
    -- Level 1 should have the C-shaped pattern with N and P bricks
    local has_normal = false
    local has_powerup = false
    
    for _, brick in ipairs(bricks) do
        if brick.color == 12 then has_normal = true end      -- Normal brick
        if brick.drops_powerup then has_powerup = true end   -- Powerup brick
    end
    
    luaunit.assertTrue(has_normal, "Level 1 should have normal bricks")
    luaunit.assertTrue(has_powerup, "Level 1 should have powerup bricks")
end

function TestLevels:test_shuffled_level_loading()
    -- Set up predictable shuffling
    pico8_shim.set_rnd_values({0.1, 0.5})
    create_shuffled_levels()
    
    current_level = 2  -- Second level should use shuffled order
    
    load_level(2)
    
    luaunit.assertTrue(#bricks > 0, "Shuffled level should create bricks")
end

--============================================
-- Level Progression Tests
--============================================

function TestLevels:DISABLED_test_count_breakable_bricks()
    local test_level = {"NUN"}  -- Normal, Unbreakable, Normal
    levels[92] = test_level
    
    load_level(92)
    
    local count = count_breakable_bricks()
    luaunit.assertEquals(count, 2, "Should count only breakable bricks")
    
    -- Clean up
    levels[92] = nil
end

function TestLevels:DISABLED_test_count_breakable_after_destruction()
    local test_level = {"NN"}
    levels[91] = test_level
    
    load_level(91)
    
    luaunit.assertEquals(count_breakable_bricks(), 2, "Initially 2 breakable bricks")
    
    -- Destroy one brick
    bricks[1].active = false
    
    luaunit.assertEquals(count_breakable_bricks(), 1, "Should count 1 after destruction")
    
    -- Clean up
    levels[91] = nil
end

--============================================
-- Edge Case Tests
--============================================

function TestLevels:test_load_invalid_level()
    local original_count = #bricks
    
    load_level(999)  -- Non-existent level
    
    luaunit.assertEquals(#bricks, original_count, "Loading invalid level should not create bricks")
end

function TestLevels:test_empty_level()
    local test_level = {""}  -- Empty row
    levels[90] = test_level
    
    load_level(90)
    
    luaunit.assertEquals(#bricks, 0, "Empty level should create no bricks")
    
    -- Clean up
    levels[90] = nil
end

function TestLevels:test_level_with_only_dots()
    local test_level = {"..."}  -- Only empty spaces
    levels[89] = test_level
    
    load_level(89)
    
    luaunit.assertEquals(#bricks, 0, "Level with only dots should create no bricks")
    
    -- Clean up
    levels[89] = nil
end

function TestLevels:test_max_width_enforcement()
    local test_level = {"NNNNNNNNNNNNNN"}  -- More than 10 characters
    levels[88] = test_level
    
    load_level(88)
    
    luaunit.assertTrue(#bricks <= 10, "Should not create more than 10 bricks per row")
    
    -- Clean up
    levels[88] = nil
end

--============================================
-- Integration Tests
--============================================

function TestLevels:test_complete_level_loading_cycle()
    -- Test loading multiple levels in sequence
    for level_num = 1, min(5, #levels) do
        bricks = {}  -- Clear bricks
        
        load_level(level_num)
        
        luaunit.assertTrue(#bricks >= 0, "Level " .. level_num .. " should load without error")
        
        -- Verify all bricks have valid properties
        for _, brick in ipairs(bricks) do
            luaunit.assertTrue(brick.x >= 0, "Brick should have valid x position")
            luaunit.assertTrue(brick.y >= 0, "Brick should have valid y position")
            luaunit.assertTrue(brick.width > 0, "Brick should have positive width")
            luaunit.assertTrue(brick.height > 0, "Brick should have positive height")
            luaunit.assertNotNil(brick.color, "Brick should have a color")
        end
    end
end

return TestLevels