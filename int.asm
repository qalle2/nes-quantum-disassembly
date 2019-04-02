; interrupt routines

; -----------------------------------------------------------------------------

nmi:
    lda ppu_status  ; clear VBlank flag

    lda demo_part
    cmp #0
    beq nmi_jump_table+1*3
    cmp #1
    beq nmi_jump_table+2*3
    cmp #2
    beq nmi_jump_table+3*3
    cmp #3
    beq nmi_jump_table+4*3
    cmp #4
    beq nmi_jump_table+5*3
    cmp #5
    beq nmi_jump_table+6*3
    cmp #6
    beq nmi_jump_table+7*3
    cmp #7
    beq nmi_jump_table+8*3
    cmp #9
    beq nmi_jump_table+9*3
    cmp #10
    beq nmi_jump_table+10*3
    cmp #11
    beq nmi_jump_table+11*3
    cmp #12
    beq nmi_jump_table+12*3
    cmp #13
    beq nmi_jump_table+13*3

nmi_jump_table:
    jmp nmi_exit    ;  0*3 (unaccessed, $f980)
    jmp nmi_part1   ;  1*3
    jmp nmi_part4   ;  2*3
    jmp nmi_part2   ;  3*3
    jmp nmi_part9   ;  4*3
    jmp nmi_part5   ;  5*3
    jmp nmi_part6   ;  6*3
    jmp nmi_part8   ;  7*3
    jmp nmi_part7   ;  8*3
    jmp nmi_part13  ;  9*3
    jmp nmi_part10  ; 10*3
    jmp nmi_part3   ; 11*3
    jmp nmi_part11  ; 12*3
    jmp nmi_part12  ; 13*3

; -----------------------------------------------------------------------------

nmi_part1:
    ; "Greetings! We come from..."

    lda flag1
    cmp #0
    beq +
    jmp ++
*   lda #1
    sta flag1
*   jsr sub19
    jsr sub12
    inc $93
    inc $93
    inc $94
    inc $94
    lda $94
    cmp #$e6
    beq +
    jmp nmi_part1_exit
*   inc $95
    lda #$00
    sta $94
nmi_part1_exit:
    jmp nmi_exit

; -----------------------------------------------------------------------------

nmi_part4:
    ; horizontal color bars

    lda flag1
    cmp #0
    beq +
    jmp ++
*   jsr sub38
*   jsr sub39
    jsr sub12
    inc $98
    lda $98
    cmp #$ff
    beq +
    jmp nmi_part4_exit
*   inc $99
    lda $99
    cmp #$03
    beq +
    jmp nmi_part4_exit
*   lda #4
    sta demo_part
    lda #0
    sta flag1
nmi_part4_exit:
    jmp nmi_exit

; -----------------------------------------------------------------------------

nmi_part2:
    ; "wAMMA - Quantum Disco Brothers"

    lda flag1
    cmp #0
    beq +
    jmp ++
*   jsr sub20
*   jsr sub21
    jsr sub12
    inc $ab
    lda $ab
    cmp #$ff
    beq +
    jmp nmi_part2_exit
*   inc $ac
    lda $ac
    cmp #$03
    beq +
    jmp nmi_part2_exit
*   lda #11
    sta demo_part
    lda #0
    sta flag1
nmi_part2_exit:
    jmp nmi_exit

; -----------------------------------------------------------------------------

nmi_part9:
    ; credits

    lda flag1
    cmp #0
    beq +
    jmp ++
*   jsr sub40
*   jsr sub41
    jsr sub12
    jmp nmi_exit

; -----------------------------------------------------------------------------

nmi_part5:
    ; the woman

    lda flag1
    cmp #0
    beq +
    jmp ++
*   jsr sub42
*   jsr sub43
    jsr sub12
    inc $a9
    lda $a9
    cmp #$ff
    beq +
    jmp nmi_part5_exit
*   inc $aa
    lda $aa
    cmp #$04
    beq +
    jmp nmi_part5_exit
*   lda #5
    sta demo_part
    lda #0
    sta flag1
nmi_part5_exit:
    jmp nmi_exit

; -----------------------------------------------------------------------------

nmi_part6:
    ; "It is Friday..."

    lda flag1
    cmp #0
    beq +
    jmp ++
*   jsr sub54
*   jsr sub55
    jsr sub12
    jmp nmi_exit

