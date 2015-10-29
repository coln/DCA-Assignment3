; Test J, JAL, JR

j jump1
addi $1, $0, 0x0001   ; This should not run
jump1:
addi $2, $0, 0x0002   ; $2 = 2
jal jump2
addi $1, $0, 0x0001   ; This should never run
jump2:
add $2, $2, $2        ; $2 = 4

addi $1, $0, 0x0040   ; Set jump address
sll $1, $1, 16
addi $1, $1, 0x000B
jr $1
add $1, $1, $1        ; This should not run
add $2, $2, $2        ; $2 = 6
