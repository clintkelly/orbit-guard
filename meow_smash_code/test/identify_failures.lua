#!/usr/bin/env lua

-- Script to identify specific failing tests

local current_dir = debug.getinfo(1, "S").source:match("@(.*/)") or "./"
package.path = package.path .. ";" .. current_dir .. "?.lua"
package.path = package.path .. ";" .. current_dir .. "../?.lua"

local luaunit = require('luaunit')
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

-- Test modules to check
local test_modules = {
    'test_collision',
    'test_ball_physics', 
    'test_brick_system',
    'test_powerups',
    'test_scoring',
    'test_levels'
}

local failing_tests = {}

for _, module_name in ipairs(test_modules) do
    print("Checking " .. module_name .. "...")
    
    local success, test_module = pcall(require, module_name)
    if success then
        -- Find test classes in the module
        for class_name, test_class in pairs(test_module) do
            if type(test_class) == "table" and class_name:match("^Test") then
                -- Find test methods
                for method_name, method in pairs(test_class) do
                    if type(method) == "function" and method_name:match("^test_") then
                        -- Try to run this specific test
                        local test_instance = {}
                        setmetatable(test_instance, {__index = test_class})
                        
                        local test_success, test_error = pcall(function()
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
                        
                        if not test_success then
                            local full_name = class_name .. "." .. method_name
                            table.insert(failing_tests, {
                                module = module_name,
                                class = class_name, 
                                method = method_name,
                                full_name = full_name,
                                error = tostring(test_error)
                            })
                            print("  ✗ " .. full_name .. ": " .. tostring(test_error))
                        end
                        
                        -- Reset state between tests
                        pico8_shim.reset_all()
                        bricks = {}
                        powerups = {}
                        balls = {}
                        player_lives = 5
                        player_score = 0
                        player_combo = 0
                    end
                end
            end
        end
    end
end

print("\n=== SUMMARY ===")
print("Total failing tests: " .. #failing_tests)
for _, test in ipairs(failing_tests) do
    print("- " .. test.full_name)
end