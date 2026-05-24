protocol TextPostProcessor {
    func process(text: String) async throws -> String
}
