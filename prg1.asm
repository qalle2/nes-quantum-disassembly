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

    `lda_imm_sta $00, $01

    `lda_imm_sta %00000000, ppu_ctrl
    `lda_imm_sta %00011110, ppu_mask

    ldx #$ff
    jsr sub59
    jsr sub28

    lda #%00000000
    sta ppu_ctrl
    sta ppu_mask

    ldy #$00
    jsr sub56
    `lda_imm_sta $ff, pulse1_ctrl

    `reset_ppu_addr

    lda #$00
    ldx #$01
    jsr sub13
    jsr wait_vbl

    `lda_imm_sta %10000000, ppu_ctrl
    `lda_imm_sta %00011110, ppu_mask

*   lda $01
    `cmp_bne $09, +
    `lda_imm_sta $0d, dmc_addr
    `lda_imm_sta $fa, dmc_length
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
    `lda_imm_sta %00000000, ppu_ctrl

    ; clear sound registers $4000...$400e
    lda #$00
    ldx #0
*   sta apu_regs,x
    inx
    `cpx_bne 15, -

    ; more sound stuff
    `lda_imm_sta $c0, apu_counter

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
    `cpx_bne 32, -
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
    `cpx_bne 32, -
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
    `cpx_bne 32, -

    `reset_ppu_addr
    rts

; -----------------------------------------------------------------------------

sub19:

    stx $88
    `lda_imm_sta 0, $87
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
    `cpy_bne 11, -

    nop
    inx
    cpx $88
    bne sub19_loop2

    rts

; -----------------------------------------------------------------------------

sub20:

    ldy #0
*   lda palette_copy,y     ; start loop
    sta $01
    and #%00110000
    `lsr4
    tax
    lda $01
    and #%00001111
    ora table18,x
    sta palette_copy,y
    iny
    `cpy_bne 32, -

    rts

; -----------------------------------------------------------------------------

sub21:

    `set_ppu_addr vram_palette+0*4

    lda $e8
    cmp #8
    bcc +
    `lda_mem_sta $e8, ppu_data
    jmp sub21_exit
*   `write_ppu_data $3f  ; black
sub21_exit:
    rts

; -----------------------------------------------------------------------------

sub22:

    stx $a5
    sty $a6
    `lda_mem_sta $9a, $a7

    lda #$00
    sta $9a
    sta $9b
    sta $9c

sub22_loop:   ; start outer loop
    ldx #0
    `lda_imm_sta $00, $9a

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
    `cpx_bne 64, -

    lda $9b
    `add_imm 8
    sta $9b
    lda $9b
    `cmp_bne 16, sub22_loop

    sty $a8
    rts

; -----------------------------------------------------------------------------

sub23:

    stx $a5
    sty $a6
    `lda_mem_sta $9a, $a7
    lda #$00
    sta $9a
    sta $9b
    sta $9c

sub23_loop:   ; start outer loop
    ldx #0
    `lda_imm_sta $00, $9a

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
    `cpx_bne 24, -

    lda $9b
    `add_imm 8
    sta $9b
    lda $9b
    `cmp_bne 16, sub23_loop

    sty $a8
    rts

; -----------------------------------------------------------------------------

sub24:

    stx $a5
    sty $a6
    `lda_mem_sta $9a, $a7

    lda #$00
    sta $9a
    sta $9b
    sta $9c

sub24_loop:   ; start outer loop
    ldx #0
    `lda_imm_sta $00, $9a

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
    `cpx_bne 32, -

    lda $9b
    `add_imm 8
    sta $9b
    lda $9b
    `cmp_bne 16, sub24_loop

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
    `cmp_bne $ff, +

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
    `cpy_bne 22, sub25_loop

    rts

; -----------------------------------------------------------------------------

sub26:

    stx $91
    sty $92

    `lda_mem_sta $91, ppu_addr
    `lda_mem_sta $92, ppu_addr

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
    `cmp_bne $10, -

    `lda_imm_sta $00, $90

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
    `cmp_bne $10, -

    `reset_ppu_addr
    rts

; -----------------------------------------------------------------------------

sub27:

    `lda_imm_sta $00, $9a

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
    `cpx_bne $ff, -

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
    `cpx_bne 255, -

    rts

; -----------------------------------------------------------------------------

sub29:

    `chr_bankswitch 0
    lda $95

    `cmp_beq  1, sub29_jump_table+1*3
    `cmp_beq  2, sub29_jump_table+2*3
    `cmp_beq  3, sub29_jump_table+3*3
    `cmp_beq  4, sub29_jump_table+4*3
    `cmp_beq  5, sub29_jump_table+5*3
    `cmp_beq  6, sub29_jump_table+6*3
    `cmp_beq  7, sub29_jump_table+7*3
    `cmp_beq  8, sub29_jump_table+8*3
    `cmp_beq  9, sub29_01
    `cmp_beq 10, sub29_jump_table+10*3
    jmp sub29_11

sub29_01:
    `lda_imm_sta 0, ppu_scroll
    ldx $96
    lda table19,x
    `add_mem $96
    sta ppu_scroll

    lda $96
    `cmp_bne $dc, +
    jmp ++
*   inc $96
    inc $96

*   `lda_imm_sta %10000000, ppu_ctrl
    `lda_imm_sta %00011110, ppu_mask

