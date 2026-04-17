# Tasks – News of the World

## Umsetzungsstrategie

Erst ein **stabiles MVP**, danach Verfeinerung. Keine voreiligen Extras.

---

## Phase 0 – Projektbasis

### T-001 Projekt initialisieren
- Xcode-Projekt für macOS-App anlegen
- sinnvolle Projektstruktur definieren
- Build-Konfigurationen festlegen
- Bundle Identifier, App Name und Signing-Kontext vorbereiten

### T-002 Architektur-Grundgerüst anlegen
- Domänenmodelle definieren
- Service-Interfaces / Ports definieren
- Adapter-Struktur festlegen
- Dependency Composition Root festlegen

### T-003 Basiskonfiguration
- Logging-Konzept definieren
- Error-Typen definieren
- grundlegende App-Konstanten strukturieren

---

## Phase 1 – Menüleisten-App und Ticker-Grundlage

### T-010 Menüleisten-App aufbauen
- Status-Bar-Icon anzeigen
- App als Menüleisten-App betreiben
- Klickverhalten definieren

### T-011 Ticker-Panel implementieren
- kleines Panel oder Popover unter der Menüleiste anzeigen
- Öffnen/Schließen implementieren
- Fokus- und Dismiss-Verhalten definieren

### T-012 Ticker-View erstellen
- horizontale Ticker-Fläche aufbauen
- Nachrichtenliste rendern
- Leerzustand rendern
- Ladezustand rendern
- Fehlerzustand rendern

### T-013 Laufschrift-Animation implementieren
- flüssige horizontale Bewegung
- sinnvolle Geschwindigkeit einstellbar machen
- sehr lange Texte robust behandeln
- Trennzeichen zwischen Headlines unterstützen

---

## Phase 2 – Quellenverwaltung

### T-020 Quellen-Domänenmodell implementieren
- NewsSource
- AuthConfig
- MappingConfig
- SourceType

### T-021 Quelle anlegen / bearbeiten / löschen
- Quelle erstellen
- Quelle validieren
- Quelle aktualisieren
- Quelle löschen

### T-022 Quellenliste in der UI
- Quellenübersicht anzeigen
- Aktiv/Inaktiv-Toggle
- Bearbeiten-Aktion
- Löschen-Aktion

### T-023 Validierung für Quellen
- Pflichtfelder prüfen
- URL validieren
- Intervall validieren
- Mapping-Konfiguration prüfen

### T-024 Quelle testen
- Test-Fetch für einzelne Quelle ausführen
- Erfolg/Fehler in UI anzeigen

---

## Phase 3 – Persistenz und Secrets

### T-030 Lokale Persistenz für Quellen
- Repository für Quellen definieren
- Speicherung lokal umsetzen
- Laden beim App-Start umsetzen

### T-031 Settings persistieren
- AppSettings speichern und laden
- Defaults sauber definieren

### T-032 API-Keys sicher speichern
- Keychain-Service definieren
- API-Key schreiben/lesen/löschen
- Verknüpfung zwischen Quelle und Keychain-Referenz umsetzen

### T-033 Migration / Datenversionierung vorbereiten
- serialisierte Daten versionieren
- robuste Deserialisierung vorsehen

---

## Phase 4 – News Fetching

### T-040 Fetching-Port definieren
- einheitliches Interface für das Laden von Nachrichten festlegen

### T-041 RSS/Atom Adapter implementieren
- Feed laden
- Feed parsen
- in `NewsItem` mappen

### T-042 JSON API Adapter implementieren
- Request ausführen
- Auth berücksichtigen
- Mapping-Regeln anwenden
- in `NewsItem` mappen

### T-043 Aggregation mehrerer Quellen
- mehrere Quellen parallel oder kontrolliert laden
- Ergebnisse zusammenführen
- sortieren
- deaktivierte Quellen ignorieren

### T-044 Fehlerisolierung pro Quelle
- Fehler je Quelle kapseln
- Teilresultate trotzdem anzeigen
- Fetch-Status aktualisieren

### T-045 Refresh-Mechanismus
- manuelles Refresh
- automatisches Refresh nach Intervall
- Deduplizierung der Requests

---

## Phase 5 – Settings und Systemintegration

### T-050 Settings-UI erstellen
- Theme-Einstellung
- Launch at Login
- Ticker-Geschwindigkeit
- Refresh-Intervall
- Quellendarstellung

### T-051 Launch at Login umsetzen
- Systemintegration für Start bei Anmeldung
- Setting mit tatsächlichem Systemstatus synchron halten

### T-052 Appearance-Verhalten umsetzen
- Light / Dark / System
- sofortige Übernahme der Einstellung

### T-053 Status- und Diagnoseanzeige
- letzte Aktualisierung anzeigen
- Fehlerstatus je Quelle anzeigen
- optional manuelles Refresh auslösen

---

## Phase 6 – Qualität und Härtung

### T-060 Unit Tests Domain / Services
- Quellvalidierung
- Mapping-Logik
- Aggregation
- Settings-Logik

### T-061 Adapter-Tests
- Feed-Parsing
- JSON-Mapping
- Persistenzadapter
- Keychain-Adapter

### T-062 UI-nahe Tests
- ViewModel-Zustände
- Settings-Flows
- Quellentest-Flow

### T-063 Resilienz und Edge Cases
- offline Verhalten
- leere Antworten
- defekte Antworten
- sehr große Headline-Listen

### T-064 Logging und Observability
- technische Logs verbessern
- keine Secrets loggen
- Fehlerdiagnose pro Quelle ermöglichen

---

## Priorisierung

### Muss zuerst
- T-001 bis T-013
- T-020 bis T-032
- T-040 bis T-045
- T-050 bis T-052

### Danach
- T-053
- T-060 bis T-064
- Datenmigration verfeinern

---

## Definition of Done je Task

Ein Task ist abgeschlossen, wenn:
- der Code gebaut werden kann
- die Architekturregeln eingehalten werden
- die Funktion testbar ist
- die Funktion ohne Workaround nutzbar ist
- keine offensichtlichen Secrets oder Anti-Patterns eingeführt wurden
