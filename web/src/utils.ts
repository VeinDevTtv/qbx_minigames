// Audio utilities
export const playSound = (
    soundName: string, 
    volume: number = 0.5, 
    soundEnabled: boolean = true
): HTMLAudioElement | null => {
    if (!soundEnabled) return null;
    
    const audio = new Audio(`sounds/${soundName}.mp3`);
    audio.volume = volume;
    audio.play().catch(err => console.error("Failed to play sound:", err));
    return audio;
};

// Timer utilities
export class CountdownTimer {
    private startTime: number;
    private duration: number;
    private timerInterval: ReturnType<typeof setInterval> | null = null;
    private onUpdateCallback: (timeLeft: number) => void;
    private onCompleteCallback: () => void;
    
    constructor(
        duration: number,
        onUpdate: (timeLeft: number) => void,
        onComplete: () => void
    ) {
        this.startTime = Date.now();
        this.duration = duration;
        this.onUpdateCallback = onUpdate;
        this.onCompleteCallback = onComplete;
    }
    
    start() {
        this.startTime = Date.now();
        this.timerInterval = setInterval(() => {
            const elapsed = Date.now() - this.startTime;
            const remaining = Math.max(0, this.duration - elapsed);
            
            this.onUpdateCallback(remaining);
            
            if (remaining <= 0) {
                this.stop();
                this.onCompleteCallback();
            }
        }, 10);
    }
    
    stop() {
        if (this.timerInterval) {
            clearInterval(this.timerInterval);
            this.timerInterval = null;
        }
    }
    
    reset() {
        this.stop();
        this.startTime = Date.now();
    }
    
    isRunning(): boolean {
        return this.timerInterval !== null;
    }
}

// Animation utilities
export const animateElement = (
    element: HTMLElement, 
    keyframes: Keyframe[] | PropertyIndexedKeyframes, 
    options: KeyframeAnimationOptions
): Animation => {
    return element.animate(keyframes, options);
};

// Random utilities
export const getRandomInt = (min: number, max: number): number => {
    min = Math.ceil(min);
    max = Math.floor(max);
    return Math.floor(Math.random() * (max - min + 1)) + min;
};

export const shuffleArray = <T>(array: T[]): T[] => {
    const newArray = [...array];
    for (let i = newArray.length - 1; i > 0; i--) {
        const j = Math.floor(Math.random() * (i + 1));
        [newArray[i], newArray[j]] = [newArray[j], newArray[i]];
    }
    return newArray;
};

// Color utilities
export const generateRandomColor = (): string => {
    const letters = '0123456789ABCDEF';
    let color = '#';
    for (let i = 0; i < 6; i++) {
        color += letters[Math.floor(Math.random() * 16)];
    }
    return color;
};

export const generateContrastingColor = (hexColor: string): string => {
    // Convert hex to RGB
    const r = parseInt(hexColor.substr(1, 2), 16);
    const g = parseInt(hexColor.substr(3, 2), 16);
    const b = parseInt(hexColor.substr(5, 2), 16);
    
    // Calculate luminance
    const luminance = (0.299 * r + 0.587 * g + 0.114 * b) / 255;
    
    // Return black or white based on luminance
    return luminance > 0.5 ? '#000000' : '#FFFFFF';
};

// Format utilities
export const formatTime = (ms: number): string => {
    const seconds = Math.floor(ms / 1000);
    const milliseconds = Math.floor((ms % 1000) / 10);
    return `${seconds}.${milliseconds.toString().padStart(2, '0')}`;
};

// UI utilities
export const createGrid = <T>(rows: number, cols: number, defaultValue: T): T[][] => {
    return Array(rows).fill(null).map(() => Array(cols).fill(defaultValue));
};

// Debounce function to limit how often a function can be called
export const debounce = <T extends (...args: any[]) => any>(
    callback: T,
    wait: number
): (...args: Parameters<T>) => void => {
    let timeoutId: ReturnType<typeof setTimeout> | null = null;
    
    return (...args: Parameters<T>) => {
        if (timeoutId) {
            clearTimeout(timeoutId);
        }
        
        timeoutId = setTimeout(() => {
            callback(...args);
        }, wait);
    };
}; 