sub29_jump_table:
    jmp sub29_11
    jmp sub29_02
    jmp sub29_03
    jmp sub29_04
    jmp sub29_05
    jmp sub29_06
    jmp sub29_07
    jmp sub29_08
    jmp sub29_09
    jmp sub29_11
    jmp sub29_10

sub29_02:
    ; pointer 0 -> ptr1
    `lda_mem_sta pointers+0*2+0, ptr1+0
    `lda_mem_sta pointers+0*2+1, ptr1+1

    ldx #$20
    ldy #$00
    jsr sub26

    `lda_imm_sta 0, ppu_scroll
    `lda_mem_sta $96, ppu_scroll

    `dec_lda $96
    cmp #$f0
    bcs +
    jmp sub29_11
*   `lda_imm_sta $00, $96
    jmp sub29_11

sub29_03:
    `lda_imm_sta $00, $96
    jmp sub29_11

sub29_04:
    ; pointer 1 -> ptr1
    `lda_mem_sta pointers+1*2+0, ptr1+0
    `lda_mem_sta pointers+1*2+1, ptr1+1

    ldx #$20
    ldy #$a0
    jsr sub26
    jmp sub29_11

sub29_05:
    ; pointer 2 -> ptr1
    `lda_mem_sta pointers+2*2+0, ptr1+0
    `lda_mem_sta pointers+2*2+1, ptr1+1

    ldx #$21
    ldy #$20
    jsr sub26
    jmp sub29_11

sub29_06:
    ; pointer 3 -> ptr1
    `lda_mem_sta pointers+3*2+0, ptr1+0
    `lda_mem_sta pointers+3*2+1, ptr1+1

    ldx #$21
    ldy #$a0
    jsr sub26
    jmp sub29_11

sub29_07:
    ; pointer 4 -> ptr1
    `lda_mem_sta pointers+4*2+0, ptr1+0
    `lda_mem_sta pointers+4*2+1, ptr1+1

    ldx #$22
    ldy #$40
    jsr sub26
    jmp sub29_11

sub29_08:
    ; pointer 5 -> ptr1
    `lda_mem_sta pointers+5*2+0, ptr1+0
    `lda_mem_sta pointers+5*2+1, ptr1+1

    ldx #$22
    ldy #$c0
    jsr sub26
    jmp sub29_11

sub29_09:
    ; pointer 6 -> ptr1
    `lda_mem_sta pointers+6*2+0, ptr1+0
    `lda_mem_sta pointers+6*2+1, ptr1+1

    ldx #$23
    ldy #$40
    jsr sub26
    jmp sub29_11

sub29_10:
    `lda_imm_sta $02, $01
    `lda_imm_sta $00, $02
    jmp sub29_11

sub29_11:
    jmp sub29_13
    `lda_imm_sta $00, $9a
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

    `lda_imm_sta $01, $02
    `lda_imm_sta $8e, $012e
    `lda_imm_sta $19, $012f

    `lda_imm_sta %00011110, ppu_mask
    rts

; -----------------------------------------------------------------------------

sub31:

    `chr_bankswitch 0
    `sprite_dma

    `lda_imm_sta %10010000, ppu_ctrl

    ; update fourth color of first background subpalette
    `set_ppu_addr vram_palette+0*4+3
    `write_ppu_data $0f  ; black
    `reset_ppu_addr

    `lda_imm_sta 0, ppu_scroll
    ldx $014e
    lda table19,x
    `add_mem $014e
    sta ppu_scroll

    lda $014e
    `cmp_beq $c1, +
    inc $014e
*   lda $ac
    `cmp_bne $02, +
    lda $ab
    `cmp_bne $32, +
    jsr sub25
*   lda $ac
    `cmp_bne $01, sub31_1
    lda $ab
    `cmp_bne $96, sub31_1
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

    `cpx_beq 0, +
    dex
    jmp -

*   `lda_imm_sta 129, sprite_page+24*4+0
    `lda_imm_sta $e5, sprite_page+24*4+1
    `lda_imm_sta %00000001, sprite_page+24*4+2
    `lda_imm_sta 214, sprite_page+24*4+3

    `lda_imm_sta 97, sprite_page+25*4+0
    `lda_imm_sta $f0, sprite_page+25*4+1
    `lda_imm_sta %00000010, sprite_page+25*4+2
    `lda_imm_sta 230, sprite_page+25*4+3

    ; update fourth color of first background subpalette
    `set_ppu_addr vram_palette+0*4+3
    `write_ppu_data $30  ; white
    `reset_ppu_addr

sub31_1:
    lda $ac
    `cmp_bne $02, sub31_2
    lda $ab
    cmp #$32
    bcc sub31_2

    ldx #0
    ldy #0
sub31_loop:
    lda $0180,x
    `cmp_bne $01, +
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
    `cpx_bne 22, sub31_loop

sub31_2:
    lda $ac
    `cmp_bne $02, +
    lda $ab
    cmp #$c8
    bcc +
    `inc_lda $a3
    `cmp_bne $04, +
    jsr sub20
    jsr update_palette
    `lda_imm_sta $00, $a3
