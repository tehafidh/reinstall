@echo off
mode con cp select=437 >nul

:: 1. Expand Disk Volume C:
ECHO SELECT VOLUME=%SystemDrive% > "%SystemDrive%\diskpart.extend"
ECHO EXTEND >> "%SystemDrive%\diskpart.extend"
START /WAIT DISKPART /S "%SystemDrive%\diskpart.extend"
DEL /F /Q "%SystemDrive%\diskpart.extend"

:: 2. Configure Single Target User (Default: HFD)
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
