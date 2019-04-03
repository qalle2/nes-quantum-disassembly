; PRG ROM of Quantum Disco Brothers. Assembles with Ophis.

    .include "macros.asm"
    .include "constants.asm"

    .org $8000

; -----------------------------------------------------------------------------
; Unaccessed block ($8000)

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
    ; Reads indirect_data1 via ptr4
    ; Called by: sub13
    ; Only called once (at frame 3 with indirect_data1 as argument).

    sta ptr4+0
    stx ptr4+1

    ; ptr4 + 16 -> ptr6
    lda #16
    clc
    adc ptr4+0
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
    ; [ptr4 + 8] -> $03e0
    iny
    lda (ptr4),y
    sta $03e0
    ; [ptr4 + 9] -> $03e1
    iny
    lda (ptr4),y
    sta $03e1
    ; [ptr4 + 10] -> $03e2
    iny
    lda (ptr4),y
    sta $03e2
    ; [ptr4 + 11] -> $03e3
    iny
    lda (ptr4),y
    sta $03e3
    ; [ptr4 + 12] -> $03e4
    iny
    lda (ptr4),y
    sta $03e4

    ; 144 -> $cb
    `iny4
    tya
    clc
    adc #128
    sta $cb

    ; ptr4 + $cb -> ptr5
    lda ptr4+0
    adc $cb
    sta ptr5+0
    lda ptr4+1
    adc #0
    sta ptr5+1

    ; $cb += $d6 * 4
    ; carry -> $cc
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
clear_loop:
    sta $0300,x
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
    bpl clear_loop

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
    ; Called by: sub05

    cmp #0
    bpl +    ; always taken
    lda #0   ; unaccessed ($8157)
*   cmp #63
    bcc +    ; always taken
    lda #63  ; unaccessed ($815d)
*   lsr
    lsr
    ora $0394,x
    ldy apu_reg_offsets,x
    sta pulse1_ctrl,y
    rts

; -----------------------------------------------------------------------------

sub03:
    ; Called by: sub06, sub07, sub08, sub09

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
    ; Called by: sub11, sub12

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
    jmp sub10_02

sub04_2:
    lda #$06
    ldx #3

sub04_loop1:
    lda $e5,x
    bmi sub04_3
    sec
    sbc #1
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
    ; Called by: sub04

    lda $035a,x
    cmp #$0a
    bne sub05_2
    lda $035f,x
    beq +
    sta $0324,x
*   lda $0324,x
    tay
    and #%11110000
    beq +           ; always taken

    ; unaccessed ($823b)
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
    bne sub05_3  ; always taken

    ; unaccessed ($826a)
    lda $035f,x
    beq +
    sta $0340,x
*   lda $0340,x
    bne unaccessed1

sub05_3:
    lda $0344,x
    bne unaccessed1  ; never taken
    lda $0300,x
    bpl +
    lda #$00
*   cmp #$3f
    bcc +        ; always taken
    lda #$3f     ; unaccessed ($8287)
*   sta $0300,x
    jmp sub02

; -----------------------------------------------------------------------------
; Unaccessed block ($828f)

unaccessed1:
    pha
    and #%00001111
    ldy $033c,x
    jsr sub06
    bmi unaccessed2
    clc
    adc $0300,x
    jsr sub02
    pla
    `lsr4
    clc
    adc $033c,x
    cmp #$20
    bpl unaccessed3
    sta $033c,x
    rts

unaccessed2:
    clc
    adc $0300,x
    jsr sub02
    pla
    `lsr4
    clc
    adc $033c,x
    cmp #$20
    bpl unaccessed3
    sta $033c,x
    rts

unaccessed3:
    sec
    sbc #$40
    sta $033c,x
    rts

; -----------------------------------------------------------------------------

sub06:
    ; Called by: sub05, sub07

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
    clc
    adc #1
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
    sec
    sbc #$40
    sta $0330,x
    rts

; -----------------------------------------------------------------------------

sub07:
    ; Called by: sub04

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
    bne +        ; never taken
    jmp sub07_1

    ; unaccessed block ($838e)
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
    bpl sub07_7  ; always taken
    jmp sub07_1  ; unaccessed ($8414)
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
    bpl sub07_8  ; always taken
    jmp sub07_1  ; unaccessed ($8433)

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
    ; Called by: sub07, sub09

    lda $035a,x
    cmp #$08
    beq +        ; never taken
    lda $0328,x
    bne sub08_1
    lda $03a4,x
    bne sub08_1
    lda $032c,x
    bne sub08_1
    rts

*   jmp unaccessed6  ; unaccessed ($8478)

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
    beq sub08_4  ; always taken
    rts          ; unaccessed ($8495)

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

; -----------------------------------------------------------------------------
; Unaccessed block ($84f8)

unaccessed4:
    sec
    sbc #1
    sta $d4
    lda $d5
    clc
    adc #1
    cmp $d6
    bcc +
    lda $d7
*   sta $d5
    jmp sub09_1

; -----------------------------------------------------------------------------

sub09:
    ; Called by: sub08, sub11

    ldy $035a,x
    beq sub09_1

    lda $035f,x
    cpy #$0c
    beq sub08_5
    cpy #$0f
    beq sub08_6
    cpy #$0d
    beq unaccessed4  ; never taken

sub09_1:
    lda $035f,x
    cpy #$08
    beq unaccessed5  ; never taken

    lda $0328,x
    bne sub09_3

    lda $03a4,x
    bne sub09_3

    lda $032c,x
    bne sub09_3

    lda $0350,x
    beq +

    lda $035a,x
    cmp #3
    beq +

    lda $0308,x
    sta $cb
    lda $dc,x
    jmp sub03

*   rts

    ; unaccessed block ($854e)
unaccessed5:
    jsr unaccessed6
    lda $0308,x
    sta $cb
    lda $dc,x
    jmp sub03

sub09_3:
    jmp sub08_1

; -----------------------------------------------------------------------------
; Unaccessed block ($855e)

unaccessed6:
    lda $035f,x
    beq +
    sta $0398,x
*   sec
    lda $d2
    beq unaccessed8

unaccessed7:
    cmp #1
    beq unaccessed9
    cmp #2
    beq unaccessed10
    sbc #3
    bne unaccessed7

unaccessed8:
    ldy $e9,x
    lda word_lo-1,y
    sta $dc,x
    lda word_hi-1,y
    sta $0308,x
    rts

unaccessed9:
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

unaccessed10:
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

; -----------------------------------------------------------------------------

    ; Reads indirect_data1 via ptr6
    ; Called by: sub04, sub11

sub10_01:
    lda $031c,x
    sta $e5,x
    lda $03b4,x
    sta $0300,x
    lda table02,x
    ora $ef
    sta $ef
    jmp sub10_06

sub10_02:
    jsr sub11

    ldx #3
sub10_03:
    lda $0355,x
    bne +
    jmp sub10_06
*   cmp $0310,x
    beq sub10_01
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
    bmi unaccessed11
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
    clc
    adc #1
    sta $0320,x
    jmp sub10_04

    ; unaccessed block ($862d)
unaccessed11:
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

sub10_04:
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
    bcs unaccessed12
    sta $0328,x
    tya
    `lsr4
    sta $03a4,x
    lda $cb
    and #%00001111
    sta $032c,x
    jmp sub10_05

    ; unaccessed block ($8681)
unaccessed12:
    eor #%11111111
    clc
    adc #1
    sta $0328,x
    tya
    `lsr4
    eor #%11111111
    clc
    adc #1
    sta $03a4,x
    lda $cb
    and #%00001111
    eor #%11111111
    clc
    adc #1
    sta $032c,x

sub10_05:
    lda table02,x
    ora $ef
    sta $ef

sub10_06:
    ldy $0350,x
    beq sub10_08
    cpy #$61
    beq sub10_09
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
    beq sub10_08
    lda #$ff
    sta $03ac,x
    lda #$00
    sta $0330,x
    cpx #$03
    beq sub10_10
    lda word_lo-1,y
    sta $dc,x
    lda word_hi-1,y

sub10_07:
    sta $0308,x
    lda table02,x
    ora $ef
    sta $ef

sub10_08:
    dex
    bmi +
    jmp sub10_03
*   jmp sub11_16

sub10_09:
    lda table03,x
    and $ef
    sta $ef
    jmp sub10_08

sub10_10:
    dey
    sty $dc,x
    lda #$00
    jmp sub10_07

sub10_11:
    lda #$00
    sta $038f,x
    jmp sub11_03

; -----------------------------------------------------------------------------

sub11:
    ; Reads indirect_data1 via ptr2, ptr3, ptr5
    ; Called by: sub10

    lda #$40
    sta $cd

    ; clear $0350-$0363
    lda #$00
    ldx #4
sub11_loop1:
    sta $0350,x
    sta $0355,x
    sta $035a,x
    sta $035f,x
    dex
    bpl sub11_loop1

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
sub11_loop2:
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
    bne +         ; never taken
    jmp sub10_11
*   lda $cb       ; unaccessed ($8798)
sub11_02:
    clc
    adc ptr4+0
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
    clc
    adc #2
    sta $e0,x
    lda #$00
    sta $0378,x

sub11_03:
    dex
    bpl sub11_loop2

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
    clc
    adc #1
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
    clc
    adc #1
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
sub11_loop3:
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
    bpl sub11_loop3

    lda apu_ctrl
    and #%00010000
    bne +
    lda $ef
    and #%00001111
    sta $ef
*   lda $ef
    sta apu_ctrl

    ldx #3
sub11_loop4:
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
    bpl sub11_loop4

    inc $039c
    inc $039d
    inc $039e
    inc $039f
    inc $d4
    rts

; -----------------------------------------------------------------------------
; Unaccessed block ($8906)

    ldx #0
    ldy #16
unaccessed13:
    dex
    bne unaccessed13
    dey
    bne unaccessed13

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
    ; Called by: nmisub06, nmisub10, nmisub14, NMI

    bit $ff
    bmi sub12_skip  ; always taken

    ; unaccessed block ($8925)
    dec $ff
    bpl sub12_skip
    lda #$05
    sta $ff
    jmp unaccessed14

sub12_skip:
    jmp sub04

unaccessed14:
    rts  ; unaccessed ($8933)

; -----------------------------------------------------------------------------

sub13:
    ; Called by: init

    ldy #$ff
    dex
    beq +
    ldy #$05  ; unaccessed ($8939)
*   sty $ff
    asl
    tay

    lda pointer_hi,y
    tax
    lda pointer_lo,y
    jsr sub01  ; A = pointer low, X = pointer high
    rts

; -----------------------------------------------------------------------------

    .include "data0.asm"

    ; The program continues at the next 16-KiB boundary for some reason.
    ; (Technically, there is only one 32-KiB PRG ROM bank.)
    .advance $c000, pad_byte

; -----------------------------------------------------------------------------

init:
    ; Called by: reset vector

    sei
    cld
    jsr wait_vbl

    ; clear RAM
    ldx #0
    txa
ram_clear_loop:
    sta $00,x
    sta $0100,x
    sta $0200,x
    sta $0300,x
    sta $0400,x
    sta sprite_page,x
    sta $0600,x
    sta $0700,x
    inx
    bne ram_clear_loop

    jsr hide_sprites
    jsr init_palette_copy
    jsr update_palette

    ; update fourth sprite subpalette
    `set_ppu_addr vram_palette+7*4
    `write_ppu_data $0f  ; black
    `write_ppu_data $1c  ; medium-dark cyan
    `write_ppu_data $2b  ; medium-light green
    `write_ppu_data $39  ; light yellow
    `reset_ppu_addr

    ; the demo part to run
    lda #0
    sta demo_part

    lda #%00000000
    sta ppu_ctrl
    lda #%00011110
    sta ppu_mask

    ldx #$ff
    jsr fill_nt_and_clear_at
    jsr sub18

    lda #%00000000
    sta ppu_ctrl
    sta ppu_mask

    ldy #$00
    jsr fill_attribute_tables
    lda #$ff
    sta pulse1_ctrl

    `reset_ppu_addr

    lda #$00
    ldx #$01
    jsr sub13
    jsr wait_vbl

    lda #%10000000
    sta ppu_ctrl
    lda #%00011110
    sta ppu_mask

*   lda demo_part
    cmp #9  ; last part?
    bne +
    lda #$0d
    sta dmc_addr
    lda #$fa
    sta dmc_length
*   jmp --

; -----------------------------------------------------------------------------

    .include "data1.asm"

; -----------------------------------------------------------------------------

wait_vbl:
    ; Wait for VBlank.
    ; Called by: init

*   bit ppu_status
    bpl -
    rts

; -----------------------------------------------------------------------------

hide_sprites:
    ; Hide all sprites by setting their Y positions outside the screen.
    ; Called by: init, nmisub10, nmisub12, nmisub13, nmisub14, nmisub15
    ; nmisub16, nmisub20, nmisub22

    ldx #0