*   jsr sub27
    `lda_imm_sta $02, $01
    rts

; -----------------------------------------------------------------------------

sub32:

    lda #$00
    ldx #0
*   sta pulse1_ctrl,x
    inx
    `cpx_bne 15, -

    `lda_imm_sta $0a, dmc_addr
    `lda_imm_sta $fa, dmc_length
    `lda_imm_sta $4c, dmc_ctrl
    `lda_imm_sta $1f, apu_ctrl
    `lda_imm_sta $ff, dmc_load
    ldx #$00
    jsr sub59
    `lda_imm_sta $01, $02
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

    `lda_imm_sta %10000100, ppu_ctrl

    `lda_imm_sta $00, $89
    ldy #$9f

sub33_loop:

    ldx #25
*   dex
    bne -

    `set_ppu_addr_via_x vram_palette+0*4

    `inc_lda $8c
    `cmp_beq $05, +
    jmp ++
*   inc $89
    `lda_imm_sta $00, $8c
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

    `lda_imm_sta %00000110, ppu_mask
    `lda_imm_sta %10010000, ppu_ctrl
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

    `lda_imm_sta $01, $02
    `lda_imm_sta $05, $00
    rts

; -----------------------------------------------------------------------------

sub35:

    `chr_bankswitch 1
    lda $0148
    `cmp_beq $00, +
    jmp sub35_1
*   dec $8a

    ldx #0
    `lda_imm_sta $00, $89
*   lda $89  ; start loop
    adc $8a
    tay
    lda table19,y
    sta $0600,x
    lda $89
    `add_mem $00
    sta $89
    inx
    `cpx_bne 64, -

    ldx #0
    ldy #0
    `lda_imm_sta $00, $9a

sub35_loop1:  ; start outer loop
    ; $2100 + [$9a] -> ppu_addr
    `lda_imm_sta $21, ppu_addr
    `lda_mem_sta $9a, ppu_addr

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
    `cpy_bne 8, -

    lda $9a
    `add_imm 32
    sta $9a
    lda $9a
    `cmp_bne $00, sub35_loop1

    `lda_imm_sta $01, $0148
    jmp sub35_2

sub35_1:
    dec $8a
    ldx #64
    `lda_imm_sta $00, $89

*   lda $89  ; start loop
    adc $8a
    tay
    lda table19,y
    sta $0600,x
    lda $89
    `add_mem $00
    sta $89
    inx
    `cpx_bne 128, -

    ldx #$7f
    `lda_imm_sta $00, $9a

sub35_loop2:  ; start outer loop
    `lda_imm_sta $22, ppu_addr
    `lda_mem_sta $9a, ppu_addr

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
    `cpy_bne 8, -

    lda $9a
    `add_imm 32
    sta $9a
    lda $9a
    `cmp_bne $00, sub35_loop2

    `lda_imm_sta $00, $0148

sub35_2:
    `reset_ppu_addr

    `lda_imm_sta $00, $89

*   ldx #$04   ; start loop
    jsr sub19
    lda $89
    `add_mem $8b
    tax
    lda table19,x
    sta ppu_scroll
    `lda_imm_sta 0, ppu_scroll
    inc $89
    iny
    `cpy_bne $98, -

    ldx $8b
    lda table22,x
    sbc $8b
    sbc $8b
    `lda_imm_sta 0, ppu_scroll
    ldx $8b
    lda table20,x
    clc
    sbc #10
    `lda_imm_sta 230, ppu_scroll
    dec $8b

    `lda_imm_sta %00001110, ppu_mask
    `lda_imm_sta %10000000, ppu_ctrl
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

    `lda_imm_sta $01, $02
    rts

; -----------------------------------------------------------------------------

sub37:

    jsr sub21
    `chr_bankswitch 1
    dec $8a
    dec $8a

    ldx #0
    `lda_imm_sta 0, $89
*   lda $89  ; start loop
    adc $8a
    tay
    lda table19,y
    adc #$46
    sta $0600,x
    inc $89
    inx
    `cpx_bne $80, -

    lda $0148
    `cmp_beq $00, +
    jmp sub37_1

*   ldx #0
    ldy #0
    lda #$00

    sta $9a
sub37_loop1:  ; start outer loop
    ; $2100 + [$9a] -> ppu_addr
    `lda_imm_sta $21, ppu_addr
    `lda_mem_sta $9a, ppu_addr

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
    `cpy_bne 8, -

    lda $9a
    `add_imm 32
    sta $9a
    lda $9a
    `cmp_bne $00, sub37_loop1

    `lda_imm_sta $01, $0148
    jmp sub37_2

sub37_1:
    ldx #$7f
    `lda_imm_sta $20, $9a

sub37_loop2:  ; start outer loop
    `lda_imm_sta $22, ppu_addr
    `lda_mem_sta $9a, ppu_addr

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
    `cpy_bne 8, -

    lda $9a
    `add_imm 32
    sta $9a
    lda $9a
    `cmp_bne $00, sub37_loop2

    `lda_imm_sta $00, $0148

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

    `lda_imm_sta %00001110, ppu_mask
    `lda_imm_sta %10000000, ppu_ctrl
    rts

; -----------------------------------------------------------------------------

sub38:

    ldx #$ff
    jsr sub59
    jsr sub12
    jsr init_palette_copy
    jsr update_palette
    `lda_imm_sta $01, $02
    jsr init_graphics_and_sound

    lda #$00
    sta $89
    sta $8a
    sta $8b
    sta $8c

    `lda_imm_sta %00000000, ppu_mask
    `lda_imm_sta %10000000, ppu_ctrl
    rts

