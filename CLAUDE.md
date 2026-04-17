# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

**News of the World** is a native macOS menu bar app that displays current headlines as a horizontal ticker in a small panel under the status bar. Users configure their own sources (RSS, Atom, generic JSON API) with optional API keys. See `newsoftheworld-starter/ai-context/` for the binding product and architecture spec (German).

## Required reading before non-trivial work

These files in `newsoftheworld-starter/ai-context/` are the authoritative spec — read them before designing or implementing features:

- `requirements.md` — full feature catalogue, domain model (`NewsSource`, `NewsItem`, `AppSettings`, `SourceFetchStatus`), MVP scope
- `architecture.md` — target layering (Presentation / Application / Domain / Infrastructure), ports/protocols, anti-patterns
- `decisions.md` — locked-in decisions (D-001..D-006) and still-open questions (O-001..O-004)
- `tasks.md` — phased roadmap T-001..T-064, MVP priority order
- `claude.md` — working rules and expected increment style

The nested `newsoftheworld-starter/.claude/CLAUDE.md` has additional project-specific working rules (focus on MVP, no business logic in Views, no direct Keychain/network access from Views).

## Build / run / test

Xcode project at the repo root: `newsoftheworld.xcodeproj`. Scheme: `newsoftheworld`. Target: macOS 26.4, Swift 5.0, bundle id `de.paulkirchhoff.newsoftheworld`.

```sh
# Build
xcodebuild -project newsoftheworld.xcodeproj -scheme newsoftheworld -configuration Debug build

# Run all unit + UI tests
xcodebuild -project newsoftheworld.xcodeproj -scheme newsoftheworld \
  -destination 'platform=macOS' test

# Run a single test (Swift Testing — tests live in newsoftheworldTests/)
xcodebuild -project newsoftheworld.xcodeproj -scheme newsoftheworld \
  -destination 'platform=macOS' test \
  -only-testing:newsoftheworldTests/newsoftheworldTests/example
```

Unit tests use **Swift Testing** (`import Testing`, `@Test`, `#expect`). UI tests under `newsoftheworldUITests/` use XCTest.

## Current state vs. target

The `newsoftheworld/` app folder still contains the default Xcode SwiftUI + SwiftData template (`Item`, `ContentView` with `NavigationSplitView`, `@Model class Item`, `ModelContainer` in `newsoftheworldApp.swift`). **This is scaffolding, not the target architecture.** The MVP requires a `MenuBarExtra`/`NSStatusItem`-based menu-bar app with a ticker panel — there is no `WindowGroup` main window in the product spec. Expect to replace or repurpose `Item.swift`, `ContentView.swift`, and the SwiftData container when building real features.

Persistence decision per `decisions.md` O-002 tends toward **JSON file in Application Support + `UserDefaults` for small global settings**, not SwiftData / Core Data. Re-evaluate before committing to the template's SwiftData setup for domain data.

## Architecture rules that bite

From `architecture.md` + `claude.md` — enforce these during every change:

- **No networking, Keychain, or persistence calls from SwiftUI Views.** Views render state; ViewModels coordinate; Use Cases / Services hold application logic; Adapters wrap infra.
- **Domain logic targets protocols (ports), not concrete adapters.** Wire concrete types only at the composition root.
- **Secrets (API keys) go in macOS Keychain.** Never in `UserDefaults`, JSON files, logs, or unnecessarily through UI state. Domain models reference secrets indirectly (e.g. `apiKeyReference`).
- **One source failing must not kill the ticker.** Isolate fetch errors per source; show partial results.
- **Split fetchers by `SourceType`** (`RSSFetcher`, `AtomFetcher`, `JSONAPIFetcher`) behind a dispatcher — do not build one mega-parser.
- No `print()` for error handling; use a typed logger with no secret leakage.
- Don't introduce dependencies when Foundation / AppKit / SwiftUI suffice. MVP scope excludes cloud sync, accounts, AI summaries, analytics, plugins.

## Language conventions

The spec docs (`ai-context/*.md`, starter `.claude/CLAUDE.md`) are in **German** — preserve German when editing them. Code identifiers, commit messages, and new docs stay English unless the user signals otherwise. User-facing UI strings are not yet decided.

## Repo layout quirk

`newsoftheworld-starter/` is a self-contained docs + `.claude/` bundle that ships alongside the app source. It has its own nested `.claude/commands/` (analyze-project, implement-next-task, review-architecture) — those are workflow prompts, not code to integrate. Don't delete or relocate this folder without asking; it's the project's knowledge base.
