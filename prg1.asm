; second half of PRG ROM except interrupt routines&vectors

; -----------------------------------------------------------------------------

init:

    sei
    cld
    jsr wait_vbl

    ; clear RAM
    ldx #0
    txa
*   sta $00,x
    sta $0100,x
    sta $0200,x
    sta $0300,x
    sta $0400,x
    sta sprite_page,x
    sta $0600,x
    sta $0700,x
    inx
    bne -

    jsr init_graphics_and_sound
    jsr init_palette_copy
    jsr update_palette

    ; update fourth sprite subpalette
    `set_ppu_addr vram_palette+7*4
    `write_ppu_data $0f  ; black
    `write_ppu_data $1c  ; medium-dark cyan
    `write_ppu_data $2b  ; medium-light green
    `write_ppu_data $39  ; light yellow
    `reset_ppu_addr

    ; the demo section to run
    lda #0
    sta nmi_task

    lda #%00000000
    sta ppu_ctrl
    lda #%00011110
    sta ppu_mask

    ldx #$ff
    jsr sub59
    jsr sub28

    lda #%00000000
    sta ppu_ctrl
    sta ppu_mask

    ldy #$00
    jsr sub56
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

*   lda nmi_task
    cmp #9  ; last section?
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

*   bit ppu_status
    bpl -
    rts

; -----------------------------------------------------------------------------

init_graphics_and_sound:
    ; Called by: init, sub38, sub40, sub41, sub42, sub43, sub44, sub50, sub54

    ; hide all sprites (set Y position outside screen)
    ldx #0
*   lda #245
    sta sprite_page,x
    `inx4
    bne -
    rts

    ; disable rendering
    lda #%00000000
    sta ppu_ctrl
    sta ppu_mask
    lda #%00000000
    sta ppu_ctrl

    ; clear sound registers $4000...$400e
    lda #$00
    ldx #0
*   sta apu_regs,x
    inx
    cpx #15
    bne -

    ; more sound stuff
    lda #$c0
    sta apu_counter

    ; initialize palette
    jsr init_palette_copy
    jsr update_palette
    rts

; -----------------------------------------------------------------------------

init_palette_copy:
    ; Copy the palette_table array to the palette_copy array.
    ; Args: none
    ; Called by: init, init_graphics_and_sound, sub34, sub36, sub38, sub40,
    ; sub43, sub46, sub49

    ldx #0
*   lda palette_table,x
    sta palette_copy,x
    inx
    cpx #32
    bne -
    rts

; -----------------------------------------------------------------------------

clear_palette_copy:
    ; Fill the palette_copy array with black.
    ; Args: none
    ; Called by: sub48

    ldx #0
*   lda #$0f
    sta palette_copy,x
    inx
    cpx #32
    bne -
    rts

; -----------------------------------------------------------------------------

update_palette:
    ; Copy the palette_copy array to the PPU.
    ; Args: none
    ; Called by: init, init_graphics_and_sound, sub31, sub34, sub36, sub38,
    ; sub40, sub41, sub43, sub46, sub48, sub49

    `set_ppu_addr vram_palette+0*4

    ldx #0
*   lda palette_copy,x
    sta ppu_data
    inx
    cpx #32
    bne -

    `reset_ppu_addr
    rts

; -----------------------------------------------------------------------------

sub19:

    stx $88
    lda #0
    sta $87
sub19_loop1:
    lda $86
    `add_imm $55
    bcc +
*   sta $86
    `inc_lda $87
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
*   lda palette_copy,y     ; start loop
    sta temp1
    and #%00110000
    `lsr4
    tax
    lda temp1
    and #%00001111
    ora table18,x
    sta palette_copy,y
    iny
    cpy #32
    bne -

    rts

; -----------------------------------------------------------------------------

sub21:

    `set_ppu_addr vram_palette+0*4

    lda $e8
    cmp #8
    bcc +
    lda $e8
    sta ppu_data
    jmp sub21_exit
*   `write_ppu_data $3f  ; black
sub21_exit:
    rts

; -----------------------------------------------------------------------------

sub22:

    stx $a5
    sty $a6
    lda $9a
    sta $a7

    lda #$00
    sta $9a
    sta $9b
    sta $9c

sub22_loop:   ; start outer loop
    ldx #0
    lda #$00
    sta $9a

*   lda $9c       ; start inner loop
    `add_mem $a7
    ldy $a8
    sta sprite_page+1,y
    txa
    adc $a5
    ldy $a8
    sta sprite_page+3,y
    lda $9b
    `add_mem $a6

    ldy $a8
    sta sprite_page,y

    lda #$03
    ldy $a8
    sta sprite_page+2,y
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
    ldx #0
    lda #$00
    sta $9a

*   lda $9c       ; start inner loop
    `add_mem $a7
    ldy $a8
    sta sprite_page+1,y
    txa
    adc $a5
    ldy $a8
    sta sprite_page+3,y
    lda $9b
    `add_mem $a6

    ldy $a8
    sta sprite_page,y

    lda #$02
    ldy $a8
    sta sprite_page+2,y
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
    ldx #0
    lda #$00
    sta $9a

