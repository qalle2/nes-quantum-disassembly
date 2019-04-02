; second half of PRG ROM except interrupt routines&vectors

; -----------------------------------------------------------------------------

init:

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

    ; the demo part to run
    lda #0
    sta demo_part

    lda #%00000000
    sta ppu_ctrl
    lda #%00011110
    sta ppu_mask

    ldx #$ff
    jsr sub59
    jsr sub18

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

wait_vbl_loop:
    bit ppu_status
    bpl wait_vbl_loop
    rts

; -----------------------------------------------------------------------------

init_graphics_and_sound:
    ; Called by: init, sub38, sub40, sub41, sub42, sub43, sub44, sub50, sub54

    ; hide all sprites (set Y position outside screen)
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
    ; Called by: init, init_graphics_and_sound, sub34, sub36, sub38, sub40,
    ; sub43, game_over_screen, sub49

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
    ; Called by: init, init_graphics_and_sound, sub21, sub34, sub36, sub38,
    ; sub40, sub41, sub43, game_over_screen, greets_screen, sub49

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

    ; Called by: sub35, sub39, sub43, sub51

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
unaccessed_loop1:
    clc
    adc #$55
    clc
    nop
    nop
    adc #15
    sbc #15
    inx
    cpx $88
    bne unaccessed_loop1

    rts

    stx $88
    ldy #0
    ldx #0
unaccessed_loop2_outer:

    ldy #0
unaccessed_loop2_inner:
    nop
    nop
    nop
    nop
    nop
    iny
    cpy #11
    bne unaccessed_loop2_inner

    nop
    inx
    cpx $88
    bne unaccessed_loop2_outer

    rts

; -----------------------------------------------------------------------------

fade_out_palette:
    ; Change each color in the palette_copy array (32 bytes).
    ; Used to fade out the "wAMMA - QUANTUM DISCO BROTHERS" logo.

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

    ; Called by: sub21

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

    ; Called by: sub19

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

    ; Called by: sub19, sub21

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

