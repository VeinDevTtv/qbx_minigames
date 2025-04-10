# QBX Minigames

A collection of interactive minigames for QBox Framework.

## Overview

QBX Minigames provides a set of challenging and interactive minigames that can be used throughout your server's resources. These are perfect for lockpicking, hacking, safe cracking, and other activities that require player skill.

## Features

- 5 different minigame types with varying difficulty levels
- Configurable parameters for each minigame
- Mobile-friendly UI design
- Sound effects (optional)
- Easy integration with other resources via exports

## Available Minigames

### 1. Memory Sequence

Players must memorize and reproduce a sequence of highlighted tiles in the correct order.

![Memory Sequence](https://i.imgur.com/example1.png)

### 2. Circuit Solver

Players must rotate circuit pieces to create a complete path from the source to the destination.

![Circuit Solver](https://i.imgur.com/example2.png)

### 3. Code Cracker

Similar to Mastermind, players must crack a color code with limited attempts, receiving feedback on correct colors and positions.

![Code Cracker](https://i.imgur.com/example3.png)

### 4. Safe Cracker

Players must rotate a dial to find specific positions, similar to cracking a combination safe.

![Safe Cracker](https://i.imgur.com/example4.png)

### 5. Thermite

Players must memorize a pattern of highlighted cells, then reproduce it from memory.

![Thermite](https://i.imgur.com/example5.png)

## Usage

You can start a minigame from any client-side resource using the provided export:

```lua
-- Basic usage
exports['qbx_minigames']:StartMinigame(minigameType, difficulty, duration, function(success, data)
    if success then
        -- Player completed the minigame successfully
        print("Minigame completed! Time remaining: " .. data.timeRemaining)
    else
        -- Player failed the minigame
        print("Minigame failed!")
    end
end)
```

### Parameters

- `minigameType`: String, one of "memory_sequence", "circuit_solver", "code_cracker", "safe_cracker", "thermite"
- `difficulty`: String, one of "easy", "normal", "hard" (optional, defaults to "normal")
- `duration`: Number, time in milliseconds (optional, uses default per minigame type)
- `callback`: Function to be called when the minigame completes (required)

### Example Usage

```lua
-- Example: Lockpicking a door with Memory Sequence
RegisterNetEvent('qbx_doors:client:lockpick')
AddEventHandler('qbx_doors:client:lockpick', function(doorId)
    -- Play lockpicking animation
    TaskPlayAnim(PlayerPedId(), "veh@break_in@0h@p_m_one@", "low_force_entry_ds", 3.0, 3.0, -1, 16, 0, 0, 0, 0)
    
    -- Start the minigame
    exports['qbx_minigames']:StartMinigame("memory_sequence", "normal", 5000, function(success)
        -- Stop animation
        ClearPedTasks(PlayerPedId())
        
        if success then
            -- Notify success
            QBX.Functions.Notify("Lockpicking successful!", "success")
            -- Trigger door unlock
            TriggerServerEvent('qbx_doors:server:updateDoorState', doorId, false)
        else
            -- Notify failure
            QBX.Functions.Notify("Lockpicking failed!", "error")
            -- Maybe break lockpick item
            TriggerServerEvent('qbx_items:server:removeLockpick')
        end
    end)
end)

-- Example: Hacking a bank vault with Thermite
RegisterNetEvent('qbx_bankrobbery:client:hackVault')
AddEventHandler('qbx_bankrobbery:client:hackVault', function(bankId)
    -- Play thermite animation
    TaskPlayAnim(PlayerPedId(), "anim@heists@ornate_bank@thermal_charge", "thermal_charge", 8.0, 8.0, -1, 17, 0, false, false, false)
    
    -- Start the minigame (hard difficulty, 10 seconds)
    exports['qbx_minigames']:StartMinigame("thermite", "hard", 10000, function(success)
        -- Stop animation
        ClearPedTasks(PlayerPedId())
        
        if success then
            -- Notify success
            QBX.Functions.Notify("Thermite charge successfully planted!", "success")
            -- Trigger explosion effects and open vault
            TriggerServerEvent('qbx_bankrobbery:server:vaultOpened', bankId)
        else
            -- Notify failure
            QBX.Functions.Notify("Thermite failed to ignite!", "error")
            -- Remove thermite item
            TriggerServerEvent('qbx_items:server:removeThermite')
        end
    end)
end)
```

## Commands

- `/testminigame [type] [difficulty]` - Test a minigame with specified type and difficulty

## Configuration

Each minigame has different configuration options based on difficulty levels:

### Memory Sequence
- Easy: 3x3 grid, 4 sequence length
- Normal: 4x4 grid, 6 sequence length
- Hard: 5x5 grid, 8 sequence length

### Circuit Solver
- Easy: 3x3 grid, 2 circuits
- Normal: 4x4 grid, 3 circuits
- Hard: 5x5 grid, 4 circuits

### Code Cracker
- Easy: 4 length code, 6 attempts
- Normal: 5 length code, 5 attempts
- Hard: 6 length code, 4 attempts

### Safe Cracker
- Easy: 1 rotation, 5 zones
- Normal: 2 rotations, 4 zones
- Hard: 3 rotations, 3 zones

### Thermite
- Easy: 5x5 grid, 3 targets
- Normal: 6x6 grid, 4 targets
- Hard: 7x7 grid, 5 targets

## Dependencies

- qbx_core

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Credits

- Created by Vein for QBox Framework
- UI Design inspired by NoPixel minigames 