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
    ; note: "unaccessed" = unaccessed except for the initial cleanup
    ram1       equ $00  ; ??
    demo_part  equ $01  ; which part is running (see int.asm)
    temp1      equ $01
    flag1      equ $02  ; flag used in NMI? (seems to always be 0 or 1)
    ptr1       equ $03  ; pointer (2 bytes)
    ; $05-$85: unaccessed
    delay_var1  equ $86
    delay_cnt   equ $87
    delay_var2  equ $88
    text_offset equ $8f
    loopcnt     equ $9b  ; loop counter (may have other uses)
    ; $ad-$c7: unaccessed
    ptr2       equ $c8  ; pointer (2 bytes)
    ptr3       equ $ce  ; pointer (2 bytes)
    ptr4       equ $d0  ; pointer (2 bytes)
    ptr5       equ $d8  ; pointer (2 bytes)
    ptr6       equ $da  ; pointer (2 bytes)
    ; $f0-$fe: unaccessed

    ; other RAM
    ; note: "unaccessed" = unaccessed except for the initial cleanup
    ; $1ac-$1eb: unaccessed
    ; $1ec-$1ff: probably stack
    ; $200-$2ff: unaccessed
    ; $400-$4ff: unaccessed
    sprite_page  equ $0500  ; 256 bytes
    ; $680-$7bf: unaccessed
    palette_copy equ $07c0  ; 32 bytes
    ; $7e0-$7ff: unaccessed

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

macro add _operand
        clc
        adc _operand
endm

macro chr_bankswitch _bank  ; write bank number (0-3) over the same value in PRG ROM
_label  lda #(_bank)
        sta _label + 1
endm

macro iny4
        iny
        iny
        iny
        iny
endm

macro lsr4
        lsr
        lsr
        lsr
        lsr
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

macro sub _operand
        sec
        sbc _operand
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
        add ptr4+0
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
        iny4
        tya
        add #128
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
        sub #1
        bpl +
        lda table2,x
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
        lsr4
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
        bne unacc1

sub5c   lda $0344,x
        bne unacc1  ; never taken
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

unacc1  pha
        and #%00001111
        ldy $033c,x
        jsr sub6
        bmi unacc2
        clc
        adc $0300,x
        jsr sub2
        pla
        lsr4
        clc
        adc $033c,x
        cmp #$20
        bpl unacc3
        sta $033c,x
        rts

unacc2  clc
        adc $0300,x
        jsr sub2
        pla
        lsr4
        clc
        adc $033c,x
        cmp #$20
        bpl unacc3
        sta $033c,x
        rts

unacc3  sub #$40
        sta $033c,x
        rts

; -------------------------------------------------------------------------------------------------

        ; Called by: sub5, sub7

sub6    bmi sub6a
        dey
        bmi sub6b
        ora or_masks,y
        tay
        lda table3,y
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
        lda table3,y
        eor #%11111111
        add #1
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
        lsr4
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
        lsr4
        clc
        adc $0330,x
        cmp #$20
        bpl sub6e
        sta $0330,x
        rts

sub6e   sub #$40
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

        lda notes_lo-1,y
        sta ptr2+0
        lda notes_hi-1,y
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

+       jmp unacc6  ; unaccessed ($8478)

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
        lda notes_hi-1,y
        sta $0308,x
        sta $cb
        lda notes_lo-1,y
        sta $dc,x
        jmp sub3

sub8b   lda $e9,x
        clc
        adc $0328,x
        tay
        lda notes_hi-1,y
        sta $0308,x
        sta $cb
        lda notes_lo-1,y
        sta $dc,x
        jmp sub3

sub8c   lda $e9,x
        clc
        adc $03a4,x
        tay
        lda notes_hi-1,y
        sta $0308,x
        sta $cb
        lda notes_lo-1,y
        sta $dc,x
        jmp sub3

sub8d   lda $e9,x
        clc
        adc $032c,x
        tay
        lda notes_hi-1,y
        sta $0308,x
        sta $cb
        lda notes_lo-1,y
        sta $dc,x
        jmp sub3

sub8e   sta $0300,x
        jmp sub9a

sub8f   sta $d3
        jmp sub9a

; -------------------------------------------------------------------------------------------------
; Unaccessed block ($84f8)

unacc4  sub #1
        sta $d4
        lda $d5
        add #1
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
        beq unacc4  ; never taken

sub9a   lda $035f,x
        cpy #$08
        beq unacc5  ; never taken

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
unacc5  jsr unacc6
        lda $0308,x
        sta $cb
        lda $dc,x
        jmp sub3

sub9b   jmp sub8a

; -------------------------------------------------------------------------------------------------
; Unaccessed block ($855e)

unacc6  lda $035f,x
        beq +
        sta $0398,x
+       sec
        lda $d2
        beq unacc8

unacc7  cmp #1
        beq unacc9
        cmp #2
        beq unacc10
        sbc #3
        bne unacc7

unacc8  ldy $e9,x
        lda notes_lo-1,y
        sta $dc,x
        lda notes_hi-1,y
        sta $0308,x
        rts

unacc9  lda $0398,x
        lsr4
        clc
        adc $e9,x
        tay
        lda notes_lo-1,y
        sta $dc,x
        lda notes_hi-1,y
        sta $0308,x
        rts

unacc10 lda $0398,x
        and #%00001111
        clc
        adc $e9,x
        tay
        lda notes_lo-1,y
        sta $dc,x
        lda notes_hi-1,y
        sta $0308,x
        rts

; -------------------------------------------------------------------------------------------------

        ; Reads indirect_data1 via ptr6
        ; Called by: sub4, sub11

sub10a  lda $031c,x
        sta $e5,x
        lda $03b4,x
        sta $0300,x
        lda table1,x
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
        bmi unacc11
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
        add #1
        sta $0320,x
        jmp sub10d

        ; unaccessed block ($862d)
unacc11 iny
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
        bcs unacc12
        sta $0328,x
        tya
        lsr4
        sta $03a4,x
        lda $cb
        and #%00001111
        sta $032c,x
        jmp sub10e

        ; unaccessed block ($8681)
unacc12 eor #%11111111
        add #1
        sta $0328,x
        tya
        lsr4
        eor #%11111111
        add #1
        sta $03a4,x
        lda $cb
        and #%00001111
        eor #%11111111
        add #1
        sta $032c,x

sub10e  lda table1,x
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

        lda table1,x
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
        lda notes_lo-1,y
        sta $dc,x
        lda notes_hi-1,y

sub10_07
        sta $0308,x
        lda table1,x
        ora $ef
        sta $ef

sub10_08
        dex
        bmi +
        jmp sub10c
+       jmp sub11_16

sub10_09
        lda table2,x
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
        add ptr4+0
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
        add #2
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
        lsr4
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
        lsr4
        add #1
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
        lsr4
        iny
        add #1
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
        lsr4
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
        lda table2,x
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
unacc13 dex
        bne unacc13
        dey
        bne unacc13

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

        ; unaccessed ($8925)
        dec $ff
        bpl sub12_skip
        lda #$05
        sta $ff
        jmp unacc14

sub12_skip
        jmp sub4

unacc14 rts  ; $8933

; -------------------------------------------------------------------------------------------------

        ; Called by: init

sub13   ldy #$ff
        dex
        beq +
        ldy #$05  ; unaccessed ($8939)
+       sty $ff
        asl
        tay

        lda ptr_hi,y
        tax
        lda ptr_lo,y
        jsr sub1  ; A = pointer low, X = pointer high
        rts

; --- Lots of data --------------------------------------------------------------------------------

        ; unaccessed ($894a)
        hex c0 00 ff fe fd fc fb fa f9 f8 f7 f6 f5 f4 f3 f2 f1

apu_reg_offsets
        ; read by: sub2, sub3, sub11
        db 0, 4, 8, 12

table1  db 1, 2, 4, 8  ; read by: sub10

table2  db 254, 253, 251, 247  ; read by: sub4, sub10, sub11

or_masks
        ; $8967 (some bytes unaccessed; read by sub6)
        hex 00 10 20 30 40 50 60 70 80 90 a0 b0 c0 d0 e0 f0
        hex e0 d0 c0 b0 a0 90 80 70 60 50 40 30 20 10 00

        ; $8986 (most bytes unaccessed)
        ; read by: sub6
        ; Math stuff? (On each line, the numbers increase linearly.)
table3  db  0,  0,  0,  1,  1,  1,  2,  2,  3,  3,  3,  4,  4,  4,  5,  5  ; value ~= index/4
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
        ; Disregarding the first nine values, each value equals approximately 0.944 times the
        ; previous value.
        ; Note frequencies?
        ; read by: sub7, sub8, sub10
notes_lo
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
notes_hi
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

        ; read by: sub13
ptr_lo  db <indirect_data1
ptr_hi  db >indirect_data1

        ; unaccessed ($8b48)
        hex 8d a0 8d a0 8d a0 8d a0 8d a0 8d a0 8d a0 8d a0
        hex 8d a0 8d a0 8d a0 8d a0 8d a0 8d a0 8d a0 8d a0