*   lda $9c       ; start inner loop
    `add_mem $a7
    ldy $a8
    sta sprite_page+1,y
    txa
    adc $a5
    ldy $a8
    sta sprite_page+3,y
    lda $9b
    `add_mem $a6

    ldy $a8
    sta sprite_page,y

    lda #$02
    ldy $a8
    sta sprite_page+2,y
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

    ldx #0
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
    sta sprite_page,x
    sta $0154,y
    lda $9b
    sta $016a,y
    lda #$01
    sta $0180,y
    lda table10,y
    sta sprite_page+1,x
    lda #$00
    sta sprite_page+2,x
    lda $9a
    `add_imm 40
    sta sprite_page+3,x

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
    sta ppu_addr
    lda $92
    sta ppu_addr

    ldx #$00
    ldy #$00
    stx $90

*   ldy $90        ; start loop
    lda (ptr1),y
    clc
    sbc #$40
    tay
    ldx table17,y
    stx ppu_data
    inx
    stx ppu_data
    `inc_lda $90
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
    stx ppu_data
    inx
    stx ppu_data
    `inc_lda $90
    cmp #$10
    bne -

    `reset_ppu_addr
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

    lda sprite_page+45*4+0,y
    clc
    sbc table46,x
    sta sprite_page+45*4+0,y

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
    sta sprite_page+45*4+0,y

    lda table47,x
    sta sprite_page+45*4+1,y

    lda #%00000011
    sta sprite_page+45*4+2,y

    lda table44,x
    sta sprite_page+45*4+3,y

    lda table46,x
    sta $011e,x

    dex
    cpx #255
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
    beq sub29_01
    cmp #10
    beq sub29_jump_table+10*3
    jmp sub29_11

sub29_01:
    lda #0
    sta ppu_scroll
    ldx $96
    lda table19,x
    `add_mem $96
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

sub29_jump_table:
    jmp sub29_11  ;  0*3
    jmp sub29_02  ;  1*3
    jmp sub29_03  ;  2*3
    jmp sub29_04  ;  3*3
    jmp sub29_05  ;  4*3
    jmp sub29_06  ;  5*3
    jmp sub29_07  ;  6*3
    jmp sub29_08  ;  7*3
    jmp sub29_09  ;  8*3
    jmp sub29_11  ;  9*3
    jmp sub29_10  ; 10*3

sub29_02:
    ; pointer 0 -> ptr1
    lda pointers+0*2+0
    sta ptr1+0
    lda pointers+0*2+1
    sta ptr1+1

    ldx #$20
    ldy #$00
    jsr sub26

    lda #0
    sta ppu_scroll
    lda $96
    sta ppu_scroll

    `dec_lda $96
    cmp #$f0
    bcs +
    jmp sub29_11
*   lda #$00
    sta $96
    jmp sub29_11

sub29_03:
    lda #$00
    sta $96
    jmp sub29_11

sub29_04:
    ; pointer 1 -> ptr1
    lda pointers+1*2+0
    sta ptr1+0
    lda pointers+1*2+1
    sta ptr1+1

    ldx #$20
    ldy #$a0
    jsr sub26
    jmp sub29_11

sub29_05:
    ; pointer 2 -> ptr1
    lda pointers+2*2+0
    sta ptr1+0
    lda pointers+2*2+1
    sta ptr1+1

    ldx #$21
    ldy #$20
    jsr sub26
    jmp sub29_11

sub29_06:
    ; pointer 3 -> ptr1
    lda pointers+3*2+0
    sta ptr1+0
    lda pointers+3*2+1
    sta ptr1+1

    ldx #$21
    ldy #$a0
    jsr sub26
    jmp sub29_11

sub29_07:
    ; pointer 4 -> ptr1
    lda pointers+4*2+0
    sta ptr1+0
    lda pointers+4*2+1
    sta ptr1+1

    ldx #$22
    ldy #$40
    jsr sub26
    jmp sub29_11

sub29_08:
    ; pointer 5 -> ptr1
    lda pointers+5*2+0
    sta ptr1+0
    lda pointers+5*2+1
    sta ptr1+1

    ldx #$22
    ldy #$c0
    jsr sub26
    jmp sub29_11

sub29_09:
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
    lda #2  ; 2nd section
    sta nmi_task
    lda #0
    sta flag1
    jmp sub29_11

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
    sta sprite_page+0*4+0

    lda table20,x
    `add_imm $6e
    sta sprite_page+0*4+3

    lda table19,x
    `add_imm $58
    sta sprite_page+1*4+0

    lda table20,x
    `add_imm $76
    sta sprite_page+1*4+3

    lda table19,x
    `add_imm $60
    sta sprite_page+2*4+0

    lda table20,x
    `add_imm $6e
    sta sprite_page+2*4+3

    lda table19,x
    `add_imm $60
    sta sprite_page+3*4+0

    lda table20,x
    `add_imm $76
    sta sprite_page+3*4+3

    lda table20,x
    `add_imm $58
    sta sprite_page+4*4+0

    lda table19,x
    `add_imm $6e
    sta sprite_page+4*4+3

    lda table20,x
    `add_imm $58
    sta sprite_page+5*4+0

    lda table19,x
    `add_imm $76
    sta sprite_page+5*4+3

    lda table20,x
    `add_imm $60
    sta sprite_page+6*4+0

    lda table19,x
    `add_imm $6e
    sta sprite_page+6*4+3

    lda table20,x
    `add_imm $60
    sta sprite_page+7*4+0

    lda table19,x
    `add_imm $75
    sta sprite_page+7*4+3

    jmp sub29_13

sub29_12:
    ; move sprites 0...7:
    ; 0, 4: up left
    ; 1, 5: up right
    ; 2, 6: down left
    ; 3, 7: down right

    dec sprite_page+0*4+0
    dec sprite_page+0*4+3

    dec sprite_page+1*4+0
    inc sprite_page+1*4+3

    inc sprite_page+2*4+0
    dec sprite_page+2*4+3

    inc sprite_page+3*4+0
    inc sprite_page+3*4+3

    dec sprite_page+4*4+0
    dec sprite_page+4*4+3

    dec sprite_page+5*4+0
    inc sprite_page+5*4+3

    inc sprite_page+6*4+0
    dec sprite_page+6*4+3

    inc sprite_page+7*4+0
    inc sprite_page+7*4+3

sub29_13:
    jsr sub27

    `sprite_dma
    rts

