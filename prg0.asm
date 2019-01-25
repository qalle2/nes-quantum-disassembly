    ; first half of PRG ROM

    jmp sub12
    jmp sub13

    sei
    cld
    ldx #$ff
    txs

    lda #%01000000
    sta ppu_ctrl
    lda #%10011110
    sta ppu_mask

    lda ppu_status
    lda ppu_status

    lda #%00000000
    sta ppu_mask

    lda #<indirect_data1
    ldx #>indirect_data1
    jsr sub01

    lda #%00011110
    sta ppu_mask
    lda #%10000000
    sta ppu_ctrl

*   jmp -

; -----------------------------------------------------------------------------

sub01:
    ; Args: A = pointer low, X = pointer high
    ; Called by: $8000, sub13

    sta ptr4+0
    stx ptr4+1

    ; ptr4 + 16 -> ptr6
    lda #16
    `add_mem ptr4+0
    sta ptr6+0
    lda ptr4+1
    adc #0
    sta ptr6+1

    ; [ptr4 + 3] -> $d3
    ldy #3
    lda (ptr4),y
    sta $d3
    ; [ptr4 + 4] -> $d7
    iny
    lda (ptr4),y
    sta $d7
    ; [ptr4 + 7] -> $d6
    iny
    iny
    iny
    lda (ptr4),y
    sta $d6

    ; [ptr4 + 8...12] -> $03e0...$03e4
    iny
    lda (ptr4),y
    sta $03e0
    iny
    lda (ptr4),y
    sta $03e1
    iny
    lda (ptr4),y
    sta $03e2
    iny
    lda (ptr4),y
    sta $03e3
    iny
    lda (ptr4),y
    sta $03e4

    ; [$80] + 16 -> $cb
    `iny4
    tya
    `add_imm $80
    sta $cb

    ; ptr4 + [$cb] -> ptr5
    lda ptr4+0
    adc $cb
    sta ptr5+0
    lda ptr4+1
    adc #0
    sta ptr5+1

    lda $d6
    asl
    asl
    adc $cb
    sta $cb
    lda #0
    adc #0
    sta $cc

    lda ptr4+0
    adc $cb
    sta $0364
    lda ptr4+1
    adc $cc
    sta $0369

    lda $03e0
    asl
    adc $0364
    sta $0365
    lda #0
    adc $0369
    sta $036a

    lda $03e1
    asl
    adc $0365
    sta $0366
    lda #0
    adc $036a
    sta $036b

    lda $03e2
    asl
    adc $0366
    sta $0367
    lda #0
    adc $036b
    sta $036c

    lda $03e3
    asl
    adc $0367
    sta $0368
    lda #0
    adc $036c
    sta $036d

    ; clear dc-df, e5-ec,
    ; 300-303, 308-30b, 310-31b, 320-347, 34c-34f, 350-353,
    ; 355-358, 35a-35d, 35f-362, 394-39f, 3a4-3a7
    lda #$00
    ldx #3
*   sta $0300,x  ; start loop
    sta $dc,x
    sta $0308,x
    sta $e9,x
    sta $0310,x
    sta $0314,x
    sta $0318,x
    sta $0394,x
    sta $0324,x
    sta $0320,x
    sta $0398,x
    sta $0328,x
    sta $03a4,x
    sta $032c,x
    sta $0330,x
    sta $0334,x
    sta $0338,x
    sta $033c,x
    sta $0340,x
    sta $0344,x
    sta $e5,x
    sta $034c,x
    sta $0350,x
    sta $0355,x
    sta $035a,x
    sta $035f,x
    sta $039c,x
    dex
    bpl -

    sta $d4
    sta $d5
    sta $ef
    sta apu_ctrl
    ldx $d3
    inx
    stx $d2
    rts

; -----------------------------------------------------------------------------

sub02:

    cmp #0
    bpl +
    lda #0
*   cmp #63
    bcc +
    lda #63
*   lsr
    lsr
    ora $0394,x
    ldy apu_reg_offsets,x
    sta pulse1_ctrl,y
    rts

; -----------------------------------------------------------------------------

sub03:

    cpx #3
    beq sub03_1
    cpx #2
    beq sub03_2
    ldy apu_reg_offsets,x
    sta pulse1_timer,y
    lda #$08
    sta pulse1_sweep,y
    lda $cb
    cmp $03ac,x
    beq +
    sta $03ac,x
    ora #%00001000
    sta pulse1_length,y
*   rts

sub03_1:
    and #%00001111
    ora $034c,x
    sta noise_period
    lda #$08
    sta noise_length
    rts

sub03_2:
    ldy apu_reg_offsets,x
    sta pulse1_timer,y
    lda $cb
    ora #%00001000
    sta pulse1_length,y
    rts

; -----------------------------------------------------------------------------

sub04:

    lda $d3
    beq sub04_4
    inc $d2
    cmp $d2
    beq +
    bpl sub04_2
*   lda #$00
    sta $d2
    lda $d4
    cmp #$40
    bcc sub04_1
    lda #$00
    sta $d4
    ldx $d5
    inx
    cpx $d6
    bcc +
    ldx $d7
*   stx $d5
sub04_1:
    jmp sub10_05

sub04_2:
    lda #$06
    ldx #3

sub04_loop1:
    lda $e5,x
    bmi sub04_3
    `sub_imm 1
    bpl +
    lda table03,x
    and $ef
    sta $ef
    lda #$00
