; interrupt routines

; -----------------------------------------------------------------------------

nmi:
    lda ppu_status  ; clear VBlank flag

    lda $01
    `cmp_beq  0, nmi_jump_table+ 1*3
    `cmp_beq  1, nmi_jump_table+ 2*3
    `cmp_beq  2, nmi_jump_table+ 3*3
    `cmp_beq  3, nmi_jump_table+ 4*3
    `cmp_beq  4, nmi_jump_table+ 5*3
    `cmp_beq  5, nmi_jump_table+ 6*3
    `cmp_beq  6, nmi_jump_table+ 7*3
    `cmp_beq  7, nmi_jump_table+ 8*3
    `cmp_beq  9, nmi_jump_table+ 9*3
    `cmp_beq 10, nmi_jump_table+10*3
    `cmp_beq 11, nmi_jump_table+11*3
    `cmp_beq 12, nmi_jump_table+12*3
    `cmp_beq 13, nmi_jump_table+13*3

nmi_jump_table:
    jmp nmi_exit  ;  0*3
    jmp nmi_01    ;  1*3
    jmp nmi_02    ;  2*3
    jmp nmi_03    ;  3*3
    jmp nmi_04    ;  4*3
    jmp nmi_05    ;  5*3
    jmp nmi_06    ;  6*3
    jmp nmi_07    ;  7*3
    jmp nmi_08    ;  8*3
    jmp nmi_09    ;  9*3
    jmp nmi_10    ; 10*3
    jmp nmi_11    ; 11*3
    jmp nmi_12    ; 12*3
    jmp nmi_13    ; 13*3

nmi_01:
    lda $02
    `cmp_beq $00, +
    jmp ++
*   `lda_imm_sta $01, $02
*   jsr sub29
    jsr sub12
    inc $93
    inc $93
    inc $94
    inc $94
    lda $94
    `cmp_beq $e6, +
    jmp nmi_01_exit
*   inc $95
    `lda_imm_sta $00, $94
nmi_01_exit:
    jmp nmi_exit

nmi_02:
    lda $02
    `cmp_beq $00, +
    jmp ++
*   jsr sub38
*   jsr sub39
    jsr sub12
    `inc_lda $98
    `cmp_beq $ff, +
    jmp nmi_02_exit
*   `inc_lda $99
    `cmp_beq $03, +
    jmp nmi_02_exit
*   `lda_imm_sta $04, $01
    `lda_imm_sta $00, $02
nmi_02_exit:
    jmp nmi_exit

nmi_03:
    lda $02
    `cmp_beq $00, +
    jmp ++
*   jsr sub30
*   jsr sub31
    jsr sub12
    `inc_lda $ab
    `cmp_beq $ff, +
    jmp nmi_03_exit
*   `inc_lda $ac
    `cmp_beq $03, +
    jmp nmi_03_exit
*   `lda_imm_sta $0b, $01
    `lda_imm_sta $00, $02
nmi_03_exit:
    jmp nmi_exit

nmi_04:
    lda $02
    `cmp_beq $00, +
    jmp ++
*   jsr sub40
*   jsr sub41
    jsr sub12
    jmp nmi_exit

nmi_05:
    lda $02
    `cmp_beq $00, +
    jmp ++
*   jsr sub42
*   jsr sub43
    jsr sub12
    `inc_lda $a9
    `cmp_beq $ff, +
    jmp nmi_05_exit
*   `inc_lda $aa
    `cmp_beq $04, +
    jmp nmi_05_exit
*   `lda_imm_sta $05, $01
    `lda_imm_sta $00, $02
nmi_05_exit:
    jmp nmi_exit

nmi_06:
    lda $02
    `cmp_beq $00, +
    jmp ++
*   jsr sub54
*   jsr sub55
    jsr sub12
    jmp nmi_exit

nmi_07:
    lda $02
    `cmp_beq $00, +
    jmp ++
*   jsr sub44
*   jsr sub45
    jsr sub12
    `inc_lda $0135
    `cmp_beq $ff, +
    jmp nmi_07_exit
*   `inc_lda $0136
    `cmp_beq $03, +
    jmp nmi_07_exit
*   `lda_imm_sta $03, $01
    `lda_imm_sta $00, $02
nmi_07_exit:
    jmp nmi_exit

nmi_08:
    lda $02
    `cmp_beq $00, +
    jmp ++
*   jsr sub50
*   jsr sub51
    jsr sub12
    `inc_lda $013f
    `cmp_beq $ff, +
    jmp ++
*   inc $0140
*   lda $0140
    `cmp_bne $03, nmi_08_exit
    lda $013f
    `cmp_bne $ae, nmi_08_exit
    `lda_imm_sta $06, $01
    `lda_imm_sta $00, $02
nmi_08_exit:
    jmp nmi_exit

nmi_09:
    lda $02
    `cmp_beq $00, +
    jmp ++
*   jsr sub32
*   jsr sub33
    `inc_lda $0141
    `cmp_beq $ff, +
    jmp $fb3d
*   `inc_lda $0142
    `cmp_beq $0e, +
    jmp nmi_09_exit
*   `lda_imm_sta $00, $01
    `lda_imm_sta $00, $02
nmi_09_exit:
    jmp nmi_exit

nmi_10:
    lda $02
    `cmp_beq $00, +
    jmp ++
*   jsr sub34
*   jsr sub35
    jsr sub12
    `inc_lda $0143
    `cmp_beq $ff, +
    jmp ++
*   inc $0144
*   lda $0144
    `cmp_bne $02, nmi_10_exit
    lda $0143
    `cmp_bne $af, nmi_10_exit
    `lda_imm_sta $0c, $01
    `lda_imm_sta $00, $02
nmi_10_exit:
    jmp nmi_exit

nmi_11:
    lda $02
    `cmp_beq $00, +
    jmp ++
*   jsr sub36
*   jsr sub37
    jsr sub12
    `inc_lda $0145
    `cmp_beq $ff, +
    jmp nmi_11_exit
*   `inc_lda $0146
    `cmp_beq $03, +
    jmp nmi_11_exit
*   `lda_imm_sta $01, $01
    `lda_imm_sta $00, $02
nmi_11_exit:
    jmp nmi_exit

nmi_12:
    lda $02
    `cmp_beq $00, +
    jmp ++
*   jsr sub48
*   jsr sub49
    jsr sub12
    `inc_lda $014f
    `cmp_beq $ff, +
    jmp ++
*   inc $0150
*   lda $0150
    `cmp_bne $03, nmi_12_exit
    lda $014f
    `cmp_bne $96, nmi_12_exit
    `lda_imm_sta $0d, $01
    `lda_imm_sta $00, $02
nmi_12_exit:
    jmp nmi_exit

nmi_13:
    lda $02
    `cmp_beq $00, +
    jmp ++
*   jsr sub46
*   jsr sub47
    `inc_lda $0151
    `cmp_beq $ff, +
    jmp ++
*   inc $0152
*   lda $0152
    `cmp_bne $0a, nmi_13_exit
    lda $0151
    `cmp_bne $a0, nmi_13_exit
    `lda_imm_sta $09, $01
    `lda_imm_sta $00, $02
nmi_13_exit:
    jmp nmi_exit

nmi_exit:
    rti

; -----------------------------------------------------------------------------

irq:
    rti
