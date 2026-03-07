.macro heap_init()
  jal heap_init
.end_macro

.macro malloc_RI(%reg, %size)
  or  $a0, $zero, %reg
  ori $a1, $zero, %size
  jal heap_malloc
 .end_macro
.macro malloc_LI(%heap_label, %size)
  lw  $a0, %heap_label
  ori $a1, $zero, %size
  jal heap_malloc
.end_macro