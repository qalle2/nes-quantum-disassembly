# Warning: this script deletes files. Run at your own risk.

rm -f "quantum-reassembled_(e).nes"

echo "=== Assembling ==="
asm6 quantum.asm "quantum-reassembled_(e).nes"
echo

echo "=== Verifying ==="
diff -q quantum_disco_brothers_by_wAMMA.nes "quantum-reassembled_(e).nes"
echo
