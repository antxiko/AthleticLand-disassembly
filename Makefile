# Athletic Land (Konami, 1984, MSX1) - desensamblado
#
# El orden de las cosas: trazar el flujo -> generar el listado -> comprobar que
# vuelve a dar la ROM byte a byte -> las comprobaciones que el reensamblado NO
# cubre.
#
# La ROM no se distribuye. Hace falta en la raiz como athletic.rom, y
# `make comprueba` verifica el sha256.

ROM      = athletic.rom
SHA      = 7bd280ae4147a5bf5676b15fde310a8106887786c78873344d97a1cd81285485
SRC      = src
WORK     = work
ORG      = 0x4000
TITULO   = ATHLETIC LAND - Konami (1984) - MSX1 - cartucho RC-700 de 16 KB en la pagina 1

# Las capturas del emulador. No las hace `make`: las hace openMSX con el
# cartucho puesto (ver la regla `capturas`), y de ahi salen tanto el mapa del
# mundo como el rotulo y la galeria de la portada.
OMSX     = $(WORK)/omsx

all: listado verify sanity test

$(ROM):
	@echo "=================================================================="
	@echo " Falta $(ROM), y este repositorio NO lo distribuye."
	@echo ""
	@echo " Es Athletic Land (Konami, RC-700, 1984) para MSX, 16384 bytes exactos."
	@echo " Ponlo aqui con ese nombre. Para comprobar que es el mismo:"
	@echo "     shasum -a 256 $(ROM)"
	@echo "     $(SHA)"
	@echo ""
	@echo " Sin el se puede leer el listado ya generado en $(SRC)/, y los"
	@echo " tests que no dependen del binario siguen pasando."
	@echo "=================================================================="
	@false

comprueba: $(ROM)
	@echo "$(SHA)  $(ROM)" | shasum -a 256 -c -

# El trazado sigue el flujo desde los puntos de entrada. Los que no se pueden
# deducir estaticamente -ganchos de interrupcion, destinos de saltos
# indirectos- estan declarados en el .entries, cada uno con su justificacion.
$(WORK)/athletic.trace.json: $(ROM) $(SRC)/athletic.entries $(SRC)/athletic.nocode
	@mkdir -p $(WORK)
	python3 tools/z80trace.py $(ROM) $(ORG) $(SRC)/athletic.entries \
	        $(WORK)/athletic $(SRC)/athletic.nocode

trace: $(WORK)/athletic.trace.json

listado: $(WORK)/athletic.trace.json $(SRC)/athletic.notes
	python3 tools/mkasm.py $(ROM) $(ORG) $(WORK)/athletic.trace.json \
	        $(SRC)/athletic.notes work/msx.sym $(SRC)/athletic.asm "$(TITULO)"

# La prueba que decide si el desensamblado es fiable.
verify: $(SRC)/athletic.asm $(ROM)
	@sh tools/verify_build.sh $(SRC)/athletic.asm $(ROM) $(ORG)

# Lo que el reensamblado NO puede cazar: que unos datos se esten leyendo como
# codigo. El binario sale identico igual, porque los bytes no cambian; lo unico
# que cambia es lo que decimos de ellos.
sanity: $(WORK)/athletic.trace.json
	@echo "=================================================================="
	@echo " ningun byte declarado como datos puede salir como codigo"
	@echo "=================================================================="
	@python3 tools/check_trace.py $(WORK)/athletic.trace.json $(SRC)/athletic.nocode
	@python3 tools/check_datos_como_codigo.py $(WORK) $(SRC)
	@echo "=================================================================="
	@echo " ningun punto de entrada puede caer dentro de una zona de datos"
	@echo "=================================================================="
	@python3 tools/check_entradas.py $(SRC)/athletic.entries $(SRC)/athletic.notes \
	        $(SRC)/athletic.nocode
	@echo "=================================================================="
	@echo " ni un byte del cartucho sin asignar"
	@echo "=================================================================="
	@python3 tools/presupuesto.py $(WORK) $(SRC)

