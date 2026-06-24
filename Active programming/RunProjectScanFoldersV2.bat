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
echo  !YELLOW![9]!RESET! Open ESP-IDF terminal here
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
if "!CHOICE!"=="8" goto GAMEMENU
if "!CHOICE!"=="9" (
    echo !GREEN!  Opening terminal in: !CD!!RESET!
    cmd /k
)

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

:GAMEMENU
echo.
echo !CYAN! =========================================!RESET!
echo !CYAN!   Game Menu!RESET!
echo !CYAN! =========================================!RESET!
echo  !YELLOW![1]!RESET! Guess the Number
echo  !YELLOW![2]!RESET! Rock, Paper, Scissors
echo  !YELLOW![3]!RESET! Hangman
echo  !YELLOW![4]!RESET! Tic-Tac-Toe
echo  !YELLOW![5]!RESET! Dice Roll
echo  !YELLOW![6]!RESET! Simple Blackjack
echo  !RED![0]!RESET! Back to main menu
echo !CYAN! =========================================!RESET!
echo.
set /p GCHOICE="  Which game? "

if "!GCHOICE!"=="1" goto GAME_GUESS
if "!GCHOICE!"=="2" goto GAME_RPS
if "!GCHOICE!"=="3" goto GAME_HANGMAN
if "!GCHOICE!"=="4" goto GAME_TTT
if "!GCHOICE!"=="5" goto GAME_DICE
if "!GCHOICE!"=="6" goto GAME_BJ
if "!GCHOICE!"=="0" goto MENU
goto GAMEMENU

:: ── GUESS THE NUMBER ────────────────────────────────────
:GAME_GUESS
echo.
echo !CYAN! =========================================!RESET!
echo !CYAN!   Guess the Number (1-100)!RESET!
echo !CYAN! =========================================!RESET!
set /a SECRET=!random! %% 100 + 1
set TRIES=0
:GUESSLOOP
set /a TRIES+=1
set /p GUESS="  Your guess: "
if !GUESS! GTR !SECRET! (
    echo !RED!  Too high!!RESET!
    goto GUESSLOOP
)
if !GUESS! LSS !SECRET! (
    echo !YELLOW!  Too low!!RESET!
    goto GUESSLOOP
)
echo.
echo !GREEN!  Correct! It was !SECRET!. You got it in !TRIES! tries!!RESET!
pause
goto GAMEMENU

:: ── ROCK PAPER SCISSORS ─────────────────────────────────
:GAME_RPS
echo.
echo !CYAN! =========================================!RESET!
echo !CYAN!   Rock, Paper, Scissors!RESET!
echo !CYAN! =========================================!RESET!
echo  !YELLOW![1]!RESET! Rock
echo  !YELLOW![2]!RESET! Paper
echo  !YELLOW![3]!RESET! Scissors
echo  !RED![0]!RESET! Back
echo.
set /p RPSCHOICE="  Pick: "
if "!RPSCHOICE!"=="0" goto GAMEMENU
set /a CPU=(!random! %% 3) + 1
echo.
if "!RPSCHOICE!"=="1" set PNAME=Rock
if "!RPSCHOICE!"=="2" set PNAME=Paper
if "!RPSCHOICE!"=="3" set PNAME=Scissors
if !CPU!==1 set CNAME=Rock
if !CPU!==2 set CNAME=Paper
if !CPU!==3 set CNAME=Scissors
echo !GRAY!  You: !PNAME!  vs  CPU: !CNAME!!RESET!

if "!RPSCHOICE!"=="!CPU!" (
    echo !YELLOW!  It's a tie!!RESET!
    goto RPSEND
)
if "!RPSCHOICE!"=="1" if !CPU!==3 goto RPSWIN
if "!RPSCHOICE!"=="2" if !CPU!==1 goto RPSWIN
if "!RPSCHOICE!"=="3" if !CPU!==2 goto RPSWIN
echo !RED!  You lose!!RESET!
goto RPSEND
:RPSWIN
echo !GREEN!  You win!!RESET!
:RPSEND
echo.
pause
goto GAME_RPS

:: ── HANGMAN ─────────────────────────────────────────────
:GAME_HANGMAN
echo.
echo !CYAN! =========================================!RESET!
echo !CYAN!   Hangman!RESET!
echo !CYAN! =========================================!RESET!
set WORDS[0]=ESPRESSIF
set WORDS[1]=FIRMWARE
set WORDS[2]=BLUETOOTH
set WORDS[3]=COMPILER
set WORDS[4]=ARDUINO
set /a WIDX=!random! %% 5
call set WORD=%%WORDS[!WIDX!]%%
set GUESSED=
set WRONG=0
set MAXWRONG=6

:HANGLOOP
set DISPLAY=
set /a LEN=0
for /l %%I in (0,1,20) do (
    set "CH=!WORD:~%%I,1!"
    if not "!CH!"=="" (
        set "FOUND=0"
        if "!GUESSED!" neq "" (
            for /l %%J in (0,1,20) do (
                set "GC=!GUESSED:~%%J,1!"
                if "!GC!"=="!CH!" set FOUND=1
            )
        )
        if !FOUND!==1 (
            set "DISPLAY=!DISPLAY!!CH! "
        ) else (
            set "DISPLAY=!DISPLAY!_ "
        )
    )
)
echo.
echo  Word: !DISPLAY!
echo  Wrong guesses: !WRONG!/!MAXWRONG!  ^(!GUESSED!^)
echo.

