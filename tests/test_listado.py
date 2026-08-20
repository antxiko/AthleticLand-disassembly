#!/usr/bin/env python3
"""Comprobaciones sobre el listado generado.

Ninguna de estas necesita el cartucho: se hacen sobre src/athletic.asm y
src/athletic.notes, que van en el repositorio. Lo que vigilan es que el listado
no se degrade sin que nadie se entere: que no desaparezcan comentarios, que no
vuelvan a aparecer bloques de datos sin identificar, y que las cifras que se
publican sean las del arbol.
"""
import os
import re
import unittest

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ASM = os.path.join(RAIZ, "src", "athletic.asm")
NOTES = os.path.join(RAIZ, "src", "athletic.notes")

ORG, FIN = 0x4000, 0x8000


def asm():
    with open(ASM, encoding="utf-8") as f:
        return f.read()


def notas():
    with open(NOTES, encoding="utf-8") as f:
        return f.read().splitlines()


def directivas(clave):
    return [l for l in notas() if l.startswith(clave + " ")]


class TestListado(unittest.TestCase):

    def test_ningun_bloque_de_datos_sin_identificar(self):
        """Cada zona de datos tiene que tener nombre y explicacion."""
        n = asm().count("DATOS sin identificar")
        self.assertEqual(n, 0, "hay %d bloques de datos sin identificar" % n)

    def test_todas_las_rutinas_con_call_tienen_nombre(self):
        """Si algo se llama con CALL es una rutina, y una rutina se bautiza."""
        texto = asm()
        sueltas = sorted(set(re.findall(
            r"\bcall (?:n?[zc],|p[oe],|[mp],)?(L_[0-9A-F]{4})", texto)))
        self.assertEqual(sueltas, [], "rutinas llamadas y sin nombre: %s"
                         % " ".join(sueltas[:12]))

    def test_las_etiquetas_sin_nombre_no_aumentan(self):
        """Las L_XXXX que quedan son destinos de salto DENTRO de una rutina.

        No hay ninguna llamada con CALL (eso lo vigila el test de arriba), pero
        siguen sin bautizar. Esta cifra solo puede bajar: si sube, es que se ha
        retrazado algo y se han perdido nombres por el camino.
        """
        sueltas = set(re.findall(r"\bL_[0-9A-F]{4}\b", asm()))
        self.assertLessEqual(len(sueltas), 199,
                             "han aparecido etiquetas sin nombre nuevas")

    def test_ninguna_etiqueta_declarada_dos_veces(self):
        """Dos etiquetas con el mismo nombre y el ensamblador se queja."""
        nombres = re.findall(r"^([A-Za-z_][\w]*):", asm(), re.M)
        repetidas = sorted({n for n in nombres if nombres.count(n) > 1})
        self.assertEqual(repetidas, [], "etiquetas repetidas: %s"
                         % " ".join(repetidas))

    def test_ninguna_direccion_bautizada_dos_veces(self):
        """Dos L para la misma direccion: una de las dos se pierde en silencio."""
        dirs = [l.split()[1] for l in directivas("L")]
        repes = sorted({d for d in dirs if dirs.count(d) > 1})
        self.assertEqual(repes, [], "direcciones con dos nombres: %s"
                         % " ".join(repes))

    def test_todos_los_comentarios_llegan_al_listado(self):
        """Un comentario anclado a una direccion que ya no existe se pierde."""
        texto = asm()
        vivas = set(re.findall(r";([0-9a-f]{4})(?:\s|$)", texto, re.M))
        perdidos = [l.split()[1] for l in directivas("C")
                    if l.split()[1][2:].lower() not in vivas]
        self.assertEqual(perdidos, [], "comentarios que no llegan: %s"
                         % " ".join(perdidos[:12]))

    def test_todas_las_cabeceras_llegan_al_listado(self):
        """Igual con las cabeceras de bloque."""
        texto = asm()
        vivas = set(re.findall(r";([0-9a-f]{4})(?:\s|$)", texto, re.M))
        perdidas = sorted({l.split()[1] for l in directivas("B")
                           if l.split()[1][2:].lower() not in vivas})
        self.assertEqual(perdidas, [], "cabeceras que no llegan: %s"
                         % " ".join(perdidas[:12]))

    def test_todas_las_etiquetas_llegan_al_listado(self):
        """Una L cuyo nombre no aparece definido en el .asm es una L perdida."""
        texto = asm()
        perdidas = [n for _, n in
                    ((l.split()[1], l.split()[2]) for l in directivas("L"))
                    if not re.search(r"^%s:" % re.escape(n), texto, re.M)]
        self.assertEqual(perdidas, [], "etiquetas que no llegan: %s"
                         % " ".join(perdidas[:12]))

    def test_los_rangos_no_se_solapan(self):
        """Dos D que pisan los mismos bytes: uno de los dos esta mal."""
        rangos = sorted((int(l.split()[1], 16), int(l.split()[2], 16),
                         l.split()[3]) for l in directivas("D"))
        for (a1, b1, n1), (a2, b2, n2) in zip(rangos, rangos[1:]):
            self.assertLessEqual(b1, a2, "%s (%04X-%04X) pisa a %s (%04X-%04X)"
                                 % (n1, a1, b1, n2, a2, b2))

    def test_todos_los_rangos_van_al_derecho_y_dentro(self):
        """Un rango acaba despues de empezar, y cae dentro del cartucho."""
        for l in directivas("D"):
            a, b, nombre = int(l.split()[1], 16), int(l.split()[2], 16), l.split()[3]
            self.assertLess(a, b, "%s va del reves" % nombre)
            self.assertGreaterEqual(a, ORG, "%s empieza fuera" % nombre)
            self.assertLessEqual(b, FIN, "%s acaba fuera" % nombre)

    def test_todos_los_rangos_estan_explicados(self):
        """Un nombre no basta: cada D lleva su explicacion detras."""
        pelados = [l.split()[3] for l in directivas("D") if len(l.split()) < 5]
        self.assertEqual(pelados, [], "rangos sin explicacion: %s"
                         % " ".join(pelados))

    def test_el_listado_lo_genera_la_herramienta(self):
        """El .asm no se edita a mano: sale de mkasm.py."""
        self.assertIn("Generado por tools/mkasm.py", asm())

    def test_no_queda_nada_por_repartir(self):
        """Mientras haya un 'formato pendiente' el trabajo no esta hecho."""
        pendientes = [l for l in notas()
                      if "formato pendiente" in l or "reparto por" in l]
        self.assertEqual(pendientes, [], "quedan %d zonas por repartir"
                         % len(pendientes))

    def test_el_listado_no_habla_de_otro_juego(self):
        """Los comentarios prestados de otro desensamblado se cuelan solos."""
        otros = ("Pitfall", "Antarctic", "Temptations", "Stardust", "Ale Hop",
                 "Colt 36", "Middle Earth")
        for juego in otros:
            self.assertNotIn(juego, asm(), "el listado nombra %s" % juego)

    def test_la_raiz_no_habla_de_otro_juego(self):
        """Ni el README ni el aviso legal."""
        otros = ("Pitfall", "Antarctic", "Temptations", "Stardust", "Ale Hop")
        for fichero in ("README.md", "README.es.md", "AVISO-LEGAL.md",
                        "LEGAL-NOTICE.md", "LICENSE"):
            ruta = os.path.join(RAIZ, fichero)
            if not os.path.exists(ruta):
                continue
            with open(ruta, encoding="utf-8") as f:
                texto = f.read()
            for juego in otros:
                self.assertNotIn(juego, texto, "%s nombra %s" % (fichero, juego))

    def test_las_cifras_publicadas_son_las_del_arbol(self):
        """Las cifras de los README se cuentan aqui: si cambian, saltan."""
        cuentas = {
            "etiquetas": len(directivas("L")),
            "comentarios": len(directivas("C")),
            "rangos": len(directivas("D")),
        }
        esperado = {"etiquetas": 296, "comentarios": 840, "rangos": 166}
        self.assertEqual(cuentas, esperado,
                         "las cifras del arbol han cambiado: hay que "
                         "actualizar README.md y README.es.md")

    def test_cada_cifra_se_publica_en_los_dos_readme(self):
        """Y estan escritas en los dos idiomas, sin que se olvide uno."""
        for fichero, sep in (("README.md", ","), ("README.es.md", ".")):
            with open(os.path.join(RAIZ, fichero), encoding="utf-8") as f:
                texto = f.read()
            for cifra in ("7%s448" % sep, "8%s936" % sep, "296", "840", "166"):
                self.assertIn(cifra, texto, "%s no publica %s" % (fichero, cifra))


if __name__ == "__main__":
    unittest.main()
