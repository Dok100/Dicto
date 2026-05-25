@testable import Dicto
import XCTest

// MARK: – DictionaryService

final class DictionaryServiceTests: XCTestCase {
    var service: DictionaryService!

    override func setUp() {
        super.setUp()
        UserDefaults.standard.removeObject(forKey: "dictionaryEntries")
        service = DictionaryService()
    }

    override func tearDown() {
        UserDefaults.standard.removeObject(forKey: "dictionaryEntries")
        super.tearDown()
    }

    func testAddEntry() {
        service.add(wrong: "Whisper Kit", correct: "WhisperKit")
        XCTAssertEqual(service.entries.count, 1)
        XCTAssertEqual(service.entries[0].wrong, "Whisper Kit")
        XCTAssertEqual(service.entries[0].correct, "WhisperKit")
    }

    func testAddDeduplicates() {
        service.add(wrong: "foo", correct: "bar")
        service.add(wrong: "foo", correct: "baz")
        XCTAssertEqual(service.entries.count, 1)
    }

    func testAddIgnoresEmptyWrong() {
        service.add(wrong: "", correct: "bar")
        XCTAssertEqual(service.entries.count, 0)
    }

    func testAddIgnoresEmptyCorrect() {
        service.add(wrong: "foo", correct: "")
        XCTAssertEqual(service.entries.count, 0)
    }

    func testAddIgnoresIdenticalStrings() {
        service.add(wrong: "foo", correct: "foo")
        XCTAssertEqual(service.entries.count, 0)
    }

    func testApplyReplacement() {
        service.add(wrong: "Whisper Kit", correct: "WhisperKit")
        let result = service.apply(to: "Ich benutze Whisper Kit täglich.")
        XCTAssertEqual(result, "Ich benutze WhisperKit täglich.")
    }

    func testApplyMultipleReplacements() {
        service.add(wrong: "foo", correct: "bar")
        service.add(wrong: "baz", correct: "qux")
        let result = service.apply(to: "foo und baz")
        XCTAssertEqual(result, "bar und qux")
    }

    func testApplyNoMatch() {
        service.add(wrong: "xyz", correct: "abc")
        let result = service.apply(to: "kein Treffer hier")
        XCTAssertEqual(result, "kein Treffer hier")
    }

    func testApplyNFCNormalization() {
        // NFC: ö = U+00F6 / NFD: o + combining diaeresis = U+006F + U+0308
        let nfc = "\u{00F6}dheim"  // wie User es eintippt
        let nfd = "o\u{0308}dheim" // wie WhisperKit es manchmal liefert
        service.add(wrong: nfc, correct: "Oedheim")
        let result = service.apply(to: "Ich wohne in \(nfd).")
        XCTAssertEqual(result, "Ich wohne in Oedheim.")
    }

    func testRemove() {
        service.add(wrong: "foo", correct: "bar")
        let id = service.entries[0].id
        service.remove(id: id)
        XCTAssertEqual(service.entries.count, 0)
    }

    func testRemoveUnknownIdDoesNothing() {
        service.add(wrong: "foo", correct: "bar")
        service.remove(id: UUID())
        XCTAssertEqual(service.entries.count, 1)
    }

    func testLearnFromDiffSameWordCount() {
        service.learnFromDiff(original: "Ich bin müde", edited: "Ich bin wach")
        XCTAssertEqual(service.entries.count, 1)
        XCTAssertEqual(service.entries[0].wrong, "müde")
        XCTAssertEqual(service.entries[0].correct, "wach")
    }

    func testLearnFromDiffDifferentWordCount() {
        service.learnFromDiff(original: "Ich bin sehr müde", edited: "Ich bin wach")
        XCTAssertEqual(service.entries.count, 0)
    }

    func testLearnFromDiffNoChanges() {
        service.learnFromDiff(original: "Ich bin müde", edited: "Ich bin müde")
        XCTAssertEqual(service.entries.count, 0)
    }

    func testLearnFromDiffStripsPunctuation() {
        service.learnFromDiff(original: "Das ist falsch.", edited: "Das ist richtig.")
        XCTAssertEqual(service.entries.count, 1)
        XCTAssertEqual(service.entries[0].wrong, "falsch")
        XCTAssertEqual(service.entries[0].correct, "richtig")
    }

