.data
 DISPLAY:
 	.word 0x10008000
 KEYPRESS:
 	.word 0xFFFF0004
 GREY_BORDER: .word 0x444444
DIS_ARR: .byte 0:2048
 Works: .asciiz "Game works"
 NoWork: .asciiz "Does not work"
 .text
 	.globl main
 	main:
 	li $t2, 0xFFFF0000
 	lw $t8, 0($t2)	
 	beq $t8, 1, showdis
 	li $v0, 4
 	la $a0, NoWork
 	syscall
 	li $v0, 10
 	syscall
 showdis:
 	li $t0, 0x10008000
 	li $s0, 0x000444444
 	li $t4, 0
   	add $t5, $t0, $t4 
   	add $t7, $s0, $t4
   	jal draw_sides
   	li $v0, 4
   	la $a0, Works
   	syscall
   	li $v0, 10
   	syscall
   	
 draw_sides:	
    la $t6, GREY_BORDER
    lw $t1, 0($t6)
    
    sw $t1, 0($t5)
    li $t2, 1
    sw $t5, 0($t7)
    
    addi $t4, $t4, 4
    add $t5, $t0, $t4
    add $t7, $s0, $t4
    
    sw $t1, 0($t5)
    li $t2, 1
    sw $t2, 0($t7)
    
    addi $t4, $t4, 52
    add $t5, $t0, $t4
    add $t7, $s0, $t4
    
    sw $t1, 0($t5)
    li $t2, 1
    sw $t2, 0($t7)
    
    addi $t4, $t4, 4
    add $t5, $t0, $t4
    add $t7, $s0, $t4
    
    sw $t1, 0($t5)
    li $t2, 1
    sw $t2, 0($t7)
    
    addi $t4, $t4, 4
    add $t5, $t0, $t4
    add $t7, $s0, $t4
    blt $t4, 1914, draw_sides
    jr $ra
 	
 	