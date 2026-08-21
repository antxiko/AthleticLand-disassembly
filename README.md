# Athletic Land (Konami, 1984, MSX1) — a commented disassembly

Konami's first MSX cartridge, taken apart byte by byte. All 16,384 bytes are
bounded and owned: there is no unexplained gap, no "graphics blob", and no
guessed table.

📖 **[Full documentation](https://antxiko.github.io/AthleticLand-disassembly/)**

[README en castellano](README.es.md)

---

## What this is

*Athletic Land* is catalogue number RC-700, the first cartridge Konami put out
for the MSX. This repository holds its code, commented, along with the tools to
rebuild it and check that the result is the original.

The machine maps the 16 KB at 0x4000-0x7FFF —page 1—, the BIOS calls the entry
point at 0x4077, and from there the program never comes back: the startup
writes a `jp` into the H.KEYI hook and drops into a two-byte loop, so **the
whole game runs inside the interrupt**, one step per frame. If a step takes
longer than a frame, the next interrupt plays the music and leaves.

## Why this can be trusted

`make` traces the flow, builds the listing and demands that assembling it gives
back exactly the original:

```
  ensamblado : 16384 bytes  7bd280ae...81285485
  original   : 16384 bytes  7bd280ae...81285485
OK: reproducible byte a byte
```

A listing can reassemble perfectly and still be wrong —if drawings are read as
instructions, the bytes do not change—, so two more checks run alongside: no
range declared as data may come out as code, and no entry point may fall inside
one.

The graphics are checked a third way. `tools/graficos.py` rebuilds video memory
by replaying the cartridge's own copy calls, in the same order and to the same
addresses, and draws the result. If a range were mislabelled the picture would
come out as noise; instead the tiles, the sprites and the nine vine frames come
out as what they are.

## The numbers

| | |
|---|---|
| bytes of code | 7,448 |
| bytes of data | 8,936 |
| bytes unexplained | **0** |
| named labels | 296 |
| anchored comments | 1,103 |
| data ranges with an explanation | 166 |

## A few things that turned up

- **The game is a table of thirty-two screens, not a map.** Two bytes per
  screen at 0x5C32: one says which fixed obstacles are there (puddles, vines,
  trampolines, water jets, the five-post pond, the rock, the campfire, the
  pond), the other which moving ones (rolling balls, spiders, fish, the
  floating log, the bouncing ball, the bee). SCENE modulo 32 picks the pair,
  and the stage number then edits it.
- **Every screen whose number ends in 0, 4 or 8 comes out empty**, and the ones
  ending in 0 carry the CHILD PARK sign. A stage is ten screens: the goal is
  kept in BCD, and clearing stage 99 wraps it to 00 and prints ALL STAGE CLEAR
  with the credits.
- **One routine draws all the scenery**, and it takes its arguments from the
  six bytes that follow its own `call`: two pointers and a video address. It is
  called nineteen times, and four of those write the colour table instead of
  tiles.
- **A jump is a table of deltas read forwards and backwards.** The same
  sixteen-byte list, walked one way subtracting and the other way adding,
  is the rise and the fall; the bookend bytes 0xFE and 0xFF are what turn it
  around and what end it.
- **What kills you is not the height you fall to, but the height you fell
  from.** The code stores the altitude you jumped from and compares: landing
  sixteen points below it is fatal, wherever you are on the screen.
- **The vine is nine drawings**, not an animation: a pendulum in nine frames,
  each ending with the three bytes that say where its tip is, which is where
  your hands can be.
- **The credits are inside the cartridge**, in plain tiles: PROGRAM A.H Y.I,
  SOUND Y.O, CG R.S C.K. They only appear after stage 99.

## Getting started

You need `pasmo`, `z80dasm` and Python 3. The cartridge is **not** distributed
here: put your copy in the root as `athletic.rom`, 16384 bytes, sha256
`7bd280ae4147a5bf5676b15fde310a8106887786c78873344d97a1cd81285485`.

```sh
make          # trace, build the listing and check everything
make verify   # assemble and compare with the cartridge
make sanity   # what reassembly cannot catch
```

## Licence and attribution

The game is not ours: *Athletic Land* belongs to Konami, and all rights remain
with their holders. What is ours —the tools, the comments and the
documentation— is published under the licence in `LICENSE`. The cartridge image
is not distributed. See [LEGAL-NOTICE.md](LEGAL-NOTICE.md).
