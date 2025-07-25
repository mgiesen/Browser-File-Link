# File: BrowserFileLinkService.ps1
# Beschreibung: Ein einfaches PowerShell-Skript, das einen lokalen HTTP-Server startet, um lokale UNC-Pfade über den Browser zu öffnen.
# Repository: https://github.com/mgiesen/Browser-File-Link
# Autor: mgiesen
# Beispiel URL: http://localhost:55555/?open_path=C:/Users/gima

$version = "1.0.0"
$port = 55555

$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add("http://localhost:$port/")

$htmlTemplate = @"
<!DOCTYPE html>
<html>
<head>
    <title>Browser File Link</title>
    <style>
        body {{ font-family: sans-serif; text-align: center; margin-top: 50px; }}
        .container {{ max-width: 600px; margin: 0 auto; padding: 20px; border: 1px solid #ccc; border-radius: 8px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }}
        .status {{ font-size: 1.2em; margin-bottom: 20px; }}
        .note {{ color: #666; font-size: 0.9em; }}
        .footer {{ margin-top: 30px; font-size: 0.8em; color: #888; }}
    </style>
</head>
<body>
    <div class="container">
        <h1>Browser File Link</h1>
        <p class="status">&raquo;{0}&laquo;</p>
        <p class="note">Du kannst dieses Fenster nun schlie&szlig;en</p>
        <p class="footer">&copy; mgiesen | v$version | <a href="https://github.com/mgiesen/Browser-File-Link" target="_blank">GitHub</a></p>
    </div>
</body>
</html>
"@ 

Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;
public class Win32 {
    [DllImport("user32.dll")]
    [return: MarshalAs(UnmanagedType.Bool)]
    public static extern bool SetForegroundWindow(IntPtr hWnd);
}
"@ -Namespace User32

try {
    $listener.Start()
    while ($true) {
        $context = $listener.GetContext()
        $request = $context.Request
        $response = $context.Response

        $query = $request.QueryString
        $openPath = $query["open_path"]

        $response.StatusCode = 200
        $statusText = "Kein Pfad angegeben. Bitte verwenden Sie den Query-Parameter 'open_path'."

        if ($openPath) {
            try {
                if (Test-Path $openPath) {
                    $command = "Start-Process -FilePath explorer.exe -ArgumentList `"$openPath`""
                    Start-Process powershell.exe -ArgumentList "-NoProfile -WindowStyle Hidden -Command `"$command`""
                    
                    $statusText = "Der Pfad '$openPath' wurde erfolgreich ge&ouml;ffnet."
                }
                else {
                    $statusText = "Der Pfad '$openPath' existiert nicht."
                }
            }
            catch {
                $statusText = "Fehler beim &Ouml;ffnen des Pfads '$openPath': $($_.Exception.Message)"
            }
        }
        
        try {
            $html = [string]::Format($htmlTemplate, $statusText)
            $response.ContentType = "text/html; charset=utf-8"
            $buffer = [System.Text.Encoding]::UTF8.GetBytes($html)
            $response.ContentLength64 = $buffer.Length
            $response.OutputStream.Write($buffer, 0, $buffer.Length)
            $response.OutputStream.Close()
        }
        catch {
            $fallbackMessage = "Browser-File-Link Service hatte einen kritischer Fehler bei der Generierung der Antwort: $($_.Exception.Message)"
            $response.ContentType = "text/plain; charset=utf-8"
            $buffer = [System.Text.Encoding]::UTF8.GetBytes($fallbackMessage)
            $response.ContentLength64 = $buffer.Length
            $response.OutputStream.Write($buffer, 0, $buffer.Length)
            $response.OutputStream.Close()
        }
    }
}
finally {
    $listener.Stop()
}