# Getting started

## What you need

`pasmo` and `z80dasm` to assemble and disassemble, and Python 3 for the tools.
No other dependencies.

The cartridge is not distributed with this repository: you need your own copy,
named `athletic.rom` in the project root. It is exactly 16384 bytes with this
sha256:

    7bd280ae4147a5bf5676b15fde310a8106887786c78873344d97a1cd81285485

With any other dump the listing will not reassemble. `make comprueba` tells you
in one line.

## The commands

```sh
make          # trace, build the listing and check everything
make verify   # assemble the listing and compare its sha256 with the cartridge
make sanity   # what reassembly cannot catch
make test     # the 17 tests over the listing, no cartridge needed
make web      # the images and these pages
```

`make` fails if the listing stops reproducing the cartridge byte for byte, if
the tracer walks into an area declared as data, if an entry point falls inside
one, or if a single byte of the 16384 is left unaccounted for.

## The proof that decides

A disassembly is trustworthy if assembling it gives back the original. That is
`make verify`:

    ensamblado : 16384 bytes  7bd280ae...81285485
    original   : 16384 bytes  7bd280ae...81285485
    OK: reproducible byte a byte

## The second proof

A listing can reassemble perfectly and still be wrong: if drawings are being
read as instructions, the bytes do not change —only what is said about them
does—. `make sanity` crosses the data ranges against the trace and ends with
the split:

      codigo trazado              7448   45.46 %
      datos identificados         8936   54.54 %
      sin explicar                   0    0.00 %
      ==========================================
      explicado                  16384  100.00 %

## The third proof, for the graphics

Neither of those two can catch a tile table read one byte out of step: the
bytes still assemble and the range is still declared. So the graphics are
checked by drawing them. `tools/graficos.py` rebuilds video memory by replaying
the cartridge's own copy calls —same order, same addresses, mirrors and colour
substitutions included— and `tools/imagenes_web.py` then repeats the specific
calls that paint each thing. Every picture on this site comes out of that: the
title logo, the scenery, the nine vine drawings, the eighteen water-jet blocks,
the tile set and the sprites. A mislabelled range comes out as noise.

## Without the cartridge

The work is in `src/athletic.asm` and the notes: 6,882 lines with 296 routines
and tables named, 348 line comments anchored to their address and 166 ranges of
data with their explanation next to them. The 17 tests run without the binary.

## How it is organised

The listing is **never edited by hand**: it is generated, governed by three
files.

| | |
|---|---|
| `src/athletic.entries` | the entry points: where tracing starts |
| `src/athletic.nocode` | the areas that are NOT code, and how that is known |
| `src/athletic.notes` | the names, the comments and the data ranges |

From those, `src/athletic.asm`. Every note is anchored to its address, so it
survives a retrace.

The `.entries` file holds 48 entry points because the cartridge declares **one
single entry point** —the BIOS reads the header and calls 0x4077— and
everything else arrives by paths no static tracer can follow: the interrupt
hook (0x4038), which is where the whole game runs, and the five dispatch tables
that the routine at 0x40A9 reads from behind its own `call`, declared one by
one with the instruction that reaches them noted alongside.

It also carries a directive of its own, `!skip 0x5F65 6`: the scenery engine
takes six bytes of parameters that sit **after** its `call`, so the tracer has
to step over them instead of executing them. Those 19 blocks of six bytes come
out of the trace as data, and each one is declared in the notes.

The `.nocode` file is short —5 ranges— and holds the five dispatch tables,
which the tracer would otherwise walk straight into.

### How the data blocks are laid out

Every data range declared in the `.notes` comes out as a block of its own: its
own heading saying what it is for, its own label, and the dump aligned to its
first byte, so where one table ends and the next begins is visible at a glance.
An optional line gives the block the row width of its real structure, and that
is what makes the tables readable in the listing itself:

| | |
|---|---|
| `F 0x48CE 8` | the 48 font glyphs, one glyph per row |
| `F 0x7608 8` | the tile patterns, one pattern per row |
| `F 0x6B8A 4` | the fourteen player poses, the four sprite patterns of each on its row |
| `F 0x6C06 5` | the death poses, five patterns each |
| `F 0x5AAF 4` | sprite attributes, one record —Y, X, pattern, colour— per row |
| `F 0x5701 19` | the eighteen water-jet blocks: 6×3 tiles and the plank's height, one block per row |
| `F 0x700D 6` and `F 0x707C 3` | tile blocks laid out at their true width, six and three columns |
| `F 0x5E54 3,1` | the three tiles of the rock on the first row and the 0xFF end marker on its own |
| `F 0x4149 w1` | a table of pointers as `defw`, one per row |
| `F 0x445E w3` | the six parameter bytes of a scenery call: three words, which is what they are |

Where a pointer lands on a block that has a name, that name is written next to
it: the twenty entries of the state table come out reading
`-> ESTADO_00_ARRANCA`, `-> ESTADO_01_LOGO` and so on, and the six that are
0x0000 are visible for what they are.

## The tools

In `tools/`, each with its own header:

| | |
|---|---|
| `z80trace.py` | follows the flow from the entry points, stepping over inline parameters |
| `mkasm.py` | builds the listing with the notes anchored |
| `presupuesto.py` | the split of the 16384 bytes, and what is left unowned |
| `refs.py` | which instructions point into a range, without inventing pointers |
| `quien_apunta.py` | for each gap, who reads it from traced code |
| `graficos.py` | rebuilds video memory the way the cartridge loads it, and draws it |
| `imagenes_web.py` | the pictures on this site, each one a routine replayed |
| `check_datos_como_codigo.py` | no declared data range may come out as code |
| `check_entradas.py` | no entry point may fall inside one |
| `omsx_*.tcl` | the openMSX harnesses used to measure who reads what |
