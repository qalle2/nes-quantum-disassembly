; NES Quantum Disco Brothers disassembly. Assembles with asm6.
; TODO: data on unaccessed parts is out of date

; High-level call graph:
;
; init:
;   sub13
;       sub1
;   wait_vbl
;   hide_sprites
;   init_palette_copy
;   update_palette
;   init_star_sprites
;   fill_attribute_tables
;   fill_nt_and_clear_at
;
; nmi:
;   nmi_wecome
;       anim_wecome
;           print_big_text_line
;           sub19
;               move_stars_up
;       jump_snd_eng
;           sound_engine
;               sound4
;                   sound1
;               sound6
;                   sound2
;                   sound5
;                       sound2
;                   sound7
;                       sound2
;                       sound8
;                           sound2
;               sound9
;                   sound10
;                       sound8
;                       sound9
;   (TODO: the rest are missing 3+ levels below nmi)
;   nmi_horzbars1
;       init_horzbars1
;       anim_horzbars1
;       jump_snd_eng (see nmi_wecome)
;   nmi_title
;       init_title
;       anim_title
;       jump_snd_eng (see nmi_wecome)
;   nmi_credits
;       init_credits
;       anim_credits
;       jump_snd_eng (see nmi_wecome)
;   nmi_woman
;       init_woman
;       anim_woman
;       jump_snd_eng (see nmi_wecome)
;   nmi_friday
;       init_friday
;       anim_friday
;       jump_snd_eng (see nmi_wecome)
;   nmi_bowser
;       init_bowser
;       anim_bowser
;       jump_snd_eng (see nmi_wecome)
;   nmi_cola
;       init_cola
;       anim_cola
;       jump_snd_eng (see nmi_wecome)
;   nmi_horzbars2
;       init_horzbars2
;       anim_horzbars2
;   nmi_checkered
;       init_checkered
;       anim_checkered
;       jump_snd_eng (see nmi_wecome)
;   nmi_gradients
;       init_gradients
;       anim_gradients
;       jump_snd_eng (see nmi_wecome)
;   nmi_greets
;       init_greets
;       anim_greets
;       jump_snd_eng (see nmi_wecome)
;   nmi_gameover
;       init_gameover
;       anim_gameover

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
ram1         equ $00  ; ?
demo_part    equ $01  ; which part is running
temp1        equ $01  ; ?
flag1        equ $02  ; 0/1; used in NMI; cleared when demo_part changes
big_text_ptr equ $03  ; pointer to a text line in wecome_text_pointers (2 bytes)
; $05-$85: unaccessed
delay_var1   equ $86
delay_cnt    equ $87
delay_var2   equ $88
zp1          equ $89  ; ?
zp2          equ $8a  ; ?
zp3          equ $8b  ; ?
zp4          equ $8c  ; used in many nmisub's
zp5          equ $8d  ; does curve stuff in anim_horzbars2, counts 0-15 in anim_woman
vram_fill_byte equ $8e
text_offset equ $8f
offset      equ $90  ; in print_big_text_line only
ppu_addr_hi equ $91  ; in print_big_text_line only
ppu_addr_lo equ $92  ; in print_big_text_line only
unused1     equ $93  ; never read
counter1    equ $94  ; in nmi_wecome
counter2    equ $95  ; in nmi_wecome
vscroll     equ $96  ; in nmi_wecome
zp10        equ $98  ; ?
zp11        equ $99  ; ?
zp12        equ $9a  ; used a lot
zp13        equ $9b  ; ?
zp14        equ $9c  ; ?
zp15        equ $9e  ; ?
zp16        equ $9f  ; ?
zp17        equ $a0  ; in init_credits only
zp18        equ $a1  ; ?
zp19        equ $a2  ; ?
zp20        equ $a3  ; ?
zp21        equ $a5  ; ?
zp22        equ $a6  ; ?
zp23        equ $a7  ; ?
zp24        equ $a8  ; ?
zp25        equ $a9  ; in nmi_woman only
zp26        equ $aa  ; in nmi_woman only
zp27        equ $ab  ; ?
zp28        equ $ac  ; ?
; $ad-$c7: unaccessed
ptr2        equ $c8  ; pointer (2 bytes)
zp29        equ $cb  ; ?
zp30        equ $cc  ; ?
zp31        equ $cd  ; ?
ptr3        equ $ce  ; pointer (2 bytes)
ptr4        equ $d0  ; pointer (2 bytes)
zp32        equ $d2  ; ?
zp33        equ $d3  ; ?
zp34        equ $d4  ; ?
zp35        equ $d5  ; ?
zp36        equ $d6  ; ?
zp37        equ $d7  ; ?
ptr5        equ $d8  ; pointer (2 bytes)
ptr6        equ $da  ; pointer (2 bytes)
zp_arr1     equ $dc  ; ?
zp_arr2     equ $e0  ; ?
zp_arr3     equ $e5  ; ?
zp38        equ $e8  ; ?
zp_arr4     equ $e9  ; ?
apu_ctrl_mirror equ $ef
; $f0-$fe: unaccessed
useless     equ $ff  ; value seems to affect nothing (only MSB is read, it's always set)

; other RAM
; note: "unaccessed" = unaccessed except for the initial cleanup
credits_bg_pal equ $014d  ; background palette number in credits
; $1ac-$1eb: unaccessed
; $1ec-$1ff: probably stack
; $200-$2ff: unaccessed
; $400-$4ff: unaccessed
sprite_page  equ $0500  ; 256 bytes
; $680-$7bf: unaccessed
palette_copy equ $07c0  ; 32 bytes
; $7e0-$7ff: unaccessed

; video RAM
name_table0  equ $2000
attr_table0  equ $23c0
name_table1  equ $2400
attr_table1  equ $27c0
name_table2  equ $2800
attr_table2  equ $2bc0
vram_palette equ $3f00

; id's of parts of the demo (stored in demo_part; TODO: find out what's in part 8)
id_wecome    equ  0
id_title     equ  2
id_gradients equ 11
id_horzbars1 equ  1  ; non-full-screen
id_woman     equ  4
id_friday    equ  5
id_cola      equ  7
id_bowser    equ  6
id_credits   equ  3
id_checkered equ 10
id_greets    equ 12
id_gameover  equ 13
id_horzbars2 equ  9  ; full-screen

; --- Macros --------------------------------------------------------------------------------------

macro add _operand
        clc
        adc _operand
endm

macro chr_bankswitch _bank  ; write bank number (0-3) over the same value in PRG ROM
_label  lda #(_bank)
        sta _label + 1
endm

macro copy _src, _dst  ; note: for clarity, don't use this if A is read later
        lda _src
        sta _dst
endm

macro dexbne _target
        dex
        bne _target
endm

macro dexbpl _target
        dex
        bpl _target
endm

macro inclda _mem
        inc _mem
        lda _mem
endm

macro iny4
        iny
        iny
        iny
        iny
endm

macro ldxy _x, _y
        ldx _x
        ldy _y
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
        copy #>(_addr), ppu_addr
        copy #<(_addr), ppu_addr
endm

macro set_ppu_addr_via_x _addr
        ldx #>(_addr)
        stx ppu_addr
        ldx #<(_addr)
        stx ppu_addr
endm

macro set_ppu_scroll _horz, _vert
        copy #(_horz), ppu_scroll
        copy #(_vert), ppu_scroll
endm

macro sub _operand
        sec
        sbc _operand
endm

; --- iNES header ---------------------------------------------------------------------------------

        base $0000
        db "NES", $1a   ; id
        db 2            ; 32 KiB PRG ROM
        db 4            ; 32 KiB CHR ROM
        db $30, $00     ; mapper 3 (CNROM), horizontal name table mirroring
        pad $0010, $00  ; padding

; --- Start of PRG ROM (unaccessed block) ---------------------------------------------------------

        base $8000

        jmp jump_snd_eng
        jmp sub13

        sei
        cld
        ldx #$ff
        txs

        copy #%01000000, ppu_ctrl
        copy #%10011110, ppu_mask

        lda ppu_status
        lda ppu_status

        copy #%00000000, ppu_mask

        lda #<indirect_data1
        ldx #>indirect_data1
        jsr sub1

        copy #%00011110, ppu_mask
        copy #%10000000, ppu_ctrl

-       jmp -

; -------------------------------------------------------------------------------------------------

        ; Args: A = pointer low, X = pointer high
        ; Reads indirect_data1 via ptr4
        ; Called by: sub13
        ; Only called once (at frame 3 with indirect_data1 as argument).
        ; Calls: nothing

sub1    sta ptr4+0  ; $8034
        stx ptr4+1

        ; ptr4 + 16 -> ptr6
        lda #16
        add ptr4+0
        sta ptr6+0
        lda ptr4+1
        adc #0
        sta ptr6+1

        ; [ptr4 + 3] -> zp33
        ldy #3
        lda (ptr4),y
        sta zp33
        ; [ptr4 + 4] -> zp37
        iny
        lda (ptr4),y
        sta zp37
        ; [ptr4 + 7] -> zp36
        iny
        iny
        iny
        lda (ptr4),y
        sta zp36
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

        ; 144 -> zp29
        iny4
        tya
        add #128
        sta zp29

        ; ptr4 + zp29 -> ptr5
        lda ptr4+0
        adc zp29
        sta ptr5+0
        lda ptr4+1
        adc #0
        sta ptr5+1

        ; zp29 += zp36 * 4
        ; carry -> zp30
        lda zp36
        asl
        asl
        adc zp29
        sta zp29
        lda #0
        adc #0
        sta zp30

        lda ptr4+0
        adc zp29
        sta $0364
        lda ptr4+1
        adc zp30
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
        sta zp_arr1,x
        sta $0308,x
        sta zp_arr4,x
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
        sta zp_arr3,x
        sta $034c,x
        sta $0350,x
        sta $0355,x
        sta $035a,x
        sta $035f,x
        sta $039c,x
        dexbpl clear_loop

        sta zp34
        sta zp35
        sta apu_ctrl_mirror
        sta apu_ctrl
        ldx zp33
        inx
        stx zp32
        rts

; -------------------------------------------------------------------------------------------------

        ; Called by: sound4
        ; Calls: nothing

sound1  cmp #0
        bpl +    ; always taken
        lda #0   ; unaccessed ($8157)
+       cmp #63
        bcc +    ; always taken
        lda #63  ; unaccessed ($815d)
        ;
+       lsr
        lsr
        ora $0394,x
        ldy apu_reg_offsets,x  ; 0, 4, 8, 12
        sta pulse1_ctrl,y
        rts

; -------------------------------------------------------------------------------------------------

        ; Called by: sound5, sound6, sound7, sound8
        ; Calls: nothing

sound2  cpx #3
        beq ++
        cpx #2
        beq +++
        ;
        ldy apu_reg_offsets,x  ; 0, 4, 8, 12
        sta pulse1_timer,y
        lda #$08
        sta pulse1_sweep,y
        lda zp29
        cmp $03ac,x
        beq +
        sta $03ac,x
        ora #%00001000
        sta pulse1_length,y
+       rts

++      and #%00001111
        ora $034c,x
        sta noise_period
        copy #$08, noise_length
        rts

+++     ldy apu_reg_offsets,x  ; 0, 4, 8, 12
        sta pulse1_timer,y
        lda zp29
        ora #%00001000
        sta pulse1_length,y
        rts

; -------------------------------------------------------------------------------------------------

        ; Called by: sound10, jump_snd_eng
        ; Calls: sound4, sound6, sound9b

sound_engine
        lda zp33
        beq snd_eng_exit
        ;
        inc zp32
        cmp zp32
        beq +
        bpl +++
        ;
+       copy #$00, zp32
        lda zp34
        cmp #$40
        bcc ++
        copy #$00, zp34
        ldx zp35
        inx
        cpx zp36
        bcc +
        ldx zp37
+       stx zp35
++      jmp sound9b

        ; loop
+++     lda #$06  ; unnecessary
        ldx #3
-       lda zp_arr3,x
        bmi ++
        sub #1
        bpl +
        ;
        lda apu_ctrl_and_masks,x
        and apu_ctrl_mirror
        sta apu_ctrl_mirror
        ;
        lda #$00
+       sta zp_arr3,x
++      cpx #$02
        bne +
        copy #$ff, triangle_ctrl
+       dexbpl -

        lda apu_ctrl
        and #%00010000
        bne +
        ;
        lda apu_ctrl_mirror
        and #%00001111
        sta apu_ctrl_mirror
+       copy apu_ctrl_mirror, apu_ctrl

        ; loop
        ldx #3
-       cpx #2
        beq +
        jsr sound4
+       jsr sound6
        dexbpl -

snd_eng_exit
        inc $039c
        inc $039d
        inc $039e
        inc $039f
        rts

; -------------------------------------------------------------------------------------------------

        ; Called by: sound_engine
        ; Calls: sound1

sound4  lda $035a,x
        cmp #$0a
        bne +++
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
        jmp ++

+       tya
        and #%00001111
        eor #%11111111
        sec
        adc $0300,x
        sta $0300,x
++      jmp +

+++     lda $0320,x
        beq +
        clc
        adc $0300,x
        sta $0300,x
+       ldy $035a,x
        cpy #$07
        bne ++   ; always taken

        ; unaccessed ($826a)
        lda $035f,x
        beq +
        sta $0340,x
+       lda $0340,x
        bne unacc1

++      lda $0344,x
        bne unacc1  ; never taken
        lda $0300,x
        bpl +
        lda #$00
+       cmp #$3f
        bcc +        ; always taken
        lda #$3f     ; unaccessed ($8287)
+       sta $0300,x
        jmp sound1   ; ends with RTS

; --- Unaccessed block ----------------------------------------------------------------------------

unacc1  pha             ; $828f
        and #%00001111
        ldy $033c,x
        jsr sound5a
        bmi +
        clc
        adc $0300,x
        jsr sound1
        pla
        lsr4
        clc
        adc $033c,x
        cmp #$20
        bpl ++
        sta $033c,x
        rts

+       clc
        adc $0300,x
        jsr sound1
        pla
        lsr4
        clc
        adc $033c,x
        cmp #$20
        bpl ++
        sta $033c,x
        rts

++      sub #$40
        sta $033c,x
        rts

; -------------------------------------------------------------------------------------------------

        ; sound5b called by: sound6
        ; Calls: sound2

sound5a bmi +
        dey
        bmi ++
        ora or_masks,y
        tay
        lda table3,y
        clc
        rts
        ;
+       pha
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
        ;
++      lda #$00
        clc
        rts

sound5b pha
        and #%00001111
        ldy $0330,x
        jsr sound5a
        ror
        bmi +
        clc
        adc zp_arr1,x
        tay
        lda $0308,x
        adc #0
        sta zp29
        tya
        jsr sound2
        pla
        lsr4
        clc
        adc $0330,x
        cmp #$20
        bpl ++
        sta $0330,x
        rts
        ;
+       clc
        adc zp_arr1,x
        tay
        lda $0308,x
        adc #$ff
        sta zp29
        tya
        jsr sound2
        pla
        lsr4
        clc
        adc $0330,x
        cmp #$20
        bpl ++
        sta $0330,x
        rts
        ;
++      sub #$40
        sta $0330,x
        rts

; -------------------------------------------------------------------------------------------------

        ; Called by: sound_engine (from one place only)
        ; Calls: sound2, sound5, sound7

sound6  jsr sound7
        jmp +++

sound6a ldy $035a,x
        cpy #$04
        bne ++
        lda $035f,x
        beq +
        sta $0334,x
+       lda $0334,x
        bne sound5b
        ;
++      lda $0338,x
        bne sound5b
        lda $0308,x
        sta zp29
        lda zp_arr1,x
        jmp sound2

+++     lda $035a,x
        cmp #$03
        beq sound6b
        cmp #$01
        beq ++
        cmp #$02
        beq +++
        lda $03a0,x
        bne +        ; never taken
        jmp sound6a

        ; unaccessed block ($838e)
+       lda $03a0,x
        bmi +
        clc
        adc zp_arr1,x
        sta zp_arr1,x
        lda $0308,x
        adc #0
        sta $0308,x
        jmp sound6a
+       clc
        adc zp_arr1,x
        sta zp_arr1,x
        lda $0308,x
        adc #$ff
        sta $0308,x
        jmp sound6a

