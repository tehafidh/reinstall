@echo off
mode con cp select=437 >nul

:: Disable IPv6 random identifiers to maintain consistent cloud networking
netsh interface ipv6 set global randomizeidentifiers=disabled >nul 2>&1

:: Multi-stage Network Interface Index (%id%) Detection
set id=

:: Method 1: WMIC (Windows 7/8/10/Server 2008-2022)
if defined mac_addr if exist "%windir%\system32\wbem\wmic.exe" (
    for /f "tokens=2 delims==" %%a in (
        'wmic nic where "MACAddress='%mac_addr%'" get InterfaceIndex /format:list 2^>nul ^| findstr "^InterfaceIndex=[0-9][0-9]*$"'
    ) do set id=%%a
)

:: Method 2: PowerShell Get-WmiObject (Windows 10/11/Server 2016-2025)
if not defined id if defined mac_addr (
    for /f %%a in ('powershell -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass ^
        -Command "(Get-WmiObject Win32_NetworkAdapter | Where-Object { $_.MACAddress -eq '%mac_addr%' }).InterfaceIndex" 2^>nul ^| findstr "^[0-9][0-9]*$"'
    ) do set id=%%a
)

:: Method 3: PowerShell Get-CimInstance (Windows 11 24H2 / Server 2025)
if not defined id if defined mac_addr (
    for /f %%a in ('powershell -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass ^
        -Command "(Get-CimInstance Win32_NetworkAdapter | Where-Object { $_.MACAddress -eq '%mac_addr%' }).InterfaceIndex" 2^>nul ^| findstr "^[0-9][0-9]*$"'
    ) do set id=%%a
)

:: Method 4: Fallback to First Connected Physical Network Interface
if not defined id (
    for /f %%a in ('powershell -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass ^
        -Command "(Get-NetAdapter | Where-Object { $_.Status -eq 'Up' }).InterfaceIndex" 2^>nul ^| findstr "^[0-9][0-9]*$"'
    ) do set id=%%a
)

:: Configure Adaptive Network Settings for Cloud Providers (Tencent Cloud, DigitalOcean, AWS, Vultr, Linode)
if defined id (
    :: Static IP Configuration (Tencent Cloud / Custom Subnets)
    if defined ipv4_addr if defined ipv4_gateway (
        echo [NETCONF] Setting Static IPv4 Address %ipv4_addr% Gateway %ipv4_gateway%...
        netsh interface ipv4 set address %id% static %ipv4_addr% gateway=%ipv4_gateway% gwmetric=0 >nul 2>&1
    ) else (
        :: DHCP Configuration (DigitalOcean, AWS, Vultr, Linode)
        echo [NETCONF] Setting DHCP IPv4 Configuration...
        netsh interface ipv4 set address %id% dhcp >nul 2>&1
    )

    :: Configure IPv4 DNS (Default Google DNS & Cloudflare)
    if defined ipv4_dns1 (
        netsh interface ipv4 set dnsservers %id% static %ipv4_dns1% primary >nul 2>&1
    ) else (
        netsh interface ipv4 set dnsservers %id% static 8.8.8.8 primary >nul 2>&1
    )
    if defined ipv4_dns2 (
        netsh interface ipv4 add dnsservers %id% %ipv4_dns2% index=2 >nul 2>&1
    ) else (
        netsh interface ipv4 add dnsservers %id% 1.1.1.1 index=2 >nul 2>&1
    )

    :: Configure IPv6 Address and Gateway
    if defined ipv6_addr if defined ipv6_gateway (
        netsh interface ipv6 set address %id% %ipv6_addr% >nul 2>&1
        netsh interface ipv6 add route prefix=::/0 %id% %ipv6_gateway% >nul 2>&1
    )
)

:del
del "%~f0"
