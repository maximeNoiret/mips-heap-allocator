.macro heap_init()
  xor $a0, $a0, $a0
  jal heap_init
.end_macro

.macro malloc_RI(%heap_reg, %size)
  or  $a0, $zero, %heap_reg
  ori $a1, $zero, %size
  jal heap_malloc
 .end_macro
.macro malloc_LI(%heap_label, %size)
  lw  $a0, %heap_label
  ori $a1, $zero, %size
  jal heap_malloc
.end_macro

.macro free_RR(%heap_reg, %p)
  or  $a0, $zero, %heap_reg
  or  $a1, $zero, %p
  jal heap_free
.end_macro
.macro free_LR(%heap_label, %p)
  lw  $a0, %heap_label
  or  $a1, $zero, %p
  jal heap_free
.end_macro
