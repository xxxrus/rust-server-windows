@echo off
chcp 65001 >nul
title Rust Server (Watchdog)

REM ==================================================
REM ================== НАСТРОЙКИ =====================
REM ==================================================

set SERVER_NAME=My Rust Server
set SERVER_DESC=Welcome to my Rust server!
set SERVER_HEADER=https://example.com/rust_header.jpg
set RCON_PASSWORD=CHANGE_THIS_TO_LONG_PASSWORD

set SERVER_IDENTITY=rst
set MAX_PLAYERS=100
set SERVER_PORT=28015
set QUERY_PORT=28016
set RCON_PORT=28017
set APP_PORT=28082

set MAP_SEED=100816564
set MAP_SIZE=2500
set TICKRATE=30

REM ==================================================
REM ================== ПУТИ ==========================
REM ==================================================

set BASE_DIR=%~dp0
set STEAM_DIR=%BASE_DIR%Steam

set STEAMCMD_DIR=%STEAM_DIR%\steamcmd
set STEAMCMD_EXE=%STEAMCMD_DIR%\steamcmd.exe
set STEAMCMD_ZIP=%STEAMCMD_DIR%\steamcmd.zip

set RUST_DIR=%STEAM_DIR%\steamapps\common\rust_dedicated
set RUSTEXE=%RUST_DIR%\RustDedicated.exe
set RUST_APPID=258550

set SERVER_DIR=%BASE_DIR%server\%SERVER_IDENTITY%
set BACKUP_DIR=%BASE_DIR%backups\%SERVER_IDENTITY%

REM ================= OXIDE / UMOD ===================

set OXIDE_URL=https://umod.org/games/rust/download
set OXIDE_ZIP=%BASE_DIR%oxide_latest.zip
set OXIDE_TEMP=%BASE_DIR%oxide_tmp

REM ==================================================
REM ================= ПРОВЕРКИ =======================
REM ==================================================

where powershell >nul 2>&1
if errorlevel 1 (
    echo [ERROR] PowerShell не найден
    pause
    exit /b
)

tasklist | find /i "RustDedicated.exe" >nul
if not errorlevel 1 (
    echo [INFO] Сервер уже запущен
    pause
    exit /b
)

mkdir "%STEAM_DIR%" >nul 2>&1
mkdir "%SERVER_DIR%" >nul 2>&1
mkdir "%BACKUP_DIR%" >nul 2>&1

REM ==================================================
REM ============ АВТОУСТАНОВКА STEAMCMD ===============
REM ==================================================

if not exist "%STEAMCMD_EXE%" (
    echo.
    echo ==============================
    echo [SteamCMD] Установка SteamCMD
    echo ==============================

    mkdir "%STEAMCMD_DIR%" >nul 2>&1

    echo [SteamCMD] Скачивание...
    powershell -Command ^
    "Invoke-WebRequest -Uri 'https://steamcdn-a.akamaihd.net/client/installer/steamcmd.zip' -OutFile '%STEAMCMD_ZIP%'"

    if not exist "%STEAMCMD_ZIP%" (
        echo [SteamCMD] Ошибка загрузки
        pause
        exit /b
    )

    echo [SteamCMD] Распаковка...
    powershell -Command ^
    "Expand-Archive -Path '%STEAMCMD_ZIP%' -DestinationPath '%STEAMCMD_DIR%' -Force"

    del /f /q "%STEAMCMD_ZIP%"

    echo [SteamCMD] Первый запуск...
    "%STEAMCMD_EXE%" +quit
)

REM ==================================================
REM ================= WATCHDOG =======================
REM ==================================================

:START

REM ---------- ДАТА / ВРЕМЯ

for /f "tokens=1-4 delims=.-/ " %%a in ("%date%") do (
    set DD=%%a
    set MM=%%b
    set YYYY=%%c
)
for /f "tokens=1-2 delims=:." %%a in ("%time%") do (
    set HH=%%a
    set MN=%%b
)
set HH=%HH: =0%

set DATE=%YYYY%-%MM%-%DD%
set TIME=%HH%-%MN%

echo.
echo ==============================
echo [Rust] Бэкап
echo ==============================

xcopy "%SERVER_DIR%\cfg"  "%BACKUP_DIR%\%DATE%_%TIME%\cfg"  /E /I /Y >nul
xcopy "%SERVER_DIR%\save" "%BACKUP_DIR%\%DATE%_%TIME%\save" /E /I /Y >nul

REM ---------- ОБНОВЛЕНИЕ RUST

echo.
echo ==============================
echo [SteamCMD] Обновление Rust
echo ==============================

"%STEAMCMD_EXE%" ^
+login anonymous ^
+force_install_dir "%RUST_DIR%" ^
+app_update %RUST_APPID% validate ^
+quit

REM ---------- ОБНОВЛЕНИЕ OXIDE

echo.
echo ==============================
echo [uMod] Обновление Oxide
echo ==============================

if exist "%OXIDE_ZIP%" del /f /q "%OXIDE_ZIP%"
if exist "%OXIDE_TEMP%" rd /s /q "%OXIDE_TEMP%"

powershell -Command ^
"Invoke-WebRequest -Uri '%OXIDE_URL%' -OutFile '%OXIDE_ZIP%'"

powershell -Command ^
"Expand-Archive -Path '%OXIDE_ZIP%' -DestinationPath '%OXIDE_TEMP%' -Force"

xcopy "%OXIDE_TEMP%\RustDedicated_Data" "%RUST_DIR%\RustDedicated_Data" /E /Y >nul
xcopy "%OXIDE_TEMP%\Oxide.*" "%RUST_DIR%" /Y >nul

rd /s /q "%OXIDE_TEMP%"
del /f /q "%OXIDE_ZIP%"

REM ---------- ЗАПУСК СЕРВЕРА

echo.
echo ==============================
echo [Rust] Запуск сервера
echo ==============================

cd /d "%RUST_DIR%"

"%RUSTEXE%" -batchmode -nographics ^
+server.port %SERVER_PORT% ^
+server.queryport %QUERY_PORT% ^
+rcon.port %RCON_PORT% ^
+rcon.web 0 ^
+app.port %APP_PORT% ^
+server.identity "%SERVER_IDENTITY%" ^
+server.level "Procedural Map" ^
+server.seed %MAP_SEED% ^
+server.worldsize %MAP_SIZE% ^
+server.maxplayers %MAX_PLAYERS% ^
+server.tickrate %TICKRATE% ^
+server.hostname "%SERVER_NAME%" ^
+server.description "%SERVER_DESC%" ^
+server.headerimage "%SERVER_HEADER%" ^
+rcon.password "%RCON_PASSWORD%" ^
+server.saveinterval 300 ^
+server.secure 1 ^
-logfile "%SERVER_DIR%\server.log"

REM ---------- WATCHDOG

echo.
echo [WATCHDOG] Сервер остановлен
echo [WATCHDOG] Перезапуск через 10 секунд...
timeout /t 10 >nul
goto START
