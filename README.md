# Assembly Matrix Multiplier
A matrix multiplication routine written in Intel x86 for the Netwide Assembler (NASM). 

## Usage
1. Edit `matrixA` and `matrixB` within `matmult.asm` to represent your chosen input matrices, an example of the input format is as follows:
```assembly
matrixA DQ 2        ; Number of rows
        DQ 3        ; Number of columns
        DQ 1, 2, 3  ; Row 1
        DQ 4, 5, 6  ; Row 2
```
2. Run `./compile.sh` from within the directory to compile *and* execute the program.