sub19:

    ; Called by: NMI

    `chr_bankswitch 0
    lda $95

    cmp #1
    beq sub19_jump_table+1*3
    cmp #2
    beq sub19_jump_table+2*3
    cmp #3
    beq sub19_jump_table+3*3
    cmp #4
    beq sub19_jump_table+4*3
    cmp #5
    beq sub19_jump_table+5*3
    cmp #6
    beq sub19_jump_table+6*3
    cmp #7
    beq sub19_jump_table+7*3
    cmp #8
    beq sub19_jump_table+8*3
    cmp #9
    beq sub19_01
    cmp #10
    beq sub19_jump_table+10*3
    jmp sub19_11

sub19_01:
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

sub19_jump_table:
    jmp sub19_11  ;  0*3
    jmp sub19_02  ;  1*3
    jmp sub19_03  ;  2*3
    jmp sub19_04  ;  3*3
    jmp sub19_05  ;  4*3
    jmp sub19_06  ;  5*3
    jmp sub19_07  ;  6*3
    jmp sub19_08  ;  7*3
    jmp sub19_09  ;  8*3
    jmp sub19_11  ;  9*3 (unaccessed, $e013)
    jmp sub19_10  ; 10*3

sub19_02:
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
    jmp sub19_11
*   lda #$00
    sta $96
    jmp sub19_11

sub19_03:
    lda #$00
    sta $96
    jmp sub19_11

sub19_04:
    ; pointer 1 -> ptr1
    lda pointers+1*2+0
    sta ptr1+0
    lda pointers+1*2+1
    sta ptr1+1

    ldx #$20
    ldy #$a0
    jsr sub16
    jmp sub19_11

sub19_05:
    ; pointer 2 -> ptr1
    lda pointers+2*2+0
    sta ptr1+0
    lda pointers+2*2+1
    sta ptr1+1

    ldx #$21
    ldy #$20
    jsr sub16
    jmp sub19_11

sub19_06:
    ; pointer 3 -> ptr1
    lda pointers+3*2+0
    sta ptr1+0
    lda pointers+3*2+1
    sta ptr1+1

    ldx #$21
    ldy #$a0
    jsr sub16
    jmp sub19_11

sub19_07:
    ; pointer 4 -> ptr1
    lda pointers+4*2+0
    sta ptr1+0
    lda pointers+4*2+1
    sta ptr1+1

    ldx #$22
    ldy #$40
    jsr sub16
    jmp sub19_11

sub19_08:
    ; pointer 5 -> ptr1
    lda pointers+5*2+0
    sta ptr1+0
    lda pointers+5*2+1
    sta ptr1+1

    ldx #$22
    ldy #$c0
    jsr sub16
    jmp sub19_11

sub19_09:
    ; pointer 6 -> ptr1
    lda pointers+6*2+0
    sta ptr1+0
    lda pointers+6*2+1
    sta ptr1+1

    ldx #$23
    ldy #$40
    jsr sub16
    jmp sub19_11

sub19_10:
    lda #2  ; 2nd part
    sta demo_part
    lda #0
    sta flag1
    jmp sub19_11

sub19_11:
    jmp sub19_13

; -----------------------------------------------------------------------------
; Unaccessed block ($e0d3)

    lda #$00
    sta $9a
    lda $96
    cmp #$a0
    bcc +
    jmp sub19_12
*   ldx $93

    lda table19,x
    clc
    adc #$58
    sta sprite_page+0*4+sprite_y

    lda table20,x
    clc
    adc #$6e
    sta sprite_page+0*4+sprite_x

    lda table19,x
    clc
    adc #$58
    sta sprite_page+1*4+sprite_y

    lda table20,x
    clc
    adc #$76
    sta sprite_page+1*4+sprite_x

    lda table19,x
    clc
    adc #$60
    sta sprite_page+2*4+sprite_y

    lda table20,x
    clc
    adc #$6e
    sta sprite_page+2*4+sprite_x

    lda table19,x
    clc
    adc #$60
    sta sprite_page+3*4+sprite_y

    lda table20,x
    clc
    adc #$76
    sta sprite_page+3*4+sprite_x

    lda table20,x
    clc
    adc #$58
    sta sprite_page+4*4+sprite_y

    lda table19,x
    clc
    adc #$6e
    sta sprite_page+4*4+sprite_x

    lda table20,x
    clc
    adc #$58
    sta sprite_page+5*4+sprite_y

    lda table19,x
    clc
    adc #$76
    sta sprite_page+5*4+sprite_x

    lda table20,x
    clc
    adc #$60
    sta sprite_page+6*4+sprite_y

    lda table19,x
    clc
    adc #$6e
    sta sprite_page+6*4+sprite_x

    lda table20,x
    clc
    adc #$60
    sta sprite_page+7*4+sprite_y

    lda table19,x
    clc
    adc #$75
    sta sprite_page+7*4+sprite_x

    jmp sub19_13

sub19_12:
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

sub19_13:
    jsr sub17

    `sprite_dma
    rts

; -----------------------------------------------------------------------------