*   sta $e5,x
sub04_3:
    cpx #$02
    bne +
    lda #$ff
    sta triangle_ctrl
*   dex
    bpl sub04_loop1

    lda apu_ctrl
    and #%00010000
    bne +
    lda $ef
    and #%00001111
    sta $ef
*   lda $ef
    sta apu_ctrl
    ldx #3

sub04_loop2:
    cpx #2
    beq +
    jsr sub05
*   jsr sub07
    dex
    bpl sub04_loop2

sub04_4:
    inc $039c
    inc $039d
    inc $039e
    inc $039f
    rts

; -----------------------------------------------------------------------------

sub05:

    lda $035a,x
    cmp #$0a
    bne sub05_2
    lda $035f,x
    beq +
    sta $0324,x
*   lda $0324,x
    tay
    and #%11110000
    beq +
    `lsr4
    adc $0300,x
    sta $0300,x
    jmp sub05_1
*   tya
    and #%00001111
    eor #%11111111
    sec
    adc $0300,x
    sta $0300,x
sub05_1:
*   jmp +

sub05_2:
    lda $0320,x
    beq +
    clc
    adc $0300,x
    sta $0300,x
*   ldy $035a,x
    cpy #$07
    bne sub05_3
    lda $035f,x
    beq +
    sta $0340,x
*   lda $0340,x
    bne sub05_4
sub05_3:
    lda $0344,x
    bne sub05_4
    lda $0300,x
    bpl +
    lda #$00
*   cmp #$3f
    bcc +
    lda #$3f
*   sta $0300,x
    jmp sub02

sub05_4:
    pha
    and #%00001111
    ldy $033c,x
    jsr sub06
    bmi sub05_5
    clc
    adc $0300,x
    jsr sub02
    pla
    `lsr4
    clc
    adc $033c,x
    cmp #$20
    bpl sub05_6
    sta $033c,x
    rts

sub05_5:
    clc
    adc $0300,x
    jsr sub02
    pla
    `lsr4
    clc
    adc $033c,x
    cmp #$20
    bpl sub05_6
    sta $033c,x
    rts

sub05_6:
    `sub_imm $40
    sta $033c,x
    rts

; -----------------------------------------------------------------------------

sub06:

    bmi sub06_1
    dey
    bmi sub06_2
    ora or_masks,y
    tay
    lda table05,y
    clc
    rts