hide_sprites_loop:
    lda #245
    sta sprite_page+sprite_y,x
    `inx4
    bne hide_sprites_loop
    rts

; -----------------------------------------------------------------------------
; Unaccessed block ($dcaa)

    lda #%00000000
    sta ppu_ctrl
    sta ppu_mask
    lda #%00000000
    sta ppu_ctrl

    lda #$00
    ldx #0
clear_snd_reg_loop:
    sta apu_regs,x
    inx
    cpx #15
    bne clear_snd_reg_loop

    lda #$c0
    sta apu_counter

    jsr init_palette_copy
    jsr update_palette
    rts

; -----------------------------------------------------------------------------

init_palette_copy:
    ; Copy the palette_table array to the palette_copy array.
    ; Args: none
    ; Called by: init, hide_sprites, nmisub06, nmisub08, nmisub10, nmisub12,
    ; nmisub15, game_over_screen, nmisub19

    ldx #0
init_palette_copy_loop:
    lda palette_table,x
    sta palette_copy,x
    inx
    cpx #32
    bne init_palette_copy_loop
    rts

; -----------------------------------------------------------------------------

clear_palette_copy:
    ; Fill the palette_copy array with black.
    ; Args: none
    ; Called by: greets_screen

    ldx #0
clear_palette_copy_loop:
    lda #$0f
    sta palette_copy,x
    inx
    cpx #32
    bne clear_palette_copy_loop
    rts

; -----------------------------------------------------------------------------

update_palette:
    ; Copy the palette_copy array to the PPU.
    ; Args: none
    ; Called by: init, hide_sprites, nmisub03, nmisub06, nmisub08, nmisub10,
    ; nmisub12, nmisub13, nmisub15, game_over_screen, greets_screen, nmisub19

    `set_ppu_addr vram_palette+0*4

    ldx #0
update_palette_loop:
    lda palette_copy,x
    sta ppu_data
    inx
    cpx #32
    bne update_palette_loop

    `reset_ppu_addr
    rts

; -----------------------------------------------------------------------------

sub14:
    ; Called by: nmisub07, nmisub11, nmisub15, nmisub21

    stx $88
    lda #0
    sta $87
sub14_loop1:
    lda $86
    clc
    adc #$55
    bcc +
*   sta $86
    inc $87
    lda $87
    cmp $88
    bne sub14_loop1

    rts

; -----------------------------------------------------------------------------
; Unaccessed block ($dd22)

    stx $88
    ldx #0
unaccessed15:
    clc
    adc #$55
    clc
    nop
    nop
    adc #15
    sbc #15
    inx
    cpx $88
    bne unaccessed15

    rts

    stx $88
    ldy #0
    ldx #0
unaccessed16:

    ldy #0
unaccessed17:
    nop
    nop
    nop
    nop
    nop
    iny
    cpy #11
    bne unaccessed17

    nop
    inx
    cpx $88
    bne unaccessed16

    rts

; -----------------------------------------------------------------------------

fade_out_palette:
    ; Change each color in the palette_copy array (32 bytes).
    ; Used to fade out the "wAMMA - QUANTUM DISCO BROTHERS" logo.
    ; Called by: nmisub03, nmisub13, nmisub19

    ; How the colors are changed:
    ;     $0x -> $0f (black)
    ;     $1x: no change
    ;     $2x -> $3x
    ;     $3x: no change

    ldy #0
fade_out_palette_loop:
    ; take color
    lda palette_copy,y
    sta temp1
    ; copy color brightness (0-3) to X
    and #%00110000
    `lsr4
    tax
    ; take color hue (0-15)
    lda temp1
    and #%00001111
    ; change color
    ora color_or_table,x  ; $0f, $00, $10, $20
    sta palette_copy,y
    ; Y += 1, loop until 32
    iny
    cpy #32
    bne fade_out_palette_loop

    rts

; -----------------------------------------------------------------------------

change_background_color:
    ; Change background color: #$3f (black) if $e8 < 8, otherwise $e8.

    `set_ppu_addr vram_palette+0*4

    lda $e8
    cmp #8
    bcc change_background_black

    lda $e8
    sta ppu_data
    jmp change_background_exit

change_background_black:
    `write_ppu_data $3f  ; black
change_background_exit:
    rts

; -----------------------------------------------------------------------------

update_sixteen_sprites:
    ; Update 16 (8*2) sprites.
    ; Called by: nmisub13

    ; Input: X, Y, $9a, $a8

    ; Modifies: A, X, Y, $9a, $9c, $a5, $a6, $a7, $a8, loopcnt

    ; Sprite page offsets: $a8*4 ... ($a8+15)*4
    ; Tiles: $9a ... $9a+15
    ; X positions: X+0, X+8, ..., X+56, X+0, X+8, ..., X+56
    ; Y positions: Y for first 8 sprites, Y+8 for the rest
    ; Subpalette: always 3

    ; X   -> $a5
    ; Y   -> $a6
    ; $9a -> $a7
    ; 0   -> $9a, loopcnt, $9c
    stx $a5
    sty $a6
    lda $9a
    sta $a7
    lda #$00
    sta $9a
    sta loopcnt
    sta $9c

update_sixteen_sprites_loop_outer:
    ; counter: loopcnt = 0, 8

    ; 0 -> X, $9a
    ldx #0
    lda #$00
    sta $9a

update_sixteen_sprites_loop_inner:
    ; counter: X = 0, 8, ..., 56

    ; update sprite at offset $a8

    ; $a7 + $9c -> sprite tile
    lda $9c
    clc
    adc $a7
    ldy $a8
    sta sprite_page+sprite_tile,y

    ; $a5 + X -> sprite X
    txa
    adc $a5
    ldy $a8
    sta sprite_page+sprite_x,y

    ; $a6 + loopcnt -> sprite Y
    lda loopcnt
    clc
    adc $a6
    ldy $a8
    sta sprite_page+sprite_y,y

    ; 3 -> sprite subpalette
    lda #%00000011
    ldy $a8
    sta sprite_page+sprite_attr,y

    ; $9a += 4
    lda $9a
    clc
    adc #4
    sta $9a

    ; $9c += 1
    inc $9c

    ; Y + 4 -> $a8
    `iny4
    sty $a8

    ; X += 8
    ; loop while less than 64
    txa
    clc
    adc #8
    tax
    cpx #64
    bne update_sixteen_sprites_loop_inner

    ; loopcnt += 8
    ; loop while less than 16
    lda loopcnt
    clc
    adc #8
    sta loopcnt
    lda loopcnt
    cmp #16
    bne update_sixteen_sprites_loop_outer

    ; Y -> $a8
    sty $a8
    rts

; -----------------------------------------------------------------------------

update_six_sprites:
    ; Update 6 (3*2) sprites.
    ; Called by: nmisub13

    ; Input: X, Y, $9a, $a8

    ; Sprite page offsets: $a8*4 ... ($a8+5)*4
    ; Tiles: $9a ... $9a+5
    ; X positions: X+0, X+8, X+16, X+0, X+8, X+16
    ; Y positions: Y+0, Y+0, Y+0, Y+8, Y+8, Y+8
    ; Subpalette: always 2

    ; X   -> $a5
    ; Y   -> $a6
    ; $9a -> $a7
    ; 0   -> $9a, loopcnt, $9c
    stx $a5
    sty $a6
    lda $9a
    sta $a7
    lda #$00
    sta $9a
    sta loopcnt
    sta $9c

update_six_sprites_loop_outer:
    ; counter: loopcnt = 0, 8

    ; 0 -> X, $9a
    ldx #0
    lda #$00
    sta $9a

update_six_sprites_loop_inner:
    ; counter: X = 0, 8, 16

    ; update sprite at offset $a8

    ; $a7 + $9c -> sprite tile
    lda $9c
    clc
    adc $a7
    ldy $a8
    sta sprite_page+sprite_tile,y

    ; $a5 + X -> sprite X
    txa
    adc $a5
    ldy $a8
    sta sprite_page+sprite_x,y

    ; $a6 + loopcnt -> sprite Y
    lda loopcnt
    clc
    adc $a6
    ldy $a8
    sta sprite_page+sprite_y,y

    ; 2 -> sprite subpalette
    lda #%00000010
    ldy $a8
    sta sprite_page+sprite_attr,y

    ; $9a += 4
    lda $9a
    clc
    adc #4
    sta $9a

    ; $9c += 1
    inc $9c

    ; Y + 4 -> $a8
    `iny4
    sty $a8

    ; X += 8
    ; loop while less than 24
    txa
    clc
    adc #8
    tax
    cpx #24
    bne update_six_sprites_loop_inner

    ; loopcnt += 8
    ; loop while less than 16
    lda loopcnt
    clc
    adc #8
    sta loopcnt
    lda loopcnt
    cmp #16
    bne update_six_sprites_loop_outer

    ; Y -> $a8
    sty $a8
    rts

; -----------------------------------------------------------------------------

update_eight_sprites:
    ; Update 8 (4*2) sprites.
    ; Called by: nmisub13

    ; Input: X, Y, $9a, $a8

    ; Sprite page offsets: $a8*4 ... ($a8+7)*4
    ; Tiles: $9a ... $9a+7
    ; X positions: X+0, X+8, ..., X+24, X+0, X+8, ..., X+24
    ; Y positions: Y+0 for first 4 sprites, Y+8 for the rest
    ; Subpalette: always 2

    ; X   -> $a5
    ; Y   -> $a6
    ; $9a -> $a7
    ; 0   -> $9a, loopcnt, $9c
    stx $a5
    sty $a6
    lda $9a
    sta $a7
    lda #$00
    sta $9a
    sta loopcnt
    sta $9c

update_eight_sprites_loop_outer:
    ; counter: loopcnt = 0, 8

    ; 0 -> X, $9a
    ldx #0
    lda #$00
    sta $9a

update_eight_sprites_loop_inner:
    ; counter: X = 0, 8, 16, 24

    ; update sprite at offset $a8

    ; $a7 + $9c -> sprite tile
    lda $9c
    clc
    adc $a7
    ldy $a8
    sta sprite_page+sprite_tile,y

    ; $a5 + X -> sprite X
    txa
    adc $a5
    ldy $a8
    sta sprite_page+sprite_x,y

    ; $a6 + loopcnt -> sprite Y
    lda loopcnt
    clc
    adc $a6
    ldy $a8
    sta sprite_page+sprite_y,y

    ; 2 -> sprite subpalette
    lda #%00000010
    ldy $a8
    sta sprite_page+sprite_attr,y

    ; $9a += 4
    lda $9a
    clc
    adc #4
    sta $9a

    ; $9c += 1
    inc $9c

    ; Y + 4 -> $a8
    `iny4
    sty $a8

    ; X += 8
    ; loop while less than 32
    txa
    clc
    adc #8
    tax
    cpx #32
    bne update_eight_sprites_loop_inner

    ; loopcnt += 8
    ; loop while less than 16
    lda loopcnt
    clc
    adc #8
    sta loopcnt
    lda loopcnt
    cmp #16
    bne update_eight_sprites_loop_outer

    ; Y -> $a8
    sty $a8
    rts

; -----------------------------------------------------------------------------

sub15:
    ; Called by: nmisub03

    ldx #0
    ldy #0
    stx $9a
    stx $9b

sub15_loop:
    lda table10,y
    cmp #$ff
    bne +

    lda $9b
    clc
    adc #14
    sta $9b
    jmp sub15_1

*   lda #$e1
    clc
    adc $9b
    sta sprite_page+sprite_y,x
    sta $0154,y
    lda $9b
    sta $016a,y
    lda #$01
    sta $0180,y
    lda table10,y
    sta sprite_page+sprite_tile,x
    lda #$00
    sta sprite_page+sprite_attr,x
    lda $9a
    clc
    adc #40
    sta sprite_page+sprite_x,x

sub15_1:
    `inx4
    iny
    lda $9a
    clc
    adc #8
    sta $9a
    cpy #22
    bne sub15_loop

    rts

; -----------------------------------------------------------------------------

sub16:
    ; Called by: nmisub01

    stx $91
    sty $92

    lda $91
    sta ppu_addr
    lda $92
    sta ppu_addr

    ldx #$00
    ldy #$00
    stx $90

sub16_loop1:
    ldy $90
    lda (ptr1),y
    clc
    sbc #$40
    tay
    ldx table17,y
    stx ppu_data
    inx
    stx ppu_data
    inc $90
    lda $90
    cmp #$10
    bne sub16_loop1

    lda #$00
    sta $90

