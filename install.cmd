@echo off
rem Double-click to run: bypasses execution policy; install.ps1 requests admin rights itself
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0install.ps1"
