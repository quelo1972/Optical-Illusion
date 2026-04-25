ASM := 64tass
EMU := x64sc
SRC := demo.asm
PRG := illusion.prg

.PHONY: all run clean

all: $(PRG)

$(PRG): $(SRC)
	$(ASM) --cbm-prg -o $(PRG) $(SRC)

run: $(PRG)
	$(EMU) -autostart $(PRG)

clean:
	rm -f $(PRG)
