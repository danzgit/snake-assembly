/*
 * Game State Manager - Finite state machine and game flow control
 * ARM64 Assembly Implementation for macOS
 */

.section __DATA,__data
.align 3

/* Current game state */
current_state:      .quad 0     // Current state (0=menu, 1=playing, 2=paused, 3=game_over, 4=exit)
previous_state:     .quad 0     // Previous state for state transitions
state_change_flag:  .quad 0     // Flag indicating state change

/* State transition table */
state_transitions:
    // From MENU (0)
    .quad 0, 1, 1               // MENU -> PLAYING (input: start game)
    .quad 0, 4, 3               // MENU -> EXIT (input: quit)
    .quad 0, 0, 0               // MENU -> MENU (input: other/invalid)
    
    // From PLAYING (1)  
    .quad 1, 2, 2               // PLAYING -> PAUSED (input: pause)
    .quad 1, 3, 1               // PLAYING -> GAME_OVER (input: collision)
    .quad 1, 4, 3               // PLAYING -> EXIT (input: quit)
    .quad 1, 1, 0               // PLAYING -> PLAYING (input: other)
    
    // From PAUSED (2)
    .quad 2, 1, 2               // PAUSED -> PLAYING (input: resume)
    .quad 2, 4, 3               // PAUSED -> EXIT (input: quit)
    .quad 2, 2, 0               // PAUSED -> PAUSED (input: other)
    
    // From GAME_OVER (3)
    .quad 3, 0, 1               // GAME_OVER -> MENU (input: restart)
    .quad 3, 4, 3               // GAME_OVER -> EXIT (input: quit)
    .quad 3, 3, 0               // GAME_OVER -> GAME_OVER (input: other)

/* State function pointers */
state_functions:
    .quad _state_menu           // Menu state handler
    .quad _state_playing        // Playing state handler
    .quad _state_paused         // Paused state handler
    .quad _state_game_over      // Game over state handler
    .quad _state_exit           // Exit state handler

.section __TEXT,__text
.align 2
.global _game_state_manager_init, _game_state_manager_update, _game_state_transition
.global _game_state_get_current, _game_state_set, _state_menu, _state_playing
.global _state_paused, _state_game_over, _state_exit

/*
 * Initialize game state manager
 * Parameters: none
 * Returns: x0 = 0 on success, -1 on failure
 */