indirect_data1
        ; $8b68-$8dbf (600 bytes)
        ; read (via pointer_lo and pointer_hi) by: sub01, sub10, sub11
        ; Some bytes unaccessed.
        hex 20 10 00 05 3a 10 00 3c 15 1c 0c 0a 01 f9 12 00
        hex 90 00 00 00 02 5f 01 00 50 00 00 00 09 f5 00 00
        hex 90 00 00 00 06 fe 00 00 10 00 00 00 20 f8 00 14
        hex 10 00 00 00 08 b4 0a 37 10 00 00 00 08 b4 00 47
        hex 10 00 00 00 3f 91 00 47 d0 00 f4 00 31 bb 00 00
        hex d0 00 00 00 32 f0 00 00 90 00 c1 00 19 92 00 00
        hex 50 00 a1 00 0c 60 00 00 50 00 91 00 0e 84 00 00
        hex 10 00 00 00 09 b4 00 73 10 00 00 00 3c 81 00 73
        hex 10 00 00 00 00 00 00 00 10 00 00 00 00 00 00 00
        hex 88 82 02 00 09 01 01 00 48 00 00 00 69 00 00 00
        hex 48 00 00 00 c9 00 00 00 88 00 00 00 a9 00 00 00
        hex 88 00 00 00 09 02 00 00 aa 01 00 00 ca 01 00 00
        hex aa 01 00 00 eb 01 00 00 00 00 00 00 00 00 00 00
        hex 00 00 00 00 27 04 00 00 02 08 00 00 03 08 00 00
        hex 04 08 00 00 26 08 00 00 05 08 00 00 03 08 00 00
        hex 04 08 00 00 ee 14 00 00 4c 8e 00 00 6d 8e 00 00
        hex 4f 8e 00 00 b0 12 02 00 48 00 00 00 69 00 00 00
        hex 48 00 00 00 c9 00 00 00 88 00 00 00 a9 00 00 00
        hex 88 00 00 00 09 02 00 00 aa 99 01 00 ca 9d 01 00
        hex aa 9d 00 00 eb 21 02 00 4f 26 00 00 70 26 00 00
        hex 4f 26 00 00 70 26 00 00 51 26 00 00 72 26 00 00
        hex 51 26 00 00 32 2b 00 00 ca 02 00 00 ea 02 00 00
        hex ca 02 00 00 0a 03 00 00 53 9b 00 00 53 9f 03 00
        hex 53 9f 03 00 53 1f 03 00 74 af 04 00 08 00 00 00
        hex 10 02 58 02 ab 02 14 03 73 03 d5 03 29 04 81 04
        hex c9 04 20 05 70 05 bd 05 16 06 5d 06 aa 06 fa 06
        hex 3f 07 89 07 f1 07 4a 08 85 08 bd 08 fd 08 3a 09
        hex 78 09 b3 09 09 0a 54 0a 91 0a da 0a 00 00 00 00
        hex 00 00 00 00 05 0b 4c 0b 96 0b e8 0b 00 00 3b 0c
        hex 88 0c d9 0c ea 0c 2f 0d 8c 0d ca 0d f7 0d 46 0e
        hex 61 0e 96 0e ee 0e 4b 0f c6 0f 35 10 a8 10 1d 11
        hex 75 11 c7 11 1c 12 99 12 13 13 54 13 aa 13 eb 13
        hex 21 14 4e 14 97 14 c6 14 e9 14 00 00 00 00 00 00
        hex 00 3e 03 00 01 13 00 13 03 01 03 00 03 01 00 03
        hex 03 01 03 00 01 13 00 03 03 01 03 01 03 0d 00 03
        hex 03 01 16 61 11 16 61 16 61 11 19 61 11 11 1d 61
        hex 1d 11 1c 61 1b 61 11 1b 61 1f 21 12 61 1b 61 11
        hex 1b 61 0f 12 1b 14 61 01

        ; unaccessed ($8dc0)
        hex 00 3e 03 00 01 13 00 13 03 01 03 00 03 01 00 03
        hex 03 01 03 00 01 13 00 03 03 01 03 01 f3 37 77 37
        hex 07 03 16 61 11 16 61 16 61 11 19 61 11 11 1d 61
        hex 1d 11 1c 61 1b 61 11 1b 61 1b 11 19 61 1b 61 11
        hex 7b 22 37 af 27 37 1b 27 72 23 77 13 7b 23 72 27
        hex 37 2e 07 00 3f 33 4f 13 13 03 00 03 0f 3f 03 f3
        hex 00 ff 13 03 13 03 0f 03 0f 03 13 13 03 00 00 4c
        hex 44 01 1f 0f 13 25 29 97 29 49 a3 24 9c 61 2e 69
        hex 31 91 2e 39 91 1c 20 9e 1c 60 91 2e 39 94 35 39
        hex 20 34 c9 10 35 c9 10 35 69 31 93 31 69 31 93 31
        hex c9 10 33 29 9e 1c 30 91 30 69 21 9c 61 2e 29 04
        hex 22 62 21 9e 2c 60 21 99 3c 20 9c 61 00 3f 03 1f
        hex 13 00 03 31 0f 01 03 13 03 13 03 13 03 01 f3 44
        hex 44 44 00 03 13 03 13 03 13 13 03 13 03 13 2e 29
        hex 99 1c 60 21 9e 61 31 69 21 9c 2e 39 30 61 30 29
        hex 9c 61 30 29 9c 61 30 29 9e 61 2c 69 21 9c 2e 39
        hex 03 33 33 33 2c 29 9b 61 2c 29 9b 61 27 29 92 61
        hex 27 69 21 99 2b 69 21 9e 2c 69 01 00 3f 33 33 10
        hex 13 00 03 01 03 01 13 03 01 f3 00 03 03 cf 44 44
        hex 44 ff 00 0f 0f cf 44 44 34 4f 10 03 13 2e 39 91
        hex 2e 29 99 61 2e 69 31 93 61 35 69 31 98 61 3a 69
        hex 31 9c 3d 39 10 3c 39 9a 14 c8 20 31 10 11 11 31
        hex ac 1c 30 ad 1c 30 ac 1c 30 aa 1c 20 80 2c 10 20
        hex 11 11 21 95 27 39 20 63 21 99 2c 69 01 00 3f 03
        hex 13 03 01 03 00 03 01 00 03 01 f3 14 13 03 13 03
        hex 01 03 01 03 13 13 f3 44 44 44 44 00 00 03 13 2e
        hex 29 99 61 2e 69 31 91 2e 69 31 95 61 33 39 95 23
        hex 30 61 35 69 31 93 31 69 31 93 61 33 69 31 91 30
        hex 69 21 9c 61 2c 29 9e 03 34 33 33 33 23 99 2c 69
        hex 01 00 3f 03 01 13 00 f3 1c 03 01 03 01 03 01 03
        hex 13 03 01 f3 44 44 44 44 44 44 00 03 13 03 13 33
        hex 13 03 13 2e 69 21 9e 61 2e 39 91 13 35 15 61 2e
        hex 69 31 90 61 30 69 31 90 2e 69 21 9c 61 2c 29 9e
        hex 03 33 33 33 33 33 33 13 ab 22 6a 21 a7 1b 6a 21
        hex a7 2e 3a a3 61 29 29 9c 61 00 3f 03 00 01 13 00
        hex 03 03 01 03 00 03 01 00 03 03 13 03 00 01 03 01
        hex 03 03 01 03 00 00 13 00 13 03 13 16 61 11 16 61
        hex 16 11 19 61 11 11 1d 61 1d 11 1c 61 61 11 1b 61
        hex 1b 61 11 1f 22 61 21 17 27 69 21 97 61 1d 29 90
        hex 61 00 3e 03 10 03 13 00 13 13 03 01 13 03 01 03
        hex 13 03 01 03 10 03 13 00 13 03 13 00 13 03 0d f3
        hex 04 03 01 0f 61 11 1b 19 61 11 14 61 16 61 11 19
        hex 61 16 61 01 1f 61 0d 01 1f 61 12 61 01 1f 61 1b
        hex 11 19 61 14 61 11 16 19 61 11 19 61 14 61 f1 02
        hex 15 11 16 43 30 19 61 01 00 3f 03 10 03 13 00 13
        hex 03 13 00 13 03 01 03 03 03 01 03 00 03 01 03 00
        hex 03 01 03 00 03 0d 03 13 13 13 0f 61 11 1b 19 61
        hex 11 14 61 16 11 19 61 16 61 01 1f 61 0d 01 1f 12
        hex 61 11 17 23 61 11 16 22 61 11 12 1e 61 f1 02 0d
        hex 01 1d 61 19 61 11 19 61 00 3e 03 00 03 13 03 13
        hex 03 13 03 03 03 03 03 00 03 13 03 00 03 03 03 00
        hex 03 01 03 00 03 0d 03 00 03 01 17 21 5f 17 61 21
        hex 13 1e 61 21 5f 23 61 11 16 2e 24 12 61 24 4e 1e
        hex 21 4e 61 0f 11 1b 27 14 11 1d 61 11 12 1e 61 f1
        hex 02 16 11 16 61 00 3f 03 00 03 13 03 13 03 13 03
        hex 03 03 01 03 01 03 13 cf 44 44 44 44 01 03 00 03
        hex 00 0f 1f 0f 13 03 13 17 21 5f 17 61 21 13 1e 61
        hex 11 17 23 61 11 16 2e 24 12 61 2e 64 11 1e 2e 64
        hex 11 8b 2c a0 02 aa aa aa aa 61 16 01 1f 0f c1 30
        hex 1b f1 02 61 1a c1 20 19 61 11 18 17 61 01 00 3f
        hex 03 00 01 13 00 13 03 01 03 01 03 01 00 00 00 13
        hex 00 13 03 01 03 00 03 00 03 00 03 01 03 00 03 1f
        hex 19 61 11 19 61 16 61 11 19 61 1b 61 11 1b 61 27
        hex 61 01 1f 61 16 61 11 15 14 11 12 1e 61 11 14 20
        hex 11 18 2c 60 01 00 3e 03 00 03 13 00 13 03 01 03
        hex 01 03 01 00 00 00 13 00 13 03 01 03 00 03 01 03
        hex 33 03 13 f3 04 03 01 19 61 11 19 61 11 16 61 19
        hex 61 11 1b 61 1b 61 21 17 61 0f 61 11 12 61 14 11
        hex 16 61 1b 21 17 61 01 1f 16 61 11 1d 1e 31 30 13
        hex 1b 61 00 3f 03 0f 03 1f f3 04 03 1f 03 00 03 00
        hex 00 01 03 01 f3 04 00 00 00 00 00 00 00 00 00 00
        hex 4f 57 57 57 2e 29 99 1c 25 9e 22 c9 15 61 2e 39
        hex 91 33 30 2e 39 91 1c 60 31 90 2c 69 21 99 61 2c
        hex 29 9e 33 30 0d 18 50 11 89 61 11 20 18 61 21 85
        hex 61 11 00 3e 03 00 01 13 00 13 03 01 03 01 03 01
        hex 00 00 00 13 00 13 03 01 03 00 03 01 03 00 03 01
        hex 03 00 03 01 16 61 11 16 61 16 61 11 19 61 1b 61
        hex 11 1b 61 27 61 01 1f 61 16 61 11 15 14 61 11 12
        hex 1e 61 11 14 20 61 01 00 3f 03 00 01 13 00 13 03
        hex 01 03 00 03 01 00 00 00 13 00 13 03 01 03 00 03
        hex 01 03 10 03 13 cf 44 44 44 19 61 11 19 61 16 61
        hex 11 19 61 1b 11 1b 61 27 61 11 1b 61 16 61 11 15
        hex 14 61 01 1d 61 1b 21 17 61 0f c8 20 0a a3 aa aa
        hex 0a 00 3e 03 03 03 0f 03 00 03 0f 33 00 03 03 00
        hex 0f 03 0f ff ff 13 13 03 0f 03 0f 03 0f 03 0f 03
        hex 00 0f 0f 22 2b b5 27 2b b2 1c 25 b7 27 2b b2 1c
        hex 25 b9 2a 2b b9 27 2b b9 1c 25 b2 27 cb 15 2c c9
        hex 10 2e c9 15 2c c9 20 2e c9 25 2c 69 21 9e 61 2c
        hex 29 9e 1c 35 91 2c c9 15 30 39 91 1c 25 9c 30 c9
        hex 15 2e 29 9c 1c 25 9e 1c 00 00 3e 03 03 03 0f 03
        hex 00 03 00 33 00 03 03 00 00 03 00 00 13 13 13 13
        hex 13 13 13 f3 13 03 01 03 1f 03 0f 22 2b b5 27 2b
        hex b2 1c 20 ba 2c 2b bc 2e 2b bc 2a 2b b7 25 69 31
        hex 91 61 2e 69 21 9c 61 2e 69 21 99 61 2a 69 21 95
        hex 2e c9 15 25 69 21 92 61 2a 29 92 1c 65 21 97 2a
        hex c9 15 00 38 03 00 00 0f 00 00 0f 00 03 00 00 0f
        hex 00 00 03 01 03 00 00 0f 00 00 0f 00 00 0f 00 00
        hex 0f 17 11 17 2c 10 17 1c 15 16 16 c1 20 12 61 01
        hex 1f 0f c1 25 0f c1 20 0f c1 15 0f c1 10 00 1e f3
        hex ff ff 00 00 ff 03 03 03 03 03 03 03 03 03 03 36
        hex 39 91 d3 20 9a d3 30 96 1c 30 91 1c 20 9a 1c 20
        hex 15 1c 20 15 2c 20 15 2f 21 1f 2f 21 1e 2c 21 1a
        hex 25 21 12 1e 01 00 3f 01 00 03 00 00 0f 03 00 0f
        hex 00 03 00 00 00 03 01 03 01 00 03 00 00 03 00 00
        hex 13 03 00 00 13 03 13 61 22 24 4e 2c 20 42 29 cc
        hex 20 29 2c c9 61 33 65 21 57 27 25 57 61 27 25 57
        hex 61 27 25 57 61 00 3e 00 00 03 00 00 03 03 00 03
        hex 00 03 00 00 00 03 0c 03 00 00 00 00 00 0f 07 00
        hex 07 07 00 07 07 00 07 22 24 4e 22 24 c9 29 2c c9
        hex 0f 22 67 25 22 70 25 22 25 22 20 22 20 22 1b 22
        hex 1b 22 00 3c 03 00 00 03 00 00 00 00 00 13 03 01
        hex 03 00 00 00 03 00 01 13 00 00 00 13 03 01 13 1f
        hex 03 00 03 27 24 47 31 65 31 51 61 33 2c c7 61 27
        hex 64 31 51 61 31 65 31 51 61 33 c4 10 61 33 3c c3
        hex 00 3f 03 00 00 03 00 00 00 00 00 13 03 01 03 00
        hex 00 00 03 00 03 00 03 00 03 00 03 00 03 00 03 00
        hex 13 13 27 24 47 31 65 31 51 61 33 2c 5f 3b 25 c7
        hex 33 2c 5a 36 25 55 31 65 31 51 61 00 3d 03 03 03
        hex 01 03 01 03 0f f3 14 03 0f 03 10 03 03 0f 03 03
        hex 00 0f 00 0f 0f 00 0f 00 13 03 00 13 25 29 47 27
        hex 69 21 9a 61 27 29 9a 1c 20 9d 2e 39 30 63 31 91
        hex 2e c9 10 36 69 31 95 31 39 95 1c 20 9e 27 34 96
        hex 1c 30 95 1c 30 91 1c 20 9e 1c 20 47 61 27 24 47
        hex 61 00 3f 03 00 f3 04 03 01 03 01 03 00 03 01 03
        hex 01 03 03 0f 03 00 00 00 00 00 00 00 03 01 13 33
        hex 03 33 13 27 24 95 27 39 30 23 9a 61 2c 69 21 9e
        hex 31 69 31 96 61 35 39 91 35 c9 10 33 29 5a 61 2a
        hex 65 21 a5 2c 3a a1 25 2a ac 31 6a 01 00 3e 03 00
        hex 00 03 00 00 00 00 00 00 00 13 03 00 03 00 03 01
        hex 00 13 03 00 00 13 03 00 13 00 33 00 03 01 27 24
        hex 47 27 6c 31 51 25 25 5f 61 2f 65 21 c7 27 6c 21
        hex 5a 2a 65 21 45 20 29 92 61 00 3e 00 00 03 01 00
        hex 00 0f 01 03 01 03 01 00 03 01 1f 03 00 00 00 00
        hex 00 00 ff 0f 07 00 07 07 00 07 07 2e 6c 21 c2 2c
        hex 60 21 c9 61 29 6c 21 c9 61 29 cc 10 61 27 26 27
        hex 1c 20 27 2c 20 27 72 20 27 22 22 22 22 12 2d 12
        hex 2d 02 00 3f 00 00 00 00 00 00 00 00 00 00 00 00
        hex 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
        hex 00 1f 13 13 25 c5 20 61 31 65 31 51 61 00 3f 03
        hex 1f 03 01 03 03 03 01 03 00 4c 03 00 01 03 01 03
        hex 00 03 00 00 00 03 00 00 13 03 00 00 13 03 13 33
        hex 29 9f 1c 60 31 96 61 36 39 95 33 69 31 95 11 10
        hex 31 69 21 9e 61 33 29 c7 27 2c 47 61 27 24 47 61
        hex 33 24 47 61 00 3f 03 1f 03 01 03 03 03 01 03 00
        hex 4c 03 00 1f 03 0f 03 00 00 00 00 00 00 00 00 13
        hex 03 13 00 03 01 13 33 29 9f 1c 60 31 96 61 36 39
        hex 95 33 69 31 95 11 10 3a 39 95 1c 60 31 95 3a c9
        hex 10 33 29 47 61 27 24 47 61 33 64 31 43 61 00 3f
        hex 03 1f 03 1f 03 00 03 00 f3 04 00 03 00 00 03 00
        hex 03 00 1f 1f 00 13 03 00 f3 44 00 00 4f 44 44 44
        hex 33 29 9f 1c 60 31 96 33 c9 10 61 36 39 93 36 39
        hex 98 13 30 35 39 91 33 29 c7 2c 60 21 c7 3c 60 21
        hex c7 61 2e 29 95 27 39 10 33 0d 18 58 11 11 11 01
        hex 00 3e 00 f3 14 03 01 00 03 01 03 00 03 01 03 00
        hex 13 03 01 0f f3 44 00 00 00 00 00 ff 0f 07 07 07
        hex 07 07 25 29 97 13 30 61 2a 69 21 9c 61 2e 39 91
        hex 61 36 39 95 61 31 69 31 95 1c 30 91 33 39 10 33
        hex 25 c2 10 25 c2 20 25 22 70 25 22 22 22 22 22 1d
        hex 22 1d 22 00 3e 03 00 00 13 00 00 13 00 03 00 03
        hex 01 00 0f 00 13 00 00 1f 00 00 00 1f 00 03 0c 0f
        hex 0d 0f 0c 0f 0d 25 25 55 61 25 65 21 c7 27 6c 21
        hex c7 1c 20 c7 61 27 cc 20 61 27 cc 10 61 2a f5 02
        hex 2a f5 04 61 0f 22 5c 0f f4 02 2c f5 04 61 0f 02
        hex 00 3e 03 00 00 13 00 00 13 00 03 00 03 01 00 0f
        hex 00 13 00 00 1f 00 00 00 0f 01 03 0d 1f 1f 0f 0d
        hex 0f 0d 25 25 55 61 25 65 21 c7 27 6c 21 c7 1c 25
        hex c7 61 27 cc 20 61 27 cc 10 61 25 65 f1 02 25 f5
        hex 04 61 25 f5 02 61 27 f4 04 61 0f 22 c7 0f 64 f1
        hex 02 00 0c 03 00 00 0f 00 00 0f 27 24 47 2c 25 47
        hex 2c 00 00 3f 03 00 00 13 00 00 13 00 03 00 03 01
        hex 00 00 00 03 01 00 0f 00 00 00 0f 00 03 01 03 01
        hex 03 1f 0f 13 25 25 55 61 25 65 21 c7 27 6c 21 c7
        hex 61 27 cc 20 27 cc 10 25 65 21 55 61 27 2c 27 2c
        hex 60 21 27 3c 20 27 61 00 3e 13 f3 04 03 01 00 03
        hex 01 03 10 03 1f 03 10 13 03 30 1f 03 01 03 00 03
        hex 0f 03 0f 03 0f 03 0f 03 0f 2a 69 21 95 27 39 20
        hex 23 9a 61 2c 69 21 9e 61 2c 29 9e 1c 60 21 9a 61
        hex 29 69 21 9a 2a 29 97 1c 60 21 99 61 25 29 92 25
        hex c9 10 27 29 92 1c 20 99 27 c9 10 2a 29 99 1c 20
        hex 9e 2a c9 10 00 3f 00 00 03 13 00 00 03 01 f3 00
        hex 03 01 03 10 13 03 00 00 00 00 01 00 00 00 00 00
        hex 00 00 00 13 03 13 2f 29 9a 61 27 69 21 9f 31 39
        hex 30 2f 69 21 9e 61 2f 69 21 9e 61 25 69 21 97 29
        hex 69 01 00 20 00 00 03 13 00 00 03 01 f3 00 03 01
        hex 03 1f 03 1f 03 2f 29 9a 61 27 69 21 9f 31 39 30
        hex 2f 69 21 9e 2f c9 10 61 2a 29 9e 1c 60 21 97 00
        hex 3f 03 00 00 13 00 00 03 01 03 00 03 00 00 0f 00
        hex 13 00 1f 0f 01 00 00 0f 00 03 00 03 00 0f 1f ff
        hex 33 25 25 55 61 25 65 21 c7 27 2c c7 1c 15 cb 61
        hex 27 cc 15 61 27 cc 25 61 27 cc 15 25 25 c7 19 c9
        hex 15 1b c9 20 61 1e c9 25 20 c9 30 22 29 95 00 20
        hex 03 00 00 00 00 00 00 00 03 00 00 03 00 00 03 00
        hex 03 23 26 42 22 24 42 27 0d 00 1e 33 f3 ff 00 00
        hex ff 03 03 03 03 03 03 03 03 03 03 25 2b b2 1e 2b
        hex b5 1c 20 b2 1c 10 be 1c 20 b0 1c 20 b0 2c 20 b0
        hex 29 2b b9 29 2b b9 25 2b b5 22 1b be 19 0b 00 3e
        hex 0f 0c 0c 0c 07 0c 0c 0c 07 0c 0c 0c 07 0c 0c 0c
        hex 07 0c 0c 0c 07 0c 0c 0c 07 0c 0c 07 07 0c 07 0c
        hex 31 22 80 0f f2 04 0f 32 21 f2 02 0f f4 02 31 22
        hex 0f f2 04 0f 32 21 f2 02 0f f4 02 31 22 0f f2 04
        hex 0f 32 21 f2 02 0f f4 02 31 22 0f f2 04 31 22 31
        hex 22 0f 32 21 f2 02 00 3f 0f 0c 0c 0c 07 0c 0c 0c
        hex 07 0c 0c 0c 07 0c 0c 07 07 0c 0c 0c 0c 0c 0c 0c
        hex cf 4c 4c 4c 4c 4c 4c 4c 31 22 80 0f f2 04 0f 32
        hex 21 f2 02 0f f4 02 31 22 0f f2 04 0f 32 21 f2 02
        hex 0f 34 21 32 21 f2 02 0f f4 02 0f f4 02 0f f4 02
        hex 0d f8 04 61 f0 02 f1 04 f1 02 f1 04 f1 02 f1 04
        hex f1 02 01 00 3e 3f 0c 0d 1f 07 1f 0f 0d 37 0c 0f
        hex 0d 07 0f 0f 0d 37 0c 0d 1f 07 0f 0f 0d 37 0d 0f
        hex 0d 07 0f 0f 0d 31 22 80 22 f9 02 61 0f 24 92 0f
        hex 62 31 21 22 92 0f 62 21 95 0f 64 f1 02 31 22 1d
        hex f9 02 29 f9 04 61 0f 32 21 22 99 0f 22 98 0f 64
        hex f1 02 31 22 27 f9 02 61 0f 24 97 0f 62 31 21 22
        hex 9b 0f 22 9e 0f 64 f1 02 31 22 27 69 f1 02 27 f9
        hex 04 61 0f 32 21 22 97 0f 22 90 0f 64 f1 02 00 3e
        hex 3f 0c 1c 1f 0f 1f 1f 0c 0f cd 0f 0d 0c 0c 1f 0c
        hex 0c 0c 1f 0c 0c 0c 1f 0c 0f 0f 00 07 07 00 07 07
        hex 31 22 80 19 f8 02 0f 64 11 89 0f 62 21 85 0f 14
        hex 89 0f 62 11 89 0f 64 f1 02 0f f8 04 61 0f c2 20
        hex 1b f8 04 61 0f f2 04 0f 12 8b 0f 64 f1 02 0f f4
        hex 02 22 f8 04 61 0f f2 04 0f 22 80 0f 64 f1 02 1e
        hex f8 04 31 22 70 2e 22 2e 22 2c 22 2c 22 00 3e 0f
        hex 0c 1c 1f 0f 1f 1f 0c 0f 0d 0f 0d 0c 0c 1f 0c 0c
        hex 0c 1f 0c 0c 0c 0f 0d 0f 1c 0f 1f 0f 0d 0c 0c 19
        hex f8 04 0f f2 04 61 19 f8 02 61 25 f8 04 19 f8 02
        hex 61 19 f8 04 61 0f 12 8b 0f 64 f1 02 1b f8 04 61
        hex 0f f2 04 0f 12 8b 0f 64 f1 02 0f f4 02 22 f8 04
        hex 61 0f f2 04 0f 22 80 0f 64 f1 02 19 f8 04 0f 62
        hex 11 8b 0f 24 87 0f 62 11 8b 0f 64 f1 02 0f f4 02
        hex 00 3e 3f 0c 1c 1f 07 1f 0f 0d 37 0c 0f 0d 07 1f
        hex 0f 0d 37 0c 0d 0f 0d 1f 0f 0d 0f 0d 0c 0c 0c 0c
        hex 0c 0c 31 22 80 22 f9 02 0f 64 21 92 0f 62 31 21
        hex 22 92 0f 62 21 95 0f 64 f1 02 31 22 1d f9 02 29
        hex f9 04 61 0f 32 21 22 99 0f 62 21 98 0f 64 f1 02
        hex 31 22 27 f9 02 61 0f 24 97 0f 62 f1 04 2b f9 02
        hex 61 2e f9 04 61 0f 32 93 0f 64 f1 02 0f f4 02 0f
        hex f4 02 0f f4 02 00 3e 4f 4c 4c 4c 4c 4c 4c 1c 0c
        hex 0c 0c 0c 0c 0c 0c 0c 0c 0c 0c 0c 0c 0c 0c 0c 0c
        hex 0c 0c 0c 0c 0c 0c 0c 31 28 30 f2 02 f2 04 f2 02
        hex f2 04 f2 02 f2 04 f2 02 61 0f f4 02 0f f4 02 0f
        hex f4 02 0f f4 02 0f f4 02 0f f4 02 0f f4 02 0f f4
        hex 02 0f f4 02 0f f4 02 0f f4 02 0f f4 02 00 3e 0c
        hex 0c 0c 0c 0c 0c 0c 0c 0c 0c 0c 0c 0c 0c 0c 0c 0c
        hex 0c 0c 0c 0c 0c 0c 0c 0c 0c 0c 0c 0c 0c 0c 0c 0f
        hex f4 02 0f f4 02 0f f4 02 0f f4 02 0f f4 02 0f f4
        hex 02 0f f4 02 0f f4 02 0f f4 02 0f f4 02 0f f4 02
        hex 0f f4 02 0f f4 02 0f f4 02 0f f4 02 0f f4 02 00
        hex 3e 0c 0c 0c 0c 0c 0c 0c 0c 0c 0c 0c 0c 0c 0c 0c
        hex 0c 0c 0c 0c 0c 0c 0c 0c 0c 0c 0c 0c 0c 0f 0c 07
        hex 07 0f f4 02 0f f4 02 0f f4 02 0f f4 02 0f f4 02
        hex 0f f4 02 0f f4 02 0f f4 02 0f f4 02 0f f4 02 0f
        hex f4 02 0f f4 02 0f f4 02 0f f4 02 25 22 80 0f 22
        hex 25 22 25 02 00 3e 3f 1c 1f 0f 07 1f 0f 1f 07 1f
        hex 0f 1c 37 0c 0f 0d 07 1f 0f 0d 07 0c 0f 0d 37 0c
        hex 0f 0d 37 0c 0f 0d 31 22 80 19 f8 02 61 25 f8 04
        hex 61 25 f8 02 31 22 19 f8 02 61 25 f8 04 19 f8 02
        hex 61 31 22 22 f8 02 61 27 f8 04 0f 62 31 21 22 8a
        hex 0f 22 87 0f 64 f1 02 31 22 27 f8 02 61 2a f8 04
        hex 61 0f 32 21 f2 02 2c f8 04 61 0f 32 21 22 8d 0f
        hex 22 8c 0f 64 f1 02 31 22 2a f8 02 27 f8 04 61 0f
        hex 02 00 3f 3f 1c 1f 0f 07 1f 0f 0d 37 1c 0f 0d 07
        hex 0c 0c 1f 07 1f 0f 0d 03 0d 0f 0d 03 1c 1f 0f 4f
        hex 4c 4c 4c 31 22 80 19 f8 02 61 25 f8 04 61 19 f8
        hex 02 31 22 22 f8 02 61 25 f8 04 61 0f 32 21 22 87
        hex 0f 62 11 8b 0f 64 f1 02 31 22 0f f2 04 33 f8 02
        hex 61 31 22 1b f8 02 61 22 f8 04 61 0f 22 8d 61 0f
        hex 22 8c 0f 64 f1 02 25 f8 02 61 1b f8 04 61 27 f8
        hex 02 19 18 30 f1 02 f1 04 f1 02 01 00 24 0c 00 00
        hex 0c 00 00 0f 0d 1f 3f 0f 1f 0f 1f 1f 0f 1c 0c 0c
        hex 0f f4 03 19 f8 05 61 0f 24 85 0f 63 11 89 0f 64
        hex 81 1d f8 05 29 f8 04 61 1e f8 05 2a f8 04 61 25
        hex f8 05 61 1e f8 04 0f 65 f1 04 0f 05 00 3e 0f 00
        hex 03 0f 0f 00 03 0f 0c 0f 03 0f 0f 00 03 0f 0c 00
        hex 03 0f 0f 00 03 0f 0c 0f 03 0f 0f 00 0f 0f 0e 0f
        hex 64 60 c0 20 3b 0f 64 60 c0 20 0f 64 c0 20 06 06
        hex 2c b0 f3 04 06 3b 2c f0 04 06 06 2c b0 f3 04 06
        hex 06 2c f0 04 06 2c 60 60 c0 20 3b 0f 64 f0 04 3b
        hex 2c 00 00 3e 0f 00 00 00 0f 00 03 03 00 00 03 00
        hex 03 00 03 0f 00 00 03 0f 03 00 03 0f 00 0f 03 0f
        hex 03 00 03 0f 63 0f b4 22 70 0a 0a 0e 2b 06 2b 2c
        hex 60 60 c0 20 2b 06 06 2c 60 c0 20 06 06 2c b0 62
        hex b0 c2 20 00 3e 0c 00 00 00 0c 00 00 00 0c 00 00
        hex 00 0c 00 00 00 0c 00 00 00 0c 00 00 00 0c 00 00
        hex 0c 0c 0f 0f 03 0f f4 04 0f f4 04 0f f4 04 0f f4
        hex 02 0f b4 c3 20 3b 0f b4 03 00 3c 0f 00 00 00 03
        hex 00 00 00 00 00 00 00 03 00 00 00 00 00 00 00 03
        hex 00 00 00 00 00 00 0f 03 00 0f 63 0f b4 b2 b2 b2
        hex c2 20 2b 2b 2c 00 00 3e 03 00 00 03 03 00 03 0f
        hex 00 0f 03 0f 03 00 03 0f 00 00 03 0f 03 00 03 00
        hex 00 0f 03 0f 0f 0f 0f 0f 63 0a 2b 0a 0a 2c a0 c0
        hex 20 0a 0a 2c b0 a2 b0 c2 20 0a 0a 2c b0 a2 a0 c0
        hex 20 0a 0a 2c b0 f2 04 3b 2c b0 f3 04 3b 0f 02 00
        hex 3c 0c 00 00 00 0c 00 00 00 0c 00 00 00 0c 00 00
        hex 00 0c 00 00 00 0c 00 00 00 0c 00 00 00 0c 00 0c
        hex 0f f4 04 0f f4 04 0f f4 04 0f f4 04 0f 04 00 20
        hex 00 00 03 03 03 00 03 0f 00 0f 03 0f 03 00 03 00
        hex 03 0e 0e 2b 0e 0e 2c e0 c0 20 0e 0e 2c b0 e2 30
        hex 0d 00 3c 00 00 03 03 03 00 03 0f 00 0f 03 0f 03
        hex 00 0f 00 00 00 03 00 03 00 03 00 00 0f 03 0f 03
        hex 00 03 0e 0e 2b 0e 0e 2c e0 c0 20 0e 0e 2c b0 e2
        hex c0 20 0e 2b 0e 0e 2c e0 e0 c0 20 2b 0e

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
        sta $0500,x
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

