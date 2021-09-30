; NES Quantum Disco Brothers disassembly. Assembles with asm6.
; TODO: data on unaccessed parts is out of date

; --- Constants -----------------------------------------------------------------------------------

    ; NES memory-mapped registers
    ppu_ctrl      equ $2000
    ppu_mask      equ $2001
    ppu_status    equ $2002
    ppu_scroll    equ $2005
    ppu_addr      equ $2006
    ppu_data      equ $2007
    apu_regs      equ $4000
    pulse1_ctrl   equ $4000
    pulse1_sweep  equ $4001
    pulse1_timer  equ $4002
    pulse1_length equ $4003
    triangle_ctrl equ $4008
    noise_period  equ $400e
    noise_length  equ $400f
    dmc_ctrl      equ $4010
    dmc_load      equ $4011
    dmc_addr      equ $4012
    dmc_length    equ $4013
    oam_dma       equ $4014
    apu_ctrl      equ $4015
    apu_counter   equ $4017

    ; zero page
    ram1       equ $00  ; ??
    demo_part  equ $01  ; which part is running (see int.asm)
    temp1      equ $01
    flag1      equ $02  ; flag used in NMI? (seems to always be 0 or 1)
    ptr1       equ $03  ; pointer (2 bytes)
    delay_var1 equ $86
    delay_cnt  equ $87
    delay_var2 equ $88
    loopcnt    equ $9b  ; loop counter (may have other uses)
    ptr2       equ $c8  ; pointer (2 bytes)
    ptr3       equ $ce  ; pointer (2 bytes)
    ptr4       equ $d0  ; pointer (2 bytes)
    ptr5       equ $d8  ; pointer (2 bytes)
    ptr6       equ $da  ; pointer (2 bytes)

    ; other RAM
    sprite_page  equ $0500  ; 256 bytes
    palette_copy equ $07c0  ; 32 bytes

    ; video RAM
    vram_name_table0 equ $2000
    vram_attr_table0 equ $23c0
    vram_name_table1 equ $2400
    vram_attr_table1 equ $27c0
    vram_name_table2 equ $2800
    vram_attr_table2 equ $2bc0
    vram_palette     equ $3f00

    ; offsets for each sprite on sprite page
    sprite_y    equ 0
    sprite_tile equ 1
    sprite_attr equ 2
    sprite_x    equ 3

; --- Macros --------------------------------------------------------------------------------------

macro chr_bankswitch _bank  ; write bank number (0-3) over the same value in PRG ROM
_label  lda #(_bank)
        sta _label + 1
endm

macro reset_ppu_addr
        lda #$00
        sta ppu_addr
        sta ppu_addr
endm

macro set_ppu_addr _addr
        lda #>(_addr)
        sta ppu_addr
        lda #<(_addr)
        sta ppu_addr
endm

macro set_ppu_addr_via_x _addr
        ldx #>(_addr)
        stx ppu_addr
        ldx #<(_addr)
        stx ppu_addr
endm

macro set_ppu_scroll _horizontal, _vertical
        lda #(_horizontal)
        sta ppu_scroll
        lda #(_vertical)
        sta ppu_scroll
endm

macro sprite_dma
        lda #>(sprite_page)
        sta oam_dma
endm

macro write_ppu_data _byte
        lda #(_byte)
        sta ppu_data
endm

; --- iNES header ---------------------------------------------------------------------------------

        base $0000
        db "NES", $1a   ; id
        db 2            ; 32 KiB PRG ROM
        db 4            ; 32 KiB CHR ROM
        db $30, $00     ; mapper 3 (CNROM), horizontal name table mirroring
        pad $0010, $00  ; padding

; --- PRG ROM -------------------------------------------------------------------------------------

        base $8000

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
        jsr sub1

        lda #%00011110
        sta ppu_mask
        lda #%10000000
        sta ppu_ctrl

-       jmp -

; -------------------------------------------------------------------------------------------------

        ; Args: A = pointer low, X = pointer high
        ; Reads indirect_data1 via ptr4
        ; Called by: sub13
        ; Only called once (at frame 3 with indirect_data1 as argument).

sub1    sta ptr4+0
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
        rept 4
            iny
        endr
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
clear_loop
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

; -------------------------------------------------------------------------------------------------

        ; Called by: sub5

sub2    cmp #0
        bpl +    ; always taken
        lda #0   ; unaccessed ($8157)
+       cmp #63
        bcc +    ; always taken
        lda #63  ; unaccessed ($815d)
+       lsr
        lsr
        ora $0394,x
        ldy apu_reg_offsets,x
        sta pulse1_ctrl,y
        rts

; -------------------------------------------------------------------------------------------------

        ; Called by: sub6, sub7, sub8, sub9

sub3    cpx #3
        beq sub3a
        cpx #2
        beq sub3b
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
+       rts

sub3a   and #%00001111
        ora $034c,x
        sta noise_period
        lda #$08
        sta noise_length
        rts

sub3b   ldy apu_reg_offsets,x
        sta pulse1_timer,y
        lda $cb
        ora #%00001000
        sta pulse1_length,y
        rts

; -------------------------------------------------------------------------------------------------

        ; Called by: sub11, sub12

sub4    lda $d3
        beq sub4d
        inc $d2
        cmp $d2
        beq +
        bpl sub4b
+       lda #$00
        sta $d2
        lda $d4
        cmp #$40
        bcc sub4a
        lda #$00
        sta $d4
        ldx $d5
        inx
        cpx $d6
        bcc +
        ldx $d7
+       stx $d5
sub4a   jmp sub10b

sub4b   lda #$06
        ldx #3

sub4_loop1
        lda $e5,x
        bmi sub4c
        sec
        sbc #1
        bpl +
        lda table03,x
        and $ef
        sta $ef
        lda #$00
+       sta $e5,x
sub4c   cpx #$02
        bne +
        lda #$ff
        sta triangle_ctrl
+       dex
        bpl sub4_loop1

        lda apu_ctrl
        and #%00010000
        bne +
        lda $ef
        and #%00001111
        sta $ef
+       lda $ef
        sta apu_ctrl
        ldx #3

sub4_loop2
        cpx #2
        beq +
        jsr sub5
+       jsr sub7
        dex
        bpl sub4_loop2

sub4d   inc $039c
        inc $039d
        inc $039e
        inc $039f
        rts

; -------------------------------------------------------------------------------------------------

        ; Called by: sub4

sub5    lda $035a,x
        cmp #$0a
        bne sub5b
        lda $035f,x
        beq +
        sta $0324,x
+       lda $0324,x
        tay
        and #%11110000
        beq +           ; always taken

        ; unaccessed ($823b)
        rept 4
            lsr
        endr
        adc $0300,x
        sta $0300,x
        jmp sub5a

+       tya
        and #%00001111
        eor #%11111111
        sec
        adc $0300,x
        sta $0300,x
sub5a   jmp +

sub5b   lda $0320,x
        beq +
        clc
        adc $0300,x
        sta $0300,x
+       ldy $035a,x
        cpy #$07
        bne sub5c   ; always taken

        ; unaccessed ($826a)
        lda $035f,x
        beq +
        sta $0340,x
+       lda $0340,x
        bne unaccessed1

sub5c   lda $0344,x
        bne unaccessed1  ; never taken
        lda $0300,x
        bpl +
        lda #$00
+       cmp #$3f
        bcc +        ; always taken
        lda #$3f     ; unaccessed ($8287)
+       sta $0300,x
        jmp sub2

; -------------------------------------------------------------------------------------------------
; Unaccessed block ($828f)

unaccessed1
        pha
        and #%00001111
        ldy $033c,x
        jsr sub6
        bmi unaccessed2
        clc
        adc $0300,x
        jsr sub2
        pla
        rept 4
            lsr
        endr
        clc
        adc $033c,x
        cmp #$20
        bpl unaccessed3
        sta $033c,x
        rts

unaccessed2
        clc
        adc $0300,x
        jsr sub2
        pla
        rept 4
            lsr
        endr
        clc
        adc $033c,x
        cmp #$20
        bpl unaccessed3
        sta $033c,x
        rts

unaccessed3
        sec
        sbc #$40
        sta $033c,x
        rts

; -------------------------------------------------------------------------------------------------

        ; Called by: sub5, sub7

sub6    bmi sub6a
        dey
        bmi sub6b
        ora or_masks,y
        tay
        lda table05,y
        clc
        rts

sub6a   pha
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

sub6b   lda #$00
        clc
        rts

sub6c   pha
        and #%00001111
        ldy $0330,x
        jsr sub6
        ror
        bmi sub6d
        clc
        adc $dc,x
        tay
        lda $0308,x
        adc #0
        sta $cb
        tya
        jsr sub3
        pla
        rept 4
            lsr
        endr
        clc
        adc $0330,x
        cmp #$20
        bpl sub6e
        sta $0330,x
        rts

sub6d   clc
        adc $dc,x
        tay
        lda $0308,x
        adc #$ff
        sta $cb
        tya
        jsr sub3
        pla
        rept 4
            lsr
        endr
        clc
        adc $0330,x
        cmp #$20
        bpl sub6e
        sta $0330,x
        rts

sub6e   sec
        sbc #$40
        sta $0330,x
        rts

; -------------------------------------------------------------------------------------------------

        ; Called by: sub4

sub7    jsr sub8
        jmp sub7c

sub7a   ldy $035a,x
        cpy #$04
        bne sub7b
        lda $035f,x
        beq +
        sta $0334,x
+       lda $0334,x
        bne sub6c

sub7b   lda $0338,x
        bne sub6c
        lda $0308,x
        sta $cb
        lda $dc,x
        jmp sub3

sub7c   lda $035a,x
        cmp #$03
        beq sub7f
        cmp #$01
        beq sub7d
        cmp #$02
        beq sub7e
        lda $03a0,x
        bne +        ; never taken
        jmp sub7a

        ; unaccessed block ($838e)
+       lda $03a0,x
        bmi +
        clc
        adc $dc,x
        sta $dc,x
        lda $0308,x
        adc #0
        sta $0308,x
        jmp sub7a
+       clc
        adc $dc,x
        sta $dc,x
        lda $0308,x
        adc #$ff
        sta $0308,x
        jmp sub7a

sub7d   lda $035f,x
        beq +
        sta $0318,x
+       lda $dc,x
        sec
        sbc $0318,x
        sta $dc,x
        lda $0308,x
        sbc #0
        sta $0308,x
        jmp sub7a

sub7e   lda $035f,x
        beq +
        sta $0318,x
+       lda $dc,x
        clc
        adc $0318,x
        sta $dc,x
        lda $0308,x
        adc #0
        sta $0308,x
        jmp sub7a

sub7f   lda $0350,x
        beq +
        sta $0314,x
+       lda $035f,x
        beq +
        sta $0318,x
+       ldy $0314,x

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
        bpl sub7g  ; always taken
        jmp sub7a  ; unaccessed ($8414)
+       lda $dc,x
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
        bpl sub7h  ; always taken
        jmp sub7a  ; unaccessed ($8433)

sub7g   lda $dc,x
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
        bmi sub7h
        jmp sub7a

sub7h   lda ptr2+0
        sta $dc,x
        lda ptr2+1
        sta $0308,x
        jmp sub7a

; -------------------------------------------------------------------------------------------------

        ; Called by: sub7, sub9

sub8    lda $035a,x
        cmp #$08
        beq +        ; never taken
        lda $0328,x
        bne sub8a
        lda $03a4,x
        bne sub8a
        lda $032c,x
        bne sub8a
        rts

+       jmp unaccessed6  ; unaccessed ($8478)

sub8a   lda $039c,x
        ldy $03a8,x
        bne +
        and #%00000011
+       cmp #0
        beq +
        cmp #1
        beq sub8b
        cmp #2
        beq sub8c
        cmp #3
        beq sub8d  ; always taken
        rts          ; unaccessed ($8495)

+       ldy $e9,x
        lda word_hi-1,y
        sta $0308,x
        sta $cb
        lda word_lo-1,y
        sta $dc,x
        jmp sub3

sub8b   lda $e9,x
        clc
        adc $0328,x
        tay
        lda word_hi-1,y
        sta $0308,x
        sta $cb
        lda word_lo-1,y
        sta $dc,x
        jmp sub3

sub8c   lda $e9,x
        clc
        adc $03a4,x
        tay
        lda word_hi-1,y
        sta $0308,x
        sta $cb
        lda word_lo-1,y
        sta $dc,x
        jmp sub3

sub8d   lda $e9,x
        clc
        adc $032c,x
        tay
        lda word_hi-1,y
        sta $0308,x
        sta $cb
        lda word_lo-1,y
        sta $dc,x
        jmp sub3

sub8e   sta $0300,x
        jmp sub9a

sub8f   sta $d3
        jmp sub9a

; -------------------------------------------------------------------------------------------------
; Unaccessed block ($84f8)

unaccessed4
        sec
        sbc #1
        sta $d4
        lda $d5
        clc
        adc #1
        cmp $d6
        bcc +
        lda $d7
+       sta $d5
        jmp sub9a

; -------------------------------------------------------------------------------------------------

        ; Called by: sub8, sub11

sub9    ldy $035a,x
        beq sub9a

        lda $035f,x
        cpy #$0c
        beq sub8e
        cpy #$0f
        beq sub8f
        cpy #$0d
        beq unaccessed4  ; never taken

sub9a   lda $035f,x
        cpy #$08
        beq unaccessed5  ; never taken

        lda $0328,x
        bne sub9b

        lda $03a4,x
        bne sub9b

        lda $032c,x
        bne sub9b

        lda $0350,x
        beq +

        lda $035a,x
        cmp #3
        beq +

        lda $0308,x
        sta $cb
        lda $dc,x
        jmp sub3

+       rts

        ; unaccessed block ($854e)
unaccessed5
        jsr unaccessed6
        lda $0308,x
        sta $cb
        lda $dc,x
        jmp sub3

sub9b   jmp sub8a

; -------------------------------------------------------------------------------------------------
; Unaccessed block ($855e)

unaccessed6
        lda $035f,x
        beq +
        sta $0398,x
+       sec
        lda $d2
        beq unaccessed8

unaccessed7
        cmp #1
        beq unaccessed9
        cmp #2
        beq unaccessed10
        sbc #3
        bne unaccessed7

unaccessed8
        ldy $e9,x
        lda word_lo-1,y
        sta $dc,x
        lda word_hi-1,y
        sta $0308,x
        rts

unaccessed9
        lda $0398,x
        rept 4
            lsr
        endr
        clc
        adc $e9,x
        tay
        lda word_lo-1,y
        sta $dc,x
        lda word_hi-1,y
        sta $0308,x
        rts

unaccessed10
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

; -------------------------------------------------------------------------------------------------

        ; Reads indirect_data1 via ptr6
        ; Called by: sub4, sub11

sub10a  lda $031c,x
        sta $e5,x
        lda $03b4,x
        sta $0300,x
        lda table02,x
        ora $ef
        sta $ef
        jmp sub10f

sub10b  jsr sub11

        ldx #3
sub10c  lda $0355,x
        bne +
        jmp sub10f
+       cmp $0310,x
        beq sub10a
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
        jmp sub10d

        ; unaccessed block ($862d)
unaccessed11
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

sub10d  iny
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
        rept 4
            lsr
        endr
        sta $03a4,x
        lda $cb
        and #%00001111
        sta $032c,x
        jmp sub10e

        ; unaccessed block ($8681)
unaccessed12
        eor #%11111111
        clc
        adc #1
        sta $0328,x
        tya
        rept 4
            lsr
        endr
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

sub10e  lda table02,x
        ora $ef
        sta $ef

sub10f  ldy $0350,x
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

sub10_07
        sta $0308,x
        lda table02,x
        ora $ef
        sta $ef

sub10_08
        dex
        bmi +
        jmp sub10c
+       jmp sub11_16

sub10_09
        lda table03,x
        and $ef
        sta $ef
        jmp sub10_08

sub10_10
        dey
        sty $dc,x
        lda #$00
        jmp sub10_07

sub10_11
        lda #$00
        sta $038f,x
        jmp sub11_03

; -------------------------------------------------------------------------------------------------

        ; Reads indirect_data1 via ptr2, ptr3, ptr5
        ; Called by: sub10

sub11   lda #$40
        sta $cd

        ; clear $0350-$0363
        lda #$00
        ldx #4
sub11_loop1
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
+       jmp sub11_04
sub11_01
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
sub11_loop2
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
+       lda $cb       ; unaccessed ($8798)
sub11_02
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

sub11_03
        dex
        bpl sub11_loop2

sub11_04
        ldx #4

sub11_05
        dec $038f,x
        bmi +
        dec $038a,x
        bpl +
        jmp sub11_06
+       jmp sub11_15
sub11_06
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
        rept 4
            lsr
        endr
+       ldy $0378,x
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

+       lda (ptr2),y
        and #%11110000
        sta $cc
        iny
        lda (ptr2),y
        and #%00001111
        ora $cc
        jmp sub11_08

sub11_07
        bvs +
        lda (ptr2),y
        and #%00001111
        sbc #$ff
        bit $cd
        jmp sub11_08
+       lda (ptr2),y
        rept 4
            lsr
        endr
        clc
        adc #1
        iny
        clv

sub11_08
        sta $0350,x

sub11_09
        lsr $cb
        bcc sub11_10
        bvs +
        lda (ptr2),y
        and #%00001111
        adc #0
        sta $0355,x
        bit $cd
        jmp sub11_10
+       lda (ptr2),y
        rept 4
            lsr
        endr
        iny
        clc
        adc #1
        sta $0355,x
        clv
sub11_10
        lsr $cb
        bcc sub11_12
        bvs +
        lda (ptr2),y
        and #%00001111
        bit $cd
        jmp sub11_11

+       lda (ptr2),y
        rept 4
            lsr
        endr
        iny
        clv
sub11_11
        sta $035a,x

sub11_12
        lsr $cb
        bcc sub11_14
        bvs +
        lda (ptr2),y
        iny
        jmp sub11_13
+       lda (ptr2),y
        and #%11110000
        sta $cc
        iny
        lda (ptr2),y
        and #%00001111
        ora $cc
sub11_13
        sta $035f,x
sub11_14
        sty $e0,x
        lda #$40
        bvs +
        lda #$00
+       sta $0378,x

sub11_15
        dex
        bmi +
        jmp sub11_05
+       rts

sub11_16
        ldx #3
sub11_loop3
        ldy $e5,x
        bmi sub11_17
        dey
        bpl +
        lda table03,x
        and $ef
        sta $ef
        lda #$00
        ldy #$00
+       sty $e5,x
sub11_17
        dex
        bpl sub11_loop3

        lda apu_ctrl
        and #%00010000
        bne +
        lda $ef
        and #%00001111
        sta $ef
+       lda $ef
        sta apu_ctrl

        ldx #3
sub11_loop4
        jsr sub9
        cpx #$02
        beq sub11_18
        lda $0355,x
        bne +
        lda $035a,x
        cmp #$0c
        beq +
        jmp sub11_18
+       lda $0300,x
        lsr
        lsr
        ora $0394,x
        ldy apu_reg_offsets,x
        sta pulse1_ctrl,y
sub11_18
        dex
        bpl sub11_loop4

        inc $039c
        inc $039d
        inc $039e
        inc $039f
        inc $d4
        rts

; -------------------------------------------------------------------------------------------------
; Unaccessed block ($8906)

        ldx #0
        ldy #16
unaccessed13
        dex
        bne unaccessed13
        dey
        bne unaccessed13

        dec $ff
        bpl +
        lda #$05
        sta $ff
        lda #$1e
+       jsr sub4
        lda #$06
        rti
        rti

; -------------------------------------------------------------------------------------------------

        ; Called by: nmisub6, nmisub10, nmisub14, NMI

sub12   bit $ff
        bmi sub12_skip  ; always taken

        ; unaccessed block ($8925)
        dec $ff
        bpl sub12_skip
        lda #$05
        sta $ff
        jmp unaccessed14

sub12_skip
        jmp sub4

unaccessed14
        rts  ; unaccessed ($8933)

; -------------------------------------------------------------------------------------------------

        ; Called by: init

sub13   ldy #$ff
        dex
        beq +
        ldy #$05  ; unaccessed ($8939)
+       sty $ff
        asl
        tay

        lda pointer_hi,y
        tax
        lda pointer_lo,y
        jsr sub1  ; A = pointer low, X = pointer high
        rts

; --- Lots of data --------------------------------------------------------------------------------

        ; unaccessed ($894a)
        db $c0, $00
        db 255, 254, 253, 252, 251, 250, 249, 248
        db 247, 246, 245, 244, 243, 242, 241

apu_reg_offsets:
        ; $895b
        ; read by: sub02, sub03, sub11
        db 0, 4, 8, 12

table02:
        ; $895f
        ; read by: sub10
        db 1, 2, 4, 8

table03:
        ; $8963
        ; read by: sub04, sub10, sub11
        db 254, 253, 251, 247

or_masks:
        ; $8967 (some bytes unaccessed)
        ; read by: sub06
        db $00, $10, $20, $30, $40, $50, $60, $70
        db $80, $90, $a0, $b0, $c0, $d0, $e0, $f0
        db $e0, $d0, $c0, $b0, $a0, $90, $80, $70
        db $60, $50, $40, $30, $20, $10, $00

table05:
        ; $8986 (most bytes unaccessed)
        ; read by: sub06
        ; Math stuff? (On each line, the numbers increase linearly.)
        db  0,  0,  0,  1,  1,  1,  2,  2,  3,  3,  3,  4,  4,  4,  5,  5  ; value ~= index/4
        db  0,  0,  1,  2,  3,  3,  4,  5,  6,  6,  7,  8,  9,  9, 10, 11
        db  0,  1,  2,  3,  4,  5,  6,  8,  9, 10, 11, 12, 13, 15, 16, 17  ; value ~= index
        db  0,  1,  3,  4,  6,  7,  9, 10, 12, 13, 15, 16, 18, 19, 21, 22
        db  0,  1,  3,  5,  7,  9, 11, 13, 15, 16, 18, 20, 22, 24, 26, 28  ; value ~= index*2
        db  0,  2,  4,  6,  8, 11, 13, 15, 17, 19, 22, 24, 26, 28, 30, 33
        db  0,  2,  5,  7, 10, 12, 15, 17, 20, 22, 25, 27, 30, 32, 35, 37
        db  0,  2,  5,  8, 11, 14, 16, 19, 22, 25, 28, 30, 33, 36, 39, 42
        db  0,  3,  6,  9, 12, 15, 18, 21, 24, 27, 30, 33, 36, 40, 43, 46  ; value ~= index*3
        db  0,  3,  6,  9, 13, 16, 19, 23, 26, 29, 33, 36, 39, 43, 46, 49
        db  0,  3,  7, 10, 14, 17, 21, 24, 28, 31, 35, 38, 42, 45, 49, 52
        db  0,  3,  7, 11, 14, 18, 22, 25, 29, 33, 36, 40, 44, 47, 51, 55
        db  0,  3,  7, 11, 15, 19, 22, 26, 30, 34, 38, 41, 45, 49, 53, 57
        db  0,  3,  7, 11, 15, 19, 23, 27, 31, 35, 39, 42, 46, 50, 54, 58
        db  0,  3,  7, 11, 15, 19, 23, 27, 31, 35, 39, 43, 47, 51, 55, 59
        db  0,  3,  7, 11, 15, 19, 23, 27, 31, 35, 39, 43, 47, 51, 55, 59  ; value ~= index*4

        ; 96 integers. First all low bytes, then all high bytes.
        ; Disregarding the first nine values, the numbers decrease exponentially.
        ; (Each value equals approximately 0.944 times the previous value.)
        ; Some bytes unaccessed.
        ; read by: sub07, sub08, sub10
word_lo:
        ; $8a86
        dl 1884, 1948, 2024, 1852, 1948, 1839, 1906, 2028
        dl 2047, 2034, 1920, 1812, 1710, 1614, 1524, 1438
        dl 1358, 1281, 1209, 1142, 1077, 1017,  960,  906
        dl  855,  807,  762,  719,  679,  641,  605,  571
        dl  539,  509,  480,  453,  428,  404,  381,  360
        dl  339,  320,  302,  285,  269,  254,  240,  227
        dl  214,  202,  190,  180,  170,  160,  151,  143
        dl  135,  127,  120,  113,  107,  101,   95,   90
        dl   85,   80,   76,   71,   67,   64,   60,   57
        dl   53,   50,   48,   45,   42,   40,   38,   36
        dl   34,   32,   30,   28,   27,   25,   24,   22
        dl   21,   20,   19,   18,   17,   16,   15,   14
word_hi:
        ; $8ae6
        dh 1884, 1948, 2024, 1852, 1948, 1839, 1906, 2028
        dh 2047, 2034, 1920, 1812, 1710, 1614, 1524, 1438
        dh 1358, 1281, 1209, 1142, 1077, 1017,  960,  906
        dh  855,  807,  762,  719,  679,  641,  605,  571
        dh  539,  509,  480,  453,  428,  404,  381,  360
        dh  339,  320,  302,  285,  269,  254,  240,  227
        dh  214,  202,  190,  180,  170,  160,  151,  143
        dh  135,  127,  120,  113,  107,  101,   95,   90
        dh   85,   80,   76,   71,   67,   64,   60,   57
        dh   53,   50,   48,   45,   42,   40,   38,   36
        dh   34,   32,   30,   28,   27,   25,   24,   22
        dh   21,   20,   19,   18,   17,   16,   15,   14

        ; $8b46 (read by: sub13)
