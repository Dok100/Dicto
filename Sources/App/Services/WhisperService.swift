import WhisperKit
import Foundation

// Kein @MainActor auf Klassenebene – wir updaten state manuell via MainActor.run,
// damit AppState das Objekt ohne Actor-Kontext erstellen kann.
final class WhisperService: ObservableObject {
    @Published private(set) var state: TranscriptionState = .idle

    private var pipe: WhisperKit?
    private static let modelName = "large-v3"

    func loadModelIfNeeded() async {
        guard pipe == nil else { return }
        await MainActor.run { state = .loadingModel(0.0) }
        do {
            pipe = try await WhisperKit(model: Self.modelName, verbose: false)
            await MainActor.run { state = .idle }
        } catch {
            let msg = error.localizedDescription
            await MainActor.run { state = .error("Modell konnte nicht geladen werden:\n\(msg)") }
        }
    }

    func transcribe(fileURL: URL) async {
        if pipe == nil { await loadModelIfNeeded() }
        guard let pipe else { return }

        await MainActor.run { state = .transcribing }
        do {
            // Parameterreihenfolge in DecodingOptions: task vor language
            let options = DecodingOptions(task: .transcribe, language: "de")
            let results = try await pipe.transcribe(audioPath: fileURL.path, decodeOptions: options)
            let text = results
                .map { $0.text }
                .joined(separator: " ")
                .trimmingCharacters(in: .whitespacesAndNewlines)
            let final = text.isEmpty ? "(kein Text erkannt)" : text
            await MainActor.run { state = .done(final) }
        } catch {
            let msg = error.localizedDescription
            await MainActor.run { state = .error("Transkription fehlgeschlagen:\n\(msg)") }
        }
    }
}
