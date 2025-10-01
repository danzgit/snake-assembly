/*
 * Memory Management System for Snake Game
 * ARM64 Assembly Implementation
 * Custom heap allocator and memory pool management
 */

.section __DATA,__data
.align 3

/* Memory pool globals */
memory_pool_start:      .quad 0     // Start of memory pool
memory_pool_end:        .quad 0     // End of memory pool  
memory_pool_current:    .quad 0     // Current allocation pointer
memory_pool_size:       .quad 4096  // Default pool size (4KB)

/* Allocation tracking */
total_allocated:        .quad 0     // Total bytes allocated
total_freed:            .quad 0     // Total bytes freed
allocation_count:       .quad 0     // Number of allocations

.section __TEXT,__text
.align 2
.global _memory_init, _memory_alloc, _memory_free, _memory_cleanup

/*
 * Initialize memory management system
 * Parameters: x0 = pool size (bytes)
 * Returns: x0 = 0 on success, -1 on failure
 */
_memory_init:
    stp x29, x30, [sp, #-16]!   // Save frame pointer and link register
    mov x29, sp                 // Set frame pointer
    
    // Store requested pool size
    adrp x1, memory_pool_size@PAGE
    add x1, x1, memory_pool_size@PAGEOFF
    str x0, [x1]
    
    // Allocate memory pool using mmap (simplified - using stack for now)
    // In a full implementation, we would use mmap system call
    // For this demo, we'll use a large static buffer
    
    adrp x1, memory_pool_buffer@PAGE
    add x1, x1, memory_pool_buffer@PAGEOFF
    
    // Set pool start
    adrp x2, memory_pool_start@PAGE
    add x2, x2, memory_pool_start@PAGEOFF
    str x1, [x2]
    
    // Set pool current to start
    adrp x2, memory_pool_current@PAGE
    add x2, x2, memory_pool_current@PAGEOFF
    str x1, [x2]
    
    // Set pool end
    add x1, x1, x0              // end = start + size
    adrp x2, memory_pool_end@PAGE
    add x2, x2, memory_pool_end@PAGEOFF
    str x1, [x2]
    
    // Initialize counters
    adrp x1, total_allocated@PAGE
    add x1, x1, total_allocated@PAGEOFF
    str xzr, [x1]
    
    adrp x1, total_freed@PAGE
    add x1, x1, total_freed@PAGEOFF
    str xzr, [x1]
    
    adrp x1, allocation_count@PAGE
    add x1, x1, allocation_count@PAGEOFF
    str xzr, [x1]
    
    mov x0, #0                  // Success
    ldp x29, x30, [sp], #16     // Restore frame pointer and link register
    ret

/*
 * Allocate memory from pool
 * Parameters: x0 = size in bytes
 * Returns: x0 = pointer to allocated memory or 0 on failure
 */
_memory_alloc:
    stp x29, x30, [sp, #-16]!   // Save frame pointer and link register
    mov x29, sp                 // Set frame pointer
    
    // Align size to 8-byte boundary
    add x0, x0, #7              // Add 7 for alignment
    and x0, x0, #~7             // Clear lower 3 bits
    
    // Check if we have enough space
    adrp x1, memory_pool_current@PAGE
    add x1, x1, memory_pool_current@PAGEOFF
    ldr x2, [x1]                // Current pointer
    
    adrp x3, memory_pool_end@PAGE
    add x3, x3, memory_pool_end@PAGEOFF
    ldr x4, [x3]                // End pointer
    
    add x5, x2, x0              // New current = current + size
    cmp x5, x4                  // Compare with end
    b.hi alloc_failed           // Branch if not enough space
    
    // Update current pointer
    str x5, [x1]
    
    // Update allocation tracking
    adrp x1, total_allocated@PAGE
    add x1, x1, total_allocated@PAGEOFF
    ldr x3, [x1]
    add x3, x3, x0
    str x3, [x1]
    
    adrp x1, allocation_count@PAGE
    add x1, x1, allocation_count@PAGEOFF
    ldr x3, [x1]
    add x3, x3, #1
    str x3, [x1]
    
    mov x0, x2                  // Return allocated pointer
    b alloc_exit
    
alloc_failed:
    mov x0, #0                  // Return null pointer
    
alloc_exit:
    ldp x29, x30, [sp], #16     // Restore frame pointer and link register
    ret

/*
 * Free memory (simplified - just updates counters)
 * Parameters: x0 = pointer to free, x1 = size
 * Returns: none
 */
_memory_free:
    stp x29, x30, [sp, #-16]!   // Save frame pointer and link register
    mov x29, sp                 // Set frame pointer
    
    // In a full implementation, we would track free blocks
    // For simplicity, we just update the freed counter
    adrp x2, total_freed@PAGE
    add x2, x2, total_freed@PAGEOFF
    ldr x3, [x2]
    add x3, x3, x1
    str x3, [x2]
    
    ldp x29, x30, [sp], #16     // Restore frame pointer and link register
    ret

/*
 * Cleanup memory management system
 * Parameters: none
 * Returns: none
 */
_memory_cleanup:
    stp x29, x30, [sp, #-16]!   // Save frame pointer and link register
    mov x29, sp                 // Set frame pointer
    
    // Reset all pointers and counters
    adrp x0, memory_pool_start@PAGE
    add x0, x0, memory_pool_start@PAGEOFF
    str xzr, [x0]
    
    adrp x0, memory_pool_end@PAGE
    add x0, x0, memory_pool_end@PAGEOFF
    str xzr, [x0]
    
    adrp x0, memory_pool_current@PAGE
    add x0, x0, memory_pool_current@PAGEOFF
    str xzr, [x0]
    
    adrp x0, total_allocated@PAGE
    add x0, x0, total_allocated@PAGEOFF
    str xzr, [x0]
    
    adrp x0, total_freed@PAGE
    add x0, x0, total_freed@PAGEOFF
    str xzr, [x0]
    
    adrp x0, allocation_count@PAGE
    add x0, x0, allocation_count@PAGEOFF
    str xzr, [x0]
    
    ldp x29, x30, [sp], #16     // Restore frame pointer and link register
    ret

/*
 * Get memory statistics
 * Parameters: x0 = pointer to stats structure
 * Returns: none
 */
.global _memory_get_stats
_memory_get_stats:
    stp x29, x30, [sp, #-16]!   // Save frame pointer and link register
    mov x29, sp                 // Set frame pointer
    
    // Store total allocated
    adrp x1, total_allocated@PAGE
    add x1, x1, total_allocated@PAGEOFF
    ldr x2, [x1]
    str x2, [x0]
    
    // Store total freed
    adrp x1, total_freed@PAGE
    add x1, x1, total_freed@PAGEOFF
    ldr x2, [x1]
    str x2, [x0, #8]
    
    // Store allocation count
    adrp x1, allocation_count@PAGE
    add x1, x1, allocation_count@PAGEOFF
    ldr x2, [x1]
    str x2, [x0, #16]
    
    // Calculate and store current usage
    adrp x1, memory_pool_start@PAGE
    add x1, x1, memory_pool_start@PAGEOFF
    ldr x1, [x1]
    
    adrp x2, memory_pool_current@PAGE
    add x2, x2, memory_pool_current@PAGEOFF
    ldr x2, [x2]
    
    sub x3, x2, x1              // current_usage = current - start
    str x3, [x0, #24]
    
    ldp x29, x30, [sp], #16     // Restore frame pointer and link register
    ret

.section __DATA,__data
.align 3

/* Static memory buffer (4KB) */
memory_pool_buffer:
    .space 4096, 0