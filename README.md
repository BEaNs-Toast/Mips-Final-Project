# Mips-Final-Project
We developed a playable Tetris‑style game entirely in MIPS assembly to explore low‑level programming concepts such as memory‑mapped I/O, system calls, and register management. This project challenged us to render colored tetrominoes directly into a bitmap framebuffer at address 0x10008000 and to capture real‑time keyboard input via the Memory‑Mapped I/O interface at 0xffff0000. By building this game, we reinforced our understanding of data layouts, macros, and control flow while creating an interactive graphics demonstration.

To run the game, you will need the MARS MIPS Simulator and two simulator tools: the Keyboard and Display MMIO Simulator and the Bitmap Display. First, open Final_Project.asm in MARS, then assemble the program with F3. Next, go to Tools > Keyboard and Display MMIO Simulator and click Connect to MIPS and run it with F5. Then open Tools > Bitmap Display and set the following configuration exactly:

• Unit Width in Pixels: 16
• Unit Height in Pixels: 16
• Display Width in Pixels: 256
• Display Height in Pixels: 512
• Base Address for Display: 0x10008000 ($gp)

Once both simulators are connected, the game initializes and you can control the active tetromino using the keyboard: press a to move left, d to move right, and s for a soft drop. When the stack reaches the top, the game will display a GAME OVER message and prompt you to play again or quit. Press p to restart the game or q to exit
