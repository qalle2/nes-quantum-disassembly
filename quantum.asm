; NES Quantum Disco Brothers disassembly. Assembles with asm6f.

; iNES header
    inesprg 2  ; PRG ROM size: 32 KiB
    ineschr 4  ; CHR ROM size: 32 KiB
    inesmap 3  ; mapper: CNROM
    inesmir 0  ; name table mirroring: horizontal

; PRG ROM (32 KiB); assembled earlier (see the batch/readme files)
    incbin "prg.bin"

; CHR ROM (32 KiB); not included (see the readme file)
    incbin "chr.bin"
