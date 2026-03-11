# Function heap_init
# Input:
#     $a0: Pointer to heap_start (or NULL during first run)
#     (potentially size of sbrk?)
# Output:
#     $v0: return value of sbrk (pointer to heap_start for first run)
# Registers used:
#     $t0: heap_start pointer arithmetic
#     $t1: last address -> chunk size
#     $t2: footer pointer
# Note:
#     The caller is in charge of storing the pointer to the allocation. 
#     If this is the first time this function is ran (and only time it is ran manually), the return value should be stored.
#     Otherwise, the return value is simply used by malloc to allocate a chunk.
#     $a0 gets clobbered for the sbrk syscall.
#     first_free is stored at heap_start + 4. 
#       No need to store it, since every function asks for POINTER to heap_start.
heap_init:
# sbrk allocation
ori   $v0, $zero, 9          # load syscall code 9 (sbrk)
ori   $a0, $zero, 4096       # load value 4096 (to allocate 4096 bytes) [this might get replaced by arg]
syscall                      # sbrk 4096 bytes

# setup heap metadata
or    $t0, $zero, $v0        # t0 = v0 for pointer arithmetic
addiu $t0, $t0, 12           # get heap_start
sw    $t0, 0($v0)            # store heap_start
sw    $t0, 4($v0)            # store first_free (same value)
addu  $t1, $v0, $a0          # get last possible address
sw    $t1, 8($v0)            # store last possible address

# setup unallocated chunk
ori   $t1, $zero, 4076       # get chunk size = sbrk allocation - 12 (metadata) - 8 (boundary tags)
sw    $t1, 0($t0)            # store chunk size into header
sw    $zero, 4($t0)          # set prev to null
sw    $zero, 8($t0)          # set next to null
addiu $t2, $t0, 4            # skip header
addu  $t2, $t2, $t1          # go to chunk footer
sw    $t1, 0($t2)            # store chunk size into footer
jr    $ra                    # return ($v0 is already what we want from sbrk syscall)

# TODO:
#     allocate more space with SBRK if no chunks apply to malloc.
#     This requires modification to heap_init:
#     1. first run
#       - $a0 is NULL
#       - run sbrk
#       - create a single unallocated chunk covering the allocation
#       - $v0 becomes pointer to heap_start
#     2. malloc run
#       - $a0 is heap_start
#       - run sbrk
#       - create an unallocated chunk covering the allocation
#       - if last chunk from previous allocation is unallocated, fuse with it
#       - $v0 becomes pointer to last unallocated chunk (which is then used by malloc)
#     Note: I might add $a1 for heap_init for size of allocation to avoid running multiple times if more than 4076 bytes are needed.
#           But, for now, still just 4096 bytes sbrk. If you need to malloc more than 4076 bytes for one pointer, what are you doing lol

# Function heap_malloc
# Input:
#     $a0: Pointer to heap_start.
#     $a1: Size of allocation in bytes.
# Output:
#     $v0: Pointer to allocated space.
#     $v1: sbrk occured
# Registers used:
#     $t0: $a1 even check -> free list iterator -> header pointer
#     $t1: current chunk size -> less-than bool -> original chunk size -> new unallocated split size -> prev ptr -> next ptr
#     $t2: footer pointer -> split header pointer
#     $t3: split footer pointer
# Note:
#     $a0 is the POINTER to heap_start, not the actual value. This makes calls easier with data segment vars.
#     Size MUST be even, as lsb is used as 'allocated' indicator.
#       There is no size correction, the caller is in charge of providing a correct size.
heap_malloc:
# check that $a1 is even
andi $t0, $a1, 1                             # check even
bnez $t0, heap_malloc_incorrect_size         # if $a1 off, return NULL (TODO)
# save ra (TODO: move this where you really need to allocate it.)
addi $sp, $sp, -4                            # allocate a word in stack
sw   $ra, 0($sp)                             # store ra

lw   $t0, 4($a0)                             # get first_free

heap_malloc_find_chunk:
  lw    $t1, 0($t0)                          # get chunk size
  addiu $t1, $t1, 16                         # chunk size + 16
  sltu  $t1, $t1, $a1                        # if chunk size + 16 !< desired size, aka if desired size <= chunk size + 16
  beq   $t1, $zero, heap_malloc_found        # break;
  lw    $t0, 8($t0)                          # else, get next
  beq   $t0, $zero, heap_malloc_not_found    # if next is null, no chunks apply. TODO: sbrk more space
  j     heap_malloc_find_chunk               # else, continue

heap_malloc_incorrect_size: # TODO: allocate more space with sbrk
heap_malloc_not_found:
break 1                                      # if no chunks work, FOR NOW, break execution

