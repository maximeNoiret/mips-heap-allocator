.data
heap_start: .word 0


.text
.include "macrosHeapManagement.asm"


main:

heap_init()
sw   $v0, heap_start

addi $sp, $sp, -64

# --- TEST 1: Middle Chunk - No Coalescing (Both Neighbors Allocated) ---
malloc_LI(heap_start, 16)    # Left neighbor (Keep)
malloc_LI(heap_start, 16)    # Target
sw $v0, 4($sp)
malloc_LI(heap_start, 16)    # Right neighbor (Keep)

lw $t0, 4($sp)
free_LR(heap_start, $t0)     # Verify: Target is free, neighbors remain allocated

# --- TEST 2: Middle Chunk - Coalesce Left (Left Neighbor Free) ---
malloc_LI(heap_start, 16)    # Left neighbor
sw $v0, 8($sp)
malloc_LI(heap_start, 16)    # Target
sw $v0, 12($sp)
malloc_LI(heap_start, 16)    # Right neighbor (Keep)

lw $t0, 8($sp)
free_LR(heap_start, $t0)     # Free left
lw $t0, 12($sp)
free_LR(heap_start, $t0)    # Verify: Target merges into Left

# --- TEST 3: Middle Chunk - Coalesce Right (Right Neighbor Free) ---
malloc_LI(heap_start, 16)    # Left neighbor (Keep)
malloc_LI(heap_start, 16)    # Target
sw $v0, 16($sp)
malloc_LI(heap_start, 16)    # Right neighbor
sw $v0, 20($sp)

lw $t0, 20($sp)
free_LR(heap_start, $t0)     # Free right
lw $t0, 16($sp)
free_LR(heap_start, $t0)    # Verify: Target merges into Right

# --- TEST 4: Middle Chunk - Double Coalesce (Both Neighbors Free) ---
malloc_LI(heap_start, 16)    # Left
sw $v0, 24($sp)
malloc_LI(heap_start, 16)    # Target
sw $v0, 28($sp)
malloc_LI(heap_start, 16)    # Right
sw $v0, 32($sp)

lw $t0, 24($sp)
free_LR(heap_start, $t0)     # Free left
lw $t0, 32($sp)
free_LR(heap_start, $t0)     # Free right
lw $t0, 28($sp)
free_LR(heap_start, $t0)    # Verify: All three merge into one block

# --- TEST 5: Boundary - First Chunk in Heap ---
malloc_LI(heap_start, 16)    # Target (Is at heap_start)
sw $v0, 36($sp)
malloc_LI(heap_start, 16)    # Right neighbor (Keep)

lw $t0, 36($sp)
free_LR(heap_start, $t0)     # Verify: Previous null check works

# --- TEST 6: Boundary - Last Chunk in Heap ---
malloc_LI(heap_start, 16)    # Left neighbor (Keep)
malloc_LI(heap_start, 16)    # Target (Is at end of current allocations)
sw $v0, 40($sp)

lw $t0, 40($sp)
free_LR(heap_start, $t0)     # Verify: Next null check works

# --- TEST 7: Single Chunk - Emptying Heap ---
malloc_LI(heap_start, 64)    # Target
sw $v0, 44($sp)

lw $t0, 44($sp)
free_LR(heap_start, $t0)     # Verify: Heap returns to fully free state

ori	 $v0, $zero, 10          # load syscall code 10 (exit)
syscall                      # exit


.include "libHeapManagement.asm"
