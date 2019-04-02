# nes-quantum-disassembly

An unofficial disassembly of the Nintendo Entertainment System (NES) demo *Quantum Disco Brothers* by wAMMA.

Notes:
* The CHR ROM (graphics data) is **not** included.
* This disassembly is at an **early stage**.
* I have not been involved with wAMMA or in the making of this demo.
* This project had an incorrect license for a short time by mistake.

## How to assemble
* **Install [Ophis](http://michaelcmartin.github.io/Ophis/)** (a 6502 assembler for Windows/Linux/Mac).
* **Download the original** *Quantum Disco Brothers* ROM file:
  * Locations:
    * [scene.org file archive](http://files.scene.org/view/parties/2006/stream06/demo/quantum_disco_brothers_by_wamma.zip)
  * If the file is compressed (extension `.zip`, `.7z`, `.rar`, etc.), **extract** it. (You can delete the compressed file afterwards.)
  * The file should have the extension `.nes`.
  * The size of the file should be 65,552 bytes.
  * The MD5 hash of the file should be `2c932e9e8ae7859517905e2539565a89`.
  * **Rename** the file to `quantum-original.nes`.
* **Extract** the PRG ROM and CHR ROM data from the original ROM file to separate files:
  * **Either** use my [ines-split](http://github.com/qalle2/ines-split)&hellip;
    * `python ines_split.py -p prg-original.bin -c chr.bin quantum-original.nes`
  * &hellip;**Or** use a **hex editor**:
    * PRG ROM: copy 32,768 (`0x8000`) bytes starting from offset 16 (`0x10`) to a new file, `prg-original.bin`.
    * CHR ROM: copy 32,768 (`0x8000`) bytes starting from offset 32,784 (`0x8010`) to a new file, `chr.bin`.
  * `prg-original.bin` should have the MD5 hash `e75cbe84e8a735665b42b245c6aff959`.
  * `chr.bin` should have the MD5 hash `8b2f42589e682cad6be6125ab5faee94`.
* **Assemble**:
  * **Either** run `assemble.bat` (a Windows batch file)&hellip;
    * Requires Ophis and `chr.bin`.
    * Also verifies the assembled files are identical to the original files (if `prg-original.bin` and `quantum-original.nes` exist).
  * &hellip;**Or** assemble manually:
    * Assemble the PRG ROM: `ophis -v -o prg.bin prg.asm`
      * It is recommended to verify that the output file is identical to `prg-original.bin`.
    * Assemble the entire file: `ophis -v -o "quantum_(e).nes" quantum.asm`
      * `prg.bin` (from the previous step) and `chr.bin` are required for this step.
      * The `(e)` in the output filename causes FCEUX to correctly start the ROM in PAL mode.
      * It is recommended to verify that the output file is identical to `quantum-original.nes`.

## The structure of the file
(from the iNES header)
* mapper: CNROM (iNES mapper number 3)
* PRG ROM: 32 KiB (1 &times; 32 KiB)
* CHR ROM: 32 KiB (4 &times; 8 KiB)
* name table mirroring: horizontal
* no trainer
* no save RAM

## Parts of the demo
* The screenshots are from FCEUX in PAL mode.
* The frame numbers are from FCEUX's Frame Display in PAL mode.
* The internal part numbers are at RAM address `0x0001`.

![](shot/01.png)
1st part (internally part #0, starts at frame ~6): "GREETINGS! WE COME FROM..."

![](shot/02.png)
2nd part (internally part #2, starts at frame 1156): "wAMMA - QUANTUM DISCO BROTHERS"

![](shot/03.png)
3rd part (internally part #11, starts at frame 1923): red&purple gradients

![](shot/04.png)
4th part (internally part #1, starts at frame 2690): horizontal color bars

![](shot/05.png)
5th part (internally part #4, starts at frame 3458): a woman

![](shot/06.png)
6th part (internally part #5, starts at frame 4481): "IT IS FRIDAY..."

![](shot/07.png)
7th part (internally part #7, starts at frame 6362): Coca Cola cans

![](shot/08.png)
8th part (internally part #6, starts at frame 7304): Bowser's spaceship

![](shot/09.png)
9th part (internally part #3, starts at frame 8071): credits

![](shot/10.png)
10th part (internally part #10, starts at frame 9692): a checkered wavy animation

![](shot/11.png)
11th part (internally part #12, starts at frame 10380): "GREETS TO ALL NINTENDAWGS"

![](shot/12.png)
12th part (internally part #13, starts at frame 11298): "GAME OVER - CONTINUE?"

At frame 14018, the demo proceeds to a part with internal part number 9, probably unintentionally.

## FCEUX Code/Data Log - PRG ROM
I used my [cdl-summary](http://github.com/qalle2/cdl-summary) with the following arguments:

`python cdl_summary.py --prg-rom-banks=2 --part=p --ignore-cpu-bank quantum.cdl`

No bytes were accessed as indirect code.

Start address, end address, length, description (all numbers in hexadecimal):

```
8000-8033 (0034): unaccessed
8034-8156 (0123): code
8157-8158 (0002): unaccessed
8159-815c (0004): code
815d-815e (0002): unaccessed
815f-823a (00dc): code
823b-8247 (000d): unaccessed
8248-8269 (0022): code
826a-8276 (000d): unaccessed
8277-8286 (0010): code
8287-8288 (0002): unaccessed
8289-828e (0006): code
828f-82d0 (0042): unaccessed
82d1-838d (00bd): code
838e-83b2 (0025): unaccessed
83b3-8413 (0061): code
8414-8416 (0003): unaccessed
8417-8432 (001c): code
8433-8435 (0003): unaccessed
8436-8477 (0042): code
8478-847a (0003): unaccessed
847b-8494 (001a): code
8495-8495 (0001): unaccessed
8496-84f7 (0062): code
84f8-850c (0015): unaccessed
850d-854d (0041): code
854e-855a (000d): unaccessed
855b-855d (0003): code
855e-85b0 (0053): unaccessed
85b1-862c (007c): code
862d-8651 (0025): unaccessed
8652-8680 (002f): code
8681-86a1 (0021): unaccessed
86a2-8797 (00f6): code
8798-8799 (0002): unaccessed
879a-8905 (016c): code
8906-8920 (001b): unaccessed
8921-8924 (0004): code
8925-892f (000b): unaccessed
8930-8932 (0003): code
8933-8933 (0001): unaccessed
8934-8938 (0005): code
8939-893a (0002): unaccessed
893b-8949 (000f): code
894a-895a (0011): unaccessed
895b-8985 (002b): data
8986-8986 (0001): unaccessed
8987-8987 (0001): data
8988-8996 (000f): unaccessed
8997-8997 (0001): data
8998-89a6 (000f): unaccessed
89a7-89a7 (0001): data
89a8-89b6 (000f): unaccessed
89b7-89b7 (0001): data
89b8-89c6 (000f): unaccessed
89c7-89c7 (0001): data
89c8-89d6 (000f): unaccessed
89d7-89d7 (0001): data
89d8-89e6 (000f): unaccessed
89e7-89e7 (0001): data
89e8-89f6 (000f): unaccessed
89f7-89f7 (0001): data
89f8-8a06 (000f): unaccessed
8a07-8a07 (0001): data
8a08-8a16 (000f): unaccessed
8a17-8a17 (0001): data
8a18-8a18 (0001): unaccessed
8a19-8a19 (0001): data
8a1a-8a26 (000d): unaccessed
8a27-8a27 (0001): data
8a28-8a36 (000f): unaccessed
8a37-8a37 (0001): data
8a38-8a46 (000f): unaccessed
8a47-8a47 (0001): data
8a48-8a56 (000f): unaccessed
8a57-8a57 (0001): data
8a58-8a65 (000e): unaccessed
8a66-8a67 (0002): data
8a68-8a76 (000f): unaccessed
8a77-8a77 (0001): data
8a78-8a88 (0011): unaccessed
8a89-8a89 (0001): data
8a8a-8a8b (0002): unaccessed
8a8c-8a8d (0002): data
8a8e-8a8f (0002): unaccessed
8a90-8a92 (0003): data
8a93-8a93 (0001): unaccessed
8a94-8a97 (0004): data
8a98-8a98 (0001): unaccessed
8a99-8aa5 (000d): data
8aa6-8aa6 (0001): unaccessed
8aa7-8aa8 (0002): data
8aa9-8aa9 (0001): unaccessed
8aaa-8aaa (0001): data
8aab-8aab (0001): unaccessed
8aac-8ab6 (000b): data
8ab7-8ab7 (0001): unaccessed
8ab8-8abd (0006): data
8abe-8abe (0001): unaccessed
8abf-8ac2 (0004): data
8ac3-8ac3 (0001): unaccessed
8ac4-8ac4 (0001): data
8ac5-8ac6 (0002): unaccessed
8ac7-8ac7 (0001): data
8ac8-8ae8 (0021): unaccessed
8ae9-8ae9 (0001): data
8aea-8aeb (0002): unaccessed
8aec-8aed (0002): data
8aee-8aef (0002): unaccessed
8af0-8af2 (0003): data
8af3-8af3 (0001): unaccessed
8af4-8af7 (0004): data
8af8-8af8 (0001): unaccessed
8af9-8b05 (000d): data
8b06-8b06 (0001): unaccessed
8b07-8b08 (0002): data
8b09-8b09 (0001): unaccessed
8b0a-8b0a (0001): data
8b0b-8b0b (0001): unaccessed
8b0c-8b16 (000b): data
8b17-8b17 (0001): unaccessed
8b18-8b1d (0006): data
8b1e-8b1e (0001): unaccessed
8b1f-8b22 (0004): data
8b23-8b23 (0001): unaccessed
8b24-8b24 (0001): data
8b25-8b26 (0002): unaccessed
8b27-8b27 (0001): data
8b28-8b45 (001e): unaccessed
8b46-8b47 (0002): data
8b48-8b6a (0023): unaccessed
8b6b-8b6c (0002): data (indirectly accessed)
8b6d-8b6e (0002): unaccessed
8b6f-8b74 (0006): data (indirectly accessed)
8b75-8b77 (0003): unaccessed
8b78-8baf (0038): data (indirectly accessed)
8bb0-8bb7 (0008): unaccessed
8bb8-8be7 (0030): data (indirectly accessed)
8be8-8bf7 (0010): unaccessed
8bf8-8bfa (0003): data (indirectly accessed)
8bfb-8bfb (0001): unaccessed
8bfc-8bfe (0003): data (indirectly accessed)
8bff-8bff (0001): unaccessed
8c00-8c02 (0003): data (indirectly accessed)
8c03-8c03 (0001): unaccessed
8c04-8c06 (0003): data (indirectly accessed)
8c07-8c07 (0001): unaccessed
8c08-8c0a (0003): data (indirectly accessed)
8c0b-8c0b (0001): unaccessed
8c0c-8c0e (0003): data (indirectly accessed)
8c0f-8c0f (0001): unaccessed
8c10-8c12 (0003): data (indirectly accessed)
8c13-8c13 (0001): unaccessed
8c14-8c16 (0003): data (indirectly accessed)
8c17-8c17 (0001): unaccessed
8c18-8c1a (0003): data (indirectly accessed)
8c1b-8c1b (0001): unaccessed
8c1c-8c1e (0003): data (indirectly accessed)
8c1f-8c1f (0001): unaccessed
8c20-8c22 (0003): data (indirectly accessed)
8c23-8c23 (0001): unaccessed
8c24-8c26 (0003): data (indirectly accessed)
8c27-8c27 (0001): unaccessed
8c28-8c2a (0003): data (indirectly accessed)
8c2b-8c2b (0001): unaccessed
8c2c-8c2e (0003): data (indirectly accessed)
8c2f-8c2f (0001): unaccessed
8c30-8c32 (0003): data (indirectly accessed)
8c33-8c33 (0001): unaccessed
8c34-8c36 (0003): data (indirectly accessed)
8c37-8c37 (0001): unaccessed
8c38-8c3a (0003): data (indirectly accessed)
8c3b-8c3b (0001): unaccessed
8c3c-8c3e (0003): data (indirectly accessed)
8c3f-8c3f (0001): unaccessed
8c40-8c42 (0003): data (indirectly accessed)
8c43-8c43 (0001): unaccessed
8c44-8c46 (0003): data (indirectly accessed)
8c47-8c47 (0001): unaccessed
8c48-8c4a (0003): data (indirectly accessed)
8c4b-8c4b (0001): unaccessed
8c4c-8c4e (0003): data (indirectly accessed)
8c4f-8c4f (0001): unaccessed
8c50-8c52 (0003): data (indirectly accessed)
8c53-8c53 (0001): unaccessed
8c54-8c56 (0003): data (indirectly accessed)
8c57-8c57 (0001): unaccessed
8c58-8c5a (0003): data (indirectly accessed)
8c5b-8c5b (0001): unaccessed
8c5c-8c5e (0003): data (indirectly accessed)
8c5f-8c5f (0001): unaccessed
8c60-8c62 (0003): data (indirectly accessed)
8c63-8c63 (0001): unaccessed
8c64-8c66 (0003): data (indirectly accessed)
8c67-8c67 (0001): unaccessed
8c68-8c6a (0003): data (indirectly accessed)
8c6b-8c6b (0001): unaccessed
8c6c-8c6e (0003): data (indirectly accessed)
8c6f-8c6f (0001): unaccessed
8c70-8c72 (0003): data (indirectly accessed)
8c73-8c73 (0001): unaccessed
8c74-8c76 (0003): data (indirectly accessed)
8c77-8c77 (0001): unaccessed
8c78-8c7a (0003): data (indirectly accessed)
8c7b-8c7b (0001): unaccessed
8c7c-8c7e (0003): data (indirectly accessed)
8c7f-8c7f (0001): unaccessed
8c80-8c82 (0003): data (indirectly accessed)
8c83-8c83 (0001): unaccessed
8c84-8c86 (0003): data (indirectly accessed)
8c87-8c87 (0001): unaccessed
8c88-8c8a (0003): data (indirectly accessed)
8c8b-8c8b (0001): unaccessed
8c8c-8c8e (0003): data (indirectly accessed)
8c8f-8c8f (0001): unaccessed
8c90-8c92 (0003): data (indirectly accessed)
8c93-8c93 (0001): unaccessed
8c94-8c96 (0003): data (indirectly accessed)
8c97-8c97 (0001): unaccessed
8c98-8c9a (0003): data (indirectly accessed)
8c9b-8c9b (0001): unaccessed
8c9c-8c9e (0003): data (indirectly accessed)
8c9f-8c9f (0001): unaccessed
8ca0-8ca2 (0003): data (indirectly accessed)
8ca3-8ca3 (0001): unaccessed
8ca4-8ca6 (0003): data (indirectly accessed)
8ca7-8ca7 (0001): unaccessed
8ca8-8caa (0003): data (indirectly accessed)
8cab-8cab (0001): unaccessed
8cac-8cae (0003): data (indirectly accessed)
8caf-8caf (0001): unaccessed
8cb0-8cb2 (0003): data (indirectly accessed)
8cb3-8cb3 (0001): unaccessed
8cb4-8cb6 (0003): data (indirectly accessed)
8cb7-8cb7 (0001): unaccessed
8cb8-8cba (0003): data (indirectly accessed)
8cbb-8cbb (0001): unaccessed
8cbc-8cbe (0003): data (indirectly accessed)
8cbf-8cbf (0001): unaccessed
8cc0-8cc2 (0003): data (indirectly accessed)
8cc3-8cc3 (0001): unaccessed
8cc4-8cc6 (0003): data (indirectly accessed)
8cc7-8cc7 (0001): unaccessed
8cc8-8cca (0003): data (indirectly accessed)
8ccb-8ccb (0001): unaccessed
8ccc-8cce (0003): data (indirectly accessed)
8ccf-8ccf (0001): unaccessed
8cd0-8cd2 (0003): data (indirectly accessed)
8cd3-8cd3 (0001): unaccessed
8cd4-8cd6 (0003): data (indirectly accessed)
8cd7-8cd7 (0001): unaccessed
8cd8-8cda (0003): data (indirectly accessed)
8cdb-8cdb (0001): unaccessed
8cdc-8cde (0003): data (indirectly accessed)
8cdf-8cdf (0001): unaccessed
8ce0-8ce2 (0003): data (indirectly accessed)
8ce3-8ce3 (0001): unaccessed
8ce4-8ce6 (0003): data (indirectly accessed)
8ce7-8ce7 (0001): unaccessed
8ce8-8ce9 (0002): data (indirectly accessed)
8cea-8ceb (0002): unaccessed
8cec-8d23 (0038): data (indirectly accessed)
8d24-8d2b (0008): unaccessed
8d2c-8d33 (0008): data (indirectly accessed)
8d34-8d35 (0002): unaccessed
8d36-8d71 (003c): data (indirectly accessed)
8d72-8d73 (0002): unaccessed
8d74-8dbf (004c): data (indirectly accessed)
8dc0-8e12 (0053): unaccessed
8e13-a08c (127a): data (indirectly accessed)

a08d-bfff (1f73): unaccessed (note: padding)

c000-c0a7 (00a8): code
c0a8-c0b5 (000e): data
c0b6-c0b7 (0002): unaccessed
c0b8-c127 (0070): data (indirectly accessed)
c128-c137 (0010): unaccessed
c138-c24d (0116): data
c24e-c253 (0006): unaccessed
c254-c273 (0020): data
c274-c27f (000c): unaccessed
c280-d220 (0fa1): data (PCM audio)
d221-d224 (0004): unaccessed
d225-d50d (02e9): data
d50e-d50f (0002): unaccessed
d510-d514 (0005): data
d515-d515 (0001): unaccessed
d516-d519 (0004): data
d51a-d51a (0001): unaccessed
d51b-d51b (0001): data
d51c-d51e (0003): unaccessed
d51f-d51f (0001): data
d520-d521 (0002): unaccessed
d522-d523 (0002): data
d524-d52f (000c): unaccessed
d530-da3c (050d): data
da3d-da84 (0048): unaccessed
da85-dae9 (0065): data
daea-db1a (0031): unaccessed
db1b-db27 (000d): data
db28-db29 (0002): unaccessed
db2a-dba1 (0078): data
dba2-dbb0 (000f): unaccessed
dbb1-dbb4 (0004): data
dbb5-dbce (001a): unaccessed
dbcf-dc1b (004d): data
dc1c-dc20 (0005): unaccessed
dc21-dc2b (000b): data
dc2c-dc30 (0005): unaccessed
dc31-dc3b (000b): data
dc3c-dc40 (0005): unaccessed
dc41-dc4b (000b): data
dc4c-dc51 (0006): unaccessed
dc52-dc91 (0040): data
dc92-dc95 (0004): unaccessed
dc96-dca9 (0014): code
dcaa-dcce (0025): unaccessed
dccf-dd21 (0053): code
dd22-dd4e (002d): unaccessed
dd4f-df9f (0251): code
dfa0-dfa0 (0001): code, data
dfa1-e012 (0072): code
e013-e015 (0003): unaccessed
e016-e0d2 (00bd): code
e0d3-e1a4 (00d2): unaccessed
e1a5-e25c (00b8): code
e25d-e25d (0001): code, data
e25e-e471 (0214): code
e472-e472 (0001): code, data
e473-e5d6 (0164): code
e5d7-e5d7 (0001): code, data
e5d8-ea7e (04a7): code
ea7f-ea7f (0001): code, data
ea80-ec46 (01c7): code
ec47-ec47 (0001): code, data
ec48-ec98 (0051): code
ec99-eefa (0262): unaccessed
eefb-f08f (0195): code
f090-f090 (0001): code, data
f091-f110 (0080): code
f111-f115 (0005): unaccessed
f116-f28b (0176): code
f28c-f28c (0001): code, data
f28d-f44a (01be): code
f44b-f44b (0001): code, data
f44c-f4f8 (00ad): code
f4f9-f503 (000b): unaccessed
f504-f67f (017c): code
f680-f680 (0001): code, data
f681-f7cf (014f): code
f7d0-f7fc (002d): unaccessed
f7fd-f97f (0183): code
f980-f982 (0003): unaccessed
f983-fc25 (02a3): code

fc26-fff9 (03d4): unaccessed (note: padding)

fffa-fffd (0004): data (note: NMI and reset vectors)
fffe-ffff (0002): unaccessed (note: IRQ vector)
```

## FCEUX Code/Data Log - CHR ROM
I used my [cdl-summary](http://github.com/qalle2/cdl-summary) with the following arguments:

`python cdl_summary.py --prg-rom-banks=2 --part=c --rom-bank-size=1000 quantum.cdl`

No bytes were read programmatically via `$2007`.

Whether each tile in each half-bank was rendered or not:

### Bank 0 - first half

(Many tiles were partially rendered, i.e., some but not all bytes were rendered.)

### Bank 0 - second half

```
00   : partially
01-04: yes
05   : partially
06   : partially
07-08: yes
09   : partially
0a   : partially
0b-0d: yes
0e   : partially
0f-ff: yes
```

### Bank 1 - first half

```
00-17: yes
18   : no
19-1a: yes
1b   : no
1c-2f: yes
30   : no
31-84: yes
85-c3: no
c4-d1: yes
d2   : no
d3-d4: yes
d5   : no
d6-da: yes
db   : no
dc   : yes
dd   : no
de-e4: yes
e5   : no
e6   : yes
e7   : no
e8-e9: yes
ea   : no
eb   : yes
ec   : no
ed   : yes
ee   : no
ef-f0: yes
f1   : no
f2-ff: yes
```

### Bank 1 - second half

```
00-b3: yes
b4-bf: no
c0-cf: yes
d0-df: no
e0-f7: yes
f8-ff: no
```

### Bank 2 - first half

```
00   : partially
01-08: no
09-0f: yes
10-18: no
19-1e: yes
1f-24: no
25   : yes
26-28: no
29-2f: yes
30-3d: no
3e-43: yes
44-4f: no
50-53: yes
54-5f: no
60-ff: yes
```

### Bank 2 - second half

```
00-4e: yes
4f   : no
50-51: yes
52-79: no
7a-7e: yes
7f   : no
80-ff: yes
```

### Bank 3 - first half

```
00-ff: yes
```

### Bank 3 - second half

```
00-d9: yes
da-de: no
df-e4: yes
e5-ee: no
ef-ff: yes
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
