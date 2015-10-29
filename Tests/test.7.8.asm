; Test ADDIU, ADDU
addi $1, $0, 0x8000   ; $1 = 0x8000
sll $1, $1, 16        ; $1 = 0x80000000
addiu $2, $1, 0xFFFF  ; $2 = 0x7FFFFFFF, no overflow
addu $3, $1, $1       ; $3 = 0x0000, no overflow

addi $4, $0, 0x8000   ; $4 = 0x8000
sll $4, $4, 16        ; $4 = 0x80000000
addi $5, $4, 0xFFFF   ; $5 = 0x7FFFFFFF, overflow
add $6, $4, $4        ; $6 = 0x0000, overflow