sub16_loop2:
    ldy $90
    lda (ptr1),y
    clc
    sbc #$40
    tay
    ldx table17,y
    txa
    clc
    adc #16
    tax
    stx ppu_data
    inx
    stx ppu_data
    inc $90
    lda $90
    cmp #$10
    bne sub16_loop2

    `reset_ppu_addr
    rts

; -----------------------------------------------------------------------------

sub17:
    ; Called by: nmisub01, nmisub03

    lda #$00
    sta $9a

    ldx data8
sub17_loop:
    txa
    asl
    asl
    tay

    lda sprite_page+45*4+sprite_y,y
    clc
    sbc table46,x
    sta sprite_page+45*4+sprite_y,y

    dex
    cpx #255
    bne sub17_loop

    rts

; -----------------------------------------------------------------------------

sub18:
    ; Called by: init

    ldx data8
sub18_loop:
    txa
    asl
    asl
    tay

    lda table45,x
    sta sprite_page+45*4+sprite_y,y

    lda table47,x
    sta sprite_page+45*4+sprite_tile,y

    lda #%00000011
    sta sprite_page+45*4+sprite_attr,y

    lda table44,x
    sta sprite_page+45*4+sprite_x,y

    lda table46,x
    sta $011e,x

    dex
    cpx #255
    bne sub18_loop

    rts

; -----------------------------------------------------------------------------

nmisub01:
    ; Called by: NMI

    `chr_bankswitch 0
    lda $95

    cmp #1
    beq nmisub01_jump_table+1*3
    cmp #2
    beq nmisub01_jump_table+2*3
    cmp #3
    beq nmisub01_jump_table+3*3
    cmp #4
    beq nmisub01_jump_table+4*3
    cmp #5
    beq nmisub01_jump_table+5*3
    cmp #6
    beq nmisub01_jump_table+6*3
    cmp #7
    beq nmisub01_jump_table+7*3
    cmp #8
    beq nmisub01_jump_table+8*3
    cmp #9
    beq nmisub01_01
    cmp #10
    beq nmisub01_jump_table+10*3
    jmp nmisub01_11

nmisub01_01:
    lda #0
    sta ppu_scroll
    ldx $96
    lda table19,x
    clc
    adc $96
    sta ppu_scroll

    lda $96
    cmp #$dc
    bne +
    jmp ++
*   inc $96
    inc $96

*   lda #%10000000
    sta ppu_ctrl
    lda #%00011110
    sta ppu_mask

nmisub01_jump_table:
    jmp nmisub01_11  ;  0*3
    jmp nmisub01_02  ;  1*3
    jmp nmisub01_03  ;  2*3
    jmp nmisub01_04  ;  3*3
    jmp nmisub01_05  ;  4*3
    jmp nmisub01_06  ;  5*3
    jmp nmisub01_07  ;  6*3
    jmp nmisub01_08  ;  7*3
    jmp nmisub01_09  ;  8*3
    jmp nmisub01_11  ;  9*3 (unaccessed, $e013)
    jmp nmisub01_10  ; 10*3

nmisub01_02:
    ; pointer 0 -> ptr1
    lda pointers+0*2+0
    sta ptr1+0
    lda pointers+0*2+1
    sta ptr1+1

    ldx #$20
    ldy #$00
    jsr sub16

    lda #0
    sta ppu_scroll
    lda $96
    sta ppu_scroll

    dec $96
    lda $96
    cmp #$f0
    bcs +
    jmp nmisub01_11
*   lda #$00
    sta $96
    jmp nmisub01_11

nmisub01_03:
    lda #$00
    sta $96
    jmp nmisub01_11

nmisub01_04:
    ; pointer 1 -> ptr1
    lda pointers+1*2+0
    sta ptr1+0
    lda pointers+1*2+1
    sta ptr1+1

    ldx #$20
    ldy #$a0
    jsr sub16
    jmp nmisub01_11

nmisub01_05:
    ; pointer 2 -> ptr1
    lda pointers+2*2+0
    sta ptr1+0
    lda pointers+2*2+1
    sta ptr1+1

    ldx #$21
    ldy #$20
    jsr sub16
    jmp nmisub01_11

nmisub01_06:
    ; pointer 3 -> ptr1
    lda pointers+3*2+0
    sta ptr1+0
    lda pointers+3*2+1
    sta ptr1+1

    ldx #$21
    ldy #$a0
    jsr sub16
    jmp nmisub01_11

nmisub01_07:
    ; pointer 4 -> ptr1
    lda pointers+4*2+0
    sta ptr1+0
    lda pointers+4*2+1
    sta ptr1+1

    ldx #$22
    ldy #$40
    jsr sub16
    jmp nmisub01_11

nmisub01_08:
    ; pointer 5 -> ptr1
    lda pointers+5*2+0
    sta ptr1+0
    lda pointers+5*2+1
    sta ptr1+1

    ldx #$22
    ldy #$c0
    jsr sub16
    jmp nmisub01_11

nmisub01_09:
    ; pointer 6 -> ptr1
    lda pointers+6*2+0
    sta ptr1+0
    lda pointers+6*2+1
    sta ptr1+1

    ldx #$23
    ldy #$40
    jsr sub16
    jmp nmisub01_11

nmisub01_10:
    lda #2  ; 2nd part
    sta demo_part
    lda #0
    sta flag1
    jmp nmisub01_11

nmisub01_11:
    jmp sub19

; -----------------------------------------------------------------------------
; Unaccessed block ($e0d3)

    lda #$00
    sta $9a
    lda $96
    cmp #$a0
    bcc +
    jmp unaccessed18
*   ldx $93

    lda table19,x
    clc
    adc #88
    sta sprite_page+0*4+sprite_y

    lda table20,x
    clc
    adc #110
    sta sprite_page+0*4+sprite_x

    lda table19,x
    clc
    adc #88
    sta sprite_page+1*4+sprite_y

    lda table20,x
    clc
    adc #118
    sta sprite_page+1*4+sprite_x

    lda table19,x
    clc
    adc #96
    sta sprite_page+2*4+sprite_y

    lda table20,x
    clc
    adc #110
    sta sprite_page+2*4+sprite_x

    lda table19,x
    clc
    adc #96
    sta sprite_page+3*4+sprite_y

    lda table20,x
    clc
    adc #118
    sta sprite_page+3*4+sprite_x

    lda table20,x
    clc
    adc #88
    sta sprite_page+4*4+sprite_y

    lda table19,x
    clc
    adc #110
    sta sprite_page+4*4+sprite_x

    lda table20,x
    clc
    adc #88
    sta sprite_page+5*4+sprite_y

    lda table19,x
    clc
    adc #118
    sta sprite_page+5*4+sprite_x

    lda table20,x
    clc
    adc #96
    sta sprite_page+6*4+sprite_y

    lda table19,x
    clc
    adc #110
    sta sprite_page+6*4+sprite_x

    lda table20,x
    clc
    adc #96
    sta sprite_page+7*4+sprite_y

    lda table19,x
    clc
    adc #117
    sta sprite_page+7*4+sprite_x

    jmp sub19

unaccessed18:
    dec sprite_page+0*4+sprite_y
    dec sprite_page+0*4+sprite_x

    dec sprite_page+1*4+sprite_y
    inc sprite_page+1*4+sprite_x

    inc sprite_page+2*4+sprite_y
    dec sprite_page+2*4+sprite_x

    inc sprite_page+3*4+sprite_y
    inc sprite_page+3*4+sprite_x

    dec sprite_page+4*4+sprite_y
    dec sprite_page+4*4+sprite_x

    dec sprite_page+5*4+sprite_y
    inc sprite_page+5*4+sprite_x

    inc sprite_page+6*4+sprite_y
    dec sprite_page+6*4+sprite_x

    inc sprite_page+7*4+sprite_y
    inc sprite_page+7*4+sprite_x

; -----------------------------------------------------------------------------

sub19:
    ; Called by: nmisub01

    jsr sub17

    `sprite_dma
    rts

; -----------------------------------------------------------------------------

nmisub02:
    ; Called by: NMI

    ; clear Name Tables
    ldx #$00
    jsr fill_name_tables

    ldy #$00
    ldy #$00

    ; fill rows 1-8 of Name Table 2 with #$00-#$ff
    `set_ppu_addr vram_name_table2+32
    ldx #0
nmisub02_loop:
    stx ppu_data
    inx
    bne nmisub02_loop
    `reset_ppu_addr

    ; update first and second color in first sprite subpalette
    `set_ppu_addr vram_palette+4*4
    `write_ppu_data $00  ; dark gray
    `write_ppu_data $30  ; white
    `reset_ppu_addr

    ; update second and third sprite subpalette
    `set_ppu_addr vram_palette+5*4+1
    `write_ppu_data $3d  ; light gray
    `write_ppu_data $0c  ; dark cyan
    `write_ppu_data $3c  ; light cyan
    `write_ppu_data $0f  ; black
    `write_ppu_data $3c  ; light cyan
    `write_ppu_data $0c  ; dark cyan
    `write_ppu_data $1a  ; medium-dark green
    `reset_ppu_addr

    ; update first background subpalette
    `set_ppu_addr vram_palette+0*4
    `write_ppu_data $38  ; light yellow
    `write_ppu_data $01  ; dark purple
    `write_ppu_data $26  ; medium-light red
    `write_ppu_data $0f  ; black
    `reset_ppu_addr

    lda #1
    sta flag1
    lda #$8e
    sta $012e
    lda #$19
    sta $012f

    lda #%00011110
    sta ppu_mask
    rts

; -----------------------------------------------------------------------------

nmisub03:
    ; Called by: NMI

    `chr_bankswitch 0
    `sprite_dma

    lda #%10010000
    sta ppu_ctrl

    ; update fourth color of first background subpalette
    `set_ppu_addr vram_palette+0*4+3
    `write_ppu_data $0f  ; black
    `reset_ppu_addr

    lda #0
    sta ppu_scroll
    ldx $014e
    lda table19,x
    clc
    adc $014e
    sta ppu_scroll

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
    jsr sub15
*   lda $ac
    cmp #$01
    bne nmisub03_1
    lda $ab
    cmp #$96
    bne nmisub03_1
    ldx data1

nmisub03_loop1:
    txa
    asl
    asl
    tay

    lda table24,x
    clc
    adc $012f
    sta sprite_page+23*4+sprite_y,y
    lda table25,x
    sta sprite_page+23*4+sprite_tile,y
    lda table26,x
    sta sprite_page+23*4+sprite_attr,y
    lda table27,x
    clc
    adc $012e
    sta sprite_page+23*4+sprite_x,y

    cpx #0
    beq +
    dex
    jmp nmisub03_loop1

*   lda #129
    sta sprite_page+24*4+sprite_y
    lda #$e5
    sta sprite_page+24*4+sprite_tile
    lda #%00000001
    sta sprite_page+24*4+sprite_attr
    lda #214
    sta sprite_page+24*4+sprite_x

    lda #97
    sta sprite_page+25*4+sprite_y
    lda #$f0
    sta sprite_page+25*4+sprite_tile
    lda #%00000010
    sta sprite_page+25*4+sprite_attr
    lda #230
    sta sprite_page+25*4+sprite_x

    ; update fourth color of first background subpalette
    `set_ppu_addr vram_palette+0*4+3
    `write_ppu_data $30  ; white
    `reset_ppu_addr

nmisub03_1:
    lda $ac
    cmp #$02
    bne nmisub03_2
    lda $ab
    cmp #$32
    bcc nmisub03_2

    ldx #0
    ldy #0
nmisub03_loop2:
    lda $0180,x
    cmp #$01
    bne +
    lda #$a0
    clc
    adc $016a,x
    sta $9a
    lda $0154,x
    sta sprite_page+sprite_y,y
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
    cpx #22
    bne nmisub03_loop2

nmisub03_2:
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

    jsr fade_out_palette
    jsr update_palette
    lda #$00
    sta $a3

*   jsr sub17
    lda #2  ; 2nd part
    sta demo_part
    rts

; -----------------------------------------------------------------------------

nmisub04:
    ; Called by: NMI

    lda #$00
    ldx #0
nmisub04_loop:
    sta pulse1_ctrl,x
    inx
    cpx #15
    bne nmisub04_loop

    lda #$0a
    sta dmc_addr
    lda #$fa
    sta dmc_length
    lda #$4c
    sta dmc_ctrl
    lda #$1f
    sta apu_ctrl
    lda #$ff
    sta dmc_load
    ldx #$00
    jsr fill_nt_and_clear_at
    lda #1
    sta flag1
    rts

; -----------------------------------------------------------------------------

nmisub05:
    ; Called by: NMI

    inc $89
    ldx $8a
    lda table22,x
    clc
    adc #$96
    sta $8b
    dec $8a
    ldx $8a
    lda table20,x
    sta $8d

    lda #%10000100
    sta ppu_ctrl

    lda #$00
    sta $89
    ldy #$9f
nmisub05_loop_outer:

    ldx #25
nmisub05_loop_inner:
    dex
    bne nmisub05_loop_inner

    `set_ppu_addr_via_x vram_palette+0*4

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
    sta ppu_data
    ldx $8b
    lda table19,x
    tax
    dey
    bne nmisub05_loop_outer

    lda #%00000110
    sta ppu_mask
    lda #%10010000
    sta ppu_ctrl
    rts

; -----------------------------------------------------------------------------

nmisub06:
    ; Called by: NMI

    ; clear Name Tables
    ldx #$00
    jsr fill_name_tables

    lda #%00000000
    sta ppu_ctrl
    sta ppu_mask

    ldy #$14
    jsr fill_attribute_tables
    jsr sub12
    jsr init_palette_copy
    jsr update_palette

    ; update first color of fourth background subpalette
    `set_ppu_addr vram_palette+3*4
    `write_ppu_data $0f  ; black
    `reset_ppu_addr

    lda #1
    sta flag1
    lda #$05
    sta ram1
    rts

