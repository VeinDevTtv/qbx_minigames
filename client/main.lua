-- Client-side script for minigames
local QBX = exports['qbx_core']:GetCoreObject()

local isAnyMinigameActive = false
local minigameResult = nil
local minigameCallback = nil

-- Main function to start a minigame
local function StartMinigame(minigameType, config, cb)
    if isAnyMinigameActive then
        return false, "Another minigame is already in progress"
    end
    
    isAnyMinigameActive = true
    minigameResult = nil
    minigameCallback = cb
    
    -- Send NUI message to start the minigame
    SendNUIMessage({
        action = "startMinigame",
        minigameType = minigameType,
        config = config
    })
    
    -- Display cursor and set NUI focus
    SetNuiFocus(true, true)
    return true
end

-- NUI Callbacks
RegisterNUICallback('minigameComplete', function(data, cb)
    minigameResult = data.success
    isAnyMinigameActive = false
    SetNuiFocus(false, false)
    
    if minigameCallback then
        minigameCallback(data.success, data.data)
    end
    
    cb('ok')
end)

RegisterNUICallback('minigameExit', function(_, cb)
    isAnyMinigameActive = false
    SetNuiFocus(false, false)
    
    if minigameCallback then
        minigameCallback(false, {})
    end
    
    cb('ok')
end)

-- Types of minigames and their configurations
local minigames = {
    memory_sequence = function(difficulty, duration, callback)
        local config = {
            difficulty = difficulty or "normal", -- easy, normal, hard
            duration = duration or 5000, -- time in ms to memorize the sequence
            gridSize = 3, -- 3x3 grid for easy, 4x4 for normal, 5x5 for hard
            soundEnabled = true
        }
        
        if config.difficulty == "easy" then
            config.sequenceLength = 4
            config.gridSize = 3
        elseif config.difficulty == "normal" then
            config.sequenceLength = 6
            config.gridSize = 4
        else -- hard
            config.sequenceLength = 8
            config.gridSize = 5
        end
        
        return StartMinigame("memory_sequence", config, callback)
    end,
    
    circuit_solver = function(difficulty, duration, callback)
        local config = {
            difficulty = difficulty or "normal", -- easy, normal, hard
            duration = duration or 30000, -- time in ms to solve the puzzle
            soundEnabled = true
        }
        
        if config.difficulty == "easy" then
            config.gridSize = 3
            config.circuits = 2
        elseif config.difficulty == "normal" then
            config.gridSize = 4
            config.circuits = 3
        else -- hard
            config.gridSize = 5
            config.circuits = 4
        end
        
        return StartMinigame("circuit_solver", config, callback)
    end,
    
    code_cracker = function(difficulty, duration, callback)
        local config = {
            difficulty = difficulty or "normal", -- easy, normal, hard
            duration = duration or 30000, -- time in ms to crack the code
            soundEnabled = true
        }
        
        if config.difficulty == "easy" then
            config.codeLength = 4
            config.attempts = 6
        elseif config.difficulty == "normal" then
            config.codeLength = 5
            config.attempts = 5
        else -- hard
            config.codeLength = 6
            config.attempts = 4
        end
        
        return StartMinigame("code_cracker", config, callback)
    end,
    
    safe_cracker = function(difficulty, duration, callback)
        local config = {
            difficulty = difficulty or "normal", -- easy, normal, hard
            duration = duration or 30000, -- time in ms to crack the safe
            soundEnabled = true
        }
        
        if config.difficulty == "easy" then
            config.maxRotations = 1
            config.zones = 5
        elseif config.difficulty == "normal" then
            config.maxRotations = 2
            config.zones = 4
        else -- hard
            config.maxRotations = 3
            config.zones = 3
        end
        
        return StartMinigame("safe_cracker", config, callback)
    end,
    
    thermite = function(difficulty, duration, callback)
        local config = {
            difficulty = difficulty or "normal", -- easy, normal, hard
            duration = duration or 8000, -- time in ms to memorize the pattern
            displayTime = 3000, -- time in ms to show the answers
            soundEnabled = true
        }
        
        if config.difficulty == "easy" then
            config.gridSize = 5
            config.targetCount = 3
        elseif config.difficulty == "normal" then
            config.gridSize = 6
            config.targetCount = 4
        else -- hard
            config.gridSize = 7
            config.targetCount = 5
        end
        
        return StartMinigame("thermite", config, callback)
    end
}

-- Exports
exports('StartMinigame', function(minigameType, ...)
    if minigames[minigameType] then
        return minigames[minigameType](...)
    else
        return false, "Invalid minigame type"
    end
end)

exports('GetAvailableMinigames', function()
    local available = {}
    for k in pairs(minigames) do
        table.insert(available, k)
    end
    return available
end)

-- Command to test minigames
RegisterCommand('testminigame', function(source, args)
    local minigameType = args[1] or "memory_sequence"
    local difficulty = args[2] or "normal"
    
    if minigames[minigameType] then
        minigames[minigameType](difficulty, nil, function(success, data)
            if success then
                QBX.Functions.Notify("Minigame completed successfully!", "success")
            else
                QBX.Functions.Notify("Minigame failed!", "error")
            end
        end)
    else
        QBX.Functions.Notify("Invalid minigame type. Available: memory_sequence, circuit_solver, code_cracker, safe_cracker, thermite", "error")
    end
end, false) 