heap_malloc_found:
# update found chunk
or    $v0, $zero, $t0
addiu $v0, $v0, 4                            # set return value to header+4 (chunk data pointer)
lw    $t1, 0($t0)                            # save original chunk size
ori   $a1, $a1, 1                            # mark chunk as allocated
sw    $a1, 0($t0)                            # store new size in header
addi  $a1, $a1, -1                           # remove allocated bit from size for calculation
addiu $t2, $t0, 4                            # header + 4
addu  $t2, $t2, $a1                          # (header + 4) + new_size = footer
ori   $a1, $a1, 1                            # mark chunk as allocated
sw    $a1, 0($t2)                            # store new size in footer
addi  $a1, $a1, -1                           # remove allocated bit from size for calculation
# create split chunk
subu  $t1, $t1, $a1                          # original_chunk_size - new_size
beq   $t1, $zero, heap_malloc_nosplit        # if zero, don't create a new chunk. else, split:
addiu $t1, $t1, -8                           # (original_chunk_size - new_size) - 8 = new unallocated split size
addiu $t2, $t2, 4                            # get split header pointer
sw    $t1, 0($t2)                            # store split size in split header
addiu $t3, $t2, 4                            # skip header
addu  $t3, $t3, $t1                          # go to split footer
sw    $t1, 0($t3)                            # store split size in split footer
# update free list
lw    $t1, 4($t0)                            # get prev pointer
sw    $t1, 4($t2)                            # store it in new split chunk
beq   $t1, $zero, heap_malloc_prevptr_null   # if null, update first_free
sw    $t2, 8($t1)                            # else, update prev's next to new split chunk's header pointer
heap_malloc_update_next:
lw    $t1, 8($t0)                            # get next pointer
sw    $t1, 8($t2)                            # store it in new split chunk
beq   $t1, $zero, heap_malloc_return         # if null, return
sw    $t2, 4($t1)                            # else, update next's prev to new split chunk's header pointer
j     heap_malloc_return

heap_malloc_prevptr_null:                    # if prev ptr was null,
sw    $t2, 4($a0)                            #   update first_free with split chunk header pointer
j     heap_malloc_update_next

heap_malloc_nosplit:
# update free list
lw   $t1, 8($t0)                             # get nextptr
lw   $t2, 4($t0)                             # get prevptr
beq  $t1, $zero, heap_malloc_ns_nextptr_null # if nextptr is null, skip
sw   $t2, 4($t1)                             # next's prevptr = prevptr
heap_malloc_ns_nextptr_null:
beq  $t2, $zero, heap_malloc_ns_prevptr_null # if prevptr not null {
sw   $t1, 8($t2)                             #   prev's nextptr = nextptr
j    heap_malloc_return                      # }
heap_malloc_ns_prevptr_null:                 # else,
sw   $t1, 4($a0)                             #   first_free = nextptr

heap_malloc_return:
lw   $ra, 0($sp)                             # retrieve ra from stack
addi $sp, $sp, 4                             # deallocate a word from stack
jr   $ra                                     # return



# Function heap_free
# Input:
#     $a0: Pointer to heap_start.
#     $a1: p Pointer to allocated space to free.
# Ouptut:
#     None
# Registers used (not detailed as too complicated):
#     $t0
#     $t1
#     $t2
#     $t3
heap_free:
# mark chunk as unallocated
lw    $t1, -4($a1)                          # get chunk size
addiu $t1, $t1, -1                          # mark as unallocated
sw    $t1, -4($a1)                          # store back
or    $t0, $zero, $a1                       # get chunk header pointer
addu  $t0, $t0, $t1                         # go to footer
sw    $t1, 0($t0)                           # update footer size to mark unallocated
# check first chunk
lw    $t0, 0($a0)                           # get heap_start
addiu $t0, $t0, 4                           # offset from header like p
beq   $t0, $a1, heap_free_firstChunk        # if p == heap_start+4, process as first chunk
# check previous neighbor
lw    $t0, -8($a1)                          # else, load size of previous neighbor
andi  $t2, $t0, 1                           # check whether previous neighbor is allocated
beq   $t2, $zero, heap_free_prevFree        # if previous neighbor unallocated, process
# check next neighbor
addu  $t0, $a1, $t1                         # else, goto footer
lw    $t1, 4($t0)                           # skip footer to load next neighbor's size
andi  $t2, $t1, 1                           # check whether next neighbor is allocated
beq   $t2, $zero, heap_free_nextFree        # if next neighbor unallocated, process

# neither neighbor is unallocated.
# iterate through chunks to find where to insert p in free list
lw   $t0, 4($a0)                            # get first_free for current_ptr
heap_free_none_find_chunk:                  # [while current_ptr < p]
  sltu $t1, $a1, $t0                        # check if current_ptr > p
  bne  $t1, $zero, heap_free_none_found     # if current_ptr > p, break
  lw   $t0, 8($t0)                          # else, go to next
  j    heap_free_none_find_chunk