pointers  ; $c0a8
        dw indirect1
        dw indirect2
        dw indirect3
        dw indirect4
        dw indirect5
        dw indirect6
        dw indirect7
        dw indirect8  ; unaccessed ($c0b6)

indirect1
        db $6c, $6c, $6c, $47, $52, $45, $45, $54
        db $49, $4e, $47, $53, $5f, $6c, $6c, $6c
indirect2
        db $6c, $6c, $57, $45, $6c, $43, $4f, $4d
        db $45, $6c, $46, $52, $4f, $4d, $6c, $6c
indirect3
        db $6c, $41, $4e, $6c, $5b, $5e, $42, $49
        db $54, $6c, $57, $4f, $52, $4c, $44, $6c
indirect4
        db $6c, $6c, $42, $52, $49, $4e, $47, $49
        db $4e, $47, $6c, $54, $48, $45, $6c, $6c
indirect5
        db $6c, $6c, $6c, $6c, $47, $49, $46, $54
        db $6c, $4f, $46, $6c, $6c, $6c, $6c, $6c
indirect6
        db $6c, $47, $41, $4c, $41, $43, $54, $49
        db $43, $6c, $44, $49, $53, $43, $4f, $6c
indirect7
        db $47, $45, $54, $6c, $55, $50, $6c, $41
        db $4e, $44, $6c, $44, $41, $4e, $43, $45
