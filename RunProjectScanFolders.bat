@echo off

call "C:\Espressif\idf_cmd_init.bat" esp-idf-a42363d30ca3a4b9ae7b7003b5ba8a20""

setlocal enabledelayedexpansion

color 0B
reg add HKCU\Console /v VirtualTerminalLevel /t REG_DWORD /d 1 /f >nul 2>&1

:: Get ESC character via PowerShell (works in all environments)
for /f %%a in ('powershell -Command "[char]27"') do set "ESC=%%a"
set "CYAN=!ESC![96m"
set "YELLOW=!ESC![93m"
set "GREEN=!ESC![92m"
set "RED=!ESC![91m"
set "GRAY=!ESC![90m"
set "PURPLE=!ESC![95m"
set "RESET=!ESC![0m"

::call "C:\Espressif\idf_cmd_init.bat" esp-idf-a42363d30ca3a4b9ae7b7003b5ba8a20""
::cd /d "C:\Espressif\frameworks\esp-idf-v4.4.7\examples\get-started\hello_world"

:PROJECTSELECT
echo.
echo !CYAN! =========================================!RESET!
echo !CYAN!   Select Project!RESET!
echo !CYAN! =========================================!RESET!
echo.

set PCOUNT=0
for /d %%S in ("%~dp0*") do (
    if exist "%%S\CMakeLists.txt" (
        set /a PCOUNT+=1
        set "PDIR_!PCOUNT!=%%S"
        set "PNAME_!PCOUNT!=%%~nxS"
        echo  [!PCOUNT!] %%~nxS
    )
)

if !PCOUNT!==0 (
    echo  No projects found!
    pause
    goto END
)

echo.
set /p PCHOICE="  Pick a number: "

set PROJECTDIR=!PDIR_%PCHOICE%!
set PROJECTNAME=!PNAME_%PCHOICE%!

if "!PROJECTDIR!"=="" (
    echo !RED!  Invalid choice, try again.!RESET!
    goto PROJECTSELECT
)

echo.
echo !GREEN!  Project: !PROJECTNAME!!RESET!
cd /d "!PROJECTDIR!"

:: Default target
set TARGET=esp32s3
echo !GREEN!  Target set to: !TARGET!!RESET!



:: ── AUTO DETECT COM PORT ON STARTUP ────────────────────
:AUTODETECT
powershell -nologo -command "$ports = (Get-ItemProperty 'HKLM:\HARDWARE\DEVICEMAP\SERIALCOMM' -ErrorAction SilentlyContinue); if ($ports) { $ports.PSObject.Properties | Where-Object { $_.Name -notlike 'PS*' } | ForEach-Object { $_.Value } }" > "%temp%\comports.txt" 2>nul

set COUNT=0
for /f "tokens=*" %%A in (%temp%\comports.txt) do (
    set /a COUNT+=1
    set "LINE_!COUNT!=%%A"
)

if !COUNT!==0 (
    echo !RED!  No COM ports found. !RESET! !CYAN! press any key To Continue ANYWAY.!RESET!
    pause >nul
    goto MENU
)

if !COUNT!==1 (
    set COMPORT=!LINE_1!
    echo !GREEN!  Auto-detected: !COMPORT!!RESET!
    goto MENU
)

:: More than one port found - ask
goto COMSELECT







:TARGETSELECT
echo.
echo !CYAN! =========================================!RESET!
echo !CYAN!   Select Chip Target!RESET!
echo !CYAN! =========================================!RESET!
echo  !YELLOW![1]!RESET! esp32
echo  !YELLOW![2]!RESET! esp32s3
echo  !YELLOW![3]!RESET! esp32s2
echo  !YELLOW![4]!RESET! esp32c3
echo  !GRAY![Enter]!RESET! Keep current: !GREEN!!TARGET!!RESET!
echo !CYAN! =========================================!RESET!
echo.
set /p TARGETCHOICE="  Pick a number: "

if "!TARGETCHOICE!"=="1" set TARGET=esp32
if "!TARGETCHOICE!"=="2" set TARGET=esp32s3
if "!TARGETCHOICE!"=="3" set TARGET=esp32s2
if "!TARGETCHOICE!"=="4" set TARGET=esp32c3

