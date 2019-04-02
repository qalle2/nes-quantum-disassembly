    ; PRG ROM
    ; 32 KiB (technically one bank but the program aligns nicely with the
    ; 16-KiB boundary)

    .include "macros.asm"
    .include "constants.asm"

    ; first half
    .org $8000
    .include "prg0.asm"
    .advance $c000, pad_byte

    ; second half
    .include "prg1.asm"
    .include "int.asm"
    .advance $fffa, pad_byte

    .word nmi, init, irq       ; interrupt vectors (IRQ unaccessed)
    .advance $10000, pad_byte  ; pad
