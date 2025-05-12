# ================================================================
#               MIPS Tetris-Style Game Project
# ================================================================
# Author Names: Ryan Pham, Ben Tzobery, Eric Lee, Sarah To, Julian Gonzalez
# Date: 5/11/25

# Description:
# This program implements a simplified Tetris-style game using
# MIPS assembly. It utilizes bitmap memory-mapped I/O to render
# tetromino blocks on screen and captures keyboard inputs through
# memory-mapped keyboard registers. The game supports movement 
# (left, right, soft drop), row clearing, and game-over logic.

# Goals of the Program:
# - Demonstrate low-level game logic using MIPS assembly.
# - Reinforce understanding of memory-mapped I/O and bitmap rendering.
# - Implement block collision, user input handling, and game state logic.
# - Practice managing the stack, syscall use, and register discipline.
# - Create a complete and playable game loop including restart/exit.

# Requirements:
# - MARS MIPS Simulator.
# - Tools > Keyboard and Display MMIO Simulator (connect to MIPS).
# - Tools > Bitmap Display with the following settings (connect to MIPS):
#   * Unit Width in Pixels: 16
#   * Unit Height in Pixels: 16
#   * Display Width in Pixels: 256
#   * Display Height in Pixels: 512
#   * Base Address for Display: 0x10008000
# - Controls:
#   * A - Move block left
#   * D - Move block right
#   * S - Soft drop (faster fall)
#   * P - Play again (on game over)
#   * Q - Quit the game
# ================================================================

# ========== MACROS ==========

.macro set_brush(%int) # Move the drawing brush to a specific memory offset
	li $t4, %int
	add $t6, $t0, $t4
	add $t7, $s0, $t4
.end_macro

.macro reset_cursor # Save current brush position as reference for block movement
	move $k1, $t4
.end_macro

.macro movebrush_right # Move brush one pixel right
	addi $t4, $t4, 4
	add $t6, $t0, $t4
	add $t7, $s0, $t4
.end_macro

.macro movebrush_left # Move brush one pixel left
	subi $t4, $t4, 4
	add $t6, $t0, $t4
	add $t7, $s0, $t4
.end_macro

.macro movebrush_down # Move brush one pixel down
	addi $t4, $t4, 64
	add $t6, $t0, $t4
	add $t7, $s0, $t4
.end_macro

.macro paint # Paint pixel at current brush with color in $t1
	sw $t1, 0($t6)
	li $t2, 1
	andi $t7, $t7, 0xFFFFFFFC
	sw $t2, 0($t7) 
.end_macro

.macro erase # Erase pixel (set to black)
	setcolor_string(BLACK)
	sw $t1, 0($t6)
	li $t2, 0
	andi $t7, $t7, 0xFFFFFFFC
	sw $t2, 0($t7)
.end_macro

.macro setcolor_string(%string) # Set paint color from label
	la $t1, %string
	lw $t1, 0($t1)
.end_macro

.macro setcolor_reg(%string) # Set paint color from register
	move $t1, %string
	lw $t1, 0($t1)
.end_macro

# Block movement macros (right/left/down/fast-down)

.macro moveblock_right         # Moves block one cell to the right
	jal erase_block            # Remove current block from screen
	move $t4, $k1              # Update brush location
	add $t6, $t0, $t4
	add $t7, $s0, $t4
	movebrush_right            # Physically move brush
	reset_cursor               # Save updated position
	setcolor_reg($s5)          # Set color
	jal draw_block             # Redraw block
.end_macro

.macro moveblock_left          # Moves block one cell to the left
	jal erase_block
	move $t4, $k1
	add $t6, $t0, $t4
	add $t7, $s0, $t4
	movebrush_left
	reset_cursor
	setcolor_reg($s5)
	jal draw_block
.end_macro

.macro moveblock_down          # Moves block down one row (without erasing)
	move $t4, $k1
	add $t6, $t0, $t4
	add $t7, $s0, $t4
	movebrush_down
	reset_cursor
	setcolor_reg($s5)
	jal draw_block
.end_macro

.macro moveblock_fastdown      # Soft drop: moves block down two rows
    jal erase_block
    move $t4, $k1
    add $t6, $t0, $t4
    add $t7, $s0, $t4
    addi $k1, $k1, 64          # Advance cursor one row
    add $t4, $zero, $k1
    add $t6, $t0, $t4
    add $t7, $s0, $t4
    reset_cursor
    setcolor_reg($s5)
    jal draw_block
