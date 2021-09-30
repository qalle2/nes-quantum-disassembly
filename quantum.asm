; NES Quantum Disco Brothers disassembly. Assembles with asm6.

; iNES header
    base $0000
    db "NES", $1a   ; id
    db 2            ; 32 KiB PRG ROM
    db 4            ; 32 KiB CHR ROM
    db $30, $00     ; mapper 3 (CNROM), horizontal name table mirroring
    pad $0010, $00  ; padding

; PRG ROM (32 KiB); assembled earlier (see the batch/readme files)
    incbin "prg.bin"

; CHR ROM (32 KiB); not included (see the readme file)
    incbin "chr.bin"
