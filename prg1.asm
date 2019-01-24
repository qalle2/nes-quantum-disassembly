    ; second half of PRG ROM, minus the interrupt vectors

init:  ; c000
    sei
    cld
    jsr sub14

    ; clear RAM (fill $0000-$07ff with $00)
    ldx #0
    txa
*   sta $00,x
    sta $0100,x
    sta $0200,x
    sta $0300,x
    sta $0400,x
    sta $0500,x
    sta $0600,x
    sta $0700,x
    inx
    bne -

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
    ; This sub could be optimized in many places.

    ldx #0
*   lda #$f5
    sta $0500,x
    `inx4
    bne -
    rts

    lda #$00
    sta reg0
    sta reg1
    lda #$00
    sta reg0

    lda #$00
    ldx #0
*   sta reg6,x
    inx
    cpx #15
    bne -

    lda #$c0
    sta reg19
    jsr sub16
    jsr sub18
    rts

; -----------------------------------------------------------------------------

sub16:

    ldx #0
*   lda table12,x
    sta $07c0,x
    inx
    cpx #32
    bne -

    rts

; -----------------------------------------------------------------------------

sub17:

    ldx #0
*   lda #$0f
    sta $07c0,x
    inx
    cpx #32
    bne -

    rts

; -----------------------------------------------------------------------------

sub18:

    lda #$3f
    sta reg4
    lda #$00
    sta reg4

    ldx #0
*   lda $07c0,x
    sta reg5
    inx
    cpx #32
    bne -

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
    bcc +         ; why?
*   sta $86
    inc $87
    lda $87
    cmp $88
    bne sub19_loop1

    rts

    stx $88
    ldx #0
*   `add_imm $55  ; start loop
    clc
    nop
    nop
    adc #15
    sbc #15
    inx
    cpx $88
    bne -

    rts

    stx $88
    ldy #0
    ldx #0
sub19_loop2:  ; start outer loop
    ldy #0

*   nop  ; start inner loop
    nop
    nop
    nop
    nop
    iny
    cpy #11
    bne -

    nop
    inx
    cpx $88
    bne sub19_loop2

    rts

; -----------------------------------------------------------------------------

sub20:

    ldy #0
*   lda $07c0,y     ; start loop
    sta $01
    and #%00110000
    `lsr4
    tax
    lda $01
    and #%00001111
    ora table18,x
    sta $07c0,y
    iny
    cpy #32
    bne -

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
    jmp sub21_exit
*   lda #$3f
    sta reg5
sub21_exit:
    rts

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

sub22_loop:   ; start outer loop
    ldx #$00
    lda #$00
    sta $9a

*   lda $9c       ; start inner loop
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
    bne -

    lda $9b
    `add_imm 8
    sta $9b
    lda $9b
    cmp #16
    bne sub22_loop

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

sub23_loop:   ; start outer loop
    ldx #$00
    lda #$00
    sta $9a

*   lda $9c       ; start inner loop
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
    bne -

    lda $9b
    `add_imm 8
    sta $9b
    lda $9b
    cmp #16
    bne sub23_loop

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

sub24_loop:   ; start outer loop
    ldx #$00
    lda #$00
    sta $9a

*   lda $9c       ; start inner loop
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
    bne -

    lda $9b
    `add_imm 8
    sta $9b
    lda $9b
    cmp #16
    bne sub24_loop

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

*   ldy $90        ; start loop
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
    bne -

    lda #$00
    sta $90

*   ldy $90       ; start loop
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
    bne -

    lda #$00
    sta reg4
    sta reg4
    rts

; -----------------------------------------------------------------------------

sub27:

    lda #$00
    sta $9a

    ldx data8
*   txa        ; start loop
    asl
    asl
    tay
    lda $05b4,y
    clc
    sbc table46,x
    sta $05b4,y
    dex
    cpx #$ff
    bne -

    rts

; -----------------------------------------------------------------------------

sub28:

    ldx data8
