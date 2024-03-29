; NES Quantum Disco Brothers disassembly. Assembles with asm6.
; TODO: data on unaccessed parts is out of date

; Call graph:
;
; init:
;   call_sub1
;       sub1
;   wait_vbl
;   hide_sprites
;   init_palette_copy
;   update_palette
;   init_stars
;   fill_attribute_tables
;   fill_nt_and_clear_at
;
; nmi:
;   nmi_wecome
;       anim_wecome
;           print_big_text_line
;           move_stars_and_update_sprites
;               move_stars
;       jump_snd_eng
;           sound_engine
;               sound1
;                   sound_util1
;               sound3
;                   sound_util2
;                   sound2
;                       sound_util2
;                   sound4
;                       sound_util2
;                       sound5
;                           sound_util2
;               sound6
;                   sound7
;                       sound5
;                       sound6
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
dmc_ctrl      equ $4010  ; write bits: 7=IRQ, 6=loop, 3-0=frequency
dmc_load      equ $4011  ; write bits: 6-0=load counter
dmc_addr      equ $4012  ; write: sample address
dmc_length    equ $4013  ; write: sample length
oam_dma       equ $4014
apu_ctrl      equ $4015
apu_counter   equ $4017

; important bits:
; ppu_ctrl: NCHBSIAa
;   N = execute NMI on VBlank
;   C = short-circuit the PPU; thankfully always 0 (off)
;   H = sprite height; always 0 (1 tile)
;   B/S = background/sprite pattern table
;   Aa = name table; always 00 (NT 0) or 10 (NT 2)
; ppu_mask: CCCSBsbg
;   CCC = color emphasis; 111 (darken all colors) in at least some of the Coca Cola part,
;         000 (normal) at other times
;   S/B = show sprites/background
;   s/b = show sprites/background in leftmost column
;   g = grayscale mode; always 0 (off)
; apu_ctrl:
;   write: 000DNTsS (DMC/noise/triangle/square2/square1 enable)

; zero page (note: "unaccessed" = unaccessed except for the initial cleanup)
zp0                equ $00
demo_part          equ $01  ; which part is running
temp1              equ $01
part_init_done     equ $02  ; has the current demo part been initialized (0/1; used in NMI)
big_text_ptr       equ $03  ; pointer to a text line in wecome_text_pointers (2 bytes)
; $05-$85: unaccessed
delay_var1         equ $86
delay_cnt          equ $87
delay_var2         equ $88
zp1                equ $89
zp2                equ $8a
zp3                equ $8b
zp4                equ $8c  ; used in many nmisub's
zp5                equ $8d  ; does curve stuff in anim_horzbars2, counts 0-15 in anim_woman
vram_fill_byte     equ $8e
text_offset        equ $8f
offset             equ $90  ; in print_big_text_line
ppu_addr_hi        equ $91  ; in print_big_text_line
ppu_addr_lo        equ $92  ; in print_big_text_line
unused1            equ $93  ; never read
wecome_timer_lo    equ $94
wecome_timer_hi    equ $95
vscroll            equ $96  ; in nmi_wecome
horzbars1_timer_lo equ $98
horzbars1_timer_hi equ $99
zp6                equ $9a  ; used a lot
zp7                equ $9b  ; used a lot
zp8                equ $9c  ; in update_metasprite_*, anim_title
writent_loopcntr1  equ $9e
writent_loopcntr2  equ $9f
credits_loop_cntr  equ $a0
credits_timer_lo   equ $a1
credits_timer_hi   equ $a2
loopcntr3          equ $a3  ; in many parts of the demo
zp9                equ $a5  ; in update_metasprite_*
zp10               equ $a6  ; in update_metasprite_*
zp11               equ $a7  ; in update_metasprite_*
sprite_page_offset equ $a8  ; in update_metasprite_*
woman_timer_lo     equ $a9
woman_timer_hi     equ $aa
title_timer_lo     equ $ab
title_timer_hi     equ $ac
; $ad-$c7: unaccessed
;
; $c8-$ef: sound-related:
snd_ptr1           equ $c8  ; data pointer (2 bytes); in sound3, sound7
snd_var1           equ $cb  ; in many subs
snd_var2           equ $cc  ; in sub1, sound7; high byte of snd_var1?
snd_var3           equ $cd  ; in sound7
snd_ptr2           equ $ce  ; data pointer (2 bytes); in sound7
snd_ptr3           equ $d0  ; data pointer (2 bytes); in sub1, sound7
snd_var4           equ $d2  ; in sub1, sound_engine, sound7
snd_var5           equ $d3  ; in sub1, sound_engine, sound4
snd_var6           equ $d4  ; in sub1, sound_engine, sound7
snd_var7           equ $d5  ; in sub1, sound_engine, sound7
snd_var8           equ $d6  ; in sub1, sound_engine
snd_var9           equ $d7  ; in sub1, sound_engine
snd_ptr4           equ $d8  ; data pointer (2 bytes); in sub1, sound7
snd_ptr5           equ $da  ; data pointer (2 bytes); in sub1, sound6
snd_arr1           equ $dc  ; 4 bytes; in many subs
snd_arr2           equ $e0  ; 5 bytes; in sound7
snd_arr3           equ $e5  ; 4 bytes; in many subs
snd_arr4           equ $e9  ; 4 bytes; in sub1, sound4, sound6
apu_ctrl_mirror    equ $ef
; $f0-$fe: unaccessed
useless            equ $ff  ; only MSB is read; it's always set

; other RAM (note: "unaccessed" = unaccessed except for the initial cleanup)
ram1               equ $0100
ram2               equ $0101
ram3               equ $0102
bowser_some_arr1   equ $0104  ; 4 bytes
bowser_tile_arr    equ $0108  ; 4 bytes
ram4               equ $0110
ram5               equ $0111
bowser_x_arr       equ $0112  ; 4 bytes
bowser_y_arr       equ $0116  ; 4 bytes
bowser_some_arr2   equ $011a  ; 4 bytes
ram_arr1           equ $011e  ; up to 16 bytes
ram6               equ $012e
ram7               equ $012f
ram8               equ $0130
bowser_timer_lo    equ $0135
bowser_timer_hi    equ $0136
ram9               equ $0137
ram10              equ $0138
ram14              equ $0139
ram15              equ $013a
ram16              equ $013b
ram17              equ $013c
ram18              equ $013d
ram19              equ $013e
cola_timer_lo      equ $013f
cola_timer_hi      equ $0140
horzbars2_timer_lo equ $0141
horzbars2_timer_hi equ $0142
checkered_timer_lo equ $0143
checkered_timer_hi equ $0144
gradients_timer_lo equ $0145
gradients_timer_hi equ $0146
ram20              equ $0148
ram21              equ $0149
ram22              equ $014a
ram23              equ $014b
ram24              equ $014c
credits_bg_pal     equ $014d  ; background palette number in credits
ram25              equ $014e
greets_timer_lo    equ $014f
greets_timer_hi    equ $0150
gameover_timer_lo  equ $0151
gameover_timer_hi  equ $0152
ram26              equ $0153
title_arr1         equ $0154  ; 22 bytes
title_arr2         equ $016a  ; 22 bytes
title_arr3         equ $0180  ; 22 bytes
title_arr4         equ $0196  ; 22 bytes
; $01ac-$01eb: unaccessed
; $01ec-$01ff: probably stack
; $0200-$02ff: unaccessed
snd_arr5           equ $0300  ; 4 bytes; in sound1, sound4, sound6, sound7
snd_arr6           equ $0304  ; 4 bytes; in sound7
snd_arr7           equ $0308  ; in sound2, sound3, sound4, sound5, sound6, sound7
snd_arr8           equ $0310  ; 4 bytes; in sound6
snd_arr9           equ $0314  ; 4 bytes; in sound3
snd_arr10          equ $0318  ; 4 bytes; in sound3
snd_arr11          equ $031c  ; in sound6
snd_arr12          equ $0320  ; 4 bytes; in sound1, sound6
snd_arr13          equ $0324  ; 4 bytes; in sound1
snd_arr14          equ $0328  ; 4 bytes; in sound4, sound5, sound6
snd_arr15          equ $032c  ; 4 bytes; in sound4, sound5, sound6
snd_arr16          equ $0330  ; 4 bytes; in sound2, sound6
snd_arr17          equ $0334  ; 4 bytes; in sound3
snd_arr18          equ $0338  ; 4 bytes; in sound3, sound6
snd_arr19          equ $033c  ; 4 bytes; in sound6
useless_arr1       equ $0340  ; 4 bytes; unaccessed
snd_arr20          equ $0344  ; in sound1, sound6
snd_arr21          equ $034c  ; 4 bytes; in sound_util2, sound6
snd_arr22          equ $0350  ; 5 bytes; in sound3, sound5, sound6, sound7
snd_arr23          equ $0355  ; 5 bytes; in sound6, sound7
snd_arr24          equ $035a  ; 5 bytes; in sound1, sound3, sound4, sound5, sound6, sound7
snd_arr25          equ $035f  ; 5 bytes; in sound1, sound3, sound5, sound7
snd_arr26          equ $0364  ; 5 bytes; in sub1, sound7
snd_arr27          equ $0369  ; 5 bytes; in sub1, sound7
snd_arr28          equ $036e  ; 5 bytes; in sound7
snd_arr29          equ $0373  ; 5 bytes; in sound7
snd_arr30          equ $0378  ; in sound7
snd_arr31          equ $038a  ; in sound7
snd_arr32          equ $038f  ; in sound6, sound7
snd_arr33          equ $0394  ; in sound_util1, sound6, sound7
useless_arr2       equ $0398  ; unaccessed
snd_arr34          equ $039c  ; in sound_engine, sound4, sound6, sound7
snd_arr35          equ $03a0  ; in sound3, sound6
snd_arr36          equ $03a4  ; in sound4, sound5, sound6
snd_arr37          equ $03a8  ; in sound4, sound6
snd_arr38          equ $03ac  ; in sound_util2, sound6
snd_arr39          equ $03b4  ; in sound6
snd_arr40          equ $03e0  ; in sub1
; $0400-$04ff: unaccessed
sprite_page        equ $0500  ; 256 bytes
ram_arr2           equ $0600  ; in anim_checkered, anim_gradients; up to 128 bytes
; $0680-$07bf: unaccessed
palette_copy       equ $07c0  ; 32 bytes
; $07e0-$07ff: unaccessed

; video RAM
name_table0  equ $2000
attr_table0  equ $23c0
name_table1  equ $2400
attr_table1  equ $27c0
name_table2  equ $2800
attr_table2  equ $2bc0
vram_palette equ $3f00

; id's of parts of the demo (stored in demo_part)
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
        sta _label+1
endm

macro cmp_beq _value, _target
        cmp _value
        beq _target
endm

macro copy _src, _dst       ; note: for clarity, don't use this if A is read later
        lda _src
        sta _dst
endm

macro inc_lda _mem
        inc _mem
        lda _mem
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
        copy #>(_addr), ppu_addr
        copy #<(_addr), ppu_addr
endm

macro set_ppu_addr_via_x _addr
        ldx #>(_addr)
        stx ppu_addr
        ldx #<(_addr)
        stx ppu_addr
endm

macro sub _operand
        sec
        sbc _operand
endm

; --- iNES header ---------------------------------------------------------------------------------

        base $0000

        db "NES", $1a            ; id
        db 2                     ; 32 KiB PRG ROM
        db 4                     ; 32 KiB CHR ROM
        db %00110000, %00000000  ; mapper 3 (CNROM), horizontal name table mirroring
        pad $0010, $00           ; padding

; --- Start of PRG ROM (unaccessed block) ---------------------------------------------------------

        base $8000

        jmp jump_snd_eng
        jmp call_sub1
        sei
        cld
        ldx #$ff
        txs
        copy #%01000000, ppu_ctrl
        copy #%10011110, ppu_mask
        lda ppu_status
        lda ppu_status
        copy #%00000000, ppu_mask
        lda #<sound_data
        ldx #>sound_data
        jsr sub1
        copy #%00011110, ppu_mask
        copy #%10000000, ppu_ctrl
-       jmp -

; -------------------------------------------------------------------------------------------------

        ; Args: A = pointer low, X = pointer high
        ; Reads indirect data via snd_ptr3
        ; Called by call_sub1 with argument sound_data
        ; Calls: nothing

sub1    sta snd_ptr3+0      ; $8034
        stx snd_ptr3+1

        lda #16             ; snd_ptr3+16 -> snd_ptr5
        add snd_ptr3+0
        sta snd_ptr5+0
        lda snd_ptr3+1
        adc #0
        sta snd_ptr5+1

        ldy #3              ; [snd_ptr3+3] -> snd_var5
        lda (snd_ptr3),y
        sta snd_var5
        ;
        iny                 ; [snd_ptr3+4] -> snd_var9
        lda (snd_ptr3),y
        sta snd_var9
        ;
        iny                 ; [snd_ptr3+7] -> snd_var8
        iny
        iny
        lda (snd_ptr3),y
        sta snd_var8

        iny                 ; copy [snd_ptr3] + 8...12 to snd_arr40 + 0...4
        lda (snd_ptr3),y
        sta snd_arr40+0
        iny
        lda (snd_ptr3),y
        sta snd_arr40+1
        iny
        lda (snd_ptr3),y
        sta snd_arr40+2
        iny
        lda (snd_ptr3),y
        sta snd_arr40+3
        iny
        lda (snd_ptr3),y
        sta snd_arr40+4

        iny4                ; 144 -> snd_var1
        tya
        add #128
        sta snd_var1

        lda snd_ptr3+0      ; snd_ptr3+snd_var1 -> snd_ptr4
        adc snd_var1
        sta snd_ptr4+0
        lda snd_ptr3+1
        adc #0
        sta snd_ptr4+1

        lda snd_var8        ; snd_var1 += snd_var8*4; carry -> snd_var2
        asl
        asl
        adc snd_var1
        sta snd_var1
        lda #0
        adc #0
        sta snd_var2

        lda snd_ptr3+0
        adc snd_var1
        sta snd_arr26+0
        lda snd_ptr3+1
        adc snd_var2
        sta snd_arr27+0

        lda snd_arr40+0
        asl
        adc snd_arr26+0
        sta snd_arr26+1
        lda #0
        adc snd_arr27+0
        sta snd_arr27+1

        lda snd_arr40+1
        asl
        adc snd_arr26+1
        sta snd_arr26+2
        lda #0
        adc snd_arr27+1
        sta snd_arr27+2

        lda snd_arr40+2
        asl
        adc snd_arr26+2
        sta snd_arr26+3
        lda #0
        adc snd_arr27+2
        sta snd_arr27+3

        lda snd_arr40+3
        asl
        adc snd_arr26+3
        sta snd_arr26+4
        lda #0
        adc snd_arr27+3
        sta snd_arr27+4

        lda #$00            ; clear sound arrays 1, 3-5, 7-10, 12-25, 33-34, 36
        ldx #3
-       sta snd_arr5,x
        sta snd_arr1,x
        sta snd_arr7,x
        sta snd_arr4,x
        sta snd_arr8,x
        sta snd_arr9,x
        sta snd_arr10,x
        sta snd_arr33,x
        sta snd_arr13,x
        sta snd_arr12,x
        sta useless_arr2,x
        sta snd_arr14,x
        sta snd_arr36,x
        sta snd_arr15,x
        sta snd_arr16,x
        sta snd_arr17,x
        sta snd_arr18,x
        sta snd_arr19,x
        sta useless_arr1,x
        sta snd_arr20,x
        sta snd_arr3,x
        sta snd_arr21,x
        sta snd_arr22,x
        sta snd_arr23,x
        sta snd_arr24,x
        sta snd_arr25,x
        sta snd_arr34,x
        dex
        bpl -

        sta snd_var6
        sta snd_var7
        sta apu_ctrl_mirror  ; disable all sound channels
        sta apu_ctrl
        ldx snd_var5
        inx
        stx snd_var4
        rts

