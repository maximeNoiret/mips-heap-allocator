test:
ori	$v0,	$zero,	10				# load syscall code 10 (exit)
syscall								# exit


# Function heap_init
# Input:
#     None  (potentially size of sbrk?)
# Output:
#     $v0: pointer to heap_start
# Registers used:
#     None
# Note:
#     The caller is in charge of storing the pointer to the allocation. 
#     first_free is stored at heap_start + 4. 
#       No need to store it, since every function asks for POINTER to heap_start.
heap_init:





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
