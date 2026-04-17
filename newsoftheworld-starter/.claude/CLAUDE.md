# Claude Code Instructions – News of the World

Nutze folgende Dateien als verbindlichen Kontext:
- ai-context/requirements.md
- ai-context/tasks.md
- ai-context/architecture.md
- ai-context/decisions.md
- ai-context/claude.md

## Arbeitsregeln

- Analysiere zuerst Anforderungen und Zielarchitektur.
- Bevorzuge native macOS-Standards und einfache Lösungen.
- Halte die Umsetzung klein, sauber und inkrementell.
- Führe keine unnötigen Bibliotheken ein, wenn Standardmittel genügen.
- Halte dich an MVP-Scope.
- Keine Secrets im Klartext loggen oder speichern.
- Jede neue Komponente braucht eine klar benannte Verantwortung.
- Vermeide God Objects und unklare Zuständigkeiten.

## Erwartetes Vorgehen

1. Lese alle Kontextdateien.
2. Analysiere die bestehende Projektstruktur.
3. Schlage die nächsten 3 bis 5 sinnvollsten Schritte vor.
4. Implementiere schrittweise und begründe wichtige Architekturentscheidungen.
5. Prüfe nach jeder Änderung, ob die Architekturprinzipien noch eingehalten werden.

## Was vermieden werden soll

- Businesslogik in SwiftUI-Views
- direkte Infrastrukturaufrufe aus UI-Komponenten
- überladene ViewModels
- voreilige Generalisierung ohne aktuellen Bedarf
- unnötige externe Abhängigkeiten
