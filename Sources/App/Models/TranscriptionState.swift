enum TranscriptionState: Equatable {
    case idle
    case loadingModel(Double)   // Fortschritt 0.0–1.0
    case transcribing
    case done(String)
    case error(String)
}