; -----------------------------------------------------------------------------

sub39:

    dec $8c
    `inc_lda $8b
    `cmp_bne $02, +

    `lda_imm_sta $00, $8b
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

    `lda_imm_sta $00, $89

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
    `lda_imm_sta $00, $9e
    `lda_imm_sta $00, $9f
sub40_loop1:  ; start outermost loop

    ldy #0
sub40_loop2:  ; start middle loop

    ldx #0
*   txa           ; start innermost loop
    `add_mem $9e
    sta ppu_data
    inx
    `cpx_bne 8, -

    iny
    `cpy_bne $04, sub40_loop2

    lda $9e
    `add_imm 8
    sta $9e
    lda $9e
    `cmp_bne $40, sub40_loop1
    `lda_imm_sta $00, $9e
    `inc_lda $9f
    `cmp_bne $03, sub40_loop1

    ldx #0
sub40_loop3:  ; start outermost loop

    ldy #0
sub40_loop4:  ; start middle loop

    ldx #0
*   txa           ; start innermost loop
    `add_mem $9e
    sta ppu_data
    inx
    `cpx_bne 8, -

    iny
    `cpy_bne 4, sub40_loop4

    lda $9e
    `add_imm 8
    sta $9e
    `cmp_bne $28, sub40_loop3

    lda #$f0
    ldy #0
sub40_loop5:  ; start outer loop

    ldx #$f0
*   stx ppu_data  ; start inner loop
    inx
    `cpx_bne $f8, -

    iny
    `cpy_bne 8, sub40_loop5

    `reset_ppu_addr

    `inc_lda $a0
    `cmp_bne $02, +
    jmp sub40_2

*   `set_ppu_addr vram_name_table2

    jmp sub40_1

sub40_2:
    ; clear Attribute Table 0
    `set_ppu_addr vram_attr_table0
    ldx #0
*   `lda_imm_sta $00, ppu_data
    inx
    `cpx_bne 64, -
    `reset_ppu_addr

    ; clear Attribute Table 2
    `set_ppu_addr vram_attr_table2
    ldx #0
*   `lda_imm_sta $00, ppu_data
    inx
    `cpx_bne 64, -
    `reset_ppu_addr

    jsr init_graphics_and_sound
    `lda_imm_sta $02, $014d
    `lda_imm_sta $00, $a3
    `lda_imm_sta $01, $02
    `lda_imm_sta $00, $89

    `lda_imm_sta %00011000, ppu_ctrl
    `lda_imm_sta %00011110, ppu_mask
    rts

; -----------------------------------------------------------------------------

sub41:

    `sprite_dma

    lda $a2
    `cmp_bne $08, sub41_01
    lda $a1
    cmp #$8c
    bcc sub41_01
    `inc_lda $a3
    `cmp_bne $04, sub41_01
    jsr sub20
    jsr update_palette
    `lda_imm_sta $00, $a3

sub41_01:
    `lda_imm_sta $03, $01

    `set_ppu_addr vram_palette+0*4

    lda $a2
    `cmp_beq $08, sub41_04
    lda $014d
    `cmp_beq $00, sub41_03
    `cmp_beq $01, sub41_02
    `cmp_beq $02, +

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
    `cmp_beq $b4, +
    jmp sub41_05
*   inc $a2
    `lda_imm_sta $00, $a1

sub41_05:
    lda $a2
    `cmp_beq 1, sub41_jump_table+1*3
    `cmp_beq 2, sub41_jump_table+2*3
    `cmp_beq 3, sub41_jump_table+3*3
    `cmp_beq 4, sub41_jump_table+4*3
    `cmp_beq 5, sub41_jump_table+5*3
    `cmp_beq 6, sub41_jump_table+6*3
    `cmp_beq 7, sub41_jump_table+7*3
    `cmp_beq 8, sub41_jump_table+8*3
    `cmp_beq 9, sub41_06

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
    `lda_imm_sta $0a, $01
    `lda_imm_sta $00, $02
    jmp $ea7e

sub41_07:
    jsr init_graphics_and_sound
    ldx #$5c
    ldy #$6a
    `lda_imm_sta $90, $9a
    jsr sub22
    jmp $ea7e

sub41_08:
    jsr init_graphics_and_sound
    ldx #$75
    ldy #$73
    `lda_imm_sta $60, $9a
    jsr sub22
    ldx #$54
    ldy #$61
    `lda_imm_sta $ac, $9a
    jsr sub24
    jmp $ea7e

sub41_09:
    jsr init_graphics_and_sound
    ldx #$75
    ldy #$73
    `lda_imm_sta $80, $9a
    jsr sub22
    ldx #$54
    ldy #$61
    `lda_imm_sta $ac, $9a
    jsr sub24
    jmp $ea7e

