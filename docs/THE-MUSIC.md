# The music

Everything you hear here comes from running the cartridge's own sound engine (`SUENA`, 0x785D, and `SONIDO`, 0x77FE, which hands it the three channels; the interrupt calls it at 0x4041) on an emulated Z80, frame by frame at 60 per second, just as the game calls it. What the engine writes to the PSG is turned into sound with an AY-3-8910 (`tools/musica.py`). Each MP3 is the whole piece up to where it starts again, plus 8 seconds of the repeat fading out; those that do not repeat end where the engine ends.

## Checked against openMSX

The PSG writes have been compared frame by frame with those of openMSX (C-BIOS MSX1 japonés). In every frame the PSG ends up the same:

- the start tune (0x8E), whole, 1,292 frames and its repeat;
- the fanfare (0x9C), whole, 194 frames.

The timbre is not checked: it is a textbook AY-3-8910, not a recording of the emulator. The probes are `tools/omsx_psg.tcl` and `tools/coteja_psg.py`.

## How a piece is asked for

`SONIDO` takes the number in A. From 0x8E up it is music (0x8E uses two channels, 0x90 and up three); below that it is an effect, which uses channel C only. Each channel has ten bytes at 0xE010, 0xE01A and 0xE024, and the engine reads one note per event from the track. In the 0x9C fanfare the last openMSX frame differs only because the game asks for it again as soon as it ends.

## The tunes

**The start** (0x8E)

Asked for by `ESTADO_10_ESPERA` when a screen starts; lasts 21.5 s and starts again at second 0.2.

<audio controls preload="none" src="audio/musica_8E.mp3"></audio>

**Death** (0x90)

Asked for by `MUERTE_CON_VIDAS`; lasts 2.0 s.

<audio controls preload="none" src="audio/musica_90.mp3"></audio>

**Game over** (0x93)

Asked for by `ESTADO_12_MUERTE` when no lives are left; lasts 5.0 s.

<audio controls preload="none" src="audio/musica_93.mp3"></audio>

**Hit** (0x96)

Asked for by `LE_HAN_DADO`; lasts 0.2 s.

<audio controls preload="none" src="audio/musica_96.mp3"></audio>

**Sinking** (0x99)

Asked for by `SE_HUNDE`; lasts 0.6 s.

<audio controls preload="none" src="audio/musica_99.mp3"></audio>

**The finish and menu fanfare** (0x9C)

Asked for by `MENU_CORTINILLA_BUCLE` and `META_ALCANZADA`; lasts 3.2 s.

<audio controls preload="none" src="audio/musica_9C.mp3"></audio>
