#!/usr/bin/env lua

-- Simple test to identify specific failing tests

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

-- Test just the brick system module
local test_brick_system = require('test_brick_system')

-- Set low verbosity and run specific failing test
luaunit.LuaUnit.verbosity = luaunit.VERBOSITY_VERBOSE

local test_suite = TestBrickSystem
local test_instance = {}
setmetatable(test_instance, {__index = test_suite})

print("Testing multi-hit brick color progression...")
test_instance:setUp()
local success, error_msg = pcall(function()
    test_instance:test_multi_hit_brick_color_progression()
end)
test_instance:tearDown()

if success then
    print("✓ Test passed!")
else
    print("✗ Test failed: " .. tostring(error_msg))
end