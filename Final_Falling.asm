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

.macro movebrush_left #this macro moves the brush by 1 pixel to the left on the screen
	subi $t4, $t4, 4
    add $t6, $t0, $t4
    add $t7, $s0, $t4
.end_macro

.macro movebrush_down #this macro moves the brush by 1 pixel down on the screen
	addi $t4, $t4, 64
    add $t6, $t0, $t4
    add $t7, $s0, $t4
.end_macro

.macro movebrush_up #this macro moves the brush by 1 pixel down on the screen
	subi $t4, $t4, 64
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
	setcolor_reg($s5)  #update when you add randomziation of blocks
	jal draw_block
.end_macro

.macro moveblock_left #this moves the cursor left by one
	jal erase_block
	move $t4, $k1 	
	add $t6, $t0, $t4 	
	add $t7, $s0, $t4
	movebrush_left
	reset_cursor
	setcolor_reg($s5)  #update when you add randomziation of blocks
	jal draw_block
.end_macro

.macro moveblock_down #This should move the block down, but I will leave it like this for right now, and pass it on to the next person. 
	#jal erase_block
	move $t4, $k1 	
	add $t6, $t0, $t4 	
	add $t7, $s0, $t4
	movebrush_down
	reset_cursor
	setcolor_reg($s5)  #update when you add randomziation of blocks
	jal draw_block
.end_macro

.macro moveblock_up #This should move the block up
	#jal erase_block
	move $t4, $k1 	
	add $t6, $t0, $t4 	
	add $t7, $s0, $t4
	movebrush_up
	reset_cursor
	setcolor_reg($s5)  #update when you add randomziation of blocks
	jal draw_block
.end_macro

.macro moveblock_fastdown #Moves the block down faster by 2 rows
    jal erase_block
    move $t4, $k1
    add $t6, $t0, $t4
    add $t7, $s0, $t4
    addi $k1, $k1, 64     
    add $t4, $zero, $k1   
    add $t6, $t0, $t4
    add $t7, $s0, $t4
    reset_cursor
    setcolor_reg($s5)
    jal draw_block
.end_macro

# ====== COLLISION MACROS ======
.macro check_right_collision
    la $t3, ($s1)        # Load block shape address
    li $t5, 0            # Counter
    li $v0, 0            # Default: no collision
    
right_check_loop:
    lw $s2, 0($t3)       # Get block part offset
    add $t4, $k1, $s2    # Current position
    addi $t4, $t4, 4     # Proposed right position
    
    # Check right boundary (X=60 bytes = 15 cells)
    andi $t6, $t4, 0x3F  # Get X position within row (0-63 bytes)
    li $t7, 60
    bgt $t6, $t7, right_collision
    
    # Check DIS_ARR for existing blocks
    add $t7, $s0, $t4
    lw $t8, 0($t7)
    bnez $t8, right_collision
    
    addi $t3, $t3, 4
    addi $t5, $t5, 1
    blt $t5, 4, right_check_loop
    j right_check_done
    
right_collision:
    li $v0, 1            # Collision detected
    
right_check_done:
.end_macro

.macro check_left_collision
    la $t3, ($s1)        # Load block shape address
    li $t5, 0            # Counter
    li $v0, 0            # Default: no collision
    
left_check_loop:
    lw $s2, 0($t3)       # Get block part offset
    add $t4, $k1, $s2    # Current position
    addi $t4, $t4, -4    # Proposed left position
    
    # Check left boundary (X=0)
    blt $t4, 0, left_collision
    
    # Check DIS_ARR for existing blocks
    add $t7, $s0, $t4
    lw $t8, 0($t7)
    bnez $t8, left_collision
    
    addi $t3, $t3, 4
    addi $t5, $t5, 1
    blt $t5, 4, left_check_loop
    j left_check_done
    
left_collision:
    li $v0, 1            # Collision detected
    
left_check_done:
.end_macro
# ==============================

.data
down: .asciiz "block moves down"
collides: .asciiz "collision"
DISPLAY: .word 0x10008000 #Display input
KEY_PRESS: .word 0xFFFF0000 #Keyboard output 
DIS_ARR: .byte 0:2048 #supposed to stroe digits, is not used currently
BORDER: .word 0x444444 #Border color
CURSOR: .word 0x00ff00 #Green Color - z block also
BLACK: .word 0x000000 #Black Color
PURPLE: .word 0xb56bff # Purple Color - T block
TURQUOISE: .word 0x45ffdd #Turquoise color - I block
YELLOW: .word 0xfff400 #Yellow Color - O Block
BLUE: .word 0x0004ff #Blue Color - J block
RED: .word 0xc90000 #Red color - S block
ORANGE: .word 0xff6600 #orange color - L block

