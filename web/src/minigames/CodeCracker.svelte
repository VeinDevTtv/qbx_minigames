<script lang="ts">
    import { onMount, createEventDispatcher } from 'svelte';
    import { CountdownTimer, playSound, getRandomInt } from '../utils';
    import type { CodeCrackerConfig } from '../types';
    
    export let config: CodeCrackerConfig;
    
    const dispatch = createEventDispatcher<{
        complete: { success: boolean; data: any };
        exit: void;
    }>();
    
    // Game state
    let gameState: 'idle' | 'playing' | 'success' | 'failure' = 'idle';
    let timeLeft = config.duration;
    let timer: CountdownTimer;
    let currentAttempt = 0;
    let attempts: string[][] = [];
    let feedback: { correct: number; misplaced: number }[] = [];
    let secretCode: string[] = [];
    let currentGuess: string[] = [];
    let selectedPosition = 0;
    
    // Color options for the code
    const colorOptions = [
        '#FF5252', // Red
        '#4CAF50', // Green
        '#2196F3', // Blue
        '#FFC107', // Yellow
        '#9C27B0', // Purple
        '#FF9800', // Orange
        '#00BCD4', // Cyan
        '#607D8B'  // Blue Grey
    ];
    
    // Initialize game
    onMount(() => {
        generateSecretCode();
        resetGame();
        
        timer = new CountdownTimer(
            config.duration,
            (remaining) => {
                timeLeft = remaining;
            },
            () => {
                handleGameOver(false);
            }
        );
        
        startGame();
        
        return () => {
            if (timer) timer.stop();
        };
    });
    
    function generateSecretCode() {
        secretCode = [];
        // Generate secret code
        for (let i = 0; i < config.codeLength; i++) {
            const randomIndex = getRandomInt(0, colorOptions.length - 1);
            secretCode.push(colorOptions[randomIndex]);
        }
    }
    
    function resetGame() {
        attempts = Array(config.attempts).fill(null).map(() => 
            Array(config.codeLength).fill(null)
        );
        
        feedback = Array(config.attempts).fill(null).map(() => ({
            correct: 0,
            misplaced: 0
        }));
        
        currentGuess = Array(config.codeLength).fill(null);
        currentAttempt = 0;
        selectedPosition = 0;
    }
    
    function startGame() {
        gameState = 'playing';
        timer.start();
        playSound('start', 0.7, config.soundEnabled);
    }
    
    function selectPosition(position: number) {
        if (gameState !== 'playing') return;
        
        selectedPosition = position;
        playSound('beep', 0.3, config.soundEnabled);
    }
    
    function selectColor(color: string) {
        if (gameState !== 'playing') return;
        
        currentGuess[selectedPosition] = color;
        
        // Auto advance to next position
        if (selectedPosition < config.codeLength - 1) {
            selectedPosition++;
        }
        
        playSound('correct', 0.3, config.soundEnabled);
    }
    
    function submitGuess() {
        if (gameState !== 'playing') return;
        
        // Check if all positions are filled
        if (currentGuess.includes(null)) {
            playSound('error', 0.5, config.soundEnabled);
            return;
        }
        
        // Copy current guess to attempts
        attempts[currentAttempt] = [...currentGuess];
        
        // Calculate feedback
        const result = checkGuess(currentGuess, secretCode);
        feedback[currentAttempt] = result;
        
        // Check if won
        if (result.correct === config.codeLength) {
            handleGameOver(true);
            return;
        }
        
        // Check if out of attempts
        if (currentAttempt >= config.attempts - 1) {
            handleGameOver(false);
            return;
        }
        
        // Move to next attempt
        currentAttempt++;
        currentGuess = Array(config.codeLength).fill(null);
        selectedPosition = 0;
        
        playSound('phase_change', 0.5, config.soundEnabled);
    }
    
    function checkGuess(guess: string[], code: string[]): { correct: number; misplaced: number } {
        let correct = 0;
        let misplaced = 0;
        
        // Make copies to avoid modifying originals
        const guessCopy = [...guess];
        const codeCopy = [...code];
        
        // Check for correct positions
        for (let i = 0; i < config.codeLength; i++) {
            if (guessCopy[i] === codeCopy[i]) {
                correct++;
                guessCopy[i] = null;
                codeCopy[i] = null;
            }
        }
        
        // Check for misplaced colors
        for (let i = 0; i < config.codeLength; i++) {
            if (guessCopy[i] !== null) {
                const index = codeCopy.findIndex(c => c === guessCopy[i]);
                if (index !== -1) {
                    misplaced++;
                    codeCopy[index] = null;
                }
            }
        }
        
        return { correct, misplaced };
    }
    
    function handleGameOver(success: boolean) {
        timer.stop();
        gameState = success ? 'success' : 'failure';
        
        // Play success or failure sound
        playSound(success ? 'success' : 'failure', 0.5, config.soundEnabled);
        
        // Dispatch result after a short delay
        setTimeout(() => {
            dispatch('complete', {
                success,
                data: {
                    timeRemaining: timeLeft,
                    attempts: currentAttempt + 1,
                    secretCode: secretCode
                }
            });
        }, 2000);
    }
    
    function exit() {
        if (timer) timer.stop();
        dispatch('exit');
    }
    
    // Format time display
    $: timeDisplay = (timeLeft / 1000).toFixed(1);
    $: attemptsLeft = config.attempts - currentAttempt;
</script>

