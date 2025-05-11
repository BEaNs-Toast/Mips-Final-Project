.macro set_brush(%int)#This code places the brush in a specific location on the screen
	li $t4, %int
	add $t6, $t0, $t4
	add $t7, $s0, $t4
.end_macro
.macro reset_cursor #this code sets the permanent cursor that is used as a baseline for the block spawn and removal.
	move $k1, $t4
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

.macro erase #erases on pixel
	setcolor_string(BLACK)
	sw $t1, 0($t6)
	li $t2, 0
	andi $t7, $t7, 0xFFFFFFFC
    	sw $t2, 0($t7)
.end_macro
   
.macro setcolor_string(%string) #sets color from string directly
	la $t1, %string
	lw $t1, 0($t1)
.end_macro
.macro setcolor_reg(%string) #sets color stored in a register, good for the randomization if you use an array
	move $t1, %string
	lw $t1, 0($t1)
.end_macro

.macro moveblock_right #this moves the block right by one
	jal erase_block
	move $t4, $k1 	
	add $t6, $t0, $t4 	
	add $t7, $s0, $t4
	movebrush_right
	reset_cursor
	setcolor_string(PURPLE) #update when you add randomziation of blocks
	jal draw_block
.end_macro

.macro moveblock_left #this moves the cursor left by one
	jal erase_block
	move $t4, $k1 	
	add $t6, $t0, $t4 	
	add $t7, $s0, $t4
	movebrush_left
	reset_cursor
	setcolor_string(PURPLE) #update when you add randomziation of blocks
	jal draw_block
.end_macro

.macro moveblock_snap #This should move the block down, but I will leave it like this for right now, and pass it on to the next person. 
	jal erase_block
	move $t4, $k1 	
	add $t6, $t0, $t4 	
	add $t7, $s0, $t4
	jal move_down
	setcolor_string(PURPLE) #update when you add randomziation of blocks
	jal draw_block
	move $s4, $zero
	set_brush(28)
	reset_cursor
	jal draw_block
.end_macro

.data
DISPLAY: .word 0x10008000 #Display input
KEY_PRESS: .word 0xFFFF0000 #Keyboard output 
start_pos: .word 28
D_key: .asciiz "Block goes right"
A_key: .asciiz "Block goes Left"
S_key:	.asciiz "Block snaps to bottom"
R_key: 	.asciiz "Block Rotates"
DIS_ARR: .byte 0:2048 #supposed to stroe digits, is not used currently
BORDER: .word 0x444444 #Border color
CURSOR: .word 0x00ff00 #Green Color
BLACK: .word 0x000000 #Black Color
PURPLE: .word 0xb56bff # Purple Color - T block
TURQUOISE: .word 0x45ffdd #pink color - I block
YELLOW: .word 0xfff400 #Yellow Color - O Block
BLUE: .word 0x0004ff #Blue Color - J block
RED: .word 0xc90000 #Red color - S block
ORANGE: .word 0xff6600 #orange color - L block

T_BLOCK: .word 4, 64, 68, 72   # T shape
I_BLOCK: .word 0, 4, 8, 12     # I shape: four horizontal blocks
O_BLOCK: .word 0, 4, 64, 68 # O shape: small square
J_BLOCK: .word 0, 64, 68, 72   # L shape
L_BLOCK: .word 8, 64, 68, 72   # mirrored L
S_BLOCK: .word 8, 4, 64, 68 # S shape
Z_BLOCK: .word 0, 4, 68, 72 #Z_shaped block.....

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
	setcolor_string(BORDER)
	
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
	setcolor_string(BORDER)
	paint
	movebrush_right
	blt $t4, 2045, draw_bottom
	jr $ra
D_press:
	moveblock_right
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
	moveblock_left
	li $v0, 4
	la $a0, A_key
	syscall
	j main
S_press:
	moveblock_snap
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
	reset_cursor
	move $s4, $zero
	li $s3, 1
	j main

reset:
	erase
	movebrush_right
	blt $t4, 2045, reset
	jr $ra

initial_spawn:
	sub $sp, $sp, 4
	sw $ra, 0($sp)
	beqz $s3, set_board
	
	#code to randomzie new falling block should be placed here, between the set board and spawn block
	
	beq $s4, $zero, block_spawn
	lw $ra, 0($sp)
	add $sp, $sp, 4
	jr $ra
block_spawn:
	
	la $s1, Z_BLOCK #This is where you set the falling block shape, update when you add randomization 
    	setcolor_string(PURPLE) #this is where you set the falling block color, update when you add randomziation
    	li $s4, 0 #set draw block counter, this is ethier at 4 (block on screen), or 0 (block not on screen)
    	
	jal draw_block
	lw $ra, 0($sp)
	add $sp, $sp, 4
	jr $ra	
reset_cursor:
	la $s1, Z_BLOCK #resets block, please update when you add randomziation
	li $s4, 4 #resets block number
	jal erase_block #removes block
	set_brush(0)
	jal draw_sides #to fix sides (erase_block removes parts of the sides so I just reset the entire thing, no issues)
	set_brush(28)
	reset_cursor
	j main

move_down: #needs to be updated to support falling block, I found out a way but it takes a decent amount of time, not sure if it will work with rotation, and I have done a bunch already
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
	
clear_top: #isn't used at all, but eh
	erase
	movebrush_right
	blt $t4, 55, clear_top
	jr $ra
	
    	
draw_block:
    	
	lw $s2, 0($s1) # load offset from block array 
	add $s3, $s2, $k1 #set brush position to offset from array + cursor location. Note: The original code would always make the block spawn at the top of the screen and never move at all, since it was a static number. Thats why you should check the code given by ChatGPT and understand what the code is doing. -B.T.
	#set brush position
	move $t4, $s3
   	add $t6, $t0, $t4
	add $t7, $s0, $t4 
	andi $t7, $t7, 0xFFFFFFFC
	lw $t2, 0($t7)
	beq $t2, 1, reset_cursor	 #check if block is occupied code is put here
    	paint
    
    	addi $s1, $s1, 4   # next offset in array
    	addi $s4, $s4, 1 #increment spawn_loop counter 
    	blt $s4, 4, draw_block # will loop 4 times bc tetris blocks made of 4 pixels
	subi $s1, $s1, 16 # 4 offsets * 4 digits = 16 total, move it back to be zero
    	jr $ra
erase_block:    	
	
	lw $s2, 0($s1) # load offset from block array 
	add $s3, $s2, $k1 #set brush position to offset from array + cursor location
	#set brush position
	move $t4, $s3
   	add $t6, $t0, $t4
	add $t7, $s0, $t4
		
    	erase
    
    	addi $s1, $s1, 4   # next offset in array
    	subi $s4, $s4, 1 #increment spawn_loop counter
    	bgt $s4, 0, erase_block # will loop 4 times bc tetris blocks made of 4 pixles on the screen
    	subi $s1, $s1, 16 # 4 offsets * 4 digits = 16 total, move the offest back to zero
    	jr $ra