++      lda $035f,x
        beq +
        sta $0318,x
+       lda zp_arr1,x
        sec
        sbc $0318,x
        sta zp_arr1,x
        lda $0308,x
        sbc #0
        sta $0308,x
        jmp sound6a

+++     lda $035f,x
        beq +
        sta $0318,x
+       lda zp_arr1,x
        clc
        adc $0318,x
        sta zp_arr1,x
        lda $0308,x
        adc #0
        sta $0308,x
        jmp sound6a

sound6b lda $0350,x
        beq +
        sta $0314,x
+       lda $035f,x
        beq +
        sta $0318,x
+       ldy $0314,x
        ;
        lda notes_lo-1,y
        sta ptr2+0
        lda notes_hi-1,y
        sta ptr2+1
        ;
        sec
        lda zp_arr1,x
        sbc ptr2+0
        lda $0308,x
        sbc ptr2+1
        bmi +
        bpl ++   ; always taken
        ;
        jmp sound6a  ; unaccessed ($8414)
+       lda zp_arr1,x
        clc
        adc $0318,x
        sta zp_arr1,x
        lda $0308,x
        adc #0
        sta $0308,x
        sec
        lda zp_arr1,x
        sbc ptr2+0
        lda $0308,x
        sbc ptr2+1
        bpl +      ; always taken
        jmp sound6a  ; unaccessed ($8433)
        ;
++      lda zp_arr1,x
        sec
        sbc $0318,x
        sta zp_arr1,x
        lda $0308,x
        sbc #0
        sta $0308,x
        sec
        lda zp_arr1,x
        sbc ptr2+0
        lda $0308,x
        sbc ptr2+1
        bmi +
        jmp sound6a
        ;
+       lda ptr2+0
        sta zp_arr1,x
        lda ptr2+1
        sta $0308,x
        jmp sound6a

; -------------------------------------------------------------------------------------------------

        ; Called by: sound6, sound8
        ; Calls: sound2, sound8a

sound7  lda $035a,x
        cmp #$08
        beq +        ; never taken
        lda $0328,x
        bne sound7a
        lda $03a4,x
        bne sound7a
        lda $032c,x
        bne sound7a
        rts

+       jmp unacc4  ; unaccessed ($8478)

sound7a lda $039c,x
        ldy $03a8,x
        bne +
        and #%00000011
+       cmp #0
        beq +
        cmp #1
        beq ++
        cmp #2
        beq +++
        cmp #3
        beq ++++  ; always taken
        rts          ; unaccessed ($8495)

+       ldy zp_arr4,x
        lda notes_hi-1,y
        sta $0308,x
        sta zp29
        lda notes_lo-1,y
        sta zp_arr1,x
        jmp sound2

++      lda zp_arr4,x
        clc
        adc $0328,x
        tay
        lda notes_hi-1,y
        sta $0308,x
        sta zp29
        lda notes_lo-1,y
        sta zp_arr1,x
        jmp sound2

+++     lda zp_arr4,x
        clc
        adc $03a4,x
        tay
        lda notes_hi-1,y
        sta $0308,x
        sta zp29
        lda notes_lo-1,y
        sta zp_arr1,x
        jmp sound2

++++    lda zp_arr4,x
        clc
        adc $032c,x
        tay
        lda notes_hi-1,y
        sta $0308,x
        sta zp29
        lda notes_lo-1,y
        sta zp_arr1,x
        jmp sound2

sound7b sta $0300,x
        jmp sound8a

sound7c sta zp33
        jmp sound8a

; --- Unaccessed block ----------------------------------------------------------------------------

unacc2  sub #1    ; $84f8
        sta zp34
        lda zp35
        add #1
        cmp zp36
        bcc +
        lda zp37
+       sta zp35
        jmp sound8a

; -------------------------------------------------------------------------------------------------

        ; Called by: sound7, sound10
        ; Calls: sound2

sound8  ldy $035a,x
        beq sound8a

        lda $035f,x
        cpy #$0c
        beq sound7b
        cpy #$0f
        beq sound7c
        cpy #$0d
        beq unacc2  ; never taken

sound8a lda $035f,x
        cpy #$08
        beq unacc3  ; never taken

        lda $0328,x
        bne sound8b

        lda $03a4,x
        bne sound8b

        lda $032c,x
        bne sound8b

        lda $0350,x
        beq +

        lda $035a,x
        cmp #3
        beq +

        lda $0308,x
        sta zp29
        lda zp_arr1,x
        jmp sound2

+       rts

        ; unaccessed block
unacc3  jsr unacc4   ; $854e
        lda $0308,x
        sta zp29
        lda zp_arr1,x
        jmp sound2

sound8b jmp sound7a

; --- Unaccessed block ----------------------------------------------------------------------------

unacc4  lda $035f,x  ; $855e
        beq +
        sta $0398,x
+       sec
        lda zp32
        beq +

-       cmp #1
        beq ++
        cmp #2
        beq +++
        sbc #3
        bne -

+       ldy zp_arr4,x
        lda notes_lo-1,y
        sta zp_arr1,x
        lda notes_hi-1,y
        sta $0308,x
        rts

++      lda $0398,x
        lsr4
        clc
        adc zp_arr4,x
        tay
        lda notes_lo-1,y
        sta zp_arr1,x
        lda notes_hi-1,y
        sta $0308,x
        rts

+++     lda $0398,x
        and #%00001111
        clc
        adc zp_arr4,x
        tay
        lda notes_lo-1,y
        sta zp_arr1,x
        lda notes_hi-1,y
        sta $0308,x
        rts

; -------------------------------------------------------------------------------------------------

        ; Reads indirect_data1 via ptr6
        ; Called by: sound_engine, sound10
        ; Calls: sound10, sound10a, sound10g

sound9a lda $031c,x
        sta zp_arr3,x
        ;
        lda $03b4,x
        sta $0300,x
        ;
        lda apu_ctrl_or_masks,x
        ora apu_ctrl_mirror
        sta apu_ctrl_mirror
        ;
        jmp sound9f

sound9b jsr sound10

        ldx #3
sound9c lda $0355,x
        bne +
        jmp sound9f
+       cmp $0310,x
        beq sound9a
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
        bmi unacc5
        iny
        and #%01111111
        sta zp29
        lda $0394,x
        asl
        asl
        and #%10000000
        ora zp29
        sta zp_arr3,x
        sta $031c,x
        lda (ptr6),y
        sta zp29
        and #%11110000
        lsr
        lsr
        sta $0300,x
        sta $03b4,x
        lda zp29
        and #%00001111
        eor #%11111111
        add #1
        sta $0320,x
        jmp sound9d

        ; unaccessed block
unacc5  iny             ; $862d
        and #%01111111
        sta zp29
        lda $0394,x
        asl
        asl
        and #%10000000
        ora zp29
        sta zp_arr3,x
        sta $031c,x
        lda (ptr6),y
        sta zp29
        and #%11110000
        lsr
        lsr
        sta $0300,x
        lda zp29
        and #%00001111
        sta $0320,x

sound9d iny
        lda (ptr6),y
        iny
        sta zp29
        asl
        and #%10000000
        sta $034c,x
        lda zp29
        and #%00100000
        sta $03a8,x
        lda (ptr6),y
        tay
        and #%00001111
        bcs unacc6
        sta $0328,x
        tya
        lsr4
        sta $03a4,x
        lda zp29
        and #%00001111
        sta $032c,x
        jmp sound9e

        ; unaccessed block
unacc6  eor #%11111111  ; $8681
        add #1
        sta $0328,x
        tya
        lsr4
        eor #%11111111
        add #1
        sta $03a4,x
        lda zp29
        and #%00001111
        eor #%11111111
        add #1
        sta $032c,x

sound9e lda apu_ctrl_or_masks,x
        ora apu_ctrl_mirror
        sta apu_ctrl_mirror

sound9f ldy $0350,x
        beq sound9h
        cpy #$61
        beq sound9i
        sty zp_arr4,x

        lda #$00
        sta $039c,x
        sta $033c,x

        lda $031c,x
        sta zp_arr3,x

        lda apu_ctrl_or_masks,x
        ora apu_ctrl_mirror
        sta apu_ctrl_mirror

        lda $035a,x
        cmp #$03
        beq sound9h
        lda #$ff
        sta $03ac,x
        lda #$00
        sta $0330,x
        cpx #$03
        beq sound9j
        lda notes_lo-1,y
        sta zp_arr1,x
        lda notes_hi-1,y

sound9g sta $0308,x
        ;
        lda apu_ctrl_or_masks,x
        ora apu_ctrl_mirror
        sta apu_ctrl_mirror

sound9h dex
        bmi +
        jmp sound9c
+       jmp sound10g

sound9i lda apu_ctrl_and_masks,x
        and apu_ctrl_mirror
        sta apu_ctrl_mirror
        ;
        jmp sound9h

sound9j dey
        sty zp_arr1,x
        lda #$00
        jmp sound9g

sound9k lda #$00
        sta $038f,x
        jmp sound10a

; -------------------------------------------------------------------------------------------------

        ; Reads indirect_data1 via ptr2, ptr3, ptr5
        ; Called by: sound9
        ; Calls: sound8, sound9k

sound10 copy #$40, zp31

        ; clear $0350-$0363
        lda #$00
        ldx #4
-       sta $0350,x
        sta $0355,x
        sta $035a,x
        sta $035f,x
        dexbpl -

        lda zp34
        bne +
        lda zp32
        bne +
        jmp ++
+       jmp sound10b
++      lda zp35
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
        sta zp29
        lsr
        sty zp30
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
        asl zp29
        ldy zp30
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
        ; loop
-       lda $0364,x
        sta ptr2+0
        lda $0369,x
        sta ptr2+1
        ldy $0304,x
        lda (ptr2),y
        iny
        cmp #$00
        bne ++
        sta zp29
        lda (ptr2),y
        bne +         ; never taken
        jmp sound9k
+       lda zp29       ; unaccessed ($8798)
++      add ptr4+0
        sta $036e,x
        sta ptr3+0
        lda (ptr2),y
        adc ptr4+1
        sta $0373,x
        sta ptr3+1
        ;
        ldy #0
        lda (ptr3),y
        sta $038a,x
        iny
        lda (ptr3),y
        adc #1
        sta $038f,x
        ;
        adc #1
        lsr
        add #2
        sta zp_arr2,x
        lda #$00
        sta $0378,x
sound10a
        dexbpl -

sound10b
        ldx #4

sound10c
        dec $038f,x
        bmi +
        dec $038a,x
        bpl +
        jmp ++
+       jmp sound10f
++      lda $036e,x
        sta ptr2+0
        lda $0373,x
        sta ptr2+1
        lda zp34
        lsr
        tay
        iny
        iny
        lda (ptr2),y
        bcc +
        lsr4
+       ldy $0378,x
        sty zp29
        bit zp29
        ldy zp_arr2,x
        lsr
        sta zp29
        bcc sound10e

        cpx #$03
        beq ++

        bvs +

        lda (ptr2),y
        iny
        jmp sound10d

+       lda (ptr2),y
        and #%11110000
        sta zp30
        iny
        lda (ptr2),y
        and #%00001111
        ora zp30
        jmp sound10d

++      bvs +
        lda (ptr2),y
        and #%00001111
        sbc #$ff
        bit zp31
        jmp sound10d
+       lda (ptr2),y
        lsr4
        add #1
        iny
        clv
sound10d
        sta $0350,x
sound10e
        lsr zp29
        bcc ++
        bvs +
        lda (ptr2),y
        and #%00001111
        adc #0
        sta $0355,x
        bit zp31
        jmp ++
+       lda (ptr2),y
        lsr4
        iny
        add #1
        sta $0355,x
        clv
++      lsr zp29
        bcc +++
        bvs +
        lda (ptr2),y
        and #%00001111
        bit zp31
        jmp ++

+       lda (ptr2),y
        lsr4
        iny
        clv
++      sta $035a,x
+++     lsr zp29
        bcc +++
        bvs +
        lda (ptr2),y
        iny
        jmp ++
+       lda (ptr2),y
        and #%11110000
        sta zp30
        iny
        lda (ptr2),y
        and #%00001111
        ora zp30
++      sta $035f,x
+++     sty zp_arr2,x
        lda #$40
        bvs +
        lda #$00
+       sta $0378,x
sound10f
        dex
        bmi +
        jmp sound10c
+       rts

sound10g
        ldx #3
        ; loop
-       ldy zp_arr3,x
        bmi ++
        dey
        bpl +
        ;
        lda apu_ctrl_and_masks,x
        and apu_ctrl_mirror
        sta apu_ctrl_mirror
        ;
        lda #$00
        ldy #$00
+       sty zp_arr3,x
++      dexbpl -

        lda apu_ctrl
        and #%00010000
        bne +
        ;
        lda apu_ctrl_mirror
        and #%00001111
        sta apu_ctrl_mirror
+       copy apu_ctrl_mirror, apu_ctrl

        ldx #3
        ; loop
-       jsr sound8
        cpx #$02
        beq ++
        lda $0355,x
        bne +
        lda $035a,x
        cmp #$0c
        beq +
        jmp ++
+       lda $0300,x
        lsr
        lsr
        ora $0394,x
        ldy apu_reg_offsets,x  ; 0, 4, 8, 12
        sta pulse1_ctrl,y
++      dexbpl -

        inc $039c
        inc $039d
        inc $039e
        inc $039f
        inc zp34
        rts

; --- Unaccessed block ----------------------------------------------------------------------------

        ldxy #0, #16  ; $8906
-       dexbne -
        dey
        bne -

        dec useless
        bpl +
        copy #$05, useless
        lda #$1e
+       jsr sound_engine
        lda #$06
        rti
        rti

; -------------------------------------------------------------------------------------------------

        ; Just jump to sound_engine
        ; Called by: init_checkered, init_horzbars1, init_woman, many nmi_part's
        ; Calls: sound_engine

jump_snd_eng
        bit useless
        bmi +        ; always taken

        ; unaccessed
        dec useless  ; $8925
        bpl +
        copy #$05, useless
        jmp unacc7

+       jmp sound_engine

unacc7  rts  ; unaccessed ($8933)

; -------------------------------------------------------------------------------------------------

        ; Called by: init
        ; Calls: sub1

sub13   ldy #$ff
        dex
        beq +
        ldy #$05  ; unaccessed ($8939)
+       sty useless
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
        db 0, 4, 8, 12  ; read by: sound1, sound2, sound10
apu_ctrl_or_masks
        db %00000001, %00000010, %00000100, %00001000  ; read by sound9
apu_ctrl_and_masks
        db %11111110, %11111101, %11111011, %11110111  ; read by sound_engine, sound9, sound10

or_masks
        ; $8967 (some bytes unaccessed; read by sound5)
        hex 00 10 20 30 40 50 60 70 80 90 a0 b0 c0 d0 e0 f0
        hex e0 d0 c0 b0 a0 90 80 70 60 50 40 30 20 10 00

        ; $8986 (most bytes unaccessed)
        ; read by: sound5
        ; Math stuff? (On each line, the numbers increase linearly.)
