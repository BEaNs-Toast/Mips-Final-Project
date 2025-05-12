We developed a playable Tetris-style game entirely in MIPS assembly to explore low-level programming concepts such as memory-mapped I/O, system calls, and register-level control. This project challenged us to render colored tetrominoes directly into a bitmap framebuffer located at memory address 0x10008000 and to capture real-time keyboard input using the memory-mapped interface at 0xFFFF0000. Through this hands-on implementation, we deepened our understanding of macros, data layouts, and control flow while creating an interactive graphical application.

To run the game, you’ll need the MARS MIPS Simulator along with two MARS tools: the Keyboard and Display MMIO Simulator and the Bitmap Display. Open Final_Project.asm in MARS and assemble it with F3. Then, navigate to Tools > Keyboard and Display MMIO Simulator, click Connect to MIPS, and run the program with F5. After that, open Tools > Bitmap Display and configure it as follows:

Unit Width in Pixels: 16

Unit Height in Pixels: 16

Display Width in Pixels: 256

Display Height in Pixels: 512

Base Address for Display: 0x10008000 ($gp)

Once both tools are connected, the game initializes. You can control the falling tetromino using the keyboard: press a to move left, d to move right, and s for a soft drop. When the stack reaches the top, the game displays a “GAME OVER” message and prompts the player to either press p to restart or q to quit.
