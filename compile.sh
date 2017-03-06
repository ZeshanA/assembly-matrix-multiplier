nasm -f elf64 -g -F stabs matmult.asm;
ld -o matmult matmult.o;
gdb matmult;
