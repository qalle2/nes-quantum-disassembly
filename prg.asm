    ; PRG ROM
    ; 32 KiB; technically one bank, but the program aligns nicely with the
    ; 16-KiB boundary

    .include "macros.asm"
    .include "constants.asm"

    .org $8000
    .include "prg0.asm"   ; first half
    .advance $c000, $00
    .include "prg1.asm"   ; second half minus the interrupt vectors
    .advance $fffa, $00
    .word nmi, init, irq  ; interrupt vectors
    .advance $10000, $00
