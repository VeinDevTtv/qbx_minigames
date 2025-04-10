// Common interfaces
export type Difficulty = 'easy' | 'normal' | 'hard';

export interface BaseConfig {
    difficulty: Difficulty;
    duration: number;
    soundEnabled: boolean;
}

// Memory Sequence Game
export interface MemorySequenceConfig extends BaseConfig {
    gridSize: number;      // Size of the grid (3x3, 4x4, 5x5)
    sequenceLength: number; // Number of tiles to remember
}

// Circuit Solver Game
export interface CircuitSolverConfig extends BaseConfig {
    gridSize: number;     // Size of the grid
    circuits: number;     // Number of circuits to complete
}

// Code Cracker Game (like Mastermind/Wordle)
export interface CodeCrackerConfig extends BaseConfig {
    codeLength: number;   // Length of the code to crack
    attempts: number;     // Number of attempts allowed
}

// Safe Cracker Game
export interface SafeCrackerConfig extends BaseConfig {
    maxRotations: number; // Maximum number of rotations per dial
    zones: number;        // Number of correct zones per dial
}

// Thermite Game
export interface ThermiteConfig extends BaseConfig {
    gridSize: number;     // Size of the grid
    targetCount: number;  // Number of squares to remember
    displayTime: number;  // Time to show the pattern
}

// Game Events
export interface GameCompleteEvent {
    success: boolean;
    data?: any;
}

// Union type for all game configs
export type MinigameConfig = 
    | MemorySequenceConfig
    | CircuitSolverConfig
    | CodeCrackerConfig
    | SafeCrackerConfig
    | ThermiteConfig; 