sub41_10:
    jsr init_graphics_and_sound
    `lda_imm_sta $01, $014d
    ldx #$75
    ldy #$73
    `lda_imm_sta $50, $9a
    jsr sub22
    ldx #$54
    ldy #$61
    `lda_imm_sta $a0, $9a
    jsr sub23
    jmp $ea7e

sub41_11:
    jsr init_graphics_and_sound
    ldx #$75
    ldy #$73
    `lda_imm_sta $40, $9a
    jsr sub22
    ldx #$54
    ldy #$61
    `lda_imm_sta $a0, $9a
    jsr sub23
    jmp $ea7e

sub41_12:
    jsr init_graphics_and_sound
    ldx #$75
    ldy #$73
    `lda_imm_sta $e0, $9a
    jsr sub22
    ldx #$54
    ldy #$61
    `lda_imm_sta $a0, $9a
    jsr sub23
    jmp $ea7e

sub41_13:
    `lda_imm_sta $00, $014d
    jsr init_graphics_and_sound
    ldx #$75
    ldy #$73
    `lda_imm_sta $c0, $9a
    jsr sub22
    ldx #$54
    ldy #$61
    `lda_imm_sta $a0, $9a
    jsr sub23
    jmp $ea7e

sub41_14:
    jsr init_graphics_and_sound
    ldx #$75
    ldy #$73
    `lda_imm_sta $70, $9a
    jsr sub22
    ldx #$54
    ldy #$61
    `lda_imm_sta $a6, $9a
    jsr sub23
    jmp $ea7e

sub41_15:
    jsr init_graphics_and_sound
    `chr_bankswitch 1

    `lda_imm_sta %10011000, ppu_ctrl
    `lda_imm_sta %00011110, ppu_mask
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

    `lda_imm_sta $20, $014a
    `lda_imm_sta $21, $014b

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
    `cpx_bne 16, -
    ; write 16 * byte $7f
    ldx #0
*   `write_ppu_data $7f
    inx
    `cpx_bne 16, -
    ; end outer loop
    `cpy_bne 0, sub42_loop1

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
    `cpx_bne 16, -
    ; second inner loop
    ldx #0
*   `write_ppu_data $7f
    inx
    `cpx_bne 16, -
    ; end outer loop
    `cpy_bne 7*32, sub42_loop2

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
    `lda_imm_sta $40, $8b
    `lda_imm_sta $00, $8c
    `lda_imm_sta $01, $02
    `lda_imm_sta $00, $a3

    `lda_imm_sta %10000000, ppu_ctrl
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
    `cmp_beq 15, +
    jmp ++
*   inc $8c
    `lda_imm_sta $00, $8d
*   lda $8c
    `cmp_beq 16, +
    jmp ++
*   `lda_imm_sta $00, $8c
*   `cpy_bne 96, sub43_loop1

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
    `cmp_beq $10, +
    jmp ++
*   `lda_imm_sta $00, $8c
*   `cpy_bne 192, sub43_loop2

    `chr_bankswitch 3

    `lda_imm_sta %10001000, ppu_ctrl

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

    `lda_imm_sta %10011000, ppu_ctrl
    `lda_imm_sta %00011110, ppu_mask

    lda $8b
    `cmp_bne $fa, sub43_exit

    `inc_lda $0149
    `cmp_beq $02, +

    `lda_imm_sta $00, $014a
    `lda_imm_sta $01, $014b
    jmp sub43_exit

*   `lda_imm_sta $20, $014a
    `lda_imm_sta $21, $014b
    `lda_imm_sta $00, $0149

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
    `cpy_bne 12, -

    `reset_ppu_addr
    `set_ppu_addr vram_name_table0+9*32+10

    ldy #0
    ldx #$5c
*   stx ppu_data  ; start loop
    inx
    iny
    `cpy_bne 12, -

    `reset_ppu_addr
    `set_ppu_addr vram_name_table0+10*32+10

    ldy #0
    ldx #$68
*   stx ppu_data  ; start loop
    inx
    iny
    `cpy_bne 12, -

    `reset_ppu_addr

    `lda_imm_sta $01, $02
    lda #$00
    sta $8f
    sta $89
    `lda_imm_sta $00, $8a

    ; update third and fourth color of third sprite subpalette
    `set_ppu_addr vram_palette+6*4+2
    `write_ppu_data $00  ; dark gray
    `write_ppu_data $10  ; light gray
    `reset_ppu_addr

    `lda_imm_sta %10000000, ppu_ctrl
    `lda_imm_sta %00011110, ppu_mask

    `lda_imm_sta $00, $0130
    rts

    lda $0130
    `cmp_beq $01, sub43_1

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
    `lda_imm_sta $01, $0130

    `lda_imm_sta %00011110, ppu_mask
    `lda_imm_sta %00010000, ppu_ctrl

    `inc_lda $8a
    `cmp_beq 8, +
    jmp sub43_2
*   `lda_imm_sta $00, $8a
    `inc_lda $8f
    `cmp_beq $eb, +
    jmp ++
*   `lda_imm_sta $00, $02
    `lda_imm_sta $07, $01

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
    `cpx_bne 31, -

    `reset_ppu_addr