.end_macro

# === Collision Macros (for left/right movement boundaries and overlapping cells) ===

.macro check_right_collision    # Checks if moving right causes a collision
    la $t3, ($s1)
    li $t5, 0
    li $v0, 0                  # Default: no collision

right_check_loop:
    lw $s2, 0($t3)             # Get block cell offset
    add $t4, $k1, $s2
    addi $t4, $t4, 4           # Try to move right
    andi $t6, $t4, 0x3F
    li $t7, 60                 # Right edge
    bgt $t6, $t7, right_collision

    add $t7, $s0, $t4
    lw $t8, 0($t7)
    bnez $t8, right_collision

    addi $t3, $t3, 4
    addi $t5, $t5, 1
    blt $t5, 4, right_check_loop
    j right_check_done

right_collision:
    li $v0, 1                  # Collision occurred

right_check_done:
.end_macro

.macro check_left_collision     # Checks if moving left causes a collision
    la $t3, ($s1)
    li $t5, 0
    li $v0, 0

left_check_loop:
    lw $s2, 0($t3)
    add $t4, $k1, $s2
    addi $t4, $t4, -4
    blt $t4, 0, left_collision

    add $t7, $s0, $t4
    lw $t8, 0($t7)
    bnez $t8, left_collision

    addi $t3, $t3, 4
    addi $t5, $t5, 1
    blt $t5, 4, left_check_loop
    j left_check_done

left_collision:
    li $v0, 1

left_check_done:
.end_macro

# ========== DATA SECTION ==========

.data

gameOverMsg: .asciiz "\n*** GAME OVER ***\n"
menuMsg:     .asciiz "Press 'p' to play again, 'q' to quit\n"

DISPLAY: .word 0x10008000         # Framebuffer base address
KEY_PRESS: .word 0xFFFF0000       # Keyboard input register
DIS_ARR: .byte 0:2048             # Array for collision detection

# Colors
BORDER: .word 0x444444
CURSOR: .word 0x00ff00
BLACK: .word 0x000000
PURPLE: .word 0xb56bff
TURQUOISE: .word 0x45ffdd
YELLOW: .word 0xfff400
BLUE: .word 0x0004ff
RED: .word 0xc90000
ORANGE: .word 0xff6600

# Block shapes (4 values = 4 pixel offsets)
T_BLOCK: .word 0, 4, 8, 68
I_BLOCK: .word 0, 4, 8, 12
O_BLOCK: .word 0, 4, 64, 68
J_BLOCK: .word 0, 4, 8, 72
L_BLOCK: .word 68, 4, 8, 12
S_BLOCK: .word 8, 4, 64, 68
Z_BLOCK: .word 0, 4, 68, 72

# Tables
BLOCK_TABLE: .word T_BLOCK, I_BLOCK, O_BLOCK, J_BLOCK, L_BLOCK, S_BLOCK, Z_BLOCK
COLOR_TABLE:
    .word PURPLE
    .word TURQUOISE
    .word YELLOW
    .word BLUE
    .word ORANGE
    .word RED
    .word CURSOR

#Before starting the code, make sure to set the bitmap display to this:
# Unit Width in Pixles - 16
#Unit Height in Pixes - 16
# Display Width in Pixels - 256
#Display Height in Pixels - 512
#Base Adress for display - 0x10008000 ($gp)

#Make sure to connect both the bitmap display and the Keyboard and Display MMIO Simulator as well.

.text

# ================================
# TETRIS MAIN GAME LOOP
# ================================

main:
	lw $t0, DISPLAY         # Load the base address of the bitmap display into $t0
	la $s0, DIS_ARR         # Load address of game board array (used for logic) into $s0

	jal initial_spawn       # Spawn the first block at the top of the board

	lw $t9, KEY_PRESS       # Load address of memory-mapped I/O for keyboard
	lw $t8, 0($t9)          # Load the status of the key press (1 if a key is pressed)

	beq $t8, 1, check_key   # If a key is pressed, jump to key-checking routine

	jal fall_loop           # Otherwise, continue the block's natural fall down the board

	j main                  # Loop back to main

# ================================
# CHECK PRESSED KEY AND HANDLE
# ================================

