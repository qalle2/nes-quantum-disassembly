; Quantum Disco Brothers disassembly

    .include "macros.asm"
    .include "constants.asm"

; -----------------------------------------------------------------------------

    ; iNES header

    .org $0000

    .byte "NES", $1a            ; identifier
    .byte 2                     ; 2*16 KiB PRG-ROM
    .byte 4                     ; 4*8 KiB CHR-ROM
    .byte %00110000, %00000000  ; mapper 3 (CNROM), horizontal mirroring

    .advance $0010, $00

; -----------------------------------------------------------------------------

    ; PRG ROM
    ; 32 KiB (technically one bank but the program aligns nicely with the
    ; 16-KiB boundary)

    .org $8000
    .include "prg0.asm"   ; first half
    .advance $c000, $00
    .include "prg1.asm"   ; second half minus the interrupt vectors
    .advance $fffa, $00
    .word nmi, init, irq  ; interrupt vectors
    .advance $10000, $00

; -----------------------------------------------------------------------------

    ; CHR ROM
    ; 32 KiB (4*8 KiB)

    .org $0000
    .incbin "chr.bin"
    .advance $8000, $00
