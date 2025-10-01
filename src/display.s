/*
 * Display Manager - Terminal rendering and ANSI escape sequences
 * ARM64 Assembly Implementation for macOS
 */

.section __DATA,__data
.align 3

/* Display buffer */
display_buffer:
    .space 8192, 0              // 8KB display buffer

/* ANSI escape sequences */
cursor_home:
    .ascii "\033[H"             // Move cursor to home position
cursor_home_len = . - cursor_home

color_reset:
    .ascii "\033[0m"            // Reset colors
color_reset_len = . - color_reset

color_red:
    .ascii "\033[31m"           // Red foreground
color_red_len = . - color_red

color_green:
    .ascii "\033[32m"           // Green foreground
color_green_len = . - color_green

color_yellow:
    .ascii "\033[33m"           // Yellow foreground
color_yellow_len = . - color_yellow

color_blue:
    .ascii "\033[34m"           // Blue foreground
color_blue_len = . - color_blue

color_magenta:
    .ascii "\033[35m"           // Magenta foreground
color_magenta_len = . - color_magenta

color_cyan:
    .ascii "\033[36m"           // Cyan foreground
color_cyan_len = . - color_cyan

color_white:
    .ascii "\033[37m"           // White foreground
color_white_len = . - color_white

/* UI text strings */
title_text:
    .ascii "SNAKE GAME - ARM64 Assembly"
title_text_len = . - title_text

menu_text:
    .ascii "Press SPACE to start, Q to quit"
menu_text_len = . - menu_text

game_over_text:
    .ascii "GAME OVER! Press SPACE to restart, Q to quit"
game_over_text_len = . - game_over_text

pause_text:
    .ascii "PAUSED - Press SPACE to continue"
pause_text_len = . - pause_text

score_text:
    .ascii "Score: "
score_text_len = . - score_text

/* Number conversion buffer */
number_buffer:
    .space 32, 0

.section __TEXT,__text
.align 2
.global _display_init, _display_cleanup, _display_render, _display_menu
.global _display_game_over, _display_pause, _cursor_move, _set_color
.global _display_snake, _display_food, _display_score, _number_to_string

/*
 * Initialize display system
 * Parameters: none
 * Returns: x0 = 0 on success, -1 on failure
 */
