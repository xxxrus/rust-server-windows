@echo off
chcp 65001 >nul
cls
title Rust Server

REM ===== НАСТРОЙКИ =====

set "SERVER_NAME=My Rust Server"
set "SERVER_DESC=Welcome!"
set "SERVER_HEADER=https://example.com/rust_header.jpg"

set "SERVER_IDENTITY=rst"
set "MAX_PLAYERS=100"

set "SERVER_PORT=28015"
set "QUERY_PORT=28016"
set "RCON_PORT=28017"
set "APP_PORT=28082"

set "MAP_SEED=100816564"
set "MAP_SIZE=2500"

REM ===== АВТО-ПУТИ =====

set "BASE_DIR=%~dp0"
set "STEAM_DIR=%BASE_DIR%Steam"
set "STEAMCMD=%STEAM_DIR%\steamcmd.exe"

set "RUST_DIR=%STEAM_DIR%\steamapps\common\rust_dedicated"
set "RUSTEXE=%RUST_DIR%\RustDedicated.exe"

cd /d "%BASE_DIR%"

REM ===== STEAMCMD =====

if not exist "%STEAMCMD%" (
    echo SteamCMD не найден. Скачивание...
    mkdir "%STEAM_DIR%" >nul 2>&1

    powershell -NoProfile -Command ^
    "Invoke-WebRequest -Uri https://steamcdn-a.akamaihd.net/client/installer/steamcmd.zip -OutFile '%STEAM_DIR%\steamcmd.zip'"

    powershell -NoProfile -Command ^
    "Expand-Archive -Force '%STEAM_DIR%\steamcmd.zip' '%STEAM_DIR%'"

    del "%STEAM_DIR%\steamcmd.zip"
)

REM ===== УСТАНОВКА / ОБНОВЛЕНИЕ RUST =====

echo Обновление Rust сервера...
"%STEAMCMD%" +login anonymous +app_update 258550 validate +quit

REM ===== ПРОВЕРКА =====

if not exist "%RUSTEXE%" (
    echo RustDedicated.exe не найден
    echo Ожидался путь:
    echo %RUSTEXE%
    pause
    exit /b
)

REM ===== ЗАПУСК =====

cd /d "%RUST_DIR%"

echo Запуск сервера...

"%RUSTEXE%" -batchmode -nographics -silent-crashes ^
+server.port %SERVER_PORT% ^
+server.queryport %QUERY_PORT% ^
+rcon.port %RCON_PORT% ^
+rcon.web 1 ^
+app.port %APP_PORT% ^
+server.identity "%SERVER_IDENTITY%" ^
+server.gamemode vanilla ^
+server.level "Procedural Map" ^
+server.seed %MAP_SEED% ^
+server.worldsize %MAP_SIZE% ^
+server.maxplayers %MAX_PLAYERS% ^
+server.hostname "%SERVER_NAME%" ^
+server.description "%SERVER_DESC%" ^
+server.headerimage "%SERVER_HEADER%" ^
+server.saveinterval 300 ^
-logfile "%BASE_DIR%server\%SERVER_IDENTITY%\server.log"

pause
