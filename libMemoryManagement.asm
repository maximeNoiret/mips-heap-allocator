# Function mem_memcpy
# Input:
#     $a0: dest ptr
#     $a1: src ptr
#     $a2: size
# Output:
#     None
# Registers used:
#     $t0: temp value to transfer from src to dest
#     $t1: saved $a0
#     $t2: saved $a1
# Note:
#     $a0 and $a1 and restored for usage convenience.
mem_memcpy:
or    $t1, $zero, $a0                     # save $a0
or    $t2, $zero, $a1                     # save $a1

mem_memcpy_loop:
  beq   $a2, $zero, mem_memcpy_endloop    # while size > 0 {
  lb    $t0, 0($a1)                       #   load from source
  sb    $t0, 0($a0)                       #   store to destination
  addiu $a1, $a1, 1                       #   ++src_ptr
  addiu $a0, $a0, 1                       #   ++dest_ptr
  addi  $a2, $a2, -1                      #   --size;
  j     mem_memcpy_loop                   # }

mem_memcpy_endloop:
or    $a1, $zero, $t2                     # restore $a1
or    $a0, $zero, $t1                     # restore $a0
jr    $ra                                 # restore