sub43_2:
    `chr_bankswitch 2
    `inc_ldx $89
    lda table20,x
    clc
    sbc #30
    sta ppu_scroll
    `lda_imm_sta 0, ppu_scroll

    `lda_imm_sta %00010000, ppu_ctrl
    `lda_imm_sta %00011110, ppu_mask

    `sprite_dma

    ldx #$ff
    jsr sub19
    jsr sub19
    jsr sub19
    ldx #$1e
    jsr sub19
    ldx #$d0
    jsr sub19

    `lda_imm_sta %00000000, ppu_ctrl

    `chr_bankswitch 0

    `lda_mem_sta $8a, ppu_scroll
    `lda_imm_sta 0, ppu_scroll

    `lda_imm_sta 215, sprite_page+0*4+0
    `lda_imm_sta $25, sprite_page+0*4+1
    `lda_imm_sta %00000000, sprite_page+0*4+2
    `lda_imm_sta 248, sprite_page+0*4+3

    `lda_imm_sta 207, sprite_page+1*4+0
    `lda_imm_sta $25, sprite_page+1*4+1
    `lda_imm_sta %00000000, sprite_page+1*4+2
    `lda_imm_sta 248, sprite_page+1*4+3

    `lda_imm_sta 223, sprite_page+2*4+0
    `lda_imm_sta $27, sprite_page+2*4+1
    `lda_imm_sta %00000000, sprite_page+2*4+2
    `lda_imm_sta 248, sprite_page+2*4+3

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

    `cpx_beq 0, +
    dex
    jmp -

*   `inc_lda $013a
    `cmp_bne $06, +
    inc $0139
    inc $0139
    `lda_imm_sta $00, $013a
*   `inc_lda $0138
    `cmp_bne $0c, +
    `lda_imm_sta $00, $0138
    `inc_lda $0137
    `cmp_bne $04, +
    `lda_imm_sta $00, $0137

*   `lda_imm_sta %10001000, ppu_ctrl
    `lda_imm_sta %00011000, ppu_mask
    rts

; -----------------------------------------------------------------------------

sub44:

    jsr init_graphics_and_sound
    ldy #$aa
    jsr sub56
    `lda_imm_sta $1a, $9a
    ldx #$60

sub44_loop1:  ; start outer loop
    ; $2100 + [$9a] -> ppu_addr
    `lda_imm_sta $21, ppu_addr
    `lda_mem_sta $9a, ppu_addr

    ldy #0
*   stx ppu_data  ; start inner loop
    inx
    iny
    `cpy_bne 3, -

    `reset_ppu_addr

    lda $9a
    `add_imm 32
    sta $9a
    lda $9a
    `cmp_bne $1a, sub44_loop1

    `lda_imm_sta $08, $9a
    ldx #$80

sub44_loop2:  ; start outer loop
    `lda_imm_sta $22, ppu_addr
    `lda_mem_sta $9a, ppu_addr

    ldy #0
*   stx ppu_data  ; start inner loop
    inx
    iny
    `cpy_bne 3, -

    `reset_ppu_addr

    lda $9a
    `add_imm 32
    sta $9a
    lda $9a
    `cmp_bne $68, sub44_loop2

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
    `cpx_bne 255, -

    ldx data5
*   lda #$00     ; start loop
    sta $0112,x
    lda #$f0
    sta $0116,x
    dex
    `cpx_bne $ff, -

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
    `cpx_bne 255, -

    `lda_imm_sta $7a, $0111
    `lda_imm_sta $0a, $0110

    ldx data4
*   txa        ; start loop
    asl
    asl
    tay

    lda table35,x
    sta sprite_page+1*4+1,y
    lda table36,x
    sta sprite_page+1*4+2,y

    `cpx_beq 0, +
    dex
    jmp -

*   lda #$00
    sta $0100
    sta $0101
    sta $0102
    `lda_imm_sta $01, $02

    `lda_imm_sta %10000000, ppu_ctrl
    `lda_imm_sta %00010010, ppu_mask
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
    `cmp_bne $00, sub45_2
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
    `cpx_bne 255, sub45_loop1

    `lda_mem_sta $0108, sprite_page+1*4+1
    `lda_mem_sta $0109, sprite_page+16*4+1
    `lda_mem_sta $010a, sprite_page+17*4+1
    `lda_mem_sta $010b, sprite_page+13*4+1

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

    `cpx_beq 0, +
    dex
    jmp -

*   lda $0100
    ldx $0101
    cmp table38,x
    bne sub45_3

    `inc_lda $0101
    cpx data6
    bne +
    `lda_imm_sta $00, $0101
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
    `lda_imm_sta $00, $0102

sub45_3:
    ldx data5
sub45_loop2:
    lda $0116,x
    `cmp_beq $f0, sub45_4
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
    `cpx_bne 255, sub45_loop2

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
    `cpx_bne 255, -

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
    `cpx_bne 255, -

    `lda_imm_sta %10000000, ppu_ctrl
    `lda_imm_sta %00011010, ppu_mask

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
    `cpx_bne 96, -

    `lda_imm_sta %00000010, ppu_ctrl
    `lda_imm_sta %00000000, ppu_mask
    rts

; -----------------------------------------------------------------------------

sub47:

    `set_ppu_scroll 0, 0

    `lda_imm_sta %10010000, ppu_ctrl
    `lda_imm_sta %00001110, ppu_mask
    rts

; -----------------------------------------------------------------------------

sub48:

    ldx #$4a
    jsr sub58
    ldy #$00
    jsr sub56
    jsr clear_palette_copy
    jsr update_palette

    `lda_imm_sta %00000010, ppu_ctrl
    `lda_imm_sta %00000000, ppu_mask

    `lda_imm_sta $00, $9a
    ldx #$00

sub48_loop:   ; start outer loop
    `lda_imm_sta $20, ppu_addr
    lda $9a
    `add_imm $69
    sta ppu_addr

    ldy #0
