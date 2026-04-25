; =============================================================================
; C64 Optical Illusion Demo
; -----------------------------------------------------------------------------
; Questo programma replica un'illusione ottica basata sul contrasto di luminanza.
; Gli sprite (omini) e la scala sono statici, ma un ciclo di colori coordinato
; tra gli oggetti e lo sfondo crea una forte percezione di movimento.
; =============================================================================

* = $0801
.byte $0c,$08,$0a,$00,$9e,$32,$30,$36,$34,$00,$00,$00   ; 10 SYS2064

* = $0810

; --- Costanti Hardware VIC-II ---
SCREEN          = $0400
SPR_PTR         = $07f8
COLOR_RAM       = $d800
VIC_BORDER      = $d020
VIC_BG          = $d021
VIC_CTRL1       = $d011
VIC_CTRL2       = $d016
VIC_MEMPTR      = $d018
VIC_RASTER      = $d012
VIC_SPR_EN      = $d015
VIC_SPR_XMSB    = $d010
VIC_SPR_XEXP    = $d01d
VIC_SPR_YEXP    = $d017
VIC_SPR_MC      = $d01c
VIC_SPR_COL0    = $d027
VIC_BANKSEL     = $dd00

; --- Indirizzi RAM per i dati personalizzati ---
CHARSET_RAM     = $2000
SPRITE_DATA     = $3000

; --- Variabili Zero Page ---
ptr             = $fb

start:
    sei                     ; Disabilita interrupt durante il setup

    ; Configura il banco VIC 0 ($0000-$3fff) tramite il registro $dd00 del CIA 2
    lda VIC_BANKSEL
    and #$fc
    ora #$03
    sta VIC_BANKSEL

    ; Imposta il colore di bordo e sfondo su Grigio Chiaro ($0f)
    lda #$0f
    sta VIC_BORDER
    sta VIC_BG

    ; VIC_CTRL1: Modalità testo standard, 25 righe
    lda #$1b
    sta VIC_CTRL1
    ; VIC_CTRL2: 40 colonne
    lda #$08
    sta VIC_CTRL2
    ; VIC_MEMPTR: Definisce dove risiedono Screen RAM ($0400) e Charset ($2000)
    lda #$18
    sta VIC_MEMPTR

    ; Inizializzazione variabili di stato
    lda #$0f
    sta currentGray
    lda #$01
    sta flashColor
    lda #$00
    sta phase

    ; Preparazione della scena
    jsr init_charset
    jsr clear_screen_and_color
    jsr draw_scene
    jsr setup_sprites

main_loop:
    jsr wait_frame          ; Sincronizzazione con il ritorno del pennello (raster)

    ; Divisore di frame per rallentare l'animazione (aggiornamento ogni 2 frame)
    inc frameDivider
    lda frameDivider
    cmp #$02
    bcc no_visual_update
    lda #$00
    sta frameDivider

    ; Gestione del ciclo di colori (luminanza)
    ldx phase
    lda flash_table,x       ; Legge il colore corrente dalla tabella
    sta flashColor
    inx
    cpx #FLASH_LEN
    bne store_phase
    ldx #$00                ; Ricomincia il ciclo
store_phase:
    stx phase

    ; Aggiorna i colori degli elementi a video
    jsr paint_gray_area
    jsr paint_staircase_color
    jsr set_sprite_colors

no_visual_update:
    jmp main_loop

; --- Sottoprogrammi ---

; Attende che il pennello raster raggiunga la fine dell'area visibile
wait_frame:
wait_hi:
    lda VIC_RASTER
    cmp #$ff
    bne wait_hi
wait_lo:
    lda VIC_RASTER
    cmp #$ff
    beq wait_lo
    rts

; Pulisce il set di caratteri e definisce il carattere 1 come un blocco pieno
init_charset:
    lda #$00
    ldx #$00
clear_loop:
    sta CHARSET_RAM + $000,x
    sta CHARSET_RAM + $100,x
    sta CHARSET_RAM + $200,x
    sta CHARSET_RAM + $300,x
    sta CHARSET_RAM + $400,x
    sta CHARSET_RAM + $500,x
    sta CHARSET_RAM + $600,x
    sta CHARSET_RAM + $700,x
    inx
    bne clear_loop

    ; Carattere 1: Blocco 8x8 pixel completamente pieno.
    ; Questo carattere viene usato per "dipingere" l'area della scala e lo sfondo
    ; reattivo alla luminanza.
    ldx #$00
