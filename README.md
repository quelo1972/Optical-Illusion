# C64 Optical Illusion Demo

Un'implementazione in Assembly 6502 per Commodore 64 di un'illusione ottica basata sulla luminanza. Questo progetto dimostra come la percezione del movimento possa essere manipolata attraverso variazioni cicliche di contrasto, senza che gli oggetti cambino effettivamente posizione.

## L'Illusione

Il principio cardine è che il cervello umano interpreta cambiamenti rapidi di luminanza (passaggio da chiaro a scuro) come vettori di movimento. 
Nel demo:
- Gli **omini** (sprite) sono assolutamente statici.
- La **scala** (caratteri custom) è statica.
- Lo **sfondo** e il bordo sono grigi uniformi.

L'animazione è generata esclusivamente dal ciclo di colori contenuto nella `flash_table`, che applica tonalità diverse di grigio e bianco agli oggetti in sincronia con il refresh del monitor.

## Caratteristiche Tecniche

- **Linguaggio**: Assembly 6502 (ACME Syntax).
- **Grafica**: Utilizzo della modalità testo con charset personalizzato per la scala e Sprite monocromatici per gli omini.
- **VIC-II Tricks**:
    - Gestione dei puntatori Sprite nella RAM del Commodore 64.
    - Utilizzo del registro MSB (`$d010`) per posizionare il settimo omino oltre il limite dei 255 pixel orizzontali.
    - Sincronizzazione tramite Raster IRQ (attesa riga `$ff`).

## Struttura del Codice

- `demo.asm`: Il cuore del progetto. Contiene la logica di inizializzazione del VIC-II, il ciclo principale e le tabelle dati per posizioni e colori.
- `videoplayback.mp4`: Riferimento visivo originale per l'illusione.

## Requisiti di Sistema

- **Assembler**: ACME
- **Emulatore**: VICE (x64sc consigliato) o hardware reale.

## Compilazione ed Esecuzione

Per compilare il sorgente in un file binario `.prg`:

```bash
acme -f cbm -o illusion.prg demo.asm
```

Per eseguire nell'emulatore VICE:

```bash
x64sc -autostart illusion.prg
```

## Personalizzazione

- **Velocità**: Modificare il valore di `cmp #$02` dopo `inc frameDivider` per accelerare o rallentare l'animazione.
- **Ciclo Colori**: Modificare `flash_table` per cambiare la fluidità dell'illusione.
- **Posizioni**: Le tabelle `sprite_x` e `sprite_y` controllano la disposizione degli omini.

---
*Sviluppato come esperimento di grafica retro-coding su C64.*