pointer_lo:
        db <indirect_data1
pointer_hi:
        db >indirect_data1

        ; unaccessed ($8b48)
        db $8d, $a0, $8d, $a0, $8d, $a0, $8d, $a0
        db $8d, $a0, $8d, $a0, $8d, $a0, $8d, $a0
        db $8d, $a0, $8d, $a0, $8d, $a0, $8d, $a0
        db $8d, $a0, $8d, $a0, $8d, $a0, $8d, $a0

indirect_data1:
        ; $8b68-$8dbf (600 bytes)
        ; read (via pointer_lo and pointer_hi) by: sub01, sub10, sub11
        ; Some bytes unaccessed.
        db $20, $10, $00, $05, $3a, $10, $00, $3c
        db $15, $1c, $0c, $0a, $01, $f9, $12, $00
        db $90, $00, $00, $00, $02, $5f, $01, $00
        db $50, $00, $00, $00, $09, $f5, $00, $00
        db $90, $00, $00, $00, $06, $fe, $00, $00
        db $10, $00, $00, $00, $20, $f8, $00, $14
        db $10, $00, $00, $00, $08, $b4, $0a, $37
        db $10, $00, $00, $00, $08, $b4, $00, $47
        db $10, $00, $00, $00, $3f, $91, $00, $47
        db $d0, $00, $f4, $00, $31, $bb, $00, $00
        db $d0, $00, $00, $00, $32, $f0, $00, $00
        db $90, $00, $c1, $00, $19, $92, $00, $00
        db $50, $00, $a1, $00, $0c, $60, $00, $00
        db $50, $00, $91, $00, $0e, $84, $00, $00
        db $10, $00, $00, $00, $09, $b4, $00, $73
        db $10, $00, $00, $00, $3c, $81, $00, $73
        db $10, $00, $00, $00, $00, $00, $00, $00
        db $10, $00, $00, $00, $00, $00, $00, $00
        db $88, $82, $02, $00, $09, $01, $01, $00
        db $48, $00, $00, $00, $69, $00, $00, $00
        db $48, $00, $00, $00, $c9, $00, $00, $00
        db $88, $00, $00, $00, $a9, $00, $00, $00
        db $88, $00, $00, $00, $09, $02, $00, $00
        db $aa, $01, $00, $00, $ca, $01, $00, $00
        db $aa, $01, $00, $00, $eb, $01, $00, $00
        db $00, $00, $00, $00, $00, $00, $00, $00
        db $00, $00, $00, $00, $27, $04, $00, $00
        db $02, $08, $00, $00, $03, $08, $00, $00
        db $04, $08, $00, $00, $26, $08, $00, $00
        db $05, $08, $00, $00, $03, $08, $00, $00
        db $04, $08, $00, $00, $ee, $14, $00, $00
        db $4c, $8e, $00, $00, $6d, $8e, $00, $00
        db $4f, $8e, $00, $00, $b0, $12, $02, $00
        db $48, $00, $00, $00, $69, $00, $00, $00
        db $48, $00, $00, $00, $c9, $00, $00, $00
        db $88, $00, $00, $00, $a9, $00, $00, $00
        db $88, $00, $00, $00, $09, $02, $00, $00
        db $aa, $99, $01, $00, $ca, $9d, $01, $00
        db $aa, $9d, $00, $00, $eb, $21, $02, $00
        db $4f, $26, $00, $00, $70, $26, $00, $00
        db $4f, $26, $00, $00, $70, $26, $00, $00
        db $51, $26, $00, $00, $72, $26, $00, $00
        db $51, $26, $00, $00, $32, $2b, $00, $00
        db $ca, $02, $00, $00, $ea, $02, $00, $00
        db $ca, $02, $00, $00, $0a, $03, $00, $00
        db $53, $9b, $00, $00, $53, $9f, $03, $00
        db $53, $9f, $03, $00, $53, $1f, $03, $00
        db $74, $af, $04, $00, $08, $00, $00, $00
        db $10, $02, $58, $02, $ab, $02, $14, $03
        db $73, $03, $d5, $03, $29, $04, $81, $04
        db $c9, $04, $20, $05, $70, $05, $bd, $05
        db $16, $06, $5d, $06, $aa, $06, $fa, $06
        db $3f, $07, $89, $07, $f1, $07, $4a, $08
        db $85, $08, $bd, $08, $fd, $08, $3a, $09
        db $78, $09, $b3, $09, $09, $0a, $54, $0a
        db $91, $0a, $da, $0a, $00, $00, $00, $00
        db $00, $00, $00, $00, $05, $0b, $4c, $0b
        db $96, $0b, $e8, $0b, $00, $00, $3b, $0c
        db $88, $0c, $d9, $0c, $ea, $0c, $2f, $0d
        db $8c, $0d, $ca, $0d, $f7, $0d, $46, $0e
        db $61, $0e, $96, $0e, $ee, $0e, $4b, $0f
        db $c6, $0f, $35, $10, $a8, $10, $1d, $11
        db $75, $11, $c7, $11, $1c, $12, $99, $12
        db $13, $13, $54, $13, $aa, $13, $eb, $13
        db $21, $14, $4e, $14, $97, $14, $c6, $14
        db $e9, $14, $00, $00, $00, $00, $00, $00
        db $00, $3e, $03, $00, $01, $13, $00, $13
        db $03, $01, $03, $00, $03, $01, $00, $03
        db $03, $01, $03, $00, $01, $13, $00, $03
        db $03, $01, $03, $01, $03, $0d, $00, $03
        db $03, $01, $16, $61, $11, $16, $61, $16
        db $61, $11, $19, $61, $11, $11, $1d, $61
        db $1d, $11, $1c, $61, $1b, $61, $11, $1b
        db $61, $1f, $21, $12, $61, $1b, $61, $11
        db $1b, $61, $0f, $12, $1b, $14, $61, $01

        ; unaccessed ($8dc0)
        db $00, $3e, $03, $00, $01, $13, $00, $13
        db $03, $01, $03, $00, $03, $01, $00, $03
        db $03, $01, $03, $00, $01, $13, $00, $03
        db $03, $01, $03, $01, $f3, $37, $77, $37
        db $07, $03, $16, $61, $11, $16, $61, $16
        db $61, $11, $19, $61, $11, $11, $1d, $61
        db $1d, $11, $1c, $61, $1b, $61, $11, $1b
        db $61, $1b, $11, $19, $61, $1b, $61, $11
        db $7b, $22, $37, $af, $27, $37, $1b, $27
        db $72, $23, $77, $13, $7b, $23, $72, $27
        db $37, $2e, $07

        ; $8e13
        ; $3f followed by $00...$1f occurs often from now on
        ; (PPU palette addresses?)
        db $00, $3f, $33, $4f, $13, $13, $03, $00
        db $03, $0f, $3f, $03, $f3, $00, $ff, $13
        db $03, $13, $03, $0f, $03, $0f, $03, $13
        db $13, $03, $00, $00, $4c, $44, $01, $1f
        db $0f, $13, $25, $29, $97, $29, $49, $a3
        db $24, $9c, $61, $2e, $69, $31, $91, $2e
        db $39, $91, $1c, $20, $9e, $1c, $60, $91
        db $2e, $39, $94, $35, $39, $20, $34, $c9
        db $10, $35, $c9, $10, $35, $69, $31, $93
        db $31, $69, $31, $93, $31, $c9, $10, $33
        db $29, $9e, $1c, $30, $91, $30, $69, $21
        db $9c, $61, $2e, $29, $04, $22, $62, $21
        db $9e, $2c, $60, $21, $99, $3c, $20, $9c
        db $61, $00

        db $3f, $03
        db $1f, $13, $00, $03
        db $31, $0f, $01, $03
        db $13, $03, $13, $03

        db $13, $03, $01, $f3, $44, $44, $44, $00
        db $03, $13, $03, $13, $03, $13, $13, $03
        db $13, $03, $13, $2e, $29, $99, $1c, $60
        db $21, $9e, $61, $31, $69, $21, $9c, $2e
        db $39, $30, $61, $30, $29, $9c, $61, $30
        db $29, $9c, $61, $30, $29, $9e, $61, $2c
        db $69, $21, $9c, $2e, $39, $03, $33, $33
        db $33, $2c, $29, $9b, $61, $2c, $29, $9b
        db $61, $27, $29, $92, $61, $27, $69, $21
        db $99, $2b, $69, $21, $9e, $2c, $69, $01
        db $00, $3f, $33, $33, $10, $13, $00, $03
        db $01, $03, $01, $13, $03, $01, $f3, $00
        db $03, $03, $cf, $44, $44, $44, $ff, $00
        db $0f, $0f, $cf, $44, $44, $34, $4f, $10
        db $03, $13, $2e, $39, $91, $2e, $29, $99
        db $61, $2e, $69, $31, $93, $61, $35, $69
        db $31, $98, $61, $3a, $69, $31, $9c, $3d
        db $39, $10, $3c, $39, $9a, $14, $c8, $20
        db $31, $10, $11, $11, $31, $ac, $1c, $30
        db $ad, $1c, $30, $ac, $1c, $30, $aa, $1c
        db $20, $80, $2c, $10, $20, $11, $11, $21
        db $95, $27, $39, $20, $63, $21, $99, $2c
        db $69, $01, $00

        db $3f, $03
        db $13, $03, $01, $03
        db $00, $03, $01, $00
        db $03, $01, $f3, $14
        db $13, $03, $13, $03
        db $01, $03, $01, $03

        db $13, $13, $f3, $44, $44, $44, $44
        db $00, $00, $03, $13, $2e, $29, $99, $61
        db $2e, $69, $31, $91, $2e, $69, $31, $95
        db $61, $33, $39, $95, $23, $30, $61, $35
        db $69, $31, $93, $31, $69, $31, $93, $61
        db $33, $69, $31, $91, $30, $69, $21, $9c
        db $61, $2c, $29, $9e, $03, $34, $33, $33
        db $33, $23, $99, $2c, $69, $01, $00, $3f
        db $03, $01, $13, $00, $f3, $1c, $03, $01
        db $03, $01, $03, $01, $03, $13, $03, $01
        db $f3, $44, $44, $44, $44, $44, $44, $00
        db $03, $13, $03, $13, $33, $13, $03, $13
        db $2e, $69, $21, $9e, $61, $2e, $39, $91
        db $13, $35, $15, $61, $2e, $69, $31, $90
        db $61, $30, $69, $31, $90, $2e, $69, $21
        db $9c, $61, $2c, $29, $9e, $03, $33, $33
        db $33, $33, $33, $33, $13, $ab, $22, $6a
        db $21, $a7, $1b, $6a, $21, $a7, $2e, $3a
        db $a3, $61, $29, $29, $9c, $61, $00, $3f
        db $03, $00, $01, $13, $00, $03, $03, $01
        db $03, $00, $03, $01, $00, $03, $03, $13
        db $03, $00, $01, $03, $01, $03, $03, $01
        db $03, $00, $00, $13, $00, $13, $03, $13
        db $16, $61, $11, $16, $61, $16, $11, $19
        db $61, $11, $11, $1d, $61, $1d, $11, $1c
        db $61, $61, $11, $1b, $61, $1b, $61, $11
        db $1f, $22, $61, $21, $17, $27, $69, $21
        db $97, $61, $1d, $29, $90, $61, $00, $3e
        db $03, $10, $03, $13, $00, $13, $13, $03
        db $01, $13, $03, $01, $03, $13, $03, $01
        db $03, $10, $03, $13, $00, $13, $03, $13
        db $00, $13, $03, $0d, $f3, $04, $03, $01
        db $0f, $61, $11, $1b, $19, $61, $11, $14
        db $61, $16, $61, $11, $19, $61, $16, $61
        db $01, $1f, $61, $0d, $01, $1f, $61, $12
        db $61, $01, $1f, $61, $1b, $11, $19, $61
        db $14, $61, $11, $16, $19, $61, $11, $19
        db $61, $14, $61, $f1, $02, $15, $11, $16
        db $43, $30, $19, $61, $01, $00, $3f, $03
        db $10, $03, $13, $00, $13, $03, $13, $00
        db $13, $03, $01, $03, $03, $03, $01, $03
        db $00, $03, $01, $03, $00, $03, $01, $03
        db $00, $03, $0d, $03, $13, $13, $13, $0f
        db $61, $11, $1b, $19, $61, $11, $14, $61
        db $16, $11, $19, $61, $16, $61, $01, $1f
        db $61, $0d, $01, $1f, $12, $61, $11, $17
        db $23, $61, $11, $16, $22, $61, $11, $12
        db $1e, $61, $f1, $02, $0d, $01, $1d, $61
        db $19, $61, $11, $19, $61, $00, $3e, $03
        db $00, $03, $13, $03, $13, $03, $13, $03
        db $03, $03, $03, $03, $00, $03, $13, $03
        db $00, $03, $03, $03, $00, $03, $01, $03
        db $00, $03, $0d, $03, $00, $03, $01, $17
        db $21, $5f, $17, $61, $21, $13, $1e, $61
        db $21, $5f, $23, $61, $11, $16, $2e, $24
        db $12, $61, $24, $4e, $1e, $21, $4e, $61
        db $0f, $11, $1b, $27, $14, $11, $1d, $61
        db $11, $12, $1e, $61, $f1, $02, $16, $11
        db $16, $61, $00, $3f, $03, $00, $03, $13
        db $03, $13, $03, $13, $03, $03, $03, $01
        db $03, $01, $03, $13, $cf, $44, $44, $44
        db $44, $01, $03, $00, $03, $00, $0f, $1f
        db $0f, $13, $03, $13, $17, $21, $5f, $17
        db $61, $21, $13, $1e, $61, $11, $17, $23
        db $61, $11, $16, $2e, $24, $12, $61, $2e
        db $64, $11, $1e, $2e, $64, $11, $8b, $2c
        db $a0, $02, $aa, $aa, $aa, $aa, $61, $16
        db $01, $1f, $0f, $c1, $30, $1b, $f1, $02
        db $61, $1a, $c1, $20, $19, $61, $11, $18
        db $17, $61, $01, $00, $3f, $03, $00, $01
        db $13, $00, $13, $03, $01, $03, $01, $03
        db $01, $00, $00, $00, $13, $00, $13, $03
        db $01, $03, $00, $03, $00, $03, $00, $03
        db $01, $03, $00, $03, $1f, $19, $61, $11
        db $19, $61, $16, $61, $11, $19, $61, $1b
        db $61, $11, $1b, $61, $27, $61, $01, $1f
        db $61, $16, $61, $11, $15, $14, $11, $12
        db $1e, $61, $11, $14, $20, $11, $18, $2c
        db $60, $01, $00, $3e, $03, $00, $03, $13
        db $00, $13, $03, $01, $03, $01, $03, $01
        db $00, $00, $00, $13, $00, $13, $03, $01
        db $03, $00, $03, $01, $03, $33, $03, $13
        db $f3, $04, $03, $01, $19, $61, $11, $19
        db $61, $11, $16, $61, $19, $61, $11, $1b
        db $61, $1b, $61, $21, $17, $61, $0f, $61
        db $11, $12, $61, $14, $11, $16, $61, $1b
        db $21, $17, $61, $01, $1f, $16, $61, $11
        db $1d, $1e, $31, $30, $13, $1b, $61, $00
        db $3f, $03, $0f, $03, $1f, $f3, $04, $03
        db $1f, $03, $00, $03, $00, $00, $01, $03
        db $01, $f3, $04, $00, $00, $00, $00, $00
        db $00, $00, $00, $00, $00, $4f, $57, $57
        db $57, $2e, $29, $99, $1c, $25, $9e, $22
        db $c9, $15, $61, $2e, $39, $91, $33, $30
        db $2e, $39, $91, $1c, $60, $31, $90, $2c
        db $69, $21, $99, $61, $2c, $29, $9e, $33
        db $30, $0d, $18, $50, $11, $89, $61, $11
        db $20, $18, $61, $21, $85, $61, $11, $00
        db $3e, $03, $00, $01, $13, $00, $13, $03
        db $01, $03, $01, $03, $01, $00, $00, $00
        db $13, $00, $13, $03, $01, $03, $00, $03
        db $01, $03, $00, $03, $01, $03, $00, $03
        db $01, $16, $61, $11, $16, $61, $16, $61
        db $11, $19, $61, $1b, $61, $11, $1b, $61
        db $27, $61, $01, $1f, $61, $16, $61, $11
        db $15, $14, $61, $11, $12, $1e, $61, $11
        db $14, $20, $61, $01, $00, $3f, $03, $00
        db $01, $13, $00, $13, $03, $01, $03, $00
        db $03, $01, $00, $00, $00, $13, $00, $13
        db $03, $01, $03, $00, $03, $01, $03, $10
        db $03, $13, $cf, $44, $44, $44, $19, $61
        db $11, $19, $61, $16, $61, $11, $19, $61
        db $1b, $11, $1b, $61, $27, $61, $11, $1b
        db $61, $16, $61, $11, $15, $14, $61, $01
        db $1d, $61, $1b, $21, $17, $61, $0f, $c8
        db $20, $0a, $a3, $aa, $aa, $0a, $00, $3e
        db $03, $03, $03, $0f, $03, $00, $03, $0f
        db $33, $00, $03, $03, $00, $0f, $03, $0f
        db $ff, $ff, $13, $13, $03, $0f, $03, $0f
        db $03, $0f, $03, $0f, $03, $00, $0f, $0f
        db $22, $2b, $b5, $27, $2b, $b2, $1c, $25
        db $b7, $27, $2b, $b2, $1c, $25, $b9, $2a
        db $2b, $b9, $27, $2b, $b9, $1c, $25, $b2
        db $27, $cb, $15, $2c, $c9, $10, $2e, $c9
        db $15, $2c, $c9, $20, $2e, $c9, $25, $2c
        db $69, $21, $9e, $61, $2c, $29, $9e, $1c
        db $35, $91, $2c, $c9, $15, $30, $39, $91
        db $1c, $25, $9c, $30, $c9, $15, $2e, $29
        db $9c, $1c, $25, $9e, $1c, $00, $00, $3e
        db $03, $03, $03, $0f, $03, $00, $03, $00
        db $33, $00, $03, $03, $00, $00, $03, $00
        db $00, $13, $13, $13, $13, $13, $13, $13
        db $f3, $13, $03, $01, $03, $1f, $03, $0f
        db $22, $2b, $b5, $27, $2b, $b2, $1c, $20
        db $ba, $2c, $2b, $bc, $2e, $2b, $bc, $2a
        db $2b, $b7, $25, $69, $31, $91, $61, $2e
        db $69, $21, $9c, $61, $2e, $69, $21, $99
        db $61, $2a, $69, $21, $95, $2e, $c9, $15
        db $25, $69, $21, $92, $61, $2a, $29, $92
        db $1c, $65, $21, $97, $2a, $c9, $15, $00
        db $38, $03, $00, $00, $0f, $00, $00, $0f
        db $00, $03, $00, $00, $0f, $00, $00, $03
        db $01, $03, $00, $00, $0f, $00, $00, $0f
        db $00, $00, $0f, $00, $00, $0f, $17, $11
        db $17, $2c, $10, $17, $1c, $15, $16, $16
        db $c1, $20, $12, $61, $01, $1f, $0f, $c1
        db $25, $0f, $c1, $20, $0f, $c1, $15, $0f
        db $c1, $10, $00, $1e, $f3, $ff, $ff, $00
        db $00, $ff, $03, $03, $03, $03, $03, $03
        db $03, $03, $03, $03, $36, $39, $91, $d3
        db $20, $9a, $d3, $30, $96, $1c, $30, $91
        db $1c, $20, $9a, $1c, $20, $15, $1c, $20
        db $15, $2c, $20, $15, $2f, $21, $1f, $2f
        db $21, $1e, $2c, $21, $1a, $25, $21, $12
        db $1e, $01, $00, $3f, $01, $00, $03, $00
        db $00, $0f, $03, $00, $0f, $00, $03, $00
        db $00, $00, $03, $01, $03, $01, $00, $03
        db $00, $00, $03, $00, $00, $13, $03, $00
        db $00, $13, $03, $13, $61, $22, $24, $4e
        db $2c, $20, $42, $29, $cc, $20, $29, $2c
        db $c9, $61, $33, $65, $21, $57, $27, $25
        db $57, $61, $27, $25, $57, $61, $27, $25
        db $57, $61, $00, $3e, $00, $00, $03, $00
        db $00, $03, $03, $00, $03, $00, $03, $00
        db $00, $00, $03, $0c, $03, $00, $00, $00
        db $00, $00, $0f, $07, $00, $07, $07, $00
        db $07, $07, $00, $07, $22, $24, $4e, $22
        db $24, $c9, $29, $2c, $c9, $0f, $22, $67
        db $25, $22, $70, $25, $22, $25, $22, $20
        db $22, $20, $22, $1b, $22, $1b, $22, $00
        db $3c, $03, $00, $00, $03, $00, $00, $00
        db $00, $00, $13, $03, $01, $03, $00, $00
        db $00, $03, $00, $01, $13, $00, $00, $00
        db $13, $03, $01, $13, $1f, $03, $00, $03
        db $27, $24, $47, $31, $65, $31, $51, $61
        db $33, $2c, $c7, $61, $27, $64, $31, $51
        db $61, $31, $65, $31, $51, $61, $33, $c4
        db $10, $61, $33, $3c, $c3, $00, $3f, $03
        db $00, $00, $03, $00, $00, $00, $00, $00
        db $13, $03, $01, $03, $00, $00, $00, $03
        db $00, $03, $00, $03, $00, $03, $00, $03
        db $00, $03, $00, $03, $00, $13, $13, $27
        db $24, $47, $31, $65, $31, $51, $61, $33
        db $2c, $5f, $3b, $25, $c7, $33, $2c, $5a
        db $36, $25, $55, $31, $65, $31, $51, $61
        db $00, $3d, $03, $03, $03, $01, $03, $01
        db $03, $0f, $f3, $14, $03, $0f, $03, $10
        db $03, $03, $0f, $03, $03, $00, $0f, $00
        db $0f, $0f, $00, $0f, $00, $13, $03, $00
        db $13, $25, $29, $47, $27, $69, $21, $9a
        db $61, $27, $29, $9a, $1c, $20, $9d, $2e
        db $39, $30, $63, $31, $91, $2e, $c9, $10
        db $36, $69, $31, $95, $31, $39, $95, $1c
        db $20, $9e, $27, $34, $96, $1c, $30, $95
        db $1c, $30, $91, $1c, $20, $9e, $1c, $20
        db $47, $61, $27, $24, $47, $61, $00, $3f
        db $03, $00, $f3, $04, $03, $01, $03, $01
        db $03, $00, $03, $01, $03, $01, $03, $03
        db $0f, $03, $00, $00, $00, $00, $00, $00
        db $00, $03, $01, $13, $33, $03, $33, $13
        db $27, $24, $95, $27, $39, $30, $23, $9a
        db $61, $2c, $69, $21, $9e, $31, $69, $31
        db $96, $61, $35, $39, $91, $35, $c9, $10
        db $33, $29, $5a, $61, $2a, $65, $21, $a5
        db $2c, $3a, $a1, $25, $2a, $ac, $31, $6a
        db $01, $00, $3e, $03, $00, $00, $03, $00
        db $00, $00, $00, $00, $00, $00, $13, $03
        db $00, $03, $00, $03, $01, $00, $13, $03
        db $00, $00, $13, $03, $00, $13, $00, $33
        db $00, $03, $01, $27, $24, $47, $27, $6c
        db $31, $51, $25, $25, $5f, $61, $2f, $65
        db $21, $c7, $27, $6c, $21, $5a, $2a, $65
        db $21, $45, $20, $29, $92, $61, $00, $3e
        db $00, $00, $03, $01, $00, $00, $0f, $01
        db $03, $01, $03, $01, $00, $03, $01, $1f
        db $03, $00, $00, $00, $00, $00, $00, $ff
        db $0f, $07, $00, $07, $07, $00, $07, $07
        db $2e, $6c, $21, $c2, $2c, $60, $21, $c9
        db $61, $29, $6c, $21, $c9, $61, $29, $cc
        db $10, $61, $27, $26, $27, $1c, $20, $27
        db $2c, $20, $27, $72, $20, $27, $22, $22
        db $22, $22, $12, $2d, $12, $2d, $02, $00
        db $3f, $00, $00, $00, $00, $00, $00, $00
        db $00, $00, $00, $00, $00, $00, $00, $00
        db $00, $00, $00, $00, $00, $00, $00, $00
        db $00, $00, $00, $00, $00, $00, $1f, $13
        db $13, $25, $c5, $20, $61, $31, $65, $31
        db $51, $61, $00, $3f, $03, $1f, $03, $01
        db $03, $03, $03, $01, $03, $00, $4c, $03
        db $00, $01, $03, $01, $03, $00, $03, $00
        db $00, $00, $03, $00, $00, $13, $03, $00
        db $00, $13, $03, $13, $33, $29, $9f, $1c
        db $60, $31, $96, $61, $36, $39, $95, $33
        db $69, $31, $95, $11, $10, $31, $69, $21
        db $9e, $61, $33, $29, $c7, $27, $2c, $47
        db $61, $27, $24, $47, $61, $33, $24, $47
        db $61, $00, $3f, $03, $1f, $03, $01, $03
        db $03, $03, $01, $03, $00, $4c, $03, $00
        db $1f, $03, $0f, $03, $00, $00, $00, $00
        db $00, $00, $00, $00, $13, $03, $13, $00
        db $03, $01, $13, $33, $29, $9f, $1c, $60
        db $31, $96, $61, $36, $39, $95, $33, $69
        db $31, $95, $11, $10, $3a, $39, $95, $1c
        db $60, $31, $95, $3a, $c9, $10, $33, $29
        db $47, $61, $27, $24, $47, $61, $33, $64
        db $31, $43, $61, $00, $3f, $03, $1f, $03
        db $1f, $03, $00, $03, $00, $f3, $04, $00
        db $03, $00, $00, $03, $00, $03, $00, $1f
        db $1f, $00, $13, $03, $00, $f3, $44, $00
        db $00, $4f, $44, $44, $44, $33, $29, $9f
        db $1c, $60, $31, $96, $33, $c9, $10, $61
        db $36, $39, $93, $36, $39, $98, $13, $30
        db $35, $39, $91, $33, $29, $c7, $2c, $60
        db $21, $c7, $3c, $60, $21, $c7, $61, $2e
        db $29, $95, $27, $39, $10, $33, $0d, $18
        db $58, $11, $11, $11, $01, $00, $3e, $00
        db $f3, $14, $03, $01, $00, $03, $01, $03
        db $00, $03, $01, $03, $00, $13, $03, $01
        db $0f, $f3, $44, $00, $00, $00, $00, $00
        db $ff, $0f, $07, $07, $07, $07, $07, $25
        db $29, $97, $13, $30, $61, $2a, $69, $21
        db $9c, $61, $2e, $39, $91, $61, $36, $39
        db $95, $61, $31, $69, $31, $95, $1c, $30
        db $91, $33, $39, $10, $33, $25, $c2, $10
        db $25, $c2, $20, $25, $22, $70, $25, $22
        db $22, $22, $22, $22, $1d, $22, $1d, $22
        db $00, $3e, $03, $00, $00, $13, $00, $00
        db $13, $00, $03, $00, $03, $01, $00, $0f
        db $00, $13, $00, $00, $1f, $00, $00, $00
        db $1f, $00, $03, $0c, $0f, $0d, $0f, $0c
        db $0f, $0d, $25, $25, $55, $61, $25, $65
        db $21, $c7, $27, $6c, $21, $c7, $1c, $20
        db $c7, $61, $27, $cc, $20, $61, $27, $cc
        db $10, $61, $2a, $f5, $02, $2a, $f5, $04
        db $61, $0f, $22, $5c, $0f, $f4, $02, $2c
        db $f5, $04, $61, $0f, $02, $00, $3e, $03
        db $00, $00, $13, $00, $00, $13, $00, $03
        db $00, $03, $01, $00, $0f, $00, $13, $00
        db $00, $1f, $00, $00, $00, $0f, $01, $03
        db $0d, $1f, $1f, $0f, $0d, $0f, $0d, $25
        db $25, $55, $61, $25, $65, $21, $c7, $27
        db $6c, $21, $c7, $1c, $25, $c7, $61, $27
        db $cc, $20, $61, $27, $cc, $10, $61, $25
        db $65, $f1, $02, $25, $f5, $04, $61, $25
        db $f5, $02, $61, $27, $f4, $04, $61, $0f
        db $22, $c7, $0f, $64, $f1, $02, $00, $0c
        db $03, $00, $00, $0f, $00, $00, $0f, $27
        db $24, $47, $2c, $25, $47, $2c, $00, $00
        db $3f, $03, $00, $00, $13, $00, $00, $13
        db $00, $03, $00, $03, $01, $00, $00, $00
        db $03, $01, $00, $0f, $00, $00, $00, $0f
        db $00, $03, $01, $03, $01, $03, $1f, $0f
        db $13, $25, $25, $55, $61, $25, $65, $21
        db $c7, $27, $6c, $21, $c7, $61, $27, $cc
        db $20, $27, $cc, $10, $25, $65, $21, $55
        db $61, $27, $2c, $27, $2c, $60, $21, $27
        db $3c, $20, $27, $61, $00, $3e, $13, $f3
        db $04, $03, $01, $00, $03, $01, $03, $10
        db $03, $1f, $03, $10, $13, $03, $30, $1f
        db $03, $01, $03, $00, $03, $0f, $03, $0f
        db $03, $0f, $03, $0f, $03, $0f, $2a, $69
        db $21, $95, $27, $39, $20, $23, $9a, $61
        db $2c, $69, $21, $9e, $61, $2c, $29, $9e
        db $1c, $60, $21, $9a, $61, $29, $69, $21
        db $9a, $2a, $29, $97, $1c, $60, $21, $99
        db $61, $25, $29, $92, $25, $c9, $10, $27
        db $29, $92, $1c, $20, $99, $27, $c9, $10
        db $2a, $29, $99, $1c, $20, $9e, $2a, $c9
        db $10, $00, $3f, $00, $00, $03, $13, $00
        db $00, $03, $01, $f3, $00, $03, $01, $03
        db $10, $13, $03, $00, $00, $00, $00, $01
        db $00, $00, $00, $00, $00, $00, $00, $00
        db $13, $03, $13, $2f, $29, $9a, $61, $27
        db $69, $21, $9f, $31, $39, $30, $2f, $69
        db $21, $9e, $61, $2f, $69, $21, $9e, $61
        db $25, $69, $21, $97, $29, $69, $01, $00
        db $20, $00, $00, $03, $13, $00, $00, $03
        db $01, $f3, $00, $03, $01, $03, $1f, $03
        db $1f, $03, $2f, $29, $9a, $61, $27, $69
        db $21, $9f, $31, $39, $30, $2f, $69, $21
        db $9e, $2f, $c9, $10, $61, $2a, $29, $9e
        db $1c, $60, $21, $97, $00, $3f, $03, $00
        db $00, $13, $00, $00, $03, $01, $03, $00
        db $03, $00, $00, $0f, $00, $13, $00, $1f
        db $0f, $01, $00, $00, $0f, $00, $03, $00
        db $03, $00, $0f, $1f, $ff, $33, $25, $25
        db $55, $61, $25, $65, $21, $c7, $27, $2c
        db $c7, $1c, $15, $cb, $61, $27, $cc, $15
        db $61, $27, $cc, $25, $61, $27, $cc, $15
        db $25, $25, $c7, $19, $c9, $15, $1b, $c9
        db $20, $61, $1e, $c9, $25, $20, $c9, $30
        db $22, $29, $95, $00, $20, $03, $00, $00
        db $00, $00, $00, $00, $00, $03, $00, $00
        db $03, $00, $00, $03, $00, $03, $23, $26
        db $42, $22, $24, $42, $27, $0d, $00, $1e
        db $33, $f3, $ff, $00, $00, $ff, $03, $03
        db $03, $03, $03, $03, $03, $03, $03, $03
        db $25, $2b, $b2, $1e, $2b, $b5, $1c, $20
        db $b2, $1c, $10, $be, $1c, $20, $b0, $1c
        db $20, $b0, $2c, $20, $b0, $29, $2b, $b9
        db $29, $2b, $b9, $25, $2b, $b5, $22, $1b
        db $be, $19, $0b, $00, $3e, $0f, $0c, $0c
        db $0c, $07, $0c, $0c, $0c, $07, $0c, $0c
        db $0c, $07, $0c, $0c, $0c, $07, $0c, $0c
        db $0c, $07, $0c, $0c, $0c, $07, $0c, $0c
        db $07, $07, $0c, $07, $0c, $31, $22, $80
        db $0f, $f2, $04, $0f, $32, $21, $f2, $02
        db $0f, $f4, $02, $31, $22, $0f, $f2, $04
        db $0f, $32, $21, $f2, $02, $0f, $f4, $02
        db $31, $22, $0f, $f2, $04, $0f, $32, $21
        db $f2, $02, $0f, $f4, $02, $31, $22, $0f
        db $f2, $04, $31, $22, $31, $22, $0f, $32
        db $21, $f2, $02, $00, $3f, $0f, $0c, $0c
        db $0c, $07, $0c, $0c, $0c, $07, $0c, $0c
        db $0c, $07, $0c, $0c, $07, $07, $0c, $0c
        db $0c, $0c, $0c, $0c, $0c, $cf, $4c, $4c
        db $4c, $4c, $4c, $4c, $4c, $31, $22, $80
        db $0f, $f2, $04, $0f, $32, $21, $f2, $02
        db $0f, $f4, $02, $31, $22, $0f, $f2, $04
        db $0f, $32, $21, $f2, $02, $0f, $34, $21
        db $32, $21, $f2, $02, $0f, $f4, $02, $0f
        db $f4, $02, $0f, $f4, $02, $0d, $f8, $04
        db $61, $f0, $02, $f1, $04, $f1, $02, $f1
        db $04, $f1, $02, $f1, $04, $f1, $02, $01
        db $00, $3e, $3f, $0c, $0d, $1f, $07, $1f
        db $0f, $0d, $37, $0c, $0f, $0d, $07, $0f
        db $0f, $0d, $37, $0c, $0d, $1f, $07, $0f
        db $0f, $0d, $37, $0d, $0f, $0d, $07, $0f
        db $0f, $0d, $31, $22, $80, $22, $f9, $02
        db $61, $0f, $24, $92, $0f, $62, $31, $21
        db $22, $92, $0f, $62, $21, $95, $0f, $64
        db $f1, $02, $31, $22, $1d, $f9, $02, $29
        db $f9, $04, $61, $0f, $32, $21, $22, $99
        db $0f, $22, $98, $0f, $64, $f1, $02, $31
        db $22, $27, $f9, $02, $61, $0f, $24, $97
        db $0f, $62, $31, $21, $22, $9b, $0f, $22
        db $9e, $0f, $64, $f1, $02, $31, $22, $27
        db $69, $f1, $02, $27, $f9, $04, $61, $0f
        db $32, $21, $22, $97, $0f, $22, $90, $0f
        db $64, $f1, $02, $00, $3e, $3f, $0c, $1c
        db $1f, $0f, $1f, $1f, $0c, $0f, $cd, $0f
        db $0d, $0c, $0c, $1f, $0c, $0c, $0c, $1f
        db $0c, $0c, $0c, $1f, $0c, $0f, $0f, $00
        db $07, $07, $00, $07, $07, $31, $22, $80
        db $19, $f8, $02, $0f, $64, $11, $89, $0f
        db $62, $21, $85, $0f, $14, $89, $0f, $62
        db $11, $89, $0f, $64, $f1, $02, $0f, $f8
        db $04, $61, $0f, $c2, $20, $1b, $f8, $04
        db $61, $0f, $f2, $04, $0f, $12, $8b, $0f
        db $64, $f1, $02, $0f, $f4, $02, $22, $f8
        db $04, $61, $0f, $f2, $04, $0f, $22, $80
        db $0f, $64, $f1, $02, $1e, $f8, $04, $31
        db $22, $70, $2e, $22, $2e, $22, $2c, $22
        db $2c, $22, $00, $3e, $0f, $0c, $1c, $1f
        db $0f, $1f, $1f, $0c, $0f, $0d, $0f, $0d
        db $0c, $0c, $1f, $0c, $0c, $0c, $1f, $0c
        db $0c, $0c, $0f, $0d, $0f, $1c, $0f, $1f
        db $0f, $0d, $0c, $0c, $19, $f8, $04, $0f
        db $f2, $04, $61, $19, $f8, $02, $61, $25
        db $f8, $04, $19, $f8, $02, $61, $19, $f8
        db $04, $61, $0f, $12, $8b, $0f, $64, $f1
        db $02, $1b, $f8, $04, $61, $0f, $f2, $04
        db $0f, $12, $8b, $0f, $64, $f1, $02, $0f
        db $f4, $02, $22, $f8, $04, $61, $0f, $f2
        db $04, $0f, $22, $80, $0f, $64, $f1, $02
        db $19, $f8, $04, $0f, $62, $11, $8b, $0f
        db $24, $87, $0f, $62, $11, $8b, $0f, $64
        db $f1, $02, $0f, $f4, $02, $00, $3e, $3f
        db $0c, $1c, $1f, $07, $1f, $0f, $0d, $37
        db $0c, $0f, $0d, $07, $1f, $0f, $0d, $37
        db $0c, $0d, $0f, $0d, $1f, $0f, $0d, $0f
        db $0d, $0c, $0c, $0c, $0c, $0c, $0c, $31
        db $22, $80, $22, $f9, $02, $0f, $64, $21
        db $92, $0f, $62, $31, $21, $22, $92, $0f
        db $62, $21, $95, $0f, $64, $f1, $02, $31
        db $22, $1d, $f9, $02, $29, $f9, $04, $61
        db $0f, $32, $21, $22, $99, $0f, $62, $21
        db $98, $0f, $64, $f1, $02, $31, $22, $27
        db $f9, $02, $61, $0f, $24, $97, $0f, $62
        db $f1, $04, $2b, $f9, $02, $61, $2e, $f9
        db $04, $61, $0f, $32, $93, $0f, $64, $f1
        db $02, $0f, $f4, $02, $0f, $f4, $02, $0f
        db $f4, $02, $00, $3e, $4f, $4c, $4c, $4c
        db $4c, $4c, $4c, $1c, $0c, $0c, $0c, $0c
        db $0c, $0c, $0c, $0c, $0c, $0c, $0c, $0c
        db $0c, $0c, $0c, $0c, $0c, $0c, $0c, $0c
        db $0c, $0c, $0c, $0c, $31, $28, $30, $f2
        db $02, $f2, $04, $f2, $02, $f2, $04, $f2
        db $02, $f2, $04, $f2, $02, $61, $0f, $f4
        db $02, $0f, $f4, $02, $0f, $f4, $02, $0f
        db $f4, $02, $0f, $f4, $02, $0f, $f4, $02
        db $0f, $f4, $02, $0f, $f4, $02, $0f, $f4
        db $02, $0f, $f4, $02, $0f, $f4, $02, $0f
        db $f4, $02, $00, $3e, $0c, $0c, $0c, $0c
        db $0c, $0c, $0c, $0c, $0c, $0c, $0c, $0c
        db $0c, $0c, $0c, $0c, $0c, $0c, $0c, $0c
        db $0c, $0c, $0c, $0c, $0c, $0c, $0c, $0c
        db $0c, $0c, $0c, $0c, $0f, $f4, $02, $0f
        db $f4, $02, $0f, $f4, $02, $0f, $f4, $02
        db $0f, $f4, $02, $0f, $f4, $02, $0f, $f4
        db $02, $0f, $f4, $02, $0f, $f4, $02, $0f
        db $f4, $02, $0f, $f4, $02, $0f, $f4, $02
        db $0f, $f4, $02, $0f, $f4, $02, $0f, $f4
        db $02, $0f, $f4, $02, $00, $3e, $0c, $0c
        db $0c, $0c, $0c, $0c, $0c, $0c, $0c, $0c
        db $0c, $0c, $0c, $0c, $0c, $0c, $0c, $0c
        db $0c, $0c, $0c, $0c, $0c, $0c, $0c, $0c
        db $0c, $0c, $0f, $0c, $07, $07, $0f, $f4
        db $02, $0f, $f4, $02, $0f, $f4, $02, $0f
        db $f4, $02, $0f, $f4, $02, $0f, $f4, $02
        db $0f, $f4, $02, $0f, $f4, $02, $0f, $f4
        db $02, $0f, $f4, $02, $0f, $f4, $02, $0f
        db $f4, $02, $0f, $f4, $02, $0f, $f4, $02
        db $25, $22, $80, $0f, $22, $25, $22, $25
        db $02, $00, $3e, $3f, $1c, $1f, $0f, $07
        db $1f, $0f, $1f, $07, $1f, $0f, $1c, $37
        db $0c, $0f, $0d, $07, $1f, $0f, $0d, $07
        db $0c, $0f, $0d, $37, $0c, $0f, $0d, $37
        db $0c, $0f, $0d, $31, $22, $80, $19, $f8
        db $02, $61, $25, $f8, $04, $61, $25, $f8
        db $02, $31, $22, $19, $f8, $02, $61, $25
        db $f8, $04, $19, $f8, $02, $61, $31, $22
        db $22, $f8, $02, $61, $27, $f8, $04, $0f
        db $62, $31, $21, $22, $8a, $0f, $22, $87
        db $0f, $64, $f1, $02, $31, $22, $27, $f8
        db $02, $61, $2a, $f8, $04, $61, $0f, $32
        db $21, $f2, $02, $2c, $f8, $04, $61, $0f
        db $32, $21, $22, $8d, $0f, $22, $8c, $0f
        db $64, $f1, $02, $31, $22, $2a, $f8, $02
        db $27, $f8, $04, $61, $0f, $02, $00, $3f
        db $3f, $1c, $1f, $0f, $07, $1f, $0f, $0d
        db $37, $1c, $0f, $0d, $07, $0c, $0c, $1f
        db $07, $1f, $0f, $0d, $03, $0d, $0f, $0d
        db $03, $1c, $1f, $0f, $4f, $4c, $4c, $4c
        db $31, $22, $80, $19, $f8, $02, $61, $25
        db $f8, $04, $61, $19, $f8, $02, $31, $22
        db $22, $f8, $02, $61, $25, $f8, $04, $61
        db $0f, $32, $21, $22, $87, $0f, $62, $11
        db $8b, $0f, $64, $f1, $02, $31, $22, $0f
        db $f2, $04, $33, $f8, $02, $61, $31, $22
        db $1b, $f8, $02, $61, $22, $f8, $04, $61
        db $0f, $22, $8d, $61, $0f, $22, $8c, $0f
        db $64, $f1, $02, $25, $f8, $02, $61, $1b
        db $f8, $04, $61, $27, $f8, $02, $19, $18
        db $30, $f1, $02, $f1, $04, $f1, $02, $01
        db $00, $24, $0c, $00, $00, $0c, $00, $00
        db $0f, $0d, $1f, $3f, $0f, $1f, $0f, $1f

        ; $9e8b
        ; no more $3f + $00...$1f
        db $1f, $0f, $1c, $0c, $0c, $0f, $f4, $03
        db $19, $f8, $05, $61, $0f, $24, $85, $0f
        db $63, $11, $89, $0f, $64, $81, $1d, $f8
        db $05, $29, $f8, $04, $61, $1e, $f8, $05
        db $2a, $f8, $04, $61, $25, $f8, $05, $61
        db $1e, $f8, $04, $0f, $65, $f1, $04, $0f
        db $05, $00, $3e, $0f, $00, $03, $0f, $0f
        db $00, $03, $0f, $0c, $0f, $03, $0f, $0f
        db $00, $03, $0f, $0c, $00, $03, $0f, $0f
        db $00, $03, $0f, $0c, $0f, $03, $0f, $0f
        db $00, $0f, $0f, $0e, $0f, $64, $60, $c0
        db $20, $3b, $0f, $64, $60, $c0, $20, $0f
        db $64, $c0, $20, $06, $06, $2c, $b0, $f3
        db $04, $06, $3b, $2c, $f0, $04, $06, $06
        db $2c, $b0, $f3, $04, $06, $06, $2c, $f0
        db $04, $06, $2c, $60, $60, $c0, $20, $3b
        db $0f, $64, $f0, $04, $3b, $2c, $00, $00
        db $3e, $0f, $00, $00, $00, $0f, $00, $03
        db $03, $00, $00, $03, $00, $03, $00, $03
        db $0f, $00, $00, $03, $0f, $03, $00, $03
        db $0f, $00, $0f, $03, $0f, $03, $00, $03
        db $0f, $63, $0f, $b4, $22, $70, $0a, $0a
        db $0e, $2b, $06, $2b, $2c, $60, $60, $c0
        db $20, $2b, $06, $06, $2c, $60, $c0, $20
        db $06, $06, $2c, $b0, $62, $b0, $c2, $20
        db $00, $3e, $0c, $00, $00, $00, $0c, $00
        db $00, $00, $0c, $00, $00, $00, $0c, $00
        db $00, $00, $0c, $00, $00, $00, $0c, $00
        db $00, $00, $0c, $00, $00, $0c, $0c, $0f
        db $0f, $03, $0f, $f4, $04, $0f, $f4, $04
        db $0f, $f4, $04, $0f, $f4, $02, $0f, $b4
        db $c3, $20, $3b, $0f, $b4, $03, $00, $3c
        db $0f, $00, $00, $00, $03, $00, $00, $00
        db $00, $00, $00, $00, $03, $00, $00, $00
        db $00, $00, $00, $00, $03, $00, $00, $00
        db $00, $00, $00, $0f, $03, $00, $0f, $63
        db $0f, $b4, $b2, $b2, $b2, $c2, $20, $2b
        db $2b, $2c, $00, $00, $3e, $03, $00, $00
        db $03, $03, $00, $03, $0f, $00, $0f, $03
        db $0f, $03, $00, $03, $0f, $00, $00, $03
        db $0f, $03, $00, $03, $00, $00, $0f, $03
        db $0f, $0f, $0f, $0f, $0f, $63, $0a, $2b
        db $0a, $0a, $2c, $a0, $c0, $20, $0a, $0a
        db $2c, $b0, $a2, $b0, $c2, $20, $0a, $0a
        db $2c, $b0, $a2, $a0, $c0, $20, $0a, $0a
        db $2c, $b0, $f2, $04, $3b, $2c, $b0, $f3
        db $04, $3b, $0f, $02, $00, $3c, $0c, $00
        db $00, $00, $0c, $00, $00, $00, $0c, $00
        db $00, $00, $0c, $00, $00, $00, $0c, $00
        db $00, $00, $0c, $00, $00, $00, $0c, $00
        db $00, $00, $0c, $00, $0c, $0f, $f4, $04
        db $0f, $f4, $04, $0f, $f4, $04, $0f, $f4
        db $04, $0f, $04, $00, $20, $00, $00, $03
        db $03, $03, $00, $03, $0f, $00, $0f, $03
        db $0f, $03, $00, $03, $00, $03, $0e, $0e
        db $2b, $0e, $0e, $2c, $e0, $c0, $20, $0e
        db $0e, $2c, $b0, $e2, $30, $0d, $00, $3c
        db $00, $00, $03, $03, $03, $00, $03, $0f
        db $00, $0f, $03, $0f, $03, $00, $0f, $00
        db $00, $00, $03, $00, $03, $00, $03, $00
        db $00, $0f, $03, $0f, $03, $00, $03, $0e
        db $0e, $2b, $0e, $0e, $2c, $e0, $c0, $20
        db $0e, $0e, $2c, $b0, $e2, $c0, $20, $0e
        db $2b, $0e, $0e, $2c, $e0, $e0, $c0, $20
        db $2b, $0e

        ; $a08d

