@echo off
setlocal
cd /d "%~dp0"
set "GODOT="
for /d %%D in (*) do if exist "%%~fD\Godot_4.7.2\Godot_v4.7.2-stable_win64.exe" set "GODOT=%%~fD\Godot_4.7.2\Godot_v4.7.2-stable_win64.exe"
if not defined GODOT (
  echo [ERROR] Godot_v4.7.2-stable_win64.exe not found.
  pause
  exit /b 1
)
start "" "%GODOT%" --path "%~dp0GodotPC"
