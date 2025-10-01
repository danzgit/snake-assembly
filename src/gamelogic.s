/*
 * Game Logic Core - Snake movement, collision detection, and food generation
 * ARM64 Assembly Implementation for macOS
 */

.section __DATA,__data
.align 3

/* Game timing */
last_move_time:     .quad 0     // Last movement timestamp
frame_counter:      .quad 0     // Frame counter for timing

.section __TEXT,__text
.align 2
.global _game_logic_init, _game_logic_update, _game_logic_move_snake
.global _game_logic_check_food, _game_logic_increase_speed, _game_logic_reset

/*
 * Initialize game logic system
 * Parameters: none
 * Returns: x0 = 0 on success, -1 on failure
 */
_game_logic_init:
    stp x29, x30, [sp, #-16]!   // Save frame pointer and link register
    mov x29, sp                 // Set frame pointer
    
    // Initialize timing
    adrp x0, last_move_time@PAGE
    add x0, x0, last_move_time@PAGEOFF
    str xzr, [x0]
    
    adrp x0, frame_counter@PAGE
    add x0, x0, frame_counter@PAGEOFF
    str xzr, [x0]
    
    // Initialize game state
    bl _game_state_init
    
    mov x0, #0                  // Success
    ldp x29, x30, [sp], #16     // Restore frame pointer and link register
    ret

/*
 * Main game logic update function
 * Called once per frame
 * Parameters: none
 * Returns: x0 = game status (0=continue, 1=game_over, 2=level_up)
 */
_game_logic_update:
    stp x29, x30, [sp, #-16]!   // Save frame pointer and link register
    mov x29, sp                 // Set frame pointer
    
    // Check if game is paused
    adrp x0, game_state@PAGE
    add x0, x0, game_state@PAGEOFF
    ldr x1, [x0, #32]           // Load pause flag
    cmp x1, #0
    b.ne game_logic_paused      // Branch if paused
    
    // Check if it's time to move
    bl _game_logic_check_move_time
    cmp x0, #0
    b.eq game_logic_no_move     // Branch if not time to move
    
    // Move snake
    bl _game_logic_move_snake
    cmp x0, #0
    b.ne game_logic_collision   // Branch if collision detected
    
    // Update board representation
    bl _game_logic_update_board
    
    // Check for food consumption
    bl _game_logic_check_food
    cmp x0, #1
    b.eq game_logic_food_eaten  // Branch if food was eaten
    
game_logic_no_move:
game_logic_paused:
    mov x0, #0                  // Continue game
    b game_logic_exit
    
game_logic_food_eaten:
    // Increase speed slightly
    bl _game_logic_increase_speed
    mov x0, #0                  // Continue game
    b game_logic_exit
    
game_logic_collision:
    mov x0, #1                  // Game over
    
game_logic_exit:
    ldp x29, x30, [sp], #16     // Restore frame pointer and link register
    ret

/*
 * Check if it's time to move the snake
 * Parameters: none
 * Returns: x0 = 1 if time to move, 0 otherwise
 */
_game_logic_check_move_time:
    stp x29, x30, [sp, #-16]!   // Save frame pointer and link register
    mov x29, sp                 // Set frame pointer
    
    // Get current time (simplified - using frame counter)
    adrp x0, frame_counter@PAGE
    add x0, x0, frame_counter@PAGEOFF
    ldr x1, [x0]                // Load frame counter
    add x1, x1, #1              // Increment
    str x1, [x0]                // Store back
    
    // Get game speed
    adrp x2, game_state@PAGE
    add x2, x2, game_state@PAGEOFF
    ldr x3, [x2, #24]           // Load speed (in ms)
    
    // Convert speed to frame count (assuming 60 FPS)
    // frames_per_move = (speed_ms * 60) / 1000
    mov x4, #60
    mul x3, x3, x4
    mov x4, #1000
    udiv x3, x3, x4             // frames per move
    
    // Check if enough frames have passed
    adrp x4, last_move_time@PAGE
    add x4, x4, last_move_time@PAGEOFF
    ldr x5, [x4]                // Load last move time
    
    sub x6, x1, x5              // Current - last
    cmp x6, x3                  // Compare with required frames
    b.lt move_time_not_ready    // Branch if not ready
    
    // Time to move
    str x1, [x4]                // Update last move time
    mov x0, #1                  // Time to move
    b move_time_exit
    
move_time_not_ready:
    mov x0, #0                  // Not time to move
    
move_time_exit:
    ldp x29, x30, [sp], #16     // Restore frame pointer and link register
    ret

/*
 * Move snake according to current direction
 * Parameters: none
 * Returns: x0 = 0 on success, -1 on collision
 */
_game_logic_move_snake:
    stp x29, x30, [sp, #-16]!   // Save frame pointer and link register
    mov x29, sp                 // Set frame pointer
    
    // Delegate to snake movement function
    bl _snake_move
    
    ldp x29, x30, [sp], #16     // Restore frame pointer and link register
    ret

/*
 * Update board representation with current game state
 * Parameters: none
 * Returns: none
 */
_game_logic_update_board:
    stp x29, x30, [sp, #-32]!   // Save frame pointer and link register
    mov x29, sp                 // Set frame pointer
    str x19, [sp, #16]          // Save x19
    str x20, [sp, #24]          // Save x20
    
    // Clear board
    bl _board_init
    
    // Draw snake
    adrp x0, game_state@PAGE
    add x0, x0, game_state@PAGEOFF
    ldr x19, [x0, #40]          // Load head pointer
    
    mov x20, #1                 // Segment counter
    
update_snake_loop:
    cmp x19, #0                 // Check if end of snake
    b.eq update_snake_done      // Branch if done
    
    // Get segment coordinates
    ldr x0, [x19]               // x coordinate
    ldr x1, [x19, #8]           // y coordinate
    
    // Determine character
    cmp x20, #1                 // Check if head
    b.eq update_snake_head
    
    // Body segment
    mov x2, #'o'                // Body character
    b update_snake_set
    
update_snake_head:
    mov x2, #'O'                // Head character
    
update_snake_set:
    bl _board_set
    
    ldr x19, [x19, #16]         // Move to next segment
    add x20, x20, #1            // Increment counter
    b update_snake_loop
    
update_snake_done:
    // Draw food
    adrp x0, game_state@PAGE
    add x0, x0, game_state@PAGEOFF
    ldr x1, [x0, #64]           // food_x
    ldr x2, [x0, #72]           // food_y
    mov x0, x1                  // x coordinate
    mov x1, x2                  // y coordinate
    mov x2, #'*'                // Food character
    bl _board_set
    
    ldr x20, [sp, #24]          // Restore x20
    ldr x19, [sp, #16]          // Restore x19
    ldp x29, x30, [sp], #32     // Restore frame pointer and link register
    ret

/*
 * Check if food was consumed and handle it
 * Parameters: none
 * Returns: x0 = 1 if food eaten, 0 otherwise
 */
_game_logic_check_food:
    stp x29, x30, [sp, #-16]!   // Save frame pointer and link register
    mov x29, sp                 // Set frame pointer
    
    // Get snake head position
    adrp x0, game_state@PAGE
    add x0, x0, game_state@PAGEOFF
    ldr x1, [x0, #40]           // Load head pointer
    cmp x1, #0
    b.eq check_food_none        // Branch if no head
    
    ldr x2, [x1]                // Head x coordinate
    ldr x3, [x1, #8]            // Head y coordinate
    
    // Get food position
    ldr x4, [x0, #64]           // food_x
    ldr x5, [x0, #72]           // food_y
    
    // Compare positions
    cmp x2, x4                  // Compare x coordinates
    b.ne check_food_none        // Branch if x doesn't match
    cmp x3, x5                  // Compare y coordinates
    b.ne check_food_none        // Branch if y doesn't match
    
    // Food was eaten
    // Increase score
    ldr x1, [x0, #8]            // Load current score
    add x1, x1, #10             // Increase by 10
    str x1, [x0, #8]            // Store new score
    
    // Generate new food
    bl _food_generate
    
    // Note: Snake growth is handled in snake_move function
    
    mov x0, #1                  // Food eaten
    b check_food_exit
    
check_food_none:
    mov x0, #0                  // No food eaten
    
check_food_exit:
    ldp x29, x30, [sp], #16     // Restore frame pointer and link register
    ret

/*
 * Increase game speed (make game faster)
 * Parameters: none
 * Returns: none
 */
_game_logic_increase_speed:
    adrp x0, game_state@PAGE
    add x0, x0, game_state@PAGEOFF
    ldr x1, [x0, #24]           // Load current speed
    
    // Decrease speed value (makes game faster)
    cmp x1, #50                 // Minimum speed (50ms)
    b.le speed_at_minimum       // Branch if already at minimum
    
    sub x1, x1, #5              // Decrease by 5ms
    str x1, [x0, #24]           // Store new speed
    
speed_at_minimum:
    ret

/*
 * Reset game to initial state
 * Parameters: none
 * Returns: none
 */
_game_logic_reset:
    stp x29, x30, [sp, #-16]!   // Save frame pointer and link register
    mov x29, sp                 // Set frame pointer
    
    // Reset game state
    bl _game_state_init
    
    // Reset timing
    adrp x0, last_move_time@PAGE
    add x0, x0, last_move_time@PAGEOFF
    str xzr, [x0]
    
    adrp x0, frame_counter@PAGE
    add x0, x0, frame_counter@PAGEOFF
    str xzr, [x0]
    
    ldp x29, x30, [sp], #16     // Restore frame pointer and link register
    ret

/*
 * Advanced collision detection with optimization
 * Parameters: x0 = x coordinate, x1 = y coordinate
 * Returns: x0 = collision type (0=none, 1=wall, 2=self, 3=food)
 */
.global _game_logic_advanced_collision
_game_logic_advanced_collision:
    stp x29, x30, [sp, #-16]!   // Save frame pointer and link register
    mov x29, sp                 // Set frame pointer
    
    // Check wall collision first (fastest check)
    cmp x0, #0                  // Left wall
    b.lt collision_wall
    cmp x0, #79                 // Right wall
    b.gt collision_wall
    cmp x1, #0                  // Top wall
    b.lt collision_wall
    cmp x1, #24                 // Bottom wall
    b.gt collision_wall
    
    // Check food collision
    adrp x2, game_state@PAGE
    add x2, x2, game_state@PAGEOFF
    ldr x3, [x2, #64]           // food_x
    ldr x4, [x2, #72]           // food_y
    cmp x0, x3
    b.ne check_self_collision
    cmp x1, x4
    b.eq collision_food
    
check_self_collision:
    // Check self collision (most expensive)
    ldr x3, [x2, #40]           // Load head pointer
    
self_collision_loop_adv:
    cmp x3, #0                  // Check if end of snake
    b.eq collision_none         // Branch if end reached
    
    ldr x4, [x3]                // Load segment x
    ldr x5, [x3, #8]            // Load segment y
    cmp x0, x4                  // Compare x coordinates
    b.ne self_collision_next_adv
    cmp x1, x5                  // Compare y coordinates
    b.eq collision_self
    
self_collision_next_adv:
    ldr x3, [x3, #16]           // Move to next segment
    b self_collision_loop_adv
    
collision_wall:
    mov x0, #1                  // Wall collision
    b collision_exit_adv
    
collision_self:
    mov x0, #2                  // Self collision
    b collision_exit_adv
    
collision_food:
    mov x0, #3                  // Food collision
    b collision_exit_adv
    
collision_none:
    mov x0, #0                  // No collision
    
collision_exit_adv:
    ldp x29, x30, [sp], #16     // Restore frame pointer and link register
    ret

/*
 * Calculate game statistics
 * Parameters: x0 = pointer to statistics structure
 * Returns: none
 */
.global _game_logic_get_stats
_game_logic_get_stats:
    stp x29, x30, [sp, #-16]!   // Save frame pointer and link register
    mov x29, sp                 // Set frame pointer
    
    adrp x1, game_state@PAGE
    add x1, x1, game_state@PAGEOFF
    
    // Store current score
    ldr x2, [x1, #8]            // Load score
    str x2, [x0]                // Store in stats structure
    
    // Store snake length
    ldr x2, [x1, #56]           // Load snake length
    str x2, [x0, #8]            // Store in stats structure
    
    // Store current speed
    ldr x2, [x1, #24]           // Load speed
    str x2, [x0, #16]           // Store in stats structure
    
    // Calculate moves per second
    mov x2, #1000               // Milliseconds per second
    ldr x3, [x1, #24]           // Load speed
    udiv x2, x2, x3             // moves_per_second = 1000 / speed_ms
    str x2, [x0, #24]           // Store in stats structure
    
    // Store frame counter
    adrp x1, frame_counter@PAGE
    add x1, x1, frame_counter@PAGEOFF
    ldr x2, [x1]
    str x2, [x0, #32]           // Store in stats structure
    
    ldp x29, x30, [sp], #16     // Restore frame pointer and link register
    ret

/*
 * Validate game state integrity
 * Parameters: none
 * Returns: x0 = 1 if valid, 0 if corrupted
 */
.global _game_logic_validate_state
_game_logic_validate_state:
    stp x29, x30, [sp, #-16]!   // Save frame pointer and link register
    mov x29, sp                 // Set frame pointer
    
    adrp x0, game_state@PAGE
    add x0, x0, game_state@PAGEOFF
    
    // Check snake length consistency
    ldr x1, [x0, #56]           // Load snake length
    cmp x1, #0                  // Check minimum length
    b.le state_invalid
    cmp x1, #1000               // Check maximum reasonable length
    b.gt state_invalid
    
    // Count actual snake segments
    ldr x2, [x0, #40]           // Load head pointer
    mov x3, #0                  // Counter
    
count_segments:
    cmp x2, #0                  // Check if end of snake
    b.eq count_done
    add x3, x3, #1              // Increment counter
    ldr x2, [x2, #16]           // Move to next segment
    cmp x3, #1000               // Prevent infinite loop
    b.lt count_segments
    b state_invalid             // Too many segments
    
count_done:
    cmp x1, x3                  // Compare stored length with counted
    b.ne state_invalid
    
    // Check food position bounds
    ldr x1, [x0, #64]           // food_x
    ldr x2, [x0, #72]           // food_y
    cmp x1, #0
    b.lt state_invalid
    cmp x1, #79
    b.gt state_invalid
    cmp x2, #0
    b.lt state_invalid
    cmp x2, #24
    b.gt state_invalid
    
    mov x0, #1                  // Valid state
    b validate_exit
    
state_invalid:
    mov x0, #0                  // Invalid state
    
validate_exit:
    ldp x29, x30, [sp], #16     // Restore frame pointer and link register
    ret