echo.
echo !GREEN!  Target set to: !TARGET!!RESET!
idf.py set-target !TARGET!
goto MENU



:: ── MAIN MENU ──────────────────────────────────────────
:MENU
echo.
echo !CYAN! =========================================!RESET!
if "!COMPORT!"=="" (
    echo !CYAN!  ESP-IDF !YELLOW!^|!CYAN! Get-Mac-Id !YELLOW!^|!RED! No COM Port !YELLOW!^|!PURPLE! !TARGET!!RESET!) else (    echo !CYAN!  ESP-IDF !YELLOW!^|!CYAN! Get-Mac-Id !YELLOW!^|!GREEN! !COMPORT! !YELLOW!^|!PURPLE! !TARGET!!RESET!)
	echo !CYAN! =========================================!RESET!
echo  !YELLOW![1]!RESET! idf.py flash
echo  !YELLOW![2]!RESET! idf.py monitor
echo  !GREEN![3]!RESET! idf.py flash monitor
echo  !YELLOW![4]!RESET! idf.py set-target  !GRAY!(current: !TARGET!)!RESET!
echo  !YELLOW![5]!RESET! idf.py build
echo  !YELLOW![6]!RESET! idf.py fullclean
if "!COMPORT!"=="" (    echo  !YELLOW![7]!RESET! Change COM port  !RED! No COM Port !RESET!) else (    echo  !YELLOW![7]!RESET! Change COM port  !GRAY! current: !COMPORT! !RESET!)
echo  !RED![0]!RESET! Exit
echo !CYAN! =========================================!RESET!
echo.
set /p CHOICE="  Which command? "

if "!CHOICE!"=="1" idf.py -p !COMPORT! flash
if "!CHOICE!"=="2" (
    echo !GRAY!  TIP: Press Ctrl+] to exit monitor!RESET!
    idf.py -p !COMPORT! monitor
)
if "!CHOICE!"=="3" (
    echo !GRAY!  TIP: Press Ctrl+] to exit monitor!RESET!
    idf.py -p !COMPORT! flash monitor
)
if "!CHOICE!"=="4" (
    goto TARGETSELECT
)
if "!CHOICE!"=="5" idf.py build
if "!CHOICE!"=="6" idf.py fullclean
if "!CHOICE!"=="7" goto COMSELECT
if "!CHOICE!"=="0" goto END

goto MENU


:: ── COM PORT SELECTION ─────────────────────────────────
:COMSELECT
echo.
echo !CYAN! =========================================!RESET!
echo !CYAN!   Select COM Port!RESET!
echo !CYAN! =========================================!RESET!

powershell -nologo -command "$ports = (Get-ItemProperty 'HKLM:\HARDWARE\DEVICEMAP\SERIALCOMM' -ErrorAction SilentlyContinue); if ($ports) { $ports.PSObject.Properties | Where-Object { $_.Name -notlike 'PS*' } | ForEach-Object { $_.Value } }" > "%temp%\comports.txt" 2>nul

set COUNT=0
for /f "tokens=*" %%A in (%temp%\comports.txt) do (
    set /a COUNT+=1
    set "LINE_!COUNT!=%%A"
)

if !COUNT!==0 (
    echo !RED!  No COM ports found.!RESET!
    echo  [1] Retry
    echo  [2] Go back to menu
    echo.
    set /p RETRYCHOICE="  Pick: "
    if "!RETRYCHOICE!"=="2" goto MENU
    goto COMSELECT
)
set IDX=0
for /f "tokens=*" %%A in (%temp%\comports.txt) do (
    set /a IDX+=1
    echo  !YELLOW![!IDX!]!RESET! %%A
)

echo.
set /p COMCHOICE="  Pick a number: "
set CHOSEN=!LINE_%COMCHOICE%!
if "!CHOSEN!"=="" (
    echo !RED!  Invalid choice, try again.!RESET!
    goto COMSELECT
)
set COMPORT=!CHOSEN!
echo.
echo !GREEN!  Using: !COMPORT!!RESET!
goto MENU


:END
echo.
echo !YELLOW! +=====================================================================+!RESET!
echo !GREEN!  Bye This was made by !RESET! !CYAN! Badeh !RESET! !GREEN! to make the Work Flow easy from Him !RESET!
echo !RED! +=====================================================================+!RESET!
pause