    ; NES memory-mapped registers

    ppu_ctrl   equ $2000
    ppu_mask   equ $2001
    ppu_status equ $2002
    ppu_scroll equ $2005
    ppu_addr   equ $2006
    ppu_data   equ $2007

    apu_regs      equ $4000
    pulse1_ctrl   equ $4000
    pulse1_sweep  equ $4001
    pulse1_timer  equ $4002
    pulse1_length equ $4003
    triangle_ctrl equ $4008
    noise_period  equ $400e
    noise_length  equ $400f
    dmc_ctrl      equ $4010
    dmc_load      equ $4011
    dmc_addr      equ $4012
    dmc_length    equ $4013
    oam_dma       equ $4014
    apu_ctrl      equ $4015
    apu_counter   equ $4017

; -----------------------------------------------------------------------------

    ram1       equ $00  ; ??
    demo_part  equ $01  ; which part is running (see int.asm)
    temp1      equ $01
    flag1      equ $02  ; flag used in NMI? (seems to always be 0 or 1)
    ptr1       equ $03  ; pointer (2 bytes)
    delay_var1 equ $86
    delay_cnt  equ $87
    delay_var2 equ $88
    loopcnt    equ $9b  ; loop counter (may have other uses)
    ptr2       equ $c8  ; pointer (2 bytes)
    ptr3       equ $ce  ; pointer (2 bytes)
    ptr4       equ $d0  ; pointer (2 bytes)
    ptr5       equ $d8  ; pointer (2 bytes)
    ptr6       equ $da  ; pointer (2 bytes)

    sprite_page equ $0500  ; 256 bytes

    palette_copy equ $07c0  ; 32 bytes

; -----------------------------------------------------------------------------

    ; video RAM
    vram_name_table0 equ $2000
    vram_attr_table0 equ $23c0
    vram_name_table1 equ $2400
    vram_attr_table1 equ $27c0
    vram_name_table2 equ $2800
    vram_attr_table2 equ $2bc0
    vram_palette     equ $3f00

; -----------------------------------------------------------------------------

    pad_byte equ $00

    ; offsets for each sprite on sprite page
    sprite_y    equ 0
    sprite_tile equ 1
    sprite_attr equ 2
    sprite_x    equ 3
