@echo off
set "VBS_NAME=StartBrowserFileLinkService.vbs"
set "LINK_NAME=Browser File Link Service.lnk"
set "TARGET=%~dp0%VBS_NAME%"
set "AUTOSTART=%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup"

REM Temporaeres VBS-Skript zur Verknuepfungserstellung
set "VBS_SCRIPT=%TEMP%\create_link.vbs"

echo Set oWS = WScript.CreateObject("WScript.Shell") > "%VBS_SCRIPT%"
echo sLinkFile = "%AUTOSTART%\%LINK_NAME%" >> "%VBS_SCRIPT%"
echo Set oLink = oWS.CreateShortcut(sLinkFile) >> "%VBS_SCRIPT%"
echo oLink.TargetPath = "wscript.exe" >> "%VBS_SCRIPT%"
echo oLink.Arguments = """%TARGET%""" >> "%VBS_SCRIPT%"
echo oLink.WorkingDirectory = "%~dp0" >> "%VBS_SCRIPT%"
echo oLink.Save >> "%VBS_SCRIPT%"

REM Verknuepfung erstellen
cscript //nologo "%VBS_SCRIPT%"
del "%VBS_SCRIPT%"

echo [OK] Verknuepfung wurde im Autostart-Ordner erstellt.
start "" "%AUTOSTART%"

pause