    func testLearnFromDiffDeduplicates() {
        service.learnFromDiff(original: "foo baz", edited: "bar baz")
        service.learnFromDiff(original: "foo baz", edited: "bar baz")
        XCTAssertEqual(service.entries.count, 1)
    }

    func testPersistence() {
        service.add(wrong: "Test", correct: "TEST")
        let reloaded = DictionaryService()
        XCTAssertEqual(reloaded.entries.count, 1)
        XCTAssertEqual(reloaded.entries[0].wrong, "Test")
    }
}

// MARK: – HistoryService

final class HistoryServiceTests: XCTestCase {
    var service: HistoryService!

    override func setUp() {
        super.setUp()
        UserDefaults.standard.removeObject(forKey: "dictationHistory")
        service = HistoryService()
    }

    override func tearDown() {
        UserDefaults.standard.removeObject(forKey: "dictationHistory")
        super.tearDown()
    }

    func testAddEntry() {
        service.add(text: "Hallo Welt")
        XCTAssertEqual(service.entries.count, 1)
        XCTAssertEqual(service.entries[0].text, "Hallo Welt")
    }

    func testNewestFirst() {
        service.add(text: "Erster")
        service.add(text: "Zweiter")
        XCTAssertEqual(service.entries[0].text, "Zweiter")
        XCTAssertEqual(service.entries[1].text, "Erster")
    }

    func testMaxTwentyEntries() {
        for i in 1...25 { service.add(text: "Eintrag \(i)") }
        XCTAssertEqual(service.entries.count, 20)
        XCTAssertEqual(service.entries[0].text, "Eintrag 25")
        XCTAssertEqual(service.entries[19].text, "Eintrag 6")
    }

    func testIgnoresEmptyText() {
        service.add(text: "")
        XCTAssertEqual(service.entries.count, 0)
    }

    func testClear() {
        service.add(text: "Hallo")
        service.add(text: "Welt")
        service.clear()
        XCTAssertEqual(service.entries.count, 0)
    }

    func testPersistence() {
        service.add(text: "Persistenter Eintrag")
        let reloaded = HistoryService()
        XCTAssertEqual(reloaded.entries.count, 1)
        XCTAssertEqual(reloaded.entries[0].text, "Persistenter Eintrag")
    }
}

// MARK: – DictationStyle

final class DictationStyleTests: XCTestCase {
    func testNeutralReturnsNilPrompt() {
        XCTAssertNil(DictationStyle.neutral.systemPrompt)
    }

    func testFormalHasPrompt() {
        XCTAssertNotNil(DictationStyle.formal.systemPrompt)
    }

    func testCasualHasPrompt() {
        XCTAssertNotNil(DictationStyle.casual.systemPrompt)
    }

    func testEmpathicHasPrompt() {
        XCTAssertNotNil(DictationStyle.empathic.systemPrompt)
    }

    func testAllCasesHaveLabels() {
        for style in DictationStyle.allCases {
            XCTAssertFalse(style.label.isEmpty, "\(style) hat kein Label")
        }
    }
}

// MARK: – WhisperLanguage

final class WhisperLanguageTests: XCTestCase {
    func testAutoReturnsNilCode() {
        XCTAssertNil(WhisperLanguage.auto.code)
    }

    func testGermanCode() {
        XCTAssertEqual(WhisperLanguage.german.code, "de")
    }

    func testEnglishCode() {
        XCTAssertEqual(WhisperLanguage.english.code, "en")
    }

    func testAllCasesHaveLabels() {
        for lang in WhisperLanguage.allCases {
            XCTAssertFalse(lang.label.isEmpty, "\(lang) hat kein Label")
        }
    }
}

// MARK: – WhisperModel

final class WhisperModelTests: XCTestCase {
    func testRawValues() {
        XCTAssertEqual(WhisperModel.base.rawValue, "base")
        XCTAssertEqual(WhisperModel.largev3.rawValue, "large-v3")
    }

    func testAllCasesHaveLabels() {
        for model in WhisperModel.allCases {
            XCTAssertFalse(model.label.isEmpty, "\(model) hat kein Label")
        }
    }
}

// MARK: – AppSettings