check_key:
	lw $a0, 4($t9)          # Load ASCII value of the key that was pressed into $a0
	beq $a0, 100, D_press   # If 'd' is pressed (ASCII 100), move block right
	beq $a0, 97, A_press    # If 'a' is pressed (ASCII 97), move block left
	beq $a0, 115, S_press   # If 's' is pressed (ASCII 115), soft drop the block

	j main                  # If no relevant key was pressed, return to main loop

# ================================
# DRAW LEFT/RIGHT/BOTTOM BORDERS
# ================================

draw_sides:
	setcolor_string(BORDER) # Set brush color to border color

	paint                   # Paint left edge pixel

    movebrush_right         # Move brush one unit to the right
    paint                   # Paint right next to the edge

    addi $t4, $t4, 52       # Move brush forward 52 units (toward right edge)
    add $t6, $t0, $t4       # Update framebuffer pointer
    add $t7, $s0, $t4       # Update logic array pointer

    paint                   # Paint near right edge

	movebrush_right         # Move brush again and paint
   	paint
	movebrush_right         # Move and paint again for full thickness
   	blt $t4, 1914, draw_sides # Repeat until right edge is reached
   	jr $ra

draw_bottom:
	setcolor_string(BORDER) # Set color to border for bottom

	paint                   # Paint bottom left pixel
	movebrush_right         # Move brush right

	blt $t4, 2045, draw_bottom # Repeat until full bottom row is drawn
	jr $ra

# ================================
# KEY: MOVE BLOCK RIGHT ('d')
# ================================

D_press:
D_loop:
    moveblock_right         # Macro to erase, move, and redraw block to the right

    li $t5, 120000          # Delay loop to slow down repeated movement
fall_delay_d:
    subi $t5, $t5, 1        # Decrement delay
    bgtz $t5, fall_delay_d  # Keep looping until delay completes

    lw $t9, KEY_PRESS       # Check if key still pressed
    lw $t8, 0($t9)
    beq $t8, 0, main        # If no key is pressed anymore, return to main

    lw $a0, 4($t9)
    beq $a0, 100, D_loop    # If 'd' is still pressed, repeat move
    j main                  # Otherwise, return to main

# ================================
# KEY: MOVE BLOCK LEFT ('a')
# ================================

A_press:
A_loop:
    moveblock_left          # Macro to erase, move, and redraw block to the left

    li $t5, 120000
fall_delay_a:
    subi $t5, $t5, 1
    bgtz $t5, fall_delay_a

    lw $t9, KEY_PRESS
    lw $t8, 0($t9)
    beq $t8, 0, main

    lw $a0, 4($t9)
    beq $a0, 97, A_loop     # If 'a' is still pressed, keep moving left
    j main

# ================================
# KEY: SOFT DROP BLOCK ('s')
# ================================

S_press:
S_fastdrop_loop:
	moveblock_fastdown      # Macro that makes the block fall by 2 rows quickly

	li $t5, 30000           # Shorter delay to make it feel faster
S_fastdrop_delay:
	subi $t5, $t5, 1
	bgtz $t5, S_fastdrop_delay

	lw $t9, KEY_PRESS
	lw $t8, 0($t9)
	beq $t8, 0, main        # If key released, go back to main loop

	lw $a0, 4($t9)
	beq $a0, 115, S_fastdrop_loop  # If 's' still pressed, repeat fast drop
	j main

# ================================
# GAME END SECTION
# ================================

.globl end
end:
    j game_over             # Jump to game over screen

# ========================================
# === GAME OVER AND RESTART MENU LOGIC ===
# ========================================

game_over:
    # Print "*** GAME OVER ***"
    li   $v0, 4               # syscall for print_string
    la   $a0, gameOverMsg     # load address of game over message
    syscall

    # Prompt user with restart/quit message
    li   $v0, 4
    la   $a0, menuMsg
    syscall

wait_choice:
    # Wait for key press (polling the MMIO device)
    lw   $t9, KEY_PRESS       # Load MMIO address for keyboard
    lw   $t8, 0($t9)          # Check if a key is pressed (1 means yes)
    beq  $t8, 0, wait_choice  # Loop until key is pressed

    # Get pressed key's ASCII value
    lw   $a0, 4($t9)          # Load ASCII value of key into $a0
    li   $t1, 'p'             # ASCII for 'p'
    beq  $a0, $t1, restart_game # If 'p' pressed, restart game

    li   $t2, 'q'             # ASCII for 'q'
    beq  $a0, $t2, do_exit    # If 'q' pressed, exit program

    j    wait_choice          # Otherwise, keep waiting for valid input

