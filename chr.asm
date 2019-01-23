    ; CHR ROM
    ; 32 KiB (four banks, 8 KiB each)

    .org $0000
    .incbin "chr.bin"
    .advance $8000, $00