*   txa        ; start loop
    asl
    asl
    tay
    lda table45,x
    sta $05b4,y
    lda table47,x
    sta $05b5,y
    lda #$03
    sta $05b6,y
    lda table44,x
    sta $05b7,y
    lda table46,x
    sta $011e,x
    dex
    cpx #$ff
    bne -

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
*   stx reg5
    inx
    bne -

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

sub31:

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
    beq +
    inc $014e
*   lda $ac
    cmp #$02
    bne +
    lda $ab
    cmp #$32
    bne +
    jsr sub25
*   lda $ac
    cmp #$01
    bne sub31_1
    lda $ab
    cmp #$96
    bne sub31_1
    ldx data1

*   txa  ; start loop
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
    beq +
    dex
    jmp -

*   lda #$81
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

sub31_1:
    lda $ac
    cmp #$02
    bne sub31_2
    lda $ab
    cmp #$32
    bcc sub31_2
    ldx #$00
    ldy #$00

sub31_loop:
    lda $0180,x
    cmp #$01
    bne +
    lda #$a0
    clc
    adc $016a,x
    sta $9a
    lda $0154,x
    sta $0500,y
    cmp $9a
    bcc +
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
*   inx
    `iny4
    cpx #$16
    bne sub31_loop

sub31_2:
    lda $ac
    cmp #$02
    bne +
    lda $ab
    cmp #$c8
    bcc +
    inc $a3
    lda $a3
    cmp #$04
    bne +
    jsr sub20
    jsr sub18
    lda #$00
    sta $a3
*   jsr sub27
    lda #$02
    sta $01
    rts

; -----------------------------------------------------------------------------

sub32:

    lda #$00
    ldx #0
*   sta reg6,x
    inx
    cpx #15
    bne -

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

sub33:

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

sub33_loop:

    ldx #25
*   dex
    bne -

    ldx #$3f
    stx reg4
    ldx #$00
    stx reg4
    inc $8c
    lda $8c
    cmp #$05
    beq +
    jmp ++
*   inc $89
    lda #$00
    sta $8c
*   inc $89
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
    bne sub33_loop

    lda #$06
    sta reg1
    lda #$90
    sta reg0
    rts

; -----------------------------------------------------------------------------

sub34:
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

sub35:

    `chr_bankswitch 1
    lda $0148
    cmp #$00
    beq +
    jmp sub35_1
*   dec $8a
    ldx #$00
    lda #$00
    sta $89

*   lda $89  ; start loop
    adc $8a
    tay
    lda table19,y
    sta $0600,x
    lda $89
    `add_mem $00
    sta $89
    inx
    cpx #64
    bne -

    ldx #$00
    ldy #$00
    lda #$00
    sta $9a

sub35_loop1:  ; start outer loop
    lda #$21
    sta reg4
    lda $9a
    sta reg4
    ldy #$00

*   lda $0600,x  ; start inner loop
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
    cpy #8
    bne -

    lda $9a
    `add_imm 32
    sta $9a
    lda $9a
    cmp #$00
    bne sub35_loop1

    lda #$01
    sta $0148
    jmp sub35_2

sub35_1:
    dec $8a
    ldx #$40
    lda #$00
    sta $89

*   lda $89  ; start loop
    adc $8a
    tay
    lda table19,y
    sta $0600,x
    lda $89
    `add_mem $00
    sta $89
    inx
    cpx #128
    bne -

    ldx #$7f
    lda #$00
    sta $9a

sub35_loop2:  ; start outer loop
    lda #$22
    sta reg4
    lda $9a
    sta reg4
    ldy #$00

*   lda $0600,x  ; start inner loop
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
    cpy #8
    bne -

    lda $9a
    `add_imm 32
    sta $9a
    lda $9a
    cmp #$00
    bne sub35_loop2

    lda #$00
    sta $0148

sub35_2:
    lda #$00
    sta reg4
    sta reg4
    lda #$00
    sta $89

*   ldx #$04   ; start loop
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
    bne -

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

