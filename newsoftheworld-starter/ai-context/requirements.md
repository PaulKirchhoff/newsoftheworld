# Anforderungen – News of the World

## 1. Produktziel

**News of the World** ist eine kleine native macOS-Menüleisten-App, die aktuelle Nachrichten als horizontale Laufschrift in einem kleinen Panel direkt unter der Menüleiste anzeigt.

Die App soll es Benutzerinnen und Benutzern ermöglichen, eigene Nachrichtenquellen zu konfigurieren, diese dauerhaft zu speichern und das Verhalten der App über klassische Einstellungen zu steuern.

---

## 2. Produktvision

Die App soll:
- leichtgewichtig sein
- schnell starten
- nativ auf macOS laufen
- keinen unnötigen technologischen Overhead mitbringen
- mehrere Nachrichtenquellen unterstützen
- im Alltag unauffällig, aber jederzeit verfügbar sein

---

## 3. Zielplattform

- **Primär:** macOS
- **App-Typ:** Menüleisten-App / Status-Bar-App
- **UI-Paradigma:** kleines Utility, kein großes Hauptfenster erforderlich

---

## 4. Fachliche Kernfunktionen

### 4.1 Menüleisten-Integration

Die App muss:
- ein Icon in der macOS-Menüleiste anzeigen
- auf Klick oder definierte Interaktion ein Ticker-Panel öffnen bzw. schließen
- möglichst wenig Ressourcen verbrauchen

### 4.2 News-Ticker / Laufschrift

Die App muss:
- aktuelle Nachrichten als horizontale Laufschrift darstellen
- Nachrichten mehrerer Quellen zusammenführen können
- Headlines lesbar und flüssig animieren
- optional Quelle oder Kategorie der Nachricht mit anzeigen können

Die Laufschrift soll:
- kontinuierlich oder segmentweise laufen
- auch bei vielen Nachrichten stabil funktionieren
- bei fehlenden Nachrichten einen sinnvollen Zustand anzeigen

### 4.3 Quellenverwaltung

Die App muss ermöglichen:
- neue Quellen anzulegen
- vorhandene Quellen zu bearbeiten
- Quellen zu löschen
- Quellen zu aktivieren oder zu deaktivieren
- einer Quelle einen sprechenden Namen zu geben

Jede Quelle soll mindestens folgende Informationen unterstützen:
- Anzeigename
- Typ der Quelle
- URL oder Endpoint
- optional API-Key
- optional Header- oder Query-Parameter-Konfiguration
- optional Aktualisierungsintervall
- Aktiv/Inaktiv-Status

### 4.4 Unterstützte Quelltypen

Für die erste Version empfohlen:
- RSS Feed
- Atom Feed
- generische JSON API mit konfigurierbarem Mapping auf die Nachrichtenliste

Spätere Erweiterungen möglich:
- dedizierte Adapter für konkrete News-Anbieter
- Authentifizierungsvarianten über Bearer Token / Header
- Kategorien / Tags / Priorisierung

### 4.5 Persistenz

Die App muss Eingaben lokal speichern, insbesondere:
- konfigurierte Quellen
- API-Keys und Zugangsdaten
- UI- und Ticker-Einstellungen
- Startverhalten und Theme-Einstellungen

Wichtige Unterscheidung:
- **nicht sensible Einstellungen** können in `UserDefaults` gespeichert werden
- **sensible Daten** wie API-Keys gehören in den **macOS Keychain**

### 4.6 Einstellungen

Die App soll klassische Einstellungen bereitstellen, insbesondere:
- Start bei Anmeldung / Start on Startup
- Theme: Light / Dark / System
- Ticker-Geschwindigkeit
- Aktualisierungsintervall der Nachrichten
- Ein- / Ausschalten einzelner Quellen
- Verhalten beim Klick auf das Menüleisten-Icon
- optional Anzeige der Quelle je Nachricht
- optional Trennzeichen zwischen Headlines

### 4.7 Fehler- und Leerzustände

Die App muss sauber mit folgenden Fällen umgehen:
- keine Quelle konfiguriert
- Quelle liefert keine Nachrichten
- Feed/Endpoint ist nicht erreichbar
- API-Key fehlt oder ist ungültig
- Mapping-Konfiguration ist fehlerhaft
- Netzwerk langsam oder offline

Die App soll Fehler pro Quelle erkennen und anzeigen können, ohne den gesamten Ticker zu blockieren.

---

## 5. Nichtfunktionale Anforderungen

### 5.1 Performance

