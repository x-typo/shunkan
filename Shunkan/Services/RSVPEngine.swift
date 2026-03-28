import Foundation
import Observation

@MainActor
@Observable
final class RSVPEngine {
    private(set) var words: [String] = []
    private(set) var currentIndex: Int = 0
    private(set) var isPlaying: Bool = false
    private(set) var pageCount: Int = 0

    var wordsPerMinute: Int = 250 {
        didSet {
            UserDefaults.standard.set(wordsPerMinute, forKey: "shunkan_wpm")
        }
    }

    var currentWord: String {
        guard currentIndex >= 0 && currentIndex < words.count else { return "" }
        let word = words[currentIndex]
        return word == Tokenizer.paragraphSentinel ? "" : word
    }

    var progress: Double {
        guard !words.isEmpty else { return 0 }
        return Double(currentIndex) / Double(words.count)
    }

    var isComplete: Bool {
        !words.isEmpty && currentIndex >= words.count
    }

    private var playbackTask: Task<Void, Never>?

    init() {
        let saved = UserDefaults.standard.integer(forKey: "shunkan_wpm")
        if saved >= 100 && saved <= 900 {
            wordsPerMinute = saved
        }
    }

    func load(text: String, startIndex: Int = 0, pageCount: Int = 0) {
        words = Tokenizer.tokenize(text)
        currentIndex = min(startIndex, words.count)
        self.pageCount = pageCount
    }

    func play() {
        guard !words.isEmpty else { return }
        playbackTask?.cancel()
        isPlaying = true
        playbackTask = Task {
            while isPlaying && currentIndex < words.count {
                let word = words[currentIndex]
                do {
                    try await Task.sleep(for: .milliseconds(delay(for: word)))
                } catch {
                    return
                }
                guard isPlaying else { return }
                currentIndex += 1
            }
            isPlaying = false
        }
    }

    func pause() {
        isPlaying = false
        playbackTask?.cancel()
        playbackTask = nil
    }

    func skipForward() {
        let target = nextSentenceBoundary(from: currentIndex, forward: true)
        currentIndex = min(target, words.count)
    }

    func skipBackward() {
        let target = nextSentenceBoundary(from: currentIndex, forward: false)
        currentIndex = max(target, 0)
    }

    private func delay(for word: String) -> Int {
        let baseDelay = 60_000 / wordsPerMinute

        if word == Tokenizer.paragraphSentinel {
            return baseDelay * 3
        }

        switch word.last {
        case ".", "?", "!":
            return baseDelay * 2
        case ",", ";", ":":
            return Int(Double(baseDelay) * 1.5)
        default:
            return baseDelay
        }
    }

    private func nextSentenceBoundary(from index: Int, forward: Bool) -> Int {
        let step = forward ? 1 : -1
        var i = index + step
        while i >= 0 && i < words.count {
            let word = words[i]
            if word.last == "." || word.last == "?" || word.last == "!" {
                return forward ? i + 1 : i
            }
            i += step
        }
        return forward ? words.count : 0
    }

    var currentPageEstimate: Int {
        guard pageCount > 0 && !words.isEmpty else { return 0 }
        let wordsPerPage = words.count / pageCount
        guard wordsPerPage > 0 else { return 1 }
        return min((currentIndex / wordsPerPage) + 1, pageCount)
    }
}
