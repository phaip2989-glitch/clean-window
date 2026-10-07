@echo off
chcp 65001 >nul
title powershell
set "SELF=%~f0"
mode con cols=62 lines=30
color 0C

:menu
cls
echo.
echo         ____ _     _____    _    _   _ ___ _   _  ____ 
echo        / ___^| ^|   ^| ____^|  / \  ^| \ ^| ^|_ _^| \ ^| ^|/ ___^|
echo       ^| ^|   ^| ^|   ^|  _^|   / _ \ ^|  \^| ^|^| ^|^|  \^| ^| ^|  _ 
echo       ^| ^|___^| ^|___^| ^|___ / ___ \^| ^|\  ^|^| ^|^| ^|\  ^| ^|_^| ^|
echo        \____^|_____^|_____/_/   \_\_^| \_^|___^|_^| \_^|\____^|
echo.
echo       __        _____ _   _ ____   _____        ______  
echo       \ \      / /_ _^| \ ^| ^|  _ \ / _ \ \      / / ___^| 
echo        \ \ /\ / / ^| ^|^|  \^| ^| ^| ^| ^| ^| ^| ^| \ \ /\ / /\___ \ 
echo         \ V  V /  ^| ^|^| ^|\  ^| ^|_^| ^| ^|_^| ^|\ V  V /  ___) ^|
echo          \_/\_/  ^|___^|_^| \_^|____/ \___/  \_/\_/  ^|____/ 
echo.
echo      ==================================================
echo                         Clean Windows  
echo      ==================================================
echo.
echo.
echo     [1]  Temp files + PowerShell history
echo     [2]  Event Viewer logs
echo     [3]  Free RAM (standby + working sets) + DNS
echo     [4]  Browser cache (Chrome/Edge/Brave/Firefox)
echo     [5]  Windows Update cache + Recycle Bin
echo     [A]  ALL of the above
echo     [0]  Exit
echo.
echo     Tip: close your browsers before using [4]
echo   ==================================================
set "choice="
set /p "choice=     Select: "

if "%choice%"=="1" call :temp & goto done
if "%choice%"=="2" call :logs & goto done
if "%choice%"=="3" call :ram & goto done
if "%choice%"=="4" call :browser & goto done
if "%choice%"=="5" call :update & goto done
if /i "%choice%"=="A" call :temp & call :logs & call :ram & call :browser & call :update & goto done
if "%choice%"=="0" exit /b
goto menu

:done
echo.
echo   Done.
pause
goto menu

:: ---- [1] Temp files ----
:temp
echo.
echo   Cleaning temp files...
del /f /s /q "%TEMP%\*" >nul 2>&1
for /d %%D in ("%TEMP%\*") do rd /s /q "%%D" >nul 2>&1
del /f /s /q "%SystemRoot%\Temp\*" >nul 2>&1
for /d %%D in ("%SystemRoot%\Temp\*") do rd /s /q "%%D" >nul 2>&1
del /f /q "%LOCALAPPDATA%\Microsoft\Windows\Explorer\thumbcache_*.db" >nul 2>&1
rd /s /q "%APPDATA%\Microsoft\Windows\PowerShell" >nul 2>&1
exit /b

:: ---- [2] Event logs ----
:logs
echo.
echo   Clearing event logs...
for /f "tokens=*" %%L in ('wevtutil el') do wevtutil cl "%%L" >nul 2>&1
exit /b

:: ---- [3] RAM + DNS ----
:ram
echo.
echo   Flushing DNS cache...
ipconfig /flushdns >nul 2>&1
echo   Freeing RAM...
powershell -NoProfile -ExecutionPolicy Bypass -Command "$c=[IO.File]::ReadAllText($env:SELF); $i=$c.LastIndexOf('#PS_BEGIN'); Invoke-Expression $c.Substring($i)"
exit /b

:: ---- [4] Browser cache ----
:browser
echo.
echo   Cleaning browser cache...
call :chromium "%LOCALAPPDATA%\Google\Chrome\User Data"
call :chromium "%LOCALAPPDATA%\Microsoft\Edge\User Data"
call :chromium "%LOCALAPPDATA%\BraveSoftware\Brave-Browser\User Data"
if exist "%LOCALAPPDATA%\Mozilla\Firefox\Profiles" (
    for /d %%P in ("%LOCALAPPDATA%\Mozilla\Firefox\Profiles\*") do rd /s /q "%%P\cache2" >nul 2>&1
)
exit /b

