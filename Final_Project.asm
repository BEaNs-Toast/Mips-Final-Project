.data
KEY_PRESS: .word 0xFFFF0000
D_key: .asciiz "Block goes right"
A_key: .asciiz "Block goes Left"
S_key:	.asciiz "Block snaps to bottom"
R_key: 	.asciiz "Block Rotates"


.text
	main:
	lw $t2, KEY_PRESS
	lw $t8, 0($t2)
	beq $t8, 1, check_key
	j main
check_key:
	lw $a0, 4($t2)
	beq $a0, 100, D_press
	beq $a0, 114, R_press
	beq $a0, 97, A_press
	beq $a0, 115, S_press
	beq $a0, 113, end
	j main
D_press:
	li $v0, 4
	la $a0, D_key
	syscall
	j main
R_press:
	li $v0, 4
	la $a0, R_key
	syscall
	j main
A_press:
	li $v0, 4
	la $a0, A_key
	syscall
	j main
S_press:
	li $v0, 4
	la $a0, S_key
	syscall
	j main
end:
	li $v0, 10
	syscall
	