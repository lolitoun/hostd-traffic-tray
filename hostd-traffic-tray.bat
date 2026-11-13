@echo off
rem [EN] Starts hostd-traffic-tray.ps1 (hostd daily traffic tray icons) without a console window.
rem      Keep this .bat in the same folder as hostd-traffic-tray.ps1, then double-click it.
rem [FR] Lance hostd-traffic-tray.ps1 (icones du trafic hostd du jour) sans fenetre noire.
rem      Garder ce .bat dans le meme dossier que hostd-traffic-tray.ps1, puis double-cliquer.
start "" conhost.exe --headless powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0hostd-traffic-tray.ps1"