_display_init:
    stp x29, x30, [sp, #-16]!   // Save frame pointer and link register
    mov x29, sp                 // Set frame pointer
    
    // Clear screen and hide cursor
    bl _terminal_clear
    bl _cursor_hide
    
    mov x0, #0                  // Success
    ldp x29, x30, [sp], #16     // Restore frame pointer and link register
    ret

/*
 * Cleanup display system
 * Parameters: none
 * Returns: none
 */
_display_cleanup:
    stp x29, x30, [sp, #-16]!   // Save frame pointer and link register
    mov x29, sp                 // Set frame pointer
    
    // Show cursor and reset colors
    bl _cursor_show
    adrp x0, color_reset@PAGE
    add x0, x0, color_reset@PAGEOFF
    mov x1, #color_reset_len
    bl _print_string
    
    ldp x29, x30, [sp], #16     // Restore frame pointer and link register
    ret

/*
 * Move cursor to specific position
 * Parameters: x0 = row (0-based), x1 = column (0-based)
 * Returns: none
 */
_cursor_move:
    stp x29, x30, [sp, #-16]!   // Save frame pointer and link register
    mov x29, sp                 // Set frame pointer
    
    // Build escape sequence: ESC[row;colH
    adrp x2, display_buffer@PAGE
    add x2, x2, display_buffer@PAGEOFF
    
    mov w3, #27                 // ESC
    strb w3, [x2], #1
    mov w3, #91                 // '['
    strb w3, [x2], #1
    
    // Convert row to string
    add x0, x0, #1              // Convert to 1-based
    mov x3, x2                  // Save position
    bl _number_to_string
    add x2, x3, x0              // Update buffer position
    
    mov w3, #59                 // ';'
    strb w3, [x2], #1
    
    // Convert column to string
    add x1, x1, #1              // Convert to 1-based
    mov x3, x2                  // Save position
    mov x0, x1                  // Column value
    bl _number_to_string
    add x2, x3, x0              // Update buffer position
    
    mov w3, #72                 // 'H'
    strb w3, [x2], #1
    
    // Calculate length and print
    adrp x0, display_buffer@PAGE
    add x0, x0, display_buffer@PAGEOFF
    sub x1, x2, x0              // Calculate length
    bl _print_string
    
    ldp x29, x30, [sp], #16     // Restore frame pointer and link register
    ret

/*
 * Set text color
 * Parameters: x0 = color code (0=reset, 1=red, 2=green, 3=yellow, 4=blue, 5=magenta, 6=cyan, 7=white)
 * Returns: none
 */
_set_color:
    stp x29, x30, [sp, #-16]!   // Save frame pointer and link register
    mov x29, sp                 // Set frame pointer
    
    // Jump table for colors
    cmp x0, #7
    b.hi set_color_reset        // Use reset if invalid
    
    lsl x1, x0, #4              // color * 16 (16 bytes per entry)
    adr x2, color_table
    ldr x3, [x2, x1]            // Load address
    add x5, x2, x1              // Calculate base address
    ldr x4, [x5, #8]            // Load length
    
    mov x0, x3                  // Color string address
    mov x1, x4                  // Color string length
    bl _print_string
    b set_color_exit
    
set_color_reset:
    adrp x0, color_reset@PAGE
    add x0, x0, color_reset@PAGEOFF
    mov x1, #color_reset_len
    bl _print_string
    
set_color_exit:
    ldp x29, x30, [sp], #16     // Restore frame pointer and link register
    ret

/* Color table for jump table */
.align 3
color_table:
    .quad color_reset, color_reset_len
    .quad color_red, color_red_len
    .quad color_green, color_green_len
    .quad color_yellow, color_yellow_len
    .quad color_blue, color_blue_len
    .quad color_magenta, color_magenta_len
    .quad color_cyan, color_cyan_len
    .quad color_white, color_white_len

/*
 * Render main game screen
 * Parameters: none
 * Returns: none
 */
_display_render:
    stp x29, x30, [sp, #-16]!   // Save frame pointer and link register
    mov x29, sp                 // Set frame pointer
    
    // Move cursor to home
    adrp x0, cursor_home@PAGE
    add x0, x0, cursor_home@PAGEOFF
    mov x1, #cursor_home_len
    bl _print_string
    
    // Display score
    bl _display_score
    
    // Display game board
    bl _display_board
    
    // Display snake
    bl _display_snake
    
    // Display food
    bl _display_food
    
    ldp x29, x30, [sp], #16     // Restore frame pointer and link register
    ret

/*
 * Display game board
 * Parameters: none
 * Returns: none
 */
_display_board:
    stp x29, x30, [sp, #-32]!   // Save frame pointer and link register
    mov x29, sp                 // Set frame pointer
    str x19, [sp, #16]          // Save x19
    str x20, [sp, #24]          // Save x20
    
    mov x19, #0                 // Row counter
    
board_row_loop:
    cmp x19, #25                // Check if all rows processed
    b.ge board_done             // Branch if done
    
    // Move cursor to start of row
    add x0, x19, #2             // Row + 2 (skip score line)
    mov x1, #0                  // Column 0
    bl _cursor_move
    
    mov x20, #0                 // Column counter
    
board_col_loop:
    cmp x20, #80                // Check if all columns processed
    b.ge board_next_row         // Branch if done with row
    
    // Get character from board
    mov x0, x20                 // x coordinate
    mov x1, x19                 // y coordinate
    bl _board_get
    
    // Print character
    bl _print_char
    
    add x20, x20, #1            // Increment column
    b board_col_loop
    
board_next_row:
    add x19, x19, #1            // Increment row
    b board_row_loop
    
board_done:
    ldr x20, [sp, #24]          // Restore x20
    ldr x19, [sp, #16]          // Restore x19
    ldp x29, x30, [sp], #32     // Restore frame pointer and link register
    ret

/*
 * Display snake
 * Parameters: none
 * Returns: none
 */
_display_snake:
    stp x29, x30, [sp, #-32]!   // Save frame pointer and link register
    mov x29, sp                 // Set frame pointer
    str x19, [sp, #16]          // Save x19
    str x20, [sp, #24]          // Save x20
    
    // Set snake color (green)
    mov x0, #2
    bl _set_color
    
    // Get snake head
    adrp x0, game_state@PAGE
    add x0, x0, game_state@PAGEOFF
    ldr x19, [x0, #40]          // Load head pointer
    
    mov x20, #1                 // Segment counter (1 = head)
    
snake_segment_loop:
    cmp x19, #0                 // Check if end of snake
    b.eq snake_done             // Branch if done
    
    // Get segment coordinates
    ldr x0, [x19]               // x coordinate
    ldr x1, [x19, #8]           // y coordinate
    
    // Move cursor to segment position
    add x1, x1, #2              // Add offset for score line
    bl _cursor_move
    
    // Draw appropriate character
    cmp x20, #1                 // Check if head
    b.eq snake_draw_head
    
    // Draw body segment
    mov x0, #'o'                // Body character
    bl _print_char
    b snake_next_segment
    
snake_draw_head:
    mov x0, #'O'                // Head character
    bl _print_char
    
snake_next_segment:
    ldr x19, [x19, #16]         // Move to next segment
    add x20, x20, #1            // Increment counter
    b snake_segment_loop
    
snake_done:
    // Reset color
    mov x0, #0
    bl _set_color
    
    ldr x20, [sp, #24]          // Restore x20
    ldr x19, [sp, #16]          // Restore x19
    ldp x29, x30, [sp], #32     // Restore frame pointer and link register
    ret

/*
 * Display food
 * Parameters: none
 * Returns: none
 */
_display_food:
    stp x29, x30, [sp, #-16]!   // Save frame pointer and link register
    mov x29, sp                 // Set frame pointer
    
    // Set food color (red)
    mov x0, #1
    bl _set_color
    
    // Get food coordinates
    adrp x0, game_state@PAGE
    add x0, x0, game_state@PAGEOFF
    ldr x1, [x0, #64]           // food_x
    ldr x2, [x0, #72]           // food_y
    
    // Move cursor to food position
    mov x0, x2                  // y coordinate
    add x0, x0, #2              // Add offset for score line
    bl _cursor_move
    
    // Draw food
    mov x0, #'*'                // Food character
    bl _print_char
    
    // Reset color
    mov x0, #0
    bl _set_color
    
    ldp x29, x30, [sp], #16     // Restore frame pointer and link register
    ret

/*
 * Display score
 * Parameters: none
 * Returns: none
 */
_display_score:
    stp x29, x30, [sp, #-16]!   // Save frame pointer and link register
    mov x29, sp                 // Set frame pointer
    
    // Move cursor to top-left
    mov x0, #0                  // Row 0
    mov x1, #0                  // Column 0
    bl _cursor_move
    
    // Print "Score: " text
    adrp x0, score_text@PAGE
    add x0, x0, score_text@PAGEOFF
    mov x1, #score_text_len
    bl _print_string
    
    // Get and display score
    adrp x0, game_state@PAGE
    add x0, x0, game_state@PAGEOFF
    ldr x0, [x0, #8]            // Load score
    bl _number_to_string_print
    
    ldp x29, x30, [sp], #16     // Restore frame pointer and link register
    ret

/*
 * Display menu screen
 * Parameters: none
 * Returns: none
 */
_display_menu:
    stp x29, x30, [sp, #-16]!   // Save frame pointer and link register
    mov x29, sp                 // Set frame pointer
    
    // Clear screen
    bl _terminal_clear
    
    // Display title
    mov x0, #5                  // Row 5
    mov x1, #20                 // Column 20
    bl _cursor_move
    
    mov x0, #3                  // Yellow color
    bl _set_color
    
    adrp x0, title_text@PAGE
    add x0, x0, title_text@PAGEOFF
    mov x1, #title_text_len
    bl _print_string
    
    // Display menu options
    mov x0, #12                 // Row 12
    mov x1, #15                 // Column 15
    bl _cursor_move
    
    mov x0, #7                  // White color
    bl _set_color
    
    adrp x0, menu_text@PAGE
    add x0, x0, menu_text@PAGEOFF
    mov x1, #menu_text_len
    bl _print_string
    
    // Reset color
    mov x0, #0
    bl _set_color
    
    ldp x29, x30, [sp], #16     // Restore frame pointer and link register
    ret

/*
 * Display game over screen
 * Parameters: none
 * Returns: none
 */
_display_game_over:
    stp x29, x30, [sp, #-16]!   // Save frame pointer and link register
    mov x29, sp                 // Set frame pointer
    
    // Display game over message
    mov x0, #10                 // Row 10
    mov x1, #10                 // Column 10
    bl _cursor_move
    
    mov x0, #1                  // Red color
    bl _set_color
    
    adrp x0, game_over_text@PAGE
    add x0, x0, game_over_text@PAGEOFF
    mov x1, #game_over_text_len
    bl _print_string
    
    // Reset color
    mov x0, #0
    bl _set_color
    
    ldp x29, x30, [sp], #16     // Restore frame pointer and link register
    ret

/*
 * Display pause screen
 * Parameters: none
 * Returns: none
 */
_display_pause:
    stp x29, x30, [sp, #-16]!   // Save frame pointer and link register
    mov x29, sp                 // Set frame pointer
    
    // Display pause message
    mov x0, #1                  // Row 1
    mov x1, #25                 // Column 25
    bl _cursor_move
    
    mov x0, #3                  // Yellow color
    bl _set_color
    
    adrp x0, pause_text@PAGE
    add x0, x0, pause_text@PAGEOFF
    mov x1, #pause_text_len
    bl _print_string
    
    // Reset color
    mov x0, #0
    bl _set_color
    
    ldp x29, x30, [sp], #16     // Restore frame pointer and link register
    ret

/*
 * Convert number to string
 * Parameters: x0 = number
 * Returns: x0 = string length
 */
_number_to_string:
    stp x29, x30, [sp, #-16]!   // Save frame pointer and link register
    mov x29, sp                 // Set frame pointer
    
    adrp x1, number_buffer@PAGE
    add x1, x1, number_buffer@PAGEOFF
    
    mov x2, #0                  // Character count
    mov x3, #10                 // Base 10
    
    cmp x0, #0                  // Check if zero
    b.ne convert_loop
    
    // Handle zero case
    mov w4, #'0'
    strb w4, [x1]
    mov x0, #1
    b convert_exit
    
convert_loop:
    cmp x0, #0                  // Check if done
    b.eq convert_reverse
    
    udiv x4, x0, x3             // Divide by 10
    msub x5, x4, x3, x0         // Get remainder
    add x5, x5, #'0'            // Convert to ASCII
    strb w5, [x1, x2]           // Store digit
    add x2, x2, #1              // Increment count
    mov x0, x4                  // Continue with quotient
    b convert_loop
    
convert_reverse:
    // Reverse the string
    mov x3, #0                  // Start index
    sub x4, x2, #1              // End index
    
reverse_loop:
    cmp x3, x4                  // Check if done
    b.ge convert_done
    
    ldrb w5, [x1, x3]           // Load start character
    ldrb w6, [x1, x4]           // Load end character
    strb w6, [x1, x3]           // Store end at start
    strb w5, [x1, x4]           // Store start at end
    
    add x3, x3, #1              // Increment start
    sub x4, x4, #1              // Decrement end
    b reverse_loop
    
convert_done:
    mov x0, x2                  // Return length
    
convert_exit:
    ldp x29, x30, [sp], #16     // Restore frame pointer and link register
    ret

/*
 * Convert number to string and print
 * Parameters: x0 = number
 * Returns: none
 */
_number_to_string_print:
    stp x29, x30, [sp, #-16]!   // Save frame pointer and link register
    mov x29, sp                 // Set frame pointer
    
    bl _number_to_string        // Convert to string
    
    adrp x1, number_buffer@PAGE
    add x1, x1, number_buffer@PAGEOFF
    mov x2, x0                  // String length
    mov x0, x1                  // String address
    mov x1, x2                  // String length
    bl _print_string
    
    ldp x29, x30, [sp], #16     // Restore frame pointer and link register
    ret