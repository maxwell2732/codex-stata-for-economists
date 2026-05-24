@echo off
rem ============================================================================
rem run_stata.bat — Windows wrapper around the configured Stata executable.
rem
rem Usage:
rem   scripts\run_stata.bat <path\to\file.do> [<log\path.log>]
rem ============================================================================

setlocal enabledelayedexpansion

if "%~1"=="" (
  echo usage: scripts\run_stata.bat ^<path\to\file.do^> [^<log\path.log^>]
  exit /b 1
)

set "DOFILE=%~1"
set "LOG_PATH=%~2"

if not exist "%DOFILE%" (
  echo error: do-file not found: %DOFILE%
  exit /b 3
)

rem --- Derive log path if not given -------------------------------------------
if "%LOG_PATH%"=="" (
  set "REL=%DOFILE%"
  set "REL=!REL:dofiles\=!"
  set "REL=!REL:.do=!"
  set "REL=!REL:\=_!"
  set "LOG_PATH=logs\!REL!.log"
)

rem --- Ensure log directory exists --------------------------------------------
for %%I in ("%LOG_PATH%") do set "LOG_DIR=%%~dpI"
if not exist "%LOG_DIR%" mkdir "%LOG_DIR%"

rem --- Locate Stata -----------------------------------------------------------
set "CONFIGURED_STATA_BIN=%STATA_BIN%"
set "STATA_BIN="
if not "%CONFIGURED_STATA_BIN%"=="" (
  if exist "%CONFIGURED_STATA_BIN%" (
    set "STATA_BIN=%CONFIGURED_STATA_BIN%"
    goto :found
  )
)
if exist "D:\stata\StataMP-64.exe" (
  set "STATA_BIN=D:\stata\StataMP-64.exe"
  goto :found
)
for %%C in (StataMP-64.exe StataSE-64.exe Stata-64.exe stata-mp.exe stata-se.exe stata.exe) do (
  where %%C >nul 2>nul
  if !ERRORLEVEL! == 0 (
    set "STATA_BIN=%%C"
    goto :found
  )
)
echo error: no Stata executable found
echo        expected local Stata at D:\stata\StataMP-64.exe, or set STATA_BIN.
exit /b 2

:found
echo [run_stata] using:    %STATA_BIN%
echo [run_stata] do-file:  %DOFILE%
echo [run_stata] log:      %LOG_PATH%
echo [run_stata] starting: %DATE% %TIME%

"%STATA_BIN%" /e do "%DOFILE%"
set "RC=%ERRORLEVEL%"

echo [run_stata] exit:     %RC%
echo [run_stata] finished: %DATE% %TIME%

if %RC% NEQ 0 (
  echo [run_stata] --- last 30 lines of %LOG_PATH% ---
  if exist "%LOG_PATH%" (
    powershell -NoProfile -Command "Get-Content -Path '%LOG_PATH%' -Tail 30"
  )
)

exit /b %RC%
