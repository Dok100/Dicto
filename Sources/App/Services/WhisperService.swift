import WhisperKit
import Foundation

// Kein @MainActor auf Klassenebene – wir updaten state manuell via MainActor.run,
// damit AppState das Objekt ohne Actor-Kontext erstellen kann.
final class WhisperService: ObservableObject {
    @Published private(set) var state: TranscriptionState = .idle

    private var pipe: WhisperKit?
    private var loadedModel: WhisperModel?

    func loadModelIfNeeded(model: WhisperModel = .largev3) async {
        if loadedModel == model, pipe != nil { return }
        pipe = nil
        loadedModel = nil
        await MainActor.run { state = .loadingModel(0.0) }
        do {
            pipe = try await WhisperKit(model: model.rawValue, verbose: false)
            loadedModel = model
            await MainActor.run { state = .idle }
        } catch {
            let msg = error.localizedDescription
            await MainActor.run { state = .error("Modell konnte nicht geladen werden:\n\(msg)") }
        }
    }

    func transcribe(fileURL: URL, model: WhisperModel = .largev3) async {
        if pipe == nil || loadedModel != model { await loadModelIfNeeded(model: model) }
        guard let pipe else { return }

        await MainActor.run { state = .transcribing }
        do {
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
