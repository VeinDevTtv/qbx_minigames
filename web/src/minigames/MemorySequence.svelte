<script lang="ts">
    import { onMount, createEventDispatcher } from 'svelte';
    import { CountdownTimer, playSound, getRandomInt } from '../utils';
    import type { MemorySequenceConfig } from '../types';
    
    export let config: MemorySequenceConfig;
    
    const dispatch = createEventDispatcher<{
        complete: { success: boolean; data: any };
        exit: void;
    }>();
    
    // Game state
    let gameState: 'idle' | 'observing' | 'input' | 'success' | 'failure' = 'idle';
    let sequence: number[] = [];
    let playerSequence: number[] = [];
    let currentIndex = 0;
    let timeLeft = config.duration;
    let grid: number[][] = [];
    let timer: CountdownTimer;
    
    // Initialize game
    onMount(() => {
        generateGrid();
        generateSequence();
        timer = new CountdownTimer(
            config.duration,
            (remaining) => {
                timeLeft = remaining;
            },
            () => {
                if (gameState === 'observing') {
                    startInputPhase();
                } else if (gameState === 'input') {
                    handleGameOver(false);
                }
            }
        );
        
        startGame();
        
        return () => {
            if (timer) timer.stop();
        };
    });
    
    function generateGrid() {
        grid = [];
        const size = config.gridSize;
        
        for (let i = 0; i < size; i++) {
            const row = [];
            for (let j = 0; j < size; j++) {
                row.push(i * size + j);
            }
            grid.push(row);
        }
    }
    
    function generateSequence() {
        sequence = [];
        const size = config.gridSize;
        const totalCells = size * size;
        
        // Generate random sequence
        for (let i = 0; i < config.sequenceLength; i++) {
            let num;
            do {
                num = getRandomInt(0, totalCells - 1);
            } while (sequence.includes(num));
            
            sequence.push(num);
        }
    }
    
    function startGame() {
        playSound('start', 0.7, config.soundEnabled);
        gameState = 'observing';
        playerSequence = [];
        currentIndex = 0;
        
        // Start timer for observation phase
        timer.start();
        
        // Display the sequence to the player
        showSequence();
    }
    
    async function showSequence() {
        // Reset highlighting
        for (let i = 0; i < sequence.length; i++) {
            const tile = document.getElementById(`tile-${sequence[i]}`);
            if (tile) {
                tile.classList.remove('highlight');
            }
        }
        
        // Show the sequence with delays
        for (let i = 0; i < sequence.length; i++) {
            await new Promise(resolve => setTimeout(resolve, 800));
            
            const tile = document.getElementById(`tile-${sequence[i]}`);
            if (tile) {
                tile.classList.add('highlight');
                playSound('beep', 0.3, config.soundEnabled);
                
                // Remove highlight after a delay
                setTimeout(() => {
                    tile.classList.remove('highlight');
                }, 600);
            }
        }
    }
    
    function startInputPhase() {
        gameState = 'input';
        playerSequence = [];
        currentIndex = 0;
        
        // Reset timer for input phase
        timer.reset();
        timer.start();
        
        playSound('phase_change', 0.5, config.soundEnabled);
    }
    
    function handleTileClick(tileNumber: number) {
        if (gameState !== 'input') return;
        
        const tile = document.getElementById(`tile-${tileNumber}`);
        if (tile) {
            // Visual feedback
            tile.classList.add('clicked');
            setTimeout(() => {
                tile.classList.remove('clicked');
            }, 300);
            
            // Add to player sequence
            playerSequence.push(tileNumber);
            
            // Check if the selection is correct
            if (tileNumber === sequence[currentIndex]) {
                playSound('correct', 0.5, config.soundEnabled);
                currentIndex++;
                
                // Check if player completed the sequence
                if (currentIndex === sequence.length) {
                    handleGameOver(true);
                }
            } else {
                // Wrong selection
                playSound('error', 0.5, config.soundEnabled);
                handleGameOver(false);
            }
        }
    }
    
    function handleGameOver(success: boolean) {
        timer.stop();
        gameState = success ? 'success' : 'failure';
        
        // Play success or failure sound
        playSound(success ? 'success' : 'failure', 0.5, config.soundEnabled);
        
        // Show correct sequence if failed
        if (!success) {
            showCorrectSequence();
        }
        
        // Dispatch result after a short delay
        setTimeout(() => {
            dispatch('complete', {
                success,
                data: {
                    timeRemaining: timeLeft,
                    sequenceLength: sequence.length,
                    playerSequence: playerSequence
                }
            });
        }, 1500);
    }
    
    async function showCorrectSequence() {
        // Highlight the correct sequence
        for (let i = 0; i < sequence.length; i++) {
            const tile = document.getElementById(`tile-${sequence[i]}`);
            if (tile) {
                await new Promise(resolve => setTimeout(resolve, 400));
                tile.classList.add('correct');
            }
        }
    }
    
    function exit() {
        if (timer) timer.stop();
        dispatch('exit');
    }
    
    // Format time display
    $: timeDisplay = (timeLeft / 1000).toFixed(1);
    
    // Compute difficulty class for styling
    $: difficultyClass = `difficulty-${config.difficulty}`;
