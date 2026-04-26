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
    sta flashColorInv
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
    cmp #$06                ; Rallentato per rendere l'illusione più fluida
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

    ; Calcola il colore inverso (speculare) per la linea spezzata
    ; Spostiamo l'indice di 2 posizioni nel ciclo da 4 (FLASH_LEN)
    txa
    clc
    adc #$02
    cmp #FLASH_LEN
    bcc no_wrap_inv
    sbc #FLASH_LEN
no_wrap_inv:
    tax
    lda flash_table,x
    sta flashColorInv
    ldx phase               ; Ripristina X per coerenza

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

    ; Caratteri custom per la linea spezzata
    ldx #$00
line_chars:
    lda #$00                 
    sta CHARSET_RAM + $010,x ; Char 2: Vuoto (tranne fondo)
    lda #$01                 ; Bit 0: pixel all'estrema destra
    sta CHARSET_RAM + $018,x ; Char 3: Linea Verticale
    lda #$00                 ; Char 4: rimosso eccesso verticale superiore
    sta CHARSET_RAM + $020,x 
    lda #$01                 ; Char 6: parte verticale della giunzione
    sta CHARSET_RAM + $030,x
    lda #$80                 ; Bit 7: pixel all'estrema sinistra
    sta CHARSET_RAM + $028,x ; Char 5: Linea Verticale (Sinistra cella)
    inx
    cpx #$08
    bne line_chars
    ; Aggiunge la linea orizzontale sul fondo dei caratteri 2 e 4
    lda #$ff
    sta CHARSET_RAM + $017   ; Char 2: linea orizzontale
    lda #$01                 ; Char 4: solo il pixel d'angolo (taglio eccedenza sinistra)
    sta CHARSET_RAM + $027   
    lda #$ff                 ; Char 6: completa la giunzione con l'orizzontale
    sta CHARSET_RAM + $037
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
    ldx #$00
row_loop_main:
    lda screen_row_lo,x
    sta ptr
    lda screen_row_hi,x
    sta ptr+1
    
    lda stair_start_x,x
    cmp #$ff
    beq next_row_draw_final

    ; 1. Disegna i blocchi della scala (Char 1)
    lda #15                ; Il poligono si chiude verticalmente alla colonna 15
    sta rightStartTmp
    ldy stair_start_x,x
draw_blocks:
    lda #$01
    sta (ptr),y
    iny
    cpy rightStartTmp
    bne draw_blocks

    ; 2. Linea Verticale di chiusura a destra (Char 5 - Linea a sinistra della cella)
    lda #$05
    sta (ptr),y
    iny

    ; 3. Pulizia area a destra (Caratteri grigio chiaro / vuoti)
    lda #$00
clean_right:
    sta (ptr),y
    iny
    cpy #40
    bne clean_right

    ; 2. Linea Verticale (Char 3): solo sul lato sinistro esterno
    ldy stair_start_x,x
    dey
    lda #$03
    sta (ptr),y

    ; 3. Profilo Superiore: solo sulla prima riga di ogni gradino (riga pari)
    txa
    and #$01
    bne next_row_draw_final
    
    ; Disegna sulla riga precedente (sopra lo scalino)
    ldy stair_start_x,x
    dey
    lda screen_row_lo-1,x  ; Prende il puntatore della riga sopra
    sta ptr+2
    lda screen_row_hi-1,x
    sta ptr+3
    
    lda #$04               ; Angolo esterno
    cpx #14                ; Se è l'ultimo scalino in basso (indice riga 14)
    bne store_corner       ; evita di disegnare l'angolo che eccede
    lda #$00               ; Sostituisci con spazio vuoto per tagliare l'eccesso
store_corner:
    sta (ptr+2),y
    iny
    lda #$02               ; Linea orizzontale superiore
    sta (ptr+2),y
    iny
    lda #$06               ; Carattere di giunzione (Orizzontale + Verticale da sopra)
    cpx #$02               ; È il primo scalino in alto?
    bne store_junction
    lda #$02               ; Estendi la linea orizzontale senza il pezzetto verticale
store_junction:
    sta (ptr+2),y

next_row_draw_final:
    inx
    cpx #$10
    bne row_loop_main

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
    cpy #40                ; Esteso a tutto lo schermo
    bne full_seg

next_row:
    inx
    cpx #$10
    bne row_loop
    rts
    
paint_staircase_color:
    ldx #$00
stair_rows:
    lda screen_row_lo,x    ; Usiamo screen_row per identificare i caratteri
    sta ptr
    lda screen_row_hi,x
    sta ptr+1
    
    lda color_row_lo,x
    sta ptr+2              ; ptr+2/3 per la RAM colore
    lda color_row_hi,x
    sta ptr+3

    ldy #$00
stair_cols:
    lda (ptr),y            ; Legge il carattere a video
    beq next_stair_col     ; Salta se è lo sfondo (Char 0) per non farlo lampeggiare
    cmp #$01               ; Blocco pieno?
    bne check_custom
    lda flashColor         ; Colore scala normale
    sta (ptr+2),y
    jmp next_stair_col
check_custom:
    cmp #$05               ; Il Carattere 5 (chiusura a piombo) resta statico
    beq next_stair_col     ; per dare solidità al lato destro
    ; Tutti gli altri caratteri custom (2, 3, 4, 6) ora partecipano
    ; al flash inverso per creare un profilo continuo e coerente.
    lda flashColorInv      ; Colore flash inverso
    sta (ptr+2),y
next_stair_col:
    iny
    cpy #40                ; Esteso a tutto lo schermo
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

flashColorInv:
.byte $00

flashColor:
.byte $01

frameDivider: .byte $00

; Tabella dei colori per l'illusione: crea una sequenza di luminanza
; Pattern ottimizzato dal video: Bianco -> Grigio Sfondo -> Nero -> Grigio Sfondo
flash_table:
.byte $01                       ; Bianco
.byte $0f                       ; Grigio Chiaro (Sfondo)
.byte $00                       ; Nero
.byte $0f                       ; Grigio Chiaro (Sfondo)
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
