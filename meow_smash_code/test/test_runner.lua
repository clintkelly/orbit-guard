#!/usr/bin/env lua

--============================================
-- Test Runner for Meow Smash Unit Tests
--============================================
-- This script sets up the test environment and runs all test suites

-- Add the current directory to the Lua path so we can require local modules
local current_dir = debug.getinfo(1, "S").source:match("@(.*/)") or "./"
package.path = package.path .. ";" .. current_dir .. "?.lua"
package.path = package.path .. ";" .. current_dir .. "../?.lua"

-- Try to load luaunit (install with: luarocks install luaunit)
local luaunit_ok, luaunit = pcall(require, 'luaunit')
if not luaunit_ok then
    print("ERROR: luaunit not found. Please install it with:")
    print("  luarocks install luaunit")
    print("or download luaunit.lua and place it in the test directory")
    os.exit(1)
end

-- Load PICO-8 shims BEFORE loading game code
print("Loading PICO-8 shims...")
local pico8_shim = require('pico8_shim')

-- Load the main game code
print("Loading game code...")
-- We need to set up some globals that the game expects
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

-- Load game code (this will define all the classes and functions)
-- First convert PICO-8 operators to standard Lua
os.execute('lua convert_main.lua')
dofile('main_converted.lua')

-- Import test modules
print("Loading test suites...")
local test_collision = require('test_collision')
local test_ball_physics = require('test_ball_physics')
local test_brick_system = require('test_brick_system')
local test_powerups = require('test_powerups')  
local test_scoring = require('test_scoring')
local test_levels = require('test_levels')

-- Set up test environment
print("\n" .. string.rep("=", 50))
print("MEOW SMASH UNIT TESTS")
print(string.rep("=", 50))

-- Reset shims before each test run
pico8_shim.reset_all()

-- Run all tests
print("Running test suites...\n")

-- Set luaunit options
luaunit.LuaUnit.verbosity = luaunit.VERBOSITY_DEFAULT

-- Run the tests
local runner = luaunit.LuaUnit.new()
local exit_code = runner:runSuite()

-- Print summary
print("\n" .. string.rep("=", 50))
if exit_code == 0 then
    print("ALL TESTS PASSED! ✓")
else
    print("SOME TESTS FAILED! ✗")
end
print(string.rep("=", 50))

-- Exit with proper code
os.exit(exit_code)