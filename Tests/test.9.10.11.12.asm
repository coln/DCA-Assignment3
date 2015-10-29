; Test AND, ANDI, OR, and NOR
addi $1, $0, 0x5511    ; $1 = 0x5511
addi $2, $0, 0xFFFF    ; $2 = 0xFFFFFFFF
and $3, $1, $2         ; $3 = 0x5511
andi $4, $2, 0xAA55    ; $4 = 0xAA55
or $5, $1, $4          ; $5 = 0xFF55
nor $6, $1, $4         ; $6 = 0xFFFF00AA
