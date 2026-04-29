#!/usr/bin/env python3
"""Converte il CSV in tabelle esadecimali per l'ASM"""

# Mapping da nomi C64 a codici colore
color_map = {
    "nero": "00",
    "bianco": "01",
    "grigio scuro": "0e",
    "grigio chiaro": "0f",
}

# Leggi il CSV
import csv

with open('color_cycle.csv', 'r') as f:
    reader = csv.DictReader(f)
    rows = list(reader)

# Estrai i 3 cicli
c_vert = []
c_oriz = []
col_stair = []

for row in rows:
    c_vert.append(color_map[row['c_vert'].strip()])
    c_oriz.append(color_map[row['c_oriz'].strip()])
    col_stair.append(color_map[row['col_stair'].strip()])

print("=== TABELLE PER L'ASM ===\n")

print("flash_table_vert:  ; Colore linee verticali")
print(".byte $" + ", $".join(c_vert))
print()

print("flash_table_horiz: ; Colore linee orizzontali")
print(".byte $" + ", $".join(c_oriz))
print()

print("flash_table_stair: ; Colore corpo scala")
print(".byte $" + ", $".join(col_stair))
print()

print(f"FLASH_LEN = {len(c_vert)}")
