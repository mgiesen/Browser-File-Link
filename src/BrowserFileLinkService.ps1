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
#    eine Hilfestellung zu geben.

# --- KONFIGURATION ---

# Version des Skriptes
$version = "1.0.0"

# Der Port, auf dem der lokale Dienst lauscht.
$port = 55555

# Die Herkunft (Origin) der Redirect-Webseite, die auf den Dienst zugreifen darf.
# Dies ist eine CORS-Sicherheitsmaßnahme. Direkte Aufrufe aus dem Browser (ohne Origin-Header)
# sind immer erlaubt.
$allowedOrigin = "https://mgiesen.github.io"

# HTML-Vorlage für die Antwortseite.
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
    <script type="text/javascript">
        // Schließt dieses Fenster nach einer kurzen Verzögerung.
        setTimeout(function() {{ window.close(); }}, 1500);
    </script>
</head>
<body>
    <div class="container">
        <h1>Browser File Link</h1>
        <p class="status">&raquo;{0}&laquo;</p>
        <p class="note">Dieses Fenster schlie&szlig;t sich automatisch.</p>
        <p class="footer">&copy; mgiesen | v$version | <a href="https://github.com/mgiesen/Browser-File-Link" target="_blank">GitHub</a></p>
    </div>
</body>
</html>
"@ 

# --- HAUPTPROGRAMM ---

try {
    $listener = New-Object System.Net.HttpListener
    $listener.Prefixes.Add("http://localhost:$port/")
    $listener.Start()

    Write-Host "Dienst gestartet auf http://localhost:$port"
    Write-Host "Anfragen von der Webseite '$allowedOrigin' sind via CORS erlaubt."

    while ($listener.IsListening) {
        $context = $listener.GetContext()
        $request = $context.Request
        $response = $context.Response

        # CORS-Prüfung: Blockiert Anfragen von unerlaubten Webseiten.
        $requestOrigin = $request.Headers["Origin"]
        if ($requestOrigin -and $requestOrigin -ne $allowedOrigin) {
            Write-Warning "Anfrage von unerlaubter Herkunft '$requestOrigin' blockiert."
            $response.StatusCode = 403 # Forbidden
            $response.OutputStream.Close()
            continue
        }

        # Setzt den CORS-Header für gültige Antworten.
        $response.AddHeader("Access-Control-Allow-Origin", $allowedOrigin)

        # Behandelt CORS Preflight-Anfragen (OPTIONS).
        if ($request.HttpMethod -eq "OPTIONS") {
            $response.AddHeader("Access-Control-Allow-Methods", "GET, OPTIONS")
            $response.AddHeader("Access-Control-Allow-Headers", "Content-Type")
            $response.StatusCode = 204 # No Content
            $response.OutputStream.Close()
            continue
        }

        # --- ANFRAGE-ROUTING ---

        if ($request.Url.AbsolutePath -eq "/health") {
            $response.StatusCode = 200
            $buffer = [System.Text.Encoding]::UTF8.GetBytes("OK")
            $response.ContentLength64 = $buffer.Length
            $response.OutputStream.Write($buffer, 0, $buffer.Length)
        }
        elseif ($request.Url.Query -like "*open_path=*") {
            $openPath = $request.QueryString["open_path"]
            $statusText = ""

            try {
                if (Test-Path -LiteralPath $openPath) {
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
                }
                else {
                    $statusText = "Fehler: Der angegebene Pfad existiert nicht."
                    $response.StatusCode = 404 # Not Found
                }
            }
            catch {
                $statusText = "Fehler beim &Ouml;ffnen des Pfads: $($_.Exception.Message)"
                $response.StatusCode = 500 # Internal Server Error
            }
            
            $html = [string]::Format($htmlTemplate, $statusText)
            $buffer = [System.Text.Encoding]::UTF8.GetBytes($html)
            $response.ContentType = "text/html; charset=utf-8"
            $response.ContentLength64 = $buffer.Length
            $response.OutputStream.Write($buffer, 0, $buffer.Length)
        }
        else {
            $response.StatusCode = 400 # Bad Request
            $statusText = "Ungültige Anfrage. Bitte benutze '?open_path=...'"
            $buffer = [System.Text.Encoding]::UTF8.GetBytes($statusText)
            $response.ContentLength64 = $buffer.Length
            $response.OutputStream.Write($buffer, 0, $buffer.Length)
        }
        
        $response.OutputStream.Close()
    }
}
catch {
    Write-Error "Ein kritischer Fehler ist aufgetreten: $($_.Exception.Message)"
}
finally {
    if ($listener -and $listener.IsListening) {
        $listener.Stop()
        Write-Host "Dienst wurde beendet."
    }
}