sub37:

    jsr sub21
    `chr_bankswitch 1
    dec $8a
    dec $8a

    ldx #0
    lda #0
    sta $89
*   lda $89  ; start loop
    adc $8a
    tay
    lda table19,y
    adc #$46
    sta $0600,x
    inc $89
    inx
    cpx #$80
    bne -

    lda $0148
    cmp #$00
    beq +
    jmp sub37_1
*   ldx #$00
    ldy #$00
    lda #$00

    sta $9a
sub37_loop1:  ; start outer loop
    lda #$21
    sta reg4
    lda $9a
    sta reg4

    ldy #0
*   lda $0600,x  ; start inner loop
    sta reg5
    lda $0600,x
    sta reg5
    lda $0600,x
    sta reg5
    lda $0600,x
    sta reg5
    inx
    iny
    cpy #8
    bne -

    lda $9a
    `add_imm 32
    sta $9a
    lda $9a
    cmp #$00
    bne sub37_loop1

    lda #$01
    sta $0148
    jmp sub37_2

sub37_1:
    ldx #$7f
    lda #$20
    sta $9a

sub37_loop2:  ; start outer loop
    lda #$22
    sta reg4
    lda $9a
    sta reg4
    ldy #0

*   lda $0600,x  ; start inner loop
    sta reg5
    lda $0600,x
    sta reg5
    lda $0600,x
    sta reg5
    lda $0600,x
    sta reg5
    dex
    iny
    cpy #8
    bne -

    lda $9a
    `add_imm 32
    sta $9a
    lda $9a
    cmp #$00
    bne sub37_loop2

    lda #$00
    sta $0148

sub37_2:
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

sub38:

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

sub39:

    dec $8c
    inc $8b
    lda $8b
    cmp #$02
    bne +
    lda #$00
    sta $8b
    dec $8a
*   lda #$84
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

    ldy #85
sub39_loop:  ; start outer loop

    ldx #25
*   dex      ; start inner loop
    bne -

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
    bne sub39_loop

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

sub40:

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

sub40_1:
    lda #$00
    sta $9e
    lda #$00
    sta $9f
sub40_loop1:  ; start outermost loop

    ldy #0
sub40_loop2:  ; start middle loop

    ldx #0
*   txa           ; start innermost loop
    `add_mem $9e
    sta reg5
    inx
    cpx #8
    bne -

    iny
    cpy #$04
    bne sub40_loop2

    lda $9e
    `add_imm 8
    sta $9e
    lda $9e
    cmp #$40
    bne sub40_loop1
    lda #$00
    sta $9e
    inc $9f
    lda $9f
    cmp #$03
    bne sub40_loop1

    ldx #0    ; why?
sub40_loop3:  ; start outermost loop

    ldy #0
sub40_loop4:  ; start middle loop

    ldx #0
*   txa           ; start innermost loop
    `add_mem $9e
    sta reg5
    inx
    cpx #8
    bne -

    iny
    cpy #4
    bne sub40_loop4

    lda $9e
    `add_imm 8
    sta $9e
    cmp #$28
    bne sub40_loop3

    lda #$f0  ; why?
    ldy #0
sub40_loop5:  ; start outer loop

    ldx #$f0
*   stx reg5  ; start inner loop
    inx
    cpx #$f8
    bne -

    iny
    cpy #8
    bne sub40_loop5

    lda #$00
    sta reg4
    sta reg4
    inc $a0
    lda $a0
    cmp #$02
    bne +
    jmp sub40_2
*   lda #$28
    sta reg4
    lda #$00
    sta reg4
    jmp sub40_1

sub40_2:
    lda #$23
    sta reg4
    lda #$c0
    sta reg4

    ldx #0
*   lda #$00  ; start loop
    sta reg5
    inx
    cpx #64
    bne -

    lda #$00
    sta reg4
    sta reg4
    lda #$2b
    sta reg4
    lda #$c0
    sta reg4

    ldx #0
*   lda #$00  ; start loop
    sta reg5
    inx
    cpx #64
    bne -

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

sub41:

    lda #$05
    sta reg17
    lda $a2
    cmp #$08
    bne sub41_1
    lda $a1
    cmp #$8c
    bcc sub41_1
    inc $a3
    lda $a3
    cmp #$04
    bne sub41_1
    jsr sub20
    jsr sub18
    lda #$00
    sta $a3

sub41_1:
    lda #$03
    sta $01
    lda #$3f
    sta reg4
    lda #$00
    sta reg4
    lda $a2
    cmp #$08
    beq sub41_4
    lda $014d
    cmp #0
    beq sub41_3
    cmp #1
    beq sub41_2
    cmp #2
    beq +     ; why?

*   lda #$34
    sta reg5
    lda #$24
    sta reg5
    lda #$14
    sta reg5
    lda #$04
    sta reg5

sub41_2:
    lda #$38
    sta reg5
    lda #$28
    sta reg5
    lda #$18
    sta reg5
    lda #$08
    sta reg5

sub41_3:
    lda #$32
    sta reg5
    lda #$22
    sta reg5
    lda #$12
    sta reg5
    lda #$02
    sta reg5

sub41_4:
    inc $89
    lda $89
    sta reg3
    ldx $89
    lda table20,x
    sta reg3
    inc $a1
    lda $a1
    cmp #$b4
    beq +
    jmp sub41_5
*   inc $a2
    lda #$00
    sta $a1

sub41_5:
    lda $a2
    cmp #1
    beq sub41_jump_table+1*3
    cmp #2
    beq sub41_jump_table+2*3
    cmp #3
    beq sub41_jump_table+3*3
    cmp #4
    beq sub41_jump_table+4*3
    cmp #5
    beq sub41_jump_table+5*3
    cmp #6
    beq sub41_jump_table+6*3
    cmp #7
    beq sub41_jump_table+7*3
    cmp #8
    beq sub41_jump_table+8*3
    cmp #9
    beq sub41_6

sub41_jump_table:
    jmp sub41_15
    jmp sub41_7
    jmp sub41_8
    jmp sub41_9
    jmp sub41_10
    jmp sub41_11
    jmp sub41_12
    jmp sub41_13
    jmp sub41_14

sub41_6:
    lda #$0a
    sta $01
    lda #$00
    sta $02
    jmp $ea7e

sub41_7:
    jsr sub15
    ldx #$5c
    ldy #$6a
    lda #$90
    sta $9a
    jsr sub22
    jmp $ea7e

sub41_8:
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

sub41_9:
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

sub41_10:
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

sub41_11:
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

sub41_12:
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

sub41_13:
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

sub41_14:
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

sub41_15:
    jsr sub15
    `chr_bankswitch 1
    lda #$98
    sta reg0
    lda #$1e
    sta reg1
    rts

