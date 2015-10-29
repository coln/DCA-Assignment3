; Test BEQ, BNE

addi $1, $0, 0x0001    ; $1 = 1
addi $2, $0, 0x0002    ; $2 = 2
beq $1, $1, skip
add $1, $1, $1         ; This should not run
skip:
add $2, $2, $1         ; $2 = 3
bne $1, $2, skip2
add $1, $1, $1         ; This should not run
skip2:
beq $1, $0, finally
add $2, $2, $1         ; $2 = 4
bne $1, $1, finally
loop:
beq $0, $0, loop       ; Run infinitely

finally:
add $2, $2, $1         ; This should never run