sub20:

    ; Called by: NMI

    ; clear Name Tables
    ldx #$00
    jsr fill_name_tables

    ldy #$00
    ldy #$00

    ; fill rows 1-8 of Name Table 2 with #$00-#$ff
    `set_ppu_addr vram_name_table2+32
    ldx #0
sub20_loop:
    stx ppu_data
    inx
    bne sub20_loop
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

sub21:

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
    bne sub21_1
    lda $ab
    cmp #$96
    bne sub21_1
    ldx data1

sub21_loop1:
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
    jmp sub21_loop1

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

sub21_1:
    lda $ac
    cmp #$02
    bne sub21_2
    lda $ab
    cmp #$32
    bcc sub21_2

    ldx #0
    ldy #0
sub21_loop2:
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
    bne sub21_loop2

sub21_2:
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

sub32:
    lda #$00
    ldx #0
sub32_loop:
    sta pulse1_ctrl,x
    inx
    cpx #15
    bne sub32_loop

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

sub33:
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
sub33_loop_outer:

    ldx #25
sub33_loop_inner:
    dex
    bne sub33_loop_inner

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
    bne sub33_loop_outer

    lda #%00000110
    sta ppu_mask
    lda #%10010000
    sta ppu_ctrl
    rts

; -----------------------------------------------------------------------------

sub34:

    ; clear Name Tables
    ldx #$00
    jsr fill_name_tables

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
sub35_loop1:
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
    bne sub35_loop1

    ldx #0
    ldy #0
    lda #$00
    sta $9a

sub35_loop2_outer:
    ; #$2100 + $9a -> ppu_addr
    lda #$21
    sta ppu_addr
    lda $9a
    sta ppu_addr

    ldy #0
sub35_loop2_inner:
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
    bne sub35_loop2_inner

    lda $9a
    clc
    adc #32
    sta $9a
    lda $9a
    cmp #$00
    bne sub35_loop2_outer

    lda #$01
    sta $0148
    jmp sub35_2

sub35_1:
    dec $8a
    ldx #64
    lda #$00
    sta $89

sub35_loop3:
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
    bne sub35_loop3

    ldx #$7f
    lda #$00
    sta $9a

sub35_loop4_outer:
    lda #$22
    sta ppu_addr
    lda $9a
    sta ppu_addr

    ldy #0
sub35_loop4_inner:
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
    bne sub35_loop4_inner

    lda $9a
    clc
    adc #32
    sta $9a
    lda $9a
    cmp #$00
    bne sub35_loop4_outer

    lda #$00
    sta $0148

sub35_2:
    `reset_ppu_addr

    lda #$00
    sta $89

sub35_loop5:
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
    bne sub35_loop5

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

    ; clear Name Tables
    ldx #$00
    jsr fill_name_tables

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

    jsr change_background_color
    `chr_bankswitch 1
    dec $8a
    dec $8a

    ldx #0
    lda #0
    sta $89
sub37_loop1:
    lda $89
    adc $8a
    tay
    lda table19,y
    adc #$46
    sta $0600,x
    inc $89
    inx
    cpx #128
    bne sub37_loop1

    lda $0148
    cmp #$00
    beq +
    jmp sub37_1

*   ldx #0
    ldy #0
    lda #$00

    sta $9a
sub37_loop2_outer:
    ; #$2100 + $9a -> ppu_addr
    lda #$21
    sta ppu_addr
    lda $9a
    sta ppu_addr

    ldy #0
sub37_loop2_inner:
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
    bne sub37_loop2_inner

    lda $9a
    clc
    adc #32
    sta $9a
    lda $9a
    cmp #$00
    bne sub37_loop2_outer

    lda #$01
    sta $0148
    jmp sub37_2

sub37_1:
    ldx #$7f
    lda #$20
    sta $9a

sub37_loop3_outer:
    lda #$22
    sta ppu_addr
    lda $9a
    sta ppu_addr

    ldy #0
sub37_loop3_inner:
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
    bne sub37_loop3_inner

    lda $9a
    clc
    adc #32
    sta $9a
    lda $9a
    cmp #$00
    bne sub37_loop3_outer

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
sub39_loop_outer:

    ldx #25
sub39_loop_inner:
    dex
    bne sub39_loop_inner

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
    bne sub39_loop_outer

    `reset_ppu_addr

    ; update first color of first background subpalette
    `set_ppu_addr_via_x vram_palette+0*4
    `write_ppu_data $0f  ; black
    `reset_ppu_addr
    rts

; -----------------------------------------------------------------------------

sub40:

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

sub40_1:
    lda #$00
    sta $9e
    lda #$00
    sta $9f
sub40_loop1_outer:

    ldy #0
sub40_loop1_middle:

    ldx #0
sub40_loop1_inner:
    txa
    clc
    adc $9e
    sta ppu_data
    inx
    cpx #8
    bne sub40_loop1_inner

    iny
    cpy #$04
    bne sub40_loop1_middle

    lda $9e
    clc
    adc #8
    sta $9e
    lda $9e
    cmp #$40
    bne sub40_loop1_outer

    lda #$00
    sta $9e
    inc $9f
    lda $9f
    cmp #$03
    bne sub40_loop1_outer

    ldx #0
sub40_loop2_outer:

    ldy #0
sub40_loop2_middle:

    ldx #0
sub40_loop2_inner:
    txa
    clc
    adc $9e
    sta ppu_data
    inx
    cpx #8
    bne sub40_loop2_inner

    iny
    cpy #4
    bne sub40_loop2_middle

    lda $9e
    clc
    adc #8
    sta $9e
    cmp #$28
    bne sub40_loop2_outer

    lda #$f0  ; unnecessary

    ; write 64 bytes to ppu_data (#$f0-#$f7 eight times)

    ldy #0
sub40_loop3_outer:

    ldx #$f0
sub40_loop3_inner:
    stx ppu_data
    inx
    cpx #$f8
    bne sub40_loop3_inner

    iny
    cpy #8
    bne sub40_loop3_outer

    `reset_ppu_addr

    inc $a0
    lda $a0
    cmp #$02
    bne +
    jmp sub40_2

