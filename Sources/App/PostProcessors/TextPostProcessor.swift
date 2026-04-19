protocol TextPostProcessor {
    func process(text: String) async -> String
}
