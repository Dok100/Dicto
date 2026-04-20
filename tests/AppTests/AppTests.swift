import XCTest
import Dicto

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

// MARK: – AppSettings Defaults

final class AppSettingsTests: XCTestCase {
    override func setUp() {
        super.setUp()
        ["ollamaEnabled", "ollamaBaseURL", "ollamaModel",
         "whisperModel", "whisperLanguage", "previewEnabled"].forEach {
            UserDefaults.standard.removeObject(forKey: $0)
        }
    }

    func testDefaultOllamaEnabled() {
        XCTAssertTrue(AppSettings().ollamaEnabled)
    }

    func testDefaultBaseURL() {
        XCTAssertEqual(AppSettings().ollamaBaseURL, "http://localhost:11434")
    }

    func testDefaultOllamaModel() {
        XCTAssertEqual(AppSettings().ollamaModel, "glm4")
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
}
