@echo off
REM ============================================================
REM  Abrir-Demo-Teclado.bat - Lanzador del demo de LAB (Windows)
REM  Doble clic: abre el Visualizador de eventos de teclado.
REM  Equivale a: powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp003-demo-visualizador-windows.ps1"
REM  Solo registra teclas DENTRO de la ventana del demo. No es un keylogger.
REM ============================================================

cd /d "%~dp0"

echo.
echo  =====================================================
echo   VISUALIZADOR DE TECLADO - DEMO DE LAB (exclusivo VM)
echo   Solo registra pulsaciones DENTRO de su ventana.
echo   Nada se envia a la red. Nada se oculta.
echo  =====================================================
echo.

if not exist "%~dp003-demo-visualizador-windows.ps1" (
    echo  ERROR: no se encuentra 03-demo-visualizador-windows.ps1 junto a este .bat
    echo  Coloque este archivo en la carpeta labs\keylogger-etico
    pause
    exit /b 1
)

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp003-demo-visualizador-windows.ps1"

if errorlevel 1 (
    echo.
    echo  El demo termino con un error. Revise el mensaje anterior.
    pause
)