; -------------------------------------------------------------------------------------------------

        ; Note: the program continues at the next 16-KiB boundary for some reason although
        ; technically there is only one 32-KiB PRG ROM bank.
        pad $c000, $00

init
        ; Called by: reset vector

        sei
        cld
        jsr wait_vbl

        ; clear RAM
        ldx #0
        txa
-       sta $00,x
        sta $0100,x
        sta $0200,x
        sta $0300,x
        sta $0400,x
        sta sprite_page,x
        sta $0600,x
        sta $0700,x
        inx
        bne -

        jsr hide_sprites
        jsr init_palette_copy
        jsr update_palette

        ; update fourth sprite subpalette
        set_ppu_addr vram_palette + 7 * 4
        write_ppu_data $0f  ; black
        write_ppu_data $1c  ; medium-dark cyan
        write_ppu_data $2b  ; medium-light green
        write_ppu_data $39  ; light yellow
        reset_ppu_addr

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

        reset_ppu_addr

        lda #$00
        ldx #$01
        jsr sub13
        jsr wait_vbl

        lda #%10000000
        sta ppu_ctrl
        lda #%00011110
        sta ppu_mask

-       lda demo_part
        cmp #9  ; last part?
        bne +
        lda #$0d
        sta dmc_addr
        lda #$fa
        sta dmc_length
+       jmp -

; --- Lots of data --------------------------------------------------------------------------------

; TODO: data on unaccessed parts is out of date

pointers:  ; $c0a8
        dw indirect1
        dw indirect2
        dw indirect3
        dw indirect4
        dw indirect5
        dw indirect6
        dw indirect7
        dw indirect8  ; unaccessed ($c0b6)

indirect1:
        db $6c, $6c, $6c, $47, $52, $45, $45, $54
        db $49, $4e, $47, $53, $5f, $6c, $6c, $6c
indirect2:
        db $6c, $6c, $57, $45, $6c, $43, $4f, $4d
        db $45, $6c, $46, $52, $4f, $4d, $6c, $6c
