@echo off
mode con cp select=437 >nul

:: Fallback default RDP Port if %RdpPort% is undefined
if not defined RdpPort set RdpPort=1

:: Set RDP Registry Port & Enable Remote Desktop Connections
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp" /v PortNumber /t REG_DWORD /d %RdpPort% /f
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Terminal Server" /v fDenyTSConnections /t REG_DWORD /d 0 /f

:: Add Windows Firewall Rules for Custom RDP Port (TCP & UDP)
for %%a in (TCP, UDP) do (
    netsh advfirewall firewall add rule ^
        name="Remote Desktop - Port %RdpPort% (%%a-In)" ^
        dir=in ^
        action=allow ^
        service=any ^
        protocol=%%a ^
        localport=%RdpPort%
)

:: Ensure TermService is Running & Restart Cleanly
sc query TermService >nul 2>&1
if %errorlevel% == 1060 goto :del

set retryCount=3
:restartRDP
if %retryCount% LEQ 0 goto :del
net stop TermService /y >nul 2>&1
net start TermService >nul 2>&1 || (
    set /a retryCount-=1
    timeout /t 5 /nobreak >nul 2>&1
    goto :restartRDP
)

:del
del "%~f0"
