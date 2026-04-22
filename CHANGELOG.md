# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.1.3] — 2026-04-22

### Added
- Ticker headlines are clickable — a tap opens the item's URL in the
  default browser and the cursor switches to a pointing hand while
  hovering a linked headline.
- Inline enable/disable switch on each row of the sources list, so a
  source can be paused without opening the edit dialog.

### Changed
- Ticker panel width is now stored as a percentage of the screen
  width (0–100 %, default 35 %) instead of an absolute point value,
  so the panel scales sensibly across different displays. Existing
  saved widths are migrated automatically on first launch.
- Hovering the cursor over the ticker freezes the scroll position;
  the animation resumes from the same spot on leave.
- Size changes from the settings sliders no longer snap the panel
  back under the menu-bar icon — only the initial show anchors to
  the icon, subsequent resizes preserve the visual top-left corner.
- README rewritten in English with accurate runtime vs.
  build-from-source requirements and a description of the
  tag-triggered CI release flow.

### Fixed
- First show of the ticker at launch no longer renders off-screen:
  the panel now waits until the status-bar anchor window has a real
  frame before positioning, and falls back to screen-center if the
  computed origin would lie outside every visible screen.
- String-catalog interpolation variants (refresh interval, item
  count, "updated ago", test-success message) were falling back to
  the raw key at runtime because the auto-generated format-specifier
  keys were left untranslated; all four now carry the correct
  de/en/fr/es translations.

## [0.1.2] — 2026-04-22

### Added
- Release workflow now auto-bumps the cask in the
  `PaulKirchhoff/homebrew-notw` tap after a successful release, so a
  `git push --tags` is the only manual action required for a new
  version to reach Homebrew users.
- The release workflow accepts a `workflow_dispatch` trigger for
  dry-runs: manual invocations produce a downloadable DMG artifact
  without creating a public GitHub release, useful for verifying the
  signing + notarisation chain without consuming a version number.

### Changed
- CI runner upgraded from `macos-14` to `macos-latest` with an
  explicit `latest-stable` Xcode selection, so the pipeline can open
  projects saved by Xcode 26 (pbxproj `objectVersion = 77`).

## [0.1.1] — 2026-04-21

### Changed
- Display name in Dock, Finder and Application Switcher is now
  "News of the World" (previously the raw bundle name `newsoftheworld`).

### Added
- Homebrew Cask install path documented in the README:
  `brew tap paulkirchhoff/notw && brew install --cask newsoftheworld`.
- `CHANGELOG.md` in Keep-a-Changelog format.
- GitHub Actions release workflow (`.github/workflows/release.yml`):
  builds, signs, notarises and publishes the DMG when a `v*` tag is
  pushed.

## [0.1.0] — 2026-04-21

### Added
- First public release.
- Native macOS menu-bar app (LSUIElement, no Dock icon) with a
  `NSStatusItem` menu: show/hide ticker, open settings, quit.
- Floating `NSPanel` ticker with time-based `TimelineView` animation,
  configurable speed / font size / panel width.
- Source management: RSS, Atom and generic JSON-API feeds with optional
  Bearer-token authentication, per-source refresh intervals (1–60 min).
- Independent per-source scheduler, error isolation, live status
  display (last fetch, item count, error message).
- API keys stored in the macOS Keychain (Generic Password, service
  `de.paulkirchhoff.newsoftheworld`).
- Sources persisted as JSON under
  `~/Library/Containers/de.paulkirchhoff.newsoftheworld/Data/Library/Application Support/NewsOfTheWorld/sources.json`.
- Settings persisted in `UserDefaults` under `app_settings_v1`.
- Appearance modes: System / Light / Dark, applied live.
- Auto-show ticker on launch, Launch-at-login via `SMAppService`.
- Localised menu and settings UI in German, English, French, Spanish.
- Unit tests for the JSON and XML feed parsers (Swift Testing).
- Signed with Developer ID and notarised by Apple.
- Distributed as a DMG via GitHub Releases and a Homebrew Cask in the
  `paulkirchhoff/notw` tap.

### Requirements
- macOS 14 Sonoma or newer, Apple Silicon.

[Unreleased]: https://github.com/PaulKirchhoff/newsoftheworld/compare/v0.1.3...HEAD
[0.1.3]: https://github.com/PaulKirchhoff/newsoftheworld/compare/v0.1.2...v0.1.3
[0.1.2]: https://github.com/PaulKirchhoff/newsoftheworld/compare/v0.1.1...v0.1.2
[0.1.1]: https://github.com/PaulKirchhoff/newsoftheworld/compare/v0.1.0...v0.1.1
[0.1.0]: https://github.com/PaulKirchhoff/newsoftheworld/releases/tag/v0.1.0
