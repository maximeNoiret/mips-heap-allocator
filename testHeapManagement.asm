main:
jal  heap_init               # call heap_init
or   $s0, $zero, $v0         # save heap_start pointer

or   $a0, $zero, $s0         # set heap_start as arg0
ori  $a1, $zero, 24          # set 24 as size to allocate
jal  heap_malloc             # malloc($s0, 24)
addi $sp, $sp, -4            # allocate 4 bytes in stack
sw   $v0, 0($sp)             # store pointer to allocated space in stack

# test writing to allocated space
lw   $t0, 0($sp)             # get space pointer
ori  $t1, $t1, 100           # value 100
sw   $t1, 0($t0)             # store 100 in allocated space?


ori	 $v0, $zero, 10          # load syscall code 10 (exit)
syscall                      # exit



.include "libHeapManagement.asm"