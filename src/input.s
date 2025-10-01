/*
 * Input Handler - Keyboard input processing and terminal control
 * ARM64 Assembly Implementation for macOS
 */

.section __DATA,__data
.align 3

/* Terminal settings storage */
original_termios:
    .space 256, 0               // Storage for original terminal settings

/* Input buffer */
input_buffer:
    .space 256, 0               // Input buffer

/* Key mapping table */
key_mappings:
    .quad 65, 0                 // Arrow Up -> DIR_UP
    .quad 66, 1                 // Arrow Down -> DIR_DOWN  
    .quad 68, 2                 // Arrow Left -> DIR_LEFT
    .quad 67, 3                 // Arrow Right -> DIR_RIGHT
    .quad 32, 100               // Space -> PAUSE
    .quad 113, 101              // 'q' -> QUIT
    .quad 27, 102               // ESC -> QUIT
    .quad 0, 0                  // End marker

/* Terminal control sequences */
clear_screen:
    .ascii "\033[2J\033[H"      // Clear screen and move cursor to home
clear_screen_len = . - clear_screen

hide_cursor:
    .ascii "\033[?25l"          // Hide cursor
hide_cursor_len = . - hide_cursor

show_cursor:
    .ascii "\033[?25h"          // Show cursor
show_cursor_len = . - show_cursor

.section __TEXT,__text
.align 2
.global _input_init, _input_cleanup, _input_read, _input_process
.global _terminal_raw_mode, _terminal_restore, _terminal_clear, _cursor_hide, _cursor_show

/*
 * Initialize input system and set terminal to raw mode
 * Parameters: none
 * Returns: x0 = 0 on success, -1 on failure
 */
