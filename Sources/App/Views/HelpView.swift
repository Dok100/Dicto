import SwiftUI

// MARK: – Hilfe-Themen

private enum HelpTopic: String, CaseIterable, Identifiable {
    case quickstart = "Schnellstart"
    case dictation = "Diktat"
    case aiSmoothing = "Textglättung (KI)"
    case styles = "Stile"
    case transform = "Transform-Modus"
    case preview = "Preview-Modus"
    case settings = "Einstellungen"
    case troubleshoot = "Fehlerbehebung"

    var id: String {
        rawValue
    }

    var icon: String {
        switch self {
        case .quickstart: "bolt.fill"
        case .dictation: "mic.fill"
        case .aiSmoothing: "brain"
        case .styles: "paintpalette.fill"
        case .transform: "wand.and.sparkles"
        case .preview: "eye.fill"
        case .settings: "gearshape.fill"
        case .troubleshoot: "wrench.and.screwdriver.fill"
        }
    }

    var color: Color {
        switch self {
        case .quickstart: .orange
        case .dictation: .red
        case .aiSmoothing: .purple
        case .styles: .pink
        case .transform: .indigo
        case .preview: .blue
        case .settings: .gray
        case .troubleshoot: .brown
        }
    }
}

// MARK: – Haupt-View

struct HelpView: View {
    @State private var selectedTopic: HelpTopic? = .quickstart

    var body: some View {
        NavigationSplitView(columnVisibility: .constant(.all)) {
            List(HelpTopic.allCases, selection: $selectedTopic) { topic in
                Label {
                    Text(topic.rawValue)
                        .font(.callout)
                } icon: {
                    Image(systemName: topic.icon)
                        .foregroundStyle(topic.color)
                        .frame(width: 20)
                }
                .tag(topic)
                .padding(.vertical, 2)
            }
            .listStyle(.sidebar)
            .navigationSplitViewColumnWidth(min: 160, ideal: 180, max: 200)
        } detail: {
            if let topic = selectedTopic {
                detailView(for: topic)
            } else {
                ContentUnavailableView("Thema auswählen", systemImage: "questionmark.circle")
            }
        }
        .frame(minWidth: 680, minHeight: 480)
    }

    private func detailView(for topic: HelpTopic) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // Titel-Header
                HStack(spacing: 12) {
                    Image(systemName: topic.icon)
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(topic.color)
                    Text(topic.rawValue)
                        .font(.title2)
                        .fontWeight(.semibold)
                }
                .padding(.bottom, 20)

                // Inhalt
                switch topic {
                case .quickstart: QuickstartContent()
                case .dictation: DictationContent()
                case .aiSmoothing: AISmoothingContent()
                case .styles: StylesContent()
                case .transform: TransformContent()
                case .preview: PreviewContent()
                case .settings: SettingsContent()
                case .troubleshoot: TroubleshootContent()
                }
            }
            .padding(28)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

// MARK: – Hilfsmethoden für Formatierung

private struct SectionTitle: View {
    let text: String
    var body: some View {
        Text(text)
            .font(.headline)
            .padding(.top, 20)
            .padding(.bottom, 6)
    }
}

private struct InfoBox: View {
    let icon: String
    let text: String
    var color: Color = .blue
    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon)
                .foregroundStyle(color)
                .frame(width: 16)
            Text(text)
                .font(.callout)
                .foregroundStyle(.secondary)
        }
        .padding(12)
        .background(color.opacity(0.08), in: RoundedRectangle(cornerRadius: 8))
        .padding(.vertical, 4)
    }
}

private struct ShortcutRow: View {
    let shortcut: String
    let description: String
    var body: some View {
        HStack {
            Text(description)
                .font(.callout)
            Spacer()
            Text(shortcut)
                .font(.system(.caption, design: .monospaced))
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(.quaternary, in: RoundedRectangle(cornerRadius: 5))
        }
        .padding(.vertical, 3)
    }
}

// MARK: – Schnellstart

