<script lang="ts">
    import { onMount, createEventDispatcher } from 'svelte';
    import { CountdownTimer, playSound, getRandomInt, shuffleArray } from '../utils';
    import type { ThermiteConfig } from '../types';
    
    export let config: ThermiteConfig;
    
    const dispatch = createEventDispatcher<{
        complete: { success: boolean; data: any };
        exit: void;
    }>();
    
    // Game state
    let gameState: 'idle' | 'memorize' | 'solving' | 'success' | 'failure' = 'idle';
    let timeLeft = config.duration;
    let timer: CountdownTimer;
    let grid: boolean[][] = [];
    let playerGrid: boolean[][] = [];
    let targetCells: {row: number, col: number}[] = [];
    let selectedCount = 0;
    let incorrectSelections = 0;
    
    // Animations and effects
    let showExplosion = false;
    let showSparks: {row: number, col: number, active: boolean}[] = [];
    
    // Initialize game
    onMount(() => {
        // Initialize grid with all cells set to false (not active)
        resetGrids();
        generatePattern();
        
        timer = new CountdownTimer(
            config.displayTime, // First use display time for memorization phase
            (remaining) => {
                timeLeft = remaining;
            },
            () => {
                if (gameState === 'memorize') {
                    startSolvingPhase();
                } else if (gameState === 'solving') {
                    handleGameOver(false);
                }
            }
        );
        
        startGame();
        
        return () => {
            if (timer) timer.stop();
        };
    });
    
    function resetGrids() {
        grid = Array(config.gridSize).fill(null).map(() => 
            Array(config.gridSize).fill(false)
        );
        
        playerGrid = Array(config.gridSize).fill(null).map(() => 
            Array(config.gridSize).fill(false)
        );
        
        targetCells = [];
        selectedCount = 0;
        incorrectSelections = 0;
    }
    
    function generatePattern() {
        // Generate random pattern of active cells
        const totalCells = config.gridSize * config.gridSize;
        const maxTargets = Math.min(config.targetCount, totalCells);
        
        // Generate all possible cell positions
        const allPositions = [];
        for (let row = 0; row < config.gridSize; row++) {
            for (let col = 0; col < config.gridSize; col++) {
                allPositions.push({row, col});
            }
        }
        
        // Shuffle and take the first N positions
        const shuffledPositions = shuffleArray(allPositions);
        targetCells = shuffledPositions.slice(0, maxTargets);
        
        // Set the cells in the grid
        for (const {row, col} of targetCells) {
            grid[row][col] = true;
        }
    }
    
    function startGame() {
        gameState = 'memorize';
        playSound('start', 0.7, config.soundEnabled);
        
        // Start timer for memorization phase
        timer.start();
    }
    
    function startSolvingPhase() {
        // Hide the pattern
        gameState = 'solving';
        
        // Reset and start timer for solving phase
        timer.stop();
        timer = new CountdownTimer(
            config.duration,
            (remaining) => {
                timeLeft = remaining;
            },
            () => {
                handleGameOver(false);
            }
        );
        timer.start();
        
        playSound('phase_change', 0.5, config.soundEnabled);
    }
    
    function handleCellClick(row: number, col: number) {
        if (gameState !== 'solving') return;
        
        if (playerGrid[row][col]) {
            // Already selected, do nothing
            return;
        }
        
        // Mark cell as selected
        playerGrid[row][col] = true;
        
        // Check if the selection is correct
        const isCorrect = grid[row][col];
        
        if (isCorrect) {
            selectedCount++;
            playSound('correct', 0.5, config.soundEnabled);
            createSparks(row, col, true);
            
            // Check if all targets have been found
            if (selectedCount === targetCells.length) {
                handleGameOver(true);
            }
        } else {
            incorrectSelections++;
            playSound('error', 0.5, config.soundEnabled);
            createSparks(row, col, false);
            
            // Check if max incorrect selections reached (fail condition)
            if (incorrectSelections >= 3) {
                handleGameOver(false);
            }
        }
    }
    
    function createSparks(row: number, col: number, isCorrect: boolean) {
        // Add spark effect at the clicked position
        showSparks = [...showSparks, {row, col, active: true}];
        
        // Remove spark after animation
        setTimeout(() => {
            showSparks = showSparks.filter(s => !(s.row === row && s.col === col));
        }, 800);
    }
    
    function handleGameOver(success: boolean) {
        timer.stop();
        gameState = success ? 'success' : 'failure';
        
        // Play success or failure sound
        playSound(success ? 'success' : 'failure', 0.5, config.soundEnabled);
        
        // Show explosion effect if failed
        if (!success) {
            showExplosion = true;
            
            // Show the correct pattern
            playerGrid = JSON.parse(JSON.stringify(grid));
        }
        
        // Dispatch result after a short delay
        setTimeout(() => {
            dispatch('complete', {
                success,
                data: {
                    timeRemaining: timeLeft,
                    correctSelections: selectedCount,
                    incorrectSelections: incorrectSelections,
                    totalTargets: targetCells.length
                }
            });
        }, success ? 1500 : 2500);
    }
    
    function exit() {
        if (timer) timer.stop();
        dispatch('exit');
    }
    
    // Format time display
    $: timeDisplay = (timeLeft / 1000).toFixed(1);
    $: cellSize = Math.min(500 / config.gridSize, 80);
    $: gapSize = Math.max(6 - config.gridSize, 2);
    $: gridStyle = `grid-template-columns: repeat(${config.gridSize}, ${cellSize}px); gap: ${gapSize}px;`;
