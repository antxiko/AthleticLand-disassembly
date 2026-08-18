# Arranca el cartucho, conduce el juego a ciegas y muestrea el PC.
#
# Cada PC visto es una instruccion que corrio de verdad; las que caen fuera
# del trazado (tools/cruza_muestreo.py) son semillas con la mejor
# justificacion posible. Teclas por la matriz del MSX: fila 8 = SPC 0x01,
# LEFT 0x10, UP 0x20, DOWN 0x40, RIGHT 0x80. Se MANTIENEN pulsadas un rato.
# Guarda tambien la RAM, capturas y un estado (store_machine) al final.
#
#   ATH_OUT=<dir C:/...> ATH_SEG=<s> ATH_NOMBRE=<n> [ATH_SEMILLA=n] \
#     openmsx -machine Philips_VG_8020 -cart athletic.rom -script tools/omsx_conduce.tcl
set OUT $::env(ATH_OUT)
set SEG [expr {[info exists ::env(ATH_SEG)] ? $::env(ATH_SEG) : 120}]
set NOMBRE [expr {[info exists ::env(ATH_NOMBRE)] ? $::env(ATH_NOMBRE) : "c1"}]
if {[info exists ::env(ATH_SEMILLA)]} { expr {srand($::env(ATH_SEMILLA))} } else { expr {srand(1)} }
file mkdir $OUT
set LOG [open "$OUT/$NOMBRE.log" w]
proc say {m} { global LOG; puts $LOG "\[[format %8.2f [machine_info time]]\] $m"; flush $LOG }
set renderer SDLGL-PP
set throttle off
set pcs [dict create]
set N 0
proc muestra {} { global pcs N; dict incr pcs [reg PC]; incr N; after time 0.0005 muestra }
after time 0.5 muestra
set ints 0
debug set_bp 0x4038 {} { incr ints }
proc pulsa {fila masc dur} { keymatrixdown $fila $masc; after time $dur [list keymatrixup $fila $masc] }
set DIRS {0x10 0x80 0x20 0x40}
proc paso {} {
    global DIRS
    set r [expr {rand()}]
    if {$r < 0.55} {
        set m [lindex $DIRS [expr {int(rand()*4)}]]
        set d [expr {0.1 + rand()*1.2}]
        pulsa 8 $m $d
        after time [expr {$d + 0.05}] paso
    } elseif {$r < 0.9} {
        pulsa 8 0x01 0.25
        after time 0.5 paso
    } else { after time 0.8 paso }
}
after time 3 { pulsa 8 0x01 0.3 }
after time 5 { paso }
set nfoto 0
proc foto {} { global OUT NOMBRE nfoto; incr nfoto; catch {screenshot [format "%s/%s_%02d.png" $OUT $NOMBRE $nfoto]} }
after time 2 { set throttle on; after realtime 1.5 { foto; set throttle off } }
after time 40 { set throttle on; after realtime 1.5 { foto; set throttle off } }
after time $SEG {
    global pcs N ints OUT NOMBRE
    set f [open "$OUT/$NOMBRE.pcs" w]
    dict for {pc n} $pcs { puts $f [format "%04X %d" $pc $n] }
    close $f
    set f [open "$OUT/$NOMBRE.ram.bin" w]; fconfigure $f -translation binary
    puts -nonewline $f [debug read_block memory 0 0x10000]; close $f
    catch {store_machine [machine] "$OUT/$NOMBRE.oms"}
    say "muestras=$N PCs=[dict size $pcs] interrupciones=$ints"
    say "FIN"; exit 0
}
