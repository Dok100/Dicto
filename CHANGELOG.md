# Changelog

All notable changes to this project will be documented in this file.  
The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

---

## [0.2.0] – 2026-06-02 — Dicto Pro

### New: Dicto Pro

- **License system** — one-time purchase via Lemon Squeezy, €19, no subscription
- License key activation directly in Settings → License
- Offline-capable: Pro status cached locally, background validation on launch
- Up to 3 activations per license key
- New **License tab** in Settings with activation status, Pro feature overview and deactivation

### Pro feature gates

- WhisperKit Large v3 Turbo and Large v3 require Dicto Pro (Base remains free)
- Ollama and OpenAI AI processing require Dicto Pro
- Custom dictation styles require Dicto Pro
- Dictation history: 10 entries (Free) vs. 20 entries (Pro)

### Improvements

- Settings window wider (700 px default) — all tabs visible without overflow
- Main panel wider (420 px default) — style picker no longer clipped
- Dictation history: trash button with confirmation dialog to clear all entries
- In-app Help updated: Pro badges on all Pro features, clearer Preview mode documentation

---

## [0.1.0] – 2026-05-26 — First public release

### Core dictation

- **Push-to-Talk** via configurable keyboard shortcut (default: Fn key)
- **WhisperKit** transcription engine — fully local, Apple Neural Engine accelerated
- **Apple Speech Engine** — live word-by-word transcription, no download required
- Whisper model selection: Base (fast) and Large v3 Turbo (best quality)
- Language selection: German, English, Auto-detect

### AI text processing

- AI text smoothing: filler words removed, grammar corrected, tone adjusted
- **Ollama** integration — runs entirely on your Mac, free, fully private
- **OpenAI API** integration — opt-in, API key stored securely in macOS Keychain
- Streaming output: AI response appears word by word in real time
- Dictation styles: Neutral, Formal, Casual, Empathetic
- Translation style: dictate in German, receive English output
- Custom styles: define your own system prompts

### Transform mode

- Select text in any app → hold `⌥ Fn` → speak a command → AI transforms the selection
- Works in Mail, Slack, VS Code, Terminal, Notion, and any other app
- Result shown in panel — copy to clipboard or insert directly

### Privacy & security

- Audio processed entirely on-device and discarded immediately after transcription
- OpenAI API key stored in macOS Keychain — never written to disk
- No telemetry, no analytics, no cloud (unless OpenAI is explicitly enabled)

### User experience

- Menu bar app — always available, never in the way
- Configurable shortcuts for dictation and transform
- Preview mode: review and edit transcription before insertion
- Personal dictionary: learns your vocabulary corrections automatically
- Dictionary export and import (JSON)
- Dictation history — last 20 entries
- Dictation statistics: total words, favourite style, daily counts
- Sound feedback on recording start and stop
- In-app help with step-by-step instructions
- First-run onboarding
- Launch at Login
- Escape key closes panel

### Error handling

- Structured, actionable error messages for all failure scenarios
- Panel opens automatically on error — no silent failures
- Direct links to relevant app settings or macOS System Settings on error

---

## Requirements

- macOS 14.0 (Sonoma) or later
- Apple Silicon (M1 or newer)
- Microphone permission
- Accessibility permission (for automatic text insertion)