T_BLOCK: .word 0, 4, 8, 68   # T shape
I_BLOCK: .word 0, 4, 8, 12 # I shape 
O_BLOCK: .word 0, 4, 64, 68 # O shape: small square
J_BLOCK: .word 0, 4, 8, 72   # mirrored L
L_BLOCK: .word 68, 4, 8, 12   # L shape
S_BLOCK: .word 8, 4, 64, 68 # S shape
Z_BLOCK: .word 0, 4, 68, 72 #Z_shaped block.....

BLOCK_TABLE: .word T_BLOCK, I_BLOCK, O_BLOCK, J_BLOCK, L_BLOCK, S_BLOCK, Z_BLOCK
COLOR_TABLE: 
    .word PURPLE    # T-block
    .word TURQUOISE # I-block
    .word YELLOW     # O-block  
    .word BLUE       # J-block
    .word ORANGE     # L-block
    .word RED        # S-block
    .word CURSOR     # Z-block 

#Before starting the code, make sure to set the bitmap display to this:
# Unit Width in Pixles - 16
#Unit Height in Pixes - 16
# Display Width in Pixels - 256
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
	jal fall_loop
	j main
	
check_key:
	lw $a0, 4($t9) #this loads the character pressed into $a0
	beq $a0, 100, D_press
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
D_loop:
    moveblock_right
    li $t5, 120000      # Same value as in fall_loop
fall_delay_d:
    subi $t5, $t5, 1
    bgtz $t5, fall_delay_d
    lw $t9, KEY_PRESS
    lw $t8, 0($t9)
    beq $t8, 0, main
    lw $a0, 4($t9)
    beq $a0, 100, D_loop
    j main
    	
A_press:
A_loop:
    moveblock_left
    li $t5, 120000   
fall_delay_a:
    subi $t5, $t5, 1
    bgtz $t5, fall_delay_a
    lw $t9, KEY_PRESS
    lw $t8, 0($t9)
    beq $t8, 0, main
    lw $a0, 4($t9)
    beq $a0, 97, A_loop
    j main
    	
S_press:
S_fastdrop_loop:
	moveblock_fastdown
	li $t5, 30000
S_fastdrop_delay:
	subi $t5, $t5, 1
	bgtz $t5, S_fastdrop_delay
	lw $t9, KEY_PRESS
	lw $t8, 0($t9)
	beq $t8, 0, main      
	lw $a0, 4($t9)
	beq $a0, 115, S_fastdrop_loop  
	j main     
	           
end:
	li $v0, 10
	syscall
	
set_board:
	set_brush(0)
	jal reset
	set_brush(0)
	jal draw_sides #adds the sides for the screen
	set_brush(1920)
	jal draw_bottom #adds the bottom for the screen
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
	beq $s4, $zero, block_spawn
	lw $ra, 0($sp)
	add $sp, $sp, 4
	jr $ra
	
block_spawn:   	
    li $v0, 42      
    li $a1, 7        
    syscall
       
    # Get random block shape
    sll $t3, $a0, 2     
    la $t2, BLOCK_TABLE
    add $t2, $t2, $t3  
    lw $s1, 0($t2)     
    # Get corresponding color
    la $t2, COLOR_TABLE
    add $t2, $t2, $t3   
    lw $s5, 0($t2)      
    setcolor_reg($s5)   
    li $s4, 0          
    jal draw_block
    lw $ra, 0($sp)
    add $sp, $sp, 4
    jr $ra
    	
reset_cursor_func:
	#li $s4, 4 
	#jal erase_block
	set_brush(0)
	jal draw_sides #to fix sides (erase_block removes parts of the sides so I just reset the entire thing, no issues)
	jal draw_bottom
	set_brush(28)
	reset_cursor
	li $s4, 0 
	j main
	
move_down:
	li $t5, 0 #set counter for check_fall_loop
    	move $s6, $s1 #move current block base into another register
    	#move $t3, $s
    	addi $s7, $k1, 64
    	jal erase_block
    	
check_fall_loop:
	lw $s2, 0($s6) 
	add $t3, $s2, $s7
	add $t7, $s0, $t3
	andi $t7, $t7, 0xFFFFFFFC
	lw $t2, 0($t7)
	beq $t2, 1, set_collision
	
    addi $s6, $s6, 4
    addi $t5, $t5, 1
    blt $t5, 4, check_fall_loop
    
    #if no collision move the block down
    li $v0, 4
    la $a0, down
    syscall
    
    moveblock_down       
    li $s7, 0
    j fall_loop
    	
