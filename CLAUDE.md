# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a PICO-8 game development directory containing cartridge files (.p8) and associated Lua code. PICO-8 is a fantasy console that uses Lua for scripting and has built-in sprite, sound, and music editors.

## File Structure and Architecture

- `.p8` files are PICO-8 cartridge files containing complete games with embedded Lua code, sprites, sound, and music data
- `demon_code/` directory contains modular Lua code that can be included in cartridge files
- The main game logic follows PICO-8's standard callback pattern with `_init()`, `_update()`, and `_draw()` functions
- Object-oriented programming is implemented using Lua metatables for game entities (player, dust particles)

## Development Workflow

### Running and Testing Games
- Load cartridge files directly in PICO-8 using `load demon.p8` or similar commands
- Test gameplay using PICO-8's built-in controls (arrow keys, Z/X buttons)
- Use PICO-8's `run` command to start the game and `stop` to halt execution

### Code Organization
- Main game code should not go in .p8 files but instead should be in  separate .lua files in subdirectories
- Use `#include` directives in .p8 files to reference external Lua files
- The `demon.p8` cartridge demonstrates the include pattern by referencing `demon_code/main.lua`

### PICO-8 Specific Considerations
- Screen resolution is fixed at 128x128 pixels
- Color palette is limited to 16 colors (0-15)
- Sprites are 8x8 pixels and stored in the cartridge's graphics data section
- Game objects should respect PICO-8's coordinate system and screen boundaries
- Use PICO-8's built-in functions like `spr()`, `circfill()`, `btn()`, `rnd()`, etc.

## Common Patterns

### Entity Classes
- Game entities use Lua's metatable system for object-oriented behavior
- Constructor pattern: `function class:new()` with `setmetatable(obj, self)` and `self.__index = self`
- Update/draw separation: entities have separate `update()` and `draw()` methods

### Game Loop
- `_init()`: Initialize game state, create initial objects
- `_update()`: Update game logic, handle input, move objects
- `_draw()`: Clear screen with `cls()`, draw all objects

### Input Handling
- Use `btn(button_id, player_num)` for continuous input detection
- Button IDs: 0=left, 1=right, 2=up, 3=down, 4=Z, 5=X
- Support for 2-player input by passing player number (0 or 1)