indirect3:
        db $6c, $41, $4e, $6c, $5b, $5e, $42, $49
        db $54, $6c, $57, $4f, $52, $4c, $44, $6c
indirect4:
        db $6c, $6c, $42, $52, $49, $4e, $47, $49
        db $4e, $47, $6c, $54, $48, $45, $6c, $6c
indirect5:
        db $6c, $6c, $6c, $6c, $47, $49, $46, $54
        db $6c, $4f, $46, $6c, $6c, $6c, $6c, $6c
indirect6:
        db $6c, $47, $41, $4c, $41, $43, $54, $49
        db $43, $6c, $44, $49, $53, $43, $4f, $6c
indirect7:
        db $47, $45, $54, $6c, $55, $50, $6c, $41
        db $4e, $44, $6c, $44, $41, $4e, $43, $45
indirect8:
        ; unaccessed ($c128)
        db $4d, $55, $53, $48, $52, $4f, $4f, $4d
        db $6c, $4d, $41, $4e, $49, $41, $43, $53

table10:
        ; 22 bytes
        db $3a, $3b, $3c, $3d, $3e, $3b, $3f, $ff
        db $f1, $f2, $f3, $f4, $f5, $ff, $f6, $f7
        db $f5, $3e, $f8, $f9, $f7, $f3

table11:
        ; 256 bytes
        db $5b, $5b, $5b, $5b, $5b, $5b, $5b, $5b
        db $5b, $5b, $5b, $5b, $5b, $5b, $49, $54
        db $5b, $49, $53, $5b, $46, $52, $49, $44
        db $41, $59, $5b, $41, $54, $5b, $4e, $49
        db $4e, $45, $5b, $50, $4d, $5b, $41, $4e
        db $44, $5b, $57, $45, $5b, $53, $54, $49
        db $4c, $4c, $5b, $41, $52, $45, $5b, $54
        db $52, $59, $49, $4e, $47, $5b, $54, $4f
        db $5b, $53, $59, $4e, $43, $5b, $54, $48
        db $49, $53, $5b, $4d, $4f, $54, $48, $45
        db $52, $46, $55, $43, $4b, $45, $52, $5b
        db $5b, $5b, $47, $52, $45, $45, $54, $49
        db $4e, $47, $53, $5b, $54, $4f, $5b, $4e
        db $49, $4e, $54, $45, $4e, $44, $4f, $5b
        db $54, $45, $43, $48, $4e, $4f, $4c, $4f
        db $47, $49, $45, $53, $5b, $46, $4f, $52
        db $5b, $54, $48, $45, $5b, $4c, $4f, $56
        db $45, $4c, $59, $5b, $48, $41, $52, $44
        db $57, $41, $52, $45, $5b, $5b, $5b, $48
        db $45, $43, $4b, $5b, $5b, $5b, $57, $45
        db $5b, $53, $48, $4f, $55, $4c, $44, $5b
        db $42, $45, $5b, $41, $4c, $52, $45, $41
        db $44, $59, $5b, $44, $52, $55, $4e, $4b
        db $5b, $5b, $5b, $4a, $55, $53, $54, $5b
        db $4c, $49, $4b, $45, $5b, $4f, $55, $52
        db $5b, $4d, $55, $53, $49, $43, $49, $41
        db $4e, $5b, $5b, $5b, $54, $45, $52, $56
        db $45, $49, $53, $45, $54, $5b, $50, $49
        db $53, $53, $41, $50, $4f, $53, $53, $45
        db $4c, $4c, $45, $5b, $65, $61, $62, $63
        db $64, $66, $5b, $5b, $5b, $5b, $5b, $5b
        db $5b, $5b, $5b, $5b, $5b, $5b, $5b, $5b

        ; unaccessed ($c24e)
        db $5b, $5b, $5b, $5b, $0d, $0a

palette_table:
        ; 32 bytes
        db $2f, $10, $00, $20  ; light gray, gray, white
        db $0f, $05, $26, $30  ; dark red, light red, white
        db $0f, $20, $10, $00  ; white, light gray, gray
        db $0f, $13, $23, $33  ; dark purple, purple, light purple
        db $0f, $1c, $2b, $39  ; dark teal, green, light yellow
        db $0f, $06, $15, $36  ; dark red, red, light red
        db $0f, $04, $24, $30  ; dark magenta, magenta, white
        db $0f, $02, $22, $30  ; dark blue, light blue, white

        ; unaccessed ($c274)
        db $a9, $aa, $aa, $aa, $aa, $aa, $aa, $aa
        db $aa, $aa, $aa, $42

        ; Read as PCM audio data.
        ; (Perhaps a glitch caused by an inaccurate emulator? Looks more like
        ; Attribute Table data because of the $55 and $aa bytes.)
        ; $c280, 4001 bytes.
        db $f8, $ff, $95, $03
        db $00, $c0, $ff, $f9, $eb, $17, $9f, $00
        db $e8, $13, $00, $68, $63, $2b, $45, $fe
        db $ff, $7f, $bb, $d3, $08, $00, $e8, $35
        db $45, $04, $36, $a4, $88, $f1, $6e, $9b
        db $5c, $df, $5f, $57, $eb, $fd, $cd, $24
        db $2a, $13, $81, $00, $19, $8f, $04, $71
        db $52, $99, $0a, $b4, $ff, $33, $79, $bf
        db $db, $54, $66, $f7, $3f, $92, $f5, $37
        db $11, $40, $4c, $33, $00, $59, $33, $23
        db $00, $d8, $5e, $46, $b9, $76, $6b, $44
        db $f5, $ff, $b5, $da, $bb, $b3, $18, $a9
        db $ff, $ab, $28, $92, $08, $20, $60, $ff
        db $3b, $20, $14, $21, $10, $a8, $fe, $7b
        db $29, $d5, $ae, $32, $d6, $fe, $ff, $96
        db $6a, $ed, $0c, $91, $ac, $6b, $31, $24
        db $55, $25, $04, $91, $ad, $65, $58, $ad
        db $ca, $28, $c5, $be, $d7, $d4, $ba, $56
        db $a9, $24, $75, $bf, $95, $ea, $6a, $8a
        db $11, $e5, $ee, $92, $54, $55, $8a, $22
        db $b2, $b6, $53, $a9, $2c, $2b, $86, $52
        db $75, $ab, $a5, $69, $ad, $4a, $a5, $76
        db $5b, $ad, $5a, $55, $55, $ca, $d4, $b6
        db $aa, $d2, $2a, $a5, $14, $49, $db, $2a
        db $93, $a5, $52, $a5, $a4, $ea, $56, $55
        db $d5, $2a, $33, $95, $76, $db, $aa, $b4
        db $55, $a6, $94, $6a, $db, $4a, $55, $95
        db $4a, $8a, $54, $d7, $4c, $a5, $aa, $2a
        db $a5, $52, $6e, $ab, $aa, $6a, $55, $96
        db $49, $ed, $b6, $2a, $ab, $95, $2a, $a9
        db $d4, $b6, $96, $cc, $4a, $a5, $52, $94
        db $5d, $4b, $a6, $59, $a5, $2a, $c9, $da
        db $5a, $65, $d6, $aa, $4c, $29, $eb, $3a
        db $4b, $b5, $9a, $2a, $29, $d5, $b9, $4a
        db $55, $53, $a5, $22, $65, $6d, $55, $a9
        db $9a, $99, $52, $c9, $d6, $4d, $d3, $ac
        db $a6, $2a, $a5, $d6, $b5, $32, $b5, $ca
        db $94, $52, $6a, $db, $54, $aa, $66, $4a
        db $49, $a9, $5d, $53, $55, $d5, $32, $25
        db $95, $75, $ab, $aa, $6a, $95, $29, $a9
        db $da, $d6, $94, $56, $4d, $65, $94, $aa
        db $5b, $95, $aa, $6a, $4a, $29, $69, $5b
        db $2b, $53, $ab, $4a, $a5, $54, $ed, $aa
        db $aa, $6a, $a5, $2a, $a9, $6a, $5b, $95
        db $55, $55, $29, $a5, $ac, $ad, $95, $aa
        db $aa, $2a, $29, $55, $ed, $aa, $2a, $ab
        db $2a, $65, $54, $5b, $ab, $aa, $aa, $a9
        db $4a, $a9, $5a, $5b, $55, $56, $a5, $aa
        db $a4, $ac, $6d, $99, $aa, $a9, $2a, $a5
        db $54, $db, $aa, $aa, $6a, $2a, $95, $52
        db $6d, $ab, $aa, $9a, $9a, $52, $c9, $5a
        db $5b, $55, $56, $95, $4a, $29, $b5, $6d
        db $69, $9a, $aa, $4a, $49, $55, $b7, $aa
        db $aa, $aa, $4a, $a5, $54, $bb, $56, $a6
        db $55, $a5, $52, $4a, $eb, $5a, $69, $56
        db $a5, $4a, $49, $ad, $6d, $a5, $99, $95
        db $4a, $4a, $55, $b7, $aa, $6a, $66, $4a
        db $25, $55, $db, $5a, $a9, $96, $a9, $4a
        db $4a, $eb, $9a, $a5, $56, $a6, $52, $52
        db $d5, $ad, $a9, $aa, $aa, $52, $4a, $d5
        db $b6, $55, $65, $56, $aa, $94, $32, $bb
        db $56, $95, $55, $aa, $54, $4a, $6d, $5b
        db $95, $aa, $aa, $a4, $52, $b5, $6d, $55
        db $aa, $aa, $54, $52, $55, $fb, $77, $ab
        db $03, $00, $00, $fc, $ff, $ff, $0b, $7a
        db $2f, $00, $00, $00, $5b, $e5, $df, $92
        db $ec, $f7, $ef, $bd, $a2, $5a, $46, $04
        db $00, $da, $8a, $80, $aa, $d7, $3a, $84
        db $b4, $55, $ff, $ff, $ef, $eb, $56, $c5
        db $88, $28, $a9, $2d, $11, $09, $81, $42
        db $10, $a8, $bd, $ff, $4c, $92, $d6, $be
        db $5a, $75, $db, $dd, $df, $39, $aa, $aa
        db $56, $2b, $0a, $81, $54, $93, $00, $a0
        db $da, $a6, $22, $28, $b6, $bb, $92, $b4
        db $fd, $de, $75, $96, $55, $b7, $ff, $2d
        db $29, $5b, $9b, $22, $04, $51, $df, $12
        db $20, $54, $89, $10, $90, $6a, $f7, $5a
        db $95, $54, $55, $6b, $b7, $bd, $75, $ef
        db $5b, $93, $52, $db, $56, $11, $49, $b5
        db $ad, $24, $52, $a6, $49, $42, $24, $4a
        db $95, $55, $55, $55, $59, $ad, $aa, $aa
        db $da, $7e, $b7, $ca, $ba, $5b, $4b, $a9
        db $ac, $b5, $55, $52, $92, $4a, $49, $a4
        db $52, $49, $aa, $aa, $92, $52, $ab, $b5
        db $aa, $aa, $ea, $b6, $ad, $aa, $ee, $ae
        db $aa, $aa, $52, $cd, $aa, $2a, $55, $a9
        db $a4, $24, $25, $49, $55, $ab, $94, $aa
        db $aa, $32, $4d, $55, $db, $ad, $b5, $aa
        db $d5, $6a, $55, $ad, $56, $55, $ab, $52
        db $a9, $54, $aa, $2a, $49, $4a, $55, $55
        db $52, $aa, $55, $a5, $aa, $aa, $ac, $6d
        db $d5, $da, $56, $55, $b5, $aa, $aa, $da
        db $b6, $aa, $52, $95, $52, $4a, $4a, $aa
        db $ad, $4a, $52, $55, $4a, $a9, $aa, $aa
        db $d6, $5a, $55, $d5, $aa, $aa, $ad, $55
        db $55, $5b, $ab, $52, $55, $ab, $aa, $54
        db $2a, $65, $55, $49, $69, $55, $29, $55
        db $aa, $a4, $5a, $ad, $55, $55, $ad, $aa
        db $aa, $2a, $ad, $bb, $55, $55, $b5, $52
        db $95, $aa, $aa, $aa, $a9, $52, $a9, $52
        db $4a, $55, $2b, $55, $55, $55, $95, $a9
        db $6a, $ad, $aa, $6a, $55, $ab, $aa, $6a
        db $ad, $aa, $aa, $aa, $2a, $55, $a9, $56
        db $53, $a5, $2a, $55, $aa, $54, $d5, $aa
        db $aa, $aa, $2a, $55, $55, $b5, $56, $ab
        db $aa, $aa, $aa, $aa, $6a, $b5, $aa, $52
        db $55, $55, $a9, $aa, $aa, $aa, $4a, $55
        db $a9, $2a, $55, $d5, $6a, $a9, $5a, $55
        db $99, $aa, $6a, $ad, $aa, $aa, $aa, $aa
        db $aa, $aa, $56, $2b, $55, $a5, $aa, $52
        db $55, $d5, $aa, $54, $55, $a5, $aa, $54
        db $b5, $56, $55, $55, $55, $55, $55, $d5
        db $6a, $55, $9a, $95, $aa, $aa, $aa, $6a
        db $95, $aa, $aa, $54, $95, $aa, $56, $35
        db $55, $55, $95, $aa, $aa, $6a, $b5, $aa
        db $aa, $aa, $aa, $4a, $b5, $5a, $a9, $aa
        db $aa, $aa, $2a, $55, $ab, $aa, $aa, $aa
        db $54, $55, $a9, $56, $55, $55, $55, $55
        db $55, $55, $55, $ab, $aa, $aa, $aa, $aa
        db $52, $b5, $6a, $a9, $aa, $aa, $aa, $54
        db $55, $b5, $aa, $4a, $35, $55, $55, $65
        db $d5, $aa, $4a, $cd, $52, $55, $55, $d5
        db $aa, $aa, $aa, $aa, $52, $55, $55, $ab
        db $aa, $aa, $aa, $4a, $55, $55, $ad, $aa
        db $ac, $aa, $aa, $54, $35, $ad, $2c, $53
        db $1b, $e3, $4a, $a5, $07, $87, $7b, $b1
        db $e3, $8b, $80, $80, $f4, $ff, $3f, $88
        db $77, $00, $44, $61, $b5, $7f, $fd, $bf
        db $2b, $90, $0e, $00, $50, $18, $f4, $7f
        db $fe, $fc, $cf, $58, $00, $00, $fc, $0f
        db $54, $fd, $fb, $03, $1e, $7e, $e0, $01
        db $00, $1c, $bf, $f4, $ff, $83, $87, $3f
        db $00, $52, $80, $fd, $09, $a7, $1f, $fc
        db $ff, $41, $13, $0a, $00, $ce, $93, $ff
        db $a8, $df, $ff, $00, $f4, $82, $21, $20
        db $b0, $ff, $e1, $e3, $cf, $5f, $09, $00
        db $8c, $01, $fe, $1f, $3c, $fe, $fc, $e0
        db $07, $00, $fe, $03, $3c, $38, $ff, $9f
        db $c1, $37, $e0, $8b, $00, $20, $7f, $e0
        db $ff, $a3, $c1, $95, $07, $31, $00, $f3
        db $0f, $7e, $3e, $34, $fd, $0f, $14, $ef
        db $40, $61, $ba, $e9, $ed, $59, $33, $47
        db $42, $b0, $83, $13, $ba, $9b, $1d, $36
        db $b2, $ea, $6e, $c0, $a8, $d4, $9a, $e5
        db $ad, $6e, $95, $d6, $14, $e8, $48, $7d
        db $5a, $a5, $56, $47, $47, $29, $d6, $19
        db $a9, $a4, $6d, $d5, $4a, $ca, $59, $55
        db $a6, $5a, $a9, $59, $cd, $9a, $b4, $d2
        db $ce, $64, $26, $ad, $2a, $b5, $6a, $55
        db $55, $a5, $94, $a6, $52, $af, $2c, $55
        db $55, $55, $d5, $a4, $d4, $9a, $ab, $aa
        db $aa, $64, $6d, $aa, $aa, $aa, $aa, $4a
        db $ad, $ca, $e4, $5a, $a5, $aa, $2a, $55
        db $55, $52, $75, $5b, $99, $aa, $2a, $6a
        db $25, $ad, $66, $4b, $ad, $a5, $2a, $55
        db $55, $6d, $a5, $2a, $ad, $aa, $4a, $da
        db $6a, $95, $aa, $4a, $aa, $55, $a5, $b6
        db $aa, $4a, $55, $55, $55, $85, $7f, $d0
        db $d2, $03, $fc, $e7, $21, $30, $dc, $3f
        db $e0, $1f, $80, $e3, $7f, $00, $e0, $1f
        db $f0, $ff, $03, $00, $8e, $ff, $3f, $c0
        db $0b, $00, $ff, $27, $ff, $00, $00, $ff
        db $fe, $0b, $74, $02, $f0, $3f, $37, $1d
        db $00, $ff, $80, $ff, $03, $e0, $3f, $41
        db $c5, $0a, $fe, $47, $ac, $54, $45, $ff
        db $00, $f0, $ff, $01, $fc, $01, $f0, $ff
        db $80, $1b, $f0, $1f, $34, $e0, $3f, $b4
        db $b7, $00, $f0, $ff, $01, $fe, $00, $f0
        db $ff, $4c, $00, $80, $ff, $ff, $2b, $00
        db $80, $ff, $7f, $09, $25, $80, $ff, $7b
        db $80, $1f, $e0, $1f, $d0, $3f, $00, $fe
        db $0f, $e0, $ef, $00, $f8, $c7, $1e, $a8
        db $41, $dd, $ff, $42, $03, $00, $fe, $bf
        db $bb, $02, $00, $ff, $b7, $c8, $05, $f0
        db $53, $5f, $01, $b5, $f4, $27, $14, $fd
        db $02, $fc, $57, $00, $bf, $40, $ff, $43
        db $5c, $11, $e8, $bf, $f0, $45, $15, $e0
        db $d7, $6e, $d4, $06, $e0, $5f, $6d, $8a
        db $02, $fc, $a7, $5e, $49, $80, $7f, $a9
        db $55, $32, $52, $6f, $55, $95, $54, $52
        db $db, $aa, $9a, $52, $5a, $55, $ab, $d2
        db $2a, $d5, $aa, $4a, $55, $55, $55, $ad
        db $95, $d4, $b4, $aa, $54, $55, $55, $b5
        db $aa, $aa, $2a, $55, $55, $55, $ab, $2a
        db $55, $b5, $54, $ab, $b2, $4a, $b5, $aa
        db $aa, $4a, $5a, $a5, $6d, $95, $54, $53
        db $55, $b5, $52, $55, $ad, $2a, $ab, $54
        db $35, $55, $b5, $aa, $2a, $d5, $4a, $6a
        db $ab, $aa, $54, $55, $d5, $aa, $4a, $2b
        db $2b, $2f, $ac, $4a, $d5, $a4, $b1, $58
        db $ae, $bd, $98, $50, $cd, $b5, $a9, $a4
        db $da, $aa, $62, $65, $ab, $6a, $d8, $65
        db $0d, $51, $ed, $f2, $24, $99, $5b, $8b
        db $49, $b4, $26, $b7, $46, $a5, $66, $d5
        db $ac, $16, $4b, $35, $95, $4e, $95, $b5
        db $a9, $b5, $2a, $a5, $9a, $2a, $65, $ab
        db $2a, $a5, $6c, $59, $35, $ab, $62, $34
        db $b5, $a9, $d5, $b1, $4c, $b3, $ea, $64
        db $56, $ca, $4c, $a9, $33, $ab, $9a, $56
        db $aa, $52, $65, $66, $ad, $58, $a9, $ae
        db $64, $57, $aa, $aa, $aa, $b2, $4c, $35
        db $65, $ad, $ac, $4a, $ad, $aa, $aa, $4c
        db $53, $a9, $6c, $55, $ad, $65, $55, $aa
        db $a4, $2d, $b5, $52, $55, $55, $ab, $aa
        db $aa, $ac, $b2, $4a, $55, $a5, $56, $b5
        db $4a, $ad, $aa, $4a, $ab, $d4, $54, $55
        db $55, $55, $b5, $aa, $aa, $aa, $2a, $55
        db $55, $55, $d5, $aa, $2a, $ab, $aa, $54
        db $55, $ab, $54, $53, $55, $d5, $aa, $52
        db $55, $ad, $aa, $52, $55, $55, $ad, $aa
        db $aa, $aa, $54, $55, $ad, $4a, $b5, $aa
        db $2a, $55, $55, $ab, $aa, $aa, $4a, $ab
        db $2a, $55, $55, $ab, $aa, $52, $55, $55
        db $55, $ad, $aa, $aa, $54, $55, $55, $d5
        db $aa, $aa, $2a, $55, $ad, $aa, $54, $55
        db $55, $ad, $aa, $52, $55, $55, $ad, $d4
        db $4a, $55, $55, $ab, $54, $55, $ad, $aa
        db $2a, $55, $ab, $aa, $54, $55, $b5, $aa
        db $aa, $aa, $4a, $55, $ab, $2a, $55, $55
        db $35, $b5, $54, $55, $b5, $2a, $55, $b5
        db $2a, $55, $13, $7f, $60, $b5, $03, $fc
        db $c7, $0d, $08, $f0, $ff, $e0, $3f, $00
        db $f8, $7f, $00, $f0, $0f, $f8, $3f, $04
        db $00, $cf, $ff, $3f, $c0, $0a, $c0, $ff
        db $03, $ff, $01, $d4, $19, $f8, $3f, $b0
        db $03, $e0, $ff, $1e, $50, $e0, $7f, $c0
        db $7f, $01, $f0, $1f, $7d, $01, $c0, $ff
        db $63, $66, $80, $3a, $7f, $04, $f8, $ff
        db $01, $7c, $00, $fc, $1f, $f0, $07, $e0
        db $3f, $80, $fb, $07, $fc, $0f, $e0, $0c
        db $ce, $88, $90, $aa, $ff, $ff, $7f, $00
        db $00, $fe, $01, $16, $00, $f0, $ff, $ff
        db $07, $f0, $ff, $7e, $dc, $01, $68, $b0
        db $03, $00, $56, $80, $fe, $03, $f8, $43
        db $8e, $ff, $c7, $ff, $a1, $6b, $af, $fc
        db $47, $00, $80, $fd, $47, $07, $00, $00
        db $7e, $f5, $01, $00, $fe, $4b, $7f, $01
        db $f6, $df, $3f, $17, $f0, $5f, $fe, $0f
        db $11, $3a, $62, $7f, $00, $56, $00, $c8
        db $1f, $e0, $0f, $40, $c0, $cb, $ff, $41
        db $27, $e8, $df, $fe, $47, $0a, $fa, $7f
        db $7f, $44, $80, $ff, $c5, $0d, $00, $36
        db $f5, $88, $00, $20, $e1, $7f, $48, $81
        db $0e, $d8, $ff, $d4, $b7, $4a, $fa, $c3
        db $fe, $8f, $4d, $da, $d2, $d7, $54, $08
        db $ee, $a2, $0a, $2c, $00, $ff, $44, $0b
        db $00, $f4, $3f, $eb, $86, $00, $f5, $ff
        db $7a, $63, $0a, $fa, $b7, $5b, $a9, $04
        db $fd, $92, $bd, $24, $40, $df, $44, $aa
        db $16, $40, $ff, $48, $15, $92, $d4, $bf
        db $aa, $95, $00, $ff, $ff, $23, $00, $00
        db $f8, $ff, $ff, $9f, $34, $52, $80, $12
        db $28, $9a, $f9, $8d, $ca, $6d, $a3, $df
        db $bf, $19, $62, $94, $19, $13, $04, $08
        db $ba, $96, $cb, $29, $8a, $cc, $df, $f3
        db $fe, $f5, $96, $ee, $9d, $32, $25, $26
        db $04, $e6, $a4, $80, $08, $92, $c1, $f9
        db $32, $6e, $56, $66, $ea, $ef, $dc, $de
        db $9a, $8d, $f5, $5f, $33, $1b, $43, $c1
        db $74, $92, $48, $48, $44, $50, $55, $c9
        db $b2, $94, $49, $b4, $5f, $b3, $ed, $d6
        db $d4, $ee, $75, $fb, $79, $5a, $8a, $aa
        db $ab, $4c, $45, $08, $52, $4a, $a5, $94
        db $94, $28, $a6, $54, $66, $ca, $6a, $b5
        db $5a, $db, $b6, $db, $b6, $75, $b7, $aa
        db $d5, $aa, $ca, $54, $92, $92, $49, $4a
        db $89, $94, $52, $4a, $a6, $52, $55, $6b
        db $55, $ad, $d5, $5a, $db, $aa, $56, $b3
        db $da, $b2, $ac, $9a, $6a, $33, $65, $52
        db $55, $aa, $52, $25, $25, $93, $55, $69
        db $55, $55, $aa, $aa, $aa, $a6, $2e, $55
        db $35, $b5, $a6, $55, $b5, $5a, $56, $b5
        db $54, $d5, $2a, $ab, $34, $53, $66, $55
        db $2b, $a9, $2a, $d5, $54, $55, $a5, $ca
        db $96, $aa, $aa, $66, $2a, $ad, $ac, $a9
        db $5a, $35, $55, $ad, $aa, $aa, $aa, $aa
        db $aa, $56, $55, $5a, $69, $2d, $a9, $aa
        db $aa, $d4, $2a, $55, $55, $95, $6a, $95
        db $aa, $4a, $ab, $5a, $a9, $4d, $ab, $2a
        db $ad, $aa, $aa, $5a, $a9, $aa, $aa, $aa
        db $aa, $aa, $aa, $b4, $aa, $4a, $55, $55
        db $55, $ad, $52, $55, $55, $55, $55, $95
        db $56, $55, $55, $35, $55, $ab, $54, $ab
        db $aa, $aa, $aa, $aa, $aa, $aa, $5a, $95
        db $aa, $aa, $2a, $b5, $89, $55, $95, $b4
        db $2b, $d1, $5b, $c0, $77, $8b, $40, $b7
        db $2f, $f0, $1f, $50, $e4, $95, $fb, $91
        db $c0, $07, $5b, $5f, $a0, $5f, $c0, $47
        db $17, $f8, $b4, $d2, $07, $54, $bb, $44
        db $6f, $e1, $d2, $02, $7f, $92, $f8, $07
        db $b5, $16, $d8, $97, $4e, $6c, $91, $6e
        db $8d, $b8, $d0, $dd, $82, $8b, $0e, $fc
        db $a3, $a4, $2d, $f4, $0b, $74, $75, $c2
        db $a7, $07, $d4, $55, $de, $92, $26, $b2
        db $f2, $2f, $68, $41, $55, $7f, $4a, $aa
        db $01, $fe, $83, $1f, $f8, $c0, $47, $7a
        db $d1, $82, $7e, $59, $e8, $01, $3f, $e9
        db $6a, $95, $d0, $0f, $7c, $e8, $0b, $7e
        db $a0, $ab, $92, $be, $68, $91, $b6, $e0
        db $1f, $7c, $c0, $92, $7d, $a9, $91, $2a
        db $b7, $b8, $52, $0b, $fa, $0b, $7d, $81
        db $85, $5f, $f2, $26, $92, $5a, $b5, $aa
        db $07, $7a, $41, $af, $e8, $85, $3e, $d0
        db $4b, $aa, $5b, $d4, $2a, $15, $7d, $c9
        db $16, $d9, $52, $be, $a8, $4a, $45, $5f
        db $a9, $2a, $45, $77, $e2, $17, $54, $d2
        db $2d, $75, $25, $2d, $69, $4b, $b5, $25
        db $7a, $49, $55, $55, $ad, $25, $b5, $09
        db $6f, $4a, $6b, $a4, $35, $d5, $aa, $54
        db $53, $f4, $0b, $d5, $0a, $6d, $d3, $aa
        db $aa, $54, $55, $6d, $a5, $5a, $4a, $55
        db $b5, $aa, $ca, $2a, $69, $2b, $d5, $2a
        db $a5, $56, $55, $4d, $ad, $a4, $b6, $aa
        db $aa, $52, $55, $ad, $aa, $aa, $12, $fc
        db $ff, $71, $00, $00, $c0, $ff, $ff, $bd
        db $45, $af, $02, $40, $00, $a8, $da, $be
        db $a5, $56, $ad, $fd, $fe, $5f, $a5, $84
        db $a8, $42, $40, $22, $52, $51, $b5, $aa
        db $16, $55, $3d, $d5, $f7, $ff, $be, $ce
        db $d5, $b2, $12, $53, $88, $a2, $44, $09
        db $82, $88, $92, $72, $6b, $b5, $aa, $b2
        db $d5, $af, $5b, $bd, $da, $eb, $d5, $ae
        db $6a, $ab, $94, $8a, $4a, $45, $44, $44
        db $24, $4a, $a4, $54, $aa, $4a, $d5, $aa
        db $56, $db, $b6, $d6, $6d, $ed, $6e, $bb
        db $6b, $ab, $a5, $aa, $aa, $54, $52, $8a
        db $12, $29, $91, $92, $90, $24, $29, $69
        db $b5, $aa, $5a, $55, $ab, $6d, $bb, $db
        db $dd, $da, $5a, $ab, $56, $55, $55, $55
        db $a9, $52, $29, $95, $52, $92, $52, $92
        db $4a, $92, $52, $a9, $aa, $aa, $aa, $d6
        db $5a, $6b, $ad, $b5, $b5, $ad, $6d, $6b
        db $b5, $aa, $aa, $aa, $54, $2a, $a5, $94
        db $94, $92, $52, $4a, $2a, $55, $aa, $aa
        db $aa, $5a, $ad, $6a, $6d, $ad, $b6, $d6
        db $5a, $5b, $ab, $6a, $a5, $aa, $aa, $52
        db $a9, $94, $52, $29, $95, $52, $4a, $a5
        db $2a, $55, $55, $b5, $aa, $55, $ab, $b5
        db $56, $ad, $b5, $5a, $ad, $56, $55, $55
        db $55, $55, $2a, $55, $4a, $95, $4a, $a9
        db $52, $a5, $52, $a9, $aa, $aa, $aa, $5a
        db $b5, $6a, $ad, $5a, $ad, $56, $6d, $55
        db $ad, $6a, $55, $55, $a5, $4a, $55, $2a
        db $55, $4a, $95, $52, $a5, $2a, $55, $55
        db $55, $55, $55, $b5, $6a, $d5, $6a, $b5
        db $6a, $b5, $aa, $56, $55, $d5, $4a, $55
        db $35, $55, $a5, $52, $a9, $2a, $a5, $aa
        db $54, $55, $aa, $aa, $aa, $aa, $aa, $5a
        db $55, $b5, $55, $ad, $aa, $aa, $5b, $a9
        db $b5, $24, $dd, $2e, $48, $aa, $2d, $d1
        db $4f, $a0, $c8, $56, $f6, $46, $50, $57
        db $52, $bd, $92, $de, $50, $5b, $55, $d5
        db $2e, $b5, $25, $a5, $ad, $aa, $5a, $91
        db $5e, $21, $ab, $45, $f8, $4b, $68, $2a
        db $c9, $b6, $a9, $aa, $52, $55, $ad, $95
        db $aa, $fa, $22, $76, $25, $b5, $57, $a1
        db $2b, $a9, $9b, $a4, $aa, $a6, $6a, $25
        db $29, $b5, $da, $4a, $d2, $92, $f4, $57
        db $64, $25, $a5, $fe, $8a, $aa, $92, $b4
        db $af, $aa, $4a, $aa, $9a, $5a, $55, $49
        db $6d, $c9, $96, $a4, $b4, $55, $da, $26
        db $52, $ab, $2a, $ed, $8a, $b6, $a2, $55
        db $d6, $6a, $53, $aa, $92, $ba, $2b, $b5
        db $94, $42, $6f, $a5, $a5, $94, $74, $2b
        db $d5, $14, $b5, $55, $ab, $52, $52, $57
        db $d9, $95, $4a, $da, $4a, $dd, $92, $aa
        db $aa, $4a, $5b, $c9, $56, $aa, $52, $55
        db $ad, $4a, $ab, $a4, $5a, $55, $55, $56
        db $d2, $2b, $55, $53, $a5, $ba, $a9, $aa
        db $52, $ad, $aa, $55, $aa, $54, $ab, $5a
        db $a5, $52, $ad, $a4, $ae, $52, $b5, $4a
        db $a5, $55, $d5, $2a, $55, $55, $55, $b5
        db $aa, $4a, $59, $ab, $aa, $aa, $92, $da
        db $aa, $aa, $52, $65, $ad, $aa, $aa, $52
        db $a9, $ad, $aa, $aa, $2a, $65, $ad, $aa
        db $aa, $2a, $55, $2b, $b5, $ca, $92, $4e
        db $4b, $b5, $62, $95, $9a, $ea, $62, $95
        db $07, $1f, $4b, $cb, $46, $8b, $0b, $67
        db $1f, $ec, $f8, $23, $80, $02, $fc, $ff
        db $4f, $f4, $00, $80, $69, $cc, $e2, $ef
        db $7f, $ff, $02, $e1, $07, $00, $01, $c0
        db $ff, $ff, $81, $ff, $9f, $01, $00, $60
        db $ff, $02, $f6, $cb, $af, $c2, $b6, $1f
        db $30, $00, $20, $0f, $bb, $ff, $fb, $7e
        db $00, $0f, $c0, $0a, $02, $7f, $f2, $e0
        db $5f, $ff, $63, $0a, $df, $00, $00, $83
        db $f7, $0f, $fe, $ff, $1c, $02, $d4, $3b
        db $00, $1c, $e0, $ff, $1c, $f8, $fb, $2b
        db $03, $80, $81, $81, $1f, $ff, $0f, $f0
        db $ff, $13, $7c, $00, $e3, $0c, $90, $df
        db $f7, $23, $fc, $0f, $78, $02, $00, $df
        db $c0, $fe, $07, $7f, $a0, $f2, $04, $66
        db $02, $fc, $bf, $80, $3f, $f8, $fd, $12
        db $68, $2d, $2a, $a0, $ff, $81, $5f, $5b
        db $e0, $1f, $40, $fc, $40, $15, $fa, $a6
        db $93, $fc, $80, $df, $0b, $e0, $07, $1c
        db $6f, $a2, $ff, $42, $97, $9c, $2e, $c0
        db $d2, $1d, $f9, $03, $fc, $07, $6a, $45
        db $6d, $89, $06, $7e, $e8, $b3, $41, $fd
        db $a0, $a3, $2e, $f0, $2d, $f8, $45, $57
        db $17, $f0, $da, $84, $7e, $81, $f3, $c1
        db $aa, $2b, $a9, $2c, $e4, $0f, $f8, $85
        db $5a, $3d, $d0, $b5, $03, $5e, $03, $bf
        db $d8, $5a, $0b, $bc, $55, $e4, $1d, $f0
        db $1e, $58, $ed, $09, $ae, $03, $f7, $82
        db $ae, $70, $8b, $17, $f8, $3e, $c0, $6b
        db $d0, $4b, $36, $ea, $41, $b7, $2c, $f6
        db $01, $df, $82, $8b, $7b, $c0, $37, $f0
        db $5a, $e8, $25, $5e, $e1, $03, $de, $07
        db $5c, $2b, $bc, $a2, $93, $de, $c0, $97
        db $aa, $74, $49, $2d, $3a, $a1, $5f, $f8
        db $a9, $07, $f8, $81, $b5, $06, $f0, $7b
        db $c9, $7b, $80, $1f, $f0, $60, $07, $7e
        db $ec, $e4, $0f, $fc, $81, $83, $8d, $e0
        db $2f, $5c, $fc, $03, $3f, $f0, $44, $15
        db $f8, $1f, $b8, $0f, $f0, $07, $1e, $fc
        db $01, $5e, $dc, $fc, $00, $7f, $d0, $c3
        db $0b, $f0, $0f, $8e, $1f, $e0, $07, $fe
        db $e8, $01, $be, $80, $ff, $0f, $fe, $00
        db $00, $f8, $e0, $ff, $ff, $35, $75, $07
        db $00, $00, $02, $f8, $d7, $cf, $4d, $fc
        db $e1, $ff, $ff, $00, $16, $f0, $2a, $00
        db $15, $70, $00, $3f, $f0, $c5, $7f, $d4
        db $de, $c5, $ff, $fc, $81, $ff, $f0, $49
        db $2b, $08, $64, $02, $0a, $80, $05, $7e
        db $b5, $c4, $97, $1a, $ea, $07, $fe, $f5
        db $5f, $bd, $f9, $ea, $65, $1f, $c0, $0f
        db $3c, $70, $15, $40, $25, $a0, $01, $bc
        db $c0, $8f, $3a, $d8, $4f, $52, $fd, $c1
        db $9f, $fe, $c5, $9f, $76, $6f, $d5, $05
        db $f8, $21, $0f, $fa, $00, $36, $10, $52
        db $00, $23, $f4, $c3, $0f, $f9, $05, $b5
        db $96, $68, $db, $9f, $fc, $53, $bf, $ba
        db $ad, $92, $5e, $b1, $92, $3e, $c0, $16
        db $14, $49, $a4, $a0, $5d, $e0, $05, $7d
        db $c1, $5d, $ad, $b2, $7d, $63, $bf, $b0
        db $ab, $b6, $52, $95, $b6, $aa, $d8, $0b
        db $b8, $0a, $15, $a9, $24, $ea, $15, $7a
        db $d0, $1d, $74, $a5, $96, $78, $37, $d9
        db $1f, $74, $b5, $2b, $a9, $49, $6d, $56
        db $75, $89, $36, $51, $1b, $2a, $50, $eb
        db $c3, $0f, $80, $3e, $ef, $e1, $1b, $98
        db $01, $2b, $ff, $fe, $87, $21, $30, $32
        db $23, $fc, $ff, $c1, $1a, $58, $03, $24
        db $f8, $df, $cd, $40, $7f, $01, $14, $74
        db $b7, $7e, $f4, $6f, $88, $12, $d0, $7e
        db $6f, $f2, $20, $de, $09, $48, $ca, $ff
        db $04, $c1, $fd, $a4, $09, $80, $ff, $92
        db $c2, $ff, $d9, $02, $60, $db, $ce, $c4
        db $fe, $de, $01, $11, $e8, $7f, $a0, $7c
        db $d1, $0f, $00, $dc, $bf, $68, $22, $ee
        db $12, $00, $fa, $ff, $bb, $c0, $2e, $82
        db $88, $d4, $ff, $3f, $ca, $16, $b2, $04
        db $aa, $fe, $af, $81, $29, $35, $00, $9d
        db $da, $ff, $01, $54, $b7, $82, $24, $f4
        db $bf, $99, $b4, $b5, $19, $42, $dc, $ab
        db $3a, $e6, $35, $4b, $88, $a4, $fe, $4d
        db $70, $4d, $56, $92, $40, $de, $df, $a8
        db $aa, $5a, $a4, $88, $ba, $fb, $86, $6a
        db $57, $22, $45, $59, $f7, $15, $66, $ad
        db $52, $21, $59, $5d, $b7, $54, $d2, $aa
        db $22, $a9, $da, $6d, $aa, $cc, $2a, $35
        db $51, $ed, $9a, $aa, $6a, $95, $5a, $a2
        db $55, $ad, $aa, $aa, $96, $4a, $55, $53
        db $da, $2a, $55, $d5, $54, $d5, $52, $d9
        db $54, $55, $da, $aa, $4a, $da, $aa, $aa
        db $1a, $d3, $ca, $aa, $54, $ab, $4a, $d5
        db $aa, $4a, $ab, $52, $ad, $54, $95, $56
        db $55, $ab, $ac, $52, $b5, $4a, $55, $b5
        db $52, $55, $55, $ad, $aa, $aa, $b4, $aa
        db $54, $b5, $aa, $aa, $52, $ad, $aa, $aa
        db $54, $b5, $4a, $69, $ab, $aa, $4a, $56
        db $55, $55, $b5, $54, $b5, $2a, $ab, $62
        db $95, $ad, $d4, $ca, $ac, $a5, $34, $4b
        db $b5, $54, $d9, $6e, $44, $6a, $55, $56
        db $55, $95, $aa, $ed, $2a, $d1, $ac, $a4
        db $55, $d4, $6a, $6b, $b6, $a2, $2a, $53
        db $55, $55, $55, $55, $b5, $4b, $52, $55
        db $55, $2d, $e9, $4a, $cd, $aa, $54, $d5
        db $2a, $ad, $91, $6a, $ad, $52, $ad, $b2
        db $aa, $95, $2a, $a5, $96, $da, $b6, $a4
        db $52, $b5, $aa, $8a, $5a, $a5, $56, $ab
        db $2a, $ab, $52, $2b, $a2, $df, $aa, $1f
        db $00, $80, $a4, $fe, $ff, $ff, $4f, $42
        db $08, $01, $40, $51, $b5, $6a, $b5, $6b
        db $7b, $df, $7f, $57, $59, $25, $54, $22
        db $88, $88, $08, $91, $52, $55, $55, $b5
        db $d6, $fa, $de, $fb, $db, $76, $ab, $aa
        db $96, $2a, $55, $45, $89, $10, $84, $88
        db $48, $53, $aa, $6a, $4a, $55, $ad, $6b
        db $b5, $75, $b7, $7b, $b7, $dd, $b6, $56
        db $55, $a9, $4a, $49, $2a, $45, $24, $92
        db $24, $29, $52, $92, $aa, $52, $59, $6b
        db $6b, $ab, $ad, $6e, $db, $de, $b6, $6d
        db $6b, $ab, $aa, $2a, $4d, $52, $55, $a2
        db $48, $92, $24, $91, $48, $92, $5a, $29
        db $55, $b5, $6a, $6b, $b5, $ad, $75, $b7
        db $5d, $db, $5a, $5b, $55, $55, $55, $55
        db $95, $92, $94, $94, $94, $48, $a5, $a4
        db $4a, $4a, $55, $b5, $aa, $a6, $56, $ab
        db $6e, $6d, $ad, $da, $5a

        ; unaccessed ($d221)
        db $6d, $65, $55, $55