; -----------------------------------------------------------------------------

sub30:

    ldx #$00
    jsr sub58
    ldy #$00
    ldy #$00

    ; fill rows 1-8 of Name Table 2 with $00...$ff
    `set_ppu_addr vram_name_table2+32
    ldx #0
*   stx ppu_data
    inx
    bne -
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

sub31:

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
    `add_mem $014e
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
    sta sprite_page+23*4+0,y
    lda table25,x
    sta sprite_page+23*4+1,y
    lda table26,x
    sta sprite_page+23*4+2,y
    lda table27,x
    `add_mem $012e
    sta sprite_page+23*4+3,y

    cpx #0
    beq +
    dex
    jmp -

*   lda #129
    sta sprite_page+24*4+0
    lda #$e5
    sta sprite_page+24*4+1
    lda #%00000001
    sta sprite_page+24*4+2
    lda #214
    sta sprite_page+24*4+3

    lda #97
    sta sprite_page+25*4+0
    lda #$f0
    sta sprite_page+25*4+1
    lda #%00000010
    sta sprite_page+25*4+2
    lda #230
    sta sprite_page+25*4+3

    ; update fourth color of first background subpalette
    `set_ppu_addr vram_palette+0*4+3
    `write_ppu_data $30  ; white
    `reset_ppu_addr

sub31_1:
    lda $ac
    cmp #$02
    bne sub31_2
    lda $ab
    cmp #$32
    bcc sub31_2

    ldx #0
    ldy #0
sub31_loop:
    lda $0180,x
    cmp #$01
    bne +
    lda #$a0
    clc
    adc $016a,x
    sta $9a
    lda $0154,x
    sta sprite_page,y
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
    bne sub31_loop

sub31_2:
    lda $ac
    cmp #$02
    bne +
    lda $ab
    cmp #$c8
    bcc +
    `inc_lda $a3
    cmp #$04
    bne +
    jsr sub20
    jsr update_palette
    lda #$00
    sta $a3
*   jsr sub27
    lda #2  ; 2nd section
    sta nmi_task
    rts

; -----------------------------------------------------------------------------

sub32:

    lda #$00
    ldx #0
*   sta pulse1_ctrl,x
    inx
    cpx #15
    bne -

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
    jsr sub59
    lda #1
    sta flag1
    rts

; -----------------------------------------------------------------------------

sub33:

    inc $89
    ldx $8a
    lda table22,x
    `add_imm $96
    sta $8b
    `dec_ldx $8a
    lda table20,x
    sta $8d

    lda #%10000100
    sta ppu_ctrl

    lda #$00
    sta $89
    ldy #$9f

sub33_loop:

    ldx #25
*   dex
    bne -

    `set_ppu_addr_via_x vram_palette+0*4

    `inc_lda $8c
    cmp #$05
    beq +
    jmp ++
*   inc $89
    lda #$00
    sta $8c
*   `inc_lda $89
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
    bne sub33_loop

    lda #%00000110
    sta ppu_mask
    lda #%10010000
    sta ppu_ctrl
    rts

; -----------------------------------------------------------------------------

sub34:

    ldx #$00
    jsr sub58

    lda #%00000000
    sta ppu_ctrl
    sta ppu_mask

    ldy #$14
    jsr sub56
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

sub35:

    `chr_bankswitch 1
    lda $0148
    cmp #$00
    beq +
    jmp sub35_1
*   dec $8a

    ldx #0
    lda #$00
    sta $89
*   lda $89  ; start loop
    adc $8a
    tay
    lda table19,y
    sta $0600,x
    lda $89
    `add_mem ram1
    sta $89
    inx
    cpx #64
    bne -

    ldx #0
    ldy #0
    lda #$00
    sta $9a

sub35_loop1:  ; start outer loop
    ; $2100 + [$9a] -> ppu_addr
    lda #$21
    sta ppu_addr
    lda $9a
    sta ppu_addr

    ldy #0
*   lda $0600,x  ; start inner loop
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
    ldx #64
    lda #$00
    sta $89

*   lda $89  ; start loop
    adc $8a
    tay
    lda table19,y
    sta $0600,x
    lda $89
    `add_mem ram1
    sta $89
    inx
    cpx #128
    bne -

    ldx #$7f
    lda #$00
    sta $9a

sub35_loop2:  ; start outer loop
    lda #$22
    sta ppu_addr
    lda $9a
    sta ppu_addr

    ldy #0
*   lda $0600,x  ; start inner loop
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
    `reset_ppu_addr

    lda #$00
    sta $89

