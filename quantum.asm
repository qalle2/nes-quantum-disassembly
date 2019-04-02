; Quantum Disco Brothers disassembly

    .include "macros.asm"
    .include "constants.asm"

; -----------------------------------------------------------------------------

    ; iNES header

    .org $0000                  ; only needed for padding
    .byte "NES", $1a            ; identifier
    .byte 2                     ; 32 KiB (2*16 KiB) PRG-ROM
    .byte 4                     ; 32 KiB (4*8 KiB) CHR-ROM
    .byte %00110000, %00000000  ; mapper 3 (CNROM), horizontal mirroring
    .advance $0010, pad_byte    ; pad

; -----------------------------------------------------------------------------

    ; PRG ROM
    ; 32 KiB (technically one bank but the program aligns nicely with the
    ; 16-KiB boundary)

    .org $8000
    .include "prg0.asm"        ; first half
    .advance $c000, pad_byte   ; pad
    .include "prg1.asm"        ; second half except interrupt routines&vectors
    .include "int.asm"         ; interrupt routines
    .advance $fffa, pad_byte   ; pad
    .word nmi, init, irq       ; interrupt vectors (IRQ unaccessed)
    .advance $10000, pad_byte  ; pad

; -----------------------------------------------------------------------------

    ; CHR ROM
    ; 32 KiB (4*8 KiB)

    .org $0000                ; only needed for padding
    .incbin "chr.bin"         ; not included; see the readme file
    .advance $8000, pad_byte  ; pad
