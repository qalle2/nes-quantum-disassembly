    ; iNES header

    .org $0000

    .byte "NES", $1a            ; identifier
    .byte 2                     ; 2*16 KiB PRG-ROM
    .byte 4                     ; 4*8 KiB CHR-ROM
    .byte %00110000, %00000000  ; mapper 3 (CNROM), horizontal mirroring

    .advance $0010
