import SwiftUI

struct LicenseSettingsView: View {
    @ObservedObject private var license = LicenseService.shared

    @State private var keyInput: String = ""
    @State private var showDeactivateConfirm = false

    var body: some View {
        Form {

            // ── Sektion 1: Status ─────────────────────────────────────────────
            Section {
                HStack(spacing: 10) {
                    Image(systemName: license.isPro ? "checkmark.seal.fill" : "seal")
                        .font(.title2)
                        .foregroundStyle(license.isPro ? .green : .secondary)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(license.isPro ? "Dicto Pro – Aktiviert" : "Dicto Free")
                            .fontWeight(.semibold)
                        Text(license.isPro
                             ? "Alle Pro-Features sind freigeschaltet."
                             : "WhisperKit Large-Modelle und KI-Verarbeitung erfordern Dicto Pro.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()
                }
                .padding(.vertical, 4)

                if license.isPro {
                    Button(role: .destructive) {
                        showDeactivateConfirm = true
                    } label: {
                        Label("Lizenz deaktivieren", systemImage: "xmark.circle")
                    }
                    .font(.callout)
                    .confirmationDialog(
                        "Lizenz deaktivieren?",
                        isPresented: $showDeactivateConfirm,
                        titleVisibility: .visible
                    ) {
                        Button("Deaktivieren", role: .destructive) {
                            Task { await license.deactivate() }
                        }
                        Button("Abbrechen", role: .cancel) {}
                    } message: {
                        Text("Dicto Pro wird auf diesem Mac deaktiviert. Du kannst die Lizenz danach auf einem anderen Gerät aktivieren.")
                    }
                }

            } header: {
                Text("Lizenzstatus")
            }

            // ── Sektion 2: Aktivierung (nur wenn nicht Pro) ───────────────────
            if !license.isPro {
                Section {
                    LabeledContent("Lizenzschlüssel") {
                        TextField("XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX", text: $keyInput)
                            .textFieldStyle(.roundedBorder)
                            .font(.system(.body, design: .monospaced))
                    }

                    if let error = license.activationError {
                        Label(error, systemImage: "exclamationmark.triangle.fill")
                            .font(.caption)
                            .foregroundStyle(.red)
                    }

                    HStack {
                        Button {
                            Task { await license.activate(key: keyInput) }
                        } label: {
                            if license.isValidating {
                                HStack(spacing: 6) {
                                    ProgressView().scaleEffect(0.7).frame(width: 14, height: 14)
                                    Text("Wird überprüft…")
                                }
                            } else {
                                Text("Aktivieren")
                            }
                        }
                        .disabled(keyInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                                  || license.isValidating)

                        Spacer()

                        Button {
                            NSWorkspace.shared.open(
                                URL(string: "https://dicto.lemonsqueezy.com")!)
                        } label: {
                            Label("Dicto Pro kaufen", systemImage: "arrow.up.right")
                                .font(.callout)
                        }
                        .buttonStyle(.link)
                    }

                } header: {
                    Text("Aktivierung")
                } footer: {
                    Text("Den Schlüssel hast du nach dem Kauf per E-Mail erhalten.")
                }
            }

            // ── Sektion 3: Pro-Features ───────────────────────────────────────
            Section {
                proFeatureRow(icon: "waveform", label: "WhisperKit Large v3 Turbo & Large v3",
                              subtitle: "Höchste Präzision, vollständig offline")
                proFeatureRow(icon: "brain",    label: "KI-Textverarbeitung",
                              subtitle: "Ollama (lokal) und OpenAI API")
                proFeatureRow(icon: "text.badge.plus", label: "Eigene Diktat-Stile",
                              subtitle: "Eigene System-Prompts konfigurieren")
                proFeatureRow(icon: "clock",    label: "Unbegrenzter Diktat-Verlauf",
                              subtitle: "Statt 10 Einträge in der Free-Version")
            } header: {
                Text("Pro-Features")
            }
        }
        .formStyle(.grouped)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: – Hilfsfunktion

    @ViewBuilder
    private func proFeatureRow(icon: String, label: String, subtitle: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .frame(width: 20)
                .foregroundStyle(license.isPro ? Color.accentColor : Color.secondary)
            VStack(alignment: .leading, spacing: 1) {
                Text(label)
                    .font(.callout)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if license.isPro {
                Image(systemName: "checkmark")
                    .foregroundStyle(.green)
                    .font(.caption)
            }
        }
        .padding(.vertical, 2)
    }
}
