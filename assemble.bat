@echo off
cls

if exist chr.bin goto assemble
echo Error: chr.bin not found, cannot assemble. See the readme file.
goto end

:assemble
echo *** Assembling iNES file ***
rem The "(e)" in the filename causes FCEUX to start the ROM in PAL mode.
ophis -v -o "quantum_(e).nes" quantum.asm
if errorlevel 1 goto end
if not exist "quantum_(e).nes" goto end
echo.

if exist quantum-original.nes goto verify
echo Warning: quantum-original.nes not found, cannot verify the assembled file.
echo See the readme file.
goto end

:verify
echo *** Verifying iNES file ***
fc /b quantum-original.nes "quantum_(e).nes"

:end