; -----------------------------------------------------------------------------

sub42:

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

    ldy #0
sub42_loop1:  ; start outer loop

    ldx #0
*   sty reg5  ; start first inner loop
    iny
    inx
    cpx #16
    bne -

    ldx #0
*   lda #$7f  ; start second inner loop
    sta reg5
    inx
    cpx #16
    bne -

    cpy #0
    bne sub42_loop1

    jsr sub12

    ldy #0
sub42_loop2:  ; start outer loop

    ldx #0
*   sty reg5  ; start first inner loop
    iny
    inx
    cpx #16
    bne -

    ldx #0
*   lda #$7f  ; start second inner loop
    sta reg5
    inx
    cpx #16
    bne -

    cpy #$e0
    bne sub42_loop2

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

sub43:

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

sub43_loop1:
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
    cmp #15
    beq +
    jmp ++
*   inc $8c
    lda #$00
    sta $8d
*   lda $8c
    cmp #16
    beq +
    jmp ++
*   lda #$00
    sta $8c
*   cpy #96
    bne sub43_loop1

    ldx #$18
    lda #$00
    sta $9a
    sta $89
    dec $8c

sub43_loop2:
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
    beq +
    jmp ++
*   lda #$00
    sta $8c
*   cpy #192
    bne sub43_loop2

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
    bne sub43_exit

    inc $0149
    lda $0149
    cmp #$02
    beq +

    lda #$00
    sta $014a
    lda #$01
    sta $014b
    jmp sub43_exit

