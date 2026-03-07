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
#     $t0: $a1 even check -> free list iterator -> header pointer
#     $t1: current chunk size -> less-than bool -> original chunk size -> new unallocated split size
#     $t2: footer pointer -> split header pointer
#     $t3: split footer pointer
# Note:
#     $a0 is the POINTER to heap_start, not the actual value. This makes calls easier with data segment vars.
heap_malloc:
# check that $a1 is even
andi $t0, $a1, 1                             # check even
bnez $t0, heap_malloc_incorrect_size         # if $a1 off, return NULL (TODO)

lw   $t0, 4($a0)                             # get first_free

heap_malloc_find_chunk:
  lw    $t1, 0($t0)                          # get chunk size
  addiu $t1, $t1, 16                         # chunk size + 16
  sltu  $t1, $t1, $a1                        # if chunk size + 16 !< desired size, aka if desired size <= chunk size + 16
  beq   $t1, $zero, heap_malloc_found        # break;
  lw    $t0, 8($t0)                          # else, get next
  beq   $t0, $zero, heap_malloc_not_found    # if next is null, no chunks apply. TODO: sbrk more space
  j     heap_malloc_find_chunk               # else, continue

heap_malloc_not_found:
break 1                                      # if no chunks work, FOR NOW, break execution

heap_malloc_found:
ori   $v0, $zero, $t0
addiu $v0, $v0, 4                            # set return value to header+4 (chunk data pointer)
lw    $t1, 0($t0)                            # save original chunk size
ori   $a1, $a1, 1                            # mark chunk as allocated
sw    $a1, 0($t0)                            # store new size in header
addiu $t2, $t0, 4                            # header + 4
addu  $t2, $t0, $a1                          # (header + 4) + new_size = footer
sw    $a1, 0($t2)                            # store new size in footer
andi  $a1, $a1, 0xFFFFFFFE                   # remove allocated bit from size for calculation
subu  $t1, $t1, $a1                          # original_chunk_size - new_size
subiu $t1, $t1, 8                            # (original_chunk_size - new_size) - 8 = new unallocated split size
addiu $t2, $t2, 4                            # get split header pointer
sw    $t1, 0($t2)                            # store split size in split header
addiu $t3, $t2, 4                            # skip header
addu  $t3, $t3, $t1                          # go to split footer
sw    $t1, 0($t3)                            # store split size in split footer

# TODO:
#   - If prev is null, update first_free
#   - Else, Iterate through previous neighbors until unallocated to update its next pointer
#   - If next not null, Iterate through next neighbors until unallocated to update its prev pointer

jr   $ra                                     # return
  








# Function heap_free
# Input:
#     $a0: Pointer to heap_start.
#     $a1: Pointer to allocated space to free.
# Ouptut:
#     None
# Registers used:
#     None
heap_free:
