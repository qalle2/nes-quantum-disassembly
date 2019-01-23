    ; second half of PRG ROM, minus the interrupt vectors

init:  ; c000
    sei
    cld
    jsr sub14
    ldx #$00
    txa

ram_clear_loop:
    sta $00,x
    sta $0100,x
    sta $0200,x
    sta $0300,x
    sta $0400,x
    sta $0500,x
    sta $0600,x
    sta $0700,x
    inx
    bne ram_clear_loop

    jsr sub15
    jsr sub16
    jsr sub18
    lda #$3f
    sta reg4
    lda #$1c
    sta reg4
    lda #$0f
    sta reg5
    lda #$1c
    sta reg5
    lda #$2b
    sta reg5
    lda #$39
    sta reg5
    lda #$00
    sta reg4
    sta reg4
    lda #$00
    sta $01
    lda #$00
    sta reg0
    lda #$1e
    sta reg1
    ldx #$ff
    jsr sub59
    jsr sub28
    lda #$00
    sta reg0
    sta reg1
    ldy #$00
    jsr sub56
    lda #$ff
    sta reg6
    lda #$00
    sta reg4
    sta reg4
    lda #$00
    ldx #$01
    jsr sub13
    jsr sub14
    lda #$80
    sta reg0
    lda #$1e
    sta reg1

*   lda $01
    cmp #$09
    bne +
        lda #$0d
        sta reg15
        lda #$fa
        sta reg16
*   jmp --

; -----------------------------------------------------------------------------

    .include "data2.asm"

; -----------------------------------------------------------------------------

sub14:  ; dc96
    bit reg2
    bpl sub14
    rts

; -----------------------------------------------------------------------------

sub15:

    ldx #0
sub15_loop1:
    lda #$f5
    sta $0500,x
    `inx4
    bne sub15_loop1
    rts

    lda #$00
    sta reg0
    sta reg1
    lda #$00
    sta reg0
    lda #$00
    ldx #0

sub15_loop2:
    sta reg6,x
    inx
    cpx #15
    bne sub15_loop2

    lda #$c0
    sta reg19
    jsr sub16
    jsr sub18
    rts

; -----------------------------------------------------------------------------

sub16:

    ldx #0

sub16_loop:
    lda table12,x
    sta $07c0,x
    inx
    cpx #32
    bne sub16_loop

    rts

; -----------------------------------------------------------------------------

sub17:
    ldx #0

sub17_loop:
    lda #$0f
    sta $07c0,x
    inx
    cpx #32
    bne sub17_loop

    rts

; -----------------------------------------------------------------------------

sub18:

    lda #$3f
    sta reg4
    lda #$00
    sta reg4
    ldx #0

sub18_loop:
    lda $07c0,x
    sta reg5
    inx
    cpx #$20
    bne sub18_loop

    lda #$00
    sta reg4
    sta reg4
    rts

; -----------------------------------------------------------------------------

sub19:

    stx $88
    lda #0
    sta $87
sub19_loop1:
    lda $86
    `add_imm $55
    bcc +  ; why?
*   sta $86
    inc $87
    lda $87
    cmp $88
    bne sub19_loop1
    rts

    stx $88
    ldx #0
sub19_loop2:
    `add_imm $55
    clc
    nop
    nop
    adc #15
    sbc #15
    inx
    cpx $88
    bne sub19_loop2
    rts

    stx $88
    ldy #0
    ldx #0
sub19_loop3:
    ldy #0
sub19_loop4:
    nop
    nop
    nop
    nop
    nop
    iny
    cpy #11
    bne sub19_loop4
    nop
    inx
    cpx $88
    bne sub19_loop3
    rts

; -----------------------------------------------------------------------------

sub20:
    ldy #0

sub20_loop:
    lda $07c0,y
    sta $01
    and #%00110000
    `lsr4
    tax
    lda $01
    and #%00001111
    ora table18,x
    sta $07c0,y
    iny
    cpy #$20
    bne sub20_loop

    rts

; -----------------------------------------------------------------------------

sub21:

    lda #$3f
    sta reg4
    lda #$00
    sta reg4
    lda $e8
    cmp #8
    bcc +
    lda $e8
    sta reg5
    jmp ++
*   lda #$3f
    sta reg5
*   rts

; -----------------------------------------------------------------------------

sub22:  ; dd8b

    stx $a5
    sty $a6
    lda $9a
    sta $a7
    lda #$00
    sta $9a
    sta $9b
    sta $9c

sub22_loop1:
    ldx #$00
    lda #$00
    sta $9a

sub22_loop2:
    lda $9c
    `add_mem $a7
    ldy $a8
    sta $0501,y
    txa
    adc $a5
    ldy $a8
    sta $0503,y
    lda $9b
    `add_mem $a6
    ldy $a8
    sta $0500,y
    lda #$03
    ldy $a8
    sta $0502,y
    lda $9a
    `add_imm 4
    sta $9a
    inc $9c
    `iny4
    sty $a8
    txa
    `add_imm 8
    tax
    cpx #64
    bne sub22_loop2

    lda $9b
    `add_imm 8
    sta $9b
    lda $9b
    cmp #16
    bne sub22_loop1

    sty $a8
    rts

; -----------------------------------------------------------------------------

sub23:

    stx $a5
    sty $a6
    lda $9a
    sta $a7
    lda #$00
    sta $9a
    sta $9b
    sta $9c

sub23_loop1:
    ldx #$00
    lda #$00
    sta $9a

sub23_loop2:
    lda $9c
    `add_mem $a7
    ldy $a8
    sta $0501,y
    txa
    adc $a5
    ldy $a8
    sta $0503,y
    lda $9b
    `add_mem $a6
    ldy $a8
    sta $0500,y
    lda #$02
    ldy $a8
    sta $0502,y
    lda $9a
    `add_imm 4
    sta $9a
    inc $9c
    `iny4
    sty $a8
    txa
    `add_imm 8
    tax
    cpx #24
    bne sub23_loop2

    lda $9b
    `add_imm 8
    sta $9b
    lda $9b
    cmp #16
    bne sub23_loop1

    sty $a8
    rts

; -----------------------------------------------------------------------------

sub24:

    stx $a5
    sty $a6
    lda $9a
    sta $a7
    lda #$00
    sta $9a
    sta $9b
    sta $9c

sub24_loop1:
    ldx #$00
    lda #$00
    sta $9a

sub24_loop2:
    lda $9c
    `add_mem $a7
    ldy $a8
    sta $0501,y
    txa
    adc $a5
    ldy $a8
    sta $0503,y
    lda $9b
    `add_mem $a6
    ldy $a8
    sta $0500,y
    lda #$02
    ldy $a8
    sta $0502,y
    lda $9a
    `add_imm 4
    sta $9a
    inc $9c
    `iny4
    sty $a8
    txa
    `add_imm 8
    tax
    cpx #32
    bne sub24_loop2

    lda $9b
    `add_imm 8
    sta $9b
    lda $9b
    cmp #16
    bne sub24_loop1

    sty $a8
    rts

; -----------------------------------------------------------------------------

sub25:

    ldx #$00
    ldy #0
    stx $9a
    stx $9b

sub25_loop:
    lda table10,y
    cmp #$ff
    bne +

    lda $9b
    `add_imm 14
    sta $9b
    jmp sub25_1

*   lda #$e1
    `add_mem $9b
    sta $0500,x
    sta $0154,y
    lda $9b
    sta $016a,y
    lda #$01
    sta $0180,y
    lda table10,y
    sta $0501,x
    lda #$00
    sta $0502,x
    lda $9a
    `add_imm 40
    sta $0503,x

sub25_1:
    `inx4
    iny
    lda $9a
    `add_imm 8
    sta $9a
    cpy #22
    bne sub25_loop

    rts

; -----------------------------------------------------------------------------

sub26:

    stx $91
    sty $92
    lda $91
    sta reg4
    lda $92
    sta reg4
    ldx #$00
    ldy #$00
    stx $90

sub26_loop1:
    ldy $90
    lda (ptr1),y
    clc
    sbc #$40
    tay
    ldx table17,y
    stx reg5
    inx
    stx reg5
    inc $90
    lda $90
    cmp #$10
    bne sub26_loop1

    lda #$00
    sta $90

sub26_loop2:
    ldy $90
    lda (ptr1),y
    clc
    sbc #$40
    tay
    ldx table17,y
    txa
    `add_imm 16
    tax
    stx reg5
    inx
    stx reg5
    inc $90
    lda $90
    cmp #$10
    bne sub26_loop2

    lda #$00
    sta reg4
    sta reg4
    rts

; -----------------------------------------------------------------------------

sub27:

    lda #$00
    sta $9a

    ldx data8
sub27_loop:
    txa
    asl
    asl
    tay
    lda $05b4,y
    clc
    sbc table46,x
    sta $05b4,y
    dex
    cpx #$ff
    bne sub27_loop

    rts

; -----------------------------------------------------------------------------

sub28:

    ldx data8
sub28_loop:
    txa
    asl
    asl
    tay
    lda table45,x
    sta $05b4,y
    lda $dc41,x
    sta $05b5,y
    lda #$03
    sta $05b6,y
    lda table44,x
    sta $05b7,y
    lda table46,x
    sta $011e,x
    dex
    cpx #$ff
    bne sub28_loop

    rts

; -----------------------------------------------------------------------------

sub29:

    `chr_bankswitch 0
    lda $95

    cmp #1
    beq sub29_jump_table+1*3
    cmp #2
    beq sub29_jump_table+2*3
    cmp #3
    beq sub29_jump_table+3*3
    cmp #4
    beq sub29_jump_table+4*3
    cmp #5
    beq sub29_jump_table+5*3
    cmp #6
    beq sub29_jump_table+6*3
    cmp #7
    beq sub29_jump_table+7*3
    cmp #8
    beq sub29_jump_table+8*3
    cmp #9
    beq sub29_1
    cmp #10
    beq sub29_jump_table+10*3
    jmp sub29_11

sub29_1:
    lda #$00
    sta reg3
    ldx $96
    lda table19,x
    `add_mem $96
    sta reg3
    lda $96
    cmp #$dc
    bne +
    jmp ++
*   inc $96
    inc $96
*   lda #$80
    sta reg0
    lda #$1e
    sta reg1

sub29_jump_table:  ; dff8
    jmp sub29_11
    jmp sub29_2
    jmp sub29_3
    jmp sub29_4
    jmp sub29_5
    jmp sub29_6
    jmp sub29_7
    jmp sub29_8
    jmp sub29_9
    jmp sub29_11
    jmp sub29_10

sub29_2:
    ; pointer 0 -> ptr1
    lda pointers+0*2+0
    sta ptr1+0
    lda pointers+0*2+1
    sta ptr1+1

    ldx #$20
    ldy #$00
    jsr sub26
    lda #$00
    sta reg3
    lda $96
    sta reg3
    dec $96
    lda $96
    cmp #$f0
    bcs +
    jmp sub29_11
*   lda #$00
    sta $96
    jmp sub29_11

sub29_3:
    lda #$00
    sta $96
    jmp sub29_11

sub29_4:
    ; pointer 1 -> ptr1
    lda pointers+1*2+0
    sta ptr1+0
    lda pointers+1*2+1
    sta ptr1+1

    ldx #$20
    ldy #$a0
    jsr sub26
    jmp sub29_11

sub29_5:
    ; pointer 2 -> ptr1
    lda pointers+2*2+0
    sta ptr1+0
    lda pointers+2*2+1
    sta ptr1+1

    ldx #$21
    ldy #$20
    jsr sub26
    jmp sub29_11

sub29_6:
    ; pointer 3 -> ptr1
    lda pointers+3*2+0
    sta ptr1+0
    lda pointers+3*2+1
    sta ptr1+1

    ldx #$21
    ldy #$a0
    jsr sub26
    jmp sub29_11

sub29_7:
    ; pointer 4 -> ptr1
    lda pointers+4*2+0
    sta ptr1+0
    lda pointers+4*2+1
    sta ptr1+1

    ldx #$22
    ldy #$40
    jsr sub26
    jmp sub29_11

sub29_8:
    ; pointer 5 -> ptr1
    lda pointers+5*2+0
    sta ptr1+0
    lda pointers+5*2+1
    sta ptr1+1

    ldx #$22
    ldy #$c0
    jsr sub26
    jmp sub29_11

sub29_9:
    ; pointer 6 -> ptr1
    lda pointers+6*2+0
    sta ptr1+0
    lda pointers+6*2+1
    sta ptr1+1

    ldx #$23
    ldy #$40
    jsr sub26
    jmp sub29_11

sub29_10:
    lda #$02
    sta $01
    lda #$00
    sta $02
    jmp sub29_11  ; why?

sub29_11:
    jmp sub29_13
    lda #$00
    sta $9a
    lda $96
    cmp #$a0
    bcc +
    jmp sub29_12
*   ldx $93
    lda table19,x
    `add_imm $58
    sta $0500
    lda table20,x
    `add_imm $6e
    sta $0503
    lda table19,x
    `add_imm $58
    sta $0504
    lda table20,x
    `add_imm $76
    sta $0507
    lda table19,x
    `add_imm $60
    sta $0508
    lda table20,x
    `add_imm $6e
    sta $050b
    lda table19,x
    `add_imm $60
    sta $050c
    lda table20,x
    `add_imm $76
    sta $050f
    lda table20,x
    `add_imm $58
    sta $0510
    lda table19,x
    `add_imm $6e
    sta $0513
    lda table20,x
    `add_imm $58
    sta $0514
    lda table19,x
    `add_imm $76
    sta $0517
    lda table20,x
    `add_imm $60
    sta $0518
    lda table19,x
    `add_imm $6e
    sta $051b
    lda table20,x
    `add_imm $60
    sta $051c
    lda table19,x
    `add_imm $75
    sta $051f
    jmp sub29_13

sub29_12:
    dec $0500
    dec $0503
    dec $0504
    inc $0507
    inc $0508
    dec $050b
    inc $050c
    inc $050f
    dec $0510
    dec $0513
    dec $0514
    inc $0517
    inc $0518
    dec $051b
    inc $051c
    inc $051f

sub29_13:
    jsr sub27
    lda #$05
    sta reg17
    rts

; -----------------------------------------------------------------------------

sub30:
    ldx #$00
    jsr sub58
    ldy #$00
    ldy #$00
    lda #$28
    sta reg4
    lda #$20
    sta reg4

    ldx #0
sub30_loop:
    stx reg5
    inx
    bne sub30_loop

    lda #$00
    sta reg4
    sta reg4
    lda #$3f
    sta reg4
    lda #$10
    sta reg4
    lda #$00
    sta reg5
    lda #$30
    sta reg5
    lda #$00
    sta reg4
    sta reg4
    lda #$3f
    sta reg4
    lda #$15
    sta reg4
    lda #$3d
    sta reg5
    lda #$0c
    sta reg5
    lda #$3c
    sta reg5
    lda #$0f
    sta reg5
    lda #$3c
    sta reg5
    lda #$0c
    sta reg5
    lda #$1a
    sta reg5
    lda #$00
    sta reg4
    sta reg4
    lda #$3f
    sta reg4
    lda #$00
    sta reg4
    lda #$38
    sta reg5
    lda #$01
    sta reg5
    lda #$26
    sta reg5
    lda #$0f
    sta reg5
    lda #$00
    sta reg4
    sta reg4
    lda #$01
    sta $02
    lda #$8e
    sta $012e
    lda #$19
    sta $012f
    lda #$1e
    sta reg1
    rts

; -----------------------------------------------------------------------------

sub31:  ; e25c
    ; jmp/bra targets:
    ; e29e
    ; e2ad
    ; e2bc
    ; e2e8
    ; e327
    ; e337
    ; e36d
    ; e376
    ; e394

    `chr_bankswitch 0
    lda #$05
    sta reg17
    lda #$90
    sta reg0
    lda #$3f
    sta reg4
    lda #$03
    sta reg4
    lda #$0f
    sta reg5
    lda #$00
    sta reg4
    sta reg4
    lda #$00
    sta reg3
    ldx $014e
    lda table19,x
    `add_mem $014e
    sta reg3
    lda $014e
    cmp #$c1
    beq $e29e

    inc $014e
    lda $ac
    cmp #$02
    bne $e2ad

    lda $ab
    cmp #$32
    bne $e2ad

    jsr sub25
    lda $ac
    cmp #$01
    bne $e327

    lda $ab
    cmp #$96
    bne $e327

    ldx data1
    txa
    asl
    asl
    tay
    lda table24,x
    `add_mem $012f
    sta $055c,y
    lda table25,x
    sta $055d,y
    lda table26,x
    sta $055e,y
    lda table27,x
    `add_mem $012e
    sta $055f,y
    cpx #$00
    beq $e2e8

    dex
    jmp $e2bc

    lda #$81
    sta $0560
    lda #$e5
    sta $0561
    lda #$01
    sta $0562
    lda #$d6
    sta $0563
    lda #$61
    sta $0564
    lda #$f0
    sta $0565
    lda #$02
    sta $0566
    lda #$e6
    sta $0567
    lda #$3f
    sta reg4
    lda #$03
    sta reg4
    lda #$30
    sta reg5
    lda #$00
    sta reg4
    sta reg4
    lda $ac
    cmp #$02
    bne $e376

    lda $ab
    cmp #$32
    bcc $e376

    ldx #$00
    ldy #$00
    lda $0180,x
    cmp #$01
    bne $e36d

    lda #$a0
    clc
    adc $016a,x
    sta $9a
    lda $0154,x
    sta $0500,y
    cmp $9a
    bcc $e36d

    txa
    pha
    inc $0196,x
    lda $0196,x
    sta $9c
    tax
    lda table19,x
    sta $9b
    pla
    tax
    lda $0154,x
    clc
    sbc $9b
    sbc $9c
    sta $0154,x
    inx
    `iny4
    cpx #$16
    bne $e337

    lda $ac
    cmp #$02
    bne $e394

    lda $ab
    cmp #$c8
    bcc $e394

    inc $a3
    lda $a3
    cmp #$04
    bne $e394

    jsr sub20
    jsr sub18
    lda #$00
    sta $a3
    jsr sub27
    lda #$02
    sta $01
    rts

; -----------------------------------------------------------------------------

sub32:  ; e39c
    ; jmp/bra targets:
    ; e3a0

    lda #$00
    ldx #$00
    sta reg6,x
    inx
    cpx #$0f
    bne $e3a0

    lda #$0a
    sta reg15
    lda #$fa
    sta reg16
    lda #$4c
    sta reg13
    lda #$1f
    sta reg18
    lda #$ff
    sta reg14
    ldx #$00
    jsr sub59
    lda #$01
    sta $02
    rts

; -----------------------------------------------------------------------------

sub33:  ; e3cb
    ; jmp/bra targets:
    ; e3eb
    ; e3ed
    ; e405
    ; e40b

    inc $89
    ldx $8a
    lda table22,x
    `add_imm $96
    sta $8b
    dec $8a
    ldx $8a
    lda table20,x
    sta $8d
    lda #$84
    sta reg0
    lda #$00
    sta $89
    ldy #$9f
    ldx #$19
    dex
    bne $e3ed

    ldx #$3f
    stx reg4
    ldx #$00
    stx reg4
    inc $8c
    lda $8c
    cmp #$05
    beq $e405

    jmp $e40b

    inc $89
    lda #$00
    sta $8c
    inc $89
    lda $89
    sbc $8a
    adc $8b
    tax
    lda table22,x
    sbc $8d
    and #%00111111
    tax
    lda table23,x
    sta reg5
    ldx $8b
    lda table19,x
    tax
    dey
    bne $e3eb

    lda #$06
    sta reg1
    lda #$90
    sta reg0
    rts

; -----------------------------------------------------------------------------

sub34:  ; e436
    ldx #$00
    jsr sub58
    lda #$00
    sta reg0
    sta reg1
    ldy #$14
    jsr sub56
    jsr sub12
    jsr sub16
    jsr sub18
    lda #$3f
    sta reg4
    lda #$0c
    sta reg4
    lda #$0f
    sta reg5
    lda #$00
    sta reg4
    sta reg4
    lda #$01
    sta $02
    lda #$05
    sta $00
    rts

; -----------------------------------------------------------------------------

sub35:  ; e471
    ; jmp/bra targets:
    ; e480
    ; e488
    ; e4a7
    ; e4b3
    ; e4e7
    ; e4ef
    ; e50c
    ; e518
    ; e549
    ; e555

    `chr_bankswitch 1
    lda $0148
    cmp #$00
    beq $e480

    jmp $e4e7

    dec $8a
    ldx #$00
    lda #$00
    sta $89
    lda $89
    adc $8a
    tay
    lda table19,y
    sta $0600,x
    lda $89
    `add_mem $00
    sta $89
    inx
    cpx #$40
    bne $e488

    ldx #$00
    ldy #$00
    lda #$00
    sta $9a
    lda #$21
    sta reg4
    lda $9a
    sta reg4
    ldy #$00
    lda $0600,x
    sta reg5
    lda $0600,x
    sta reg5
    inx
    lda $0600,x
    sta reg5
    lda $0600,x
    sta reg5
    inx
    iny
    cpy #$08
    bne $e4b3

    lda $9a
    `add_imm 32
    sta $9a
    lda $9a
    cmp #$00
    bne $e4a7

    lda #$01
    sta $0148
    jmp $e549

    dec $8a
    ldx #$40
    lda #$00
    sta $89
    lda $89
    adc $8a
    tay
    lda table19,y
    sta $0600,x
    lda $89
    `add_mem $00
    sta $89
    inx
    cpx #$80
    bne $e4ef

    ldx #$7f
    lda #$00
    sta $9a
    lda #$22
    sta reg4
    lda $9a
    sta reg4
    ldy #$00
    lda $0600,x
    sta reg5
    lda $0600,x
    sta reg5
    dex
    lda $0600,x
    sta reg5
    lda $0600,x
    sta reg5
    dex
    iny
    cpy #$08
    bne $e518

    lda $9a
    `add_imm 32
    sta $9a
    lda $9a
    cmp #$00
    bne $e50c

    lda #$00
    sta $0148
    lda #$00
    sta reg4
    sta reg4
    lda #$00
    sta $89
    ldx #$04
    jsr sub19
    lda $89
    `add_mem $8b
    tax
    lda table19,x
    sta reg3
    lda #$00
    sta reg3
    inc $89
    iny
    cpy #$98
    bne $e555

    ldx $8b
    lda table22,x
    sbc $8b
    sbc $8b
    lda #$00
    sta reg3
    ldx $8b
    lda table20,x
    clc
    sbc #10
    lda #$e6
    sta reg3
    dec $8b
    lda #$0e
    sta reg1
    lda #$80
    sta reg0
    rts

; -----------------------------------------------------------------------------

sub36:  ; e59a
    ldx #$00
    jsr sub58
    jsr sub16
    jsr sub18
    lda #$00
    sta reg0
    sta reg1
    ldy #$ff
    jsr sub56
    ldy #$55
    jsr sub57
    lda #$3f
    sta reg4
    lda #$0c
    sta reg4
    lda #$0f
    sta reg5
    lda #$00
    sta reg4
    sta reg4
    lda #$01
    sta $02
    rts

; -----------------------------------------------------------------------------

sub37:  ; e5d3
    ; jmp/bra targets:
    ; e5e5
    ; e603
    ; e60b
    ; e617
    ; e64a
    ; e650
    ; e65c
    ; e68c

    jsr sub21
    `chr_bankswitch 1
    dec $8a
    dec $8a
    ldx #$00
    lda #$00
    sta $89
    lda $89
    adc $8a
    tay
    lda table19,y
    adc #$46
    sta $0600,x
    inc $89
    inx
    cpx #$80
    bne $e5e5

    lda $0148
    cmp #$00
    beq $e603

    jmp $e64a

    ldx #$00
    ldy #$00
    lda #$00
    sta $9a
    lda #$21
    sta reg4
    lda $9a
    sta reg4
    ldy #$00
    lda $0600,x
    sta reg5
    lda $0600,x
    sta reg5
    lda $0600,x
    sta reg5
    lda $0600,x
    sta reg5
    inx
    iny
    cpy #$08
    bne $e617

    lda $9a
    `add_imm 32
    sta $9a
    lda $9a
    cmp #$00
    bne $e60b

    lda #$01
    sta $0148
    jmp $e68c

    ldx #$7f
    lda #$20
    sta $9a
    lda #$22
    sta reg4
    lda $9a
    sta reg4
    ldy #$00
    lda $0600,x
    sta reg5
    lda $0600,x
    sta reg5
    lda $0600,x
    sta reg5
    lda $0600,x
    sta reg5
    dex
    iny
    cpy #$08
    bne $e65c

    lda $9a
    `add_imm 32
    sta $9a
    lda $9a
    cmp #$00
    bne $e650

    lda #$00
    sta $0148
    lda #$00
    sta reg4
    sta reg4
    ldx $8b
    lda table22,x
    sbc $8b
    sbc $8b
    sbc $8b
    sbc $8b
    sbc $8b
    sbc $8b
    sta reg3
    ldx $8b
    lda table20,x
    clc
    sbc #10
    sta reg3
    dec $8b
    lda #$0e
    sta reg1
    lda #$80
    sta reg0
    rts

; -----------------------------------------------------------------------------

sub38:  ; e6c0
    ldx #$ff
    jsr sub59
    jsr sub12
    jsr sub16
    jsr sub18
    lda #$01
    sta $02
    jsr sub15
    lda #$00
    sta $89
    sta $8a
    sta $8b
    sta $8c
    lda #$00
    sta reg1
    lda #$80
    sta reg0
    rts

; -----------------------------------------------------------------------------

sub39:  ; e6ea
    ; jmp/bra targets:
    ; e6fa
    ; e73d
    ; e73f

    dec $8c
    inc $8b
    lda $8b
    cmp #$02
    bne $e6fa

    lda #$00
    sta $8b
    dec $8a
    lda #$84
    sta reg0
    ldx #$3f
    stx reg4
    ldx #$00
    stx reg4
    lda #$0f
    sta reg5
    lda #$00
    sta reg4
    sta reg4
    ldx #$ff
    jsr sub19
    ldx #$01
    jsr sub19
    ldx #$3f
    stx reg4
    ldx #$00
    stx reg4
    lda #$0f
    sta reg5
    lda #$00
    sta reg4
    sta reg4
    lda #$00
    sta $89
    ldy #$55
    ldx #$19
    dex
    bne $e73f

    ldx #$3f
    stx reg4
    ldx #$00
    stx reg4
    ldx $8a
    lda table22,x
    sta $9a
    dec $89
    lda $89
    `add_mem $8a
    tax
    lda table20,x
    clc
    sbc $9a
    adc $8c
    tax
    lda table23,x
    sta reg5
    dey
    bne $e73d

    lda #$00
    sta reg4
    sta reg4
    ldx #$3f
    stx reg4
    ldx #$00
    stx reg4
    lda #$0f
    sta reg5
    lda #$00
    sta reg4
    sta reg4
    rts

; -----------------------------------------------------------------------------

sub40:  ; e78d
    ; jmp/bra targets:
    ; e7c8
    ; e7d0
    ; e7d2
    ; e7d4
    ; e800
    ; e802
    ; e804
    ; e824
    ; e826
    ; e846
    ; e853
    ; e85f
    ; e87d

    ldx #$ff
    jsr sub58
    jsr sub16
    jsr sub18
    lda #$3f
    sta reg4
    lda #$1c
    sta reg4
    lda #$0f
    sta reg5
    lda #$19
    sta reg5
    lda #$33
    sta reg5
    lda #$30
    sta reg5
    lda #$00
    sta reg4
    sta reg4
    lda #$20
    sta reg4
    lda #$00
    sta reg4
    lda #$00
    sta $9e
    lda #$00
    sta $9f
    ldy #$00
    ldx #$00
    txa
    `add_mem $9e
    sta reg5
    inx
    cpx #$08
    bne $e7d4

    iny
    cpy #$04
    bne $e7d2

    lda $9e
    `add_imm 8
    sta $9e
    lda $9e
    cmp #$40
    bne $e7d0

    lda #$00
    sta $9e
    inc $9f
    lda $9f
    cmp #$03
    bne $e7d0

    ldx #$00
    ldy #$00
    ldx #$00
    txa
    `add_mem $9e
    sta reg5
    inx
    cpx #$08
    bne $e804

    iny
    cpy #$04
    bne $e802

    lda $9e
    `add_imm 8
    sta $9e
    cmp #$28
    bne $e800

    lda #$f0
    ldy #$00
    ldx #$f0
    stx reg5
    inx
    cpx #$f8
    bne $e826

    iny
    cpy #$08
    bne $e824

    lda #$00
    sta reg4
    sta reg4
    inc $a0
    lda $a0
    cmp #$02
    bne $e846

    jmp $e853

    lda #$28
    sta reg4
    lda #$00
    sta reg4
    jmp $e7c8

    lda #$23
    sta reg4
    lda #$c0
    sta reg4
    ldx #$00
    lda #$00
    sta reg5
    inx
    cpx #$40
    bne $e85f

    lda #$00
    sta reg4
    sta reg4
    lda #$2b
    sta reg4
    lda #$c0
    sta reg4
    ldx #$00
    lda #$00
    sta reg5
    inx
    cpx #$40
    bne $e87d

    lda #$00
    sta reg4
    sta reg4
    jsr sub15
    lda #$02
    sta $014d
    lda #$00
    sta $a3
    lda #$01
    sta $02
    lda #$00
    sta $89
    lda #$18
    sta reg0
    lda #$1e
    sta reg1
    rts

; -----------------------------------------------------------------------------

sub41:  ; e8ae
    ; jmp/bra targets:
    ; e8d1
    ; e8f4
    ; e908
    ; e91c
    ; e930
    ; e94a
    ; e950
    ; e979
    ; e97c
    ; e97f
    ; e982
    ; e985
    ; e988
    ; e98b
    ; e98e
    ; e991
    ; e99c
    ; e9ad
    ; e9c9
    ; e9e5
    ; ea06
    ; ea22
    ; ea3e
    ; ea5f
    ; ea7b
    ; ea7e

    lda #$05
    sta reg17
    lda $a2
    cmp #$08
    bne $e8d1

    lda $a1
    cmp #$8c
    bcc $e8d1

    inc $a3
    lda $a3
    cmp #$04
    bne $e8d1

    jsr sub20
    jsr sub18
    lda #$00
    sta $a3
    lda #$03
    sta $01
    lda #$3f
    sta reg4
    lda #$00
    sta reg4
    lda $a2
    cmp #$08
    beq $e930

    lda $014d
    cmp #$00
    beq $e91c

    cmp #$01
    beq $e908

    cmp #$02
    beq $e8f4

    lda #$34
    sta reg5
    lda #$24
    sta reg5
    lda #$14
    sta reg5
    lda #$04
    sta reg5
    lda #$38
    sta reg5
    lda #$28
    sta reg5
    lda #$18
    sta reg5
    lda #$08
    sta reg5
    lda #$32
    sta reg5
    lda #$22
    sta reg5
    lda #$12
    sta reg5
    lda #$02
    sta reg5
    inc $89
    lda $89
    sta reg3
    ldx $89
    lda table20,x
    sta reg3
    inc $a1
    lda $a1
    cmp #$b4
    beq $e94a

    jmp $e950

    inc $a2
    lda #$00
    sta $a1
    lda $a2
    cmp #$01
    beq $e979

    cmp #$02
    beq $e97c

    cmp #$03
    beq $e97f

    cmp #$04
    beq $e982

    cmp #$05
    beq $e985

    cmp #$06
    beq $e988

    cmp #$07
    beq $e98b

    cmp #$08
    beq $e98e

    cmp #$09
    beq $e991

    jmp $ea7b
    jmp $e99c
    jmp $e9ad
    jmp $e9c9
    jmp $e9e5
    jmp $ea06
    jmp $ea22
    jmp $ea3e
    jmp $ea5f

    lda #$0a
    sta $01
    lda #$00
    sta $02
    jmp $ea7e

    jsr sub15
    ldx #$5c
    ldy #$6a
    lda #$90
    sta $9a
    jsr sub22
    jmp $ea7e

    jsr sub15
    ldx #$75
    ldy #$73
    lda #$60
    sta $9a
    jsr sub22
    ldx #$54
    ldy #$61
    lda #$ac
    sta $9a
    jsr sub24
    jmp $ea7e

    jsr sub15
    ldx #$75
    ldy #$73
    lda #$80
    sta $9a
    jsr sub22
    ldx #$54
    ldy #$61
    lda #$ac
    sta $9a
    jsr sub24
    jmp $ea7e

    jsr sub15
    lda #$01
    sta $014d
    ldx #$75
    ldy #$73
    lda #$50
    sta $9a
    jsr sub22
    ldx #$54
    ldy #$61
    lda #$a0
    sta $9a
    jsr sub23
    jmp $ea7e

    jsr sub15
    ldx #$75
    ldy #$73
    lda #$40
    sta $9a
    jsr sub22
    ldx #$54
    ldy #$61
    lda #$a0
    sta $9a
    jsr sub23
    jmp $ea7e

    jsr sub15
    ldx #$75
    ldy #$73
    lda #$e0
    sta $9a
    jsr sub22
    ldx #$54
    ldy #$61
    lda #$a0
    sta $9a
    jsr sub23
    jmp $ea7e

    lda #$00
    sta $014d
    jsr sub15
    ldx #$75
    ldy #$73
    lda #$c0
    sta $9a
    jsr sub22
    ldx #$54
    ldy #$61
    lda #$a0
    sta $9a
    jsr sub23
    jmp $ea7e

    jsr sub15
    ldx #$75
    ldy #$73
    lda #$70
    sta $9a
    jsr sub22
    ldx #$54
    ldy #$61
    lda #$a6
    sta $9a
    jsr sub23
    jmp $ea7e

    jsr sub15
    `chr_bankswitch 1
    lda #$98
    sta reg0
    lda #$1e
    sta reg1
    rts

; -----------------------------------------------------------------------------

sub42:  ; ea8e
    ; jmp/bra targets:
    ; eab9
    ; eabb
    ; eac6
    ; ead9
    ; eadb
    ; eae6

    ldx #$7f
    jsr sub58
    ldy #$00
    jsr sub56
    jsr sub15
    lda #$00
    sta reg0
    sta reg1
    lda #$20
    sta $014a
    lda #$21
    sta $014b
    lda #$20
    sta reg4
    lda #$00
    sta reg4
    ldy #$00
    ldx #$00
    sty reg5
    iny
    inx
    cpx #$10
    bne $eabb

    ldx #$00
    lda #$7f
    sta reg5
    inx
    cpx #$10
    bne $eac6

    cpy #$00
    bne $eab9

    jsr sub12
    ldy #$00
    ldx #$00
    sty reg5
    iny
    inx
    cpx #$10
    bne $eadb

    ldx #$00
    lda #$7f
    sta reg5
    inx
    cpx #$10
    bne $eae6

    cpy #$e0
    bne $ead9

    lda #$00
    sta reg4
    sta reg4
    lda #$23
    sta reg4
    lda #$aa
    sta reg4
    lda #$e0
    sta reg5
    lda #$e1
    sta reg5
    lda #$e2
    sta reg5
    lda #$e3
    sta reg5
    lda #$e4
    sta reg5
    lda #$00
    sta reg4
    sta reg4
    lda #$3f
    sta reg4
    lda #$00
    sta reg4
    ldx #$00
    lda #$30
    sta reg5
    lda #$25
    sta reg5
    lda #$17
    sta reg5
    lda #$0f
    sta reg5
    lda #$3f
    sta reg4
    lda #$11
    sta reg4
    lda #$02
    sta reg5
    lda #$12
    sta reg5
    lda #$22
    sta reg5
    lda #$00
    sta reg4
    sta reg4
    lda #$00
    sta reg3
    sta reg3
    lda #$00
    sta $89
    sta $8a
    lda #$40
    sta $8b
    lda #$00
    sta $8c
    lda #$01
    sta $02
    lda #$00
    sta $a3
    lda #$80
    sta reg0
    rts

; -----------------------------------------------------------------------------

sub43:  ; eb8c
    ; jmp/bra targets:
    ; eba1
    ; ebe0
    ; ebe6
    ; ebef
    ; ebf3
    ; ec01
    ; ec3e
    ; ec42
    ; ec89
    ; ec98
    ; ecc2
    ; ece1
    ; ed00
    ; ed9e
    ; edb8
    ; edc7
    ; edcf
    ; eddb
    ; edf6
    ; ee84
    ; eebd
    ; eed2
    ; eef0

    lda #$05
    sta reg17
    inc $8a
    inc $8b
    ldx #$18
    ldy #$00
    lda #$00
    sta $9a
    sta $89
    lda $8b
    txa
    sta $0500,y
    lda #$f0
    `add_mem $8c
    sta $0501,y
    lda $014a
    sta $0502,y
    txa
    pha
    inc $89
    inc $89
    inc $89
    lda $89
    `add_mem $8a
    tax
    lda table21,x
    `add_imm $c2
    sta $0503,y
    pla
    tax
    `iny4
    txa
    `add_imm 8
    tax
    inc $8d
    lda $8d
    cmp #$0f
    beq $ebe0

    jmp $ebe6

    inc $8c
    lda #$00
    sta $8d
    lda $8c
    cmp #$10
    beq $ebef

    jmp $ebf3

    lda #$00
    sta $8c
    cpy #$60
    bne $eba1

    ldx #$18
    lda #$00
    sta $9a
    sta $89
    dec $8c
    txa
    sta $0500,y
    lda #$f0
    `add_mem $8c
    sta $0501,y
    lda $014b
    sta $0502,y
    txa
    pha
    dec $89
    dec $89
    lda $89
    `add_mem $8b
    tax
    lda table21,x
    `add_imm $c2
    sta $0503,y
    pla
    tax
    `iny4
    txa
    `add_imm 8
    tax
    inc $8c
    lda $8c
    cmp #$10
    beq $ec3e

    jmp $ec42

    lda #$00
    sta $8c
    cpy #$c0
    bne $ec01

    `chr_bankswitch 3
    lda #$88
    sta reg0
    ldx #$ff
    jsr sub19
    jsr sub19
    ldx #$30
    jsr sub19
    nop
    nop
    nop
    nop
    nop
    lda #$98
    sta reg0
    lda #$1e
    sta reg1
    lda $8b
    cmp #$fa
    bne $ec98

    inc $0149
    lda $0149
    cmp #$02
    beq $ec89

    lda #$00
    sta $014a
    lda #$01
    sta $014b
    jmp $ec98

    lda #$20
    sta $014a
    lda #$21
    sta $014b
    lda #$00
    sta $0149
    rts

    ; ec99
    ldx #$7a
    jsr sub58
    ldy #$00
    jsr sub56
    jsr sub16
    jsr sub18
    jsr sub15
    lda #$00
    sta reg0
    sta reg1
    lda #$21
    sta reg4
    lda #$0a
    sta reg4
    ldx #$50
    ldy #$00
    stx reg5
    inx
    iny
    cpy #$0c
    bne $ecc2

    lda #$00
    sta reg4
    sta reg4
    lda #$21
    sta reg4
    lda #$2a
    sta reg4
    ldy #$00
    ldx #$5c
    stx reg5
    inx
    iny
    cpy #$0c
    bne $ece1

    lda #$00
    sta reg4
    sta reg4
    lda #$21
    sta reg4
    lda #$4a
    sta reg4
    ldy #$00
    ldx #$68
    stx reg5
    inx
    iny
    cpy #$0c
    bne $ed00

    lda #$00
    sta reg4
    sta reg4
    lda #$01
    sta $02
    lda #$00
    sta $8f
    sta $89
    lda #$00
    sta $8a
    lda #$3f
    sta reg4
    lda #$1a
    sta reg4
    lda #$00
    sta reg5
    lda #$10
    sta reg5
    lda #$00
    sta reg4
    sta reg4
    lda #$80
    sta reg0
    lda #$1e
    sta reg1
    lda #$00
    sta $0130
    rts

    lda $0130
    cmp #$01
    beq $ed9e

    lda #$3f
    sta reg4
    lda #$10
    sta reg4
    lda #$0f
    sta reg5
    lda #$0f
    sta reg5
    lda #$0f
    sta reg5
    lda #$0f
    sta reg5
    lda #$00
    sta reg4
    sta reg4
    lda #$3f
    sta reg4
    lda #$00
    sta reg4
    lda #$0f
    sta reg5
    lda #$30
    sta reg5
    lda #$10
    sta reg5
    lda #$00
    sta reg5
    lda #$00
    sta reg4
    sta reg4
    lda #$01
    sta $0130
    lda #$1e
    sta reg1
    lda #$10
    sta reg0
    inc $8a
    lda $8a
    cmp #$08
    beq $edb8

    jmp $edf6

    lda #$00
    sta $8a
    inc $8f
    lda $8f
    cmp #$eb
    beq $edc7

    jmp $edcf

    lda #$00
    sta $02
    lda #$07
    sta $01
    lda #$23
    sta reg4
    lda #$61
    sta reg4
    ldx #$00
    txa
    `add_mem $8f
    tay
    lda table11,y
    clc
    sbc #$36
    sta reg5
    inx
    cpx #$1f
    bne $eddb

    lda #$00
    sta reg4
    sta reg4
    `chr_bankswitch 2
    inc $89
    ldx $89
    lda table20,x
    clc
    sbc #$1e
    sta reg3
    lda #$00
    sta reg3
    lda #$10
    sta reg0
    lda #$1e
    sta reg1
    lda #$05
    sta reg17
    ldx #$ff
    jsr sub19
    jsr sub19
    jsr sub19
    ldx #$1e
    jsr sub19
    ldx #$d0
    jsr sub19
    lda #$00
    sta reg0
    `chr_bankswitch 0
    lda $8a
    sta reg3
    lda #$00
    sta reg3
    lda #$d7
    sta $0500
    lda #$25
    sta $0501
    lda #$00
    sta $0502
    lda #$f8
    sta $0503
    lda #$cf
    sta $0504
    lda #$25
    sta $0505
    lda #$00
    sta $0506
    lda #$f8
    sta $0507
    lda #$df
    sta $0508
    lda #$27
    sta $0509
    lda #$00
    sta $050a
    lda #$f8
    sta $050b
    ldx data2
    txa
    asl
    asl
    tay
    lda table28,x
    `add_imm $9b
    sta $055c,y
    txa
    pha
    ldx $0137
    lda $dc92,x
    sta $9a
    pla
    tax
    lda table29,x
    `add_mem $9a
    sta $055d,y
    lda #$02
    sta $055e,y
    lda table30,x
    `add_mem $0139
    sta $055f,y
    cpx #$00
    beq $eebd

    dex
    jmp $ee84

    inc $013a
    lda $013a
    cmp #$06
    bne $eed2

    inc $0139
    inc $0139
    lda #$00
    sta $013a
    inc $0138
    lda $0138
    cmp #$0c
    bne $eef0

    lda #$00
    sta $0138
    inc $0137
    lda $0137
    cmp #$04
    bne $eef0

    lda #$00
    sta $0137
    lda #$88
    sta reg0
    lda #$18
    sta reg1
    rts

; -----------------------------------------------------------------------------

sub44:  ; eefb
    ; jmp/bra targets:
    ; ef09
    ; ef15
    ; ef39
    ; ef45
    ; efee
    ; f002
    ; f014
    ; f042
    ; f05a

    jsr sub15
    ldy #$aa
    jsr sub56
    lda #$1a
    sta $9a
    ldx #$60
    lda #$21
    sta reg4
    lda $9a
    sta reg4
    ldy #$00
    stx reg5
    inx
    iny
    cpy #$03
    bne $ef15

    lda #$00
    sta reg4
    sta reg4
    lda $9a
    `add_imm 32
    sta $9a
    lda $9a
    cmp #$1a
    bne $ef09

    lda #$08
    sta $9a
    ldx #$80
    lda #$22
    sta reg4
    lda $9a
    sta reg4
    ldy #$00
    stx reg5
    inx
    iny
    cpy #$03
    bne $ef45

    lda #$00
    sta reg4
    sta reg4
    lda $9a
    `add_imm 32
    sta $9a
    lda $9a
    cmp #$68
    bne $ef39

    lda #$3f
    sta reg4
    lda #$10
    sta reg4
    lda #$0f
    sta reg5
    lda #$01
    sta reg5
    lda #$1c
    sta reg5
    lda #$30
    sta reg5
    lda #$0f
    sta reg5
    lda #$00
    sta reg5
    lda #$10
    sta reg5
    lda #$20
    sta reg5
    lda #$0f
    sta reg5
    lda #$19
    sta reg5
    lda #$26
    sta reg5
    lda #$30
    sta reg5
    lda #$22
    sta reg5
    lda #$16
    sta reg5
    lda #$27
    sta reg5
    lda #$18
    sta reg5
    lda #$00
    sta reg4
    sta reg4
    lda #$3f
    sta reg4
    lda #$00
    sta reg4
    lda #$0f
    sta reg5
    lda #$20
    sta reg5
    lda #$10
    sta reg5
    lda #$00
    sta reg5
    lda #$00
    sta reg4
    sta reg4
    ldx data3
    lda table31,x
    sta $0104,x
    lda table32,x
    sta $0108,x
    dex
    cpx #$ff
    bne $efee

    ldx data5
    lda #$00
    sta $0112,x
    lda #$f0
    sta $0116,x
    dex
    cpx #$ff
    bne $f002

    ldx data7
    txa
    asl
    asl
    tay
    lda table41,x
    sta $05c0,y
    lda table43,x
    sta $05c1,y
    lda table40,x
    sta $05c3,y
    lda table42,x
    sta $011e,x
    dex
    cpx #$ff
    bne $f014

    lda #$7a
    sta $0111
    lda #$0a
    sta $0110
    ldx data4
    txa
    asl
    asl
    tay
    lda table35,x
    sta $0505,y
    lda table36,x
    sta $0506,y
    cpx #$00
    beq $f05a

    dex
    jmp $f042

    lda #$00
    sta $0100
    sta $0101
    sta $0102
    lda #$01
    sta $02
    lda #$80
    sta reg0
    lda #$12
    sta reg1
    rts

; -----------------------------------------------------------------------------

sub45:  ; f074
    ; jmp/bra targets:
    ; f097
    ; f0af
    ; f0b5
    ; f0bb
    ; f0db
    ; f0fb
    ; f116
    ; f13d
    ; f140
    ; f156
    ; f15b
    ; f163
    ; f186

    lda #$05
    sta reg17
    inc $0100
    ldx $0100
    lda table19,x
    adc #$7a
    sta $0111
    lda table20,x
    adc #15
    sta $0110
    `chr_bankswitch 2
    ldx data3
    dec $0104,x
    lda $0104,x
    cmp #$00
    bne $f0bb

    lda $0108,x
    cmp table33,x
    beq $f0af

    inc $0108,x
    jmp $f0b5

    lda table32,x
    sta $0108,x
    lda table31,x
    sta $0104,x
    dex
    cpx #$ff
    bne $f097

    lda $0108
    sta $0505
    lda $0109
    sta $0541
    lda $010a
    sta $0545
    lda $010b
    sta $0535
    ldx data4
    txa
    asl
    asl
    tay
    lda table34,x
    `add_mem $0111
    sta $0504,y
    lda table37,x
    `add_mem $0110
    sta $0507,y
    cpx #$00
    beq $f0fb

    dex
    jmp $f0db

    lda $0100
    ldx $0101
    cmp table38,x
    bne $f13d

    inc $0101
    lda $0101
    cpx data6
    bne $f116

    ; f111
    lda #$00
    sta $0101

    ; f116
    ldx $0102
    ldy $0100
    lda #$ff
    sta $0112,x
    lda table19,y
    `add_imm $5a
    sta $0116,x
    lda table22,y
    sta $011a,x
    inc $0102
    cpx data5
    bne $f13d

    lda #$00
    sta $0102
    ldx data5
    lda $0116,x
    cmp #$f0
    beq $f15b

    lda $0112,x
    clc
    sbc $011a,x
    bcc $f156

    sta $0112,x
    jmp $f15b

    lda #$f0
    sta $0116,x
    dex
    cpx #$ff
    bne $f140

    ldx data5
    txa
    asl
    asl
    tay
    lda $0116,x
    sta $0548,y
    lda table39,x
    sta $0549,y
    lda #$2b
    sta $054a,y
    lda $0112,x
    sta $054b,y
    dex
    cpx #$ff
    bne $f163

    ldx data7
    txa
    asl
    asl
    tay
    lda $05c3,y
    clc
    sbc table42,x
    sta $05c3,y
    dex
    cpx #$ff
    bne $f186

    lda #$80
    sta reg0
    lda #$1a
    sta reg1
    lda #$00
    sta reg3
    lda #$32
    sta reg3
    rts

; -----------------------------------------------------------------------------

sub46:  ; f1ae
    ; jmp/bra targets:
    ; f1ca

    ldx #$4a
    jsr sub58
    ldy #$00
    jsr sub56
    jsr sub16
    jsr sub18
    lda #$21
    sta reg4
    lda #$c0
    sta reg4
    ldx #$00
    lda table13,x
    clc
    sbc #$10
    sta reg5
    inx
    cpx #$60
    bne $f1ca

    lda #$02
    sta reg0
    lda #$00
    sta reg1
    rts

; -----------------------------------------------------------------------------

sub47:  ; f1e3
    lda #$00
    sta reg3
    lda #$00
    sta reg3
    lda #$90
    sta reg0
    lda #$0e
    sta reg1
    rts

; -----------------------------------------------------------------------------

sub48:  ; f1f8
    ; jmp/bra targets:
    ; f218
    ; f227
    ; f24f
    ; f25d
    ; f26b

    ldx #$4a
    jsr sub58
    ldy #$00
    jsr sub56
    jsr sub17
    jsr sub18
    lda #$02
    sta reg0
    lda #$00
    sta reg1
    lda #$00
    sta $9a
    ldx #$00
    lda #$20
    sta reg4
    lda $9a
    `add_imm $69
    sta reg4
    ldy #$00
    stx reg5
    inx
    iny
    cpy #$10
    bne $f227

    lda #$00
    sta reg4
    sta reg4
    lda $9a
    `add_imm 32
    sta $9a
    cmp #$60
    bne $f218

    lda #$21
    sta reg4
    lda #$00
    sta reg4
    ldx #$00
    lda table14,x
    clc
    sbc #$10
    sta reg5
    inx
    bne $f24f

    ldx #$00
    lda table15,x
    clc
    sbc #$10
    sta reg5
    inx
    bne $f25d

    ldx #$00
    lda table16,x
    clc
    sbc #$10
    sta reg5
    inx
    cpx #$80
    bne $f26b

    lda #$00
    sta reg4
    sta reg4
    lda #$01
    sta $02
    lda #$e6
    sta $0153
    rts

; -----------------------------------------------------------------------------

sub49:  ; f28b
    ; jmp/bra targets:
    ; f2ca
    ; f2e6
    ; f306

    `chr_bankswitch 2
    lda $0150
    cmp #$00
    bne $f2ca

    lda $014f
    cmp #$03
    bne $f2ca

    jsr sub16
    jsr sub18
    lda #$3f
    sta reg4
    lda #$00
    sta reg4
    lda #$0f
    sta reg5
    lda #$30
    sta reg5
    lda #$1a
    sta reg5
    lda #$09
    sta reg5
    lda #$00
    sta reg4
    sta reg4
    lda #$00
    sta reg3
    ldx $0153
    lda table19,x
    `add_mem $0153
    sta reg3
    lda $0153
    cmp #$00
    beq $f2e6

    dec $0153
    lda $0150
    cmp #$03
    bne $f306

    lda $014f
    cmp #$00
    bcc $f306

    inc $a3
    lda $a3
    cmp #$04
    bne $f306

    jsr sub20
    jsr sub18
    lda #$00
    sta $a3
    lda #$0c
    sta $01
    lda #$90
    sta reg0
    lda #$0e
    sta reg1
    rts

; -----------------------------------------------------------------------------

sub50:  ; f315
    ldx #$80
    jsr sub58
    jsr sub15
    ldy #$00
    jsr sub56
    lda #$00
    sta reg0
    sta reg1
    lda #$00
    sta $89
    sta $8a
    sta $8b
    lda #$3f
    sta reg4
    lda #$00
    sta reg4
    lda #$05
    sta reg5
    lda #$25
    sta reg5
    lda #$15
    sta reg5
    lda #$30
    sta reg5
    lda #$00
    sta reg4
    sta reg4
    lda #$c8
    sta $013d
    lda #$00
    sta reg3
    lda #$c8
    sta reg3
    lda #$00
    sta $014c
    lda #$01
    sta $02
    lda #$80
    sta reg0
    rts

; -----------------------------------------------------------------------------

sub51:  ; f376
    ; jmp/bra targets:
    ; f380
    ; f382
    ; f392
    ; f3a8
    ; f3b8
    ; f3db
    ; f3eb
    ; f401
    ; f411
    ; f42f
    ; f439
    ; f448
    ; f467
    ; f46c
    ; f47b
    ; f497
    ; f49f
    ; f4aa
    ; f4ad
    ; f4b2
    ; f4e3

    lda $013c
    cmp #$02
    beq $f380

    jmp $f42f

    ldy #$80
    lda #$21
    sta reg4
    lda #$04
    `add_mem $013b
    sta reg4
    ldx #$00
    sty reg5
    iny
    inx
    cpx #$08
    bne $f392

    lda $013b
    `add_imm 32
    sta $013b
    cpy #$c0
    bne $f382

    lda #$22
    sta reg4
    lda #$04
    `add_mem $013b
    sta reg4
    ldx #$00
    sty reg5
    iny
    inx
    cpx #$08
    bne $f3b8

    lda $013b
    `add_imm 32
    sta $013b
    cpy #$00
    bne $f3a8

    lda #$00
    sta reg4
    sta reg4
    lda #$00
    sta $013b
    lda #$21
    sta reg4
    lda #$14
    `add_mem $013b
    sta reg4
    ldx #$00
    sty reg5
    iny
    inx
    cpx #$08
    bne $f3eb

    lda $013b
    `add_imm 32
    sta $013b
    cpy #$c0
    bne $f3db

    lda #$22
    sta reg4
    lda #$14
    `add_mem $013b
    sta reg4
    ldx #$00
    sty reg5
    iny
    inx
    cpx #$08
    bne $f411

    lda $013b
    `add_imm 32
    sta $013b
    cpy #$00
    bne $f401

    lda #$00
    sta reg4
    sta reg4
    lda $013c
    cmp #$a0
    bcc $f439

    jmp $f448

    lda #$00
    sta reg3
    lda $013d
    clc
    sbc $013c
    sta reg3
    lda $00
    `chr_bankswitch 2
    lda #$00
    sta $89
    lda $013e
    cmp #$01
    beq $f46c

    inc $013c
    lda $013c
    cmp #$c8
    beq $f467

    jmp $f46c

    lda #$01
    sta $013e
    ldx #$00
    ldy #$00
    lda $013e
    cmp #$00
    beq $f4e3

    inc $8b
    inc $8a
    ldx #$01
    jsr sub19
    ldx $8a
    lda table20,x
    adc #$32
    sta $9a
    lda $9a
    adc #$28
    sta $9b
    lda $89
    cmp $9a
    bcc $f497

    bcs $f49f

    lda #$0e
    sta reg1
    jmp $f4aa

    lda $89
    cmp $9b
    bcs $f4ad

    lda #$ee
    sta reg1
    jmp $f4b2

    lda #$0e
    sta reg1
    lda $89
    `add_mem $8b
    adc $8a
    clc
    sbc #$14
    tax
    lda table19,x
    `add_mem $8b
    sta reg3
    lda $89
    `add_mem $8b
    tax
    lda table20,x
    sta reg3
    ldx $8a
    lda table20,x
    `add_imm 60
    sta $9b
    inc $89
    iny
    cpy #$91
    bne $f47b

    lda #$90
    sta reg0
    lda #$0e
    sta reg1
    rts

; -----------------------------------------------------------------------------

sub52:  ; f4ee
    ; jmp/bra targets:
    ; f4f0

    ldy #$00
    stx reg5
    iny
    cpy #$20
    bne $f4f0
    rts

; -----------------------------------------------------------------------------

sub53:  ; f4f9
    ; jmp/bra targets:
    ; f4fb

    ldy #$00
    stx reg5
    iny
    cpy #$20
    bne $f4fb
    rts

; -----------------------------------------------------------------------------

sub54:  ; f504
    ; jmp/bra targets:
    ; f5f5

    ldx #$25
    jsr sub59
    jsr sub15
    lda #$00
    sta reg0
    sta reg1
    lda #$20
    sta reg4
    lda #$00
    sta reg4
    ldx #$25
    jsr sub52
    ldx #$25
    jsr sub52
    ldx #$25
    jsr sub52
    ldx #$25
    jsr sub52
    ldx #$25
    jsr sub52
    ldx #$25
    jsr sub52
    ldx #$25
    jsr sub52
    ldx #$25
    jsr sub52
    ldx #$25
    jsr sub52
    ldx #$25
    jsr sub52
    ldx #$25
    jsr sub52
    ldx #$25
    jsr sub52
    ldx #$25
    jsr sub52
    ldx #$25
    jsr sub52
    ldx #$25
    jsr sub52
    ldx #$39
    jsr sub52
    ldx #$37
    jsr sub52
    ldx #$37
    jsr sub52
    ldx #$37
    jsr sub52
    ldx #$37
    jsr sub52
    ldx #$37
    jsr sub52
    ldx #$37
    jsr sub52
    ldx #$37
    jsr sub52
    ldx #$38
    jsr sub52
    lda #$00
    sta reg4
    sta reg4
    lda #$3f
    sta reg4
    lda #$00
    sta reg4
    lda table18+4
    sta reg5
    lda table18+5
    sta reg5
    lda table18+6
    sta reg5
    lda table18+7
    sta reg5
    lda #$00
    sta reg4
    sta reg4
    lda #$3f
    sta reg4
    lda #$10
    sta reg4
    lda table18+8
    sta reg5
    lda table18+9
    sta reg5
    lda table18+10
    sta reg5
    lda table18+11
    sta reg5
    lda #$00
    sta reg4
    sta reg4
    ldx data7
    txa
    asl
    asl
    tay
    lda $dc62,x
    sta $05c0,y
    lda $dc82,x
    sta $05c1,y
    lda #$02
    sta $05c2,y
    lda $dc52,x
    sta $05c3,y
    lda $dc72,x
    sta $011e,x
    dex
    cpx #$ff
    bne $f5f5

    lda #$00
    sta $0100
    lda #$01
    sta $02
    lda #$00
    sta $89
    sta $8a
    lda #$00
    sta $8f
    rts

; -----------------------------------------------------------------------------

sub55:  ; f62f
    ; jmp/bra targets:
    ; f647
    ; f663
    ; f68f
    ; f69e
    ; f6a6
    ; f6b2
    ; f6cd

    inc $0100
    ldx $0100
    lda table21,x
    sta $9a
    lda table22,x
    sta $9b
    lda #$05
    sta reg17
    ldx data7
    txa
    asl
    asl
    tay
    lda $dc62,x
    `add_mem $9a
    sta $05c0,y
    lda $05c3,y
    clc
    adc $dc72,x
    sta $05c3,y
    dex
    cpx #$07
    bne $f647

    txa
    asl
    asl
    tay
    lda $dc62,x
    `add_mem $9b
    sta $05c0,y
    lda $05c3,y
    clc
    adc $dc72,x
    sta $05c3,y
    dex
    cpx #$ff
    bne $f663

    `chr_bankswitch 0
    inc $8a
    lda $8a
    cmp #$08
    beq $f68f

    jmp $f6cd

    lda #$00
    sta $8a
    inc $8f
    lda $8f
    cmp #$eb
    beq $f69e

    jmp $f6a6

    lda #$00
    sta $02
    lda #$07
    sta $01
    lda #$22
    sta reg4
    lda #$61
    sta reg4
    ldx #$00
    txa
    `add_mem $8f
    tay
    lda table11,y
    clc
    sbc #$36
    sta reg5
    inx
    cpx #$1f
    bne $f6b2

    lda #$00
    sta reg4
    sta reg4
    inc $89
    ldx $89
    lda $8a
    sta reg3
    lda table20,x
    sta reg3
    lda table20,x
    sta $9a
    lda #$94
    clc
    sbc $9a
    sta $0500
    lda #$25
    sta $0501
    lda #$00
    sta $0502
    lda #$f8
    sta $0503
    lda #$98
    clc
    sbc $9a
    sta $0504
    lda #$25
    sta $0505
    lda #$00
    sta $0506
    lda #$f8
    sta $0507
    lda #$9c
    clc
    sbc $9a
    sta $0508
    lda #$25
    sta $0509
    lda #$00
    sta $050a
    lda #$f8
    sta $050b
    lda #$94
    clc
    sbc $9a
    sta $050c
    lda #$25
    sta $050d
    lda #$00
    sta $050e
    lda #$00
    sta $050f
    lda #$98
    clc
    sbc $9a
    sta $0510
    lda #$25
    sta $0511
    lda #$00
    sta $0512
    lda #$00
    sta $0513
    lda #$9c
    clc
    sbc $9a
    sta $0514
    lda #$25
    sta $0515
    lda #$00
    sta $0516
    lda #$00
    sta $0517
    lda #$80
    sta reg0
    lda #$1e
    sta reg1
    rts

; -----------------------------------------------------------------------------

sub56:  ; f776
    ; jmp/bra targets:
    ; f782
    ; f794

    lda #$23
    sta reg4
    lda #$c0
    sta reg4
    ldx #$40
    sty reg5
    dex
    bne $f782

    lda #$2b
    sta reg4
    lda #$c0
    sta reg4
    ldx #$40
    sty reg5
    dex
    bne $f794

    lda #$00
    sta reg4
    sta reg4
    rts

; -----------------------------------------------------------------------------

sub57:  ; f7a3
    ; jmp/bra targets:
    ; f7af
    ; f7c1
    ; f7dc
    ; f7ee

    lda #$23
    sta reg4
    lda #$c0
    sta reg4
    ldx #$20
    sty reg5
    dex
    bne $f7af

    lda #$2b
    sta reg4
    lda #$c0
    sta reg4
    ldx #$20
    sty reg5
    dex
    bne $f7c1

    lda #$00
    sta reg4
    sta reg4
    rts

    ; f7d0
    lda #$23
    sta reg4
    lda #$e0
    sta reg4
    ldx #$20
    sty reg5
    dex
    bne $f7dc

    lda #$2b
    sta reg4
    lda #$e0
    sta reg4
    ldx #$20
    sty reg5
    dex
    bne $f7ee

    lda #$00
    sta reg4
    sta reg4
    rts

; -----------------------------------------------------------------------------

sub58:  ; f7fd
    ; jmp/bra targets:
    ; f81b
    ; f83a

    stx $8e
    ldy #$00
    lda #$3c
    sta $9a
    lda #$00
    sta reg0
    sta reg1
    lda #$20
    sta reg4
    lda #$00
    sta reg4
    ldx #$00
    ldy #$00
    lda $8e
    sta reg5
    sta reg5
    sta reg5
    sta reg5
    inx
    bne $f81b

    lda #$28
    sta reg4
    lda #$00
    sta reg4
    ldx #$00
    ldy #$00
    lda $8e
    sta reg5
    sta reg5
    sta reg5
    sta reg5
    inx
    bne $f83a

    lda #$01
    sta $02
    lda #$00
    sta reg4
    sta reg4
    rts

; -----------------------------------------------------------------------------

sub59:  ; f858
    ; jmp/bra targets:
    ; f874
    ; f88a
    ; f8a2
    ; f8aa
    ; f8b2
    ; f8ba
    ; f8d2
    ; f8da
    ; f8e2
    ; f8ea
    ; f902
    ; f90a
    ; f912
    ; f91a

    stx $8e
    ldy #$00
    lda #$3c
    sta $9a
    lda #$00
    sta reg0
    sta reg1
    lda #$23
    sta reg4
    lda #$c0
    sta reg4
    ldx #$00
    lda #$00
    sta reg5
    inx
    cpx #$40
    bne $f874

    lda #$27
    sta reg4
    lda #$c0
    sta reg4
    ldx #$00
    lda #$00
    sta reg5
    inx
    cpx #$40
    bne $f88a

    lda #$20
    sta reg4
    lda #$00
    sta reg4
    ldx #$00
    ldy #$00
    lda $8e
    sta reg5
    inx
    bne $f8a2

    lda $8e
    sta reg5
    inx
    bne $f8aa

    lda $8e
    sta reg5
    inx
    bne $f8b2

    lda $8e
    sta reg5
    inx
    cpx #$c0
    bne $f8ba

    lda #$24
    sta reg4
    lda #$00
    sta reg4
    ldx #$00
    ldy #$00
    lda $8e
    sta reg5
    inx
    bne $f8d2

    lda $8e
    sta reg5
    inx
    bne $f8da

    lda $8e
    sta reg5
    inx
    bne $f8e2

    lda $8e
    sta reg5
    inx
    cpx #$c0
    bne $f8ea

    lda #$28
    sta reg4
    lda #$00
    sta reg4
    ldx #$00
    ldy #$00
    lda $8e
    sta reg5
    inx
    bne $f902

    lda $8e
    sta reg5
    inx
    bne $f90a

    lda $8e
    sta reg5
    inx
    bne $f912

    lda $8e
    sta reg5
    inx
    cpx #$c0
    bne $f91a

    lda #$01
    sta $02
    lda #$72
    sta $96
    lda #$00
    sta reg4
    sta reg4
    lda #$00
    sta reg3
    sta reg3
    lda #$00
    sta reg0
    lda #$1e
    sta reg1
    rts

; -----------------------------------------------------------------------------

nmi:  ; f947
    ; Note: why not just RTI instead of a JMP to one (or even JMP to another
    ; JMP to RTI)?

    lda reg2
    lda $01
    cmp #0
    beq jump_table+1*3
    cmp #1
    beq jump_table+2*3
    cmp #2
    beq jump_table+3*3
    cmp #3
    beq jump_table+4*3
    cmp #4
    beq jump_table+5*3
    cmp #5
    beq jump_table+6*3
    cmp #6
    beq jump_table+7*3
    cmp #7
    beq jump_table+8*3
    cmp #9
    beq jump_table+9*3
    cmp #10
    beq jump_table+10*3
    cmp #11
    beq jump_table+11*3
    cmp #12
    beq jump_table+12*3
    cmp #13
    beq jump_table+13*3

jump_table:
    jmp nmi_exit  ; $01 was none of the below
    jmp nmi_1     ; $01 was 0
    jmp nmi_2     ; $01 was 1
    jmp nmi_3     ; $01 was 2
    jmp nmi_4     ; $01 was 3
    jmp nmi_5     ; $01 was 4
    jmp nmi_6     ; $01 was 5
    jmp nmi_7     ; $01 was 6
    jmp nmi_8     ; $01 was 7
    jmp nmi_9     ; $01 was 9
    jmp nmi_10    ; $01 was 10
    jmp nmi_11    ; $01 was 11
    jmp nmi_12    ; $01 was 12
    jmp nmi_13    ; $01 was 13

nmi_1:
    lda $02
    cmp #$00
    beq +
    jmp ++
*   lda #$01
    sta $02
*   jsr sub29
    jsr sub12
    inc $93
    inc $93
    inc $94
    inc $94
    lda $94
    cmp #$e6
    beq +
    jmp ++
*   inc $95
    lda #$00
    sta $94
*   jmp nmi_exit

nmi_2:
    lda $02
    cmp #$00
    beq +
    jmp ++
*   jsr sub38
*   jsr sub39
    jsr sub12
    inc $98
    lda $98
    cmp #$ff
    beq +
    jmp +++
*   inc $99
    lda $99
    cmp #$03
    beq +
    jmp ++
*   lda #$04
    sta $01
    lda #$00
    sta $02
*   jmp nmi_exit

nmi_3:
    lda $02
    cmp #$00
    beq +
    jmp ++
*   jsr sub30
*   jsr sub31
    jsr sub12
    inc $ab
    lda $ab
    cmp #$ff
    beq +
    jmp +++
*   inc $ac
    lda $ac
    cmp #$03
    beq +
    jmp ++
*   lda #$0b
    sta $01
    lda #$00
    sta $02
*   jmp nmi_exit

nmi_4:
    lda $02
    cmp #$00
    beq +
    jmp ++
*   jsr sub40
*   jsr sub41
    jsr sub12
    jmp nmi_exit

nmi_5:
    lda $02
    cmp #$00
    beq +
    jmp ++
*   jsr sub42
*   jsr sub43
    jsr sub12
    inc $a9
    lda $a9
    cmp #$ff
    beq +
    jmp +++
*   inc $aa
    lda $aa
    cmp #$04
    beq +
    jmp ++
*   lda #$05
    sta $01
    lda #$00
    sta $02
*   jmp nmi_exit

nmi_6:
    lda $02
    cmp #$00
    beq +
    jmp ++
*   jsr sub54
*   jsr sub55
    jsr sub12
    jmp nmi_exit

nmi_7:
    lda $02
    cmp #$00
    beq +
    jmp ++
*   jsr sub44
*   jsr sub45
    jsr sub12
    inc $0135
    lda $0135
    cmp #$ff
    beq +
    jmp +++
*   inc $0136
    lda $0136
    cmp #$03
    beq +
    jmp ++
*   lda #$03
    sta $01
    lda #$00
    sta $02
*   jmp nmi_exit

nmi_8:
    lda $02
    cmp #$00
    beq +
    jmp ++
*   jsr sub50
*   jsr sub51
    jsr sub12
    inc $013f
    lda $013f
    cmp #$ff
    beq +
    jmp ++
*   inc $0140
*   lda $0140
    cmp #$03
    bne +
    lda $013f
    cmp #$ae
    bne +
    lda #$06
    sta $01
    lda #$00
    sta $02
*   jmp nmi_exit

nmi_9:
    lda $02
    cmp #$00
    beq +
    jmp ++
*   jsr sub32
*   jsr sub33
    inc $0141
    lda $0141
    cmp #$ff
    beq +
    jmp $fb3d
*   inc $0142
    lda $0142
    cmp #$0e
    beq +
    jmp ++
*   lda #$00
    sta $01
    lda #$00
    sta $02
*   jmp nmi_exit

nmi_10:
    lda $02
    cmp #$00
    beq +
    jmp ++
*   jsr sub34
*   jsr sub35
    jsr sub12
    inc $0143
    lda $0143
    cmp #$ff
    beq +
    jmp ++
*   inc $0144
*   lda $0144
    cmp #$02
    bne +
    lda $0143
    cmp #$af
    bne +
    lda #$0c
    sta $01
    lda #$00
    sta $02
*   jmp nmi_exit

nmi_11:
    lda $02
    cmp #$00
    beq +
    jmp ++
*   jsr sub36
*   jsr sub37
    jsr sub12
    inc $0145
    lda $0145
    cmp #$ff
    beq +
    jmp +++
*   inc $0146
    lda $0146
    cmp #$03
    beq +
    jmp ++
*   lda #$01
    sta $01
    lda #$00
    sta $02
*   jmp nmi_exit

nmi_12:
    lda $02
    cmp #$00
    beq +
    jmp ++
*   jsr sub48
*   jsr sub49
    jsr sub12
    inc $014f
    lda $014f
    cmp #$ff
    beq +
    jmp ++
*   inc $0150
*   lda $0150
    cmp #$03
    bne +
    lda $014f
    cmp #$96
    bne +
    lda #$0d
    sta $01
    lda #$00
    sta $02
*   jmp nmi_exit

nmi_13:
    lda $02
    cmp #$00
    beq +
    jmp ++
*   jsr sub46
*   jsr sub47
    inc $0151
    lda $0151
    cmp #$ff
    beq +
    jmp ++
*   inc $0152
*   lda $0152
    cmp #$0a
    bne +
    lda $0151
    cmp #$a0
    bne +
    lda #$09
    sta $01
    lda #$00
    sta $02
*   jmp nmi_exit  ; why?

nmi_exit:
    rti

; -----------------------------------------------------------------------------

irq:  ; fc26
    rti