*   `set_ppu_addr vram_name_table2

    jmp sub40_1

sub40_2:
    ; clear Attribute Table 0
    `set_ppu_addr vram_attr_table0
    ldx #0
sub40_loop4:
    lda #$00
    sta ppu_data
    inx
    cpx #64
    bne sub40_loop4
    `reset_ppu_addr

    ; clear Attribute Table 2
    `set_ppu_addr vram_attr_table2
    ldx #0
sub40_loop5:
    lda #$00
    sta ppu_data
    inx
    cpx #64
    bne sub40_loop5
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
    inc $a3
    lda $a3
    cmp #$04
    bne sub41_01

    jsr fade_out_palette
    jsr update_palette
    lda #$00
    sta $a3

sub41_01:
    lda #3  ; 9th part
    sta demo_part

    `set_ppu_addr vram_palette+0*4

    lda $a2
    cmp #8
    beq sub41_04
    lda $014d
    cmp #0
    beq sub41_03
    cmp #1
    beq sub41_02
    cmp #2
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
    lda #10  ; 10th part
    sta demo_part
    lda #0
    sta flag1
    jmp sub41_16

sub41_07:
    jsr init_graphics_and_sound

    ; draw 8*2 sprites: tiles #$90-#$9f starting from (92, 106), subpalette 3
    ldx #92
    ldy #106
    lda #$90
    sta $9a
    jsr update_sixteen_sprites

    jmp sub41_16

sub41_08:
    jsr init_graphics_and_sound

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

    jmp sub41_16

sub41_09:
    jsr init_graphics_and_sound

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

    jmp sub41_16

sub41_10:
    jsr init_graphics_and_sound
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

    jmp sub41_16

sub41_11:
    jsr init_graphics_and_sound

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

    jmp sub41_16

sub41_12:
    jsr init_graphics_and_sound

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

    jmp sub41_16

sub41_13:
    lda #$00
    sta $014d
    jsr init_graphics_and_sound

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

    jmp sub41_16

sub41_14:
    jsr init_graphics_and_sound

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

    jmp sub41_16

sub41_15:
    jsr init_graphics_and_sound
sub41_16:
    `chr_bankswitch 1

    lda #%10011000
    sta ppu_ctrl
    lda #%00011110
    sta ppu_mask
    rts

; -----------------------------------------------------------------------------

sub42:

    ; fill Name Tables with #$7f
    ldx #$7f
    jsr fill_name_tables

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
    ; the left half consists of tiles #$00, #$01, ..., #$ff;
    ; the right half consists of tile #$7f

    `set_ppu_addr vram_name_table0

    ldy #0
sub42_loop1_outer:

    ; write Y...Y+15
    ldx #0
sub42_loop1_inner1:
    sty ppu_data
    iny
    inx
    cpx #16
    bne sub42_loop1_inner1

    ; write 16 * byte #$7f
    ldx #0
sub42_loop1_inner2:
    `write_ppu_data $7f
    inx
    cpx #16
    bne sub42_loop1_inner2

    cpy #0
    bne sub42_loop1_outer

    jsr sub12

    ; write another 7 rows to Name Table 0;
    ; the left half consists of tiles #$00, #$01, ..., #$df
    ; the right half consists of tile #$7f

    ldy #0
