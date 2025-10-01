# Snake Game - ARM64 Assembly Implementation

A classic Snake game implemented in pure ARM64 assembly language for Apple Silicon Mac computers (M1/M2/M3). This project demonstrates low-level programming concepts, direct hardware manipulation, and system programming on modern ARM64 architecture.

## 🎮 Features

- **Pure ARM64 Assembly**: Written entirely in ARM64 assembly language
- **Native macOS Support**: Optimized for Apple Silicon (M1/M2/M3) processors
- **Terminal-Based UI**: Clean terminal interface with ANSI escape sequences
- **Real-time Gameplay**: 60 FPS game loop with precise timing control
- **Custom Memory Management**: Hand-written heap allocator and memory pool
- **Advanced Input Handling**: Non-blocking keyboard input with arrow key support
- **Collision Detection**: Efficient wall and self-collision detection
- **Score System**: Real-time score tracking and display
- **State Management**: Finite state machine for game flow control

## 🏗️ Architecture

The game follows a modular architecture with clearly separated components:

```
┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐
│   Input Handler │  │ Display Manager │  │ Game State Mgr  │
└─────────────────┘  └─────────────────┘  └─────────────────┘
         │                     │                     │
         └─────────────────────┼─────────────────────┘
                               │
                    ┌─────────────────┐
                    │   Game Logic    │
                    │     Engine      │
                    └─────────────────┘
                               │
         ┌─────────────────────┼─────────────────────┐
         │                     │                     │
┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐
│ Memory Manager  │  │  Snake Engine   │  │ System Calls    │
└─────────────────┘  └─────────────────┘  └─────────────────┘
```

### Core Components

- **System Interface Layer** (`src/syscalls.s`): macOS system call wrappers
- **Memory Management** (`src/memory.s`): Custom heap allocator with 4KB pool
- **Game Data Models** (`src/gamedata.s`): Snake structure and board representation
- **Input Handler** (`src/input.s`): Keyboard processing and terminal control
- **Display Manager** (`src/display.s`): Terminal rendering with ANSI colors
- **Game Logic Core** (`src/gamelogic.s`): Movement, collision, and food generation
- **Game State Manager** (`src/gamestate.s`): FSM for menu/playing/paused/game-over
- **Main Loop** (`src/main.s`): Entry point and frame rate control

## 🚀 Getting Started

### Prerequisites

- **Hardware**: Apple Silicon Mac (M1, M2, or M3)
- **OS**: macOS 11.0 (Big Sur) or later
- **Tools**: Xcode Command Line Tools or Xcode
- **Terminal**: Any terminal application

### Installation

1. **Clone the repository**:
   ```bash
   git clone <repository-url>
   cd snake-assembly
   ```

2. **Build the game**:
   ```bash
   make all
   ```

3. **Run the game**:
   ```bash
   make run
   ```

### Build Options

```bash
# Clean build artifacts
make clean

# Build with debug information
make all

# Run tests
make test

# Debug with LLDB
make debug

# Show disassembly
make disasm

# Check for memory leaks
make memcheck

# Display help
make help
```

## 🎯 Gameplay

### Controls

- **Arrow Keys**: Change snake direction (Up/Down/Left/Right)
- **Space**: Pause/Resume game
- **Q** or **Escape**: Quit game

### Game Rules

1. Control the snake to eat food (*) and grow longer
2. Avoid colliding with walls or the snake's own body
3. Score increases by 10 points for each food consumed
4. Game speed increases as you eat more food
5. Game ends when the snake collides with walls or itself

### Game States

- **Menu**: Start screen with game title and instructions
- **Playing**: Active gameplay with real-time snake movement
- **Paused**: Game paused, can resume or quit
- **Game Over**: End screen with final score and restart option

## 🛠️ Technical Details

### Memory Management

- **Pool Size**: 4KB static memory pool
- **Allocation Strategy**: Linear allocator with 8-byte alignment
- **Snake Storage**: Dynamic linked list of body segments
- **Board Representation**: 25x80 character matrix

### Performance Optimizations

- **ARM64 Registers**: Efficient use of 31 general-purpose registers
- **Cache Alignment**: Data structures aligned to cache boundaries
- **Branch Prediction**: Optimized conditional jumps
- **Frame Rate Control**: Adaptive timing for consistent 60 FPS

### System Integration

- **System Calls**: Direct macOS system call interface
- **Terminal Control**: Raw mode with ANSI escape sequences
- **Non-blocking I/O**: Asynchronous input processing
- **Signal Handling**: Graceful cleanup on exit

## 🧪 Testing

The project includes a comprehensive test suite:

```bash
# Run unit tests
make test

# Run individual test components
./build/test_runner
```

### Test Coverage

- Memory allocation and deallocation
- Snake data structure operations
- Game board manipulation
- Display rendering functions
- Input processing validation
- State transition verification

## 🔧 Development

### Project Structure

```
snake-assembly/
├── src/                    # Source files
│   ├── main.s             # Main entry point
│   ├── syscalls.s         # System call wrappers
│   ├── memory.s           # Memory management
│   ├── gamedata.s         # Data structures
│   ├── input.s            # Input handling
│   ├── display.s          # Display rendering
│   ├── gamelogic.s        # Game logic
│   └── gamestate.s        # State management
├── include/               # Header files
│   ├── constants.h        # Game constants
│   └── structures.h       # Data structures
├── tests/                 # Test files
│   └── test_basic.s       # Basic functionality tests
├── build/                 # Build artifacts
├── docs/                  # Documentation
├── Makefile              # Build system
└── README.md             # This file
```

### Adding Features

1. **New Game Mechanics**: Extend `gamelogic.s`
2. **Display Effects**: Modify `display.s`
3. **Input Commands**: Update `input.s`
4. **State Transitions**: Extend `gamestate.s`

### Debug Information

The build system includes debug symbols. Use LLDB for debugging:

```bash
make debug
(lldb) breakpoint set --name _main_loop
(lldb) run
```

## 📊 Performance Metrics

### Target Specifications

- **Frame Rate**: 60 FPS sustained
- **Input Latency**: < 16ms response time
- **Memory Usage**: < 1MB total allocation
- **CPU Usage**: < 5% of single core

### Optimization Features

- **SIMD Instructions**: NEON for bulk operations
- **Register Allocation**: Minimized memory access
- **Branch Optimization**: Predicted execution paths
- **Cache Efficiency**: Aligned data structures

## 🐛 Troubleshooting

### Common Issues

1. **Build Errors**:
   - Ensure Xcode Command Line Tools are installed
   - Check macOS version compatibility (11.0+)
   - Verify ARM64 architecture

2. **Runtime Issues**:
   - Terminal size should be at least 80x25
   - Check terminal ANSI support
   - Ensure proper cleanup on exit

3. **Performance Issues**:
   - Close unnecessary applications
   - Check system resources
   - Verify frame rate settings

### Debug Commands

```bash
# Check file information
make info

# View memory usage
make memcheck

# Profile performance
make profile

# Show assembly code
make disasm
```

## 🤝 Contributing

This project is designed for educational purposes and demonstrates advanced assembly programming concepts. Contributions are welcome for:

- Performance optimizations
- Additional game features
- Platform ports
- Documentation improvements
- Test coverage expansion

## 📄 License

This project is provided as-is for educational and research purposes.

## 🙏 Acknowledgments

- Apple Silicon ARM64 Architecture Reference
- macOS System Call Documentation
- ARM64 Assembly Language Programming
- Classic Snake Game Design Patterns

---

**Happy Gaming! 🐍**

*Built with ❤️ and Assembly on Apple Silicon*