game_over:
        ; Name Table data for the "GAME OVER - CONTINUE?" screen with a simple
        ; encryption (17 is subtracted from each value). 96 (32*3) bytes.

        ; "           GAME OVER            "
        db $4a+17, $4a+17, $4a+17, $4a+17, $4a+17, $4a+17, $4a+17, $4a+17
        db $4a+17, $4a+17, $4a+17, $36+17, $30+17, $3c+17, $34+17, $4a+17
        db $3e+17, $45+17, $34+17, $41+17, $4a+17, $4a+17, $4a+17, $4a+17
        db $4a+17, $4a+17, $4a+17, $4a+17, $4a+17, $4a+17, $4a+17, $4a+17

        ; "                                "
        db $4a+17, $4a+17, $4a+17, $4a+17, $4a+17, $4a+17, $4a+17, $4a+17
        db $4a+17, $4a+17, $4a+17, $4a+17, $4a+17, $4a+17, $4a+17, $4a+17
        db $4a+17, $4a+17, $4a+17, $4a+17, $4a+17, $4a+17, $4a+17, $4a+17
        db $4a+17, $4a+17, $4a+17, $4a+17, $4a+17, $4a+17, $4a+17, $4a+17

        ; "           CONTINUE?            "
        db $4a+17, $4a+17, $4a+17, $4a+17, $4a+17, $4a+17, $4a+17, $4a+17
        db $4a+17, $4a+17, $4a+17, $32+17, $3e+17, $3d+17, $43+17, $38+17
        db $3d+17, $44+17, $34+17, $7a+17, $4a+17, $4a+17, $4a+17, $4a+17
        db $4a+17, $4a+17, $4a+17, $4a+17, $4a+17, $4a+17, $4a+17, $4a+17

greets:
        ; Name Table data for the "GREETS TO ALL NINTENDAWGS" screen with a simple
        ; encryption (17 is subtracted from each value). 640 (32*20) bytes.

        ; "           NAE(M)OK             "
        db $4a+17, $4a+17, $4a+17, $4a+17, $4a+17, $4a+17, $4a+17, $4a+17
        db $4a+17, $4a+17, $4a+17, $3d+17, $30+17, $34+17, $4d+17, $3c+17
        db $4e+17, $3e+17, $3a+17, $4a+17, $4a+17, $4a+17, $4a+17, $4a+17
        db $4a+17, $4a+17, $4a+17, $4a+17, $4a+17, $4a+17, $4a+17, $4a+17

        ; "         BYTER(A)PERS           "
        db $4a+17, $4a+17, $4a+17, $4a+17, $4a+17, $4a+17, $4a+17, $4a+17
        db $4a+17, $31+17, $48+17, $43+17, $34+17, $41+17, $4d+17, $30+17
        db $4e+17, $3f+17, $34+17, $41+17, $42+17, $4a+17, $4a+17, $4a+17
        db $4a+17, $4a+17, $4a+17, $4a+17, $4a+17, $4a+17, $4a+17, $4a+17

        ; "       JUMALAU(T)A              "
        db $4a+17, $4a+17, $4a+17, $4a+17, $4a+17, $4a+17, $4a+17, $39+17
        db $44+17, $3c+17, $30+17, $3b+17, $30+17, $44+17, $4d+17, $43+17
        db $4e+17, $30+17, $4a+17, $4a+17, $4a+17, $4a+17, $4a+17, $4a+17
        db $4a+17, $4a+17, $4a+17, $4a+17, $4a+17, $4a+17, $4a+17, $4a+17

        ; "           SHI(T)FACED CLOWNS   "
        db $4a+17, $4a+17, $4a+17, $4a+17, $4a+17, $4a+17, $4a+17, $4a+17
        db $4a+17, $4a+17, $4a+17, $42+17, $37+17, $38+17, $4d+17, $43+17
        db $4e+17, $35+17, $30+17, $32+17, $34+17, $33+17, $4a+17, $32+17
        db $3b+17, $3e+17, $46+17, $3d+17, $42+17, $4a+17, $4a+17, $4a+17

        ; "              ( )               "
        db $4a+17, $4a+17, $4a+17, $4a+17, $4a+17, $4a+17, $4a+17, $4a+17
        db $4a+17, $4a+17, $4a+17, $4a+17, $4a+17, $4a+17, $4d+17, $4a+17
        db $4e+17, $4a+17, $4a+17, $4a+17, $4a+17, $4a+17, $4a+17, $4a+17
        db $4a+17, $4a+17, $4a+17, $4a+17, $4a+17, $4a+17, $4a+17, $4a+17

        ; "       DEKADEN(C)E              "
        db $4a+17, $4a+17, $4a+17, $4a+17, $4a+17, $4a+17, $4a+17, $33+17
        db $34+17, $3a+17, $30+17, $33+17, $34+17, $3d+17, $4d+17, $32+17
        db $4e+17, $34+17, $4a+17, $4a+17, $4a+17, $4a+17, $4a+17, $4a+17
        db $4a+17, $4a+17, $4a+17, $4a+17, $4a+17, $4a+17, $4a+17, $4a+17

        ; "       ANANASM(U)RSKA           "
        db $4a+17, $4a+17, $4a+17, $4a+17, $4a+17, $4a+17, $4a+17, $30+17
        db $3d+17, $30+17, $3d+17, $30+17, $42+17, $3c+17, $4d+17, $44+17
        db $4e+17, $41+17, $42+17, $3a+17, $30+17, $4a+17, $4a+17, $4a+17
        db $4a+17, $4a+17, $4a+17, $4a+17, $4a+17, $4a+17, $4a+17, $4a+17

        ; "             T(R)ACTION         "
        db $4a+17, $4a+17, $4a+17, $4a+17, $4a+17, $4a+17, $4a+17, $4a+17
        db $4a+17, $4a+17, $4a+17, $4a+17, $4a+17, $43+17, $4d+17, $41+17
        db $4e+17, $30+17, $32+17, $43+17, $38+17, $3e+17, $3d+17, $4a+17
        db $4a+17, $4a+17, $4a+17, $4a+17, $4a+17, $4a+17, $4a+17, $4a+17

        ; "             D(R)AGON MAGIC     "
        db $4a+17, $4a+17, $4a+17, $4a+17, $4a+17, $4a+17, $4a+17, $4a+17
        db $4a+17, $4a+17, $4a+17, $4a+17, $4a+17, $33+17, $4d+17, $41+17
        db $4e+17, $30+17, $36+17, $3e+17, $3d+17, $4a+17, $3c+17, $30+17
        db $36+17, $38+17, $32+17, $4a+17, $4a+17, $4a+17, $4a+17, $4a+17

        ; "           ASP(E)KT             "
        db $4a+17, $4a+17, $4a+17, $4a+17, $4a+17, $4a+17, $4a+17, $4a+17
        db $4a+17, $4a+17, $4a+17, $30+17, $42+17, $3f+17, $4d+17, $34+17
        db $4e+17, $3a+17, $43+17, $4a+17, $4a+17, $4a+17, $4a+17, $4a+17
        db $4a+17, $4a+17, $4a+17, $4a+17, $4a+17, $4a+17, $4a+17, $4a+17

        ; "              (N)ALLEPERHE      "
        db $4a+17, $4a+17, $4a+17, $4a+17, $4a+17, $4a+17, $4a+17, $4a+17
        db $4a+17, $4a+17, $4a+17, $4a+17, $4a+17, $4a+17, $4d+17, $3d+17
        db $4e+17, $30+17, $3b+17, $3b+17, $34+17, $3f+17, $34+17, $41+17
        db $37+17, $34+17, $4a+17, $4a+17, $4a+17, $4a+17, $4a+17, $4a+17

        ; "            FI(T)               "
        db $4a+17, $4a+17, $4a+17, $4a+17, $4a+17, $4a+17, $4a+17, $4a+17
        db $4a+17, $4a+17, $4a+17, $4a+17, $35+17, $38+17, $4d+17, $43+17
        db $4e+17, $4a+17, $4a+17, $4a+17, $4a+17, $4a+17, $4a+17, $4a+17
        db $4a+17, $4a+17, $4a+17, $4a+17, $4a+17, $4a+17, $4a+17, $4a+17

        ; "                                "
        db $4a+17, $4a+17, $4a+17, $4a+17, $4a+17, $4a+17, $4a+17, $4a+17
        db $4a+17, $4a+17, $4a+17, $4a+17, $4a+17, $4a+17, $4a+17, $4a+17
        db $4a+17, $4a+17, $4a+17, $4a+17, $4a+17, $4a+17, $4a+17, $4a+17
        db $4a+17, $4a+17, $4a+17, $4a+17, $4a+17, $4a+17, $4a+17, $4a+17

        ; "               +                "
        db $4a+17, $4a+17, $4a+17, $4a+17, $4a+17, $4a+17, $4a+17, $4a+17
        db $4a+17, $4a+17, $4a+17, $4a+17, $4a+17, $4a+17, $4a+17, $4c+17
        db $4a+17, $4a+17, $4a+17, $4a+17, $4a+17, $4a+17, $4a+17, $4a+17
        db $4a+17, $4a+17, $4a+17, $4a+17, $4a+17, $4a+17, $4a+17, $4a+17

        ; "                                "
        db $4a+17, $4a+17, $4a+17, $4a+17, $4a+17, $4a+17, $4a+17, $4a+17
        db $4a+17, $4a+17, $4a+17, $4a+17, $4a+17, $4a+17, $4a+17, $4a+17
        db $4a+17, $4a+17, $4a+17, $4a+17, $4a+17, $4a+17, $4a+17, $4a+17
        db $4a+17, $4a+17, $4a+17, $4a+17, $4a+17, $4a+17, $4a+17, $4a+17

        ; "  PWP/FAIRLIGHT/MFX/MOONHAZARD  "
        db $4a+17, $4a+17, $3f+17, $46+17, $3f+17, $4b+17, $35+17, $30+17
        db $38+17, $41+17, $3b+17, $38+17, $36+17, $37+17, $43+17, $4b+17
        db $3c+17, $35+17, $47+17, $4b+17, $3c+17, $3e+17, $3e+17, $3d+17
        db $37+17, $30+17, $49+17, $30+17, $41+17, $33+17, $4a+17, $4a+17

        ; "    ISO/RNO/DAMONES/HEDELMAE    "
        db $4a+17, $4a+17, $4a+17, $4a+17, $38+17, $42+17, $3e+17, $4b+17
        db $41+17, $3d+17, $3e+17, $4b+17, $33+17, $30+17, $3c+17, $3e+17
        db $3d+17, $34+17, $42+17, $4b+17, $37+17, $34+17, $33+17, $34+17
        db $3b+17, $3c+17, $30+17, $34+17, $4a+17, $4a+17, $4a+17, $4a+17

        ; "                                "
        db $4a+17, $4a+17, $4a+17, $4a+17, $4a+17, $4a+17, $4a+17, $4a+17
        db $4a+17, $4a+17, $4a+17, $4a+17, $4a+17, $4a+17, $4a+17, $4a+17
        db $4a+17, $4a+17, $4a+17, $4a+17, $4a+17, $4a+17, $4a+17, $4a+17
        db $4a+17, $4a+17, $4a+17, $4a+17, $4a+17, $4a+17, $4a+17, $4a+17

        ; "             WAMMA              "
        db $4a+17, $4a+17, $4a+17, $4a+17, $4a+17, $4a+17, $4a+17, $4a+17
        db $4a+17, $4a+17, $4a+17, $4a+17, $4a+17, $46+17, $30+17, $3c+17
        db $3c+17, $30+17, $4a+17, $4a+17, $4a+17, $4a+17, $4a+17, $4a+17
        db $4a+17, $4a+17, $4a+17, $4a+17, $4a+17, $4a+17, $4a+17, $4a+17

        ; " QUALITY PRODUCTIONS SINCE 1930 "
        db $4a+17, $40+17, $44+17, $30+17, $3b+17, $38+17, $43+17, $48+17
        db $4a+17, $3f+17, $41+17, $3e+17, $33+17, $44+17, $32+17, $43+17
        db $38+17, $3e+17, $3d+17, $42+17, $4a+17, $42+17, $38+17, $3d+17
        db $32+17, $34+17, $4a+17, $7b+17, $7c+17, $7d+17, $7e+17, $4a+17