table3  db  0,  0,  0,  1,  1,  1,  2,  2,  3,  3,  3,  4,  4,  4,  5,  5  ; value ~= h_index/4
        db  0,  0,  1,  2,  3,  3,  4,  5,  6,  6,  7,  8,  9,  9, 10, 11
        db  0,  1,  2,  3,  4,  5,  6,  8,  9, 10, 11, 12, 13, 15, 16, 17  ; value ~= h_index
        db  0,  1,  3,  4,  6,  7,  9, 10, 12, 13, 15, 16, 18, 19, 21, 22
        db  0,  1,  3,  5,  7,  9, 11, 13, 15, 16, 18, 20, 22, 24, 26, 28  ; value ~= h_index*2
        db  0,  2,  4,  6,  8, 11, 13, 15, 17, 19, 22, 24, 26, 28, 30, 33
        db  0,  2,  5,  7, 10, 12, 15, 17, 20, 22, 25, 27, 30, 32, 35, 37
        db  0,  2,  5,  8, 11, 14, 16, 19, 22, 25, 28, 30, 33, 36, 39, 42
        db  0,  3,  6,  9, 12, 15, 18, 21, 24, 27, 30, 33, 36, 40, 43, 46  ; value ~= h_index*3
        db  0,  3,  6,  9, 13, 16, 19, 23, 26, 29, 33, 36, 39, 43, 46, 49
        db  0,  3,  7, 10, 14, 17, 21, 24, 28, 31, 35, 38, 42, 45, 49, 52
        db  0,  3,  7, 11, 14, 18, 22, 25, 29, 33, 36, 40, 44, 47, 51, 55
        db  0,  3,  7, 11, 15, 19, 22, 26, 30, 34, 38, 41, 45, 49, 53, 57
        db  0,  3,  7, 11, 15, 19, 23, 27, 31, 35, 39, 42, 46, 50, 54, 58
        db  0,  3,  7, 11, 15, 19, 23, 27, 31, 35, 39, 43, 47, 51, 55, 59
        db  0,  3,  7, 11, 15, 19, 23, 27, 31, 35, 39, 43, 47, 51, 55, 59  ; value ~= h_index*4

        ; 96 integers. First all low bytes, then all high bytes.
        ; Disregarding the first nine values, each value equals approximately 0.944 times the
        ; previous value.
        ; Note frequencies?
        ; read by: sound6, sound7, sound9
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
ptr_lo  dl indirect_data1
ptr_hi  dh indirect_data1

        ; unaccessed ($8b48)
        hex 8d a0 8d a0 8d a0 8d a0 8d a0 8d a0 8d a0 8d a0
        hex 8d a0 8d a0 8d a0 8d a0 8d a0 8d a0 8d a0 8d a0

indirect_data1
        ; $8b68-$8dbf (600 bytes)
        ; read (via pointer_lo and pointer_hi) by: sub01, sound9, sound10
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

init    ; Called by: reset vector
        ; Calls: wait_vbl, hide_sprites, init_palette_copy, update_palette, fill_nt_and_clear_at,
        ;        init_star_sprites, fill_attribute_tables, sub13

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
        jsr init_palette_copy  ; palette_table -> palette_copy
        jsr update_palette  ; palette_copy -> PPU

        ; update fourth sprite subpalette
        set_ppu_addr vram_palette + 7*4
        copy #$0f, ppu_data  ; black
        copy #$1c, ppu_data  ; medium-dark cyan
        copy #$2b, ppu_data  ; medium-light green
        copy #$39, ppu_data  ; light yellow
        reset_ppu_addr

        copy #id_wecome, demo_part  ; the first part of the demo to run

        copy #%00000000, ppu_ctrl
        copy #%00011110, ppu_mask

        ldx #$ff
        jsr fill_nt_and_clear_at
        jsr init_star_sprites

        lda #%00000000
        sta ppu_ctrl
        sta ppu_mask

        ldy #$00
        jsr fill_attribute_tables
        copy #$ff, pulse1_ctrl

        reset_ppu_addr

        lda #$00
        ldx #$01
        jsr sub13
        jsr wait_vbl

        copy #%10000000, ppu_ctrl
        copy #%00011110, ppu_mask

        ; infinite loop; if at last part of the demo, do sound stuff
-       lda demo_part
        cmp #id_horzbars2
        bne +
        copy #$0d, dmc_addr
        copy #$fa, dmc_length
+       jmp -

; --- Lots of data --------------------------------------------------------------------------------

wecome_text_pointers  ; $c0a8
        dw wecome_text + 0*16
        dw wecome_text + 1*16
        dw wecome_text + 2*16
        dw wecome_text + 3*16
        dw wecome_text + 4*16
        dw wecome_text + 5*16
        dw wecome_text + 6*16
        dw wecome_text + 7*16  ; unaccessed ($c0b6)

wecome_text
        ; note: "l_^[" = " !-8"
        db "lllGREETINGS_lll"
        db "llWElCOMElFROMll"
        db "lANl[^BITlWORLDl"
        db "llBRINGINGlTHEll"
        db "llllGIFTlOFlllll"
        db "lGALACTIClDISCOl"
        db "GETlUPlANDlDANCE"
        db "MUSHROOMlMANIACS"  ; "MUSHROOM MANIACS" (unaccessed, $c128)

sprite_tiles  ; 22 bytes; read by: sub15
        hex 3a 3b 3c 3d 3e 3b 3f ff
        hex f1 f2 f3 f4 f5 ff f6 f7
        hex f5 3e f8 f9 f7 f3

friday_text
        ; 256 bytes; read by anim_friday; note:
        ; "[ef" = " ()", "abcd" = "ninja" in Japanese
        db "[[[[[[[[[[[[[["
        db "IT[IS[FRIDAY[AT[NINE[PM[AND[WE[STILL[ARE[TRYING[TO[SYNC[THIS[MOTHERFUCKER[[["
        db "GREETINGS[TO[NINTENDO[TECHNOLOGIES[FOR[THE[LOVELY[HARDWARE[[["
        db "HECK[[["
        db "WE[SHOULD[BE[ALREADY[DRUNK[[["
        db "JUST[LIKE[OUR[MUSICIAN[[["
        db "TERVEISET[PISSAPOSSELLE[eabcdf"
        db "[[[[[[[[[[[[[["

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

        ; text; note:
        ; "[]^_" = " +()", $5c = "/", $8b = "?", $8c-$8f = "1930"
gameover_text  ; 32*3 bytes
        db "[[[[[[[[[[[GAME[OVER[[[[[[[[[[[["
        db "[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[["
        db "[[[[[[[[[[[CONTINUE", $8b, "[[[[[[[[[[[["
greets_text  ; 32*20 bytes
        db "[[[[[[[[[[[NAE^M_OK[[[[[[[[[[[[["
        db "[[[[[[[[[BYTER^A_PERS[[[[[[[[[[["
        db "[[[[[[[JUMALAU^T_A[[[[[[[[[[[[[["
        db "[[[[[[[[[[[SHI^T_FACED[CLOWNS[[["
        db "[[[[[[[[[[[[[[^[_[[[[[[[[[[[[[[["
        db "[[[[[[[DEKADEN^C_E[[[[[[[[[[[[[["
        db "[[[[[[[ANANASM^U_RSKA[[[[[[[[[[["
        db "[[[[[[[[[[[[[T^R_ACTION[[[[[[[[["
        db "[[[[[[[[[[[[[D^R_AGON[MAGIC[[[[["
        db "[[[[[[[[[[[ASP^E_KT[[[[[[[[[[[[["
        db "[[[[[[[[[[[[[[^N_ALLEPERHE[[[[[["
        db "[[[[[[[[[[[[FI^T_[[[[[[[[[[[[[[["
        db "[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[["
        db "[[[[[[[[[[[[[[[][[[[[[[[[[[[[[[["
        db "[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[["
        db "[[PWP", $5c, "FAIRLIGHT", $5c, "MFX", $5c, "MOONHAZARD[["
        db "[[[[ISO", $5c, "RNO", $5c, "DAMONES", $5c, "HEDELMAE[[[["
        db "[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[["
        db "[[[[[[[[[[[[[WAMMA[[[[[[[[[[[[[["
        db "[QUALITY[PRODUCTIONS[SINCE[", $8c, $8d, $8e, $8f, "["

        ; tile numbers of top left tiles of big letters, starting from the big "A"
        ; (in the "we come from..." part)
big_letter_tiles
        hex 48 4a 4c 4e
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

unacc_data  ; unaccessed ($daea)
        hex 0b

unacc_table1  ; unaccessed
        hex 00 00 00
        hex 08 08 08
        hex 10 10 10
        hex 18 18 18

unacc_table2  ; unaccessed
        hex 00 01 02
        hex 10 11 12
        hex 20 21 22
        hex 30 31 32
        hex 40 40 40
        hex 40 40 40
        hex 40 40 40
        hex 40 40 40

unacc_table3  ; unaccessed
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
table9  hex 08 13 19 30 45 50 5e 67 80 88 9f ba c8 d1 e0 f4
        hex 18 25 34 50 54 55 6a 6f 9e ab cd d3 da e5 f0 ff
        hex 0a 19 3a 56 5a 5f 7b 80 90 af b9 c6 cf ea f7 fa
        hex 13 19 25 55 6a 6f 5e 67 80 88 ba c8 e1 eb f0 f4

sprite_tile_table3
        hex 40 43 42 41

        ; unaccessed ($dbb5)
        hex 03 00 00 07 07 42 43 52 53 03 03 03 03 00 07 00
        hex 07 01 00 00 41 51 03 03 00 07

data7   db 15

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
        db 10  ; number of stars, minus one
star_initial_x
        hex 13 50 54 6f 9e ab d0 ef 06 5a 5f d6 ca 13 19 25
star_initial_y
        hex 55 df 51 21 3d 9a 7d 88 cc 8f aa 43 8a 6e 90 76
star_y_speeds
        db 2, 3, 3, 5, 4, 2, 4, 3, 2, 2, 3, 4, 3, 2, 7, 6
star_tiles
        hex af ae ae be be bf af bf bf af ae ae bf be be be

        db $0f  ; unaccessed

        ; read by: init_friday, anim_friday
friday_sprites_x
        hex 40 48 40 48 80 88 80 88
        hex c0 c8 c0 c8 f0 f8 f0 f8
friday_sprites_y
        hex 32 32 3a 3a 80 80 88 88
        hex 68 68 70 70 b8 b8 c0 c0
friday_sprites_xadd
        db 3, 3, 3, 3
        db 5, 5, 5, 5
        db 2, 2, 2, 2
        db 4, 4, 4, 4
friday_sprites_tile
        hex ea eb fa fb ec ed fc fd
        hex ea eb fa fb ec ed fc fd

unacc_table4
        hex 00 03 06 03  ; unaccessed ($dc92)

; -------------------------------------------------------------------------------------------------

        ; Wait for VBlank ($dc96)
        ; Called by: init
        ; Calls: nothing
wait_vbl
-       bit ppu_status
        bpl -
        rts

; -------------------------------------------------------------------------------------------------

hide_sprites
        ; Hide all sprites by setting their Y positions outside the screen.
        ; Called by: init, init_horzbars1, init_credits, anim_credits, init_woman, anim_woman
        ;            init_bowser, init_cola, init_friday
        ; Calls: nothing

        ldx #0
-       lda #245
        sta sprite_page + 0,x
        inx
        inx
        inx
        inx
        bne -
        rts

; --- Unaccessed block ----------------------------------------------------------------------------

        lda #%00000000  ; $dcaa
        sta ppu_ctrl
        sta ppu_mask
        copy #%00000000, ppu_ctrl

        ; clear sound registers
        lda #$00
        ldx #0
-       sta apu_regs,x
        inx
        cpx #15
        bne -

        copy #$c0, apu_counter

        jsr init_palette_copy  ; palette_table -> palette_copy
        jsr update_palette  ; palette_copy -> PPU
        rts

; -------------------------------------------------------------------------------------------------

init_palette_copy
        ; Copy the palette_table array to the palette_copy array.
        ; Args: none
        ; Called by: init, hide_sprites, init_checkered, init_gradients, init_horzbars1,
        ;            init_credits, anim_woman, init_gameover, anim_greets
        ; Calls: nothing

        ldx #0
-       lda palette_table,x
        sta palette_copy,x
        inx
        cpx #32
        bne -
        rts

; -------------------------------------------------------------------------------------------------

clear_palette_copy
        ; Fill palette_copy array with black.
        ; Args: none
        ; Called by: init_greets
        ; Calls: nothing

        ldx #0
-       lda #$0f  ; black
        sta palette_copy,x
        inx
        cpx #32
        bne -
        rts

; -------------------------------------------------------------------------------------------------

update_palette
        ; Copy the palette_copy array to the PPU.
        ; Args: none
        ; Called by: init, hide_sprites, anim_title, init_checkered, init_gradients,
        ;            init_horzbars1, init_credits, anim_credits, anim_woman, init_gameover,
        ;            init_greets, anim_greets
        ; Calls: nothing

        set_ppu_addr vram_palette + 0*4

        ldx #0
-       lda palette_copy,x
        sta ppu_data
        inx
        cpx #32
        bne -

        reset_ppu_addr
        rts

; -------------------------------------------------------------------------------------------------

delay   ; Delay for raster effects.
        ; Add #$55 (85) to delay_var1 X times.
        ; Called by: anim_checkered, anim_horzbars1, anim_woman, anim_cola
        ; Calls: nothing

        stx delay_var2
        copy #0, delay_cnt  ; loop counter

delay_loop
        lda delay_var1
        add #85
        bcc +
+       sta delay_var1

        inclda delay_cnt
        cmp delay_var2
        bne delay_loop

        rts

; --- Unaccessed block ----------------------------------------------------------------------------

        stx delay_var2  ; $dd22
        ldx #0
        ;
-       add #85
        clc
        nop
        nop
        adc #15
        sbc #15
        inx
        cpx delay_var2
        bne -

        rts

        stx delay_var2
        ldy #0
        ldx #0
        ;
--      ldy #0
-       nop
        nop
        nop
        nop
        nop
        iny
        cpy #11
        bne -
        ;
        nop
        inx
        cpx delay_var2
        bne --

        rts

; -------------------------------------------------------------------------------------------------

fade_out_palette
        ; Change each color in the palette_copy array (32 bytes).
        ; Called by: anim_title, anim_credits, anim_greets
        ; Calls: nothing

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
        ; Change background color: #$3f (black) if zp38 < 8, otherwise zp38.
        ; Called by: anim_gradients
        ; Calls: nothing

        set_ppu_addr vram_palette + 0*4

        lda zp38
        cmp #8
        bcc +
        copy zp38, ppu_data
        jmp ++
        ;
+       copy #$3f, ppu_data  ; black
++      rts

; -------------------------------------------------------------------------------------------------

update_sixteen_sprites
        ; Update 16 (8*2) sprites.
        ; Called by: anim_credits
        ; Calls: nothing

        ; Input: X, Y, zp12, zp24

        ; Modifies: A, X, Y, zp12, zp14, zp21, zp22, zp23, zp24, zp13

        ; Sprite page offsets: zp24 * 4 ... (zp24 + 15) * 4
        ; Tiles: zp12 ... zp12+15
        ; X positions: X+0, X+8, ..., X+56, X+0, X+8, ..., X+56
        ; Y positions: Y for first 8 sprites, Y+8 for the rest
        ; Subpalette: always 3

        stx zp21
        sty zp22
        copy zp12, zp23
        lda #$00
        sta zp12
        sta zp13
        sta zp14

update_sixteen_sprites_loop_outer
        ; counter: zp13 = 0, 8

        ldx #0
        copy #$00, zp12

update_sixteen_sprites_loop_inner
        ; counter: X = 0, 8, ..., 56

        ; update sprite at offset zp24

        ; zp23 + zp14 -> sprite tile
        lda zp14
        add zp23
        ldy zp24
        sta sprite_page + 1,y

        ; zp21 + X -> sprite X
        txa
        adc zp21
        ldy zp24
        sta sprite_page + 3,y

        ; zp22 + zp13 -> sprite Y
        lda zp13
        add zp22
        ldy zp24
        sta sprite_page + 0,y

        ; 3 -> sprite subpalette
        lda #%00000011
        ldy zp24
        sta sprite_page + 2,y

        lda zp12
        add #4
        sta zp12

        inc zp14

        ; Y + 4 -> zp24
        iny4
        sty zp24

        ; X += 8
        ; loop while less than 64
        txa
        add #8
        tax
        cpx #64
        bne update_sixteen_sprites_loop_inner

        ; zp13 += 8
        ; loop while less than 16
        lda zp13
        add #8
        sta zp13
        lda zp13
        cmp #16
        bne update_sixteen_sprites_loop_outer

        sty zp24
        rts

; -------------------------------------------------------------------------------------------------

update_six_sprites
        ; Update 6 (3*2) sprites.
        ; Called by: anim_credits
        ; Calls: nothing

        ; Input: X, Y, zp12, zp24

        ; Sprite page offsets: zp24 * 4 ... (zp24 + 5) * 4
        ; Tiles: zp12 ... zp12+5
        ; X positions: X+0, X+8, X+16, X+0, X+8, X+16
        ; Y positions: Y+0, Y+0, Y+0, Y+8, Y+8, Y+8
        ; Subpalette: always 2

        stx zp21
        sty zp22
        copy zp12, zp23
        lda #$00
        sta zp12
        sta zp13
        sta zp14

