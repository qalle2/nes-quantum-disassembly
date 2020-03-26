@rem Windows batch file for assembling and verifying Quantum Disco Brothers

@echo off
cls

echo === assemble.bat: assembling PRG ROM ===
asm6f -m prg.asm prg.bin
if errorlevel 1 goto end
echo.

echo === assemble.bat: verifying PRG ROM ===
fc /b prg-original.bin prg.bin
if errorlevel 1 goto end
echo.

echo === assemble.bat: assembling iNES file ===
asm6f quantum.asm "quantum_(e).nes"
if errorlevel 1 goto end
echo.

echo === assemble.bat: verifying iNES file ===
fc /b quantum-original.nes "quantum_(e).nes"

:end