- schneller Start der App
- geringer Speicherverbrauch
- geringe CPU-Last im Idle-Betrieb
- flüssige Animation der Laufschrift
- keine unnötigen Netzwerkanfragen

### 5.2 Wartbarkeit

- klare Trennung von UI, Anwendunglogik, Persistenz und Integrationen
- testbare Kernlogik
- erweiterbare Quelladapter
- keine harte Kopplung an einzelne Anbieter

### 5.3 Sicherheit

- API-Keys nicht im Klartext in unsicheren lokalen Dateien speichern
- Keychain für Geheimnisse verwenden
- Logging darf keine Secrets enthalten
- Netzwerkfehler und ungültige Eingaben robust behandeln
- keine Ausführung fremder Inhalte aus JSON/Feeds

### 5.4 Benutzerfreundlichkeit

- Quellenanlage muss verständlich sein
- klare Beschriftungen in den Settings
- sensible Felder als Secret behandeln
- Rückmeldung bei Testen einer Quelle

### 5.5 Offline- und Resilienzverhalten

- App soll bei temporären Fehlern weiterlaufen
- zuletzt bekannte Nachrichten dürfen optional kurzzeitig angezeigt werden
- defekte Quelle darf nicht die ganze App unbenutzbar machen

---

## 6. Datenmodell – fachlich

### 6.1 NewsSource

Beschreibt eine Nachrichtenquelle.

Attribute:
- id
- name
- type
- endpointUrl
- isEnabled
- refreshIntervalSeconds
- authType
- apiKeyReference
- headers
- queryParameters
- mappingConfiguration
- createdAt
- updatedAt

### 6.2 NewsItem

Beschreibt eine geladene Nachricht.

Attribute:
- id oder stabiler Hash
- sourceId
- sourceName
- title
- url
- publishedAt
- summary (optional)
- category (optional)
- author (optional)

### 6.3 AppSettings

Beschreibt globale Einstellungen.

Attribute:
- launchAtLogin
- appearanceMode
- tickerSpeed
- refreshIntervalSeconds
- showSourceName
- separatorStyle
- panelWidthMode
- openBehavior

### 6.4 SourceFetchStatus

Beschreibt technischen Status einer Quelle.

Attribute:
- sourceId
- lastFetchAt
- lastSuccessAt
- lastErrorMessage
- consecutiveFailures
- lastItemCount

---

## 7. Benutzerfälle

### 7.1 Quelle anlegen
Als Benutzer möchte ich eine neue Nachrichtenquelle anlegen, damit deren Nachrichten im Ticker angezeigt werden können.

### 7.2 API-Key speichern
Als Benutzer möchte ich einen API-Key sicher speichern, damit eine geschützte Quelle genutzt werden kann.

### 7.3 Quellen deaktivieren
Als Benutzer möchte ich einzelne Quellen deaktivieren können, damit ich deren Inhalte temporär ausblenden kann.

### 7.4 Nachrichten lesen
Als Benutzer möchte ich aktuelle Schlagzeilen in der Menüleiste lesen, ohne eine große App zu öffnen.

### 7.5 App-Verhalten konfigurieren
Als Benutzer möchte ich Theme, Startverhalten und Ticker-Geschwindigkeit anpassen.

### 7.6 Fehler erkennen
Als Benutzer möchte ich sehen, wenn eine Quelle fehlerhaft ist, damit ich sie korrigieren kann.

---

## 8. MVP-Abgrenzung

### In Scope für MVP
- native Menüleisten-App
- Ticker-Panel
- RSS/Atom-Unterstützung
- generische JSON-API-Unterstützung mit einfachem Mapping
- Quellenverwaltung
- lokale Persistenz
- Keychain für API-Keys
- Settings
- manuelles und automatisches Aktualisieren

### Out of Scope für MVP
- Cloud-Sync
- Benutzerkonten
- iCloud-Synchronisation
- Volltextsuche über Nachrichtenhistorie
- komplexe Priorisierungsalgorithmen
- KI-Zusammenfassungen
- Push-Benachrichtigungen
- umfangreiche Analytics

---

## 9. Qualitätskriterien für die Umsetzung

Eine gute erste Version ist erreicht, wenn:
- die App stabil in der Menüleiste läuft
- mindestens mehrere Quellen konfigurierbar sind
- Nachrichten zuverlässig geladen und als Laufschrift angezeigt werden
- API-Keys sicher gespeichert werden
- Settings nach Neustart erhalten bleiben
- Fehler einzelner Quellen die App nicht insgesamt stören
