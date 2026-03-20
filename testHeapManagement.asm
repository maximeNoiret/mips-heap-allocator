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

addiu $sp, $sp, -64

print("Malloc 16 bytes\n")
malloc_LI(heap, 16)
sw    $v0, 60($sp)

print("test Realloc to 32 bytes\n")
lw    $v0, 60($sp)
realloc_LRI(heap, $v0, 32)

printL(cleanup)
lw    $v0, 60($sp)
free_LR(heap, $v0)

print("Malloc 128 bytes\n")
malloc_LI(heap, 128)
sw    $v0, 60($sp)

print("test Realloc to 64 bytes\n")
lw    $v0, 60($sp)
realloc_LRI(heap, $v0, 64)


# exit
addiu $sp, $sp, 64
ori   $v0, $zero, 10
syscall

.include "libHeapManagement.asm"
