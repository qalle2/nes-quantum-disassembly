; Quantum Disco Brothers disassembly. Assembles with Ophis.

; -----------------------------------------------------------------------------

    ; iNES header

    ; identifier
    .byte "NES", $1a
    ; PRG ROM size (32 KiB)
    .byte 2
    ; CHR ROM size (32 KiB)
    .byte 4
    ; flags: mapper (3 = CNROM), Name Table mirroring (horizontal), Trainer
    ; (no), battery-backed PRG RAM (no)
    .byte %00110000, %00000000
    ; unused
    .byte $00, $00, $00, $00, $00, $00, $00, $00

; -----------------------------------------------------------------------------

    ; PRG ROM (32 KiB)
    ; assembled earlier (see the batch/readme files)
    .incbin "prg.bin"

; -----------------------------------------------------------------------------

    ; CHR ROM (32 KiB)
    ; not included (see the readme file)
    .incbin "chr.bin"
