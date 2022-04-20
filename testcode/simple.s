
	.file	"simple.c"
	.option nopic
	.text
	.globl	_start
	.hidden	_start
	.type	_start, @function
_start:
    lui	x2,0x84000
    addi	x2,x2,-704
    li x1, 0x11
    li x5, 0x22
    li x6, 0x33


    sw x1, 0(x2)

    nop
    nop

    lw x5, 0(x2)

    sw x6, 700(x2)


    sw x5, 500(x2) 


    lw x9, 700(x2)


    lw x10, 0(x2)


    mul x8, x1, x5

    nop
    nop
    nop
    nop
    nop


    lui     x2,0x84000
    add    x2,x2,-16
    sw      x1,12(x2)
    sw      x5,8(x2)
    sw      x6,4(x2)



    add x1, x0, 1
    add x2, x0, 1

L1:
    beq x1, x0, L2
    add x2, x0, 1
    beq x0, x0, L1

L2:
    bne x0, x0, L3
    bne x0, x0, L3
    add x3, x0, 1



L3:
    add x4, x0, 1
    add x4, x0, 1
    add x4, x0, 1
    add x4, x0, 1
    add x4, x0, 1
    add x4, x0, 1
    jal L5



L4:

    add x5, x0, 1

    beq x5, x1, L3


L5:
    jal L5




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
