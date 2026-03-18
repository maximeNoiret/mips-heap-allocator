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

print("test malloc first chunk\n")
malloc_LI(heap, 128)
sw    $v0, 60($sp)
print("test malloc normal\n")
malloc_LI(heap, 32)
sw    $v0, 56($sp)
malloc_LI(heap, 32)
sw    $v0, 52($sp)
malloc_LI(heap, 32)
sw    $v0, 48($sp)
malloc_LI(heap, 32)
sw    $v0, 44($sp)
malloc_LI(heap, 32)
sw    $v0, 40($sp)
malloc_LI(heap, 32)
sw    $v0, 36($sp)
malloc_LI(heap, 32)
sw    $v0, 32($sp)
malloc_LI(heap, 32)
sw    $v0, 28($sp)

print("test free first chunk\n")
lw    $t0, 60($sp)
free_LR(heap, $t0)

print("test free prev_free\n")
lw    $t0, 56($sp)
free_LR(heap, $t0)

print("test free no_free\n")
lw    $t0, 44($sp)
free_LR(heap, $t0)

print("test free next_free\n")
lw    $t0, 48($sp)
free_LR(heap, $t0)

print("test free next_last\n")
lw    $t0, 28($sp)
free_LR(heap, $t0)

# exit
ori   $v0, $zero, 10
syscall

.include "libHeapManagement.asm"