final class AppSettingsTests: XCTestCase {
    // Alle persistierten Keys vor jedem Test löschen
    private let keysToClean: [String] = [
        "llmProvider", "ollamaBaseURL", "ollamaModel", "ollamaPrompt",
        "whisperModel", "whisperLanguage", "previewEnabled", "soundFeedbackEnabled",
        "transcriptionEngine", "openAIModel", "openAIBaseURL",
        "ollamaEnabled",  // Legacy-Key – darf nicht mehr geschrieben werden
    ]

    override func setUp() {
        super.setUp()
        keysToClean.forEach { UserDefaults.standard.removeObject(forKey: $0) }
    }

    override func tearDown() {
        keysToClean.forEach { UserDefaults.standard.removeObject(forKey: $0) }
        super.tearDown()
    }

    func testDefaultLLMProvider() {
        XCTAssertEqual(AppSettings().llmProvider, .ollama)
    }

    func testDefaultLLMEnabled() {
        XCTAssertTrue(AppSettings().llmEnabled)
    }

    func testDefaultBaseURL() {
        XCTAssertEqual(AppSettings().ollamaBaseURL, "http://localhost:11434")
    }

    func testDefaultOllamaModel() {
        XCTAssertEqual(AppSettings().ollamaModel, "qwen2.5:32b")
    }

    func testDefaultWhisperModel() {
        XCTAssertEqual(AppSettings().whisperModel, .largev3)
    }

    func testDefaultWhisperLanguage() {
        XCTAssertEqual(AppSettings().whisperLanguage, .german)
    }

    func testDefaultPreviewDisabled() {
        XCTAssertFalse(AppSettings().previewEnabled)
    }

    func testDefaultSoundFeedbackEnabled() {
        XCTAssertTrue(AppSettings().soundFeedbackEnabled)
    }

    func testDefaultOpenAIModel() {
        XCTAssertEqual(AppSettings().openAIModel, "gpt-4o-mini")
    }

    func testDefaultOpenAIBaseURL() {
        XCTAssertEqual(AppSettings().openAIBaseURL, "https://api.openai.com/v1")
    }

    func testLLMEnabledFalseWhenDisabled() {
        let s = AppSettings()
        s.llmProvider = .disabled
        XCTAssertFalse(s.llmEnabled)
    }

    // MARK: Migration

    func testMigrationOllamaEnabledFalse() {
        // Altes Nutzer-Setup simulieren: ollamaEnabled = false gespeichert
        UserDefaults.standard.set(false, forKey: "ollamaEnabled")
        // llmProvider war noch nicht gesetzt → default .ollama
        UserDefaults.standard.removeObject(forKey: "llmProvider")

        let settings = AppSettings()

        // Migration muss .disabled setzen
        XCTAssertEqual(settings.llmProvider, .disabled)
        // Legacy-Key muss danach gelöscht sein
        XCTAssertNil(UserDefaults.standard.object(forKey: "ollamaEnabled"))
    }

    func testMigrationOllamaEnabledTrueKeepsProvider() {
        UserDefaults.standard.set(true, forKey: "ollamaEnabled")
        UserDefaults.standard.set("openai", forKey: "llmProvider")

        let settings = AppSettings()

        // ollamaEnabled=true darf llmProvider nicht überschreiben
        XCTAssertEqual(settings.llmProvider, .openAI)
        // Legacy-Key muss trotzdem gelöscht sein
        XCTAssertNil(UserDefaults.standard.object(forKey: "ollamaEnabled"))
    }

    func testMigrationRunsOnlyOnce() {
        UserDefaults.standard.set(false, forKey: "ollamaEnabled")
        _ = AppSettings()  // erste Initialisierung: Migration läuft

        // ollamaEnabled wurde gelöscht → zweite Init darf llmProvider nicht nochmal kippen
        UserDefaults.standard.set("openai", forKey: "llmProvider")
        let settings = AppSettings()
        XCTAssertEqual(settings.llmProvider, .openAI)
    }
}

// MARK: – LLMProvider

final class LLMProviderTests: XCTestCase {
    func testRawValues() {
        XCTAssertEqual(LLMProvider.disabled.rawValue, "disabled")
        XCTAssertEqual(LLMProvider.ollama.rawValue,   "ollama")
        XCTAssertEqual(LLMProvider.openAI.rawValue,   "openai")
    }