*   ldx #$04   ; start loop
    jsr sub19
    lda $89
    `add_mem $8b
    tax
    lda table19,x
    sta ppu_scroll
    lda #0
    sta ppu_scroll
    inc $89
    iny
    cpy #$98
    bne -

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

sub36:

    ldx #$00
    jsr sub58
    jsr init_palette_copy
    jsr update_palette

    lda #%00000000
    sta ppu_ctrl
    sta ppu_mask

    ldy #$ff
    jsr sub56
    ldy #$55
    jsr sub57

    ; update first color of fourth background subpalette
    `set_ppu_addr vram_palette+3*4
    `write_ppu_data $0f  ; black
    `reset_ppu_addr

    lda #1
    sta flag1
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

*   ldx #0
    ldy #0
    lda #$00

    sta $9a
sub37_loop1:  ; start outer loop
    ; $2100 + [$9a] -> ppu_addr
    lda #$21
    sta ppu_addr
    lda $9a
    sta ppu_addr

    ldy #0
*   lda $0600,x  ; start inner loop
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
    sta ppu_addr
    lda $9a
    sta ppu_addr

    ldy #0
*   lda $0600,x  ; start inner loop
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

sub38:

    ldx #$ff
    jsr sub59
    jsr sub12
    jsr init_palette_copy
    jsr update_palette
    lda #1
    sta flag1
    jsr init_graphics_and_sound

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

sub39:

    dec $8c
    `inc_lda $8b
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
    jsr sub19
    ldx #$01
    jsr sub19

    ; update first color of first background subpalette
    `set_ppu_addr_via_x vram_palette+0*4
    `write_ppu_data $0f  ; black
    `reset_ppu_addr

    lda #$00
    sta $89

    ldy #85
sub39_loop:  ; start outer loop

    ldx #25
*   dex      ; start inner loop
    bne -

    `set_ppu_addr_via_x vram_palette+0*4

    ldx $8a
    lda table22,x
    sta $9a
    `dec_lda $89
    `add_mem $8a
    tax
    lda table20,x
    clc
    sbc $9a
    adc $8c
    tax
    lda table23,x
    sta ppu_data
    dey
    bne sub39_loop

    `reset_ppu_addr

    ; update first color of first background subpalette
    `set_ppu_addr_via_x vram_palette+0*4
    `write_ppu_data $0f  ; black
    `reset_ppu_addr
    rts

; -----------------------------------------------------------------------------

sub40:

    ldx #$ff
    jsr sub58
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
    sta ppu_data
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
    `inc_lda $9f
    cmp #$03
    bne sub40_loop1

    ldx #0
sub40_loop3:  ; start outermost loop

    ldy #0
sub40_loop4:  ; start middle loop

    ldx #0
*   txa           ; start innermost loop
    `add_mem $9e
    sta ppu_data
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

    lda #$f0
    ldy #0
sub40_loop5:  ; start outer loop

    ldx #$f0
*   stx ppu_data  ; start inner loop
    inx
    cpx #$f8
    bne -

    iny
    cpy #8
    bne sub40_loop5

    `reset_ppu_addr

    `inc_lda $a0
    cmp #$02
    bne +
    jmp sub40_2

*   `set_ppu_addr vram_name_table2

    jmp sub40_1

sub40_2:
    ; clear Attribute Table 0
    `set_ppu_addr vram_attr_table0
    ldx #0
*   lda #$00
    sta ppu_data
    inx
    cpx #64
    bne -
    `reset_ppu_addr

    ; clear Attribute Table 2
    `set_ppu_addr vram_attr_table2
    ldx #0
*   lda #$00
    sta ppu_data
    inx
    cpx #64
    bne -
    `reset_ppu_addr

    jsr init_graphics_and_sound
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

sub41:

    `sprite_dma

    lda $a2
    cmp #$08
    bne sub41_01
    lda $a1
    cmp #$8c
    bcc sub41_01
    `inc_lda $a3
    cmp #$04
    bne sub41_01
    jsr sub20
    jsr update_palette
    lda #$00
    sta $a3

sub41_01:
    lda #3  ; 9th section
    sta nmi_task

    `set_ppu_addr vram_palette+0*4

    lda $a2
    cmp #$08
    beq sub41_04
    lda $014d
    cmp #$00
    beq sub41_03
    cmp #$01
    beq sub41_02
    cmp #$02
    beq +

*   `write_ppu_data $34  ; light purple
    `write_ppu_data $24  ; medium-light purple
    `write_ppu_data $14  ; medium-dark purple
    `write_ppu_data $04  ; dark purple

sub41_02:
    `write_ppu_data $38  ; light yellow
    `write_ppu_data $28  ; medium-light yellow
    `write_ppu_data $18  ; medium-dark yellow
    `write_ppu_data $08  ; dark yellow

sub41_03:
    `write_ppu_data $32  ; light blue
    `write_ppu_data $22  ; medium-light blue
    `write_ppu_data $12  ; medium-dark blue
    `write_ppu_data $02  ; dark blue

sub41_04:
    `inc_lda $89
    sta ppu_scroll
    ldx $89
    lda table20,x
    sta ppu_scroll
    `inc_lda $a1
    cmp #$b4
    beq +
    jmp sub41_05
*   inc $a2
    lda #$00
    sta $a1

sub41_05:
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
    beq sub41_06

sub41_jump_table:
    jmp sub41_15
    jmp sub41_07
    jmp sub41_08
    jmp sub41_09
    jmp sub41_10
    jmp sub41_11
    jmp sub41_12
    jmp sub41_13
    jmp sub41_14

sub41_06:
    lda #10  ; 10th section
    sta nmi_task
    lda #0
    sta flag1
    jmp $ea7e

sub41_07:
    jsr init_graphics_and_sound
    ldx #$5c
    ldy #$6a
    lda #$90
    sta $9a
    jsr sub22
    jmp $ea7e

sub41_08:
    jsr init_graphics_and_sound
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

sub41_09:
    jsr init_graphics_and_sound
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
    jsr init_graphics_and_sound
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
    jsr init_graphics_and_sound
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
    jsr init_graphics_and_sound
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
    jsr init_graphics_and_sound
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
    jsr init_graphics_and_sound
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
    jsr init_graphics_and_sound
    `chr_bankswitch 1

    lda #%10011000
    sta ppu_ctrl
    lda #%00011110
    sta ppu_mask
    rts

