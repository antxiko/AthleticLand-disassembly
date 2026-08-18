# Findings

What turned up when the cartridge was taken apart, with the evidence next to
it. What is not settled is in [Open questions](OPEN-QUESTIONS.html).

## What kills you is not the height you fall to: it is the height you fell from

There is no fall damage and no minimum height anywhere. What there is, is one
byte: 0xE13A, written **at the moment you press the button** (0x6DAA).

Normally it is the Y you jumped from plus sixteen —sixteen points lower on the
screen, which from the ground is just the ground—. But if you jump while
standing on one of the two middle water-jet planks, with X between 0x48 and
0x9F, it is that plank's height, with nothing added.

From then on, two checks compare against it. Walking, 0x6960 kills you if your
Y minus 0x11 has reached it; landing on a plank, 0x656C does the same with
0x10. So the very same landing is harmless or fatal depending on where the jump
started, and jumping off a high plank means the ground itself is a fatal
distance away.

## The world is sixty-four bytes

Not a map, not a generator: two tables of thirty-two bytes, at 0x5C32 and
0x5C52, indexed by **SCENE modulo 32**. One says which fixed obstacles the
screen is built with and the other which things move in it.

    5C32  03 82 20 04 88 00 01 20 41 10 C0 00 88 40 88 20
          01 04 50 80 50 40 10 20 10 82 00 05 41 88 01 50

    5C52  80 A0 08 08 08 0C 80 0C 10 08 60 08 00 80 18 02
          10 08 48 A0 40 C0 08 09 08 00 01 10 58 10 18 40

SCENE itself, at 0xE054, is a plain counter that goes up or down by one and, on
passing 255, drops back to **56** (0x43F2) —not to 0, and not to 1—. Going the
other way it sticks at 1 and turns you round. Beyond thirty-two screens the
park repeats; what does not repeat is the stage number, which edits the pair
before it is used.

## The vine is nine drawings, not an animation

There is no interpolation, no pendulum and no trigonometry. 0x555B is a table
of nine pointers, and each one is a small drawing: tile, tile, then 0xFE, 0xFD
or 0xFC to drop a row —one column left, the same, or one right— and 0xFF to
finish. That is the whole swing.

![The nine drawings of the vine](imagenes/liana.png)

The phase counter runs 0 to 15, and from 9 upwards it is negated and read
backwards (0x60D9), so nine drawings make a full swing out and back. Two vines
are drawn per screen, twelve columns apart, on two counters that tick at
different rates —every 8 and every 10 frames—, which is why they are never in
step.

And behind each drawing's 0xFF come **three more bytes**: the Y and the two X
of the tip. That is the only place the game knows where the rope ends, and it
is what your hands are checked against (0x6C3C).

## The vine is drawn across two tile banks, on purpose

In graphics mode 2 the screen is three thirds and each one has its own patterns.
The vine hangs from row 6 and reaches row 12, so it straddles the seam between
the first third and the middle one — and the cartridge loads its tiles
accordingly: the **top** of a vine is tiles 0xB0-0xB6, copied into the first
third (0x594C), and everything from row 8 down is tiles 0x60-0x9B, copied into
the middle one (0x5940). Neither set exists in the other bank.

That is not something playing shows you; it falls out of putting the loader's
addresses next to the drawings' tile numbers.

## The credits are inside the cartridge, in ordinary tiles

At 0x447E, in plain sight, the tile codes being the ASCII of the letters:

    ALL STAGE CLEAR
    PROGRAM  A.H  Y.I
    SOUND  Y.O
    CG  R.S  C.K

They are painted in one place only: 0x445B, when the stage counter wraps from
99 back to 00. The layout list in front of them (0x4468) is six entries long —a
rule of 18 tiles on row 5, the ALL STAGE CLEAR on row 6, another rule on row 7,
and the three credit lines on rows 16, 17 and 18—.

No full names: initials only, and nothing else in the cartridge is signed
except the KONAMI 1984 on the title screen and at the foot of the scoreboard.

## Two bytes that are a note and a pointer at the same time

The sound player has a table of note periods at 0x7960 —ten bytes— and, right
after it, a table of 34 track pointers at 0x796A. The two overlap by design:
the eleventh and twelfth notes, periods 60 and 56, are the bytes `3C 38`, and
those same two bytes are **entry 0 of the pointer table**, reading as the
address 0x383C.

Entry 0 is never asked for —sound numbers start at 1— so nothing is broken by
it. It saves two bytes.

## A sound that is one byte long

Sound 6 is asked for every time the bee leaves the screen and every time you
leave a screen, and all it does is shut the effects channel up: it is the only
way to stop the bee's buzz, which loops on a 0xFE.

Its track is the single byte 0xFF at **0x79DB** — which is not a track at all:
it is the 0xFF that ends the fanfare's channel A. Nine of the 34 entries in the
table point at that one byte: sound 6, and the unused channels of every
three-channel sound.

## The plank carries its own height

The eighteen blocks of the water jet (0x5701) are nineteen bytes each: 6×3
tiles of drawing, and then one byte that is not drawn at all — the height at
which the plank ends up, from 0x52 at the bottom to 0x32 at the top, two at a
time.

0x60B7 draws the block and returns that byte, and 0x604B stores the four of
them in 0xE148-0xE14B. When the player lands, 0x650E compares his Y against
those four numbers. The picture and the physics come out of the same nineteen
bytes, so they cannot drift apart.

## The title logo is revealed one column at a time

The ATHLETIC LAND logo is not a picture that gets uploaded. It is 34 tiles,
0x40 to 0x61, unpacked once by the run-length decompressor, and then 0x47CB is
called once per frame and each call places **one column**: two tiles, on rows 5
and 6, at column 8 plus however many columns have already gone in.

![The title logo, rebuilt from the cartridge](imagenes/logo.png)

Seventeen calls draw the logo, and the counter keeps going to 52: the calls
after the seventeenth paint the KONAMI 1984 underneath and then say there is
nothing left.

## What was left over inside the cartridge

Things that are there and go unused. None is a guess; each was looked for.

- **Six null entries** in the player's state table (0x66C2). States 9 to 14 are
  `0000`, and jumping there would restart the machine. No instruction writes a
  9 to 14 into 0xE138.
- **Five bytes of code nobody calls**, at 0x4523: it would put A into video chip
  register 7 —the border— and resend all eight registers. It sits immediately
  before the routine that does the same thing without touching the border, and
  is reached by nothing.
- **Six bytes** at 0x77F8, between the last tile pattern and the sound code.
- **962 bytes of 0xFF** from 0x7C3E to the end: the padding up to 16 KB, and
  0xFF rather than 0x00.