echo "!DISPLAY!" | findstr "_" >nul
if errorlevel 1 (
    echo !GREEN!  You won! The word was !WORD!!RESET!
    pause
    goto GAMEMENU
)

if !WRONG! GEQ !MAXWRONG! (
    echo !RED!  You lost! The word was !WORD!!RESET!
    pause
    goto GAMEMENU
)

set /p LETTER="  Guess a letter: "
set GUESSED=!GUESSED!!LETTER!
echo "!WORD!" | findstr /i "!LETTER!" >nul
if errorlevel 1 set /a WRONG+=1
goto HANGLOOP

:: ── TIC TAC TOE ─────────────────────────────────────────
:GAME_TTT
echo.
echo !CYAN! =========================================!RESET!
echo !CYAN!   Tic-Tac-Toe (2 Player)!RESET!
echo !CYAN! =========================================!RESET!
for /l %%I in (1,1,9) do set "C%%I= "
set TURN=X

:TTTLOOP
echo.
echo   !C1!^|!C2!^|!C3!
echo   ---^|---^|---
echo   !C4!^|!C5!^|!C6!
echo   ---^|---^|---
echo   !C7!^|!C8!^|!C9!
echo.
set /p TPOS="  Player !TURN!, pick a cell (1-9): "
call set "CELL=%%C!TPOS!%%"
if not "!CELL!"==" " (
    echo !RED!  Cell taken, try again.!RESET!
    goto TTTLOOP
)
set "C!TPOS!=!TURN!"

:: check win combos
set WIN=0
if "!C1!!C2!!C3!"=="!TURN!!TURN!!TURN!" set WIN=1
if "!C4!!C5!!C6!"=="!TURN!!TURN!!TURN!" set WIN=1
if "!C7!!C8!!C9!"=="!TURN!!TURN!!TURN!" set WIN=1
if "!C1!!C4!!C7!"=="!TURN!!TURN!!TURN!" set WIN=1
if "!C2!!C5!!C8!"=="!TURN!!TURN!!TURN!" set WIN=1
if "!C3!!C6!!C9!"=="!TURN!!TURN!!TURN!" set WIN=1
if "!C1!!C5!!C9!"=="!TURN!!TURN!!TURN!" set WIN=1
if "!C3!!C5!!C7!"=="!TURN!!TURN!!TURN!" set WIN=1

if !WIN!==1 (
    echo.
    echo   !C1!^|!C2!^|!C3!
    echo   ---^|---^|---
    echo   !C4!^|!C5!^|!C6!
    echo   ---^|---^|---
    echo   !C7!^|!C8!^|!C9!
    echo.
    echo !GREEN!  Player !TURN! wins!!RESET!
    pause
    goto GAMEMENU
)

if "!TURN!"=="X" (set TURN=O) else (set TURN=X)
goto TTTLOOP

:: ── DICE ROLL ────────────────────────────────────────────
:GAME_DICE
echo.
echo !CYAN! =========================================!RESET!
echo !CYAN!   Dice Roll!RESET!
echo !CYAN! =========================================!RESET!
set /a D1=(!random! %% 6) + 1
set /a D2=(!random! %% 6) + 1
echo.
echo !YELLOW!  You rolled: !D1! and !D2!  (Total: !D1!+!D2!)!RESET!
echo.
pause
goto GAME_DICE

:: ── SIMPLE BLACKJACK ────────────────────────────────────
:GAME_BJ
echo.
echo !CYAN! =========================================!RESET!
echo !CYAN!   Simple Blackjack (numbers only)!RESET!
echo !CYAN! =========================================!RESET!
set /a P1=(!random! %% 10) + 1
set /a P2=(!random! %% 10) + 1
set /a PTOTAL=!P1!+!P2!
echo  Your cards: !P1! and !P2!  (Total: !PTOTAL!)
echo.

:BJLOOP
if !PTOTAL! GEQ 21 goto BJBUST
set /p BJHIT="  Hit or Stand? (h/s): "
if /i "!BJHIT!"=="h" (
    set /a NEWCARD=(!random! %% 10) + 1
    set /a PTOTAL+=!NEWCARD!
    echo  You drew: !NEWCARD!  (Total: !PTOTAL!)
    goto BJLOOP
)

set /a DTOTAL=(!random! %% 10) + 10
echo  Dealer total: !DTOTAL!
if !PTOTAL! GTR !DTOTAL! (
    echo !GREEN!  You win!!RESET!
) else if !PTOTAL!==!DTOTAL! (
    echo !YELLOW!  Push - tie game!!RESET!
) else (
    echo !RED!  Dealer wins!!RESET!
)
pause
goto GAME_BJ

:BJBUST
echo !RED!  Bust! You went over 21.!RESET!
pause
goto GAME_BJ

:END
echo.
echo !YELLOW! +=====================================================================+!RESET!
echo !GREEN!  Bye This was made by !RESET! !CYAN! Badeh !RESET! !GREEN! to make the Work Flow easy from Him !RESET!
echo !RED! +=====================================================================+!RESET!
pause