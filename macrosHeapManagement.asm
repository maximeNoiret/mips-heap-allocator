.macro heap_init()
  jal heap_init
.end_macro


.macro malloc_LI(%heap_label, %size)
  la  $a0, %heap_label
  ori $a1, $zero, %size
  jal heap_malloc
.end_macro