table17:
        ; $d505, 44 bytes, some bytes unaccessed
        db $48, $4a, $4c, $4e, $60, $62, $64, $66
        db $68, $6a, $6c, $6e, $80, $82, $84, $86
        db $88, $8a, $8c, $8e, $a0, $a2, $a4, $a6
        db $a8, $aa, $ac, $ae, $c0, $c2, $c4, $c6
        db $c8, $ca, $cc, $ce, $e0, $e2, $e4, $e6
        db $e8, $ea, $ec, $ee

color_or_table:
        db $0f, $00, $10, $20

table18b:
        db $3c, $0f, $3c, $22

table18c:
        db $3c, $3c, $3c, $3c

table19:
        ; 256 bytes.
        ; If the formula (x+60)%256 is applied, looks like a smooth curve with
        ; values 0-121.

        db   0,   0, 255, 254, 253, 252, 252, 251
        db 250, 250, 249, 248, 248, 247, 247, 246
        db 246, 245, 245, 245, 244, 244, 244, 244
        db 244, 244, 244, 245, 245, 245, 246, 246
        db 247, 247, 248, 249, 250, 251, 252, 253
        db 254, 255,   0,   1,   3,   4,   5,   7
        db   8,  10,  11,  13,  14,  16,  18,  19
        db  21,  23,  25,  26,  28,  30,  31,  33
        db  35,  37,  38,  40,  41,  43,  44,  46
        db  47,  49,  50,  51,  52,  53,  54,  55
        db  56,  57,  58,  59,  59,  60,  60,  60
        db  61,  61,  61,  61,  61,  60,  60,  60
        db  59,  58,  58,  57,  56,  55,  54,  53
        db  51,  50,  49,  47,  45,  44,  42,  40
        db  38,  36,  34,  32,  30,  28,  25,  23
        db  21,  18,  16,  14,  11,   9,   6,   4
        db   1, 255, 252, 250, 247, 245, 242, 240
        db 237, 235, 233, 230, 228, 226, 224, 222
        db 220, 218, 216, 214, 212, 211, 209, 208
        db 206, 205, 204, 203, 202, 201, 200, 199
        db 198, 198, 197, 197, 197, 196, 196, 196
        db 196, 197, 197, 197, 198, 198, 199, 200
        db 200, 201, 202, 203, 204, 206, 207, 208
        db 209, 211, 212, 214, 215, 217, 218, 220
        db 222, 223, 225, 227, 228, 230, 232, 233
        db 235, 237, 239, 240, 242, 243, 245, 247
        db 248, 250, 251, 252, 254, 255,   0,   2
        db   3,   4,   5,   6,   7,   8,   8,   9
        db  10,  10,  11,  11,  12,  12,  12,  12
        db  12,  13,  13,  12,  12,  12,  12,  12
        db  11,  11,  10,  10,   9,   9,   8,   7
        db   7,   6,   5,   5,   4,   3,   2,   1

table20:
        ; A smooth curve with 256 values between 4-64.

        db 34, 36, 37, 38, 39, 40, 42, 43
        db 44, 45, 46, 48, 49, 50, 51, 52
        db 53, 54, 55, 56, 56, 57, 58, 59
        db 60, 60, 61, 61, 62, 62, 63, 63
        db 63, 64, 64, 64, 64, 64, 64, 64
        db 64, 64, 64, 64, 64, 63, 63, 63
        db 62, 62, 61, 61, 60, 60, 59, 58
        db 58, 57, 56, 56, 55, 54, 53, 52
        db 52, 51, 50, 49, 48, 47, 46, 46
        db 45, 44, 43, 42, 41, 41, 40, 39
        db 38, 38, 37, 36, 35, 35, 34, 34
        db 33, 32, 32, 31, 31, 31, 30, 30
        db 30, 29, 29, 29, 29, 28, 28, 28
        db 28, 28, 28, 28, 28, 28, 29, 29
        db 29, 29, 29, 30, 30, 30, 30, 31
        db 31, 31, 32, 32, 33, 33, 33, 34
        db 34, 35, 35, 35, 36, 36, 37, 37
        db 37, 38, 38, 38, 39, 39, 39, 39
        db 40, 40, 40, 40, 40, 40, 40, 40
        db 40, 40, 40, 40, 40, 40, 40, 39
        db 39, 39, 39, 38, 38, 37, 37, 36
        db 36, 35, 35, 34, 33, 33, 32, 31
        db 31, 30, 29, 28, 27, 27, 26, 25
        db 24, 23, 22, 21, 21, 20, 19, 18
        db 17, 16, 16, 15, 14, 13, 12, 12
        db 11, 10, 10,  9,  8,  8,  7,  7
        db  6,  6,  6,  5,  5,  5,  4,  4
        db  4,  4,  4,  4,  4,  4,  4,  5
        db  5,  5,  6,  6,  6,  7,  7,  8
        db  9,  9, 10, 11, 12, 12, 13, 14
        db 15, 16, 17, 18, 19, 20, 22, 23
        db 24, 25, 26, 27, 29, 30, 31, 32

woman_sprite_x:
        ; Sprite X positions in the woman part of the demo. 256 bytes.
        ; 194 (-62) is added to these.
        ; If the formula (x+182)%256 is applied, looks like a smooth curve with
        ; values 0-212.

        db 221, 221, 221, 221, 222, 222, 222, 222
        db 222, 222, 222, 222, 222, 222, 222, 222
        db 222, 221, 221, 221, 220, 220, 219, 219
        db 218, 217, 216, 215, 215, 213, 212, 211
        db 210, 208, 207, 205, 204, 202, 200, 198
        db 196, 194, 192, 190, 187, 185, 182, 180
        db 177, 174, 171, 168, 165, 162, 159, 155
        db 152, 149, 145, 142, 138, 135, 131, 128
        db 124, 121, 117, 114, 111, 108, 104, 101
        db  98,  96,  93,  90,  88,  86,  84,  82
        db  80,  78,  77,  76,  75,  75,  74,  74
        db  74,  75,  75,  76,  77,  79,  80,  82
        db  84,  87,  89,  92,  95,  98, 102, 105
        db 109, 113, 117, 122, 126, 130, 135, 140
        db 145, 149, 154, 159, 164, 169, 174, 179
        db 184, 189, 193, 198, 203, 207, 211, 216
        db 220, 224, 228, 231, 235, 238, 242, 245
        db 248, 251, 253,   0,   2,   5,   7,   9
        db  11,  12,  14,  15,  17,  18,  19,  20
        db  21,  22,  23,  23,  24,  25,  25,  26
        db  26,  27,  27,  27,  28,  28,  28,  29
        db  29,  29,  29,  30,  30,  30,  30,  30
        db  30,  30,  30,  30,  30,  30,  30,  30
        db  29,  29,  29,  28,  28,  27,  27,  26
        db  25,  25,  24,  23,  22,  21,  19,  18
        db  17,  16,  14,  13,  11,  10,   8,   7
        db   5,   3,   2,   0, 254, 253, 251, 249
        db 248, 246, 244, 243, 241, 239, 238, 236
        db 235, 234, 232, 231, 230, 229, 228, 227
        db 226, 225, 224, 224, 223, 223, 222, 222
        db 221, 221, 221, 221, 220, 220, 220, 220
        db 220, 220, 220, 221, 221, 221, 221, 221

table22:
        ; A smooth curve with 256 values between 2-22.

        db 10, 11, 12, 12, 13, 14, 15, 15
        db 16, 16, 17, 17, 18, 18, 19, 19
        db 19, 19, 19, 19, 19, 19, 18, 18
        db 18, 17, 17, 16, 16, 15, 14, 14
        db 13, 12, 11, 11, 10,  9,  9,  8
        db  7,  7,  6,  6,  6,  5,  5,  5
        db  5,  5,  5,  6,  6,  6,  7,  7
        db  8,  8,  9, 10, 11, 11, 12, 13
        db 14, 15, 16, 16, 17, 18, 19, 19
        db 20, 20, 21, 21, 22, 22, 22, 22
        db 22, 22, 22, 22, 21, 21, 20, 20
        db 19, 18, 18, 17, 16, 15, 15, 14
        db 13, 12, 11, 10, 10,  9,  8,  7
        db  7,  6,  6,  5,  5,  5,  5,  4
        db  4,  4,  4,  5,  5,  5,  5,  6
        db  6,  7,  7,  8,  8,  9,  9, 10
        db 10, 11, 11, 12, 12, 13, 13, 14
        db 14, 14, 14, 15, 15, 15, 15, 15
        db 15, 14, 14, 14, 14, 13, 13, 12
        db 12, 12, 11, 10, 10,  9,  9,  8
        db  8,  7,  7,  6,  6,  5,  5,  4
        db  4,  4,  3,  3,  3,  3,  3,  3
        db  2,  2,  3,  3,  3,  3,  3,  3
        db  4,  4,  4,  5,  5,  5,  6,  6
        db  7,  7,  8,  8,  8,  9,  9,  9
        db 10, 10, 10, 11, 11, 11, 11, 11
        db 11, 11, 11, 11, 11, 11, 11, 11
        db 11, 10, 10, 10,  9,  9,  9,  8
        db  8,  7,  7,  6,  6,  6,  5,  5
        db  5,  4,  4,  4,  4,  3,  3,  3
        db  3,  3,  3,  4,  4,  4,  4,  5
        db  5,  6,  6,  7,  8,  8,  9, 10

table23:
        ; 256 bytes.
        ; Note: on each line:
        ;     - the high nybbles are 0, 1, 2, 3, 2, 1, 0, 0
        ;     - all low nybbles are the same

        db $06, $16, $26, $36, $26, $16, $06, $06
        db $0a, $1a, $2a, $3a, $2a, $1a, $0a, $0a
        db $02, $12, $22, $32, $22, $12, $02, $02
        db $03, $13, $23, $33, $23, $13, $03, $03
        db $08, $18, $28, $38, $28, $18, $08, $08
        db $05, $15, $25, $35, $25, $15, $05, $05
        db $0b, $1b, $2b, $3b, $2b, $1b, $0b, $0b
        db $04, $14, $24, $34, $24, $14, $04, $04
        db $07, $17, $27, $37, $27, $17, $07, $07
        db $06, $16, $26, $36, $26, $16, $06, $06
        db $0a, $1a, $2a, $3a, $2a, $1a, $0a, $0a
        db $02, $12, $22, $32, $22, $12, $02, $02
        db $03, $13, $23, $33, $23, $13, $03, $03
        db $08, $18, $28, $38, $28, $18, $08, $08
        db $05, $15, $25, $35, $25, $15, $05, $05
        db $0b, $1b, $2b, $3b, $2b, $1b, $0b, $0b
        db $04, $14, $24, $34, $24, $14, $04, $04
        db $07, $17, $27, $37, $27, $17, $07, $07
        db $06, $16, $26, $36, $26, $16, $06, $06
        db $0a, $1a, $2a, $3a, $2a, $1a, $0a, $0a
        db $02, $12, $22, $32, $22, $12, $02, $02
        db $03, $13, $23, $33, $23, $13, $03, $03
        db $08, $18, $28, $38, $28, $18, $08, $08
        db $05, $15, $25, $35, $25, $15, $05, $05
        db $0b, $1b, $2b, $3b, $2b, $1b, $0b, $0b
        db $04, $14, $24, $34, $24, $14, $04, $04
        db $0b, $1b, $2b, $3b, $2b, $1b, $0b, $0b
        db $05, $15, $25, $35, $25, $15, $05, $05
        db $08, $18, $28, $38, $28, $18, $08, $08
        db $03, $13, $23, $33, $23, $13, $03, $03
        db $02, $12, $22, $32, $22, $12, $02, $02
        db $0a, $1a, $2a, $3a, $2a, $1a, $0a, $0a

        ; unaccessed ($da3d)
        db $06, $16, $26, $36, $26, $16, $06, $06
        db $07, $17, $27, $37, $27, $17, $07, $07
        db $06, $16, $26, $36, $26, $16, $06, $06
        db $0a, $1a, $2a, $3a, $2a, $1a, $0a, $0a
        db $02, $12, $22, $32, $22, $12, $02, $02
        db $03, $13, $23, $33, $23, $13, $03, $03
        db $08, $18, $28, $38, $28, $18, $08, $08
        db $05, $15, $25, $35, $25, $15, $05, $05
        db $0b, $1b, $2b, $3b, $2b, $1b, $0b, $0b

data1:  ; $da85
        db $18

table24:  ; $da86 (25 bytes)
        db $40, $40, $40, $40, $40
        db $48, $48, $48, $48, $48
        db $50, $50, $50, $50, $50
        db $58, $58, $58, $58, $58
        db $60, $60, $60, $60, $60

table25:  ; $da9f (25 bytes)
        db $c6, $c7, $c8, $c9, $ca, $cb, $cc, $cd, $ce, $cf
        db $d6, $d7, $d8, $d9, $da, $db, $dc, $dd, $de, $df
        db $e0, $e1, $e2, $e3, $e4

table26:  ; $dab8 (25 bytes)
        db $01, $01, $01, $01, $01, $01, $01, $01
        db $01, $01, $01, $01, $01, $01, $01, $01
        db $01, $01, $01, $01, $01, $01, $01, $01
        db $01

table27:  ; $dad1 (25 bytes)
        db $40, $48, $50, $58, $60
        db $40, $48, $50, $58, $60
        db $40, $48, $50, $58, $60
        db $40, $48, $50, $58, $60
        db $40, $48, $50, $58, $60

; Unaccessed block ($daea)

data2:
        db $0b

table28:
        db $00, $00, $00
        db $08, $08, $08
        db $10, $10, $10
        db $18, $18, $18

table29:
        db $00, $01, $02
        db $10, $11, $12
        db $20, $21, $22
        db $30, $31, $32
        db $40, $40, $40
        db $40, $40, $40
        db $40, $40, $40
        db $40, $40, $40

table30:
        db $00, $08, $10
        db $00, $08, $10
        db $00, $08, $10
        db $00, $08, $10

data3:
        ; $db1b
        db $03

table31:
        db $04, $06, $06, $06

table32:
        db $09, $0e, $0c, $3e

table33:
        db $0b, $0f, $0d, $3f

        ; unaccessed ($db28)
        db $04, $02

data4:  ; $db2a
        db $10

table34:  ; $db2b (17 bytes)
        db $00
        db $fb, $fb, $fb, $fb
        db $03, $03, $03, $03
        db $f6, $f6, $f6
        db $ee, $ee, $ee
        db $e6, $e6

table35:  ; $db3c (17 bytes)
        db $46
        db $1c, $1b, $1a, $19
        db $2c, $2b, $2a, $29
        db $2f, $2e, $2d
        db $3e
        db $1e, $1d
        db $0e, $0c

table36:  ; $db4d (17 bytes)
        db $40
        db $41, $41, $41, $41, $41, $41, $41, $41
        db $42, $42, $42, $42, $42, $42, $42, $42

table37:  ; $db5e (17 bytes)
        db $00, $06, $0e, $16
        db $1e, $07, $0f, $17
        db $1f, $0c, $14
        db $1c, $0c, $14
        db $1c, $0c, $14

data5:  ; $db6f
        db $03

data6:  ; $db70
        db $3f

table38:
        ; $db71, 64 bytes.
        ; Looks like a sawtooth wave with values 8-255.
        ; Last 15 bytes are unaccessed.
        db   8,  19,  25,  48,  69,  80,  94, 103
        db 128, 136, 159, 186, 200, 209, 224, 244
        db  24,  37,  52,  80,  84,  85, 106, 111
        db 158, 171, 205, 211, 218, 229, 240, 255
        db  10,  25,  58,  86,  90,  95, 123, 128
        db 144, 175, 185, 198, 207, 234, 247, 250
        db  19,  25,  37,  85, 106, 111,  94, 103
        db 128, 136, 186, 200, 225, 235, 240, 244

table39:
        db $40, $43, $42, $41

        ; unaccessed ($dbb5)
        db $03, $00, $00, $07, $07, $42, $43, $52
        db $53, $03, $03, $03, $03, $00, $07, $00
        db $07, $01, $00, $00, $41, $51, $03, $03
        db $00, $07

data7:  ; $dbcf
        db $0f

table40:  ; $dbd0 (16 bytes)
        db $13, $50, $54, $6f, $9e, $ab, $d0, $ff
        db $06, $5a, $5f, $c6, $ca, $13, $19, $25

table41:  ; $dbe0 (16 bytes)
        db $55, $df, $51, $21, $3d, $9a, $7d, $88
        db $cc, $8f, $aa, $43, $8a, $6e, $90, $76

table42:  ; $dbf0 (16 bytes)
        db $03, $05, $05, $07, $06, $04, $06, $05
        db $02, $05, $04, $08, $03, $02, $07, $06

table43:  ; $dc00 (16 bytes)
        db $50, $51, $51, $53, $51, $52, $50, $53
        db $52, $52, $51, $51, $52, $53, $53, $51

; Star sprites in the first two parts of the demo.
; The last 5 bytes of each 16-byte table are unaccessed.

star_count:
        ; Number of stars, minus one.
        db 10

star_initial_x:
        db  19,  80,  84, 111, 158, 171, 208, 239
        db   6,  90,  95, 214, 202,  19,  25,  37

star_initial_y:
        db  85, 223,  81,  33,  61, 154, 125, 136
        db 204, 143, 170,  67, 138, 110, 144, 118

star_y_speeds:
        db 2, 3, 3, 5, 4, 2, 4, 3
        db 2, 2, 3, 4, 3, 2, 7, 6

star_tiles:
        db $af, $ae, $ae, $be, $be, $bf, $af, $bf
        db $bf, $af, $ae, $ae, $bf, $be, $be, $be

        db $0f  ; unaccessed

table48:  ; $dc52 (16 bytes)
        db $40, $48, $40, $48
        db $80, $88, $80, $88
        db $c0, $c8, $c0, $c8
        db $f0, $f8, $f0, $f8

table49:  ; $dc62 (16 bytes)
        db $32, $32, $3a, $3a, $80, $80, $88, $88
        db $68, $68, $70, $70, $b8, $b8, $c0, $c0

table50:  ; $dc72 (16 bytes)
        db $03, $03, $03, $03
        db $05, $05, $05, $05
        db $02, $02, $02, $02
        db $04, $04, $04, $04

table51:  ; $dc82 (16 bytes)
        db $ea, $eb, $fa, $fb, $ec, $ed, $fc, $fd
        db $ea, $eb, $fa, $fb, $ec, $ed, $fc, $fd

table52:
        ; unaccessed ($dc92)
        db $00, $03, $06, $03

        ; $dc96

; -------------------------------------------------------------------------------------------------

wait_vbl:  ; $dc96
        ; Wait for VBlank.
        ; Called by: init

-       bit ppu_status
        bpl -
        rts

; -------------------------------------------------------------------------------------------------

hide_sprites
        ; Hide all sprites by setting their Y positions outside the screen.
        ; Called by: init, nmisub10, nmisub12, nmisub13, nmisub14, nmisub15
        ; nmisub16, nmisub20, nmisub22

        ldx #0
-       lda #245
        sta sprite_page+sprite_y,x
        rept 4
            inx
        endr
        bne -
        rts

; -------------------------------------------------------------------------------------------------
; Unaccessed block ($dcaa)

        lda #%00000000
        sta ppu_ctrl
        sta ppu_mask
        lda #%00000000
        sta ppu_ctrl

        ; clear sound registers
        lda #$00
        ldx #0
-       sta apu_regs,x
        inx
        cpx #15
        bne -

        lda #$c0
        sta apu_counter

        jsr init_palette_copy
        jsr update_palette
        rts

; -------------------------------------------------------------------------------------------------

init_palette_copy
        ; Copy the palette_table array to the palette_copy array.
        ; Args: none
        ; Called by: init, hide_sprites, nmisub6, nmisub8, nmisub10, nmisub12,
        ; nmisub15, game_over_screen, nmisub19

        ldx #0
-       lda palette_table,x
        sta palette_copy,x
        inx
        cpx #32
        bne -
        rts

; -------------------------------------------------------------------------------------------------

clear_palette_copy
        ; Fill the palette_copy array with black.
        ; Args: none
        ; Called by: greets_screen

        ldx #0
-       lda #$0f
        sta palette_copy,x
        inx
        cpx #32
        bne -
        rts

; -------------------------------------------------------------------------------------------------

update_palette
        ; Copy the palette_copy array to the PPU.
        ; Args: none
        ; Called by: init, hide_sprites, nmisub3, nmisub6, nmisub8, nmisub10,
        ; nmisub12, nmisub13, nmisub15, game_over_screen, greets_screen, nmisub19

        set_ppu_addr vram_palette + 0 * 4

        ldx #0
-       lda palette_copy,x
        sta ppu_data
        inx
        cpx #32
        bne -

        reset_ppu_addr
        rts

; -------------------------------------------------------------------------------------------------

delay
        ; Delay for raster effects.
        ; Add #$55 (85) to delay_var1 X times.
        ; Called by: nmisub7, nmisub11, nmisub15, nmisub21

        stx delay_var2
        lda #0
        sta delay_cnt  ; loop counter

