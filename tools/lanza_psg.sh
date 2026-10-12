#!/bin/sh
# lanza_psg.sh [dir] [segundos] [numero que sustituye a todas las peticiones]: UN openMSX con tools/omsx_psg.tcl (cotejo del
# PSG). Lo medido queda en work/<dir>/psg.txt. Los datos del juego, de `musica.py emu`.
R=$(cd "$(dirname "$0")/.." && pwd)
d=$R/work/${1:-psg}
mkdir -p $d
cd $R
PY=/c/Users/Antxiko/AppData/Local/Programs/Python/Python313/python.exe
eval "$($PY tools/musica.py emu)"
PSG_OUT="$d" PSG_FIN=${2:-120} PSG_SIEMPRE="$3" "/c/Program Files/openMSX/openmsx.exe" -machine $EMU_MAQUINA -cart $EMU_ROM $EMU_TIPO -script tools/omsx_psg.tcl > $d/stdout.txt 2>&1
echo hecho > $d/fin.txt