; -----------------------------------------------------------------------------

sub42:

    ldx #$7f
    jsr sub58
    ldy #$00
    jsr sub56
    jsr init_graphics_and_sound

    lda #%00000000
    sta ppu_ctrl
    sta ppu_mask

    lda #$20
    sta $014a
    lda #$21
    sta $014b

    ; write 16 rows to Name Table 0;
    ; the left half consists of tiles $00, $01, ..., $ff;
    ; the right half consists of tile $7f
    `set_ppu_addr vram_name_table0
    ; start outer loop
    ldy #0
sub42_loop1:
    ; write Y...Y+15
    ldx #0
*   sty ppu_data
    iny
    inx
    cpx #16
    bne -
    ; write 16 * byte $7f
    ldx #0
*   `write_ppu_data $7f
    inx
    cpx #16
    bne -
    ; end outer loop
    cpy #0
    bne sub42_loop1

    jsr sub12

    ; write another 7 rows to Name Table 0;
    ; the left half consists of tiles $00, $01, ..., $df
    ; the right half consists of tile $7f
    ; start outer loop
    ldy #0
sub42_loop2:
    ; first inner loop
    ldx #0
*   sty ppu_data
    iny
    inx
    cpx #16
    bne -
    ; second inner loop
    ldx #0
*   `write_ppu_data $7f
    inx
    cpx #16
    bne -
    ; end outer loop
    cpy #7*32
    bne sub42_loop2

    ; write bytes $e0...$e4 to Name Table 0, row 29, columns 10...14
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

sub43:

    `sprite_dma

    inc $8a
    inc $8b
    ldx #24
    ldy #0
    lda #$00
    sta $9a
    sta $89
    lda $8b

sub43_loop1:
    txa
    sta sprite_page,y

    lda #$f0
    `add_mem $8c
    sta sprite_page+1,y
    lda $014a
    sta sprite_page+2,y
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
    sta sprite_page+3,y
    pla
    tax
    `iny4
    txa
    `add_imm 8
    tax
    `inc_lda $8d
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
    sta sprite_page,y

    lda #$f0
    `add_mem $8c
    sta sprite_page+1,y
    lda $014b
    sta sprite_page+2,y
    txa
    pha
    dec $89
    dec $89
    lda $89
    `add_mem $8b
    tax
    lda table21,x
    `add_imm $c2
    sta sprite_page+3,y
    pla
    tax
    `iny4
    txa
    `add_imm 8
    tax
    `inc_lda $8c
    cmp #$10
    beq +
    jmp ++
*   lda #$00
    sta $8c
*   cpy #192
    bne sub43_loop2

    `chr_bankswitch 3

    lda #%10001000
    sta ppu_ctrl

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

    lda #%10011000
    sta ppu_ctrl
    lda #%00011110
    sta ppu_mask

    lda $8b
    cmp #$fa
    bne sub43_exit

    `inc_lda $0149
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
    jsr init_palette_copy
    jsr update_palette
    jsr init_graphics_and_sound

    lda #%00000000
    sta ppu_ctrl
    sta ppu_mask

    `set_ppu_addr vram_name_table0+8*32+10

    ldx #$50
    ldy #0
*   stx ppu_data  ; start loop
    inx
    iny
    cpy #12
    bne -

    `reset_ppu_addr
    `set_ppu_addr vram_name_table0+9*32+10

    ldy #0
    ldx #$5c
*   stx ppu_data  ; start loop
    inx
    iny
    cpy #12
    bne -

    `reset_ppu_addr
    `set_ppu_addr vram_name_table0+10*32+10

    ldy #0
    ldx #$68
*   stx ppu_data  ; start loop
    inx
    iny
    cpy #12
    bne -

    `reset_ppu_addr

    lda #1
    sta flag1
    lda #$00
    sta $8f
    sta $89
    lda #$00
    sta $8a

    ; update third and fourth color of third sprite subpalette
    `set_ppu_addr vram_palette+6*4+2
    `write_ppu_data $00  ; dark gray
    `write_ppu_data $10  ; light gray
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
    beq sub43_1

    ; update first sprite subpalette
    `set_ppu_addr vram_palette+4*4
    `write_ppu_data $0f  ; black
    `write_ppu_data $0f  ; black
    `write_ppu_data $0f  ; black
    `write_ppu_data $0f  ; black
    `reset_ppu_addr

    ; update first background subpalette
    `set_ppu_addr vram_palette+0*4
    `write_ppu_data $0f  ; black
    `write_ppu_data $30  ; white
    `write_ppu_data $10  ; light gray
    `write_ppu_data $00  ; dark gray
    `reset_ppu_addr

sub43_1:
    lda #$01
    sta $0130

    lda #%00011110
    sta ppu_mask
    lda #%00010000
    sta ppu_ctrl

    `inc_lda $8a
    cmp #8
    beq +
    jmp sub43_2
