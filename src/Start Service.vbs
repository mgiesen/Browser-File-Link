Set fso = CreateObject("Scripting.FileSystemObject")
Set shell = CreateObject("WScript.Shell")
ps1Path = fso.GetParentFolderName(WScript.ScriptFullName) & "\BrowserFileLinkService.ps1"
shell.Run "powershell.exe -WindowStyle Hidden -ExecutionPolicy Bypass -File """ & ps1Path & """", 0
