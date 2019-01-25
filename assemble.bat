@echo off
cls

if exist chr.bin goto assemble
echo Error: chr.bin not found, cannot assemble. See the readme file.
goto end

:assemble
echo *** Assembling iNES file ***
ophis -v -o quantum.nes quantum.asm
if errorlevel 1 goto end
if not exist quantum.nes goto end
echo.

if exist quantum-original.nes goto verify
echo Warning: quantum-original.nes not found, cannot verify the assembled file.
echo See the readme file.
goto end

:verify
echo *** Verifying iNES file ***
fc /b quantum-original.nes quantum.nes

:end