indirect8
        ; unaccessed ($c128)
        db $4d, $55, $53, $48, $52, $4f, $4f, $4d
        db $6c, $4d, $41, $4e, $49, $41, $43, $53

sprite_tiles  ; 22 bytes
        hex 3a 3b 3c 3d 3e 3b 3f ff
        hex f1 f2 f3 f4 f5 ff f6 f7
        hex f5 3e f8 f9 f7 f3

it_is_friday_text
        ; 256 bytes; read by nmisub23
        ; text; $37 is subtracted from each value
        hex 5b5b5b5b 5b5b5b5b 5b5b5b5b 5b5b                      ; "              "
        hex 4954 5b 4953 5b 465249444159 5b 4154 5b 4e494e45 5b  ; "IT IS FRIDAY AT NINE "
        hex 504d 5b 414e44 5b 5745 5b 5354494c4c 5b 415245 5b    ; "PM AND WE STILL ARE "
        hex 545259494e47 5b 544f 5b 53594e43 5b 54484953 5b      ; "TRYING TO SYNC THIS "
        hex 4d4f544845524655434b4552 5b5b5b                      ; "MOTHERFUCKER   "
        hex 4752454554494e4753 5b 544f 5b 4e494e54454e444f 5b    ; "GREETINGS TO NINTENDO "
        hex 544543484e4f4c4f47494553 5b 464f52 5b 544845 5b      ; "TECHNOLOGIES FOR THE "
        hex 4c4f56454c59 5b 4841524457415245 5b5b5b              ; "LOVELY HARDWARE   "
        hex 4845434b 5b5b5b                                      ; "HECK   "
        hex 5745 5b 53484f554c44 5b 4245 5b 414c5245414459 5b    ; "WE SHOULD BE ALREADY "
        hex 4452554e4b 5b5b5b                                    ; "DRUNK   "
        hex 4a555354 5b 4c494b45 5b 4f5552 5b                    ; "JUST LIKE OUR "
        hex 4d5553494349414e 5b5b5b                              ; "MUSICIAN   "
        hex 544552564549534554 5b 5049535341504f5353454c4c45 5b  ; "TERVEISET PISSAPOSSELLE "
        hex 656162636466 5b5b5b5b5b5b5b5b5b5b5b5b5b5b            ; "(jjjj)              "
        ; ("jjjj" above = "ninja" in Japanese)

        hex 5b 5b 5b 5b 0d 0a  ; unaccessed ($c24e)

