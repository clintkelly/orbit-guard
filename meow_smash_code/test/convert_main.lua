#!/usr/bin/env lua

-- Script to convert PICO-8 main.lua to standard Lua for testing

local function convert_pico8_operators(content)
    -- Convert PICO-8 compound assignment operators to standard Lua
    -- Process line by line to avoid issues with line breaks
    local lines = {}
    for line in content:gmatch("[^\r\n]*") do
        -- Convert operators on each line
        line = line:gsub("([%w_%[%]%.]+)%s*%+=%s*([^%s]+)", "%1 = %1 + %2")
        line = line:gsub("([%w_%[%]%.]+)%s*%-=%s*([^%s]+)", "%1 = %1 - %2") 
        line = line:gsub("([%w_%[%]%.]+)%s*%*=%s*([^%s]+)", "%1 = %1 * %2")
        line = line:gsub("([%w_%[%]%.]+)%s*/=%s*([^%s]+)", "%1 = %1 / %2")
        -- Convert PICO-8 != to Lua ~=
        line = line:gsub("!=", "~=")
        table.insert(lines, line)
    end
    return table.concat(lines, "\n")
end

-- Read the main.lua file (prefer PICO-8 version if it exists)
local input_file = "../main_pico8.lua"
local output_file = "main_converted.lua"

local file = io.open(input_file, "r")
if not file then
    -- Fall back to main.lua if PICO-8 version doesn't exist
    input_file = "../main.lua"
    file = io.open(input_file, "r")
    if not file then
        print("Error: Could not open " .. input_file)
        os.exit(1)
    end
end

local content = file:read("*all")
file:close()

-- Convert operators
local converted_content = convert_pico8_operators(content)

-- Write converted file
local output = io.open(output_file, "w")
if not output then
    print("Error: Could not create " .. output_file)
    os.exit(1)
end

output:write(converted_content)
output:close()

print("Converted " .. input_file .. " to " .. output_file)
print("PICO-8 operators converted to standard Lua syntax")