*   lda #$00
    sta $8a
    `inc_lda $8f
    cmp #$eb
    beq +
    jmp ++
*   lda #0
    sta flag1
    lda #7  ; 7th section
    sta nmi_task

*   `set_ppu_addr vram_name_table0+27*32+1

    ldx #0
*   txa           ; start loop
    `add_mem $8f
    tay
    lda table11,y
    clc
    sbc #$36
    sta ppu_data
    inx
    cpx #31
    bne -

    `reset_ppu_addr

sub43_2:
    `chr_bankswitch 2
    `inc_ldx $89
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
    jsr sub19
    jsr sub19
    jsr sub19
    ldx #$1e
    jsr sub19
    ldx #$d0
    jsr sub19

    lda #%00000000
    sta ppu_ctrl

    `chr_bankswitch 0

    lda $8a
    sta ppu_scroll
    lda #0
    sta ppu_scroll

    lda #215
    sta sprite_page+0*4+0
    lda #$25
    sta sprite_page+0*4+1
    lda #%00000000
    sta sprite_page+0*4+2
    lda #248
    sta sprite_page+0*4+3

    lda #207
    sta sprite_page+1*4+0
    lda #$25
    sta sprite_page+1*4+1
    lda #%00000000
    sta sprite_page+1*4+2
    lda #248
    sta sprite_page+1*4+3

    lda #223
    sta sprite_page+2*4+0
    lda #$27
    sta sprite_page+2*4+1
    lda #%00000000
    sta sprite_page+2*4+2
    lda #248
    sta sprite_page+2*4+3

    ldx data2
*   txa  ; start loop
    asl
    asl
    tay

    lda table28,x
    `add_imm $9b
    sta sprite_page+23*4+0,y

    txa
    pha
    ldx $0137
    lda table52,x
    sta $9a
    pla

    tax
    lda table29,x
    `add_mem $9a
    sta sprite_page+23*4+1,y

    lda #%00000010
    sta sprite_page+23*4+2,y

    lda table30,x
    `add_mem $0139
    sta sprite_page+23*4+3,y

    cpx #0
    beq +
    dex
    jmp -

*   `inc_lda $013a
    cmp #$06
    bne +
    inc $0139
    inc $0139
    lda #$00
    sta $013a
*   `inc_lda $0138
    cmp #$0c
    bne +
    lda #$00
    sta $0138
    `inc_lda $0137
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

sub44:

    jsr init_graphics_and_sound
    ldy #$aa
    jsr sub56
    lda #$1a
    sta $9a
    ldx #$60

sub44_loop1:  ; start outer loop
    ; $2100 + [$9a] -> ppu_addr
    lda #$21
    sta ppu_addr
    lda $9a
    sta ppu_addr

    ldy #0
*   stx ppu_data  ; start inner loop
    inx
    iny
    cpy #3
    bne -

    `reset_ppu_addr

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
    sta ppu_addr
    lda $9a
    sta ppu_addr

    ldy #0
*   stx ppu_data  ; start inner loop
    inx
    iny
    cpy #3
    bne -

    `reset_ppu_addr

    lda $9a
    `add_imm 32
    sta $9a
    lda $9a
    cmp #$68
    bne sub44_loop2

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
    sta sprite_page+48*4+0,y
    lda table43,x
    sta sprite_page+48*4+1,y
    lda table40,x
    sta sprite_page+48*4+3,y

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
    sta sprite_page+1*4+1,y
    lda table36,x
    sta sprite_page+1*4+2,y

    cpx #0
    beq +
    dex
    jmp -

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

sub45:

    `sprite_dma

    `inc_ldx $0100
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
    bne sub45_2
    lda $0108,x
    cmp table33,x
    beq +
    inc $0108,x
    jmp sub45_1
*   lda table32,x
    sta $0108,x
sub45_1:
    lda table31,x
    sta $0104,x
sub45_2:
    dex
    cpx #255
    bne sub45_loop1

    lda $0108
    sta sprite_page+1*4+1
    lda $0109
    sta sprite_page+16*4+1
    lda $010a
    sta sprite_page+17*4+1
    lda $010b
    sta sprite_page+13*4+1

    ldx data4
*   txa  ; start loop
    asl
    asl
    tay

    lda table34,x
    `add_mem $0111
    sta sprite_page+1*4+0,y

    lda table37,x
    `add_mem $0110
    sta sprite_page+1*4+3,y

    cpx #0
    beq +
    dex
    jmp -

