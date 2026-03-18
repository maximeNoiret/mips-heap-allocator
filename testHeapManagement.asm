.data
heap_start: .word 0


.text
.include "macrosHeapManagement.asm"


main:
addi $sp, $sp, -8            # allocate enough in the stack to fit every pointers
heap_init()
sw   $v0, heap_start         # save heap_start pointer

malloc_LI(heap_start, 24)
sw   $v0, 4($sp)             # store pointer to allocated space in stack

malloc_LI(heap_start, 32)    # allocate a second chunk to test first+alloc
sw   $v0, 0($sp)
malloc_LI(heap_start, 16)

# test writing to allocated space
lw   $t0, 4($sp)             # get space pointer
ori  $t1, $t1, 100           # value 100
sw   $t1, 4($t0)             # store 100 in allocated space

free_LR(heap_start, $t0)     # test free firstChunk
lw   $t0, 0($sp)
free_LR(heap_start, $t0)     # test free prevFree

ori	 $v0, $zero, 10          # load syscall code 10 (exit)
syscall                      # exit


.include "libHeapManagement.asm"