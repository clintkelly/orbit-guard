#!/usr/bin/env lua

-- Convert standard Lua syntax back to PICO-8 syntax

local input_file = "main_compact.lua"
local output_file = "main_pico8.lua"

-- Read the input file
local file = io.open(input_file, "r")
if not file then
    print("Error: Could not open input file " .. input_file)
    os.exit(1)
end

local content = file:read("*all")
file:close()

-- Convert standard Lua operators back to PICO-8 syntax
local conversions = {
    -- += operators
    {"([%w_%.%[%]]+)%s*=%s*%1%s*%+%s*([^%s][^%c]*)", "%1 += %2"},
    {"([%w_%.%[%]]+)%s*=%s*([^%s][^%c]*)%s*%+%s*%1", "%1 += %2"},
    
    -- -= operators  
    {"([%w_%.%[%]]+)%s*=%s*%1%s*%-%s*([^%s][^%c]*)", "%1 -= %2"},
    
    -- *= operators
    {"([%w_%.%[%]]+)%s*=%s*%1%s*%*%s*([^%s][^%c]*)", "%1 *= %2"},
    
    -- != operator
    {"~=", "!="}
}

-- Apply conversions
for _, conversion in ipairs(conversions) do
    content = content:gsub(conversion[1], conversion[2])
end

-- More specific conversions for common patterns
local specific_patterns = {
    {"self%.x = self%.x %+ self%.dx", "self.x += self.dx"},
    {"self%.y = self%.y %+ self%.dy", "self.y += self.dy"},
    {"self%.dx = self%.dx %* friction", "self.dx *= friction"},
    {"self%.dy = self%.dy %* friction", "self.dy *= friction"},
    {"self%.dx = self%.dx %* scale", "self.dx *= scale"},
    {"self%.dy = self%.dy %* scale", "self.dy *= scale"},
    {"player_lives = player_lives %+ (%d+)", "player_lives += %1"},
    {"player_score = player_score %+ ([^%s]+)", "player_score += %1"},
    {"player_combo = player_combo %+ (%d+)", "player_combo += %1"},
    {"particle%.age = particle%.age %+ (%d+)", "particle.age += %1"},
    {"particle%.life = particle%.life %- ([^%s]+)", "particle.life -= %1"},
    {"self%.life = self%.life %- (%d+)", "self.life -= %1"},
    {"self%.flash_timer = self%.flash_timer %- (%d+)", "self.flash_timer -= %1"},
    {"self%.size_timer = self%.size_timer %- (%d+)", "self.size_timer -= %1"},
    {"self%.sticky_timer = self%.sticky_timer %- (%d+)", "self.sticky_timer -= %1"}
}

for _, pattern in ipairs(specific_patterns) do
    content = content:gsub(pattern[1], pattern[2])
end

-- Write the PICO-8 syntax file
local output = io.open(output_file, "w")
if not output then
    print("Error: Could not create output file " .. output_file)
    os.exit(1)
end

output:write(content)
output:close()

-- Check sizes
local function get_file_size(filename)
    local f = io.open(filename, "r")
    if not f then return 0 end
    local size = f:seek("end")
    f:close()
    return size
end

local input_size = get_file_size(input_file)
local output_size = get_file_size(output_file)

print(string.format("Input size: %d bytes (%.1fK)", input_size, input_size / 1024))
print(string.format("PICO-8 size: %d bytes (%.1fK)", output_size, output_size / 1024))

if output_size <= 65536 then
    print("✓ File fits within PICO-8's 64K limit!")
else
    print("✗ File still exceeds 64K limit")
end

print("Converted to PICO-8 syntax with +=, -=, *= and != operators")