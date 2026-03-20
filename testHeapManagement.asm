.data
heap: .word 0
cleanup: .asciiz "\n\nCleanup\n\n"


.text
.include "macrosHeapManagement.asm"

# EXTREMELY DIRTY PRINT MACRO
.macro print(%text)
  .data
  text: .asciiz %text
  .text
  ori $v0, $zero, 4
  la $a0, text
  syscall
.end_macro

.macro printL(%label)
  ori   $v0, $zero, 4
  la    $a0, cleanup
  syscall
.end_macro

main:

heap_init()
sw    $v0, heap

print("Malloc 16 bytes\n")
malloc_LI(heap, 16)
or    $s0, $zero, $v0

print("test Realloc to 16 bytes (same)\n")
realloc_LRI(heap, $s0, 16)
or    $s0, $zero, $v0

print("test Realloc to 32 bytes\n")
realloc_LRI(heap, $s0, 32)
or    $s0, $zero, $v0

printL(cleanup)
free_LR(heap, $s0)

print("Malloc 128 bytes\n")
malloc_LI(heap, 128)
or    $s0, $zero, $v0

print("test Realloc to 64 bytes\n")
realloc_LRI(heap, $s0, 64)
or    $s0, $zero, $v0


# exit
addiu $sp, $sp, 64
ori   $v0, $zero, 10
syscall

.include "libHeapManagement.asm"
