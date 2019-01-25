    ; NES memory-mapped registers

    .alias ppu_ctrl   $2000
    .alias ppu_mask   $2001
    .alias ppu_status $2002
    .alias ppu_scroll $2005
    .alias ppu_addr   $2006
    .alias ppu_data   $2007

    .alias apu_regs      $4000
    .alias pulse1_ctrl   $4000
    .alias pulse1_sweep  $4001
    .alias pulse1_timer  $4002
    .alias pulse1_length $4003
    .alias triangle_ctrl $4008
    .alias noise_period  $400e
    .alias noise_length  $400f
    .alias dmc_ctrl      $4010
    .alias dmc_load      $4011
    .alias dmc_addr      $4012
    .alias dmc_length    $4013
    .alias oam_dma       $4014
    .alias apu_ctrl      $4015
    .alias apu_counter   $4017

; -----------------------------------------------------------------------------

    ; memory pointers (2 bytes each)
    .alias ptr1 $03
    .alias ptr2 $c8
    .alias ptr3 $ce
    .alias ptr4 $d0
    .alias ptr5 $d8
    .alias ptr6 $da

    .alias sprite_page $0500  ; 256 bytes

    .alias palette_copy $07c0  ; 32 bytes

; -----------------------------------------------------------------------------

    ; video RAM
    .alias vram_name_table0 $2000
    .alias vram_attr_table0 $23c0
    .alias vram_name_table1 $2400
    .alias vram_attr_table1 $27c0
    .alias vram_name_table2 $2800
    .alias vram_attr_table2 $2bc0
    .alias vram_palette     $3f00
