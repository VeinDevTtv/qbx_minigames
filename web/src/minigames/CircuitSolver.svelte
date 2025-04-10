<script lang="ts">
    import { onMount, createEventDispatcher } from 'svelte';
    import { CountdownTimer, playSound, getRandomInt, createGrid } from '../utils';
    import type { CircuitSolverConfig } from '../types';
    
    export let config: CircuitSolverConfig;
    
    const dispatch = createEventDispatcher<{
        complete: { success: boolean; data: any };
        exit: void;
    }>();
    
    // Circuit piece types
    type PieceType = 'straight' | 'corner' | 'three-way' | 'four-way' | 'empty' | 'source' | 'destination';
    
    // Direction connections
    type Connections = {
        top: boolean;
        right: boolean;
        bottom: boolean;
        left: boolean;
    };
    
    // Piece definition
    type CircuitPiece = {
        type: PieceType;
        rotation: number; // 0, 90, 180, 270 degrees
        connections: Connections;
        powered: boolean;
        fixed: boolean; // If true, cannot be rotated
    };
    
    // Game state
    let gameState: 'idle' | 'playing' | 'success' | 'failure' = 'idle';
    let timeLeft = config.duration;
    let grid: CircuitPiece[][] = [];
    let timer: CountdownTimer;
    let sourcePosition: { row: number; col: number };
    let destinationPosition: { row: number; col: number };
    
    // Piece definitions
    const pieceDefs: Record<PieceType, Connections> = {
        'straight': { top: true, right: false, bottom: true, left: false },
        'corner': { top: true, right: true, bottom: false, left: false },
        'three-way': { top: true, right: true, bottom: true, left: false },
        'four-way': { top: true, right: true, bottom: true, left: true },
        'empty': { top: false, right: false, bottom: false, left: false },
        'source': { top: false, right: true, bottom: false, left: false },
        'destination': { top: false, right: false, bottom: false, left: true }
    };
    
    // Initialize game
    onMount(() => {
        initializeGame();
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
    
    function initializeGame() {
        const size = config.gridSize;
        grid = createGrid(size, size, null);
        
        // Place source and destination
        placeSourceAndDestination(size);
        
        // Fill the grid with circuit pieces
        fillGrid(size);
        
        // Randomize rotations
        randomizeRotations();
    }
    
    function placeSourceAndDestination(size: number) {
        // Randomly decide if source and destination will be on opposite sides horizontally or vertically
        const isHorizontal = Math.random() < 0.5;
        
        if (isHorizontal) {
            // Source on left, destination on right
            const row = getRandomInt(0, size - 1);
            sourcePosition = { row, col: 0 };
            destinationPosition = { row, col: size - 1 };
            
            grid[row][0] = createPiece('source', 0);
            grid[row][size - 1] = createPiece('destination', 0);
        } else {
            // Source on top, destination on bottom
            const col = getRandomInt(0, size - 1);
            sourcePosition = { row: 0, col };
            destinationPosition = { row: size - 1, col };
            
            grid[0][col] = createPiece('source', 90); // Rotate source to point down
            grid[size - 1][col] = createPiece('destination', 270); // Rotate destination to point up
        }
    }
    
    function fillGrid(size: number) {
        // Create a valid path from source to destination
        createValidPath();
        
        // Fill the rest of the grid with random pieces
        for (let row = 0; row < size; row++) {
            for (let col = 0; col < size; col++) {
                if (!grid[row][col]) {
                    const pieceTypes: PieceType[] = ['straight', 'corner', 'three-way', 'four-way', 'empty'];
                    const randomType = pieceTypes[getRandomInt(0, pieceTypes.length - 1)];
                    grid[row][col] = createPiece(randomType, 0);
                }
            }
        }
    }
    
    function createValidPath() {
        // Implement a simple path from source to destination
        let current = { ...sourcePosition };
        const target = { ...destinationPosition };
        const visited = createGrid(grid.length, grid[0].length, false);
        visited[current.row][current.col] = true;
        
        while (current.row !== target.row || current.col !== target.col) {
            const moves = [];
            
            // Try to move towards the destination
            if (current.row < target.row && !visited[current.row + 1][current.col]) {
                moves.push({ row: current.row + 1, col: current.col, dir: 'down' });
            }
            if (current.row > target.row && !visited[current.row - 1][current.col]) {
                moves.push({ row: current.row - 1, col: current.col, dir: 'up' });
            }
            if (current.col < target.col && !visited[current.row][current.col + 1]) {
                moves.push({ row: current.row, col: current.col + 1, dir: 'right' });
            }
            if (current.col > target.col && !visited[current.row][current.col - 1]) {
                moves.push({ row: current.row, col: current.col - 1, dir: 'left' });
            }
            
            // If no direct moves toward destination, try random valid move
            if (moves.length === 0) {
                if (current.row < grid.length - 1 && !visited[current.row + 1][current.col]) {
                    moves.push({ row: current.row + 1, col: current.col, dir: 'down' });
                }
                if (current.row > 0 && !visited[current.row - 1][current.col]) {
                    moves.push({ row: current.row - 1, col: current.col, dir: 'up' });
                }
                if (current.col < grid[0].length - 1 && !visited[current.row][current.col + 1]) {
                    moves.push({ row: current.row, col: current.col + 1, dir: 'right' });
                }
                if (current.col > 0 && !visited[current.row][current.col - 1]) {
                    moves.push({ row: current.row, col: current.col - 1, dir: 'left' });
                }
            }
            
            // If still no moves, break out
            if (moves.length === 0) break;
            
            const move = moves[getRandomInt(0, moves.length - 1)];
            
            // Create appropriate piece at current position (if not already a fixed piece)
            if (!grid[current.row][current.col] || !grid[current.row][current.col].fixed) {
                let pieceType: PieceType;
                let rotation = 0;
                
                // Determine appropriate piece type based on previous and next direction
                if (move.dir === 'right') {
                    pieceType = 'straight';
                    rotation = 90; // horizontal
                } else if (move.dir === 'left') {
                    pieceType = 'straight';
                    rotation = 90; // horizontal
                } else if (move.dir === 'up') {
                    pieceType = 'straight';
                    rotation = 0; // vertical
                } else {
                    pieceType = 'straight';
                    rotation = 0; // vertical
                }
                
                grid[current.row][current.col] = createPiece(pieceType, rotation);
            }
            
            // Move to the next position
            current = { row: move.row, col: move.col };
            visited[current.row][current.col] = true;
        }
    }
    
    function createPiece(type: PieceType, rotation: number): CircuitPiece {
        // Get base connections for the piece type
        const baseConnections = { ...pieceDefs[type] };
        
        // Apply rotation to connections
        const rotatedConnections = rotateConnections(baseConnections, rotation);
        
        return {
            type,
            rotation,
            connections: rotatedConnections,
            powered: type === 'source', // Source piece starts powered
            fixed: type === 'source' || type === 'destination' // Source and destination are fixed
        };
    }
    
    function rotateConnections(connections: Connections, rotation: number): Connections {
        const result = { ...connections };
        
        // Apply rotation
        for (let i = 0; i < rotation / 90; i++) {
            const temp = result.top;
            result.top = result.left;
            result.left = result.bottom;
            result.bottom = result.right;
            result.right = temp;
        }
        
        return result;
    }
    
    function randomizeRotations() {
        for (let row = 0; row < grid.length; row++) {
            for (let col = 0; col < grid[0].length; col++) {
                const piece = grid[row][col];
                if (piece && !piece.fixed) {
                    const rotations = [0, 90, 180, 270];
                    const randomRotation = rotations[getRandomInt(0, 3)];
                    piece.rotation = randomRotation;
                    piece.connections = rotateConnections(pieceDefs[piece.type], randomRotation);
                }
            }
        }
    }
    
    function startGame() {
        playSound('start', 0.7, config.soundEnabled);
        gameState = 'playing';
        timer.start();
    }
    
    function handlePieceClick(row: number, col: number) {
        if (gameState !== 'playing') return;
        
        const piece = grid[row][col];
        if (!piece || piece.fixed) return;
        
        // Rotate the piece 90 degrees clockwise
        piece.rotation = (piece.rotation + 90) % 360;
        piece.connections = rotateConnections(pieceDefs[piece.type], piece.rotation);
        
        playSound('rotate', 0.3, config.soundEnabled);
        
        // Update power flow after rotation
        updatePowerFlow();
        
        // Check if the destination is powered
        checkWinCondition();
    }
    
    function updatePowerFlow() {
        // Reset power state except for source
        for (let row = 0; row < grid.length; row++) {
            for (let col = 0; col < grid[0].length; col++) {
                const piece = grid[row][col];
                if (piece && piece.type !== 'source') {
                    piece.powered = false;
                }
            }
        }
        
        // Start propagating power from source
        propagatePower(sourcePosition.row, sourcePosition.col);
    }
    
    function propagatePower(row: number, col: number) {
        const piece = grid[row][col];
        if (!piece || !piece.powered) return;
        
        // Check each direction and propagate power if connected
        if (piece.connections.top && row > 0) {
            const topPiece = grid[row - 1][col];
            if (topPiece && topPiece.connections.bottom && !topPiece.powered) {
                topPiece.powered = true;
                propagatePower(row - 1, col);
            }
        }
        
        if (piece.connections.right && col < grid[0].length - 1) {
            const rightPiece = grid[row][col + 1];
            if (rightPiece && rightPiece.connections.left && !rightPiece.powered) {
                rightPiece.powered = true;
                propagatePower(row, col + 1);
            }
        }
        
        if (piece.connections.bottom && row < grid.length - 1) {
            const bottomPiece = grid[row + 1][col];
            if (bottomPiece && bottomPiece.connections.top && !bottomPiece.powered) {
                bottomPiece.powered = true;
                propagatePower(row + 1, col);
            }
        }
        
        if (piece.connections.left && col > 0) {
            const leftPiece = grid[row][col - 1];
            if (leftPiece && leftPiece.connections.right && !leftPiece.powered) {
                leftPiece.powered = true;
                propagatePower(row, col - 1);
            }
        }
    }
    
    function checkWinCondition() {
        const destPiece = grid[destinationPosition.row][destinationPosition.col];
        if (destPiece.powered) {
            handleGameOver(true);
        }
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
                    timeRemaining: timeLeft
                }
            });
        }, 1500);
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

