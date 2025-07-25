# Browser-File-Link: Lokale Dateipfade einfach über den Browser öffnen

In vielen Unternehmensumgebungen ist es eine Herausforderung, direkt von Webanwendungen oder Dokumenten auf lokale Dateipfade (z.B. auf einem Firmen-Fileserver) zuzugreifen. Browser blockieren aus Sicherheitsgründen oft das direkte Öffnen von `file://`-URIs, was die Integration von internen Ressourcen erschwert.

**Browser-File-Link** ist eine schlanke PowerShell-Lösung, die genau dieses Problem umgeht. Sie startet einen einfachen lokalen HTTP-Server, der als Brücke zwischen deinem Browser und deinem lokalen Dateisystem fungiert. So kannst du Projektordner, Dokumente oder Tools, die auf einem Netzlaufwerk oder Fileserver liegen, bequem aus Anwendungen wie Microsoft Teams, SharePoint-Listen oder internen Webseiten heraus öffnen.

## Funktionsweise & Anwendungsfälle

Das Skript startet einen HTTP-Listener auf deinem PC (standardmäßig Port `55555`). Je nachdem, wo du die Links einsetzt, gibt es zwei empfohlene Methoden:

### 1. Direkter Aufruf (für Einzelnutzer)

Du erstellst Links, die direkt auf deinen lokalen Dienst zeigen:

```
http://localhost:55555/?open_path=C:/Pfad/Zum/Ordner
```

**Vorteil:** Sehr einfach und direkt
**Nachteil:** Bei Nutzung durch andere (z.B. in SharePoint) erscheint eine Fehlermeldung, falls der Dienst nicht installiert ist.

### 2. Aufruf über Redirect-Seite (empfohlen für Teams & SharePoint)

Du nutzt einen Link zur GitHub-Seite, die erkennt, ob der lokale Dienst läuft:

```
https://mgiesen.github.io/Browser-File-Link/?open_path=C:/Pfad/Zum/Ordner
```

**Vorteil:**

* Wenn der Dienst installiert ist: nahtloser Redirect
* Wenn **nicht**: Nutzer sieht eine Hilfeseite mit Anleitung

---

## Einrichtung und Verwendung

### Repository klonen oder herunterladen

```bash
git clone https://github.com/mgiesen/Browser-File-Link.git
cd Browser-File-Link
```

### Dienst für Autostart einrichten

Führe `Autostart.bat` per Doppelklick aus. Der Dienst startet bei jeder Windows-Anmeldung automatisch im Hintergrund. Keine Admin-Rechte nötig.

## Links erstellen und verwenden

### Option A: Direkter Link (für persönlichen Gebrauch)

```
http://localhost:55555/?open_path=C:/Dein/Pfad
```

### Option B: Redirect-Link (für Teams, SharePoint etc.)

```
https://mgiesen.github.io/Browser-File-Link/?open_path=\\FirmenServer\Projekte\ProjektX
```

> Hinweis: Bei UNC-Pfaden und Pfaden mit Leerzeichen empfiehlt sich URL-Encoding.


## Hinweise

* Das Skript muss **lokal** auf jedem Rechner laufen, der Links öffnen soll.
* Stelle sicher, dass der Port `55555` nicht von einer anderen Anwendung blockiert ist.
* Der Pfad im `open_path`-Parameter muss vom jeweiligen Rechner erreichbar sein.

## Beitrag

Ideen, Feedback und Pull Requests sind willkommen!
