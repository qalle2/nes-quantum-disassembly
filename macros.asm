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