private struct QuickstartContent: View {
    var body: some View {
        Text("Mit Dicto diktierst du Text direkt an jede Cursor-Position – in jedem Programm.")
            .font(.callout)
            .foregroundStyle(.secondary)
            .padding(.bottom, 8)

        SectionTitle(text: "In 3 Schritten loslegen")

        VStack(alignment: .leading, spacing: 12) {
            StepRow(
                number: "1",
                title: "Cursor setzen",
                detail: "Klicke in ein Textfeld – egal ob Mail, Slack, Word oder Terminal.")
            StepRow(
                number: "2",
                title: "Fn gedrückt halten und sprechen",
                detail: "Sprich deinen Text. Dicto nimmt auf solange du die Taste hältst.")
            StepRow(
                number: "3",
                title: "Taste loslassen",
                detail: "Der Text wird transkribiert und automatisch eingefügt.")
        }
        .padding(.bottom, 8)

        SectionTitle(text: "Tastenkürzel")
        VStack(spacing: 0) {
            ShortcutRow(shortcut: "Fn (halten)", description: "Diktat starten / stoppen")
            Divider().opacity(0.4)
            ShortcutRow(shortcut: "⌥ Fn (halten)", description: "Transform-Modus (markierten Text umformulieren)")
            Divider().opacity(0.4)
            ShortcutRow(shortcut: "⌘ ↩", description: "Text einfügen (im Preview-Modus)")
            Divider().opacity(0.4)
            ShortcutRow(shortcut: "⎋", description: "Panel schließen")
        }
        .padding(12)
        .background(.quinary, in: RoundedRectangle(cornerRadius: 8))
        .padding(.bottom, 8)

        InfoBox(
            icon: "info.circle",
            text: "Der Diktat-Shortcut ist in Einstellungen → Allgemein → Tastenkürzel frei konfigurierbar.",
            color: .blue)
    }
}

private struct StepRow: View {
    let number: String
    let title: String
    let detail: String
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text(number)
                .font(.system(.callout, design: .rounded))
                .fontWeight(.bold)
                .foregroundStyle(.white)
                .frame(width: 24, height: 24)
                .background(.blue, in: Circle())
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.callout).fontWeight(.medium)
                Text(detail).font(.caption).foregroundStyle(.secondary)
            }
        }
    }
}

// MARK: – Diktat

private struct DictationContent: View {
    var body: some View {
        Text("Dicto nimmt deine Stimme auf und wandelt sie in Text um – vollständig lokal, ohne Cloud.")
            .font(.callout)
            .foregroundStyle(.secondary)
            .padding(.bottom, 8)

        SectionTitle(text: "Spracherkennungs-Engine")

        VStack(alignment: .leading, spacing: 10) {
            EngineRow(
                name: "Apple (live, kein Download)",
                icon: "apple.logo",
                pros: ["Sofort verfügbar, kein Download", "Text erscheint live während der Aufnahme"],
                cons: ["Weniger präzise bei Fachbegriffen", "Interpunktion unzuverlässiger"])
            EngineRow(
                name: "Whisper (präziser, offline)",
                icon: "waveform",
                pros: ["Sehr hohe Genauigkeit", "Fachvokabular, Eigennamen, Umlaute"],
                cons: ["Einmaliger Download (800 MB – 3 GB)", "Text erscheint erst nach Aufnahme"])
        }
        .padding(.bottom, 4)

        InfoBox(
            icon: "arrow.down.circle",
            text: "Whisper lädt das Modell beim ersten Einsatz automatisch herunter. Danach funktioniert es vollständig offline.",
            color: .orange)

        SectionTitle(text: "Sprachauswahl")
        Text(
            "Unter Einstellungen → Allgemein → Sprache wählst du zwischen **Deutsch**, **Englisch** oder **Automatisch** (erkennt die Sprache selbst).")
            .font(.callout)
            .padding(.bottom, 8)

        SectionTitle(text: "Sound-Feedback")
        Text(
            "Dicto spielt beim Start und Stopp der Aufnahme einen kurzen Ton. Abschaltbar unter Einstellungen → Allgemein.")
            .font(.callout)
    }
}