*   lda #$20
    sta $014a
    lda #$21
    sta $014b
    lda #$00
    sta $0149

sub43_exit:
    rts

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
    ldy #0
*   stx reg5  ; start loop
    inx
    iny
    cpy #12
    bne -

    lda #$00
    sta reg4
    sta reg4
    lda #$21
    sta reg4
    lda #$2a
    sta reg4

    ldy #0
    ldx #$5c
*   stx reg5  ; start loop
    inx
    iny
    cpy #12
    bne -

    lda #$00
    sta reg4
    sta reg4
    lda #$21
    sta reg4
    lda #$4a
    sta reg4

    ldy #0
    ldx #$68
*   stx reg5  ; start loop
    inx
    iny
    cpy #12
    bne -

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
    beq sub43_1

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

sub43_1:
    lda #$01
    sta $0130
    lda #$1e
    sta reg1
    lda #$10
    sta reg0
    inc $8a
    lda $8a
    cmp #8
    beq +
    jmp sub43_2
*   lda #$00
    sta $8a
    inc $8f
    lda $8f
    cmp #$eb
    beq +
    jmp ++
*   lda #$00
    sta $02
    lda #$07
    sta $01
*   lda #$23
    sta reg4
    lda #$61
    sta reg4

    ldx #0
*   txa           ; start loop
    `add_mem $8f
    tay
    lda table11,y
    clc
    sbc #$36
    sta reg5
    inx
    cpx #31
    bne -

    lda #$00
    sta reg4
    sta reg4

sub43_2:
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

*   txa  ; start loop
    asl
    asl
    tay
    lda table28,x
    `add_imm $9b
    sta $055c,y
    txa
    pha
    ldx $0137
    lda table52,x
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
    cpx #0
    beq +
    dex
    jmp -

*   inc $013a
    lda $013a
    cmp #$06
    bne +
    inc $0139
    inc $0139
    lda #$00
    sta $013a
*   inc $0138
    lda $0138
    cmp #$0c
    bne +
    lda #$00
    sta $0138
    inc $0137
    lda $0137
    cmp #$04
    bne +
    lda #$00
    sta $0137
*   lda #$88
    sta reg0
    lda #$18
    sta reg1
    rts

; -----------------------------------------------------------------------------

sub44:

    jsr sub15
    ldy #$aa
    jsr sub56
    lda #$1a
    sta $9a
    ldx #$60

sub44_loop1:  ; start outer loop
    lda #$21
    sta reg4
    lda $9a
    sta reg4
    ldy #0

*   stx reg5  ; start inner loop
    inx
    iny
    cpy #$03
    bne -

    lda #$00
    sta reg4
    sta reg4
    lda $9a
    `add_imm 32
    sta $9a
    lda $9a
    cmp #$1a
    bne sub44_loop1

    lda #$08
    sta $9a
    ldx #$80

sub44_loop2:  ; start outer loop
    lda #$22
    sta reg4
    lda $9a
    sta reg4
    ldy #0

*   stx reg5  ; start inner loop
    inx
    iny
    cpy #3
    bne -

    lda #$00
    sta reg4
    sta reg4
    lda $9a
    `add_imm 32
    sta $9a
    lda $9a
    cmp #$68
    bne sub44_loop2

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
*   lda table31,x  ; start loop
    sta $0104,x
    lda table32,x
    sta $0108,x
    dex
    cpx #255
    bne -

    ldx data5
*   lda #$00     ; start loop
    sta $0112,x
    lda #$f0
    sta $0116,x
    dex
    cpx #$ff
    bne -

    ldx data7
*   txa        ; start loop
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
    cpx #255
    bne -

    lda #$7a
    sta $0111
    lda #$0a
    sta $0110

    ldx data4
