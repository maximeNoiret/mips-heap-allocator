.data
heap: .word 0


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

main:

heap_init()
sw   $v0, heap

addi $sp, $sp, -64

print("Malloc 16 bytes\n")
malloc_LI(heap, 16)
sw    $v0, 60($sp)

print("test Realloc to 32 bytes\n")
lw    $v0, 60($sp)
realloc_LRI(heap, $v0, 32)


# exit
ori   $v0, $zero, 10
syscall

.include "libHeapManagement.asm"