private struct EngineRow: View {
    let name: String
    let icon: String
    let pros: [String]
    let cons: [String]
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label(name, systemImage: icon).font(.callout).fontWeight(.medium)
            HStack(alignment: .top, spacing: 16) {
                VStack(alignment: .leading, spacing: 3) {
                    ForEach(pros, id: \.self) { p in
                        Label(p, systemImage: "checkmark").font(.caption).foregroundStyle(.green)
                    }
                }
                VStack(alignment: .leading, spacing: 3) {
                    ForEach(cons, id: \.self) { c in
                        Label(c, systemImage: "minus").font(.caption).foregroundStyle(.secondary)
                    }
                }
            }
        }
        .padding(10)
        .background(.quinary, in: RoundedRectangle(cornerRadius: 8))
    }
}

// MARK: – KI-Textglättung

private struct AISmoothingContent: View {
    var body: some View {
        Text(
            "Die KI glättet deinen Diktat-Text: entfernt Füllwörter, korrigiert Satzbau und macht den Text schreibfertig.")
            .font(.callout)
            .foregroundStyle(.secondary)
            .padding(.bottom, 8)

        InfoBox(
            icon: "bolt.fill",
            text: "Die Textglättung ist optional. Ohne KI wird der Rohtext direkt eingefügt.",
            color: .orange)

        SectionTitle(text: "Anbieter")

        VStack(alignment: .leading, spacing: 10) {
            ProviderRow(
                name: "Ollama (lokal)",
                icon: "desktopcomputer",
                description: "Läuft komplett auf deinem Mac. Kein Internet nötig, keine Kosten. Empfohlen: qwen2.5:32b (braucht ~20 GB RAM).",
                color: .green)
            ProviderRow(
                name: "OpenAI API",
                icon: "cloud.fill",
                description: "Nutzt GPT-4o-mini oder GPT-4o. Sehr schnell, geringe Kosten (~0,01 €/Tag bei normalem Einsatz). API-Key erforderlich.",
                color: .blue)
        }
        .padding(.bottom, 4)

        SectionTitle(text: "System-Prompt anpassen")
        Text(
            "Unter Einstellungen → KI → System-Prompt (Neutral) kannst du das Verhalten der KI steuern. Der Standard-Prompt ist für deutsches Diktat optimiert.")
            .font(.callout)
            .padding(.bottom, 6)

        InfoBox(
            icon: "key.fill",
            text: "Der OpenAI API-Key wird verschlüsselt im macOS Keychain gespeichert – nicht im Klartext auf der Festplatte.",
            color: .green)
    }
}

private struct ProviderRow: View {
    let name: String
    let icon: String
    let description: String
    let color: Color
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundStyle(color)
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 4) {
                Text(name).font(.callout).fontWeight(.medium)
                Text(description).font(.caption).foregroundStyle(.secondary)
            }
        }
        .padding(10)
        .background(.quinary, in: RoundedRectangle(cornerRadius: 8))
    }
}

// MARK: – Stile

private struct StylesContent: View {
    var body: some View {
        Text("Stile steuern, wie der Text von der KI umformuliert wird. Wähle den Stil im Panel vor dem Diktat.")
            .font(.callout)
            .foregroundStyle(.secondary)
            .padding(.bottom, 8)

        SectionTitle(text: "Eingebaute Stile")

        VStack(spacing: 6) {
            StyleRow(
                name: "Neutral",
                icon: "minus.circle.fill",
                color: .blue,
                desc: "Glättet Füllwörter und Satzbau, behält Ton und Inhalt unverändert.")
            StyleRow(
                name: "Formell",
                icon: "briefcase.fill",
                color: .brown,
                desc: "Schreibt in sachlicher, professioneller Sprache. Gut für E-Mails und Berichte.")
            StyleRow(
                name: "Locker",
                icon: "bubble.left.fill",
                color: .green,
                desc: "Entspannter, umgangssprachlicher Ton. Gut für Slack, WhatsApp, Notizen.")
            StyleRow(
                name: "Empathisch",
                icon: "heart.fill",
                color: .pink,
                desc: "Einfühlsamer, wertschätzender Ton. Gut für Feedback und heikle Themen.")
            StyleRow(
                name: "→ EN",
                icon: "globe",
                color: .orange,
                desc: "Übersetzt den Text ins Englische und glättet dabei gleichzeitig.")
        }
        .padding(.bottom, 8)

        SectionTitle(text: "Eigene Stile")
        Text(
            "Unter Einstellungen → KI → Eigene Stile kannst du beliebig viele eigene Stile mit eigenem System-Prompt erstellen (z.B. Arztbrief, Protokoll, Twitterpost).")
            .font(.callout)
            .padding(.bottom, 6)

        InfoBox(
            icon: "info.circle",
            text: "Eigene Stile erscheinen im Panel unterhalb der eingebauten Stile und nutzen immer die konfigurierte KI.",
            color: .blue)
    }
}