; -----------------------------------------------------------------------------

nmisub07:
    ; Called by: NMI

    `chr_bankswitch 1
    lda $0148
    cmp #$00
    beq +
    jmp nmisub07_1
*   dec $8a

    ldx #0
    lda #$00
    sta $89
nmisub07_loop1:
    lda $89
    adc $8a
    tay
    lda table19,y
    sta $0600,x
    lda $89
    clc
    adc ram1
    sta $89
    inx
    cpx #64
    bne nmisub07_loop1

    ldx #0
    ldy #0
    lda #$00
    sta $9a

nmisub07_loop2_outer:
    ; #$2100 + $9a -> ppu_addr
    lda #$21
    sta ppu_addr
    lda $9a
    sta ppu_addr

    ldy #0
nmisub07_loop2_inner:
    lda $0600,x
    sta ppu_data
    lda $0600,x
    sta ppu_data
    inx
    lda $0600,x
    sta ppu_data
    lda $0600,x
    sta ppu_data
    inx
    iny
    cpy #8
    bne nmisub07_loop2_inner

    lda $9a
    clc
    adc #32
    sta $9a
    lda $9a
    cmp #$00
    bne nmisub07_loop2_outer

    lda #$01
    sta $0148
    jmp nmisub07_2

nmisub07_1:
    dec $8a
    ldx #64
    lda #$00
    sta $89

nmisub07_loop3:
    lda $89
    adc $8a
    tay
    lda table19,y
    sta $0600,x
    lda $89
    clc
    adc ram1
    sta $89
    inx
    cpx #128
    bne nmisub07_loop3

    ldx #$7f
    lda #$00
    sta $9a

nmisub07_loop4_outer:
    lda #$22
    sta ppu_addr
    lda $9a
    sta ppu_addr

    ldy #0
nmisub07_loop4_inner:
    lda $0600,x
    sta ppu_data
    lda $0600,x
    sta ppu_data
    dex
    lda $0600,x
    sta ppu_data
    lda $0600,x
    sta ppu_data
    dex
    iny
    cpy #8
    bne nmisub07_loop4_inner

    lda $9a
    clc
    adc #32
    sta $9a
    lda $9a
    cmp #$00
    bne nmisub07_loop4_outer

    lda #$00
    sta $0148

nmisub07_2:
    `reset_ppu_addr

    lda #$00
    sta $89

nmisub07_loop5:
    ldx #$04
    jsr sub14
    lda $89
    clc
    adc $8b
    tax
    lda table19,x
    sta ppu_scroll
    lda #0
    sta ppu_scroll
    inc $89
    iny
    cpy #$98
    bne nmisub07_loop5

    ldx $8b
    lda table22,x
    sbc $8b
    sbc $8b
    lda #0
    sta ppu_scroll

    ldx $8b
    lda table20,x
    clc
    sbc #10

    lda #230
    sta ppu_scroll
    dec $8b

    lda #%00001110
    sta ppu_mask
    lda #%10000000
    sta ppu_ctrl
    rts

; -----------------------------------------------------------------------------

nmisub08:
    ; Called by: NMI

    ; clear Name Tables
    ldx #$00
    jsr fill_name_tables

    jsr init_palette_copy
    jsr update_palette

    lda #%00000000
    sta ppu_ctrl
    sta ppu_mask

    ldy #$ff
    jsr fill_attribute_tables
    ldy #$55
    jsr fill_attribute_tables_top

    ; update first color of fourth background subpalette
    `set_ppu_addr vram_palette+3*4
    `write_ppu_data $0f  ; black
    `reset_ppu_addr

    lda #1
    sta flag1
    rts

; -----------------------------------------------------------------------------

nmisub09:
    ; Called by: NMI

    jsr change_background_color
    `chr_bankswitch 1
    dec $8a
    dec $8a

    ldx #0
    lda #0
    sta $89
nmisub09_loop1:
    lda $89
    adc $8a
    tay
    lda table19,y
    adc #$46
    sta $0600,x
    inc $89
    inx
    cpx #128
    bne nmisub09_loop1

    lda $0148
    cmp #$00
    beq +
    jmp nmisub09_1

*   ldx #0
    ldy #0
    lda #$00

    sta $9a
nmisub09_loop2_outer:
    ; #$2100 + $9a -> ppu_addr
    lda #$21
    sta ppu_addr
    lda $9a
    sta ppu_addr

    ldy #0
nmisub09_loop2_inner:
    lda $0600,x
    sta ppu_data
    lda $0600,x
    sta ppu_data
    lda $0600,x
    sta ppu_data
    lda $0600,x
    sta ppu_data
    inx
    iny
    cpy #8
    bne nmisub09_loop2_inner

    lda $9a
    clc
    adc #32
    sta $9a
    lda $9a
    cmp #$00
    bne nmisub09_loop2_outer

    lda #$01
    sta $0148
    jmp nmisub09_2

nmisub09_1:
    ldx #$7f
    lda #$20
    sta $9a

nmisub09_loop3_outer:
    lda #$22
    sta ppu_addr
    lda $9a
    sta ppu_addr

    ldy #0
nmisub09_loop3_inner:
    lda $0600,x
    sta ppu_data
    lda $0600,x
    sta ppu_data
    lda $0600,x
    sta ppu_data
    lda $0600,x
    sta ppu_data
    dex
    iny
    cpy #8
    bne nmisub09_loop3_inner

    lda $9a
    clc
    adc #32
    sta $9a
    lda $9a
    cmp #$00
    bne nmisub09_loop3_outer

    lda #$00
    sta $0148

nmisub09_2:
    `reset_ppu_addr

    ldx $8b
    lda table22,x
    sbc $8b
    sbc $8b
    sbc $8b
    sbc $8b
    sbc $8b
    sbc $8b
    sta ppu_scroll

    ldx $8b
    lda table20,x
    clc
    sbc #10
    sta ppu_scroll

    dec $8b

    lda #%00001110
    sta ppu_mask
    lda #%10000000
    sta ppu_ctrl
    rts

; -----------------------------------------------------------------------------

nmisub10:
    ; Called by: NMI

    ldx #$ff
    jsr fill_nt_and_clear_at
    jsr sub12
    jsr init_palette_copy
    jsr update_palette
    lda #1
    sta flag1
    jsr hide_sprites

    lda #$00
    sta $89
    sta $8a
    sta $8b
    sta $8c

    lda #%00000000
    sta ppu_mask
    lda #%10000000
    sta ppu_ctrl
    rts

; -----------------------------------------------------------------------------

nmisub11:
    ; Called by: NMI

    dec $8c
    inc $8b
    lda $8b
    cmp #$02
    bne +

    lda #$00
    sta $8b
    dec $8a

*   lda #%10000100
    sta ppu_ctrl

    ; update first color of first background subpalette
    `set_ppu_addr_via_x vram_palette+0*4
    `write_ppu_data $0f  ; black
    `reset_ppu_addr

    ldx #$ff
    jsr sub14
    ldx #$01
    jsr sub14

    ; update first color of first background subpalette
    `set_ppu_addr_via_x vram_palette+0*4
    `write_ppu_data $0f  ; black
    `reset_ppu_addr

    lda #$00
    sta $89

    ldy #85
nmisub11_loop_outer:

    ldx #25
nmisub11_loop_inner:
    dex
    bne nmisub11_loop_inner

    `set_ppu_addr_via_x vram_palette+0*4

    ldx $8a
    lda table22,x
    sta $9a
    dec $89

    lda $89
    clc
    adc $8a
    tax
    lda table20,x
    clc
    sbc $9a
    adc $8c
    tax
    lda table23,x
    sta ppu_data
    dey
    bne nmisub11_loop_outer

    `reset_ppu_addr

    ; update first color of first background subpalette
    `set_ppu_addr_via_x vram_palette+0*4
    `write_ppu_data $0f  ; black
    `reset_ppu_addr
    rts

; -----------------------------------------------------------------------------

nmisub12:
    ; Called by: NMI

    ; fill Name Tables with #$ff
    ldx #$ff
    jsr fill_name_tables

    jsr init_palette_copy
    jsr update_palette

    ; update fourth sprite subpalette
    `set_ppu_addr vram_palette+7*4
    `write_ppu_data $0f  ; black
    `write_ppu_data $19  ; medium-dark green
    `write_ppu_data $33  ; light purple
    `write_ppu_data $30  ; white
    `reset_ppu_addr

    `set_ppu_addr vram_name_table0

nmisub12_1:
    lda #$00
    sta $9e
    lda #$00
    sta $9f
nmisub12_loop1_outer:

    ldy #0
nmisub12_loop1_middle:

    ldx #0
nmisub12_loop1_inner:
    txa
    clc
    adc $9e
    sta ppu_data
    inx
    cpx #8
    bne nmisub12_loop1_inner

    iny
    cpy #$04
    bne nmisub12_loop1_middle

    lda $9e
    clc
    adc #8
    sta $9e
    lda $9e
    cmp #$40
    bne nmisub12_loop1_outer

    lda #$00
    sta $9e
    inc $9f
    lda $9f
    cmp #$03
    bne nmisub12_loop1_outer

    ldx #0
nmisub12_loop2_outer:

    ldy #0
nmisub12_loop2_middle:

    ldx #0
nmisub12_loop2_inner:
    txa
    clc
    adc $9e
    sta ppu_data
    inx
    cpx #8
    bne nmisub12_loop2_inner

    iny
    cpy #4
    bne nmisub12_loop2_middle

    lda $9e
    clc
    adc #8
    sta $9e
    cmp #$28
    bne nmisub12_loop2_outer

    lda #$f0  ; unnecessary

    ; write 64 bytes to ppu_data (#$f0-#$f7 eight times)

    ldy #0
nmisub12_loop3_outer:

    ldx #$f0
nmisub12_loop3_inner:
    stx ppu_data
    inx
    cpx #$f8
    bne nmisub12_loop3_inner

    iny
    cpy #8
    bne nmisub12_loop3_outer

    `reset_ppu_addr

    inc $a0
    lda $a0
    cmp #$02
    bne +
    jmp nmisub12_2

*   `set_ppu_addr vram_name_table2

    jmp nmisub12_1

nmisub12_2:
    ; clear Attribute Table 0
    `set_ppu_addr vram_attr_table0
    ldx #0
nmisub12_loop4:
    lda #$00
    sta ppu_data
    inx
    cpx #64
    bne nmisub12_loop4
    `reset_ppu_addr

    ; clear Attribute Table 2
    `set_ppu_addr vram_attr_table2
    ldx #0
nmisub12_loop5:
    lda #$00
    sta ppu_data
    inx
    cpx #64
    bne nmisub12_loop5
    `reset_ppu_addr

    jsr hide_sprites

    lda #$02
    sta $014d
    lda #$00
    sta $a3
    lda #1
    sta flag1
    lda #$00
    sta $89

    lda #%00011000
    sta ppu_ctrl
    lda #%00011110
    sta ppu_mask
    rts

; -----------------------------------------------------------------------------

nmisub13:
    ; Called by: NMI

    `sprite_dma

    lda $a2
    cmp #$08
    bne nmisub13_01
    lda $a1
    cmp #$8c
    bcc nmisub13_01
    inc $a3
    lda $a3
    cmp #$04
    bne nmisub13_01

    jsr fade_out_palette
    jsr update_palette
    lda #$00
    sta $a3