full_block:
    lda #$ff
    sta CHARSET_RAM + $008,x
    inx
    cpx #$08
    bne full_block

    rts

; Pulisce la memoria dello schermo e resetta i colori (RAM Colore)
clear_screen_and_color:
    lda #$00
    ldx #$00
screen_3pages:
    sta SCREEN + $000,x
    sta SCREEN + $100,x
    sta SCREEN + $200,x
    inx
    bne screen_3pages

    ldx #$00
screen_last:
    sta SCREEN + $300,x
    inx
    cpx #$e8
    bne screen_last

    ldx #$00
color_3pages:
    sta COLOR_RAM + $000,x
    sta COLOR_RAM + $100,x
    sta COLOR_RAM + $200,x
    inx
    bne color_3pages

    ldx #$00
color_last:
    sta COLOR_RAM + $300,x
    inx
    cpx #$e8
    bne color_last
    rts

draw_scene:
    ; Disegna l'area rettangolare centrale utilizzando il carattere 1 (blocco pieno).
    ; Le coordinate sono centrate rispetto allo schermo 40x25.
    ldx #$00
row_chars:
    lda screen_row_lo,x
    sta ptr
    lda screen_row_hi,x
    sta ptr+1

    ldy #$00
col_chars:
    lda #$01
    sta (ptr),y
    iny
    cpy #$1a               ; Larghezza di 26 colonne
    bne col_chars

    inx
    cpx #$10               ; 16 rows
    bne row_chars

    ; Initial light gray fill
    lda #$0f
    sta currentGray
    jsr paint_gray_area

    jsr paint_staircase_color
    rts

; Colora lo sfondo dell'area di lavoro con il grigio corrente
paint_gray_area:
    ldx #$00
row_loop:
    lda color_row_lo,x
    sta ptr
    lda color_row_hi,x
    sta ptr+1

    ; Fill full active row with gray background.
    ldy #$00
full_seg:
    lda currentGray
    sta (ptr),y
    iny
    cpy #$1a
    bne full_seg

next_row:
    inx
    cpx #$10
    bne row_loop
    rts

; Colora i tasselli della scala applicando il ciclo di luminanza
paint_staircase_color:
    ldx #$00
stair_rows:
    lda color_row_lo,x
    sta ptr
    lda color_row_hi,x
    sta ptr+1

    ; Legge dove inizia la scala orizzontalmente per questa riga specifica
    lda stair_start_x,x 
    cmp #$ff               ; Se $ff, la riga non contiene parti della scala
    beq stair_next_row
    sta rightStartTmp

    ; Applica il colore dinamico (flashColor) solo alla porzione della scala.
    ; L'illusione di movimento nasce dalla differenza di luminanza tra
    ; questo colore e quello dello sfondo (currentGray).
    ldy rightStartTmp
stair_cols:
    lda flashColor
    sta (ptr),y
    iny
    cpy #$0f               ; Limite destro della scala
    bne stair_cols

stair_next_row:
    inx
    cpx #$10               ; all 16 active rows
    bne stair_rows
    rts

; Applica lo stesso ciclo di colori a tutti gli sprite attivi
set_sprite_colors:
    ldx #$00
col_loop_dynamic:
    lda flashColor
    sta VIC_SPR_COL0,x
    inx
    cpx #$07
    bne col_loop_dynamic
    rts

; Configurazione iniziale dei registri VIC-II per gli sprite
setup_sprites:
    ; Punta i 7 sprite ai dati definiti in SPRITE_DATA
    lda #SPRITE_DATA / 64
    ldx #$00
ptr_loop:
    sta SPR_PTR,x
    inx
    cpx #$07
    bne ptr_loop

    lda #$7f               ; Abilita i primi 7 sprite
    sta VIC_SPR_EN

    ; Gestione del 9° bit per la coordinata X (MSB) per il 7° sprite
    lda #$40               ; Sprite 6 (7th) X position > 255 (bit 6 set)
    sta VIC_SPR_XMSB

    lda #$7f
    sta VIC_SPR_XEXP
    sta VIC_SPR_YEXP

    ; Modalità monocromatica per tutti
    lda #$00
    sta VIC_SPR_MC

    ; Posizionamento iniziale dagli array sprite_x e sprite_y
    ; Il VIC-II usa indirizzi consecutivi per X e Y: $d000=X0, $d001=Y0, $d002=X1...
    ldx #$00 
pos_loop:
    txa
    asl
    tay
    lda sprite_x,x
    sta $d000,y
    lda sprite_y,x
    sta $d001,y
    inx
    cpx #$07
    bne pos_loop

    jsr set_sprite_colors
    rts

