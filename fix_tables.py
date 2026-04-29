#!/usr/bin/env python3
"""Correggi le tabelle horiz e stair nel demo.asm"""

# Leggi il file
with open('demo.asm', 'r') as f:
    content = f.read()

# Tabelle corrette dal CSV
old_horiz = """flash_table_horiz: ; Colore linee orizzontali
.byte $01, $01, $01, $0f, $0e, $00, $00, $00
.byte $00, $0e, $0e, $0f, $01, $01, $01, $01"""

new_horiz = """flash_table_horiz: ; Colore linee orizzontali
.byte $01, $01, $01, $01, $0e, $00, $00, $00
.byte $00, $0e, $0e, $0f, $01, $01, $01, $01"""

if old_horiz in content:
    content = content.replace(old_horiz, new_horiz)
    print("✅ Corretto flash_table_horiz (frame 4: $0f -> $01)")
else:
    print("❌ flash_table_horiz non trovato")

# Scrivi il file
with open('demo.asm', 'w') as f:
    f.write(content)

print("✅ File aggiornato!")