# ================================
# === RESTART OR EXIT LOGIC    ===
# ================================

restart_game:
    # Reset board and game variables
    jal  set_board            # Re-draw border, clear screen
    li   $s7, 0               # Reset fall counter
    j    main                 # Return to game loop

do_exit:
    li   $v0, 10              # syscall for exit
    syscall

# =======================================
# === BOARD INITIALIZATION / CLEANUP ====
# =======================================

set_board:
	set_brush(0)             # Set brush to pixel 0 (top left corner)
	jal reset                # Clear all display area

	set_brush(0)
	jal draw_sides           # Draw left and right borders

	set_brush(1920)
	jal draw_bottom          # Draw bottom border

	set_brush(28)            # Move brush to the default spawn location
	reset_cursor             # Store the spawn location in $k1

	move $s4, $zero          # Clear pixel paint counter
	li $s3, 1                # Set game state flag (to skip set_board on next spawn)

	j main                   # Start the game loop

reset:
	erase                    # Clear the current pixel (set to black)
	movebrush_right          # Move brush to next pixel to the right
	blt $t4, 2045, reset     # Repeat until full display is erased
	jr $ra

# =======================================
# === SPAWN HANDLING ===
# =======================================

initial_spawn:
	sub $sp, $sp, 4          # Allocate stack space to save return address
	sw $ra, 0($sp)           # Save return address

	beqz $s3, set_board      # If game not started yet, draw borders first

	beq $s4, $zero, block_spawn  # If no block is active, spawn a new one

	lw $ra, 0($sp)           # Restore return address
	add $sp, $sp, 4          # Clean up stack
	jr $ra                   # Return

block_spawn:
    # Allocate stack frame to save return address
    sub   $sp, $sp, 4
    sw    $ra, 0($sp)

    # Generate a pseudo-random number [0, 6] to choose block type
    li    $v0, 42           # syscall for random integer
    li    $a1, 7            # max = 7
    syscall                 # result in $a0

    # Compute block shape pointer and store in $s1
    sll   $t3, $a0, 2       # t3 = $a0 * 4 (word index)
    la    $t2, BLOCK_TABLE  # Base address of block shape array
    add   $t2, $t2, $t3
    lw    $s1, 0($t2)       # Load pointer to block shape into $s1

    # Load corresponding color into $s5
    la    $t2, COLOR_TABLE
    add   $t2, $t2, $t3
    lw    $s5, 0($t2)

    # ========== COLLISION CHECK ON SPAWN ==========
    li    $t5, 0            # Loop counter
    move  $t3, $s1          # Load block shape pointer

spawn_check:
    lw    $s2, 0($t3)       # Get offset of each cell in the shape
    add   $t4, $k1, $s2     # Proposed memory offset of block part
    la    $t6, DIS_ARR
    add   $t6, $t6, $t4     # Calculate cell address in logic array
    lb    $t8, 0($t6)       # Read logic value (1 = filled)

    bnez  $t8, game_over    # If block would overlap, game is over

    addi  $t3, $t3, 4       # Move to next cell of the block
    addi  $t5, $t5, 1
    blt   $t5, 4, spawn_check # Repeat for all 4 cells

    # ========== DRAW BLOCK IF NO COLLISION ==========
    setcolor_reg($s5)       # Set color for current block
    li    $s4, 0            # Reset paint counter
    jal   draw_block        # Draw block on screen

    # Restore return address and exit
    lw    $ra, 0($sp)
    add   $sp, $sp, 4
    jr    $ra

# ==========================================
# === RESET CURSOR & FALL LOGIC ROUTINES ===
# ==========================================

reset_cursor_func:
	set_brush(0)              # Set brush to start of display
	jal draw_sides            # Repaint left and right borders (in case they were erased)
	jal draw_bottom           # Repaint bottom border
	set_brush(28)             # Set brush to spawn location
	reset_cursor              # Store cursor location in $k1 for new block spawn
	li $s4, 0                 # Reset draw counter
	j main                    # Go back to main game loop

# ==========================================
# === BLOCK FALL HANDLING (gravity step) ===
# ==========================================

move_down:
	li $t5, 0                 # Counter for checking all 4 parts of block
	move $s6, $s1             # Copy block pointer into $s6 (so $s1 isn't altered)
	addi $s7, $k1, 64         # Predict the next position (1 row down)
	jal erase_block           # Temporarily erase the current block from display