:chromium
if not exist "%~1" exit /b
for /d %%P in ("%~1\*") do (
    rd /s /q "%%P\Cache" >nul 2>&1
    rd /s /q "%%P\Code Cache" >nul 2>&1
    rd /s /q "%%P\GPUCache" >nul 2>&1
)
rd /s /q "%~1\ShaderCache" >nul 2>&1
rd /s /q "%~1\GrShaderCache" >nul 2>&1
exit /b

:: ---- [5] Windows Update cache + Recycle Bin ----
:update
echo.
echo   Clearing Windows Update cache and Recycle Bin...
net stop wuauserv >nul 2>&1
net stop bits >nul 2>&1
del /f /s /q "%SystemRoot%\SoftwareDistribution\Download\*" >nul 2>&1
for /d %%D in ("%SystemRoot%\SoftwareDistribution\Download\*") do rd /s /q "%%D" >nul 2>&1
net start bits >nul 2>&1
net start wuauserv >nul 2>&1
powershell -NoProfile -Command "Clear-RecycleBin -Force -ErrorAction SilentlyContinue" >nul 2>&1
exit /b

exit /b

#PS_BEGIN
$sig = @'
using System;
using System.Runtime.InteropServices;
public class MemClean {
  [DllImport("ntdll.dll")]
  public static extern int NtSetSystemInformation(int cls, IntPtr info, int len);
  [DllImport("advapi32.dll", SetLastError=true)]
  public static extern bool OpenProcessToken(IntPtr h, uint acc, out IntPtr tok);
  [DllImport("advapi32.dll", SetLastError=true, CharSet=CharSet.Unicode)]
  public static extern bool LookupPrivilegeValue(string host, string name, out long luid);
  [DllImport("advapi32.dll", SetLastError=true)]
  public static extern bool AdjustTokenPrivileges(IntPtr tok, bool dis, ref TokPriv tp, int len, IntPtr prev, IntPtr ret);
  [StructLayout(LayoutKind.Sequential, Pack=1)]
  public struct TokPriv { public int Count; public long Luid; public int Attr; }
  public static void Priv(string name) {
    IntPtr tok; long luid;
    OpenProcessToken(System.Diagnostics.Process.GetCurrentProcess().Handle, 0x28, out tok);
    LookupPrivilegeValue(null, name, out luid);
    TokPriv tp = new TokPriv(); tp.Count = 1; tp.Luid = luid; tp.Attr = 2;
    AdjustTokenPrivileges(tok, false, ref tp, 0, IntPtr.Zero, IntPtr.Zero);
  }
  public static int Cmd(int c) {
    IntPtr p = Marshal.AllocHGlobal(4);
    Marshal.WriteInt32(p, c);
    int r = NtSetSystemInformation(80, p, 4);   // SystemMemoryListInformation
    Marshal.FreeHGlobal(p);
    return r;
  }
}
'@
Add-Type -TypeDefinition $sig

function Snap {
  $m  = Get-CimInstance Win32_PerfFormattedData_PerfOS_Memory
  $sb = $m.StandbyCacheNormalPriorityBytes + $m.StandbyCacheReserveBytes + $m.StandbyCacheCoreBytes
  [pscustomobject]@{
    Free    = [math]::Round($m.FreeAndZeroPageListBytes / 1MB)
    Standby = [math]::Round($sb / 1MB)
  }
}

$before = Snap
[MemClean]::Priv('SeProfileSingleProcessPrivilege')
[MemClean]::Priv('SeIncreaseQuotaPrivilege')
[void][MemClean]::Cmd(2)   # empty working sets
[void][MemClean]::Cmd(3)   # flush modified page list
[void][MemClean]::Cmd(4)   # purge standby list
Start-Sleep -Seconds 1
$after = Snap

Write-Host ("  Free RAM : {0} MB -> {1} MB" -f $before.Free, $after.Free)
Write-Host ("  Standby  : {0} MB -> {1} MB" -f $before.Standby, $after.Standby)
