; PPU

macro reset_ppu_addr
    lda #$00
    sta ppu_addr
    sta ppu_addr
endm

macro set_ppu_addr addr
    lda #>(addr)
    sta ppu_addr
    lda #<(addr)
    sta ppu_addr
endm

macro set_ppu_addr_via_x addr
    ldx #>(addr)
    stx ppu_addr
    ldx #<(addr)
    stx ppu_addr
endm

macro reset_ppu_scroll
    lda #0
    sta ppu_scroll
    sta ppu_scroll
endm

macro set_ppu_scroll horizontal, vertical
    lda #(horizontal)
    sta ppu_scroll
    lda #(vertical)
    sta ppu_scroll
endm

macro write_ppu_data byte
    lda #(byte)
    sta ppu_data
endm

macro sprite_dma
    lda #>(sprite_page)
    sta oam_dma
endm

; --------------------------------------------------------------------------------------------------
; misc

macro chr_bankswitch bank
    ; write a constant (0...3) over the same value in PRG ROM
label:
    lda #(bank)
    sta label + 1
endm
