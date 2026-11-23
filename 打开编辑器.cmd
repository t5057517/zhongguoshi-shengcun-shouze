@echo off
setlocal
rem Pure-ASCII launcher (avoids UTF-8 / chcp parsing issues with Chinese paths)
set "HTTP_PROXY=http://127.0.0.1:7890"
set "HTTPS_PROXY=http://127.0.0.1:7890"
cd /d "%~dp0"
set "GODOT="
for /d %%D in (*) do if exist "%%~fD\Godot_4.7.2\Godot_v4.7.2-stable_win64_console.exe" set "GODOT=%%~fD\Godot_4.7.2\Godot_v4.7.2-stable_win64_console.exe"
if not defined GODOT (
  echo [ERROR] Godot_v4.7.2-stable_win64_console.exe not found.
  pause
  exit /b 1
)
title Godot editor log - keep this window open
"%GODOT%" --editor --path "%~dp0GodotPC"
if errorlevel 1 (
  echo.
  echo [Godot exited with error %errorlevel%] Please screenshot this window.
  pause
)