*   stx ppu_data  ; start inner loop
    inx
    iny
    `cpy_bne 16, -

    `reset_ppu_addr

    lda $9a
    `add_imm 32
    sta $9a
    `cmp_bne 96, sub48_loop

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
    `cpx_bne $80, -

    `reset_ppu_addr

    `lda_imm_sta $01, $02
    `lda_imm_sta $e6, $0153
    rts

; -----------------------------------------------------------------------------

sub49:

    `chr_bankswitch 2
    lda $0150
    `cmp_bne $00, +
    lda $014f
    `cmp_bne $03, +
    jsr init_palette_copy
    jsr update_palette

    ; update first background subpalette
    `set_ppu_addr vram_palette+0*4
    `write_ppu_data $0f  ; black
    `write_ppu_data $30  ; white
    `write_ppu_data $1a  ; medium-dark green
    `write_ppu_data $09  ; dark green
    `reset_ppu_addr

*   `lda_imm_sta 0, ppu_scroll
    ldx $0153
    lda table19,x
    `add_mem $0153
    sta ppu_scroll

    lda $0153
    `cmp_beq $00, +
    dec $0153
*   lda $0150
    `cmp_bne $03, +
    lda $014f
    cmp #$00
    bcc +
    `inc_lda $a3
    `cmp_bne $04, +
    jsr sub20
    jsr update_palette
    `lda_imm_sta $00, $a3
*   `lda_imm_sta $0c, $01

    `lda_imm_sta %10010000, ppu_ctrl
    `lda_imm_sta %00001110, ppu_mask
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

    `lda_imm_sta $c8, $013d

    `set_ppu_scroll 0, 200

    `lda_imm_sta $00, $014c
    `lda_imm_sta $01, $02

    `lda_imm_sta %10000000, ppu_ctrl
    rts

; -----------------------------------------------------------------------------

sub51:

    lda $013c
    `cmp_beq $02, +
    jmp sub51_1
*   ldy #$80

sub51_loop1:  ; start outer loop
    `lda_imm_sta >[vram_name_table0+8*32+4], ppu_addr
    lda #<[vram_name_table0+8*32+4]
    `add_mem $013b
    sta ppu_addr

    ldx #0
*   sty ppu_data  ; start inner loop
    iny
    inx
    `cpx_bne 8, -

    lda $013b
    `add_imm 32
    sta $013b
    `cpy_bne $c0, sub51_loop1

sub51_loop2:  ; start outer loop
    `lda_imm_sta >[vram_name_table0+16*32+4], ppu_addr
    lda #<[vram_name_table0+16*32+4]
    `add_mem $013b
    sta ppu_addr

    ldx #0
*   sty ppu_data  ; start inner loop
    iny
    inx
    `cpx_bne 8, -

    lda $013b
    `add_imm 32
    sta $013b
    `cpy_bne $00, sub51_loop2

    `reset_ppu_addr

    `lda_imm_sta $00, $013b

sub51_loop3:  ; start outer loop
    `lda_imm_sta >[vram_name_table0+8*32+20], ppu_addr
    lda #<[vram_name_table0+8*32+20]
    `add_mem $013b
    sta ppu_addr

    ldx #0
*   sty ppu_data  ; start inner loop
    iny
    inx
    `cpx_bne 8, -

    lda $013b
    `add_imm 32
    sta $013b
    `cpy_bne $c0, sub51_loop3

sub51_loop4:  ; start outer loop
    `lda_imm_sta >[vram_name_table0+16*32+20], ppu_addr
    lda #<[vram_name_table0+16*32+20]
    `add_mem $013b
    sta ppu_addr

    ldx #0
*   sty ppu_data  ; start inner loop
    iny
    inx
    `cpx_bne 8, -

    lda $013b
    `add_imm 32
    sta $013b
    `cpy_bne 0, sub51_loop4

    `reset_ppu_addr

sub51_1:
    lda $013c
    cmp #$a0
    bcc +
    jmp sub51_2

*   `lda_imm_sta $00, ppu_scroll
    lda $013d
    clc
    sbc $013c
    sta ppu_scroll

sub51_2:
    lda $00
    `chr_bankswitch 2
    `lda_imm_sta $00, $89
    lda $013e
    `cmp_beq $01, sub51_3
    `inc_lda $013c
    `cmp_beq $c8, +
    jmp sub51_3
*   `lda_imm_sta $01, $013e

sub51_3:
    ldx #$00
    ldy #$00
    lda $013e
    `cmp_beq $00, sub51_5
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

*   `lda_imm_sta %00001110, ppu_mask
    jmp sub51_4

*   lda $89
    cmp $9b
    bcs +
    `lda_imm_sta %11101110, ppu_mask

sub51_4:
    jmp ++

*   `lda_imm_sta %00001110, ppu_mask

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
    `cpy_bne $91, sub51_loop5

sub51_5:
    `lda_imm_sta %10010000, ppu_ctrl
    `lda_imm_sta %00001110, ppu_mask
    rts

; -----------------------------------------------------------------------------

sub52:

    ldy #0