</script>

<div class="thermite-game">
    <div class="header">
        <div class="timer">Time: {timeDisplay}s</div>
        <div class="phase">
            {#if gameState === 'memorize'}
                Phase: Memorize Pattern
            {:else if gameState === 'solving'}
                Phase: Recall Pattern {selectedCount}/{targetCells.length}
            {:else}
                Phase: {gameState.charAt(0).toUpperCase() + gameState.slice(1)}
            {/if}
        </div>
    </div>
    
    <div class="game-container">
        <div class="circuit-board">
            <div class="grid" style={gridStyle}>
                {#each grid as row, rowIndex}
                    {#each row as cell, colIndex}
                        <div 
                            class="cell"
                            class:active={gameState === 'memorize' && cell}
                            class:selected={playerGrid[rowIndex][colIndex]}
                            class:correct={gameState !== 'solving' && cell && playerGrid[rowIndex][colIndex]}
                            class:incorrect={gameState !== 'solving' && !cell && playerGrid[rowIndex][colIndex]}
                            on:click={() => handleCellClick(rowIndex, colIndex)}
                        >
                            <!-- Spark effect -->
                            {#each showSparks.filter(s => s.row === rowIndex && s.col === colIndex) as spark}
                                <div class="spark {spark.active ? 'correct-spark' : 'incorrect-spark'}"></div>
                            {/each}
                        </div>
                    {/each}
                {/each}
            </div>
            
            {#if showExplosion}
                <div class="explosion"></div>
            {/if}
        </div>
    </div>
    
    <!-- Instructions based on game state -->
    <div class="instructions">
        {#if gameState === 'memorize'}
            <p>Memorize the highlighted pattern!</p>
        {:else if gameState === 'solving'}
            <p>Select the cells that were highlighted in the pattern</p>
            <p class="warning">{3 - incorrectSelections} incorrect selections remaining</p>
        {/if}
    </div>
    
    <!-- Game over state -->
    {#if gameState === 'success' || gameState === 'failure'}
        <div class="game-over">
            {#if gameState === 'success'}
                <h2 class="success-message">Hack Successful!</h2>
            {:else}
                <h2 class="failure-message">Hack Failed</h2>
                <p>The circuit has been damaged</p>
            {/if}
        </div>
    {/if}
    
    <div class="footer">
        <button class="exit-btn" on:click={exit}>Exit</button>
    </div>
</div>

<style>
    .thermite-game {
        width: 100%;
        height: 100%;
        display: flex;
        flex-direction: column;
        align-items: center;
        padding: 20px;
        color: white;
        font-family: 'Roboto', sans-serif;
    }
    
    .header {
        display: flex;
        justify-content: space-between;
        width: 100%;
        margin-bottom: 20px;
    }
    
    .timer, .phase {
        font-size: 1.2rem;
        font-weight: bold;
        padding: 8px 16px;
        border-radius: 4px;
        background-color: rgba(0, 0, 0, 0.5);
    }
    
    .game-container {
        flex: 1;
        display: flex;
        align-items: center;
        justify-content: center;
        position: relative;
    }
    
    .circuit-board {
        position: relative;
        background-color: #1a1a1a;
        border-radius: 10px;
        padding: 20px;
        box-shadow: 0 0 30px rgba(0, 100, 255, 0.3);
        border: 2px solid #333;
        overflow: hidden;
    }
    
    .grid {
        display: grid;
        grid-template-columns: repeat(6, 80px);
        gap: 6px;
    }
    
    .cell {
        position: relative;
        aspect-ratio: 1 / 1;
        background-color: #333;
        border-radius: 4px;
        cursor: pointer;
        transition: all 0.2s ease;
        overflow: hidden;
        display: flex;
        align-items: center;
        justify-content: center;
        box-shadow: inset 0 0 5px rgba(0, 0, 0, 0.5);
    }
    
    .cell:hover {
        transform: scale(1.03);
        box-shadow: 0 0 10px rgba(0, 150, 255, 0.5);
    }
    
    .cell.active {
        background-color: #4caf50;
        box-shadow: 0 0 15px rgba(76, 175, 80, 0.7);
        animation: pulse 1.5s infinite;
    }
    
    .cell.selected {
        background-color: #2196F3;
        box-shadow: 0 0 10px rgba(33, 150, 243, 0.7);
    }
    
    .cell.correct {
        background-color: #4caf50;
        box-shadow: 0 0 10px rgba(76, 175, 80, 0.7);
    }
    
    .cell.incorrect {
        background-color: #f44336;
        box-shadow: 0 0 10px rgba(244, 67, 54, 0.7);
    }
    
    .spark {
        position: absolute;
        width: 100%;
        height: 100%;
        border-radius: 4px;
        z-index: 10;
    }
    
    .correct-spark {
        background: radial-gradient(circle, rgba(76, 175, 80, 0.8) 0%, rgba(76, 175, 80, 0) 70%);
        animation: sparkle 0.8s ease-out;
    }
    
    .incorrect-spark {
        background: radial-gradient(circle, rgba(244, 67, 54, 0.8) 0%, rgba(244, 67, 54, 0) 70%);
        animation: sparkle 0.8s ease-out;
    }
    
    .explosion {
        position: absolute;
        top: 0;
        left: 0;
        width: 100%;
        height: 100%;
        background: radial-gradient(circle, rgba(255, 100, 50, 0.9) 0%, rgba(255, 50, 0, 0) 70%);
        animation: explode 2s ease-out;
        z-index: 20;
    }
    
    .instructions {
        margin-top: 20px;
        text-align: center;
    }
    
    .warning {
        color: #f44336;
        font-weight: bold;
    }
    
    .footer {
        margin-top: 20px;
    }
    
    .exit-btn {
        padding: 8px 16px;
        background-color: #f44336;
        color: white;
        border: none;
        border-radius: 4px;
        cursor: pointer;
        font-size: 16px;
    }
    
    .game-over {
        position: absolute;
        top: 50%;
        left: 50%;
        transform: translate(-50%, -50%);
        background-color: rgba(0, 0, 0, 0.8);
        padding: 30px;
        border-radius: 10px;
        text-align: center;
        z-index: 30;
    }
    
    .success-message {
        color: #4CAF50;
        font-size: 2rem;
    }
    
    .failure-message {
        color: #FF5252;
        font-size: 2rem;
    }
    
    @keyframes pulse {
        0% { transform: scale(1); }
        50% { transform: scale(1.05); }
        100% { transform: scale(1); }
    }
    
    @keyframes sparkle {
        0% { opacity: 1; transform: scale(0.3); }
        100% { opacity: 0; transform: scale(1.5); }
    }
    
    @keyframes explode {
        0% { opacity: 0; transform: scale(0.1); }
        30% { opacity: 1; transform: scale(1.5); }
        100% { opacity: 0; transform: scale(2); }
    }
</style> 