phase:
.byte $00

currentGray:
.byte $0f

rightStartTmp:
.byte $00

flashColor:
.byte $01

frameDivider: .byte $00

; Tabella dei colori per l'illusione: crea una sequenza di luminanza
; Bianco -> Grigio Chiaro -> Grigio Scuro -> Nero -> Grigio Scuro -> Grigio Chiaro
flash_table:
.byte $01,$01,$01,$0f,$0c,$0b,$00,$00,$00,$0b,$0c,$0f
FLASH_LEN = * - flash_table

; Tabelle di puntatori per le righe dello schermo (offset per centrare la scena)
screen_row_lo:
.byte <(SCREEN+$00f6), <(SCREEN+$011e), <(SCREEN+$0146), <(SCREEN+$016e)
.byte <(SCREEN+$0196), <(SCREEN+$01be), <(SCREEN+$01e6), <(SCREEN+$020e)
.byte <(SCREEN+$0236), <(SCREEN+$025e), <(SCREEN+$0286), <(SCREEN+$02ae)
.byte <(SCREEN+$02d6), <(SCREEN+$02fe), <(SCREEN+$0326), <(SCREEN+$034e)

screen_row_hi:
.byte >(SCREEN+$00f6), >(SCREEN+$011e), >(SCREEN+$0146), >(SCREEN+$016e)
.byte >(SCREEN+$0196), >(SCREEN+$01be), >(SCREEN+$01e6), >(SCREEN+$020e)
.byte >(SCREEN+$0236), >(SCREEN+$025e), >(SCREEN+$0286), >(SCREEN+$02ae)
.byte >(SCREEN+$02d6), >(SCREEN+$02fe), >(SCREEN+$0326), >(SCREEN+$034e)

color_row_lo:
.byte <(COLOR_RAM+$00f6), <(COLOR_RAM+$011e), <(COLOR_RAM+$0146), <(COLOR_RAM+$016e)
.byte <(COLOR_RAM+$0196), <(COLOR_RAM+$01be), <(COLOR_RAM+$01e6), <(COLOR_RAM+$020e)
.byte <(COLOR_RAM+$0236), <(COLOR_RAM+$025e), <(COLOR_RAM+$0286), <(COLOR_RAM+$02ae)
.byte <(COLOR_RAM+$02d6), <(COLOR_RAM+$02fe), <(COLOR_RAM+$0326), <(COLOR_RAM+$034e)

color_row_hi:
.byte >(COLOR_RAM+$00f6), >(COLOR_RAM+$011e), >(COLOR_RAM+$0146), >(COLOR_RAM+$016e)
.byte >(COLOR_RAM+$0196), >(COLOR_RAM+$01be), >(COLOR_RAM+$01e6), >(COLOR_RAM+$020e)
.byte >(COLOR_RAM+$0236), >(COLOR_RAM+$025e), >(COLOR_RAM+$0286), >(COLOR_RAM+$02ae)
.byte >(COLOR_RAM+$02d6), >(COLOR_RAM+$02fe), >(COLOR_RAM+$0326), >(COLOR_RAM+$034e)

; Definizione della forma della scala: colonna di inizio per ogni riga
; Ogni scalino è alto 2 righe e largo 2 caratteri.
stair_start_x:
.byte $ff,$ff
.byte $0d,$0d
.byte $0b,$0b
.byte $09,$09
.byte $07,$07
.byte $05,$05
.byte $03,$03
.byte $01,$01

; Coordinate X e Y dei 7 omini
sprite_x:
.byte $51,$81,$a8,$c8,$e0,$e6,$10

sprite_y:
.byte $af,$7f,$58,$3a,$71,$a7,$d0

; --- Dati Grafici degli Sprite ---
* = SPRITE_DATA
; Dati grafici degli sprite (24x21 pixel). Ogni riga occupa 3 byte.
.byte $00,$30,$00
.byte $00,$78,$00
.byte $00,$30,$00
.byte $00,$30,$00
.byte $00,$7c,$00
.byte $00,$30,$00
.byte $00,$30,$00
.byte $00,$6c,$00
.byte $00,$c6,$00
.byte $00,$00,$00
.byte $00,$00,$00
.byte $00,$00,$00
.byte $00,$00,$00
.byte $00,$00,$00
.byte $00,$00,$00
.byte $00,$00,$00
.byte $00,$00,$00
.byte $00,$00,$00
.byte $00,$00,$00
.byte $00,$00,$00
.byte $00,$00,$00
