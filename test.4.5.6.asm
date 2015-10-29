; Load/store 0xAA from base address 0x10000000 + offset of 3
addi $1, $0, 0xAA     ; $1 = 0xAA
addi $2, $0, 0x1000   ; $2 = 0x1000
sll $2, $2, 16        ; $2 = 0x10000000
sw $1, 3($2)          ; mem[0x10000003] = 0xAA
lw $3, 3($2)          ; $3 = 0xAA