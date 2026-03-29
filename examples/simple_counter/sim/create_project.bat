@echo off
REM ==============================================================================
REM Create Vivado Project (Windows)
REM Copyright (c) 2026 Differential Audio Inc.
REM Licensed under MIT License
REM ==============================================================================

echo ========================================
echo Creating Vivado Project
echo ========================================
echo.

REM Run Vivado with project creation script
vivado -mode batch -source create_vivado_project.tcl

echo.
echo ========================================
echo Project created!
echo ========================================
echo.
echo To open the project:
echo   1. Double-click: simple_counter_project\simple_counter_project.xpr
echo   2. Or launch Vivado and open the .xpr file
echo.
echo Then in Vivado GUI:
echo   Flow ^> Run Simulation ^> Run Behavioral Simulation
echo.

pause