nmisub13_01:
    lda #3  ; 9th part
    sta demo_part

    `set_ppu_addr vram_palette+0*4

    lda $a2
    cmp #8
    beq nmisub13_04
    lda $014d
    cmp #0
    beq nmisub13_03
    cmp #1
    beq nmisub13_02
    cmp #2
    beq +

*   `write_ppu_data $34  ; light purple
    `write_ppu_data $24  ; medium-light purple
    `write_ppu_data $14  ; medium-dark purple
    `write_ppu_data $04  ; dark purple

nmisub13_02:
    `write_ppu_data $38  ; light yellow
    `write_ppu_data $28  ; medium-light yellow
    `write_ppu_data $18  ; medium-dark yellow
    `write_ppu_data $08  ; dark yellow

nmisub13_03:
    `write_ppu_data $32  ; light blue
    `write_ppu_data $22  ; medium-light blue
    `write_ppu_data $12  ; medium-dark blue
    `write_ppu_data $02  ; dark blue

nmisub13_04:
    inc $89
    lda $89
    sta ppu_scroll
    ldx $89
    lda table20,x
    sta ppu_scroll
    inc $a1
    lda $a1
    cmp #$b4
    beq +
    jmp nmisub13_05
*   inc $a2
    lda #$00
    sta $a1

nmisub13_05:
    lda $a2
    cmp #1
    beq nmisub13_jump_table+1*3
    cmp #2
    beq nmisub13_jump_table+2*3
    cmp #3
    beq nmisub13_jump_table+3*3
    cmp #4
    beq nmisub13_jump_table+4*3
    cmp #5
    beq nmisub13_jump_table+5*3
    cmp #6
    beq nmisub13_jump_table+6*3
    cmp #7
    beq nmisub13_jump_table+7*3
    cmp #8
    beq nmisub13_jump_table+8*3
    cmp #9
    beq nmisub13_06

nmisub13_jump_table:
    jmp nmisub13_15
    jmp nmisub13_07
    jmp nmisub13_08
    jmp nmisub13_09
    jmp nmisub13_10
    jmp nmisub13_11
    jmp nmisub13_12
    jmp nmisub13_13
    jmp nmisub13_14

nmisub13_06:
    lda #10  ; 10th part
    sta demo_part
    lda #0
    sta flag1
    jmp nmisub13_16

nmisub13_07:
    jsr hide_sprites

    ; draw 8*2 sprites: tiles #$90-#$9f starting from (92, 106), subpalette 3
    ldx #92
    ldy #106
    lda #$90
    sta $9a
    jsr update_sixteen_sprites

    jmp nmisub13_16

nmisub13_08:
    jsr hide_sprites

    ; draw 8*2 sprites: tiles #$60-#$6f starting from (117, 115), subpalette 3
    ldx #117
    ldy #115
    lda #$60
    sta $9a
    jsr update_sixteen_sprites

    ; draw 4*2 sprites: tiles #$ac-#$b3 starting from (84, 97), subpalette 2
    ldx #84
    ldy #97
    lda #$ac
    sta $9a
    jsr update_eight_sprites

    jmp nmisub13_16

nmisub13_09:
    jsr hide_sprites

    ; draw 8*2 sprites: tiles #$80-#$8f starting from (117, 115), subpalette 3
    ldx #117
    ldy #115
    lda #$80
    sta $9a
    jsr update_sixteen_sprites

    ; draw 4*2 sprites: tiles #$ac-#$b3 starting from (84, 97), subpalette 2
    ldx #84
    ldy #97
    lda #$ac
    sta $9a
    jsr update_eight_sprites

    jmp nmisub13_16

nmisub13_10:
    jsr hide_sprites
    lda #$01
    sta $014d

    ; draw 8*2 sprites: tiles #$50-#$5f starting from (117, 115), subpalette 3
    ldx #117
    ldy #115
    lda #$50
    sta $9a
    jsr update_sixteen_sprites

    ; draw 3*2 sprites: tiles #$a0-#$a5 starting from (84, 97), subpalette 2
    ldx #84
    ldy #97
    lda #$a0
    sta $9a
    jsr update_six_sprites

    jmp nmisub13_16

nmisub13_11:
    jsr hide_sprites

    ; draw 8*2 sprites: tiles #$40-#$4f starting from (117, 115), subpalette 3
    ldx #117
    ldy #115
    lda #$40
    sta $9a
    jsr update_sixteen_sprites

    ; draw 3*2 sprites: tiles #$a0-#$a5 starting from (84, 97), subpalette 2
    ldx #84
    ldy #97
    lda #$a0
    sta $9a
    jsr update_six_sprites

    jmp nmisub13_16

nmisub13_12:
    jsr hide_sprites

    ; draw 8*2 sprites: tiles #$e0-#$ef starting from (117, 115), subpalette 3
    ldx #117
    ldy #115
    lda #$e0
    sta $9a
    jsr update_sixteen_sprites

    ; draw 3*2 sprites: tiles #$a0-#$a5 starting from (84, 97), subpalette 2
    ldx #84
    ldy #97
    lda #$a0
    sta $9a
    jsr update_six_sprites

    jmp nmisub13_16

nmisub13_13:
    lda #$00
    sta $014d
    jsr hide_sprites

    ; draw 8*2 sprites: tiles #$c0-#$cf starting from (117, 115), subpalette 3
    ldx #117
    ldy #115
    lda #$c0
    sta $9a
    jsr update_sixteen_sprites

    ; draw 3*2 sprites: tiles #$a0-#$a5 starting from (84, 97), subpalette 2
    ldx #84
    ldy #97
    lda #$a0
    sta $9a
    jsr update_six_sprites

    jmp nmisub13_16

nmisub13_14:
    jsr hide_sprites

    ; draw 8*2 sprites: tiles #$70-#$7f starting from (117, 115), subpalette 3
    ldx #117
    ldy #115
    lda #$70
    sta $9a
    jsr update_sixteen_sprites

    ; draw 3*2 sprites: tiles #$a6-#$ab starting from (84, 97), subpalette 2
    ldx #84
    ldy #97
    lda #$a6
    sta $9a
    jsr update_six_sprites

    jmp nmisub13_16

nmisub13_15:
    jsr hide_sprites
nmisub13_16:
    `chr_bankswitch 1

    lda #%10011000
    sta ppu_ctrl
    lda #%00011110
    sta ppu_mask
    rts

; -----------------------------------------------------------------------------

nmisub14:
    ; Called by: NMI

    ; fill Name Tables with #$7f
    ldx #$7f
    jsr fill_name_tables

    ldy #$00
    jsr fill_attribute_tables
    jsr hide_sprites

    lda #%00000000
    sta ppu_ctrl
    sta ppu_mask

    lda #$20
    sta $014a
    lda #$21
    sta $014b

    ; write 16 rows to Name Table 0;
    ; the left half consists of tiles #$00, #$01, ..., #$ff;
    ; the right half consists of tile #$7f

    `set_ppu_addr vram_name_table0

    ldy #0
nmisub14_loop1_outer:

    ; write Y...Y+15
    ldx #0
nmisub14_loop1_inner1:
    sty ppu_data
    iny
    inx
    cpx #16
    bne nmisub14_loop1_inner1

    ; write 16 * byte #$7f
    ldx #0
nmisub14_loop1_inner2:
    `write_ppu_data $7f
    inx
    cpx #16
    bne nmisub14_loop1_inner2

    cpy #0
    bne nmisub14_loop1_outer

    jsr sub12

    ; write another 7 rows to Name Table 0;
    ; the left half consists of tiles #$00, #$01, ..., #$df
    ; the right half consists of tile #$7f

    ldy #0
nmisub14_loop2_outer:

    ; first inner loop
    ldx #0
nmisub14_loop2_inner1:
    sty ppu_data
    iny
    inx
    cpx #16
    bne nmisub14_loop2_inner1

    ; second inner loop
    ldx #0
nmisub14_loop2_inner2:
    `write_ppu_data $7f
    inx
    cpx #16
    bne nmisub14_loop2_inner2

    cpy #7*32
    bne nmisub14_loop2_outer

    ; write bytes #$e0-#$e4 to Name Table 0, row 29, columns 10-14
    `reset_ppu_addr
    `set_ppu_addr vram_name_table0+29*32+10
    `write_ppu_data $e0
    `write_ppu_data $e1
    `write_ppu_data $e2
    `write_ppu_data $e3
    `write_ppu_data $e4
    `reset_ppu_addr

    ; update first background subpalette and first sprite subpalette
    `set_ppu_addr vram_palette+0*4
    ldx #0
    `write_ppu_data $30  ; white
    `write_ppu_data $25  ; medium-light red
    `write_ppu_data $17  ; medium-dark orange
    `write_ppu_data $0f  ; black
    `set_ppu_addr vram_palette+4*4+1
    `write_ppu_data $02  ; dark blue
    `write_ppu_data $12  ; medium-dark blue
    `write_ppu_data $22  ; medium-light blue
    `reset_ppu_addr

    `reset_ppu_scroll

    lda #$00
    sta $89
    sta $8a
    lda #$40
    sta $8b
    lda #$00
    sta $8c
    lda #1
    sta flag1
    lda #$00
    sta $a3

    lda #%10000000
    sta ppu_ctrl
    rts

; -----------------------------------------------------------------------------

nmisub15:
    ; Called by: NMI

    `sprite_dma

    inc $8a
    inc $8b
    ldx #24
    ldy #0
    lda #$00
    sta $9a
    sta $89
    lda $8b

nmisub15_loop1:
    ; update sprite at offset Y

    ; X -> sprite Y position
    txa
    sta sprite_page+sprite_y,y

    ; #$f0 + $8c -> sprite tile
    lda #$f0
    clc
    adc $8c
    sta sprite_page+sprite_tile,y

    ; $014a -> sprite attributes
    lda $014a
    sta sprite_page+sprite_attr,y

    ; store X
    txa
    pha

    ; $89 += 3
    inc $89
    inc $89
    inc $89

    ; [woman_sprite_x + $89 + $8a] + 194 -> sprite X position
    lda $89
    clc
    adc $8a
    tax
    lda woman_sprite_x,x
    clc
    adc #194
    sta sprite_page+sprite_x,y

    ; restore X
    pla
    tax

    ; Y   += 4
    ; X   += 8
    ; $8d += 1
    `iny4
    txa
    clc
    adc #8
    tax
    inc $8d

    ; if $8d = 15 then clear it and increment $8c
    lda $8d
    cmp #15
    beq +
    jmp ++
*   inc $8c
    lda #0
    sta $8d

    ; if $8c = 16 then clear it
*   lda $8c
    cmp #16
    beq +
    jmp ++
*   lda #0
    sta $8c

    ; loop until Y = 96
*   cpy #96
    bne nmisub15_loop1

    ; 24 -> X
    ;  0 -> $9a, $89
    ; $8c -= 1
    ldx #24
    lda #$00
    sta $9a
    sta $89
    dec $8c

nmisub15_loop2:
    ; update sprite at offset Y

    ; X -> sprite Y position
    txa
    sta sprite_page+sprite_y,y

    ; #$f0 + $8c -> sprite tile
    lda #$f0
    clc
    adc $8c
    sta sprite_page+sprite_tile,y

    ; $014b -> sprite attributes
    lda $014b
    sta sprite_page+sprite_attr,y

    ; store X
    txa
    pha

    ; $89 -= 2
    dec $89
    dec $89

    ; [woman_sprite_x + $89 + $8b] + 194 -> sprite X position
    lda $89
    clc
    adc $8b
    tax
    lda woman_sprite_x,x
    clc
    adc #194
    sta sprite_page+sprite_x,y

    ; restore X
    pla
    tax

    ; Y   += 4
    ; X   += 8
    ; $8c += 1
    `iny4
    txa
    clc
    adc #8
    tax
    inc $8c

    ; if $8c = 16 then clear it
    lda $8c
    cmp #16
    beq +
    jmp ++
*   lda #0
    sta $8c

    ; loop until Y = 192
*   cpy #192
    bne nmisub15_loop2

    `chr_bankswitch 3

    lda #%10001000
    sta ppu_ctrl

    ldx #$ff
    jsr sub14
    jsr sub14
    ldx #$30
    jsr sub14
    nop
    nop
    nop
    nop
    nop

    lda #%10011000
    sta ppu_ctrl
    lda #%00011110
    sta ppu_mask

    lda $8b
    cmp #$fa
    bne nmisub15_exit

    inc $0149
    lda $0149
    cmp #$02
    beq +

    lda #$00
    sta $014a
    lda #$01
    sta $014b
    jmp nmisub15_exit

*   lda #$20
    sta $014a
    lda #$21
    sta $014b
    lda #$00
    sta $0149

nmisub15_exit:
    rts

; -----------------------------------------------------------------------------
; Unaccessed block ($ec99)

    ldx #$7a
    jsr fill_name_tables

    ldy #$00
    jsr fill_attribute_tables
    jsr init_palette_copy
    jsr update_palette
    jsr hide_sprites

    lda #%00000000
    sta ppu_ctrl
    sta ppu_mask

    `set_ppu_addr vram_name_table0+8*32+10

    ldx #$50
    ldy #0
unaccessed19:
    stx ppu_data
    inx
    iny
    cpy #12
    bne unaccessed19

    `reset_ppu_addr
    `set_ppu_addr vram_name_table0+9*32+10

    ldy #0
    ldx #$5c
unaccessed20:
    stx ppu_data
    inx
    iny
    cpy #12
    bne unaccessed20

    `reset_ppu_addr
    `set_ppu_addr vram_name_table0+10*32+10

    ldy #0
    ldx #$68
unaccessed21:
    stx ppu_data
    inx
    iny
    cpy #12
    bne unaccessed21

    `reset_ppu_addr

    lda #1
    sta flag1
    lda #$00
    sta $8f
    sta $89
    lda #$00
    sta $8a

    `set_ppu_addr vram_palette+6*4+2
    `write_ppu_data $00
    `write_ppu_data $10
    `reset_ppu_addr

    lda #%10000000
    sta ppu_ctrl
    lda #%00011110
    sta ppu_mask

    lda #$00
    sta $0130
    rts

    lda $0130
    cmp #$01
    beq unaccessed22

    `set_ppu_addr vram_palette+4*4
    `write_ppu_data $0f
    `write_ppu_data $0f
    `write_ppu_data $0f
    `write_ppu_data $0f
    `reset_ppu_addr

    `set_ppu_addr vram_palette+0*4
    `write_ppu_data $0f
    `write_ppu_data $30
    `write_ppu_data $10
    `write_ppu_data $00
    `reset_ppu_addr