test:
	@echo "=================================================================="
	@echo " Tests"
	@echo "=================================================================="
	@python3 -m unittest discover -s tests -v

clean:
	rm -rf $(WORK)/athletic.trace.json $(WORK)/athletic.map $(WORK)/png

.PHONY: all comprueba trace listado verify sanity test clean capturas imagenes web

# ---------------------------------------------------------------------------
# La web
# ---------------------------------------------------------------------------
# Las capturas son el unico material que no sale de leer el binario: las hace
# el propio cartucho corriendo. Se piden una vez y se quedan en work/, que no
# se versiona.
capturas:
	@echo "=================================================================="
	@echo " Las capturas las hace openMSX con el cartucho puesto:"
	@echo "     openmsx -machine C-BIOS_MSX1_EU -cart $(ROM) \\"
	@echo "             -script tools/omsx_arranque.tcl"
	@echo "     openmsx -machine C-BIOS_MSX1_EU -cart $(ROM) \\"
	@echo "             -script tools/omsx_mapa_lfsr.tcl"
	@echo ""
	@echo " La primera deja $(OMSX)/arranque.png -la presentacion, que es el"
	@echo " rotulo de la portada- y la segunda las 255 de $(OMSX)/mapa/,"
	@echo " una por escena, dictandole al LFSR de 0xE222 cual montar."
	@echo "=================================================================="

$(OMSX)/mapa:
	@echo "Faltan las capturas de las escenas. Hazlas con: make capturas"
	@false

# Las imagenes grandes de la web: el mapa del mundo etiquetado y el guion de
# la partida perfecta. El orden importa -las escaleras se MIDEN sobre el mapa
# ya montado, y la ruta necesita las escaleras-, asi que es una cadena.
imagenes: $(ROM) $(OMSX)/mapa
	@mkdir -p docs/imagenes $(WORK)
	python3 tools/mapa_escenas.py $(ROM) $(WORK)/mapa_escenas.tsv | tail -3
	python3 tools/monta_mapa_guion.py $(OMSX)/mapa $(WORK)/mapa_escenas.tsv \
	        docs/imagenes/mapa-del-mundo.png | tail -1
	python3 tools/busca_escaleras.py docs/imagenes/mapa-del-mundo.png \
	        $(WORK)/mapa_escenas.tsv $(WORK)/escaleras.tsv | tail -3
	python3 tools/ruta_optima.py $(WORK)/mapa_escenas.tsv $(WORK)/escaleras.tsv \
	        $(WORK)/ruta_optima.tsv | tail -4
	python3 tools/dibuja_guion.py docs/imagenes/mapa-del-mundo.png \
	        $(WORK)/ruta_optima.tsv docs/imagenes/guion-de-la-partida-perfecta.png | tail -1
	@# La liana no necesita capturas: se traza desde el cartucho, igual que la
	@# traza el juego. 33 fases, todas superpuestas.
	python3 tools/render_liana.py $(ROM) docs/imagenes/liana.png 6 abanico | head -2
	@# La tira del protagonista sale de la VRAM volcada, que la deja
	@# tools/omsx_arranque.tcl junto con la captura del rotulo. Se ve en la
	@# pagina de EL-CODIGO / THE-CODE; la portada no la usa.
	@if [ -f $(OMSX)/demo.vram.bin ]; then \
	    python3 tools/render_jugador.py $(OMSX)/demo.vram.bin docs/imagenes/jugador-tira.png 4 | head -1; \
	 else \
	    echo "  (sin $(OMSX)/demo.vram.bin: no se regenera la tira del protagonista)"; \
	 fi

web: imagenes
	python3 tools/md2html.py docs en
	python3 tools/md2html.py docs/es es
	python3 tools/make_web.py $(OMSX) $(WORK)/mapa_escenas.tsv docs/imagenes \
	        docs/index.html en
	python3 tools/make_web.py $(OMSX) $(WORK)/mapa_escenas.tsv docs/imagenes \
	        docs/es/index.html es
	@touch docs/.nojekyll
	@python3 tools/check_enlaces.py docs
