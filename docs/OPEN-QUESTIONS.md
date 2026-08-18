# Open questions

Every byte of the cartridge is accounted for, the listing gives back the
original byte for byte, and its 296 labels have names. That does not mean
everything is understood. This page says what the figures mean and what remains
unknown.

## 199 jump destinations still carry their address as a name

The listing has 296 named labels and 199 that are still `L_XXXX`. Those 199 are
**destinations of jumps inside a routine** —the far side of a `jr nz`, the tail
of a loop—, and none of them is the target of a `call`: there is a test that
fails if a routine reached by `call` is left unnamed.

So nothing is unidentified there; what is missing is a good name for each
branch. Anyone carrying on has a clear, mechanical job waiting.

## Six states that do not exist

The player's state table (0x66C2) has seventeen entries and six of them are
`0000`: states 9 to 14. Jumping there would run whatever sits at address zero
and restart the machine.

No traced instruction writes a 9 to 14 into 0xE138, and the states that do get
written are 0 to 8, 15 and 16. The reading that fits is that the table was left
with a gap so that 15 and 16 could keep their numbers, but **that is a reading,
not a measurement**: what is proven is that they are never used.

## Five bytes of code with no caller

0x4523 sets video chip register 7 —the border colour— from A and then resends
all eight registers. It is well formed, it is three instructions long, and
nothing in the cartridge reaches it: it was declared as an entry point by hand,
with that noted, because otherwise the tracer would never see it.

What it was for cannot be told from the binary.

## Some names come from the pictures, not from the code

The obstacles were named by rebuilding video memory and looking at the result
(`tools/graficos.py`), which is solid for shapes but not for intentions. The
round things with eight legs that drop from the top of the screen are called
spiders in this listing **because of what they look like**; the code only calls
them a sprite pattern.

The same caution applies to the top band of the screen: the listing's names for
its two halves are internal, and what the pictures show is a canopy of leaves
with a trunk on each side, in two shapes.

## The reconstruction has not been checked against a capture

Every picture on this site comes from replaying the cartridge's own copies and
draw calls. That catches a mislabelled range —it would come out as noise— but
it has not been compared pixel by pixel with a photograph of the running game.

Two things are known to be missing from it on purpose: the sprites come out
white on black, because an MSX1 sprite's colour is not in its pattern but in
the attribute record the game writes at run time; and the pictures are the
pieces the routines paint, not whole screens with their obstacles placed.

What the video chip is told, though, was measured: the eight registers were
read in the emulator with the game running, and they are the eight bytes at
0x4545.

## The other dump

There is a second dump of this game, a different build: sha256
`ed5b214fdf7272a509f0fcb0496550cf766fff3b2c39cfc9ba37609da8f3447e`, also 16384
bytes, which differs from this one in 14823 of them. It is **not** disassembled
here, and nothing on this site says anything about it.

## What backs each figure, and what does not

- **It reassembles byte for byte.** The published listing assembles and the
  sha256 is the cartridge's.
- **Not one byte unexplained.** The 16384 split into 7,448 of code reached by
  the tracer and 8,936 inside declared ranges, each with the instruction that
  reads it noted alongside.
- **No data area is read as code.** A separate check from reassembly, which
  cannot catch that: if drawings are read as instructions, the bytes do not
  change.
- **No entry point falls inside a data area.** Seeding the tracer with a wrongly
  deduced address would inflate coverage with no alarm.

What the 100 % does **not** mean: that the purpose of every byte is known. It
means every byte sits in a named range, and that name comes from reading the
instruction that consumes it. The cases in the sections above are the
exceptions, which is why they are written down.

The listing's comments are verified by sampling, not line by line.

## Four warnings for whoever carries on

**A period is not a speed.** The code says frames per tick —8, 9, 10, 11 for the
phases, 256 for a chunk of the clock—; how long that lasts depends on whether
the machine interrupts fifty or sixty times a second, and the two are easily
confused.

**Poking 0xE054 repaints nothing.** SCENE is only read when a screen is built,
and the only path that builds one is state 17 (0x43F9), through 0x5A64 and
0x5AE3. To walk the park in the emulator, let the game change screen on its
own.

**Sampling the program counter from power-on lies.** Before the BIOS maps the
cartridge, page 1 holds the BASIC ROM, and a sampler started too early reports
addresses inside this cartridge's range that are not this cartridge at all.
Arm anything you measure from INIT (0x4077) onwards, never from the reset.

**Brute-force pointer hunting lies.** A run of repeated bytes looks like a
pointer, and reading an operand from the middle of an instruction gives
plausible addresses that do not exist. Every lead from there is confirmed
against the listing; that is why this repository's tools walk instruction
starts only.