private struct StyleRow: View {
    let name: String
    let icon: String
    let color: Color
    let desc: String
    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon).foregroundStyle(color).frame(width: 20)
            VStack(alignment: .leading, spacing: 2) {
                Text(name).font(.callout).fontWeight(.medium)
                Text(desc).font(.caption).foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: – Transform-Modus

private struct TransformContent: View {
    var body: some View {
        Text(
            "Mit Transform kannst du bestehenden Text in einer anderen App markieren und per Sprachbefehl umformulieren lassen.")
            .font(.callout)
            .foregroundStyle(.secondary)
            .padding(.bottom, 8)

        SectionTitle(text: "So funktioniert es")

        VStack(alignment: .leading, spacing: 12) {
            StepRow(
                number: "1",
                title: "Text markieren",
                detail: "Markiere den Text, den du umformulieren möchtest (in beliebiger App).")
            StepRow(
                number: "2",
                title: "Transform-Shortcut halten",
                detail: "Standard: ⌥ + Fn. Gleichzeitig sprechen was passieren soll.")
            StepRow(
                number: "3",
                title: "Befehl sprechen",
                detail: "z.B. 'Mach das formeller' oder 'Uebersetze auf Englisch' oder 'Kuerze auf 2 Saetze'.")
            StepRow(
                number: "4",
                title: "Ergebnis pruefen und einfuegen",
                detail: "Das Ergebnis erscheint im Dicto-Panel. Mit 'Einfuegen' wird der Originaltext ersetzt.")
        }
        .padding(.bottom, 8)

        SectionTitle(text: "Beispiel-Befehle")
        VStack(spacing: 0) {
            CommandRow(cmd: "Mach das formeller")
            Divider().opacity(0.4)
            CommandRow(cmd: "Übersetze auf Englisch")
            Divider().opacity(0.4)
            CommandRow(cmd: "Kürze auf zwei Sätze")
            Divider().opacity(0.4)
            CommandRow(cmd: "Schreib das als Aufzählung")
            Divider().opacity(0.4)
            CommandRow(cmd: "Korrigiere Rechtschreibung und Grammatik")
        }
        .padding(12)
        .background(.quinary, in: RoundedRectangle(cornerRadius: 8))
        .padding(.bottom, 8)

        InfoBox(
            icon: "exclamationmark.triangle",
            text: "Transform benötigt die Eingabehilfen-Berechtigung, um den markierten Text lesen zu können. Einmal in Systemeinstellungen → Datenschutz → Eingabehilfen erlauben.",
            color: .orange)
    }
}

private struct CommandRow: View {
    let cmd: String
    var body: some View {
        HStack {
            Image(systemName: "mic").font(.caption).foregroundStyle(.secondary)
            Text("\"\(cmd)\"").font(.callout).italic()
        }
        .padding(.vertical, 5)
    }
}

// MARK: – Preview-Modus

private struct PreviewContent: View {
    var body: some View {
        Text("Im Preview-Modus erscheint der fertige Text im Dicto-Panel zur Kontrolle – bevor er eingefügt wird.")
            .font(.callout)
            .foregroundStyle(.secondary)
            .padding(.bottom, 8)

        SectionTitle(text: "Aktivieren")
        Text("Einstellungen → Allgemein → Vorschau vor dem Einfügen aktivieren.")
            .font(.callout)
            .padding(.bottom, 8)

        SectionTitle(text: "Einfügen")
        VStack(spacing: 0) {
            ShortcutRow(shortcut: "⌘ ↩", description: "Text einfügen")
            Divider().opacity(0.4)
            ShortcutRow(shortcut: "⎋", description: "Verwerfen und schließen")
        }
        .padding(12)
        .background(.quinary, in: RoundedRectangle(cornerRadius: 8))
        .padding(.bottom, 8)

        SectionTitle(text: "Text bearbeiten")
        Text(
            "Du kannst den Text im Panel vor dem Einfügen direkt bearbeiten. Wenn du Wörter korrigierst (z.B. falsch erkannte Eigennamen), merkt sich Dicto die Korrektur im **persönlichen Wörterbuch** und wendet sie beim nächsten Mal automatisch an.")
            .font(.callout)
            .padding(.bottom, 4)

        InfoBox(
            icon: "book.fill",
            text: "Das Wörterbuch kann unter Einstellungen → Wörterbuch eingesehen, bearbeitet und exportiert werden.",
            color: .blue)
    }
}

// MARK: – Einstellungen

private struct SettingsContent: View {
    var body: some View {
        Text("Übersicht aller konfigurierbaren Optionen.")
            .font(.callout)
            .foregroundStyle(.secondary)
            .padding(.bottom, 8)

        SectionTitle(text: "Allgemein")
        SettingsList(items: [
            ("Spracherkennung", "Apple Speech (live) oder Whisper (präziser)"),
            ("Whisper-Modell", "Base (~150 MB), Large v3 Turbo (~800 MB, empfohlen) oder Large v3 (~3 GB)"),
            ("Sprache", "Deutsch, Englisch oder Automatisch"),
            ("Vorschau", "Text vor dem Einfügen im Panel anzeigen"),
            ("Sound-Feedback", "Tink/Pop bei Aufnahme-Start und -Stopp"),
            ("Diktat-Shortcut", "Taste für Push-to-Talk (Standard: Fn)"),
            ("Transform-Shortcut", "Taste für Transform-Modus (Standard: ⌥ Fn)"),
            ("Launch at Login", "Dicto automatisch beim Mac-Start öffnen")
        ])

        SectionTitle(text: "KI")
        SettingsList(items: [
            ("Textglättung", "KI-Verarbeitung ein- oder ausschalten"),
            ("Anbieter", "Ollama (lokal) oder OpenAI API"),
            ("Ollama-Modell", "Aus installierten Modellen wählen (empfohlen: qwen2.5:32b)"),
            ("Ollama-Endpoint", "URL des lokalen Ollama-Servers (Standard: localhost:11434)"),
            ("OpenAI API-Key", "Wird sicher im macOS Keychain gespeichert"),
            ("OpenAI-Modell", "z.B. gpt-4o-mini (schnell/günstig) oder gpt-4o (beste Qualität)"),
            ("OpenAI Basis-URL", "Für OpenAI-kompatible APIs (Groq, LM Studio etc.)"),
            ("System-Prompt", "Anweisungen für die KI beim Neutralstil"),
            ("Eigene Stile", "Stile mit eigenem Prompt erstellen und verwalten")
        ])

        SectionTitle(text: "Wörterbuch")
        SettingsList(items: [
            ("Einträge", "Manuell Korrekturpaare hinzufügen (z.B. Dikto → Dicto)"),
            ("Export / Import", "Wörterbuch als JSON-Datei sichern oder übertragen")
        ])

        SectionTitle(text: "Statistiken")
        SettingsList(items: [
            ("Diktat-Verlauf", "Die letzten 20 Diktate mit Text und Zeitstempel"),
            ("Nutzungsstatistik", "Anzahl Diktate, Wörter und meistgenutzter Stil")
        ])
    }
}

private struct SettingsList: View {
    let items: [(String, String)]
    var body: some View {
        VStack(spacing: 0) {
            ForEach(Array(items.enumerated()), id: \.offset) { i, item in
                HStack(alignment: .top, spacing: 8) {
                    Text(item.0)
                        .font(.callout)
                        .fontWeight(.medium)
                        .frame(width: 160, alignment: .leading)
                    Text(item.1)
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.vertical, 6)
                .padding(.horizontal, 10)
                if i < items.count - 1 { Divider().opacity(0.4) }
            }
        }
        .background(.quinary, in: RoundedRectangle(cornerRadius: 8))
        .padding(.bottom, 4)
    }
}

// MARK: – Fehlerbehebung

private struct TroubleshootContent: View {
    var body: some View {
        Text("Häufige Probleme und ihre Lösung.")
            .font(.callout)
            .foregroundStyle(.secondary)
            .padding(.bottom, 8)

        ErrorBlock(
            title: "Ollama nicht erreichbar",
            icon: "desktopcomputer.trianglebadge.exclamationmark",
            color: .orange,
            steps: [
                "Prüfe ob Ollama läuft: Terminal → ollama serve",
                "Prüfe die Endpoint-URL in Einstellungen → KI (Standard: http://localhost:11434)",
                "Firewall-Einstellungen: Ollama muss auf Port 11434 erreichbar sein"
            ])

        ErrorBlock(
            title: "API-Key ungültig (OpenAI)",
            icon: "key.slash",
            color: .red,
            steps: [
                "Key unter Einstellungen → KI löschen und neu einfügen",
                "Prüfe ob das OpenAI-Projekt eine aktive Zahlungsmethode hat",
                "Prüfe ob der Key nicht abgelaufen oder widerrufen wurde",
                "Neuen Key erstellen unter: platform.openai.com/api-keys"
            ])

        ErrorBlock(
            title: "Text wird nicht eingefügt",
            icon: "keyboard.badge.exclamationmark",
            color: .red,
            steps: [
                "Systemeinstellungen → Datenschutz → Eingabehilfen → Dicto erlauben",
                "Falls Dicto dort nicht erscheint: App neu starten",
                "Nach XcodeGen-Regenerierung muss die Berechtigung neu erteilt werden"
            ])

        ErrorBlock(
            title: "Whisper-Modell lädt nicht / Fehler",
            icon: "arrow.down.circle.dotted",
            color: .orange,
            steps: [
                "Internetverbindung prüfen (nur beim ersten Download nötig)",
                "Unter ~/Documents/huggingface prüfen ob der Download vollständig ist",
                "Dicto neu starten – der Download wird automatisch fortgesetzt",
                "Bei dauerhaften Problemen: Modell-Ordner löschen und neu herunterladen"
            ])

        ErrorBlock(
            title: "Mikrofon nicht erkannt",
            icon: "mic.slash.fill",
            color: .red,
            steps: [
                "Systemeinstellungen → Datenschutz → Mikrofon → Dicto erlauben",
                "Prüfe ob das richtige Mikrofon als Systemstandard eingestellt ist",
                "Dicto neu starten nach Berechtigung"
            ])

        ErrorBlock(
            title: "Fn-Taste reagiert nicht",
            icon: "keyboard",
            color: .orange,
            steps: [
                "Systemeinstellungen → Datenschutz → Eingabeüberwachung → Dicto erlauben",
                "In macOS Systemeinstellungen → Tastatur: Fn als Sondertaste (nicht als Medientaste) konfigurieren",
                "Alternativen Shortcut in Einstellungen → Allgemein → Tastenkürzel konfigurieren"
            ])
    }
}

private struct ErrorBlock: View {
    let title: String
    let icon: String
    let color: Color
    let steps: [String]
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(title, systemImage: icon)
                .font(.callout)
                .fontWeight(.semibold)
                .foregroundStyle(color)
            VStack(alignment: .leading, spacing: 4) {
                ForEach(Array(steps.enumerated()), id: \.offset) { i, step in
                    HStack(alignment: .top, spacing: 8) {
                        Text("\(i + 1).")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .frame(width: 16, alignment: .trailing)
                        Text(step)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .padding(12)
        .background(color.opacity(0.06), in: RoundedRectangle(cornerRadius: 8))
        .padding(.bottom, 8)
    }
}