*   lda $0100
    ldx $0101
    cmp table38,x
    bne sub45_3

    `inc_lda $0101
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
    bne sub45_3
    lda #$00
    sta $0102

sub45_3:
    ldx data5
sub45_loop2:
    lda $0116,x
    cmp #$f0
    beq sub45_4
    lda $0112,x
    clc
    sbc $011a,x
    bcc +
    sta $0112,x
    jmp sub45_4
*   lda #$f0
    sta $0116,x
sub45_4:
    dex
    cpx #255
    bne sub45_loop2

    ldx data5
*   txa        ; start loop
    asl
    asl
    tay

    lda $0116,x
    sta sprite_page+18*4+0,y
    lda table39,x
    sta sprite_page+18*4+1,y
    lda #$2b
    sta sprite_page+18*4+2,y
    lda $0112,x
    sta sprite_page+18*4+3,y

    dex
    cpx #255
    bne -

    ldx data7
*   txa        ; start loop
    asl
    asl
    tay

    lda sprite_page+48*4+3,y
    clc
    sbc table42,x
    sta sprite_page+48*4+3,y

    dex
    cpx #255
    bne -

    lda #%10000000
    sta ppu_ctrl
    lda #%00011010
    sta ppu_mask

    `set_ppu_scroll 0, 50
    rts

; -----------------------------------------------------------------------------

sub46:

    ldx #$4a
    jsr sub58
    ldy #$00
    jsr sub56
    jsr init_palette_copy
    jsr update_palette

    `set_ppu_addr vram_name_table0+14*32

    ldx #0
*   lda table13,x  ; start loop
    clc
    sbc #$10
    sta ppu_data
    inx
    cpx #96
    bne -

    lda #%00000010
    sta ppu_ctrl
    lda #%00000000
    sta ppu_mask
    rts

; -----------------------------------------------------------------------------

sub47:

    `set_ppu_scroll 0, 0

    lda #%10010000
    sta ppu_ctrl
    lda #%00001110
    sta ppu_mask
    rts

; -----------------------------------------------------------------------------

sub48:

    ldx #$4a
    jsr sub58
    ldy #$00
    jsr sub56
    jsr clear_palette_copy
    jsr update_palette

    lda #%00000010
    sta ppu_ctrl
    lda #%00000000
    sta ppu_mask

    lda #$00
    sta $9a
    ldx #$00

sub48_loop:   ; start outer loop
    lda #$20
    sta ppu_addr
    lda $9a
    `add_imm $69
    sta ppu_addr

    ldy #0
*   stx ppu_data  ; start inner loop
    inx
    iny
    cpy #16
    bne -

    `reset_ppu_addr

    lda $9a
    `add_imm 32
    sta $9a
    cmp #96
    bne sub48_loop

    `set_ppu_addr vram_name_table0+8*32

    ldx #0
*   lda table14,x  ; start loop
    clc
    sbc #$10
    sta ppu_data
    inx
    bne -

    ldx #0
*   lda table15,x  ; start loop
    clc
    sbc #$10
    sta ppu_data
    inx
    bne -

    ldx #0
*   lda table16,x  ; start loop
    clc
    sbc #$10
    sta ppu_data
    inx
    cpx #$80
    bne -

    `reset_ppu_addr

    lda #1
    sta flag1
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
    `add_mem $0153
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
    `inc_lda $a3
    cmp #$04
    bne +
    jsr sub20
    jsr update_palette
    lda #$00
    sta $a3
*   lda #12  ; 11th section
    sta nmi_task

    lda #%10010000
    sta ppu_ctrl
    lda #%00001110
    sta ppu_mask
    rts

; -----------------------------------------------------------------------------

sub50:

    ldx #$80
    jsr sub58
    jsr init_graphics_and_sound
    ldy #$00
    jsr sub56

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

sub51:

    lda $013c
    cmp #$02
    beq +
    jmp sub51_1
*   ldy #$80

sub51_loop1:  ; start outer loop
    lda #>[vram_name_table0+8*32+4]
    sta ppu_addr
    lda #<[vram_name_table0+8*32+4]
    `add_mem $013b
    sta ppu_addr

    ldx #0
*   sty ppu_data  ; start inner loop
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
    lda #>[vram_name_table0+16*32+4]
    sta ppu_addr
    lda #<[vram_name_table0+16*32+4]
    `add_mem $013b
    sta ppu_addr

    ldx #0
*   sty ppu_data  ; start inner loop
    iny
    inx
    cpx #8
    bne -

    lda $013b
    `add_imm 32
    sta $013b
    cpy #$00
    bne sub51_loop2

    `reset_ppu_addr

    lda #$00
    sta $013b

sub51_loop3:  ; start outer loop
    lda #>[vram_name_table0+8*32+20]
    sta ppu_addr
    lda #<[vram_name_table0+8*32+20]
    `add_mem $013b
    sta ppu_addr

    ldx #0
