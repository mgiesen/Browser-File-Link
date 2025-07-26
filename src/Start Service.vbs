' WMI-Objekt zum Abfragen von Systeminformationen erstellen
Set wmi = GetObject("winmgmts:\\.\root\cimv2")

' Alle laufenden PowerShell-Prozesse abfragen
Set processes = wmi.ExecQuery("SELECT * FROM Win32_Process WHERE Name='powershell.exe'")

Dim isRunning
isRunning = False

' Die gefundenen Prozesse durchlaufen
For Each p In processes
    ' Prüfen, ob der spezifische Dienst (BrowserFileLinkService.ps1) in der Befehlszeile des Prozesses enthalten ist
    If InStr(p.CommandLine, "BrowserFileLinkService.ps1") > 0 Then
        isRunning = True
        Exit For ' Schleife beenden, da der Dienst gefunden wurde
    End If
Next

' Basierend auf dem Ergebnis handeln
If isRunning Then
    ' Wenn der Dienst bereits läuft, eine Warnung ausgeben
    MsgBox "Der Dienst wurde bereits gestartet", 48, "Browser File Link"
Else
    ' Wenn der Dienst nicht läuft, den Startvorgang einleiten
    Set fso = CreateObject("Scripting.FileSystemObject")
    Set shell = CreateObject("WScript.Shell")
    
    ' Den vollständigen Pfad zur PowerShell-Datei ermitteln
    ps1Path = fso.GetParentFolderName(WScript.ScriptFullName) & "\BrowserFileLinkService.ps1"
    
    ' Den PowerShell-Befehl ausführen, um den Dienst zu starten
    shell.Run "powershell.exe -WindowStyle Hidden -ExecutionPolicy Bypass -File """ & ps1Path & """", 0
End If