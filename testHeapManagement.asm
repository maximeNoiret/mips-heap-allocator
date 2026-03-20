.data
heap: .word 0
cleanup: .asciiz "\n\nCleanup\n\n"


.text
.include "macrosMemoryManagement.asm"
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

ori   $t0, $zero, 13
sw    $t0, 0($s0)
ori   $t0, $zero, 26
sw    $t0, 4($s0)
ori   $t0, $zero, 54
sw    $t0, 8($s0)
ori   $t0, $zero, 876
sw    $t0, 12($s0)

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

print("Malloc 32 bytes\n")
malloc_LI(heap, 32)
or    $s1, $zero, $v0

print("test Realloc first chunk back to 128 bytes (test move)\n")
realloc_LRI(heap, $s0, 128)
or    $s0, $zero, $v0


# exit
addiu $sp, $sp, 64
ori   $v0, $zero, 10
syscall

.include "libMemoryManagement.asm"
.include "libHeapManagement.asm"
