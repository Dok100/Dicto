import Foundation

/// Strukturierte, nutzerfreundliche Fehlermeldungen für Dicto.
enum DictoError: Error {
    // Whisper
    case whisperModelLoad
    case whisperTranscription

    // Ollama
    case ollamaNotReachable
    case ollamaTimeout
    case ollamaEmptyResponse
    case ollamaUnknown

    /// Kurze Überschrift (1 Zeile)
    var title: String {
        switch self {
        case .whisperModelLoad:      return "Sprachmodell nicht geladen"
        case .whisperTranscription:  return "Transkription fehlgeschlagen"
        case .ollamaNotReachable:    return "Ollama nicht erreichbar"
        case .ollamaTimeout:         return "Ollama antwortet nicht"
        case .ollamaEmptyResponse:   return "Leere Antwort von Ollama"
        case .ollamaUnknown:         return "Ollama-Fehler"
        }
    }

    /// Ausführliche, handlungsorientierte Beschreibung
    var detail: String {
        switch self {
        case .whisperModelLoad:
            return "Das Whisper-Modell konnte nicht geladen werden. Prüfe deine Internetverbindung (erster Download) oder starte Dicto neu."
        case .whisperTranscription:
            return "Die Spracherkennung ist fehlgeschlagen. Bitte versuche es erneut."
        case .ollamaNotReachable:
            return "Ollama läuft nicht oder ist unter einer anderen Adresse erreichbar. Prüfe unter Einstellungen → KI ob der Server läuft."
        case .ollamaTimeout:
            return "Ollama hat zu lange nicht geantwortet (>120 s). Das Modell ist möglicherweise noch am Laden – bitte kurz warten und erneut versuchen."
        case .ollamaEmptyResponse:
            return "Ollama hat eine leere Antwort zurückgegeben. Bitte versuche es erneut."
        case .ollamaUnknown:
            return "Ein unbekannter Fehler ist bei der KI-Verarbeitung aufgetreten. Bitte versuche es erneut."
        }
    }

    /// Vollständige Anzeige: Titel + Detail
    var displayMessage: String { "\(title)\n\(detail)" }

    /// Aus URLError ableiten
    static func from(_ urlError: URLError) -> DictoError {
        switch urlError.code {
        case .timedOut:                    return .ollamaTimeout
        case .cannotConnectToHost,
             .networkConnectionLost,
             .notConnectedToInternet:      return .ollamaNotReachable
        default:                           return .ollamaUnknown
        }
    }
}
