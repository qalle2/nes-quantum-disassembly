@echo off
cls

echo *** Assembling PRG ROM ***
ophis -v -o prg.bin prg.asm
if errorlevel 1 goto end
if not exist prg.bin goto end
echo.

echo *** Verifying PRG ROM ***
if exist prg-original.bin goto verifyprg
echo Warning: "prg-original.bin not found", cannot verify.
echo.
goto assembleall
:verifyprg
fc /b prg-original.bin prg.bin
if errorlevel 1 goto end

:assembleall
echo *** Assembling iNES file ***
ophis -v -o quantum.nes quantum.asm
if errorlevel 1 goto end
if not exist quantum.nes goto end
echo.

echo *** Verifying iNES file ***
if exist quantum-original.nes goto verifyall
echo Warning: "quantum-original.nes" not found, cannot verify.
goto end
:verifyall
fc /b quantum-original.nes quantum.nes
if errorlevel 1 goto end

:end
