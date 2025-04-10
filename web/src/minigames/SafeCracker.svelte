<script lang="ts">
    import { onMount, createEventDispatcher } from 'svelte';
    import { CountdownTimer, playSound, getRandomInt } from '../utils';
    import type { SafeCrackerConfig } from '../types';
    
    export let config: SafeCrackerConfig;
    
    const dispatch = createEventDispatcher<{
        complete: { success: boolean; data: any };
        exit: void;
    }>();
    
    // Game constants
    const TOTAL_DEGREES = 360;
    const MIN_ZONE_SIZE = 10; // Minimum size of a correct zone in degrees
    const MAX_ZONE_SIZE = 30; // Maximum size of a correct zone in degrees
    
    // Game state
    let gameState: 'idle' | 'playing' | 'success' | 'failure' = 'idle';
    let timeLeft = config.duration;
    let timer: CountdownTimer;
    let currentRotation = 0;
    let rotationCount = 0;
    let maxRotationCount = config.maxRotations;
    let isDragging = false;
    let prevAngle = 0;
    let dialElement: HTMLElement | null = null;
    let successZones: { start: number; end: number; found: boolean }[] = [];
    let foundZonesCount = 0;
    let dialHistory: number[] = [];
    
    // Visual feedback
    let dialColor = '#444';
    let feedback = '';
    let feedbackColor = 'white';
    let showVisualFeedback = false;
    let visualFeedbackTimeout: number | null = null;
    
    // Initialize game
    onMount(() => {
        dialElement = document.getElementById('dial');
        generateSuccessZones();
        
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
        
        // Add event listeners for mouse/touch
        if (dialElement) {
            dialElement.addEventListener('mousedown', startDrag);
            document.addEventListener('mousemove', drag);
            document.addEventListener('mouseup', endDrag);
            
            // Touch events
            dialElement.addEventListener('touchstart', handleTouchStart);
            document.addEventListener('touchmove', handleTouchMove);
            document.addEventListener('touchend', handleTouchEnd);
        }
        
        return () => {
            // Clean up event listeners
            if (dialElement) {
                dialElement.removeEventListener('mousedown', startDrag);
                document.removeEventListener('mousemove', drag);
                document.removeEventListener('mouseup', endDrag);
                
                dialElement.removeEventListener('touchstart', handleTouchStart);
                document.removeEventListener('touchmove', handleTouchMove);
                document.removeEventListener('touchend', handleTouchEnd);
            }
            
            if (timer) timer.stop();
            if (visualFeedbackTimeout) clearTimeout(visualFeedbackTimeout);
        };
    });
    
    function generateSuccessZones() {
        successZones = [];
        
        // Generate random zones that don't overlap
        for (let i = 0; i < config.zones; i++) {
            let zoneSize = getRandomInt(MIN_ZONE_SIZE, MAX_ZONE_SIZE);
            let startPosition;
            let overlap;
            
            // Try to find a non-overlapping position
            do {
                overlap = false;
                startPosition = getRandomInt(0, TOTAL_DEGREES - zoneSize);
                
                for (const zone of successZones) {
                    if (
                        (startPosition >= zone.start && startPosition <= zone.end) ||
                        (startPosition + zoneSize >= zone.start && startPosition + zoneSize <= zone.end) ||
                        (zone.start >= startPosition && zone.start <= startPosition + zoneSize)
                    ) {
                        overlap = true;
                        break;
                    }
                }
            } while (overlap);
            
            successZones.push({
                start: startPosition,
                end: startPosition + zoneSize,
                found: false
            });
        }
    }
    
    function startGame() {
        gameState = 'playing';
        timer.start();
        playSound('start', 0.7, config.soundEnabled);
    }
    
    function startDrag(e: MouseEvent) {
        if (gameState !== 'playing') return;
        
        e.preventDefault();
        isDragging = true;
        
        const dialRect = dialElement?.getBoundingClientRect();
        if (!dialRect) return;
        
        const centerX = dialRect.left + dialRect.width / 2;
        const centerY = dialRect.top + dialRect.height / 2;
        
        prevAngle = calculateAngle(e.clientX, e.clientY, centerX, centerY);
    }
    
    function drag(e: MouseEvent) {
        if (!isDragging || gameState !== 'playing') return;
        
        const dialRect = dialElement?.getBoundingClientRect();
        if (!dialRect) return;
        
        const centerX = dialRect.left + dialRect.width / 2;
        const centerY = dialRect.top + dialRect.height / 2;
        
        const currentAngle = calculateAngle(e.clientX, e.clientY, centerX, centerY);
        const angleDiff = currentAngle - prevAngle;
        
        // Handle angle wrap-around
        let delta = angleDiff;
        if (angleDiff > 180) {
            delta = angleDiff - 360;
        } else if (angleDiff < -180) {
            delta = angleDiff + 360;
        }
        
        rotateDial(delta);
        prevAngle = currentAngle;
    }
    
    function endDrag() {
        isDragging = false;
    }
    
    // Touch event handlers
    function handleTouchStart(e: TouchEvent) {
        if (e.touches.length === 1) {
            const touch = e.touches[0];
            const mouseEvent = new MouseEvent('mousedown', {
                clientX: touch.clientX,
                clientY: touch.clientY
            });
            startDrag(mouseEvent);
        }
    }
    
    function handleTouchMove(e: TouchEvent) {
        if (e.touches.length === 1) {
            e.preventDefault(); // Prevent scrolling
            const touch = e.touches[0];
            const mouseEvent = new MouseEvent('mousemove', {
                clientX: touch.clientX,
                clientY: touch.clientY
            });
            drag(mouseEvent);
        }
    }
    
    function handleTouchEnd() {
        endDrag();
    }
    
    function calculateAngle(x: number, y: number, centerX: number, centerY: number) {
        const deltaX = x - centerX;
        const deltaY = y - centerY;
        
        // Calculate angle in degrees
        let angle = Math.atan2(deltaY, deltaX) * (180 / Math.PI);
        
        // Convert to 0-360 range
        if (angle < 0) {
            angle += 360;
        }
        
        return angle;
    }
    
    function rotateDial(delta: number) {
        // Update the current rotation
        currentRotation = (currentRotation + delta) % 360;
        if (currentRotation < 0) {
            currentRotation += 360;
        }
        
        // Store rotation in history (for visual trail)
        dialHistory.push(currentRotation);
        if (dialHistory.length > 100) {
            dialHistory.shift(); // Keep history to reasonable size
        }
        
        // Check if we're in a success zone
        checkSuccessZones();
    }
    
    function checkSuccessZones() {
        for (let i = 0; i < successZones.length; i++) {
            const zone = successZones[i];
            
            if (!zone.found && 
                currentRotation >= zone.start && 
                currentRotation <= zone.end) {
                
                // Found a zone!
                zone.found = true;
                foundZonesCount++;
                
                playSound('correct', 0.5, config.soundEnabled);
                showFeedback(`Found zone ${foundZonesCount}/${config.zones}!`, '#4CAF50');
                
                // Vibrate if available
                if (navigator.vibrate) {
                    navigator.vibrate(100);
                }
                
                // Check if all zones found
                if (foundZonesCount === config.zones) {
                    handleGameOver(true);
                    return;
                }
                
                // Increment rotation count after finding a zone
                rotationCount++;
                if (rotationCount >= maxRotationCount) {
                    handleGameOver(false);
                    return;
                }
                
                // Change dial color for feedback
                dialColor = '#4CAF50';
                setTimeout(() => {
                    dialColor = '#444';
                }, 300);
            }
        }
    }
    
    function showFeedback(message: string, color: string) {
        feedback = message;
        feedbackColor = color;
        showVisualFeedback = true;
        
        if (visualFeedbackTimeout) {
            clearTimeout(visualFeedbackTimeout);
        }
        
        visualFeedbackTimeout = setTimeout(() => {
            showVisualFeedback = false;
        }, 2000);
    }
    
    function handleGameOver(success: boolean) {
        timer.stop();
        gameState = success ? 'success' : 'failure';
        
        // Play success or failure sound
        playSound(success ? 'success' : 'failure', 0.5, config.soundEnabled);
        
        // Show unFound zones if failed
        if (!success) {
            showUnfoundZones();
        }
        
        // Dispatch result after a short delay
        setTimeout(() => {
            dispatch('complete', {
                success,
                data: {
                    timeRemaining: timeLeft,
                    zonesFound: foundZonesCount,
                    totalZones: config.zones
                }
            });
        }, 2000);
    }
    
    function showUnfoundZones() {
        // Highlight unfound zones for player to see
        for (const zone of successZones) {
            if (!zone.found) {
                zone.found = true; // Just to highlight them
            }
        }
    }
    
    function exit() {
        if (timer) timer.stop();
        dispatch('exit');
    }
    
    // Format time display
    $: timeDisplay = (timeLeft / 1000).toFixed(1);
    $: rotationsLeft = maxRotationCount - rotationCount;
    $: rotationStyle = `transform: rotate(${currentRotation}deg)`;
