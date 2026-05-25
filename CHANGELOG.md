# Changelog

All notable changes to AgeniusNote Lite are documented here.

Format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/). Versions follow [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- **Custom vocabulary / hotwords.** Settings dialog now has a "Custom vocabulary" field — a short list of proper nouns or acronyms (e.g. `n8n, Agenius, Cursor, faster-whisper`) that biases the decoder toward those terms. The same string is passed to faster-whisper as both `hotwords=` (token-level bias) and `initial_prompt=` (so preferred casing/spelling for things like `n8n` is also picked up). Configurable via the new `VN_LITE_VOCABULARY` env var or the `vocabulary` key in `config.json`. No model warmup needed on save — next transcription picks it up. Older faster-whisper builds without `hotwords` degrade gracefully to no biasing.
- **In-app Settings dialog.** A new Settings button next to Auto-paste opens a modal for changing the global hotkey, Whisper model, device (CPU / CUDA / auto), and default auto-paste state. The hotkey field captures the next chord you press, so picking a non-colliding shortcut no longer requires editing env vars or knowing the pynput string format.
- **Persisted user config.** Settings save to `%APPDATA%\AgeniusNote Lite\config.json` (Windows), `~/Library/Application Support/AgeniusNote Lite/` (macOS), or `~/.config/ageniusnote-lite/` (Linux). Resolution priority is `config.json` > `VN_LITE_*` env vars > hardcoded defaults, so existing setups keep working unchanged.
- **Live apply on save.** Saving Settings rebinds the global hotkey, swaps the model/device, and re-runs warmup in the background — no restart needed.
- **CUDA wheel auto-discovery.** If the pip wheels `nvidia-cublas-cu12` / `nvidia-cudnn-cu12` / `nvidia-cuda-nvrtc-cu12` are installed in the same environment as Lite, their DLL directories are registered at import time (both `os.add_dll_directory` and `PATH`), so `device=cuda` works without a system CUDA Toolkit install. No-op when the wheels aren't present, so CPU-only setups are unaffected.
- **Real inference warmup.** Preload now runs two short dummy transcribe passes in the background after loading the model — one with `vad_filter=False` to force the decoder to actually run (so CUDA kernel JIT, decoder graph init, and GPU memory pool sizing all happen during warmup, not on the user's first hotkey press), and one with `vad_filter=True` to load the Silero VAD model. Without the first pass, VAD treats the synthetic tone as non-speech and gates the decoder out, leaving the cold-start cost to the user. On CUDA the warmup takes ~300 ms and saves ~5 s on the first real transcription. Re-fires automatically when the model or device is changed via Settings.

### Fixed
- **Hotkey transcripts dropped on CUDA fallback.** When `device=cuda` failed at transcribe time and the CPU fallback succeeded, the resulting text was being skipped by an early `return` in the result handler — the transcript was on the clipboard but never pasted, and the user saw "CUDA unavailable" with no apparent output. The fallback path now pastes/copies the result normally and the fallback note is appended to the status line.
- **Hidden CUDA errors.** The status bar previously showed a generic "CUDA unavailable, used CPU" with no detail. It now includes the underlying error message (e.g. "library cublas64_12.dll is not found"), truncated to 90 chars, so DLL/driver issues are diagnosable instead of opaque.

## [1.0.3] - 2026-05-25

### Fixed
- **macOS launch loop / runaway window spawning on first run.** The frozen `.app` was missing `multiprocessing.freeze_support()`, so any multiprocessing child (sounddevice / ctranslate2 thread helpers) re-execed the entire bundle and spawned a fresh Qt window. Each child then hit bug #2 below, crashed, and macOS LaunchServices re-ran the bundle, producing what looked like a Dock-icon-bouncing loop with dozens of windows. Calling `freeze_support()` + `set_start_method("spawn", force=True)` at the top of `main()` kills the loop.
- **Whisper model download segfault on first run.** Passing a HF Hub model id directly to `WhisperModel(...)` makes libctranslate2 download from inside native code, and any failure (no internet, partial cache, sandbox permission) crashes inside spdlog's error path with `EXC_BAD_ACCESS` instead of raising a clean Python exception. Now we pre-download with `huggingface_hub.snapshot_download` to `~/Library/Application Support/AgeniusNote Lite/models/` (mac) or `%LOCALAPPDATA%\AgeniusNote Lite\models\` (win), validate `model.bin` exists and is non-trivial, then pass the local path to `WhisperModel`. Failures now surface as a clear Qt error dialog.

### Added
- Explicit `huggingface_hub` dependency in `requirements.txt` (was already a transitive dep of faster-whisper; pinning it removes the implicit chain).

### Known limitations
- The `.app` is still ad-hoc signed, not Apple-notarized. Users downloading via Chrome will see the quarantine flag; until notarization lands, the workaround is `xattr -dr com.apple.quarantine "/Applications/AgeniusNote Lite.app"` after install.

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

[1.0.3]: https://github.com/Agenius-AI-Labs/ageniusnote-lite/releases/tag/v1.0.3
[1.0.2]: https://github.com/Agenius-AI-Labs/ageniusnote-lite/releases/tag/v1.0.2
[1.0.1]: https://github.com/Agenius-AI-Labs/ageniusnote-lite/releases/tag/v1.0.1
[1.0.0]: https://github.com/Agenius-AI-Labs/ageniusnote-lite/releases/tag/v1.0.0
