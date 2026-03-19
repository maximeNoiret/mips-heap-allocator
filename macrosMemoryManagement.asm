.macro mem_RR(%dst_reg, %src_reg)
  or    $a0, $zero, %dst_reg
  or    $a1, $zero, %src_reg
.end_macro

.macro memcpy_RRI(%dst_reg, %src_reg, %size_i)
  mem_RR(%dst_reg, %src_reg)
  addiu $a2, $zero, %size_i
  jal   mem_memcpy
.end_macro

.macro memcpy_RRR(%dst_reg, %src_reg, %size_reg)
  mem_RR(%dst_reg, %src_reg)
  or    $a2, $zero, %size_reg
  jal   mem_memcy
.end_macro

.macro mem_LL(%dst_label, %src_label)
  lw    $a0, %dst_label
  lw    $a1, %src_label
.end_macro

.macro memcpy_LLI(%dst_label, %src_label, %size_i)
  mem_LL(%dst_label, %src_label)
  addiu $a2, $zero, $size_i
  jal   mem_memcpy
.end_macro

.macro memcpy_LLR(%dst_label, %src_label, %size_reg)
  mem_LL(%dst_label, %src_label)
  or    $a2, $zero, $size_i
  jal   mem_memcpy
.end_macro
