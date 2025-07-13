# Meow Smash Unit Tests

This directory contains a comprehensive unit testing framework for the Meow Smash PICO-8 game, focusing on collision detection and other critical game systems.

## Setup Instructions

### 1. Install Lua
On macOS with Homebrew:
```bash
brew install lua
```

On Ubuntu/Debian:
```bash
sudo apt-get install lua5.3
```

### 2. Install luaunit
```bash
luarocks install luaunit
```

Or download luaunit.lua directly and place it in the test directory.

### 3. Run Tests
```bash
cd meow_smash_code/test
lua test_runner.lua
```

## Test Structure

### Test Files

- **`pico8_shim.lua`** - Mock implementations of PICO-8 built-in functions
- **`test_runner.lua`** - Main test runner script that sets up environment and runs all tests
- **`test_collision.lua`** - **PRIMARY FOCUS** - Collision detection tests including:
  - Ball vs brick collision direction detection
  - Corner collision handling with trajectory analysis  
  - Swept collision detection validation
  - Position correction after collision
- **`test_ball_physics.lua`** - Ball physics and movement tests:
  - Zone-based paddle bouncing (5 zones A-E with specific angles)
  - Speed boost decay calculations
  - Sticky ball behavior and launch mechanics
- **`test_brick_system.lua`** - Brick system tests:
  - Different brick type behaviors (normal, unbreakable, speed, moving, powerup)
  - Multi-hit brick color progression and hit counting
  - Moving brick boundary collision
- **`test_powerups.lua`** - Powerup system tests:
  - Powerup spawning, collection, and effects
  - Bottom pause/timer behavior with flashing
  - All powerup types (life, multi-ball, bigger paddle, sticky, shield)
- **`test_scoring.lua`** - Scoring and combo system tests:
  - Combo calculation with max cap at 10 to prevent overflow
  - Points calculation for different brick types and states
  - Score progression with combo multipliers
- **`test_levels.lua`** - Level system tests:
  - Level loading from string patterns
  - Brick creation from character codes (N, U, 2-9, S, M, P)
  - Fisher-Yates level shuffling algorithm

### Key Features

- **PICO-8 Function Shims**: Complete mock implementations of PICO-8 built-ins
- **Configurable Test State**: Control random values, input states for predictable testing
- **Comprehensive Coverage**: Tests cover all major game systems and edge cases
- **Performance Testing**: Includes tests for performance-critical code paths
- **Integration Tests**: Tests that verify systems work together correctly

## Test Categories

### Collision Detection (Primary Focus)
- ✅ Ball vs brick collision direction detection (side vs top)
- ✅ Corner collision handling with trajectory analysis
- ✅ Swept collision detection to prevent tunneling
- ✅ Position correction after collision
- ✅ Multiple collision handling
- ✅ Edge cases (touching edges, zero velocity, etc.)

### Ball Physics
- ✅ Zone-based paddle bouncing with correct angles (150°, 120°, 90°, 60°, 30°)
- ✅ Speed boost activation and decay
- ✅ Sticky ball positioning and launch mechanics
- ✅ Wall and boundary collisions

### Brick System
- ✅ All brick type creation and behavior
- ✅ Multi-hit brick color progression
- ✅ Moving brick boundary collision
- ✅ Unbreakable brick immunity

### Powerup System
- ✅ All powerup types and their effects
- ✅ Bottom pause behavior with flashing
- ✅ Collection detection during fall and pause
- ✅ Multi-ball spawning with proper physics

### Scoring System
- ✅ Combo calculation with overflow prevention
- ✅ Different scoring for brick types and states
- ✅ Combo reset conditions
- ✅ Large score accumulation

### Level System
- ✅ Level loading from string patterns
- ✅ Brick positioning and spacing
- ✅ Fisher-Yates shuffling algorithm
- ✅ Level progression logic

## Benefits

- **Regression Prevention**: Catch bugs when modifying collision detection
- **Edge Case Validation**: Test corner cases difficult to reproduce in game
- **Refactoring Confidence**: Safely improve code knowing tests will catch breaks
- **Documentation**: Tests serve as executable documentation of expected behavior
- **Performance Monitoring**: Detect performance regressions in critical code paths

## Example Test Run Output

```
==================================================
MEOW SMASH UNIT TESTS
==================================================
Running test suites...

Started on Sun Jan  1 12:00:00 2024
Success: 127 tests
  TestCollision: 15 tests
  TestBallPhysics: 18 tests  
  TestBrickSystem: 22 tests
  TestPowerups: 25 tests
  TestScoring: 23 tests
  TestLevels: 24 tests

==================================================
ALL TESTS PASSED! ✓
==================================================
```