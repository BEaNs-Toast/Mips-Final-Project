.macro set_brush(%int)
	li $t4, %int
	add $t6, $t0, $t4
	add $t7, $s0, $t4
.end_macro
.macro movebrush
	addi $t4, $t4, 4
    	add $t6, $t0, $t4
    	add $t7, $s0, $t4
.end_macro
.macro paint
	sw $t1, 0($t6)
	li $t2, 1
    	#sw $t2, 0($t7)
.end_macro

.data
DISPLAY: .word 0x10008000
KEY_PRESS: .word 0xFFFF0000
D_key: .asciiz "Block goes right"
A_key: .asciiz "Block goes Left"
S_key:	.asciiz "Block snaps to bottom"
R_key: 	.asciiz "Block Rotates"
DIS_ARR: .byte 0:2048
BORDER: .word 0x444444
GREY_PATTERN: .word 0x161616 
BLACK: .word 0x000000


.text
	main:
	lw $t0, DISPLAY
	la $s0, DIS_ARR
	set_brush(0)
	jal draw_sides
	set_brush(1920)
	jal draw_bottom
	set_brush(4)
	lw $t9, KEY_PRESS
	lw $t8, 0($t9)
	beq $t8, 1, check_key
	j main
check_key:
	lw $a0, 4($t9)
	beq $a0, 100, D_press
	beq $a0, 114, R_press
	beq $a0, 97, A_press
	beq $a0, 115, S_press
	beq $a0, 113, end
	j main
draw_sides:
	la $t5, BORDER
	lw $t1, 0($t5)
	
	paint
    
    	movebrush
    
    paint
    
    addi $t4, $t4, 52
    add $t6, $t0, $t4
    add $t7, $s0, $t4
    
    paint
    
   movebrush
    
   paint
    
   movebrush
   blt $t4, 1914, draw_sides
   jr $ra
draw_bottom:
	la $t5, BORDER
	lw $t1, 0($t5)
	paint
	movebrush
	blt $t4, 2045, draw_bottom
	jr $ra
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
	