sub42_loop2_outer:

    ; first inner loop
    ldx #0
sub42_loop2_inner1:
    sty ppu_data
    iny
    inx
    cpx #16
    bne sub42_loop2_inner1

    ; second inner loop
    ldx #0
sub42_loop2_inner2:
    `write_ppu_data $7f
    inx
    cpx #16
    bne sub42_loop2_inner2

    cpy #7*32
    bne sub42_loop2_outer

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
    bne sub43_loop1

    ; 24 -> X
    ;  0 -> $9a, $89
    ; $8c -= 1
    ldx #24
    lda #$00
    sta $9a
    sta $89
    dec $8c

sub43_loop2:
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
    bne sub43_loop2

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

; -----------------------------------------------------------------------------
; Unaccessed block ($ec99)

    ldx #$7a
    jsr fill_name_tables

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
sub43_loop3:
    stx ppu_data
    inx
    iny
    cpy #12
    bne sub43_loop3

    `reset_ppu_addr
    `set_ppu_addr vram_name_table0+9*32+10

    ldy #0
    ldx #$5c
sub43_loop4:
    stx ppu_data
    inx
    iny
    cpy #12
    bne sub43_loop4

    `reset_ppu_addr
    `set_ppu_addr vram_name_table0+10*32+10

    ldy #0
    ldx #$68
sub43_loop5:
    stx ppu_data
    inx
    iny
    cpy #12
    bne sub43_loop5

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
    beq sub43_1

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

sub43_1:
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
    jmp sub43_2
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
sub43_loop6:
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
    bne sub43_loop6

    `reset_ppu_addr

sub43_2:
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
sub43_loop7:
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
    jmp sub43_loop7

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

sub44:

    jsr init_graphics_and_sound
    ldy #$aa
    jsr sub56
    lda #$1a
    sta $9a
    ldx #$60

sub44_loop1_outer:
    ; #$2100 + $9a -> ppu_addr
    lda #$21
    sta ppu_addr
    lda $9a
    sta ppu_addr

    ldy #0
sub44_loop1_inner:
    stx ppu_data
    inx
    iny
    cpy #3
    bne sub44_loop1_inner

    `reset_ppu_addr

    lda $9a
    clc
    adc #32
    sta $9a
    lda $9a
    cmp #$1a
    bne sub44_loop1_outer

    lda #$08
    sta $9a
    ldx #$80

sub44_loop2_outer:
    lda #$22
    sta ppu_addr
    lda $9a
    sta ppu_addr

    ldy #0
sub44_loop2_inner:
    stx ppu_data
    inx
    iny
    cpy #3
    bne sub44_loop2_inner

    `reset_ppu_addr

    lda $9a
    clc
    adc #32
    sta $9a
    lda $9a
    cmp #$68
    bne sub44_loop2_outer

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
sub44_loop3:
    lda table31,x
    sta $0104,x
    lda table32,x
    sta $0108,x
    dex
    cpx #255
    bne sub44_loop3

    ldx data5
sub44_loop4:
    lda #$00
    sta $0112,x
    lda #$f0
    sta $0116,x
    dex
    cpx #$ff
    bne sub44_loop4

    ldx data7
sub44_loop5:
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
    bne sub44_loop5

    lda #$7a
    sta $0111
    lda #$0a
    sta $0110

    ldx data4
sub44_loop6:
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
    jmp sub44_loop6

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
    sta sprite_page+1*4+sprite_tile
    lda $0109
    sta sprite_page+16*4+sprite_tile
    lda $010a
    sta sprite_page+17*4+sprite_tile
    lda $010b
    sta sprite_page+13*4+sprite_tile

    ldx data4
sub45_loop2:
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
    jmp sub45_loop2

*   lda $0100
    ldx $0101
    cmp table38,x
    bne sub45_3

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
    bne sub45_3
    lda #$00
    sta $0102

sub45_3:
    ldx data5
