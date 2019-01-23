"""Disassemble Quantum Disco Brothers using an FCEUX Code/Data Logger file."""

import os.path
import struct

INPUT_FILE = "original.nes"
CDL_FILE = "quantum.cdl"
OUTPUT_FILE = "prg.asm"

CPU_PRG_ADDRESS = 0x8000
BYTES_PER_LINE = 8

# addressing_mode: (operand_length, operand_prefix, operand_suffix)
ADDRESSING_MODES = {
    "#":   (1, "#", ""),     # immediate
    "-":   (0, "", ""),      # implied
    "a":   (2, "", ""),      # absolute
    "ax":  (2, "", ",x"),    # absolute,x
    "ay":  (2, "", ",y"),    # absolute,y
    "idy": (1, "(", "),y"),  # (indirect),y
    "r":   (1, "", ""),      # relative
    "z":   (1, "", ""),      # zero page
    "zx":  (1, "", ",x"),    # zero page,x
}

# opcode: (mnemonic, addressing_mode)
OPCODES = {
    0x05: ("ora", "z"),
    0x06: ("asl", "z"),
    0x09: ("ora", "#"),
    0x0a: ("asl", "-"),
    0x10: ("bpl", "r"),
    0x18: ("clc", "-"),
    0x19: ("ora", "ay"),
    0x1d: ("ora", "ax"),
    0x20: ("jsr", "a"),
    0x24: ("bit", "z"),
    0x25: ("and", "z"),
    0x29: ("and", "#"),
    0x2a: ("rol", "-"),
    0x2c: ("bit", "a"),
    0x30: ("bmi", "r"),
    0x38: ("sec", "-"),
    0x40: ("rti", "-"),
    0x46: ("lsr", "z"),
    0x48: ("pha", "-"),
    0x49: ("eor", "#"),
    0x4a: ("lsr", "-"),
    0x4c: ("jmp", "a"),
    0x60: ("rts", "-"),
    0x65: ("adc", "z"),
    0x68: ("pla", "-"),
    0x69: ("adc", "#"),
    0x6a: ("ror", "-"),
    0x6d: ("adc", "a"),
    0x70: ("bvs", "r"),
    0x75: ("adc", "zx"),
    0x78: ("sei", "-"),
    0x7d: ("adc", "ax"),
    0x84: ("sty", "z"),
    0x85: ("sta", "z"),
    0x86: ("stx", "z"),
    0x88: ("dey", "-"),
    0x8a: ("txa", "-"),
    0x8c: ("sty", "a"),
    0x8d: ("sta", "a"),
    0x8e: ("stx", "a"),
    0x90: ("bcc", "r"),
    0x94: ("sty", "zx"),
    0x95: ("sta", "zx"),
    0x98: ("tya", "-"),
    0x99: ("sta", "ay"),
    0x9a: ("txs", "-"),
    0x9d: ("sta", "ax"),
    0xa0: ("ldy", "#"),
    0xa2: ("ldx", "#"),
    0xa4: ("ldy", "z"),
    0xa5: ("lda", "z"),
    0xa6: ("ldx", "z"),
    0xa8: ("tay", "-"),
    0xa9: ("lda", "#"),
    0xaa: ("tax", "-"),
    0xac: ("ldy", "a"),
    0xad: ("lda", "a"),
    0xae: ("ldx", "a"),
    0xb0: ("bcs", "r"),
    0xb1: ("lda", "idy"),
    0xb4: ("ldy", "zx"),
    0xb5: ("lda", "zx"),
    0xb8: ("clv", "-"),
    0xb9: ("lda", "ay"),
    0xbc: ("ldy", "ax"),
    0xbd: ("lda", "ax"),
    0xbe: ("ldx", "ay"),
    0xc0: ("cpy", "#"),
    0xc5: ("cmp", "z"),
    0xc6: ("dec", "z"),
    0xc8: ("iny", "-"),
    0xc9: ("cmp", "#"),
    0xca: ("dex", "-"),
    0xce: ("dec", "a"),
    0xd0: ("bne", "r"),
    0xd8: ("cld", "-"),
    0xdd: ("cmp", "ax"),
    0xde: ("dec", "ax"),
    0xe0: ("cpx", "#"),
    0xe4: ("cpx", "z"),
    0xe5: ("sbc", "z"),
    0xe6: ("inc", "z"),
    0xe8: ("inx", "-"),
    0xe9: ("sbc", "#"),
    0xea: ("nop", "-"),
    0xec: ("cpx", "a"),
    0xed: ("sbc", "a"),
    0xee: ("inc", "a"),
    0xf0: ("beq", "r"),
    0xfd: ("sbc", "ax"),
    0xfe: ("inc", "ax"),
}

