/*
 * Basic functionality test for Snake Game
 * ARM64 Assembly Test Suite
 */

.section __DATA,__data
.align 3

test_message:
    .ascii "Running basic tests...\n"
test_message_len = . - test_message

success_message:
    .ascii "All tests passed!\n"
success_message_len = . - success_message

failure_message:
    .ascii "Tests failed!\n"
failure_message_len = . - failure_message

test_counter:       .quad 0
passed_tests:       .quad 0

.section __TEXT,__text
.align 2
.global _test_main
.global _test_memory, _test_gamedata, _test_display

/*
 * Main test entry point
 * Parameters: none
 * Returns: x0 = 0 on success, 1 on failure
 */
_test_main:
    stp x29, x30, [sp, #-16]!   // Save frame pointer and link register
    mov x29, sp                 // Set frame pointer
    
    // Print test start message
    adrp x0, test_message@PAGE
    add x0, x0, test_message@PAGEOFF
    mov x1, #test_message_len
    bl _print_string
    
    // Initialize systems for testing
    mov x0, #1024               // Small memory pool for testing
    bl _memory_init
    
    // Run tests
    bl _test_memory
    bl _test_gamedata
    bl _test_display
    
    // Check results
    adrp x0, test_counter@PAGE
    add x0, x0, test_counter@PAGEOFF
    ldr x1, [x0]                // Total tests
    
    adrp x0, passed_tests@PAGE
    add x0, x0, passed_tests@PAGEOFF
    ldr x2, [x0]                // Passed tests
    
    cmp x1, x2                  // Compare total vs passed
    b.ne test_failure
    
    // All tests passed
    adrp x0, success_message@PAGE
    add x0, x0, success_message@PAGEOFF
    mov x1, #success_message_len
    bl _print_string
    
    mov x0, #0                  // Success
    b test_exit
    
test_failure:
    adrp x0, failure_message@PAGE
    add x0, x0, failure_message@PAGEOFF
    mov x1, #failure_message_len
    bl _print_string
    
    mov x0, #1                  // Failure
    
test_exit:
    bl _memory_cleanup
    ldp x29, x30, [sp], #16     // Restore frame pointer and link register
    ret

/*
 * Test memory management functions
 * Parameters: none
 * Returns: none
 */
_test_memory:
    stp x29, x30, [sp, #-16]!   // Save frame pointer and link register
    mov x29, sp                 // Set frame pointer
    
    // Increment test counter
    bl _increment_test_counter
    
    // Test memory allocation
    mov x0, #64                 // Allocate 64 bytes
    bl _memory_alloc
    cmp x0, #0                  // Check if allocation succeeded
    b.eq memory_test_failed
    
    // Test memory can be written to
    mov x1, #0x12345678
    str x1, [x0]                // Write test value
    ldr x2, [x0]                // Read back
    cmp x1, x2                  // Compare
    b.ne memory_test_failed
    
    // Memory test passed
    bl _increment_passed_counter
    b memory_test_exit
    
memory_test_failed:
    // Test failed - counter already incremented
    
memory_test_exit:
    ldp x29, x30, [sp], #16     // Restore frame pointer and link register
    ret

/*
 * Test game data structures
 * Parameters: none
 * Returns: none
 */
_test_gamedata:
    stp x29, x30, [sp, #-16]!   // Save frame pointer and link register
    mov x29, sp                 // Set frame pointer
    
    // Increment test counter
    bl _increment_test_counter
    
    // Test game state initialization
    bl _game_state_init
    
    // Test snake initialization
    mov x0, #10                 // start_x
    mov x1, #10                 // start_y
    mov x2, #3                  // initial_length
    bl _snake_init
    cmp x0, #0                  // Check if initialization succeeded
    b.ne gamedata_test_failed
    
    // Test board functions
    mov x0, #5                  // x
    mov x1, #5                  // y
    mov x2, #'X'                // character
    bl _board_set
    
    mov x0, #5                  // x
    mov x1, #5                  // y
    bl _board_get
    cmp x0, #'X'                // Check if character was set correctly
    b.ne gamedata_test_failed
    
    // Game data test passed
    bl _increment_passed_counter
    b gamedata_test_exit
    
gamedata_test_failed:
    // Test failed - counter already incremented
    
gamedata_test_exit:
    ldp x29, x30, [sp], #16     // Restore frame pointer and link register
    ret

/*
 * Test display functions
 * Parameters: none
 * Returns: none
 */
_test_display:
    stp x29, x30, [sp, #-16]!   // Save frame pointer and link register
    mov x29, sp                 // Set frame pointer
    
    // Increment test counter
    bl _increment_test_counter
    
    // Test number to string conversion
    mov x0, #12345              // Test number
    bl _number_to_string
    cmp x0, #5                  // Should return length 5
    b.ne display_test_failed
    
    // Display test passed
    bl _increment_passed_counter
    b display_test_exit
    
display_test_failed:
    // Test failed - counter already incremented
    
display_test_exit:
    ldp x29, x30, [sp], #16     // Restore frame pointer and link register
    ret

/*
 * Increment test counter
 * Parameters: none
 * Returns: none
 */
_increment_test_counter:
    adrp x0, test_counter@PAGE
    add x0, x0, test_counter@PAGEOFF
    ldr x1, [x0]
    add x1, x1, #1
    str x1, [x0]
    ret

/*
 * Increment passed test counter
 * Parameters: none
 * Returns: none
 */
_increment_passed_counter:
    adrp x0, passed_tests@PAGE
    add x0, x0, passed_tests@PAGEOFF
    ldr x1, [x0]
    add x1, x1, #1
    str x1, [x0]
    ret