*   txa        ; start loop
    asl
    asl
    tay
    lda table35,x
    sta $0505,y
    lda table36,x
    sta $0506,y
    cpx #0
    beq +
    dex
    jmp -

*   lda #$00
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

sub45:

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

sub45_loop1:
    dec $0104,x
    lda $0104,x
    cmp #$00
    bne sub45_1
    lda $0108,x
    cmp table33,x
    beq +
    inc $0108,x
    jmp sub45_0
*   lda table32,x
    sta $0108,x
sub45_0:
    lda table31,x
    sta $0104,x
sub45_1:
    dex
    cpx #255
    bne sub45_loop1

    lda $0108
    sta $0505
    lda $0109
    sta $0541
    lda $010a
    sta $0545
    lda $010b
    sta $0535
    ldx data4

*   txa  ; start loop
    asl
    asl
    tay
    lda table34,x
    `add_mem $0111
    sta $0504,y
    lda table37,x
    `add_mem $0110
    sta $0507,y
    cpx #0
    beq +
    dex
    jmp -

*   lda $0100
    ldx $0101
    cmp table38,x
    bne sub45_2

    inc $0101
    lda $0101
    cpx data6
    bne +
    lda #$00
    sta $0101
*   ldx $0102
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
    bne sub45_2
    lda #$00
    sta $0102

sub45_2:
    ldx data5
sub45_loop2:
    lda $0116,x
    cmp #$f0
    beq sub45_3
    lda $0112,x
    clc
    sbc $011a,x
    bcc +
    sta $0112,x
    jmp sub45_3
*   lda #$f0
    sta $0116,x
sub45_3:
    dex
    cpx #255
    bne sub45_loop2

    ldx data5
*   txa        ; start loop
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
    cpx #255
    bne -

    ldx data7
*   txa        ; start loop
    asl
    asl
    tay
    lda $05c3,y
    clc
    sbc table42,x
    sta $05c3,y
    dex
    cpx #255
    bne -

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

sub46:

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

    ldx #0
*   lda table13,x  ; start loop
    clc
    sbc #$10
    sta reg5
    inx
    cpx #96
    bne -

    lda #$02
    sta reg0
    lda #$00
    sta reg1
    rts

; -----------------------------------------------------------------------------

sub47:

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

sub48:

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

sub48_loop:   ; start outer loop
    lda #$20
    sta reg4
    lda $9a
    `add_imm $69
    sta reg4
    ldy #0

*   stx reg5  ; start inner loop
    inx
    iny
    cpy #16
    bne -

    lda #$00
    sta reg4
    sta reg4
    lda $9a
    `add_imm 32
    sta $9a
    cmp #96
    bne sub48_loop

    lda #$21
    sta reg4
    lda #$00
    sta reg4

    ldx #0
*   lda table14,x  ; start loop
    clc
    sbc #$10
    sta reg5
    inx
    bne -

    ldx #0
*   lda table15,x  ; start loop
    clc
    sbc #$10
    sta reg5
    inx
    bne -

    ldx #0
*   lda table16,x  ; start loop
    clc
    sbc #$10
    sta reg5
    inx
    cpx #$80
    bne -

    lda #$00
    sta reg4
    sta reg4
    lda #$01
    sta $02
    lda #$e6
    sta $0153
    rts

; -----------------------------------------------------------------------------

sub49:

    `chr_bankswitch 2
    lda $0150
    cmp #$00
    bne +
    lda $014f
    cmp #$03
    bne +
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
*   lda #$00
    sta reg3
    ldx $0153
    lda table19,x
    `add_mem $0153
    sta reg3
    lda $0153
    cmp #$00
    beq +
    dec $0153
*   lda $0150
    cmp #$03
    bne +
    lda $014f
    cmp #$00
    bcc +
    inc $a3
    lda $a3
    cmp #$04
    bne +
    jsr sub20
    jsr sub18
    lda #$00
    sta $a3
