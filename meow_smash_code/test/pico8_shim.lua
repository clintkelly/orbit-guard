--============================================
-- PICO-8 Function Shims for Unit Testing
--============================================
-- This file provides mock implementations of PICO-8 built-in functions
-- to allow testing game logic in a standard Lua environment

local pico8_shim = {}

-- Override Lua's load function to handle PICO-8 operators
local original_load = load
function load(chunk, chunkname, mode, env)
    if type(chunk) == "string" then
        -- Convert PICO-8 operators to standard Lua
        chunk = chunk:gsub("([%w_%[%]%.]+)%s*%+=%s*([^%s]+)", "%1 = %1 + (%2)")
        chunk = chunk:gsub("([%w_%[%]%.]+)%s*%-=%s*([^%s]+)", "%1 = %1 - (%2)")
        chunk = chunk:gsub("([%w_%[%]%.]+)%s*%*=%s*([^%s]+)", "%1 = %1 * (%2)")
        chunk = chunk:gsub("([%w_%[%]%.]+)%s*/=%s*([^%s]+)", "%1 = %1 / (%2)")
    end
    return original_load(chunk, chunkname, mode, env)
end

-- Test state for configurable functions
local test_state = {
    rnd_values = {},
    rnd_index = 1,
    btn_states = {},
    btnp_states = {}
}

--============================================
-- MATH FUNCTIONS
--============================================

-- Use standard Lua math functions with PICO-8 naming
sqrt = math.sqrt
abs = math.abs
sin = math.sin
cos = math.cos
ceil = math.ceil

-- PICO-8 specific math functions
function min(a, b)
    if a == nil or b == nil then return a or b end
    return math.min(a, b)
end

function max(a, b)
    if a == nil or b == nil then return a or b end
    return math.max(a, b)
end

function flr(x)
    if x == nil then return nil end
    return math.floor(x)
end

-- Random number generator with test control
function rnd(n)
    n = n or 1
    
    -- Use pre-configured test values if available
    if #test_state.rnd_values > 0 then
        local value = test_state.rnd_values[test_state.rnd_index]
        test_state.rnd_index = (test_state.rnd_index % #test_state.rnd_values) + 1
        return value * n
    end
    
    -- Fall back to standard Lua random
    return math.random() * n
end

--============================================
-- TABLE FUNCTIONS
--============================================

function add(t, item)
    if t == nil then return end
    table.insert(t, item)
end

function del(t, item)
    if t == nil then return end
    for i, v in ipairs(t) do
        if v == item then
            table.remove(t, i)
            break
        end
    end
end

function all(t)
    if t == nil then return function() end end
    local i = 0
    return function()
        i = i + 1
        return t[i]
    end
end

--============================================
-- INPUT FUNCTIONS  
--============================================

function btn(button_id, player_num)
    player_num = player_num or 0
    local key = tostring(button_id) .. "_" .. tostring(player_num)
    return test_state.btn_states[key] or false
end

function btnp(button_id, player_num)
    player_num = player_num or 0
    local key = tostring(button_id) .. "_" .. tostring(player_num)
    return test_state.btnp_states[key] or false
end

--============================================
-- GRAPHICS FUNCTIONS (No-op for tests)
--============================================

function spr(sprite_id, x, y, w, h, flip_x, flip_y)
    -- No-op for tests
end

function line(x1, y1, x2, y2, color)
    -- No-op for tests  
end

function rectfill(x1, y1, x2, y2, color)
    -- No-op for tests
end

function circfill(x, y, radius, color)
    -- No-op for tests
end

function cls(color)
    -- No-op for tests
end

function print(text, x, y, color)
    -- No-op for tests (could log for debugging if needed)
end

--============================================
-- AUDIO FUNCTIONS (No-op for tests)
--============================================

function sfx(sound_id, channel, offset, length)
    -- No-op for tests
end

--============================================
-- STRING FUNCTIONS
--============================================

function sub(str, start_pos, end_pos)
    if str == nil then return nil end
    return string.sub(str, start_pos, end_pos)
end

function tonum(str, base)
    if str == nil then return nil end
    return tonumber(str, base)
end

function tostr(num, hex_digits)
    if num == nil then return "nil" end
    if hex_digits then
        -- PICO-8 hex formatting (simplified)
        return string.format("%x", math.floor(num))
    else
        return tostring(num)
    end
end

--============================================
-- TEST UTILITY FUNCTIONS
--============================================

function pico8_shim.set_rnd_values(values)
    test_state.rnd_values = values
    test_state.rnd_index = 1
end

function pico8_shim.clear_rnd_values()
    test_state.rnd_values = {}
    test_state.rnd_index = 1
end

function pico8_shim.set_btn_state(button_id, player_num, pressed)
    player_num = player_num or 0
    local key = tostring(button_id) .. "_" .. tostring(player_num)
    test_state.btn_states[key] = pressed
end

function pico8_shim.set_btnp_state(button_id, player_num, pressed)
    player_num = player_num or 0
    local key = tostring(button_id) .. "_" .. tostring(player_num)
    test_state.btnp_states[key] = pressed
end

function pico8_shim.clear_input_states()
    test_state.btn_states = {}
    test_state.btnp_states = {}
end

function pico8_shim.reset_all()
    pico8_shim.clear_rnd_values()
    pico8_shim.clear_input_states()
end

return pico8_shim