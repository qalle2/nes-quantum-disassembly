@echo off
cls


echo *** Assembling iNES file ***
ophis -v -o quantum.nes quantum.asm
if errorlevel 1 goto end
if not exist quantum.nes goto end
echo.

echo *** Verifying iNES file ***
fc /b quantum-original.nes quantum.nes

:end
