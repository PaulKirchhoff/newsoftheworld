# News of the World

A lightweight native macOS menu-bar app that displays headlines from your own sources as a horizontal ticker under the system menu bar. Supports RSS, Atom and generic JSON APIs, optionally authenticated with an API key stored securely in the macOS Keychain.

![Ticker panel under the menu bar](docs/screenshots/ticker.png)

## Contents

- [Overview](#overview)
- [System requirements](#system-requirements)
- [Install](#install)
- [Quickstart](#quickstart)
- [Usage](#usage)
- [Settings](#settings)
- [Connecting sources](#connecting-sources)
- [Behaviour and error states](#behaviour-and-error-states)
- [Data storage](#data-storage)
- [Architecture](#architecture)
- [Development](#development)
- [Release](#release)
- [Known limitations](#known-limitations)
- [License](#license)

## Overview

**News of the World** is a small macOS utility that aggregates news headlines from multiple sources and surfaces them as a calm horizontal ticker directly under the menu bar. Design priorities:

- **Lightweight** — no Electron layer, no third-party frameworks, minimal footprint.
- **Native** — Swift, SwiftUI + AppKit, standard macOS integrations (Keychain, App Sandbox, appearance).
- **Private** — everything stays local. No cloud sync, no analytics, no embedded SDKs.
- **Extensible** — new source types are added by implementing a single `NewsFetcher` protocol and registering it in the resolver.

## System requirements

To **run** the app (the signed, notarised release):

| Area | Requirement |
| --- | --- |
| Operating system | macOS 14 Sonoma or newer |
| CPU | Apple Silicon (arm64) |
| Permissions | App Sandbox with `com.apple.security.network.client` (shipped enabled) and Keychain access |
| Network | Internet access to the configured feed and API endpoints |
| Disk | < 10 MB for the app; sources and settings live inside the sandbox container |

To **build from source**:

| Area | Requirement |
| --- | --- |
| Xcode | Xcode 26 or newer (the project file uses `objectVersion = 77`, which older Xcode cannot open) |
| Swift | Swift 5 language mode; the compiler ships with Xcode |
| Signing (local dev) | Ad-hoc signing is sufficient; no Apple Developer account required |
| Signing (release) | Apple Developer Program membership and a "Developer ID Application" certificate — see [Release](#release) |

If `xcodebuild` from the terminal says "requires Xcode", point `xcode-select` at the full Xcode installation:

```sh
sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
```

## Install

### Homebrew (recommended)

```sh
brew tap paulkirchhoff/notw
brew install --cask newsoftheworld
```

Downloads the signed, notarised DMG from the GitHub release, installs the app into `/Applications`, and is accepted by Gatekeeper without any additional dialogs.

Upgrade to a newer release:

```sh
brew upgrade --cask newsoftheworld
```

### Build from source

```sh
git clone https://github.com/PaulKirchhoff/newsoftheworld.git
cd newsoftheworld
open newsoftheworld.xcodeproj
```

In Xcode: pick the **newsoftheworld** scheme, hit ⌘R. The debug build produces a regular `.app` bundle in DerivedData.

From the command line:

```sh
xcodebuild \
  -project newsoftheworld.xcodeproj \
  -scheme newsoftheworld \
  -configuration Debug \
  -destination 'platform=macOS' \
  build
```

## Quickstart

Assuming the app is installed and launched:

1. Click the newspaper icon in the menu bar → **Settings…**.
2. Switch to the **Sources** tab → **+ Add source**.
3. Fill in a sample source: Name `tagesschau business`, Type `JSON API`, URL `https://www.tagesschau.de/api2u/news/?regions=1&ressort=wirtschaft`, Save.
4. Menu bar icon → **Show ticker**. The panel slides in under the icon and starts scrolling after a few seconds.

## Usage

### Menu bar

![Status-bar menu](docs/screenshots/menu.png)

After launch a newspaper icon appears in the menu bar. Clicking it opens a three-item menu:

- **Show / Hide ticker** — toggles the scrolling panel. The label flips to reflect the current state.
- **Settings…** (⌘,) — opens the settings window.
- **Quit** (⌘Q) — quits the app.

The app is intentionally dock-less and window-less; it lives entirely in the menu bar.

### Ticker panel

The panel anchors itself directly under the menu-bar icon, floats above other windows, and stays visible on focus changes. It contains nothing but the horizontal ticker — no controls — so it stays visually quiet.

Rendering details:

- Category or kicker (when provided by the feed) rendered as a coloured prefix in front of the title.
- Configurable separator string between headlines.
- Single-line layout with edge clipping; long titles are handled cleanly.

## Settings

The settings window has two tabs.

### General

![General tab](docs/screenshots/settings-general.png)

- **Appearance** — System / Light / Dark; applies immediately to the ticker panel and the settings window.
- **Ticker speed** — 20–200 pt/s slider; effects are live.
- **Font size** — 11–22 pt slider.
- **Width** — 320–1200 pt slider for the ticker panel.
- **Show ticker on launch** — opens the panel automatically after app start.
- **Launch at login** — toggled through `SMAppService`; macOS may require confirmation in System Settings the first time.
- **Language** — system default plus explicit German, English, French and Spanish. Changes require an app relaunch; the UI offers to relaunch immediately.

### Sources

![Sources tab](docs/screenshots/settings-sources.png)

Lists every configured source. Each row shows:

- Status icon: active (coloured antenna), disabled (pause symbol), error (red triangle).
- Display name and endpoint URL.
- Type badge (RSS / Atom / JSON API).
- Key icon when an API key is stored for the source.
- Relative timestamp and item count of the last successful fetch, or the error message when something failed.

Interaction:

- **Double-click** a row to edit.
- **Right-click** for the context menu (*Edit*, *Refresh now*, *Remove*).
- **+ Add source** opens the source form for a new entry.

### Source form

![Source form sheet](docs/screenshots/source-form.png)

| Field | Description |
| --- | --- |
| Name | Free-form label; used only in the settings UI, never shown in the ticker. |
| Type | RSS, Atom or JSON API. |
| URL | Feed or API endpoint. https strongly recommended. |
| Enabled | Disabled sources are kept but not polled. |
| Refresh every | Polling interval, 1–60 minutes, default 5. |
| API key (optional) | Sent as `Authorization: Bearer <key>` and stored in the Keychain. |
| Test | Runs a one-shot fetch against the entered values and reports success or the error inline, without saving. |

When editing, the API key field is always empty. If a key is already stored this is indicated and can be either *Removed* or overwritten by typing a new value. The stored cleartext never leaves the Keychain; it is read on demand only when the fetcher builds the request.

Pressing **Save** persists the change and the scheduler re-polls the affected source immediately — no app restart required.

## Connecting sources

### RSS and Atom

Standards-compliant XML feeds work out of the box. For each `<item>` (RSS) or `<entry>` (Atom) the fetcher extracts (first match wins):

| Field | Accepted elements |
| --- | --- |
| Title | `<title>` |
| Link | `<link>…</link>` (RSS), `<link rel="alternate" href="…"/>` (Atom) |
| Date | `<pubDate>`, `<published>`, `<updated>`, `<dc:date>` |
| Summary | `<description>`, `<summary>`, `<content>` |
| Author | `<author>`, `<dc:creator>` |
| ID | `<guid>`, `<id>` |

Supported date formats: ISO-8601 (with or without fractional seconds) and RFC-822 (the typical RSS `pubDate`).

### Generic JSON API

The JSON fetcher auto-detects several common container shapes.

Accepted at the root:

1. An array of items: `[ {…}, {…} ]`.
2. An object with one of the keys `items`, `articles`, `news`, `results`, `data`, `entries`, `posts`.

For each item, the first matching key is used:

| Target | Accepted keys |
| --- | --- |
| Title | `title`, `headline`, `name` |
| URL | `url`, `link`, `canonical_url`, `permalink`, `detailsweb`, `shareURL` |
| Date | `publishedAt`, `published_at`, `pubDate`, `published`, `date`, `updated` |
| Summary | `summary`, `description`, `excerpt`, `firstSentence` |
| Author | `author`, `byline`, `creator` |
| ID | `id`, `guid`, `uuid`, `externalId`, `sophoraId` |
| Category | `topline`, `kicker`, `category` |

The category is rendered as a coloured prefix in the ticker, e.g. *"Hannover Messe: How deeply German industry has already adopted AI"*.

### Authentication

Currently only **Bearer tokens** via the `Authorization` header are supported. API keys as query parameters, Basic auth and custom headers are not implemented yet — see [Known limitations](#known-limitations).

Flow:

1. Enter the API key in the source form and save.
2. The key is written to the Keychain under service `de.paulkirchhoff.newsoftheworld`, account `source.<UUID>`.
3. Every fetch for that source adds `Authorization: Bearer <key>` to the request.

### Example: tagesschau business ressort

A real JSON API without an API key.

1. **+ Add source**.
2. Fields:
   - Name: `tagesschau business`
   - Type: `JSON API`
   - URL: `https://www.tagesschau.de/api2u/news/?regions=1&ressort=wirtschaft`
   - Enabled: yes
   - Refresh: 5 min
   - API key: (leave empty)
3. **Save** → the scheduler polls the source immediately.
4. **Menu → Show ticker** — headlines appear with the `topline` prefix, e.g. *"Rising DAX: Hope prevails on the stock market"*.

The response is an object keyed by `news`, which the fetcher recognises. Per item, `externalId`, `title`, `date`, `firstSentence`, `shareURL` and `topline` are mapped automatically — no extra configuration.

## Behaviour and error states

| Situation | What the ticker shows |
| --- | --- |
| No sources configured | "No sources configured" |
| All sources disabled | same |
| First fetch in progress, no items yet | "Loading headlines…" |
| At least one source delivered items | Running ticker with all items, sorted by date descending |
| One source fails, others succeed | The per-source error is recorded but hidden; the ticker keeps scrolling |
| All active sources fail | The error message of the first failing source is shown in the ticker |
| Source disabled or deleted | Its items disappear from the ticker immediately |

Refresh behaviour:

- Each active source runs its own independent scheduler task.
- Saving a source (add, edit, delete, toggle) re-fetches it immediately.
- An internal minimum interval of 30 seconds guards against accidental spam, even though the UI offers 1 minute as the lowest selectable value.

## Data storage

| What | Where |
| --- | --- |
| Settings | `UserDefaults`, key `app_settings_v1` |
| Sources | `~/Library/Containers/de.paulkirchhoff.newsoftheworld/Data/Library/Application Support/NewsOfTheWorld/sources.json` |
| API keys | macOS Keychain, service `de.paulkirchhoff.newsoftheworld`, account `source.<UUID>` |

The app runs sandboxed with exactly two entitlements: `com.apple.security.app-sandbox` and `com.apple.security.network.client`. No file or system access outside its own container.

## Architecture

Four cleanly separated layers. Full spec in `newsoftheworld-starter/ai-context/architecture.md`; contextual notes for Claude Code in `CLAUDE.md`.

```
Presentation    SwiftUI + AppKit — status-bar menu, ticker panel (NSPanel),
                settings window, view models
Application     Ports (NewsFetcher, repositories, SecretStore),
                services (RefreshCoordinator, FetcherResolver, SourceTester)
Domain          NewsItem, NewsSource, AppSettings, TickerState, AppLanguage
Infrastructure  URLSessionHTTPClient, XMLFeedFetcher, JSONFeedFetcher,
                JSONNewsSourceRepository, UserDefaultsSettingsRepository,
                KeychainSecretStore, SMAppServiceLaunchAtLoginAdapter
```

Consequences:

- Views never call networking, file or Keychain APIs directly — everything goes through ports in the Application layer.
- Domain models are framework-free, `Codable`, `Sendable` and `nonisolated`, so fetchers can construct them off the main actor.
- New source types are added by implementing `NewsFetcher` and registering the instance in `FetcherResolver`.

## Development

Run the full test suite (Swift Testing + XCTest):

```sh
xcodebuild \
  -project newsoftheworld.xcodeproj \
  -scheme newsoftheworld \
  -destination 'platform=macOS' \
  test
```

Run a single test:

```sh
xcodebuild \
  -project newsoftheworld.xcodeproj \
  -scheme newsoftheworld \
  -destination 'platform=macOS' test \
  -only-testing:newsoftheworldTests/JSONFeedFetcherTests/mapsTagesschauShapeWithToplineAndShareURL
```

The Xcode project uses **file-system synchronised groups** — new files under `newsoftheworld/` are picked up by the build automatically without editing `project.pbxproj`.

## Release

Releases are produced by a CI workflow in `.github/workflows/release.yml`. Pushing a `v*` tag triggers:

1. `xcodebuild archive` with Developer ID signing, hardened runtime and App Sandbox.
2. `xcodebuild -exportArchive` using `ExportOptions.plist` (developer-id / manual signing).
3. Notarisation of the `.app` via `xcrun notarytool --wait`, followed by stapling.
4. A signed, notarised, stapled DMG built with `create-dmg`, plus a second notarisation round for the DMG itself.
5. A GitHub Release created with the tag name, containing the DMG and its SHA-256 file as assets.
6. An automatic bump of the Homebrew cask in `PaulKirchhoff/homebrew-notw` with the new version and SHA, committed as `github-actions[bot]`.

Thus a full release is:

```sh
git tag v0.2.0
git push origin v0.2.0
```

Required GitHub repository secrets:

| Secret | Content |
| --- | --- |
| `DEVELOPER_ID_CERT_P12` | Base64 of the exported `Developer ID Application` certificate (`.p12`) |
| `DEVELOPER_ID_CERT_PASSWORD` | Password used to export the `.p12` |
| `KEYCHAIN_PASSWORD` | Any strong password used for the runner's temporary keychain |
| `APPLE_API_KEY_P8` | Contents of the App Store Connect `AuthKey_<ID>.p8` file |
| `APPLE_API_KEY_ID` | 10-character key identifier from App Store Connect |
| `APPLE_API_ISSUER_ID` | Issuer UUID from App Store Connect |
| `TAP_REPO_TOKEN` | Fine-grained PAT with `Contents: Read and write` on `PaulKirchhoff/homebrew-notw` |

For local release builds, `scripts/release.sh <version>` reproduces the same pipeline using a local Keychain profile `NEWS_OF_THE_WORLD_NOTARY` instead of CI secrets. The same `workflow_dispatch` entry point lets you dry-run the CI path from the Actions UI without creating a public release.

## Known limitations

- The JSON mapping uses a fixed set of candidate keys and is not yet per-source configurable.
- Authentication is Bearer-token only; no Basic auth, query-parameter keys or custom headers.
- Headlines are cached only in memory; a restart triggers a fresh fetch.
- No in-app auto-updates (`Sparkle` or similar) — users pick up new versions via `brew upgrade`.

## License

MIT — see [LICENSE](LICENSE).
