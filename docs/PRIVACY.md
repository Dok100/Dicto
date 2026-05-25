# Privacy Policy — Dicto

*Last updated: May 2026*

## Summary

Dicto does not collect any personal data. Period.

## Audio

All audio recordings are processed locally on your device and are never transmitted anywhere. Recordings are held in memory only for the duration of transcription and immediately discarded.

## Transcription

- **Apple Speech**: processed on-device via Apple's Speech framework. No audio leaves your Mac.
- **Whisper**: processed locally via WhisperKit. No audio leaves your Mac.

## AI text processing

- **Ollama**: runs entirely on your Mac. No data is sent to any external server.
- **OpenAI API**: if you choose this option, the transcribed text is sent to OpenAI's API for processing. This is opt-in and clearly indicated in settings. OpenAI's privacy policy applies: [openai.com/privacy](https://openai.com/privacy)

## API keys

Your OpenAI API key is stored exclusively in the **macOS Keychain**, encrypted by the operating system. It is never written to disk in plain text, never logged, and never transmitted anywhere other than directly to the OpenAI API endpoint you configure.

## Settings

App settings (preferences, custom styles, shortcuts) are stored locally in macOS UserDefaults. No settings are synced to any server.

## Dictation history

The last 20 dictations are stored locally on your device for your convenience. This data never leaves your Mac.

## Contact

Questions about privacy? Open an issue on [GitHub](https://github.com/Dok100/Dicto).