unaccessed22:
    lda #$01
    sta $0130

    lda #%00011110
    sta ppu_mask
    lda #%00010000
    sta ppu_ctrl

    inc $8a
    lda $8a
    cmp #8
    beq +
    jmp unaccessed24
*   lda #$00
    sta $8a
    inc $8f
    lda $8f
    cmp #$eb
    beq +
    jmp ++
*   lda #0
    sta flag1
    lda #7
    sta demo_part

*   `set_ppu_addr vram_name_table0+27*32+1

    ldx #0
unaccessed23:
    txa
    clc
    adc $8f
    tay
    lda table11,y
    clc
    sbc #$36
    sta ppu_data
    inx
    cpx #31
    bne unaccessed23

    `reset_ppu_addr

unaccessed24:
    `chr_bankswitch 2
    inc $89
    ldx $89
    lda table20,x
    clc
    sbc #30
    sta ppu_scroll
    lda #0
    sta ppu_scroll

    lda #%00010000
    sta ppu_ctrl
    lda #%00011110
    sta ppu_mask

    `sprite_dma

    ldx #$ff
    jsr sub14
    jsr sub14
    jsr sub14
    ldx #$1e
    jsr sub14
    ldx #$d0
    jsr sub14

    lda #%00000000
    sta ppu_ctrl

    `chr_bankswitch 0

    lda $8a
    sta ppu_scroll
    lda #0
    sta ppu_scroll

    lda #215
    sta sprite_page+0*4+sprite_y
    lda #$25
    sta sprite_page+0*4+sprite_tile
    lda #%00000000
    sta sprite_page+0*4+sprite_attr
    lda #248
    sta sprite_page+0*4+sprite_x

    lda #207
    sta sprite_page+1*4+sprite_y
    lda #$25
    sta sprite_page+1*4+sprite_tile
    lda #%00000000
    sta sprite_page+1*4+sprite_attr
    lda #248
    sta sprite_page+1*4+sprite_x

    lda #223
    sta sprite_page+2*4+sprite_y
    lda #$27
    sta sprite_page+2*4+sprite_tile
    lda #%00000000
    sta sprite_page+2*4+sprite_attr
    lda #248
    sta sprite_page+2*4+sprite_x

    ldx data2
unaccessed25:
    txa
    asl
    asl
    tay

    lda table28,x
    clc
    adc #$9b
    sta sprite_page+23*4+sprite_y,y

    txa
    pha
    ldx $0137
    lda table52,x
    sta $9a
    pla

    tax
    lda table29,x
    clc
    adc $9a
    sta sprite_page+23*4+sprite_tile,y

    lda #%00000010
    sta sprite_page+23*4+sprite_attr,y

    lda table30,x
    clc
    adc $0139
    sta sprite_page+23*4+sprite_x,y

    cpx #0
    beq +
    dex
    jmp unaccessed25

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

*   lda #%10001000
    sta ppu_ctrl
    lda #%00011000
    sta ppu_mask
    rts

; -----------------------------------------------------------------------------

nmisub16:
    ; Called by: NMI

    jsr hide_sprites
    ldy #$aa
    jsr fill_attribute_tables
    lda #$1a
    sta $9a
    ldx #$60

nmisub16_loop1_outer:
    ; #$2100 + $9a -> ppu_addr
    lda #$21
    sta ppu_addr
    lda $9a
    sta ppu_addr

    ldy #0
nmisub16_loop1_inner:
    stx ppu_data
    inx
    iny
    cpy #3
    bne nmisub16_loop1_inner

    `reset_ppu_addr

    lda $9a
    clc
    adc #32
    sta $9a
    lda $9a
    cmp #$1a
    bne nmisub16_loop1_outer

    lda #$08
    sta $9a
    ldx #$80

nmisub16_loop2_outer:
    lda #$22
    sta ppu_addr
    lda $9a
    sta ppu_addr

    ldy #0
nmisub16_loop2_inner:
    stx ppu_data
    inx
    iny
    cpy #3
    bne nmisub16_loop2_inner

    `reset_ppu_addr

    lda $9a
    clc
    adc #32
    sta $9a
    lda $9a
    cmp #$68
    bne nmisub16_loop2_outer

    ; update all sprite subpalettes
    `set_ppu_addr vram_palette+4*4
    `write_ppu_data $0f  ; black
    `write_ppu_data $01  ; dark blue
    `write_ppu_data $1c  ; medium-dark cyan
    `write_ppu_data $30  ; white
    `write_ppu_data $0f  ; black
    `write_ppu_data $00  ; dark gray
    `write_ppu_data $10  ; light gray
    `write_ppu_data $20  ; white
    `write_ppu_data $0f  ; black
    `write_ppu_data $19  ; medium-light green
    `write_ppu_data $26  ; medium-light red
    `write_ppu_data $30  ; white
    `write_ppu_data $22  ; medium-light blue
    `write_ppu_data $16  ; medium-dark red
    `write_ppu_data $27  ; medium-light orange
    `write_ppu_data $18  ; medium-dark yellow
    `reset_ppu_addr

    ; update first background subpalette
    `set_ppu_addr vram_palette+0*4
    `write_ppu_data $0f  ; black
    `write_ppu_data $20  ; white
    `write_ppu_data $10  ; light gray
    `write_ppu_data $00  ; dark gray
    `reset_ppu_addr

    ldx data3
nmisub16_loop3:
    lda table31,x
    sta $0104,x
    lda table32,x
    sta $0108,x
    dex
    cpx #255
    bne nmisub16_loop3

    ldx data5
nmisub16_loop4:
    lda #$00
    sta $0112,x
    lda #$f0
    sta $0116,x
    dex
    cpx #$ff
    bne nmisub16_loop4

    ldx data7
nmisub16_loop5:
    txa
    asl
    asl
    tay

    lda table41,x
    sta sprite_page+48*4+sprite_y,y
    lda table43,x
    sta sprite_page+48*4+sprite_tile,y
    lda table40,x
    sta sprite_page+48*4+sprite_x,y

    lda table42,x
    sta $011e,x
    dex
    cpx #255
    bne nmisub16_loop5

    lda #$7a
    sta $0111
    lda #$0a
    sta $0110

    ldx data4
nmisub16_loop6:
    txa
    asl
    asl
    tay

    lda table35,x
    sta sprite_page+1*4+sprite_tile,y
    lda table36,x
    sta sprite_page+1*4+sprite_attr,y

    cpx #0
    beq +
    dex
    jmp nmisub16_loop6

*   lda #$00
    sta $0100
    sta $0101
    sta $0102
    lda #1
    sta flag1

    lda #%10000000
    sta ppu_ctrl
    lda #%00010010
    sta ppu_mask
    rts

; -----------------------------------------------------------------------------

nmisub17:
    ; Called by: NMI

    `sprite_dma

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

nmisub17_loop1:
    dec $0104,x
    lda $0104,x
    cmp #$00
    bne nmisub17_2
    lda $0108,x
    cmp table33,x
    beq +
    inc $0108,x
    jmp nmisub17_1
*   lda table32,x
    sta $0108,x
nmisub17_1:
    lda table31,x
    sta $0104,x
nmisub17_2:
    dex
    cpx #255
    bne nmisub17_loop1

    lda $0108
    sta sprite_page+1*4+sprite_tile
    lda $0109
    sta sprite_page+16*4+sprite_tile
    lda $010a
    sta sprite_page+17*4+sprite_tile
    lda $010b
    sta sprite_page+13*4+sprite_tile

    ldx data4
nmisub17_loop2:
    txa
    asl
    asl
    tay

    lda table34,x
    clc
    adc $0111
    sta sprite_page+1*4+sprite_y,y

    lda table37,x
    clc
    adc $0110
    sta sprite_page+1*4+sprite_x,y

    cpx #0
    beq +
    dex
    jmp nmisub17_loop2

*   lda $0100
    ldx $0101
    cmp table38,x
    bne nmisub17_3

    inc $0101
    lda $0101
    cpx data6
    bne +      ; always taken

    ; unaccessed block ($f111)
    lda #$00
    sta $0101

*   ldx $0102
    ldy $0100
    lda #$ff
    sta $0112,x
    lda table19,y
    clc
    adc #$5a
    sta $0116,x
    lda table22,y
    sta $011a,x
    inc $0102
    cpx data5
    bne nmisub17_3
    lda #$00
    sta $0102

nmisub17_3:
    ldx data5
nmisub17_loop3:
    lda $0116,x
    cmp #$f0
    beq nmisub17_4
    lda $0112,x
    clc
    sbc $011a,x
    bcc +
    sta $0112,x
    jmp nmisub17_4
*   lda #$f0
    sta $0116,x
nmisub17_4:
    dex
    cpx #255
    bne nmisub17_loop3

    ldx data5
nmisub17_loop4:
    txa
    asl
    asl
    tay

    lda $0116,x
    sta sprite_page+18*4+sprite_y,y
    lda table39,x
    sta sprite_page+18*4+sprite_tile,y
    lda #$2b
    sta sprite_page+18*4+sprite_attr,y
    lda $0112,x
    sta sprite_page+18*4+sprite_x,y

    dex
    cpx #255
    bne nmisub17_loop4

    ldx data7
nmisub17_loop5:
    txa
    asl
    asl
    tay

    lda sprite_page+48*4+sprite_x,y
    clc
    sbc table42,x
    sta sprite_page+48*4+sprite_x,y

    dex
    cpx #255
    bne nmisub17_loop5

    lda #%10000000
    sta ppu_ctrl
    lda #%00011010
    sta ppu_mask

    `set_ppu_scroll 0, 50
    rts

; -----------------------------------------------------------------------------

game_over_screen:
    ; Show the "GAME OVER - CONTINUE?" screen.
    ; Called by: NMI

    ; fill Name Tables with the space character (#$4a)
    ldx #$4a
    jsr fill_name_tables

    ldy #$00
    jsr fill_attribute_tables
    jsr init_palette_copy
    jsr update_palette

    ; Copy 96 (32*3) bytes of text from an encrypted table to rows 14-16 of
    ; Name Table 0. Subtract 17 from each byte.

    `set_ppu_addr vram_name_table0+14*32

    ldx #0
game_over_loop:
    lda game_over,x
    clc
    sbc #16
    sta ppu_data
    inx
    cpx #96
    bne game_over_loop

    lda #%00000010
    sta ppu_ctrl
    lda #%00000000
    sta ppu_mask
    rts

; -----------------------------------------------------------------------------

nmisub18:
    ; Called by: NMI

    `set_ppu_scroll 0, 0

    lda #%10010000
    sta ppu_ctrl
    lda #%00001110
    sta ppu_mask
    rts

; -----------------------------------------------------------------------------

greets_screen:
    ; Show the "GREETS TO ALL NINTENDAWGS" screen.
    ; Called by: NMI

    ; fill Name Tables with the space character
    ldx #$4a
    jsr fill_name_tables

    ldy #$00
    jsr fill_attribute_tables
    jsr clear_palette_copy
    jsr update_palette

    lda #%00000010  ; disable NMI
    sta ppu_ctrl
    lda #%00000000  ; hide sprites and background
    sta ppu_mask

    ; Write the heading "GREETS TO ALL NINTENDAWGS:" (16*3 characters, tiles
    ; $00-$2f) to rows 3-5, columns 9-24 of Name Table 0.

    ; 0 -> $9a (outer loop counter and VRAM address offset)
    ; 0 -> X   (tile number)
    lda #0
    sta $9a
    ldx #0

greets_heading_loop_outer:
    ; go to column 9 of row 3-5
    lda #>[$2000+3*32+9]
    sta ppu_addr
    lda $9a
    clc
    adc #<[$2000+3*32+9]
    sta ppu_addr

    ; copy the row (16 tiles)
    ldy #0
greets_heading_loop_inner:
    stx ppu_data
    inx
    iny
    cpy #16
    bne greets_heading_loop_inner

    `reset_ppu_addr

    ; move output offset to next row: $9a += 32
    ; loop while less than 3*32
    lda $9a
    clc
    adc #32
    sta $9a
    cmp #3*32
    bne greets_heading_loop_outer

    ; Copy 640 (32*20) bytes of text from an encrypted table to rows 8-27 of
    ; Name Table 0. Subtract 17 from each byte.

    ; go to row 8, column 0 of Name Table 0
    `set_ppu_addr vram_name_table0+8*32

    ; copy the first 256 bytes
    ldx #0
copy_greets_loop1:
    lda greets+0,x
    clc
    sbc #16
    sta ppu_data
    inx
    bne copy_greets_loop1

    ; copy another 256 bytes
    ldx #0
copy_greets_loop2:
    lda greets+256,x
    clc
    sbc #16
    sta ppu_data
    inx
    bne copy_greets_loop2

    ; copy another 128 bytes
    ldx #0
copy_greets_loop3:
    lda greets+2*256,x
    clc
    sbc #16
    sta ppu_data
    inx
    cpx #128
    bne copy_greets_loop3

    `reset_ppu_addr

    lda #1
    sta flag1
    lda #$e6
    sta $0153
    rts

; -----------------------------------------------------------------------------

