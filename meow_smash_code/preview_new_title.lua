#!/usr/bin/env lua
--============================================
-- New Title Screen Animation Preview
--============================================

-- Simulate PICO-8 colors
local colors = {
    [0] = "BLACK (INVISIBLE)",
    [5] = "DARK_GREY", 
    [6] = "LIGHT_GREY",
    [7] = "WHITE",
    [11] = "LIGHT_GREEN"
}

-- Simulate the new instruction text animation logic
local function get_instruction_color(frame_counter, is_fast_blinking, fast_blink_timer)
    if is_fast_blinking then
        -- Very fast blinking: every 4 frames, on for 2, off for 2
        if fast_blink_timer % 4 < 2 then
            return 6, colors[6] -- LIGHT_GREY
        else
            return 0, colors[0] -- BLACK (invisible)
        end
    else
        -- Faster pulsing cycle: white -> grey -> dark -> light green -> back
        -- Cycle every 80 frames (1.3 seconds at 60fps - faster than before)
        local cycle_position = (frame_counter % 80) / 80
        
        if cycle_position < 0.25 then
            return 7, colors[7] -- WHITE
        elseif cycle_position < 0.5 then
            return 6, colors[6] -- LIGHT_GREY
        elseif cycle_position < 0.75 then
            return 5, colors[5] -- DARK_GREY
        else
            return 11, colors[11] -- LIGHT_GREEN
        end
    end
end

print("New Title Screen Animation Preview")
print("==================================")
print()
print("TITLE: 'MEOW SMASH!' - Always WHITE with WHITE box (no animation)")
print()

-- Show faster normal pulsing cycle
print("INSTRUCTION TEXT Normal Pulsing (80 frames = 1.3 seconds, faster than before):")
for frame = 0, 79, 8 do
    local color_id, color_name = get_instruction_color(frame, false, 0)
    local cycle_pos = (frame % 80) / 80
    print(string.format("Frame %2d: %s (%.1f%% through cycle)", frame, color_name, cycle_pos * 100))
end

print()
print("INSTRUCTION TEXT Fast Blinking (first 16 frames - much faster than before):")
for frame = 60, 44, -1 do  -- counting down like the timer
    local color_id, color_name = get_instruction_color(0, true, frame)
    local visible = color_name ~= "BLACK (INVISIBLE)" and "VISIBLE" or "HIDDEN"
    print(string.format("Timer %2d: %s (%s)", frame, color_name, visible))
    if frame == 44 then break end
end

print()
print("Summary of changes:")
print("✓ 'MEOW SMASH!' title: Always WHITE with WHITE box (no animation)")
print("✓ 'Press any key' text: Faster color pulsing (1.3s vs 2s cycle)")
print("✓ Button press effect: Much faster blinking (every 4 frames vs 6)")
print("✓ Same 1-second fast blink duration before game starts")