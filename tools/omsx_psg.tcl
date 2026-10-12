# omsx_psg.tcl - Lo que el juego escribe de verdad en el PSG, para cotejarlo
# con tools/musica.py (que ejecuta el mismo motor fuera del emulador).
#
# Apunta en $PSG_OUT/psg.txt, en orden:
#   F                 cada llamada al motor de cada cuadro ($PSG_FRAME)
#   S nn              cada llamada a "pedir sonido" ($PSG_PIDE): A
#   W r v             cada escritura al PSG (puerto 0xA0 el registro, 0xA1 el dato)
# $PSG_FRAME_BYTE y $PSG_PIDE_BYTE: el byte que debe haber en esas direcciones
# (para saber que el cartucho esta mapeado). $PSG_FUERZA: lista de numeros que
# sustituyen a la A de las primeras peticiones (para oir piezas sin jugar).
# $PSG_SIEMPRE: sustituye la A de TODAS las peticiones (una pieza entera, sin que otra la pise).
# Pulsa ESPACIO cada 3 s entre los 6 y los FIN-10 s; sale a los FIN s emulados.
set OUT $::env(PSG_OUT)
set FIN [expr {[info exists ::env(PSG_FIN)] ? $::env(PSG_FIN) : 120}]
set FRAME $::env(PSG_FRAME)
set PIDE $::env(PSG_PIDE)
set FB $::env(PSG_FRAME_BYTE)
set PB $::env(PSG_PIDE_BYTE)
set ::fuerza [expr {[info exists ::env(PSG_FUERZA)] ? $::env(PSG_FUERZA) : ""}]
file mkdir $OUT
set ::log {}
set ::reg 0
debug set_watchpoint write_io 0xA0 {} { set ::reg [expr {$::wp_last_value & 0x0F}] }
debug set_watchpoint write_io 0xA1 {} { lappend ::log "W $::reg $::wp_last_value" }
debug set_bp $FRAME "\[debug read memory $FRAME\] == $FB" { lappend ::log "F" }
debug set_bp $PIDE "\[debug read memory $PIDE\] == $PB" {
    if {[info exists ::env(PSG_SIEMPRE)] && $::env(PSG_SIEMPRE) ne ""} {
        reg a $::env(PSG_SIEMPRE)
    } elseif {[llength $::fuerza] > 0} {
        reg a [lindex $::fuerza 0]
        set ::fuerza [lrange $::fuerza 1 end]
    }
    lappend ::log "S [reg a]"
}
proc pulsa {} { keymatrixdown 8 0x01; after time 0.15 { keymatrixup 8 0x01 } }
for {set t 6} {$t < [expr {$FIN - 10}]} {incr t 3} { after time $t pulsa }
proc acaba {} {
    set f [open [file join $::OUT psg.txt] w]
    puts $f [join $::log "\n"]
    close $f
    exit
}
after time $FIN acaba