nmisub19:
    ; Called by: NMI

    `chr_bankswitch 2
    lda $0150
    cmp #$00
    bne +
    lda $014f
    cmp #$03
    bne +
    jsr init_palette_copy
    jsr update_palette

    ; update first background subpalette
    `set_ppu_addr vram_palette+0*4
    `write_ppu_data $0f  ; black
    `write_ppu_data $30  ; white
    `write_ppu_data $1a  ; medium-dark green
    `write_ppu_data $09  ; dark green
    `reset_ppu_addr

*   lda #0
    sta ppu_scroll
    ldx $0153
    lda table19,x
    clc
    adc $0153
    sta ppu_scroll

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

    jsr fade_out_palette
    jsr update_palette
    lda #$00
    sta $a3

*   lda #12  ; 11th part
    sta demo_part

    lda #%10010000
    sta ppu_ctrl
    lda #%00001110
    sta ppu_mask
    rts

; -----------------------------------------------------------------------------

nmisub20:
    ; Called by: NMI

    ; fill Name Tables with #$80
    ldx #$80
    jsr fill_name_tables

    jsr hide_sprites
    ldy #$00
    jsr fill_attribute_tables

    lda #%00000000
    sta ppu_ctrl
    sta ppu_mask

    lda #$00
    sta $89
    sta $8a
    sta $8b

    ; update first background subpalette
    `set_ppu_addr vram_palette+0*4
    `write_ppu_data $05  ; dark red
    `write_ppu_data $25  ; medium-light red
    `write_ppu_data $15  ; medium-dark red
    `write_ppu_data $30  ; white
    `reset_ppu_addr

    lda #$c8
    sta $013d

    `set_ppu_scroll 0, 200

    lda #$00
    sta $014c
    lda #1
    sta flag1

    lda #%10000000
    sta ppu_ctrl
    rts

; -----------------------------------------------------------------------------

nmisub21:
    ; Called by: NMI

    lda $013c
    cmp #$02
    beq +
    jmp nmisub21_1
*   ldy #$80

nmisub21_loop1_outer:
    lda #>[vram_name_table0+8*32+4]
    sta ppu_addr
    lda #<[vram_name_table0+8*32+4]
    clc
    adc $013b
    sta ppu_addr

    ldx #0
nmisub21_loop1_inner:
    sty ppu_data
    iny
    inx
    cpx #8
    bne nmisub21_loop1_inner

    lda $013b
    clc
    adc #32
    sta $013b
    cpy #$c0
    bne nmisub21_loop1_outer

nmisub21_loop2_outer:
    lda #>[vram_name_table0+16*32+4]
    sta ppu_addr
    lda #<[vram_name_table0+16*32+4]
    clc
    adc $013b
    sta ppu_addr

    ldx #0
nmisub21_loop2_inner:
    sty ppu_data
    iny
    inx
    cpx #8
    bne nmisub21_loop2_inner

    lda $013b
    clc
    adc #32
    sta $013b
    cpy #$00
    bne nmisub21_loop2_outer

    `reset_ppu_addr

    lda #$00
    sta $013b

nmisub21_loop3_outer:
    lda #>[vram_name_table0+8*32+20]
    sta ppu_addr
    lda #<[vram_name_table0+8*32+20]
    clc
    adc $013b
    sta ppu_addr

    ldx #0
nmisub21_loop3_inner:
    sty ppu_data
    iny
    inx
    cpx #8
    bne nmisub21_loop3_inner

    lda $013b
    clc
    adc #32
    sta $013b
    cpy #$c0
    bne nmisub21_loop3_outer

nmisub21_loop4_outer:
    lda #>[vram_name_table0+16*32+20]
    sta ppu_addr
    lda #<[vram_name_table0+16*32+20]
    clc
    adc $013b
    sta ppu_addr

    ldx #0
nmisub21_loop4_inner:
    sty ppu_data
    iny
    inx
    cpx #8
    bne nmisub21_loop4_inner

    lda $013b
    clc
    adc #32
    sta $013b
    cpy #0
    bne nmisub21_loop4_outer

    `reset_ppu_addr

nmisub21_1:
    lda $013c
    cmp #$a0
    bcc +
    jmp nmisub21_2

*   lda #$00
    sta ppu_scroll
    lda $013d
    clc
    sbc $013c
    sta ppu_scroll

nmisub21_2:
    lda ram1
    `chr_bankswitch 2
    lda #$00
    sta $89
    lda $013e
    cmp #$01
    beq nmisub21_3
    inc $013c
    lda $013c
    cmp #$c8
    beq +
    jmp nmisub21_3
*   lda #$01
    sta $013e

nmisub21_3:
    ldx #$00
    ldy #$00
    lda $013e
    cmp #$00
    beq nmisub21_5
    inc $8b
    inc $8a

nmisub21_loop5:
    ldx #1
    jsr sub14
    ldx $8a
    lda table20,x
    adc #$32
    sta $9a
    lda $9a
    adc #$28
    sta $9b
    lda $89
    cmp $9a
    bcc +
    bcs ++

*   lda #%00001110
    sta ppu_mask
    jmp nmisub21_4

*   lda $89
    cmp $9b
    bcs +
    lda #%11101110
    sta ppu_mask

nmisub21_4:
    jmp ++

*   lda #%00001110
    sta ppu_mask

*   lda $89
    clc
    adc $8b
    adc $8a
    clc
    sbc #$14
    tax
    lda table19,x
    clc
    adc $8b
    sta ppu_scroll
    lda $89
    clc
    adc $8b
    tax
    lda table20,x
    sta ppu_scroll

    ldx $8a
    lda table20,x
    clc
    adc #60
    sta $9b
    inc $89
    iny
    cpy #$91
    bne nmisub21_loop5

nmisub21_5:
    lda #%10010000
    sta ppu_ctrl
    lda #%00001110
    sta ppu_mask
    rts

; -----------------------------------------------------------------------------

write_row:
    ; Write X to VRAM 32 times.
    ; Called by: nmisub22

    ldy #0
*   stx ppu_data
    iny
    cpy #32
    bne -

    rts

; -----------------------------------------------------------------------------
; Unaccessed block ($f4f9)

unaccessed26:
    ldy #0
*   stx ppu_data
    iny
    cpy #32
    bne -
    rts

; -----------------------------------------------------------------------------

nmisub22:
    ; Called by: NMI

    ldx #$25
    jsr fill_nt_and_clear_at
    jsr hide_sprites

    lda #%00000000
    sta ppu_ctrl
    sta ppu_mask

    ; write 24 rows of tiles to the start of Name Table 0

    `set_ppu_addr vram_name_table0

    ldx #$25
    jsr write_row
    ldx #$25
    jsr write_row
    ldx #$25
    jsr write_row
    ldx #$25
    jsr write_row
    ldx #$25
    jsr write_row
    ldx #$25
    jsr write_row
    ldx #$25
    jsr write_row
    ldx #$25
    jsr write_row
    ldx #$25
    jsr write_row
    ldx #$25
    jsr write_row
    ldx #$25
    jsr write_row
    ldx #$25
    jsr write_row
    ldx #$25
    jsr write_row
    ldx #$25
    jsr write_row
    ldx #$25
    jsr write_row
    ldx #$39
    jsr write_row
    ldx #$37
    jsr write_row
    ldx #$37
    jsr write_row
    ldx #$37
    jsr write_row
    ldx #$37
    jsr write_row
    ldx #$37
    jsr write_row
    ldx #$37
    jsr write_row
    ldx #$37
    jsr write_row
    ldx #$38
    jsr write_row

    `reset_ppu_addr

    ; update first background subpalette from table18b
    `set_ppu_addr vram_palette+0*4
    lda table18b+0
    sta ppu_data
    lda table18b+1
    sta ppu_data
    lda table18b+2
    sta ppu_data
    lda table18b+3
    sta ppu_data
    `reset_ppu_addr

    ; update first sprite subpalette from table18c
    `set_ppu_addr vram_palette+4*4
    lda table18c+0
    sta ppu_data
    lda table18c+1
    sta ppu_data
    lda table18c+2
    sta ppu_data
    lda table18c+3
    sta ppu_data
    `reset_ppu_addr

    ldx data7
nmisub22_loop:
    txa
    asl
    asl
    tay

    lda table49,x
    sta sprite_page+48*4+sprite_y,y
    lda table51,x
    sta sprite_page+48*4+sprite_tile,y
    lda #%00000010
    sta sprite_page+48*4+sprite_attr,y
    lda table48,x
    sta sprite_page+48*4+sprite_x,y

    lda table50,x
    sta $011e,x
    dex
    cpx #255
    bne nmisub22_loop

    lda #$00
    sta $0100
    lda #1
    sta flag1
    lda #$00
    sta $89
    sta $8a
    lda #$00
    sta $8f
    rts

; -----------------------------------------------------------------------------

nmisub23:
    ; Called by: NMI

    inc $0100
    ldx $0100
    lda woman_sprite_x,x
    sta $9a
    lda table22,x
    sta $9b

    `sprite_dma

    ldx data7
nmisub23_loop1:
    txa
    asl
    asl
    tay

    lda table49,x
    clc
    adc $9a
    sta sprite_page+48*4+sprite_y,y
    lda sprite_page+48*4+sprite_x,y
    clc
    adc table50,x
    sta sprite_page+48*4+sprite_x,y

    dex
    cpx #7
    bne nmisub23_loop1

nmisub23_loop2:
    txa
    asl
    asl
    tay

    lda table49,x
    clc
    adc $9b
    sta sprite_page+48*4+sprite_y,y
    lda sprite_page+48*4+sprite_x,y
    clc
    adc table50,x
    sta sprite_page+48*4+sprite_x,y

    dex
    cpx #255
    bne nmisub23_loop2

    `chr_bankswitch 0
    inc $8a
    lda $8a
    cmp #$08
    beq +
    jmp nmisub23_2
*   lda #$00
    sta $8a
    inc $8f
    lda $8f
    cmp #$eb
    beq +
    jmp nmisub23_1
*   lda #0
    sta flag1
    lda #7  ; 7th part
    sta demo_part

nmisub23_1:
    lda #>[vram_name_table0+19*32+1]
    sta ppu_addr
    lda #<[vram_name_table0+19*32+1]
    sta ppu_addr

    ldx #0
nmisub23_loop3:
    txa
    clc
    adc $8f
    tay
    lda table11,y
    clc
    sbc #$36
    sta ppu_data
    inx
    cpx #31
    bne nmisub23_loop3

    `reset_ppu_addr

nmisub23_2:
    inc $89
    ldx $89
    lda $8a
    sta ppu_scroll
    lda table20,x
    sta ppu_scroll

    lda table20,x
    sta $9a

    ; set up sprites 0-5
    ; Y        : (147, 151 or 155) - $9a
    ; tile     : #$25
    ; attribute: %00000000
    ; X        : 0 or 248

    lda #148
    clc
    sbc $9a
    sta sprite_page+0*4+0
    lda #$25
    sta sprite_page+0*4+1
    lda #%00000000
    sta sprite_page+0*4+2
    lda #248
    sta sprite_page+0*4+3

    lda #152
    clc
    sbc $9a
    sta sprite_page+1*4+0
    lda #$25
    sta sprite_page+1*4+1
    lda #%00000000
    sta sprite_page+1*4+2
    lda #248
    sta sprite_page+1*4+3

    lda #156
    clc
    sbc $9a
    sta sprite_page+2*4+0
    lda #$25
    sta sprite_page+2*4+1
    lda #%00000000
    sta sprite_page+2*4+2
    lda #248
    sta sprite_page+2*4+3

    lda #148
    clc
    sbc $9a
    sta sprite_page+3*4+0
    lda #$25
    sta sprite_page+3*4+1
    lda #%00000000
    sta sprite_page+3*4+2
    lda #0
    sta sprite_page+3*4+3

    lda #152
    clc
    sbc $9a
    sta sprite_page+4*4+0
    lda #$25
    sta sprite_page+4*4+1
    lda #%00000000
    sta sprite_page+4*4+2
    lda #0
    sta sprite_page+4*4+3

    lda #156
    clc
    sbc $9a
    sta sprite_page+5*4+0
    lda #$25
    sta sprite_page+5*4+1
    lda #%00000000
    sta sprite_page+5*4+2
    lda #0
    sta sprite_page+5*4+3

    lda #%10000000
    sta ppu_ctrl
    lda #%00011110
    sta ppu_mask
    rts

; -----------------------------------------------------------------------------

fill_attribute_tables:
    ; Fill Attribute Tables 0 and 2 with Y.
    ; Called by: init, nmisub06, nmisub08, nmisub14, nmisub16
    ; game_over_screen, greets_screen, nmisub20

    `set_ppu_addr vram_attr_table0

    ldx #64
*   sty ppu_data
    dex
    bne -

    `set_ppu_addr vram_attr_table2

    ldx #64
*   sty ppu_data
    dex
    bne -

    `reset_ppu_addr
    rts

; -----------------------------------------------------------------------------

fill_attribute_tables_top:
    ; Fill top parts (first 32 bytes) of Attribute Tables 0 and 2 with Y.
    ; Called by: nmisub08

    `set_ppu_addr vram_attr_table0

    ldx #32
