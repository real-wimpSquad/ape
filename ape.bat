@echo off
setlocal enabledelayedexpansion
title Atomic Pumpkin
color 07

REM ============================================================================
REM Atomic Pumpkin - Windows Launcher
REM Just double-click this file. It handles the rest.
REM ============================================================================

cd /d "%~dp0"

echo.
echo   ============================================
echo     Atomic Pumpkin - Starting up...
echo   ============================================
echo.

REM =====================================================================
REM  Step 1: Is WSL available?
REM =====================================================================

echo   Checking for WSL...
where wsl >nul 2>&1
if errorlevel 1 (
    echo.
    echo   Hey! We need something called WSL (Windows Subsystem for Linux^)
    echo   to run Atomic Pumpkin. It's a one-time install.
    echo.
    echo   Don't worry, it's made by Microsoft and is perfectly safe.
    echo.
    set /p WSL_INSTALL="   Install it now? (Y/n): "
    if /i "!WSL_INSTALL!"=="n" (
        echo.
        echo   OK! When you're ready, you can install it manually:
        echo     1. Open PowerShell as Administrator
        echo     2. Type:  wsl --install
        echo     3. Restart your computer
        echo     4. Double-click this file again
        echo.
        pause
        exit /b 0
    )
    echo.
    echo   Installing WSL... (this needs admin permission - click Yes if prompted^)
    echo.
    powershell -Command "Start-Process cmd -ArgumentList '/c wsl --install && pause' -Verb RunAs"
    echo.
    echo   ============================================
    echo   WSL is being installed in another window.
    echo.
    echo   When it's done:
    echo     1. RESTART your computer
    echo     2. Double-click this file again
    echo   ============================================
    echo.
    pause
    exit /b 0
)
echo   WSL: OK

REM =====================================================================
REM  Step 2: Is a Linux distro installed?
REM =====================================================================

echo   Checking for a Linux distro...

REM Write wsl test output to a temp file — don't trust errorlevel
wsl -- echo WSLOK > "%TEMP%\ape_wsl_test.txt" 2>&1
findstr /C:"WSLOK" "%TEMP%\ape_wsl_test.txt" >nul 2>&1
if errorlevel 1 (
    echo   No working distro found. Here's what WSL said:
    type "%TEMP%\ape_wsl_test.txt" 2>nul
    del "%TEMP%\ape_wsl_test.txt" 2>nul
    echo.
    echo   Installing Debian (small, ~74 MB^)...
    echo.
    wsl --install -d Debian --no-launch
    echo.
    echo   Initializing Debian (first run^)...
    wsl -- echo "ready"
    echo.

    REM Verify it actually worked
    wsl -- echo WSLOK2 > "%TEMP%\ape_wsl_test2.txt" 2>&1
    findstr /C:"WSLOK2" "%TEMP%\ape_wsl_test2.txt" >nul 2>&1
    if errorlevel 1 (
        echo   Still not working. WSL says:
        type "%TEMP%\ape_wsl_test2.txt" 2>nul
        del "%TEMP%\ape_wsl_test2.txt" 2>nul
        echo.
        echo   This might need admin permissions. Try:
        echo     1. Right-click this file, "Run as administrator"
        echo     2. Or open PowerShell as Admin and run:
        echo        wsl --install -d Debian
        echo.
        pause
        exit /b 1
    )
    del "%TEMP%\ape_wsl_test2.txt" 2>nul
    echo   Debian: OK
) else (
    del "%TEMP%\ape_wsl_test.txt" 2>nul
    echo   Linux distro: OK
)

REM =====================================================================
REM  Step 3: Everything looks good — launch into WSL
REM =====================================================================

REM --- Convert Windows path to WSL mount path ---
set "WINPATH=%~dp0"
if "!WINPATH:~-1!"=="\" set "WINPATH=!WINPATH:~0,-1!"
set "DRIVE=!WINPATH:~0,1!"
for %%a in (a b c d e f g h i j k l m n o p q r s t u v w x y z) do (
    if /i "!DRIVE!"=="%%a" set "DRIVE=%%a"
)
set "REMAINDER=!WINPATH:~2!"
set "REMAINDER=!REMAINDER:\=/!"
set "WSLPATH=/mnt/!DRIVE!!REMAINDER!"

echo   Path: !WSLPATH!
echo.

REM --- Fix line endings on ape.sh (Windows may have mangled them) ---
echo   Preparing launcher script...
wsl -- sed -i 's/\r$//' "!WSLPATH!/ape.sh" 2>nul || wsl -- tr -d '\r' ^< "!WSLPATH!/ape.sh" ^> "!WSLPATH!/ape.sh.tmp" 2>nul && wsl -- mv "!WSLPATH!/ape.sh.tmp" "!WSLPATH!/ape.sh" 2>nul

REM --- Launch ape.sh ---
echo   Launching...
echo.
if "%~1"=="" (
    wsl -- bash "!WSLPATH!/ape.sh"
) else (
    wsl -- bash "!WSLPATH!/ape.sh" %*
)

set "EXIT_CODE=!errorlevel!"

echo.
if not "!EXIT_CODE!"=="0" (
    echo   Something went wrong (exit code: !EXIT_CODE!^).
    echo.
    echo   Things to try:
    echo     - Make sure Docker Desktop is running (check your taskbar^)
    echo     - Try double-clicking this file again
    echo     - Ask Jon :^)
)

echo.
pause
endlocal
