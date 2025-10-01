/*
 * System Call Interface for macOS ARM64
 * Provides wrapper functions for macOS system calls
 */

.section __DATA,__data
.align 3

/* System call numbers */
.equ SYS_READ,      3
.equ SYS_WRITE,     4
.equ SYS_NANOSLEEP, 240
.equ SYS_IOCTL,     54
.equ SYS_EXIT,      1

/* File descriptors */
.equ STDIN,         0
.equ STDOUT,        1
.equ STDERR,        2

.section __TEXT,__text
.align 2
.global _sys_read, _sys_write, _sys_nanosleep, _sys_ioctl, _sys_exit

/*
 * System call wrapper: read
 * Parameters: x0 = fd, x1 = buffer, x2 = count
 * Returns: x0 = bytes read or -1 on error
 */
_sys_read:
    mov x16, #SYS_READ          // System call number
    svc #0x80                   // Supervisor call
    ret

/*
 * System call wrapper: write
 * Parameters: x0 = fd, x1 = buffer, x2 = count
 * Returns: x0 = bytes written or -1 on error
 */
_sys_write:
    mov x16, #SYS_WRITE         // System call number
    svc #0x80                   // Supervisor call
    ret

/*
 * System call wrapper: nanosleep
 * Parameters: x0 = timespec pointer, x1 = remaining time pointer
 * Returns: x0 = 0 on success, -1 on error
 */
_sys_nanosleep:
    mov x16, #SYS_NANOSLEEP     // System call number
    svc #0x80                   // Supervisor call
    ret

/*
 * System call wrapper: ioctl
 * Parameters: x0 = fd, x1 = request, x2 = argument
 * Returns: x0 = 0 on success, -1 on error
 */
_sys_ioctl:
    mov x16, #SYS_IOCTL         // System call number
    svc #0x80                   // Supervisor call
    ret

/*
 * System call wrapper: exit
 * Parameters: x0 = exit code
 * Returns: does not return
 */
_sys_exit:
    mov x16, #SYS_EXIT          // System call number
    svc #0x80                   // Supervisor call
    // Should not reach here

/*
 * Write string to stdout
 * Parameters: x0 = string pointer, x1 = length
 * Returns: x0 = bytes written
 */
.global _print_string
_print_string:
    stp x29, x30, [sp, #-16]!   // Save frame pointer and link register
    mov x29, sp                 // Set frame pointer
    
    mov x2, x1                  // Length
    mov x1, x0                  // String pointer
    mov x0, #STDOUT             // File descriptor
    bl _sys_write               // Call write system call
    
    ldp x29, x30, [sp], #16     // Restore frame pointer and link register
    ret

/*
 * Write character to stdout
 * Parameters: x0 = character
 * Returns: x0 = bytes written
 */
.global _print_char
_print_char:
    stp x29, x30, [sp, #-16]!   // Save frame pointer and link register
    mov x29, sp                 // Set frame pointer
    
    sub sp, sp, #16             // Allocate space for character
    strb w0, [sp]               // Store character on stack
    
    mov x0, #STDOUT             // File descriptor
    mov x1, sp                  // Character address
    mov x2, #1                  // Length = 1
    bl _sys_write               // Call write system call
    
    add sp, sp, #16             // Deallocate space
    ldp x29, x30, [sp], #16     // Restore frame pointer and link register
    ret

/*
 * Read single character from stdin (non-blocking)
 * Parameters: none
 * Returns: x0 = character or -1 if no input
 */
.global _read_char
_read_char:
    stp x29, x30, [sp, #-16]!   // Save frame pointer and link register
    mov x29, sp                 // Set frame pointer
    
    sub sp, sp, #16             // Allocate space for character
    
    mov x0, #STDIN              // File descriptor
    mov x1, sp                  // Buffer address
    mov x2, #1                  // Length = 1
    bl _sys_read                // Call read system call
    
    cmp x0, #1                  // Check if one byte was read
    b.ne read_char_error        // Branch if not
    
    ldrb w0, [sp]               // Load character
    b read_char_exit
    
read_char_error:
    mov x0, #-1                 // Return -1 on error
    
read_char_exit:
    add sp, sp, #16             // Deallocate space
    ldp x29, x30, [sp], #16     // Restore frame pointer and link register
    ret

/*
 * Sleep for specified milliseconds
 * Parameters: x0 = milliseconds
 * Returns: x0 = 0 on success
 */
.global _sleep_ms
_sleep_ms:
    stp x29, x30, [sp, #-32]!   // Save frame pointer and link register
    mov x29, sp                 // Set frame pointer
    
    // Convert milliseconds to nanoseconds
    movz x1, #0x0F, lsl #16     // 1 million high bits
    movk x1, #0x4240            // 1 million low bits (1,000,000)
    mul x0, x0, x1              // x0 = nanoseconds
    
    // Create timespec structure on stack
    movz x1, #0x3B9A, lsl #16   // 1 billion high bits
    movk x1, #0xCA00            // 1 billion low bits (1,000,000,000)
    udiv x2, x0, x1             // x2 = seconds
    msub x3, x2, x1, x0         // x3 = remaining nanoseconds
    
    stp x2, x3, [sp, #16]       // Store timespec on stack
    
    add x0, sp, #16             // Timespec pointer
    mov x1, #0                  // No remaining time pointer
    bl _sys_nanosleep           // Call nanosleep system call
    
    ldp x29, x30, [sp], #32     // Restore frame pointer and link register
    ret