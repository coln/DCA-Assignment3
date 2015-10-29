; Test SLT, SLTU, SLTI, SLTIU

addi $1, $0, 0xFFFF  ; $1 = 0xFFFFFFFF
addi $2, $0, 0x0002
slt $3, $1, $2       ; $3 = 0x0001
sltu $4, $1, $2      ; $4 = 0x0000
slti $5, $1, 0x0004  ; $5 = 0x0001
sltiu $6, $1, 0x0004 ; $6 = 0x0000
