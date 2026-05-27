# Privacy Policy – Dicto

_Last updated: May 2026_

## Summary

Dicto is a local macOS app. **It does not collect, transmit, or store any personal data on external servers.** Your voice recordings and transcriptions never leave your device.

---

## 1. Who is responsible

Oliver Kern  
Germany  
Contact: ratschlag_turbine.0h@icloud.com

---

## 2. What data Dicto processes

### On your device (local only)

| Data | Where stored | Purpose |
|------|-------------|---------|
| App settings (engine, model, shortcuts) | macOS UserDefaults | Remember your preferences |
| Dictation history (last 20 entries) | macOS UserDefaults | Show recent transcriptions |
| Custom dictionary entries | macOS UserDefaults | Improve transcription accuracy |
| OpenAI API key (if used) | macOS Keychain | Authenticate with OpenAI |
| Dicto Pro license key | macOS Keychain | Verify your license |

All of the above is stored exclusively on your Mac and can be deleted at any time by uninstalling Dicto.

### Audio

Microphone audio is processed in real time to produce a transcription. **Audio is never recorded to disk and never transmitted to any server.**

---

## 3. Third-party services

Dicto optionally connects to the following external services — all of which are **user-initiated and opt-in**:

**Ollama (local)**  
If you enable Ollama, text is sent to a locally running server on your own machine (`localhost`). No data leaves your device.

**OpenAI API**  
If you choose OpenAI as your LLM provider, transcribed text is sent to OpenAI's servers for processing. This is governed by [OpenAI's Privacy Policy](https://openai.com/privacy). You supply your own API key; Dicto does not proxy or log these requests.

**LemonSqueezy (license validation)**  
When you activate or validate a Dicto Pro license, your license key is sent to LemonSqueezy's servers. LemonSqueezy acts as the Merchant of Record and handles payment data. See [LemonSqueezy's Privacy Policy](https://www.lemonsqueezy.com/privacy) for details. Dicto stores only the license key and an activation token locally in your macOS Keychain.

**Sparkle (software updates)**  
Dicto uses Sparkle to check for updates. Sparkle fetches a public `appcast.xml` file hosted on GitHub Pages. No personal data is transmitted; Sparkle may include your macOS version and Dicto version in the request header for compatibility checks.

---

## 4. Your rights (EU/GDPR)

Since Dicto stores no personal data on external servers, there is no user account and no data to request, correct, or delete server-side. To remove all local data, simply uninstall Dicto from your Mac.

For questions regarding personal data processed by LemonSqueezy (purchase history, invoices), contact LemonSqueezy directly at privacy@lemonsqueezy.com.

For any other privacy questions, contact: ratschlag_turbine.0h@icloud.com

---

## 5. Changes to this policy

If this policy changes materially, the update will be noted in the Dicto release notes and in this document.
