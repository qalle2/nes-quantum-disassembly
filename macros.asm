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

    .macro sub_imm
        ; subtract immediate without carry
        sec
        sbc #_1
    .macend