delay_loop
        lda delay_var1
        clc
        adc #85
        bcc +
+       sta delay_var1

        inc delay_cnt
        lda delay_cnt
        cmp delay_var2
        bne delay_loop

        rts

; -------------------------------------------------------------------------------------------------
; Unaccessed block ($dd22)

        stx delay_var2
        ldx #0
unaccessed15
        clc
        adc #85
        clc
        nop
        nop
        adc #15
        sbc #15
        inx
        cpx delay_var2
        bne unaccessed15

        rts

        stx delay_var2
        ldy #0
        ldx #0
unaccessed16

        ldy #0
unaccessed17
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
        cpx delay_var2
        bne unaccessed16

        rts

; -------------------------------------------------------------------------------------------------

fade_out_palette
        ; Change each color in the palette_copy array (32 bytes).
        ; Used to fade out the "wAMMA - QUANTUM DISCO BROTHERS" logo.
        ; Called by: nmisub3, nmisub13, nmisub19

        ; How the colors are changed:
        ;     $0x -> $0f (black)
        ;     $1x: no change
        ;     $2x -> $3x
        ;     $3x: no change

        ldy #0
fade_out_palette_loop
        ; take color
        lda palette_copy,y
        sta temp1
        ; copy color brightness (0-3) to X
        and #%00110000
        rept 4
            lsr
        endr
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

; -------------------------------------------------------------------------------------------------

change_background_color
        ; Change background color: #$3f (black) if $e8 < 8, otherwise $e8.

        set_ppu_addr vram_palette + 0 * 4

        lda $e8
        cmp #8
        bcc change_background_black

        lda $e8
        sta ppu_data
        jmp change_background_exit

change_background_black
        write_ppu_data $3f  ; black
change_background_exit
        rts

; -------------------------------------------------------------------------------------------------

update_sixteen_sprites
        ; Update 16 (8 * 2) sprites.
        ; Called by: nmisub13

        ; Input: X, Y, $9a, $a8

        ; Modifies: A, X, Y, $9a, $9c, $a5, $a6, $a7, $a8, loopcnt

        ; Sprite page offsets: $a8 * 4 ... ($a8 + 15) * 4
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

update_sixteen_sprites_loop_outer
        ; counter: loopcnt = 0, 8

        ; 0 -> X, $9a
        ldx #0
        lda #$00
        sta $9a

update_sixteen_sprites_loop_inner
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
        rept 4
            iny
        endr
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

; -------------------------------------------------------------------------------------------------

update_six_sprites
        ; Update 6 (3 * 2) sprites.
        ; Called by: nmisub13

        ; Input: X, Y, $9a, $a8

        ; Sprite page offsets: $a8 * 4 ... ($a8 + 5) * 4
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

update_six_sprites_loop_outer
        ; counter: loopcnt = 0, 8

        ; 0 -> X, $9a
        ldx #0
        lda #$00
        sta $9a

update_six_sprites_loop_inner
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
        rept 4
            iny
        endr
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

; -------------------------------------------------------------------------------------------------

update_eight_sprites
        ; Update 8 (4 * 2) sprites.
        ; Called by: nmisub13

        ; Input: X, Y, $9a, $a8

        ; Sprite page offsets: $a8 * 4 ... ($a8 + 7) * 4
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

update_eight_sprites_loop_outer
        ; counter: loopcnt = 0, 8

        ; 0 -> X, $9a
        ldx #0
        lda #$00
        sta $9a

update_eight_sprites_loop_inner
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
        rept 4
            iny
        endr
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

; -------------------------------------------------------------------------------------------------

        ; Called by: nmisub3

sub15   ldx #0
        ldy #0
        stx $9a
        stx $9b

sub15_loop
        lda table10,y
        cmp #$ff
        bne +

        lda $9b
        clc
        adc #14
        sta $9b
        jmp sub15_1

+       lda #$e1
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

sub15_1
        rept 4
            inx
        endr
        iny
        lda $9a
        clc
        adc #8
        sta $9a
        cpy #22
        bne sub15_loop

        rts

; -------------------------------------------------------------------------------------------------

        ; Called by: nmisub1

sub16   stx $91
        sty $92

        lda $91
        sta ppu_addr
        lda $92
        sta ppu_addr

        ldx #0
        ldy #0
        stx $90

-       ldy $90
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
        cmp #16
        bne -

        lda #0
        sta $90

-       ldy $90
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
        cmp #16
        bne -

        reset_ppu_addr
        rts

; -------------------------------------------------------------------------------------------------

move_stars_up
        ; Move stars (sprites 45-55) up in the first two parts of the demo, i.e.,
        ; subtract constants from the Y positions of sprites 45-55.
        ; Called by: nmisub1, nmisub3

        ; 0  -> $9a
        ; 10 -> X
        lda #$00
        sta $9a
        ldx star_count

        ; X*4 -> Y
-       txa
        asl
        asl
        tay
        ; subtract star_y_speeds,x + 1 from the sprite's Y position
        lda sprite_page + 45 * 4 + sprite_y, y
        clc
        sbc star_y_speeds,x
        sta sprite_page + 45 * 4 + sprite_y, y
        ; loop
        dex
        cpx #255
        bne -

        rts

; -------------------------------------------------------------------------------------------------

        ; Initialize star sprites for first two parts of demo?
        ; Called by: init

        ; 10 -> X
sub18   ldx star_count

        ; X*4 -> Y
-       txa
        asl
        asl
        tay

        lda star_initial_y,x
        sta sprite_page+45*4+sprite_y,y

        lda star_tiles,x
        sta sprite_page+45*4+sprite_tile,y

        lda #%00000011
        sta sprite_page+45*4+sprite_attr,y

        lda star_initial_x,x
        sta sprite_page+45*4+sprite_x,y

        lda star_y_speeds,x
        sta $011e,x

        dex
        cpx #255
        bne -

        rts

; -------------------------------------------------------------------------------------------------

nmisub1
        ; Called by: NMI

        chr_bankswitch 0
        lda $95

        cmp #1
        beq nmisub1_jump_table+1*3
        cmp #2
        beq nmisub1_jump_table+2*3
        cmp #3
        beq nmisub1_jump_table+3*3
        cmp #4
        beq nmisub1_jump_table+4*3
        cmp #5
        beq nmisub1_jump_table+5*3
        cmp #6
        beq nmisub1_jump_table+6*3
        cmp #7
        beq nmisub1_jump_table+7*3
        cmp #8
        beq nmisub1_jump_table+8*3
        cmp #9
        beq nmisub1_01
        cmp #10
        beq nmisub1_jump_table+10*3
        jmp nmisub1_11

nmisub1_01
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
+       inc $96
        inc $96

++      lda #%10000000
        sta ppu_ctrl
        lda #%00011110
        sta ppu_mask

nmisub1_jump_table
        jmp nmisub1_11  ;  0*3
        jmp nmisub1_02  ;  1*3
        jmp nmisub1_03  ;  2*3
        jmp nmisub1_04  ;  3*3
        jmp nmisub1_05  ;  4*3
        jmp nmisub1_06  ;  5*3
        jmp nmisub1_07  ;  6*3
        jmp nmisub1_08  ;  7*3
        jmp nmisub1_09  ;  8*3
        jmp nmisub1_11  ;  9*3 (unaccessed, $e013)
        jmp nmisub1_10  ; 10*3

nmisub1_02
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
        jmp nmisub1_11
+       lda #$00
        sta $96
        jmp nmisub1_11

nmisub1_03
        lda #$00
        sta $96
        jmp nmisub1_11

nmisub1_04
        ; pointer 1 -> ptr1
        lda pointers+1*2+0
        sta ptr1+0
        lda pointers+1*2+1
        sta ptr1+1

        ldx #$20
        ldy #$a0
        jsr sub16
        jmp nmisub1_11

nmisub1_05
        ; pointer 2 -> ptr1
        lda pointers+2*2+0
        sta ptr1+0
        lda pointers+2*2+1
        sta ptr1+1

        ldx #$21
        ldy #$20
        jsr sub16
        jmp nmisub1_11

nmisub1_06
        ; pointer 3 -> ptr1
        lda pointers+3*2+0
        sta ptr1+0
        lda pointers+3*2+1
        sta ptr1+1

        ldx #$21
        ldy #$a0
        jsr sub16
        jmp nmisub1_11

nmisub1_07
        ; pointer 4 -> ptr1
        lda pointers+4*2+0
        sta ptr1+0
        lda pointers+4*2+1
        sta ptr1+1

        ldx #$22
        ldy #$40
        jsr sub16
        jmp nmisub1_11

nmisub1_08
        ; pointer 5 -> ptr1
        lda pointers+5*2+0
        sta ptr1+0
        lda pointers+5*2+1
        sta ptr1+1

        ldx #$22
        ldy #$c0
        jsr sub16
        jmp nmisub1_11

nmisub1_09
        ; pointer 6 -> ptr1
        lda pointers+6*2+0
        sta ptr1+0
        lda pointers+6*2+1
        sta ptr1+1

        ldx #$23
        ldy #$40
        jsr sub16
        jmp nmisub1_11

nmisub1_10
        lda #2  ; 2nd part
        sta demo_part
        lda #0
        sta flag1
        jmp nmisub1_11

nmisub1_11
        jmp sub19

; -------------------------------------------------------------------------------------------------
; Unaccessed block ($e0d3)

        lda #$00
        sta $9a
        lda $96
        cmp #$a0
        bcc +
        jmp unaccessed18
+       ldx $93

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

unaccessed18
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

; -------------------------------------------------------------------------------------------------

        ; Called by: nmisub1

sub19   jsr move_stars_up
        sprite_dma
        rts

; -------------------------------------------------------------------------------------------------

nmisub2
        ; Called by: NMI

        ; clear Name Tables
        ldx #$00
        jsr fill_name_tables

        ldy #$00
        ldy #$00

        ; fill rows 1-8 of Name Table 2 with #$00-#$ff
        set_ppu_addr vram_name_table2+32
        ldx #0
-       stx ppu_data
        inx
        bne -

        reset_ppu_addr

        ; update first and second color in first sprite subpalette
        set_ppu_addr vram_palette+4*4
        write_ppu_data $00  ; dark gray
        write_ppu_data $30  ; white
        reset_ppu_addr

        ; update second and third sprite subpalette
        set_ppu_addr vram_palette+5*4+1
        write_ppu_data $3d  ; light gray
        write_ppu_data $0c  ; dark cyan
        write_ppu_data $3c  ; light cyan
        write_ppu_data $0f  ; black
        write_ppu_data $3c  ; light cyan
        write_ppu_data $0c  ; dark cyan
        write_ppu_data $1a  ; medium-dark green
        reset_ppu_addr

        ; update first background subpalette
        set_ppu_addr vram_palette+0*4
        write_ppu_data $38  ; light yellow
        write_ppu_data $01  ; dark purple
        write_ppu_data $26  ; medium-light red
        write_ppu_data $0f  ; black
        reset_ppu_addr

        lda #1
        sta flag1
        lda #$8e
        sta $012e
        lda #$19
        sta $012f

        lda #%00011110
        sta ppu_mask
        rts

; -------------------------------------------------------------------------------------------------

nmisub3
        ; Called by: NMI

        chr_bankswitch 0
        sprite_dma

        lda #%10010000
        sta ppu_ctrl

        ; update fourth color of first background subpalette
        set_ppu_addr vram_palette+0*4+3
        write_ppu_data $0f  ; black
        reset_ppu_addr

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
+       lda $ac
        cmp #$02
        bne +
        lda $ab
        cmp #$32
        bne +
        jsr sub15
+       lda $ac
        cmp #$01
        bne nmisub3_1
        lda $ab
        cmp #$96
        bne nmisub3_1
        ldx data1

nmisub3_loop1
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
        jmp nmisub3_loop1

+       lda #129
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
        set_ppu_addr vram_palette+0*4+3
        write_ppu_data $30  ; white
        reset_ppu_addr

nmisub3_1
        lda $ac
        cmp #$02
        bne nmisub3_2
        lda $ab
        cmp #$32
        bcc nmisub3_2

        ldx #0
        ldy #0
nmisub3_loop2
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
+       inx
        rept 4
            iny
        endr
        cpx #22
        bne nmisub3_loop2

nmisub3_2
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

+       jsr move_stars_up
        lda #2  ; 2nd part
        sta demo_part
        rts

; -------------------------------------------------------------------------------------------------

nmisub4
        ; Called by: NMI

        lda #$00
        ldx #0
-       sta pulse1_ctrl,x
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
        jsr fill_nt_and_clear_at
        lda #1
        sta flag1
        rts

; -------------------------------------------------------------------------------------------------

nmisub5
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
nmisub5_loop

        ldx #25
-       dex
        bne -

        set_ppu_addr_via_x vram_palette+0*4

        inc $8c
        lda $8c
        cmp #$05
        beq +
        jmp ++
+       inc $89
        lda #$00
        sta $8c
++      inc $89
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
        bne nmisub5_loop

        lda #%00000110
        sta ppu_mask
        lda #%10010000
        sta ppu_ctrl
        rts

; -------------------------------------------------------------------------------------------------

nmisub6
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
        set_ppu_addr vram_palette+3*4
        write_ppu_data $0f  ; black
        reset_ppu_addr

        lda #1
        sta flag1
        lda #$05
        sta ram1
        rts

; -------------------------------------------------------------------------------------------------

nmisub7
        ; Called by: NMI

        chr_bankswitch 1
        lda $0148
        cmp #$00
        beq +
        jmp nmisub7_1
+       dec $8a

        ldx #0
        lda #$00
        sta $89
nmisub7_loop1
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
        bne nmisub7_loop1

        ldx #0
        ldy #0
        lda #$00
        sta $9a

nmisub7_loop2
        ; #$2100 + $9a -> ppu_addr
        lda #$21
        sta ppu_addr
        lda $9a
        sta ppu_addr

        ldy #0
-       lda $0600,x
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
        clc
        adc #32
        sta $9a
        lda $9a
        cmp #$00
        bne nmisub7_loop2

        lda #$01
        sta $0148
        jmp nmisub7_2

nmisub7_1
        dec $8a
        ldx #64
        lda #$00
        sta $89

-       lda $89
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
        bne -

        ldx #$7f
        lda #$00
        sta $9a

nmisub7_loop3
        lda #$22
        sta ppu_addr
        lda $9a
        sta ppu_addr

        ldy #0
-       lda $0600,x
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
        clc
        adc #32
        sta $9a
        lda $9a
        cmp #$00
        bne nmisub7_loop3

        lda #$00
        sta $0148

nmisub7_2
        reset_ppu_addr

        lda #$00
        sta $89

-       ldx #$04
        jsr delay
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

; -------------------------------------------------------------------------------------------------

nmisub8
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
        set_ppu_addr vram_palette+3*4
        write_ppu_data $0f  ; black
        reset_ppu_addr

        lda #1
        sta flag1
        rts

; -------------------------------------------------------------------------------------------------

nmisub9
        ; Called by: NMI

        jsr change_background_color
        chr_bankswitch 1
        dec $8a
        dec $8a

        ldx #0
        lda #0
        sta $89
-       lda $89
        adc $8a
        tay
        lda table19,y
        adc #$46
        sta $0600,x
        inc $89
        inx
        cpx #128
        bne -

        lda $0148
        cmp #$00
        beq +
        jmp nmisub9_1

+       ldx #0
        ldy #0
        lda #$00

        sta $9a
nmisub9_loop1
        ; #$2100 + $9a -> ppu_addr
        lda #$21
        sta ppu_addr
        lda $9a
        sta ppu_addr

        ldy #0
-       lda $0600,x
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
        clc
        adc #32
        sta $9a
        lda $9a
        cmp #$00
        bne nmisub9_loop1

        lda #$01
        sta $0148
        jmp nmisub9_2

nmisub9_1
        ldx #$7f
        lda #$20
        sta $9a

nmisub9_loop2
        lda #$22
        sta ppu_addr
        lda $9a
        sta ppu_addr

        ldy #0
-       lda $0600,x
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
        clc
        adc #32
        sta $9a
        lda $9a
        cmp #$00
        bne nmisub9_loop2

        lda #$00
        sta $0148

nmisub9_2
        reset_ppu_addr

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

; -------------------------------------------------------------------------------------------------

nmisub10
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

; -------------------------------------------------------------------------------------------------

nmisub11
        ; Called by: NMI

        dec $8c
        inc $8b
        lda $8b
        cmp #$02
        bne +

        lda #$00
        sta $8b
        dec $8a

+       lda #%10000100
        sta ppu_ctrl

        ; update first color of first background subpalette
        set_ppu_addr_via_x vram_palette+0*4
        write_ppu_data $0f  ; black
        reset_ppu_addr

        ldx #$ff
        jsr delay
        ldx #$01
        jsr delay

        ; update first color of first background subpalette
        set_ppu_addr_via_x vram_palette+0*4
        write_ppu_data $0f  ; black
        reset_ppu_addr

        lda #$00
        sta $89

        ldy #85
nmisub11_loop

        ldx #25
-       dex
        bne -

        set_ppu_addr_via_x vram_palette+0*4

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
        bne nmisub11_loop

        reset_ppu_addr

        ; update first color of first background subpalette
        set_ppu_addr_via_x vram_palette+0*4
        write_ppu_data $0f  ; black
        reset_ppu_addr
        rts

; -------------------------------------------------------------------------------------------------

nmisub12
        ; Called by: NMI

        ; fill Name Tables with #$ff
        ldx #$ff
        jsr fill_name_tables

        jsr init_palette_copy
        jsr update_palette

        ; update fourth sprite subpalette
        set_ppu_addr vram_palette+7*4
        write_ppu_data $0f  ; black
        write_ppu_data $19  ; medium-dark green
        write_ppu_data $33  ; light purple
        write_ppu_data $30  ; white
        reset_ppu_addr

        set_ppu_addr vram_name_table0

nmisub12_1
        lda #$00
        sta $9e
        lda #$00
        sta $9f
nmisub12_loop1

        ldy #0
nmisub12_loop2

        ldx #0
-       txa
        clc
        adc $9e
        sta ppu_data
        inx
        cpx #8
        bne -

        iny
        cpy #$04
        bne nmisub12_loop2

        lda $9e
        clc
        adc #8
        sta $9e
        lda $9e
        cmp #$40
        bne nmisub12_loop1

        lda #$00
        sta $9e
        inc $9f
        lda $9f
        cmp #$03
        bne nmisub12_loop1

        ldx #0
nmisub12_loop3

        ldy #0
nmisub12_loop4

        ldx #0
