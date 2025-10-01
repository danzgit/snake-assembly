/*
 * Game Data Structures Implementation
 * Snake data structure and game board management
 * ARM64 Assembly for macOS
 */

.section __DATA,__data
.align 3

/* Game state structure */
.global game_state
game_state:
    .quad 0                     // state (menu/playing/paused/game_over)
    .quad 0                     // score
    .quad 0                     // direction (up/down/left/right)
    .quad 200                   // speed (milliseconds)
    .quad 0                     // paused flag
    .quad 0                     // snake head pointer
    .quad 0                     // snake tail pointer
    .quad 3                     // snake length
    .quad 0                     // food x coordinate
    .quad 0                     // food y coordinate

/* Game board (25 rows x 80 columns) */
.global game_board
game_board:
    .space 2000, 32             // Initialize with spaces (ASCII 32)

/* Direction vectors */
direction_vectors:
    .quad 0, -1                 // UP: dx=0, dy=-1
    .quad 0, 1                  // DOWN: dx=0, dy=1
    .quad -1, 0                 // LEFT: dx=-1, dy=0
    .quad 1, 0                  // RIGHT: dx=1, dy=0

.section __TEXT,__text
.align 2
.global _snake_init, _snake_add_segment, _snake_remove_tail, _snake_move
.global _snake_check_collision, _board_init, _board_set, _board_get
.global _food_generate, _game_state_init

/*
 * Initialize snake with initial segments
 * Parameters: x0 = start_x, x1 = start_y, x2 = initial_length
 * Returns: x0 = 0 on success, -1 on failure
 */
