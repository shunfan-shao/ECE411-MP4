
	.file	"simple.c"
	.option nopic
	.text
	.globl	_start
	.hidden	_start
	.type	_start, @function
_start:
    lui x1, 0x1
    nop
    nop
    nop
    nop
    nop
    lui x2, 0x2
    nop
    nop
    nop
    nop
    nop
    add x3, x1, x2
    nop
    nop
    nop
    nop
    nop
    lui x4, 0x3
    nop
    nop
    nop
    nop
    nop
    lui x5, 0x4
    nop
    nop
    nop
    nop
    nop
    add x6, x4, x5
    nop
    nop
    nop
    nop
    nop
    lw x1, ONE
    nop
    nop
    nop
    nop
    nop



loop:
    beq x1, x1, loop
    nop
    nop
    nop
    nop
    nop


.section .rodata
.balign 256
ONE:    .word 0x00000001
TWO:    .word 0x00000002
NEGTWO: .word 0xFFFFFFFE
TEMP1:  .word 0x00000001
GOOD:   .word 0x600D600D
BADD:   .word 0xBADDBADD
BYTES:  .word 0x04030201
HALF:   .word 0x0020FFFF
