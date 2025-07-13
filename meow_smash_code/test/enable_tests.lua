#!/usr/bin/env lua
--============================================
-- Test Re-enabler Script
--============================================
-- This script helps re-enable disabled tests by removing DISABLED_ prefixes

local function enable_test_in_file(filename, test_name)
    local file = io.open(filename, "r")
    if not file then
        print("Error: Could not open " .. filename)
        return false
    end
    
    local content = file:read("*all")
    file:close()
    
    local old_pattern = "function " .. test_name:gsub("([^%w])", "%%%1") .. ":DISABLED_([%w_]+)%(%)%s*"
    local new_replacement = "function " .. test_name .. ":%1()"
    
    local new_content, count = content:gsub(old_pattern, new_replacement)
    
    if count > 0 then
        local file = io.open(filename, "w")
        if file then
            file:write(new_content)
            file:close()
            print("Re-enabled " .. count .. " test(s) in " .. filename)
            return true
        else
            print("Error: Could not write to " .. filename)
            return false
        end
    else
        print("No disabled tests found matching pattern in " .. filename)
        return false
    end
end

local function enable_all_tests_in_file(filename)
    local file = io.open(filename, "r")
    if not file then
        print("Error: Could not open " .. filename)
        return false
    end
    
    local content = file:read("*all")
    file:close()
    
    -- Replace all DISABLED_ prefixes
    local new_content, count = content:gsub("function (%w+):DISABLED_([%w_]+)%(", "function %1:%2(")
    
    if count > 0 then
        local file = io.open(filename, "w")
        if file then
            file:write(new_content)
            file:close()
            print("Re-enabled " .. count .. " test(s) in " .. filename)
            return true
        else
            print("Error: Could not write to " .. filename)
            return false
        end
    else
        print("No disabled tests found in " .. filename)
        return false
    end
end

local function show_disabled_tests_in_file(filename)
    local file = io.open(filename, "r")
    if not file then
        print("Error: Could not open " .. filename)
        return
    end
    
    local content = file:read("*all")
    file:close()
    
    print("\nDisabled tests in " .. filename .. ":")
    local found = false
    for class_name, method_name in content:gmatch("function (%w+):DISABLED_([%w_]+)%(") do
        print("  - " .. class_name .. ":DISABLED_" .. method_name .. "()")
        found = true
    end
    
    if not found then
        print("  No disabled tests found")
    end
end

local function main()
    local test_files = {
        "test_collision.lua",
        "test_ball_physics.lua", 
        "test_brick_system.lua",
        "test_powerups.lua",
        "test_levels.lua"
    }
    
    if #arg == 0 then
        print("Test Re-enabler Script")
        print("Usage:")
        print("  lua enable_tests.lua list                    - Show all disabled tests")
        print("  lua enable_tests.lua all                     - Re-enable ALL disabled tests")
        print("  lua enable_tests.lua file <filename>         - Re-enable all tests in specific file")
        print("  lua enable_tests.lua test <filename> <test>  - Re-enable specific test")
        print("")
        print("Examples:")
        print("  lua enable_tests.lua list")
        print("  lua enable_tests.lua all")
        print("  lua enable_tests.lua file test_ball_physics.lua")
        print("  lua enable_tests.lua test test_ball_physics.lua TestBallPhysics")
        return
    end
    
    local command = arg[1]
    
    if command == "list" then
        print("=== Disabled Tests Report ===")
        for _, filename in ipairs(test_files) do
            show_disabled_tests_in_file(filename)
        end
        
    elseif command == "all" then
        print("Re-enabling ALL disabled tests...")
        local total_enabled = 0
        for _, filename in ipairs(test_files) do
            if enable_all_tests_in_file(filename) then
                total_enabled = total_enabled + 1
            end
        end
        print("\nProcessed " .. total_enabled .. " files")
        print("Run 'lua test_runner.lua' to test the changes")
        
    elseif command == "file" then
        local filename = arg[2]
        if not filename then
            print("Error: Please specify filename")
            return
        end
        
        print("Re-enabling all tests in " .. filename .. "...")
        enable_all_tests_in_file(filename)
        print("Run 'lua test_runner.lua' to test the changes")
        
    elseif command == "test" then
        local filename = arg[2]
        local test_name = arg[3]
        if not filename or not test_name then
            print("Error: Please specify both filename and test class name")
            return
        end
        
        print("Re-enabling specific test in " .. filename .. "...")
        enable_test_in_file(filename, test_name)
        print("Run 'lua test_runner.lua' to test the changes")
        
    else
        print("Error: Unknown command '" .. command .. "'")
        print("Run 'lua enable_tests.lua' for usage help")
    end
end

main()