    func testAllCasesHaveLabels() {
        for provider in LLMProvider.allCases {
            XCTAssertFalse(provider.label.isEmpty, "\(provider) hat kein Label")
        }
    }

    func testActiveProvidersExcludesDisabled() {
        XCTAssertFalse(LLMProvider.activeProviders.contains(.disabled))
        XCTAssertTrue(LLMProvider.activeProviders.contains(.ollama))
        XCTAssertTrue(LLMProvider.activeProviders.contains(.openAI))
    }

    func testUnknownRawValueFallsBackToOllama() {
        // Verhindert Silent-Failure wenn ein alter/unbekannter rawValue in UserDefaults liegt
        let provider = LLMProvider(rawValue: "unbekannt") ?? .ollama
        XCTAssertEqual(provider, .ollama)
    }
}

// MARK: – DictoError

final class DictoErrorTests: XCTestCase {
    func testAllCasesHaveNonEmptyTitles() {
        let allErrors: [DictoError] = [
            .whisperModelLoad, .whisperTranscription,
            .appleSpeechDenied, .appleSpeechUnavailable,
            .ollamaNotReachable, .ollamaTimeout, .ollamaEmptyResponse, .ollamaUnknown,
            .openAIKeyMissing, .openAIAuthFailed, .openAINotReachable,
            .openAITimeout, .openAIUnknown,
        ]
        for error in allErrors {
            XCTAssertFalse(error.title.isEmpty, "\(error) hat keinen Titel")
        }
    }

    func testAllCasesHaveNonEmptyDetails() {
        let allErrors: [DictoError] = [
            .whisperModelLoad, .whisperTranscription,
            .appleSpeechDenied, .appleSpeechUnavailable,
            .ollamaNotReachable, .ollamaTimeout, .ollamaEmptyResponse, .ollamaUnknown,
            .openAIKeyMissing, .openAIAuthFailed, .openAINotReachable,
            .openAITimeout, .openAIUnknown,
        ]
        for error in allErrors {
            XCTAssertFalse(error.detail.isEmpty, "\(error) hat kein Detail")
        }
    }

    func testDisplayMessageContainsTitleAndDetail() {
        let error = DictoError.ollamaNotReachable
        XCTAssertTrue(error.displayMessage.contains(error.title))
        XCTAssertTrue(error.displayMessage.contains(error.detail))
    }

    // MARK: from(URLError) – Ollama

    func testFromURLErrorTimeout() {
        XCTAssertEqual(DictoError.from(URLError(.timedOut)), .ollamaTimeout)
    }

    func testFromURLErrorCannotConnect() {
        XCTAssertEqual(DictoError.from(URLError(.cannotConnectToHost)), .ollamaNotReachable)
    }

    func testFromURLErrorNetworkLost() {
        XCTAssertEqual(DictoError.from(URLError(.networkConnectionLost)), .ollamaNotReachable)
    }

    func testFromURLErrorNotConnected() {
        XCTAssertEqual(DictoError.from(URLError(.notConnectedToInternet)), .ollamaNotReachable)
    }

    func testFromURLErrorUnknownFallback() {
        XCTAssertEqual(DictoError.from(URLError(.badURL)), .ollamaUnknown)
    }

    // MARK: fromOpenAI(URLError)

    func testFromOpenAITimeout() {
        XCTAssertEqual(DictoError.fromOpenAI(URLError(.timedOut)), .openAITimeout)
    }

    func testFromOpenAICannotConnect() {
        XCTAssertEqual(DictoError.fromOpenAI(URLError(.cannotConnectToHost)), .openAINotReachable)
    }

    func testFromOpenAINetworkLost() {
        XCTAssertEqual(DictoError.fromOpenAI(URLError(.networkConnectionLost)), .openAINotReachable)
    }

    func testFromOpenAINotConnected() {
        XCTAssertEqual(DictoError.fromOpenAI(URLError(.notConnectedToInternet)), .openAINotReachable)
    }

    func testFromOpenAIUnknownFallback() {
        XCTAssertEqual(DictoError.fromOpenAI(URLError(.badURL)), .openAIUnknown)
    }
}

