# Warning: this script deletes files. Run at your own risk.

clear

rm -f prg-reassembled.bin
rm -f "quantum-reassembled_(e).nes"

echo "=== Assembling PRG ROM ==="
asm6 prg.asm prg-reassembled.bin
echo

echo "=== Verifying PRG ROM ==="
diff -q prg.bin prg-reassembled.bin
echo

echo "=== Assembling iNES file ==="
asm6 quantum.asm "quantum-reassembled_(e).nes"
echo

echo "=== Verifying iNES file ==="
diff -q quantum_disco_brothers_by_wAMMA.nes "quantum-reassembled_(e).nes"
echo
