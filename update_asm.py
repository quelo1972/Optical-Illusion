#!/usr/bin/env python3
"""Script per aggiornare il codice paint_staircase_color in demo.asm"""

# Leggi il file
with open('demo.asm', 'r') as f:
    content = f.read()

# Stringa da cercare
old_code = """    cmp #$01               ; Blocco pieno?
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
    sta (ptr+2),y"""

# Stringa da inserire
new_code = """    cmp #$01               ; Blocco pieno (corpo scala)?
    bne check_vert
    lda flashColorStair    ; Colore corpo scala
    sta (ptr+2),y
    jmp next_stair_col
check_vert:
    cmp #$03               ; Linea verticale?
    beq use_vert
    cmp #$05               ; Linea verticale chiusura?
    beq use_vert
    ; Altrimenti è orizzontale (Char 2, 4, 6)
    lda flashColorHoriz    ; Colore linea orizzontale
    sta (ptr+2),y
    jmp next_stair_col
use_vert:
    lda flashColorVert     ; Colore linea verticale
    sta (ptr+2),y"""

if old_code in content:
    content = content.replace(old_code, new_code)
    with open('demo.asm', 'w') as f:
        f.write(content)
    print("✅ File aggiornato con successo!")
else:
    print("❌ Codice da sostituire non trovato")
    print("\nRicerco pattern alternativo...")
    if "cmp #$01               ; Blocco pieno?" in content:
        print("Pattern trovato! Procedendo con sostituzione...")
