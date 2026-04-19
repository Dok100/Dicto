struct PassthroughPostProcessor: TextPostProcessor {
    func process(text: String) async -> String { text }
}
