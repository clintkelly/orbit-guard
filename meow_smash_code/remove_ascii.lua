#!/usr/bin/env lua

-- Remove ASCII art comments to reduce file size

local input_file = "main.lua"
local output_file = "main_compact.lua"

-- Read the input file
local file = io.open(input_file, "r")
if not file then
    print("Error: Could not open input file " .. input_file)
    os.exit(1)
end

local lines = {}
for line in file:lines() do
    table.insert(lines, line)
end
file:close()

-- Remove ASCII art and excessive comment blocks
local compact_lines = {}
local skip_ascii_block = false

for _, line in ipairs(lines) do
    -- Check if this is an ASCII art comment block
    if line:match("^%-%-==+") or line:match("^%-%-██") or line:match("^%-%-[ ]*██") then
        skip_ascii_block = true
        goto continue
    end
    
    -- Check if ASCII block is ending
    if skip_ascii_block and (line:match("^%-%-==+") or line == "" or (not line:match("^%-%-"))) then
        skip_ascii_block = false
        if line == "" or not line:match("^%-%-") then
            table.insert(compact_lines, line)
        end
        goto continue
    end
    
    -- Skip lines that are part of ASCII blocks
    if skip_ascii_block then
        goto continue
    end
    
    -- Keep all other lines
    table.insert(compact_lines, line)
    
    ::continue::
end

-- Write the compact file
local output = io.open(output_file, "w")
if not output then
    print("Error: Could not create output file " .. output_file)
    os.exit(1)
end

for _, line in ipairs(compact_lines) do
    output:write(line .. "\n")
end
output:close()

-- Check sizes
local function get_file_size(filename)
    local f = io.open(filename, "r")
    if not f then return 0 end
    local size = f:seek("end")
    f:close()
    return size
end

local original_size = get_file_size(input_file)
local compact_size = get_file_size(output_file)

print(string.format("Original size: %d bytes (%.1fK)", original_size, original_size / 1024))
print(string.format("Compact size: %d bytes (%.1fK)", compact_size, compact_size / 1024))
print(string.format("Reduction: %d bytes (%.1f%%)", original_size - compact_size, (original_size - compact_size) / original_size * 100))

if compact_size <= 65536 then
    print("✓ File fits within PICO-8's 64K limit!")
else
    print("✗ File still exceeds 64K limit")
end