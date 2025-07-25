# Browser-File-Link: Lokale Dateipfade einfach über den Browser öffnen

In vielen Unternehmensumgebungen ist es eine Herausforderung, **direkt von Webanwendungen oder Dokumenten auf lokale Dateipfade** (z.B. auf einem Firmen-Fileserver) zuzugreifen. Browser blockieren aus Sicherheitsgründen oft das direkte Öffnen von `file://` URIs, was die Integration von internen Ressourcen erschwert.

Der **Browser-File-Link** ist eine schlanke PowerShell-Lösung, die genau dieses Problem umgeht. Sie startet einen einfachen, lokalen HTTP-Server, der als Brücke zwischen deinem Browser und deinem lokalen Dateisystem fungiert. So kannst du beispielsweise **Projektordner, Dokumente oder Tools, die auf einem Netzlaufwerk oder Fileserver liegen, bequem aus Anwendungen wie Microsoft Teams, SharePoint-Listen oder internen Webseiten heraus öffnen.**

## Funktionsweise

Das Skript startet einen HTTP-Listener auf einem definierten Port (standardmäßig `55555`). Du kannst dann URLs in folgendem Format verwenden:

`http://localhost:55555/?open_path=C:/Pfad/Zum/Ordner`

Der `open_path`-Parameter erwartet den **vollständigen Pfad** zu einer Datei oder einem Ordner auf deinem lokalen System oder einem erreichbaren Netzlaufwerk (UNC-Pfad). Der Server nimmt die Anfrage entgegen, validiert den Pfad und verwendet `Invoke-Item`, um den Pfad zu öffnen. Nach dem Öffnen wird eine Bestätigungsseite im Browser angezeigt.

Wichtig: Damit die Links funktionieren, muss der Dienst **dauerhaft auf jedem Client aktiv sein**, der mit den Links arbeiten soll. Das bedeutet, dass das PowerShell-Skript beim Windows-Start automatisch im Hintergrund gestartet werden sollte.

### Autostart einrichten (empfohlene Methode)

Für die einfache Integration in den Autostart empfehlen wir die mitgelieferte Datei `Enable Autostart.bat`. Diese erstellt eine Verknüpfung zu einem versteckt startenden Dienstskript im Autostart-Ordner des aktuellen Benutzers.

**Vorteile dieser Methode:**

* Kein Administrator-Zugriff erforderlich
* Kompatibel mit den meisten Unternehmensrichtlinien
* Der Dienst startet unauffällig im Hintergrund bei jedem Windows-Login

Nach der Ausführung von `Enable Autostart.bat` wird der Autostart-Ordner geöffnet, sodass du die Verknüpfung direkt kontrollieren kannst.

## Einrichtung und Verwendung

1. **Klon das Repository:**

   ```bash
   git clone https://github.com/mgiesen/Browser-File-Link.git
   cd Browser-File-Link
   ```

2. **Aktiviere den Autostart:**
   Führe `Enable Autostart.bat` per Doppelklick aus, um die Autostart-Verknüpfung einzurichten.

3. **Verwende die Links:**
   Erstelle Links in deiner gewünschten Anwendung (z.B. MS Teams, SharePoint) im Format:
   `http://localhost:55555/?open_path=C:/Pfad/Zu/Deinem/Projektordner`
   oder für einen UNC-Pfad:
   `http://55555/?open_path=\\DeinFileserver\Projekte\ProjektX`

   *Beachte: Bei UNC-Pfaden und Pfaden mit Leerzeichen ist es ratsam, die URL zu kodieren, wenn die Zielplattform dies nicht automatisch tut.*

## Hinweise

* Das Skript muss **lokal auf deinem Rechner ausgeführt** werden, der die Links öffnen soll. Es ist kein zentraler Serverdienst.

* Stell sicher, dass der gewählte Port (Standard: 55555) auf deinem Rechner nicht bereits belegt ist.

* Der Pfad im `open_path`-Parameter muss für deinen Rechner zugänglich sein.

## Beitrag

Ideen und Verbesserungen sind jederzeit willkommen! Erstelle gerne einen Issue oder reiche einen Pull Request ein.