palette_table
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

        ; read as PCM audio data ($c280, 4001 bytes)
        hex f8ff950300c0fff9eb179f00e8130068632b45feff7fbbd30800e835450436a4
        hex 88f16e9b5cdf5f57ebfdcd242a138100198f047152990ab4ff3379bfdb5466f7
        hex 3f92f53711404c330059332300d85e46b9766b44f5ffb5dabbb318a9ffab2892
        hex 082060ff3b20142110a8fe7b29d5ae32d6feff966aed0c91ac6b312455250491
        hex ad6558adca28c5bed7d4ba56a92475bf95ea6a8a11e5ee9254558a22b2b653a9
        hex 2c2b865275aba569ad4aa5765bad5a5555cad4b6aad22aa51449db2a93a552a5
        hex a4ea5655d52a339576dbaab455a6946adb4a55954a8a54d74ca5aa2aa5526eab
        hex aa6a559649edb62aab952aa9d4b696cc4aa552945d4ba659a52ac9da5a65d6aa
        hex 4c29eb3a4bb59a2a29d5b94a5553a522656d55a99a9952c9d64dd3aca62aa5d6
        hex b532b5ca94526adb54aa664a49a95d5355d532259575abaa6a9529a9dad69456
        hex 4d6594aa5b95aa6a4a29695b2b53ab4aa554edaaaa6aa52aa96a5b95555529a5
        hex acad95aaaa2a2955edaa2aab2a65545babaaaaa94aa95a5b5556a5aaa4ac6d99
        hex aaa92aa554dbaaaa6a2a95526dabaa9a9a52c95a5b5556954a29b56d699aaa4a
        hex 4955b7aaaaaa4aa554bb56a655a5524aeb5a6956a54a49ad6da599954a4a55b7
        hex aa6a664a2555db5aa996a94a4aeb9aa556a65252d5ada9aaaa524ad5b6556556
        hex aa9432bb569555aa544a6d5b95aaaaa452b56d55aaaa545255fb77ab030000fc
        hex ffff0b7a2f0000005be5df92ecf7efbda25a460400da8a80aad73a84b455ffff
        hex efeb56c58828a92d1109814210a8bdff4c92d6be5a75dbdddf39aaaa562b0a81
        hex 549300a0daa62228b6bb92b4fdde759655b7ff2d295b9b220451df1220548910
        hex 906af75a9554556bb7bd75ef5b9352db561149b5ad2452a64942244a95555555
        hex 59adaaaada7eb7caba5b4ba9acb55552924a49a45249aaaa9252abb5aaaaeab6
        hex adaaeeaeaaaa52cdaa2a55a9a424254955ab94aaaa324d55dbadb5aad56a55ad
        hex 5655ab52a954aa2a494a555552aa55a5aaaaac6dd5da5655b5aaaadab6aa5295
        hex 524a4aaaad4a52554aa9aaaad65a55d5aaaaad55555bab5255abaa542a655549
        hex 69552955aaa45aad5555adaaaa2aadbb5555b55295aaaaaaa952a9524a552b55
        hex 555595a96aadaa6a55abaa6aadaaaaaa2a55a95653a52a55aa54d5aaaaaa2a55
        hex 55b556abaaaaaaaa6ab5aa525555a9aaaaaa4a55a92a55d56aa95a5599aa6aad
        hex aaaaaaaaaaaa562b55a5aa5255d5aa5455a5aa54b5565555555555d56a559a95
        hex aaaaaa6a95aaaa5495aa5635555595aaaa6ab5aaaaaaaa4ab55aa9aaaaaa2a55
        hex abaaaaaa5455a95655555555555555abaaaaaaaa52b56aa9aaaaaa5455b5aa4a
        hex 35555565d5aa4acd525555d5aaaaaaaa525555abaaaaaa4a5555adaaacaaaa54
        hex 35ad2c531be34aa507877bb1e38b8080f4ff3f8877004461b57ffdbf2b900e00
        hex 5018f47ffefccf580000fc0f54fdfb031e7ee001001cbff4ff83873f005280fd
        hex 09a71ffcff41130a00ce93ffa8dfff00f4822120b0ffe1e3cf5f09008c01fe1f
        hex 3cfefce00700fe033c38ff9fc137e08b00207fe0ffa3c195073100f30f7e3e34
        hex fd0f14ef4061bae9ed59334742b08313ba9b1d36b2ea6ec0a8d49ae5ad6e95d6
        hex 14e8487d5aa556474729d619a9a46dd54aca5955a65aa959cd9ab4d2ce6426ad
        hex 2ab56a5555a594a652af2c555555d5a4d49aabaaaa646daaaaaaaa4aadcae45a
        hex a5aa2a555552755b99aa2a6a25ad664bada52a55556da52aadaa4ada6a95aa4a
        hex aa55a5b6aa4a555555857fd0d203fce72130dc3fe01f80e37f00e01ff0ff0300
        hex 8eff3fc00b00ff27ff0000fffe0b7402f03f371d00ff80ff03e03f41c50afe47
        hex ac5445ff00f0ff01fc01f0ff801bf01f34e03fb4b700f0ff01fe00f0ff4c0080
        hex ffff2b0080ff7f092580ff7b801fe01fd03f00fe0fe0ef00f8c71ea841ddff42
        hex 0300febfbb0200ffb7c805f0535f01b5f42714fd02fc5700bf40ff435c11e8bf
        hex f04515e0d76ed406e05f6d8a02fca75e49807fa95532526f55955452dbaa9a52
        hex 5a55abd22ad5aa4a555555ad95d4b4aa545555b5aaaa2a555555ab2a55b554ab
        hex b24ab5aaaa4a5aa56d95545355b55255ad2aab543555b5aa2ad54a6aabaa5455
        hex d5aa4a2b2b2fac4ad5a4b158aebd9850cdb5a9a4daaa6265ab6ad8650d51edf2
        hex 24995b8b49b426b746a566d5ac164b35954e95b5a9b52aa59a2a65ab2aa56c59
        hex 35ab6234b5a9d5b14cb3ea6456ca4ca933ab9a56aa526566ad58a9ae6457aaaa
        hex aab24c3565adac4aadaaaa4c53a96c55ad6555aaa42db5525555abaaaaacb24a
        hex 55a556b54aadaa4aabd454555555b5aaaaaa2a555555d5aa2aabaa5455ab5453
        hex 55d5aa5255adaa525555adaaaaaa5455ad4ab5aa2a5555abaaaa4aab2a5555ab
        hex aa52555555adaaaa545555d5aaaa2a55adaa545555adaa525555add44a5555ab
        hex 5455adaa2a55abaa5455b5aaaaaa4a55ab2a555535b55455b52a55b52a55137f
        hex 60b503fcc70d08f0ffe03f00f87f00f00ff83f0400cfff3fc00ac0ff03ff01d4
        hex 19f83fb003e0ff1e50e07fc07f01f01f7d01c0ff6366803a7f04f8ff017c00fc
        hex 1ff007e03f80fb07fc0fe00cce8890aaffff7f0000fe011600f0ffff07f0ff7e
        hex dc0168b003005680fe03f8438effc7ffa16baffc470080fd470700007ef50100
        hex fe4b7f01f6df3f17f05ffe0f113a627f005600c81fe00f40c0cbff4127e8dffe
        hex 470afa7f7f4480ffc50d0036f5880020e17f48810ed8ffd4b74afac3fe8f4dda
        hex d2d75408eea20a2c00ff440b00f43feb8600f5ff7a630afab75ba904fd92bd24
        hex 40df44aa1640ff481592d4bfaa9500ffff230000f8ffff9f34528012289af98d
        hex ca6da3dfbf19629419130408ba96cb298accdff3fef596ee9d32252604e6a480
        hex 0892c1f9326e5666eaefdcde9a8df55f331b43c174924848445055c9b29449b4
        hex 5fb3edd6d4ee75fb795a8aaaab4c4508524aa5949428a65466ca6ab55adbb6db
        hex b675b7aad5aaca549292494a8994524aa652556b55add55adbaa56b3dab2ac9a
        hex 6a33655255aa5225259355695555aaaaaaa62e5535b5a655b55a56b554d52aab
        hex 345366552ba92ad55455a5ca96aaaa662aadaca95a3555adaaaaaaaaaa56555a
        hex 692da9aaaad42a5555956a95aa4aab5aa94dab2aadaaaa5aa9aaaaaaaaaaaab4
        hex aa4a555555ad5255555555955655553555ab54abaaaaaaaaaaaa5a95aaaa2ab5
        hex 895595b42bd15bc0778b40b72ff01f50e495fb91c0075b5fa05fc04717f8b4d2
        hex 0754bb446fe1d2027f92f807b516d8974e6c916e8db8d0dd828b0efca3a42df4
        hex 0b7475c2a707d455de9226b2f22f6841557f4aaa01fe831ff8c0477ad1827e59
        hex e8013fe96a95d00f7ce80b7ea0ab92be6891b6e01f7cc0927da9912ab7b8520b
        hex fa0b7d81855ff226925ab5aa077a41afe8853ed04baa5bd42a157dc916d952be
        hex a84a455fa92a4577e21754d22d75252d694bb5257a495555ad25b5096f4a6ba4
        hex 35d5aa5453f40bd50a6dd3aaaa54556da55a4a55b5aaca2a692bd52aa556554d
        hex ada4b6aaaa5255adaaaa12fcff710000c0ffffbd45af024000a8dabea556adfd
        hex fe5fa584a84240225251b5aa16553dd5f7ffbeced5b2125388a2440982889272
        hex 6bb5aab2d5af5bbddaebd5ae6aab948a4a454444244aa454aa4ad5aa56dbb6d6
        hex 6ded6ebb6baba5aaaa54528a1229919290242969b5aa5a55ab6dbbdbddda5aab
        hex 56555555a9522995529252924a9252a9aaaaaad65a6badb5b5ad6d6bb5aaaaaa
        hex 542aa5949492524a2a55aaaaaa5aad6a6dadb6d65a5bab6aa5aaaa52a9945229
        hex 95524aa52a5555b5aa55abb556adb55aad56555555552a554a954aa952a552a9
        hex aaaaaa5ab56aad5aad566d55ad6a5555a54a552a554a9552a52a5555555555b5
        hex 6ad56ab56ab5aa5655d54a553555a552a92aa5aa5455aaaaaaaaaa5a55b555ad
        hex aaaa5ba9b524dd2e48aa2dd14fa0c856f646505752bd92de505b55d52eb525a5
        hex adaa5a915e21ab45f84b682ac9b6a9aa5255ad95aafa227625b557a12ba99ba4
        hex aaa66a2529b5da4ad292f4576425a5fe8aaa92b4afaa4aaa9a5a55496dc996a4
        hex b455da2652ab2aed8ab6a255d66a53aa92ba2bb594426fa5a594742bd514b555
        hex ab525257d9954ada4add92aaaa4a5bc956aa5255ad4aaba45a555556d22b5553
        hex a5baa9aa52adaa55aa54ab5aa552ada4ae52b54aa555d52a555555b5aa4a59ab
        hex aaaa92daaaaa5265adaaaa52a9adaaaa2a65adaaaa2a552bb5ca924e4bb56295
        hex 9aea6295071f4bcb468b0b671fecf8238002fcff4ff4008069cce2ef7fff02e1
        hex 070001c0ffff81ff9f010060ff02f6cbafc2b61f3000200fbbfffb7e000fc00a
        hex 027ff2e05fff630adf000083f70ffeff1c02d43b001ce0ff1cf8fb2b03808181
        hex 1fff0ff0ff137c00e30c90dff723fc0f780200dfc0fe077fa0f2046602fcbf80
        hex 3ff8fd12682d2aa0ff815f5be01f40fc4015faa693fc80df0be0071c6fa2ff42
        hex 979c2ec0d21df903fc076a456d89067ee8b341fda0a32ef02df8455717f0da84
        hex 7e81f3c1aa2ba92ce40ff8855a3dd0b5035e03bfd85a0bbc55e41df01e58ed09
        hex ae03f782ae708b17f83ec06bd04b36ea41b72cf601df828b7bc037f05ae8255e
        hex e103de075c2bbca293dec097aa74492d3aa15ff8a907f881b506f07bc97b801f
        hex f060077eece40ffc81838de02f5cfc033ff04415f81fb80ff0071efc015edcfc
        hex 007fd0c30bf00f8e1fe007fee801be80ff0ffe0000f8e0ffff357507000002f8
        hex d7cf4dfce1ffff0016f02a001570003ff0c57fd4dec5fffc81fff0492b086402
        hex 0a80057eb5c4971aea07fef55fbdf9ea651fc00f3c70154025a001bcc08f3ad8
        hex 4f52fdc19ffec59f766fd505f8210ffa003610520023f4c30ff905b59668db9f
        hex fc53bfbaad925eb1923ec0161449a4a05de0057dc15dadb27d63bfb0abb65295
        hex b6aad80bb80a15a924ea157ad01d74a5967837d91f74b52ba9496d5675893651
        hex 1b2a50ebc30f803eefe11b98012bfffe8721303223fcffc11a580324f8dfcd40
        hex 7f011474b77ef46f8812d07e6ff220de0948caff04c1fda40980ff92c2ffd902
        hex 60dbcec4fede0111e87fa07cd10f00dcbf6822ee1200faffbbc02e8288d4ff3f
        hex ca16b204aafeaf812935009ddaff0154b78224f4bf99b4b51942dcab3ae6354b
        hex 88a4fe4d704d569240dedfa8aa5aa488bafb866a57224559f71566ad5221595d
        hex b754d2aa22a9da6daacc2a3551ed9aaa6a955aa255adaaaa964a5553da2a55d5
        hex 54d552d95455daaa4adaaaaa1ad3caaa54ab4ad5aa4aab52ad54955655abac52
        hex b54a55b5525555adaaaab4aa54b5aaaa52adaaaa54b54a69abaa4a565555b554
        hex b52aab6295add4caaca5344bb554d96e446a55565595aaed2ad1aca455d46a6b
        hex b6a22a5355555555b54b5255552de94acdaa54d52aad916aad52adb2aa952aa5
        hex 96dab6a452b5aa8a5aa556ab2aab522ba2dfaa1f0080a4feffff4f4208014051
        hex b56ab56b7bdf7f575925542288880891525555b5d6fadefbdb76abaa962a5545
        hex 891084884853aa6a4a55ad6bb575b77bb7ddb65655a94a492a45249224295292
        hex aa52596b6babad6edbdeb66d6babaa2a4d5255a24892249148925a2955b56a6b
        hex b5ad75b75ddb5a5b55555555959294949448a5a44a4a55b5aaa656ab6e6dadda
        hex 5a

        ; unaccessed ($d221)
        hex 6d 65 55 55

game_over
        ; Name Table data for the "GAME OVER - CONTINUE?" screen with a simple
        ; encryption ($11 is subtracted from each value). 96 (32*3) bytes.

        ; "           GAME OVER            "
        hex 5b5b5b5b 5b5b5b5b 5b5b5b47 414d455b 4f564552 5b5b5b5b 5b5b5b5b 5b5b5b5b
        ; "                                "
        hex 5b5b5b5b 5b5b5b5b 5b5b5b5b 5b5b5b5b 5b5b5b5b 5b5b5b5b 5b5b5b5b 5b5b5b5b
        ; "           CONTINUE?            "
        hex 5b5b5b5b 5b5b5b5b 5b5b5b43 4f4e5449 4e55458b 5b5b5b5b 5b5b5b5b 5b5b5b5b

        ; Name Table data for the "GREETS TO ALL NINTENDAWGS" screen with a simple
        ; encryption ($11 is subtracted from each value). 640 (32*20) bytes.