heap_free_none_found:
# by this point, $t0 is on the NEXT unallocated chunk AFTER p
# set p's prev & next
sw    $t0, 4($a1)                           # p's nextptr = current_ptr
lw    $t1, 4($t0)                           # get current_ptr's prevptr
sw    $t1, 0($a1)                           # p's prevptr = current_ptr's prevptr
addiu $t2, $a1, -4                          # get p's ptr
# update free list
sw    $t2, 4($t0)                           # current_ptr's prevptr = p
beq   $t1, $zero, heap_free_none_first      # if p's prevptr is null, update first_free
sw    $t2, 8($t1)                           # else, p's prev's nextptr = p
j     heap_free_return
heap_free_none_first:                       # if p's prevptr is null,
sw    $t2, 4($a0)                           # set first_free to p
j     heap_free_return


heap_free_firstChunk:
sw    $zero, 0($a1)                         # set p's prevptr to NULL
# check next neighbor
addu  $t2, $a1, $t1                         # go to p footer
lw    $t0, 4($t2)                           # get next's size
andi  $t3, $t0, 1                           # check if next neighbor allocated
beq   $t3, $zero, heap_free_firstChunkNext  # if unallocated, process firstChunk & nextFree case
lw    $t0, 4($a0)                           # else, get first unallocated chunk
# update free list
addiu $a1, $a1, -4                          # get p header pointer
sw    $a1, 4($t0)                           # set prevptr of that chunk to p
sw    $t0, 8($a1)                           # set p's nextptr to that chunk
sw    $a1, 4($a0)                           # update first_free to p header
addiu $a1, $a1, 4                           # set p back
j     heap_free_return

heap_free_firstChunkNext:
addiu $a1, $a1, -4                          # get p header pointer
sw    $a1, 4($a0)                           # update first_free to p header
addiu $a1, $a1, 4                           # set p back
j     heap_free_bothFree                    # go on to both free case

heap_free_prevFree:
# fuse with previous chunk
subu  $t2, $a1, $t0                         # go back by size of previous chunk
addiu $t2, $t2, -12                         # get previous header: go back p header, prev foot and prev header (3*4 = 12)
addu  $t1, $t0, $t1                         # get sum of previous chunk size and p size
addiu $t1, $t1, 8                           # add 8 since 2 tags will be deleted
sw    $t1, 0($t2)                           # update header size value
addiu $t2, $t2, 4                           # goto chunk data section
or    $a1, $zero, $t2                       # set p to that
addu  $t2, $t2, $t1                         # goto footer
lw    $t0, 4($t2)                           # get next chunk size
andi  $t3, $t0, 1                           # check if next chunk is allocated
beq   $t3, $zero, heap_free_bothFree        # if next neighbor unallocated, process
sw    $t1, 0($t2)                           # else, update footer size value
j     heap_free_return

heap_free_bothFree:
# fuse with next chunk
addu  $t0, $t0, $t1                         # get sum of current chunk size and next chunk size
addiu $t0, $t0, 8                           # add 8 since 2 tags will be deleted
sw    $t0, -4($a1)                          # update header with new size
addu  $t1, $a1, $t0                         # go to new footer
sw    $t0, 0($t1)                           # update footer with new size
# update free list
lw    $t3, 12($t2)                          # get next neighbor's nextptr
sw    $t3, 4($a1)                           # save it as p's nextptr
beq   $t3, $zero, heap_free_return          # if nextptr is NULL, done
addiu $t0, $a1, -4                          # else, get p header pointer
sw    $t0, 4($t3)                           # set p as p's next's prevptr
j     heap_free_return


heap_free_nextFree:
# t0 is at footer
# t1 is next neighbor's size
# update free list
lw    $t2, 8($t0)                               # get next chunk's prevptr
sw    $t2, 0($a1)                               # set it as p's prevptr
lw    $t2, 12($t0)                              # get next chunk's nextptr
sw    $t2, 4($a1)                               # set it as p's nextptr
# fuse with next chunk
lw    $t0, -4($a1)                              # get p's size
addu  $t1, $t0, $t1                             # add p's size and next chunk's size
addiu $t1, $t1, 8                               # add 8 since we're deleted 2 tags
or    $t0, $zero, $a1                           # go to p
sw    $t1, -4($t0)                              # store new size in header
addu  $t0, $t0, $t1                             # go to new footer
sw    $t1, 0($t0)                               # store new size in new footer
# update links in free list
addiu $t0, $a1, -4                              # get p header pointer
beq   $t2, $zero, heap_free_nextFree_skipNext   # if nextptr not NULL,
sw    $t0, 4($t2)                               #   set next's prevptr to p
heap_free_nextFree_skipNext:
lw    $t2, 4($t0)                               # get p prevptr
beq   $t2, $zero, heap_free_nextFree_prevNull   # if prevptr not NULL {
sw    $t0, 8($t2)                               #   set prev's nextptr to p
j     heap_free_return                          # }
heap_free_nextFree_prevNull:                    # else,
sw    $t0, 4($a0)                               #   update first_free to p
j     heap_free_return                          # }


heap_free_return:
jr    $ra
