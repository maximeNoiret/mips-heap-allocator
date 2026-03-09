.data
heap_start: .word 0


.text
.include "macrosHeapManagement.asm"



# Offsets
# - 8: first allocated chunk
# - 4: second allocated chunk
# - 0: third allocated chunk

main:
addi $sp, $sp, -12            # allocate enough in the stack to fit every pointers
heap_init()
sw   $v0, heap_start         # save heap_start pointer

malloc_LI(heap_start, 128)
sw   $v0, 8($sp)
malloc_LI(heap_start, 32)
sw   $v0, 4($sp)
malloc_LI(heap_start, 32)
malloc_LI(heap_start, 32)
sw   $v0, 0($sp)
malloc_LI(heap_start, 32)

lw   $t0, 4($sp)
free_LR(heap_start, $t0)     # free third chunk to test <-[ALLOC],[TARGET],[ALLOC]...[UNALLOC]->

lw   $t0, 0($sp)
free_LR(heap_start, $t0)     # free middle chunk to test [ALLOC],[UNALLOC],[ALLOC],[TARGET][ALLOC][UNALLOC]->

ori	 $v0, $zero, 10          # load syscall code 10 (exit)
syscall                      # exit


.include "libHeapManagement.asm"
