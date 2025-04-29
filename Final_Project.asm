.macro set_brush(%int)#This code places the brush in a specific location on the screen
	li $t4, %int
	add $t6, $t0, $t4
	add $t7, $s0, $t4
.end_macro

.macro movebrush_right #this macro moves the brush by 1 pixel to the right on the screen

	addi $t4, $t4, 4
    	add $t6, $t0, $t4
    	add $t7, $s0, $t4
.end_macro
.macro movebrush_left #this macro moves the brush by 1 pixel to the right on the screen
	subi $t4, $t4, 4
    	add $t6, $t0, $t4
    	add $t7, $s0, $t4
.end_macro
.macro paint #this macro changes the color of the screen by what color was inputed into $t1
	sw $t1, 0($t6)
	li $t2, 1
	andi $t7, $t7, 0xFFFFFFFC
    	sw $t2, 0($t7) 
.end_macro
.macro erase
	set_color(BLACK)
	sw $t1, 0($t6)
	li $t2, 0
	andi $t7, $t7, 0xFFFFFFFC
    	sw $t2, 0($t7)
   .end_macro
.macro set_color(%string)
	la $t5, %string
	lw $t1, 0($t5)
.end_macro
.macro movecursor_right #this moves the cursor right by one
	erase
	movebrush_right
	movebrush_right
	andi $t7, $t7, 0xFFFFFFFC
	lw $t2, 0($t7)
	beq $t2, 1, reset_cursor
	set_color(CURSOR)
	paint
	movebrush_left 
.end_macro
.macro movecursor_left #this moves the cursor left by one
	movebrush_right
	erase
	movebrush_left
	movebrush_left
    	andi $t7, $t7, 0xFFFFFFFC
	lw $t2, 0($t7)
	beq $t2, 1, reset_cursor
	set_color(CURSOR)
	paint 
.end_macro
.macro movecursor_snap #this makes the cursor drop its blocks down to the lowest  open spot
	erase
	movebrush_right
	erase
	movebrush_left
	jal move_down
	set_color(CURSOR)
	paint
	movebrush_right
	paint
	li $v0, 4
	la $a0, S_key
	syscall
	j reset_cursor

.data
DISPLAY: .word 0x10008000 #Display input
KEY_PRESS: .word 0xFFFF0000 #Keyboard output 
D_key: .asciiz "Block goes right"
A_key: .asciiz "Block goes Left"
S_key:	.asciiz "Block snaps to bottom"
R_key: 	.asciiz "Block Rotates"
DIS_ARR: .byte 0:2048 #supposed to stroe digits, is not used currently
BORDER: .word 0x444444 #Border color
CURSOR: .word 0x00ff00 #Green Color
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
	jal initial_spawn
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
    
    	movebrush_right
    
    paint
    
    addi $t4, $t4, 52
    add $t6, $t0, $t4
    add $t7, $s0, $t4
    
    paint
    

   movebrush_right
    
   paint
    
   movebrush_right
   blt $t4, 1914, draw_sides
   jr $ra
draw_bottom:
	la $t5, BORDER
	lw $t1, 0($t5)
	paint
	movebrush_right
	blt $t4, 2045, draw_bottom
	jr $ra
D_press:
	movecursor_right
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
	movecursor_left
	li $v0, 4
	la $a0, A_key
	syscall
	j main
S_press:
	movecursor_snap
	li $v0, 4
	la $a0, S_key
	syscall
	j main
end:
	li $v0, 10
	syscall
set_board:
	set_brush(0)
	jal reset
	set_brush(0)
	jal draw_sides #addes the sides for the screen
	set_brush(1920)
	jal draw_bottom #addes the bottom for the screen
	set_brush(28)
	set_color(CURSOR)
	paint
	movebrush_right
	paint
	movebrush_left
	li $s3, 1
	lw $ra, 0($sp)
	add $sp, $sp, 4
	jr $ra
reset:
	erase
	movebrush_right
	blt $t4, 2045, reset
	jr $ra

initial_spawn:
	sub $sp, $sp, 4
	sw $ra, 0($sp)
	beqz $s3, set_board
	lw $ra, 0($sp)
	add $sp, $sp, 4
	jr $ra
reset_cursor:
	set_brush(8)
	jal clear_top
	set_brush(28)
	set_color(CURSOR)
	paint
	movebrush_right
	paint
	movebrush_left
	j main
move_down:
	addi $t4, $t4, 64
    	add $t6, $t0, $t4
    	add $t7, $s0, $t4
	andi $t7, $t7, 0xFFFFFFFC
	lw $t2, 0($t7)
	beq $t2, 0, move_down
	movebrush_right
	add $t7, $s0, $t4
	andi $t7, $t7, 0xFFFFFFFC
	lw $t2, 0($t7)
	beq $t2, 1, move_up
	movebrush_left
	subi $t4, $t4, 64
    	add $t6, $t0, $t4
    	add $t7, $s0, $t4
	jr $ra
move_up:
	subi $t4, $t4, 64
    	add $t6, $t0, $t4
    	add $t7, $s0, $t4
    	andi $t7, $t7, 0xFFFFFFFC
	lw $t2, 0($t7)
	beq $t2, 1, move_up
	movebrush_left
	jr $ra
clear_top:
	erase
	movebrush_right
	blt $t4, 55, clear_top
	jr $ra
	
