@echo off
rem [EN] Starts hostd-traffic-tray.ps1 (hostd traffic tray icons).
rem      PowerShell opens minimized, then the script hides its own console window.
rem      Keep this .bat in the same folder as hostd-traffic-tray.ps1, then double-click it.
rem      -ExecutionPolicy Bypass applies to this one PowerShell process only.
rem [FR] Lance hostd-traffic-tray.ps1 (icones du trafic hostd).
rem      PowerShell s'ouvre reduit, puis le script cache sa propre fenetre.
rem      Garder ce .bat dans le meme dossier que hostd-traffic-tray.ps1, puis double-cliquer.
rem      -ExecutionPolicy Bypass ne vaut que pour ce lancement de PowerShell.
start "hostd-traffic-tray" /min powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0hostd-traffic-tray.ps1" -HideConsole