*   stx ppu_data
    iny
    `cpy_bne 32, -

    rts

; -----------------------------------------------------------------------------

sub53:
    ; Why identical to the previous subroutine?

    ldy #0
*   stx ppu_data
    iny
    `cpy_bne 32, -

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
    `lda_mem_sta table18+4, ppu_data
    `lda_mem_sta table18+5, ppu_data
    `lda_mem_sta table18+6, ppu_data
    `lda_mem_sta table18+7, ppu_data
    `reset_ppu_addr

    ; update first sprite subpalette from table18
    `set_ppu_addr vram_palette+4*4
    `lda_mem_sta table18+8, ppu_data
    `lda_mem_sta table18+9, ppu_data
    `lda_mem_sta table18+10, ppu_data
    `lda_mem_sta table18+11, ppu_data
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
    `cpx_bne 255, -

    `lda_imm_sta $00, $0100
    `lda_imm_sta $01, $02
    lda #$00
    sta $89
    sta $8a
    `lda_imm_sta $00, $8f
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
    `cpx_bne 7, -

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
    `cpx_bne 255, -

    `chr_bankswitch 0
    `inc_lda $8a
    `cmp_beq $08, +
    jmp sub55_2
*   `lda_imm_sta $00, $8a
    `inc_lda $8f
    `cmp_beq $eb, +
    jmp sub55_1
*   `lda_imm_sta $00, $02
    `lda_imm_sta $07, $01

sub55_1:
    `lda_imm_sta >[vram_name_table0+19*32+1], ppu_addr
    `lda_imm_sta <[vram_name_table0+19*32+1], ppu_addr

    ldx #0
*   txa           ; start loop
    `add_mem $8f
    tay
    lda table11,y
    clc
    sbc #$36
    sta ppu_data
    inx
    `cpx_bne 31, -

    `reset_ppu_addr

sub55_2:
    `inc_ldx $89
    `lda_mem_sta $8a, ppu_scroll
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
    `lda_imm_sta $25, sprite_page+0*4+1
    `lda_imm_sta %00000000, sprite_page+0*4+2
    `lda_imm_sta 248, sprite_page+0*4+3

    lda #152
    clc
    sbc $9a
    sta sprite_page+1*4+0
    `lda_imm_sta $25, sprite_page+1*4+1
    `lda_imm_sta %00000000, sprite_page+1*4+2
    `lda_imm_sta 248, sprite_page+1*4+3

    lda #156
    clc
    sbc $9a
    sta sprite_page+2*4+0
    `lda_imm_sta $25, sprite_page+2*4+1
    `lda_imm_sta %00000000, sprite_page+2*4+2
    `lda_imm_sta 248, sprite_page+2*4+3

    lda #148
    clc
    sbc $9a
    sta sprite_page+3*4+0
    `lda_imm_sta $25, sprite_page+3*4+1
    `lda_imm_sta %00000000, sprite_page+3*4+2
    `lda_imm_sta 0, sprite_page+3*4+3

    lda #152
    clc
    sbc $9a
    sta sprite_page+4*4+0
    `lda_imm_sta $25, sprite_page+4*4+1
    `lda_imm_sta %00000000, sprite_page+4*4+2
    `lda_imm_sta 0, sprite_page+4*4+3

    lda #156
    clc
    sbc $9a
    sta sprite_page+5*4+0
    `lda_imm_sta $25, sprite_page+5*4+1
    `lda_imm_sta %00000000, sprite_page+5*4+2
    `lda_imm_sta 0, sprite_page+5*4+3

    `lda_imm_sta %10000000, ppu_ctrl
    `lda_imm_sta %00011110, ppu_mask
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
    `lda_imm_sta $3c, $9a

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

    `lda_imm_sta $01, $02

    `reset_ppu_addr
    rts

; -----------------------------------------------------------------------------

sub59:

    stx $8e
    ldy #$00
    `lda_imm_sta $3c, $9a

    lda #%00000000
    sta ppu_ctrl
    sta ppu_mask

    ; clear Attribute Table 0
    `set_ppu_addr vram_attr_table0
    ldx #0
*   `write_ppu_data $00
    inx
    `cpx_bne 64, -

    ; clear Attribute Table 1
    `set_ppu_addr vram_attr_table1
    ldx #0
*   `write_ppu_data $00
    inx
    `cpx_bne 64, -

    `set_ppu_addr vram_name_table0

    ldx #0
    ldy #0
*   `lda_mem_sta $8e, ppu_data
    inx
    bne -

*   `lda_mem_sta $8e, ppu_data
    inx
    bne -

*   `lda_mem_sta $8e, ppu_data
    inx
    bne -

*   `lda_mem_sta $8e, ppu_data
    inx
    `cpx_bne 192, -

    `set_ppu_addr vram_name_table1

    ldx #0
    ldy #0
*   `lda_mem_sta $8e, ppu_data
    inx
    bne -

*   `lda_mem_sta $8e, ppu_data
    inx
    bne -

*   `lda_mem_sta $8e, ppu_data
    inx
    bne -

*   `lda_mem_sta $8e, ppu_data
    inx
    `cpx_bne 192, -

    `set_ppu_addr vram_name_table2

    ldx #0
    ldy #0
*   `lda_mem_sta $8e, ppu_data
    inx
    bne -

*   `lda_mem_sta $8e, ppu_data
    inx
    bne -

*   `lda_mem_sta $8e, ppu_data
    inx
    bne -

*   `lda_mem_sta $8e, ppu_data
    inx
    `cpx_bne 192, -

    `lda_imm_sta $01, $02
    `lda_imm_sta $72, $96

    `reset_ppu_addr
    `reset_ppu_scroll

    `lda_imm_sta %00000000, ppu_ctrl
    `lda_imm_sta %00011110, ppu_mask
    rts