; -----------------------------------------------------------------------------

nmi_part8:
    ; Bowser's spaceship

    lda flag1
    cmp #0
    beq +
    jmp ++
*   jsr sub44
*   jsr sub45
    jsr sub12
    inc $0135
    lda $0135
    cmp #$ff
    beq +
    jmp nmi_part8_exit
*   inc $0136
    lda $0136
    cmp #$03
    beq +
    jmp nmi_part8_exit
*   lda #3
    sta demo_part
    lda #0
    sta flag1
nmi_part8_exit:
    jmp nmi_exit

; -----------------------------------------------------------------------------

nmi_part7:
    ; Coca Cola cans

    lda flag1
    cmp #0
    beq +
    jmp ++
*   jsr sub50
*   jsr sub51
    jsr sub12
    inc $013f
    lda $013f
    cmp #$ff
    beq +
    jmp ++
*   inc $0140
*   lda $0140
    cmp #$03
    bne nmi_part7_exit
    lda $013f
    cmp #$ae
    bne nmi_part7_exit
    lda #6
    sta demo_part
    lda #0
    sta flag1
nmi_part7_exit:
    jmp nmi_exit

; -----------------------------------------------------------------------------

nmi_part13:
    ; full-screen horizontal color bars after "game over - continue?"; the
    ; demo freezes soon afterwards

    lda flag1
    cmp #0
    beq +
    jmp ++
*   jsr sub32
*   jsr sub33
    inc $0141
    lda $0141
    cmp #$ff
    beq +
    jmp $fb3d
*   inc $0142
    lda $0142
    cmp #$0e
    beq +
    jmp nmi_part13_exit
*   lda #0
    sta demo_part
    lda #0
    sta flag1
nmi_part13_exit:
    jmp nmi_exit

; -----------------------------------------------------------------------------

nmi_part10:
    ; checkered wavy animation

    lda flag1
    cmp #0
    beq +
    jmp ++
*   jsr sub34
*   jsr sub35
    jsr sub12
    inc $0143
    lda $0143
    cmp #$ff
    beq +
    jmp ++
*   inc $0144
*   lda $0144
    cmp #$02
    bne nmi_part10_exit
    lda $0143
    cmp #$af
    bne nmi_part10_exit
    lda #12
    sta demo_part
    lda #0
    sta flag1
nmi_part10_exit:
    jmp nmi_exit

; -----------------------------------------------------------------------------

nmi_part3:
    ; red&purple gradient

    lda flag1
    cmp #0
    beq +
    jmp ++
*   jsr sub36
*   jsr sub37
    jsr sub12
    inc $0145
    lda $0145
    cmp #$ff
    beq +
    jmp nmi_part3_exit
*   inc $0146
    lda $0146
    cmp #$03
    beq +
    jmp nmi_part3_exit
*   lda #1
    sta demo_part
    lda #0
    sta flag1
nmi_part3_exit:
    jmp nmi_exit

; -----------------------------------------------------------------------------

nmi_part11:
    ; greets

    lda flag1
    cmp #0
    beq +
    jmp ++
*   jsr greets_screen
*   jsr sub49
    jsr sub12
    inc $014f
    lda $014f
    cmp #$ff
    beq +
    jmp ++
*   inc $0150
*   lda $0150
    cmp #$03
    bne nmi_part11_exit
    lda $014f
    cmp #$96
    bne nmi_part11_exit
    lda #13
    sta demo_part
    lda #0
    sta flag1
nmi_part11_exit:
    jmp nmi_exit

; -----------------------------------------------------------------------------

nmi_part12:
    ; "GAME OVER - CONTINUE?"

    lda flag1
    cmp #0
    beq +
    jmp ++
*   jsr game_over_screen
*   jsr sub47
    inc $0151
    lda $0151
    cmp #$ff
    beq +
    jmp ++
*   inc $0152
*   lda $0152
    cmp #$0a
    bne nmi_part12_exit
    lda $0151
    cmp #$a0
    bne nmi_part12_exit
    lda #9
    sta demo_part
    lda #0
    sta flag1
nmi_part12_exit:
    jmp nmi_exit

; -----------------------------------------------------------------------------

nmi_exit:
    rti

; -----------------------------------------------------------------------------

irq:
    rti  ; unaccessed ($fc26)