// MARK: – StorageKey
//
// Diese Tests schützen vor versehentlichem Umbenennen von Keys die in
// UserDefaults persistiert sind. Bestehende Nutzer verlieren sonst ihre Einstellungen.

final class StorageKeyTests: XCTestCase {
    func testUserDefaultsKeys() {
        XCTAssertEqual(StorageKey.Defaults.ollamaBaseURL,        "ollamaBaseURL")
        XCTAssertEqual(StorageKey.Defaults.ollamaModel,          "ollamaModel")
        XCTAssertEqual(StorageKey.Defaults.ollamaPrompt,         "ollamaPrompt")
        XCTAssertEqual(StorageKey.Defaults.transcriptionEngine,  "transcriptionEngine")
        XCTAssertEqual(StorageKey.Defaults.whisperModel,         "whisperModel")
        XCTAssertEqual(StorageKey.Defaults.whisperLanguage,      "whisperLanguage")
        XCTAssertEqual(StorageKey.Defaults.previewEnabled,       "previewEnabled")
        XCTAssertEqual(StorageKey.Defaults.soundFeedbackEnabled, "soundFeedbackEnabled")
        XCTAssertEqual(StorageKey.Defaults.customStyles,         "customStyles")
        XCTAssertEqual(StorageKey.Defaults.dictationShortcut,    "dictationShortcut")
        XCTAssertEqual(StorageKey.Defaults.transformShortcut,    "transformShortcut")
        XCTAssertEqual(StorageKey.Defaults.dictationStyle,       "dictationStyle")
        XCTAssertEqual(StorageKey.Defaults.llmProvider,          "llmProvider")
        XCTAssertEqual(StorageKey.Defaults.openAIModel,          "openAIModel")
        XCTAssertEqual(StorageKey.Defaults.openAIBaseURL,        "openAIBaseURL")
        XCTAssertEqual(StorageKey.Defaults.onboardingCompleted,  "onboardingCompleted")
        XCTAssertEqual(StorageKey.Defaults.dictationHistory,     "dictationHistory")
        XCTAssertEqual(StorageKey.Defaults.dictionaryEntries,    "dictionaryEntries")
    }

    func testLegacyKeyPreservedForMigration() {
        // Wichtig: dieser String muss exakt dem alten UserDefaults-Key entsprechen
        XCTAssertEqual(StorageKey.Defaults.ollamaEnabledLegacy, "ollamaEnabled")
    }

    func testKeychainKeys() {
        XCTAssertEqual(StorageKey.Keychain.openAIApiKey, "openAIApiKey")
    }
}

// MARK: – KeychainService

final class KeychainServiceTests: XCTestCase {
    private let testKey = "dicto.test.keychainKey"

    override func tearDown() {
        KeychainService.shared.delete(forKey: testKey)
        super.tearDown()
    }

    func testSaveAndLoad() {
        KeychainService.shared.save("mein-api-key", forKey: testKey)
        XCTAssertEqual(KeychainService.shared.load(forKey: testKey), "mein-api-key")
    }

    func testLoadMissingKeyReturnsNil() {
        XCTAssertNil(KeychainService.shared.load(forKey: testKey))
    }

    func testOverwriteUpdatesValue() {
        KeychainService.shared.save("erster-wert", forKey: testKey)
        KeychainService.shared.save("zweiter-wert", forKey: testKey)
        XCTAssertEqual(KeychainService.shared.load(forKey: testKey), "zweiter-wert")
    }

    func testDeleteRemovesValue() {
        KeychainService.shared.save("zu-loeschen", forKey: testKey)
        KeychainService.shared.delete(forKey: testKey)
        XCTAssertNil(KeychainService.shared.load(forKey: testKey))
    }

    func testDeleteNonExistentKeyDoesNotCrash() {
        // Darf keinen Fehler werfen
        KeychainService.shared.delete(forKey: testKey)
    }

    func testSaveEmptyString() {
        KeychainService.shared.save("", forKey: testKey)
        // Leerer String wird gespeichert und als leer zurückgegeben
        let loaded = KeychainService.shared.load(forKey: testKey)
        XCTAssertTrue(loaded == nil || loaded == "")
    }
}
