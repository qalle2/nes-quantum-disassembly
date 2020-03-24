# nes-quantum-disassembly

An unofficial disassembly of the Nintendo Entertainment System (NES) demo *Quantum Disco Brothers* by wAMMA.

Notes:
* The CHR ROM (graphics data) is not included.
* This disassembly is at an early stage.
* I have not been involved with wAMMA or in the making of this demo.
* This project had an incorrect license for a short time by mistake.

## How to get the original files
* Download the original *Quantum Disco Brothers* file from e.g. [the scene.org file archive](http://files.scene.org/view/parties/2006/stream06/demo/quantum_disco_brothers_by_wamma.zip).
* If the file is compressed, extract it to get an iNES ROM file (`.nes`).
* The `.nes` file should be 65,552 bytes and have the MD5 hash `2c932e9e8ae7859517905e2539565a89`.
* Rename the `.nes` file to `quantum-original.nes`.
* Extract the PRG ROM data to `prg-original.bin` and the CHR ROM data to `chr.bin` from the `.nes` file. Use my [ines-split](http://github.com/qalle2/ines-split) or a general-purpose tool like a hex editor (the `.nes` file consists of a 16-byte iNES header, then the PRG ROM data and finally the CHR ROM data.)

## How to assemble
* Install [Ophis](http://michaelcmartin.github.io/Ophis/) (a 6502 assembler for Windows/Linux/Mac).
* Either run `assemble.bat` on Windows (also verifies the assembled files are identical to the original files) or assemble manually:
  * `ophis -v -o prg.bin prg.asm`
  * `prg.bin` should be identical to `prg-original.bin`
  * `ophis -v -o "quantum_(e).nes" quantum.asm` (`(e)` in the output filename causes FCEUX to correctly start the ROM in PAL mode)
  * `quantum_(e).nes` should be identical to `quantum-original.nes`

## The type of the iNES ROM file (from the header)
* mapper: CNROM (iNES mapper number 3)
* PRG ROM: 32 KiB (1 &times; 32 KiB)
* CHR ROM: 32 KiB (4 &times; 8 KiB)
* name table mirroring: horizontal
* no trainer
* no save RAM

## The parts of the demo
* Screenshots from FCEUX in PAL mode.
* Frame numbers: FCEUX's Frame Display in PAL mode.
* The internal part numbers are at RAM address `0x0001`.

![](shot/01.png)
1st part (internally part 0, starts at frame ~6): "GREETINGS! WE COME FROM..."

![](shot/02.png)
2nd part (internally part 2, starts at frame 1156): "wAMMA - QUANTUM DISCO BROTHERS"

![](shot/03.png)
3rd part (internally part 11, starts at frame 1923): red&purple gradients

![](shot/04.png)
4th part (internally part 1, starts at frame 2690): horizontal color bars

![](shot/05.png)
5th part (internally part 4, starts at frame 3458): a woman

![](shot/06.png)
6th part (internally part 5, starts at frame 4481): "IT IS FRIDAY..."

![](shot/07.png)
7th part (internally part 7, starts at frame 6362): Coca Cola cans

![](shot/08.png)
8th part (internally part 6, starts at frame 7304): Bowser's spaceship

![](shot/09.png)
9th part (internally part 3, starts at frame 8071): credits

![](shot/10.png)
10th part (internally part 10, starts at frame 9692): a checkered wavy animation

![](shot/11.png)
11th part (internally part 12, starts at frame 10380): "GREETS TO ALL NINTENDAWGS"

![](shot/12.png)
12th part (internally part 13, starts at frame 11298): "GAME OVER - CONTINUE?"

![](shot/13.png)
13th part (internally part 9, starts at frame 14018): more horizontal color bars

The demo should probably end at this point, as on [this YouTube video](https://www.youtube.com/watch?v=hhoa_K75BKI). However, on FCEUX, it starts to glitch from frame ~17603 on. I omitted the glitchy part from the Code/Data Logger file.

## FCEUX Code/Data Log - PRG ROM
I used my [cdl-summary](http://github.com/qalle2/cdl-summary) with the following arguments:

`python cdl_summary.py --prg-size 32 --part p --origin 32 --bank-size 32 quantum.cdl`

CPU address range, block length, description:
```
$8000-$8033 (  52): unaccessed
$8034-$8156 ( 291): code
$8157-$8158 (   2): unaccessed
$8159-$815c (   4): code
$815d-$815e (   2): unaccessed
$815f-$81ca ( 108): code
$81cb-$81cc (   2): unaccessed
$81cd-$823a ( 110): code
$823b-$8247 (  13): unaccessed
$8248-$8269 (  34): code
$826a-$8276 (  13): unaccessed
$8277-$8286 (  16): code
$8287-$8288 (   2): unaccessed
$8289-$828e (   6): code
$828f-$82d0 (  66): unaccessed
$82d1-$838d ( 189): code
$838e-$83b2 (  37): unaccessed
$83b3-$8413 (  97): code
$8414-$8416 (   3): unaccessed
$8417-$8432 (  28): code
$8433-$8435 (   3): unaccessed
$8436-$8477 (  66): code
$8478-$847a (   3): unaccessed
$847b-$8494 (  26): code
$8495-$8495 (   1): unaccessed
$8496-$84f7 (  98): code
$84f8-$850c (  21): unaccessed
$850d-$854d (  65): code
$854e-$855a (  13): unaccessed
$855b-$855d (   3): code
$855e-$85b0 (  83): unaccessed
$85b1-$862c ( 124): code
$862d-$8651 (  37): unaccessed
$8652-$8680 (  47): code
$8681-$86a1 (  33): unaccessed
$86a2-$8797 ( 246): code
$8798-$8799 (   2): unaccessed
$879a-$8905 ( 364): code
$8906-$8920 (  27): unaccessed
$8921-$8924 (   4): code
$8925-$892f (  11): unaccessed
$8930-$8932 (   3): code
$8933-$8933 (   1): unaccessed
$8934-$8938 (   5): code
$8939-$893a (   2): unaccessed
$893b-$8949 (  15): code
$894a-$895a (  17): unaccessed

$895b-$896a (  16): data
$896b-$896b (   1): unaccessed
$896c-$8973 (   8): data
$8974-$8974 (   1): unaccessed
$8975-$897b (   7): data
$897c-$897c (   1): unaccessed
$897d-$8985 (   9): data
$8986-$8986 (   1): unaccessed
$8987-$8987 (   1): data
$8988-$8996 (  15): unaccessed
$8997-$8997 (   1): data
$8998-$89a6 (  15): unaccessed
$89a7-$89a7 (   1): data
$89a8-$89b6 (  15): unaccessed
$89b7-$89b7 (   1): data
$89b8-$89c6 (  15): unaccessed
$89c7-$89c7 (   1): data
$89c8-$89d6 (  15): unaccessed
$89d7-$89d7 (   1): data
$89d8-$89e6 (  15): unaccessed
$89e7-$89e7 (   1): data
$89e8-$89f6 (  15): unaccessed
$89f7-$89f7 (   1): data
$89f8-$8a06 (  15): unaccessed
$8a07-$8a07 (   1): data
$8a08-$8a16 (  15): unaccessed
$8a17-$8a17 (   1): data
$8a18-$8a18 (   1): unaccessed
$8a19-$8a19 (   1): data
$8a1a-$8a26 (  13): unaccessed
$8a27-$8a27 (   1): data
$8a28-$8a36 (  15): unaccessed
$8a37-$8a37 (   1): data
$8a38-$8a46 (  15): unaccessed
$8a47-$8a47 (   1): data
$8a48-$8a56 (  15): unaccessed
$8a57-$8a57 (   1): data
$8a58-$8a65 (  14): unaccessed
$8a66-$8a67 (   2): data
$8a68-$8a76 (  15): unaccessed
$8a77-$8a77 (   1): data
$8a78-$8a88 (  17): unaccessed
$8a89-$8a89 (   1): data
$8a8a-$8a8b (   2): unaccessed
$8a8c-$8a8d (   2): data
$8a8e-$8a8f (   2): unaccessed
$8a90-$8a92 (   3): data
$8a93-$8a93 (   1): unaccessed
$8a94-$8a97 (   4): data
$8a98-$8a98 (   1): unaccessed
$8a99-$8aa5 (  13): data
$8aa6-$8aa6 (   1): unaccessed
$8aa7-$8aa8 (   2): data
$8aa9-$8aa9 (   1): unaccessed
$8aaa-$8aaa (   1): data
$8aab-$8aab (   1): unaccessed
$8aac-$8ab6 (  11): data
$8ab7-$8ab7 (   1): unaccessed
$8ab8-$8abd (   6): data
$8abe-$8abe (   1): unaccessed
$8abf-$8ac2 (   4): data
$8ac3-$8ac3 (   1): unaccessed
$8ac4-$8ac4 (   1): data
$8ac5-$8ac6 (   2): unaccessed
$8ac7-$8ac7 (   1): data
$8ac8-$8ae8 (  33): unaccessed
$8ae9-$8ae9 (   1): data
$8aea-$8aeb (   2): unaccessed
$8aec-$8aed (   2): data
$8aee-$8aef (   2): unaccessed
$8af0-$8af2 (   3): data
$8af3-$8af3 (   1): unaccessed
$8af4-$8af7 (   4): data
$8af8-$8af8 (   1): unaccessed
$8af9-$8b05 (  13): data
$8b06-$8b06 (   1): unaccessed
$8b07-$8b08 (   2): data
$8b09-$8b09 (   1): unaccessed
$8b0a-$8b0a (   1): data
$8b0b-$8b0b (   1): unaccessed
$8b0c-$8b16 (  11): data
$8b17-$8b17 (   1): unaccessed
$8b18-$8b1d (   6): data
$8b1e-$8b1e (   1): unaccessed
$8b1f-$8b22 (   4): data
$8b23-$8b23 (   1): unaccessed
$8b24-$8b24 (   1): data
$8b25-$8b26 (   2): unaccessed
$8b27-$8b27 (   1): data
$8b28-$8b45 (  30): unaccessed
$8b46-$8b47 (   2): data
$8b48-$8b6a (  35): unaccessed

$8b6b-$8b6c (   2): data (indirectly accessed)
$8b6d-$8b6e (   2): unaccessed
$8b6f-$8b74 (   6): data (indirectly accessed)
$8b75-$8b77 (   3): unaccessed
$8b78-$8baf (  56): data (indirectly accessed)
$8bb0-$8bb7 (   8): unaccessed
$8bb8-$8be7 (  48): data (indirectly accessed)
$8be8-$8bf7 (  16): unaccessed
$8bf8-$8bfa (   3): data (indirectly accessed)
$8bfb-$8bfb (   1): unaccessed
$8bfc-$8bfe (   3): data (indirectly accessed)
$8bff-$8bff (   1): unaccessed
$8c00-$8c02 (   3): data (indirectly accessed)
$8c03-$8c03 (   1): unaccessed
$8c04-$8c06 (   3): data (indirectly accessed)
$8c07-$8c07 (   1): unaccessed
$8c08-$8c0a (   3): data (indirectly accessed)
$8c0b-$8c0b (   1): unaccessed
$8c0c-$8c0e (   3): data (indirectly accessed)
$8c0f-$8c0f (   1): unaccessed
$8c10-$8c12 (   3): data (indirectly accessed)
$8c13-$8c13 (   1): unaccessed
$8c14-$8c16 (   3): data (indirectly accessed)
$8c17-$8c17 (   1): unaccessed
$8c18-$8c1a (   3): data (indirectly accessed)
$8c1b-$8c1b (   1): unaccessed
$8c1c-$8c1e (   3): data (indirectly accessed)
$8c1f-$8c1f (   1): unaccessed
$8c20-$8c22 (   3): data (indirectly accessed)
$8c23-$8c23 (   1): unaccessed
$8c24-$8c26 (   3): data (indirectly accessed)
$8c27-$8c27 (   1): unaccessed
$8c28-$8c2a (   3): data (indirectly accessed)
$8c2b-$8c2b (   1): unaccessed
$8c2c-$8c2e (   3): data (indirectly accessed)
$8c2f-$8c2f (   1): unaccessed
$8c30-$8c32 (   3): data (indirectly accessed)
$8c33-$8c33 (   1): unaccessed
$8c34-$8c36 (   3): data (indirectly accessed)
$8c37-$8c37 (   1): unaccessed
$8c38-$8c3a (   3): data (indirectly accessed)
$8c3b-$8c3b (   1): unaccessed
$8c3c-$8c3e (   3): data (indirectly accessed)
$8c3f-$8c3f (   1): unaccessed
$8c40-$8c42 (   3): data (indirectly accessed)
$8c43-$8c43 (   1): unaccessed
$8c44-$8c46 (   3): data (indirectly accessed)
$8c47-$8c47 (   1): unaccessed
$8c48-$8c4a (   3): data (indirectly accessed)
$8c4b-$8c4b (   1): unaccessed
$8c4c-$8c4e (   3): data (indirectly accessed)
$8c4f-$8c4f (   1): unaccessed
$8c50-$8c52 (   3): data (indirectly accessed)
$8c53-$8c53 (   1): unaccessed
$8c54-$8c56 (   3): data (indirectly accessed)
$8c57-$8c57 (   1): unaccessed
$8c58-$8c5a (   3): data (indirectly accessed)
$8c5b-$8c5b (   1): unaccessed
$8c5c-$8c5e (   3): data (indirectly accessed)
$8c5f-$8c5f (   1): unaccessed
$8c60-$8c62 (   3): data (indirectly accessed)
$8c63-$8c63 (   1): unaccessed
$8c64-$8c66 (   3): data (indirectly accessed)
$8c67-$8c67 (   1): unaccessed
$8c68-$8c6a (   3): data (indirectly accessed)
$8c6b-$8c6b (   1): unaccessed
$8c6c-$8c6e (   3): data (indirectly accessed)
$8c6f-$8c6f (   1): unaccessed
$8c70-$8c72 (   3): data (indirectly accessed)
$8c73-$8c73 (   1): unaccessed
$8c74-$8c76 (   3): data (indirectly accessed)
$8c77-$8c77 (   1): unaccessed
$8c78-$8c7a (   3): data (indirectly accessed)
$8c7b-$8c7b (   1): unaccessed
$8c7c-$8c7e (   3): data (indirectly accessed)
$8c7f-$8c7f (   1): unaccessed
$8c80-$8c82 (   3): data (indirectly accessed)
$8c83-$8c83 (   1): unaccessed
$8c84-$8c86 (   3): data (indirectly accessed)
$8c87-$8c87 (   1): unaccessed
$8c88-$8c8a (   3): data (indirectly accessed)
$8c8b-$8c8b (   1): unaccessed
$8c8c-$8c8e (   3): data (indirectly accessed)
$8c8f-$8c8f (   1): unaccessed
$8c90-$8c92 (   3): data (indirectly accessed)
$8c93-$8c93 (   1): unaccessed
$8c94-$8c96 (   3): data (indirectly accessed)
$8c97-$8c97 (   1): unaccessed
$8c98-$8c9a (   3): data (indirectly accessed)
$8c9b-$8c9b (   1): unaccessed
$8c9c-$8c9e (   3): data (indirectly accessed)
$8c9f-$8c9f (   1): unaccessed
$8ca0-$8ca2 (   3): data (indirectly accessed)
$8ca3-$8ca3 (   1): unaccessed
$8ca4-$8ca6 (   3): data (indirectly accessed)
$8ca7-$8ca7 (   1): unaccessed
$8ca8-$8caa (   3): data (indirectly accessed)
$8cab-$8cab (   1): unaccessed
$8cac-$8cae (   3): data (indirectly accessed)
$8caf-$8caf (   1): unaccessed
$8cb0-$8cb2 (   3): data (indirectly accessed)
$8cb3-$8cb3 (   1): unaccessed
$8cb4-$8cb6 (   3): data (indirectly accessed)
$8cb7-$8cb7 (   1): unaccessed
$8cb8-$8cba (   3): data (indirectly accessed)
$8cbb-$8cbb (   1): unaccessed
$8cbc-$8cbe (   3): data (indirectly accessed)
$8cbf-$8cbf (   1): unaccessed
$8cc0-$8cc2 (   3): data (indirectly accessed)
$8cc3-$8cc3 (   1): unaccessed
$8cc4-$8cc6 (   3): data (indirectly accessed)
$8cc7-$8cc7 (   1): unaccessed
$8cc8-$8cca (   3): data (indirectly accessed)
$8ccb-$8ccb (   1): unaccessed
$8ccc-$8cce (   3): data (indirectly accessed)
$8ccf-$8ccf (   1): unaccessed
$8cd0-$8cd2 (   3): data (indirectly accessed)
$8cd3-$8cd3 (   1): unaccessed
$8cd4-$8cd6 (   3): data (indirectly accessed)
$8cd7-$8cd7 (   1): unaccessed
$8cd8-$8cda (   3): data (indirectly accessed)
$8cdb-$8cdb (   1): unaccessed
$8cdc-$8cde (   3): data (indirectly accessed)
$8cdf-$8cdf (   1): unaccessed
$8ce0-$8ce2 (   3): data (indirectly accessed)
$8ce3-$8ce7 (   5): unaccessed
$8ce8-$8ce9 (   2): data (indirectly accessed)
$8cea-$8ceb (   2): unaccessed
$8cec-$8d23 (  56): data (indirectly accessed)
$8d24-$8d2b (   8): unaccessed
$8d2c-$8d33 (   8): data (indirectly accessed)
$8d34-$8d35 (   2): unaccessed
$8d36-$8d71 (  60): data (indirectly accessed)
$8d72-$8d73 (   2): unaccessed
$8d74-$8dbf (  76): data (indirectly accessed)
$8dc0-$8e12 (  83): unaccessed
$8e13-$a08c (4730): data (indirectly accessed)
$a08d-$bfff (8051): unaccessed

$c000-$c0a7 ( 168): code

$c0a8-$c0b5 (  14): data
$c0b6-$c0b7 (   2): unaccessed
$c0b8-$c127 ( 112): data (indirectly accessed)
$c128-$c137 (  16): unaccessed
$c138-$c24d ( 278): data
$c24e-$c253 (   6): unaccessed
$c254-$c273 (  32): data
$c274-$c27f (  12): unaccessed
$c280-$d220 (4001): data (PCM audio)
$d221-$d224 (   4): unaccessed
$d225-$d50d ( 745): data
$d50e-$d50f (   2): unaccessed
$d510-$d514 (   5): data
$d515-$d515 (   1): unaccessed
$d516-$d519 (   4): data
$d51a-$d51a (   1): unaccessed
$d51b-$d51b (   1): data
$d51c-$d51e (   3): unaccessed
$d51f-$d51f (   1): data
$d520-$d521 (   2): unaccessed
$d522-$d523 (   2): data
$d524-$d52f (  12): unaccessed
$d530-$da3c (1293): data
$da3d-$da84 (  72): unaccessed
$da85-$dae9 ( 101): data
$daea-$db1a (  49): unaccessed
$db1b-$db27 (  13): data
$db28-$db29 (   2): unaccessed
$db2a-$dba1 ( 120): data
$dba2-$dbb0 (  15): unaccessed
$dbb1-$dbb4 (   4): data
$dbb5-$dbce (  26): unaccessed
$dbcf-$dc1b (  77): data
$dc1c-$dc20 (   5): unaccessed
$dc21-$dc2b (  11): data
$dc2c-$dc30 (   5): unaccessed
$dc31-$dc3b (  11): data
$dc3c-$dc40 (   5): unaccessed
$dc41-$dc4b (  11): data
$dc4c-$dc51 (   6): unaccessed
$dc52-$dc91 (  64): data
$dc92-$dc95 (   4): unaccessed

$dc96-$dca9 (  20): code
$dcaa-$dcce (  37): unaccessed
$dccf-$dd21 (  83): code
$dd22-$dd4e (  45): unaccessed
$dd4f-$df9f ( 593): code
$dfa0-$dfa0 (   1): code, data
$dfa1-$e012 ( 114): code
$e013-$e015 (   3): unaccessed
$e016-$e0d2 ( 189): code
$e0d3-$e1a4 ( 210): unaccessed
$e1a5-$e25c ( 184): code
$e25d-$e25d (   1): code, data
$e25e-$e471 ( 532): code
$e472-$e472 (   1): code, data
$e473-$e5d6 ( 356): code
$e5d7-$e5d7 (   1): code, data
$e5d8-$ea7e (1191): code
$ea7f-$ea7f (   1): code, data
$ea80-$ec46 ( 455): code
$ec47-$ec47 (   1): code, data
$ec48-$ec98 (  81): code
$ec99-$eefa ( 610): unaccessed
$eefb-$f08f ( 405): code
$f090-$f090 (   1): code, data
$f091-$f110 ( 128): code
$f111-$f115 (   5): unaccessed
$f116-$f28b ( 374): code
$f28c-$f28c (   1): code, data
$f28d-$f44a ( 446): code
$f44b-$f44b (   1): code, data
$f44c-$f4f8 ( 173): code
$f4f9-$f503 (  11): unaccessed
$f504-$f67f ( 380): code
$f680-$f680 (   1): code, data
$f681-$f7cf ( 335): code
$f7d0-$f7fc (  45): unaccessed
$f7fd-$f97f ( 387): code
$f980-$f982 (   3): unaccessed
$f983-$f9b2 (  48): code
$f9b3-$f9b6 (   4): unaccessed
$f9b7-$fb34 ( 382): code
$fb35-$fb3c (   8): unaccessed
$fb3d-$fc25 ( 233): code
$fc26-$fff9 ( 980): unaccessed

$fffa-$fffd (   4): data (NMI&amp;reset vectors)
$fffe-$ffff (   2): unaccessed (IRQ vector)
```

## FCEUX Code/Data Log - CHR ROM
I used my [cdl-summary](http://github.com/qalle2/cdl-summary) with the following arguments:

`python cdl_summary.py --prg-size 32 --part c --origin 0 --bank-size 8 quantum.cdl`

Each line: PPU address range, description.

### CHR bank 0
```
$0000-$000f: rendered
$0010-$009f: unaccessed
$00a0-$019f: rendered
$01a0-$01af: unaccessed
$01b0-$020f: rendered
$0210-$021f: unaccessed
$0220-$022f: rendered
$0230-$023f: unaccessed
$0240-$025f: rendered
$0260-$029f: unaccessed
$02a0-$02ff: rendered
$0300-$036f: unaccessed
$0370-$03ff: rendered
$0400-$047f: unaccessed
$0480-$04ff: rendered
$0500-$057f: unaccessed
$0580-$069f: rendered
$06a0-$06df: unaccessed
$06e0-$079f: rendered
$07a0-$07df: unaccessed
$07e0-$087f: rendered
$0880-$089f: unaccessed
$08a0-$097f: rendered
$0980-$099f: unaccessed
$09a0-$0a1f: rendered
$0a20-$0a3f: unaccessed
$0a40-$0a5f: rendered
$0a60-$0abf: unaccessed
$0ac0-$0b1f: rendered
$0b20-$0b3f: unaccessed
$0b40-$0b5f: rendered
$0b60-$0bbf: unaccessed
$0bc0-$0bff: rendered
$0c00-$0c1f: unaccessed
$0c20-$0c6f: rendered
$0c70-$0c8f: unaccessed
$0c90-$0cff: rendered
$0d00-$0d1f: unaccessed
$0d20-$0e5f: rendered
$0e60-$0e9f: unaccessed
$0ea0-$0eff: rendered
$0f00-$0f01: unaccessed
$0f02-$0f12: rendered
$0f13-$0f13: unaccessed
$0f14-$0fff: rendered

$1000-$1fff: rendered
```

### CHR bank 1
```
$0000-$017f: rendered
$0180-$018f: unaccessed
$0190-$01af: rendered
$01b0-$01bf: unaccessed
$01c0-$02ff: rendered
$0300-$030f: unaccessed
$0310-$084f: rendered
$0850-$0c3f: unaccessed
$0c40-$0d1f: rendered
$0d20-$0d2f: unaccessed
$0d30-$0d4f: rendered
$0d50-$0d5f: unaccessed
$0d60-$0daf: rendered
$0db0-$0dbf: unaccessed
$0dc0-$0dcf: rendered
$0dd0-$0ddf: unaccessed
$0de0-$0e4f: rendered
$0e50-$0e5f: unaccessed
$0e60-$0e6f: rendered
$0e70-$0e7f: unaccessed
$0e80-$0e9f: rendered
$0ea0-$0eaf: unaccessed
$0eb0-$0ebf: rendered
$0ec0-$0ecf: unaccessed
$0ed0-$0edf: rendered
$0ee0-$0eef: unaccessed
$0ef0-$0f0f: rendered
$0f10-$0f1f: unaccessed
$0f20-$0fff: rendered

$1000-$1b3f: rendered
$1b40-$1bff: unaccessed
$1c00-$1cff: rendered
$1d00-$1dff: unaccessed
$1e00-$1f7f: rendered
$1f80-$1fff: unaccessed
```

### CHR bank 2
```
$0000-$0002: unaccessed
$0003-$0005: rendered
$0006-$000a: unaccessed
$000b-$000d: rendered
$000e-$008f: unaccessed
$0090-$00ff: rendered
$0100-$018f: unaccessed
$0190-$01ef: rendered
$01f0-$028f: unaccessed
$0290-$02ff: rendered
$0300-$03df: unaccessed
$03e0-$043f: rendered
$0440-$04ff: unaccessed
$0500-$053f: rendered
$0540-$05ff: unaccessed
$0600-$0fff: rendered

$1000-$14ef: rendered
$14f0-$1502: unaccessed
$1503-$1503: rendered
$1504-$150a: unaccessed
$150b-$150b: rendered
$150c-$179f: unaccessed
$17a0-$17ef: rendered
$17f0-$17ff: unaccessed
$1800-$1fff: rendered
```

### CHR bank 3
```
$0000-$0fff: rendered

$1000-$1d9f: rendered
$1da0-$1def: unaccessed
$1df0-$1e4f: rendered
$1e50-$1eef: unaccessed
$1ef0-$1fff: rendered
```

## CPU RAM map
* `000`-`004`: ??
* `005`-`085`: unaccessed (except for the initial cleanup)
* `086`-`0ac`: ??
* `0ad`-`0c7`: unaccessed (except for the initial cleanup)
* `0c8`-`0ef`: ??
* `0f0`-`0fe`: unaccessed (except for the initial cleanup)
* `0ff`-`1ab`: ??
* `1ac`-`1eb`: unaccessed (except for the initial cleanup)
* `1ec`-`1ff`: probably stack
* `200`-`2ff`: unaccessed (except for the initial cleanup)
* `300`-`3ff`: ??
* `400`-`4ff`: unaccessed (except for the initial cleanup)
* `500`-`5ff`: used for OAM DMA
* `600`-`67f`: ??
* `680`-`7bf`: unaccessed (except for the initial cleanup)
* `7c0`-`7df`: a copy of current palette?
* `7e0`-`7ff`: unaccessed (except for the initial cleanup)

## Misc notes
* The program does not execute code from outside of PRG ROM (from `0000`-`7fff`).
* The program does not access CPU addresses `0800`-`1fff`.

## References
* [NESDev Wiki](http://wiki.nesdev.com):
  * [APU registers](http://wiki.nesdev.com/w/index.php/APU_registers)
  * [CNROM](http://wiki.nesdev.com/w/index.php/CNROM)
  * [iNES](http://wiki.nesdev.com/w/index.php/INES) file format
  * [PPU registers](http://wiki.nesdev.com/w/index.php/PPU_registers)
* [a 6502 instruction reference](http://www.obelisk.me.uk/6502/reference.html)

## Software used
* FCEUX (Code/Data Logger etc.)
* HxD (hex editor)
* my [cdl-summary](http://github.com/qalle2/cdl-summary)
* my [ines-info](http://github.com/qalle2/ines-info)
* my [ines-split](http://github.com/qalle2/ines-split)