*   lda #$0c
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

sub51:

    lda $013c
    cmp #$02
    beq +
    jmp sub51_0
*   ldy #$80

sub51_loop1:  ; start outer loop
    lda #$21
    sta reg4
    lda #$04
    `add_mem $013b
    sta reg4

    ldx #0
*   sty reg5  ; start inner loop
    iny
    inx
    cpx #8
    bne -

    lda $013b
    `add_imm 32
    sta $013b
    cpy #$c0
    bne sub51_loop1

sub51_loop2:  ; start outer loop
    lda #$22
    sta reg4
    lda #$04
    `add_mem $013b
    sta reg4

    ldx #0
*   sty reg5  ; start inner loop
    iny
    inx
    cpx #8
    bne -

    lda $013b
    `add_imm 32
    sta $013b
    cpy #$00
    bne sub51_loop2

    lda #$00
    sta reg4
    sta reg4
    lda #$00
    sta $013b

sub51_loop3:  ; start outer loop
    lda #$21
    sta reg4
    lda #$14
    `add_mem $013b
    sta reg4

    ldx #0
*   sty reg5  ; start inner loop
    iny
    inx
    cpx #8
    bne -

    lda $013b
    `add_imm 32
    sta $013b
    cpy #$c0
    bne sub51_loop3

sub51_loop4:  ; start outer loop
    lda #$22
    sta reg4
    lda #$14
    `add_mem $013b
    sta reg4

    ldx #0
*   sty reg5  ; start inner loop
    iny
    inx
    cpx #8
    bne -

    lda $013b
    `add_imm 32
    sta $013b
    cpy #0
    bne sub51_loop4

    lda #$00
    sta reg4
    sta reg4

sub51_0:
    lda $013c
    cmp #$a0
    bcc +
    jmp sub51_1
*   lda #$00
    sta reg3
    lda $013d
    clc
    sbc $013c
    sta reg3

sub51_1:
    lda $00
    `chr_bankswitch 2
    lda #$00
    sta $89
    lda $013e
    cmp #$01
    beq sub51_2
    inc $013c
    lda $013c
    cmp #$c8
    beq +
    jmp sub51_2
*   lda #$01
    sta $013e

sub51_2:
    ldx #$00
    ldy #$00
    lda $013e
    cmp #$00
    beq sub51_10
    inc $8b
    inc $8a

sub51_loop5:
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
    bcc +   ; why?
    bcs ++

*   lda #$0e
    sta reg1
    jmp sub51_5  ; why jump to another JMP?
*   lda $89
    cmp $9b
    bcs +
    lda #$ee
    sta reg1

sub51_5:
    jmp ++
*   lda #$0e
    sta reg1
*   lda $89
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
    bne sub51_loop5

sub51_10:
    lda #$90
    sta reg0
    lda #$0e
    sta reg1
    rts

; -----------------------------------------------------------------------------

sub52:

    ldy #0
*   stx reg5
    iny
    cpy #32
    bne -

    rts

; -----------------------------------------------------------------------------

sub53:
    ; Why identical to the previous subroutine?

    ldy #0
*   stx reg5
    iny
    cpy #32
    bne -

    rts

; -----------------------------------------------------------------------------

sub54:

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
*   txa        ; start loop
    asl
    asl
    tay
    lda table49,x
    sta $05c0,y
    lda table51,x
    sta $05c1,y
    lda #$02
    sta $05c2,y
    lda table48,x
    sta $05c3,y
    lda table50,x
    sta $011e,x
    dex
    cpx #255
    bne -

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

sub55:

    inc $0100
    ldx $0100
    lda table21,x
    sta $9a
    lda table22,x
    sta $9b
    lda #$05
    sta reg17
    ldx data7

*   txa  ; start loop
    asl
    asl
    tay
    lda table49,x
    `add_mem $9a
    sta $05c0,y
    lda $05c3,y
    clc
    adc table50,x
    sta $05c3,y
    dex
    cpx #7
    bne -

