#!/usr/bin/env python3
import csv
color_map = {'nero': '00', 'bianco': '01', 'grigio scuro': '0e', 'grigio chiaro': '0f'}
with open('color_cycle.csv', 'r') as f:
    reader = csv.DictReader(f)
    vert, horiz, stair = [], [], []
    for i, row in enumerate(reader, 1):
        v = color_map[row['c_vert'].strip()]
        h = color_map[row['c_oriz'].strip()]
        s = color_map[row['col_stair'].strip()]
        vert.append(v)
        horiz.append(h)
        stair.append(s)
        print(f'{i:2d}: v={v} h={h} s={s}  (vert={row["c_vert"].strip():15} horiz={row["c_oriz"].strip():15} stair={row["col_stair"].strip()})')

print(f'\nVert:  {", ".join(vert)}')
print(f'Horiz: {", ".join(horiz)}')
print(f'Stair: {", ".join(stair)}')
