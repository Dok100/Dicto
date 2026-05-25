# Dicto

**Push-to-talk dictation for macOS — local, private, instant.**

Hold a key, speak, release. Your words appear at the cursor — in any app, in under a second.

<!-- SCREENSHOT: Hero image — Dicto panel open with streaming text, over a Mail or Notion window -->
<!-- Suggested size: 1200×750px, show the panel mid-stream with a few words appearing -->

---

## Download

> **Apple Developer Account in progress — release coming soon.**
> 
> [⭐ Star this repo](../../stargazers) to get notified when it launches.

---

## What it does

Dicto sits quietly in your menu bar. Press and hold your dictation key, speak naturally, release — the text is inserted exactly where your cursor is. No switching apps, no clicking, no copy-paste.

**It works everywhere:** Mail, Notion, Slack, Notes, Terminal, any text field on macOS.

<!-- SCREENSHOT: Three-panel collage — panel idle / panel recording (red dot) / panel streaming KI result -->

---

## Features

### 🎤 Two transcription engines

| | Apple Speech | Whisper |
|---|---|---|
| Download required | None | ~800 MB (one-time) |
| Transcription | Live, word by word | After recording ends |
| Quality | Good for everyday speech | Excellent, handles jargon |
| Works offline | Yes | Yes |

### 🧠 AI text smoothing (optional)

Raw dictation gets cleaned up automatically — filler words removed, grammar corrected, tone adjusted. Choose your provider:

- **Ollama (local)** — fully private, runs on your Mac, no cost
- **OpenAI API** — cloud-fast, ~€0.01/day at normal usage

Your API key is stored encrypted in the **macOS Keychain** — never in plain text.

### ✨ Transform mode

Select text in any app → hold `⌥ Fn` → speak your instruction.

> *"Make this more formal"*  
> *"Translate to English"*  
> *"Shorten to two sentences"*

The result appears in Dicto for review before replacing the original.

### 🎨 Styles

Switch styles before dictating — the AI adjusts accordingly:

| Style | Best for |
|-------|----------|
| Neutral | General use, clean and direct |
| Formal | Emails, reports, business writing |
| Casual | Slack, WhatsApp, quick notes |
| Empathetic | Feedback, sensitive topics |
| → EN | Dictate in German, output in English |

Custom styles with your own prompt are also supported.

<!-- SCREENSHOT: Style picker in the panel with "Formal" selected -->

### 👁 Preview mode

See the result before it's inserted. Edit inline, then confirm with `⌘ ↩`. Corrections are remembered in a personal dictionary.

### 🔒 Privacy first

- Audio **never leaves your device**
- Whisper and Apple Speech run fully on-device
- Ollama runs locally — no internet required
- OpenAI is opt-in and clearly labeled

---

## Requirements

- macOS 14.0 (Sonoma) or later
- Apple Silicon (M1 or newer)
- Microphone access
- Accessibility permission (for text insertion)

---

## How to build from source

```bash
# Dependencies
brew install xcodegen swiftformat

# Clone and build
git clone https://github.com/Dok100/Dicto.git
cd Dicto
make generate   # Generate Xcode project
make build      # Build the app
make install-app # Install to /Applications
```

Ollama is optional. If you want local AI smoothing:
```bash
brew install ollama
ollama pull qwen2.5:32b   # recommended (~20 GB, needs 24 GB RAM)
ollama pull qwen2.5:14b   # lighter option (~8 GB)
```

---

## Privacy Policy

Dicto does not collect, transmit, or store any personal data. All processing happens locally unless you explicitly configure OpenAI API (opt-in). See [PRIVACY.md](docs/PRIVACY.md).

---

## License

MIT — free to use, modify, and distribute.

---

## Support the project

Dicto is free. If it saves you time, consider supporting development:

<!-- GUMROAD BADGE PLACEHOLDER -->
> 💛 [Pay what you want on Gumroad](#) *(link coming soon)*

This helps cover API costs and keeps development going.

---

*Built with [WhisperKit](https://github.com/argmaxinc/WhisperKit) · Runs on Apple Silicon · Made in Germany 🇩🇪*
