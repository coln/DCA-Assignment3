; Test SUB, SUBU, SRL

addi $1, $0, 0x5555
addi $2, $0, 0x2222
srl $2, $2, 8        ; $2 = 0x0022
sub $3, $1, $2       ; $3 = 0x5533

andi $1, $1, 0x0001  ; $1 = 0x0001
addi $4, 0, 0x8000
sll $4, $4, 16       ; $4 = 0x80000000
subu $5, $4, $1      ; $5 = -(MAX) - 1 = 0x7FFFFFFF,  no overflow
sub $6, $4, $1       ; $6 = -(MAX) - 1 = 0x7FFFFFFF,  overflow