_game_state_manager_init:
    stp x29, x30, [sp, #-16]!   // Save frame pointer and link register
    mov x29, sp                 // Set frame pointer
    
    // Set initial state to menu
    adrp x0, current_state@PAGE
    add x0, x0, current_state@PAGEOFF
    str xzr, [x0]               // Set to MENU (0)
    
    adrp x0, previous_state@PAGE
    add x0, x0, previous_state@PAGEOFF
    str xzr, [x0]               // Set previous to MENU (0)
    
    adrp x0, state_change_flag@PAGE
    add x0, x0, state_change_flag@PAGEOFF
    mov x1, #1                  // Mark state change
    str x1, [x0]
    
    mov x0, #0                  // Success
    ldp x29, x30, [sp], #16     // Restore frame pointer and link register
    ret

/*
 * Update game state manager (called once per frame)
 * Parameters: none
 * Returns: x0 = 0 to continue, 1 to exit
 */
_game_state_manager_update:
    stp x29, x30, [sp, #-16]!   // Save frame pointer and link register
    mov x29, sp                 // Set frame pointer
    
    // Get current state
    adrp x0, current_state@PAGE
    add x0, x0, current_state@PAGEOFF
    ldr x1, [x0]                // Load current state
    
    // Check if state is valid
    cmp x1, #4                  // Check if state > EXIT
    b.hi state_invalid
    
    // Call appropriate state function
    adrp x2, state_functions@PAGE
    add x2, x2, state_functions@PAGEOFF
    lsl x3, x1, #3              // state * 8 (8 bytes per pointer)
    ldr x4, [x2, x3]            // Load function pointer
    blr x4                      // Call state function
    
    // Check for exit condition
    adrp x1, current_state@PAGE
    add x1, x1, current_state@PAGEOFF
    ldr x2, [x1]                // Load current state
    cmp x2, #4                  // Check if EXIT state
    b.eq state_exit_requested
    
    mov x0, #0                  // Continue
    b state_update_exit
    
state_invalid:
    // Reset to menu on invalid state
    mov x1, #0                  // MENU state
    str x1, [x0]
    mov x0, #0                  // Continue
    b state_update_exit
    
state_exit_requested:
    mov x0, #1                  // Exit requested
    
state_update_exit:
    ldp x29, x30, [sp], #16     // Restore frame pointer and link register
    ret

/*
 * Transition to new state
 * Parameters: x0 = input/event type
 * Returns: none
 */
_game_state_transition:
    stp x29, x30, [sp, #-16]!   // Save frame pointer and link register
    mov x29, sp                 // Set frame pointer
    
    // Get current state
    adrp x1, current_state@PAGE
    add x1, x1, current_state@PAGEOFF
    ldr x2, [x1]                // Load current state
    
    // Find transition in table
    mov x3, x0                  // Save input
    mov x4, x2                  // Current state
    bl _find_state_transition
    
    cmp x0, #-1                 // Check if valid transition found
    b.eq transition_exit        // Branch if no valid transition
    
    // Store previous state
    adrp x1, previous_state@PAGE
    add x1, x1, previous_state@PAGEOFF
    str x2, [x1]
    
    // Set new state
    adrp x1, current_state@PAGE
    add x1, x1, current_state@PAGEOFF
    str x0, [x1]
    
    // Mark state change
    adrp x1, state_change_flag@PAGE
    add x1, x1, state_change_flag@PAGEOFF
    mov x2, #1
    str x2, [x1]
    
transition_exit:
    ldp x29, x30, [sp], #16     // Restore frame pointer and link register
    ret

/*
 * Find state transition in table
 * Parameters: x3 = input, x4 = current state
 * Returns: x0 = new state or -1 if not found
 */
_find_state_transition:
    adrp x0, state_transitions@PAGE
    add x0, x0, state_transitions@PAGEOFF
    mov x1, #0                  // Index counter
    
transition_loop:
    ldr x2, [x0, x1]            // Load from_state
    cmp x2, x4                  // Compare with current state
    b.ne transition_next
    
    add x6, x0, x1              // Calculate base address
    ldr x2, [x6, #8]            // Load to_state
    ldr x5, [x6, #16]           // Load required_input
    cmp x5, x3                  // Compare with input
    b.eq transition_found
    
transition_next:
    add x1, x1, #24             // Move to next entry (3 quads)
    cmp x1, #288                // Check if end of table (12 entries * 24 bytes)
    b.lt transition_loop
    
    mov x0, #-1                 // Not found
    ret
    
transition_found:
    mov x0, x2                  // Return new state
    ret

/*
 * Get current state
 * Parameters: none
 * Returns: x0 = current state
 */
_game_state_get_current:
    adrp x0, current_state@PAGE
    add x0, x0, current_state@PAGEOFF
    ldr x0, [x0]
    ret

/*
 * Set current state directly
 * Parameters: x0 = new state
 * Returns: none
 */
_game_state_set:
    // Store previous state
    adrp x1, previous_state@PAGE
    add x1, x1, previous_state@PAGEOFF
    adrp x2, current_state@PAGE
    add x2, x2, current_state@PAGEOFF
    ldr x3, [x2]
    str x3, [x1]
    
    // Set new state
    str x0, [x2]
    
    // Mark state change
    adrp x1, state_change_flag@PAGE
    add x1, x1, state_change_flag@PAGEOFF
    mov x2, #1
    str x2, [x1]
    ret

/*
 * Menu state handler
 * Parameters: none
 * Returns: none
 */
_state_menu:
    stp x29, x30, [sp, #-16]!   // Save frame pointer and link register
    mov x29, sp                 // Set frame pointer
    
    // Check for state change
    adrp x0, state_change_flag@PAGE
    add x0, x0, state_change_flag@PAGEOFF
    ldr x1, [x0]
    cmp x1, #0
    b.eq menu_no_change
    
    // Clear state change flag
    str xzr, [x0]
    
    // Display menu
    bl _display_menu
    
menu_no_change:
    // Process input
    bl _input_process
    cmp x0, #0
    b.eq menu_exit              // No input
    
    // Handle input
    cmp x0, #2                  // Space (start game)
    b.eq menu_start_game
    cmp x0, #3                  // Quit
    b.eq menu_quit
    b menu_exit
    
menu_start_game:
    // Initialize new game
    bl _game_logic_reset
    mov x0, #1                  // Start game input
    bl _game_state_transition
    b menu_exit
    
menu_quit:
    mov x0, #3                  // Quit input
    bl _game_state_transition
    
menu_exit:
    ldp x29, x30, [sp], #16     // Restore frame pointer and link register
    ret

/*
 * Playing state handler
 * Parameters: none
 * Returns: none
 */
_state_playing:
    stp x29, x30, [sp, #-16]!   // Save frame pointer and link register
    mov x29, sp                 // Set frame pointer
    
    // Check for state change
    adrp x0, state_change_flag@PAGE
    add x0, x0, state_change_flag@PAGEOFF
    ldr x1, [x0]
    cmp x1, #0
    b.eq playing_no_change
    
    // Clear state change flag
    str xzr, [x0]
    
    // Initialize display for playing
    bl _display_init
    
playing_no_change:
    // Process input
    bl _input_process
    cmp x0, #0
    b.ne playing_handle_input
    
    // Update game logic
    bl _game_logic_update
    cmp x0, #1                  // Check for game over
    b.eq playing_game_over
    
    // Render game
    bl _display_render
    b playing_exit
    
playing_handle_input:
    cmp x0, #2                  // Pause
    b.eq playing_pause
    cmp x0, #3                  // Quit
    b.eq playing_quit
    b playing_continue_game
    
playing_pause:
    mov x0, #2                  // Pause input
    bl _game_state_transition
    b playing_exit
    
playing_quit:
    mov x0, #3                  // Quit input
    bl _game_state_transition
    b playing_exit
    
playing_game_over:
    mov x0, #1                  // Game over input
    bl _game_state_transition
    b playing_exit
    
playing_continue_game:
    // Update game logic
    bl _game_logic_update
    cmp x0, #1                  // Check for game over
    b.eq playing_game_over
    
    // Render game
    bl _display_render
    
playing_exit:
    ldp x29, x30, [sp], #16     // Restore frame pointer and link register
    ret

/*
 * Paused state handler
 * Parameters: none
 * Returns: none
 */
_state_paused:
    stp x29, x30, [sp, #-16]!   // Save frame pointer and link register
    mov x29, sp                 // Set frame pointer
    
    // Check for state change
    adrp x0, state_change_flag@PAGE
    add x0, x0, state_change_flag@PAGEOFF
    ldr x1, [x0]
    cmp x1, #0
    b.eq paused_no_change
    
    // Clear state change flag
    str xzr, [x0]
    
    // Display pause overlay
    bl _display_pause
    
paused_no_change:
    // Process input
    bl _input_process
    cmp x0, #0
    b.eq paused_exit            // No input
    
    // Handle input
    cmp x0, #2                  // Space (resume)
    b.eq paused_resume
    cmp x0, #3                  // Quit
    b.eq paused_quit
    b paused_exit
    
paused_resume:
    mov x0, #2                  // Resume input
    bl _game_state_transition
    b paused_exit
    
paused_quit:
    mov x0, #3                  // Quit input
    bl _game_state_transition
    
paused_exit:
    ldp x29, x30, [sp], #16     // Restore frame pointer and link register
    ret

/*
 * Game over state handler
 * Parameters: none
 * Returns: none
 */
_state_game_over:
    stp x29, x30, [sp, #-16]!   // Save frame pointer and link register
    mov x29, sp                 // Set frame pointer
    
    // Check for state change
    adrp x0, state_change_flag@PAGE
    add x0, x0, state_change_flag@PAGEOFF
    ldr x1, [x0]
    cmp x1, #0
    b.eq game_over_no_change
    
    // Clear state change flag
    str xzr, [x0]
    
    // Display game over screen
    bl _display_game_over
    
game_over_no_change:
    // Process input
    bl _input_process
    cmp x0, #0
    b.eq game_over_exit         // No input
    
    // Handle input
    cmp x0, #2                  // Space (restart)
    b.eq game_over_restart
    cmp x0, #3                  // Quit
    b.eq game_over_quit
    b game_over_exit
    
game_over_restart:
    mov x0, #1                  // Restart input
    bl _game_state_transition
    b game_over_exit
    
game_over_quit:
    mov x0, #3                  // Quit input
    bl _game_state_transition
    
game_over_exit:
    ldp x29, x30, [sp], #16     // Restore frame pointer and link register
    ret

/*
 * Exit state handler
 * Parameters: none
 * Returns: none
 */
_state_exit:
    stp x29, x30, [sp, #-16]!   // Save frame pointer and link register
    mov x29, sp                 // Set frame pointer
    
    // Cleanup all systems
    bl _display_cleanup
    bl _input_cleanup
    bl _memory_cleanup
    
    ldp x29, x30, [sp], #16     // Restore frame pointer and link register
    ret

/*
 * Get state change flag
 * Parameters: none
 * Returns: x0 = 1 if state changed, 0 otherwise
 */
.global _game_state_changed
_game_state_changed:
    adrp x0, state_change_flag@PAGE
    add x0, x0, state_change_flag@PAGEOFF
    ldr x0, [x0]
    ret

/*
 * Clear state change flag
 * Parameters: none
 * Returns: none
 */
.global _game_state_clear_change
_game_state_clear_change:
    adrp x0, state_change_flag@PAGE
    add x0, x0, state_change_flag@PAGEOFF
    str xzr, [x0]
    ret