*   txa  ; start loop
    asl
    asl
    tay
    lda table49,x
    `add_mem $9b
    sta $05c0,y
    lda $05c3,y
    clc
    adc table50,x
    sta $05c3,y
    dex
    cpx #255
    bne -

    `chr_bankswitch 0
    inc $8a
    lda $8a
    cmp #$08
    beq +
    jmp sub55_2
*   lda #$00
    sta $8a
    inc $8f
    lda $8f
    cmp #$eb
    beq +
    jmp sub55_1
*   lda #$00
    sta $02
    lda #$07
    sta $01

sub55_1:
    lda #$22
    sta reg4
    lda #$61
    sta reg4
    ldx #$00

*   txa           ; start loop
    `add_mem $8f
    tay
    lda table11,y
    clc
    sbc #$36
    sta reg5
    inx
    cpx #31
    bne -

    lda #$00
    sta reg4
    sta reg4

sub55_2:
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

sub56:

    lda #$23
    sta reg4
    lda #$c0
    sta reg4

    ldx #64
*   sty reg5
    dex
    bne -

    lda #$2b
    sta reg4
    lda #$c0
    sta reg4

    ldx #64
*   sty reg5
    dex
    bne -

    lda #$00
    sta reg4
    sta reg4
    rts

; -----------------------------------------------------------------------------

sub57:

    lda #$23
    sta reg4
    lda #$c0
    sta reg4

    ldx #32
*   sty reg5
    dex
    bne -

    lda #$2b
    sta reg4
    lda #$c0
    sta reg4

    ldx #32
*   sty reg5
    dex
    bne -

    lda #$00
    sta reg4
    sta reg4
    rts

    lda #$23
    sta reg4
    lda #$e0
    sta reg4

    ldx #32
*   sty reg5
    dex
    bne -

    lda #$2b
    sta reg4
    lda #$e0
    sta reg4

    ldx #32
*   sty reg5
    dex
    bne -

    lda #$00
    sta reg4
    sta reg4
    rts

; -----------------------------------------------------------------------------

sub58:

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

    ldx #0
    ldy #0  ; why?
*   lda $8e
    sta reg5
    sta reg5
    sta reg5
    sta reg5
    inx
    bne -

    lda #$28
    sta reg4
    lda #$00
    sta reg4

    ldx #0
    ldy #0  ; why?
*   lda $8e
    sta reg5
    sta reg5
    sta reg5
    sta reg5
    inx
    bne -

    lda #$01
    sta $02
    lda #$00
    sta reg4
    sta reg4
    rts

; -----------------------------------------------------------------------------

sub59:

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

*   lda #$00
    sta reg5
    inx
    cpx #64
    bne -

    lda #$27
    sta reg4
    lda #$c0
    sta reg4
    ldx #$00

*   lda #$00
    sta reg5
    inx
    cpx #64
    bne -

    lda #$20
    sta reg4
    lda #$00
    sta reg4
    ldx #$00
    ldy #$00

*   lda $8e
    sta reg5
    inx
    bne -

*   lda $8e
    sta reg5
    inx
    bne -

*   lda $8e
    sta reg5
    inx
    bne -

*   lda $8e
    sta reg5
    inx
    cpx #192
    bne -

    lda #$24
    sta reg4
    lda #$00
    sta reg4
    ldx #$00
    ldy #$00

*   lda $8e
    sta reg5
    inx
    bne -

*   lda $8e
    sta reg5
    inx
    bne -

*   lda $8e
    sta reg5
    inx
    bne -

*   lda $8e
    sta reg5
    inx
    cpx #192
    bne -

    lda #$28
    sta reg4
    lda #$00
    sta reg4
    ldx #$00
    ldy #$00

*   lda $8e
    sta reg5
    inx
    bne -

*   lda $8e
    sta reg5
    inx
    bne -

*   lda $8e
    sta reg5
    inx
    bne -

*   lda $8e
    sta reg5
    inx
    cpx #192
    bne -

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
