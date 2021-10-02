# Warning: this script deletes files. Run at your own risk.

rm -f "quantum-reassembled_(e).nes"
rm -f chr?.bin

echo "=== Encoding CHR data ==="
python3 ../nes-util/nes_chr_encode.py chr0.png chr0.bin
python3 ../nes-util/nes_chr_encode.py chr1.png chr1.bin
python3 ../nes-util/nes_chr_encode.py chr2.png chr2.bin
python3 ../nes-util/nes_chr_encode.py --palette ffffff aaaaaa 555555 000000 chr3.png chr3.bin
echo

echo "=== Assembling ==="
asm6 quantum.asm "quantum-reassembled_(e).nes"
echo

echo "=== Verifying ==="
diff -q quantum_disco_brothers_by_wAMMA.nes "quantum-reassembled_(e).nes"
echo