sub06_1:
    pha
    tya
    eor #%11111111
    and #%00011111
    tay
    dey
    pla
    ora or_masks,y
    tay
    lda table05,y
    eor #%11111111
    `add_imm 1
    cmp #$80
    rts

sub06_2:
    lda #$00
    clc
    rts

sub06_3:
    pha
    and #%00001111
    ldy $0330,x
    jsr sub06
    ror
    bmi sub06_4
    clc
    adc $dc,x
    tay
    lda $0308,x
    adc #0
    sta $cb
    tya
    jsr sub03
    pla
    `lsr4
    clc
    adc $0330,x
    cmp #$20
    bpl sub06_5
    sta $0330,x
    rts

sub06_4:
    clc
    adc $dc,x
    tay
    lda $0308,x
    adc #$ff
    sta $cb
    tya
    jsr sub03
    pla
    `lsr4
    clc
    adc $0330,x
    cmp #$20
    bpl sub06_5
    sta $0330,x
    rts

sub06_5:
    `sub_imm $40
    sta $0330,x
    rts

; -----------------------------------------------------------------------------

sub07:

    jsr sub08
    jmp sub07_3

sub07_1:
    ldy $035a,x
    cpy #$04
    bne sub07_2
    lda $035f,x
    beq +
    sta $0334,x
*   lda $0334,x
    bne sub06_3

sub07_2:
    lda $0338,x
    bne sub06_3
    lda $0308,x
    sta $cb
    lda $dc,x
    jmp sub03

sub07_3:
    lda $035a,x
    cmp #$03
    beq sub07_6
    cmp #$01
    beq sub07_4
    cmp #$02
    beq sub07_5
    lda $03a0,x
    bne +
    jmp sub07_1
*   lda $03a0,x
    bmi +
    clc
    adc $dc,x
    sta $dc,x
    lda $0308,x
    adc #0
    sta $0308,x
    jmp sub07_1
*   clc
    adc $dc,x
    sta $dc,x
    lda $0308,x
    adc #$ff
    sta $0308,x
    jmp sub07_1

sub07_4:
    lda $035f,x
    beq +
    sta $0318,x
*   lda $dc,x
    sec
    sbc $0318,x
    sta $dc,x
    lda $0308,x
    sbc #0
    sta $0308,x
    jmp sub07_1

sub07_5:
    lda $035f,x
    beq +
    sta $0318,x
*   lda $dc,x
    clc
    adc $0318,x
    sta $dc,x
    lda $0308,x
    adc #0
    sta $0308,x
    jmp sub07_1

sub07_6:
    lda $0350,x
    beq +
    sta $0314,x
*   lda $035f,x
    beq +
    sta $0318,x
*   ldy $0314,x

    lda word_lo-1,y
    sta ptr2+0
    lda word_hi-1,y
    sta ptr2+1

    sec
    lda $dc,x
    sbc ptr2+0
    lda $0308,x
    sbc ptr2+1
    bmi +
    bpl sub07_7
    jmp sub07_1
*   lda $dc,x
    clc
    adc $0318,x
    sta $dc,x
    lda $0308,x
    adc #0
    sta $0308,x
    sec
    lda $dc,x
    sbc ptr2+0
    lda $0308,x
    sbc ptr2+1
    bpl sub07_8
    jmp sub07_1

sub07_7:
    lda $dc,x
    sec
    sbc $0318,x
    sta $dc,x
    lda $0308,x
    sbc #0
    sta $0308,x
    sec
    lda $dc,x
    sbc ptr2+0
    lda $0308,x
    sbc ptr2+1
    bmi sub07_8
    jmp sub07_1

sub07_8:
    lda ptr2+0
    sta $dc,x
    lda ptr2+1
    sta $0308,x
    jmp sub07_1

; -----------------------------------------------------------------------------

sub08:

    lda $035a,x
    cmp #$08
    beq +
    lda $0328,x
    bne sub08_1
    lda $03a4,x
    bne sub08_1
    lda $032c,x
    bne sub08_1
    rts

*   jmp sub10
sub08_1:
    lda $039c,x
    ldy $03a8,x
    bne +
    and #%00000011
*   cmp #0
    beq +
    cmp #1
    beq sub08_2
    cmp #2
    beq sub08_3
    cmp #3
    beq sub08_4
    rts