sub45_loop3:
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
    bne sub45_loop3

    ldx data5
sub45_loop4:
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
    bne sub45_loop4

    ldx data7
sub45_loop5:
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
    bne sub45_loop5

    lda #%10000000
    sta ppu_ctrl
    lda #%00011010
    sta ppu_mask

    `set_ppu_scroll 0, 50
    rts

; -----------------------------------------------------------------------------

game_over_screen:
	; Show the "GAME OVER - CONTINUE?" screen.

    ; fill Name Tables with the space character (#$4a)
    ldx #$4a
    jsr fill_name_tables

    ldy #$00
    jsr sub56
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

sub47:

    `set_ppu_scroll 0, 0

    lda #%10010000
    sta ppu_ctrl
    lda #%00001110
    sta ppu_mask
    rts

; -----------------------------------------------------------------------------

greets_screen:
    ; Show the "GREETS TO ALL NINTENDAWGS" screen.

    ; fill Name Tables with the space character
    ldx #$4a
    jsr fill_name_tables

    ldy #$00
    jsr sub56
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

sub50:

    ; fill Name Tables with #$80
    ldx #$80
    jsr fill_name_tables

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

sub51_loop1_outer:
    lda #>[vram_name_table0+8*32+4]
    sta ppu_addr
    lda #<[vram_name_table0+8*32+4]
    clc
    adc $013b
    sta ppu_addr

    ldx #0
sub51_loop1_inner:
    sty ppu_data
    iny
    inx
    cpx #8
    bne sub51_loop1_inner

    lda $013b
    clc
    adc #32
    sta $013b
    cpy #$c0
    bne sub51_loop1_outer

sub51_loop2_outer:
    lda #>[vram_name_table0+16*32+4]
    sta ppu_addr
    lda #<[vram_name_table0+16*32+4]
    clc
    adc $013b
    sta ppu_addr

    ldx #0
sub51_loop2_inner:
    sty ppu_data
    iny
    inx
    cpx #8
    bne sub51_loop2_inner

    lda $013b
    clc
    adc #32
    sta $013b
    cpy #$00
    bne sub51_loop2_outer

    `reset_ppu_addr

    lda #$00
    sta $013b

sub51_loop3_outer:
    lda #>[vram_name_table0+8*32+20]
    sta ppu_addr
    lda #<[vram_name_table0+8*32+20]
    clc
    adc $013b
    sta ppu_addr

    ldx #0
sub51_loop3_inner:
    sty ppu_data
    iny
    inx
    cpx #8
    bne sub51_loop3_inner

    lda $013b
    clc
    adc #32
    sta $013b
    cpy #$c0
    bne sub51_loop3_outer

sub51_loop4_outer:
    lda #>[vram_name_table0+16*32+20]
    sta ppu_addr
    lda #<[vram_name_table0+16*32+20]
    clc
    adc $013b
    sta ppu_addr

    ldx #0
sub51_loop4_inner:
    sty ppu_data
    iny
    inx
    cpx #8
    bne sub51_loop4_inner

    lda $013b
    clc
    adc #32
    sta $013b
    cpy #0
    bne sub51_loop4_outer

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
    inc $013c
    lda $013c
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
sub52_loop:
    stx ppu_data
    iny
    cpy #32
    bne sub52_loop

    rts

; -----------------------------------------------------------------------------
; Unaccessed block ($f4f9)

sub53:
    ldy #0
sub53_loop:
    stx ppu_data
    iny
    cpy #32
    bne sub53_loop
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
sub54_loop:
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
    bne sub54_loop

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

    inc $0100
    ldx $0100
    lda woman_sprite_x,x
    sta $9a
    lda table22,x
    sta $9b

    `sprite_dma

    ldx data7
sub55_loop1:
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
    bne sub55_loop1

sub55_loop2:
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
    bne sub55_loop2

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
*   lda #0
    sta flag1
    lda #7  ; 7th part
    sta demo_part

sub55_1:
    lda #>[vram_name_table0+19*32+1]
    sta ppu_addr
    lda #<[vram_name_table0+19*32+1]
    sta ppu_addr

    ldx #0
