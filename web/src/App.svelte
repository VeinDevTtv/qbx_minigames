<script lang="ts">
    import { onMount } from 'svelte';
    import MemorySequence from './minigames/MemorySequence.svelte';
    import CircuitSolver from './minigames/CircuitSolver.svelte';
    import CodeCracker from './minigames/CodeCracker.svelte';
    import SafeCracker from './minigames/SafeCracker.svelte';
    import Thermite from './minigames/Thermite.svelte';
    
    // Game state
    let active = false;
    let minigameType = '';
    let config = {};
    
    // Event listener for messages from Lua
    onMount(() => {
        window.addEventListener("message", (event) => {
            const { action, minigameType: type, config: gameConfig } = event.data;
            
            if (action === "startMinigame") {
                // Start the minigame
                active = true;
                minigameType = type;
                config = gameConfig;
            }
        });
        
        // For testing in browser
        if (import.meta.env.DEV) {
            const urlParams = new URLSearchParams(window.location.search);
            const type = urlParams.get('type');
            if (type) {
                active = true;
                minigameType = type;
                config = getDefaultConfig(type);
            }
        }
    });
    
    // Function to get default config for testing
    function getDefaultConfig(type: string) {
        switch (type) {
            case 'memory_sequence':
                return {
                    difficulty: 'normal',
                    duration: 5000,
                    gridSize: 4,
                    sequenceLength: 6,
                    soundEnabled: true
                };
            case 'circuit_solver':
                return {
                    difficulty: 'normal',
                    duration: 30000,
                    gridSize: 4,
                    circuits: 3,
                    soundEnabled: true
                };
            case 'code_cracker':
                return {
                    difficulty: 'normal',
                    duration: 30000,
                    codeLength: 5,
                    attempts: 5,
                    soundEnabled: true
                };
            case 'safe_cracker':
                return {
                    difficulty: 'normal',
                    duration: 30000,
                    maxRotations: 2,
                    zones: 4,
                    soundEnabled: true
                };
            case 'thermite':
                return {
                    difficulty: 'normal',
                    duration: 8000,
                    displayTime: 3000,
                    gridSize: 6,
                    targetCount: 4,
                    soundEnabled: true
                };
            default:
                return {};
        }
    }
    
    // Function to handle minigame completion
    function handleComplete(success: boolean, data: any = {}) {
        // Send result back to Lua
        fetch('https://qbx_minigames/minigameComplete', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json; charset=UTF-8',
            },
            body: JSON.stringify({
                success,
                data
            })
        });
        
        // Reset game state
        active = false;
        minigameType = '';
        config = {};
    }
    
    // Function to handle minigame exit
    function handleExit() {
        // Send exit event to Lua
        fetch('https://qbx_minigames/minigameExit', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json; charset=UTF-8',
            },
            body: JSON.stringify({})
        });
        
        // Reset game state
        active = false;
        minigameType = '';
        config = {};
    }
    
    // Key press event to allow escape key to exit minigame
    function handleKeydown(event: KeyboardEvent) {
        if (event.key === 'Escape' && active) {
            handleExit();
        }
    }
</script>

<svelte:window on:keydown={handleKeydown} />

<main class:active>
    {#if active}
        <div class="minigame-container">
            {#if minigameType === 'memory_sequence'}
                <MemorySequence 
                    {config} 
                    on:complete={(e) => handleComplete(e.detail.success, e.detail.data)} 
                    on:exit={handleExit} 
                />
            {:else if minigameType === 'circuit_solver'}
                <CircuitSolver 
                    {config} 
                    on:complete={(e) => handleComplete(e.detail.success, e.detail.data)} 
                    on:exit={handleExit} 
                />
            {:else if minigameType === 'code_cracker'}
                <CodeCracker 
                    {config} 
                    on:complete={(e) => handleComplete(e.detail.success, e.detail.data)} 
                    on:exit={handleExit} 
                />
            {:else if minigameType === 'safe_cracker'}
                <SafeCracker 
                    {config} 
                    on:complete={(e) => handleComplete(e.detail.success, e.detail.data)} 
                    on:exit={handleExit} 
                />
            {:else if minigameType === 'thermite'}
                <Thermite 
                    {config} 
                    on:complete={(e) => handleComplete(e.detail.success, e.detail.data)} 
                    on:exit={handleExit} 
                />
            {:else}
                <div class="error">
                    <h2>Error: Unknown minigame type</h2>
                    <button on:click={handleExit}>Exit</button>
                </div>
            {/if}
        </div>
    {/if}
</main>

<style>
    main {
        width: 100vw;
        height: 100vh;
        display: none;
        align-items: center;
        justify-content: center;
        overflow: hidden;
        font-family: 'Roboto', sans-serif;
    }
    
    main.active {
        display: flex;
    }
    
    .minigame-container {
        position: relative;
        background-color: rgba(0, 0, 0, 0.8);
        box-shadow: 0 0 40px rgba(0, 0, 0, 0.8);
        border-radius: 10px;
        width: 800px;
        height: 600px;
        max-width: 90vw;
        max-height: 90vh;
        overflow: hidden;
    }
    
    .error {
        width: 100%;
        height: 100%;
        display: flex;
        flex-direction: column;
        align-items: center;
        justify-content: center;
        color: white;
    }
    
    .error button {
        margin-top: 20px;
        padding: 10px 20px;
        background-color: #f44336;
        color: white;
        border: none;
        border-radius: 4px;
        cursor: pointer;
        font-size: 16px;
    }
</style> 