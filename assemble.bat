@rem Windows batch file for assembling and verifying Quantum Disco Brothers

@echo off
cls

echo *** Assembling PRG ROM to prg.bin ***
ophis -v -o prg.bin prg.asm
if errorlevel 1 goto end
if not exist prg.bin goto end
echo.

echo *** Verifying PRG ROM ***
if exist prg-original.bin goto verifyprg
echo Warning: prg-original.bin not found, cannot verify. See the readme file.
echo.
goto trytoassemble
:verifyprg
fc /b prg-original.bin prg.bin

:trytoassemble
echo *** Assembling iNES file to "quantum_(e).nes" ***
if exist chr.bin goto assemble
echo Error: chr.bin not found, cannot assemble. See the readme file.
goto end
:assemble
ophis -v -o "quantum_(e).nes" quantum.asm
if errorlevel 1 goto end
if not exist "quantum_(e).nes" goto end
echo.

echo *** Verifying iNES file ***
if exist quantum-original.nes goto verifyines
echo Warning: quantum-original.nes not found, cannot verify the assembled file.
echo See the readme file.
goto end
:verifyines
fc /b quantum-original.nes "quantum_(e).nes"

:end
