import Foundation

/// Strukturierte, nutzerfreundliche Fehlermeldungen für Dicto.
enum DictoError: Error {
    // Whisper
    case whisperModelLoad
    case whisperTranscription

    // Apple Speech
    case appleSpeechDenied
    case appleSpeechUnavailable

    // Ollama
    case ollamaNotReachable
    case ollamaTimeout
    case ollamaEmptyResponse
    case ollamaUnknown

    // OpenAI
    case openAIKeyMissing
    case openAINotReachable
    case openAITimeout
    case openAIUnknown

    /// Kurze Überschrift (1 Zeile)
    var title: String {
        switch self {
        case .whisperModelLoad:         return "Sprachmodell nicht geladen"
        case .whisperTranscription:     return "Transkription fehlgeschlagen"
        case .appleSpeechDenied:        return "Spracherkennung nicht erlaubt"
        case .appleSpeechUnavailable:   return "Spracherkennung nicht verfügbar"
        case .ollamaNotReachable:       return "Ollama nicht erreichbar"
        case .ollamaTimeout:         return "Ollama antwortet nicht"
        case .ollamaEmptyResponse:   return "Leere Antwort von Ollama"
        case .ollamaUnknown:         return "Ollama-Fehler"
        case .openAIKeyMissing:      return "Kein API-Key"
        case .openAINotReachable:    return "OpenAI nicht erreichbar"
        case .openAITimeout:         return "OpenAI antwortet nicht"
        case .openAIUnknown:         return "OpenAI-Fehler"
        }
    }

    /// Ausführliche, handlungsorientierte Beschreibung
    var detail: String {
        switch self {
        case .whisperModelLoad:
            return "Das Whisper-Modell konnte nicht geladen werden. Prüfe deine Internetverbindung (erster Download) oder starte Dicto neu."
        case .whisperTranscription:
            return "Die Spracherkennung ist fehlgeschlagen. Bitte versuche es erneut."
        case .appleSpeechDenied:
            return "Bitte erlaube die Spracherkennung unter Systemeinstellungen → Datenschutz → Spracherkennung."
        case .appleSpeechUnavailable:
            return "Die Apple-Spracherkennung ist auf diesem Gerät nicht verfügbar. Wechsle zu Whisper in den Einstellungen."
        case .ollamaNotReachable:
            return "Ollama läuft nicht oder ist unter einer anderen Adresse erreichbar. Prüfe unter Einstellungen → KI ob der Server läuft."
        case .ollamaTimeout:
            return "Ollama hat zu lange nicht geantwortet (>120 s). Das Modell ist möglicherweise noch am Laden – bitte kurz warten und erneut versuchen."
        case .ollamaEmptyResponse:
            return "Ollama hat eine leere Antwort zurückgegeben. Bitte versuche es erneut."
        case .ollamaUnknown:
            return "Ein unbekannter Fehler ist bei der KI-Verarbeitung aufgetreten. Bitte versuche es erneut."
        case .openAIKeyMissing:
            return "Bitte trage deinen OpenAI API-Key unter Einstellungen → KI ein."
        case .openAINotReachable:
            return "Die OpenAI API ist nicht erreichbar. Prüfe deine Internetverbindung oder den konfigurierten Basis-URL."
        case .openAITimeout:
            return "OpenAI hat zu lange nicht geantwortet (>120 s). Bitte versuche es erneut."
        case .openAIUnknown:
            return "Ein unbekannter Fehler ist bei der OpenAI-Verarbeitung aufgetreten. Bitte versuche es erneut."
        }
    }

    /// Vollständige Anzeige: Titel + Detail
    var displayMessage: String { "\(title)\n\(detail)" }

    /// Aus URLError ableiten (Ollama)
    static func from(_ urlError: URLError) -> DictoError {
        switch urlError.code {
        case .timedOut:                    return .ollamaTimeout
        case .cannotConnectToHost,
             .networkConnectionLost,
             .notConnectedToInternet:      return .ollamaNotReachable
        default:                           return .ollamaUnknown
        }
    }

    /// Aus URLError ableiten (OpenAI)
    static func fromOpenAI(_ urlError: URLError) -> DictoError {
        switch urlError.code {
        case .timedOut:                    return .openAITimeout
        case .cannotConnectToHost,
             .networkConnectionLost,
             .notConnectedToInternet:      return .openAINotReachable
        default:                           return .openAIUnknown
        }
    }
}
