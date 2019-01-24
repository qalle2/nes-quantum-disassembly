    .macro add_imm
        ; add immediate without carry
        clc
        adc #_1
    .macend

    .macro add_mem
        ; add memory (zero page/absolute) without carry
        clc
        adc _1
    .macend

    .macro chr_bankswitch
        ; write a constant (0...3) over the same value in PRG ROM
        lda #_1
        sta ^-1
    .macend

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

    .macro reset_ppu_addr
        lda #$00
        sta ppu_addr
        sta ppu_addr
    .macend

    .macro reset_ppu_scroll
        lda #0
        sta ppu_scroll
        sta ppu_scroll
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

    .macro set_ppu_scroll
        lda #_1
        sta ppu_scroll
        lda #_2
        sta ppu_scroll
    .macend

    .macro sub_imm
        ; subtract immediate without carry
        sec
        sbc #_1
    .macend

    .macro write_ppu_data
        lda #_1
        sta ppu_data
    .macend