*   sty ppu_data
    dex
    bne -

    `set_ppu_addr vram_attr_table2

    ldx #32
*   sty ppu_data
    dex
    bne -

    `reset_ppu_addr
    rts

; -----------------------------------------------------------------------------
; Unaccessed block ($f7d0).

    `set_ppu_addr vram_attr_table0+4*8

    ldx #32
*   sty ppu_data
    dex
    bne -

    `set_ppu_addr vram_attr_table2+4*8

    ldx #32
*   sty ppu_data
    dex
    bne -

    `reset_ppu_addr
    rts

; -----------------------------------------------------------------------------

fill_name_tables:
    ; Fill Name Tables 0 and 2 with byte X and set flag1.
    ; Called by: nmisub02, nmisub06, nmisub08, nmisub12, nmisub14
    ; game_over_screen, greets_screen, nmisub20

    ; X    -> $8e
    ; 0    -> Y   (why?)
    ; #$3c -> $9a
    stx $8e
    ldy #0
    lda #$3c
    sta $9a

    lda #%00000000
    sta ppu_ctrl  ; disable NMI
    sta ppu_mask  ; hide sprites and background

    ; fill the Name Tables with the specified byte

    `set_ppu_addr vram_name_table0

    ldx #0
    ldy #0
*   lda $8e
    sta ppu_data
    sta ppu_data
    sta ppu_data
    sta ppu_data
    inx
    bne -

    `set_ppu_addr vram_name_table2

    ldx #0
    ldy #0
*   lda $8e
    sta ppu_data
    sta ppu_data
    sta ppu_data
    sta ppu_data
    inx
    bne -

    lda #1
    sta flag1

    `reset_ppu_addr
    rts

; -----------------------------------------------------------------------------

fill_nt_and_clear_at:
    ; Fill Name Tables 0, 1 and 2 with byte X.
    ; Clear Attribute Tables 0 and 1.
    ; Called by: init, nmisub04, nmisub10, nmisub22

    ; X    -> $8e
    ; #0   -> Y
    ; #$3c -> $9a
    stx $8e
    ldy #$00
    lda #$3c
    sta $9a

    lda #%00000000
    sta ppu_ctrl
    sta ppu_mask

    ; clear Attribute Table 0
    `set_ppu_addr vram_attr_table0
    ldx #0
*   lda #%00000000
    sta ppu_data
    inx
    cpx #64
    bne -

    ; clear Attribute Table 1
    `set_ppu_addr vram_attr_table1
    ldx #0
*   lda #%00000000
    sta ppu_data
    inx
    cpx #64
    bne -

    ; clear Name Table 0 (960 bytes)

    lda #>vram_name_table0
    sta ppu_addr
    lda #<vram_name_table0
    sta ppu_addr

    ldx #0
    ldy #0  ; why?

*   lda $8e
    sta ppu_data
    inx
    bne -

*   lda $8e
    sta ppu_data
    inx
    bne -

*   lda $8e
    sta ppu_data
    inx
    bne -

*   lda $8e
    sta ppu_data
    inx
    cpx #192
    bne -

    ; clear Name Table 1 (960 bytes)

    lda #>vram_name_table1
    sta ppu_addr
    lda #<vram_name_table1
    sta ppu_addr

    ldx #0
    ldy #0

*   lda $8e
    sta ppu_data
    inx
    bne -

*   lda $8e
    sta ppu_data
    inx
    bne -

*   lda $8e
    sta ppu_data
    inx
    bne -

*   lda $8e
    sta ppu_data
    inx
    cpx #192
    bne -

    ; clear Name Table 2 (960 bytes)

    lda #>vram_name_table2
    sta ppu_addr
    lda #<vram_name_table2
    sta ppu_addr

    ldx #0
    ldy #0

*   lda $8e
    sta ppu_data
    inx
    bne -

*   lda $8e
    sta ppu_data
    inx
    bne -

*   lda $8e
    sta ppu_data
    inx
    bne -

*   lda $8e
    sta ppu_data
    inx
    cpx #192
    bne -

    ; 1    -> flag1
    ; #$72 -> $96
    lda #1
    sta flag1
    lda #$72
    sta $96

    `reset_ppu_addr
    `reset_ppu_scroll

    lda #%00000000
    sta ppu_ctrl
    lda #%00011110
    sta ppu_mask
    rts

; -----------------------------------------------------------------------------

nmi:
    ; Non-maskable interrupt routine
    ; Called by: NMI vector

    lda ppu_status  ; clear VBlank flag

    lda demo_part
    cmp #0
    beq nmi_jump_table+1*3
    cmp #1
    beq nmi_jump_table+2*3
    cmp #2
    beq nmi_jump_table+3*3
    cmp #3
    beq nmi_jump_table+4*3
    cmp #4
    beq nmi_jump_table+5*3
    cmp #5
    beq nmi_jump_table+6*3
    cmp #6
    beq nmi_jump_table+7*3
    cmp #7
    beq nmi_jump_table+8*3
    cmp #9
    beq nmi_jump_table+9*3
    cmp #10
    beq nmi_jump_table+10*3
    cmp #11
    beq nmi_jump_table+11*3
    cmp #12
    beq nmi_jump_table+12*3
    cmp #13
    beq nmi_jump_table+13*3

nmi_jump_table:
    jmp nmi_exit    ;  0*3 (unaccessed, $f980)
    jmp nmi_part1   ;  1*3
    jmp nmi_part4   ;  2*3
    jmp nmi_part2   ;  3*3
    jmp nmi_part9   ;  4*3
    jmp nmi_part5   ;  5*3
    jmp nmi_part6   ;  6*3
    jmp nmi_part8   ;  7*3
    jmp nmi_part7   ;  8*3
    jmp nmi_part13  ;  9*3
    jmp nmi_part10  ; 10*3
    jmp nmi_part3   ; 11*3
    jmp nmi_part11  ; 12*3
    jmp nmi_part12  ; 13*3

; -----------------------------------------------------------------------------

nmi_part1:
    ; "Greetings! We come from..."

    lda flag1
    cmp #0
    beq +
    jmp ++
*   lda #1
    sta flag1
*   jsr nmisub01
    jsr sub12
    inc $93
    inc $93
    inc $94
    inc $94
    lda $94
    cmp #$e6
    beq +
    jmp nmi_part1_exit
*   inc $95
    lda #$00
    sta $94
nmi_part1_exit:
    jmp nmi_exit

; -----------------------------------------------------------------------------

nmi_part4:
    ; horizontal color bars

    lda flag1
    cmp #0
    beq +
    jmp ++
*   jsr nmisub10
*   jsr nmisub11
    jsr sub12
    inc $98
    lda $98
    cmp #$ff
    beq +
    jmp nmi_part4_exit
*   inc $99
    lda $99
    cmp #$03
    beq +
    jmp nmi_part4_exit
*   lda #4
    sta demo_part
    lda #0
    sta flag1
nmi_part4_exit:
    jmp nmi_exit

; -----------------------------------------------------------------------------

nmi_part2:
    ; "wAMMA - Quantum Disco Brothers"

    lda flag1
    cmp #0
    beq +
    jmp ++
*   jsr nmisub02
*   jsr nmisub03
    jsr sub12
    inc $ab
    lda $ab
    cmp #$ff
    beq +
    jmp nmi_part2_exit
*   inc $ac
    lda $ac
    cmp #$03
    beq +
    jmp nmi_part2_exit
*   lda #11
    sta demo_part
    lda #0
    sta flag1
nmi_part2_exit:
    jmp nmi_exit

; -----------------------------------------------------------------------------

nmi_part9:
    ; credits

    lda flag1
    cmp #0
    beq +
    jmp ++
*   jsr nmisub12
*   jsr nmisub13
    jsr sub12
    jmp nmi_exit

; -----------------------------------------------------------------------------

nmi_part5:
    ; the woman

    lda flag1
    cmp #0
    beq +
    jmp ++
*   jsr nmisub14
*   jsr nmisub15
    jsr sub12
    inc $a9
    lda $a9
    cmp #$ff
    beq +
    jmp nmi_part5_exit
*   inc $aa
    lda $aa
    cmp #$04
    beq +
    jmp nmi_part5_exit
*   lda #5
    sta demo_part
    lda #0
    sta flag1
nmi_part5_exit:
    jmp nmi_exit

; -----------------------------------------------------------------------------

nmi_part6:
    ; "It is Friday..."

    lda flag1
    cmp #0
    beq +
    jmp ++
*   jsr nmisub22
*   jsr nmisub23
    jsr sub12
    jmp nmi_exit

; -----------------------------------------------------------------------------

nmi_part8:
    ; Bowser's spaceship

    lda flag1
    cmp #0
    beq +
    jmp ++
*   jsr nmisub16
*   jsr nmisub17
    jsr sub12
    inc $0135
    lda $0135
    cmp #$ff
    beq +
    jmp nmi_part8_exit
*   inc $0136
    lda $0136
    cmp #$03
    beq +
    jmp nmi_part8_exit
*   lda #3
    sta demo_part
    lda #0
    sta flag1
nmi_part8_exit:
    jmp nmi_exit

; -----------------------------------------------------------------------------

nmi_part7:
    ; Coca Cola cans

    lda flag1
    cmp #0
    beq +
    jmp ++
*   jsr nmisub20
*   jsr nmisub21
    jsr sub12
    inc $013f
    lda $013f
    cmp #$ff
    beq +
    jmp ++
*   inc $0140
*   lda $0140
    cmp #$03
    bne nmi_part7_exit
    lda $013f
    cmp #$ae
    bne nmi_part7_exit
    lda #6
    sta demo_part
    lda #0
    sta flag1
nmi_part7_exit:
    jmp nmi_exit

; -----------------------------------------------------------------------------

nmi_part13:
    ; full-screen horizontal color bars after "game over - continue?"; the
    ; demo freezes soon afterwards

    lda flag1
    cmp #0
    beq +
    jmp ++
*   jsr nmisub04
*   jsr nmisub05
    inc $0141
    lda $0141
    cmp #$ff
    beq +
    jmp $fb3d
*   inc $0142
    lda $0142
    cmp #$0e
    beq +
    jmp nmi_part13_exit
*   lda #0
    sta demo_part
    lda #0
    sta flag1
nmi_part13_exit:
    jmp nmi_exit

; -----------------------------------------------------------------------------

nmi_part10:
    ; checkered wavy animation

    lda flag1
    cmp #0
    beq +
    jmp ++
*   jsr nmisub06
*   jsr nmisub07
    jsr sub12
    inc $0143
    lda $0143
    cmp #$ff
    beq +
    jmp ++
*   inc $0144
*   lda $0144
    cmp #$02
    bne nmi_part10_exit
    lda $0143
    cmp #$af
    bne nmi_part10_exit
    lda #12
    sta demo_part
    lda #0
    sta flag1
nmi_part10_exit:
    jmp nmi_exit

; -----------------------------------------------------------------------------

nmi_part3:
    ; red&purple gradient

    lda flag1
    cmp #0
    beq +
    jmp ++
*   jsr nmisub08
*   jsr nmisub09
    jsr sub12
    inc $0145
    lda $0145
    cmp #$ff
    beq +
    jmp nmi_part3_exit
*   inc $0146
    lda $0146
    cmp #$03
    beq +
    jmp nmi_part3_exit
*   lda #1
    sta demo_part
    lda #0
    sta flag1
nmi_part3_exit:
    jmp nmi_exit

; -----------------------------------------------------------------------------

nmi_part11:
    ; greets

    lda flag1
    cmp #0
    beq +
    jmp ++
*   jsr greets_screen
*   jsr nmisub19
    jsr sub12
    inc $014f
    lda $014f
    cmp #$ff
    beq +
    jmp ++
*   inc $0150
*   lda $0150
    cmp #$03
    bne nmi_part11_exit
    lda $014f
    cmp #$96
    bne nmi_part11_exit
    lda #13
    sta demo_part
    lda #0
    sta flag1
nmi_part11_exit:
    jmp nmi_exit

; -----------------------------------------------------------------------------

nmi_part12:
    ; "GAME OVER - CONTINUE?"

    lda flag1
    cmp #0
    beq +
    jmp ++
*   jsr game_over_screen
*   jsr nmisub18
    inc $0151
    lda $0151
    cmp #$ff
    beq +
    jmp ++
*   inc $0152
*   lda $0152
    cmp #$0a
    bne nmi_part12_exit
    lda $0151
    cmp #$a0
    bne nmi_part12_exit
    lda #9
    sta demo_part
    lda #0
    sta flag1
nmi_part12_exit:
    jmp nmi_exit

; -----------------------------------------------------------------------------

nmi_exit:
    rti

; -----------------------------------------------------------------------------

irq:
    ; IRQ routine (unaccessed, $fc26)
    rti

; -----------------------------------------------------------------------------

    ; Interrupt vectors (at the end of PRG ROM; IRQ unaccessed)
    .advance $fffa, pad_byte
    .word nmi, init, irq