<div class="code-cracker">
    <div class="header">
        <div class="timer">Time: {timeDisplay}s</div>
        <div class="attempts">Attempts: {attemptsLeft}</div>
    </div>
    
    <div class="game-board">
        <!-- Previous attempts -->
        {#each attempts.slice(0, currentAttempt) as attempt, index}
            <div class="attempt">
                <div class="pegs">
                    {#each attempt as color, i}
                        <div class="peg" style="background-color: {color}"></div>
                    {/each}
                </div>
                
                <div class="feedback">
                    <div class="feedback-text">
                        <span class="correct">{feedback[index].correct} ✓</span>
                        <span class="misplaced">{feedback[index].misplaced} ◎</span>
                    </div>
                </div>
            </div>
        {/each}
        
        <!-- Current attempt -->
        {#if gameState === 'playing'}
            <div class="attempt current">
                <div class="pegs">
                    {#each currentGuess as color, i}
                        <div 
                            class="peg {selectedPosition === i ? 'selected' : ''} {color ? '' : 'empty'}" 
                            style={color ? `background-color: ${color}` : ''}
                            on:click={() => selectPosition(i)}
                        ></div>
                    {/each}
                </div>
                
                <div class="controls">
                    <button class="submit-btn" on:click={submitGuess}>Submit</button>
                </div>
            </div>
        {/if}
        
        <!-- Future attempts (placeholders) -->
        {#each attempts.slice(currentAttempt + 1) as attempt, index}
            <div class="attempt future">
                <div class="pegs">
                    {#each Array(config.codeLength).fill(null) as _, i}
                        <div class="peg empty"></div>
                    {/each}
                </div>
            </div>
        {/each}
    </div>
    
    <!-- Color palette -->
    {#if gameState === 'playing'}
        <div class="color-palette">
            {#each colorOptions as color}
                <div 
                    class="color-option" 
                    style="background-color: {color}" 
                    on:click={() => selectColor(color)}
                ></div>
            {/each}
        </div>
    {/if}
    
    <!-- Game over state -->
    {#if gameState === 'success' || gameState === 'failure'}
        <div class="game-over">
            {#if gameState === 'success'}
                <h2 class="success-message">Code Cracked!</h2>
            {:else}
                <h2 class="failure-message">Code Not Cracked</h2>
                <div class="secret-code">
                    <span>The secret code was:</span>
                    <div class="pegs">
                        {#each secretCode as color}
                            <div class="peg" style="background-color: {color}"></div>
                        {/each}
                    </div>
                </div>
            {/if}
        </div>
    {/if}
    
    <div class="footer">
        <button class="exit-btn" on:click={exit}>Exit</button>
    </div>
</div>

<style>
    .code-cracker {
        width: 100%;
        height: 100%;
        display: flex;
        flex-direction: column;
        padding: 20px;
        color: white;
        font-family: 'Roboto', sans-serif;
    }
    
    .header {
        display: flex;
        justify-content: space-between;
        margin-bottom: 20px;
    }
    
    .timer, .attempts {
        font-size: 1.2rem;
        font-weight: bold;
        padding: 8px 16px;
        border-radius: 4px;
        background-color: rgba(0, 0, 0, 0.5);
    }
    
    .game-board {
        flex: 1;
        display: flex;
        flex-direction: column;
        gap: 10px;
        overflow-y: auto;
        padding: 0 10px;
    }
    
    .attempt {
        display: flex;
        align-items: center;
        padding: 10px;
        border-radius: 8px;
        background-color: rgba(255, 255, 255, 0.1);
    }
    
    .attempt.current {
        background-color: rgba(66, 133, 244, 0.2);
        border: 2px solid #4285F4;
    }
    
    .attempt.future {
        opacity: 0.5;
    }
    
    .pegs {
        display: flex;
        gap: 10px;
    }
    
    .peg {
        width: 40px;
        height: 40px;
        border-radius: 50%;
        box-shadow: 0 2px 5px rgba(0, 0, 0, 0.3);
        transition: all 0.2s ease;
    }
    
    .peg.empty {
        background-color: rgba(255, 255, 255, 0.1);
        border: 2px dashed rgba(255, 255, 255, 0.3);
    }
    
    .peg.selected {
        transform: scale(1.15);
        box-shadow: 0 0 10px white;
    }
    
    .feedback {
        margin-left: auto;
        padding: 0 10px;
    }
    
    .feedback-text {
        font-size: 1rem;
        display: flex;
        gap: 10px;
    }
    
    .correct {
        color: #4CAF50;
    }
    
    .misplaced {
        color: #FFC107;
    }
    
    .controls {
        margin-left: auto;
    }
    
    .submit-btn {
        padding: 8px 16px;
        background-color: #4CAF50;
        color: white;
        border: none;
        border-radius: 4px;
        cursor: pointer;
        font-size: 16px;
        transition: all 0.2s ease;
    }
    
    .submit-btn:hover {
        background-color: #388E3C;
        transform: scale(1.05);
    }
    
    .color-palette {
        display: flex;
        justify-content: center;
        gap: 15px;
        padding: 20px;
        background-color: rgba(0, 0, 0, 0.3);
        border-radius: 8px;
        margin-top: 20px;
    }
    
    .color-option {
        width: 50px;
        height: 50px;
        border-radius: 50%;
        cursor: pointer;
        transition: all 0.2s ease;
        box-shadow: 0 2px 10px rgba(0, 0, 0, 0.3);
    }
    
    .color-option:hover {
        transform: scale(1.2);
        box-shadow: 0 0 15px white;
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
        z-index: 10;
    }
    
    .success-message {
        color: #4CAF50;
        font-size: 2rem;
    }
    
    .failure-message {
        color: #FF5252;
        font-size: 2rem;
    }
    
    .secret-code {
        margin-top: 20px;
        display: flex;
        flex-direction: column;
        align-items: center;
        gap: 10px;
    }
    
    .footer {
        margin-top: 20px;
        display: flex;
        justify-content: center;
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
</style> 