greets  ; "           NAE(M)OK             "
        hex 5b5b5b5b 5b5b5b5b 5b5b5b4e 41455e4d 5f4f4b5b 5b5b5b5b 5b5b5b5b 5b5b5b5b
        ; "         BYTER(A)PERS           "
        hex 5b5b5b5b 5b5b5b5b 5b425954 45525e41 5f504552 535b5b5b 5b5b5b5b 5b5b5b5b
        ; "       JUMALAU(T)A              "
        hex 5b5b5b5b 5b5b5b4a 554d414c 41555e54 5f415b5b 5b5b5b5b 5b5b5b5b 5b5b5b5b
        ; "           SHI(T)FACED CLOWNS   "
        hex 5b5b5b5b 5b5b5b5b 5b5b5b53 48495e54 5f464143 45445b43 4c4f574e 535b5b5b
        ; "              ( )               "
        hex 5b5b5b5b 5b5b5b5b 5b5b5b5b 5b5b5e5b 5f5b5b5b 5b5b5b5b 5b5b5b5b 5b5b5b5b
        ; "       DEKADEN(C)E              "
        hex 5b5b5b5b 5b5b5b44 454b4144 454e5e43 5f455b5b 5b5b5b5b 5b5b5b5b 5b5b5b5b
        ; "       ANANASM(U)RSKA           "
        hex 5b5b5b5b 5b5b5b41 4e414e41 534d5e55 5f52534b 415b5b5b 5b5b5b5b 5b5b5b5b
        ; "             T(R)ACTION         "
        hex 5b5b5b5b 5b5b5b5b 5b5b5b5b 5b545e52 5f414354 494f4e5b 5b5b5b5b 5b5b5b5b
        ; "             D(R)AGON MAGIC     "
        hex 5b5b5b5b 5b5b5b5b 5b5b5b5b 5b445e52 5f41474f 4e5b4d41 4749435b 5b5b5b5b
        ; "           ASP(E)KT             "
        hex 5b5b5b5b 5b5b5b5b 5b5b5b41 53505e45 5f4b545b 5b5b5b5b 5b5b5b5b 5b5b5b5b
        ; "              (N)ALLEPERHE      "
        hex 5b5b5b5b 5b5b5b5b 5b5b5b5b 5b5b5e4e 5f414c4c 45504552 48455b5b 5b5b5b5b
        ; "            FI(T)               "
        hex 5b5b5b5b 5b5b5b5b 5b5b5b5b 46495e54 5f5b5b5b 5b5b5b5b 5b5b5b5b 5b5b5b5b
        ; "                                "
        hex 5b5b5b5b 5b5b5b5b 5b5b5b5b 5b5b5b5b 5b5b5b5b 5b5b5b5b 5b5b5b5b 5b5b5b5b
        ; "               +                "
        hex 5b5b5b5b 5b5b5b5b 5b5b5b5b 5b5b5b5d 5b5b5b5b 5b5b5b5b 5b5b5b5b 5b5b5b5b
        ; "                                "
        hex 5b5b5b5b 5b5b5b5b 5b5b5b5b 5b5b5b5b 5b5b5b5b 5b5b5b5b 5b5b5b5b 5b5b5b5b
        ; "  PWP/FAIRLIGHT/MFX/MOONHAZARD  "
        hex 5b5b5057 505c4641 49524c49 4748545c 4d46585c 4d4f4f4e 48415a41 52445b5b
        ; "    ISO/RNO/DAMONES/HEDELMAE    "
        hex 5b5b5b5b 49534f5c 524e4f5c 44414d4f 4e45535c 48454445 4c4d4145 5b5b5b5b
        ; "                                "
        hex 5b5b5b5b 5b5b5b5b 5b5b5b5b 5b5b5b5b 5b5b5b5b 5b5b5b5b 5b5b5b5b 5b5b5b5b
        ; "             WAMMA              "
        hex 5b5b5b5b 5b5b5b5b 5b5b5b5b 5b57414d 4d415b5b 5b5b5b5b 5b5b5b5b 5b5b5b5b
        ; " QUALITY PRODUCTIONS SINCE 1930 "
        hex 5b515541 4c495459 5b50524f 44554354 494f4e53 5b53494e 43455b8c 8d8e8f5b

        ; written to PPU ($d505, 44 bytes, some bytes unaccessed)
table4  hex 48 4a 4c 4e
        hex 60 62 64 66 68 6a 6c 6e
        hex 80 82 84 86 88 8a 8c 8e
        hex a0 a2 a4 a6 a8 aa ac ae
        hex c0 c2 c4 c6 c8 ca cc ce
        hex e0 e2 e4 e6 e8 ea ec ee

color_or_table
        db %00001111, %00000000, %00010000, %00100000

some_palette1
        hex 3c 0f 3c 22

some_palette2
        hex 3c 3c 3c 3c

        ; 256 bytes.
        ; If the formula (x + 60) % 256 is applied, looks like a smooth curve with values 0-121.
        ; Used as scroll values and sprite positions.
curve1  hex 00 00 ff fe fd fc fc fb fa fa f9 f8 f8 f7 f7 f6
        hex f6 f5 f5 f5 f4 f4 f4 f4 f4 f4 f4 f5 f5 f5 f6 f6
        hex f7 f7 f8 f9 fa fb fc fd fe ff 00 01 03 04 05 07
        hex 08 0a 0b 0d 0e 10 12 13 15 17 19 1a 1c 1e 1f 21
        hex 23 25 26 28 29 2b 2c 2e 2f 31 32 33 34 35 36 37
        hex 38 39 3a 3b 3b 3c 3c 3c 3d 3d 3d 3d 3d 3c 3c 3c
        hex 3b 3a 3a 39 38 37 36 35 33 32 31 2f 2d 2c 2a 28
        hex 26 24 22 20 1e 1c 19 17 15 12 10 0e 0b 09 06 04
        hex 01 ff fc fa f7 f5 f2 f0 ed eb e9 e6 e4 e2 e0 de
        hex dc da d8 d6 d4 d3 d1 d0 ce cd cc cb ca c9 c8 c7
        hex c6 c6 c5 c5 c5 c4 c4 c4 c4 c5 c5 c5 c6 c6 c7 c8
        hex c8 c9 ca cb cc ce cf d0 d1 d3 d4 d6 d7 d9 da dc
        hex de df e1 e3 e4 e6 e8 e9 eb ed ef f0 f2 f3 f5 f7
        hex f8 fa fb fc fe ff 00 02 03 04 05 06 07 08 08 09
        hex 0a 0a 0b 0b 0c 0c 0c 0c 0c 0d 0d 0c 0c 0c 0c 0c
        hex 0b 0b 0a 0a 09 09 08 07 07 06 05 05 04 03 02 01

        ; A smooth curve with 256 values between 4-64.
        ; Used as scroll values and sprite positions.
curve2  hex 22 24 25 26 27 28 2a 2b 2c 2d 2e 30 31 32 33 34
        hex 35 36 37 38 38 39 3a 3b 3c 3c 3d 3d 3e 3e 3f 3f
        hex 3f 40 40 40 40 40 40 40 40 40 40 40 40 3f 3f 3f
        hex 3e 3e 3d 3d 3c 3c 3b 3a 3a 39 38 38 37 36 35 34
        hex 34 33 32 31 30 2f 2e 2e 2d 2c 2b 2a 29 29 28 27
        hex 26 26 25 24 23 23 22 22 21 20 20 1f 1f 1f 1e 1e
        hex 1e 1d 1d 1d 1d 1c 1c 1c 1c 1c 1c 1c 1c 1c 1d 1d
        hex 1d 1d 1d 1e 1e 1e 1e 1f 1f 1f 20 20 21 21 21 22
        hex 22 23 23 23 24 24 25 25 25 26 26 26 27 27 27 27
        hex 28 28 28 28 28 28 28 28 28 28 28 28 28 28 28 27
        hex 27 27 27 26 26 25 25 24 24 23 23 22 21 21 20 1f
        hex 1f 1e 1d 1c 1b 1b 1a 19 18 17 16 15 15 14 13 12
        hex 11 10 10 0f 0e 0d 0c 0c 0b 0a 0a 09 08 08 07 07
        hex 06 06 06 05 05 05 04 04 04 04 04 04 04 04 04 05
        hex 05 05 06 06 06 07 07 08 09 09 0a 0b 0c 0c 0d 0e
        hex 0f 10 11 12 13 14 16 17 18 19 1a 1b 1d 1e 1f 20

woman_sprite_x
        ; Sprite X positions in the woman part of the demo. 256 bytes.
        ; 194 (-62) is added to these.
        ; If the formula (x + 182) % 256 is applied, looks like a smooth curve with values 0-212.
        hex dd dd dd dd de de de de de de de de de de de de
        hex de dd dd dd dc dc db db da d9 d8 d7 d7 d5 d4 d3
        hex d2 d0 cf cd cc ca c8 c6 c4 c2 c0 be bb b9 b6 b4
        hex b1 ae ab a8 a5 a2 9f 9b 98 95 91 8e 8a 87 83 80
        hex 7c 79 75 72 6f 6c 68 65 62 60 5d 5a 58 56 54 52
        hex 50 4e 4d 4c 4b 4b 4a 4a 4a 4b 4b 4c 4d 4f 50 52
        hex 54 57 59 5c 5f 62 66 69 6d 71 75 7a 7e 82 87 8c
        hex 91 95 9a 9f a4 a9 ae b3 b8 bd c1 c6 cb cf d3 d8
        hex dc e0 e4 e7 eb ee f2 f5 f8 fb fd 00 02 05 07 09
        hex 0b 0c 0e 0f 11 12 13 14 15 16 17 17 18 19 19 1a
        hex 1a 1b 1b 1b 1c 1c 1c 1d 1d 1d 1d 1e 1e 1e 1e 1e
        hex 1e 1e 1e 1e 1e 1e 1e 1e 1d 1d 1d 1c 1c 1b 1b 1a
        hex 19 19 18 17 16 15 13 12 11 10 0e 0d 0b 0a 08 07
        hex 05 03 02 00 fe fd fb f9 f8 f6 f4 f3 f1 ef ee ec
        hex eb ea e8 e7 e6 e5 e4 e3 e2 e1 e0 e0 df df de de
        hex dd dd dd dd dc dc dc dc dc dc dc dd dd dd dd dd

        ; A smooth curve with 256 values between 2-22.
curve3  hex 0a 0b 0c 0c 0d 0e 0f 0f 10 10 11 11 12 12 13 13
        hex 13 13 13 13 13 13 12 12 12 11 11 10 10 0f 0e 0e
        hex 0d 0c 0b 0b 0a 09 09 08 07 07 06 06 06 05 05 05
        hex 05 05 05 06 06 06 07 07 08 08 09 0a 0b 0b 0c 0d
        hex 0e 0f 10 10 11 12 13 13 14 14 15 15 16 16 16 16
        hex 16 16 16 16 15 15 14 14 13 12 12 11 10 0f 0f 0e
        hex 0d 0c 0b 0a 0a 09 08 07 07 06 06 05 05 05 05 04
        hex 04 04 04 05 05 05 05 06 06 07 07 08 08 09 09 0a
        hex 0a 0b 0b 0c 0c 0d 0d 0e 0e 0e 0e 0f 0f 0f 0f 0f
        hex 0f 0e 0e 0e 0e 0d 0d 0c 0c 0c 0b 0a 0a 09 09 08
        hex 08 07 07 06 06 05 05 04 04 04 03 03 03 03 03 03
        hex 02 02 03 03 03 03 03 03 04 04 04 05 05 05 06 06
        hex 07 07 08 08 08 09 09 09 0a 0a 0a 0b 0b 0b 0b 0b
        hex 0b 0b 0b 0b 0b 0b 0b 0b 0b 0a 0a 0a 09 09 09 08
        hex 08 07 07 06 06 06 05 05 05 04 04 04 04 03 03 03
        hex 03 03 03 04 04 04 04 05 05 06 06 07 08 08 09 0a

        ; 256 bytes. Written to PPU.
        ; Note: on each line:
        ;     - the high nybbles are 0, 1, 2, 3, 2, 1, 0, 0
        ;     - all low nybbles are the same
table5  hex 06 16 26 36 26 16 06 06
        hex 0a 1a 2a 3a 2a 1a 0a 0a
        hex 02 12 22 32 22 12 02 02
        hex 03 13 23 33 23 13 03 03
        hex 08 18 28 38 28 18 08 08
        hex 05 15 25 35 25 15 05 05
        hex 0b 1b 2b 3b 2b 1b 0b 0b
        hex 04 14 24 34 24 14 04 04
        hex 07 17 27 37 27 17 07 07
        hex 06 16 26 36 26 16 06 06
        hex 0a 1a 2a 3a 2a 1a 0a 0a
        hex 02 12 22 32 22 12 02 02
        hex 03 13 23 33 23 13 03 03
        hex 08 18 28 38 28 18 08 08
        hex 05 15 25 35 25 15 05 05
        hex 0b 1b 2b 3b 2b 1b 0b 0b
        hex 04 14 24 34 24 14 04 04
        hex 07 17 27 37 27 17 07 07
        hex 06 16 26 36 26 16 06 06
        hex 0a 1a 2a 3a 2a 1a 0a 0a
        hex 02 12 22 32 22 12 02 02
        hex 03 13 23 33 23 13 03 03
        hex 08 18 28 38 28 18 08 08
        hex 05 15 25 35 25 15 05 05
        hex 0b 1b 2b 3b 2b 1b 0b 0b
        hex 04 14 24 34 24 14 04 04
        hex 0b 1b 2b 3b 2b 1b 0b 0b
        hex 05 15 25 35 25 15 05 05
        hex 08 18 28 38 28 18 08 08
        hex 03 13 23 33 23 13 03 03
        hex 02 12 22 32 22 12 02 02
        hex 0a 1a 2a 3a 2a 1a 0a 0a

        ; unaccessed ($da3d)
        hex 06 16 26 36 26 16 06 06
        hex 07 17 27 37 27 17 07 07
        hex 06 16 26 36 26 16 06 06
        hex 0a 1a 2a 3a 2a 1a 0a 0a
        hex 02 12 22 32 22 12 02 02
        hex 03 13 23 33 23 13 03 03
        hex 08 18 28 38 28 18 08 08
        hex 05 15 25 35 25 15 05 05
        hex 0b 1b 2b 3b 2b 1b 0b 0b

