; Do so simple register checking
addi $1, $0, 0x0001   ; $1 = 0x0001
add $2, $1, $0        ; $2 = 0x0001
ori $3, $2, 0x0100    ; $3 = 0x0101
ori $4, $2, 0x0000    ; $4 = 0x0001
ori $5, $2, 0xFFFF    ; $5 = 0xFFFFFFFF