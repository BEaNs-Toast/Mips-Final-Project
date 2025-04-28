# Minimal‑change Tetris Sandbox
# * Grey rails + floor draw once.
# * One green block moves with:
#       a ← left   d → right   s ↓ down   r (prints)   q (quit)
# * Uses MARS keyboard MMIO layout:
#0xFFFF0000  Receiver‑CONTROL (bit‑0 = ready)
#0xFFFF0004  Receiver‑DATA    (ASCII)


#Compile‑time constants
.eqv VRAM_BASE           0x10008000   # bitmap MMIO base
.eqv KEY_CTRL            0xFFFF0000   # keyboard control reg (ready bit)
.eqv KEY_DATA            0xFFFF0004   # keyboard data reg   (ASCII)

# 128‑word‑wide (Display Map Settings - 16, 16, 128, 512)
.eqv DISPLAY_W_WORDS     128
.eqv SCREEN_STRIDE       512          

.eqv LEFT_OFFSET_PLAY    8           
.eqv RIGHT_OFFSET_PLAY   48          


.eqv DOWN_LIMIT_BYTES    1480

#Macros
.macro syscall_msg(%lbl)
    li   $v0, 4
    la   $a0, %lbl
    syscall
.end_macro

.macro set_brush_imm(%off)
    li   $t4, %off
    add  $t6, $t0, $t4
    add  $t7, $s0, $t4
.end_macro

.macro sync_brush_from_t4
    add  $t6, $t0, $t4
    add  $t7, $s0, $t4
.end_macro

.macro movebrush
    addi $t4, $t4, 4
    sync_brush_from_t4
.end_macro

.macro paint
    sw   $t1, 0($t6)
.end_macro

#Data
.data
DISPLAY:      .word VRAM_BASE
KEY_CTRL_ADDR:.word KEY_CTRL
KEY_DATA_ADDR:.word KEY_DATA

D_key: .asciiz "Block goes right\n"
A_key: .asciiz "Block goes left\n"
S_key: .asciiz "Block snaps down\n"
R_key: .asciiz "Rotate (not yet)\n"

BORDER:       .word 0x444444
BLOCK_COLOR:  .word 0x00ff00
BLACK:        .word 0x000000

DIS_ARR: .space 2048
curr_off: .word 0

#Text
.text
.globl main

main:
    lw   $t0, DISPLAY          # VRAM base
    la   $s0, DIS_ARR

    # draw border
    set_brush_imm(0)
    jal  draw_sides
    set_brush_imm(1920)
    jal  draw_bottom

    # spawn first block
    li   $t1, LEFT_OFFSET_PLAY
    sw   $t1, curr_off
    set_brush_imm(LEFT_OFFSET_PLAY)
    la   $t2, BLOCK_COLOR
    lw   $t1, 0($t2)
    paint

#Nain
main_loop:
    # poll keyboard MMIO
    lw   $t9, KEY_CTRL_ADDR     # $t9 = 0xFFFF0000
    lw   $t8, 0($t9)            # control / ready bit
    andi $t8, $t8, 1
    beqz $t8, main_loop         # not ready

    lw   $a0, 4($t9)            # read ASCII from DATA reg (auto‑clears ready)

    li   $t2, 'd'
    beq  $a0, $t2, D_press
    li   $t2, 'a'
    beq  $a0, $t2, A_press
    li   $t2, 's'
    beq  $a0, $t2, S_press
    li   $t2, 'r'
    beq  $a0, $t2, R_press
    li   $t2, 'q'
    beq  $a0, $t2, quit
    j    main_loop

#Keyboard
D_press:
    la   $t3, curr_off
    lw   $t4, 0($t3)
    li   $t5, 44               # right edge before wall
    bge  $t4, $t5, key_done
    # erase old
    sync_brush_from_t4
    la   $t1, BLACK
    paint
    # draw new
    addi $t4, $t4, 4
    sw   $t4, 0($t3)
    sync_brush_from_t4
    la   $t1, BLOCK_COLOR
    paint
    syscall_msg D_key
    j   main_loop

A_press:
    la   $t3, curr_off
    lw   $t4, 0($t3)
    li   $t5, LEFT_OFFSET_PLAY
    ble  $t4, $t5, key_done
    sync_brush_from_t4
    la   $t1, BLACK
    paint
    addi $t4, $t4, -4
    sw   $t4, 0($t3)
    sync_brush_from_t4
    la   $t1, BLOCK_COLOR
    paint
    syscall_msg A_key
    j   main_loop

S_press:
    la   $t3, curr_off
    lw   $t4, 0($t3)
    addi $t4, $t4, SCREEN_STRIDE
    li   $t5, DOWN_LIMIT_BYTES
    bgt  $t4, $t5, key_done
    sync_brush_from_t4
    la   $t1, BLACK
    paint
    sw   $t4, 0($t3)
    sync_brush_from_t4
    la   $t1, BLOCK_COLOR
    paint
    syscall_msg S_key
    j   main_loop

R_press:
    syscall_msg R_key
key_done:
    j   main_loop

quit:
    li   $v0, 10
    syscall

#Border
.globl draw_sides
draw_sides:
    la $t5, BORDER
    lw $t1, 0($t5)
paint_left:
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
    blt $t4, 1914, paint_left
    jr $ra

.globl draw_bottom
draw_bottom:
    la $t5, BORDER
    lw $t1, 0($t5)
paint_floor:
    paint
    movebrush
    blt $t4, 2045, paint_floor
    jr $ra