*   ldy $e9,x
    lda word_hi-1,y
    sta $0308,x
    sta $cb
    lda word_lo-1,y
    sta $dc,x
    jmp sub03

sub08_2:
    lda $e9,x
    clc
    adc $0328,x
    tay
    lda word_hi-1,y
    sta $0308,x
    sta $cb
    lda word_lo-1,y
    sta $dc,x
    jmp sub03

sub08_3:
    lda $e9,x
    clc
    adc $03a4,x
    tay
    lda word_hi-1,y
    sta $0308,x
    sta $cb
    lda word_lo-1,y
    sta $dc,x
    jmp sub03

sub08_4:
    lda $e9,x
    clc
    adc $032c,x
    tay
    lda word_hi-1,y
    sta $0308,x
    sta $cb
    lda word_lo-1,y
    sta $dc,x
    jmp sub03

sub08_5:
    sta $0300,x
    jmp sub09_1

sub08_6:
    sta $d3
    jmp sub09_1

sub08_7:
    `sub_imm 1
    sta $d4
    lda $d5
    `add_imm 1
    cmp $d6
    bcc +
    lda $d7
*   sta $d5
    jmp sub09_1

; -----------------------------------------------------------------------------

sub09:

    ldy $035a,x
    beq sub09_1

    lda $035f,x
    cpy #$0c
    beq sub08_5
    cpy #$0f
    beq sub08_6
    cpy #$0d
    beq sub08_7

sub09_1:
    lda $035f,x
    cpy #$08
    beq sub09_2

    lda $0328,x
    bne sub09_3

    lda $03a4,x
    bne sub09_3

    lda $032c,x
    bne sub09_3

    lda $0350,x
    beq +

    lda $035a,x
    cmp #$03
    beq +

    lda $0308,x
    sta $cb
    lda $dc,x
    jmp sub03

*   rts

sub09_2:
    jsr sub10
    lda $0308,x
    sta $cb
    lda $dc,x
    jmp sub03

sub09_3:
    jmp sub08_1

; -----------------------------------------------------------------------------

sub10:

    lda $035f,x
    beq +
    sta $0398,x
*   sec
    lda $d2
    beq sub10_01
*   cmp #1       ; start loop
    beq sub10_02
    cmp #2
    beq sub10_03
    sbc #3
    bne -

sub10_01:
    ldy $e9,x
    lda word_lo-1,y
    sta $dc,x
    lda word_hi-1,y
    sta $0308,x
    rts

sub10_02:
    lda $0398,x
    `lsr4
    clc
    adc $e9,x
    tay
    lda word_lo-1,y
    sta $dc,x
    lda word_hi-1,y
    sta $0308,x
    rts

sub10_03:
    lda $0398,x
    and #%00001111
    clc
    adc $e9,x
    tay
    lda word_lo-1,y
    sta $dc,x
    lda word_hi-1,y
    sta $0308,x
    rts

sub10_04:
    lda $031c,x
    sta $e5,x
    lda $03b4,x
    sta $0300,x
    lda table02,x
    ora $ef
    sta $ef
    jmp sub10_11

sub10_05:
    jsr sub11
    ldx #3

sub10_06:
    lda $0355,x
    bne +
    jmp sub10_11
*   cmp $0310,x
    beq sub10_04
    sta $0310,x
    asl
    asl
    asl
    adc #$f8
    tay
    lda (ptr6),y
    iny
    sta $0394,x
    lda (ptr6),y
    iny
    sta $03a0,x
    lda (ptr6),y
    iny
    sta $0338,x
    lda (ptr6),y
    iny
    sta $0344,x
    lda (ptr6),y
    bmi sub10_07
    iny
    and #%01111111
    sta $cb
    lda $0394,x
    asl
    asl
    and #%10000000
    ora $cb
    sta $e5,x
    sta $031c,x
    lda (ptr6),y
    sta $cb
    and #%11110000
    lsr
    lsr
    sta $0300,x
    sta $03b4,x
    lda $cb
    and #%00001111
    eor #%11111111
    `add_imm 1
    sta $0320,x
    jmp sub10_08

