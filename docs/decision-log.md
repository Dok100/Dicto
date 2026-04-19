# Decision Log

## 2026-04-19 – App-Sandbox deaktiviert

**Entscheidung**: `ENABLE_APP_SANDBOX=NO`

**Grund**: CGEventTap (für globalen Hotkey) und das Simulieren von Cmd+V via CGEvent funktionieren nicht innerhalb der macOS-App-Sandbox. Da keine App-Store-Distribution geplant ist, gibt es keinen Zwang zur Sandbox.

**Alternative**: Accessibility-basierter Ansatz via `AXUIElement` wäre theoretisch sandbox-kompatibel, ist aber deutlich komplexer und fehleranfälliger.

---

## 2026-04-19 – LSUIElement=YES (kein Dock-Icon)

**Entscheidung**: `LSUIElement: true` in Info.plist

**Grund**: Dicto ist eine reine Menübar-App. Ein Dock-Icon würde Platz vergeuden und den Charakter der App ("unsichtbar im Hintergrund") verfälschen.

**Konsequenz**: Es gibt kein App-Menü in der Menüzeile (außer dem NSStatusItem). Der "Beenden"-Button im Popover ist der primäre Weg, die App zu beenden.

---

## 2026-04-19 – CGEventTap für Fn-Hotkey (primär), rechte Ctrl als Plan B

**Entscheidung**: Fn-Taste via `flagsChanged`-Event als primärer Hotkey

**Grund**: Fn ist auf Apple-Tastaturen frei belegt (kein anderer Standard-Shortcut nutzt sie), intuitiv für Push-to-Talk, und die Taste ist mechanisch angenehm für dauerhaftes Drücken.

**Risiko**: Fn-Erkennung via CGEventTap ist nicht offiziell dokumentiert und könnte sich mit macOS-Updates ändern. Rechte Ctrl-Taste als einfach umzustellender Plan B ist im HotkeyService vorgesehen.

**Voraussetzung**: Nutzer muss App in Systemeinstellungen → Datenschutz → Bedienungshilfen und Eingabe-Überwachung freischalten.

---

## 2026-04-19 – WhisperKit statt whisper.cpp direkt

**Entscheidung**: WhisperKit als Swift-nativer Wrapper

**Grund**: WhisperKit ist in Swift geschrieben, unterstützt Apple Neural Engine auf M-Chips nativ und bietet eine komfortable Swift-API. whisper.cpp wäre schneller, aber die C++-Integration via Swift Package Manager ist aufwendig.

**Modell**: `openai_whisper-large-v3-turbo` – gute Balance aus Qualität und Geschwindigkeit.

---

## 2026-04-19 – Pasteboard + Cmd+V für Text-Einfügung

**Entscheidung**: Text via NSPasteboard setzen + Cmd+V simulieren

**Grund**: Dies ist der zuverlässigste systemweite Weg, Text in beliebige Apps einzufügen. `AXUIElement` würde accessibility-fähige Apps voraussetzen und viele Terminals/Editoren ausschließen.

**Nebeneffekt**: Alter Clipboard-Inhalt wird kurz überschrieben. Wird durch Sichern + Wiederherstellen nach 0.5 s Delay gemildert.

---

## 2026-04-19 – Ollama mit glm-4.7-flash für Text-Glättung

**Entscheidung**: Optionaler OllamaPostProcessor via HTTP-API, Fallback auf Passthrough

**Grund**: Ollama läuft bereits lokal. glm-4.7-flash ist schnell genug, um die wahrgenommene Latenz gering zu halten. Fallback auf Passthrough stellt sicher, dass die Kern-Funktion auch ohne Ollama funktioniert.
