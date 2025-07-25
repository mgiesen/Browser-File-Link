Set wmi = GetObject("winmgmts:\\.\root\cimv2")
Set processes = wmi.ExecQuery("SELECT * FROM Win32_Process WHERE Name='powershell.exe'")

Dim found
found = False

For Each p In processes
    If InStr(p.CommandLine, "BrowserFileLinkService.ps1") > 0 Then
        p.Terminate()
        found = True
    End If
Next

If found Then
    MsgBox "Dienst wurde beendet.", 64, "Browser File Link"
Else
    MsgBox "Dienst war nicht aktiv.", 48, "Browser File Link"
End If