sub10_07:
    iny
    and #%01111111
    sta $cb
    lda $0394,x
    asl
    asl
    and #%10000000
    ora $cb
    sta $e5,x
    sta $031c,x
    lda (ptr6),y
    sta $cb
    and #%11110000
    lsr
    lsr
    sta $0300,x
    lda $cb
    and #%00001111
    sta $0320,x

sub10_08:
    iny
    lda (ptr6),y
    iny
    sta $cb
    asl
    and #%10000000
    sta $034c,x
    lda $cb
    and #%00100000
    sta $03a8,x
    lda (ptr6),y
    tay
    and #%00001111
    bcs sub10_09
    sta $0328,x
    tya
    `lsr4
    sta $03a4,x
    lda $cb
    and #%00001111
    sta $032c,x
    jmp sub10_10

sub10_09:
    eor #%11111111
    `add_imm 1
    sta $0328,x
    tya
    `lsr4
    eor #%11111111
    `add_imm 1
    sta $03a4,x
    lda $cb
    and #%00001111
    eor #%11111111
    `add_imm 1
    sta $032c,x

sub10_10:
    lda table02,x
    ora $ef
    sta $ef

sub10_11:
    ldy $0350,x
    beq sub10_13
    cpy #$61
    beq sub10_14
    sty $e9,x

    lda #$00
    sta $039c,x
    sta $033c,x

    lda $031c,x
    sta $e5,x

    lda table02,x
    ora $ef
    sta $ef

    lda $035a,x
    cmp #$03
    beq sub10_13
    lda #$ff
    sta $03ac,x
    lda #$00
    sta $0330,x
    cpx #$03
    beq sub10_15
    lda word_lo-1,y
    sta $dc,x
    lda word_hi-1,y

sub10_12:
    sta $0308,x
    lda table02,x
    ora $ef
    sta $ef

sub10_13:
    dex
    bmi +
    jmp sub10_06
*   jmp sub11_16

sub10_14:
    lda table03,x
    and $ef
    sta $ef
    jmp sub10_13

sub10_15:
    dey
    sty $dc,x
    lda #$00
    jmp sub10_12

sub10_16:
    lda #$00
    sta $038f,x
    jmp sub11_03

; -----------------------------------------------------------------------------

sub11:

    lda #$40
    sta $cd

    ; clear $0350...$0363
    lda #$00
    ldx #4
*   sta $0350,x  ; start loop
    sta $0355,x
    sta $035a,x
    sta $035f,x
    dex
    bpl -

    lda $d4
    bne +
    lda $d2
    bne +
    jmp sub11_01
*   jmp sub11_04
sub11_01:
    lda $d5
    asl
    asl
    tay
    lda (ptr5),y
    iny
    tax
    and #%00011111
    asl
    sta $0304
    lda (ptr5),y
    sta $cb
    lsr
    sty $cc
    tay
    and #%00111110
    sta $0306
    txa
    ror
    tax
    tya
    lsr
    txa
    ror
    ror
    ror
    and #%00111110
    sta $0305
    asl $cb
    ldy $cc
    iny
    lda (ptr5),y
    tax
    rol
    asl
    and #%00111110
    sta $0307
    txa
    lsr
    lsr
    lsr
    and #%00111110
    sta $0308

    ldx #4
sub11_loop1:
    lda $0364,x
    sta ptr2+0
    lda $0369,x
    sta ptr2+1
    ldy $0304,x
    lda (ptr2),y
    iny
    cmp #$00
    bne sub11_02
    sta $cb
    lda (ptr2),y
    bne +
    jmp sub10_16
*   lda $cb
sub11_02:
    `add_mem ptr4+0
    sta $036e,x
    sta ptr3+0
    lda (ptr2),y
    adc ptr4+1
    sta $0373,x
    sta ptr3+1

    ldy #0
    lda (ptr3),y
    sta $038a,x
    iny
    lda (ptr3),y
    adc #1
    sta $038f,x

    adc #1
    lsr
    `add_imm 2
    sta $e0,x
    lda #$00
    sta $0378,x

sub11_03:
    dex
    bpl sub11_loop1

sub11_04:
    ldx #4

sub11_05:
    dec $038f,x
    bmi +
    dec $038a,x
    bpl +
    jmp sub11_06
*   jmp sub11_15
sub11_06:
    lda $036e,x
    sta ptr2+0
    lda $0373,x
    sta ptr2+1
    lda $d4
    lsr
    tay
    iny
    iny
    lda (ptr2),y
    bcc +
    `lsr4
