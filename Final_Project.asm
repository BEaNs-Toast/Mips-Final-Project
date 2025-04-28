.macro set_brush(%int)#This code places the brush in a specific location on the screen
	li $t4, %int
	add $t6, $t0, $t4
	add $t7, $s0, $t4
.end_macro
.macro movebrush #this macro moves the brush by 1 pixel to the right on the screen
	addi $t4, $t4, 4
    	add $t6, $t0, $t4
    	add $t7, $s0, $t4
.end_macro
.macro paint #this macro changes the color of the screen by what color was inputed into $t1
	sw $t1, 0($t6)
	li $t2, 1
    	#sw $t2, 0($t7) This code does not work, but what it should do is tell the computer that that section of the screen is occpuied
.end_macro

.data
DISPLAY: .word 0x10008000 #Display input
KEY_PRESS: .word 0xFFFF0000 #Keyboard output 
D_key: .asciiz "Block goes right"
A_key: .asciiz "Block goes Left"
S_key:	.asciiz "Block snaps to bottom"
R_key: 	.asciiz "Block Rotates"
DIS_ARR: .byte 0:2048 #supposed to stroe digits, is not used currently
BORDER: .word 0x444444 #Border color
GREY_PATTERN: .word 0x161616 #grey Color
BLACK: .word 0x000000 #Black Color
#Before starting the code, make sure to set the bitmap display to this:
# Unit Width in Pixles - 16
#Unit Height in Pixes - 16
# Display Width in Pixels - 156
#Display Height in Pixels - 512
#Base Adress for display - 0x10008000 ($gp)

#Make sure to connect both the bitmap display and the Keyboard and Display MMIO Simulator as well.

.text
	main:
	lw $t0, DISPLAY
	la $s0, DIS_ARR
	set_brush(0)
	jal draw_sides #addes the sides for the screen
	set_brush(1920)
	jal draw_bottom #addes the bottom for the screen
	set_brush(4)
	lw $t9, KEY_PRESS
	lw $t8, 0($t9)
	beq $t8, 1, check_key 
	j main
check_key:
	lw $a0, 4($t9) #this loads the character pressed into $a0
	beq $a0, 100, D_press
	beq $a0, 114, R_press
	beq $a0, 97, A_press
	beq $a0, 115, S_press
	beq $a0, 113, end #If you press Q, this activates
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
	
