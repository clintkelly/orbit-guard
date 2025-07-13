#!/usr/bin/env lua

-- Debug script to identify failing tests one by one

-- Add the current directory to the Lua path
local current_dir = debug.getinfo(1, "S").source:match("@(.*/)") or "./"
package.path = package.path .. ";" .. current_dir .. "?.lua"
package.path = package.path .. ";" .. current_dir .. "../?.lua"

-- Load luaunit
local luaunit = require('luaunit')

-- Load PICO-8 shims
local pico8_shim = require('pico8_shim')

-- Set up globals
bricks = {}
powerups = {}
balls = {}
player_shield = nil
player_paddle = nil
game_state = "start"
player_lives = 5
player_score = 0
player_combo = 0
powerup_fall_speed = 0.5
powerup_bottom_pause = 60
max_ball_dx_dy_ratio = 3.0
default_ball_speed = 2.0
current_level = 1
shuffled_levels = {}

-- Convert and load game code
os.execute('lua convert_main.lua')
dofile('main_converted.lua')

-- Test each module individually
local test_modules = {
    'test_collision',
    'test_ball_physics', 
    'test_brick_system',
    'test_powerups',
    'test_scoring',
    'test_levels'
}

for _, module_name in ipairs(test_modules) do
    print("\n=== Testing " .. module_name .. " ===")
    
    -- Clear any previous test state
    pico8_shim.reset_all()
    
    local success, test_module = pcall(require, module_name)
    if not success then
        print("ERROR: Could not load " .. module_name .. ": " .. test_module)
    else
        print("Module loaded successfully")
        
        -- Try to run just the first test from this module
        local runner = luaunit.LuaUnit.new()
        runner.verbosity = luaunit.VERBOSITY_VERBOSE
        
        -- Get all test methods from the module
        for name, value in pairs(test_module) do
            if type(value) == "table" and name:match("^Test") then
                print("Test class found: " .. name)
                for method_name, method in pairs(value) do
                    if type(method) == "function" and method_name:match("^test_") then
                        print("  Test method: " .. method_name)
                        
                        -- Try to run this specific test
                        local test_success, test_error = pcall(function()
                            local test_instance = {}
                            setmetatable(test_instance, {__index = value})
                            
                            -- Set up
                            if test_instance.setUp then
                                test_instance:setUp()
                            end
                            
                            -- Run test
                            test_instance[method_name](test_instance)
                            
                            -- Tear down
                            if test_instance.tearDown then
                                test_instance:tearDown()
                            end
                        end)
                        
                        if test_success then
                            print("    ✓ PASSED")
                        else
                            print("    ✗ FAILED: " .. tostring(test_error))
                        end
                        
                        -- Only test first few methods to avoid spam
                        break
                    end
                end
                break -- Only test first class
            end
        end
    end
end