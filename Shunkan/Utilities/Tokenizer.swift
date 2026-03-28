import Foundation

enum Tokenizer {
    // Unicode paragraph separator - inserted between paragraphs to trigger 3x pause delay
    static let paragraphSentinel = "\u{2029}"

    static func tokenize(_ text: String) -> [String] {
        var tokens: [String] = []
        let paragraphs = text.components(separatedBy: "\n\n")
        for (i, paragraph) in paragraphs.enumerated() {
            let words = paragraph.components(separatedBy: .whitespacesAndNewlines)
                .filter { !$0.isEmpty }
            tokens.append(contentsOf: words)
            if i < paragraphs.count - 1 && !words.isEmpty {
                tokens.append(paragraphSentinel)
            }
        }
        return tokens
    }

    static func wordCount(_ text: String) -> Int {
        tokenize(text).filter { $0 != paragraphSentinel }.count
    }
}