<div class="circuit-solver-container {difficultyClass}">
    <div class="header">
        <h2>Circuit Solver</h2>
        <div class="status">
            {#if gameState === 'playing'}
                <div class="phase">CONNECT</div>
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
            {#each row as piece, colIndex}
                {#if piece}
                    <div 
                        class="circuit-piece {piece.type} {piece.powered ? 'powered' : ''}"
                        on:click={() => handlePieceClick(rowIndex, colIndex)}
                        style="transform: rotate({piece.rotation}deg);"
                    >
                        <div class="piece-inner">
                            {#if piece.type === 'straight'}
                                <div class="connector vertical"></div>
                            {:else if piece.type === 'corner'}
                                <div class="connector corner"></div>
                            {:else if piece.type === 'three-way'}
                                <div class="connector three-way"></div>
                            {:else if piece.type === 'four-way'}
                                <div class="connector four-way"></div>
                            {:else if piece.type === 'source'}
                                <div class="connector source"></div>
                            {:else if piece.type === 'destination'}
                                <div class="connector destination"></div>
                            {/if}
                        </div>
                    </div>
                {/if}
            {/each}
        {/each}
    </div>
    
    <div class="footer">
        <div class="instructions">
            {#if gameState === 'playing'}
                Rotate the circuit pieces to connect power from source to destination
            {:else if gameState === 'success'}
                Circuit successfully connected!
            {:else if gameState === 'failure'}
                Failed to connect the circuit in time.
            {/if}
        </div>
        <button class="exit-button" on:click={exit}>EXIT</button>
    </div>
</div>

<style>
    .circuit-solver-container {
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
        gap: 5px;
        padding: 20px;
        justify-content: center;
        align-content: center;
    }
    
    .circuit-piece {
        aspect-ratio: 1/1;
        background-color: #21262d;
        border-radius: 4px;
        cursor: pointer;
        transition: transform 0.3s ease;
        position: relative;
        border: 1px solid #30363d;
        box-shadow: 0 2px 4px rgba(0, 0, 0, 0.3);
        display: flex;
        justify-content: center;
        align-items: center;
    }
    
    .circuit-piece.source, .circuit-piece.destination {
        cursor: default;
    }
    
    .circuit-piece.powered {
        box-shadow: 0 0 8px rgba(88, 166, 255, 0.8);
    }
    
    .piece-inner {
        width: 80%;
        height: 80%;
        position: relative;
    }
    
    /* Connectors */
    .connector {
        position: absolute;
        background-color: #c9d1d9;
    }
    
    .connector.vertical {
        width: 20%;
        height: 100%;
        left: 40%;
    }
    
    .connector.corner {
        width: 20%;
        height: 60%;
        left: 40%;
        border-top-right-radius: 10px;
    }
    
    .connector.corner::before {
        content: '';
        position: absolute;
        top: 0;
        right: -100%;
        width: 60%;
        height: 20%;
        background-color: #c9d1d9;
    }
    
    .connector.three-way {
        width: 20%;
        height: 100%;
        left: 40%;
    }
    
    .connector.three-way::before {
        content: '';
        position: absolute;
        top: 40%;
        right: -100%;
        width: 60%;
        height: 20%;
        background-color: #c9d1d9;
    }
    
    .connector.four-way {
        width: 20%;
        height: 100%;
        left: 40%;
    }
    
    .connector.four-way::before, .connector.four-way::after {
        content: '';
        position: absolute;
        background-color: #c9d1d9;
    }
    
    .connector.four-way::before {
        top: 40%;
        left: -100%;
        width: 100%;
        height: 20%;
    }
    
    .connector.four-way::after {
        top: 40%;
        right: -100%;
        width: 100%;
        height: 20%;
    }
    
    .connector.source {
        width: 60%;
        height: 20%;
        top: 40%;
        right: 0;
        background-color: #58a6ff;
        box-shadow: 0 0 10px rgba(88, 166, 255, 0.8);
    }
    
    .connector.source::before {
        content: 'S';
        position: absolute;
        top: -5px;
        left: -20px;
        color: #58a6ff;
        font-weight: bold;
        font-size: 18px;
    }
    
    .connector.destination {
        width: 60%;
        height: 20%;
        top: 40%;
        left: 0;
        background-color: #da3633;
    }
    
    .connector.destination::before {
        content: 'D';
        position: absolute;
        top: -5px;
        right: -20px;
        color: #da3633;
        font-weight: bold;
        font-size: 18px;
    }
    
    .circuit-piece.powered .connector {
        background-color: #58a6ff;
        box-shadow: 0 0 10px rgba(88, 166, 255, 0.8);
    }
    
    .circuit-piece.powered .connector.destination {
        background-color: #238636;
        box-shadow: 0 0 10px rgba(35, 134, 54, 0.8);
    }
    
    .circuit-piece.powered .connector.destination::before {
        color: #238636;
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
    .difficulty-easy .circuit-piece {
        background-color: #21262d;
    }
    
    .difficulty-normal .circuit-piece {
        background-color: #1c2128;
    }
    
    .difficulty-hard .circuit-piece {
        background-color: #101418;
    }
</style> 