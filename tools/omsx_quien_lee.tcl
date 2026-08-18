# Quien LEE cada zona de datos del cartucho: puntos de observacion de lectura
# por rangos, y por cada rango los PC que leen de el con su cuenta. Se activan
# al llegar a INIT (0x4077): antes, la pagina 1 es la ROM del BASIC y sus PC
# no son del juego (A8=0xF0 en el arranque; pagado el 2026-08-17). Conduce a
# ciegas como omsx_conduce.tcl y muestrea el PC tambien (solo desde INIT).
#
#   ATH_OUT=<dir> ATH_SEG=<s> ATH_NOMBRE=<n> ATH_RANGOS="0x47FB-0x4B52;..." \
#     openmsx -machine Philips_VG_8020 -cart athletic.rom -script tools/omsx_quien_lee.tcl
set OUT $::env(ATH_OUT)
set SEG [expr {[info exists ::env(ATH_SEG)] ? $::env(ATH_SEG) : 120}]
set NOMBRE [expr {[info exists ::env(ATH_NOMBRE)] ? $::env(ATH_NOMBRE) : "lee1"}]
if {[info exists ::env(ATH_SEMILLA)]} { expr {srand($::env(ATH_SEMILLA))} } else { expr {srand(2)} }
file mkdir $OUT
set LOG [open "$OUT/$NOMBRE.log" w]
proc say {m} { global LOG; puts $LOG "\[[format %8.2f [machine_info time]]\] $m"; flush $LOG }
set throttle off
set RANGOS [list]
set i 0
foreach par [split $::env(ATH_RANGOS) ";"] {
    lassign [split $par "-"] a b
    lappend RANGOS [list $i [expr $a] [expr $b]]
    set ::lee($i) [dict create]
    incr i
}
set pcs [dict create]
proc muestra {} { global pcs; dict incr pcs [reg PC]; after time 0.0005 muestra }
set ::armado 0
debug set_bp 0x4077 {} {
    if {!$::armado} {
        set ::armado 1
        foreach r $::RANGOS {
            lassign $r i a b
            debug set_watchpoint read_mem [list $a [expr {$b - 1}]] {} [subst -nocommands {dict incr ::lee($i) [reg PC]}]
        }
        say "INIT: [llength $::RANGOS] rangos armados; muestreo en marcha"
        after time 0.5 muestra
    }
}
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
    } elseif {$r < 0.9} { pulsa 8 0x01 0.25; after time 0.5 paso } else { after time 0.8 paso }
}
after time 3 { pulsa 8 0x01 0.3 }
after time 5 { paso }
after time $SEG {
    global RANGOS OUT NOMBRE pcs
    set f [open "$OUT/$NOMBRE.lee" w]
    foreach r $RANGOS {
        lassign $r i a b
        puts $f [format "== rango 0x%04X-0x%04X" $a [expr {$b-1}]]
        dict for {pc n} $::lee($i) { puts $f [format "%04X %d" $pc $n] }
    }
    close $f
    set f [open "$OUT/$NOMBRE.pcs" w]
    dict for {pc n} $pcs { puts $f [format "%04X %d" $pc $n] }
    close $f
    say "FIN: PCs=[dict size $pcs]"; exit 0
}