update_six_sprites_loop_outer
        ; counter: zp13 = 0, 8

        ldx #0
        copy #$00, zp12

update_six_sprites_loop_inner
        ; counter: X = 0, 8, 16

        ; update sprite at offset zp24

        ; zp23 + zp14 -> sprite tile
        lda zp14
        add zp23
        ldy zp24
        sta sprite_page + 1,y

        ; zp21 + X -> sprite X
        txa
        adc zp21
        ldy zp24
        sta sprite_page + 3,y

        ; zp22 + zp13 -> sprite Y
        lda zp13
        add zp22
        ldy zp24
        sta sprite_page + 0,y

        ; 2 -> sprite subpalette
        lda #%00000010
        ldy zp24
        sta sprite_page + 2,y

        lda zp12
        add #4
        sta zp12

        inc zp14

        ; Y + 4 -> zp24
        iny4
        sty zp24

        ; X += 8
        ; loop while less than 24
        txa
        add #8
        tax
        cpx #24
        bne update_six_sprites_loop_inner

        ; zp13 += 8
        ; loop while less than 16
        lda zp13
        add #8
        sta zp13
        lda zp13
        cmp #16
        bne update_six_sprites_loop_outer

        sty zp24
        rts

; -------------------------------------------------------------------------------------------------

update_eight_sprites
        ; Update 8 (4*2) sprites.
        ; Called by: anim_credits
        ; Calls: nothing

        ; Input: X, Y, zp12, zp24

        ; Sprite page offsets: zp24 * 4 ... (zp24 + 7) * 4
        ; Tiles: zp12 ... zp12+7
        ; X positions: X+0, X+8, ..., X+24, X+0, X+8, ..., X+24
        ; Y positions: Y+0 for first 4 sprites, Y+8 for the rest
        ; Subpalette: always 2

        stx zp21
        sty zp22
        copy zp12, zp23
        lda #$00
        sta zp12
        sta zp13
        sta zp14

        ; outer loop (zp13 = 0, 8)
--      ldx #0
        copy #$00, zp12
        ;
        ; inner loop (X = 0, 8, 16, 24)
        ;
-       ; update sprite at offset zp24
        ;
        ; zp23 + zp14 -> sprite tile
        lda zp14
        add zp23
        ldy zp24
        sta sprite_page + 1,y
        ;
        ; zp21 + X -> sprite X
        txa
        adc zp21
        ldy zp24
        sta sprite_page + 3,y
        ;
        ; zp22 + zp13 -> sprite Y
        lda zp13
        add zp22
        ldy zp24
        sta sprite_page + 0,y
        ;
        ; 2 -> sprite subpalette
        lda #%00000010
        ldy zp24
        sta sprite_page + 2,y
        ;
        lda zp12
        add #4
        sta zp12
        ;
        inc zp14
        ;
        iny4
        sty zp24
        ;
        ; end inner loop
        txa
        add #8
        tax
        cpx #32
        bne -
        ;
        ; end outer loop
        lda zp13
        add #8
        sta zp13
        lda zp13
        cmp #16
        bne --

        sty zp24
        rts

; -------------------------------------------------------------------------------------------------

sub15   ; Called by: anim_title
        ; Calls: nothing

        ldxy #0, #0
        stx zp12
        stx zp13

        ; loop (Y = 0 to 21)
-       lda sprite_tiles,y
        cmp #$ff
        bne +
        ;
        lda zp13
        add #14
        sta zp13
        jmp ++
        ;
+       lda #$e1
        add zp13
        sta sprite_page + 0,x
        sta $0154,y
        ;
        lda zp13
        sta $016a,y
        ;
        lda #$01
        sta $0180,y
        ;
        lda sprite_tiles,y
        sta sprite_page + 1,x
        ;
        lda #$00
        sta sprite_page + 2,x
        ;
        lda zp12
        add #40
        sta sprite_page + 3,x
        ;
++      inx
        inx
        inx
        inx
        iny
        lda zp12
        add #8
        sta zp12
        cpy #22
        bne -

        rts

; -------------------------------------------------------------------------------------------------

macro get_top_left_tile_of_big_letter
        ; tile determined by offset -> X
        ldy offset
        lda (big_text_ptr),y
        clc
        sbc #$40
        tay
        ldx big_letter_tiles,y
endm

print_big_text_line
        ; Write a line of big text (64 tiles) to PPU.
        ; Args: X/Y = PPU addr hi/lo, big_text_ptr = start address in wecome_text
        ; Called by: anim_wecome
        ; Calls: nothing

        stx ppu_addr_hi
        sty ppu_addr_lo
        copy ppu_addr_hi, ppu_addr
        copy ppu_addr_lo, ppu_addr

        ; top halves of one row of big letters: read 16 bytes via big_text_ptr, subtract 0x41
        ; (ASCII "A") from each, use as index to big_letter_tiles, write that byte and that
        ; byte + 1 to PPU
        ldxy #0, #0
        stx offset
        ;
-       get_top_left_tile_of_big_letter
        stx ppu_data
        inx
        stx ppu_data
        ;
        inclda offset
        cmp #16
        bne -

        ; same for bottom halves of one row of big letters, but add 16/17 to tile number
        copy #0, offset
        ;
-       get_top_left_tile_of_big_letter
        txa
        add #16
        tax
        stx ppu_data
        inx
        stx ppu_data
        ;
        inclda offset
        cmp #16
        bne -

        reset_ppu_addr
        rts

; -------------------------------------------------------------------------------------------------

move_stars_up
        ; Move star sprites up.
        ; Called by: anim_wecome, anim_title
        ; Calls: nothing

        copy #$00, zp12
        ldx star_count  ; 10

        ; loop: subtract star_y_speeds,x + 1 from Y positions of sprites 45-55
        ;
-       ; X*4 -> Y
        txa
        asl
        asl
        tay
        ;
        lda sprite_page + 45*4 + 0, y
        clc
        sbc star_y_speeds,x
        sta sprite_page + 45*4 + 0, y
        ;
        dex
        cpx #255
        bne -

        rts

; -------------------------------------------------------------------------------------------------

init_star_sprites
        ; Initialize star sprites for the first two parts of the demo.
        ; Called by: init
        ; Calls: nothing

        ldx star_count  ; 10

        ; loop - edit sprites
        ; X*4 -> Y
-       txa
        asl
        asl
        tay
        ;
        lda star_initial_y,x
        sta sprite_page + 45*4 + 0,y
        lda star_tiles,x
        sta sprite_page + 45*4 + 1,y
        lda #%00000011
        sta sprite_page + 45*4 + 2,y
        lda star_initial_x,x
        sta sprite_page + 45*4 + 3,y
        lda star_y_speeds,x
        sta $011e,x
        ;
        dex
        cpx #255
        bne -

        rts

; -------------------------------------------------------------------------------------------------

macro print_big_text_line_macro _srcline, _dstline
        ; print a line of big text
        copy wecome_text_pointers + _srcline*2 + 0, big_text_ptr+0
        copy wecome_text_pointers + _srcline*2 + 1, big_text_ptr+1
        ldxy #>(name_table0 + _dstline*32), #<(name_table0 + _dstline*32)
        jsr print_big_text_line
endm

anim_wecome
        ; Animate "GREETINGS! WE COME FROM..." part.
        ; Called by: nmi_wecome
        ; Calls: print_big_text_line, sub19

        chr_bankswitch 0
        lda counter2

        cmp #1
        beq jump_table1 + 1*3
        cmp #2
        beq jump_table1 + 2*3
        cmp #3
        beq jump_table1 + 3*3
        cmp #4
        beq jump_table1 + 4*3
        cmp #5
        beq jump_table1 + 5*3
        cmp #6
        beq jump_table1 + 6*3
        cmp #7
        beq jump_table1 + 7*3
        cmp #8
        beq jump_table1 + 8*3
        cmp #9
        beq +
        cmp #10
        beq jump_table1 + 10*3
        jmp bigtext_exit

+       copy #0, ppu_scroll
        ldx vscroll
        lda curve1,x
        add vscroll
        sta ppu_scroll

        lda vscroll
        cmp #220
        bne +
        jmp ++
        ;
+       inc vscroll
        inc vscroll

++      copy #%10000000, ppu_ctrl
        copy #%00011110, ppu_mask

jump_table1
        jmp bigtext_exit    ;  0
        jmp print_bigtext1  ;  1
        jmp reset_scroll    ;  2
        jmp print_bigtext2  ;  3
        jmp print_bigtext3  ;  4
        jmp print_bigtext4  ;  5
        jmp print_bigtext5  ;  6
        jmp print_bigtext6  ;  7
        jmp print_bigtext7  ;  8
        jmp bigtext_exit    ;  9 (unaccessed, $e013)
        jmp to_next_part    ; 10

print_bigtext1
        print_big_text_line_macro 0, 0
        ; update&decrement vertical scroll, reset if >= 240
        copy #0,      ppu_scroll
        copy vscroll, ppu_scroll
        dec vscroll
        lda vscroll
        cmp #240
        bcs +
        jmp bigtext_exit
+       copy #0, vscroll
        jmp bigtext_exit
reset_scroll
        copy #0, vscroll
        jmp bigtext_exit
print_bigtext2
        print_big_text_line_macro 1, 5
        jmp bigtext_exit
print_bigtext3
        print_big_text_line_macro 2, 9
        jmp bigtext_exit
print_bigtext4
        print_big_text_line_macro 3, 13
        jmp bigtext_exit
print_bigtext5
        print_big_text_line_macro 4, 18
        jmp bigtext_exit
print_bigtext6
        print_big_text_line_macro 5, 22
        jmp bigtext_exit
print_bigtext7
        print_big_text_line_macro 6, 26
        jmp bigtext_exit
to_next_part
        copy #id_title, demo_part  ; next part
        copy #0, flag1
        jmp bigtext_exit
bigtext_exit
        jmp sub19

; --- Unaccessed block ----------------------------------------------------------------------------

macro set_sprite_pos _index, _ycurve, _yadd, _xcurve, _xadd
        lda _ycurve,x
        add #_yadd
        sta sprite_page + _index*4 + 0
        lda _xcurve,x
        add #_xadd
        sta sprite_page + _index*4 + 3
endm

macro move_four_sprites _i1, _i2, _i3, _i4
        dec sprite_page + _i1*4 + 0
        dec sprite_page + _i1*4 + 3

        dec sprite_page + _i2*4 + 0
        inc sprite_page + _i2*4 + 3

        inc sprite_page + _i3*4 + 0
        dec sprite_page + _i3*4 + 3

        inc sprite_page + _i4*4 + 0
        inc sprite_page + _i4*4 + 3
endm

        copy #$00, zp12  ; $e0d3
        lda vscroll
        cmp #$a0
        bcc +
        jmp ++
+       ldx unused1

        set_sprite_pos 0, curve1, 88, curve2, 110
        set_sprite_pos 1, curve1, 88, curve2, 118
        set_sprite_pos 2, curve1, 96, curve2, 110
        set_sprite_pos 3, curve1, 96, curve2, 118
        set_sprite_pos 4, curve2, 88, curve1, 110
        set_sprite_pos 5, curve2, 88, curve1, 118
        set_sprite_pos 6, curve2, 96, curve1, 110
        set_sprite_pos 7, curve2, 96, curve1, 117

        jmp sub19

++      move_four_sprites 0, 1, 2, 3
        move_four_sprites 4, 5, 6, 7

; -------------------------------------------------------------------------------------------------

sub19   ; Called by: anim_wecome
        ; Calls: move_stars_up
        ;
        jsr move_stars_up
        copy #>sprite_page, oam_dma  ; do sprite DMA
        rts

; -------------------------------------------------------------------------------------------------

init_title
        ; Set up title part (wAMMA logo).
        ; Called by: nmi_title
        ; Calls: fill_name_tables

        ; clear Name Tables
        ldx #$00
        jsr fill_name_tables

        ldy #$00
        ldy #$00

        ; fill rows 1-8 of Name Table 2 with #$00-#$ff
        set_ppu_addr name_table2+32
        ldx #0
-       stx ppu_data
        inx
        bne -

        reset_ppu_addr

        ; update first and second color in first sprite subpalette
        set_ppu_addr vram_palette + 4*4
        copy #$00, ppu_data  ; dark gray
        copy #$30, ppu_data  ; white
        reset_ppu_addr

        ; update second and third sprite subpalette
        set_ppu_addr vram_palette + 5*4 + 1
        copy #$3d, ppu_data  ; light gray
        copy #$0c, ppu_data  ; dark cyan
        copy #$3c, ppu_data  ; light cyan
        copy #$0f, ppu_data  ; black
        copy #$3c, ppu_data  ; light cyan
        copy #$0c, ppu_data  ; dark cyan
        copy #$1a, ppu_data  ; medium-dark green
        reset_ppu_addr

        ; update first background subpalette
        set_ppu_addr vram_palette + 0*4
        copy #$38, ppu_data  ; light yellow
        copy #$01, ppu_data  ; dark purple
        copy #$26, ppu_data  ; medium-light red
        copy #$0f, ppu_data  ; black
        reset_ppu_addr

        copy #1, flag1
        copy #$8e, $012e
        copy #$19, $012f
        copy #%00011110, ppu_mask
        rts

; -------------------------------------------------------------------------------------------------

anim_title
        ; Animate title part (wAMMA logo).
        ; Called by: nmi_title
        ; Calls: sub15, fade_out_palette, update_palette, move_stars_up

        chr_bankswitch 0
        copy #>sprite_page, oam_dma  ; do sprite DMA

        copy #%10010000, ppu_ctrl

        ; update fourth color of first background subpalette
        set_ppu_addr vram_palette + 0*4 + 3
        copy #$0f, ppu_data  ; black
        reset_ppu_addr

        copy #0, ppu_scroll
        ldx $014e
        lda curve1,x
        add $014e
        sta ppu_scroll

        lda $014e
        cmp #$c1
        beq +
        inc $014e
+       lda zp28
        cmp #$02
        bne +
        ;
        lda zp27
        cmp #$32
        bne +
        ;
        jsr sub15
+       lda zp28
        cmp #$01
        bne anim_title_1
        ;
        lda zp27
        cmp #$96
        bne anim_title_1
        ;
        ldx data1

        ; loop - edit sprites
-       txa
        asl
        asl
        tay
        ;
        lda sprite_y_table1,x
        add $012f
        sta sprite_page + 23*4 + 0,y
        lda sprite_tile_table1,x
        sta sprite_page + 23*4 + 1,y
        lda sprite_attr_table1,x
        sta sprite_page + 23*4 + 2,y
        lda sprite_x_table1,x
        add $012e
        sta sprite_page + 23*4 + 3,y
        ;
        cpx #0
        beq +
        dex
        jmp -

        ; edit sprite #24
+       copy #129,       sprite_page + 24*4 + 0
        copy #$e5,       sprite_page + 24*4 + 1
        copy #%00000001, sprite_page + 24*4 + 2
        copy #214,       sprite_page + 24*4 + 3

        ; edit sprite #25
        copy #97,        sprite_page + 25*4 + 0
        copy #$f0,       sprite_page + 25*4 + 1
        copy #%00000010, sprite_page + 25*4 + 2
        copy #230,       sprite_page + 25*4 + 3

        ; update fourth color of first background subpalette
        set_ppu_addr vram_palette + 0*4 + 3
        copy #$30, ppu_data  ; white
        reset_ppu_addr

anim_title_1
        lda zp28
        cmp #$02
        bne anim_title_2
        lda zp27
        cmp #$32
        bcc anim_title_2

        ldxy #0, #0
        ; loop
-       lda $0180,x
        cmp #$01
        bne +
        ;
        lda #$a0
        clc
        adc $016a,x
        sta zp12
        lda $0154,x
        sta sprite_page + 0,y
        cmp zp12
        bcc +
        ;
        txa
        pha
        inc $0196,x
        lda $0196,x
        sta zp14
        tax
        lda curve1,x
        sta zp13
        pla
        tax
        lda $0154,x
        clc
        sbc zp13
        sbc zp14
        sta $0154,x
        ;
+       inx
        iny4
        cpx #22
        bne -

anim_title_2
        lda zp28
        cmp #$02
        bne +
        lda zp27
        cmp #$c8
        bcc +
        inclda zp20
        cmp #$04
        bne +

        jsr fade_out_palette
        jsr update_palette  ; palette_copy -> PPU
        copy #$00, zp20

+       jsr move_stars_up
        copy #id_title, demo_part
        rts

; -------------------------------------------------------------------------------------------------

init_horzbars2
        ; Set up full-screen horizontal color bars.
        ; Called by: nmi_horzbars2
        ; Calls: fill_nt_and_clear_at

        lda #$00
        ldx #0
-       sta pulse1_ctrl,x
        inx
        cpx #15
        bne -

        copy #$0a, dmc_addr
        copy #$fa, dmc_length
        copy #$4c, dmc_ctrl
        copy #$1f, apu_ctrl
        copy #$ff, dmc_load
        ldx #$00
        jsr fill_nt_and_clear_at
        copy #1, flag1
        rts

; -------------------------------------------------------------------------------------------------

anim_horzbars2
        ; Animate full-screen horizontal color bars.
        ; Called by: nmi_horzbars2
        ; Calls: nothing

        inc zp1
        ldx zp2
        lda curve3,x
        add #$96
        sta zp3
        dec zp2
        ldx zp2
        lda curve2,x
        sta zp5

        copy #%10000100, ppu_ctrl

        copy #$00, zp1
        ldy #$9f

        ; loop
--      ldx #25
-       dexbne -
        ;
        set_ppu_addr_via_x vram_palette + 0*4
        inclda zp4
        cmp #$05
        beq +
        jmp ++
        ;
+       inc zp1
        copy #$00, zp4
++      inclda zp1
        sbc zp2
        adc zp3
        tax
        lda curve3,x
        sbc zp5
        and #%00111111
        tax
        lda table5,x
        sta ppu_data
        ldx zp3
        lda curve1,x
        tax
        dey
        bne --

        copy #%00000110, ppu_mask
        copy #%10010000, ppu_ctrl
        rts

; -------------------------------------------------------------------------------------------------

init_checkered
        ; Set up checkered wavy animation.
        ; Called by: nmi_checkered
        ; Calls: fill_name_tables, fill_attribute_tables, jump_snd_eng, init_palette_copy,
        ;        update_palette

        ; clear Name Tables
        ldx #$00
        jsr fill_name_tables

        lda #%00000000
        sta ppu_ctrl
        sta ppu_mask

        ldy #$14
        jsr fill_attribute_tables
        jsr jump_snd_eng
        jsr init_palette_copy  ; palette_table -> palette_copy
        jsr update_palette  ; palette_copy -> PPU

        ; update first color of fourth background subpalette
        set_ppu_addr vram_palette + 3*4
        copy #$0f, ppu_data  ; black
        reset_ppu_addr

        copy #1, flag1
        copy #5, ram1
        rts

; -------------------------------------------------------------------------------------------------

anim_checkered
        ; Animate checkered wavy animation.
        ; Called by: nmi_checkered
        ; Calls: delay

        chr_bankswitch 1
        lda $0148
        cmp #$00
        beq +
        jmp anim_checkered_1
+       dec zp2

        ldx #0
        copy #$00, zp1
        ;
-       lda zp1
        adc zp2
        tay
        lda curve1,y
        sta $0600,x
        lda zp1
        add ram1
        sta zp1
        inx
        cpx #64
        bne -

        ldxy #0, #0
        copy #$00, zp12

--      copy #$21, ppu_addr
        copy zp12, ppu_addr

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

        lda zp12
        add #32
        sta zp12
        lda zp12
        cmp #$00
        bne --

        copy #$01, $0148
        jmp anim_checkered_2

anim_checkered_1
        dec zp2
        ldx #64
        copy #$00, zp1

-       lda zp1
        adc zp2
        tay
        lda curve1,y
        sta $0600,x
        lda zp1
        add ram1
        sta zp1
        inx
        cpx #128
        bne -

        ldx #$7f
        copy #$00, zp12

--      copy #$22, ppu_addr
        copy zp12, ppu_addr

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

        lda zp12
        add #32
        sta zp12
        lda zp12
        cmp #$00
        bne --

        copy #$00, $0148

anim_checkered_2
        reset_ppu_addr

        copy #$00, zp1

-       ldx #$04
        jsr delay
        lda zp1
        add zp3
        tax
        lda curve1,x
        sta ppu_scroll
        copy #0, ppu_scroll
        inc zp1
        iny
        cpy #$98
        bne -

        ldx zp3
        lda curve3,x
        sbc zp3
        sbc zp3
        copy #0, ppu_scroll

        ldx zp3
        lda curve2,x
        clc
        sbc #10

        copy #230, ppu_scroll
        dec zp3

        copy #%00001110, ppu_mask
        copy #%10000000, ppu_ctrl
        rts

; -------------------------------------------------------------------------------------------------

init_gradients
        ; Set up red&purple gradients.
        ; Called by: nmi_gradients
        ; Calls: fill_name_tables, init_palette_copy, update_palette, fill_attribute_tables,
        ;        fill_attribute_tables_top

        ; clear Name Tables
        ldx #$00
        jsr fill_name_tables

        jsr init_palette_copy  ; palette_table -> palette_copy
        jsr update_palette  ; palette_copy -> PPU

        lda #%00000000
        sta ppu_ctrl
        sta ppu_mask

        ldy #$ff
        jsr fill_attribute_tables
        ldy #$55
        jsr fill_attribute_tables_top

        ; update first color of fourth background subpalette
        set_ppu_addr vram_palette + 3*4
        copy #$0f, ppu_data  ; black
        reset_ppu_addr

        copy #1, flag1
        rts

; -------------------------------------------------------------------------------------------------

anim_gradients
        ; Animate red&purple gradients.
        ; Called by: nmi_gradients
        ; Calls: change_background_color

        jsr change_background_color
        chr_bankswitch 1
        dec zp2
        dec zp2

        ldx #0
        copy #0, zp1
-       lda zp1
        adc zp2
        tay
        lda curve1,y
        adc #$46
        sta $0600,x
        inc zp1
        inx
        cpx #128
        bne -

        lda $0148
        cmp #$00
        beq +
        jmp anim_gradients_1

+       ldxy #0, #0
        lda #$00

        sta zp12
--      copy #$21, ppu_addr
        copy zp12, ppu_addr

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

        lda zp12
        add #32
        sta zp12
        lda zp12
        cmp #$00
        bne --

        copy #$01, $0148
        jmp anim_gradients_2

anim_gradients_1
        ldx #$7f
        copy #$20, zp12

--      copy #$22, ppu_addr
        copy zp12, ppu_addr

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

        lda zp12
        add #32
        sta zp12
        lda zp12
        cmp #$00
        bne --

        copy #$00, $0148

anim_gradients_2
        reset_ppu_addr

        ldx zp3
        lda curve3,x
        sbc zp3
        sbc zp3
        sbc zp3
        sbc zp3
        sbc zp3
        sbc zp3
        sta ppu_scroll

        ldx zp3
        lda curve2,x
        clc
        sbc #10
        sta ppu_scroll

        dec zp3

        copy #%00001110, ppu_mask
        copy #%10000000, ppu_ctrl
        rts

; -------------------------------------------------------------------------------------------------

init_horzbars1
        ; Set up non-full-screen horizontal color bars.
        ; Called by: nmi_horzbars1
        ; Calls: fill_nt_and_clear_at, jump_snd_eng, init_palette_copy, update_palette,
        ;        hide_sprites

        ldx #$ff
        jsr fill_nt_and_clear_at
        jsr jump_snd_eng
        jsr init_palette_copy  ; palette_table -> palette_copy
        jsr update_palette  ; palette_copy -> PPU
        copy #1, flag1
        jsr hide_sprites

        lda #$00
        sta zp1
        sta zp2
        sta zp3
        sta zp4

        copy #%00000000, ppu_mask
        copy #%10000000, ppu_ctrl
        rts

; -------------------------------------------------------------------------------------------------

anim_horzbars1
        ; Animate non-full-screen horizontal color bars.
        ; Called by: nmi_horzbars1
        ; Calls: delay

        dec zp4
        inclda zp3
        cmp #$02
        bne +

        copy #$00, zp3
        dec zp2

+       copy #%10000100, ppu_ctrl

        ; update first color of first background subpalette
        set_ppu_addr_via_x vram_palette + 0*4
        copy #$0f, ppu_data  ; black
        reset_ppu_addr

        ldx #$ff
        jsr delay
        ldx #$01
        jsr delay

        ; update first color of first background subpalette
        set_ppu_addr_via_x vram_palette + 0*4
        copy #$0f, ppu_data  ; black
        reset_ppu_addr

        copy #$00, zp1

        ldy #85
        ; loop
--      ldx #25
-       dexbne -
        ;
        set_ppu_addr_via_x vram_palette + 0*4
        ldx zp2
        lda curve3,x
        sta zp12
        dec zp1
        lda zp1
        add zp2
        tax
        lda curve2,x
        clc
        sbc zp12
        adc zp4
        tax
        lda table5,x
        sta ppu_data
        dey
        bne --

        reset_ppu_addr

        ; update first color of first background subpalette
        set_ppu_addr_via_x vram_palette + 0*4
        copy #$0f, ppu_data  ; black
        reset_ppu_addr
        rts

; -------------------------------------------------------------------------------------------------

init_credits
        ; Set up credits part.
        ; Called by: nmi_credits
        ; Calls: fill_name_tables, init_palette_copy, update_palette, hide_sprites

        ; fill Name Tables with #$ff
        ldx #$ff
        jsr fill_name_tables

        jsr init_palette_copy  ; palette_table -> palette_copy
        jsr update_palette  ; palette_copy -> PPU

        ; update fourth sprite subpalette
        set_ppu_addr vram_palette + 7*4
        copy #$0f, ppu_data  ; black
        copy #$19, ppu_data  ; medium-dark green
        copy #$33, ppu_data  ; light purple
        copy #$30, ppu_data  ; white
        reset_ppu_addr

        set_ppu_addr name_table0

init_credits_1
        ; TODO: Something doesn't add up here: we write 768+160+64 = 992 bytes to PPU; why not
        ; 960 or 1024? I'm probably missing something.

        ; a quadruple loop:
        ;   outermost:     zp16 = 0 to 2;         write 3*8*4*8 = 768 bytes to PPU
        ;   2nd-outermost: zp15 = 0 to 48 step 8; write 8*4*8 = 256 bytes
        ;   2nd-innermost: Y = 0 to 3;            write 4*8 = 32 bytes
        ;   innermost:     X = 0 to 7;            write 8 bytes (zp15+0 to zp15+7)
        copy #0, zp15
        copy #0, zp16
---     ldy #0         ; start outermost and 2nd-outermost
--      ldx #0         ; start 2nd-innermost
-       txa            ; start innermost
        add zp15
        sta ppu_data
        inx
        cpx #8
        bne -          ; end innermost
        ;
        iny
        cpy #4
        bne --         ; end 2nd-innermost
        ;
        lda zp15
        add #8
        sta zp15
        lda zp15
        cmp #64
        bne ---        ; end 2nd-outermost
        ;
        copy #0, zp15
        inclda zp16
        cmp #3
        bne ---        ; end outermost

        ; triple loop:
        ;   outermost: zp15 = 0 to 32 step 8; write 5*4*8 = 160 bytes to PPU
        ;   middle:    Y = 0 to 3;            write 4*8 = 32 bytes
        ;   innermost: X = 0 to 7;            write 8 bytes (zp15+0 to zp15+7)
        ldx #0
---     ldy #0        ; start outermost
--      ldx #0        ; start middle
-       txa           ; start innermost
        add zp15
        sta ppu_data
        inx
        cpx #8
        bne -         ; end innermost
        ;
        iny
        cpy #4
        bne --        ; end middle
        ;
        lda zp15
        add #8
        sta zp15
        cmp #40
        bne ---       ; end outermost

        lda #$f0  ; unnecessary

        ; write 8*8 = 64 bytes to PPU ($f0-$f7 eight times)
        ; attribute data?
        ldy #0
        ; loop
--      ldx #$f0
-       stx ppu_data
        inx
        cpx #$f8
        bne -
        ;
        iny
        cpy #8
        bne --

        reset_ppu_addr
        inclda zp17
        cmp #$02
        bne +
        jmp init_credits_2

+       set_ppu_addr name_table2

        jmp init_credits_1

init_credits_2
        ; clear Attribute Table 0
        set_ppu_addr attr_table0
        ldx #0
-       copy #$00, ppu_data
        inx
        cpx #64
        bne -

        reset_ppu_addr

        ; clear Attribute Table 2
        set_ppu_addr attr_table2
        ldx #0
-       copy #$00, ppu_data
        inx
        cpx #64
        bne -

        reset_ppu_addr

        jsr hide_sprites

        copy #2,   credits_bg_pal  ; pink
        copy #$00, zp20
        copy #1,   flag1
        copy #$00, zp1

        copy #%00011000, ppu_ctrl
        copy #%00011110, ppu_mask
        rts

; -------------------------------------------------------------------------------------------------

anim_credits
        ; Animate credits part.
        ; Called by: nmi_credits
        ; Calls: fade_out_palette, update_palette, hide_sprites, update_sixteen_sprites,
        ;        update_eight_sprites, update_six_sprites

        copy #>sprite_page, oam_dma  ; do sprite DMA

        lda zp19
        cmp #$08
        bne anim_credits1
        ;
        lda zp18
        cmp #$8c
        bcc anim_credits1
        ;
        inclda zp20
        cmp #$04
        bne anim_credits1

        jsr fade_out_palette
        jsr update_palette  ; palette_copy -> PPU
        copy #$00, zp20

anim_credits1
        copy #id_credits, demo_part

        set_ppu_addr vram_palette + 0*4

        lda zp19
        cmp #8
        beq anim_credits2
        ;
        lda credits_bg_pal
        cmp #0
        beq +++
        cmp #1
        beq ++
        cmp #2
        beq +

+       copy #$34, ppu_data  ; light pink
        copy #$24, ppu_data  ; medium-light pink
        copy #$14, ppu_data  ; medium-dark pink
        copy #$04, ppu_data  ; dark pink

++      copy #$38, ppu_data  ; light yellow
        copy #$28, ppu_data  ; medium-light yellow
        copy #$18, ppu_data  ; medium-dark yellow
        copy #$08, ppu_data  ; dark yellow

+++     copy #$32, ppu_data  ; light blue
        copy #$22, ppu_data  ; medium-light blue
        copy #$12, ppu_data  ; medium-dark blue
        copy #$02, ppu_data  ; dark blue

anim_credits2
        inc zp1
        copy zp1, ppu_scroll
        ldx zp1
        lda curve2,x
        sta ppu_scroll
        inclda zp18
        cmp #$b4
        beq +
        jmp ++
        ;
+       inc zp19
        copy #$00, zp18
++      lda zp19
        cmp #1
        beq jump_table2 + 1*3
        cmp #2
        beq jump_table2 + 2*3
        cmp #3
        beq jump_table2 + 3*3
        cmp #4
        beq jump_table2 + 4*3
        cmp #5
        beq jump_table2 + 5*3
        cmp #6
        beq jump_table2 + 6*3
        cmp #7
        beq jump_table2 + 7*3
        cmp #8
        beq jump_table2 + 8*3
        cmp #9
        beq anim_credits_nextpart

jump_table2
        jmp cred_exit1
        jmp cred_starring
        jmp cred_code1
        jmp cred_code2
        jmp cred_gfx1
        jmp cred_gfx2
        jmp cred_gfx3
        jmp cred_gfx4
        jmp cred_zax

anim_credits_nextpart
        copy #id_checkered, demo_part  ; next part
        copy #0, flag1

        jmp cred_exit2

cred_starring
        jsr hide_sprites

        ; draw 8*2 sprites: tiles $90-$9f ("STARRING") starting from (92, 106), subpalette 3
        ldxy #92, #106
        copy #$90, zp12
        jsr update_sixteen_sprites

        jmp cred_exit2

cred_code1
        jsr hide_sprites

        ; draw 8*2 sprites: tiles $60-$6f ("VISY") starting from (117, 115), subpalette 3
        ldxy #117, #115
        copy #$60, zp12
        jsr update_sixteen_sprites

        ; draw 4*2 sprites: tiles $ac-$b3 ("CODE") starting from (84, 97), subpalette 2
        ldxy #84, #97
        copy #$ac, zp12
        jsr update_eight_sprites

        jmp cred_exit2

cred_code2
        jsr hide_sprites

        ; draw 8*2 sprites: tiles $80-$8f ("PAHAMOKA") starting from (117, 115), subpalette 3
        ldxy #117, #115
        copy #$80, zp12
        jsr update_sixteen_sprites

        ; draw 4*2 sprites: tiles $ac-$b3 ("CODE") starting from (84, 97), subpalette 2
        ldxy #84, #97
        copy #$ac, zp12
        jsr update_eight_sprites

        jmp cred_exit2

cred_gfx1
        jsr hide_sprites
        copy #1, credits_bg_pal  ; yellow

        ; draw 8*2 sprites: tiles $50-$5f ("ZEROIC") starting from (117, 115), subpalette 3
        ldxy #117, #115
        copy #$50, zp12
        jsr update_sixteen_sprites

        ; draw 3*2 sprites: tiles $a0-$a5 ("GFX") starting from (84, 97), subpalette 2
        ldxy #84, #97
        copy #$a0, zp12
        jsr update_six_sprites

        jmp cred_exit2

cred_gfx2
        jsr hide_sprites

        ; draw 8*2 sprites: tiles $40-$4f ("Inkoddi") starting from (117, 115), subpalette 3
        ldxy #117, #115
        copy #$40, zp12
        jsr update_sixteen_sprites

        ; draw 3*2 sprites: tiles $a0-$a5 ("GFX") starting from (84, 97), subpalette 2
        ldxy #84, #97
        copy #$a0, zp12
        jsr update_six_sprites

        jmp cred_exit2

cred_gfx3
        jsr hide_sprites

        ; draw 8*2 sprites: tiles $e0-$ef ("PROGZMAX") starting from (117, 115), subpalette 3
        ldxy #117, #115
        copy #$e0, zp12
        jsr update_sixteen_sprites

        ; draw 3*2 sprites: tiles $a0-$a5 ("GFX") starting from (84, 97), subpalette 2
        ldxy #84, #97
        copy #$a0, zp12
        jsr update_six_sprites

        jmp cred_exit2

cred_gfx4
        copy #0, credits_bg_pal  ; blue
        jsr hide_sprites

        ; draw 8*2 sprites: tiles $c0-$cf ("MANGAELF", "SAKAMIES") starting from (117, 115),
        ; subpalette 3
        ldxy #117, #115
        copy #$c0, zp12
        jsr update_sixteen_sprites

        ; draw 3*2 sprites: tiles $a0-$a5 ("GFX") starting from (84, 97), subpalette 2
        ldxy #84, #97
        copy #$a0, zp12
        jsr update_six_sprites

        jmp cred_exit2

cred_zax
        jsr hide_sprites

        ; draw 8*2 sprites: tiles $70-$7f ("ilmarque") starting from (117, 115), subpalette 3
        ldxy #117, #115
        copy #$70, zp12
        jsr update_sixteen_sprites

        ; draw 3*2 sprites: tiles $a6-$ab ("ZAX") starting from (84, 97), subpalette 2
        ldxy #84, #97
        copy #$a6, zp12
        jsr update_six_sprites

        jmp cred_exit2

cred_exit1
        jsr hide_sprites
cred_exit2
        chr_bankswitch 1
        copy #%10011000, ppu_ctrl
        copy #%00011110, ppu_mask
        rts

; -------------------------------------------------------------------------------------------------

init_woman
        ; Set up woman part.
        ; Called by: nmi_woman
        ; Calls: fill_name_tables, fill_attribute_tables, hide_sprites, jump_snd_eng

        ; fill Name Tables with #$7f
        ldx #$7f
        jsr fill_name_tables

        ldy #$00
        jsr fill_attribute_tables
        jsr hide_sprites

        lda #%00000000
        sta ppu_ctrl
        sta ppu_mask

        copy #$20, $014a
        copy #$21, $014b

        ; write 16 rows to Name Table 0;
        ; the left half consists of tiles $00, $01, ..., $ff;
        ; the right half consists of tile $7f

        set_ppu_addr name_table0

        ldy #0
        ; loop
--      ; write Y...Y+15
        ldx #0
-       sty ppu_data
        iny
        inx
        cpx #16
        bne -
        ;
        ; write 16 * byte #$7f
        ldx #0
-       copy #$7f, ppu_data
        inx
        cpx #16
        bne -
        ;
        cpy #0
        bne --

        jsr jump_snd_eng

        ; write another 7 rows to Name Table 0;
        ; the left half consists of tiles $00, $01, ..., $df
        ; the right half consists of tile $7f

        ldy #0
        ; loop
--      ; first inner loop
        ldx #0
-       sty ppu_data
        iny
        inx
        cpx #16
        bne -
        ;
        ; second inner loop
        ldx #0
-       copy #$7f, ppu_data
        inx
        cpx #16
        bne -
        ;
        cpy #7*32
        bne --

        ; write bytes #$e0-#$e4 to Name Table 0, row 29, columns 10-14
        reset_ppu_addr
        set_ppu_addr name_table0 + 29*32 + 10
        copy #$e0, ppu_data
        copy #$e1, ppu_data
        copy #$e2, ppu_data
        copy #$e3, ppu_data
        copy #$e4, ppu_data
        reset_ppu_addr

        ; update first background subpalette and first sprite subpalette
        set_ppu_addr vram_palette + 0*4
        ldx #0
        copy #$30, ppu_data  ; white
        copy #$25, ppu_data  ; medium-light red
        copy #$17, ppu_data  ; medium-dark orange
        copy #$0f, ppu_data  ; black
        set_ppu_addr vram_palette + 4*4 + 1
        copy #$02, ppu_data  ; dark blue
        copy #$12, ppu_data  ; medium-dark blue
        copy #$22, ppu_data  ; medium-light blue
        reset_ppu_addr

        ; reset H/V scroll
        lda #0
        sta ppu_scroll
        sta ppu_scroll

        lda #$00
        sta zp1
        sta zp2
        copy #$40, zp3
        copy #$00, zp4
        copy #1,   flag1
        copy #$00, zp20

        copy #%10000000, ppu_ctrl
        rts

; -------------------------------------------------------------------------------------------------

anim_woman
        ; Animate woman part.
        ; Called by: nmi_woman
        ; Calls: delay

        copy #>sprite_page, oam_dma  ; do sprite DMA

        inc zp2
        inc zp3
        ldxy #24, #0
        lda #$00
        sta zp12
        sta zp1
        lda zp3

        ; loop
-       ; update sprite at offset Y
        ;
        txa
        sta sprite_page + 0,y
        ;
        lda #$f0
        add zp4
        sta sprite_page + 1,y
        ;
        lda $014a
        sta sprite_page + 2,y
        ;
        ; store X
        txa
        pha
        ;
        inc zp1
        inc zp1
        inc zp1
        ;
        ; [woman_sprite_x + zp1 + zp2] + 194 -> sprite X position
        lda zp1
        add zp2
        tax
        lda woman_sprite_x,x
        add #194
        sta sprite_page + 3,y
        ;
        ; restore X
        pla
        tax
        ;
        iny4
        txa
        add #8
        tax
        inc zp5
        ;
        ; if zp5 = 15 then clear it and increment zp4
        lda zp5
        cmp #15
        beq +
        jmp ++
        ;
+       inc zp4
        copy #0, zp5

        ; if zp4 = 16 then clear it
++      lda zp4
        cmp #16
        beq +
        jmp ++
        ;
+       copy #0, zp4

        ; loop until Y = 96
++      cpy #96
        bne -

        ldx #24
        lda #$00
        sta zp12
        sta zp1
        dec zp4

        ; loop
-       ; update sprite at offset Y
        ;
        txa
        sta sprite_page + 0,y
        ;
        lda #$f0
        add zp4
        sta sprite_page + 1,y
        ;
        lda $014b
        sta sprite_page + 2,y
        ;
        ; store X
        txa
        pha
        ;
        dec zp1
        dec zp1
        ;
        ; [woman_sprite_x + zp1 + zp3] + 194 -> sprite X position
        lda zp1
        add zp3
        tax
        lda woman_sprite_x,x
        add #194
        sta sprite_page + 3,y
        ;
        ; restore X
        pla
        tax
        ;
        iny4
        txa
        add #8
        tax
        inc zp4
        ;
        ; if zp4 = 16 then clear it
        lda zp4
        cmp #16
        beq +
        jmp ++
        ;
+       copy #0, zp4
        ; loop until Y = 192
++      cpy #192
        bne -

        chr_bankswitch 3

        copy #%10001000, ppu_ctrl

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

        copy #%10011000, ppu_ctrl
        copy #%00011110, ppu_mask

        lda zp3
        cmp #$fa
        bne ++

        inclda $0149
        cmp #$02
        beq +

        copy #$00, $014a
        copy #$01, $014b
        jmp ++

+       copy #$20, $014a
        copy #$21, $014b
        copy #$00, $0149
++      rts

; --- Unaccessed block ----------------------------------------------------------------------------

        ldx #$7a              ; $ec99
        jsr fill_name_tables

        ldy #$00
        jsr fill_attribute_tables
        jsr init_palette_copy  ; palette_table -> palette_copy
        jsr update_palette  ; palette_copy -> PPU
        jsr hide_sprites

        lda #%00000000
        sta ppu_ctrl
        sta ppu_mask

        set_ppu_addr name_table0 + 8*32 + 10

        ldxy #$50, #0
-       stx ppu_data
        inx
        iny
        cpy #12
        bne -

        reset_ppu_addr
        set_ppu_addr name_table0 + 9*32 + 10

        ldy #0
        ldx #$5c
-       stx ppu_data
        inx
        iny
        cpy #12
        bne -

        reset_ppu_addr
        set_ppu_addr name_table0 + 10*32 + 10

        ldy #0
        ldx #$68
-       stx ppu_data
        inx
        iny
        cpy #12
        bne -

        reset_ppu_addr

        copy #1, flag1
        lda #$00
        sta text_offset
        sta zp1
        copy #$00, zp2

        set_ppu_addr vram_palette + 6*4 + 2
        copy #$00, ppu_data
        copy #$10, ppu_data
        reset_ppu_addr

        copy #%10000000, ppu_ctrl
        copy #%00011110, ppu_mask

        copy #$00, $0130
        rts

        lda $0130
        cmp #$01
        beq +

        set_ppu_addr vram_palette + 4*4
        copy #$0f, ppu_data
        copy #$0f, ppu_data
        copy #$0f, ppu_data
        copy #$0f, ppu_data
        reset_ppu_addr

        set_ppu_addr vram_palette + 0*4
        copy #$0f, ppu_data
        copy #$30, ppu_data
        copy #$10, ppu_data
        copy #$00, ppu_data
        reset_ppu_addr

+       copy #$01, $0130
        copy #%00011110, ppu_mask
        copy #%00010000, ppu_ctrl

        inclda zp2
        cmp #8
        beq +
        jmp +++
+       copy #$00, zp2
        inclda text_offset
        cmp #235
        beq +
        jmp ++
        ;
+       copy #0, flag1
        copy #id_cola, demo_part
++      set_ppu_addr name_table0 + 27*32 + 1

        ldx #0
-       txa
        add text_offset
        tay
        lda friday_text,y
        clc
        sbc #$36
        sta ppu_data
        inx
        cpx #31
        bne -

        reset_ppu_addr

+++     chr_bankswitch 2
        inc zp1
        ldx zp1
        lda curve2,x
        clc
        sbc #30
        sta ppu_scroll
        copy #0, ppu_scroll

        copy #%00010000, ppu_ctrl
        copy #%00011110, ppu_mask

        copy #>sprite_page, oam_dma  ; do sprite DMA

        ldx #$ff
        jsr delay
        jsr delay
        jsr delay
        ldx #$1e
        jsr delay
        ldx #$d0
        jsr delay

        copy #%00000000, ppu_ctrl

        chr_bankswitch 0

        copy zp2, ppu_scroll
        copy #0,  ppu_scroll

        ; edit sprite #0
        copy #215,       sprite_page + 0*4 + 0
        copy #$25,       sprite_page + 0*4 + 1
        copy #%00000000, sprite_page + 0*4 + 2
        copy #248,       sprite_page + 0*4 + 3

        ; edit sprite #1
        copy #207,       sprite_page + 1*4 + 0
        copy #$25,       sprite_page + 1*4 + 1
        copy #%00000000, sprite_page + 1*4 + 2
        copy #248,       sprite_page + 1*4 + 3

        ; edit sprite #2
        copy #223,       sprite_page + 2*4 + 0
        copy #$27,       sprite_page + 2*4 + 1
        copy #%00000000, sprite_page + 2*4 + 2
        copy #248,       sprite_page + 2*4 + 3

        ldx unacc_data
-       txa
        asl
        asl
        tay

        lda unacc_table1,x
        add #$9b
        sta sprite_page + 23*4 + 0,y

        txa
        pha
        ldx $0137
        lda unacc_table4,x
        sta zp12
        pla

        tax
        lda unacc_table2,x
        add zp12
        sta sprite_page + 23*4 + 1,y

        lda #%00000010
        sta sprite_page + 23*4 + 2,y

        lda unacc_table3,x
        add $0139
        sta sprite_page + 23*4 + 3,y

        cpx #0
        beq +
        dex
        jmp -

+       inclda $013a
        cmp #$06
        bne +
        inc $0139
        inc $0139
        copy #$00, $013a
+       inclda $0138
        cmp #$0c
        bne +
        copy #$00, $0138
        inclda $0137
        cmp #$04
        bne +
        copy #$00, $0137

+       copy #%10001000, ppu_ctrl
        copy #%00011000, ppu_mask
        rts

; -------------------------------------------------------------------------------------------------

init_bowser
        ; Set up Bowser's spaceship part.
        ; Called by: nmi_bowser
        ; Calls: hide_sprites, fill_attribute_tables

        jsr hide_sprites
        ldy #$aa
        jsr fill_attribute_tables
        copy #$1a, zp12
        ldx #$60

        ; loop
--      copy #$21, ppu_addr
        copy zp12, ppu_addr
        ;
        ldy #0
-       stx ppu_data
        inx
        iny
        cpy #3
        bne -
        ;
        reset_ppu_addr
        lda zp12
        add #32
        sta zp12
        lda zp12
        cmp #$1a
        bne --

        copy #$08, zp12
        ldx #$80

        ; loop
--      copy #$22, ppu_addr
        copy zp12, ppu_addr
        ;
        ldy #0
-       stx ppu_data
        inx
        iny
        cpy #3
        bne -
        ;
        reset_ppu_addr
        lda zp12
        add #32
        sta zp12
        lda zp12
        cmp #$68
        bne --

        ; update all sprite subpalettes
        set_ppu_addr vram_palette + 4*4
        copy #$0f, ppu_data  ; black
        copy #$01, ppu_data  ; dark blue
        copy #$1c, ppu_data  ; medium-dark cyan
        copy #$30, ppu_data  ; white
        copy #$0f, ppu_data  ; black
        copy #$00, ppu_data  ; dark gray
        copy #$10, ppu_data  ; light gray
        copy #$20, ppu_data  ; white
        copy #$0f, ppu_data  ; black
        copy #$19, ppu_data  ; medium-light green
        copy #$26, ppu_data  ; medium-light red
        copy #$30, ppu_data  ; white
        copy #$22, ppu_data  ; medium-light blue
        copy #$16, ppu_data  ; medium-dark red
        copy #$27, ppu_data  ; medium-light orange
        copy #$18, ppu_data  ; medium-dark yellow
        reset_ppu_addr

        ; update first background subpalette
        set_ppu_addr vram_palette + 0*4
        copy #$0f, ppu_data  ; black
        copy #$20, ppu_data  ; white
        copy #$10, ppu_data  ; light gray
        copy #$00, ppu_data  ; dark gray
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
        ; loop - edit sprites
-       txa
        asl
        asl
        tay
        ;
        lda sprite_y_table4,x
        sta sprite_page + 48*4 + 0,y
        lda sprite_tile_table4,x
        sta sprite_page + 48*4 + 1,y
        lda sprite_x_table4,x
        sta sprite_page + 48*4 + 3,y
        ;
        lda sprite_xsub_table,x
        sta $011e,x
        dex
        cpx #255
        bne -

        copy #$7a, $0111
        copy #$0a, $0110

        ldx data4
        ; loop - edit sprites
-       txa
        asl
        asl
        tay
        ;
        lda sprite_tile_table2,x
        sta sprite_page + 1*4 + 1,y
        lda sprite_attr_table2,x
        sta sprite_page + 1*4 + 2,y
        ;
        cpx #0
        beq +
        dex
        jmp -

+       lda #$00
        sta $0100
        sta $0101
        sta $0102
        copy #1, flag1
        copy #%10000000, ppu_ctrl
        copy #%00010010, ppu_mask
        rts

; -------------------------------------------------------------------------------------------------

anim_bowser
        ; Animate Bowser's spaceship part.
        ; Called by: nmi_bowser
        ; Calls: nothing

        copy #>sprite_page, oam_dma  ; do sprite DMA

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

        ; loop
-       dec $0104,x
        lda $0104,x
        cmp #$00
        bne anim_bowser_2
        lda $0108,x
        cmp table8,x
        beq +
        inc $0108,x
        jmp anim_bowser_1
+       lda table7,x
        sta $0108,x
anim_bowser_1
        lda table6,x
        sta $0104,x
anim_bowser_2
        dex
        cpx #255
        bne -

        ; edit tiles of four sprites
        copy $0108, sprite_page +  1*4 + 1
        copy $0109, sprite_page + 16*4 + 1
        copy $010a, sprite_page + 17*4 + 1
        copy $010b, sprite_page + 13*4 + 1

        ldx data4
        ; loop - edit sprite positions
-       txa
        asl
        asl
        tay
        ;
        lda sprite_y_table2,x
        add $0111
        sta sprite_page + 1*4 + 0,y
        lda sprite_x_table2,x
        add $0110
        sta sprite_page + 1*4 + 3,y
        ;
        cpx #0
        beq +
        dex
        jmp -

+       lda $0100
        ldx $0101
        cmp table9,x
        bne anim_bowser_3

        inclda $0101
        cpx data6
        bne +      ; always taken

        ; unaccessed block ($f111)
        copy #$00, $0101

+       ldxy $0102, $0100
        lda #$ff
        sta $0112,x
        lda curve1,y
        add #$5a
        sta $0116,x
        lda curve3,y
        sta $011a,x
        inc $0102
        cpx data5
        bne anim_bowser_3
        copy #$00, $0102

anim_bowser_3
        ldx data5
        ; loop
-       lda $0116,x
        cmp #$f0
        beq anim_bowser_4
        lda $0112,x
        clc
        sbc $011a,x
        bcc +
        sta $0112,x
        jmp anim_bowser_4
+       lda #$f0
        sta $0116,x
anim_bowser_4
        dex
        cpx #255
        bne -

        ldx data5
        ; loop - edit sprites
-       txa
        asl
        asl
        tay
        ;
        lda $0116,x
        sta sprite_page + 18*4 + 0,y
        lda sprite_tile_table3,x
        sta sprite_page + 18*4 + 1,y
        lda #$2b
        sta sprite_page + 18*4 + 2,y
        lda $0112,x
        sta sprite_page + 18*4 + 3,y
        ;
        dex
        cpx #255
        bne -

        ldx data7
        ; loop
-       txa
        asl
        asl
        tay
        ;
        lda sprite_page + 48*4 + 3,y
        clc
        sbc sprite_xsub_table,x
        sta sprite_page + 48*4 + 3,y
        ;
        dex
        cpx #255
        bne -

        copy #%10000000, ppu_ctrl
        copy #%00011010, ppu_mask

        set_ppu_scroll 0, 50
        rts

; -------------------------------------------------------------------------------------------------

init_gameover
        ; Set up "game over" part.
        ; Called by: nmi_gameover
        ; Calls: fill_name_tables, fill_attribute_tables, init_palette_copy, update_palette

        ; clear name&attribute tables
        ldx #$4a  ; space
        jsr fill_name_tables
        ldy #$00
        jsr fill_attribute_tables

        jsr init_palette_copy  ; palette_table -> palette_copy
        jsr update_palette     ; palette_copy -> PPU

        ; Copy 96 (32*3) bytes of encrypted text to rows 14-16 of name table 0.
        ; Subtract 17 from each byte.

        set_ppu_addr name_table0 + 14*32

        ldx #0
-       lda gameover_text,x
        clc
        sbc #16
        sta ppu_data
        inx
        cpx #96
        bne -

        copy #%00000010, ppu_ctrl
        copy #%00000000, ppu_mask
        rts

; -------------------------------------------------------------------------------------------------

anim_gameover
        ; Animate "game over" part.
        ; Called by: nmi_gameover
        ; Calls: nothing

        set_ppu_scroll 0, 0
        copy #%10010000, ppu_ctrl
        copy #%00001110, ppu_mask
        rts

; -------------------------------------------------------------------------------------------------

init_greets
        ; Set up "GREETS" part.
        ; Called by: nmi_greets
        ; Calls: fill_name_tables, fill_attribute_tables, clear_palette_copy, update_palette

        ; clear name&attribute tables
        ldx #$4a  ; space
        jsr fill_name_tables
        ldy #$00
        jsr fill_attribute_tables

        jsr clear_palette_copy  ; black -> palette_copy
        jsr update_palette      ; palette_copy -> PPU

        copy #%00000010, ppu_ctrl  ; disable NMI
        copy #%00000000, ppu_mask  ; hide sprites and background

        ; Write the heading "GREETS TO ALL NINTENDAWGS:" (16*3 tiles, tiles $00-$2f)
        ; to rows 3-5, columns 9-24 of Name Table 0.
        ;
        copy #0, zp12  ; outer loop counter, VRAM address offset
        ldx #0         ; tile number
        ;
--      copy #>(name_table0 + 3*32 + 9), ppu_addr
        lda zp12
        add #<(name_table0 + 3*32 + 9)
        sta ppu_addr
        ;
        ; write row
        ldy #0
-       stx ppu_data
        inx
        iny
        cpy #16
        bne -
        ;
        reset_ppu_addr
        ;
        ; manage loop counter
        lda zp12
        add #32
        sta zp12
        cmp #(3*32)
        bne --

        ; Copy the encrypted main text (32*20 = 256+256+128 tiles) to rows 8-27 of name table 0.
        ; Subtract 17 from each byte.
        ;
        set_ppu_addr name_table0 + 8*32
        ;
        ldx #0
-       lda greets_text + 0,x
        clc
        sbc #16
        sta ppu_data
        inx
        bne -
        ;
        ldx #0
-       lda greets_text + 256,x
        clc
        sbc #16
        sta ppu_data
        inx
        bne -
        ;
        ldx #0
-       lda greets_text + 2*256,x
        clc
        sbc #16
        sta ppu_data
        inx
        cpx #128
        bne -

        reset_ppu_addr

        copy #1,   flag1
        copy #$e6, $0153
        rts

; -------------------------------------------------------------------------------------------------

anim_greets
        ; Animate "GREETS" part.
        ; Called by: nmi_greets
        ; Calls: init_palette_copy, update_palette, fade_out_palette

        chr_bankswitch 2

        lda $0150
        cmp #0
        bne +
        lda $014f
        cmp #3
        bne +

        jsr init_palette_copy  ; palette_table -> palette_copy
        jsr update_palette     ; palette_copy -> PPU

        ; update first background subpalette
        set_ppu_addr vram_palette + 0*4
        copy #$0f, ppu_data  ; black
        copy #$30, ppu_data  ; white
        copy #$1a, ppu_data  ; medium-dark green
        copy #$09, ppu_data  ; dark green
        reset_ppu_addr

+       copy #0, ppu_scroll
        ldx $0153
        lda curve1,x
        add $0153
        sta ppu_scroll

        lda $0153
        cmp #0
        beq +
        dec $0153
        ;
+       lda $0150
        cmp #3
        bne +
        lda $014f
        cmp #0
        bcc +
        ;
        inclda zp20
        cmp #4
        bne +

        jsr fade_out_palette
        jsr update_palette  ; palette_copy -> PPU
        copy #0, zp20

+       copy #id_greets, demo_part
        copy #%10010000, ppu_ctrl
        copy #%00001110, ppu_mask
        rts

; -------------------------------------------------------------------------------------------------

init_cola
        ; Set up wavy Coca Cola cans.
        ; Called by: nmi_cola
        ; Calls: fill_name_tables, hide_sprites, fill_attribute_tables

        ; fill name tables with #$80, clear attribute tables, hide sprites
        ldx #$80
        jsr fill_name_tables
        jsr hide_sprites
        ldy #$00
        jsr fill_attribute_tables

        lda #%00000000
        sta ppu_ctrl
        sta ppu_mask

        lda #$00
        sta zp1
        sta zp2
        sta zp3

        ; update first background subpalette
        set_ppu_addr vram_palette + 0*4
        copy #$05, ppu_data  ; dark red
        copy #$25, ppu_data  ; medium-light red
        copy #$15, ppu_data  ; medium-dark red
        copy #$30, ppu_data  ; white
        reset_ppu_addr

        copy #$c8, $013d

        set_ppu_scroll 0, 200

        copy #$00,       $014c
        copy #1,         flag1
        copy #%10000000, ppu_ctrl
        rts

; -------------------------------------------------------------------------------------------------

anim_cola
        ; Animate wavy Coca Cola cans.
        ; Called by: nmi_cola
        ; Calls: delay

        lda $013c
        cmp #$02
        beq +
        jmp anim_cola_1
+       ldy #$80

        ; loop
--      copy #>(name_table0 + 8*32 + 4), ppu_addr
        lda #<(name_table0 + 8*32 + 4)
        add $013b
        sta ppu_addr
        ;
        ldx #0
-       sty ppu_data
        iny
        inx
        cpx #8
        bne -
        ;
        lda $013b
        add #32
        sta $013b
        cpy #$c0
        bne --

        ; loop
--      copy #>(name_table0 + 16*32 + 4), ppu_addr
        lda #<(name_table0 + 16*32 + 4)
        add $013b
        sta ppu_addr
        ;
        ldx #0
-       sty ppu_data
        iny
        inx
        cpx #8
        bne -
        ;
        lda $013b
        add #32
        sta $013b
        cpy #$00
        bne --

        reset_ppu_addr
        copy #$00, $013b

        ; loop
--      copy #>(name_table0 + 8*32 + 20), ppu_addr
        lda #<(name_table0 + 8*32 + 20)
        add $013b
        sta ppu_addr
        ;
        ldx #0
-       sty ppu_data
        iny
        inx
        cpx #8
        bne -
        ;
        lda $013b
        add #32
        sta $013b
        cpy #$c0
        bne --

        ; loop
--      copy #>(name_table0 + 16*32 + 20), ppu_addr
        lda #<(name_table0 + 16*32 + 20)
        add $013b
        sta ppu_addr
        ;
        ldx #0
-       sty ppu_data
        iny
        inx
        cpx #8
        bne -
        ;
        lda $013b
        add #32
        sta $013b
        cpy #0
        bne --

        reset_ppu_addr

anim_cola_1
        lda $013c
        cmp #$a0
        bcc +
        jmp anim_cola_2

+       copy #0, ppu_scroll
        lda $013d
        clc
        sbc $013c
        sta ppu_scroll

anim_cola_2
        lda ram1
        chr_bankswitch 2
        copy #$00, zp1
        lda $013e
        cmp #$01
        beq anim_cola_3
        inclda $013c
        cmp #$c8
        beq +
        jmp anim_cola_3
+       copy #$01, $013e

anim_cola_3
        ldxy #$00, #$00
        lda $013e
        cmp #$00
        beq anim_cola_5
        inc zp3
        inc zp2

        ; loop
-       ldx #1
        jsr delay
        ldx zp2
        lda curve2,x
        adc #$32
        sta zp12
        lda zp12
        adc #$28
        sta zp13
        lda zp1
        cmp zp12
        bcc +
        bcs ++
+       copy #%00001110, ppu_mask
        jmp +++
++      lda zp1
        cmp zp13
        bcs +
        copy #%11101110, ppu_mask
+++     jmp ++
+       copy #%00001110, ppu_mask
++      lda zp1
        add zp3
        adc zp2
        clc
        sbc #$14
        tax
        lda curve1,x
        add zp3
        sta ppu_scroll
        lda zp1
        add zp3
        tax
        lda curve2,x
        sta ppu_scroll
        ldx zp2
        lda curve2,x
        add #60
        sta zp13
        inc zp1
        iny
        cpy #$91
        bne -

anim_cola_5
        copy #%10010000, ppu_ctrl
        copy #%00001110, ppu_mask
        rts

; -------------------------------------------------------------------------------------------------

write_row
        ; Write X to VRAM 32 times.
        ; Called by: init_friday
        ; Calls: nothing

        ldy #0
-       stx ppu_data
        iny
        cpy #32
        bne -

        rts

; --- Unaccessed block ----------------------------------------------------------------------------

        ldy #0        ; $f4f9
-       stx ppu_data
        iny
        cpy #32
        bne -
        rts

; -------------------------------------------------------------------------------------------------

macro write_row_macro _byte
        ldx _byte
        jsr write_row
endm

init_friday
        ; Set up "IT IS FRIDAY..." part.
        ; Called by: nmi_friday
        ; Calls: fill_nt_and_clear_at, hide_sprites, write_row

        ldx #$25
        jsr fill_nt_and_clear_at
        jsr hide_sprites

        lda #%00000000
        sta ppu_ctrl
        sta ppu_mask

        ; write 24 rows of tiles to the start of Name Table 0
        set_ppu_addr name_table0
        write_row_macro #$25
        write_row_macro #$25
        write_row_macro #$25
        write_row_macro #$25
        write_row_macro #$25
        write_row_macro #$25
        write_row_macro #$25
        write_row_macro #$25
        write_row_macro #$25
        write_row_macro #$25
        write_row_macro #$25
        write_row_macro #$25
        write_row_macro #$25
        write_row_macro #$25
        write_row_macro #$25
        write_row_macro #$39
        write_row_macro #$37
        write_row_macro #$37
        write_row_macro #$37
        write_row_macro #$37
        write_row_macro #$37
        write_row_macro #$37
        write_row_macro #$37
        write_row_macro #$38

        reset_ppu_addr

        ; update first background subpalette from some_palette1
        set_ppu_addr vram_palette + 0*4
        copy some_palette1 + 0, ppu_data
        copy some_palette1 + 1, ppu_data
        copy some_palette1 + 2, ppu_data
        copy some_palette1 + 3, ppu_data
        reset_ppu_addr

        ; update first sprite subpalette from some_palette2
        set_ppu_addr vram_palette + 4*4
        copy some_palette2 + 0, ppu_data
        copy some_palette2 + 1, ppu_data
        copy some_palette2 + 2, ppu_data
        copy some_palette2 + 3, ppu_data
        reset_ppu_addr

        ldx data7
        ; loop - edit sprites
-       txa
        asl
        asl
        tay
        ;
        lda friday_sprites_y,x
        sta sprite_page + 48*4 + 0,y
        lda friday_sprites_tile,x
        sta sprite_page + 48*4 + 1,y
        lda #%00000010
        sta sprite_page + 48*4 + 2,y
        lda friday_sprites_x,x
        sta sprite_page + 48*4 + 3,y
        ;
        lda friday_sprites_xadd,x
        sta $011e,x
        dex
        cpx #255
        bne -

        copy #$00, $0100
        copy #1,   flag1
        lda #$00
        sta zp1
        sta zp2
        copy #$00, text_offset
        rts

; -------------------------------------------------------------------------------------------------

macro edit_sprite_macro _index, _y, _x
        lda #_y
        clc
        sbc zp12
        sta sprite_page + _index*4 + 0
        copy #$25,       sprite_page + _index*4 + 1
        copy #%00000000, sprite_page + _index*4 + 2
        copy #_x,        sprite_page + _index*4 + 3
endm

anim_friday
        ; Animate "IT IS FRIDAY..." part.
        ; Called by: nmi_friday
        ; Calls: nothing

        inc $0100
        ldx $0100
        lda woman_sprite_x,x
        sta zp12
        lda curve3,x
        sta zp13

        copy #>sprite_page, oam_dma  ; do sprite DMA

        ldx data7
        ; loop - edit sprite positions
-       txa
        asl
        asl
        tay
        ;
        lda friday_sprites_y,x
        add zp12
        sta sprite_page + 48*4 + 0,y
        lda sprite_page + 48*4 + 3,y
        clc
        adc friday_sprites_xadd,x
        sta sprite_page + 48*4 + 3,y
        ;
        dex
        cpx #7
        bne -

        ; loop - edit sprite positions
-       txa
        asl
        asl
        tay
        ;
        lda friday_sprites_y,x
        add zp13
        sta sprite_page + 48*4 + 0,y
        lda sprite_page + 48*4 + 3,y
        clc
        adc friday_sprites_xadd,x
        sta sprite_page + 48*4 + 3,y
        ;
        dex
        cpx #255
        bne -

        chr_bankswitch 0
        inclda zp2
        cmp #$08
        beq +
        jmp anim_friday_2
        ;
+       copy #$00, zp2
        inclda text_offset
        cmp #235
        beq +
        jmp anim_friday_1
        ;
+       copy #0, flag1
        copy #id_cola, demo_part  ; next part

anim_friday_1
        ; copy 31 bytes from friday_text + text_offset to name table 0 Y pos 19, X pos 1

        copy #>(name_table0 + 19*32 + 1), ppu_addr
        copy #<(name_table0 + 19*32 + 1), ppu_addr

        ldx #0
-       txa
        add text_offset
        tay
        lda friday_text,y
        clc
        sbc #$36
        sta ppu_data
        inx
        cpx #31
        bne -

        reset_ppu_addr

anim_friday_2
        inc zp1
        ldx zp1
        copy zp2, ppu_scroll
        lda curve2,x
        sta ppu_scroll

        lda curve2,x
        sta zp12

        edit_sprite_macro 0, 148, 248
        edit_sprite_macro 1, 152, 248
        edit_sprite_macro 2, 156, 248
        edit_sprite_macro 3, 148, 0
        edit_sprite_macro 4, 152, 0
        edit_sprite_macro 5, 156, 0

        copy #%10000000, ppu_ctrl
        copy #%00011110, ppu_mask
        rts

; -------------------------------------------------------------------------------------------------

fill_attribute_tables
        ; Fill Attribute Tables 0 and 2 with Y.
        ; Called by: init, init_checkered, init_gradients, init_woman, init_bowser
        ;            init_gameover, init_greets, init_cola
        ; Calls: nothing

        set_ppu_addr attr_table0

        ldx #64
-       sty ppu_data
        dexbne -

        set_ppu_addr attr_table2

        ldx #64
-       sty ppu_data
        dexbne -

        reset_ppu_addr
        rts

; -------------------------------------------------------------------------------------------------

fill_attribute_tables_top
        ; Fill top halves (first 32 bytes) of Attribute Tables 0 and 2 with Y.
        ; Called by: init_gradients
        ; Calls: nothing

        set_ppu_addr attr_table0

        ldx #32
-       sty ppu_data
        dexbne -

        set_ppu_addr attr_table2

        ldx #32
-       sty ppu_data
        dexbne -

        reset_ppu_addr
        rts

; --- Unaccessed block ----------------------------------------------------------------------------

        set_ppu_addr attr_table0 + 4*8  ; $f7d0

        ldx #32
-       sty ppu_data
        dexbne -

        set_ppu_addr attr_table2 + 4*8

        ldx #32
-       sty ppu_data
        dexbne -

        reset_ppu_addr
        rts

; -------------------------------------------------------------------------------------------------

fill_name_tables
        ; Fill Name Tables 0 and 2 with byte X and set flag1.
        ; Called by: init_title, init_checkered, init_gradients, init_credits, init_woman
        ;            init_gameover, init_greets, init_cola
        ; Calls: nothing

        stx vram_fill_byte
        ldy #0
        copy #$3c, zp12

        lda #%00000000
        sta ppu_ctrl  ; disable NMI
        sta ppu_mask  ; hide sprites and background

        ; fill the Name Tables with the specified byte

        set_ppu_addr name_table0

        ldxy #0, #0
-       lda vram_fill_byte
        sta ppu_data
        sta ppu_data
        sta ppu_data
        sta ppu_data
        inx
        bne -

        set_ppu_addr name_table2

        ldxy #0, #0
-       lda vram_fill_byte
        sta ppu_data
        sta ppu_data
        sta ppu_data
        sta ppu_data
        inx
        bne -

        copy #1, flag1
        reset_ppu_addr
        rts

; -------------------------------------------------------------------------------------------------

macro clear_at_macro _addr
        ; write 0 to PPU 64 times, starting from _addr

        set_ppu_addr _addr

        ldx #0
-       copy #%00000000, ppu_data
        inx
        cpx #64
        bne -
endm

macro fill_nt_macro _addr
        ; write vram_fill_byte to PPU 960 times, starting from _addr

        copy #>_addr, ppu_addr
        copy #<_addr, ppu_addr
        ldxy #0, #0

-       copy vram_fill_byte, ppu_data
        inx
        bne -
-       copy vram_fill_byte, ppu_data
        inx
        bne -
-       copy vram_fill_byte, ppu_data
        inx
        bne -
-       copy vram_fill_byte, ppu_data
        inx
        cpx #192
        bne -
endm

fill_nt_and_clear_at
        ; Fill Name Tables 0, 1 and 2 with byte X.
        ; Clear Attribute Tables 0 and 1.
        ; Called by: init, init_horzbars2, init_horzbars1, init_friday
        ; Calls: nothing

        stx vram_fill_byte
        ldy #$00
        copy #$3c, zp12

        lda #%00000000
        sta ppu_ctrl
        sta ppu_mask

        clear_at_macro attr_table0
        clear_at_macro attr_table1
        fill_nt_macro name_table0
        fill_nt_macro name_table1
        fill_nt_macro name_table2

        copy #1,   flag1
        copy #$72, vscroll  ; ?
        reset_ppu_addr

        ; reset H/V scroll
        lda #0
        sta ppu_scroll
        sta ppu_scroll

        copy #%00000000, ppu_ctrl
        copy #%00011110, ppu_mask
        rts

; -------------------------------------------------------------------------------------------------

nmi     ; Non-maskable interrupt routine
        ; Called by: NMI vector
        ; Calls: many things (see jump table)

        lda ppu_status  ; clear VBlank flag

        lda demo_part
        cmp #0
        beq jump_table3 + 1*3
        cmp #1
        beq jump_table3 + 2*3
        cmp #2
        beq jump_table3 + 3*3
        cmp #3
        beq jump_table3 + 4*3
        cmp #4
        beq jump_table3 + 5*3
        cmp #5
        beq jump_table3 + 6*3
        cmp #6
        beq jump_table3 + 7*3
        cmp #7
        beq jump_table3 + 8*3
        cmp #9
        beq jump_table3 + 9*3
        cmp #10
        beq jump_table3 + 10*3
        cmp #11
        beq jump_table3 + 11*3
        cmp #12
        beq jump_table3 + 12*3
        cmp #13
        beq jump_table3 + 13*3

jump_table3
        jmp nmi_exit       ;  0 (unaccessed, $f980)
        jmp nmi_wecome     ;  1
        jmp nmi_horzbars1  ;  2
        jmp nmi_title      ;  3
        jmp nmi_credits    ;  4
        jmp nmi_woman      ;  5
        jmp nmi_friday     ;  6
        jmp nmi_bowser     ;  7
        jmp nmi_cola       ;  8
        jmp nmi_horzbars2  ;  9
        jmp nmi_checkered  ; 10
        jmp nmi_gradients  ; 11
        jmp nmi_greets     ; 12
        jmp nmi_gameover   ; 13

; -------------------------------------------------------------------------------------------------

nmi_wecome
        ; "Greetings! We come from..."
        ; Called by: nmi
        ; Calls: anim_wecome, jump_snd_eng

        ; set flag1
        lda flag1
        cmp #0
        beq +
        jmp ++
        ;
+       copy #1, flag1
++      jsr anim_wecome
        jsr jump_snd_eng
        inc unused1
        inc unused1
        inc counter1
        inclda counter1
        cmp #230
        beq +
        jmp ++
        ;
+       inc counter2
        copy #0, counter1
++      jmp nmi_exit  ; RTI

; -------------------------------------------------------------------------------------------------

nmi_horzbars1
        ; non-full-screen horizontal color bars (after the red&purple gradients)
        ; Called by: nmi
        ; Calls: init_horzbars1, anim_horzbars1, jump_snd_eng

        ; if flag1 clear, run init_horzbars1 (sets the flag)
        lda flag1
        cmp #0
        beq +
        jmp ++
+       jsr init_horzbars1
        ;
++      jsr anim_horzbars1
        jsr jump_snd_eng
        inclda zp10
        cmp #255
        beq +
        jmp ++
        ;
+       inclda zp11
        cmp #3
        beq +
        jmp ++
        ;
+       copy #id_woman, demo_part  ; next part
        copy #0, flag1
++      jmp nmi_exit  ; RTI

; -------------------------------------------------------------------------------------------------

nmi_title
        ; "wAMMA - Quantum Disco Brothers"
        ; Called by: nmi
        ; Calls: init_title, anim_title, jump_snd_eng

        lda flag1
        cmp #0
        beq +
        jmp ++
        ;
+       jsr init_title
++      jsr anim_title
        jsr jump_snd_eng
        inclda zp27
        cmp #$ff
        beq +
        jmp ++
        ;
+       inclda zp28
        cmp #$03
        beq +
        jmp ++
        ;
+       copy #id_gradients, demo_part  ; next part
        copy #0, flag1
++      jmp nmi_exit  ; RTI

; -------------------------------------------------------------------------------------------------

nmi_credits
        ; credits
        ; Called by: nmi
        ; Calls: init_credits, anim_credits, jump_snd_eng

        lda flag1
        cmp #0
        beq +
        jmp ++
        ;
+       jsr init_credits
++      jsr anim_credits
        jsr jump_snd_eng
        jmp nmi_exit  ; RTI

; -------------------------------------------------------------------------------------------------

nmi_woman
        ; the woman
        ; Called by: nmi
        ; Calls: init_woman, anim_woman, jump_snd_eng

        lda flag1
        cmp #0
        beq +
        jmp ++
        ;
+       jsr init_woman
++      jsr anim_woman
        jsr jump_snd_eng
        inclda zp25
        cmp #$ff
        beq +
        jmp ++
        ;
+       inclda zp26
        cmp #$04
        beq +
        jmp ++
        ;
+       copy #id_friday, demo_part  ; next part
        copy #0, flag1
++      jmp nmi_exit  ; RTI

; -------------------------------------------------------------------------------------------------

nmi_friday
        ; "It is Friday..."
        ; Called by: nmi
        ; Calls: init_friday, anim_friday, jump_snd_eng

        lda flag1
        cmp #0
        beq +
        jmp ++
        ;
+       jsr init_friday
++      jsr anim_friday
        jsr jump_snd_eng
        jmp nmi_exit  ; RTI

; -------------------------------------------------------------------------------------------------

nmi_bowser
        ; Bowser's spaceship
        ; Called by: nmi
        ; Calls: init_bowser, anim_bowser, jump_snd_eng

        lda flag1
        cmp #0
        beq +
        jmp ++
        ;
+       jsr init_bowser
++      jsr anim_bowser
        jsr jump_snd_eng
        inclda $0135
        cmp #$ff
        beq +
        jmp ++
        ;
+       inclda $0136
        cmp #$03
        beq +
        jmp ++
        ;
+       copy #id_credits, demo_part  ; next part
        copy #0, flag1
++      jmp nmi_exit  ; RTI

; -------------------------------------------------------------------------------------------------

nmi_cola
        ; Coca Cola cans
        ; Called by: nmi
        ; Calls: init_cola, anim_cola, jump_snd_eng

        lda flag1
        cmp #0
        beq +
        jmp ++
        ;
+       jsr init_cola
++      jsr anim_cola
        jsr jump_snd_eng
        inclda $013f
        cmp #$ff
        beq +
        jmp ++
        ;
+       inc $0140
++      lda $0140
        cmp #$03
        bne ++
        lda $013f
        cmp #$ae
        bne ++
        copy #id_bowser, demo_part  ; next part
        copy #0, flag1
++      jmp nmi_exit  ; RTI

; -------------------------------------------------------------------------------------------------

nmi_horzbars2
        ; full-screen horizontal color bars (after "game over - continue?")
        ; Called by: nmi
        ; Calls: init_horzbars2, anim_horzbars2

        lda flag1
        cmp #0
        beq +
        jmp ++
        ;
+       jsr init_horzbars2
++      jsr anim_horzbars2
        inclda $0141
        cmp #$ff
        beq +
        jmp ++
        ;
+       inclda $0142
        cmp #$0e
        beq +
        jmp ++
        ;
+       copy #id_wecome, demo_part  ; back to first part
        copy #0, flag1
++      jmp nmi_exit  ; RTI

; -------------------------------------------------------------------------------------------------

nmi_checkered
        ; checkered wavy animation
        ; Called by: nmi
        ; Calls: init_checkered, anim_checkered, jump_snd_eng

        lda flag1
        cmp #0
        beq +
        jmp ++
        ;
+       jsr init_checkered
++      jsr anim_checkered
        jsr jump_snd_eng
        inclda $0143
        cmp #$ff
        beq +
        jmp ++
        ;
+       inc $0144
++      lda $0144
        cmp #$02
        bne +
        lda $0143
        cmp #$af
        bne +
        copy #id_greets, demo_part  ; next part
        copy #0, flag1
+       jmp nmi_exit  ; RTI

; -------------------------------------------------------------------------------------------------

nmi_gradients
        ; red&purple gradient
        ; Called by: nmi
        ; Calls: init_gradients, anim_gradients, jump_snd_eng

        lda flag1
        cmp #0
        beq +
        jmp ++
        ;
+       jsr init_gradients
++      jsr anim_gradients
        jsr jump_snd_eng
        inclda $0145
        cmp #$ff
        beq +
        jmp ++
        ;
+       inclda $0146
        cmp #$03
        beq +
        jmp ++
        ;
+       copy #id_horzbars1, demo_part  ; next part
        copy #0, flag1
++      jmp nmi_exit  ; RTI

; -------------------------------------------------------------------------------------------------

nmi_greets
        ; greets
        ; Called by: nmi
        ; Calls: init_greets, anim_greets, jump_snd_eng

        lda flag1
        cmp #0
        beq +
        jmp ++
        ;
+       jsr init_greets
++      jsr anim_greets
        jsr jump_snd_eng
        inclda $014f
        cmp #$ff
        beq +
        jmp ++
        ;
+       inc $0150
++      lda $0150
        cmp #$03
        bne +
        lda $014f
        cmp #$96
        bne +
        copy #id_gameover, demo_part  ; next part
        copy #0, flag1
+       jmp nmi_exit  ; RTI

; -------------------------------------------------------------------------------------------------

nmi_gameover
        ; "GAME OVER - CONTINUE?"
        ; Called by: nmi
        ; Calls: init_gameover, anim_gameover

        lda flag1
        cmp #0
        beq +
        jmp ++
        ;
+       jsr init_gameover
++      jsr anim_gameover
        inclda $0151
        cmp #$ff
        beq +
        jmp ++
        ;
+       inc $0152
++      lda $0152
        cmp #$0a
        bne +
        lda $0151
        cmp #$a0
        bne +
        copy #id_horzbars2, demo_part  ; next part
        copy #0, flag1
+       jmp nmi_exit  ; RTI

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

        ; see readme file
        incbin "chr0.bin"
        incbin "chr1.bin"
        incbin "chr2.bin"
        incbin "chr3.bin"