check_fall_loop:
	lw $s2, 0($s6)            # Load current cell offset of block
	add $t3, $s2, $s7         # Compute target address of that block part
	add $t7, $s0, $t3         # Offset into logic array (DIS_ARR)
	andi $t7, $t7, 0xFFFFFFFC # Align to word boundary
	lw $t2, 0($t7)            # Check if cell is already filled
	beq $t2, 1, set_collision # If filled, block cannot fall — trigger collision

	addi $s6, $s6, 4          # Move to next block cell
	addi $t5, $t5, 1
	blt $t5, 4, check_fall_loop # Repeat for all 4 cells

	# If no collision, move block down and continue
	moveblock_down
	li $s7, 0                 # Reset fall counter
	j fall_loop               # Go back to fall loop

# ==========================================
# === BLOCK COLLISION HANDLING & DRAWING ===
# ==========================================

set_collision:
	move $s6, $s1             # Reload block pointer
	li $s4, 0                 # Reset draw counter

	move $t4, $k1             # Restore brush position from cursor
	add $t6, $t0, $t4         # Set display pointer
	add $t7, $s0, $t4         # Set logic array pointer
	reset_cursor              # Reset spawn position reference

	setcolor_reg($s5)         # Set color for final block placement

draw_new_block:
	lw $s2, 0($s6)            # Load offset of block part
	add $s3, $s2, $k1         # Compute display offset
	move $t4, $s3
	add $t6, $t0, $t4         # Display memory address
	add $t7, $s0, $t4         # Logic memory address
	andi $t7, $t7, 0xFFFFFFFC # Align address to word boundary
	paint                     # Paint the block
	addi $s6, $s6, 4          # Next block cell
	addi $s4, $s4, 1
	blt $s4, 4, draw_new_block # Loop for 4 block cells
	subi $s6, $s6, 16         # Reset $s6 to original shape pointer

	jal check_full_lines      # Check for and clear full rows
	jal reset_cursor_func     # Redraw borders and reset cursor
	li $s7, 0                 # Reset fall timer
	j fall_loop               # Continue game

# ==========================================
# === DRAW AND ERASE ROUTINES ===
# ==========================================

draw_block:
	lw $s2, 0($s1)            # Load offset of a block cell
	add $s3, $s2, $k1         # Calculate memory offset
	move $t4, $s3
	add $t6, $t0, $t4         # Display address
	add $t7, $s0, $t4         # Logic address
	andi $t7, $t7, 0xFFFFFFFC # Align to word boundary
	lw $t2, 0($t7)            # Check if pixel is occupied
	beq $t2, 1, reset_cursor_func # If collision at draw time, restart

	paint                     # Draw the pixel
	addi $s1, $s1, 4          # Move to next offset in block shape
	addi $s4, $s4, 1          # Increment painted cells counter
	blt $s4, 4, draw_block    # Draw all 4 parts
	subi $s1, $s1, 16         # Reset shape pointer
	jr $ra                    # Return from draw_block

erase_block:
	lw $s2, 0($s1)            # Load offset of block part
	add $s3, $s2, $k1         # Compute full offset
	move $t4, $s3
	add $t6, $t0, $t4         # Display address
	add $t7, $s0, $t4         # Logic array address
	erase                    # Remove from screen and logic
	addi $s1, $s1, 4          # Next block cell
	subi $s4, $s4, 1          # Decrease paint counter
	bgt $s4, 0, erase_block   # Continue until all 4 cells erased
	subi $s1, $s1, 16         # Reset shape pointer
	jr $ra                    # Return
    	
# ========================
# === FALL LOOP TIMER ===
# ========================
fall_loop:
    li $t5, 20000          # Delay loop counter (slows down block fall)
fall_delay:
    subi $t5, $t5, 1       # Subtract 1 from delay counter
    bgtz $t5, fall_delay   # If delay not finished, loop again

    # Check if a key was pressed
    lw $t9, KEY_PRESS      # Load base address for keyboard input
    lw $t8, 0($t9)         # Check key press flag (1 if key was pressed)
    beq $t8, 0, handle_fall # If no key pressed, continue normal fall

    lw $a0, 4($t9)         # Load the actual key code pressed
    beq $a0, 97, do_left   # 'a' key pressed → move block left
    beq $a0, 100, do_right # 'd' key pressed → move block right
    beq $a0, 115, do_softdrop # 's' key pressed → soft drop