# CDL bits: --dc--DC (indirect data/code, data/code)
CDL_DESCRIPTIONS = {
    0b0000_0000: "unaccessed",
    0b0000_0001: "code",
    0b0000_0010: "data",
    0b0000_0011: "code&data",
    0b0001_0001: "code (indirect)",
    0b0010_0010: "data (indirect)",
    0b0001_0011: "code (indirect) & data",
    0b0010_0011: "code & data (indirect)",
    0b0011_0011: "code (indirect) & data (indirect)",
}

def get_PRG_ROM():
    with open(INPUT_FILE, "rb") as handle:
        handle.seek(0x10)
        data = handle.read(0x8000)
    return data

def get_CDL_data():
    with open(CDL_FILE, "rb") as handle:
        handle.seek(0)
        data = handle.read(0x8000)
    return data

def print_data_bytes(buffer, handle):
    for pos in range(0, len(buffer), BYTES_PER_LINE):
        values = ", ".join(
            "${:02x}".format(byte) for byte in buffer[pos:pos+BYTES_PER_LINE]
        )
        print("    .byte {:s}".format(values), file=handle)

def main():
    # read files
    PRG = get_PRG_ROM()
    CDL = get_CDL_data()

    if(os.path.exists(OUTPUT_FILE)):
        exit("Error: output file already exists.")

    print("Disassembling to output file...")

    prevByteType = None
    dataByteBuffer = bytearray()

    with open(OUTPUT_FILE, "wt", encoding="ascii", newline="\n") as target:
        pos = 0
        while pos < len(PRG):
            byteType = CDL[pos] & 0b0011_0011  # don't care about PCM/bank

            if prevByteType is None or byteType != prevByteType:
                # chunk changes

                # flush data byte buffer
                print_data_bytes(dataByteBuffer, target)
                dataByteBuffer.clear()

                # print new chunk heading
                print(file=target)
                print("    ; {:04x}: {:s}".format(
                    CPU_PRG_ADDRESS + pos,
                    CDL_DESCRIPTIONS[byteType]
                ), file=target)
                prevByteType = byteType

            # disassemble instruction if it was accessed as code or if it was
            # unaccessed but looks like code
            if CDL[pos] & 0b1 or (
                0x0 <= pos < 0x34
                or 0x157 <= pos < 0x159
                or 0x15d <= pos < 0x15f
                or 0x1cb <= pos < 0x1cd
                or 0x23b <= pos < 0x248
                or 0x26a <= pos < 0x277
                or 0x287 <= pos < 0x289
                or 0x28f <= pos < 0x2d1
                or 0x38e <= pos < 0x3b3
                or 0x414 <= pos < 0x417
                or 0x433 <= pos < 0x436
                or 0x478 <= pos < 0x47b
                or 0x495 <= pos < 0x496
                or 0x4f8 <= pos < 0x50d
                or 0x54e <= pos < 0x55b
                or 0x55e <= pos < 0x5b1
                or 0x62d <= pos < 0x652
                or 0x681 <= pos < 0x6a2
                or 0x798 <= pos < 0x79a
                or 0x906 <= pos < 0x921
                or 0x925 <= pos < 0x930
                or 0x939 <= pos < 0x93b
                or 0x5caa <= pos < 0x5ccf
                or 0x5d22 <= pos < 0x5d4f
                or 0x6013 <= pos < 0x6016
                or 0x60d3 <= pos < 0x61a5
                or 0x639c <= pos < 0x6436
                or 0x6c99 <= pos < 0x6efb
                or 0x7111 <= pos < 0x7116
                or 0x74f9 <= pos < 0x7504
                or 0x77d0 <= pos < 0x77fd
                or 0x7980 <= pos < 0x7983
                or 0x799b <= pos < 0x799e
                or 0x79b3 <= pos < 0x79b7
                or 0x7b0c <= pos < 0x7b40
                or 0x7c13 <= pos < 0x7c22
            ):
                # instruction

                (mnemonic, addrMode) = OPCODES[PRG[pos]]
                (operandLen, prefix, suffix) = ADDRESSING_MODES[addrMode]

                if operandLen == 0:
                    print("    {:s}".format(mnemonic), file=target)
                elif operandLen == 1:
                    operand = PRG[pos+1]

                    if addrMode == "r":
                        base = CPU_PRG_ADDRESS + pos + 2
                        offset = (operand & 0x7f) - (operand & 0x80)
                        operand = (base + offset) & 0xffff
                        operand = format(operand, "04x")
                    else:
                        operand = format(operand, "02x")

                    print("    {:s} {:s}${:s}{:s}".format(
                        mnemonic, prefix, operand, suffix
                    ), file=target)
                else:
                    operand = struct.unpack("<H", PRG[pos+1:pos+3])[0]
                    print("    {:s} {:s}${:04x}{:s}".format(
                        mnemonic, prefix, operand, suffix
                    ), file=target)

                pos += 1 + operandLen
            else:
                # data byte; do not print yet
                dataByteBuffer.append(PRG[pos])
                pos += 1

        # flush data byte buffer
        print_data_bytes(dataByteBuffer, target)

if __name__ == "__main__":
    main()