sub55_loop3:
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
    bne sub55_loop3

    `reset_ppu_addr

sub55_2:
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

sub56:

    `set_ppu_addr vram_attr_table0

    ldx #64
sub56_loop1:
    sty ppu_data
    dex
    bne sub56_loop1

    `set_ppu_addr vram_attr_table2

    ldx #64
sub56_loop2:
    sty ppu_data
    dex
    bne sub56_loop2

    `reset_ppu_addr
    rts

; -----------------------------------------------------------------------------

sub57:

    `set_ppu_addr vram_attr_table0

    ldx #32
sub57_loop1:
    sty ppu_data
    dex
    bne sub57_loop1

    `set_ppu_addr vram_attr_table2

    ldx #32
sub57_loop2:
    sty ppu_data
    dex
    bne sub57_loop2

    `reset_ppu_addr
    rts

; -----------------------------------------------------------------------------
; Unaccessed block ($f7d0)

    `set_ppu_addr vram_attr_table0+4*8

    ldx #32
sub57_loop3:
    sty ppu_data
    dex
    bne sub57_loop3

    `set_ppu_addr vram_attr_table2+4*8

    ldx #32
sub57_loop4:
    sty ppu_data
    dex
    bne sub57_loop4

    `reset_ppu_addr
    rts

; -----------------------------------------------------------------------------

fill_name_tables:
    ; Fill Name Tables 0 and 2 with byte X and set flag1.

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
fill_nt0_loop:
    lda $8e
    sta ppu_data
    sta ppu_data
    sta ppu_data
    sta ppu_data
    inx
    bne fill_nt0_loop

    `set_ppu_addr vram_name_table2

    ldx #0
    ldy #0
fill_nt2_loop:
    lda $8e
    sta ppu_data
    sta ppu_data
    sta ppu_data
    sta ppu_data
    inx
    bne fill_nt2_loop

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
clear_at0_loop:
    `write_ppu_data $00
    inx
    cpx #64
    bne clear_at0_loop

    ; clear Attribute Table 1
    `set_ppu_addr vram_attr_table1
    ldx #0
clear_at1_loop:
    `write_ppu_data $00
    inx
    cpx #64
    bne clear_at1_loop

    ; clear Name Table 0 (960 bytes)

    `set_ppu_addr vram_name_table0

    ldx #0
    ldy #0

clear_nt0_loop1:
    lda $8e
    sta ppu_data
    inx
    bne clear_nt0_loop1

clear_nt0_loop2:
    lda $8e
    sta ppu_data
    inx
    bne clear_nt0_loop2

clear_nt0_loop3:
    lda $8e
    sta ppu_data
    inx
    bne clear_nt0_loop3

clear_nt0_loop4:
    lda $8e
    sta ppu_data
    inx
    cpx #192
    bne clear_nt0_loop4

    ; clear Name Table 1 (960 bytes)

    `set_ppu_addr vram_name_table1

    ldx #0
    ldy #0

clear_nt1_loop1:
    lda $8e
    sta ppu_data
    inx
    bne clear_nt1_loop1

clear_nt1_loop2:
    lda $8e
    sta ppu_data
    inx
    bne clear_nt1_loop2

clear_nt1_loop3:
    lda $8e
    sta ppu_data
    inx
    bne clear_nt1_loop3

clear_nt1_loop4:
    lda $8e
    sta ppu_data
    inx
    cpx #192
    bne clear_nt1_loop4

    ; clear Name Table 2 (960 bytes)

    `set_ppu_addr vram_name_table2

    ldx #0
    ldy #0

clear_nt2_loop1:
    lda $8e
    sta ppu_data
    inx
    bne clear_nt2_loop1

clear_nt2_loop2:
    lda $8e
    sta ppu_data
    inx
    bne clear_nt2_loop2

clear_nt2_loop3:
    lda $8e
    sta ppu_data
    inx
    bne clear_nt2_loop3

clear_nt2_loop4:
    lda $8e
    sta ppu_data
    inx
    cpx #192
    bne clear_nt2_loop4

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