_snake_init:
    stp x29, x30, [sp, #-32]!   // Save frame pointer and link register
    mov x29, sp                 // Set frame pointer
    str x19, [sp, #16]          // Save x19
    str x20, [sp, #24]          // Save x20
    
    mov x19, x0                 // Save start_x
    mov x20, x1                 // Save start_y
    
    // Clear existing snake
    adrp x0, game_state@PAGE
    add x0, x0, game_state@PAGEOFF
    str xzr, [x0, #40]          // Clear head pointer
    str xzr, [x0, #48]          // Clear tail pointer
    str x2, [x0, #56]           // Set snake length
    
    // Create initial segments
    mov x3, #0                  // Counter
    
snake_init_loop:
    cmp x3, x2                  // Compare with initial length
    b.ge snake_init_done        // Branch if done
    
    // Allocate new segment
    mov x0, #24                 // Size of SnakeNode (x, y, next)
    bl _memory_alloc
    cmp x0, #0
    b.eq snake_init_failed      // Branch if allocation failed
    
    // Set segment coordinates
    str x19, [x0]               // Store x coordinate
    add x1, x20, x3             // y = start_y + counter
    str x1, [x0, #8]            // Store y coordinate
    str xzr, [x0, #16]          // Clear next pointer
    
    // Link segment to snake
    adrp x1, game_state@PAGE
    add x1, x1, game_state@PAGEOFF
    ldr x4, [x1, #40]           // Load head pointer
    cmp x4, #0
    b.eq snake_init_first       // Branch if first segment
    
    // Link to previous head
    str x0, [x4, #16]           // Set previous head's next to new segment
    b snake_init_continue
    
snake_init_first:
    str x0, [x1, #48]           // Set as tail
    
snake_init_continue:
    str x0, [x1, #40]           // Set as new head
    add x3, x3, #1              // Increment counter
    b snake_init_loop
    
snake_init_done:
    mov x0, #0                  // Success
    b snake_init_exit
    
snake_init_failed:
    mov x0, #-1                 // Failure
    
snake_init_exit:
    ldr x20, [sp, #24]          // Restore x20
    ldr x19, [sp, #16]          // Restore x19
    ldp x29, x30, [sp], #32     // Restore frame pointer and link register
    ret

/*
 * Add new segment to snake head
 * Parameters: x0 = x coordinate, x1 = y coordinate
 * Returns: x0 = 0 on success, -1 on failure
 */
_snake_add_segment:
    stp x29, x30, [sp, #-16]!   // Save frame pointer and link register
    mov x29, sp                 // Set frame pointer
    
    // Allocate new segment
    mov x2, x0                  // Save x coordinate
    mov x3, x1                  // Save y coordinate
    mov x0, #24                 // Size of SnakeNode
    bl _memory_alloc
    cmp x0, #0
    b.eq add_segment_failed     // Branch if allocation failed
    
    // Set segment data
    str x2, [x0]                // Store x coordinate
    str x3, [x0, #8]            // Store y coordinate
    str xzr, [x0, #16]          // Clear next pointer
    
    // Link to current head
    adrp x1, game_state@PAGE
    add x1, x1, game_state@PAGEOFF
    ldr x4, [x1, #40]           // Load current head
    str x4, [x0, #16]           // Link new segment to current head
    str x0, [x1, #40]           // Set new segment as head
    
    // Increment snake length
    ldr x2, [x1, #56]           // Load current length
    add x2, x2, #1              // Increment
    str x2, [x1, #56]           // Store new length
    
    mov x0, #0                  // Success
    b add_segment_exit
    
add_segment_failed:
    mov x0, #-1                 // Failure
    
add_segment_exit:
    ldp x29, x30, [sp], #16     // Restore frame pointer and link register
    ret

/*
 * Remove tail segment from snake
 * Parameters: none
 * Returns: x0 = 0 on success, -1 on failure
 */
_snake_remove_tail:
    stp x29, x30, [sp, #-16]!   // Save frame pointer and link register
    mov x29, sp                 // Set frame pointer
    
    adrp x0, game_state@PAGE
    add x0, x0, game_state@PAGEOFF
    ldr x1, [x0, #48]           // Load tail pointer
    cmp x1, #0
    b.eq remove_tail_failed     // Branch if no tail
    
    // Find second-to-last segment
    ldr x2, [x0, #40]           // Load head pointer
    cmp x2, x1                  // Check if head is tail (single segment)
    b.eq remove_tail_single
    
    // Traverse to find previous segment
remove_tail_loop:
    ldr x3, [x2, #16]           // Load next pointer
    cmp x3, x1                  // Compare with tail
    b.eq remove_tail_found      // Branch if found
    mov x2, x3                  // Move to next segment
    b remove_tail_loop
    
remove_tail_found:
    str xzr, [x2, #16]          // Clear next pointer of previous segment
    str x2, [x0, #48]           // Set previous segment as new tail
    b remove_tail_free
    
remove_tail_single:
    str xzr, [x0, #40]          // Clear head pointer
    str xzr, [x0, #48]          // Clear tail pointer
    
remove_tail_free:
    // Free the old tail segment
    mov x0, x1                  // Tail pointer
    mov x1, #24                 // Size of SnakeNode
    bl _memory_free
    
    // Decrement snake length
    adrp x0, game_state@PAGE
    add x0, x0, game_state@PAGEOFF
    ldr x1, [x0, #56]           // Load current length
    sub x1, x1, #1              // Decrement
    str x1, [x0, #56]           // Store new length
    
    mov x0, #0                  // Success
    b remove_tail_exit
    
remove_tail_failed:
    mov x0, #-1                 // Failure
    
remove_tail_exit:
    ldp x29, x30, [sp], #16     // Restore frame pointer and link register
    ret

/*
 * Move snake in current direction
 * Parameters: none
 * Returns: x0 = 0 on success, -1 on collision
 */
_snake_move:
    stp x29, x30, [sp, #-16]!   // Save frame pointer and link register
    mov x29, sp                 // Set frame pointer
    
    // Get current direction and head position
    adrp x0, game_state@PAGE
    add x0, x0, game_state@PAGEOFF
    ldr x1, [x0, #16]           // Load direction
    ldr x2, [x0, #40]           // Load head pointer
    
    // Get head coordinates
    ldr x3, [x2]                // Head x
    ldr x4, [x2, #8]            // Head y
    
    // Get direction vector
    adrp x5, direction_vectors@PAGE
    add x5, x5, direction_vectors@PAGEOFF
    lsl x6, x1, #4              // direction * 16 (2 quads per direction)
    add x5, x5, x6              // Point to direction vector
    ldr x7, [x5]                // Load dx
    ldr x8, [x5, #8]            // Load dy
    
    // Calculate new head position
    add x3, x3, x7              // new_x = head_x + dx
    add x4, x4, x8              // new_y = head_y + dy
    
    // Check collision
    mov x0, x3
    mov x1, x4
    bl _snake_check_collision
    cmp x0, #0
    b.ne snake_move_collision   // Branch if collision detected
    
    // Add new head segment
    mov x0, x3
    mov x1, x4
    bl _snake_add_segment
    cmp x0, #0
    b.ne snake_move_failed      // Branch if failed to add segment
    
    // Check if food was eaten
    adrp x0, game_state@PAGE
    add x0, x0, game_state@PAGEOFF
    ldr x1, [x0, #64]           // Load food_x
    ldr x2, [x0, #72]           // Load food_y
    cmp x3, x1
    b.ne snake_move_no_food     // Branch if x doesn't match
    cmp x4, x2
    b.ne snake_move_no_food     // Branch if y doesn't match
    
    // Food eaten - increase score and generate new food
    ldr x1, [x0, #8]            // Load score
    add x1, x1, #10             // Increase score
    str x1, [x0, #8]            // Store score
    bl _food_generate           // Generate new food
    b snake_move_success
    
snake_move_no_food:
    // Remove tail segment (snake doesn't grow)
    bl _snake_remove_tail
    
snake_move_success:
    mov x0, #0                  // Success
    b snake_move_exit
    
snake_move_collision:
snake_move_failed:
    mov x0, #-1                 // Failure
    
snake_move_exit:
    ldp x29, x30, [sp], #16     // Restore frame pointer and link register
    ret

/*
 * Check for collisions at given position
 * Parameters: x0 = x coordinate, x1 = y coordinate
 * Returns: x0 = 0 if no collision, 1 if collision
 */
_snake_check_collision:
    stp x29, x30, [sp, #-16]!   // Save frame pointer and link register
    mov x29, sp                 // Set frame pointer
    
    // Check wall collision
    cmp x0, #0                  // Check left wall
    b.lt collision_detected
    cmp x0, #79                 // Check right wall (width - 1)
    b.gt collision_detected
    cmp x1, #0                  // Check top wall
    b.lt collision_detected
    cmp x1, #24                 // Check bottom wall (height - 1)
    b.gt collision_detected
    
    // Check self collision
    adrp x2, game_state@PAGE
    add x2, x2, game_state@PAGEOFF
    ldr x3, [x2, #40]           // Load head pointer
    
self_collision_loop:
    cmp x3, #0                  // Check if end of snake
    b.eq no_collision           // Branch if end reached
    
    ldr x4, [x3]                // Load segment x
    ldr x5, [x3, #8]            // Load segment y
    cmp x0, x4                  // Compare x coordinates
    b.ne self_collision_next    // Branch if x doesn't match
    cmp x1, x5                  // Compare y coordinates
    b.eq collision_detected     // Branch if collision found
    
self_collision_next:
    ldr x3, [x3, #16]           // Move to next segment
    b self_collision_loop
    
collision_detected:
    mov x0, #1                  // Collision detected
    b collision_exit
    
no_collision:
    mov x0, #0                  // No collision
    
collision_exit:
    ldp x29, x30, [sp], #16     // Restore frame pointer and link register
    ret

/*
 * Initialize game board with walls
 * Parameters: none
 * Returns: none
 */
_board_init:
    stp x29, x30, [sp, #-16]!   // Save frame pointer and link register
    mov x29, sp                 // Set frame pointer
    
    adrp x0, game_board@PAGE
    add x0, x0, game_board@PAGEOFF
    
    // Clear board with spaces
    mov x1, #32                 // Space character
    mov x2, #2000               // Board size
    
clear_loop:
    cmp x2, #0
    b.eq board_init_exit
    strb w1, [x0], #1
    sub x2, x2, #1
    b clear_loop
    
board_init_exit:
    ldp x29, x30, [sp], #16     // Restore frame pointer and link register
    ret

/*
 * Set character at board position
 * Parameters: x0 = x, x1 = y, x2 = character
 * Returns: none
 */
_board_set:
    // Calculate offset: y * width + x
    mov x3, #80                 // Board width
    mul x4, x1, x3              // y * width
    add x4, x4, x0              // + x
    
    adrp x5, game_board@PAGE
    add x5, x5, game_board@PAGEOFF
    strb w2, [x5, x4]           // Store character
    ret

/*
 * Get character at board position
 * Parameters: x0 = x, x1 = y
 * Returns: x0 = character
 */
_board_get:
    // Calculate offset: y * width + x
    mov x2, #80                 // Board width
    mul x3, x1, x2              // y * width
    add x3, x3, x0              // + x
    
    adrp x4, game_board@PAGE
    add x4, x4, game_board@PAGEOFF
    ldrb w0, [x4, x3]           // Load character
    ret

/*
 * Generate food at random position
 * Parameters: none
 * Returns: none
 */
_food_generate:
    stp x29, x30, [sp, #-16]!   // Save frame pointer and link register
    mov x29, sp                 // Set frame pointer
    
    // Simple pseudo-random generation (for demo)
    // In a full implementation, use proper random number generation
    adrp x0, game_state@PAGE
    add x0, x0, game_state@PAGEOFF
    ldr x1, [x0, #8]            // Use score as seed
    add x1, x1, #17             // Add prime number
    
    // Generate x coordinate (0-79)
    mov x2, #79
    udiv x3, x1, x2
    msub x4, x3, x2, x1         // x = (score + 17) % 79
    str x4, [x0, #64]           // Store food_x
    
    // Generate y coordinate (0-24)
    lsr x1, x1, #3              // Shift for different sequence
    mov x2, #24
    udiv x3, x1, x2
    msub x5, x3, x2, x1         // y = ((score + 17) >> 3) % 24
    str x5, [x0, #72]           // Store food_y
    
    ldp x29, x30, [sp], #16     // Restore frame pointer and link register
    ret

/*
 * Initialize game state
 * Parameters: none
 * Returns: none
 */
_game_state_init:
    stp x29, x30, [sp, #-16]!   // Save frame pointer and link register
    mov x29, sp                 // Set frame pointer
    
    adrp x0, game_state@PAGE
    add x0, x0, game_state@PAGEOFF
    
    // Initialize state values
    str xzr, [x0]               // state = 0 (menu)
    str xzr, [x0, #8]           // score = 0
    mov x1, #3                  // direction = 3 (right)
    str x1, [x0, #16]
    mov x1, #200                // speed = 200ms
    str x1, [x0, #24]
    str xzr, [x0, #32]          // paused = 0
    
    // Initialize snake
    mov x0, #10                 // start_x
    mov x1, #12                 // start_y
    mov x2, #3                  // initial_length
    bl _snake_init
    
    // Initialize board
    bl _board_init
    
    // Generate initial food
    bl _food_generate
    
    ldp x29, x30, [sp], #16     // Restore frame pointer and link register
    ret