_input_init:
    stp x29, x30, [sp, #-16]!   // Save frame pointer and link register
    mov x29, sp                 // Set frame pointer
    
    // Set terminal to raw mode
    bl _terminal_raw_mode
    cmp x0, #0
    b.ne input_init_failed
    
    // Clear screen and hide cursor
    bl _terminal_clear
    bl _cursor_hide
    
    mov x0, #0                  // Success
    b input_init_exit
    
input_init_failed:
    mov x0, #-1                 // Failure
    
input_init_exit:
    ldp x29, x30, [sp], #16     // Restore frame pointer and link register
    ret

/*
 * Cleanup input system and restore terminal
 * Parameters: none
 * Returns: none
 */
_input_cleanup:
    stp x29, x30, [sp, #-16]!   // Save frame pointer and link register
    mov x29, sp                 // Set frame pointer
    
    // Show cursor and restore terminal
    bl _cursor_show
    bl _terminal_restore
    
    ldp x29, x30, [sp], #16     // Restore frame pointer and link register
    ret

/*
 * Set terminal to raw mode (non-canonical, no echo)
 * Parameters: none
 * Returns: x0 = 0 on success, -1 on failure
 */
_terminal_raw_mode:
    stp x29, x30, [sp, #-32]!   // Save frame pointer and link register
    mov x29, sp                 // Set frame pointer
    str x19, [sp, #16]          // Save x19
    
    // Get current terminal attributes
    mov x0, #0                  // STDIN
    movz x1, #0x6740, lsl #16   // TIOCGETA high bits
    movk x1, #0x8408            // TIOCGETA low bits
    adrp x2, original_termios@PAGE
    add x2, x2, original_termios@PAGEOFF
    bl _sys_ioctl
    cmp x0, #0
    b.ne terminal_raw_failed
    
    // Copy original settings for modification
    adrp x19, original_termios@PAGE
    add x19, x19, original_termios@PAGEOFF
    
    // Modify terminal flags for raw mode
    // Clear ICANON (canonical mode) and ECHO
    ldr x0, [x19, #12]          // Load c_lflag
    mov x1, #0x102              // ICANON | ECHO
    bic x0, x0, x1              // Clear flags
    str x0, [x19, #12]          // Store modified c_lflag
    
    // Set VMIN = 0, VTIME = 1 for non-blocking read
    mov x0, #0
    strb w0, [x19, #16]         // VMIN = 0
    mov x0, #1
    strb w0, [x19, #17]         // VTIME = 1 (0.1 second timeout)
    
    // Apply modified settings
    mov x0, #0                  // STDIN
    movz x1, #0x8006, lsl #16   // TIOCSETA high bits
    movk x1, #0x7409            // TIOCSETA low bits
    mov x2, x19                 // Modified termios
    bl _sys_ioctl
    cmp x0, #0
    b.ne terminal_raw_failed
    
    mov x0, #0                  // Success
    b terminal_raw_exit
    
terminal_raw_failed:
    mov x0, #-1                 // Failure
    
terminal_raw_exit:
    ldr x19, [sp, #16]          // Restore x19
    ldp x29, x30, [sp], #32     // Restore frame pointer and link register
    ret

/*
 * Restore terminal to original mode
 * Parameters: none
 * Returns: none
 */
_terminal_restore:
    stp x29, x30, [sp, #-16]!   // Save frame pointer and link register
    mov x29, sp                 // Set frame pointer
    
    // Restore original terminal settings
    mov x0, #0                  // STDIN
    movz x1, #0x8006, lsl #16   // TIOCSETA high bits
    movk x1, #0x7409            // TIOCSETA low bits
    adrp x2, original_termios@PAGE
    add x2, x2, original_termios@PAGEOFF
    bl _sys_ioctl
    
    ldp x29, x30, [sp], #16     // Restore frame pointer and link register
    ret

/*
 * Clear terminal screen
 * Parameters: none
 * Returns: none
 */
_terminal_clear:
    stp x29, x30, [sp, #-16]!   // Save frame pointer and link register
    mov x29, sp                 // Set frame pointer
    
    adrp x0, clear_screen@PAGE
    add x0, x0, clear_screen@PAGEOFF
    mov x1, #clear_screen_len
    bl _print_string
    
    ldp x29, x30, [sp], #16     // Restore frame pointer and link register
    ret

/*
 * Hide cursor
 * Parameters: none
 * Returns: none
 */
_cursor_hide:
    stp x29, x30, [sp, #-16]!   // Save frame pointer and link register
    mov x29, sp                 // Set frame pointer
    
    adrp x0, hide_cursor@PAGE
    add x0, x0, hide_cursor@PAGEOFF
    mov x1, #hide_cursor_len
    bl _print_string
    
    ldp x29, x30, [sp], #16     // Restore frame pointer and link register
    ret

/*
 * Show cursor
 * Parameters: none
 * Returns: none
 */
_cursor_show:
    stp x29, x30, [sp, #-16]!   // Save frame pointer and link register
    mov x29, sp                 // Set frame pointer
    
    adrp x0, show_cursor@PAGE
    add x0, x0, show_cursor@PAGEOFF
    mov x1, #show_cursor_len
    bl _print_string
    
    ldp x29, x30, [sp], #16     // Restore frame pointer and link register
    ret

/*
 * Read input from terminal (non-blocking)
 * Parameters: none
 * Returns: x0 = number of bytes read, -1 on error
 */
_input_read:
    stp x29, x30, [sp, #-16]!   // Save frame pointer and link register
    mov x29, sp                 // Set frame pointer
    
    mov x0, #0                  // STDIN
    adrp x1, input_buffer@PAGE
    add x1, x1, input_buffer@PAGEOFF
    mov x2, #256                // Buffer size
    bl _sys_read
    
    ldp x29, x30, [sp], #16     // Restore frame pointer and link register
    ret

/*
 * Process input and update game state
 * Parameters: none
 * Returns: x0 = action code (0=none, 1=direction, 2=pause, 3=quit)
 */
_input_process:
    stp x29, x30, [sp, #-32]!   // Save frame pointer and link register
    mov x29, sp                 // Set frame pointer
    str x19, [sp, #16]          // Save x19
    str x20, [sp, #24]          // Save x20
    
    // Read input
    bl _input_read
    cmp x0, #0
    b.le input_process_none     // Branch if no input
    
    mov x19, x0                 // Save bytes read
    adrp x20, input_buffer@PAGE
    add x20, x20, input_buffer@PAGEOFF
    
    // Check for escape sequences (arrow keys)
    ldrb w0, [x20]              // Load first byte
    cmp x0, #27                 // Check for ESC
    b.eq input_process_escape   // Branch if escape sequence
    
    // Process single character
    mov x1, x0                  // Character to process
    bl _input_map_key
    b input_process_exit
    
input_process_escape:
    cmp x19, #3                 // Check if we have full escape sequence
    b.lt input_process_none     // Branch if incomplete
    
    ldrb w0, [x20, #1]          // Load second byte
    cmp x0, #91                 // Check for '['
    b.ne input_process_quit     // Branch if not arrow key (treat as ESC)
    
    ldrb w1, [x20, #2]          // Load third byte (arrow key code)
    bl _input_map_key
    b input_process_exit
    
input_process_none:
    mov x0, #0                  // No action
    b input_process_exit
    
input_process_quit:
    mov x0, #3                  // Quit action
    
input_process_exit:
    ldr x20, [sp, #24]          // Restore x20
    ldr x19, [sp, #16]          // Restore x19
    ldp x29, x30, [sp], #32     // Restore frame pointer and link register
    ret

/*
 * Map key code to action
 * Parameters: x1 = key code
 * Returns: x0 = action code
 */
_input_map_key:
    stp x29, x30, [sp, #-16]!   // Save frame pointer and link register
    mov x29, sp                 // Set frame pointer
    
    adrp x0, key_mappings@PAGE
    add x0, x0, key_mappings@PAGEOFF
    
map_key_loop:
    ldr x2, [x0]                // Load key code from table
    cmp x2, #0                  // Check for end marker
    b.eq map_key_none           // Branch if end reached
    
    cmp x1, x2                  // Compare with input key
    b.eq map_key_found          // Branch if match found
    
    add x0, x0, #16             // Move to next entry
    b map_key_loop
    
map_key_found:
    ldr x3, [x0, #8]            // Load action code
    cmp x3, #100                // Check if special action
    b.ge map_key_special        // Branch if special action
    
    // Direction change
    bl _input_update_direction
    mov x0, #1                  // Direction action
    b map_key_exit
    
map_key_special:
    cmp x3, #100                // Pause action
    b.eq map_key_pause
    mov x0, #3                  // Quit action
    b map_key_exit
    
map_key_pause:
    bl _input_toggle_pause
    mov x0, #2                  // Pause action
    b map_key_exit
    
map_key_none:
    mov x0, #0                  // No action
    
map_key_exit:
    ldp x29, x30, [sp], #16     // Restore frame pointer and link register
    ret

/*
 * Update game direction
 * Parameters: x3 = new direction
 * Returns: none
 */
_input_update_direction:
    stp x29, x30, [sp, #-16]!   // Save frame pointer and link register
    mov x29, sp                 // Set frame pointer
    
    adrp x0, game_state@PAGE
    add x0, x0, game_state@PAGEOFF
    ldr x1, [x0, #16]           // Load current direction
    
    // Prevent reverse direction
    add x2, x1, x3              // current + new
    cmp x2, #1                  // Check if opposite directions (0+1 or 2+3)
    b.eq direction_invalid
    cmp x2, #5                  // Check if opposite directions (2+3)
    b.eq direction_invalid
    
    // Valid direction change
    str x3, [x0, #16]           // Store new direction
    
direction_invalid:
    ldp x29, x30, [sp], #16     // Restore frame pointer and link register
    ret

/*
 * Toggle pause state
 * Parameters: none
 * Returns: none
 */
_input_toggle_pause:
    adrp x0, game_state@PAGE
    add x0, x0, game_state@PAGEOFF
    ldr x1, [x0, #32]           // Load pause flag
    eor x1, x1, #1              // Toggle bit
    str x1, [x0, #32]           // Store new pause state
    ret