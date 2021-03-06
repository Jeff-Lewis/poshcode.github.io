rem #####################################################################
rem
rem Check system uptime with performance counter.
rem
rem PowerShell way:
rem $pc = New-Object Disgnostics.PerformanceCounter("System", "System Up Time", $true)
rem [void]$pc.NextValue()
rem [TimeSpan]::FromSeconds($pc.NextValue()) | select Days, Hours, Minutes | ft -a
rem
rem It's time to get same with usual batch file :)
rem
rem #####################################################################
@echo off
  setlocal
    for /f "tokens=2 delims=," %%i in (
      'typeperf "\System\System Up Time" -sc 1 ^| findstr /rc:"\:"'
    ) do set "sec=%%i"
    set "sec=%sec:"=%"
    for /f "tokens=1 delims=." %%i in ("%sec%") do set "sec=%%i"
    set /a "min=%sec% / 60"
    set /a "hor=%min% / 60"
    set /a "day=%hor% / 24"
    echo.Days    : %day%
    echo.Hours   : %hor%
    echo.Minutes : %min%
  endlocal
exit /b