set_collision:
     li $v0, 4
    la $a0, collides
    syscall
    
    #redraw the block
    move $s6, $s1
    li $s4, 0
    
    move $t4, $k1 	
    add $t6, $t0, $t4 	
    add $t7, $s0, $t4
    reset_cursor
    setcolor_reg($s5)
    draw_new_block:
    	lw $s2, 0($s6) 
	add $s3, $s2, $k1
	move $t4, $s3
   	add $t6, $t0, $t4
	add $t7, $s0, $t4 
	andi $t7, $t7, 0xFFFFFFFC
        paint
        addi $s6, $s6, 4   
        addi $s4, $s4, 1 
        blt $s4, 4, draw_new_block 
	subi $s6, $s6, 16
    	#jr $ra
    	
   
    jal check_full_lines
    jal reset_cursor_func
    li $s7, 0
    j fall_loop
    	
draw_block:
	lw $s2, 0($s1) 
	add $s3, $s2, $k1 
	move $t4, $s3
   	add $t6, $t0, $t4
	add $t7, $s0, $t4 
	andi $t7, $t7, 0xFFFFFFFC
	lw $t2, 0($t7)
	beq $t2, 1, reset_cursor_func	
        paint
        addi $s1, $s1, 4   
        addi $s4, $s4, 1 
        blt $s4, 4, draw_block 
	subi $s1, $s1, 16
    	jr $ra
    	
erase_block:   
	lw $s2, 0($s1)  
	add $s3, $s2, $k1 
	move $t4, $s3
   	add $t6, $t0, $t4
	add $t7, $s0, $t4
    erase
    addi $s1, $s1, 4  
    subi $s4, $s4, 1
    bgt $s4, 0, erase_block
    subi $s1, $s1, 16 
    jr $ra
    	
fall_loop:
    li $t5, 20000
fall_delay:
    subi $t5, $t5, 1
    bgtz $t5, fall_delay
    lw $t9, KEY_PRESS
    lw $t8, 0($t9)
    beq $t8, 0, handle_fall  
    lw $a0, 4($t9)
    beq $a0, 97, do_left   
    beq $a0, 100, do_right  
    beq $a0, 115, do_softdrop
    beq $a0, 113, end       
handle_fall:
   addi $s7, $s7, 1
    li $t6, 6
    blt $s7, $t6, fall_loop
 
    jal move_down
    li $s7, 0
    j fall_loop
do_left:
    moveblock_left
    j handle_fall 
do_right:
    moveblock_right
    j handle_fall 
do_softdrop:
    moveblock_fastdown
    j handle_fall 

check_full_lines:
    li $t1, 0          # Starting offset in DIS_ARR
    li $t2, 0          # Cleared row counter

check_row_loop:
    li $t3, 8          # Start at 2nd column (skip first 2)
    li $t4, 0          # Cell value sum
sum_row:
    add $t6, $s0, $t1
    add $t6, $t6, $t3
    lw $t7, 0($t6)
    add $t4, $t4, $t7
    addi $t3, $t3, 4
    li $t8, 56         # 8 + 48 (12 columns) = 56
    blt $t3, $t8, sum_row

    li $t9, 12         # Expect 12 filled cells, other 4 for sides
    beq $t4, $t9, clear_this_row

next_row:
    addi $t1, $t1, 64
    li $t9, 1920  # 30 * 64 Û ignore bottom border row so it doesnt delete
    blt $t1, $t9, check_row_loop
    j end_check 

clear_this_row:
    move $a0, $t1
    jal clear_line
    addi $t2, $t2, 1
    j check_row_loop   # Recheck the same row index

clear_line:
        li $t3, 8              # Start at playable column (2nd column)
clear_loop:
    add $t4, $s0, $a0
    add $t4, $t4, $t3
    sw $zero, 0($t4)

    add $t6, $t0, $a0
    add $t6, $t6, $t3
    li $t7, 0x000000
    sw $t7, 0($t6)

    addi $t3, $t3, 4
    li $t8, 56             # 8 to 56 = 12 columns
    blt $t3, $t8, clear_loop

    # Shift rows above
    move $t9, $a0

shift_rows:
    subi $t9, $t9, 64
    blt $t9, 0, end_shift

    li $t3, 8              # Start at column 2
shift_cells:
    add $s1, $s0, $t9
    add $s1, $s1, $t3
    add $s2, $s0, $t9
    addi $s2, $s2, 64
    add $s2, $s2, $t3
    lw $t4, 0($s1)
    sw $t4, 0($s2)

    add $s3, $t0, $t9
    add $s3, $s3, $t3
    add $s4, $t0, $t9
    addi $s4, $s4, 64
    add $s4, $s4, $t3
    lw $t5, 0($s3)
    sw $t5, 0($s4)

    addi $t3, $t3, 4
    li $t8, 56
    blt $t3, $t8, shift_cells

    subi $a0, $a0, 64
    j shift_rows

end_shift:
    jr $ra
end_check:
	jal reset_cursor_func
    