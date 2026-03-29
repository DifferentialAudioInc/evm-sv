@echo off
REM ==============================================================================
REM Run Simulation Script (Windows)
REM Copyright (c) 2026 Differential Audio Inc.
REM Licensed under MIT License
REM ==============================================================================

echo === Simple Counter Simulation ===
echo.

REM Check if Vivado is in PATH
where vivado >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: Vivado not found in PATH!
    echo Please add Vivado to PATH or run:
    echo   C:\Xilinx\Vivado\2023.2\settings64.bat
    exit /b 1
)

REM Run Vivado simulation
echo Starting Vivado simulation...
vivado -mode batch -source vivado_sim.tcl

echo.
echo === Simulation Complete ===
echo.
echo To view waveforms:
echo   vivado simple_counter_sim\simple_counter_sim.xpr
echo   Then: Flow ^> Run Simulation ^> Run Behavioral Simulation
echo.

pause
