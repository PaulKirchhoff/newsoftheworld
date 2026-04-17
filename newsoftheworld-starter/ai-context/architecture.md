# Architektur – News of the World

## 1. Architekturziel

Die App soll klein bleiben, aber nicht chaotisch werden.

Ziel ist eine **leichtgewichtige, native macOS-Architektur** mit sauberer Trennung zwischen:
- UI
- Zustandssteuerung
- fachlicher Anwendungslogik
- Persistenz
- externer Kommunikation
- Systemintegration

Wichtig: Keine akademische Überarchitektur, aber auch kein unstrukturierter View-Logik-Sumpf.

---

## 2. Leitprinzipien

### 2.1 Native first
- Swift und macOS-Frameworks zuerst
- keine Web- oder Cross-Platform-Schicht für dieses Projekt

### 2.2 Separation of Concerns
- Views rendern Zustände
- ViewModels koordinieren UI-nahe Interaktionen
- Use Cases / Services enthalten Anwendungslogik
- Repositories und Adapter kapseln Technikdetails

### 2.3 Dependency Inversion
- Fachlogik kennt nur Protokolle / Ports
- konkrete Implementierungen werden am Rand injiziert

### 2.4 Small composable components
- lieber mehrere kleine Services statt großer God-Manager
- pro fachlicher Verantwortung ein klarer Typ

### 2.5 Secure by default
- Secrets nur im Keychain
- Logging ohne Geheimnisse
- technische Fehler robust behandeln

### 2.6 Fail soft
- eine defekte Quelle darf nicht den gesamten Ticker lahmlegen
- Teilergebnisse sind besser als Totalausfall

---

## 3. Empfohlene Schichten

## 3.1 Presentation Layer
Verantwortlich für:
- Menüleisten-Icon
- Panel / Fenster / Popover
- Settings-Views
- Quellenverwaltungs-Views
- ViewModels

Enthält z. B.:
- `TickerView`
- `SourcesView`
- `SettingsView`
- `TickerViewModel`
- `SourcesViewModel`
- `SettingsViewModel`
- `StatusBarController`
- `TickerPanelController`

Regeln:
- keine direkte Netzwerklogik in Views
- keine Persistenzlogik in Views
- keine Keychain-Zugriffe direkt aus Views

## 3.2 Application Layer
Verantwortlich für Anwendungsfälle.

Beispiele:
- Quellen anlegen
- Quellen aktualisieren
- Nachrichten aktualisieren
- Nachrichten aggregieren
- Quelle testen
- Settings laden/speichern
- Launch at Login setzen

Typische Komponenten:
- `FetchNewsUseCase`
- `ManageSourcesUseCase`
- `SaveSettingsUseCase`
- `TestSourceUseCase`
- `RefreshTickerUseCase`

Regeln:
- kennt nur Ports/Protokolle
- keine UI-spezifischen Details
- keine AppKit/SwiftUI-Abhängigkeit

## 3.3 Domain Layer
Verantwortlich für:
- Kernmodelle
- Validierungsregeln
- kleine fachliche Policies

Typische Modelle:
- `NewsSource`
- `NewsItem`
- `AppSettings`
- `FetchStatus`
- `SourceType`
- `AuthType`

Regeln:
- keine Framework-Abhängigkeiten wenn möglich
- Logik klein, klar und testbar halten

## 3.4 Infrastructure Layer
Verantwortlich für technische Integrationen.

Beispiele:
- RSS/Atom-Parser
- JSON API Client
- lokale Persistenz
- Keychain-Zugriff
- Launch-at-Login Adapter
- System Appearance Adapter

Typische Adapter:
- `URLSessionHTTPClient`
- `RSSFeedClient`
- `JSONNewsAPIClient`
- `UserDefaultsSettingsStore`
- `FileBasedSourcesRepository`
- `KeychainSecretStore`
- `LaunchAtLoginAdapter`

---

## 4. Ports / Protokolle

Die fachliche Logik soll gegen Protokolle arbeiten, zum Beispiel:

- `NewsSourceRepository`
- `SettingsRepository`
- `SecretStore`
- `NewsFetcher`
- `NewsAggregationService`
- `LaunchAtLoginService`
- `Clock`
- `Logger`

So bleibt die App testbar und austauschbar.

---

## 5. Vorschlag für Projektstruktur