; --- Sound subs that call no other subs ----------------------------------------------------------

        ; Args: A (0-63), X (channel, 0-3), snd_arr33
        ; Called by: sound1
sound_util1
        ; clamp A to 0-63 range (but it always is already)
        cmp #0
        bpl +               ; always taken
        lda #0              ; unaccessed ($8157)
+       cmp #63
        bcc +               ; always taken
        lda #63             ; unaccessed ($815d)
        ;
+       lsr
        lsr
        ora snd_arr33,x
        ldy apu_reg_offsets,x  ; 0, 4, 8, 12
        sta apu_regs,y
        rts

        ; Args: X (channel, 0-3), A, snd_var1, snd_arr21, snd_arr38
        ; Called by: sound2, sound3, sound4, sound5
sound_util2
        cpx #3
        beq ++
        cpx #2
        beq +++
        ;
        ldy apu_reg_offsets,x  ; 0, 4, 8, 12
        sta apu_regs+2,y
        lda #$08
        sta apu_regs+1,y
        lda snd_var1
        cmp snd_arr38,x
        beq +
        sta snd_arr38,x
        ora #%00001000
        sta apu_regs+3,y
+       rts

++      and #%00001111
        ora snd_arr21,x
        sta noise_period
        copy #$08, noise_length
        rts

+++     ldy apu_reg_offsets,x  ; 0, 4, 8, 12
        sta apu_regs+2,y
        lda snd_var1
        ora #%00001000
        sta apu_regs+3,y
        rts

; -------------------------------------------------------------------------------------------------

        ; Called by: sound7, jump_snd_eng
        ; Calls: sound1, sound3, sound6

sound_engine
        lda snd_var5
        beq snd_eng_exit
        ;
        inc snd_var4
        cmp snd_var4
        beq +
        bpl +++
        ;
+       copy #$00, snd_var4
        lda snd_var6
        cmp #$40
        bcc ++
        copy #$00, snd_var6
        ldx snd_var7
        inx
        cpx snd_var8
        bcc +
        ldx snd_var9
+       stx snd_var7
++      jmp sound6

        ; loop
+++     lda #$06            ; unnecessary
        ldx #3
-       lda snd_arr3,x
        bmi ++
        sub #1
        bpl +
        ;
        lda apu_ctrl_channel_disable_masks,x
        and apu_ctrl_mirror
        sta apu_ctrl_mirror
        ;
        lda #$00
+       sta snd_arr3,x
++      cpx #$02
        bne +
        copy #$ff, triangle_ctrl
+       dex
        bpl -

        lda apu_ctrl
        and #%00010000
        bne +
        ;
        lda apu_ctrl_mirror
        and #%00001111
        sta apu_ctrl_mirror
+       copy apu_ctrl_mirror, apu_ctrl

        ldx #3              ; loop
-       cpx #2
        beq +
        jsr sound1
+       jsr sound3
        dex
        bpl -

snd_eng_exit
        inc snd_arr34+0
        inc snd_arr34+1
        inc snd_arr34+2
        inc snd_arr34+3
        rts

; -------------------------------------------------------------------------------------------------

        ; Called by: sound_engine
        ; Calls: sound_util1

sound1  lda snd_arr24,x
        cmp #$0a
        bne +++
        lda snd_arr25,x
        beq +
        sta snd_arr13,x
+       lda snd_arr13,x
        tay
        and #%11110000
        beq +               ; always taken

        lsr4                ; unaccessed block ($823b)
        adc snd_arr5,x
        sta snd_arr5,x
        jmp ++

+       tya
        and #%00001111
        eor #%11111111
        sec
        adc snd_arr5,x
        sta snd_arr5,x
++      jmp +

+++     lda snd_arr12,x
        beq +
        clc
        adc snd_arr5,x
        sta snd_arr5,x
+       ldy snd_arr24,x
        cpy #$07
        bne ++              ; always taken

        lda snd_arr25,x     ; unaccessed block ($826a)
        beq +
        sta useless_arr1,x
+       lda useless_arr1,x
        bne unacc1

++      lda snd_arr20,x
        bne unacc1          ; never taken
        lda snd_arr5,x
        bpl +
        lda #$00
+       cmp #$3f
        bcc +               ; always taken
        lda #$3f            ; unaccessed ($8287)
+       sta snd_arr5,x
        jmp sound_util1     ; ends with RTS

; --- Unaccessed block ($828f) --------------------------------------------------------------------

unacc1  pha
        and #%00001111
        ldy snd_arr19,x
        jsr sound2a
        bmi +
        clc
        adc snd_arr5,x
        jsr sound_util1
        pla
        lsr4
        clc
        adc snd_arr19,x
        cmp #$20
        bpl ++
        sta snd_arr19,x
        rts
+       clc
        adc snd_arr5,x
        jsr sound_util1
        pla
        lsr4
        clc
        adc snd_arr19,x
        cmp #$20
        bpl ++
        sta snd_arr19,x
        rts
++      sub #$40
        sta snd_arr19,x
        rts

; -------------------------------------------------------------------------------------------------

        ; sound2b called by: sound3
        ; Calls: sound_util2
sound2a bmi +
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

sound2b pha
        and #%00001111
        ldy snd_arr16,x
        jsr sound2a
        ror
        bmi +
        clc
        adc snd_arr1,x
        tay
        lda snd_arr7,x
        adc #0
        sta snd_var1
        tya
        jsr sound_util2
        pla
        lsr4
        clc
        adc snd_arr16,x
        cmp #$20
        bpl ++
        sta snd_arr16,x
        rts
        ;
+       clc
        adc snd_arr1,x
        tay
        lda snd_arr7,x
        adc #$ff
        sta snd_var1
        tya
        jsr sound_util2
        pla
        lsr4
        clc
        adc snd_arr16,x
        cmp #$20
        bpl ++
        sta snd_arr16,x
        rts
        ;
++      sub #$40
        sta snd_arr16,x
        rts

; -------------------------------------------------------------------------------------------------

        ; Called by: sound_engine
        ; Calls: sound_util2, sound2, sound4

sound3  jsr sound4
        jmp +++

sound3a ldy snd_arr24,x
        cpy #$04
        bne ++
        lda snd_arr25,x
        beq +
        sta snd_arr17,x
+       lda snd_arr17,x
        bne sound2b
        ;
++      lda snd_arr18,x
        bne sound2b
        lda snd_arr7,x
        sta snd_var1
        lda snd_arr1,x
        jmp sound_util2

+++     lda snd_arr24,x
        cmp_beq #3, sound3b
        cmp_beq #1, ++
        cmp_beq #2, +++
        lda snd_arr35,x
        bne +               ; never taken
        jmp sound3a

+       lda snd_arr35,x     ; unaccessed block ($838e)
        bmi +
        clc
        adc snd_arr1,x
        sta snd_arr1,x
        lda snd_arr7,x
        adc #0
        sta snd_arr7,x
        jmp sound3a
+       clc
        adc snd_arr1,x
        sta snd_arr1,x
        lda snd_arr7,x
        adc #$ff
        sta snd_arr7,x
        jmp sound3a

++      lda snd_arr25,x
        beq +
        sta snd_arr10,x
+       lda snd_arr1,x
        sec
        sbc snd_arr10,x
        sta snd_arr1,x
        lda snd_arr7,x
        sbc #0
        sta snd_arr7,x
        jmp sound3a

+++     lda snd_arr25,x
        beq +
        sta snd_arr10,x
+       lda snd_arr1,x
        clc
        adc snd_arr10,x
        sta snd_arr1,x
        lda snd_arr7,x
        adc #0
        sta snd_arr7,x
        jmp sound3a

sound3b lda snd_arr22,x
        beq +
        sta snd_arr9,x
+       lda snd_arr25,x
        beq +
        sta snd_arr10,x
+       ldy snd_arr9,x
        ;
        lda notes_lo-1,y
        sta snd_ptr1+0
        lda notes_hi-1,y
        sta snd_ptr1+1
        ;
        sec
        lda snd_arr1,x
        sbc snd_ptr1+0
        lda snd_arr7,x
        sbc snd_ptr1+1
        bmi +
        bpl ++              ; always taken
        ;
        jmp sound3a         ; unaccessed ($8414)
+       lda snd_arr1,x
        clc
        adc snd_arr10,x
        sta snd_arr1,x
        lda snd_arr7,x
        adc #0
        sta snd_arr7,x
        sec
        lda snd_arr1,x
        sbc snd_ptr1+0
        lda snd_arr7,x
        sbc snd_ptr1+1
        bpl +               ; always taken
        jmp sound3a         ; unaccessed ($8433)
        ;
++      lda snd_arr1,x
        sec
        sbc snd_arr10,x
        sta snd_arr1,x
        lda snd_arr7,x
        sbc #0
        sta snd_arr7,x
        sec
        lda snd_arr1,x
        sbc snd_ptr1+0
        lda snd_arr7,x
        sbc snd_ptr1+1
        bmi +
        jmp sound3a
        ;
+       lda snd_ptr1+0
        sta snd_arr1,x
        lda snd_ptr1+1
        sta snd_arr7,x
        jmp sound3a

; -------------------------------------------------------------------------------------------------

        ; Called by: sound3, sound5
        ; Calls: sound_util2, sound5a

sound4  lda snd_arr24,x
        cmp #$08
        beq +               ; never taken
        lda snd_arr14,x
        bne sound4a
        lda snd_arr36,x
        bne sound4a
        lda snd_arr15,x
        bne sound4a
        rts

+       jmp unacc4          ; unaccessed ($8478)

sound4a lda snd_arr34,x
        ldy snd_arr37,x
        bne +
        and #%00000011
+       cmp_beq #0, +
        cmp_beq #1, ++
        cmp_beq #2, +++
        cmp_beq #3, ++++    ; always taken
        rts                 ; unaccessed ($8495)

+       ldy snd_arr4,x
        lda notes_hi-1,y
        sta snd_arr7,x
        sta snd_var1
        lda notes_lo-1,y
        sta snd_arr1,x
        jmp sound_util2

++      lda snd_arr4,x
        clc
        adc snd_arr14,x
        tay
        lda notes_hi-1,y
        sta snd_arr7,x
        sta snd_var1
        lda notes_lo-1,y
        sta snd_arr1,x
        jmp sound_util2

+++     lda snd_arr4,x
        clc
        adc snd_arr36,x
        tay
        lda notes_hi-1,y
        sta snd_arr7,x
        sta snd_var1
        lda notes_lo-1,y
        sta snd_arr1,x
        jmp sound_util2

++++    lda snd_arr4,x
        clc
        adc snd_arr15,x
        tay
        lda notes_hi-1,y
        sta snd_arr7,x
        sta snd_var1
        lda notes_lo-1,y
        sta snd_arr1,x
        jmp sound_util2

sound4b sta snd_arr5,x
        jmp sound5a

sound4c sta snd_var5
        jmp sound5a

; --- Unaccessed block ($84f8) --------------------------------------------------------------------

unacc2  sub #1
        sta snd_var6
        lda snd_var7
        add #1
        cmp snd_var8
        bcc +
        lda snd_var9
+       sta snd_var7
        jmp sound5a

; -------------------------------------------------------------------------------------------------

        ; Called by: sound4, sound7
        ; Calls: sound_util2

sound5  ldy snd_arr24,x
        beq sound5a

        lda snd_arr25,x
        cpy #$0c
        beq sound4b
        cpy #$0f
        beq sound4c
        cpy #$0d
        beq unacc2          ; never taken

sound5a lda snd_arr25,x
        cpy #$08
        beq unacc3          ; never taken

        lda snd_arr14,x
        bne ++
        lda snd_arr36,x
        bne ++
        lda snd_arr15,x
        bne ++

        lda snd_arr22,x
        beq +
        lda snd_arr24,x
        cmp #3
        beq +

        lda snd_arr7,x
        sta snd_var1
        lda snd_arr1,x
        jmp sound_util2
+       rts

unacc3  jsr unacc4          ; unaccessed block ($854e)
        lda snd_arr7,x
        sta snd_var1
        lda snd_arr1,x
        jmp sound_util2

++      jmp sound4a

; --- Unaccessed block ($855e) --------------------------------------------------------------------

unacc4  lda snd_arr25,x
        beq +
        sta useless_arr2,x
+       sec
        lda snd_var4
        beq +
-       cmp_beq #1, ++
        cmp_beq #2, +++
        sbc #3
        bne -
+       ldy snd_arr4,x
        lda notes_lo-1,y
        sta snd_arr1,x
        lda notes_hi-1,y
        sta snd_arr7,x
        rts
++      lda useless_arr2,x
        lsr4
        clc
        adc snd_arr4,x
        tay
        lda notes_lo-1,y
        sta snd_arr1,x
        lda notes_hi-1,y
        sta snd_arr7,x
        rts
+++     lda useless_arr2,x
        and #%00001111
        clc
        adc snd_arr4,x
        tay
        lda notes_lo-1,y
        sta snd_arr1,x
        lda notes_hi-1,y
        sta snd_arr7,x
        rts

; -------------------------------------------------------------------------------------------------

        ; Reads sound_data via snd_ptr5
        ; Called by: sound_engine, sound7
        ; Calls: sound7, sound7a, sound7e

-       lda snd_arr11,x
        sta snd_arr3,x
        ;
        lda snd_arr39,x
        sta snd_arr5,x
        ;
        lda apu_ctrl_channel_enable_masks,x
        ora apu_ctrl_mirror
        sta apu_ctrl_mirror
        ;
        jmp sound6b
        ;
sound6  jsr sound7
        ldx #3
sound6a lda snd_arr23,x
        bne +
        jmp sound6b
+       cmp snd_arr8,x
        beq -

        sta snd_arr8,x
        asl
        asl
        asl
        adc #$f8
        tay
        lda (snd_ptr5),y
        iny
        sta snd_arr33,x
        lda (snd_ptr5),y
        iny
        sta snd_arr35,x
        lda (snd_ptr5),y
        iny
        sta snd_arr18,x
        lda (snd_ptr5),y
        iny
        sta snd_arr20,x
        lda (snd_ptr5),y
        bmi unacc5
        iny
        and #%01111111
        sta snd_var1
        lda snd_arr33,x
        asl
        asl
        and #%10000000
        ora snd_var1
        sta snd_arr3,x
        sta snd_arr11,x
        lda (snd_ptr5),y
        sta snd_var1
        and #%11110000
        lsr
        lsr
        sta snd_arr5,x
        sta snd_arr39,x
        lda snd_var1
        and #%00001111
        eor #%11111111
        add #1
        sta snd_arr12,x
        jmp +

unacc5  iny                 ; unaccessed block ($862d)
        and #%01111111
        sta snd_var1
        lda snd_arr33,x
        asl
        asl
        and #%10000000
        ora snd_var1
        sta snd_arr3,x
        sta snd_arr11,x
        lda (snd_ptr5),y
        sta snd_var1
        and #%11110000
        lsr
        lsr
        sta snd_arr5,x
        lda snd_var1
        and #%00001111
        sta snd_arr12,x

+       iny
        lda (snd_ptr5),y
        iny
        sta snd_var1
        asl
        and #%10000000
        sta snd_arr21,x
        lda snd_var1
        and #%00100000
        sta snd_arr37,x
        lda (snd_ptr5),y
        tay
        and #%00001111
        bcs unacc6
        sta snd_arr14,x
        tya
        lsr4
        sta snd_arr36,x
        lda snd_var1
        and #%00001111
        sta snd_arr15,x
        jmp +

unacc6  eor #%11111111      ; unaccessed block ($8681)
        add #1
        sta snd_arr14,x
        tya
        lsr4
        eor #%11111111
        add #1
        sta snd_arr36,x
        lda snd_var1
        and #%00001111
        eor #%11111111
        add #1
        sta snd_arr15,x

+       lda apu_ctrl_channel_enable_masks,x
        ora apu_ctrl_mirror
        sta apu_ctrl_mirror

sound6b ldy snd_arr22,x
        beq sound6c
        cpy #$61
        beq ++
        sty snd_arr4,x

        lda #$00
        sta snd_arr34,x
        sta snd_arr19,x

        lda snd_arr11,x
        sta snd_arr3,x

        lda apu_ctrl_channel_enable_masks,x
        ora apu_ctrl_mirror
        sta apu_ctrl_mirror

        lda snd_arr24,x
        cmp #$03
        beq sound6c
        lda #$ff
        sta snd_arr38,x
        lda #$00
        sta snd_arr16,x
        cpx #$03
        beq +++
        lda notes_lo-1,y
        sta snd_arr1,x
        lda notes_hi-1,y

-       sta snd_arr7,x
        ;
        lda apu_ctrl_channel_enable_masks,x
        ora apu_ctrl_mirror
        sta apu_ctrl_mirror

sound6c dex
        bmi +
        jmp sound6a
+       jmp sound7e

++      lda apu_ctrl_channel_disable_masks,x
        and apu_ctrl_mirror
        sta apu_ctrl_mirror
        jmp sound6c

+++     dey
        sty snd_arr1,x
        lda #$00
        jmp -

sound6d lda #$00
        sta snd_arr32,x
        jmp sound7a

; -------------------------------------------------------------------------------------------------

        ; Reads sound_data via snd_ptr1, snd_ptr2, snd_ptr4
        ; Called by: sound6
        ; Calls: sound5, sound6d

sound7  copy #$40, snd_var3

        lda #$00
        ldx #4
-       sta snd_arr22,x
        sta snd_arr23,x
        sta snd_arr24,x
        sta snd_arr25,x
        dex
        bpl -

        lda snd_var6
        bne +
        lda snd_var4
        bne +
        jmp ++
+       jmp sound7b
++      lda snd_var7
        asl
        asl
        tay

        lda (snd_ptr4),y
        iny
        tax
        and #%00011111
        asl
        sta snd_arr6+0

        lda (snd_ptr4),y
        sta snd_var1
        lsr
        sty snd_var2
        tay
        and #%00111110
        sta snd_arr6+2

        txa
        ror
        tax
        ;
        tya
        lsr
        txa
        ror
        ror
        ror
        and #%00111110
        sta snd_arr6+1

        asl snd_var1
        ldy snd_var2
        iny
        lda (snd_ptr4),y
        tax
        rol
        asl
        and #%00111110
        sta snd_arr6+3

        txa
        lsr
        lsr
        lsr
        and #%00111110
        sta snd_arr7+0

        ; loop
        ldx #4
        ;
-       lda snd_arr26,x
        sta snd_ptr1+0
        lda snd_arr27,x
        sta snd_ptr1+1
        ;
        ldy snd_arr6,x      ; out of bounds? snd_arr6+4 = snd_arr7
        lda (snd_ptr1),y
        iny
        cmp #$00
        bne ++
        sta snd_var1
        lda (snd_ptr1),y
        bne +               ; never taken
        jmp sound6d

+       lda snd_var1        ; unaccessed ($8798)
++      add snd_ptr3+0
        sta snd_arr28,x
        sta snd_ptr2+0
        ;
        lda (snd_ptr1),y
        adc snd_ptr3+1
        sta snd_arr29,x
        sta snd_ptr2+1
        ;
        ldy #0
        lda (snd_ptr2),y
        sta snd_arr31,x
        iny
        lda (snd_ptr2),y
        adc #1
        sta snd_arr32,x
        ;
        adc #1
        lsr
        add #2
        sta snd_arr2,x
        ;
        lda #$00
        sta snd_arr30,x
sound7a dex
        bpl -

sound7b ldx #4
sound7c dec snd_arr32,x
        bmi +
        dec snd_arr31,x
        bpl +
        jmp ++
+       jmp sound7d
++      lda snd_arr28,x
        sta snd_ptr1+0
        lda snd_arr29,x
        sta snd_ptr1+1
        ;
        lda snd_var6
        lsr
        tay
        iny
        iny
        lda (snd_ptr1),y
        bcc +
        lsr4
+       ldy snd_arr30,x
        sty snd_var1
        bit snd_var1
        ldy snd_arr2,x
        lsr
        sta snd_var1
        bcc ++++
        cpx #$03
        beq ++
        bvs +
        lda (snd_ptr1),y
        iny
        jmp +++

+       lda (snd_ptr1),y
        and #%11110000
        sta snd_var2
        iny
        lda (snd_ptr1),y
        and #%00001111
        ora snd_var2
        jmp +++

++      bvs +
        lda (snd_ptr1),y
        and #%00001111
        sbc #$ff
        bit snd_var3
        jmp +++

+       lda (snd_ptr1),y
        lsr4
        add #1
        iny
        clv
+++     sta snd_arr22,x
++++    lsr snd_var1
        bcc ++
        bvs +
        lda (snd_ptr1),y
        and #%00001111
        adc #0
        sta snd_arr23,x
        bit snd_var3
        jmp ++

+       lda (snd_ptr1),y
        lsr4
        iny
        add #1
        sta snd_arr23,x
        clv
++      lsr snd_var1
        bcc +++
        bvs +
        lda (snd_ptr1),y
        and #%00001111
        bit snd_var3
        jmp ++

+       lda (snd_ptr1),y
        lsr4
        iny
        clv
++      sta snd_arr24,x
+++     lsr snd_var1
        bcc +++
        bvs +
        lda (snd_ptr1),y
        iny
        jmp ++

+       lda (snd_ptr1),y
        and #%11110000
        sta snd_var2
        iny
        lda (snd_ptr1),y
        and #%00001111
        ora snd_var2
++      sta snd_arr25,x
+++     sty snd_arr2,x
        lda #$40
        bvs +
        lda #$00
+       sta snd_arr30,x
sound7d dex
        bmi +
        jmp sound7c
+       rts

sound7e ldx #3              ; loop
-       ldy snd_arr3,x
        bmi ++
        dey
        bpl +
        ;
        lda apu_ctrl_channel_disable_masks,x
        and apu_ctrl_mirror
        sta apu_ctrl_mirror
        ;
        lda #$00
        ldy #$00
+       sty snd_arr3,x
++      dex
        bpl -

        lda apu_ctrl
        and #%00010000
        bne +
        ;
        lda apu_ctrl_mirror
        and #%00001111
        sta apu_ctrl_mirror
+       copy apu_ctrl_mirror, apu_ctrl

        ldx #3              ; loop
-       jsr sound5
        cpx #$02
        beq ++
        lda snd_arr23,x
        bne +
        lda snd_arr24,x
        cmp #$0c
        beq +
        jmp ++
+       lda snd_arr5,x
        lsr
        lsr
        ora snd_arr33,x
        ldy apu_reg_offsets,x  ; 0, 4, 8, 12
        sta apu_regs,y
++      dex
        bpl -

        inc snd_arr34+0
        inc snd_arr34+1
        inc snd_arr34+2
        inc snd_arr34+3
        inc snd_var6
        rts

; --- Unaccessed block ($8906) --------------------------------------------------------------------

        ldx #0
        ldy #16
-       dex
        bne -
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
        bmi +               ; always taken

        dec useless         ; unaccessed block ($8925)
        bpl +
        copy #$05, useless
        jmp unacc7

+       jmp sound_engine

unacc7  rts                 ; unaccessed ($8933)

; -------------------------------------------------------------------------------------------------

        ; Called by init with args A=0, X=1
        ; Calls sub1 with args A = <sound_data, X = >sound_data
call_sub1
        ldy #255
        dex
        beq +               ; always taken
        ldy #5              ; unaccessed ($8939)
+       sty useless
        asl
        tay
        lda ptr_to_sound_data+1,y
        tax
        lda ptr_to_sound_data+0,y
        jsr sub1
        rts

; --- Lots of data --------------------------------------------------------------------------------

        ; unaccessed ($894a)
        hex c0 00 ff fe fd fc fb fa f9 f8 f7 f6 f5 f4 f3 f2 f1

apu_reg_offsets
        ; read by: sound_util1, sound_util2, sound7
        db 0, 4, 8, 12
apu_ctrl_channel_enable_masks
        ; OR bitmasks for enabling square 1 / square 2 / triangle / noise
        ; read by sound6
        db %00000001, %00000010, %00000100, %00001000
apu_ctrl_channel_disable_masks
        ; AND bitmasks for disabling square 1 / square 2 / triangle / noise
        ; read by sound_engine, sound6, sound7
        db %11111110, %11111101, %11111011, %11110111

or_masks
        ; $8967 (some bytes unaccessed; read by sound2)
        hex 00 10 20 30 40 50 60 70 80 90 a0 b0 c0 d0 e0 f0
        hex e0 d0 c0 b0 a0 90 80 70 60 50 40 30 20 10 00

        ; $8986 (most bytes unaccessed)
        ; read by: sound2
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
        ; read by: sound3, sound4, sound6
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

        ; $8b46; read by call_sub1; only the first entry is accessed
ptr_to_sound_data
        dw sound_data
        dw sound_data_end, sound_data_end, sound_data_end, sound_data_end
        dw sound_data_end, sound_data_end, sound_data_end, sound_data_end
        dw sound_data_end, sound_data_end, sound_data_end, sound_data_end
        dw sound_data_end, sound_data_end, sound_data_end, sound_data_end

sound_data
        ; $8b68-$8dbf (600 bytes)
        ; Read via snd_ptr1, snd_ptr2, snd_ptr4, snd_ptr5 by sound6, sound7
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

sound_data_end              ; $a08d

; -------------------------------------------------------------------------------------------------

        ; Note: the program continues at the next 16-KiB boundary for some reason although
        ; technically there is only one 32-KiB PRG ROM bank.
        pad $c000, $00

init    ; Called by: reset vector
        ; Calls: wait_vbl, hide_sprites, init_palette_copy, update_palette, fill_nt_and_clear_at,
        ;        init_stars, fill_attribute_tables, call_sub1

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
        jsr update_palette     ; palette_copy -> PPU

        ; update 4th sprite subpalette
        set_ppu_addr vram_palette+7*4
        copy #$0f, ppu_data  ; black
        copy #$1c, ppu_data  ; medium-dark cyan
        copy #$2b, ppu_data  ; medium-light green
        copy #$39, ppu_data  ; light yellow
        reset_ppu_addr

        copy #id_wecome, demo_part  ; the first part of the demo to run

        copy #%00000000, ppu_ctrl  ; disable NMI
        copy #%00011110, ppu_mask  ; show BG and sprites

        ldx #$ff
        jsr fill_nt_and_clear_at
        jsr init_stars

        lda #%00000000
        sta ppu_ctrl        ; disable NMI
        sta ppu_mask        ; hide BG and sprites

        ldy #$00
        jsr fill_attribute_tables
        copy #$ff, pulse1_ctrl

        reset_ppu_addr

        lda #$00
        ldx #$01
        jsr call_sub1
        jsr wait_vbl

        copy #%10000000, ppu_ctrl  ; enable NMI
        copy #%00011110, ppu_mask  ; show BG and sprites

-       lda demo_part       ; infinite loop; if at last part of demo, do sound stuff
        cmp #id_horzbars2
        bne +
        copy #$0d, dmc_addr
        copy #$fa, dmc_length
+       jmp -

; --- Lots of data --------------------------------------------------------------------------------

wecome_text_pointers  ; $c0a8
        dw wecome_text+0*16
        dw wecome_text+1*16
        dw wecome_text+2*16
        dw wecome_text+3*16
        dw wecome_text+4*16
        dw wecome_text+5*16
        dw wecome_text+6*16
        dw wecome_text+7*16  ; unaccessed ($c0b6)

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
        hex a9 aa aa aa aa aa aa aa aa aa aa 42

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

        ; Tile numbers of top left tiles of big letters, starting from the big "A".
        ; Read by: print_big_text_line
big_letter_tiles
        hex 48 4a 4c 4e              ; "ABCD"
        hex 60 62 64 66 68 6a 6c 6e  ; "EFGHI KL"
        hex 80 82 84 86 88 8a 8c 8e  ; "MNOPQRST"
        hex a0 a2 a4 a6 a8 aa ac ae  ; "UVW"
        hex c0 c2 c4 c6 c8 ca cc ce
        hex e0 e2 e4 e6 e8 ea ec ee

color_or_table  ; read by: fade_to_black
        hex 0f 00 10 20

        ; Read by: init_friday
friday_bg_palette
        hex 3c 0f 3c 22
friday_spr_palette
        hex 3c 3c 3c 3c

        ; 256 bytes.
        ; If the formula (x+60) % 256 is applied, looks like a smooth curve with values 0-121.
        ; Used as scroll values and sprite positions.
        ; Read by: many anim_ subs
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
        ; Read by: many anim_ parts
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

sprite_x_or_y
        ; Used for sprite X positions in anim_woman and for sprite Y positions in anim_friday.
        ; 256 bytes. 194 (-62) is added to these.
        ; If the formula (x+182) % 256 is applied, looks like a smooth curve with values 0-212.
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
        ; Read by: many anim_ subs
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
        ; Read by: anim_horzbars2, anim_horzbars1
        ; Note: on each line:
        ;     - the high nybbles are 0, 1, 2, 3, 2, 1, 0, 0
        ;     - all low nybbles are the same
some_horzbars_data
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

        ; Sprite data read by anim_title
title_sprite_count_minus_one
        db 24
title_sprites_y
        hex 40 40 40 40 40
        hex 48 48 48 48 48
        hex 50 50 50 50 50
        hex 58 58 58 58 58
        hex 60 60 60 60 60
title_sprites_tile
        hex c6 c7 c8 c9 ca
        hex cb cc cd ce cf
        hex d6 d7 d8 d9 da
        hex db dc dd de df
        hex e0 e1 e2 e3 e4
title_sprites_attr
        hex 01 01 01 01 01
        hex 01 01 01 01 01
        hex 01 01 01 01 01
        hex 01 01 01 01 01
        hex 01 01 01 01 01
title_sprites_x
        hex 40 48 50 58 60
        hex 40 48 50 58 60
        hex 40 48 50 58 60
        hex 40 48 50 58 60
        hex 40 48 50 58 60

        ; Sprite data read by anim_ninja (unaccessed in unmodified demo; $daea).
ninja_sprite_count_minus_one
        db 11
ninja_sprites_y
        hex 00 00 00
        hex 08 08 08
        hex 10 10 10
        hex 18 18 18
ninja_sprites_tile
        hex 00 01 02
        hex 10 11 12
        hex 20 21 22
        hex 30 31 32
        hex 40 40 40
        hex 40 40 40
        hex 40 40 40
        hex 40 40 40
ninja_sprites_x
        hex 00 08 10
        hex 00 08 10
        hex 00 08 10
        hex 00 08 10

        ; Read by: init_bowser, anim_bowser
bowser_sprite_count1_minus_one
        db 3
some_bowser_table1
        hex 04 06 06 06
bowser_sprites_tile1
        hex 09 0e 0c 3e
some_bowser_table2
        hex 0b 0f 0d 3f

        hex 04 02  ; unaccessed ($db28)

        ; Read by: init_bowser, anim_bowser
bowser_sprite_count2_minus_one
        db 16
bowser_sprites_y1
        hex 00 fb fb fb fb 03 03 03 03 f6 f6 f6 ee ee ee e6 e6
bowser_sprites_tile2
        hex 46 1c 1b 1a 19 2c 2b 2a 29 2f 2e 2d 3e 1e 1d 0e 0c
bowser_sprites_attr
        hex 40 41 41 41 41 41 41 41 41 42 42 42 42 42 42 42 42
bowser_sprites_x1
        hex 00 06 0e 16 1e 07 0f 17 1f 0c 14 1c 0c 14 1c 0c 14
bowser_sprite_count3_minus_one
        db 3
some_bowser_data2
        hex 3f
some_bowser_table3  ; looks like a sawtooth wave; last 15 bytes unaccessed
        hex 08 13 19 30 45 50 5e 67 80 88 9f ba c8 d1 e0 f4
        hex 18 25 34 50 54 55 6a 6f 9e ab cd d3 da e5 f0 ff
        hex 0a 19 3a 56 5a 5f 7b 80 90 af b9 c6 cf ea f7 fa
        hex 13 19 25 55 6a 6f 5e 67 80 88 ba c8 e1 eb f0 f4
bowser_sprites_tile3
        hex 40 43 42 41

        ; unaccessed ($dbb5)
        hex 03 00 00 07 07 42 43 52 53 03 03 03 03 00 07 00
        hex 07 01 00 00 41 51 03 03 00 07

        ; Read by: init_bowser, anim_bowser
bowser_and_friday_sprite_count_minus_one  ; also read by init_friday, anim_friday
        db 15
bowser_sprites_x2
        hex 13 50 54 6f 9e ab d0 ff 06 5a 5f c6 ca 13 19 25
bowser_sprites_y2
        hex 55 df 51 21 3d 9a 7d 88 cc 8f aa 43 8a 6e 90 76
bowser_sprites_xsub
        db 3, 5, 5, 7, 6, 4, 6, 5, 2, 5, 4, 8, 3, 2, 7, 6
bowser_sprites_tile4
        hex 50 51 51 53 51 52 50 53 52 52 51 51 52 53 53 51

        ; Star sprite data read by move_stars, init_stars.
        ; The last 5 bytes of each 16-byte table are unaccessed.
star_count_minus_one
        db 10
star_initial_x
        hex 13 50 54 6f 9e ab d0 ef 06 5a 5f d6 ca 13 19 25
star_initial_y
        hex 55 df 51 21 3d 9a 7d 88 cc 8f aa 43 8a 6e 90 76  ; same as bowser_sprites_y2
star_y_speeds
        db 2, 3, 3, 5, 4, 2, 4, 3, 2, 2, 3, 4, 3, 2, 7, 6
star_tiles
        hex af ae ae be be bf af bf bf af ae ae bf be be be

        ; Sprite data read by init_friday, anim_friday
        db 15  ; unaccessed (likely sprite count as in Bowser sprites above)
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

ninja_sprites_tile_add  ; read by anim_ninja (unaccessed in unmodified demo; $dc92)
        hex 00 03 06 03

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
        sta sprite_page+0,x
        inx
        inx
        inx
        inx
        bne -
        rts

; --- Unaccessed block ($dcaa) --------------------------------------------------------------------

        lda #%00000000
        sta ppu_ctrl
        sta ppu_mask
        copy #%00000000, ppu_ctrl
        lda #$00
        ldx #0
-       sta apu_regs,x
        inx
        cpx #15
        bne -
        copy #%11000000, apu_counter  ; frame counter: 5-step seq'r mode, interr. inhibit
        jsr init_palette_copy
        jsr update_palette
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
-       lda #$0f            ; black
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

        set_ppu_addr vram_palette+0*4

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

-       lda delay_var1
        add #85
        bcc +
+       sta delay_var1
        ;
        inc_lda delay_cnt
        cmp delay_var2
        bne -

        rts

; --- Unaccessed block ($dd22) --------------------------------------------------------------------

        stx delay_var2
        ldx #0
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
--      ldy #0
-       nop
        nop
        nop
        nop
        nop
        iny
        cpy #11
        bne -
        nop
        inx
        cpx delay_var2
        bne --
        rts

; -------------------------------------------------------------------------------------------------

fade_to_black
        ; Fade colors in the palette_copy array towards black.
        ; Called by: anim_title, anim_credits, anim_greets
        ; Calls: nothing

        ; Change each color as follows (bits 5-4 = brightness, 3-0 = hue):
        ;     $0x -> $0f (black)
        ;     $1x -> $0x
        ;     $2x -> $1x
        ;     $3x -> $2x

        ldy #0
-       lda palette_copy,y
        sta temp1
        and #%00110000        ; brightness
        lsr4
        tax
        ;
        lda temp1
        and #%00001111        ; hue
        ora color_or_table,x  ; 0f 00 10 20
        sta palette_copy,y
        ;
        iny
        cpy #32
        bne -

        rts

; -------------------------------------------------------------------------------------------------

change_bg_color
        ; Change background color: #$3f (black) if snd_arr3+3 < 8, otherwise snd_arr3+3.
        ; Called by: anim_gradients
        ; Calls: nothing

        set_ppu_addr vram_palette+0*4

        lda snd_arr3+3
        cmp #8
        bcc +
        copy snd_arr3+3, ppu_data
        jmp ++
        ;
+       copy #$3f, ppu_data  ; black
++      rts

; --- Update a metasprite -------------------------------------------------------------------------

; Input: X/Y = first X/Y position, zp6 = first tile, sprite_page_offset = first offset on sprite
;        page
; Return: sprite_page_offset = current offset on sprite page
; Order of sprites: first right, then down.
; Called by: anim_credits
; Call: nothing

update_metasprite_8x2
        ; 8*2 hardware sprites. Subpalette always 3.

        stx zp9             ; first X position
        sty zp10            ; first Y position
        copy zp6, zp11      ; first tile

        lda #0
        sta zp6             ; unused
        sta zp7             ; outer loop counter
        sta zp8             ; what to add to first tile number

--      ; outer loop (counter: zp7 = 0, 8)
        ;
        ldx #0
        copy #0, zp6
        ;
-       ; inner loop (update one sprite/round; counter: X = 0, 8, ..., 56)
        ;
        lda zp8
        add zp11
        ldy sprite_page_offset
        sta sprite_page+1,y  ; tile
        ;
        txa
        adc zp9
        ldy sprite_page_offset
        sta sprite_page+3,y  ; X
        ;
        lda zp7
        add zp10
        ldy sprite_page_offset
        sta sprite_page+0,y  ; Y
        ;
        lda #%00000011
        ldy sprite_page_offset
        sta sprite_page+2,y  ; attributes
        ;
        lda zp6
        add #4
        sta zp6
        ;
        inc zp8
        ;
        iny4
        sty sprite_page_offset  ; to next sprite
        ;
        txa
        add #8
        tax
        cpx #64
        bne -               ; end inner loop
        ;
        lda zp7
        add #8
        sta zp7
        lda zp7
        cmp #16
        bne --              ; end outer loop

        sty sprite_page_offset  ; unnecessary
        rts

update_metasprite_3x2
        ; 3*2 hardware sprites. Subpalette always 2.

        stx zp9             ; first X position
        sty zp10            ; first Y position
        copy zp6, zp11      ; first tile

        lda #0
        sta zp6             ; unused
        sta zp7             ; outer loop counter
        sta zp8             ; what to add to first tile number

--      ; outer loop (counter: zp7 = 0, 8)
        ldx #0
        copy #0, zp6
        ;
-       ; inner loop (update one sprite/round; counter: X = 0, 8, 16)
        ;
        lda zp8
        add zp11
        ldy sprite_page_offset
        sta sprite_page+1,y  ; tile
        ;
        txa
        adc zp9
        ldy sprite_page_offset
        sta sprite_page+3,y  ; X
        ;
        lda zp7
        add zp10
        ldy sprite_page_offset
        sta sprite_page+0,y  ; Y
        ;
        lda #%00000010
        ldy sprite_page_offset
        sta sprite_page+2,y  ; attributes
        ;
        lda zp6
        add #4
        sta zp6
        ;
        inc zp8
        ;
        iny4
        sty sprite_page_offset  ; to next sprite
        ;
        txa
        add #8
        tax
        cpx #24
        bne -               ; end inner loop
        ;
        lda zp7
        add #8
        sta zp7
        lda zp7
        cmp #16
        bne --              ; end outer loop

        sty sprite_page_offset  ; unnecessary
        rts

update_metasprite_4x2
        ; 4*2 hardware sprites. Subpalette always 2.

        stx zp9             ; first X position
        sty zp10            ; first Y position
        copy zp6, zp11      ; first tile

        lda #0
        sta zp6             ; unused
        sta zp7             ; outer loop counter
        sta zp8             ; what to add to first tile number

        ; outer loop (counter: zp7 = 0, 8)
--      ldx #0
        copy #0, zp6
        ;
-       ; inner loop (update one sprite/round; counter: X = 0, 8, 16, 24)
        ;
        lda zp8
        add zp11
        ldy sprite_page_offset
        sta sprite_page+1,y  ; tile
        ;
        txa
        adc zp9
        ldy sprite_page_offset
        sta sprite_page+3,y  ; X
        ;
        lda zp7
        add zp10
        ldy sprite_page_offset
        sta sprite_page+0,y  ; Y
        ;
        lda #%00000010
        ldy sprite_page_offset
        sta sprite_page+2,y  ; attributes
        ;
        lda zp6
        add #4
        sta zp6
        ;
        inc zp8
        ;
        iny4
        sty sprite_page_offset  ; to next sprite
        ;
        txa
        add #8
        tax
        cpx #32
        bne -               ; end inner loop
        ;
        lda zp7
        add #8
        sta zp7
        lda zp7
        cmp #16
        bne --              ; end outer loop

        sty sprite_page_offset  ; unnecessary
        rts

; -------------------------------------------------------------------------------------------------

sub15   ; Called by: anim_title
        ; Calls: nothing

        ldx #0
        ldy #0
        stx zp6
        stx zp7

-       lda sprite_tiles,y  ; loop (Y = 0...21)
        cmp #$ff
        bne +
        ;
        lda zp7
        add #14
        sta zp7
        jmp ++
        ;
+       lda #$e1
        add zp7
        sta sprite_page+0,x
        sta title_arr1,y
        ;
        lda zp7
        sta title_arr2,y
        ;
        lda #$01
        sta title_arr3,y
        ;
        lda sprite_tiles,y
        sta sprite_page+1,x
        ;
        lda #$00
        sta sprite_page+2,x
        ;
        lda zp6
        add #40
        sta sprite_page+3,x
        ;
++      inx
        inx
        inx
        inx
        iny
        lda zp6
        add #8
        sta zp6
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
        ldx #0
        ldy #0
        stx offset
        ;
-       get_top_left_tile_of_big_letter
        stx ppu_data
        inx
        stx ppu_data
        ;
        inc_lda offset
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
        inc_lda offset
        cmp #16
        bne -

        reset_ppu_addr
        rts

; -------------------------------------------------------------------------------------------------

move_stars
        ; Move star sprites up.
        ; Called by: anim_wecome, anim_title
        ; Calls: nothing

        copy #$00, zp6
        ldx star_count_minus_one  ; 10

        ; loop: subtract star_y_speeds,x + 1 from Y positions of sprites 45-55
        ;
-       ; X*4 -> Y
        txa
        asl
        asl
        tay
        ;
        lda sprite_page+45*4+0, y
        clc
        sbc star_y_speeds,x
        sta sprite_page+45*4+0, y
        ;
        dex
        cpx #255
        bne -

        rts

; -------------------------------------------------------------------------------------------------

init_stars
        ; Set up star sprites for the first two parts of the demo.
        ; Called by: init
        ; Calls: nothing

        ; set up sprites #45-#55
        ldx star_count_minus_one  ; 10
-       txa
        asl
        asl
        tay
        ;
        lda star_initial_y,x
        sta sprite_page+45*4+0,y
        lda star_tiles,x
        sta sprite_page+45*4+1,y  ; tile ($ae/$af/$be/$bf)
        lda #%00000011
        sta sprite_page+45*4+2,y  ; subpalette 3
        lda star_initial_x,x
        sta sprite_page+45*4+3,y
        lda star_y_speeds,x
        sta ram_arr1,x            ; 2-7
        ;
        dex
        cpx #255
        bne -

        rts

; -------------------------------------------------------------------------------------------------

macro print_big_text_line_macro _srcline, _dstline
        ; print a line of big text
        copy wecome_text_pointers+_srcline*2+0, big_text_ptr+0
        copy wecome_text_pointers+_srcline*2+1, big_text_ptr+1
        ldx #>(name_table0+_dstline*32)
        ldy #<(name_table0+_dstline*32)
        jsr print_big_text_line
endm

anim_wecome
        ; Animate "GREETINGS! WE COME FROM..." part.
        ; Called by: nmi_wecome
        ; Calls: print_big_text_line, move_stars_and_update_sprites

        chr_bankswitch 0

        lda wecome_timer_hi
        cmp_beq #1,  wecome_jump_table+1*3
        cmp_beq #2,  wecome_jump_table+2*3
        cmp_beq #3,  wecome_jump_table+3*3
        cmp_beq #4,  wecome_jump_table+4*3
        cmp_beq #5,  wecome_jump_table+5*3
        cmp_beq #6,  wecome_jump_table+6*3
        cmp_beq #7,  wecome_jump_table+7*3
        cmp_beq #8,  wecome_jump_table+8*3
        cmp_beq #9,  +
        cmp_beq #10, wecome_jump_table+10*3
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

+       inc vscroll
        inc vscroll
++      copy #%10000000, ppu_ctrl  ; enable NMI
        copy #%00011110, ppu_mask  ; show BG and sprites

wecome_jump_table
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
        copy #0, part_init_done
        jmp bigtext_exit
bigtext_exit
        jmp move_stars_and_update_sprites

; --- Unaccessed block ($e0d3) --------------------------------------------------------------------

macro set_sprite_pos _index, _ycurve, _yadd, _xcurve, _xadd
        lda _ycurve,x
        add #_yadd
        sta sprite_page+_index*4+0
        lda _xcurve,x
        add #_xadd
        sta sprite_page+_index*4+3
endm

macro move_four_sprites _i1, _i2, _i3, _i4
        dec sprite_page+_i1*4+0
        dec sprite_page+_i1*4+3
        dec sprite_page+_i2*4+0
        inc sprite_page+_i2*4+3
        inc sprite_page+_i3*4+0
        dec sprite_page+_i3*4+3
        inc sprite_page+_i4*4+0
        inc sprite_page+_i4*4+3
endm

        copy #$00, zp6
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
        jmp move_stars_and_update_sprites
++      move_four_sprites 0, 1, 2, 3
        move_four_sprites 4, 5, 6, 7

; -------------------------------------------------------------------------------------------------

move_stars_and_update_sprites
        ; Called by: anim_wecome
        ;
        jsr move_stars
        copy #>sprite_page, oam_dma
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

        ; update 1st and 2nd color in 1st sprite subpalette
        set_ppu_addr vram_palette+4*4
        copy #$00, ppu_data  ; dark gray
        copy #$30, ppu_data  ; white
        reset_ppu_addr

        ; update 2nd and 3rd sprite subpalette
        set_ppu_addr vram_palette+5*4+1
        copy #$3d, ppu_data  ; light gray
        copy #$0c, ppu_data  ; dark cyan
        copy #$3c, ppu_data  ; light cyan
        copy #$0f, ppu_data  ; black
        copy #$3c, ppu_data  ; light cyan
        copy #$0c, ppu_data  ; dark cyan
        copy #$1a, ppu_data  ; medium-dark green
        reset_ppu_addr

        ; update 1st BG subpalette
        set_ppu_addr vram_palette+0*4
        copy #$38, ppu_data  ; light yellow
        copy #$01, ppu_data  ; dark purple
        copy #$26, ppu_data  ; medium-light red
        copy #$0f, ppu_data  ; black
        reset_ppu_addr

        copy #1, part_init_done
        copy #$8e, ram6
        copy #$19, ram7
        copy #%00011110, ppu_mask  ; show BG and sprites
        rts

anim_title
        ; Animate title part (wAMMA logo).
        ; Called by: nmi_title
        ; Calls: sub15, fade_to_black, update_palette, move_stars

        chr_bankswitch 0
        copy #>sprite_page, oam_dma      ; do sprite DMA

        copy #%10010000, ppu_ctrl        ; enable NMI, use PT1 for BG

        set_ppu_addr vram_palette+0*4+3  ; update 4th color of 1st BG subpalette
        copy #$0f, ppu_data              ; black
        reset_ppu_addr

        copy #0, ppu_scroll
        ldx ram25
        lda curve1,x
        add ram25
        sta ppu_scroll

        lda ram25
        cmp #$c1
        beq +
        inc ram25
+       lda title_timer_hi
        cmp #2
        bne +
        ;
        lda title_timer_lo
        cmp #50
        bne +
        ;
        jsr sub15
+       lda title_timer_hi
        cmp #1
        bne anim_title_1
        ;
        lda title_timer_lo
        cmp #150
        bne anim_title_1

        ; loop - edit sprites #23-#47
        ldx title_sprite_count_minus_one  ; 24
-       txa
        asl
        asl
        tay
        ;
        lda title_sprites_y,x
        add ram7
        sta sprite_page+23*4+0,y
        lda title_sprites_tile,x
        sta sprite_page+23*4+1,y
        lda title_sprites_attr,x
        sta sprite_page+23*4+2,y
        lda title_sprites_x,x
        add ram6
        sta sprite_page+23*4+3,y
        ;
        cpx #0
        beq +
        dex
        jmp -

        ; edit sprite #24
+       copy #129,       sprite_page+24*4+0
        copy #$e5,       sprite_page+24*4+1
        copy #%00000001, sprite_page+24*4+2
        copy #214,       sprite_page+24*4+3

        ; edit sprite #25
        copy #97,        sprite_page+25*4+0
        copy #$f0,       sprite_page+25*4+1
        copy #%00000010, sprite_page+25*4+2
        copy #230,       sprite_page+25*4+3

        set_ppu_addr vram_palette+0*4+3  ; update 4th color of 1st BG subpalette
        copy #$30, ppu_data              ; white
        reset_ppu_addr

anim_title_1
        lda title_timer_hi
        cmp #2
        bne anim_title_2
        lda title_timer_lo
        cmp #50
        bcc anim_title_2

        ; loop
        ldx #0
        ldy #0
-       lda title_arr3,x
        cmp #$01
        bne +
        ;
        lda #$a0
        clc
        adc title_arr2,x
        sta zp6
        lda title_arr1,x
        sta sprite_page+0,y
        cmp zp6
        bcc +
        ;
        txa
        pha
        inc title_arr4,x
        lda title_arr4,x
        sta zp8
        tax
        lda curve1,x
        sta zp7
        pla
        tax
        lda title_arr1,x
        clc
        sbc zp7
        sbc zp8
        sta title_arr1,x
        ;
+       inx
        iny4
        cpx #22
        bne -

anim_title_2
        lda title_timer_hi
        cmp #2
        bne +
        lda title_timer_lo
        cmp #200
        bcc +
        inc_lda loopcntr3
        cmp #4
        bne +

        jsr fade_to_black
        jsr update_palette  ; palette_copy -> PPU
        copy #0, loopcntr3

+       jsr move_stars
        copy #id_title, demo_part
        rts

; -------------------------------------------------------------------------------------------------

init_horzbars2
        ; Set up full-screen horizontal color bars.
        ; Called by: nmi_horzbars2
        ; Calls: fill_nt_and_clear_at

        lda #$00
        ldx #0
-       sta apu_regs,x
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
        copy #1, part_init_done
        rts

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

        copy #%10000100, ppu_ctrl  ; enable NMI, autoincrement PPU address by 32

        copy #$00, zp1
        ldy #$9f

        ; loop
--      ldx #25
-       dex
        bne -
        ;
        set_ppu_addr_via_x vram_palette+0*4
        inc_lda zp4
        cmp #5
        beq +
        jmp ++
        ;
+       inc zp1
        copy #0, zp4
++      inc_lda zp1
        sbc zp2
        adc zp3
        tax
        lda curve3,x
        sbc zp5
        and #%00111111
        tax
        lda some_horzbars_data,x
        sta ppu_data
        ldx zp3
        lda curve1,x
        tax
        dey
        bne --

        copy #%00000110, ppu_mask  ; hide BG and sprites
        copy #%10010000, ppu_ctrl  ; enable NMI, use PT1 for BG
        rts

; --- Set up and animate checkered wavy animation -------------------------------------------------

init_checkered
        ; Called by: nmi_checkered
        ; Calls: fill_name_tables, fill_attribute_tables, jump_snd_eng, init_palette_copy,
        ;        update_palette

        ldx #$00              ; clear Name Tables
        jsr fill_name_tables

        lda #%00000000
        sta ppu_ctrl        ; disable NMI
        sta ppu_mask        ; hide BG and sprites

        ldy #$14
        jsr fill_attribute_tables
        jsr jump_snd_eng
        jsr init_palette_copy  ; palette_table -> palette_copy
        jsr update_palette     ; palette_copy -> PPU


        set_ppu_addr vram_palette+3*4  ; update 1st color of 4th BG subpalette
        copy #$0f, ppu_data            ; black
        reset_ppu_addr

        copy #1, part_init_done
        copy #5, zp0
        rts

anim_checkered
        ; Called by: nmi_checkered
        ; Calls: delay

        chr_bankswitch 1
        lda ram20
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
        sta ram_arr2,x
        lda zp1
        add zp0
        sta zp1
        inx
        cpx #64
        bne -

        ldx #0
        ldy #0
        copy #$00, zp6

--      copy #$21, ppu_addr
        copy zp6,  ppu_addr

        ldy #0
-       lda ram_arr2,x
        sta ppu_data
        lda ram_arr2,x
        sta ppu_data
        inx
        lda ram_arr2,x
        sta ppu_data
        lda ram_arr2,x
        sta ppu_data
        inx
        iny
        cpy #8
        bne -

        lda zp6
        add #32
        sta zp6
        lda zp6
        cmp #$00
        bne --

        copy #$01, ram20
        jmp anim_checkered_2

anim_checkered_1
        dec zp2
        ldx #64
        copy #$00, zp1

-       lda zp1
        adc zp2
        tay
        lda curve1,y
        sta ram_arr2,x
        lda zp1
        add zp0
        sta zp1
        inx
        cpx #128
        bne -

        ldx #$7f
        copy #$00, zp6

--      copy #$22, ppu_addr
        copy zp6,  ppu_addr

        ldy #0
-       lda ram_arr2,x
        sta ppu_data
        lda ram_arr2,x
        sta ppu_data
        dex
        lda ram_arr2,x
        sta ppu_data
        lda ram_arr2,x
        sta ppu_data
        dex
        iny
        cpy #8
        bne -

        lda zp6
        add #32
        sta zp6
        lda zp6
        cmp #$00
        bne --

        copy #$00, ram20

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

        copy #%00001110, ppu_mask  ; show BG, hide sprites
        copy #%10000000, ppu_ctrl  ; enable NMI
        rts

; --- Set up and animate red and purple gradients -------------------------------------------------

init_gradients
        ; Called by: nmi_gradients
        ; Calls: fill_name_tables, init_palette_copy, update_palette, fill_attribute_tables,
        ;        fill_attribute_tables_top

        ldx #$00              ; clear Name Tables
        jsr fill_name_tables

        jsr init_palette_copy  ; palette_table -> palette_copy
        jsr update_palette     ; palette_copy -> PPU

        lda #%00000000
        sta ppu_ctrl        ; disable NMI
        sta ppu_mask        ; hide BG and sprites

        ldy #$ff
        jsr fill_attribute_tables
        ldy #$55
        jsr fill_attribute_tables_top

        set_ppu_addr vram_palette+3*4  ; update 1st color of 4th BG subpalette
        copy #$0f, ppu_data            ; black
        reset_ppu_addr

        copy #1, part_init_done
        rts

anim_gradients
        ; Called by: nmi_gradients
        ; Calls: change_bg_color

        jsr change_bg_color
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
        sta ram_arr2,x
        inc zp1
        inx
        cpx #128
        bne -

        lda ram20
        cmp #$00
        beq +
        jmp anim_gradients_1

+       ldx #0
        ldy #0
        lda #$00

        sta zp6
--      copy #$21, ppu_addr
        copy zp6,  ppu_addr

        ldy #0
-       lda ram_arr2,x
        sta ppu_data
        lda ram_arr2,x
        sta ppu_data
        lda ram_arr2,x
        sta ppu_data
        lda ram_arr2,x
        sta ppu_data
        inx
        iny
        cpy #8
        bne -

        lda zp6
        add #32
        sta zp6
        lda zp6
        cmp #$00
        bne --

        copy #$01, ram20
        jmp anim_gradients_2

anim_gradients_1
        ldx #$7f
        copy #$20, zp6

--      copy #$22, ppu_addr
        copy zp6,  ppu_addr

        ldy #0
-       lda ram_arr2,x
        sta ppu_data
        lda ram_arr2,x
        sta ppu_data
        lda ram_arr2,x
        sta ppu_data
        lda ram_arr2,x
        sta ppu_data
        dex
        iny
        cpy #8
        bne -

        lda zp6
        add #32
        sta zp6
        lda zp6
        cmp #$00
        bne --

        copy #$00, ram20

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

        copy #%00001110, ppu_mask  ; show BG, hide sprites
        copy #%10000000, ppu_ctrl  ; enable NMI
        rts

; --- Set up and animate non-full-screen horizontal color bars ------------------------------------

init_horzbars1
        ; Called by: nmi_horzbars1
        ; Calls: fill_nt_and_clear_at, jump_snd_eng, init_palette_copy, update_palette,
        ;        hide_sprites

        ldx #$ff
        jsr fill_nt_and_clear_at
        jsr jump_snd_eng
        jsr init_palette_copy     ; palette_table -> palette_copy
        jsr update_palette        ; palette_copy  -> PPU
        copy #1, part_init_done
        jsr hide_sprites

        lda #$00
        sta zp1
        sta zp2
        sta zp3
        sta zp4

        copy #%00000000, ppu_mask  ; hide BG and sprites
        copy #%10000000, ppu_ctrl  ; enable NMI
        rts

anim_horzbars1
        ; Called by: nmi_horzbars1
        ; Calls: delay

        dec zp4
        inc_lda zp3
        cmp #2
        bne +

        copy #$00, zp3
        dec zp2

+       copy #%10000100, ppu_ctrl  ; enable NMI, autoincrement PPU address by 32

        set_ppu_addr_via_x vram_palette+0  ; update 1st color of 1st BG subpalette
        copy #$0f, ppu_data                ; black
        reset_ppu_addr

        ldx #$ff
        jsr delay
        ldx #$01
        jsr delay


        set_ppu_addr_via_x vram_palette+0  ; update 1st color of 1st BG subpalette
        copy #$0f, ppu_data                ; black
        reset_ppu_addr

        copy #$00, zp1

        ldy #85             ; loop
--      ldx #25
-       dex
        bne -
        ;
        set_ppu_addr_via_x vram_palette+0*4
        ldx zp2
        lda curve3,x
        sta zp6
        dec zp1
        lda zp1
        add zp2
        tax
        lda curve2,x
        clc
        sbc zp6
        adc zp4
        tax
        lda some_horzbars_data,x
        sta ppu_data
        dey
        bne --

        reset_ppu_addr

        set_ppu_addr_via_x vram_palette+0  ; update 1st color of 1st BG subpalette
        copy #$0f, ppu_data                ; black
        reset_ppu_addr
        rts

; --- Set up and animate credits ------------------------------------------------------------------

init_credits
        ; Called by: nmi_credits
        ; In: credits_loop_cntr
        ; Out: credits_loop_cntr
        ; Calls: fill_name_tables, init_palette_copy, update_palette, hide_sprites

        ldx #$ff              ; fill Name Tables with #$ff
        jsr fill_name_tables

        jsr init_palette_copy  ; palette_table -> palette_copy
        jsr update_palette     ; palette_copy  -> PPU

        set_ppu_addr vram_palette+7*4  ; update 4th sprite subpalette
        copy #$0f, ppu_data            ; black
        copy #$19, ppu_data            ; medium-dark green
        copy #$33, ppu_data            ; light purple
        copy #$30, ppu_data            ; white
        reset_ppu_addr

        ; write name tables 0 and 2, then clear attribute tables

        set_ppu_addr name_table0+0*32+0

write_name_table
        ; Write 768+160 = 928 bytes (why not 960?) to PPU.

        ; a quadruple loop:
        ;   outermost:     writent_loopcntr2 = 0 to 2;         write 3*8*4*8 = 768 bytes to PPU
        ;   2nd-outermost: writent_loopcntr1 = 0 to 56 step 8; write 8*4*8 = 256 bytes
        ;   2nd-innermost: Y = 0 to 3;                         write 4*8 = 32 bytes
        ;   innermost:     X = 0 to 7;                    write 8 bytes (writent_loopcntr1 + 0...7)
        copy #0, writent_loopcntr1
        copy #0, writent_loopcntr2
---     ldy #0              ; start outermost and 2nd-outermost
--      ldx #0              ; start 2nd-innermost
-       txa                 ; start innermost
        add writent_loopcntr1
        sta ppu_data
        inx
        cpx #8
        bne -               ; end innermost
        ;
        iny
        cpy #4
        bne --              ; end 2nd-innermost
        ;
        lda writent_loopcntr1
        add #8
        sta writent_loopcntr1
        lda writent_loopcntr1
        cmp #64
        bne ---             ; end 2nd-outermost
        ;
        copy #0, writent_loopcntr1
        inc_lda writent_loopcntr2
        cmp #3
        bne ---             ; end outermost

        ; triple loop:
        ;   outermost: writent_loopcntr1 = 0 to 32 step 8; write 5*4*8 = 160 bytes to PPU
        ;   middle:    Y = 0 to 3;                 write 4*8 = 32 bytes
        ;   innermost: X = 0 to 7;                 write 8 bytes (writent_loopcntr1 + 0...7)
        ldx #0
---     ldy #0              ; start outermost
--      ldx #0              ; start middle
-       txa                 ; start innermost
        add writent_loopcntr1
        sta ppu_data
        inx
        cpx #8
        bne -               ; end innermost
        ;
        iny
        cpy #4
        bne --              ; end middle
        ;
        lda writent_loopcntr1
        add #8
        sta writent_loopcntr1
        cmp #40
        bne ---             ; end outermost

        lda #$f0            ; unnecessary

        ; write 8*8 = 64 bytes to PPU ($f0-$f7 eight times; attribute data?)
        ldy #0
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
        inc_lda credits_loop_cntr
        cmp #2
        bne +
        jmp ++
+       set_ppu_addr name_table2+0*32+0
        jmp write_name_table

++      set_ppu_addr attr_table0  ; clear Attribute Table 0
        ldx #0
-       copy #$00, ppu_data
        inx
        cpx #64
        bne -
        reset_ppu_addr

        set_ppu_addr attr_table2  ; clear Attribute Table 2
        ldx #0
-       copy #$00, ppu_data
        inx
        cpx #64
        bne -
        reset_ppu_addr

        jsr hide_sprites

        copy #2, credits_bg_pal  ; pink
        copy #0, loopcntr3
        copy #1, part_init_done
        copy #0, zp1

        copy #%00011000, ppu_ctrl  ; disable NMI, use PT1 for BG and sprites
        copy #%00011110, ppu_mask  ; show BG and sprites
        rts

anim_credits
        ; Called by: nmi_credits
        ; Calls: fade_to_black, update_palette, hide_sprites, update_metasprite_8x2,
        ;        update_metasprite_4x2, update_metasprite_3x2

        copy #>sprite_page, oam_dma  ; do sprite DMA

        lda credits_timer_hi
        cmp #8
        bne anim_credits1
        ;
        lda credits_timer_lo
        cmp #140
        bcc anim_credits1
        ;
        inc_lda loopcntr3
        cmp #4
        bne anim_credits1

        jsr fade_to_black
        jsr update_palette  ; palette_copy -> PPU
        copy #0, loopcntr3

anim_credits1
        copy #id_credits, demo_part

        set_ppu_addr vram_palette+0*4

        lda credits_timer_hi
        cmp #8
        beq anim_credits2

        lda credits_bg_pal
        cmp_beq #0, +++
        cmp_beq #1, ++
        cmp_beq #2, +

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

        inc_lda credits_timer_lo
        cmp #180
        beq +
        jmp ++
+       inc credits_timer_hi
        copy #0, credits_timer_lo

++      lda credits_timer_hi
        cmp_beq #1, credits_jump_table+1*3
        cmp_beq #2, credits_jump_table+2*3
        cmp_beq #3, credits_jump_table+3*3
        cmp_beq #4, credits_jump_table+4*3
        cmp_beq #5, credits_jump_table+5*3
        cmp_beq #6, credits_jump_table+6*3
        cmp_beq #7, credits_jump_table+7*3
        cmp_beq #8, credits_jump_table+8*3
        cmp_beq #9, anim_credits_nextpart

credits_jump_table
        jmp cred_exit1      ; 0
        jmp cred_starring   ; 1
        jmp cred_code1      ; 2
        jmp cred_code2      ; 3
        jmp cred_gfx1       ; 4
        jmp cred_gfx2       ; 5
        jmp cred_gfx3       ; 6
        jmp cred_gfx4       ; 7
        jmp cred_zax        ; 8

anim_credits_nextpart
        copy #id_checkered, demo_part  ; next part
        copy #0, part_init_done
        jmp cred_exit2

macro metasprite_args _x, _y, _tile
        ldx #_x
        ldy #_y
        copy #_tile, zp6
endm

cred_starring
        jsr hide_sprites
        metasprite_args 92, 106, $90  ; "STARRING"
        jsr update_metasprite_8x2
        jmp cred_exit2
cred_code1
        jsr hide_sprites
        metasprite_args 117, 115, $60  ; "VISY"
        jsr update_metasprite_8x2
        metasprite_args 84, 97, $ac    ; "CODE"
        jsr update_metasprite_4x2
        jmp cred_exit2
cred_code2
        jsr hide_sprites
        metasprite_args 117, 115, $80  ; "PAHAMOKA"
        jsr update_metasprite_8x2
        metasprite_args 84, 97, $ac    ; "CODE"
        jsr update_metasprite_4x2
        jmp cred_exit2
cred_gfx1
        jsr hide_sprites
        copy #1, credits_bg_pal        ; yellow
        metasprite_args 117, 115, $50  ; "ZEROIC"
        jsr update_metasprite_8x2
        metasprite_args 84, 97, $a0    ; "GFX"
        jsr update_metasprite_3x2
        jmp cred_exit2
cred_gfx2
        jsr hide_sprites
        metasprite_args 117, 115, $40  ; "Inkoddi"
        jsr update_metasprite_8x2
        metasprite_args 84, 97, $a0    ; "GFX"
        jsr update_metasprite_3x2
        jmp cred_exit2
cred_gfx3
        jsr hide_sprites
        metasprite_args 117, 115, $e0  ; "PROGZMAX"
        jsr update_metasprite_8x2
        metasprite_args 84, 97, $a0    ; "GFX"
        jsr update_metasprite_3x2
        jmp cred_exit2
cred_gfx4
        copy #0, credits_bg_pal        ; blue
        jsr hide_sprites
        metasprite_args 117, 115, $c0  ; "MANGAELF", "SAKAMIES"
        jsr update_metasprite_8x2
        metasprite_args 84, 97, $a0    ; "GFX"
        jsr update_metasprite_3x2
        jmp cred_exit2
cred_zax
        jsr hide_sprites
        metasprite_args 117, 115, $70  ; "ilmarque"
        jsr update_metasprite_8x2
        metasprite_args 84, 97, $a6    ; "ZAX"
        jsr update_metasprite_3x2
        jmp cred_exit2

cred_exit1
        jsr hide_sprites
cred_exit2
        chr_bankswitch 1
        copy #%10011000, ppu_ctrl  ; enable NMI, use PT1 for BG and sprites
        copy #%00011110, ppu_mask  ; show BG and sprites
        rts

; --- Set up and animate woman --------------------------------------------------------------------

init_woman
        ; Called by: nmi_woman
        ; Calls: fill_name_tables, fill_attribute_tables, hide_sprites, jump_snd_eng

        ldx #$7f              ; fill Name Tables with #$7f
        jsr fill_name_tables

        ldy #$00
        jsr fill_attribute_tables
        jsr hide_sprites

        lda #%00000000
        sta ppu_ctrl        ; disable NMI
        sta ppu_mask        ; hide BG and sprites

        copy #$20, ram22
        copy #$21, ram23

        ; write 16 rows to Name Table 0;
        ; the left half consists of tiles $00, $01, ..., $ff;
        ; the right half consists of tile $7f

        set_ppu_addr name_table0


        ldy #0              ; loop
--      ldx #0              ; write Y...Y+15
-       sty ppu_data
        iny
        inx
        cpx #16
        bne -
        ;
        ldx #0              ; write 16 * byte #$7f
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

        ldy #0              ; loop
--      ldx #0              ; 1st inner loop
-       sty ppu_data
        iny
        inx
        cpx #16
        bne -
        ;
        ldx #0              ; 2nd inner loop
-       copy #$7f, ppu_data
        inx
        cpx #16
        bne -
        ;
        cpy #7*32
        bne --

        ; write bytes #$e0-#$e4 to Name Table 0, row 29, columns 10-14
        reset_ppu_addr
        set_ppu_addr name_table0+29*32+10
        copy #$e0, ppu_data
        copy #$e1, ppu_data
        copy #$e2, ppu_data
        copy #$e3, ppu_data
        copy #$e4, ppu_data
        reset_ppu_addr

        ; update 1st BG subpalette and 1st sprite subpalette
        set_ppu_addr vram_palette+0*4
        ldx #0
        copy #$30, ppu_data  ; white
        copy #$25, ppu_data  ; medium-light red
        copy #$17, ppu_data  ; medium-dark orange
        copy #$0f, ppu_data  ; black
        set_ppu_addr vram_palette+4*4+1
        copy #$02, ppu_data  ; dark blue
        copy #$12, ppu_data  ; medium-dark blue
        copy #$22, ppu_data  ; medium-light blue
        reset_ppu_addr

        lda #0              ; reset H/V scroll
        sta ppu_scroll
        sta ppu_scroll

        lda #$00
        sta zp1
        sta zp2
        copy #$40, zp3
        copy #$00, zp4
        copy #1, part_init_done
        copy #0, loopcntr3

        copy #%10000000, ppu_ctrl  ; enable NMI
        rts

anim_woman
        ; Called by: nmi_woman
        ; Calls: delay

        copy #>sprite_page, oam_dma  ; do sprite DMA

        inc zp2
        inc zp3
        ldx #24
        ldy #0
        lda #$00
        sta zp6
        sta zp1
        lda zp3

        ; loop
-       txa                 ; update sprite at offset Y
        sta sprite_page+0,y
        lda #$f0
        add zp4
        sta sprite_page+1,y
        lda ram22
        sta sprite_page+2,y
        ;
        txa                 ; store X
        pha
        ;
        inc zp1
        inc zp1
        inc zp1
        ;
        lda zp1             ; [sprite_x_or_y+zp1+zp2] + 194 -> sprite X pos
        add zp2
        tax
        lda sprite_x_or_y,x
        add #194
        sta sprite_page+3,y
        ;
        pla                 ; restore X
        tax
        ;
        iny4
        txa
        add #8
        tax
        inc zp5
        ;
        lda zp5             ; if zp5 = 15 then clear it and increment zp4
        cmp #15
        beq +
        jmp ++
        ;
+       inc zp4
        copy #0, zp5

++      lda zp4             ; if zp4 = 16 then clear it
        cmp #16
        beq +
        jmp ++
        ;
+       copy #0, zp4

++      cpy #96             ; loop until Y = 96
        bne -

        ldx #24
        lda #$00
        sta zp6
        sta zp1
        dec zp4

        ; loop
-       txa                 ; update sprite at offset Y
        sta sprite_page+0,y
        lda #$f0
        add zp4
        sta sprite_page+1,y
        lda ram23
        sta sprite_page+2,y
        ;
        txa                 ; store X
        pha
        ;
        dec zp1
        dec zp1
        ;
        lda zp1             ; [sprite_x_or_y+zp1+zp3] + 194 -> sprite X pos
        add zp3
        tax
        lda sprite_x_or_y,x
        add #194
        sta sprite_page+3,y
        ;
        pla                 ; restore X
        tax
        ;
        iny4
        txa
        add #8
        tax
        inc zp4
        ;
        lda zp4             ; if zp4 = 16 then clear it
        cmp #16
        beq +
        jmp ++
        ;
+       copy #0, zp4
++      cpy #192            ; loop until Y = 192
        bne -

        chr_bankswitch 3

        copy #%10001000, ppu_ctrl  ; enable NMI, use PT1 for sprites

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

        copy #%10011000, ppu_ctrl  ; enable NMI, use PT1 for BG and sprites
        copy #%00011110, ppu_mask  ; show BG and sprites

        lda zp3
        cmp #$fa
        bne ++

        inc_lda ram21
        cmp #$02
        beq +

        copy #$00, ram22
        copy #$01, ram23
        jmp ++

+       copy #$20, ram22
        copy #$21, ram23
        copy #$00, ram21
++      rts

; --- Ninja part (unused) -------------------------------------------------------------------------

        ; Shows big eyes of a ninja at the top, a ninja walking right at the middle and credits
        ; scrolling at the bottom.
        ; How to see this part (although glitched):
        ; - replace "jsr init_title" with "jsr init_ninja"
        ; - replace "jsr anim_title" with "jsr anim_ninja"

init_ninja  ; $ec99
        ldx #$7a
        jsr fill_name_tables

        ldy #$00
        jsr fill_attribute_tables
        jsr init_palette_copy  ; palette_table -> palette_copy
        jsr update_palette     ; palette_copy  -> PPU
        jsr hide_sprites

        lda #%00000000
        sta ppu_ctrl        ; disable NMI
        sta ppu_mask        ; hide BG and sprites

        set_ppu_addr name_table0+8*32+10

        ldx #$50
        ldy #0
-       stx ppu_data
        inx
        iny
        cpy #12
        bne -

        reset_ppu_addr

        set_ppu_addr name_table0+9*32+10

        ldy #0
        ldx #$5c
-       stx ppu_data
        inx
        iny
        cpy #12
        bne -

        reset_ppu_addr

        set_ppu_addr name_table0+10*32+10

        ldy #0
        ldx #$68
-       stx ppu_data
        inx
        iny
        cpy #12
        bne -

        reset_ppu_addr

        copy #1, part_init_done
        lda #$00
        sta text_offset
        sta zp1
        copy #$00, zp2

        set_ppu_addr vram_palette+6*4+2
        copy #$00, ppu_data
        copy #$10, ppu_data
        reset_ppu_addr

        copy #%10000000, ppu_ctrl  ; enable NMI
        copy #%00011110, ppu_mask  ; show BG and sprites

        copy #$00, ram8
        rts

anim_ninja                  ; $ed4b
        lda ram8
        cmp #$01
        beq +

        set_ppu_addr vram_palette+4*4
        copy #$0f, ppu_data
        copy #$0f, ppu_data
        copy #$0f, ppu_data
        copy #$0f, ppu_data
        reset_ppu_addr

        set_ppu_addr vram_palette+0*4
        copy #$0f, ppu_data
        copy #$30, ppu_data
        copy #$10, ppu_data
        copy #$00, ppu_data
        reset_ppu_addr

+       copy #$01, ram8
        copy #%00011110, ppu_mask  ; show BG and sprites
        copy #%00010000, ppu_ctrl  ; disable NMI, use PT1 for BG

        inc_lda zp2
        cmp #8
        beq +
        jmp +++
+       copy #$00, zp2
        inc_lda text_offset
        cmp #235
        beq +
        jmp ++
        ;
+       copy #0, part_init_done
        copy #id_cola, demo_part
++      set_ppu_addr name_table0+27*32+1

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

        copy #%00010000, ppu_ctrl  ; disable NMI, use PT1 for BG
        copy #%00011110, ppu_mask  ; show BG and sprites

        copy #>sprite_page, oam_dma  ; do sprite DMA

        ldx #$ff
        jsr delay
        jsr delay
        jsr delay
        ldx #$1e
        jsr delay
        ldx #$d0
        jsr delay

        copy #%00000000, ppu_ctrl  ; disable NMI

        chr_bankswitch 0

        copy zp2, ppu_scroll
        copy #0,  ppu_scroll

        copy #215,       sprite_page+0*4+0  ; edit sprite #0
        copy #$25,       sprite_page+0*4+1
        copy #%00000000, sprite_page+0*4+2
        copy #248,       sprite_page+0*4+3

        copy #207,       sprite_page+1*4+0  ; edit sprite #1
        copy #$25,       sprite_page+1*4+1
        copy #%00000000, sprite_page+1*4+2
        copy #248,       sprite_page+1*4+3

        copy #223,       sprite_page+2*4+0  ; edit sprite #2
        copy #$27,       sprite_page+2*4+1
        copy #%00000000, sprite_page+2*4+2
        copy #248,       sprite_page+2*4+3

        ; edit sprites
        ldx ninja_sprite_count_minus_one  ; 11
-       txa
        asl
        asl
        tay
        ;
        lda ninja_sprites_y,x
        add #$9b
        sta sprite_page+23*4+0,y
        ;
        txa
        pha
        ldx ram9
        lda ninja_sprites_tile_add,x
        sta zp6
        pla
        ;
        tax
        lda ninja_sprites_tile,x
        add zp6
        sta sprite_page+23*4+1,y
        ;
        lda #%00000010
        sta sprite_page+23*4+2,y
        ;
        lda ninja_sprites_x,x
        add ram14
        sta sprite_page+23*4+3,y
        ;
        cpx #0
        beq +
        dex
        jmp -

+       inc_lda ram15
        cmp #$06
        bne +
        inc ram14
        inc ram14
        copy #$00, ram15
+       inc_lda ram10
        cmp #$0c
        bne +
        copy #$00, ram10
        inc_lda ram9
        cmp #$04
        bne +
        copy #$00, ram9

+       copy #%10001000, ppu_ctrl  ; enable NMI, use PT1 for sprites
        copy #%00011000, ppu_mask  ; show BG and sprites (neither in the leftmost column)
        rts

; --- Set up and animate Bowser's spaceship -------------------------------------------------------

init_bowser
        ; Called by: nmi_bowser
        ; Calls: hide_sprites, fill_attribute_tables

        jsr hide_sprites

        ldy #$aa
        jsr fill_attribute_tables

        ; write the crescent moon to NT0 (lines 8-15, columns 26-28, tiles $60-$77)
        copy #$1a, zp6      ; row start address low ($1a, $3a, ..., $fa)
        ldx #$60            ; tile
--      copy #$21, ppu_addr
        copy zp6,  ppu_addr
        ;
        ldy #0
-       stx ppu_data
        inx
        iny
        cpy #3
        bne -
        ;
        reset_ppu_addr
        lda zp6
        add #$20
        sta zp6
        lda zp6
        cmp #$1a
        bne --

        ; write blank tiles to NT0 (lines 16-18, columns 8-10, tiles $80-$88)
        copy #$08, zp6      ; row start address low ($08, $28, $48)
        ldx #$80            ; tile (replace with #$57 to make small crescent moon reappear)
--      copy #$22, ppu_addr
        copy zp6,  ppu_addr
        ;
        ldy #0
-       stx ppu_data
        inx
        iny
        cpy #3
        bne -
        ;
        reset_ppu_addr
        lda zp6
        add #$20
        sta zp6
        lda zp6
        cmp #$68
        bne --

        ; update all sprite subpalettes
        set_ppu_addr vram_palette+4*4
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

        ; update 1st BG subpalette
        set_ppu_addr vram_palette+0*4
        copy #$0f, ppu_data  ; black
        copy #$20, ppu_data  ; white
        copy #$10, ppu_data  ; light gray
        copy #$00, ppu_data  ; dark gray
        reset_ppu_addr

        ; init sprite array and some other array
        ldx bowser_sprite_count1_minus_one  ; 3
-       lda some_bowser_table1,x
        sta bowser_some_arr1,x
        lda bowser_sprites_tile1,x
        sta bowser_tile_arr,x
        dex
        cpx #255
        bne -

        ; init X and Y arrays
        ldx bowser_sprite_count3_minus_one  ; 3
-       lda #$00
        sta bowser_x_arr,x
        lda #$f0
        sta bowser_y_arr,x
        dex
        cpx #$ff
        bne -

        ; set up sprites (#48-#63) and some RAM array
        ldx bowser_and_friday_sprite_count_minus_one  ; 15
-       txa
        asl
        asl
        tay
        ;
        lda bowser_sprites_y2,x
        sta sprite_page+48*4+0,y
        lda bowser_sprites_tile4,x
        sta sprite_page+48*4+1,y
        lda bowser_sprites_x2,x
        sta sprite_page+48*4+3,y
        lda bowser_sprites_xsub,x
        sta ram_arr1,x
        ;
        dex
        cpx #255
        bne -

        copy #$7a, ram5
        copy #$0a, ram4

        ; loop - edit sprites #1-#17
        ldx bowser_sprite_count2_minus_one  ; 16
-       txa
        asl
        asl
        tay
        ;
        lda bowser_sprites_tile2,x
        sta sprite_page+1*4+1,y
        lda bowser_sprites_attr,x
        sta sprite_page+1*4+2,y
        ;
        cpx #0
        beq +
        dex
        jmp -

+       lda #$00
        sta ram1
        sta ram2
        sta ram3
        copy #1, part_init_done
        copy #%10000000, ppu_ctrl  ; enable NMI
        copy #%00010010, ppu_mask  ; hide BG, show sprites (not in the leftmost column)
        rts

anim_bowser
        ; Called by: nmi_bowser
        ; Calls: nothing

        copy #>sprite_page, oam_dma  ; do sprite DMA

        inc ram1
        ldx ram1
        lda curve1,x
        adc #$7a
        sta ram5
        lda curve2,x
        adc #15
        sta ram4
        chr_bankswitch 2

        ; loop
        ldx bowser_sprite_count1_minus_one  ; 3
-       dec bowser_some_arr1,x
        lda bowser_some_arr1,x
        cmp #$00
        bne +++
        lda bowser_tile_arr,x
        cmp some_bowser_table2,x
        beq +
        inc bowser_tile_arr,x
        jmp ++
+       lda bowser_sprites_tile1,x
        sta bowser_tile_arr,x
++      lda some_bowser_table1,x
        sta bowser_some_arr1,x
+++     dex
        cpx #255
        bne -

        ; edit tiles of four sprites
        copy bowser_tile_arr+0, sprite_page+ 1*4+1
        copy bowser_tile_arr+1, sprite_page+16*4+1
        copy bowser_tile_arr+2, sprite_page+17*4+1
        copy bowser_tile_arr+3, sprite_page+13*4+1

        ; loop - edit positions of sprites #1-#17
        ldx bowser_sprite_count2_minus_one  ; 16
-       txa
        asl
        asl
        tay
        ;
        lda bowser_sprites_y1,x
        add ram5
        sta sprite_page+1*4+0,y
        lda bowser_sprites_x1,x
        add ram4
        sta sprite_page+1*4+3,y
        ;
        cpx #0
        beq +
        dex
        jmp -

+       lda ram1
        ldx ram2
        cmp some_bowser_table3,x
        bne ++

        inc_lda ram2
        cpx some_bowser_data2
        bne +               ; always taken

        copy #$00, ram2     ; unaccessed ($f111)

+       ldx ram3
        ldy ram1
        lda #$ff
        sta bowser_x_arr,x
        lda curve1,y
        add #$5a
        sta bowser_y_arr,x
        lda curve3,y
        sta bowser_some_arr2,x
        inc ram3
        cpx bowser_sprite_count3_minus_one  ; 3
        bne ++
        copy #$00, ram3

        ; loop
++      ldx bowser_sprite_count3_minus_one  ; 3
-       lda bowser_y_arr,x
        cmp #$f0
        beq ++
        lda bowser_x_arr,x
        clc
        sbc bowser_some_arr2,x
        bcc +
        sta bowser_x_arr,x
        jmp ++
+       lda #$f0
        sta bowser_y_arr,x
++      dex
        cpx #255
        bne -

        ; loop - edit sprites #18-#21
        ldx bowser_sprite_count3_minus_one  ; 3
-       txa
        asl
        asl
        tay
        ;
        lda bowser_y_arr,x
        sta sprite_page+18*4+0,y
        lda bowser_sprites_tile3,x
        sta sprite_page+18*4+1,y
        lda #$2b
        sta sprite_page+18*4+2,y
        lda bowser_x_arr,x
        sta sprite_page+18*4+3,y
        ;
        dex
        cpx #255
        bne -

        ; loop
        ldx bowser_and_friday_sprite_count_minus_one  ; 15
-       txa
        asl
        asl
        tay
        ;
        lda sprite_page+48*4+3,y
        clc
        sbc bowser_sprites_xsub,x
        sta sprite_page+48*4+3,y
        ;
        dex
        cpx #255
        bne -

        copy #%10000000, ppu_ctrl  ; enable NMI
        copy #%00011010, ppu_mask  ; show BG and sprites (no sprites in leftmost column)

        copy #0,  ppu_scroll
        copy #50, ppu_scroll
        rts

; --- Set up and "animate" "game over" part -------------------------------------------------------

init_gameover
        ; Called by: nmi_gameover
        ; Calls: fill_name_tables, fill_attribute_tables, init_palette_copy, update_palette

        ; clear name & attribute tables
        ldx #$4a            ; space
        jsr fill_name_tables
        ldy #$00
        jsr fill_attribute_tables

        jsr init_palette_copy  ; palette_table -> palette_copy
        jsr update_palette     ; palette_copy  -> PPU

        ; copy 96 (32*3) bytes of text to rows 14-16 of NT0; subtract 17 from each byte
        set_ppu_addr name_table0+14*32
        ldx #0
-       lda gameover_text,x
        clc
        sbc #16
        sta ppu_data
        inx
        cpx #96
        bne -

        copy #%00000010, ppu_ctrl  ; disable NMI, use NT2
        copy #%00000000, ppu_mask  ; hide BG and sprites
        rts

anim_gameover
        ; Called by: nmi_gameover
        ; Calls: nothing

        copy #0, ppu_scroll
        copy #0, ppu_scroll
        copy #%10010000, ppu_ctrl  ; enable NMI, use PT1 for BG
        copy #%00001110, ppu_mask  ; show BG, hide sprites
        rts

; --- Set up and animate "GREETS" part ------------------------------------------------------------

init_greets
        ; Called by: nmi_greets
        ; Calls: fill_name_tables, fill_attribute_tables, clear_palette_copy, update_palette

        ; clear name&attribute tables
        ldx #$4a            ; space
        jsr fill_name_tables
        ldy #$00
        jsr fill_attribute_tables

        jsr clear_palette_copy  ; black -> palette_copy
        jsr update_palette      ; palette_copy -> PPU

        copy #%00000010, ppu_ctrl  ; disable NMI, use NT2
        copy #%00000000, ppu_mask  ; hide BG and sprites

        ; Write the heading "GREETS TO ALL NINTENDAWGS:" (16*3 tiles, tiles $00-$2f)
        ; to rows 3-5, columns 9-24 of Name Table 0.
        ;
        copy #0, zp6        ; outer loop counter, VRAM address offset
        ldx #0              ; tile number
        ;
--      copy #>(name_table0+3*32+9), ppu_addr
        lda zp6
        add #<(name_table0+3*32+9)
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
        lda zp6             ; manage loop counter
        add #32
        sta zp6
        cmp #(3*32)
        bne --

        ; copy the main text (32*20 = 256+256+128 tiles) to rows 8-27 of NT0;
        ; subtract 17 from each byte
        ;
        set_ppu_addr name_table0+8*32
        ;
        ldx #0
-       lda greets_text+0,x
        clc
        sbc #16
        sta ppu_data
        inx
        bne -
        ;
        ldx #0
-       lda greets_text+256,x
        clc
        sbc #16
        sta ppu_data
        inx
        bne -
        ;
        ldx #0
-       lda greets_text+2*256,x
        clc
        sbc #16
        sta ppu_data
        inx
        cpx #128
        bne -

        reset_ppu_addr

        copy #1, part_init_done
        copy #$e6, ram26
        rts

anim_greets
        ; Called by: nmi_greets
        ; Calls: init_palette_copy, update_palette, fade_to_black

        chr_bankswitch 2

        lda greets_timer_hi
        cmp #0
        bne +
        lda greets_timer_lo
        cmp #3
        bne +

        jsr init_palette_copy  ; palette_table -> palette_copy
        jsr update_palette     ; palette_copy  -> PPU

        ; update 1st BG subpalette
        set_ppu_addr vram_palette+0*4
        copy #$0f, ppu_data  ; black
        copy #$30, ppu_data  ; white
        copy #$1a, ppu_data  ; medium-dark green
        copy #$09, ppu_data  ; dark green
        reset_ppu_addr

+       copy #0, ppu_scroll
        ldx ram26
        lda curve1,x
        add ram26
        sta ppu_scroll

        lda ram26
        cmp #0
        beq +
        dec ram26
        ;
+       lda greets_timer_hi
        cmp #3
        bne +
        lda greets_timer_lo
        cmp #0
        bcc +
        ;
        inc_lda loopcntr3
        cmp #4
        bne +

        jsr fade_to_black
        jsr update_palette  ; palette_copy -> PPU
        copy #0, loopcntr3

+       copy #id_greets, demo_part
        copy #%10010000, ppu_ctrl  ; enable NMI, use PT1 for BG
        copy #%00001110, ppu_mask  ; show BG, hide sprites
        rts

; --- Set up and animate Coca Cola cans -----------------------------------------------------------

init_cola
        ; Called by: nmi_cola
        ; Calls: fill_name_tables, hide_sprites, fill_attribute_tables

        ; fill name tables with #$80, clear attribute tables, hide sprites
        ldx #$80
        jsr fill_name_tables
        jsr hide_sprites
        ldy #$00
        jsr fill_attribute_tables

        lda #%00000000
        sta ppu_ctrl        ; disable NMI
        sta ppu_mask        ; hide BG and sprites

        lda #$00
        sta zp1
        sta zp2
        sta zp3

        ; update 1st BG subpalette
        set_ppu_addr vram_palette+0*4
        copy #$05, ppu_data  ; dark red
        copy #$25, ppu_data  ; medium-light red
        copy #$15, ppu_data  ; medium-dark red
        copy #$30, ppu_data  ; white
        reset_ppu_addr

        copy #$c8, ram18

        copy #0,   ppu_scroll
        copy #200, ppu_scroll

        copy #$00, ram24
        copy #1, part_init_done
        copy #%10000000, ppu_ctrl  ; enable NMI
        rts

anim_cola
        ; Called by: nmi_cola
        ; Calls: delay

        lda ram17
        cmp #$02
        beq +
        jmp anim_cola_1
+       ldy #$80

        ; loop
--      copy #>(name_table0+8*32+4), ppu_addr
        lda #<(name_table0+8*32+4)
        add ram16
        sta ppu_addr
        ;
        ldx #0
-       sty ppu_data
        iny
        inx
        cpx #8
        bne -
        ;
        lda ram16
        add #32
        sta ram16
        cpy #$c0
        bne --

        ; loop
--      copy #>(name_table0+16*32+4), ppu_addr
        lda #<(name_table0+16*32+4)
        add ram16
        sta ppu_addr
        ;
        ldx #0
-       sty ppu_data
        iny
        inx
        cpx #8
        bne -
        ;
        lda ram16
        add #32
        sta ram16
        cpy #$00
        bne --

        reset_ppu_addr
        copy #$00, ram16

        ; loop
--      copy #>(name_table0+8*32+20), ppu_addr
        lda #<(name_table0+8*32+20)
        add ram16
        sta ppu_addr
        ;
        ldx #0
-       sty ppu_data
        iny
        inx
        cpx #8
        bne -
        ;
        lda ram16
        add #32
        sta ram16
        cpy #$c0
        bne --

        ; loop
--      copy #>(name_table0+16*32+20), ppu_addr
        lda #<(name_table0+16*32+20)
        add ram16
        sta ppu_addr
        ;
        ldx #0
-       sty ppu_data
        iny
        inx
        cpx #8
        bne -
        ;
        lda ram16
        add #32
        sta ram16
        cpy #0
        bne --

        reset_ppu_addr

anim_cola_1
        lda ram17
        cmp #$a0
        bcc +
        jmp anim_cola_2

+       copy #0, ppu_scroll
        lda ram18
        clc
        sbc ram17
        sta ppu_scroll

anim_cola_2
        lda zp0
        chr_bankswitch 2
        copy #$00, zp1
        lda ram19
        cmp #$01
        beq anim_cola_3
        inc_lda ram17
        cmp #$c8
        beq +
        jmp anim_cola_3
+       copy #$01, ram19

anim_cola_3
        ldx #$00
        ldy #$00
        lda ram19
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
        sta zp6
        lda zp6
        adc #$28
        sta zp7
        lda zp1
        cmp zp6
        bcc +
        bcs ++
+       copy #%00001110, ppu_mask  ; show BG, hide sprites
        jmp +++
++      lda zp1
        cmp zp7
        bcs +
        copy #%11101110, ppu_mask  ; darken all colors, show BG, hide sprites
+++     jmp ++
+       copy #%00001110, ppu_mask  ; show BG, hide sprites
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
        sta zp7
        inc zp1
        iny
        cpy #$91
        bne -

anim_cola_5
        copy #%10010000, ppu_ctrl  ; enable NMI, use PT1 for BG
        copy #%00001110, ppu_mask  ; show BG, hide sprites
        rts

; --- Set up and animate the "IT IS FRIDAY..." part -----------------------------------------------

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

        ldy #0              ; unaccessed block ($f4f9)
-       stx ppu_data
        iny
        cpy #32
        bne -
        rts

init_friday
        ; Called by: nmi_friday
        ; Calls: fill_nt_and_clear_at, hide_sprites, write_row

        ldx #$25
        jsr fill_nt_and_clear_at
        jsr hide_sprites

        lda #%00000000
        sta ppu_ctrl        ; disable NMI
        sta ppu_mask        ; hide BG and sprites

        ; write 24 rows of tiles to the start of Name Table 0
        set_ppu_addr name_table0
rept 15
        ldx #$25
        jsr write_row
endr
        ldx #$39
        jsr write_row
rept 7
        ldx #$37
        jsr write_row
endr
        ldx #$38
        jsr write_row

        reset_ppu_addr

        ; update 1st BG subpalette
        set_ppu_addr vram_palette+0*4
        copy friday_bg_palette+0, ppu_data
        copy friday_bg_palette+1, ppu_data
        copy friday_bg_palette+2, ppu_data
        copy friday_bg_palette+3, ppu_data
        reset_ppu_addr

        ; update 1st sprite subpalette
        set_ppu_addr vram_palette+4*4
        copy friday_spr_palette+0, ppu_data
        copy friday_spr_palette+1, ppu_data
        copy friday_spr_palette+2, ppu_data
        copy friday_spr_palette+3, ppu_data
        reset_ppu_addr

        ; loop - edit sprites #48-#63
        ldx bowser_and_friday_sprite_count_minus_one  ; 15
-       txa
        asl
        asl
        tay
        ;
        lda friday_sprites_y,x
        sta sprite_page+48*4+0,y
        lda friday_sprites_tile,x
        sta sprite_page+48*4+1,y
        lda #%00000010
        sta sprite_page+48*4+2,y
        lda friday_sprites_x,x
        sta sprite_page+48*4+3,y
        ;
        lda friday_sprites_xadd,x
        sta ram_arr1,x
        dex
        cpx #255
        bne -

        copy #$00, ram1
        copy #1, part_init_done
        lda #$00
        sta zp1
        sta zp2
        copy #$00, text_offset
        rts

macro edit_sprite_macro _index, _y, _x
        lda #_y
        clc
        sbc zp6
        sta sprite_page+_index*4+0
        copy #$25,       sprite_page+_index*4+1
        copy #%00000000, sprite_page+_index*4+2
        copy #_x,        sprite_page+_index*4+3
endm

anim_friday
        ; Called by: nmi_friday
        ; Calls: nothing

        inc ram1
        ldx ram1
        lda sprite_x_or_y,x
        sta zp6
        lda curve3,x
        sta zp7

        copy #>sprite_page, oam_dma  ; do sprite DMA

        ; loop - edit positions of sprites #48-#55
        ldx bowser_and_friday_sprite_count_minus_one  ; 15
-       txa
        asl
        asl
        tay
        ;
        lda friday_sprites_y,x
        add zp6
        sta sprite_page+48*4+0,y
        lda sprite_page+48*4+3,y
        clc
        adc friday_sprites_xadd,x
        sta sprite_page+48*4+3,y
        ;
        dex
        cpx #7
        bne -

        ; loop - edit positions of sprites #56-#63
-       txa
        asl
        asl
        tay
        ;
        lda friday_sprites_y,x
        add zp7
        sta sprite_page+48*4+0,y
        lda sprite_page+48*4+3,y
        clc
        adc friday_sprites_xadd,x
        sta sprite_page+48*4+3,y
        ;
        dex
        cpx #255
        bne -

        chr_bankswitch 0
        inc_lda zp2
        cmp #$08
        beq +
        jmp anim_friday_2
        ;
+       copy #$00, zp2
        inc_lda text_offset
        cmp #235
        beq +
        jmp anim_friday_1
        ;
+       copy #0, part_init_done
        copy #id_cola, demo_part  ; next part

anim_friday_1
        ; copy 31 bytes from friday_text+text_offset to NT0 Y pos 19, X pos 1

        set_ppu_addr name_table0+19*32+1

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
        sta zp6

        edit_sprite_macro 0, 148, 248
        edit_sprite_macro 1, 152, 248
        edit_sprite_macro 2, 156, 248
        edit_sprite_macro 3, 148, 0
        edit_sprite_macro 4, 152, 0
        edit_sprite_macro 5, 156, 0

        copy #%10000000, ppu_ctrl  ; enable NMI
        copy #%00011110, ppu_mask  ; show BG and sprites
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
        dex
        bne -

        set_ppu_addr attr_table2

        ldx #64
-       sty ppu_data
        dex
        bne -

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
        dex
        bne -

        set_ppu_addr attr_table2

        ldx #32
-       sty ppu_data
        dex
        bne -

        reset_ppu_addr
        rts

; --- Unaccessed block ($f7d0) --------------------------------------------------------------------

        set_ppu_addr attr_table0+4*8
        ldx #32
-       sty ppu_data
        dex
        bne -
        set_ppu_addr attr_table2+4*8
        ldx #32
-       sty ppu_data
        dex
        bne -
        reset_ppu_addr
        rts

; -------------------------------------------------------------------------------------------------

fill_name_tables
        ; Fill Name Tables 0 and 2 with byte X.
        ; Called by: init_title, init_checkered, init_gradients, init_credits, init_woman
        ;            init_gameover, init_greets, init_cola
        ; Calls: nothing

        stx vram_fill_byte
        ldy #0
        copy #$3c, zp6

        lda #%00000000
        sta ppu_ctrl        ; disable NMI
        sta ppu_mask        ; hide sprites and BG

        ; fill Name Tables with specified byte

        set_ppu_addr name_table0

        ldx #0
        ldy #0
-       lda vram_fill_byte
        sta ppu_data
        sta ppu_data
        sta ppu_data
        sta ppu_data
        inx
        bne -

        set_ppu_addr name_table2

        ldx #0
        ldy #0
-       lda vram_fill_byte
        sta ppu_data
        sta ppu_data
        sta ppu_data
        sta ppu_data
        inx
        bne -

        copy #1, part_init_done
        reset_ppu_addr
        rts

; -------------------------------------------------------------------------------------------------

macro clear_at _addr
        ; write $00 to PPU 64 times, starting from _addr
        set_ppu_addr _addr
        ldx #0
-       copy #$00, ppu_data
        inx
        cpx #64
        bne -
endm

macro fill_nt _addr
        ; write vram_fill_byte to PPU 960 times, starting from _addr
        set_ppu_addr _addr
        ldx #0
        ldy #0
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
        copy #$3c, zp6

        lda #%00000000
        sta ppu_ctrl          ; disable NMI
        sta ppu_mask          ; hide BG and sprites

        clear_at attr_table0  ; clear attribute tables
        clear_at attr_table1

        fill_nt name_table0   ; fill name tables with vram_fill_byte
        fill_nt name_table1
        fill_nt name_table2

        copy #1, part_init_done
        copy #114, vscroll
        reset_ppu_addr

        ; reset H/V scroll
        lda #0
        sta ppu_scroll
        sta ppu_scroll

        copy #%00000000, ppu_ctrl  ; disable NMI
        copy #%00011110, ppu_mask  ; show BG and sprites
        rts

; -------------------------------------------------------------------------------------------------

nmi     ; Non-maskable interrupt routine. Run code for the part of the demo we're in.
        ; Called by: NMI vector
        ; Calls: (see jump table)

        lda ppu_status      ; clear VBlank flag

        lda demo_part
        cmp_beq #id_wecome,    nmi_jump_table+ 1*3
        cmp_beq #id_horzbars1, nmi_jump_table+ 2*3
        cmp_beq #id_title,     nmi_jump_table+ 3*3
        cmp_beq #id_credits,   nmi_jump_table+ 4*3
        cmp_beq #id_woman,     nmi_jump_table+ 5*3
        cmp_beq #id_friday,    nmi_jump_table+ 6*3
        cmp_beq #id_bowser,    nmi_jump_table+ 7*3
        cmp_beq #id_cola,      nmi_jump_table+ 8*3
        cmp_beq #id_horzbars2, nmi_jump_table+ 9*3
        cmp_beq #id_checkered, nmi_jump_table+10*3
        cmp_beq #id_gradients, nmi_jump_table+11*3
        cmp_beq #id_greets,    nmi_jump_table+12*3
        cmp_beq #id_gameover,  nmi_jump_table+13*3

nmi_jump_table
        jmp nmi_exit        ;  0 (unaccessed, $f980)
        jmp nmi_wecome      ;  1
        jmp nmi_horzbars1   ;  2
        jmp nmi_title       ;  3
        jmp nmi_credits     ;  4
        jmp nmi_woman       ;  5
        jmp nmi_friday      ;  6
        jmp nmi_bowser      ;  7
        jmp nmi_cola        ;  8
        jmp nmi_horzbars2   ;  9
        jmp nmi_checkered   ; 10
        jmp nmi_gradients   ; 11
        jmp nmi_greets      ; 12
        jmp nmi_gameover    ; 13

nmi_wecome
        ; Demo part: "GREETINGS! WE COME FROM..."
        ; Called by: nmi
        ; Calls: anim_wecome, jump_snd_eng

        lda part_init_done  ; set flag on first run
        cmp #0
        beq +
        jmp ++
+       copy #1, part_init_done

++      jsr anim_wecome
        jsr jump_snd_eng
        inc unused1
        inc unused1
        inc wecome_timer_lo
        inc wecome_timer_lo
        lda wecome_timer_lo
        cmp #230
        beq +
        jmp ++

+       inc wecome_timer_hi
        copy #0, wecome_timer_lo
++      jmp nmi_exit        ; RTI

nmi_horzbars1
        ; Demo part: non-full-screen horizontal color bars (after the red and purple gradients).
        ; Called by: nmi
        ; Calls: init_horzbars1, anim_horzbars1, jump_snd_eng

        lda part_init_done  ; initialize on first run
        cmp #0
        beq +
        jmp ++
+       jsr init_horzbars1

++      jsr anim_horzbars1
        jsr jump_snd_eng
        inc_lda horzbars1_timer_lo
        cmp #255
        beq +
        jmp ++
+       inc_lda horzbars1_timer_hi
        cmp #3
        beq +
        jmp ++

+       copy #id_woman, demo_part  ; next part
        copy #0, part_init_done
++      jmp nmi_exit        ; RTI

nmi_title
        ; Demo part: title screen ("wAMMA - QUANTUM DISCO BROTHERS").
        ; Called by: nmi
        ; Calls: init_title, anim_title, jump_snd_eng

        lda part_init_done  ; initialize on first run
        cmp #0
        beq +
        jmp ++
+       jsr init_title

++      jsr anim_title
        jsr jump_snd_eng
        inc_lda title_timer_lo
        cmp #255
        beq +
        jmp ++
+       inc_lda title_timer_hi
        cmp #3
        beq +
        jmp ++

+       copy #id_gradients, demo_part  ; next part
        copy #0, part_init_done
++      jmp nmi_exit        ; RTI

nmi_credits
        ; Demo part: credits.
        ; Called by: nmi
        ; Calls: init_credits, anim_credits, jump_snd_eng

        lda part_init_done  ; initialize on first run
        cmp #0
        beq +
        jmp ++
+       jsr init_credits

++      jsr anim_credits
        jsr jump_snd_eng
        jmp nmi_exit        ; RTI

nmi_woman
        ; Demo part: the woman.
        ; Called by: nmi
        ; Calls: init_woman, anim_woman, jump_snd_eng

        lda part_init_done  ; initialize on first run
        cmp #0
        beq +
        jmp ++
+       jsr init_woman

++      jsr anim_woman
        jsr jump_snd_eng
        inc_lda woman_timer_lo
        cmp #255
        beq +
        jmp ++
+       inc_lda woman_timer_hi
        cmp #4
        beq +
        jmp ++

+       copy #id_friday, demo_part  ; next part
        copy #0, part_init_done
++      jmp nmi_exit        ; RTI

nmi_friday
        ; Demo part: "IT IS FRIDAY..."
        ; Called by: nmi
        ; Calls: init_friday, anim_friday, jump_snd_eng

        lda part_init_done  ; initialize on first run
        cmp #0
        beq +
        jmp ++
+       jsr init_friday

++      jsr anim_friday
        jsr jump_snd_eng
        jmp nmi_exit        ; RTI

nmi_bowser
        ; Demo part: Bowser's spaceship.
        ; Called by: nmi
        ; Calls: init_bowser, anim_bowser, jump_snd_eng

        lda part_init_done  ; initialize on first run
        cmp #0
        beq +
        jmp ++
+       jsr init_bowser

++      jsr anim_bowser
        jsr jump_snd_eng
        inc_lda bowser_timer_lo
        cmp #255
        beq +
        jmp ++
+       inc_lda bowser_timer_hi
        cmp #3
        beq +
        jmp ++

+       copy #id_credits, demo_part  ; next part
        copy #0, part_init_done
++      jmp nmi_exit        ; RTI

nmi_cola
        ; Demo part: Coca Cola cans.
        ; Called by: nmi
        ; Calls: init_cola, anim_cola, jump_snd_eng

        lda part_init_done  ; initialize on first run
        cmp #0
        beq +
        jmp ++
+       jsr init_cola

++      jsr anim_cola
        jsr jump_snd_eng
        inc_lda cola_timer_lo
        cmp #255
        beq +
        jmp ++
+       inc cola_timer_hi
++      lda cola_timer_hi
        cmp #3
        bne ++
        lda cola_timer_lo
        cmp #174
        bne ++

        copy #id_bowser, demo_part  ; next part
        copy #0, part_init_done
++      jmp nmi_exit        ; RTI

nmi_horzbars2
        ; Demo part: full-screen horizontal color bars (after "game over - continue?").
        ; Called by: nmi
        ; Calls: init_horzbars2, anim_horzbars2

        lda part_init_done  ; initialize on first run
        cmp #0
        beq +
        jmp ++
+       jsr init_horzbars2

++      jsr anim_horzbars2
        inc_lda horzbars2_timer_lo
        cmp #255
        beq +
        jmp ++
+       inc_lda horzbars2_timer_hi
        cmp #14
        beq +
        jmp ++

+       copy #id_wecome, demo_part  ; back to first part
        copy #0, part_init_done
++      jmp nmi_exit        ; RTI

nmi_checkered
        ; Demo part: checkered wavy animation.
        ; Called by: nmi
        ; Calls: init_checkered, anim_checkered, jump_snd_eng

        lda part_init_done  ; initialize on first run
        cmp #0
        beq +
        jmp ++
+       jsr init_checkered

++      jsr anim_checkered
        jsr jump_snd_eng
        inc_lda checkered_timer_lo
        cmp #255
        beq +
        jmp ++
+       inc checkered_timer_hi
++      lda checkered_timer_hi
        cmp #2
        bne +
        lda checkered_timer_lo
        cmp #175
        bne +

        copy #id_greets, demo_part  ; next part
        copy #0, part_init_done
+       jmp nmi_exit        ; RTI

nmi_gradients
        ; Demo part: red and purple gradient.
        ; Called by: nmi
        ; Calls: init_gradients, anim_gradients, jump_snd_eng

        lda part_init_done  ; initialize on first run
        cmp #0
        beq +
        jmp ++
+       jsr init_gradients

++      jsr anim_gradients
        jsr jump_snd_eng
        inc_lda gradients_timer_lo
        cmp #255
        beq +
        jmp ++
+       inc_lda gradients_timer_hi
        cmp #3
        beq +
        jmp ++

+       copy #id_horzbars1, demo_part  ; next part
        copy #0, part_init_done
++      jmp nmi_exit        ; RTI

nmi_greets
        ; Demo part: "GREETS TO ALL NINTENDAWGS".
        ; Called by: nmi
        ; Calls: init_greets, anim_greets, jump_snd_eng

        lda part_init_done  ; initialize on first run
        cmp #0
        beq +
        jmp ++
+       jsr init_greets

++      jsr anim_greets
        jsr jump_snd_eng
        inc_lda greets_timer_lo
        cmp #255
        beq +
        jmp ++
+       inc greets_timer_hi
++      lda greets_timer_hi
        cmp #3
        bne +
        lda greets_timer_lo
        cmp #150
        bne +

        copy #id_gameover, demo_part  ; next part
        copy #0, part_init_done
+       jmp nmi_exit        ; RTI

nmi_gameover
        ; Demo part: "game over - continue?".
        ; Called by: nmi
        ; Calls: init_gameover, anim_gameover

        lda part_init_done  ; initialize on first run
        cmp #0
        beq +
        jmp ++
+       jsr init_gameover

++      jsr anim_gameover
        inc_lda gameover_timer_lo
        cmp #255
        beq +
        jmp ++
+       inc gameover_timer_hi
++      lda gameover_timer_hi
        cmp #10
        bne +
        lda gameover_timer_lo
        cmp #160
        bne +

        copy #id_horzbars2, demo_part  ; next part
        copy #0, part_init_done
+       jmp nmi_exit                   ; RTI

nmi_exit
        rti

; --- IRQ routine (unaccessed) --------------------------------------------------------------------

irq     rti                 ; $fc26

; --- Interrupt vectors ---------------------------------------------------------------------------

        pad $fffa, $00
        dw nmi, init, irq

; --- CHR ROM -------------------------------------------------------------------------------------

        ; see readme file
        incbin "chr0.bin"
        incbin "chr1.bin"
        incbin "chr2.bin"
        incbin "chr3.bin"