data1   db $18  ; $da85

sprite_y_table1
        hex 40 40 40 40 40
        hex 48 48 48 48 48
        hex 50 50 50 50 50
        hex 58 58 58 58 58
        hex 60 60 60 60 60
sprite_tile_table1
        hex c6 c7 c8 c9 ca
        hex cb cc cd ce cf
        hex d6 d7 d8 d9 da
        hex db dc dd de df
        hex e0 e1 e2 e3 e4
sprite_attr_table1
        hex 01 01 01 01 01
        hex 01 01 01 01 01
        hex 01 01 01 01 01
        hex 01 01 01 01 01
        hex 01 01 01 01 01
sprite_x_table1
        hex 40 48 50 58 60
        hex 40 48 50 58 60
        hex 40 48 50 58 60
        hex 40 48 50 58 60
        hex 40 48 50 58 60

; Unaccessed block ($daea)

unacc_data1
        hex 0b

unacc_table1
        hex 00 00 00
        hex 08 08 08
        hex 10 10 10
        hex 18 18 18

unacc_table2
        hex 00 01 02
        hex 10 11 12
        hex 20 21 22
        hex 30 31 32
        hex 40 40 40
        hex 40 40 40
        hex 40 40 40
        hex 40 40 40

unacc_table3
        hex 00 08 10
        hex 00 08 10
        hex 00 08 10
        hex 00 08 10

data3   hex 03

table6  hex 04 06 06 06

table7  hex 09 0e 0c 3e

table8  hex 0b 0f 0d 3f

        hex 04 02  ; unaccessed ($db28)

data4   hex 10

sprite_y_table2
        hex 00 fb fb fb fb 03 03 03 03 f6 f6 f6 ee ee ee e6 e6
sprite_tile_table2
        hex 46 1c 1b 1a 19 2c 2b 2a 29 2f 2e 2d 3e 1e 1d 0e 0c
sprite_attr_table2
        hex 40 41 41 41 41 41 41 41 41 42 42 42 42 42 42 42 42
sprite_x_table2
        hex 00 06 0e 16 1e 07 0f 17 1f 0c 14 1c 0c 14 1c 0c 14

data5   hex 03

data6   hex 3f

        ; $db71, 64 bytes.
        ; Looks like a sawtooth wave with values 8-255.
        ; Last 15 bytes are unaccessed.
table9  db   8,  19,  25,  48,  69,  80,  94, 103
        db 128, 136, 159, 186, 200, 209, 224, 244
        db  24,  37,  52,  80,  84,  85, 106, 111
        db 158, 171, 205, 211, 218, 229, 240, 255
        db  10,  25,  58,  86,  90,  95, 123, 128
        db 144, 175, 185, 198, 207, 234, 247, 250
        db  19,  25,  37,  85, 106, 111,  94, 103
        db 128, 136, 186, 200, 225, 235, 240, 244

sprite_tile_table3
        hex 40 43 42 41

        ; unaccessed ($dbb5)
        db $03, $00, $00, $07, $07, $42, $43, $52
        db $53, $03, $03, $03, $03, $00, $07, $00
        db $07, $01, $00, $00, $41, $51, $03, $03
        db $00, $07

data7   hex 0f

sprite_x_table4
        hex 13 50 54 6f 9e ab d0 ff 06 5a 5f c6 ca 13 19 25
sprite_y_table4
        hex 55 df 51 21 3d 9a 7d 88 cc 8f aa 43 8a 6e 90 76
sprite_xsub_table
        hex 03 05 05 07 06 04 06 05 02 05 04 08 03 02 07 06
sprite_tile_table4
        hex 50 51 51 53 51 52 50 53 52 52 51 51 52 53 53 51

; Star sprites in the first two parts of the demo.
; The last 5 bytes of each 16-byte table are unaccessed.

star_count
        ; Number of stars, minus one.
        db 10

star_initial_x
        db  19,  80,  84, 111, 158, 171, 208, 239
        db   6,  90,  95, 214, 202,  19,  25,  37

star_initial_y
        db  85, 223,  81,  33,  61, 154, 125, 136
        db 204, 143, 170,  67, 138, 110, 144, 118

star_y_speeds
        db 2, 3, 3, 5, 4, 2, 4, 3
        db 2, 2, 3, 4, 3, 2, 7, 6

star_tiles
        db $af, $ae, $ae, $be, $be, $bf, $af, $bf
        db $bf, $af, $ae, $ae, $bf, $be, $be, $be

        db $0f  ; unaccessed

sprite_x_table5
        hex 40 48 40 48 80 88 80 88
        hex c0 c8 c0 c8 f0 f8 f0 f8
sprite_y_table5
        hex 32 32 3a 3a 80 80 88 88
        hex 68 68 70 70 b8 b8 c0 c0
sprite_xadd_table
        hex 03 03 03 03 05 05 05 05
        hex 02 02 02 02 04 04 04 04
sprite_tile_table5
        hex ea eb fa fb ec ed fc fd
        hex ea eb fa fb ec ed fc fd

unacc_table4
        hex 00 03 06 03  ; unaccessed ($dc92)

; -------------------------------------------------------------------------------------------------

        ; Wait for VBlank ($dc96)
        ; Called by: init
wait_vbl
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
        inx
        inx
        inx
        inx
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
        add #85
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
unacc15 add #85
        clc
        nop
        nop
        adc #15
        sbc #15
        inx
        cpx delay_var2
        bne unacc15

        rts

        stx delay_var2
        ldy #0
        ldx #0
unacc16 ldy #0
unacc17 nop
        nop
        nop
        nop
        nop
        iny
        cpy #11
        bne unacc17

        nop
        inx
        cpx delay_var2
        bne unacc16

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
        lsr4
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
        add $a7
        ldy $a8
        sta sprite_page+sprite_tile,y

        ; $a5 + X -> sprite X
        txa
        adc $a5
        ldy $a8
        sta sprite_page+sprite_x,y

        ; $a6 + loopcnt -> sprite Y
        lda loopcnt
        add $a6
        ldy $a8
        sta sprite_page+sprite_y,y

        ; 3 -> sprite subpalette
        lda #%00000011
        ldy $a8
        sta sprite_page+sprite_attr,y

        ; $9a += 4
        lda $9a
        add #4
        sta $9a

        ; $9c += 1
        inc $9c

        ; Y + 4 -> $a8
        iny4
        sty $a8

        ; X += 8
        ; loop while less than 64
        txa
        add #8
        tax
        cpx #64
        bne update_sixteen_sprites_loop_inner

        ; loopcnt += 8
        ; loop while less than 16
        lda loopcnt
        add #8
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
        add $a7
        ldy $a8
        sta sprite_page+sprite_tile,y

        ; $a5 + X -> sprite X
        txa
        adc $a5
        ldy $a8
        sta sprite_page+sprite_x,y

        ; $a6 + loopcnt -> sprite Y
        lda loopcnt
        add $a6
        ldy $a8
        sta sprite_page+sprite_y,y

        ; 2 -> sprite subpalette
        lda #%00000010
        ldy $a8
        sta sprite_page+sprite_attr,y

        ; $9a += 4
        lda $9a
        add #4
        sta $9a

        ; $9c += 1
        inc $9c

        ; Y + 4 -> $a8
        iny4
        sty $a8

        ; X += 8
        ; loop while less than 24
        txa
        add #8
        tax
        cpx #24
        bne update_six_sprites_loop_inner

        ; loopcnt += 8
        ; loop while less than 16
        lda loopcnt
        add #8
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
        add $a7
        ldy $a8
        sta sprite_page+sprite_tile,y

        ; $a5 + X -> sprite X
        txa
        adc $a5
        ldy $a8
        sta sprite_page+sprite_x,y

        ; $a6 + loopcnt -> sprite Y
        lda loopcnt
        add $a6
        ldy $a8
        sta sprite_page+sprite_y,y

        ; 2 -> sprite subpalette
        lda #%00000010
        ldy $a8
        sta sprite_page+sprite_attr,y

        ; $9a += 4
        lda $9a
        add #4
        sta $9a

        ; $9c += 1
        inc $9c

        ; Y + 4 -> $a8
        iny4
        sty $a8

        ; X += 8
        ; loop while less than 32
        txa
        add #8
        tax
        cpx #32
        bne update_eight_sprites_loop_inner

        ; loopcnt += 8
        ; loop while less than 16
        lda loopcnt
        add #8
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
        lda sprite_tiles,y
        cmp #$ff
        bne +

        lda $9b
        add #14
        sta $9b
        jmp sub15_1

+       lda #$e1
        add $9b
        sta sprite_page+sprite_y,x
        sta $0154,y
        ;
        lda $9b
        sta $016a,y
        ;
        lda #$01
        sta $0180,y
        ;
        lda sprite_tiles,y
        sta sprite_page+sprite_tile,x
        ;
        lda #$00
        sta sprite_page+sprite_attr,x
        ;
        lda $9a
        add #40
        sta sprite_page+sprite_x,x

sub15_1
        inx
        inx
        inx
        inx
        iny
        lda $9a
        add #8
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
        ldx table4,y
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
        ldx table4,y
        txa
        add #16
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
        ;
        lda star_tiles,x
        sta sprite_page+45*4+sprite_tile,y
        ;
        lda #%00000011
        sta sprite_page+45*4+sprite_attr,y
        ;
        lda star_initial_x,x
        sta sprite_page+45*4+sprite_x,y
        ;
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
        lda curve1,x
        add $96
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
        jmp unacc18
+       ldx $93

        lda curve1,x
        add #88
        sta sprite_page+0*4+sprite_y
        lda curve2,x
        add #110
        sta sprite_page+0*4+sprite_x

        lda curve1,x
        add #88
        sta sprite_page+1*4+sprite_y
        lda curve2,x
        add #118
        sta sprite_page+1*4+sprite_x

        lda curve1,x
        add #96
        sta sprite_page+2*4+sprite_y
        lda curve2,x
        add #110
        sta sprite_page+2*4+sprite_x

        lda curve1,x
        add #96
        sta sprite_page+3*4+sprite_y
        lda curve2,x
        add #118
        sta sprite_page+3*4+sprite_x

        lda curve2,x
        add #88
        sta sprite_page+4*4+sprite_y
        lda curve1,x
        add #110
        sta sprite_page+4*4+sprite_x

        lda curve2,x
        add #88
        sta sprite_page+5*4+sprite_y
        lda curve1,x
        add #118
        sta sprite_page+5*4+sprite_x

        lda curve2,x
        add #96
        sta sprite_page+6*4+sprite_y
        lda curve1,x
        add #110
        sta sprite_page+6*4+sprite_x

        lda curve2,x
        add #96
        sta sprite_page+7*4+sprite_y
        lda curve1,x
        add #117
        sta sprite_page+7*4+sprite_x

        jmp sub19

unacc18 dec sprite_page+0*4+sprite_y
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
        lda curve1,x
        add $014e
        sta ppu_scroll

        lda $014e
        cmp #$c1
        beq +
        inc $014e
+       lda $ac
        cmp #$02
        bne +
        ;
        lda $ab
        cmp #$32
        bne +
        ;
        jsr sub15
+       lda $ac
        cmp #$01
        bne nmisub3_1
        ;
        lda $ab
        cmp #$96
        bne nmisub3_1
        ;
        ldx data1

nmisub3_loop1
        txa
        asl
        asl
        tay

        ; edit sprite #23
        lda sprite_y_table1,x
        add $012f
        sta sprite_page+23*4+sprite_y,y
        lda sprite_tile_table1,x
        sta sprite_page+23*4+sprite_tile,y
        lda sprite_attr_table1,x
        sta sprite_page+23*4+sprite_attr,y
        lda sprite_x_table1,x
        add $012e
        sta sprite_page+23*4+sprite_x,y

        cpx #0
        beq +
        dex
        jmp nmisub3_loop1

        ; edit sprite #24
+       lda #129
        sta sprite_page+24*4+sprite_y
        lda #$e5
        sta sprite_page+24*4+sprite_tile
        lda #%00000001
        sta sprite_page+24*4+sprite_attr
        lda #214
        sta sprite_page+24*4+sprite_x

        ; edit sprite #25
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
        ;
        lda #$a0
        clc
        adc $016a,x
        sta $9a
        lda $0154,x
        sta sprite_page+sprite_y,y
        cmp $9a
        bcc +
        ;
        txa
        pha
        inc $0196,x
        lda $0196,x
        sta $9c
        tax
        lda curve1,x
        sta $9b
        pla
        tax
        lda $0154,x
        clc
        sbc $9b
        sbc $9c
        sta $0154,x
        ;
+       inx
        iny4
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
        lda curve3,x
        add #$96
        sta $8b
        dec $8a
        ldx $8a
        lda curve2,x
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
        lda curve3,x
        sbc $8d
        and #%00111111
        tax
        lda table5,x
        sta ppu_data
        ldx $8b
        lda curve1,x
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
        lda #5
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
        lda curve1,y
        sta $0600,x
        lda $89
        add ram1
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
        add #32
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
        lda curve1,y
        sta $0600,x
        lda $89
        add ram1
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
        add #32
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
        add $8b
        tax
        lda curve1,x
        sta ppu_scroll
        lda #0
        sta ppu_scroll
        inc $89
        iny
        cpy #$98
        bne -

        ldx $8b
        lda curve3,x
        sbc $8b
        sbc $8b
        lda #0
        sta ppu_scroll

        ldx $8b
        lda curve2,x
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
        lda curve1,y
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
        add #32
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
        add #32
        sta $9a
        lda $9a
        cmp #$00
        bne nmisub9_loop2

        lda #$00
        sta $0148

nmisub9_2
        reset_ppu_addr

        ldx $8b
        lda curve3,x
        sbc $8b
        sbc $8b
        sbc $8b
        sbc $8b
        sbc $8b
        sbc $8b
        sta ppu_scroll

        ldx $8b
        lda curve2,x
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
        lda curve3,x
        sta $9a
        dec $89

        lda $89
        add $8a
        tax
        lda curve2,x
        clc
        sbc $9a
        adc $8c
        tax
        lda table5,x
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
        add $9e
        sta ppu_data
        inx
        cpx #8
        bne -

        iny
        cpy #$04
        bne nmisub12_loop2

        lda $9e
        add #8
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
        add $9e
        sta ppu_data
        inx
        cpx #8
        bne -

        iny
        cpy #4
        bne nmisub12_loop4

        lda $9e
        add #8
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
        lda curve2,x
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

        txa
        sta sprite_page+sprite_y,y
        ;
        lda #$f0
        add $8c
        sta sprite_page+sprite_tile,y
        ;
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
        add $8a
        tax
        lda woman_sprite_x,x
        add #194
        sta sprite_page+sprite_x,y

        ; restore X
        pla
        tax

        ; Y   += 4
        ; X   += 8
        ; $8d += 1
        iny4
        txa
        add #8
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

        txa
        sta sprite_page+sprite_y,y
        ;
        lda #$f0
        add $8c
        sta sprite_page+sprite_tile,y
        ;
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
        add $8b
        tax
        lda woman_sprite_x,x
        add #194
        sta sprite_page+sprite_x,y

        ; restore X
        pla
        tax

        ; Y   += 4
        ; X   += 8
        ; $8c += 1
        iny4
        txa
        add #8
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
unacc19 stx ppu_data
        inx
        iny
        cpy #12
        bne unacc19

        reset_ppu_addr
        set_ppu_addr vram_name_table0+9*32+10

        ldy #0
        ldx #$5c
unacc20 stx ppu_data
        inx
        iny
        cpy #12
        bne unacc20

        reset_ppu_addr
        set_ppu_addr vram_name_table0+10*32+10

        ldy #0
        ldx #$68
unacc21 stx ppu_data
        inx
        iny
        cpy #12
        bne unacc21

        reset_ppu_addr

        lda #1
        sta flag1
        lda #$00
        sta text_offset
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
        beq unacc22

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

unacc22 lda #$01
        sta $0130

        lda #%00011110
        sta ppu_mask
        lda #%00010000
        sta ppu_ctrl

        inc $8a
        lda $8a
        cmp #8
        beq +
        jmp unacc24
+       lda #$00
        sta $8a
        inc text_offset
        lda text_offset
        cmp #235
        beq +
        jmp ++
+       lda #0
        sta flag1
        lda #7
        sta demo_part

++      set_ppu_addr vram_name_table0+27*32+1

        ldx #0
unacc23 txa
        add text_offset
        tay
        lda it_is_friday_text,y
        clc
        sbc #$36
        sta ppu_data
        inx
        cpx #31
        bne unacc23

        reset_ppu_addr

unacc24 chr_bankswitch 2
        inc $89
        ldx $89
        lda curve2,x
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

        ; edit sprite #0
        lda #215
        sta sprite_page+0*4+sprite_y
        lda #$25
        sta sprite_page+0*4+sprite_tile
        lda #%00000000
        sta sprite_page+0*4+sprite_attr
        lda #248
        sta sprite_page+0*4+sprite_x

        ; edit sprite #1
        lda #207
        sta sprite_page+1*4+sprite_y
        lda #$25
        sta sprite_page+1*4+sprite_tile
        lda #%00000000
        sta sprite_page+1*4+sprite_attr
        lda #248
        sta sprite_page+1*4+sprite_x

        ; edit sprite #2
        lda #223
        sta sprite_page+2*4+sprite_y
        lda #$27
        sta sprite_page+2*4+sprite_tile
        lda #%00000000
        sta sprite_page+2*4+sprite_attr
        lda #248
        sta sprite_page+2*4+sprite_x

        ldx unacc_data1
unacc25 txa
        asl
        asl
        tay

        lda unacc_table1,x
        add #$9b
        sta sprite_page+23*4+sprite_y,y

        txa
        pha
        ldx $0137
        lda unacc_table4,x
        sta $9a
        pla

        tax
        lda unacc_table2,x
        add $9a
        sta sprite_page+23*4+sprite_tile,y

        lda #%00000010
        sta sprite_page+23*4+sprite_attr,y

        lda unacc_table3,x
        add $0139
        sta sprite_page+23*4+sprite_x,y

        cpx #0
        beq +
        dex
        jmp unacc25

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
        add #32
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
        add #32
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
-       lda table6,x
        sta $0104,x
        lda table7,x
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

        ; edit sprite #48
        lda sprite_y_table4,x
        sta sprite_page+48*4+sprite_y,y
        lda sprite_tile_table4,x
        sta sprite_page+48*4+sprite_tile,y
        lda sprite_x_table4,x
        sta sprite_page+48*4+sprite_x,y

        lda sprite_xsub_table,x
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

        ; edit sprite #1
        lda sprite_tile_table2,x
        sta sprite_page+1*4+sprite_tile,y
        lda sprite_attr_table2,x
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
        lda curve1,x
        adc #$7a
        sta $0111
        lda curve2,x
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
        cmp table8,x
        beq +
        inc $0108,x
        jmp nmisub17_1
+       lda table7,x
        sta $0108,x
nmisub17_1
        lda table6,x
        sta $0104,x
nmisub17_2
        dex
        cpx #255
        bne nmisub17_loop1

        ; edit tiles of four sprites
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

        ; edit sprite #1 position
        lda sprite_y_table2,x
        add $0111
        sta sprite_page+1*4+sprite_y,y
        lda sprite_x_table2,x
        add $0110
        sta sprite_page+1*4+sprite_x,y

        cpx #0
        beq +
        dex
        jmp nmisub17_loop2

+       lda $0100
        ldx $0101
        cmp table9,x
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
        lda curve1,y
        add #$5a
        sta $0116,x
        lda curve3,y
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

        ; edit sprite #18
        lda $0116,x
        sta sprite_page+18*4+sprite_y,y
        lda sprite_tile_table3,x
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
        sbc sprite_xsub_table,x
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
        add #<($2000+3*32+9)
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
        add #32
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
        lda curve1,x
        add $0153
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
        add $013b
        sta ppu_addr

        ldx #0
-       sty ppu_data
        iny
        inx
        cpx #8
        bne -

        lda $013b
        add #32
        sta $013b
        cpy #$c0
        bne nmisub21_loop1

nmisub21_loop2
        lda #>(vram_name_table0+16*32+4)
        sta ppu_addr
        lda #<(vram_name_table0+16*32+4)
        add $013b
        sta ppu_addr

        ldx #0
-       sty ppu_data
        iny
        inx
        cpx #8
        bne -

        lda $013b
        add #32
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
        add $013b
        sta ppu_addr

        ldx #0
-       sty ppu_data
        iny
        inx
        cpx #8
        bne -

        lda $013b
        add #32
        sta $013b
        cpy #$c0
        bne nmisub21_loop3

nmisub21_loop4
        lda #>(vram_name_table0+16*32+20)
        sta ppu_addr
        lda #<(vram_name_table0+16*32+20)
        add $013b
        sta ppu_addr

        ldx #0
-       sty ppu_data
        iny
        inx
        cpx #8
        bne -

        lda $013b
        add #32
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
        lda curve2,x
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
        add $8b
        adc $8a
        clc
        sbc #$14
        tax
        lda curve1,x
        add $8b
        sta ppu_scroll
        lda $89
        add $8b
        tax
        lda curve2,x
        sta ppu_scroll

        ldx $8a
        lda curve2,x
        add #60
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

unacc26 ldy #0
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

        ; update first background subpalette from some_palette1
        set_ppu_addr vram_palette+0*4
        lda some_palette1+0
        sta ppu_data
        lda some_palette1+1
        sta ppu_data
        lda some_palette1+2
        sta ppu_data
        lda some_palette1+3
        sta ppu_data
        reset_ppu_addr

        ; update first sprite subpalette from some_palette2
        set_ppu_addr vram_palette+4*4
        lda some_palette2+0
        sta ppu_data
        lda some_palette2+1
        sta ppu_data
        lda some_palette2+2
        sta ppu_data
        lda some_palette2+3
        sta ppu_data
        reset_ppu_addr

        ldx data7
nmisub22_loop
        txa
        asl
        asl
        tay

        ; edit sprite #48
        lda sprite_y_table5,x
        sta sprite_page+48*4+sprite_y,y
        lda sprite_tile_table5,x
        sta sprite_page+48*4+sprite_tile,y
        lda #%00000010
        sta sprite_page+48*4+sprite_attr,y
        lda sprite_x_table5,x
        sta sprite_page+48*4+sprite_x,y

        lda sprite_xadd_table,x
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
        sta text_offset
        rts

; -------------------------------------------------------------------------------------------------

nmisub23
        ; Called by: NMI

        inc $0100
        ldx $0100
        lda woman_sprite_x,x
        sta $9a
        lda curve3,x
        sta $9b

        sprite_dma

        ldx data7
nmisub23_loop1
        txa
        asl
        asl
        tay

        ; edit sprite #48 position
        lda sprite_y_table5,x
        add $9a
        sta sprite_page+48*4+sprite_y,y
        lda sprite_page+48*4+sprite_x,y
        clc
        adc sprite_xadd_table,x
        sta sprite_page+48*4+sprite_x,y

        dex
        cpx #7
        bne nmisub23_loop1

nmisub23_loop2
        txa
        asl
        asl
        tay

        ; edit sprite #48 position
        lda sprite_y_table5,x
        add $9b
        sta sprite_page+48*4+sprite_y,y
        lda sprite_page+48*4+sprite_x,y
        clc
        adc sprite_xadd_table,x
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
        ;
+       lda #$00
        sta $8a
        inc text_offset
        lda text_offset
        cmp #235
        beq +
        jmp nmisub23_1
        ;
+       lda #0
        sta flag1
        lda #7  ; 7th part
        sta demo_part

nmisub23_1
        ; copy 31 bytes from it_is_friday_text + text_offset to name table 0 Y pos 19, X pos 1

        lda #>(vram_name_table0+19*32+1)
        sta ppu_addr
        lda #<(vram_name_table0+19*32+1)
        sta ppu_addr

        ldx #0
-       txa
        add text_offset
        tay
        lda it_is_friday_text,y
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
        lda curve2,x
        sta ppu_scroll

        lda curve2,x
        sta $9a

        ; set up sprites 0-5
        ; Y        : (147, 151 or 155) - $9a
        ; tile     : #$25
        ; attribute: %00000000
        ; X        : 0 or 248

        ; edit sprite #0
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

        ; edit sprite #1
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

        ; edit sprite #2
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

        ; edit sprite #3
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

        ; edit sprite #4
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

        ; edit sprite #5
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