-       txa
        clc
        adc $9e
        sta ppu_data
        inx
        cpx #8
        bne -

        iny
        cpy #4
        bne nmisub12_loop4

        lda $9e
        clc
        adc #8
        sta $9e
        cmp #$28
        bne nmisub12_loop3

        lda #$f0  ; unnecessary

        ; write 64 bytes to ppu_data (#$f0-#$f7 eight times)

        ldy #0
nmisub12_loop5

        ldx #$f0
-       stx ppu_data
        inx
        cpx #$f8
        bne -

        iny
        cpy #8
        bne nmisub12_loop5

        reset_ppu_addr

        inc $a0
        lda $a0
        cmp #$02
        bne +
        jmp nmisub12_2

+       set_ppu_addr vram_name_table2

        jmp nmisub12_1

nmisub12_2
        ; clear Attribute Table 0
        set_ppu_addr vram_attr_table0
        ldx #0
-       lda #$00
        sta ppu_data
        inx
        cpx #64
        bne -

        reset_ppu_addr

        ; clear Attribute Table 2
        set_ppu_addr vram_attr_table2
        ldx #0
-       lda #$00
        sta ppu_data
        inx
        cpx #64
        bne -

        reset_ppu_addr

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

; -------------------------------------------------------------------------------------------------

nmisub13
        ; Called by: NMI

        sprite_dma

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

nmisub13_01
        lda #3  ; 9th part
        sta demo_part

        set_ppu_addr vram_palette+0*4

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

+       write_ppu_data $34  ; light purple
        write_ppu_data $24  ; medium-light purple
        write_ppu_data $14  ; medium-dark purple
        write_ppu_data $04  ; dark purple

nmisub13_02
        write_ppu_data $38  ; light yellow
        write_ppu_data $28  ; medium-light yellow
        write_ppu_data $18  ; medium-dark yellow
        write_ppu_data $08  ; dark yellow

nmisub13_03
        write_ppu_data $32  ; light blue
        write_ppu_data $22  ; medium-light blue
        write_ppu_data $12  ; medium-dark blue
        write_ppu_data $02  ; dark blue

nmisub13_04
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
+       inc $a2
        lda #$00
        sta $a1

nmisub13_05
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

nmisub13_jump_table
        jmp nmisub13_15
        jmp nmisub13_07
        jmp nmisub13_08
        jmp nmisub13_09
        jmp nmisub13_10
        jmp nmisub13_11
        jmp nmisub13_12
        jmp nmisub13_13
        jmp nmisub13_14

nmisub13_06
        lda #10  ; 10th part
        sta demo_part
        lda #0
        sta flag1
        jmp nmisub13_16

nmisub13_07
        jsr hide_sprites

        ; draw 8*2 sprites: tiles #$90-#$9f starting from (92, 106), subpalette 3
        ldx #92
        ldy #106
        lda #$90
        sta $9a
        jsr update_sixteen_sprites

        jmp nmisub13_16

nmisub13_08
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

nmisub13_09
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

nmisub13_10
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

nmisub13_11
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

nmisub13_12
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

nmisub13_13
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

nmisub13_14
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

nmisub13_15
        jsr hide_sprites
nmisub13_16
        chr_bankswitch 1

        lda #%10011000
        sta ppu_ctrl
        lda #%00011110
        sta ppu_mask
        rts

; -------------------------------------------------------------------------------------------------

nmisub14
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

        set_ppu_addr vram_name_table0

        ldy #0
nmisub14_loop1

        ; write Y...Y+15
        ldx #0
-       sty ppu_data
        iny
        inx
        cpx #16
        bne -

        ; write 16 * byte #$7f
        ldx #0
-       write_ppu_data $7f
        inx
        cpx #16
        bne -

        cpy #0
        bne nmisub14_loop1

        jsr sub12

        ; write another 7 rows to Name Table 0;
        ; the left half consists of tiles #$00, #$01, ..., #$df
        ; the right half consists of tile #$7f

        ldy #0
nmisub14_loop2

        ; first inner loop
        ldx #0
-       sty ppu_data
        iny
        inx
        cpx #16
        bne -

        ; second inner loop
        ldx #0
-       write_ppu_data $7f
        inx
        cpx #16
        bne -

        cpy #7*32
        bne nmisub14_loop2

        ; write bytes #$e0-#$e4 to Name Table 0, row 29, columns 10-14
        reset_ppu_addr
        set_ppu_addr vram_name_table0+29*32+10
        write_ppu_data $e0
        write_ppu_data $e1
        write_ppu_data $e2
        write_ppu_data $e3
        write_ppu_data $e4
        reset_ppu_addr

        ; update first background subpalette and first sprite subpalette
        set_ppu_addr vram_palette+0*4
        ldx #0
        write_ppu_data $30  ; white
        write_ppu_data $25  ; medium-light red
        write_ppu_data $17  ; medium-dark orange
        write_ppu_data $0f  ; black
        set_ppu_addr vram_palette+4*4+1
        write_ppu_data $02  ; dark blue
        write_ppu_data $12  ; medium-dark blue
        write_ppu_data $22  ; medium-light blue
        reset_ppu_addr

        ; reset H/V scroll
        lda #0
        sta ppu_scroll
        sta ppu_scroll

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

; -------------------------------------------------------------------------------------------------

nmisub15
        ; Called by: NMI

        sprite_dma

        inc $8a
        inc $8b
        ldx #24
        ldy #0
        lda #$00
        sta $9a
        sta $89
        lda $8b

nmisub15_loop1
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
        rept 4
            iny
        endr
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
+       inc $8c
        lda #0
        sta $8d

        ; if $8c = 16 then clear it
++      lda $8c
        cmp #16
        beq +
        jmp ++
+       lda #0
        sta $8c

        ; loop until Y = 96
++      cpy #96
        bne nmisub15_loop1

        ; 24 -> X
        ;  0 -> $9a, $89
        ; $8c -= 1
        ldx #24
        lda #$00
        sta $9a
        sta $89
        dec $8c

nmisub15_loop2
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
        rept 4
            iny
        endr
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
+       lda #0
        sta $8c

        ; loop until Y = 192
++      cpy #192
        bne nmisub15_loop2

        chr_bankswitch 3

        lda #%10001000
        sta ppu_ctrl

        ldx #$ff
        jsr delay
        jsr delay
        ldx #$30
        jsr delay
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

+       lda #$20
        sta $014a
        lda #$21
        sta $014b
        lda #$00
        sta $0149

nmisub15_exit
        rts

; -------------------------------------------------------------------------------------------------
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

        set_ppu_addr vram_name_table0+8*32+10

        ldx #$50
        ldy #0
unaccessed19
        stx ppu_data
        inx
        iny
        cpy #12
        bne unaccessed19

        reset_ppu_addr
        set_ppu_addr vram_name_table0+9*32+10

        ldy #0
        ldx #$5c
unaccessed20
        stx ppu_data
        inx
        iny
        cpy #12
        bne unaccessed20

        reset_ppu_addr
        set_ppu_addr vram_name_table0+10*32+10

        ldy #0
        ldx #$68
unaccessed21
        stx ppu_data
        inx
        iny
        cpy #12
        bne unaccessed21

        reset_ppu_addr

        lda #1
        sta flag1
        lda #$00
        sta $8f
        sta $89
        lda #$00
        sta $8a

        set_ppu_addr vram_palette+6*4+2
        write_ppu_data $00
        write_ppu_data $10
        reset_ppu_addr

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

        set_ppu_addr vram_palette+4*4
        write_ppu_data $0f
        write_ppu_data $0f
        write_ppu_data $0f
        write_ppu_data $0f
        reset_ppu_addr

        set_ppu_addr vram_palette+0*4
        write_ppu_data $0f
        write_ppu_data $30
        write_ppu_data $10
        write_ppu_data $00
        reset_ppu_addr

unaccessed22
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
+       lda #$00
        sta $8a
        inc $8f
        lda $8f
        cmp #$eb
        beq +
        jmp ++
+       lda #0
        sta flag1
        lda #7
        sta demo_part

++      set_ppu_addr vram_name_table0+27*32+1

        ldx #0
unaccessed23
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

        reset_ppu_addr

unaccessed24
        chr_bankswitch 2
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

        sprite_dma

        ldx #$ff
        jsr delay
        jsr delay
        jsr delay
        ldx #$1e
        jsr delay
        ldx #$d0
        jsr delay

        lda #%00000000
        sta ppu_ctrl

        chr_bankswitch 0

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
unaccessed25
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

+       inc $013a
        lda $013a
        cmp #$06
        bne +
        inc $0139
        inc $0139
        lda #$00
        sta $013a
+       inc $0138
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

+       lda #%10001000
        sta ppu_ctrl
        lda #%00011000
        sta ppu_mask
        rts

; -------------------------------------------------------------------------------------------------

nmisub16
        ; Called by: NMI

        jsr hide_sprites
        ldy #$aa
        jsr fill_attribute_tables
        lda #$1a
        sta $9a
        ldx #$60

nmisub16_loop1
        ; #$2100 + $9a -> ppu_addr
        lda #$21
        sta ppu_addr
        lda $9a
        sta ppu_addr

        ldy #0
-       stx ppu_data
        inx
        iny
        cpy #3
        bne -

        reset_ppu_addr

        lda $9a
        clc
        adc #32
        sta $9a
        lda $9a
        cmp #$1a
        bne nmisub16_loop1

        lda #$08
        sta $9a
        ldx #$80

nmisub16_loop2
        lda #$22
        sta ppu_addr
        lda $9a
        sta ppu_addr

        ldy #0
-       stx ppu_data
        inx
        iny
        cpy #3
        bne -

        reset_ppu_addr

        lda $9a
        clc
        adc #32
        sta $9a
        lda $9a
        cmp #$68
        bne nmisub16_loop2

        ; update all sprite subpalettes
        set_ppu_addr vram_palette+4*4
        write_ppu_data $0f  ; black
        write_ppu_data $01  ; dark blue
        write_ppu_data $1c  ; medium-dark cyan
        write_ppu_data $30  ; white
        write_ppu_data $0f  ; black
        write_ppu_data $00  ; dark gray
        write_ppu_data $10  ; light gray
        write_ppu_data $20  ; white
        write_ppu_data $0f  ; black
        write_ppu_data $19  ; medium-light green
        write_ppu_data $26  ; medium-light red
        write_ppu_data $30  ; white
        write_ppu_data $22  ; medium-light blue
        write_ppu_data $16  ; medium-dark red
        write_ppu_data $27  ; medium-light orange
        write_ppu_data $18  ; medium-dark yellow
        reset_ppu_addr

        ; update first background subpalette
        set_ppu_addr vram_palette+0*4
        write_ppu_data $0f  ; black
        write_ppu_data $20  ; white
        write_ppu_data $10  ; light gray
        write_ppu_data $00  ; dark gray
        reset_ppu_addr

        ldx data3
-       lda table31,x
        sta $0104,x
        lda table32,x
        sta $0108,x
        dex
        cpx #255
        bne -

        ldx data5
-       lda #$00
        sta $0112,x
        lda #$f0
        sta $0116,x
        dex
        cpx #$ff
        bne -

        ldx data7
nmisub16_loop3
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
        bne nmisub16_loop3

        lda #$7a
        sta $0111
        lda #$0a
        sta $0110

        ldx data4
nmisub16_loop4
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
        jmp nmisub16_loop4

+       lda #$00
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

; -------------------------------------------------------------------------------------------------

nmisub17
        ; Called by: NMI

        sprite_dma

        inc $0100
        ldx $0100
        lda table19,x
        adc #$7a
        sta $0111
        lda table20,x
        adc #15
        sta $0110
        chr_bankswitch 2
        ldx data3

nmisub17_loop1
        dec $0104,x
        lda $0104,x
        cmp #$00
        bne nmisub17_2
        lda $0108,x
        cmp table33,x
        beq +
        inc $0108,x
        jmp nmisub17_1
+       lda table32,x
        sta $0108,x
nmisub17_1
        lda table31,x
        sta $0104,x
nmisub17_2
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
nmisub17_loop2
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

+       lda $0100
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

+       ldx $0102
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

nmisub17_3
        ldx data5
nmisub17_loop3
        lda $0116,x
        cmp #$f0
        beq nmisub17_4
        lda $0112,x
        clc
        sbc $011a,x
        bcc +
        sta $0112,x
        jmp nmisub17_4
+       lda #$f0
        sta $0116,x
nmisub17_4
        dex
        cpx #255
        bne nmisub17_loop3

        ldx data5
nmisub17_loop4
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
nmisub17_loop5
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

        set_ppu_scroll 0, 50
        rts

; -------------------------------------------------------------------------------------------------

game_over_screen
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

        set_ppu_addr vram_name_table0+14*32

        ldx #0
-       lda game_over,x
        clc
        sbc #16
        sta ppu_data
        inx
        cpx #96
        bne -

        lda #%00000010
        sta ppu_ctrl
        lda #%00000000
        sta ppu_mask
        rts

; -------------------------------------------------------------------------------------------------

nmisub18
        ; Called by: NMI

        set_ppu_scroll 0, 0

        lda #%10010000
        sta ppu_ctrl
        lda #%00001110
        sta ppu_mask
        rts

; -------------------------------------------------------------------------------------------------

greets_screen
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

greets_heading_loop
        ; go to column 9 of row 3-5
        lda #>($2000+3*32+9)
        sta ppu_addr
        lda $9a
        clc
        adc #<($2000+3*32+9)
        sta ppu_addr

        ; copy the row (16 tiles)
        ldy #0
-       stx ppu_data
        inx
        iny
        cpy #16
        bne -

        reset_ppu_addr

        ; move output offset to next row: $9a += 32
        ; loop while less than 3*32
        lda $9a
        clc
        adc #32
        sta $9a
        cmp #3*32
        bne greets_heading_loop

        ; Copy 640 (32*20) bytes of text from an encrypted table to rows 8-27 of
        ; Name Table 0. Subtract 17 from each byte.

        ; go to row 8, column 0 of Name Table 0
        set_ppu_addr vram_name_table0+8*32

        ; copy the first 256 bytes
        ldx #0
-       lda greets+0,x
        clc
        sbc #16
        sta ppu_data
        inx
        bne -

        ; copy another 256 bytes
        ldx #0
-       lda greets+256,x
        clc
        sbc #16
        sta ppu_data
        inx
        bne -

        ; copy another 128 bytes
        ldx #0
-       lda greets+2*256,x
        clc
        sbc #16
        sta ppu_data
        inx
        cpx #128
        bne -

        reset_ppu_addr

        lda #1
        sta flag1
        lda #$e6
        sta $0153
        rts

; -------------------------------------------------------------------------------------------------

nmisub19
        ; Called by: NMI

        chr_bankswitch 2
        lda $0150
        cmp #$00
        bne +
        lda $014f
        cmp #$03
        bne +
        jsr init_palette_copy
        jsr update_palette

        ; update first background subpalette
        set_ppu_addr vram_palette+0*4
        write_ppu_data $0f  ; black
        write_ppu_data $30  ; white
        write_ppu_data $1a  ; medium-dark green
        write_ppu_data $09  ; dark green
        reset_ppu_addr

+       lda #0
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
+       lda $0150
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

+       lda #12  ; 11th part
        sta demo_part

        lda #%10010000
        sta ppu_ctrl
        lda #%00001110
        sta ppu_mask
        rts

; -------------------------------------------------------------------------------------------------

nmisub20
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
        set_ppu_addr vram_palette+0*4
        write_ppu_data $05  ; dark red
        write_ppu_data $25  ; medium-light red
        write_ppu_data $15  ; medium-dark red
        write_ppu_data $30  ; white
        reset_ppu_addr

        lda #$c8
        sta $013d

        set_ppu_scroll 0, 200

        lda #$00
        sta $014c
        lda #1
        sta flag1

        lda #%10000000
        sta ppu_ctrl
        rts

; -------------------------------------------------------------------------------------------------

nmisub21
        ; Called by: NMI

        lda $013c
        cmp #$02
        beq +
        jmp nmisub21_1
+       ldy #$80

nmisub21_loop1
        lda #>(vram_name_table0+8*32+4)
        sta ppu_addr
        lda #<(vram_name_table0+8*32+4)
        clc
        adc $013b
        sta ppu_addr

        ldx #0
-       sty ppu_data
        iny
        inx
        cpx #8
        bne -

        lda $013b
        clc
        adc #32
        sta $013b
        cpy #$c0
        bne nmisub21_loop1

nmisub21_loop2
        lda #>(vram_name_table0+16*32+4)
        sta ppu_addr
        lda #<(vram_name_table0+16*32+4)
        clc
        adc $013b
        sta ppu_addr

        ldx #0
-       sty ppu_data
        iny
        inx
        cpx #8
        bne -

        lda $013b
        clc
        adc #32
        sta $013b
        cpy #$00
        bne nmisub21_loop2

        reset_ppu_addr

        lda #$00
        sta $013b

nmisub21_loop3
        lda #>(vram_name_table0+8*32+20)
        sta ppu_addr
        lda #<(vram_name_table0+8*32+20)
        clc
        adc $013b
        sta ppu_addr

        ldx #0
-       sty ppu_data
        iny
        inx
        cpx #8
        bne -

        lda $013b
        clc
        adc #32
        sta $013b
        cpy #$c0
        bne nmisub21_loop3

nmisub21_loop4
        lda #>(vram_name_table0+16*32+20)
        sta ppu_addr
        lda #<(vram_name_table0+16*32+20)
        clc
        adc $013b
        sta ppu_addr

        ldx #0
-       sty ppu_data
        iny
        inx
        cpx #8
        bne -

        lda $013b
        clc
        adc #32
        sta $013b
        cpy #0
        bne nmisub21_loop4

        reset_ppu_addr

nmisub21_1
        lda $013c
        cmp #$a0
        bcc +
        jmp nmisub21_2

+       lda #$00
        sta ppu_scroll
        lda $013d
        clc
        sbc $013c
        sta ppu_scroll

nmisub21_2
        lda ram1
        chr_bankswitch 2
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
+       lda #$01
        sta $013e

nmisub21_3
        ldx #$00
        ldy #$00
        lda $013e
        cmp #$00
        beq nmisub21_5
        inc $8b
        inc $8a

nmisub21_loop5
        ldx #1
        jsr delay
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

+       lda #%00001110
        sta ppu_mask
        jmp nmisub21_4

++      lda $89
        cmp $9b
        bcs +
        lda #%11101110
        sta ppu_mask

nmisub21_4
        jmp ++

+       lda #%00001110
        sta ppu_mask

++      lda $89
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

nmisub21_5
        lda #%10010000
        sta ppu_ctrl
        lda #%00001110
        sta ppu_mask
        rts

; -------------------------------------------------------------------------------------------------

write_row
        ; Write X to VRAM 32 times.
        ; Called by: nmisub22

        ldy #0
-       stx ppu_data
        iny
        cpy #32
        bne -

        rts

; -------------------------------------------------------------------------------------------------
; Unaccessed block ($f4f9)

unaccessed26
        ldy #0
-       stx ppu_data
        iny
        cpy #32
        bne -
        rts

; -------------------------------------------------------------------------------------------------

nmisub22
        ; Called by: NMI

        ldx #$25
        jsr fill_nt_and_clear_at
        jsr hide_sprites

        lda #%00000000
        sta ppu_ctrl
        sta ppu_mask

        ; write 24 rows of tiles to the start of Name Table 0

        set_ppu_addr vram_name_table0

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

        reset_ppu_addr

        ; update first background subpalette from table18b
        set_ppu_addr vram_palette+0*4
        lda table18b+0
        sta ppu_data
        lda table18b+1
        sta ppu_data
        lda table18b+2
        sta ppu_data
        lda table18b+3
        sta ppu_data
        reset_ppu_addr

        ; update first sprite subpalette from table18c
        set_ppu_addr vram_palette+4*4
        lda table18c+0
        sta ppu_data
        lda table18c+1
        sta ppu_data
        lda table18c+2
        sta ppu_data
        lda table18c+3
        sta ppu_data
        reset_ppu_addr

        ldx data7
nmisub22_loop
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

; -------------------------------------------------------------------------------------------------

nmisub23
        ; Called by: NMI

        inc $0100
        ldx $0100
        lda woman_sprite_x,x
        sta $9a
        lda table22,x
        sta $9b

        sprite_dma

        ldx data7
nmisub23_loop1
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

nmisub23_loop2
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

        chr_bankswitch 0
        inc $8a
        lda $8a
        cmp #$08
        beq +
        jmp nmisub23_2
+       lda #$00
        sta $8a
        inc $8f
        lda $8f
        cmp #$eb
        beq +
        jmp nmisub23_1
+       lda #0
        sta flag1
        lda #7  ; 7th part
        sta demo_part

nmisub23_1
        lda #>(vram_name_table0+19*32+1)
        sta ppu_addr
        lda #<(vram_name_table0+19*32+1)
        sta ppu_addr

        ldx #0
-       txa
        clc
        adc $8f
        tay
        lda table11,y
        clc
        sbc #$36
        sta ppu_data
        inx
        cpx #31
        bne -

        reset_ppu_addr

nmisub23_2
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

; -------------------------------------------------------------------------------------------------

fill_attribute_tables
        ; Fill Attribute Tables 0 and 2 with Y.
        ; Called by: init, nmisub6, nmisub8, nmisub14, nmisub16
        ; game_over_screen, greets_screen, nmisub20

        set_ppu_addr vram_attr_table0

        ldx #64
-       sty ppu_data
        dex
        bne -

        set_ppu_addr vram_attr_table2

        ldx #64
-       sty ppu_data
        dex
        bne -

        reset_ppu_addr
        rts

; -------------------------------------------------------------------------------------------------

fill_attribute_tables_top
        ; Fill top parts (first 32 bytes) of Attribute Tables 0 and 2 with Y.
        ; Called by: nmisub8

        set_ppu_addr vram_attr_table0

        ldx #32
-       sty ppu_data
        dex
        bne -

        set_ppu_addr vram_attr_table2

        ldx #32
-       sty ppu_data
        dex
        bne -

        reset_ppu_addr
        rts

; -------------------------------------------------------------------------------------------------
; Unaccessed block ($f7d0).

        set_ppu_addr vram_attr_table0+4*8

        ldx #32
-       sty ppu_data
        dex
        bne -

        set_ppu_addr vram_attr_table2+4*8

        ldx #32
-       sty ppu_data
        dex
        bne -

        reset_ppu_addr
        rts

; -------------------------------------------------------------------------------------------------

fill_name_tables
        ; Fill Name Tables 0 and 2 with byte X and set flag1.
        ; Called by: nmisub2, nmisub6, nmisub8, nmisub12, nmisub14
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

        set_ppu_addr vram_name_table0

        ldx #0
        ldy #0
-       lda $8e
        sta ppu_data
        sta ppu_data
        sta ppu_data
        sta ppu_data
        inx
        bne -

        set_ppu_addr vram_name_table2

        ldx #0
        ldy #0
-       lda $8e
        sta ppu_data
        sta ppu_data
        sta ppu_data
        sta ppu_data
        inx
        bne -

        lda #1
        sta flag1

        reset_ppu_addr
        rts

; -------------------------------------------------------------------------------------------------

fill_nt_and_clear_at
        ; Fill Name Tables 0, 1 and 2 with byte X.
        ; Clear Attribute Tables 0 and 1.
        ; Called by: init, nmisub4, nmisub10, nmisub22

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
        set_ppu_addr vram_attr_table0
        ldx #0
-       lda #%00000000
        sta ppu_data
        inx
        cpx #64
        bne -

        ; clear Attribute Table 1
        set_ppu_addr vram_attr_table1
        ldx #0
-       lda #%00000000
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

-       lda $8e
        sta ppu_data
        inx
        bne -

-       lda $8e
        sta ppu_data
        inx
        bne -

-       lda $8e
        sta ppu_data
        inx
        bne -

-       lda $8e
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

-       lda $8e
        sta ppu_data
        inx
        bne -

-       lda $8e
        sta ppu_data
        inx
        bne -

-       lda $8e
        sta ppu_data
        inx
        bne -

-       lda $8e
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

-       lda $8e
        sta ppu_data
        inx
        bne -

-       lda $8e
        sta ppu_data
        inx
        bne -

-       lda $8e
        sta ppu_data
        inx
        bne -

-       lda $8e
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

        reset_ppu_addr
        ; reset H/V scroll
        lda #0
        sta ppu_scroll
        sta ppu_scroll

        lda #%00000000
        sta ppu_ctrl
        lda #%00011110
        sta ppu_mask
        rts

; -------------------------------------------------------------------------------------------------

nmi
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

nmi_jump_table
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

; -------------------------------------------------------------------------------------------------

nmi_part1
        ; "Greetings! We come from..."

        lda flag1
        cmp #0
        beq +
        jmp ++
+       lda #1
        sta flag1
++      jsr nmisub1
        jsr sub12
        inc $93
        inc $93
        inc $94
        inc $94
        lda $94
        cmp #$e6
        beq +
        jmp nmi_part1_exit
+       inc $95
        lda #$00
        sta $94
nmi_part1_exit
        jmp nmi_exit

; -------------------------------------------------------------------------------------------------

nmi_part4
        ; horizontal color bars

        lda flag1
        cmp #0
        beq +
        jmp ++
+       jsr nmisub10
++      jsr nmisub11
        jsr sub12
        inc $98
        lda $98
        cmp #$ff
        beq +
        jmp nmi_part4_exit
+       inc $99
        lda $99
        cmp #$03
        beq +
        jmp nmi_part4_exit
+       lda #4
        sta demo_part
        lda #0
        sta flag1
nmi_part4_exit
        jmp nmi_exit

; -------------------------------------------------------------------------------------------------

nmi_part2
        ; "wAMMA - Quantum Disco Brothers"

        lda flag1
        cmp #0
        beq +
        jmp ++
+       jsr nmisub2
++      jsr nmisub3
        jsr sub12
        inc $ab
        lda $ab
        cmp #$ff
        beq +
        jmp nmi_part2_exit
+       inc $ac
        lda $ac
        cmp #$03
        beq +
        jmp nmi_part2_exit
+       lda #11
        sta demo_part
        lda #0
        sta flag1
nmi_part2_exit
        jmp nmi_exit

; -------------------------------------------------------------------------------------------------

nmi_part9
        ; credits

        lda flag1
        cmp #0
        beq +
        jmp ++
+       jsr nmisub12
++      jsr nmisub13
        jsr sub12
        jmp nmi_exit

; -------------------------------------------------------------------------------------------------

nmi_part5
        ; the woman

        lda flag1
        cmp #0
        beq +
        jmp ++
+       jsr nmisub14
++      jsr nmisub15
        jsr sub12
        inc $a9
        lda $a9
        cmp #$ff
        beq +
        jmp nmi_part5_exit
+       inc $aa
        lda $aa
        cmp #$04
        beq +
        jmp nmi_part5_exit
+       lda #5
        sta demo_part
        lda #0
        sta flag1
nmi_part5_exit
        jmp nmi_exit

; -------------------------------------------------------------------------------------------------

nmi_part6
        ; "It is Friday..."

        lda flag1
        cmp #0
        beq +
        jmp ++
+       jsr nmisub22
++      jsr nmisub23
        jsr sub12
        jmp nmi_exit

; -------------------------------------------------------------------------------------------------

nmi_part8
        ; Bowser's spaceship

        lda flag1
        cmp #0
        beq +
        jmp ++
+       jsr nmisub16
++      jsr nmisub17
        jsr sub12
        inc $0135
        lda $0135
        cmp #$ff
        beq +
        jmp nmi_part8_exit
+       inc $0136
        lda $0136
        cmp #$03
        beq +
        jmp nmi_part8_exit
+       lda #3
        sta demo_part
        lda #0
        sta flag1
nmi_part8_exit
        jmp nmi_exit

; -------------------------------------------------------------------------------------------------

nmi_part7
        ; Coca Cola cans

        lda flag1
        cmp #0
        beq +
        jmp ++
+       jsr nmisub20
++      jsr nmisub21
        jsr sub12
        inc $013f
        lda $013f
        cmp #$ff
        beq +
        jmp ++
+       inc $0140
++      lda $0140
        cmp #$03
        bne nmi_part7_exit
        lda $013f
        cmp #$ae
        bne nmi_part7_exit
        lda #6
        sta demo_part
        lda #0
        sta flag1
nmi_part7_exit
        jmp nmi_exit

; -------------------------------------------------------------------------------------------------

nmi_part13
        ; full-screen horizontal color bars after "game over - continue?"

        lda flag1
        cmp #0
        beq +
        jmp ++
+       jsr nmisub4
++      jsr nmisub5
        inc $0141
        lda $0141
        cmp #$ff
        beq +
        jmp $fb3d
+       inc $0142
        lda $0142
        cmp #$0e
        beq +
        jmp nmi_part13_exit
+       lda #0
        sta demo_part
        lda #0
        sta flag1
nmi_part13_exit
        jmp nmi_exit

; -------------------------------------------------------------------------------------------------

nmi_part10
        ; checkered wavy animation

        lda flag1
        cmp #0
        beq +
        jmp ++
+       jsr nmisub6
++      jsr nmisub7
        jsr sub12
        inc $0143
        lda $0143
        cmp #$ff
        beq +
        jmp ++
+       inc $0144
++      lda $0144
        cmp #$02
        bne nmi_part10_exit
        lda $0143
        cmp #$af
        bne nmi_part10_exit
        lda #12
        sta demo_part
        lda #0
        sta flag1
nmi_part10_exit
        jmp nmi_exit

; -------------------------------------------------------------------------------------------------

nmi_part3
        ; red&purple gradient

        lda flag1
        cmp #0
        beq +
        jmp ++
+       jsr nmisub8
++      jsr nmisub9
        jsr sub12
        inc $0145
        lda $0145
        cmp #$ff
        beq +
        jmp nmi_part3_exit
+       inc $0146
        lda $0146
        cmp #$03
        beq +
        jmp nmi_part3_exit
+       lda #1
        sta demo_part
        lda #0
        sta flag1
nmi_part3_exit
        jmp nmi_exit

; -------------------------------------------------------------------------------------------------

nmi_part11
        ; greets

        lda flag1
        cmp #0
        beq +
        jmp ++
+       jsr greets_screen
++      jsr nmisub19
        jsr sub12
        inc $014f
        lda $014f
        cmp #$ff
        beq +
        jmp ++
+       inc $0150
++      lda $0150
        cmp #$03
        bne nmi_part11_exit
        lda $014f
        cmp #$96
        bne nmi_part11_exit
        lda #13
        sta demo_part
        lda #0
        sta flag1
nmi_part11_exit
        jmp nmi_exit

; -------------------------------------------------------------------------------------------------

nmi_part12
        ; "GAME OVER - CONTINUE?"

        lda flag1
        cmp #0
        beq +
        jmp ++
+       jsr game_over_screen
++      jsr nmisub18
        inc $0151
        lda $0151
        cmp #$ff
        beq +
        jmp ++
+       inc $0152
++      lda $0152
        cmp #$0a
        bne nmi_part12_exit
        lda $0151
        cmp #$a0
        bne nmi_part12_exit
        lda #9
        sta demo_part
        lda #0
        sta flag1
nmi_part12_exit
        jmp nmi_exit

; -------------------------------------------------------------------------------------------------

nmi_exit
        rti

; --- IRQ routine (unaccessed) --------------------------------------------------------------------

irq     rti  ; $fc26

; --- Interrupt vectors ---------------------------------------------------------------------------

        pad $fffa, $00
        dw nmi, init, irq
        pad $10000, $ff

; --- CHR ROM -------------------------------------------------------------------------------------

        base $0000
        incbin "chr.bin"  ; not included (see the readme file)
        pad $8000, $ff
