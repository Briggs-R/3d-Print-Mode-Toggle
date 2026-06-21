@echo off
setlocal EnableDelayedExpansion
color 78
title 3d-Print Mode
MODE CON: COLS=74 LINES=16

echo =========================================================================
echo           3D-PRINT MODE, BY Briggs R, Nerdy Bird DBA, V1.0
echo     Double-click once to turn it ON (disables sleep + screensaver).
echo  Double-click again to turn it OFF (restores your original settings).
echo       Intended for use with Pronterface to prevent the Computer 
echo                      from sleeping temporarily
echo =========================================================================

net session >nul 2>&1
if !errorlevel! neq 0 (
    echo Administrator rights are required - requesting elevation...
    powershell -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
    exit /b
)
set "BACKUP=%~dp0printmode_backup.ini"
if exist "%BACKUP%" (
    call :TURN_OFF
) else (
    call :TURN_ON
)

echo.
pause
endlocal
exit /b

:TURN_ON
echo Saving current power and screensaver settings...

for /f "tokens=2 delims=:" %%A in ('powercfg /query SCHEME_CURRENT SUB_SLEEP STANDBYIDLE ^| findstr /C:"Current AC Power Setting Index"') do set "HEX_STANDBY_AC=%%A"
for /f "tokens=2 delims=:" %%A in ('powercfg /query SCHEME_CURRENT SUB_SLEEP STANDBYIDLE ^| findstr /C:"Current DC Power Setting Index"') do set "HEX_STANDBY_DC=%%A"
for /f "tokens=2 delims=:" %%A in ('powercfg /query SCHEME_CURRENT SUB_SLEEP HIBERNATEIDLE ^| findstr /C:"Current AC Power Setting Index"') do set "HEX_HIBERNATE_AC=%%A"
for /f "tokens=2 delims=:" %%A in ('powercfg /query SCHEME_CURRENT SUB_SLEEP HIBERNATEIDLE ^| findstr /C:"Current DC Power Setting Index"') do set "HEX_HIBERNATE_DC=%%A"

for /f "tokens=* delims= " %%B in ("!HEX_STANDBY_AC!")   do set "HEX_STANDBY_AC=%%B"
for /f "tokens=* delims= " %%B in ("!HEX_STANDBY_DC!")   do set "HEX_STANDBY_DC=%%B"
for /f "tokens=* delims= " %%B in ("!HEX_HIBERNATE_AC!") do set "HEX_HIBERNATE_AC=%%B"
for /f "tokens=* delims= " %%B in ("!HEX_HIBERNATE_DC!") do set "HEX_HIBERNATE_DC=%%B"

set /a SEC_STANDBY_AC=!HEX_STANDBY_AC!
set /a SEC_STANDBY_DC=!HEX_STANDBY_DC!
set /a SEC_HIBERNATE_AC=!HEX_HIBERNATE_AC!
set /a SEC_HIBERNATE_DC=!HEX_HIBERNATE_DC!

set "SS_ACTIVE=1"
set "SS_TIMEOUT=600"
for /f "tokens=3" %%C in ('reg query "HKCU\Control Panel\Desktop" /v ScreenSaveActive 2^>nul ^| findstr /I "ScreenSaveActive"') do set "SS_ACTIVE=%%C"
for /f "tokens=3" %%C in ('reg query "HKCU\Control Panel\Desktop" /v ScreenSaveTimeOut 2^>nul ^| findstr /I "ScreenSaveTimeOut"') do set "SS_TIMEOUT=%%C"

(
    echo SEC_STANDBY_AC=!SEC_STANDBY_AC!
    echo SEC_STANDBY_DC=!SEC_STANDBY_DC!
    echo SEC_HIBERNATE_AC=!SEC_HIBERNATE_AC!
    echo SEC_HIBERNATE_DC=!SEC_HIBERNATE_DC!
    echo SS_ACTIVE=!SS_ACTIVE!
    echo SS_TIMEOUT=!SS_TIMEOUT!
) > "%BACKUP%"

echo Disabling sleep mode...
powercfg /change standby-timeout-ac 0
powercfg /change standby-timeout-dc 0
powercfg /change hibernate-timeout-ac 0
powercfg /change hibernate-timeout-dc 0

echo Disabling screensaver...
reg add "HKCU\Control Panel\Desktop" /v ScreenSaveActive /t REG_SZ /d 0 /f >nul

echo.
echo PRINT MODE: ON  -  sleep and the screensaver are disabled.
echo Run this file again when the print job is done to restore your settings.
exit /b

:TURN_OFF
echo Restoring your original settings...

for /f "tokens=1,2 delims==" %%A in ('type "%BACKUP%"') do set "%%A=%%B"

set /a MIN_STANDBY_AC=!SEC_STANDBY_AC!/60
set /a MIN_STANDBY_DC=!SEC_STANDBY_DC!/60
set /a MIN_HIBERNATE_AC=!SEC_HIBERNATE_AC!/60
set /a MIN_HIBERNATE_DC=!SEC_HIBERNATE_DC!/60

powercfg /change standby-timeout-ac !MIN_STANDBY_AC!
powercfg /change standby-timeout-dc !MIN_STANDBY_DC!
powercfg /change hibernate-timeout-ac !MIN_HIBERNATE_AC!
powercfg /change hibernate-timeout-dc !MIN_HIBERNATE_DC!

reg add "HKCU\Control Panel\Desktop" /v ScreenSaveActive /t REG_SZ /d !SS_ACTIVE! /f >nul
reg add "HKCU\Control Panel\Desktop" /v ScreenSaveTimeOut /t REG_SZ /d !SS_TIMEOUT! /f >nul

del "%BACKUP%"

echo.
echo PRINT MODE: OFF  -  your original sleep and screensaver settings are back.
exit /b