</script>

<div class="memory-sequence-container {difficultyClass}">
    <div class="header">
        <h2>Memory Sequence</h2>
        <div class="status">
            {#if gameState === 'observing'}
                <div class="phase">OBSERVE</div>
            {:else if gameState === 'input'}
                <div class="phase">REPEAT</div>
            {:else if gameState === 'success'}
                <div class="phase success">SUCCESS</div>
            {:else if gameState === 'failure'}
                <div class="phase failure">FAILED</div>
            {/if}
            <div class="timer">{timeDisplay}s</div>
        </div>
    </div>
    
    <div class="grid" style="grid-template-columns: repeat({config.gridSize}, 1fr);">
        {#each grid as row, rowIndex}
            {#each row as cell, colIndex}
                <div 
                    id="tile-{cell}"
                    class="tile"
                    on:click={() => handleTileClick(cell)}
                >
                </div>
            {/each}
        {/each}
    </div>
    
    <div class="footer">
        <div class="instructions">
            {#if gameState === 'observing'}
                Memorize the sequence
            {:else if gameState === 'input'}
                Repeat the sequence in the correct order
            {:else if gameState === 'success'}
                Sequence completed successfully!
            {:else if gameState === 'failure'}
                Incorrect sequence. Try again!
            {/if}
        </div>
        <button class="exit-button" on:click={exit}>EXIT</button>
    </div>
</div>

<style>
    .memory-sequence-container {
        width: 100%;
        height: 100%;
        display: flex;
        flex-direction: column;
        background-color: #0d1117;
        color: white;
        font-family: 'Roboto Mono', monospace;
    }
    
    .header {
        padding: 20px;
        display: flex;
        justify-content: space-between;
        align-items: center;
        border-bottom: 1px solid #30363d;
        background-color: #161b22;
    }
    
    h2 {
        margin: 0;
        font-size: 24px;
        font-weight: 600;
        color: #58a6ff;
    }
    
    .status {
        display: flex;
        align-items: center;
        gap: 15px;
    }
    
    .phase {
        font-size: 18px;
        font-weight: 700;
        padding: 5px 10px;
        border-radius: 4px;
        background-color: #21262d;
        color: #f0f6fc;
    }
    
    .phase.success {
        background-color: #238636;
    }
    
    .phase.failure {
        background-color: #da3633;
    }
    
    .timer {
        font-size: 20px;
        font-weight: 700;
        font-family: 'Digital-7', monospace;
        color: #f0f6fc;
        background-color: #0d1117;
        padding: 5px 10px;
        border-radius: 4px;
        border: 1px solid #30363d;
    }
    
    .grid {
        flex: 1;
        display: grid;
        gap: 10px;
        padding: 20px;
        justify-content: center;
        align-content: center;
    }
    
    .tile {
        aspect-ratio: 1/1;
        background-color: #21262d;
        border-radius: 4px;
        cursor: pointer;
        transition: all 0.2s ease;
        position: relative;
        border: 1px solid #30363d;
        box-shadow: 0 2px 4px rgba(0, 0, 0, 0.3);
    }
    
    .tile:hover {
        background-color: #2c3139;
    }
    
    .tile.highlight {
        background-color: #58a6ff;
        box-shadow: 0 0 10px #58a6ff, 0 0 20px rgba(88, 166, 255, 0.6);
        transform: scale(1.05);
    }
    
    .tile.clicked {
        background-color: #ffca28;
        box-shadow: 0 0 10px #ffca28, 0 0 20px rgba(255, 202, 40, 0.6);
        transform: scale(1.05);
    }
    
    .tile.correct {
        background-color: #238636;
        box-shadow: 0 0 10px #238636, 0 0 20px rgba(35, 134, 54, 0.6);
    }
    
    .footer {
        padding: 15px 20px;
        display: flex;
        justify-content: space-between;
        align-items: center;
        border-top: 1px solid #30363d;
        background-color: #161b22;
    }
    
    .instructions {
        font-size: 16px;
        color: #c9d1d9;
    }
    
    .exit-button {
        padding: 8px 16px;
        background-color: #da3633;
        border: none;
        border-radius: 4px;
        color: white;
        font-weight: 600;
        cursor: pointer;
        transition: background-color 0.2s;
    }
    
    .exit-button:hover {
        background-color: #f85149;
    }
    
    /* Difficulty-specific styling */
    .difficulty-easy .tile {
        background-color: #21262d;
    }
    
    .difficulty-normal .tile {
        background-color: #1c2128;
    }
    
    .difficulty-hard .tile {
        background-color: #101418;
    }
</style> 