; interrupt routines

; -----------------------------------------------------------------------------

nmi:
    lda ppu_status  ; clear VBlank flag

    lda nmi_task
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
    jmp nmi_exit       ;  0*3
    jmp nmi_section1   ;  1*3
    jmp nmi_section4   ;  2*3
    jmp nmi_section2   ;  3*3
    jmp nmi_section9   ;  4*3
    jmp nmi_section5   ;  5*3
    jmp nmi_section6   ;  6*3
    jmp nmi_section8   ;  7*3
    jmp nmi_section7   ;  8*3
    jmp nmi_section13  ;  9*3
    jmp nmi_section10  ; 10*3
    jmp nmi_section3   ; 11*3
    jmp nmi_section11  ; 12*3
    jmp nmi_section12  ; 13*3

; -----------------------------------------------------------------------------

nmi_section1:
    ; "Greetings! We come from..."

    lda flag1
    cmp #0
    beq +
    jmp ++
*   lda #1
    sta flag1
*   jsr sub29
    jsr sub12
    inc $93
    inc $93
    inc $94
    inc $94
    lda $94
    cmp #$e6
    beq +
    jmp nmi_section1_exit
*   inc $95
    lda #$00
    sta $94
nmi_section1_exit:
    jmp nmi_exit

; -----------------------------------------------------------------------------

nmi_section4:
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
    jmp nmi_section4_exit
*   inc $99
    lda $99
    cmp #$03
    beq +
    jmp nmi_section4_exit
*   lda #4
    sta nmi_task
    lda #0
    sta flag1
nmi_section4_exit:
    jmp nmi_exit

; -----------------------------------------------------------------------------

nmi_section2:
    ; "wAMMA - Quantum Disco Brothers"

    lda flag1
    cmp #0
    beq +
    jmp ++
*   jsr sub30
*   jsr sub31
    jsr sub12
    inc $ab
    lda $ab
    cmp #$ff
    beq +
    jmp nmi_section2_exit
*   inc $ac
    lda $ac
    cmp #$03
    beq +
    jmp nmi_section2_exit
*   lda #11
    sta nmi_task
    lda #0
    sta flag1
nmi_section2_exit:
    jmp nmi_exit

; -----------------------------------------------------------------------------

nmi_section9:
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

nmi_section5:
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
    jmp nmi_section5_exit
*   inc $aa
    lda $aa
    cmp #$04
    beq +
    jmp nmi_section5_exit
*   lda #5
    sta nmi_task
    lda #0
    sta flag1
nmi_section5_exit:
    jmp nmi_exit

; -----------------------------------------------------------------------------

nmi_section6:
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

nmi_section8:
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
    jmp nmi_section8_exit
*   inc $0136
    lda $0136
    cmp #$03
    beq +
    jmp nmi_section8_exit
*   lda #3
    sta nmi_task
    lda #0
    sta flag1
nmi_section8_exit:
    jmp nmi_exit

; -----------------------------------------------------------------------------

nmi_section7:
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
    bne nmi_section7_exit
    lda $013f
    cmp #$ae
    bne nmi_section7_exit
    lda #6
    sta nmi_task
    lda #0
    sta flag1
nmi_section7_exit:
    jmp nmi_exit

; -----------------------------------------------------------------------------

nmi_section13:
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
    jmp nmi_section13_exit
*   lda #0
    sta nmi_task
    lda #0
    sta flag1
nmi_section13_exit:
    jmp nmi_exit

; -----------------------------------------------------------------------------

nmi_section10:
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
    bne nmi_section10_exit
    lda $0143
    cmp #$af
    bne nmi_section10_exit
    lda #12
    sta nmi_task
    lda #0
    sta flag1
nmi_section10_exit:
    jmp nmi_exit

; -----------------------------------------------------------------------------

nmi_section3:
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
    jmp nmi_section3_exit
*   inc $0146
    lda $0146
    cmp #$03
    beq +
    jmp nmi_section3_exit
*   lda #1
    sta nmi_task
    lda #0
    sta flag1
nmi_section3_exit:
    jmp nmi_exit

; -----------------------------------------------------------------------------

nmi_section11:
    ; greets

    lda flag1
    cmp #0
    beq +
    jmp ++
*   jsr sub48
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
    bne nmi_section11_exit
    lda $014f
    cmp #$96
    bne nmi_section11_exit
    lda #13
    sta nmi_task
    lda #0
    sta flag1
nmi_section11_exit:
    jmp nmi_exit

; -----------------------------------------------------------------------------

nmi_section12:
    ; "game over - continue?"

    lda flag1
    cmp #0
    beq +
    jmp ++
*   jsr sub46
*   jsr sub47
    inc $0151
    lda $0151
    cmp #$ff
    beq +
    jmp ++
*   inc $0152
*   lda $0152
    cmp #$0a
    bne nmi_section12_exit
    lda $0151
    cmp #$a0
    bne nmi_section12_exit
    lda #9
    sta nmi_task
    lda #0
    sta flag1
nmi_section12_exit:
    jmp nmi_exit

; -----------------------------------------------------------------------------

nmi_exit:
    rti

; -----------------------------------------------------------------------------

irq:
    rti