# ========================
# === GRAVITY HANDLER ===
# ========================
handle_fall:
    addi $s7, $s7, 1       # Increment gravity counter
    li $t6, 6              # Threshold for gravity-triggered fall
    blt $s7, $t6, fall_loop # If not time to fall yet, restart loop

    jal move_down          # Perform gravity-based fall
    li $s7, 0              # Reset gravity counter
    j fall_loop            # Continue falling

# ========================
# === MANUAL MOVEMENT ===
# ========================
do_left:
    moveblock_left         # Move block left
    j handle_fall

do_right:
    moveblock_right        # Move block right
    j handle_fall

do_softdrop:
    moveblock_fastdown     # Accelerate block downward
    j handle_fall


# ===================================
# === CHECK FOR FULL LINES ===
# ===================================
check_full_lines:
    li $t1, 0              # Starting row offset in DIS_ARR
    li $t2, 0              # Cleared row counter (optional)

check_row_loop:
    li $t3, 8              # Start at second column (skipping walls)
    li $t4, 0              # Sum of current row's filled cells

# Sum the row from column 2 to column 13 (12 cells total)
sum_row:
    add $t6, $s0, $t1      # Base of current row in DIS_ARR
    add $t6, $t6, $t3      # Offset to current column
    lw $t7, 0($t6)         # Load cell value (0 or 1)
    add $t4, $t4, $t7      # Accumulate into row sum
    addi $t3, $t3, 4       # Move to next column
    li $t8, 56             # Last playable column offset
    blt $t3, $t8, sum_row  # Continue summing row

    # If all 12 playable cells are filled, clear row
    li $t9, 12
    beq $t4, $t9, clear_this_row

# Move to next row
next_row:
    addi $t1, $t1, 64      # Each row is 64 bytes apart
    li $t9, 1920           # Stop before bottom border (30*64)
    blt $t1, $t9, check_row_loop # Loop through all rows
    j end_check            # Done checking rows

# ===========================
# === CLEAR A FULL LINE ====
# ===========================
clear_this_row:
    move $a0, $t1          # Pass row offset to clear_line
    jal clear_line         # Clear the row visually and logically
    addi $t2, $t2, 1       # Track how many lines cleared
    j next_row             # Check next row

# ===========================================
# === ERASE VISUAL & LOGIC DATA FROM ROW ===
# ===========================================
clear_line:
    li $t3, 8              # Start at second column

clear_loop:
    add $t4, $s0, $a0      # Logical array (DIS_ARR) row base
    add $t4, $t4, $t3      # Logical cell address
    sw $zero, 0($t4)       # Clear logic (0 = empty)

    add $t6, $t0, $a0      # Bitmap display base
    add $t6, $t6, $t3      # Pixel display address
    li $t7, 0x000000       # Black pixel color
    sw $t7, 0($t6)         # Clear pixel

    addi $t3, $t3, 4
    li $t8, 56             # End at last playable column
    blt $t3, $t8, clear_loop

    # ===========================
    # === SHIFT ROWS DOWNWARD ===
    # ===========================

    move $t9, $a0          # Start shifting from cleared row

shift_rows:
    subi $t9, $t9, 64      # Move one row up
    blt $t9, 0, end_shift   # If past top row, stop

    li $t3, 8              # Column index starts at 2nd col

shift_cells:
    # Copy logical cell
    add $s1, $s0, $t9
    add $s1, $s1, $t3
    add $s2, $s0, $t9
    addi $s2, $s2, 64
    add $s2, $s2, $t3
    lw $t4, 0($s1)
    sw $t4, 0($s2)

    # Copy display pixel
    add $s3, $t0, $t9
    add $s3, $s3, $t3
    add $s4, $t0, $t9
    addi $s4, $s4, 64
    add $s4, $s4, $t3
    lw $t5, 0($s3)
    sw $t5, 0($s4)

    addi $t3, $t3, 4
    li $t8, 56
    blt $t3, $t8, shift_cells # Continue for all columns

    subi $a0, $a0, 64
    j shift_rows             # Continue shifting next row

end_shift:
    jr $ra                   # Return from clear_line

# Return from check_full_lines after all rows checked
end_check:
    jal reset_cursor_func    # Reset cursor and repaint edges
