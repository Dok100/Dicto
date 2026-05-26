enum TranscriptionState: Equatable {
    case idle
    case loadingModel(Double) // Fortschritt 0.0–1.0
    case transcribing
    case streaming(String) // Ollama-Antwort trifft live ein
    case done(String)
    case error(DictoError) // typsicher – kein String-Parsing mehr nötig
}
