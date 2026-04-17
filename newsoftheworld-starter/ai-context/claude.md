# Claude Code Kontext – News of the World

## Projektmission

Baue eine kleine native macOS-Menüleisten-App namens **News of the World**.

Die App zeigt aktuelle Nachrichten als Laufschrift unter der Menüleiste an. Benutzer können eigene Quellen pflegen, darunter RSS/Atom-Feeds und API-basierte Quellen mit optionalen API-Keys. Quellen und Einstellungen werden lokal gespeichert. API-Keys werden sicher gespeichert.

---

## Verbindliche Umsetzungsziele

- native macOS-App
- leichtgewichtig
- sauber strukturiert
- testbar
- ohne unnötigen technologischen Overhead
- gute Systemintegration
- sichere Secret-Verwaltung

---

## Fachlicher Scope

Pflicht für MVP:
- Menüleisten-Icon
- Ticker-Panel
- Laufschrift mit Nachrichten
- Quellenverwaltung
- persistente Speicherung von Quellen und Settings
- sichere Speicherung von API-Keys
- Settings für Startverhalten, Theme und Ticker-Verhalten

Nicht zuerst bauen:
- Cloud-Features
- Nutzerkonten
- KI-Zusammenfassungen
- Analytics
- Plugin-System
- komplexe Synchronisation

---

## Architekturregeln

1. UI und Fachlogik sauber trennen.
2. Keine Netzwerklogik direkt in Views.
3. Keine Keychain-Zugriffe direkt aus Views.
4. Fachlogik gegen Protokolle / Ports modellieren.
5. Infrastrukturdetails in Adapter kapseln.
6. Fehler pro Quelle isoliert behandeln.
7. Keine Secrets loggen.
8. Keine unnötige Abhängigkeit einführen, wenn Standard-Frameworks ausreichen.

---

## Qualitätsmaßstab

Eine gute Lösung ist:
- klein
- klar
- robust
- gut benannt
- testbar
- fachlich nachvollziehbar

Eine schlechte Lösung ist:
- stark gekoppelt
- voll mit Singletons
- UI-lastig ohne Schichten
- unsicher im Umgang mit API-Keys
- unnötig komplex

---

## Arbeitsweise für Claude Code

Beim Arbeiten an diesem Projekt gilt:

1. Lies zuerst:
   - `ai-context/requirements.md`
   - `ai-context/tasks.md`
   - `ai-context/architecture.md`
   - `ai-context/decisions.md`
   - `ai-context/claude.md`

2. Prüfe danach den existierenden Code.

3. Ordne jede Änderung einer fachlichen Aufgabe oder einem Architekturziel zu.

4. Arbeite bevorzugt inkrementell:
   - zuerst Struktur
   - dann Kernfunktion
   - dann Härtung

5. Wenn du Architekturentscheidungen triffst, begründe sie kurz und konkret.

6. Halte dich an MVP-Fokus. Baue keine netten Extras, nur weil sie technisch interessant sind.

---

## Erwartung an Implementierungsvorschläge

Wenn du eine Änderung vorschlägst oder umsetzt, liefere:
- betroffene Schicht
- Ziel der Änderung
- kurze Begründung
- mögliche Risiken oder offene Punkte

---

## Bevorzugter Startpunkt

Empfohlene Reihenfolge:
1. Menüleisten-App-Grundgerüst
2. Ticker-Panel
3. Ticker-View + Zustandsmodell
4. Quellenmodell + Persistenz
5. Feed-Fetching
6. Settings
7. Tests und Härtung
