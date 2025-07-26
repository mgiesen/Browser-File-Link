# File: BrowserFileLinkService.ps1
# Autor: mgiesen
# Repository: https://github.com/mgiesen/Browser-File-Link
#
# Beschreibung: 
# Lokaler HTTP-Server zum Öffnen von Datei- und Ordnerpfaden im Explorer per HTTP-Aufruf.
#
# Anwendungsfälle:
# 1. Direkter Aufruf: 'http://localhost:55555/?open_path=C:/...' 
#    kann direkt im Browser aufgerufen werden.
#
# 2. Redirect-Seite: Dient als Vermittler, um Nutzern ohne lokal ausgeführten Dienst 
#    eine Hilfestellung zu geben. Aufruf: 'https://mgiesen.github.io/Browser-File-Link/?open_path=C:/...'

# Version des Skriptes
$version = "1.0.0"

# Der Port, auf dem der lokale Dienst lauscht.
$port = 55555

# HTML-Vorlage für die Antwortseite.
$htmlTemplate = @"
<!DOCTYPE html>
<html>
<head>
    <title>Browser File Link</title>
    <style>
        body {{ font-family: sans-serif; text-align: center; margin-top: 50px; }}
        .container {{ max-width: 600px; margin: 0 auto; padding: 20px; border: 1px solid #ccc; border-radius: 8px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }}
        .container.status-success {{ background-color: #a9d1a9ff; }}
        .container.status-warning {{ background-color: #ffe4b3; }}
        .status {{ font-size: 1.2em; margin-bottom: 20px; }}
        .note {{ color: #666; font-size: 0.9em; }}
        .footer {{ margin-top: 30px; font-size: 0.8em; color: #888; }}
    </style>
    {3}
</head>
<body>
    <div class="container {1}">
        <h1>Browser File Link</h1>
        <p class="status">&raquo;{0}&laquo;</p>
        <p class="note">{2}</p>
        <p class="footer">&copy; mgiesen | v$version | <a href="https://github.com/mgiesen/Browser-File-Link" target="_blank">GitHub</a></p>
    </div>
</body>
</html>
"@ 

# --- HAUPTPROGRAMM ---

try 
{
    $listener = New-Object System.Net.HttpListener
    $listener.Prefixes.Add("http://localhost:$port/")
    $listener.Start()

    Write-Host "Dienst gestartet auf http://localhost:$port"
    Write-Host "Anfragen von Webseiten sind via CORS erlaubt."

    while ($listener.IsListening) 
    {
        $context = $listener.GetContext()
        $request = $context.Request
        $response = $context.Response

        # --- CORS-Handling ---
        # Erlaubt Anfragen von jeder Origin, indem der empfangene Origin-Header zurückgespiegelt wird.
        $requestOrigin = $request.Headers["Origin"]
        if ($requestOrigin) 
        {
            $response.AddHeader("Access-Control-Allow-Origin", $requestOrigin)
        }

        # Behandelt CORS Preflight-Anfragen (OPTIONS).
        if ($request.HttpMethod -eq "OPTIONS") 
        {
            $response.AddHeader("Access-Control-Allow-Methods", "GET, OPTIONS")
            $response.AddHeader("Access-Control-Allow-Headers", "Content-Type")
            $response.StatusCode = 204 # No Content
            $response.OutputStream.Close()
            continue
        }

        # --- ANFRAGE-ROUTING ---
        
        # Standardwerte für die dynamischen HTML-Teile
        $statusText = ""
        $statusClass = "status-warning"
        $noteText = "Das Fenster bleibt zur Ansicht ge&ouml;ffnet."
        $scriptBlock = ""

        # Health Check für Redirect Service
        if ($request.Url.AbsolutePath -eq "/health") 
        {
            $response.StatusCode = 200
            $buffer = [System.Text.Encoding]::UTF8.GetBytes("OK")
            $response.ContentLength64 = $buffer.Length
            $response.OutputStream.Write($buffer, 0, $buffer.Length)
            $response.OutputStream.Close()
            continue
        }
        elseif ($request.Url.Query -like "*open_path=*") 
        {
            $openPath = $request.QueryString["open_path"]

            if ([string]::IsNullOrEmpty($openPath)) 
            {
                $statusText = "Deine Anfrage enth&auml;lt keinen g&uuml;ltigen Pfad"
                $response.StatusCode = 400 # Bad Request
            }
            else 
            {
                try 
                {
                    if (Test-Path -LiteralPath $openPath) 
                    {
                        # Da die Ausführung des Skriptes im Hintergrund erfolgt, muss ein neuer PowerShell-Prozess gestartet werden, um den Explorer im Vordergrund zu öffnen.
                        # Die Powershell öffnet langsamer als die CMD, behandelt aber relative UNC-Pfade sicherer.
                        $command = "& {
                            Write-Host 'Der Aufruf des Dateipfades wird vorbereitet...';
                            Start-Process explorer.exe -ArgumentList \`"$openPath\`";
                            Start-Sleep -Seconds 2
                        }"

                        # Startet einen neuen PowerShell-Prozess ohne Laden des Benutzerprofils (-NoProfile),
                        Start-Process "powershell.exe" -ArgumentList "-NoProfile -Command $command"

                        $statusText = "Der Pfad wurde erfolgreich ge&ouml;ffnet."
                        $statusClass = "status-success"
                        $noteText = "Dieses Fenster schlie&szlig;t sich automatisch."
                        $scriptBlock = '<script type="text/javascript">setTimeout(function() { window.close(); }, 1500);</script>'
                        $response.StatusCode = 200 # OK
                    }
                    else 
                    {
                        $statusText = "Der angegebene Pfad konnte nicht ge&ouml;ffnet werden"
                        $response.StatusCode = 404 # Not Found
                    }
                }
                catch {
                    $statusText = "Fehler beim &Ouml;ffnen des Pfads: $($_.Exception.Message)"
                    $response.StatusCode = 500 # Internal Server Error
                }
            }
        }
        else 
        {
            $response.StatusCode = 400 # Bad Request
            $statusText = "Deine Anfrage erf&uuml;llt nicht die erwartete URL Struktur"
        }

        $html = [string]::Format($htmlTemplate, $statusText, $statusClass, $noteText, $scriptBlock)
        $buffer = [System.Text.Encoding]::UTF8.GetBytes($html)
        $response.ContentType = "text/html; charset=utf-8"
        $response.ContentLength64 = $buffer.Length
        $response.OutputStream.Write($buffer, 0, $buffer.Length)
        
        $response.OutputStream.Close()
    }
}
catch 
{
    Write-Error "Ein kritischer Fehler ist aufgetreten: $($_.Exception.Message)"
}
finally 
{
    if ($listener -and $listener.IsListening) 
    {
        $listener.Stop()
        Write-Host "Dienst wurde beendet."
    }
}