```text
NewsOfTheWorld/
  App/
    NewsOfTheWorldApp.swift
    CompositionRoot/

  Presentation/
    StatusBar/
    Ticker/
    Sources/
    Settings/
    Shared/

  Application/
    UseCases/
    Services/
    DTOs/

  Domain/
    Models/
    ValueObjects/
    Policies/
    Errors/

  Infrastructure/
    Networking/
    Feeds/
    Persistence/
    Security/
    System/
    Logging/

  Tests/
    Unit/
    Integration/
```

Wenn du es kleiner halten willst, kannst du Application/Domain/Infrastructure anfangs weniger fein schneiden. Aber die Trennung sollte logisch trotzdem bestehen.

---

## 6. Technische Prinzipien für die Umsetzung

### 6.1 MVVM sinnvoll, aber nicht religiös
Für SwiftUI ist MVVM praktikabel.

Aber:
- ViewModels sollen keine halben Repositories werden
- komplexe Fachlogik gehört in Services / Use Cases

### 6.2 Composition Root zentral halten
Die Verkabelung konkreter Implementierungen gehört an einen klaren Ort.
Nicht wild in jeder View neue Services erzeugen.

### 6.3 Asynchronität sauber kapseln
- Netzwerkzugriffe klar kapseln
- Main-Thread nur für UI
- Zustandswechsel nachvollziehbar halten

### 6.4 Fehler als Domäne behandeln
- saubere Error-Typen
- pro Quelle differenzierbar
- verständliche UI-Meldungen aus technischen Fehlern ableiten

### 6.5 Kein Secret-Leak
- API-Key nicht im UI-State herumreichen, wenn unnötig
- niemals Secret-Werte loggen
- nach Speichern möglichst nur Referenz halten

### 6.6 Testbarkeit einplanen, nicht nachträglich ankleben
- Mapper
- Validierung
- Aggregation
- Refresh-Logik
- Persistenz-Schnittstellen

---

## 7. Empfohlene Persistenzstrategie

### Nicht-sensitive Daten
- Quellenmetadaten
- Settings
- UI-Präferenzen

Speicherort:
- Datei im Application Support Verzeichnis oder strukturierte lokale Speicherung
- kleine Settings optional in `UserDefaults`

### Sensitive Daten
- API-Keys
- Tokens

Speicherort:
- macOS Keychain

Regel:
- Fachliches Modell referenziert Secrets indirekt
- konkrete Secret-Werte werden nur bei Bedarf aufgelöst

---

## 8. Adapterstrategie für Quellen

Nicht jede Quelle gleich hart codieren.

Empfehlung:
- `SourceType.rss`
- `SourceType.atom`
- `SourceType.jsonApi`

Dazu ein Dispatcher oder Resolver, der je nach Quelltyp den passenden Fetcher wählt.

Beispielhafte Verantwortung:
- `RSSFetcher` → lädt und parst RSS
- `AtomFetcher` → lädt und parst Atom
- `JSONAPIFetcher` → lädt JSON und wendet Mapping an

Das verhindert, dass ein einzelner Monster-Parser entsteht.

---

## 9. UI-Prinzipien

- Menüleisten-App bleibt klein und direkt
- Settings verständlich statt überladen
- Quelleneingabe mit klaren Feldern
- Test-Button für Quelle
- sichtbare technische Diagnose, aber nicht erschlagend

Für das Ticker-Panel:
- Fokus auf Lesbarkeit
- ruhige Animation
- kein visuelles Gewitter
- lange Headlines elegant behandeln

---

## 10. Architektur-Anti-Patterns, die vermieden werden sollen

- Netzwerkcode direkt in SwiftUI-Views
- Keychain-Zugriffe direkt aus dem UI
- ein einzelner globaler Singleton für alles
- AppKit-/SwiftUI-Code vermischt mit Parsing-Logik
- ungeprüfte Speicherung von API-Keys in Klartext
- unstrukturierte Fehlerbehandlung mit bloßem `print()`
- zu frühe Plugin-Architektur ohne Bedarf

---

## 11. MVP-Architekturentscheidung

Für MVP reicht:
- native macOS-App
- MVVM in der Presentation
- Use Cases / Services in der Application
- klare Models in der Domain
- Adapter in Infrastructure

Das ist klein genug, um schnell zu liefern, und sauber genug, um später nicht alles wegwerfen zu müssen.
