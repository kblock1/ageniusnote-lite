# Changelog

All notable changes to AgeniusNote Lite are documented here.

Format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/). Versions follow [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Changed
- **Bundled `AgeniusNoteLite.exe` now ships with populated Windows file properties** (Company, FileDescription, ProductName, FileVersion, LegalCopyright). The PyInstaller spec generates a VSVersionInfo file from `packaging/VERSION` on each Windows build and passes it via `EXE(version=...)`. AV engines and SmartScreen treat exes with blank version resources as more suspicious, so populating them is the cheapest available trust signal short of a code-signing certificate.
- **Installer (Inno Setup) carries richer file-properties metadata.** Added `AppCopyright`, `UninstallDisplayName`, `SetupMutex`, and `VersionInfoVersion` / `VersionInfoCompany` / `VersionInfoDescription` / `VersionInfoCopyright` / `VersionInfoProductName` / `VersionInfoProductVersion`. The installer .exe now identifies itself in the Details tab the way a normal commercial installer would, reducing AV heuristic flags.

### Added
- **Code-signing wiring stub in `packaging/installer.iss`.** `SignTool=` / `SignedUninstaller=yes` directives are present but commented out, with an inline guide for enabling them once an OV / EV code-signing certificate is available. Until then, the lines remain inert.
- **README: "If Windows blocks the installer" section.** Step-by-step for clicking past SmartScreen, restoring Defender-quarantined files, and submitting the installer to Microsoft / third-party AV vendors as a false-positive report. Shortens the path from "Windows blocked it" to "installed successfully" and gives users a way to help reduce the warning for everyone.

### Notes
- The `AppId` in `installer.iss` is deliberately left as the existing string `{B9F1A2E0-7B5C-4F4F-9E2D-AGENIUSNOTELITE}`, even though it isn't a valid hex GUID. Inno Setup treats `AppId` as an opaque identifier, and changing it would orphan every existing v1.0.x install (the upgrader keys off this exact value). The malformed-hex AppId is purely cosmetic and is not the cause of any SmartScreen / AV behavior.

## [1.0.2] - 2026-05-20

### Fixed
- **In-app version label drift.** The window title was hardcoded to "1.0.0" even after the package bumped to 1.0.1, which made support triage confusing. The version is now read at runtime from `packaging/VERSION`, bundled into the PyInstaller `.app` / installer payload so frozen mode resolves correctly.
- **`build.ps1 -SkipBuild` and `build.sh SKIP_BUILD=1` are no longer broken.** Both scripts used to allocate a fresh timestamped output directory even when re-running just the installer/DMG step, so the packaging tools would point at an empty path. They now reuse the most recent `dist-build-*` (Win) or `dist-build-mac-*` (macOS) directory that contains a built bundle.
- **`scripts/build_icon.py`** now writes generated icons to `<repo_root>/assets/`. Previously it wrote to `voice_notes_v3/assets/`, a monorepo-only path that does not exist in this OSS repo, so re-running the script silently produced files that nobody saw.

### Changed
- Top-of-file docstring in `voice_notes_lite.py` corrected: the default hotkey is `Ctrl+Alt+M`, not `Ctrl+Alt+Space`.

## [1.0.1] - 2026-05-20

### Fixed
- Transcription crash on first run after installer launch. The PyInstaller bundle was missing `yaml` and a couple of CTranslate2 runtime data files, so the first hotkey press would raise `ModuleNotFoundError: No module named 'yaml'` before the model loaded. Spec now keeps `yaml` and pulls the required CTranslate2 assets explicitly.

### Added
- **Collapse toggle** on the Lite window. Click the chevron to shrink the window to a compact strip that still shows the recording indicator. Useful when you want the hotkey workflow without the full notepad pane on screen.
- **Background model preload.** `base.en` (or whatever `VN_LITE_MODEL` is set to) is loaded on a worker thread at app startup instead of on first hotkey press. First transcription is now snappy instead of paying the model-load cost mid-dictation.
- **Intel Mac build path** added to the GHA workflow (matrix job on macos-13).

### Changed
- Mac DMG naming now includes the architecture suffix. Old `AgeniusNoteLite-Setup-x.y.z.dmg` is replaced by `AgeniusNoteLite-Setup-x.y.z-arm64.dmg`.

### Known limitations
- **Intel Mac DMG not attached to this release.** GitHub Actions' macos-13 Intel runner pool failed to assign a runner within 65+ minutes after the tag push, so the Intel build was canceled. Apple Silicon Mac users are unaffected. The build path is wired and ready; we'll attach `AgeniusNoteLite-Setup-1.0.1-x86_64.dmg` to this release as soon as a runner becomes available. Track [the v1.0.1 release page](https://github.com/Agenius-AI-Labs/ageniusnote-lite/releases/tag/v1.0.1) or file an issue if you're blocked on Intel.

## [1.0.0] - 2026-05-16

### Added
- Initial public release.
- Push-to-talk dictation via global hotkey (default `Ctrl+Alt+M`), pastes transcription into the focused window.
- In-window record button (no auto-paste mode).
- Local speech-to-text with [faster-whisper](https://github.com/SYSTRAN/faster-whisper), `base.en` by default. Configurable via `VN_LITE_MODEL`.
- CPU and CUDA device strategies via `VN_LITE_DEVICE`.
- Configurable hotkey via `VN_LITE_HOTKEY`.
- Windows installer (Inno Setup) with optional auto-start and desktop icon.
- macOS DMG with Gatekeeper-friendly first-launch instructions.
- Cyberpunk theme.

[1.0.2]: https://github.com/Agenius-AI-Labs/ageniusnote-lite/releases/tag/v1.0.2
[1.0.1]: https://github.com/Agenius-AI-Labs/ageniusnote-lite/releases/tag/v1.0.1
[1.0.0]: https://github.com/Agenius-AI-Labs/ageniusnote-lite/releases/tag/v1.0.0