*   ldy $0378,x
    sty $cb
    bit $cb
    ldy $e0,x
    lsr
    sta $cb
    bcc sub11_09

    cpx #$03
    beq sub11_07

    bvs +

    lda (ptr2),y
    iny
    jmp sub11_08

*   lda (ptr2),y
    and #%11110000
    sta $cc
    iny
    lda (ptr2),y
    and #%00001111
    ora $cc
    jmp sub11_08

sub11_07:
    bvs +
    lda (ptr2),y
    and #%00001111
    sbc #$ff
    bit $cd
    jmp sub11_08
*   lda (ptr2),y
    `lsr4
    `add_imm 1
    iny
    clv

sub11_08:
    sta $0350,x

sub11_09:
    lsr $cb
    bcc sub11_10
    bvs +
    lda (ptr2),y
    and #%00001111
    adc #0
    sta $0355,x
    bit $cd
    jmp sub11_10
*   lda (ptr2),y
    `lsr4
    iny
    `add_imm 1
    sta $0355,x
    clv
sub11_10:
    lsr $cb
    bcc sub11_12
    bvs +
    lda (ptr2),y
    and #%00001111
    bit $cd
    jmp sub11_11

*   lda (ptr2),y
    `lsr4
    iny
    clv
sub11_11:
    sta $035a,x

sub11_12:
    lsr $cb
    bcc sub11_14
    bvs +
    lda (ptr2),y
    iny
    jmp sub11_13
*   lda (ptr2),y
    and #%11110000
    sta $cc
    iny
    lda (ptr2),y
    and #%00001111
    ora $cc
sub11_13:
    sta $035f,x
sub11_14:
    sty $e0,x
    lda #$40
    bvs +
    lda #$00
*   sta $0378,x

sub11_15:
    dex
    bmi +
    jmp sub11_05
*   rts

sub11_16:
    ldx #3
sub11_loop2:
    ldy $e5,x
    bmi sub11_17
    dey
    bpl +
    lda table03,x
    and $ef
    sta $ef
    lda #$00
    ldy #$00
*   sty $e5,x
sub11_17:
    dex
    bpl sub11_loop2

    lda apu_ctrl
    and #%00010000
    bne +
    lda $ef
    and #%00001111
    sta $ef
*   lda $ef
    sta apu_ctrl

    ldx #3
sub11_loop3:
    jsr sub09
    cpx #$02
    beq sub11_18
    lda $0355,x
    bne +
    lda $035a,x
    cmp #$0c
    beq +
    jmp sub11_18
*   lda $0300,x
    lsr
    lsr
    ora $0394,x
    ldy apu_reg_offsets,x
    sta pulse1_ctrl,y
sub11_18:
    dex
    bpl sub11_loop3

    inc $039c
    inc $039d
    inc $039e
    inc $039f
    inc $d4
    rts

    ldx #0
    ldy #16
*   dex
    bne -
    dey
    bne -

    dec $ff
    bpl +
    lda #$05
    sta $ff
    lda #$1e
*   jsr sub04
    lda #$06
    rti
    rti

; -----------------------------------------------------------------------------

sub12:

    bit $ff
    bmi +
    dec $ff
    bpl +
    lda #$05
    sta $ff
    jmp sub12_exit
*   jmp sub04
sub12_exit:
    rts

; -----------------------------------------------------------------------------

sub13:

    ldy #$ff
    dex
    beq +
    ldy #$05
*   sty $ff
    asl
    tay
    lda pointer_hi,y
    tax
    lda pointer_lo,y
    jsr sub01
    rts

; -----------------------------------------------------------------------------

    .include "data0.asm"
