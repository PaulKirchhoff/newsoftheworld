# News of the World – Claude Code Starter Pack

Dieses Paket enthält den fachlichen und architektonischen Startkontext für eine kleine macOS-Menüleisten-App namens **News of the World**.

## Ziel

Eine native macOS-App in der Menüleiste, die aktuelle Nachrichten als Laufschrift unter der Top Bar anzeigt. Die App soll mehrere Quellen unterstützen, darunter RSS/Atom-Feeds sowie API-basierte Quellen mit optionalem API-Key.

## Inhalt

- `ai-context/requirements.md` – Anforderungskatalog
- `ai-context/tasks.md` – Umsetzungsaufgaben und Roadmap
- `ai-context/architecture.md` – Zielarchitektur und Best Practices
- `ai-context/decisions.md` – Architektur- und Produktentscheidungen
- `ai-context/claude.md` – Arbeitskontext für Claude Code
- `.claude/CLAUDE.md` – Claude-Code-Instruktionen für dieses Projekt
- `.claude/commands/analyze-project.md` – Analyse-Prompt
- `.claude/commands/implement-next-task.md` – Implementierungs-Prompt
- `.claude/commands/review-architecture.md` – Architektur-Review-Prompt

## Empfohlener Start in Claude Code

1. Lege diese Dateien in dein Projekt.
2. Bitte Claude Code zuerst, die Dateien unter `ai-context/` vollständig zu lesen.
3. Lass dir eine konkrete Projektstruktur und die ersten Implementierungsschritte ableiten.
4. Starte mit dem Minimalumfang:
   - Menüleisten-App
   - Ticker-Panel
   - lokale Quellenverwaltung
   - Persistenz
   - Settings

## Empfohlene erste Arbeitsanweisung für Claude Code

Nutze folgende Dateien als verbindlichen Kontext:
- ai-context/requirements.md
- ai-context/tasks.md
- ai-context/architecture.md
- ai-context/decisions.md
- ai-context/claude.md

Aufgabe:
1. Analysiere Anforderungen und Zielarchitektur
2. Entwerfe eine konkrete initiale Projektstruktur
3. Definiere die wichtigsten Kernkomponenten
4. Plane die Implementierung für MVP Phase 1
5. Beginne noch nicht mit unnötigen Extras

Wichtig:
- Fokus auf native macOS-App
- Fokus auf wartbare Architektur
- Fokus auf MVP vor Perfektion
