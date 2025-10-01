# Snake Game ARM64 Assembly - Makefile
# Targets Apple Silicon (M1/M2/M3) macOS

# Compiler and assembler settings
AS = as
LD = ld
CC = clang

# Architecture and platform
ARCH = -arch arm64
PLATFORM = -macosx_version_min 11.0

# Directories
SRC_DIR = src
INC_DIR = include
BUILD_DIR = build
TEST_DIR = tests
DOC_DIR = docs

# Source files
ASM_SOURCES = $(wildcard $(SRC_DIR)/*.s)
C_SOURCES = $(wildcard $(SRC_DIR)/*.c)
TEST_SOURCES = $(wildcard $(TEST_DIR)/*.s)

# Object files
ASM_OBJECTS = $(ASM_SOURCES:$(SRC_DIR)/%.s=$(BUILD_DIR)/%.o)
C_OBJECTS = $(C_SOURCES:$(SRC_DIR)/%.c=$(BUILD_DIR)/%.o)
TEST_OBJECTS = $(TEST_SOURCES:$(TEST_DIR)/%.s=$(BUILD_DIR)/test_%.o)

# Target executable
TARGET = $(BUILD_DIR)/snake_game
TEST_TARGET = $(BUILD_DIR)/test_runner

# Compiler flags
ASFLAGS = $(ARCH) -g
CFLAGS = $(ARCH) -I$(INC_DIR) -O2 -g -Wall -Wextra
LDFLAGS = $(ARCH) $(PLATFORM) -e _start

# Default target
all: $(TARGET)

# Create build directory
$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)

# Assemble ARM64 assembly files
$(BUILD_DIR)/%.o: $(SRC_DIR)/%.s | $(BUILD_DIR)
	$(AS) $(ASFLAGS) -o $@ $<

# Compile C files (for testing framework)
$(BUILD_DIR)/%.o: $(SRC_DIR)/%.c | $(BUILD_DIR)
	$(CC) $(CFLAGS) -c -o $@ $<

# Assemble test files
$(BUILD_DIR)/test_%.o: $(TEST_DIR)/%.s | $(BUILD_DIR)
	$(AS) $(ASFLAGS) -o $@ $<

# Link main executable
$(TARGET): $(ASM_OBJECTS) $(C_OBJECTS)
	$(LD) $(LDFLAGS) -o $@ $^

# Link test executable
$(TEST_TARGET): $(TEST_OBJECTS) $(ASM_OBJECTS)
	$(LD) $(LDFLAGS) -o $@ $^

# Run the game
run: $(TARGET)
	./$(TARGET)

# Run tests
test: $(TEST_TARGET)
	./$(TEST_TARGET)

# Debug with lldb
debug: $(TARGET)
	lldb $(TARGET)

# Clean build artifacts
clean:
	rm -rf $(BUILD_DIR)/*

# Clean all generated files
distclean: clean
	rm -rf $(BUILD_DIR)

# Install to system (optional)
install: $(TARGET)
	cp $(TARGET) /usr/local/bin/snake_game

# Uninstall from system
uninstall:
	rm -f /usr/local/bin/snake_game

# Show assembly code with symbols
disasm: $(TARGET)
	objdump -d -S $(TARGET)

# Show file information
info: $(TARGET)
	file $(TARGET)
	size $(TARGET)
	otool -h $(TARGET)

# Check for memory leaks (using leaks tool)
memcheck: $(TARGET)
	leaks --atExit -- ./$(TARGET)

# Performance profiling
profile: $(TARGET)
	instruments -t "Time Profiler" ./$(TARGET)

# Code formatting (for C files)
format:
	clang-format -i $(C_SOURCES)

# Documentation generation
docs:
	mkdir -p $(DOC_DIR)
	# Generate documentation from comments

# Help target
help:
	@echo "Snake Game ARM64 Assembly - Build System"
	@echo "Available targets:"
	@echo "  all        - Build the game (default)"
	@echo "  run        - Build and run the game"
	@echo "  test       - Build and run tests"
	@echo "  debug      - Launch debugger"
	@echo "  clean      - Remove build artifacts"
	@echo "  distclean  - Remove all generated files"
	@echo "  install    - Install to system"
	@echo "  uninstall  - Remove from system"
	@echo "  disasm     - Show disassembly"
	@echo "  info       - Show file information"
	@echo "  memcheck   - Check for memory leaks"
	@echo "  profile    - Run performance profiler"
	@echo "  format     - Format C source files"
	@echo "  docs       - Generate documentation"
	@echo "  help       - Show this help"

# Phony targets
.PHONY: all run test debug clean distclean install uninstall disasm info memcheck profile format docs help

# Dependency tracking
-include $(BUILD_DIR)/*.d