*   sty ppu_data  ; start inner loop
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
    lda #>[vram_name_table0+16*32+20]
    sta ppu_addr
    lda #<[vram_name_table0+16*32+20]
    `add_mem $013b
    sta ppu_addr

    ldx #0
*   sty ppu_data  ; start inner loop
    iny
    inx
    cpx #8
    bne -

    lda $013b
    `add_imm 32
    sta $013b
    cpy #0
    bne sub51_loop4

    `reset_ppu_addr

sub51_1:
    lda $013c
    cmp #$a0
    bcc +
    jmp sub51_2

*   lda #$00
    sta ppu_scroll
    lda $013d
    clc
    sbc $013c
    sta ppu_scroll

sub51_2:
    lda ram1
    `chr_bankswitch 2
    lda #$00
    sta $89
    lda $013e
    cmp #$01
    beq sub51_3
    `inc_lda $013c
    cmp #$c8
    beq +
    jmp sub51_3
*   lda #$01
    sta $013e

sub51_3:
    ldx #$00
    ldy #$00
    lda $013e
    cmp #$00
    beq sub51_5
    inc $8b
    inc $8a

sub51_loop5:
    ldx #1
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
    bcc +
    bcs ++

*   lda #%00001110
    sta ppu_mask
    jmp sub51_4

*   lda $89
    cmp $9b
    bcs +
    lda #%11101110
    sta ppu_mask

sub51_4:
    jmp ++

*   lda #%00001110
    sta ppu_mask

*   lda $89
    `add_mem $8b
    adc $8a
    clc
    sbc #$14
    tax
    lda table19,x
    `add_mem $8b
    sta ppu_scroll
    lda $89
    `add_mem $8b
    tax
    lda table20,x
    sta ppu_scroll

    ldx $8a
    lda table20,x
    `add_imm 60
    sta $9b
    inc $89
    iny
    cpy #$91
    bne sub51_loop5

sub51_5:
    lda #%10010000
    sta ppu_ctrl
    lda #%00001110
    sta ppu_mask
    rts

; -----------------------------------------------------------------------------

sub52:

    ldy #0
*   stx ppu_data
    iny
    cpy #32
    bne -

    rts

; -----------------------------------------------------------------------------

sub53:
    ; Why identical to the previous subroutine?

    ldy #0
*   stx ppu_data
    iny
    cpy #32
    bne -

    rts

; -----------------------------------------------------------------------------

sub54:

    ldx #$25
    jsr sub59
    jsr init_graphics_and_sound

    lda #%00000000
    sta ppu_ctrl
    sta ppu_mask

    `set_ppu_addr vram_name_table0

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

    `reset_ppu_addr

    ; update first background subpalette from table18
    `set_ppu_addr vram_palette+0*4
    lda table18+4
    sta ppu_data
    lda table18+5
    sta ppu_data
    lda table18+6
    sta ppu_data
    lda table18+7
    sta ppu_data
    `reset_ppu_addr

    ; update first sprite subpalette from table18
    `set_ppu_addr vram_palette+4*4
    lda table18+8
    sta ppu_data
    lda table18+9
    sta ppu_data
    lda table18+10
    sta ppu_data
    lda table18+11
    sta ppu_data
    `reset_ppu_addr

    ldx data7
*   txa        ; start loop
    asl
    asl
    tay

    lda table49,x
    sta sprite_page+48*4+0,y
    lda table51,x
    sta sprite_page+48*4+1,y
    lda #%00000010
    sta sprite_page+48*4+2,y
    lda table48,x
    sta sprite_page+48*4+3,y

    lda table50,x
    sta $011e,x
    dex
    cpx #255
    bne -

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

sub55:

    `inc_ldx $0100
    lda table21,x
    sta $9a
    lda table22,x
    sta $9b

    `sprite_dma

    ldx data7
*   txa  ; start loop
    asl
    asl
    tay

    lda table49,x
    `add_mem $9a
    sta sprite_page+48*4+0,y
    lda sprite_page+48*4+3,y
    clc
    adc table50,x
    sta sprite_page+48*4+3,y

    dex
    cpx #7
    bne -

*   txa  ; start loop
    asl
    asl
    tay

    lda table49,x
    `add_mem $9b
    sta sprite_page+48*4+0,y
    lda sprite_page+48*4+3,y
    clc
    adc table50,x
    sta sprite_page+48*4+3,y

    dex
    cpx #255
    bne -

    `chr_bankswitch 0
    `inc_lda $8a
    cmp #$08
    beq +
    jmp sub55_2
*   lda #$00
    sta $8a
    `inc_lda $8f
    cmp #$eb
    beq +
    jmp sub55_1
*   lda #0
    sta flag1
    lda #7  ; 7th section
    sta nmi_task

sub55_1:
    lda #>[vram_name_table0+19*32+1]
    sta ppu_addr
    lda #<[vram_name_table0+19*32+1]
    sta ppu_addr

    ldx #0
*   txa           ; start loop
    `add_mem $8f
    tay
    lda table11,y
    clc
    sbc #$36
    sta ppu_data
    inx
    cpx #31
    bne -

    `reset_ppu_addr

sub55_2:
    `inc_ldx $89
    lda $8a
    sta ppu_scroll
    lda table20,x
    sta ppu_scroll

    lda table20,x
    sta $9a

    ; set up sprites 0...5
    ; Y        : (147, 151 or 155) - [$9a]
    ; tile     : $25
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

sub56:

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

sub57:

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

sub58:

    stx $8e
    ldy #$00
    lda #$3c
    sta $9a

    lda #%00000000
    sta ppu_ctrl
    sta ppu_mask

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

sub59:

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
*   `write_ppu_data $00
    inx
    cpx #64
    bne -

    ; clear Attribute Table 1
    `set_ppu_addr vram_attr_table1
    ldx #0
*   `write_ppu_data $00
    inx
    cpx #64
    bne -

    `set_ppu_addr vram_name_table0

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

    `set_ppu_addr vram_name_table1

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

    `set_ppu_addr vram_name_table2

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
