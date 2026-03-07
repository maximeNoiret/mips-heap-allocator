test:
jal heap_init                # call heap_init
lw   $a0, 0($v0)             # a0 = heap_start
ori  $v0, $zero, 1           # load syscall code 1 (print int)
syscall                      # print heap_start

ori	 $v0, $zero, 10          # load syscall code 10 (exit)
syscall                      # exit


# Function heap_init
# Input:
#     None  (potentially size of sbrk?)
# Output:
#     $v0: pointer to heap_start
# Registers used:
#     $t0: heap_start pointer arithmetic
#     $t1: chunk size
#     $t2: footer pointer
# Note:
#     The caller is in charge of storing the pointer to the allocation. 
#     first_free is stored at heap_start + 4. 
#       No need to store it, since every function asks for POINTER to heap_start.
#     Size MUST be even, as lsb is used as 'allocated' indicator.
heap_init:
# sbrk allocation
ori  $v0, $zero, 9          # load syscall code 9 (sbrk)
ori  $a0, $zero, 4096       # load value 4096 (to allocate 4096 bytes) [this might get replaced by arg]
syscall                     # sbrk 4096 bytes

# setup heap metadata
or   $t0, $zero, $v0        # t0 = v0 for pointer arithmetic
addi $t0, $t0, 8            # get heap_start
sw   $t0, 0($v0)            # store heap_start
sw   $t0, 4($v0)            # store first_free (same value)

# setup unallocated chunk
ori  $t1, $zero, 4080       # get chunk size = sbrk allocation - 8 (metadata) - 8 (boundary tags)
sw   $t1, 0($t0)            # store chunk size into header
sw   $zero, 4($t0)          # set prev to null
sw   $zero, 8($t0)          # set next to null
add  $t2, $t0, $t1          # go to chunk footer
sw   $t1, 0($t2)            # store chunk size into footer
jr   $ra                    # return ($v0 is already what we want from sbrk syscall)





# Function heap_malloc
# Input:
#     $a0: Pointer to heap_start.
#     $a1: Size of allocation in bytes.
# Output:
#     $v0: Pointer to allocated space.
# Registers used:
#     None
# Note:
#     $a0 is the POINTER to heap_start, not the actual value. This makes calls easier with data segment vars.
heap_malloc:






# Function heap_free
# Input:
#     $a0: Pointer to heap_start.
#     $a1: Pointer to allocated space to free.
# Ouptut:
#     None
# Registers used:
#     None
heap_free:
