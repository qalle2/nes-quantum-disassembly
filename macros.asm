; add/subtract without carry

    .macro add_imm
        clc
        adc #_1
    .macend
    .macro add_mem
        clc
        adc _1
    .macend
    .macro sub_imm
        sec
        sbc #_1
    .macend

; -----------------------------------------------------------------------------
; compare + branch

    .macro cmp_beq
        cmp #_1
        beq _2
    .macend
    .macro cmp_bne
        cmp #_1
        bne _2
    .macend
    .macro cpx_beq
        cpx #_1
        beq _2
    .macend
    .macro cpx_bne
        cpx #_1
        bne _2
    .macend
    .macro cpy_beq
        cpy #_1
        beq _2
    .macend
    .macro cpy_bne
        cpy #_1
        bne _2
    .macend

; -----------------------------------------------------------------------------
; decrement/increment + load

    .macro dec_lda
        dec _1
        lda _1
    .macend
    .macro dec_ldx
        dec _1
        ldx _1
    .macend
    .macro inc_lda
        inc _1
        lda _1
    .macend
    .macro inc_ldx
        inc _1
        ldx _1
    .macend

; -----------------------------------------------------------------------------
; load + store

    .macro lda_imm_sta
        lda #_1
        sta _2
    .macend
    .macro lda_mem_sta
        lda _1
        sta _2
    .macend

; -----------------------------------------------------------------------------
; repeat instruction

    .macro inx4
        inx
        inx
        inx
        inx
    .macend
    .macro iny4
        iny
        iny
        iny
        iny
    .macend
    .macro lsr4
        lsr
        lsr
        lsr
        lsr
    .macend

; -----------------------------------------------------------------------------
; PPU

    .macro reset_ppu_addr
        lda #$00
        sta ppu_addr
        sta ppu_addr
    .macend
    .macro set_ppu_addr
        lda #>_1
        sta ppu_addr
        lda #<_1
        sta ppu_addr
    .macend
    .macro set_ppu_addr_via_x
        ldx #>_1
        stx ppu_addr
        ldx #<_1
        stx ppu_addr
    .macend
    .macro reset_ppu_scroll
        lda #0
        sta ppu_scroll
        sta ppu_scroll
    .macend
    .macro set_ppu_scroll
        lda #_1
        sta ppu_scroll
        lda #_2
        sta ppu_scroll
    .macend
    .macro write_ppu_data
        lda #_1
        sta ppu_data
    .macend
    .macro sprite_dma
        lda #>sprite_page
        sta oam_dma
    .macend

; -----------------------------------------------------------------------------
; misc

    .macro chr_bankswitch
        ; write a constant (0...3) over the same value in PRG ROM
        lda #_1
        sta ^-1
    .macend
