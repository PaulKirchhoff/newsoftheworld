# Entscheidungen – News of the World

## Bereits getroffene Leitentscheidungen

### D-001 Native macOS statt Cross-Platform
**Entscheidung:** Die App wird nativ für macOS umgesetzt.

**Begründung:**
- Ziel ist eine kleine Menüleisten-App
- geringe Laufzeitkosten
- beste Integration in Menüleiste, Panel und Systemeinstellungen
- geringerer Overhead als Electron/Tauri für diesen Use Case

---

### D-002 Fokus auf Menüleisten-App
**Entscheidung:** Kein klassisches großes Hauptfenster als Kerninteraktion.

**Begründung:**
- Produktziel ist ein Utility in der Top Bar
- schneller Zugriff ohne App-Wechsel

---

### D-003 Quellen lokal konfigurierbar
**Entscheidung:** Benutzer pflegen Quellen direkt in der App.

**Begründung:**
- keine Backend-Abhängigkeit nötig
- passt zum Utility-Charakter

---

### D-004 Secrets sicher speichern
**Entscheidung:** API-Keys gehören in die Keychain.

**Begründung:**
- Klartextspeicherung wäre unnötig riskant
- macOS bietet dafür eine etablierte Lösung

---

### D-005 MVP zuerst schlank halten
**Entscheidung:** Erst RSS/Atom + generische JSON-API statt sofort viele Spezialintegrationen.

**Begründung:**
- hoher Nutzwert mit überschaubarem Aufwand
- vermeidet frühe Verzettelung

---

### D-006 Architektur: sauber, aber leichtgewichtig
**Entscheidung:** Klare Schichten und Ports, aber keine übertriebene Enterprise-Architektur.

**Begründung:**
- Projekt ist klein
- trotzdem sollen Testbarkeit und Wartbarkeit erhalten bleiben

---

## Offene Entscheidungen

### O-001 Panel oder Popover
Zu klären in der Umsetzung:
- klassisches Popover
- eigenes schmales Panel/Fenster

Empfehlung aktuell:
- eher Panel/Fenster bei echter Laufschrift

### O-002 Persistenzformat für Quellen
Zu klären:
- JSON-Datei im Application Support
- Core Data / SwiftData
- reine UserDefaults-Lösung

Empfehlung aktuell:
- JSON-Datei + UserDefaults für kleine globale Settings

### O-003 JSON-Mapping-UX
Zu klären:
- einfaches Path-Mapping
- vordefinierte Standardfelder
- erweiterbare Mapping-Struktur

Empfehlung aktuell:
- einfache Mapping-Konfiguration für Liste, Titel, URL, Datum

### O-004 Caching von Nachrichten
Zu klären:
- gar kein Cache
- nur In-Memory
- letzter erfolgreicher Stand lokal

Empfehlung aktuell:
- zunächst In-Memory, optional später letzter erfolgreicher Stand lokal