</script>

<div class="safe-cracker">
    <div class="header">
        <div class="timer">Time: {timeDisplay}s</div>
        <div class="rotations">Rotations: {rotationsLeft}</div>
        <div class="zones">Zones: {foundZonesCount}/{config.zones}</div>
    </div>
    
    <div class="game-area">
        <div class="safe">
            <div class="dial-container">
                <div class="dial-markings">
                    {#each Array(36) as _, i}
                        <div class="dial-mark" style="transform: rotate({i * 10}deg) translateY(-120px)">
                            {i % 9 === 0 ? i * 10 : ''}
                        </div>
                    {/each}
                </div>
                
                <div class="dial" id="dial" style="{rotationStyle}; background-color: {dialColor}">
                    <div class="dial-grip"></div>
                    <div class="dial-grip" style="transform: rotate(120deg)"></div>
                    <div class="dial-grip" style="transform: rotate(240deg)"></div>
                </div>
                
                <div class="dial-center"></div>
                
                <div class="dial-indicator"></div>
            </div>
        </div>
        
        <!-- Visual trail (last positions) -->
        <div class="dial-trail">
            {#each dialHistory.slice(-20) as position, i}
                <div 
                    class="trail-mark" 
                    style="
                        opacity: {(i + 1) / 20}; 
                        transform: rotate({position}deg) translateY(-145px);
                    "
                ></div>
            {/each}
        </div>
        
        <!-- Success zone indicators (only visible when found or game over) -->
        {#if gameState === 'success' || gameState === 'failure'}
            <div class="success-zones">
                {#each successZones as zone}
                    <div 
                        class="zone-indicator {zone.found ? 'found' : ''}" 
                        style="
                            transform: rotate({(zone.start + zone.end) / 2}deg) translateY(-145px);
                            width: {zone.end - zone.start}px;
                        "
                    ></div>
                {/each}
            </div>
        {/if}
        
        <!-- Visual feedback -->
        {#if showVisualFeedback}
            <div class="visual-feedback" style="color: {feedbackColor}">
                {feedback}
            </div>
        {/if}
    </div>
    
    <!-- Game over state -->
    {#if gameState === 'success' || gameState === 'failure'}
        <div class="game-over">
            {#if gameState === 'success'}
                <h2 class="success-message">Safe Cracked!</h2>
            {:else}
                <h2 class="failure-message">Safe Not Cracked</h2>
                <p>You found {foundZonesCount} out of {config.zones} zones.</p>
            {/if}
        </div>
    {/if}
    
    <div class="instructions">
        <p>Rotate the dial to find the {config.zones} correct positions</p>
        <p>You have {maxRotationCount} full rotations to find all zones</p>
    </div>
    
    <div class="footer">
        <button class="exit-btn" on:click={exit}>Exit</button>
    </div>
</div>

<style>
    .safe-cracker {
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
    
    .timer, .rotations, .zones {
        font-size: 1.2rem;
        font-weight: bold;
        padding: 8px 16px;
        border-radius: 4px;
        background-color: rgba(0, 0, 0, 0.5);
    }
    
    .game-area {
        position: relative;
        display: flex;
        flex-direction: column;
        align-items: center;
        justify-content: center;
        width: 100%;
        flex: 1;
    }
    
    .safe {
        width: 400px;
        height: 400px;
        background-color: #222;
        border-radius: 10px;
        display: flex;
        align-items: center;
        justify-content: center;
        box-shadow: 0 0 40px rgba(0, 0, 0, 0.8);
        border: 8px solid #333;
    }
    
    .dial-container {
        position: relative;
        width: 300px;
        height: 300px;
        border-radius: 50%;
        background-color: #333;
        display: flex;
        align-items: center;
        justify-content: center;
        box-shadow: inset 0 0 20px rgba(0, 0, 0, 0.8);
    }
    
    .dial {
        position: relative;
        width: 200px;
        height: 200px;
        border-radius: 50%;
        background-color: #444;
        cursor: grab;
        box-shadow: 0 0 15px rgba(0, 0, 0, 0.8);
        transition: background-color 0.3s ease;
        user-select: none;
        transform-origin: center;
    }
    
    .dial:active {
        cursor: grabbing;
    }
    
    .dial-grip {
        position: absolute;
        width: 15px;
        height: 80px;
        background-color: #222;
        top: 20px;
        left: calc(50% - 7.5px);
        border-radius: 5px;
    }
    
    .dial-center {
        position: absolute;
        width: 30px;
        height: 30px;
        border-radius: 50%;
        background-color: #222;
        box-shadow: inset 0 0 5px rgba(255, 255, 255, 0.3);
        z-index: 10;
    }
    
    .dial-markings {
        position: absolute;
        width: 100%;
        height: 100%;
        border-radius: 50%;
    }
    
    .dial-mark {
        position: absolute;
        width: 2px;
        height: 10px;
        background-color: white;
        top: 50%;
        left: 50%;
        transform-origin: center;
    }
    
    .dial-mark:nth-child(9n+1) {
        height: 20px;
        width: 3px;
        font-weight: bold;
    }
    
    .dial-indicator {
        position: absolute;
        width: 0;
        height: 0;
        top: 15px;
        border-left: 10px solid transparent;
        border-right: 10px solid transparent;
        border-bottom: 15px solid red;
    }
    
    .dial-trail {
        position: absolute;
        width: 300px;
        height: 300px;
        pointer-events: none;
    }
    
    .trail-mark {
        position: absolute;
        width: 6px;
        height: 6px;
        background-color: rgba(255, 255, 255, 0.7);
        border-radius: 50%;
        top: 50%;
        left: 50%;
        transform-origin: center;
    }
    
    .success-zones {
        position: absolute;
        width: 300px;
        height: 300px;
        pointer-events: none;
    }
    
    .zone-indicator {
        position: absolute;
        height: 15px;
        background-color: rgba(76, 175, 80, 0.7);
        border-radius: 5px;
        top: 50%;
        left: 50%;
        transform-origin: center;
    }
    
    .zone-indicator.found {
        background-color: rgba(76, 175, 80, 0.7);
    }
    
    .visual-feedback {
        position: absolute;
        top: 10px;
        font-size: 1.5rem;
        font-weight: bold;
        text-shadow: 0 0 10px black;
        animation: fadeIn 0.3s ease-in-out;
    }
    
    .instructions {
        margin-top: 20px;
        text-align: center;
        color: rgba(255, 255, 255, 0.7);
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
    
    @keyframes fadeIn {
        from { opacity: 0; }
        to { opacity: 1; }
    }
</style> 