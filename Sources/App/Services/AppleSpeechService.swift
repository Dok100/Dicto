import AVFoundation
import Speech

/// Echtzeit-Spracherkennung via Apples SFSpeechRecognizer.
/// Liefert Zwischenergebnisse während der Aufnahme läuft und ein
/// finales Ergebnis nach stopRecording().
final class AppleSpeechService {
    // Callbacks – werden auf beliebigem Thread gerufen, Dispatch liegt beim Aufrufer
    var onPartialResult: ((String) -> Void)?
    var onFinalResult: ((String) -> Void)?
    var onError: ((String) -> Void)?

    private var audioEngine = AVAudioEngine()
    private var recognizer: SFSpeechRecognizer?
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var task: SFSpeechRecognitionTask?
    private var didFireFinalResult = false

    var isAuthorized: Bool {
        SFSpeechRecognizer.authorizationStatus() == .authorized
    }

    // MARK: – Berechtigung

    func requestAuthorization(completion: @escaping (Bool) -> Void) {
        SFSpeechRecognizer.requestAuthorization { status in
            DispatchQueue.main.async { completion(status == .authorized) }
        }
    }

    // MARK: – Aufnahme starten

    func startRecording(locale: Locale) {
        // Alten Zustand bereinigen
        stopRecording()
        didFireFinalResult = false

        let rec = SFSpeechRecognizer(locale: locale)
        rec?.defaultTaskHint = .dictation
        recognizer = rec

        let req = SFSpeechAudioBufferRecognitionRequest()
        req.shouldReportPartialResults = true
        req.requiresOnDeviceRecognition = true // vollständig lokal, kein Apple-Server
        request = req

        // Mikrofon-Tap auf den Input-Node
        audioEngine = AVAudioEngine()
        let inputNode = audioEngine.inputNode
        let format = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak self] buffer, _ in
            self?.request?.append(buffer)
        }

        do {
            audioEngine.prepare()
            try audioEngine.start()
        } catch {
            onError?("Mikrofon konnte nicht gestartet werden.")
            return
        }

        task = rec?.recognitionTask(with: req) { [weak self] result, error in
            guard let self else { return }
            if let result {
                let text = result.bestTranscription.formattedString
                if result.isFinal {
                    guard !didFireFinalResult else { return }
                    didFireFinalResult = true
                    onFinalResult?(text)
                } else {
                    onPartialResult?(text)
                }
            } else if let error {
                // Fehler-Code 1110 = kein Audio-Input (normal nach endAudio)
                let nsErr = error as NSError
                if nsErr.code != 1110 {
                    onError?(error.localizedDescription)
                }
            }
        }
    }

    // MARK: – Aufnahme beenden

    func stopRecording() {
        request?.endAudio()
        if audioEngine.isRunning {
            audioEngine.stop()
            audioEngine.inputNode.removeTap(onBus: 0)
        }
        // task und request nicht nil-setzen – finale Callbacks kommen noch asynchron
    }
}

// MARK: – Locale aus WhisperLanguage ableiten

extension WhisperLanguage {
    var appleLocale: Locale {
        switch self {
        case .german: Locale(identifier: "de-DE")
        case .english: Locale(identifier: "en-US")
        case .auto: Locale.current
        }
    }
}
